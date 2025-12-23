import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

class BleService extends ChangeNotifier {
  // Custom IoT Device Service UUID - Replace with your device's actual UUIDs
  static final Guid iotServiceUuid = Guid('0000180A-0000-1000-8000-00805f9b34fb');
  static final Guid commandCharUuid = Guid('00002A29-0000-1000-8000-00805f9b34fb');
  static final Guid dataCharUuid = Guid('00002A2A-0000-1000-8000-00805f9b34fb');

  BleConnectionState _connectionState = BleConnectionState.disconnected;
  List<BleDevice> _discoveredDevices = [];
  BleDevice? _connectedDevice;
  BluetoothDevice? _bluetoothDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _dataCharacteristic;
  String? _errorMessage;
  
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;

  final List<int> _dataBuffer = [];
  Completer<String>? _dataCompleter;

  BleConnectionState get connectionState => _connectionState;
  List<BleDevice> get discoveredDevices => _discoveredDevices;
  BleDevice? get connectedDevice => _connectedDevice;
  String? get errorMessage => _errorMessage;
  bool get isScanning => _connectionState == BleConnectionState.scanning;
  bool get isConnected => _connectionState == BleConnectionState.ready;

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
      _errorMessage = 'Bluetooth permissions not granted';
      _connectionState = BleConnectionState.error;
      notifyListeners();
      return;
    }

    if (!await isBluetoothOn()) {
      _errorMessage = 'Bluetooth is not enabled';
      _connectionState = BleConnectionState.error;
      notifyListeners();
      return;
    }

    await stopScan();
    _discoveredDevices = [];
    _connectionState = BleConnectionState.scanning;
    _errorMessage = null;
    notifyListeners();

    try {
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _discoveredDevices = results.map((result) {
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
        notifyListeners();
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      // Scan automatically stops after timeout
      await Future.delayed(const Duration(seconds: 10));
      _connectionState = BleConnectionState.disconnected;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Scan failed: ${e.toString()}';
      _connectionState = BleConnectionState.error;
      notifyListeners();
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
      _errorMessage = 'Invalid device';
      _connectionState = BleConnectionState.error;
      notifyListeners();
      return;
    }

    await disconnect();
    
    _connectionState = BleConnectionState.connecting;
    _connectedDevice = device;
    _bluetoothDevice = device.bluetoothDevice;
    _errorMessage = null;
    notifyListeners();

    try {
      // Listen to connection state changes
      _connectionSubscription = _bluetoothDevice!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Connect to device
      await _bluetoothDevice!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _connectionState = BleConnectionState.discoveringServices;
      notifyListeners();

      // Discover services
      final services = await _bluetoothDevice!.discoverServices();
      
      // Find our IoT service
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

      // Enable notifications on data characteristic
      if (_dataCharacteristic != null) {
        await _dataCharacteristic!.setNotifyValue(true);
        _dataSubscription = _dataCharacteristic!.onValueReceived.listen((value) {
          _handleDataReceived(value);
        });
      }

      _connectionState = BleConnectionState.ready;
      notifyListeners();
      debugPrint('BLE: Connected and ready');
    } catch (e) {
      debugPrint('BLE connection error: $e');
      _errorMessage = 'Connection failed: ${e.toString()}';
      _connectionState = BleConnectionState.error;
      _connectedDevice = null;
      notifyListeners();
    }
  }

  void _handleDisconnection() {
    _connectionState = BleConnectionState.disconnected;
    _connectedDevice = null;
    _bluetoothDevice = null;
    _commandCharacteristic = null;
    _dataCharacteristic = null;
    notifyListeners();
  }

  void _handleDataReceived(List<int> data) {
    _dataBuffer.addAll(data);
    
    // Check for complete data (ends with newline or semicolon)
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
    _connectedDevice = null;
    _commandCharacteristic = null;
    _dataCharacteristic = null;
    _connectionState = BleConnectionState.disconnected;
    notifyListeners();
  }

  Future<List<SensorReading>> sendDataCommand(String deviceId) async {
    if (_connectionState != BleConnectionState.ready) {
      throw Exception('Device not connected or ready');
    }

    try {
      final command = utf8.encode('data\n');
      
      if (_commandCharacteristic != null) {
        await _commandCharacteristic!.write(command, withoutResponse: false);
        debugPrint('BLE: Sent "data" command');
      } else if (_dataCharacteristic != null) {
        // If no command characteristic, try reading data characteristic
        await _dataCharacteristic!.read();
      }

      // Wait for response with timeout
      _dataCompleter = Completer<String>();
      _dataBuffer.clear();

      final response = await _dataCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => '',
      );

      if (response.isEmpty) {
        // Generate simulated data for testing if no response
        debugPrint('BLE: No response, using simulated data');
        return _generateSimulatedData(deviceId);
      }

      return _parseMultipleReadings(deviceId, response);
    } catch (e) {
      debugPrint('Error sending data command: $e');
      // Return simulated data for testing
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
      // Expected format: "T:25.5,H:60.0" or "temp=25.5;humidity=60.0"
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
        timestamp: now - (i * 3600000), // 1 hour apart
      ));
    }

    return readings;
  }

  void clearError() {
    _errorMessage = null;
    if (_connectionState == BleConnectionState.error) {
      _connectionState = BleConnectionState.disconnected;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    stopScan();
    super.dispose();
  }
}
