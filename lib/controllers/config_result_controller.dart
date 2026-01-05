import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/ble_data.dart';
import '../models/device.dart';
import '../models/sensor_reading.dart';
import '../services/database_service.dart';
import '../controllers/ble_controller.dart';
import '../controllers/new_device_controller.dart';
import '../utils/snackbar_helper.dart';

class ConfigResultController extends GetxController {
  final BleController _bleController = Get.find<BleController>();
  final DatabaseService _databaseService = Get.find<DatabaseService>();
  NewDeviceController? _newDeviceController;
  
  final RxList<SensorReading> dataEntries = <SensorReading>[].obs;
  final RxString status = 'Listening'.obs;
  final Rx<DateTime?> lastUpdateTime = Rxn<DateTime>();
  final Rx<Device?> onboardedDevice = Rxn<Device>();
  final RxBool isOnboarding = false.obs;
  
  StreamSubscription<Map<String, dynamic>>? _dataSubscription;
  Timer? _readTimer;

  @override
  void onInit() {
    super.onInit();
    try {
      _newDeviceController = Get.find<NewDeviceController>();
    } catch (e) {
      debugPrint('NewDeviceController not available: $e');
    }
    checkAndOnboardDevice();
    subscribeToData();
    tryReadData();
  }

  @override
  void onClose() {
    _dataSubscription?.cancel();
    _readTimer?.cancel();
    super.onClose();
  }

  Future<void> checkAndOnboardDevice() async {
    final connectedDevice = _bleController.connectedDevice.value;
    if (connectedDevice == null) {
      debugPrint('ConfigResultController: No connected device found');
      return;
    }

    debugPrint('ConfigResultController: Checking device: ${connectedDevice.macAddress}');

    try {
      final existingDevice = await _databaseService.getDeviceByMac(connectedDevice.macAddress);
      
      if (existingDevice == null) {
        debugPrint('ConfigResultController: Device not onboarded, onboarding now...');
        isOnboarding.value = true;
        
        final allDevices = await _databaseService.getDevices();
        final maxSensorNumber = allDevices.isEmpty 
            ? 1 
            : allDevices.map((d) => d.sensorNumber).reduce((a, b) => a > b ? a : b) + 1;
        
        final device = Device(
          id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
          macAddress: connectedDevice.macAddress.toUpperCase(),
          sensorNumber: maxSensorNumber,
          name: connectedDevice.name.isNotEmpty ? connectedDevice.name : 'Device ${connectedDevice.macAddress.substring(connectedDevice.macAddress.length - 4)}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        
        await _databaseService.insertDevice(device);
        onboardedDevice.value = device;
        isOnboarding.value = false;
        
        debugPrint('ConfigResultController: Device onboarded successfully: ${device.macAddress}');
        
        if (_newDeviceController != null) {
          await _newDeviceController!.loadOnboardedDevices();
        }
        
        SnackbarHelper.showSuccess(
          'Device ${device.displayName} has been onboarded',
          title: 'Device Onboarded',
        );
      } else {
        onboardedDevice.value = existingDevice;
        debugPrint('ConfigResultController: Device already onboarded: ${existingDevice.macAddress}');
      }
    } catch (e, stackTrace) {
      debugPrint('ConfigResultController: Error checking/onboarding device: $e');
      debugPrint('ConfigResultController: Stack trace: $stackTrace');
      isOnboarding.value = false;
      
      SnackbarHelper.showError(
        'Failed to onboard device: ${e.toString()}',
        title: 'Onboarding Error',
      );
    }
  }

  Future<void> tryReadData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      final data = await _bleController.readCharacteristic();
      if (data != null && data.isNotEmpty) {
        final isValid = isValidSensorData(data);
        if (isValid) {
          addDataEntry(data);
          return;
        } else {
          debugPrint('ConfigResultController: Read invalid data, will continue listening: $data');
        }
      }
    } catch (e) {
      debugPrint('ConfigResultController: Failed to read characteristic: $e');
    }
    
    int readAttempts = 0;
    _readTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      readAttempts++;
      if (readAttempts > 10) {
        timer.cancel();
        if (dataEntries.isEmpty) {
          status.value = 'Timeout';
        }
        return;
      }
      
