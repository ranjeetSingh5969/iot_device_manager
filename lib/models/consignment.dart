class Consignment {
  final int id;
  final String startLocation;
  final String endLocation;
  final DateTime? startDate;
  final String? clientName;

  Consignment({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    this.startDate,
    this.clientName,
  });

  String get displayName => '$id - $startLocation to $endLocation';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'startDate': startDate?.millisecondsSinceEpoch,
      'clientName': clientName,
    };
  }

  factory Consignment.fromMap(Map<String, dynamic> map) {
    return Consignment(
      id: map['id'] as int,
      startLocation: map['startLocation'] as String,
      endLocation: map['endLocation'] as String,
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int)
          : null,
      clientName: map['clientName'] as String?,
    );
  }
}

