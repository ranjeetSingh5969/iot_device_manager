import 'package:get/get.dart';
import '../models/device.dart';
import '../models/ble_device.dart';
import '../services/database_service.dart';
import '../controllers/ble_controller.dart';
import '../routes/app_routes.dart';
import '../utils/snackbar_helper.dart';

enum DeviceTab {
  onboarded,
  nearby,
}

class NewDeviceController extends GetxController {
  final Rx<DeviceTab> selectedTab = DeviceTab.onboarded.obs;
  final RxList<Device> onboardedDevices = <Device>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadOnboardedDevices();
    if (selectedTab.value == DeviceTab.nearby) {
      startScan();
    }
  }

  void switchTab(DeviceTab tab) {
    selectedTab.value = tab;
    if (tab == DeviceTab.nearby) {
      startScan();
    }
  }

  Future<void> loadOnboardedDevices() async {
    isLoading.value = true;
    try {
      final db = Get.find<DatabaseService>();
      final devices = await db.getDevices();
      onboardedDevices.value = devices;
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }

  void startScan() {
    final bleController = Get.find<BleController>();
    bleController.startScan();
  }

  Future<void> connectToDevice(Device device) async {
    try {
      final bleController = Get.find<BleController>();
      if (bleController.isConnected) {
        final connectedMac = bleController.connectedDevice.value?.macAddress.toUpperCase();
        if (connectedMac == device.macAddress.toUpperCase()) {
          SnackbarHelper.showInfo('Device is already connected', title: 'Already Connected');
          return;
        }
        await bleController.disconnect();
      }
      SnackbarHelper.showInfo('Scanning for ${device.displayName}...', title: 'Scanning');
      await bleController.startScan();
      await Future.delayed(const Duration(seconds: 3));
      BleDevice? matchingDevice;
      try {
        matchingDevice = bleController.discoveredDevices.firstWhere(
          (d) => d.macAddress.toUpperCase() == device.macAddress.toUpperCase(),
        );
      } catch (e) {
        matchingDevice = null;
      }
      if (matchingDevice == null || matchingDevice.bluetoothDevice == null) {
        SnackbarHelper.showError('Please make sure the device is nearby and try again', title: 'Device Not Found');
        return;
      }
      SnackbarHelper.showInfo('Connecting to ${device.displayName}...', title: 'Connecting');
      await bleController.connect(matchingDevice);
      
      // Wait a bit for state to propagate
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Check connection state after delay
      final currentState = bleController.connectionState.value;
      final currentDevice = bleController.connectedDevice.value;
      
      if (currentState == BleConnectionState.ready && 
          currentDevice?.macAddress.toUpperCase() == device.macAddress.toUpperCase()) {
        SnackbarHelper.showSuccess('Successfully connected to ${device.displayName}', title: 'Connected');
        // No need to reload devices - connection state is already updated and UI will react
      } else {
        SnackbarHelper.showError(bleController.errorMessage.value ?? 'Failed to connect to device', title: 'Connection Failed');
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to connect to device: ${e.toString()}', title: 'Error');
    }
  }

  Future<void> connectToNearbyDevice(BleDevice bleDevice) async {
    try {
      final bleController = Get.find<BleController>();
      if (bleController.isConnected) {
        final connectedMac = bleController.connectedDevice.value?.macAddress.toUpperCase();
        if (connectedMac == bleDevice.macAddress.toUpperCase()) {
          SnackbarHelper.showInfo('Device is already connected', title: 'Already Connected');
          return;
        }
        await bleController.disconnect();
      }
      SnackbarHelper.showInfo('Connecting to ${bleDevice.name}...', title: 'Connecting');
      await bleController.connect(bleDevice);
      
      // Wait a bit for state to propagate
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Check connection state after delay
      final currentState = bleController.connectionState.value;
      final currentDevice = bleController.connectedDevice.value;
      
      if (currentState == BleConnectionState.ready && 
          currentDevice?.macAddress.toUpperCase() == bleDevice.macAddress.toUpperCase()) {
        final db = Get.find<DatabaseService>();
        final existing = await db.getDeviceByMac(bleDevice.macAddress);
        if (existing == null) {
          final device = Device(
            id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
            macAddress: bleDevice.macAddress.toUpperCase(),
            sensorNumber: 1,
            name: bleDevice.name,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          );
          await db.insertDevice(device);
        }
        SnackbarHelper.showSuccess('Successfully connected to ${bleDevice.name}', title: 'Connected');
        // Reload devices to show the newly added device in onboarded list
        await loadOnboardedDevices();
      } else {
        SnackbarHelper.showError(bleController.errorMessage.value ?? 'Failed to connect to device', title: 'Connection Failed');
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to connect to device: ${e.toString()}', title: 'Error');
    }
  }
}

