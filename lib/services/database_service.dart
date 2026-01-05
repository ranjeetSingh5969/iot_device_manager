import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/device.dart';
import '../models/sensor_reading.dart';

class DatabaseService {
  static Database? _database;

  Future<void> init() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'iot_device_manager.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE devices (
            id TEXT PRIMARY KEY,
            macAddress TEXT NOT NULL UNIQUE,
            sensorNumber INTEGER NOT NULL,
            name TEXT,
            isConnected INTEGER DEFAULT 0,
            createdAt INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE sensor_readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deviceId TEXT NOT NULL,
            temperature REAL NOT NULL,
            humidity REAL NOT NULL,
            timestamp INTEGER NOT NULL,
            FOREIGN KEY (deviceId) REFERENCES devices(id)
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_readings_device ON sensor_readings(deviceId)
        ''');

        await db.execute('''
          CREATE INDEX idx_readings_timestamp ON sensor_readings(timestamp)
        ''');

        await db.execute('''
          CREATE TABLE trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startLocation TEXT NOT NULL,
            endLocation TEXT NOT NULL,
            transportMode TEXT NOT NULL,
            startDate INTEGER NOT NULL,
            tempLow REAL NOT NULL,
            tempHigh REAL NOT NULL,
            humidityLow REAL NOT NULL,
            humidityHigh REAL NOT NULL,
            clientName TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE trip_sensors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tripId INTEGER NOT NULL,
            deviceId TEXT NOT NULL,
            FOREIGN KEY (tripId) REFERENCES trips(id),
            FOREIGN KEY (deviceId) REFERENCES devices(id)
          )
        ''');
      },
    );
  }

  Database get db {
    if (_database == null) {
      throw Exception('Database not initialized');
    }
    return _database!;
  }

  // Device operations
  Future<List<Device>> getDevices() async {
    final maps = await db.query('devices', orderBy: 'createdAt DESC');
    return maps.map((map) => Device.fromMap(map)).toList();
  }

  Future<Device?> getDeviceById(String id) async {
    final maps = await db.query('devices', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Device.fromMap(maps.first);
  }

  Future<Device?> getDeviceByMac(String macAddress) async {
    final maps = await db.query(
      'devices',
      where: 'macAddress = ?',
      whereArgs: [macAddress.toUpperCase()],
    );
    if (maps.isEmpty) return null;
    return Device.fromMap(maps.first);
  }

  Future<void> insertDevice(Device device) async {
    await db.insert(
      'devices',
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDevice(Device device) async {
    await db.update(
      'devices',
      device.toMap(),
      where: 'id = ?',
      whereArgs: [device.id],
    );
  }

  Future<void> deleteDevice(String id) async {
    await db.delete('devices', where: 'id = ?', whereArgs: [id]);
    await db.delete('sensor_readings', where: 'deviceId = ?', whereArgs: [id]);
  }

  // Sensor reading operations
  Future<List<SensorReading>> getReadingsForDevice(
    String deviceId, {
    int? limit,
    int? since,
  }) async {
    String? where = 'deviceId = ?';
    List<dynamic> whereArgs = [deviceId];

    if (since != null) {
      where = 'deviceId = ? AND timestamp >= ?';
      whereArgs = [deviceId, since];
    }

    final maps = await db.query(
      'sensor_readings',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => SensorReading.fromMap(map)).toList();
  }

  Future<SensorReading?> getLatestReading(String deviceId) async {
    final readings = await getReadingsForDevice(deviceId, limit: 1);
    return readings.isNotEmpty ? readings.first : null;
  }

  /// Check if a reading with the same deviceId and timestamp already exists
  Future<bool> readingExists(String deviceId, int timestamp) async {
    final result = await db.query(
      'sensor_readings',
      where: 'deviceId = ? AND timestamp = ?',
      whereArgs: [deviceId, timestamp],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> insertReading(SensorReading reading) async {
    // Check if a reading with the same deviceId and timestamp already exists
    final exists = await readingExists(reading.deviceId, reading.timestamp);
    if (exists) {
      // Skip inserting duplicate
      return;
    }
    await db.insert('sensor_readings', reading.toMap());
  }

  Future<void> insertReadings(List<SensorReading> readings) async {
    if (readings.isEmpty) return;
    
    final batch = db.batch();
    int insertedCount = 0;
    int skippedCount = 0;
    
    // Get all existing timestamps for the devices in this batch to check duplicates efficiently
    final deviceIds = readings.map((r) => r.deviceId).toSet().toList();
    final existingReadings = <String, Set<int>>{};
    
    for (final deviceId in deviceIds) {
      final deviceReadings = await db.query(
        'sensor_readings',
        columns: ['timestamp'],
        where: 'deviceId = ?',
        whereArgs: [deviceId],
      );
      existingReadings[deviceId] = deviceReadings
          .map((r) => r['timestamp'] as int)
          .toSet();
    }
    
    for (final reading in readings) {
      final deviceTimestamps = existingReadings[reading.deviceId] ?? <int>{};
      if (deviceTimestamps.contains(reading.timestamp)) {
        skippedCount++;
        continue;
      }
      
      batch.insert('sensor_readings', reading.toMap());
      deviceTimestamps.add(reading.timestamp);
      insertedCount++;
    }
    
    if (insertedCount > 0) {
      await batch.commit(noResult: true);
    }
    
    if (skippedCount > 0) {
      debugPrint('DatabaseService: Skipped $skippedCount duplicate readings (same timestamp)');
    }
  }

  Future<int> getReadingCount(String deviceId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sensor_readings WHERE deviceId = ?',
      [deviceId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearReadings(String deviceId) async {
    await db.delete('sensor_readings', where: 'deviceId = ?', whereArgs: [deviceId]);
  }

  // Trip operations
  Future<List<Map<String, dynamic>>> getAllTrips() async {
    return await db.query('trips', orderBy: 'id DESC');
  }

  Future<int> insertTrip({
    required String startLocation,
    required String endLocation,
    required String transportMode,
    required int startDate,
    required double tempLow,
    required double tempHigh,
    required double humidityLow,
    required double humidityHigh,
    required String clientName,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.insert(
      'trips',
      {
        'startLocation': startLocation,
        'endLocation': endLocation,
        'transportMode': transportMode,
        'startDate': startDate,
        'tempLow': tempLow,
        'tempHigh': tempHigh,
        'humidityLow': humidityLow,
        'humidityHigh': humidityHigh,
        'clientName': clientName,
        'createdAt': now,
      },
    );
  }

  Future<void> insertTripSensor({
    required int tripId,
    required String deviceId,
  }) async {
    await db.insert(
      'trip_sensors',
      {
        'tripId': tripId,
        'deviceId': deviceId,
      },
    );
  }

  Future<void> insertTripSensors({
    required int tripId,
    required List<String> deviceIds,
  }) async {
    final batch = db.batch();
    for (final deviceId in deviceIds) {
      batch.insert(
        'trip_sensors',
        {
          'tripId': tripId,
          'deviceId': deviceId,
        },
      );
    }
    await batch.commit(noResult: true);
  }

  // Alias for getDevices to match controller expectations
  Future<List<Device>> getAllDevices() async {
    return await getDevices();
  }
}
