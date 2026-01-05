import 'sensor_reading.dart';

class BleData {
  final String id;
  final String deviceId;
  final String deviceName;
  final String rawData;
  final List<int> rawBytes;
  final DateTime timestamp;
  final SensorReading? parsedReading;

  BleData({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.rawData,
    required this.rawBytes,
    required this.timestamp,
    this.parsedReading,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'rawData': rawData,
      'rawBytes': rawBytes,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'parsedReading': parsedReading?.toMap(),
    };
  }

  factory BleData.fromMap(Map<String, dynamic> map) {
    return BleData(
      id: map['id'] as String,
      deviceId: map['deviceId'] as String,
      deviceName: map['deviceName'] as String,
      rawData: map['rawData'] as String,
      rawBytes: List<int>.from(map['rawBytes'] as List),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      parsedReading: map['parsedReading'] != null
          ? SensorReading.fromMap(map['parsedReading'] as Map<String, dynamic>)
          : null,
    );
  }
}

