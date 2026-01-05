import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_dimensions.dart';
import '../../models/device.dart';
import '../../models/sensor_reading.dart';
import '../../shared/controllers/ble_controller.dart';
import '../../services/database_service.dart';
import '../../routes/app_routes.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  final Device device;

  const DashboardScreen({super.key, required this.device});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SensorReading? _latestReading;
  List<SensorReading> _recentReadings = [];
  List<SensorReading> _allReadings = [];
  int _totalReadings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load data after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen becomes visible again if we don't have data
    if (!_isLoading && _allReadings.isEmpty && _recentReadings.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDashboardData();
      });
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
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
      // Also get all readings for average calculation
      final allReadings = await db.getReadingsForDevice(
        widget.device.id,
        limit: 1000,
      );
      final totalCount = await db.getReadingCount(widget.device.id);
      
      debugPrint('Dashboard: Loaded ${allReadings.length} total readings, ${recentReadings.length} recent readings');
      
      if (mounted) {
        setState(() {
          _latestReading = latestReading;
          _recentReadings = recentReadings;
          _allReadings = allReadings;
          _totalReadings = totalCount;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading dashboard data: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToSync() async {
    final result = await Get.toNamed(AppRoutes.dataSync, arguments: widget.device);
    // Reload data after sync
    await _loadDashboardData();
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

        // Average Temperature Card - Show if we have any readings
        Builder(
          builder: (context) {
            final readingsForAverage = _allReadings.isNotEmpty ? _allReadings : _recentReadings;
            final averageTemp = _calculateAverageTemperature();
            
            if (readingsForAverage.isEmpty || averageTemp == 0.0) {
              return const SizedBox.shrink();
            }
            
            return Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.thermostat, color: Colors.orange, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Average Temperature',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              averageTemp.toStringAsFixed(2),
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '°C',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Based on ${readingsForAverage.length} reading${readingsForAverage.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),

        // Temperature vs Time Graph
        if (_recentReadings.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temperature vs Time',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _buildTemperatureChart(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

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

  double _calculateAverageTemperature() {
    // Use all readings for average calculation, fallback to recent if all is empty
    final readingsToUse = _allReadings.isNotEmpty ? _allReadings : _recentReadings;
    if (readingsToUse.isEmpty) {
      debugPrint('Dashboard: No readings available for average calculation');
      return 0.0;
    }
    final sum = readingsToUse.fold<double>(0.0, (sum, reading) => sum + reading.temperature);
    final average = sum / readingsToUse.length;
    debugPrint('Dashboard: Calculating average from ${readingsToUse.length} readings: $average°C');
    return average;
  }

  Widget _buildTemperatureChart() {
    if (_recentReadings.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Sort readings by timestamp
    final sortedReadings = List<SensorReading>.from(_recentReadings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Prepare chart data
    final spots = sortedReadings.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final reading = entry.value;
      return FlSpot(index, reading.temperature);
    }).toList();

    // Get min and max temperatures for Y axis
    final temperatures = sortedReadings.map((r) => r.temperature).toList();
    final minTemp = temperatures.reduce((a, b) => a < b ? a : b);
    final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    final tempRange = maxTemp - minTemp;
    final yMin = (minTemp - (tempRange * 0.1)).clamp(0.0, double.infinity);
    final yMax = maxTemp + (tempRange * 0.1);

    // Prepare X axis labels (show time for first, middle, last)
    String getXLabel(int index) {
      if (index == 0 || index == sortedReadings.length - 1 || 
          (sortedReadings.length > 2 && index == sortedReadings.length ~/ 2)) {
        final reading = sortedReadings[index];
        return DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(reading.timestamp));
      }
      return '';
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (yMax - yMin) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.borderGrey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: sortedReadings.length > 10 ? (sortedReadings.length / 3).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedReadings.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      getXLabel(index),
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: (yMax - yMin) / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppColors.borderGrey,
            width: 1,
          ),
        ),
        minX: 0,
        maxX: (sortedReadings.length - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
