import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/device.dart';

class DeviceInfoScreen extends StatelessWidget {
  final Device device;

  const DeviceInfoScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    icon: Icons.label,
                    label: 'Device Name',
                    value: device.displayName,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    icon: Icons.tag,
                    label: 'Device ID',
                    value: device.id,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    icon: Icons.numbers,
                    label: 'Sensor Number',
                    value: '#${device.sensorNumber}',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    icon: Icons.wifi,
                    label: 'MAC Address',
                    value: device.macAddress,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    icon: Icons.bluetooth,
                    label: 'Connection Type',
                    value: 'Bluetooth LE',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Registered On',
                    value: DateFormat('MMM dd, yyyy').format(
                      DateTime.fromMillisecondsSinceEpoch(device.createdAt),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
