import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../models/ble_device.dart';
import '../../services/database_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../shared/controllers/ble_controller.dart';

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
  final Rxn<String> connectingDeviceMac = Rxn<String>(); // Track which device is being connected
  final RxBool isConnecting = false.obs;
  
  final TextEditingController macAddressController = TextEditingController();
  final TextEditingController startLocationController = TextEditingController();
  final TextEditingController endLocationController = TextEditingController();
  final TextEditingController tempLowerController = TextEditingController();
  final TextEditingController tempHigherController = TextEditingController();
  final TextEditingController humidityLowerController = TextEditingController();
  final TextEditingController humidityHigherController = TextEditingController();
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController sensorNumberController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadDevices();
    startDate.value = DateTime.now();
    selectedTab.value = OnboardingTab.deviceDetails;
    checkBluetoothStatus();
    _listenToBluetoothState();
    _setupTextControllers();
  }

  void _setupTextControllers() {
    macAddressController.addListener(() {
      if (macAddressController.text != macAddress.value) {
        macAddress.value = macAddressController.text;
        macAddressError.value = '';
      }
    });
    startLocationController.addListener(() {
      if (startLocationController.text != startLocation.value) {
        startLocation.value = startLocationController.text;
        startLocationError.value = '';
      }
    });
    endLocationController.addListener(() {
      if (endLocationController.text != endLocation.value) {
        endLocation.value = endLocationController.text;
        endLocationError.value = '';
      }
    });
    tempLowerController.addListener(() {
      if (tempLowerController.text != tempLower.value) {
        tempLower.value = tempLowerController.text;
        tempLowerError.value = '';
      }
    });
    tempHigherController.addListener(() {
      if (tempHigherController.text != tempHigher.value) {
        tempHigher.value = tempHigherController.text;
        tempHigherError.value = '';
      }
    });
    humidityLowerController.addListener(() {
      if (humidityLowerController.text != humidityLower.value) {
        humidityLower.value = humidityLowerController.text;
        humidityLowerError.value = '';
      }
    });
    humidityHigherController.addListener(() {
      if (humidityHigherController.text != humidityHigher.value) {
        humidityHigher.value = humidityHigherController.text;
        humidityHigherError.value = '';
      }
    });
    clientNameController.addListener(() {
      if (clientNameController.text != clientName.value) {
        clientName.value = clientNameController.text;
        clientNameError.value = '';
      }
    });
    sensorNumberController.addListener(() {
      if (sensorNumberController.text != sensorNumber.value) {
        sensorNumber.value = sensorNumberController.text;
        sensorNumberError.value = '';
      }
    });
  }

  @override
  void onClose() {
    macAddressController.dispose();
    startLocationController.dispose();
    endLocationController.dispose();
    tempLowerController.dispose();
    tempHigherController.dispose();
    humidityLowerController.dispose();
    humidityHigherController.dispose();
    clientNameController.dispose();
    sensorNumberController.dispose();
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
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
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
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    }
  }

  void _showDeviceSelectionDialog(BleController bleController) {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.backgroundWhite,
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
                  // Observe connection state and discovered devices to trigger rebuilds
                  final connectionState = bleController.connectionState.value;
                  final connectedDevice = bleController.connectedDevice.value;
                  final currentConnectingMac = connectingDeviceMac.value;
                  final currentlyConnecting = isConnecting.value;
                  
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
                      final isConnectingThisDevice = currentConnectingMac == device.macAddress.toUpperCase() && currentlyConnecting;
                      final isConnected = connectionState == BleConnectionState.ready &&
                          connectedDevice?.macAddress.toUpperCase() == device.macAddress.toUpperCase();
                      
                      return ListTile(
                        leading: isConnectingThisDevice
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                ),
                              )
                            : isConnected
                                ? const Icon(Icons.check_circle, color: AppColors.secondaryGreen)
                                : const Icon(Icons.bluetooth, color: AppColors.primaryBlue),
                        title: Text(
                          device.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textBlack,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.macAddress,
                              style: const TextStyle(color: AppColors.textGrey),
                            ),
                            if (isConnectingThisDevice)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Connecting...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              )
                            else if (isConnected)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Connected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.secondaryGreen,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          '${device.rssi} dBm',
                          style: const TextStyle(color: AppColors.textGrey),
                        ),
                        onTap: isConnectingThisDevice || isConnected
                            ? null
                            : () async {
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textGrey,
                      ),
                    ),
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
      barrierColor: Colors.black54,
    );
  }

  Future<void> _connectToDevice(BleController bleController, BleDevice device) async {
    try {
      isConnecting.value = true;
      connectingDeviceMac.value = device.macAddress.toUpperCase();
      
      await bleController.connect(device);
      
      // Wait a bit for connection state to update
      await Future.delayed(const Duration(milliseconds: 500));
      
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
    } finally {
      isConnecting.value = false;
      connectingDeviceMac.value = null;
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
    if (startLocationController.text != value) {
      startLocationController.text = value;
    }
    startLocation.value = value;
    startLocationError.value = '';
  }

  void setEndLocation(String value) {
    if (endLocationController.text != value) {
      endLocationController.text = value;
    }
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
    if (tempLowerController.text != value) {
      tempLowerController.text = value;
    }
    tempLower.value = value;
    tempLowerError.value = '';
  }

  void setTempHigher(String value) {
    if (tempHigherController.text != value) {
      tempHigherController.text = value;
    }
    tempHigher.value = value;
    tempHigherError.value = '';
  }

  void setHumidityLower(String value) {
    if (humidityLowerController.text != value) {
      humidityLowerController.text = value;
    }
    humidityLower.value = value;
    humidityLowerError.value = '';
  }

  void setHumidityHigher(String value) {
    if (humidityHigherController.text != value) {
      humidityHigherController.text = value;
    }
    humidityHigher.value = value;
    humidityHigherError.value = '';
  }

  void setClientName(String value) {
    if (clientNameController.text != value) {
      clientNameController.text = value;
    }
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
    if (sensorNumberController.text != value) {
      sensorNumberController.text = value;
    }
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
        Get.snackbar('Error', 'Device with this MAC address already exists', backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,);
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
      sensorNumberController.clear();
      await loadDevices();
      Get.snackbar('Success', 'Device registered successfully', backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,);
    } catch (e) {
      Get.snackbar('Error', 'Failed to register device: ${e.toString()}', backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,);
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
    final List<String> errors = [];
    
    if (startLocation.value.isEmpty) {
      startLocationError.value = 'Start location is required';
      errors.add('Start location is required');
      isValid = false;
    } else {
      startLocationError.value = '';
    }
    
    if (endLocation.value.isEmpty) {
      endLocationError.value = 'End location is required';
      errors.add('End location is required');
      isValid = false;
    } else {
      endLocationError.value = '';
    }
    
    if (transportMode.value == null) {
      transportModeError.value = 'Transport mode is required';
      errors.add('Transport mode is required');
      isValid = false;
    } else {
      transportModeError.value = '';
    }
    
    if (startDate.value == null) {
      startDateError.value = 'Start date is required';
      errors.add('Start date is required');
      isValid = false;
    } else {
      startDateError.value = '';
    }
    
    if (tempLower.value.isEmpty) {
      tempLowerError.value = 'Lower temperature is required';
      errors.add('Lower temperature is required');
      isValid = false;
    } else {
      final tempLow = double.tryParse(tempLower.value);
      if (tempLow == null) {
        tempLowerError.value = 'Invalid temperature value';
        errors.add('Lower temperature must be a valid number');
        isValid = false;
      } else {
        tempLowerError.value = '';
      }
    }
    
    if (tempHigher.value.isEmpty) {
      tempHigherError.value = 'Higher temperature is required';
      errors.add('Higher temperature is required');
      isValid = false;
    } else {
      final tempHigh = double.tryParse(tempHigher.value);
      if (tempHigh == null) {
        tempHigherError.value = 'Invalid temperature value';
        errors.add('Higher temperature must be a valid number');
        isValid = false;
      } else {
        tempHigherError.value = '';
      }
    }
    
    if (tempLower.value.isNotEmpty && tempHigher.value.isNotEmpty) {
      final tempLow = double.tryParse(tempLower.value);
      final tempHigh = double.tryParse(tempHigher.value);
      if (tempLow != null && tempHigh != null) {
        if (tempHigh <= tempLow) {
          tempLowerError.value = 'Lower temperature must be less than higher temperature';
          tempHigherError.value = 'Higher temperature must be greater than lower temperature';
          errors.add('Higher temperature must be greater than lower temperature. Current values: Lower = $tempLow, Higher = $tempHigh');
          isValid = false;
        } else {
          if (tempLowerError.value == 'Lower temperature must be less than higher temperature') {
            tempLowerError.value = '';
          }
          if (tempHigherError.value == 'Higher temperature must be greater than lower temperature') {
            tempHigherError.value = '';
          }
        }
      }
    }
    
    if (humidityLower.value.isEmpty) {
      humidityLowerError.value = 'Lower humidity is required';
      errors.add('Lower humidity is required');
      isValid = false;
    } else {
      final humidityLow = double.tryParse(humidityLower.value);
      if (humidityLow == null) {
        humidityLowerError.value = 'Invalid humidity value';
        errors.add('Lower humidity must be a valid number');
        isValid = false;
      } else if (humidityLow < 0 || humidityLow > 100) {
        humidityLowerError.value = 'Humidity must be between 0 and 100';
        errors.add('Lower humidity must be between 0 and 100');
        isValid = false;
      } else {
        humidityLowerError.value = '';
      }
    }
    
    if (humidityHigher.value.isEmpty) {
      humidityHigherError.value = 'Higher humidity is required';
      errors.add('Higher humidity is required');
      isValid = false;
    } else {
      final humidityHigh = double.tryParse(humidityHigher.value);
      if (humidityHigh == null) {
        humidityHigherError.value = 'Invalid humidity value';
        errors.add('Higher humidity must be a valid number');
        isValid = false;
      } else if (humidityHigh < 0 || humidityHigh > 100) {
        humidityHigherError.value = 'Humidity must be between 0 and 100';
        errors.add('Higher humidity must be between 0 and 100');
        isValid = false;
      } else {
        humidityHigherError.value = '';
      }
    }
    
    if (humidityLower.value.isNotEmpty && humidityHigher.value.isNotEmpty) {
      final humidityLow = double.tryParse(humidityLower.value);
      final humidityHigh = double.tryParse(humidityHigher.value);
      if (humidityLow != null && humidityHigh != null) {
        if (humidityHigh <= humidityLow) {
          humidityLowerError.value = 'Lower humidity must be less than higher humidity';
          humidityHigherError.value = 'Higher humidity must be greater than lower humidity';
          errors.add('Higher humidity must be greater than lower humidity. Current values: Lower = $humidityLow, Higher = $humidityHigh');
          isValid = false;
        } else {
          if (humidityLowerError.value == 'Lower humidity must be less than higher humidity') {
            humidityLowerError.value = '';
          }
          if (humidityHigherError.value == 'Higher humidity must be greater than lower humidity') {
            humidityHigherError.value = '';
          }
        }
      }
    }
    
    if (clientName.value.isEmpty) {
      clientNameError.value = 'Client name is required';
      errors.add('Client name is required');
      isValid = false;
    } else {
      clientNameError.value = '';
    }
    
    if (!isValid) {
      _showValidationErrorDialog(errors);
    }
    
    return isValid;
  }

  void _showValidationErrorDialog(List<String> errors) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.backgroundWhite,
        title: const Text(
          'Validation Error',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textBlack,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please fix the following errors:',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              ...errors.map((error) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
      ),
      barrierColor: Colors.black54,
    );
  }

  Future<void> saveTrip() async {
    if (!validateTripDetails()) {
      return;
    }
    try {
      final db = Get.find<DatabaseService>();
      final tempLow = double.parse(tempLower.value);
      final tempHigh = double.parse(tempHigher.value);
      final humidityLow = double.parse(humidityLower.value);
      final humidityHigh = double.parse(humidityHigher.value);
      final tripId = await db.insertTrip(
        startLocation: startLocation.value.trim(),
        endLocation: endLocation.value.trim(),
        transportMode: transportMode.value!.name,
        startDate: startDate.value!.millisecondsSinceEpoch,
        tempLow: tempLow,
        tempHigh: tempHigh,
        humidityLow: humidityLow,
        humidityHigh: humidityHigh,
        clientName: clientName.value.trim(),
      );
      if (selectedDevices.isNotEmpty) {
        final deviceIds = selectedDevices.map((device) => device.id).toList();
        await db.insertTripSensors(
          tripId: tripId,
          deviceIds: deviceIds,
        );
      }
      _clearTripForm();
      Get.snackbar(
        'Success',
        'Trip configured successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save trip: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  void _clearTripForm() {
    startLocation.value = '';
    startLocationController.clear();
    endLocation.value = '';
    endLocationController.clear();
    transportMode.value = null;
    startDate.value = DateTime.now();
    tempLower.value = '';
    tempLowerController.clear();
    tempHigher.value = '';
    tempHigherController.clear();
    humidityLower.value = '';
    humidityLowerController.clear();
    humidityHigher.value = '';
    humidityHigherController.clear();
    clientName.value = '';
    clientNameController.clear();
    selectedDevices.clear();
    startLocationError.value = '';
    endLocationError.value = '';
    transportModeError.value = '';
    startDateError.value = '';
    tempLowerError.value = '';
    tempHigherError.value = '';
    humidityLowerError.value = '';
    humidityHigherError.value = '';
    clientNameError.value = '';
  }
}

