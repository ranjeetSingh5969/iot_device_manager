import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'report_generator_controller.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';

class ReportGeneratorScreen extends StatelessWidget {
  const ReportGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportGeneratorController>();
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Report Generator',
          style: TextStyle(
            color: AppColors.textBlack,
            fontWeight: FontWeight.w600,
            fontSize: 20,
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
            _buildHeader(),
            const SizedBox(height: AppDimensions.spacingXLarge),
            _buildSelectConsignmentSection(controller),
            const SizedBox(height: AppDimensions.spacingXLarge),
            _buildSelectSensorsSection(controller),
            const SizedBox(height: AppDimensions.spacingXLarge),
            _buildGenerateReportButton(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Generate Report',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Text(
          'Select a consignment and sensors to generate daily analytics report',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectConsignmentSection(ReportGeneratorController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Consignment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        Obx(() => GestureDetector(
          onTap: controller.toggleConsignmentListExpansion,
          child: Container(
            height: AppDimensions.inputHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.inputPadding,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(
                color: AppColors.borderGrey,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.selectedConsignment.value != null
                        ? controller.selectedConsignment.value!.displayName
                        : 'Select a consignment',
                    style: TextStyle(
                      fontSize: 16,
                      color: controller.selectedConsignment.value != null
                          ? AppColors.textBlack
                          : AppColors.textGreyLight,
                    ),
                  ),
                ),
                Icon(
                  controller.isConsignmentListExpanded.value
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textGrey,
                ),
              ],
            ),
          ),
        )),
        Obx(() => controller.isConsignmentListExpanded.value
            ? _buildConsignmentList(controller)
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildSelectSensorsSection(ReportGeneratorController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Sensors',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: controller.selectAllSensors,
                  child: const Text(
                    'Select All',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSmall),
                const Text(
                  '|',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSmall),
                GestureDetector(
                  onTap: controller.clearAllSensors,
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        Obx(() => GestureDetector(
          onTap: controller.toggleSensorListExpansion,
          child: Container(
            height: AppDimensions.inputHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.inputPadding,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(
                color: AppColors.borderGrey,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.selectedSensorCount == 0
                        ? 'Select sensors'
                        : '${controller.selectedSensorCount} sensor(s) selected',
                    style: TextStyle(
                      fontSize: 16,
                      color: controller.selectedSensorCount > 0
                          ? AppColors.textBlack
                          : AppColors.textGreyLight,
                    ),
                  ),
                ),
                Icon(
                  controller.isSensorListExpanded.value
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textGrey,
                ),
              ],
            ),
          ),
        )),
        Obx(() => controller.isSensorListExpanded.value
            ? _buildSensorList(controller)
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildSensorList(ReportGeneratorController controller) {
    return Obx(() {
      if (controller.availableSensors.isEmpty) {
        return Container(
          margin: const EdgeInsets.only(top: AppDimensions.spacingSmall),
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          child: const Text(
            'No sensors available',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
        );
      }
      return Container(
        margin: const EdgeInsets.only(top: AppDimensions.spacingSmall),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        child: Column(
          children: controller.availableSensors.map((sensor) {
            return Obx(() {
              final isSelected = controller.selectedSensorIds.contains(sensor.id);
              return Container(
                margin: const EdgeInsets.all(AppDimensions.spacingSmall),
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBlueLight.withValues(alpha: 0.15)
                      : AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: GestureDetector(
                  onTap: () => controller.toggleSensorSelection(sensor.id),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.borderGrey,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.textWhite,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppDimensions.spacingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sensor.macAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textBlack,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingXSmall),
                            Text(
                              sensor.displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          }).toList(),
        ),
      );
    });
  }

  Widget _buildGenerateReportButton(ReportGeneratorController controller) {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.isGenerating.value
            ? null
            : controller.generateReport,
        icon: controller.isGenerating.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                ),
              )
            : const Icon(Icons.bar_chart, size: 20),
        label: Text(
          controller.isGenerating.value ? 'Generating...' : 'Generate Report',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.textWhite,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLarge),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          elevation: 0,
        ),
      ),
    ));
  }

  Widget _buildConsignmentList(ReportGeneratorController controller) {
    return Obx(() {
      if (controller.consignments.isEmpty) {
        return Container(
          margin: const EdgeInsets.only(top: AppDimensions.spacingSmall),
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          child: const Text(
            'No consignments available',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
        );
      }
      return Container(
        margin: const EdgeInsets.only(top: AppDimensions.spacingSmall),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView(
          shrinkWrap: true,
          children: controller.consignments.map((consignment) {
            return Obx(() {
              final isSelected = controller.selectedConsignment.value?.id ==
                  consignment.id;
              return Container(
                margin: const EdgeInsets.all(AppDimensions.spacingSmall),
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBlueLight.withValues(alpha: 0.15)
                      : AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: GestureDetector(
                  onTap: () => controller.selectConsignment(consignment),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          consignment.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: AppColors.textBlack,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            });
          }).toList(),
        ),
      );
    });
  }
}

