class SensorReading {
  final int? id;
  final String deviceId;
  final double temperature;
  final double humidity;
  final int timestamp;

  SensorReading({
    this.id,
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] as int?,
      deviceId: map['deviceId'] as String,
      temperature: (map['temperature'] as num).toDouble(),
      humidity: (map['humidity'] as num).toDouble(),
      timestamp: map['timestamp'] as int,
    );
  }
}
