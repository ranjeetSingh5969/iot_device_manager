import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../models/consignment.dart';
import '../../models/device.dart';
import '../../models/trip_report.dart';
import '../../models/sensor_reading.dart';
import '../../services/database_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/snackbar_helper.dart';

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
      SnackbarHelper.showError('Please select a consignment');
      return;
    }
    if (selectedSensorIds.isEmpty) {
      SnackbarHelper.showError('Please select at least one sensor');
      return;
    }
    
    isGenerating.value = true;
    try {
      final db = Get.find<DatabaseService>();
      final consignment = selectedConsignment.value!;
      
      // Get trip data
      final tripData = await db.getTripById(consignment.id);
      if (tripData == null) {
        SnackbarHelper.showError('Trip data not found');
        return;
      }
      
      // Get selected sensors
      final selectedSensors = availableSensors
          .where((sensor) => selectedSensorIds.contains(sensor.id))
          .toList();
      
      // Get trip start date
      final startDate = consignment.startDate ?? DateTime.now();
      final startTimestamp = startDate.millisecondsSinceEpoch;
      
      // Calculate end date (use current time or last reading time)
      int? endTimestamp;
      DateTime? endDate;
      
      // Get readings for selected sensors within trip time period
      final allReadings = <SensorReading>[];
      for (final sensorId in selectedSensorIds) {
        final readings = await db.getReadingsForDevice(
          sensorId,
          since: startTimestamp,
        );
        // Filter readings to only include those within trip period
        // (readings after start date)
        final tripReadings = readings.where((reading) {
          return reading.timestamp >= startTimestamp;
        }).toList();
        allReadings.addAll(tripReadings);
      }
      
      // Sort readings by timestamp
      allReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Calculate end date from readings
      if (allReadings.isNotEmpty) {
        final lastReading = allReadings.last;
        endTimestamp = lastReading.timestamp;
        endDate = DateTime.fromMillisecondsSinceEpoch(endTimestamp);
      } else {
        endDate = DateTime.now();
        endTimestamp = endDate.millisecondsSinceEpoch;
      }
      
      debugPrint('ReportGenerator: Found ${allReadings.length} readings for trip');
      if (allReadings.isNotEmpty) {
        final firstReading = allReadings.first;
        final lastReading = allReadings.last;
        debugPrint('ReportGenerator: First reading at ${DateTime.fromMillisecondsSinceEpoch(firstReading.timestamp)}');
        debugPrint('ReportGenerator: Last reading at ${DateTime.fromMillisecondsSinceEpoch(lastReading.timestamp)}');
      }
      
      // Get trip limits
      final tempLow = (tripData['tempLow'] as num).toDouble();
      final tempHigh = (tripData['tempHigh'] as num).toDouble();
      final humidityLow = (tripData['humidityLow'] as num).toDouble();
      final humidityHigh = (tripData['humidityHigh'] as num).toDouble();
      
      // Calculate statistics
      final stats = _calculateStatistics(
        readings: allReadings,
        tempLow: tempLow,
        tempHigh: tempHigh,
        humidityLow: humidityLow,
        humidityHigh: humidityHigh,
        sensors: selectedSensors,
      );
      
      // Create trip report
      final report = TripReport(
        tripId: consignment.id,
        startLocation: consignment.startLocation,
        endLocation: consignment.endLocation,
        startDate: startDate,
        endDate: endDate,
        clientName: tripData['clientName'] as String?,
        tempLow: tempLow,
        tempHigh: tempHigh,
        humidityLow: humidityLow,
        humidityHigh: humidityHigh,
        sensors: selectedSensors,
        readings: allReadings,
        avgTemperature: stats['avgTemp'] as double,
        avgHumidity: stats['avgHum'] as double,
        tempBreachCount: stats['tempBreaches'] as int,
        humBreachCount: stats['humBreaches'] as int,
        outOfLimitDuration: stats['outOfLimitDuration'] as Duration,
        breaches: stats['breaches'] as List<BreachRecord>,
      );
      
      // Navigate to report screen
      Get.toNamed(AppRoutes.tripReport, arguments: report);
      
      SnackbarHelper.showSuccess('Report generated successfully');
    } catch (e, stackTrace) {
      debugPrint('Error generating report: $e');
      debugPrint('Stack trace: $stackTrace');
      SnackbarHelper.showError('Failed to generate report: ${e.toString()}');
    } finally {
      isGenerating.value = false;
    }
  }
  
  Map<String, dynamic> _calculateStatistics({
    required List<SensorReading> readings,
    required double tempLow,
    required double tempHigh,
    required double humidityLow,
    required double humidityHigh,
    required List<Device> sensors,
  }) {
    if (readings.isEmpty) {
      return {
        'avgTemp': 0.0,
        'avgHum': 0.0,
        'tempBreaches': 0,
        'humBreaches': 0,
        'outOfLimitDuration': const Duration(seconds: 0),
        'breaches': <BreachRecord>[],
      };
    }
    
    double totalTemp = 0.0;
    double totalHum = 0.0;
    int tempBreaches = 0;
    int humBreaches = 0;
    final breaches = <BreachRecord>[];
    final sensorMap = {for (var s in sensors) s.id: s};
    
    // Track out of limit periods
    DateTime? outOfLimitStart;
    Duration totalOutOfLimit = const Duration(seconds: 0);
    
    for (final reading in readings) {
      totalTemp += reading.temperature;
      totalHum += reading.humidity;
      
      final sensor = sensorMap[reading.deviceId];
      final sensorName = sensor?.displayName ?? reading.deviceId;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(reading.timestamp);
      
      bool isOutOfLimit = false;
      
      // Check temperature breaches
      if (reading.temperature < tempLow) {
        tempBreaches++;
        breaches.add(BreachRecord(
          timestamp: timestamp,
          sensorName: sensorName,
          sensorId: reading.deviceId,
          type: 'TEMP',
          value: reading.temperature,
          breachType: 'LOW',
        ));
        isOutOfLimit = true;
      } else if (reading.temperature > tempHigh) {
        tempBreaches++;
        breaches.add(BreachRecord(
          timestamp: timestamp,
          sensorName: sensorName,
          sensorId: reading.deviceId,
          type: 'TEMP',
          value: reading.temperature,
          breachType: 'HIGH',
        ));
        isOutOfLimit = true;
      }
      
      // Check humidity breaches
      if (reading.humidity < humidityLow) {
        humBreaches++;
        breaches.add(BreachRecord(
          timestamp: timestamp,
          sensorName: sensorName,
          sensorId: reading.deviceId,
          type: 'HUM',
          value: reading.humidity,
          breachType: 'LOW',
        ));
        isOutOfLimit = true;
      } else if (reading.humidity > humidityHigh) {
        humBreaches++;
        breaches.add(BreachRecord(
          timestamp: timestamp,
          sensorName: sensorName,
          sensorId: reading.deviceId,
          type: 'HUM',
          value: reading.humidity,
          breachType: 'HIGH',
        ));
        isOutOfLimit = true;
      }
      
      // Track out of limit duration
      if (isOutOfLimit) {
        if (outOfLimitStart == null) {
          outOfLimitStart = timestamp;
        }
      } else {
        if (outOfLimitStart != null) {
          totalOutOfLimit += timestamp.difference(outOfLimitStart);
          outOfLimitStart = null;
        }
      }
    }
    
    // Handle case where last reading is still out of limit
    if (outOfLimitStart != null && readings.isNotEmpty) {
      final lastTimestamp = DateTime.fromMillisecondsSinceEpoch(
        readings.last.timestamp,
      );
      totalOutOfLimit += lastTimestamp.difference(outOfLimitStart);
    }
    
    // Sort breaches by timestamp
    breaches.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Calculate averages from all readings (same method as dashboard)
    final avgTemp = readings.isEmpty ? 0.0 : totalTemp / readings.length;
    final avgHum = readings.isEmpty ? 0.0 : totalHum / readings.length;
    
    debugPrint('ReportGenerator: Calculated averages - Temp: ${avgTemp.toStringAsFixed(2)}°C, Hum: ${avgHum.toStringAsFixed(2)}%');
    debugPrint('ReportGenerator: From ${readings.length} readings');
    debugPrint('ReportGenerator: Breaches - Temp: $tempBreaches, Hum: $humBreaches');
    
    return {
      'avgTemp': avgTemp,
      'avgHum': avgHum,
      'tempBreaches': tempBreaches,
      'humBreaches': humBreaches,
      'outOfLimitDuration': totalOutOfLimit,
      'breaches': breaches,
    };
  }
}

