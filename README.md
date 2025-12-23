# IoT Device Manager - Flutter

A Flutter app for managing IoT devices via Bluetooth Low Energy (BLE).

## Features

- **BLE Device Scanning**: Discover nearby Bluetooth devices with signal strength indicators
- **Device Connection**: Connect to BLE devices and register them
- **Dashboard**: View real-time temperature and humidity readings
- **Data Sync**: Send "data" command to retrieve sensor readings
- **History**: View historical sensor data
- **SQLite Storage**: Local database for offline data persistence
- **Authentication**: Client ID + password authentication

## Requirements

- Flutter 3.0 or higher
- Android SDK 21+ (Android 5.0+)
- Physical Android device (BLE doesn't work in emulators)

## Getting Started

1. Install Flutter SDK: https://docs.flutter.dev/get-started/install

2. Clone and navigate to the project:
   ```bash
   cd flutter-app
   ```

3. Get dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Building APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/
│   ├── device.dart        # Device model
│   ├── ble_device.dart    # BLE device model
│   └── sensor_reading.dart # Sensor reading model
├── services/
│   ├── auth_service.dart  # Authentication service
│   ├── ble_service.dart   # BLE scanning and connection
│   └── database_service.dart # SQLite database
└── screens/
    ├── login_screen.dart
    ├── device_list_screen.dart
    ├── ble_scan_screen.dart
    ├── dashboard_screen.dart
    ├── data_sync_screen.dart
    ├── history_screen.dart
    └── device_info_screen.dart
```

## BLE Communication Protocol

After connecting to a device:
1. App sends "data" command via write characteristic
2. Device responds with sensor readings
3. App parses and stores readings in local database

Expected data format: `T:25.5,H:60.0` or `temp=25.5;humidity=60.0`

## Demo Mode

Use any client ID and password (4+ characters) to log in.
