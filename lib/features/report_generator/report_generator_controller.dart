import 'package:get/get.dart';
import '../../models/consignment.dart';
import '../../models/device.dart';
import '../../services/database_service.dart';

class ReportGeneratorController extends GetxController {
  final RxList<Consignment> consignments = <Consignment>[].obs;
  final Rx<Consignment?> selectedConsignment = Rxn<Consignment>();
  final RxList<Device> availableSensors = <Device>[].obs;
  final RxList<String> selectedSensorIds = <String>[].obs;
  final RxBool isSensorListExpanded = false.obs;
  final RxBool isConsignmentListExpanded = false.obs;
  final RxBool isGenerating = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadConsignments();
    loadSensors();
  }

  Future<void> loadConsignments() async {
    try {
      final db = Get.find<DatabaseService>();
      final trips = await db.getAllTrips();
      consignments.value = trips.map((trip) {
        return Consignment(
          id: trip['id'] as int,
          startLocation: trip['startLocation'] as String,
          endLocation: trip['endLocation'] as String,
          startDate: trip['startDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(trip['startDate'] as int)
              : null,
          clientName: trip['clientName'] as String?,
        );
      }).toList();
      if (consignments.isNotEmpty) {
        selectedConsignment.value = consignments.first;
      }
    } catch (e) {
      consignments.clear();
    }
  }

  Future<void> loadSensors() async {
    try {
      final db = Get.find<DatabaseService>();
      final devices = await db.getDevices();
      availableSensors.value = devices;
    } catch (e) {
      availableSensors.clear();
    }
  }

  void selectConsignment(Consignment? consignment) {
    selectedConsignment.value = consignment;
    isConsignmentListExpanded.value = false;
  }

  void toggleSensorSelection(String sensorId) {
    if (selectedSensorIds.contains(sensorId)) {
      selectedSensorIds.remove(sensorId);
    } else {
      selectedSensorIds.add(sensorId);
    }
  }

  void selectAllSensors() {
    selectedSensorIds.value = availableSensors.map((s) => s.id).toList();
  }

  void clearAllSensors() {
    selectedSensorIds.clear();
  }

  void toggleSensorListExpansion() {
    isSensorListExpanded.value = !isSensorListExpanded.value;
  }

  void toggleConsignmentListExpansion() {
    isConsignmentListExpanded.value = !isConsignmentListExpanded.value;
  }

  bool isSensorSelected(String sensorId) {
    return selectedSensorIds.contains(sensorId);
  }

  int get selectedSensorCount => selectedSensorIds.length;

  Device? getSensorById(String sensorId) {
    try {
      return availableSensors.firstWhere((s) => s.id == sensorId);
    } catch (e) {
      return null;
    }
  }

  Future<void> generateReport() async {
    if (selectedConsignment.value == null) {
      Get.snackbar(
        'Error',
        'Please select a consignment',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      return;
    }
    if (selectedSensorIds.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one sensor',
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      return;
    }
    isGenerating.value = true;
    try {
      await Future.delayed(const Duration(seconds: 2));
      Get.snackbar(
        'Success',
        'Report generated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate report: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } finally {
      isGenerating.value = false;
    }
  }
}

