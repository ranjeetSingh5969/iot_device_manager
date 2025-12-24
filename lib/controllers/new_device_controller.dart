import 'package:get/get.dart';
import '../models/device.dart';
import '../models/ble_device.dart';
import '../services/database_service.dart';
import '../controllers/ble_controller.dart';
import '../routes/app_routes.dart';

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
      Get.back(result: device);
      Get.toNamed(AppRoutes.dashboard, arguments: device);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to connect to device: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> connectToNearbyDevice(BleDevice bleDevice) async {
    try {
      final bleController = Get.find<BleController>();
      await bleController.connect(bleDevice);
      final db = Get.find<DatabaseService>();
      final existing = await db.getDeviceByMac(bleDevice.macAddress);
      if (existing != null) {
        Get.back(result: existing);
      } else {
        final device = Device(
          id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
          macAddress: bleDevice.macAddress.toUpperCase(),
          sensorNumber: 1,
          name: bleDevice.name,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        await db.insertDevice(device);
        Get.back(result: device);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to connect to device: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

