import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import 'config_result_controller.dart';
import '../../features/new_device/new_device_controller.dart';
import '../../features/live_dashboard/dashboard_controller.dart';
import '../../models/sensor_reading.dart';
import '../../routes/app_routes.dart';
import '../../utils/snackbar_helper.dart';

class ConfigResultScreen extends StatelessWidget {
  const ConfigResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ConfigResultController>();
    
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () {
            // Reload devices when going back
            try {
              final newDeviceController = Get.find<NewDeviceController>();
              newDeviceController.loadOnboardedDevices();
            } catch (e) {
              // Controller not available, that's okay
            }
            Get.back();
          },
        ),
        title: const Text(
          'Result',
          style: TextStyle(
            color: AppColors.textBlack,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        actions: [
          Obx(() {
            if (controller.onboardedDevice.value == null) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.dashboard, color: AppColors.primaryBlue),
              onPressed: () {
                // Navigate to live dashboard with the device
                final device = controller.onboardedDevice.value;
                if (device != null) {
                  // Initialize dashboard controller if not already initialized
                  DashboardController dashboardController;
                  try {
                    dashboardController = Get.find<DashboardController>();
                  } catch (e) {
                    // Controller not found, initialize it
                    dashboardController = Get.put(DashboardController());
                  }
                  dashboardController.setDevice(device);
                  Get.toNamed(AppRoutes.liveDashboard);
                }
              },
              tooltip: 'View Live Dashboard',
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Historical Data Header with Action Buttons
          Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack,
                      ),
                    ),
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Text(
                        '${controller.dataEntries.length} records',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                // Live Dashboard Button
                Obx(() {
                  if (controller.onboardedDevice.value == null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to live dashboard with the device
                        final device = controller.onboardedDevice.value;
                        if (device != null) {
                          // Initialize dashboard controller if not already initialized
                          DashboardController dashboardController;
                          try {
                            dashboardController = Get.find<DashboardController>();
                          } catch (e) {
                            // Controller not found, initialize it
                            dashboardController = Get.put(DashboardController());
                          }
                          dashboardController.setDevice(device);
                          Get.toNamed(AppRoutes.liveDashboard);
                        }
                      },
                      icon: const Icon(Icons.dashboard, size: 20),
                      label: const Text(
                        'View Live Dashboard',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryGreen,
                        foregroundColor: AppColors.textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                }),
                Row(
                  children: [
                    // Export CSV button (blue, oval)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.exportToCsv,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.textWhite,
                          side: const BorderSide(color: AppColors.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Export CSV',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    // Download Data button (blue, rectangular with arrow)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.downloadData,
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        label: const Text(
                          'Download Data',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    // Upload Data button (green, rectangular with cloud)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.uploadData,
                        icon: const Icon(Icons.cloud_upload, size: 18),
                        label: const Text(
                          'Upload Data',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryGreen,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Data List
          Expanded(
            child: Obx(() {
              if (controller.dataEntries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.status.value == 'Listening'
                            ? Icons.bluetooth_searching
                            : Icons.inbox,
                        size: 64,
                        color: AppColors.textGreyLight,
                      ),
                      const SizedBox(height: AppDimensions.spacingMedium),
                      Text(
                        controller.status.value == 'Listening'
                            ? 'Waiting for data...'
                            : controller.status.value == 'Timeout'
                            ? 'No data received'
                            : 'No data yet',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
                itemCount: controller.dataEntries.length,
                itemBuilder: (context, index) {
                  final reading = controller.dataEntries[index];
                  return _buildDataEntryCard(reading);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDataEntryCard(SensorReading reading) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(reading.timestamp);
    final dateFormat = DateFormat('dd/MM/yyyy, HH:mm:ss');
    final formattedDateTime = dateFormat.format(dateTime);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: AppColors.borderGrey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Time
          Text(
            formattedDateTime,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          // Temperature and Humidity Row
          Row(
            children: [
              // Temperature with red thermometer icon
              Row(
                children: [
                  const Icon(
                    Icons.thermostat,
                    size: 20,
                    color: Colors.red,
                  ),
                  const SizedBox(width: AppDimensions.spacingSmall),
                  Text(
                    '${reading.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppDimensions.spacingLarge),
              // Humidity with blue water drop icon
              Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    size: 20,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: AppDimensions.spacingSmall),
                  Text(
                    '${reading.humidity.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textBlack,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
