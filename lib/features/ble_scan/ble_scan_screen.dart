import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/ble_device.dart';
import '../../models/device.dart';
import '../../shared/controllers/ble_controller.dart';
import '../../services/database_service.dart';
import '../../constants/app_strings.dart';

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({super.key});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  void _startScan() {
    Get.find<BleController>().startScan();
  }

  void _selectDevice(BleDevice bleDevice) {
    _showAddDeviceDialog(bleDevice);
  }

  void _showAddDeviceDialog(BleDevice bleDevice) {
    final nameController = TextEditingController();
    final sensorNumberController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device: ${bleDevice.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'MAC: ${bleDevice.macAddress}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name (optional)',
                hintText: 'e.g., Cold Chain Sensor 1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sensorNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sensor Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final sensorNumber = int.tryParse(sensorNumberController.text) ?? 1;
              final device = await _registerDevice(
                bleDevice,
                nameController.text.trim(),
                sensorNumber,
              );
              Get.back(); // Close dialog
              Get.back(result: device); // Return device to list screen
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  Future<Device?> _registerDevice(
    BleDevice bleDevice,
    String? name,
    int sensorNumber,
  ) async {
    final db = Get.find<DatabaseService>();
    final bleController = Get.find<BleController>();

    // Check if device already exists
    final existing = await db.getDeviceByMac(bleDevice.macAddress);
    if (existing != null) {
      // Connect and return existing device
      await bleController.connect(bleDevice);
      return existing;
    }

    // Create new device
    final device = Device(
      id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
      macAddress: bleDevice.macAddress.toUpperCase(),
      sensorNumber: sensorNumber,
      name: name?.isNotEmpty == true ? name : null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await db.insertDevice(device);
    await bleController.connect(bleDevice);
    return device;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scanForDevices),
        actions: [
          GetBuilder<BleController>(
            builder: (bleController) {
              return IconButton(
                icon: Icon(
                  bleController.isScanning ? Icons.stop : Icons.refresh,
                ),
                onPressed: bleController.isScanning
                    ? () => bleController.stopScan()
                    : _startScan,
                tooltip: bleController.isScanning ? AppStrings.stopScan : 'Rescan',
              );
            },
          ),
        ],
      ),
      body: GetBuilder<BleController>(
        builder: (bleController) {
          if (bleController.connectionState.value == BleConnectionState.error) {
            return _buildErrorState(bleController.errorMessage.value ?? 'Unknown error');
          }

          if (bleController.isScanning && bleController.discoveredDevices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning for nearby devices...'),
                ],
              ),
            );
          }

          if (bleController.discoveredDevices.isEmpty) {
            return _buildEmptyState();
          }

          return _buildDeviceList(bleController);
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final bleController = Get.find<BleController>();
                bleController.clearError();
                _startScan();
              },
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noDevices,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure your IoT devices are powered on',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BleController bleController) {
    final devices = bleController.discoveredDevices;

    return Column(
      children: [
        if (bleController.isScanning)
          const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: _buildSignalIcon(device),
                  title: Text(device.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.macAddress),
                      Text(
                        '${device.signalStrength} (${device.rssi} dBm)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getSignalColor(device),
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _selectDevice(device),
                    child: const Text(AppStrings.connect),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSignalIcon(BleDevice device) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.bluetooth,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _getSignalColor(device),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${device.signalBars}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getSignalColor(BleDevice device) {
    switch (device.signalBars) {
      case 4:
        return Colors.green;
      case 3:
        return Colors.lightGreen;
      case 2:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
