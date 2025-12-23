import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/device.dart';
import '../controllers/auth_controller.dart';
import '../services/database_service.dart';
import '../routes/app_routes.dart';
import '../constants/app_strings.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  List<Device> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final db = Get.find<DatabaseService>();
      final devices = await db.getDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final authController = Get.find<AuthController>();
    await authController.logout();
    Get.offAllNamed(AppRoutes.login);
  }

  void _navigateToScan() async {
    final result = await Get.toNamed<Device>(AppRoutes.bleScan);
    if (result != null) {
      await _loadDevices();
      Get.toNamed(AppRoutes.dashboard, arguments: result);
    }
  }

  void _navigateToDashboard(Device device) {
    Get.toNamed(AppRoutes.dashboard, arguments: device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.devices),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: AppStrings.logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDevices,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _devices.isEmpty
                ? _buildEmptyState()
                : _buildDeviceList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToScan,
        icon: const Icon(Icons.bluetooth_searching),
        label: const Text(AppStrings.scanForDevices),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noDevices,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan for nearby Bluetooth devices to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.sensors,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(device.displayName),
            subtitle: Text(device.macAddress),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToDashboard(device),
          ),
        );
      },
    );
  }
}
