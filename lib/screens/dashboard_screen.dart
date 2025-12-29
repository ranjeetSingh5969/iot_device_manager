import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../constants/app_dimensions.dart';
import '../models/device.dart';
import '../models/sensor_reading.dart';
import '../controllers/ble_controller.dart';
import '../services/database_service.dart';
import '../routes/app_routes.dart';
import '../constants/app_strings.dart';

class DashboardScreen extends StatefulWidget {
  final Device device;

  const DashboardScreen({super.key, required this.device});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SensorReading? _latestReading;
  List<SensorReading> _recentReadings = [];
  int _totalReadings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final db = Get.find<DatabaseService>();
      final latestReading = await db.getLatestReading(widget.device.id);
      final last24Hours = DateTime.now().millisecondsSinceEpoch - (24 * 3600000);
      final recentReadings = await db.getReadingsForDevice(
        widget.device.id,
        since: last24Hours,
        limit: 100,
      );
      final totalCount = await db.getReadingCount(widget.device.id);
      setState(() {
        _latestReading = latestReading;
        _recentReadings = recentReadings;
        _totalReadings = totalCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToSync() async {
    await Get.toNamed(AppRoutes.dataSync, arguments: widget.device);
    _loadDashboardData();
  }

  void _navigateToHistory() {
    Get.toNamed(AppRoutes.history, arguments: widget.device);
  }

  void _navigateToDeviceInfo() {
    Get.toNamed(AppRoutes.deviceInfo, arguments: widget.device);
  }

  Future<void> _disconnect() async {
    final bleController = Get.find<BleController>();
    await bleController.disconnect();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _navigateToDeviceInfo,
            tooltip: 'Device Info',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildDashboardContent(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
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
                    Text(
                      isConnected ? AppStrings.connected : AppStrings.disconnected,
                      style: TextStyle(
                        color: isConnected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Metric cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Temperature',
                value: _latestReading != null
                    ? '${_latestReading!.temperature.toStringAsFixed(1)}°C'
                    : '--°C',
                icon: Icons.thermostat,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Humidity',
                value: _latestReading != null
                    ? '${_latestReading!.humidity.toStringAsFixed(1)}%'
                    : '--%',
                icon: Icons.water_drop,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Recent readings card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.sensorReadings,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_recentReadings.isEmpty)
                  Text(
                    'No readings available. Sync data to see sensor readings.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else ...[
                  Text(
                    '${_recentReadings.length} readings in last 24 hours',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_totalReadings > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$_totalReadings total readings stored',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_latestReading != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last update: ${DateFormat('MMM dd, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(_latestReading!.timestamp))}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Quick actions
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.sync,
                label: AppStrings.syncNow,
                onPressed: _navigateToSync,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.history,
                label: AppStrings.history,
                onPressed: _navigateToHistory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Disconnect button
        OutlinedButton.icon(
          onPressed: _disconnect,
          icon: const Icon(Icons.bluetooth_disabled),
          label: const Text(
            AppStrings.disconnect,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
            minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMedium),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        overflow: TextOverflow.visible,
        softWrap: true,
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingMedium,
        ),
      ),
    );
  }
}
