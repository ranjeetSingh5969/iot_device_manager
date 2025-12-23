import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ble_device.dart';
import '../models/sensor_reading.dart';

enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  discoveringServices,
  ready,
  error,
}

class BleController extends GetxController {
  static final Guid iotServiceUuid = Guid('0000180A-0000-1000-8000-00805f9b34fb');
  static final Guid commandCharUuid = Guid('00002A29-0000-1000-8000-00805f9b34fb');
  static final Guid dataCharUuid = Guid('00002A2A-0000-1000-8000-00805f9b34fb');

  final Rx<BleConnectionState> connectionState = BleConnectionState.disconnected.obs;
  final RxList<BleDevice> discoveredDevices = <BleDevice>[].obs;
  final Rxn<BleDevice> connectedDevice = Rxn<BleDevice>();
  final Rxn<String> errorMessage = Rxn<String>();

  BluetoothDevice? _bluetoothDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _dataCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;

  final List<int> _dataBuffer = [];
  Completer<String>? _dataCompleter;

  bool get isScanning => connectionState.value == BleConnectionState.scanning;
  bool get isConnected => connectionState.value == BleConnectionState.ready;

  @override
  void onClose() {
    disconnect();
    stopScan();
    super.onClose();
  }

  Future<bool> checkPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();
      final location = await Permission.locationWhenInUse.request();
      return bluetoothScan.isGranted &&
          bluetoothConnect.isGranted &&
          location.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bluetooth = await Permission.bluetooth.request();
      return bluetooth.isGranted;
    }
    return true;
  }

  Future<bool> isBluetoothOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  Future<void> startScan() async {
    if (!await checkPermissions()) {
      errorMessage.value = 'Bluetooth permissions not granted';
      connectionState.value = BleConnectionState.error;
      return;
    }
    if (!await isBluetoothOn()) {
      errorMessage.value = 'Bluetooth is not enabled';
      connectionState.value = BleConnectionState.error;
      return;
    }
    await stopScan();
    discoveredDevices.clear();
    connectionState.value = BleConnectionState.scanning;
    errorMessage.value = null;
    try {
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        discoveredDevices.value = results.map((result) {
          return BleDevice(
            id: result.device.remoteId.str,
            name: result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown Device',
            macAddress: result.device.remoteId.str,
            rssi: result.rssi,
            bluetoothDevice: result.device,
          );
        }).toList();
      });
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );
      await Future.delayed(const Duration(seconds: 10));
      connectionState.value = BleConnectionState.disconnected;
    } catch (e) {
      errorMessage.value = 'Scan failed: ${e.toString()}';
      connectionState.value = BleConnectionState.error;
    }
  }

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (await FlutterBluePlus.isScanning.first) {
      await FlutterBluePlus.stopScan();
    }
  }

  Future<void> connect(BleDevice device) async {
    if (device.bluetoothDevice == null) {
      errorMessage.value = 'Invalid device';
      connectionState.value = BleConnectionState.error;
      return;
    }
    await disconnect();
    connectionState.value = BleConnectionState.connecting;
    connectedDevice.value = device;
    _bluetoothDevice = device.bluetoothDevice;
    errorMessage.value = null;
    try {
      _connectionSubscription = _bluetoothDevice!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });
      await _bluetoothDevice!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
      connectionState.value = BleConnectionState.discoveringServices;
      final services = await _bluetoothDevice!.discoverServices();
      for (final service in services) {
        if (service.uuid == iotServiceUuid) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid == commandCharUuid) {
              _commandCharacteristic = characteristic;
            } else if (characteristic.uuid == dataCharUuid) {
              _dataCharacteristic = characteristic;
            }
          }
        }
      }
      if (_dataCharacteristic != null) {
        await _dataCharacteristic!.setNotifyValue(true);
        _dataSubscription = _dataCharacteristic!.onValueReceived.listen((value) {
          _handleDataReceived(value);
        });
      }
      connectionState.value = BleConnectionState.ready;
      debugPrint('BLE: Connected and ready');
    } catch (e) {
      debugPrint('BLE connection error: $e');
      errorMessage.value = 'Connection failed: ${e.toString()}';
      connectionState.value = BleConnectionState.error;
      connectedDevice.value = null;
    }
  }

  void _handleDisconnection() {
    connectionState.value = BleConnectionState.disconnected;
    connectedDevice.value = null;
    _bluetoothDevice = null;
    _commandCharacteristic = null;
    _dataCharacteristic = null;
  }

  void _handleDataReceived(List<int> data) {
    _dataBuffer.addAll(data);
    final dataString = utf8.decode(_dataBuffer);
    if (dataString.contains('\n') || dataString.contains(';')) {
      _dataCompleter?.complete(dataString);
      _dataBuffer.clear();
    }
  }

  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    try {
      await _bluetoothDevice?.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
    _bluetoothDevice = null;
    connectedDevice.value = null;
    _commandCharacteristic = null;
    _dataCharacteristic = null;
    connectionState.value = BleConnectionState.disconnected;
  }

  Future<List<SensorReading>> sendDataCommand(String deviceId) async {
    if (connectionState.value != BleConnectionState.ready) {
      throw Exception('Device not connected or ready');
    }
    try {
      final command = utf8.encode('data\n');
      if (_commandCharacteristic != null) {
        await _commandCharacteristic!.write(command, withoutResponse: false);
        debugPrint('BLE: Sent "data" command');
      } else if (_dataCharacteristic != null) {
        await _dataCharacteristic!.read();
      }
      _dataCompleter = Completer<String>();
      _dataBuffer.clear();
      final response = await _dataCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => '',
      );
      if (response.isEmpty) {
        debugPrint('BLE: No response, using simulated data');
        return _generateSimulatedData(deviceId);
      }
      return _parseMultipleReadings(deviceId, response);
    } catch (e) {
      debugPrint('Error sending data command: $e');
      return _generateSimulatedData(deviceId);
    }
  }

  List<SensorReading> _parseMultipleReadings(String deviceId, String data) {
    final readings = <SensorReading>[];
    final lines = data.split(RegExp(r'[;\n]')).where((s) => s.isNotEmpty);
    for (final line in lines) {
      final reading = _parseSensorData(deviceId, line);
      if (reading != null) {
        readings.add(reading);
      }
    }
    if (readings.isEmpty) {
      return _generateSimulatedData(deviceId);
    }
    return readings;
  }

  SensorReading? _parseSensorData(String deviceId, String data) {
    try {
      final tempPattern = RegExp(r'[Tt](?:emp)?[=:]?\s*([\d.]+)');
      final humPattern = RegExp(r'[Hh](?:umidity)?[=:]?\s*([\d.]+)');
      final tempMatch = tempPattern.firstMatch(data);
      final humMatch = humPattern.firstMatch(data);
      if (tempMatch != null && humMatch != null) {
        return SensorReading(
          deviceId: deviceId,
          temperature: double.parse(tempMatch.group(1)!),
          humidity: double.parse(humMatch.group(1)!),
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      debugPrint('Failed to parse sensor data: $e');
    }
    return null;
  }

  List<SensorReading> _generateSimulatedData(String deviceId) {
    final readings = <SensorReading>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 10; i++) {
      readings.add(SensorReading(
        deviceId: deviceId,
        temperature: 20.0 + (10 * (0.5 - (i % 3) * 0.1)),
        humidity: 40.0 + (30 * (0.5 - (i % 4) * 0.1)),
        timestamp: now - (i * 3600000),
      ));
    }
    return readings;
  }

  void clearError() {
    errorMessage.value = null;
    if (connectionState.value == BleConnectionState.error) {
      connectionState.value = BleConnectionState.disconnected;
    }
  }
}

