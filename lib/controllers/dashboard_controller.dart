import 'package:get/get.dart';
import '../models/device.dart';
import '../services/database_service.dart';
import '../models/sensor_reading.dart';

enum DateRange {
  today,
  week,
  month,
  all,
}

class DashboardController extends GetxController {
  final Rx<DateRange> selectedDateRange = DateRange.week.obs;
  final RxList<Device> selectedDevices = <Device>[].obs;
  final RxList<Device> availableDevices = <Device>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble avgTemperature = 0.0.obs;
  final RxDouble avgHumidity = 0.0.obs;
  final RxList<SensorReading> readings = <SensorReading>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDevices();
  }

  Future<void> loadDevices() async {
    isLoading.value = true;
    try {
      final db = Get.find<DatabaseService>();
      final devices = await db.getDevices();
      availableDevices.value = devices;
      if (devices.isNotEmpty && selectedDevices.isEmpty) {
        selectedDevices.value = [devices.first];
      }
      await loadChartData();
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }

  void setDateRange(DateRange range) {
    selectedDateRange.value = range;
    loadChartData();
  }

  void toggleDevice(Device device) {
    final currentList = List<Device>.from(selectedDevices);
    final deviceIndex = currentList.indexWhere((d) => d.id == device.id);
    if (deviceIndex >= 0) {
      currentList.removeAt(deviceIndex);
    } else {
      currentList.add(device);
    }
    selectedDevices.value = currentList;
    loadChartData();
  }

  Future<void> loadChartData() async {
    if (selectedDevices.isEmpty) {
      readings.value = [];
      avgTemperature.value = 0.0;
      avgHumidity.value = 0.0;
      return;
    }
    isLoading.value = true;
    try {
      final db = Get.find<DatabaseService>();
      final now = DateTime.now();
      int? sinceTimestamp;
      switch (selectedDateRange.value) {
        case DateRange.today:
          sinceTimestamp = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
          break;
        case DateRange.week:
          sinceTimestamp = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
          break;
        case DateRange.month:
          sinceTimestamp = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
          break;
        case DateRange.all:
          sinceTimestamp = null;
          break;
      }
      final allReadings = <SensorReading>[];
      for (final device in selectedDevices) {
        final deviceReadings = await db.getReadingsForDevice(
          device.id,
          since: sinceTimestamp,
        );
        allReadings.addAll(deviceReadings);
      }
      readings.value = allReadings;
      _calculateAverages();
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateAverages() {
    if (readings.isEmpty) {
      avgTemperature.value = 0.0;
      avgHumidity.value = 0.0;
      return;
    }
    double totalTemp = 0;
    double totalHumidity = 0;
    for (final reading in readings) {
      totalTemp += reading.temperature;
      totalHumidity += reading.humidity;
    }
    avgTemperature.value = totalTemp / readings.length;
    avgHumidity.value = totalHumidity / readings.length;
  }
}