      try {
        final data = await _bleController.readCharacteristic();
        if (data != null && data.isNotEmpty) {
          final isValid = isValidSensorData(data);
          if (isValid) {
            addDataEntry(data);
          } else {
            debugPrint('ConfigResultController: Read invalid data, continuing to listen: $data');
          }
        }
      } catch (e) {
        debugPrint('ConfigResultController: Periodic read attempt $readAttempts failed: $e');
      }
    });
  }

  int? extractSerialNumber(String data) {
    try {
      final regex = RegExp(r's\.no\s*:\s*(\d+)', caseSensitive: false);
      final match = regex.firstMatch(data);
      if (match != null && match.groupCount >= 1) {
        return int.tryParse(match.group(1) ?? '');
      }
    } catch (e) {
      debugPrint('Error extracting serial number: $e');
    }
    return null;
  }

  bool hasDuplicateSerialNumber(int serialNumber) {
    return dataEntries.any((entry) {
      // Check if entry has the same timestamp (which would indicate same serial number)
      // This is a simplified check - you might want to store serial number in SensorReading
      return false; // For now, allow all entries
    });
  }

  SensorReading? parseSensorDataFromString(String data, String deviceId) {
    try {
      final tempRegex = RegExp(r'temp\s*:\s*([\d.]+)', caseSensitive: false);
      final tempMatch = tempRegex.firstMatch(data);
      
      final timeRegex = RegExp(r'time\s*:\s*(\d{2}:\d{2}:\d{2})', caseSensitive: false);
      final dateRegex = RegExp(r'date\s*:\s*(\d{2}/\d{2}/\d{2})', caseSensitive: false);
      final timeMatch = timeRegex.firstMatch(data);
      final dateMatch = dateRegex.firstMatch(data);
      
      if (tempMatch != null) {
        final temperature = double.tryParse(tempMatch.group(1) ?? '0') ?? 0.0;
        int timestamp = DateTime.now().millisecondsSinceEpoch;
        
        if (dateMatch != null && timeMatch != null) {
          try {
            final dateStr = dateMatch.group(1)!;
            final timeStr = timeMatch.group(1)!;
            final dateParts = dateStr.split('/');
            final timeParts = timeStr.split(':');
            if (dateParts.length == 3 && timeParts.length == 3) {
              final year = 2000 + int.parse(dateParts[2]);
              final month = int.parse(dateParts[1]);
              final day = int.parse(dateParts[0]);
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              final second = int.parse(timeParts[2]);
              final dateTime = DateTime(year, month, day, hour, minute, second);
              timestamp = dateTime.millisecondsSinceEpoch;
            }
          } catch (e) {
            debugPrint('Error parsing date/time: $e');
          }
        }
        
        final humidityRegex = RegExp(r'(?:hum|humidity)\s*:\s*([\d.]+)', caseSensitive: false);
        final humidityMatch = humidityRegex.firstMatch(data);
        final humidity = humidityMatch != null
            ? double.tryParse(humidityMatch.group(1) ?? '0') ?? 0.0
            : 0.0;
        
        return SensorReading(
          deviceId: deviceId,
          temperature: temperature,
          humidity: humidity,
          timestamp: timestamp,
        );
      }
    } catch (e) {
      debugPrint('Error parsing sensor data: $e');
    }
    return null;
  }

  void addDataEntry(String data, {BleData? bleData}) async {
    final serialNumber = extractSerialNumber(data);
    
    if (serialNumber != null) {
      if (hasDuplicateSerialNumber(serialNumber)) {
        debugPrint('ConfigResultController: Duplicate serial number $serialNumber, skipping entry');
        return;
      }
    }
    
    final deviceId = onboardedDevice.value?.id ?? '';
    if (deviceId.isEmpty) {
      await checkAndOnboardDevice();
      if (onboardedDevice.value == null) {
        debugPrint('ConfigResultController: Cannot add entry without device');
        return;
      }
    }
    
    final sensorReading = parseSensorDataFromString(data, onboardedDevice.value!.id);
    if (sensorReading != null) {
      // Insert at the beginning to show newest first
      dataEntries.insert(0, sensorReading);
      // Sort by timestamp descending (newest first)
      dataEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      status.value = 'Data Received';
      lastUpdateTime.value = DateTime.now();
      
      try {
        await _databaseService.insertReading(sensorReading);
        debugPrint('ConfigResultController: Saved sensor reading for device ${onboardedDevice.value!.id}');
      } catch (e) {
        debugPrint('ConfigResultController: Error saving sensor reading: $e');
      }
      
      _readTimer?.cancel();
    }
  }

  void subscribeToData() {
    _dataSubscription = _bleController.onDataReceived.listen(
      (data) {
        final rawData = data['rawData'] as String? ?? '';
        final isValid = data['isValid'] as bool? ?? false;
        final bleData = data['bleData'] as BleData?;
        
        debugPrint('ConfigResultController: Received data: $rawData (isValid: $isValid)');
        
        if (rawData.isNotEmpty && isValid) {
          addDataEntry(rawData, bleData: bleData);
        } else if (rawData.isNotEmpty && !isValid) {
          debugPrint('ConfigResultController: Ignoring invalid data: $rawData');
        }
      },
      onError: (error) {
        debugPrint('ConfigResultController: Stream error: $error');
        status.value = 'Error';
        lastUpdateTime.value = DateTime.now();
      },
      onDone: () {
        debugPrint('ConfigResultController: Stream closed');
      },
    );
    
    if (!_bleController.isConnected) {
      status.value = 'Error';
    }
  }

  bool isValidSensorData(String data) {
    final trimmedData = data.trim().toLowerCase();
    
    if (trimmedData.contains('config done') || 
        (trimmedData.contains('config') && trimmedData.length < 20)) {
      return false;
    }
    
    final hasSerialNumber = trimmedData.contains('s.no') || trimmedData.contains('sno');
    final hasTemperature = trimmedData.contains('temp');
    final hasDeviceId = trimmedData.contains('device id') || trimmedData.contains('deviceid');
    final hasMacId = trimmedData.contains('mac id') || trimmedData.contains('macid');
    
    return hasSerialNumber && hasTemperature && hasDeviceId && hasMacId;
  }

  Future<void> exportToCsv() async {
    if (dataEntries.isEmpty) {
      SnackbarHelper.showError('No data to export');
      return;
    }
    // TODO: Implement CSV export
    SnackbarHelper.showSuccess('CSV export functionality coming soon');
  }

  Future<void> downloadData() async {
    if (onboardedDevice.value == null) {
      SnackbarHelper.showError('No device selected');
      return;
    }
    // TODO: Implement download data functionality
    SnackbarHelper.showSuccess('Download data functionality coming soon');
  }

  Future<void> uploadData() async {
    if (onboardedDevice.value == null) {
      SnackbarHelper.showError('No device selected');
      return;
    }
    // TODO: Implement upload data functionality
    SnackbarHelper.showSuccess('Upload data functionality coming soon');
  }
}

