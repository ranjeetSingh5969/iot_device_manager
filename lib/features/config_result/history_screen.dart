import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/device.dart';
import '../../models/sensor_reading.dart';
import '../../services/database_service.dart';
import '../../constants/app_strings.dart';

class HistoryScreen extends StatefulWidget {
  final Device device;

  const HistoryScreen({super.key, required this.device});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SensorReading> _readings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() => _isLoading = true);
    try {
      final db = Get.find<DatabaseService>();
      final readings = await db.getReadingsForDevice(widget.device.id, limit: 100);
      setState(() {
        _readings = readings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.history),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReadings,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _readings.isEmpty
                ? _buildEmptyState()
                : _buildReadingsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noHistory,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Sync data from your device to see history',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _readings.length,
      itemBuilder: (context, index) {
        final reading = _readings[index];
        final dateTime = DateTime.fromMillisecondsSinceEpoch(reading.timestamp);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.data_usage,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                _buildChip(
                  icon: Icons.thermostat,
                  value: '${reading.temperature.toStringAsFixed(1)}°C',
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  icon: Icons.water_drop,
                  value: '${reading.humidity.toStringAsFixed(1)}%',
                  color: Colors.blue,
                ),
              ],
            ),
            subtitle: Text(
              DateFormat('MMM dd, yyyy HH:mm:ss').format(dateTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
