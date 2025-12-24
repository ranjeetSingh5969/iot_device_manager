import 'package:get/get.dart';
import '../models/device.dart';
import '../services/database_service.dart';

enum UploadStatus {
  uploaded,
  pending,
  uploading,
}

class DeviceSyncStatus {
  final Device device;
  final int recordCount;
  final UploadStatus status;
  final DateTime? lastSyncedDate;
  final DateTime? uploadedDate;
  final bool isSelected;

  DeviceSyncStatus({
    required this.device,
    required this.recordCount,
    required this.status,
    this.lastSyncedDate,
    this.uploadedDate,
    this.isSelected = false,
  });

  DeviceSyncStatus copyWith({
    Device? device,
    int? recordCount,
    UploadStatus? status,
    DateTime? lastSyncedDate,
    DateTime? uploadedDate,
    bool? isSelected,
  }) {
    return DeviceSyncStatus(
      device: device ?? this.device,
      recordCount: recordCount ?? this.recordCount,
      status: status ?? this.status,
      lastSyncedDate: lastSyncedDate ?? this.lastSyncedDate,
      uploadedDate: uploadedDate ?? this.uploadedDate,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class DownloadDataController extends GetxController {
  final RxList<DeviceSyncStatus> deviceSyncStatuses = <DeviceSyncStatus>[].obs;
  final RxBool selectAll = false.obs;
  final RxBool isUploading = false.obs;

  int get totalRecords => deviceSyncStatuses.fold(0, (sum, status) => sum + status.recordCount);
  int get uploadedCount => deviceSyncStatuses.where((s) => s.status == UploadStatus.uploaded).length;
  int get pendingCount => deviceSyncStatuses.where((s) => s.status == UploadStatus.pending).length;

  @override
  void onInit() {
    super.onInit();
    loadDeviceSyncStatuses();
  }

  Future<void> loadDeviceSyncStatuses() async {
    try {
      final db = Get.find<DatabaseService>();
      final devices = await db.getDevices();
      final statuses = <DeviceSyncStatus>[];

      for (final device in devices) {
        final recordCount = await db.getReadingCount(device.id);
        final latestReading = await db.getLatestReading(device.id);
        
        final status = _determineUploadStatus(device);
        final lastSyncedDate = latestReading != null
            ? DateTime.fromMillisecondsSinceEpoch(latestReading.timestamp)
            : null;

        statuses.add(DeviceSyncStatus(
          device: device,
          recordCount: recordCount,
          status: status,
          lastSyncedDate: lastSyncedDate,
          uploadedDate: status == UploadStatus.uploaded ? lastSyncedDate : null,
        ));
      }

      deviceSyncStatuses.value = statuses;
    } catch (e) {
      // Handle error
    }
  }

  UploadStatus _determineUploadStatus(Device device) {
    if (device.id.contains('001')) {
      return UploadStatus.uploaded;
    }
    return UploadStatus.pending;
  }

  void toggleSelectAll() {
    selectAll.value = !selectAll.value;
    deviceSyncStatuses.value = deviceSyncStatuses.map((status) {
      return status.copyWith(isSelected: selectAll.value);
    }).toList();
  }

  void toggleDeviceSelection(int index) {
    final status = deviceSyncStatuses[index];
    deviceSyncStatuses[index] = status.copyWith(isSelected: !status.isSelected);
    _updateSelectAllState();
  }

  void _updateSelectAllState() {
    selectAll.value = deviceSyncStatuses.every((status) => status.isSelected);
  }

  Future<void> uploadDevice(int index) async {
    final status = deviceSyncStatuses[index];
    if (status.status == UploadStatus.uploaded || status.status == UploadStatus.uploading) {
      return;
    }

    deviceSyncStatuses[index] = status.copyWith(status: UploadStatus.uploading);
    isUploading.value = true;

    try {
      await Future.delayed(const Duration(seconds: 2));
      deviceSyncStatuses[index] = status.copyWith(
        status: UploadStatus.uploaded,
        uploadedDate: DateTime.now(),
      );
    } catch (e) {
      deviceSyncStatuses[index] = status.copyWith(status: UploadStatus.pending);
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> uploadSelected() async {
    final selectedIndices = deviceSyncStatuses
        .asMap()
        .entries
        .where((entry) => entry.value.isSelected)
        .map((entry) => entry.key)
        .toList();

    for (final index in selectedIndices) {
      await uploadDevice(index);
    }
  }
}

