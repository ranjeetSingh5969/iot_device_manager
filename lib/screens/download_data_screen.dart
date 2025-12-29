import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/download_data_controller.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class DownloadDataScreen extends StatelessWidget {
  const DownloadDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DownloadDataController>();
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Download Data',
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
            _buildDataSummaryCard(controller),
            const SizedBox(height: AppDimensions.spacingXLarge),
            _buildLegend(),
            const SizedBox(height: AppDimensions.spacingXLarge),
            _buildDeviceSyncStatusHeader(controller),
            const SizedBox(height: AppDimensions.spacingMedium),
            _buildDeviceList(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummaryCard(DownloadDataController controller) {
    return Card(
      elevation: 0,
      color: AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderGrey, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Obx(() => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.totalRecords}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  const Text(
                    'Total Records',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSmall),
                      Text(
                        '${controller.uploadedCount}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'Uploaded',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSmall),
                      Text(
                        '${controller.pendingCount}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.secondaryGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            const Text(
              'Uploaded to Cloud (Admin can view)',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            const Text(
              'Pending Upload (Local only)',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceSyncStatusHeader(DownloadDataController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Device Sync Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        Obx(() => Row(
          children: [
            const Text(
              'Select All',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            Checkbox(
              value: controller.selectAll.value,
              onChanged: (_) => controller.toggleSelectAll(),
              activeColor: AppColors.primaryBlue,
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildDeviceList(DownloadDataController controller) {
    return Obx(() => Column(
      children: controller.deviceSyncStatuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        return _buildDeviceCard(controller, index, status);
      }).toList(),
    ));
  }

  Widget _buildDeviceCard(
    DownloadDataController controller,
    int index,
    DeviceSyncStatus status,
  ) {
    final isUploaded = status.status == UploadStatus.uploaded;
    final statusColor = isUploaded ? AppColors.secondaryGreen : AppColors.error;
    final statusText = isUploaded ? 'Uploaded to Cloud' : 'Pending Upload';
    final statusIcon = isUploaded ? Icons.check : Icons.error_outline;

    return Card(
      elevation: 0,
      color: AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderGrey, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Obx(() => Checkbox(
                  value: controller.deviceSyncStatuses[index].isSelected,
                  onChanged: (_) => controller.toggleDeviceSelection(index),
                  activeColor: AppColors.primaryBlue,
                )),
                const SizedBox(width: AppDimensions.spacingSmall),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSmall),
                Expanded(
                  child: Text(
                    status.device.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSmall),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                status.device.id,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                children: [
                  const Icon(
                    Icons.description,
                    size: 16,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(width: AppDimensions.spacingSmall),
                  Text(
                    '${status.recordCount} local records',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                children: [
                  const Icon(
                    Icons.sync,
                    size: 16,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(width: AppDimensions.spacingSmall),
                  Text(
                    status.lastSyncedDate != null
                        ? 'Synced ${DateFormat('MM/dd/yyyy').format(status.lastSyncedDate!)}'
                        : 'Not synced',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Obx(() {
              final currentStatus = controller.deviceSyncStatuses[index];
              final currentIsUploaded = currentStatus.status == UploadStatus.uploaded;
              final currentIsUploading = currentStatus.status == UploadStatus.uploading;
              
              if (currentIsUploaded && currentStatus.uploadedDate != null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_done,
                        size: 16,
                        color: AppColors.secondaryGreen,
                      ),
                      const SizedBox(width: AppDimensions.spacingSmall),
                      Text(
                        'Uploaded ${DateFormat('MM/dd/yyyy').format(currentStatus.uploadedDate!)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryGreen,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (currentIsUploading) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                        ),
                      ),
                      SizedBox(width: AppDimensions.spacingSmall),
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => controller.uploadDevice(index),
                    icon: const Icon(Icons.cloud_upload, size: 18),
                    label: const Text(
                      'Upload to Cloud',
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.textWhite,
                      minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMedium),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMedium,
                        vertical: AppDimensions.paddingMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                    ),
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}

