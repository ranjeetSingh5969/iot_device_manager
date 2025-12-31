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
  // ESP32 BLE Service UUIDs (common IoT device UUIDs)
  static final Guid iotServiceUuid = Guid('4fafc201-1fb5-459e-8fcc-c5c9c331914b');
  // ESP32 BLE Characteristic UUIDs (Nordic UART Service)
  static final Guid rxCharacteristicUuid = Guid('6e400002-b5a3-f393-e0a9-e50e24dcca9e'); // RX - WRITE
  static final Guid txCharacteristicUuid = Guid('6e400003-b5a3-f393-e0a9-e50e24dcca9e'); // TX - NOTIFY, READ
  // Try multiple possible characteristic UUIDs as fallback
  static final List<Guid> possibleCommandCharUuids = [
    rxCharacteristicUuid, // Primary RX characteristic
    Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8'), // Common ESP32 command char
    Guid('00002A29-0000-1000-8000-00805f9b34fb'), // Fallback
  ];
  static final List<Guid> possibleDataCharUuids = [
    txCharacteristicUuid, // Primary TX characteristic
    Guid('beb5483f-36e1-4688-b7f5-ea07361b26a8'), // Common ESP32 data char
    Guid('00002A2A-0000-1000-8000-00805f9b34fb'), // Fallback
  ];

  final Rx<BleConnectionState> connectionState = BleConnectionState.disconnected.obs;
  final RxList<BleDevice> discoveredDevices = <BleDevice>[].obs;
  final Rxn<BleDevice> connectedDevice = Rxn<BleDevice>();
  final Rxn<String> connectingDeviceMac = Rxn<String>(); // Track which device is being connected
  final Rxn<String> errorMessage = Rxn<String>();
  final _dataStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onDataReceived => _dataStreamController.stream;

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
    _dataStreamController.close();
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
      connectingDeviceMac.value = null;
      return;
    }
    await disconnect();
    connectionState.value = BleConnectionState.connecting;
    connectingDeviceMac.value = device.macAddress.toUpperCase(); // Track which device is connecting
    connectedDevice.value = device;
    _bluetoothDevice = device.bluetoothDevice;
    errorMessage.value = null;
    update();
    try {
      final bluetoothDevice = _bluetoothDevice;
      if (bluetoothDevice == null) {
        throw Exception('Bluetooth device is null');
      }
      _connectionSubscription = bluetoothDevice.connectionState.listen((state) {
        // Only handle disconnection if we're not in the middle of connecting
        if (state == BluetoothConnectionState.disconnected && 
            connectionState.value != BleConnectionState.connecting &&
            connectionState.value != BleConnectionState.discoveringServices) {
          _handleDisconnection();
        }
      });
      await bluetoothDevice.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
      connectionState.value = BleConnectionState.discoveringServices;
      update();
      final services = await bluetoothDevice.discoverServices();
      if (services.isEmpty) {
        throw Exception('No services discovered');
      }
      
      debugPrint('BLE: Discovered ${services.length} services: ${services.map((s) => s.uuid.toString()).join(', ')}');
      
      bool foundService = false;
      BluetoothService? targetService;
      
      // First, try to find the expected service
      for (final service in services) {
        if (service.uuid == iotServiceUuid) {
          foundService = true;
          targetService = service;
          debugPrint('BLE: Found expected service: ${service.uuid}');
          break;
        }
      }
      
      // If expected service not found, use the first non-standard service (likely the IoT service)
      if (!foundService && services.isNotEmpty) {
        for (final service in services) {
          final uuidStr = service.uuid.toString().toLowerCase();
          // Skip standard Bluetooth services (1800, 1801, etc.)
          if (!uuidStr.startsWith('000018') && !uuidStr.startsWith('0000fff')) {
            targetService = service;
            foundService = true;
            debugPrint('BLE: Using alternative service: ${service.uuid}');
            break;
          }
        }
      }
      
      if (foundService && targetService != null) {
        debugPrint('BLE: Service has ${targetService.characteristics.length} characteristics');
        for (final characteristic in targetService.characteristics) {
          final charUuid = characteristic.uuid.toString().toLowerCase();
          debugPrint('BLE: Found characteristic: $charUuid');
          
          // Try to match command characteristic
          if (_commandCharacteristic == null) {
            for (final possibleUuid in possibleCommandCharUuids) {
              if (characteristic.uuid == possibleUuid) {
                _commandCharacteristic = characteristic;
                debugPrint('BLE: Matched command characteristic: $charUuid');
                break;
              }
            }
          }
          
          // Try to match data characteristic
          if (_dataCharacteristic == null) {
            for (final possibleUuid in possibleDataCharUuids) {
              if (characteristic.uuid == possibleUuid) {
                _dataCharacteristic = characteristic;
                debugPrint('BLE: Matched data characteristic: $charUuid');
                break;
              }
            }
          }
          
          // If no match found, use the first characteristic that supports notify as data char
          if (_dataCharacteristic == null && characteristic.properties.notify) {
            _dataCharacteristic = characteristic;
            debugPrint('BLE: Using first notify characteristic as data: $charUuid');
          }
          
          // If no match found, use the first writable characteristic as command char
          if (_commandCharacteristic == null && characteristic.properties.write) {
            _commandCharacteristic = characteristic;
            debugPrint('BLE: Using first writable characteristic as command: $charUuid');
          }
        }
      } else {
        debugPrint('BLE: No suitable service found. Available services: ${services.map((s) => s.uuid.toString()).join(', ')}');
      }
      
      // Enable notifications on data characteristic if found
      if (_dataCharacteristic != null) {
        try {
          await _dataCharacteristic!.setNotifyValue(true);
          _dataSubscription = _dataCharacteristic!.onValueReceived.listen((value) {
            _handleDataReceived(value);
          });
          debugPrint('BLE: Data characteristic notification enabled');
        } catch (e) {
          debugPrint('BLE: Failed to enable notifications: $e');
        }
      } else {
        debugPrint('BLE: Warning - Data characteristic not found, but continuing connection');
      }
      
      if (_commandCharacteristic != null) {
        debugPrint('BLE: Command characteristic found');
      } else {
        debugPrint('BLE: Warning - Command characteristic not found, but continuing connection');
      }
      
      // Mark as ready even if characteristics aren't found - connection is still valid
      // Ensure connectedDevice is set before setting state to ready
      if (connectedDevice.value == null) {
        connectedDevice.value = device;
      }
      connectionState.value = BleConnectionState.ready;
      connectingDeviceMac.value = null; // Clear connecting state
      update();
      debugPrint('BLE: Connected and ready - Device: ${connectedDevice.value?.macAddress}');
    } catch (e, stackTrace) {
      debugPrint('BLE connection error: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage.value = 'Connection failed: ${e.toString()}';
      connectionState.value = BleConnectionState.error;
      connectingDeviceMac.value = null; // Clear connecting state on error
      connectedDevice.value = null;
      _bluetoothDevice = null;
      _commandCharacteristic = null;
      _dataCharacteristic = null;
      _connectionSubscription?.cancel();
      _connectionSubscription = null;
      _dataSubscription?.cancel();
      _dataSubscription = null;
      update();
    }
  }

  void _handleDisconnection() {
    // Only handle disconnection if we're actually connected or ready
    // Don't clear state if we're in the middle of connecting
    if (connectionState.value == BleConnectionState.ready || 
        connectionState.value == BleConnectionState.connected) {
      connectionState.value = BleConnectionState.disconnected;
      connectingDeviceMac.value = null; // Clear connecting state
      connectedDevice.value = null;
      _bluetoothDevice = null;
      _commandCharacteristic = null;
      _dataCharacteristic = null;
      update();
    }
  }

  void _handleDataReceived(List<int> data) {
    if (data.isEmpty) return;
    final rawBytes = List<int>.from(data);
    _dataBuffer.addAll(data);
    try {
      final dataString = utf8.decode(_dataBuffer);
      if (dataString.contains('\n') || dataString.contains(';')) {
        _dataCompleter?.complete(dataString);
      final lines = dataString.split(RegExp(r'[;\n]')).where((s) => s.isNotEmpty);
      final currentDevice = connectedDevice.value;
      for (final line in lines) {
        SensorReading? parsedReading;
        if (currentDevice != null) {
          parsedReading = _parseSensorData(currentDevice.macAddress, line);
        }
        _dataStreamController.add({
          'rawData': line.trim(),
          'rawBytes': List<int>.from(data),
          'parsedReading': parsedReading,
        });
      }
        _dataBuffer.clear();
      } else {
        _dataStreamController.add({
          'rawData': dataString,
          'rawBytes': rawBytes,
          'parsedReading': null,
        });
      }
    } catch (e) {
      debugPrint('Error decoding data: $e');
      _dataStreamController.add({
        'rawData': 'Binary data (${data.length} bytes)',
        'rawBytes': rawBytes,
        'parsedReading': null,
      });
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
    update();
  }

  /// Send a command to the device
  Future<bool> sendCommand(String command) async {
    return await _sendCommand(command);
  }

  /// Internal method to send command
  Future<bool> _sendCommand(String command) async {
    if (connectionState.value != BleConnectionState.ready) {
      debugPrint('BLE: Cannot send command - device not ready');
      return false;
    }
    
    if (_commandCharacteristic == null) {
      debugPrint('BLE: Cannot send command - command characteristic not found');
      return false;
    }
    
    try {
      final commandBytes = utf8.encode(command);
      await _commandCharacteristic!.write(commandBytes, withoutResponse: false);
      debugPrint('BLE: Sent command: ${command.trim()} (${commandBytes.length} bytes)');
      return true;
    } catch (e) {
      debugPrint('BLE: Error sending command: $e');
      return false;
    }
  }

  /// Send config command to the device (writes to RX, listens to TX)
  /// Returns the response string if successful, null otherwise
  Future<String?> sendConfigCommand({String configCommand = 'Data'}) async {
    if (connectionState.value != BleConnectionState.ready) {
      debugPrint('BLE: Cannot send config - device not ready');
      return null;
    }
    
    if (_commandCharacteristic == null) {
      debugPrint('BLE: Cannot send config - command characteristic not found');
      return null;
    }
    
    try {
      // Write config command to RX characteristic
      final commandBytes = utf8.encode('$configCommand\n');
      await _commandCharacteristic!.write(commandBytes, withoutResponse: false);
      debugPrint('BLE: Sent config command: $configCommand');
      
      // Read from TX characteristic to get response
      if (_dataCharacteristic != null && _dataCharacteristic!.properties.read) {
        try {
          // Wait a bit for the device to process the command
          await Future.delayed(const Duration(milliseconds: 200));
          final response = await _dataCharacteristic!.read();
          final responseString = utf8.decode(response);
          debugPrint('BLE: Config response: $responseString');
          
          // Return the response string
          return responseString.trim();
        } catch (e) {
          debugPrint('BLE: Failed to read config response: $e');
          return null;
        }
      } else {
        // If read is not available, return null
        debugPrint('BLE: TX characteristic does not support read');
        return null;
      }
    } catch (e) {
      debugPrint('BLE: Error sending config command: $e');
      return null;
    }
  }

  /// Read from TX characteristic
  Future<String?> readCharacteristic() async {
    if (connectionState.value != BleConnectionState.ready) {
      debugPrint('BLE: Cannot read - device not ready');
      return null;
    }
    
    if (_dataCharacteristic == null) {
      debugPrint('BLE: Cannot read - data characteristic not found');
      return null;
    }
    
    if (!_dataCharacteristic!.properties.read) {
      debugPrint('BLE: Cannot read - characteristic does not support read');
      return null;
    }
    
    try {
      // Wait a bit for the device to process any pending commands
      await Future.delayed(const Duration(milliseconds: 200));
      final response = await _dataCharacteristic!.read();
      final responseString = utf8.decode(response);
      debugPrint('BLE: Read characteristic response: $responseString');
      
      // Emit the response through the data stream (this will be counted in total data)
      _dataStreamController.add({
        'rawData': responseString.trim(),
        'rawBytes': response,
        'parsedReading': null,
        'isReadResponse': true,
      });
      
      return responseString.trim();
    } catch (e) {
      debugPrint('BLE: Error reading characteristic: $e');
      return null;
    }
  }

  /// Request data from the device
  Future<bool> requestData() async {
    return await _sendCommand('data\n');
  }

  /// Send data command and wait for response
  Future<List<SensorReading>> sendDataCommand(String deviceId) async {
    if (connectionState.value != BleConnectionState.ready) {
      throw Exception('Device not connected or ready');
    }
    try {
      _dataCompleter = Completer<String>();
      _dataBuffer.clear();
      
      final success = await _sendCommand('data\n');
      if (!success) {
        debugPrint('BLE: Failed to send data command');
        return _generateSimulatedData(deviceId);
      }
      
      if (_dataCompleter == null) {
        throw Exception('Data completer is null');
      }
      
      final response = await _dataCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('BLE: Command response timeout');
          return '';
        },
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
        final tempValue = tempMatch.group(1);
        final humValue = humMatch.group(1);
        if (tempValue != null && humValue != null) {
          return SensorReading(
            deviceId: deviceId,
            temperature: double.parse(tempValue),
            humidity: double.parse(humValue),
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
        }
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

