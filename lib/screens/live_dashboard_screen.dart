import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_controller.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class LiveDashboardScreen extends StatelessWidget {
  const LiveDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Live Dashboard',
          style: TextStyle(
            color: AppColors.textBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeSection(controller),
            const SizedBox(height: AppDimensions.spacingXLarge),
            _buildDeviceSelectionSection(controller),
            const SizedBox(height: AppDimensions.spacingXLarge),
            _buildChartSection(controller),
            const SizedBox(height: AppDimensions.spacingXLarge),
            Obx(() => _buildSummaryCards(controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSection(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        Obx(() => Row(
          children: [
            Expanded(
              child: _buildDateRangeButton(
                label: 'Today',
                isSelected: controller.selectedDateRange.value == DateRange.today,
                onTap: () => controller.setDateRange(DateRange.today),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(
              child: _buildDateRangeButton(
                label: 'Week',
                isSelected: controller.selectedDateRange.value == DateRange.week,
                onTap: () => controller.setDateRange(DateRange.week),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(
              child: _buildDateRangeButton(
                label: 'Month',
                isSelected: controller.selectedDateRange.value == DateRange.month,
                onTap: () => controller.setDateRange(DateRange.month),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(
              child: _buildDateRangeButton(
                label: 'All',
                isSelected: controller.selectedDateRange.value == DateRange.all,
                onTap: () => controller.setDateRange(DateRange.all),
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildDateRangeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderGrey,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.textWhite : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceSelectionSection(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Devices (tap to compare)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        Obx(() => InkWell(
          onTap: () => _showDeviceSelectionDialog(controller),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Row(
              children: [
                if (controller.selectedDevices.isEmpty)
                  const Text(
                    'Select devices',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 16,
                    ),
                  )
                else
                  Expanded(
                    child: Wrap(
                      spacing: AppDimensions.spacingSmall,
                      children: controller.selectedDevices.map((device) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingSmall,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                device.displayName,
                                style: const TextStyle(
                                  color: AppColors.textBlack,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textGrey,
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _showDeviceSelectionDialog(DashboardController controller) {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Devices',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLarge),
              Obx(() {
                if (controller.availableDevices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppDimensions.paddingLarge),
                    child: Center(
                      child: Text(
                        'No devices available',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.availableDevices.length,
                    itemBuilder: (context, index) {
                      final device = controller.availableDevices[index];
                      return Obx(() {
                        final isSelected = controller.selectedDevices.any((d) => d.id == device.id);
                        return CheckboxListTile(
                          title: Text(
                            device.displayName,
                            style: const TextStyle(color: AppColors.textBlack),
                          ),
                          subtitle: Text(
                            device.macAddress,
                            style: const TextStyle(color: AppColors.textGrey),
                          ),
                          value: isSelected,
                          onChanged: (value) => controller.toggleDevice(device),
                          activeColor: AppColors.primaryBlue,
                        );
                      });
                    },
                  ),
                );
              }),
              const SizedBox(height: AppDimensions.spacingLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black54,
    );
  }

  Widget _buildChartSection(DashboardController controller) {
    return Card(
      elevation: 0,
      color: AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderGrey, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temperature vs Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLarge),
            Obx(() {
              if (controller.selectedDevices.isEmpty) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 64,
                          color: AppColors.textGreyLight,
                        ),
                        const SizedBox(height: AppDimensions.spacingMedium),
                        const Text(
                          'Select devices to view chart',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (controller.readings.isEmpty) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 64,
                          color: AppColors.textGreyLight,
                        ),
                        const SizedBox(height: AppDimensions.spacingMedium),
                        const Text(
                          'No data available for selected period',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Sort readings by timestamp
              final sortedReadings = List.from(controller.readings)
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
                if (index == 0 || index == sortedReadings.length - 1 || index == sortedReadings.length ~/ 2) {
                  final reading = sortedReadings[index];
                  return DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(reading.timestamp));
                }
                return '';
              }
              
              return SizedBox(
                height: 250,
                child: LineChart(
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
                        color: AppColors.primaryBlue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(
                          show: false,
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppDimensions.spacingMedium),
            Obx(() => Wrap(
              spacing: AppDimensions.spacingMedium,
              children: controller.selectedDevices.map((device) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      device.displayName,
                      style: const TextStyle(
                        color: AppColors.textBlack,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList(),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DashboardController controller) {
    // Access reactive values to trigger rebuild
    final avgTemp = controller.avgTemperature.value;
    final avgHum = controller.avgHumidity.value;
    final readingsCount = controller.readings.length;
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.thermostat,
            iconColor: AppColors.error,
            value: avgTemp > 0 ? avgTemp.toStringAsFixed(1) : '0.0',
            unit: '°C',
            label: 'Avg Temperature',
            showEmpty: readingsCount == 0,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.water_drop,
            iconColor: AppColors.primaryBlue,
            value: avgHum > 0 ? avgHum.toStringAsFixed(1) : '0.0',
            unit: '%',
            label: 'Avg Humidity',
            showEmpty: readingsCount == 0,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    required String label,
    bool showEmpty = false,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderGrey, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: AppDimensions.spacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showEmpty ? '--' : value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: showEmpty ? AppColors.textGrey : AppColors.textBlack,
                  ),
                ),
                if (!showEmpty)
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textBlack,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

