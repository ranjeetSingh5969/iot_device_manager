import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/device.dart';
import '../controllers/ble_controller.dart';
import '../services/database_service.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';

class DataSyncScreen extends StatefulWidget {
  final Device device;

  const DataSyncScreen({super.key, required this.device});

  @override
  State<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends State<DataSyncScreen> {
  bool _isSyncing = false;
  bool _syncComplete = false;
  String? _error;
  int _syncedRecords = 0;
  String _currentPhase = '';

  Future<void> _startSync() async {
    final bleController = Get.find<BleController>();
    final db = Get.find<DatabaseService>();

    if (!bleController.isConnected) {
      setState(() {
        _error = 'Device not connected. Please reconnect and try again.';
      });
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncComplete = false;
      _error = null;
      _syncedRecords = 0;
      _currentPhase = 'Sending "data" command...';
    });

    try {
      // Send data command and get readings
      final readings = await bleController.sendDataCommand(widget.device.id);

      setState(() {
        _currentPhase = 'Saving readings to database...';
      });

      // Save readings to database
      if (readings.isNotEmpty) {
        await db.insertReadings(readings);
        setState(() {
          _syncedRecords = readings.length;
        });
      }

      setState(() {
        _isSyncing = false;
        _syncComplete = true;
        _currentPhase = '';
      });
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _error = 'Sync failed: ${e.toString()}';
        _currentPhase = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dataSync),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Connection status
              GetBuilder<BleController>(
                builder: (bleController) {
                  final isConnected = bleController.isConnected;
                  return Card(
                    color: isConnected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_disabled,
                            color: isConnected
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConnected ? 'Device Connected' : 'Device Not Connected',
                                style: TextStyle(
                                  color: isConnected
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                widget.device.displayName,
                                style: TextStyle(
                                  color: isConnected
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onErrorContainer,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),

              // Sync status display
              if (_isSyncing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  _currentPhase.isNotEmpty ? _currentPhase : AppStrings.syncing,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ] else if (_syncComplete) ...[
                Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppColors.success,
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.syncComplete,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '$_syncedRecords readings synchronized',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Back to Dashboard'),
                ),
              ] else if (_error != null) ...[
                Icon(
                  Icons.error,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.syncFailed,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _startSync,
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.retry),
                ),
              ] else ...[
                Icon(
                  Icons.cloud_download,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Ready to Sync',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'This will send the "data" command to the device to retrieve sensor readings.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                GetBuilder<BleController>(
                  builder: (bleController) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: bleController.isConnected ? _startSync : null,
                        icon: const Icon(Icons.sync),
                        label: const Text('Send "data" Command'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    );
                  },
                ),
                GetBuilder<BleController>(
                  builder: (bleController) {
                    if (!bleController.isConnected) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Please connect to the device first',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
