class Device {
  final String id;
  final String macAddress;
  final int sensorNumber;
  final String? name;
  final bool isConnected;
  final int createdAt;

  Device({
    required this.id,
    required this.macAddress,
    required this.sensorNumber,
    this.name,
    this.isConnected = false,
    required this.createdAt,
  });

  String get displayName => name ?? 'Sensor #$sensorNumber';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'macAddress': macAddress,
      'sensorNumber': sensorNumber,
      'name': name,
      'isConnected': isConnected ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] as String,
      macAddress: map['macAddress'] as String,
      sensorNumber: map['sensorNumber'] as int,
      name: map['name'] as String?,
      isConnected: (map['isConnected'] as int?) == 1,
      createdAt: map['createdAt'] as int,
    );
  }

  Device copyWith({
    String? id,
    String? macAddress,
    int? sensorNumber,
    String? name,
    bool? isConnected,
    int? createdAt,
  }) {
    return Device(
      id: id ?? this.id,
      macAddress: macAddress ?? this.macAddress,
      sensorNumber: sensorNumber ?? this.sensorNumber,
      name: name ?? this.name,
      isConnected: isConnected ?? this.isConnected,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
