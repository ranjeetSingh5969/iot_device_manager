import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/ble_device.dart';
import '../services/database_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'ble_controller.dart';

enum OnboardingTab {
  deviceDetails,
  tripDetails,
}

enum TransportMode {
  ship,
  truck,
  plane,
  train,
}

class OnboardingController extends GetxController {
  final Rx<OnboardingTab> selectedTab = OnboardingTab.tripDetails.obs;
  final RxList<Device> availableDevices = <Device>[].obs;
  final RxList<Device> selectedDevices = <Device>[].obs;
  
  final RxString startLocation = ''.obs;
  final RxString endLocation = ''.obs;
  final Rx<TransportMode?> transportMode = Rxn<TransportMode>();
  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final RxString tempLower = ''.obs;
  final RxString tempHigher = ''.obs;
  final RxString humidityLower = ''.obs;
  final RxString humidityHigher = ''.obs;
  final RxString clientName = ''.obs;
  final RxString macAddress = ''.obs;
  final RxString sensorNumber = ''.obs;

  final RxString startLocationError = ''.obs;
  final RxString endLocationError = ''.obs;
  final RxString transportModeError = ''.obs;
  final RxString startDateError = ''.obs;
  final RxString tempLowerError = ''.obs;
  final RxString tempHigherError = ''.obs;
  final RxString humidityLowerError = ''.obs;
  final RxString humidityHigherError = ''.obs;
  final RxString clientNameError = ''.obs;
  final RxString macAddressError = ''.obs;
  final RxString sensorNumberError = ''.obs;
  final RxBool isBluetoothEnabled = false.obs;
  final RxBool isScanningBluetooth = false.obs;
  
