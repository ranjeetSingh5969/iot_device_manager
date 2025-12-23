import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../models/device.dart';
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
            _buildSummaryCards(controller),
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
              Obx(() => ListView.builder(
                shrinkWrap: true,
                itemCount: controller.availableDevices.length,
                itemBuilder: (context, index) {
                  final device = controller.availableDevices[index];
                  final isSelected = controller.selectedDevices.contains(device);
                  return CheckboxListTile(
                    title: Text(device.displayName),
                    subtitle: Text(device.macAddress),
                    value: isSelected,
                    onChanged: (value) => controller.toggleDevice(device),
                    activeColor: AppColors.primaryBlue,
                  );
                },
              )),
              const SizedBox(height: AppDimensions.spacingLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 64,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: AppDimensions.spacingMedium),
                      const Text(
                        'Chart visualization',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingSmall),
                      Text(
                        '${controller.readings.length} readings',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
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
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.thermostat,
            iconColor: AppColors.error,
            value: controller.avgTemperature.value.toStringAsFixed(1),
            unit: '°C',
            label: 'Avg Temperature',
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.water_drop,
            iconColor: AppColors.primaryBlue,
            value: controller.avgHumidity.value.toStringAsFixed(1),
            unit: '%',
            label: 'Avg Humidity',
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
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
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

