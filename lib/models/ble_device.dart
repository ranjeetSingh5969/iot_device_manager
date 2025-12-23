import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDevice {
  final String id;
  final String name;
  final String macAddress;
  final int rssi;
  final BluetoothDevice? bluetoothDevice;

  BleDevice({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.rssi,
    this.bluetoothDevice,
  });

  String get signalStrength {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    return 'Weak';
  }

  int get signalBars {
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    return 1;
  }
}