  final TextEditingController macAddressController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadDevices();
    startDate.value = DateTime.now();
    selectedTab.value = OnboardingTab.deviceDetails;
    checkBluetoothStatus();
    _listenToBluetoothState();
    macAddressController.addListener(() {
      if (macAddressController.text != macAddress.value) {
        macAddress.value = macAddressController.text;
        macAddressError.value = '';
      }
    });
  }

  @override
  void onClose() {
    macAddressController.dispose();
    super.onClose();
  }

  void _listenToBluetoothState() {
    FlutterBluePlus.adapterState.listen((state) {
      isBluetoothEnabled.value = state == BluetoothAdapterState.on;
    });
  }

  Future<void> checkBluetoothStatus() async {
    try {
      final bleController = Get.find<BleController>();
      isBluetoothEnabled.value = await bleController.isBluetoothOn();
    } catch (e) {
      isBluetoothEnabled.value = false;
    }
  }

  Future<void> toggleBluetooth() async {
    try {
      final bleController = Get.find<BleController>();
      final isOn = await bleController.isBluetoothOn();
      if (!isOn) {
        Get.snackbar(
          'Bluetooth Off',
          'Please turn on Bluetooth from device settings',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }
      isBluetoothEnabled.value = true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to check Bluetooth status: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> scanAndConnectBluetooth() async {
    if (!isBluetoothEnabled.value) {
      Get.snackbar(
        'Bluetooth Off',
        'Please turn on Bluetooth to scan for devices',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }
    try {
      final bleController = Get.find<BleController>();
      isScanningBluetooth.value = true;
      await bleController.startScan();
      await Future.delayed(const Duration(seconds: 3));
      isScanningBluetooth.value = false;
      _showDeviceSelectionDialog(bleController);
    } catch (e) {
      isScanningBluetooth.value = false;
      Get.snackbar(
        'Error',
        'Failed to scan for devices: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showDeviceSelectionDialog(BleController bleController) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Bluetooth Device',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              Expanded(
                child: Obx(() {
                  if (bleController.discoveredDevices.isEmpty) {
                    return const Center(
                      child: Text(
                        'No devices found',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: bleController.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = bleController.discoveredDevices[index];
                      return ListTile(
                        leading: const Icon(Icons.bluetooth, color: AppColors.primaryBlue),
                        title: Text(
                          device.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textBlack,
                          ),
                        ),
                        subtitle: Text(
                          device.macAddress,
                          style: const TextStyle(color: AppColors.textGrey),
                        ),
                        trailing: Text(
                          '${device.rssi} dBm',
                          style: const TextStyle(color: AppColors.textGrey),
                        ),
                        onTap: () async {
                          Get.back();
                          await _connectToDevice(bleController, device);
                        },
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppDimensions.spacingSmall),
                  ElevatedButton(
                    onPressed: () async {
                      Get.back();
                      await scanAndConnectBluetooth();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.textWhite,
                    ),
                    child: const Text('Scan Again'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connectToDevice(BleController bleController, BleDevice device) async {
    try {
      Get.snackbar(
        'Connecting',
        'Connecting to ${device.name}...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      await bleController.connect(device);
      if (bleController.connectionState.value == BleConnectionState.ready) {
        macAddress.value = device.macAddress;
        Get.snackbar(
          'Connected',
          'Successfully connected to ${device.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        Get.snackbar(
          'Connection Failed',
          bleController.errorMessage.value ?? 'Failed to connect to device',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to connect: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> loadDevices() async {
    try {
      final db = Get.find<DatabaseService>();
      final devices = await db.getDevices();
      availableDevices.value = devices;
    } catch (e) {
      // Handle error
    }
  }

  void switchTab(OnboardingTab tab) {
    selectedTab.value = tab;
  }

  void setStartLocation(String value) {
    startLocation.value = value;
    startLocationError.value = '';
  }

  void setEndLocation(String value) {
    endLocation.value = value;
    endLocationError.value = '';
  }

  void setTransportMode(TransportMode? mode) {
    transportMode.value = mode;
    transportModeError.value = '';
  }

  void setStartDate(DateTime? date) {
    startDate.value = date;
    startDateError.value = '';
  }

  void setTempLower(String value) {
    tempLower.value = value;
    tempLowerError.value = '';
  }

  void setTempHigher(String value) {
    tempHigher.value = value;
    tempHigherError.value = '';
  }

  void setHumidityLower(String value) {
    humidityLower.value = value;
    humidityLowerError.value = '';
  }

  void setHumidityHigher(String value) {
    humidityHigher.value = value;
    humidityHigherError.value = '';
  }

  void setClientName(String value) {
    clientName.value = value;
    clientNameError.value = '';
  }

  void setMacAddress(String value) {
    if (macAddressController.text != value) {
      macAddressController.text = value;
    }
    macAddress.value = value;
    macAddressError.value = '';
  }

  void setSensorNumber(String value) {
    sensorNumber.value = value;
    sensorNumberError.value = '';
  }

  bool validateDeviceDetails() {
    bool isValid = true;
    
    if (macAddress.value.isEmpty) {
      macAddressError.value = 'MAC Address is required';
      isValid = false;
    } else {
      final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
      if (!macRegex.hasMatch(macAddress.value)) {
        macAddressError.value = 'Invalid MAC address format';
        isValid = false;
      }
    }
    
    if (sensorNumber.value.isEmpty) {
      sensorNumberError.value = 'Sensor number is required';
      isValid = false;
    } else {
      final number = int.tryParse(sensorNumber.value);
      if (number == null || number < 1) {
        sensorNumberError.value = 'Sensor number must be a positive number';
        isValid = false;
      }
    }
    
    return isValid;
  }

  Future<void> saveDeviceDetails() async {
    if (!validateDeviceDetails()) {
      return;
    }
    try {
      final db = Get.find<DatabaseService>();
      final existing = await db.getDeviceByMac(macAddress.value.toUpperCase());
      if (existing != null) {
        Get.snackbar('Error', 'Device with this MAC address already exists');
        return;
      }
      final device = Device(
        id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
        macAddress: macAddress.value.toUpperCase(),
        sensorNumber: int.parse(sensorNumber.value),
        name: null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await db.insertDevice(device);
      macAddress.value = '';
      macAddressController.clear();
      sensorNumber.value = '';
      await loadDevices();
      Get.snackbar('Success', 'Device registered successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to register device: ${e.toString()}');
    }
  }

  void toggleDeviceSelection(Device device) {
    if (selectedDevices.contains(device)) {
      selectedDevices.remove(device);
    } else {
      selectedDevices.add(device);
    }
  }

  bool validateTripDetails() {
    bool isValid = true;
    
    if (startLocation.value.isEmpty) {
      startLocationError.value = 'Start location is required';
      isValid = false;
    }
    
    if (endLocation.value.isEmpty) {
      endLocationError.value = 'End location is required';
      isValid = false;
    }
    
    if (transportMode.value == null) {
      transportModeError.value = 'Transport mode is required';
      isValid = false;
    }
    
    if (startDate.value == null) {
      startDateError.value = 'Start date is required';
      isValid = false;
    }
    
    if (tempLower.value.isEmpty) {
      tempLowerError.value = 'Lower temperature is required';
      isValid = false;
    }
    
    if (tempHigher.value.isEmpty) {
      tempHigherError.value = 'Higher temperature is required';
      isValid = false;
    }
    
    if (humidityLower.value.isEmpty) {
      humidityLowerError.value = 'Lower humidity is required';
      isValid = false;
    }
    
    if (humidityHigher.value.isEmpty) {
      humidityHigherError.value = 'Higher humidity is required';
      isValid = false;
    }
    
    if (clientName.value.isEmpty) {
      clientNameError.value = 'Client name is required';
      isValid = false;
    }
    
    return isValid;
  }

  Future<void> saveTrip() async {
    if (!validateTripDetails()) {
      return;
    }
    // TODO: Save trip to database
    Get.snackbar('Success', 'Trip configured successfully');
  }
}

