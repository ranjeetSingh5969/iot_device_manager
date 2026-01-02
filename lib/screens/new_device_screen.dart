import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/new_device_controller.dart';
import '../controllers/ble_controller.dart';
import '../models/device.dart';
import '../models/ble_device.dart';
import '../services/database_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../routes/app_routes.dart';
import '../utils/snackbar_helper.dart';

class NewDeviceScreen extends StatefulWidget {
  const NewDeviceScreen({super.key});

  @override
  State<NewDeviceScreen> createState() => _NewDeviceScreenState();
}

class _NewDeviceScreenState extends State<NewDeviceScreen> {
  @override
  void initState() {
    super.initState();
    // Reload devices when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<NewDeviceController>();
      controller.loadOnboardedDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NewDeviceController>();
    final bleController = Get.find<BleController>();
    
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'New Device',
          style: TextStyle(
            color: AppColors.textBlack,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        actions: [
          Obx(() {
            if (controller.selectedTab.value == DeviceTab.nearby) {
              return IconButton(
                icon: bleController.isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: AppColors.primaryBlue,
                      ),
                onPressed: bleController.isScanning
                    ? null
                    : () {
                        controller.startScan();
                      },
                tooltip: 'Rescan',
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(controller),
          const SizedBox(height: AppDimensions.spacingMedium),
          Expanded(
            child: Obx(() {
              // Observe connection state to trigger rebuilds
              final _ = bleController.connectionState.value;
              final __ = bleController.connectedDevice.value;
              
              if (controller.selectedTab.value == DeviceTab.onboarded) {
                return _buildOnboardedDevicesList(controller, bleController);
              } else {
                return _buildNearbyDevicesList(controller, bleController);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(NewDeviceController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => _buildTab(
              label: 'Onboarded Devices',
              isSelected: controller.selectedTab.value == DeviceTab.onboarded,
              onTap: () => controller.switchTab(DeviceTab.onboarded),
            )),
          ),
          const SizedBox(width: AppDimensions.spacingMedium),
          Expanded(
            child: Obx(() => _buildTab(
              label: 'Nearby Devices',
              isSelected: controller.selectedTab.value == DeviceTab.nearby,
              onTap: () => controller.switchTab(DeviceTab.nearby),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.primaryBlue : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardedDevicesList(
    NewDeviceController controller,
    BleController bleController,
  ) {
    return Obx(() {
      // Observe connection state to trigger rebuilds when connection changes
      final connectionState = bleController.connectionState.value;
      final connectedDevice = bleController.connectedDevice.value;
      final connectingDeviceMac = bleController.connectingDeviceMac.value;
      
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.onboardedDevices.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.devices_other,
                size: 64,
                color: AppColors.textGreyLight,
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              const Text(
                'No onboarded devices',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
        itemCount: controller.onboardedDevices.length,
        itemBuilder: (context, index) {
          final device = controller.onboardedDevices[index];
          return _buildDeviceTile(
            device: device,
            bleController: bleController,
            controller: controller,
            onSwipe: () {},
          );
        },
      );
    });
  }

  Widget _buildNearbyDevicesList(
    NewDeviceController controller,
    BleController bleController,
  ) {
    return Obx(() {
      // Observe connection state to trigger rebuilds when connection changes
      final connectionState = bleController.connectionState.value;
      final connectedDevice = bleController.connectedDevice.value;
      final connectingDeviceMac = bleController.connectingDeviceMac.value;
      
      if (bleController.isScanning && bleController.discoveredDevices.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppDimensions.spacingMedium),
              Text(
                'Scanning for nearby devices...',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }
      if (bleController.discoveredDevices.isEmpty && !bleController.isScanning) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_disabled,
                size: 64,
                color: AppColors.textGreyLight,
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              const Text(
                'No nearby devices found',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              ElevatedButton.icon(
                onPressed: () => controller.startScan(),
                icon: const Icon(Icons.refresh),
                label: const Text('Rescan'),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
        itemCount: bleController.discoveredDevices.length,
        itemBuilder: (context, index) {
          final bleDevice = bleController.discoveredDevices[index];
          return _buildBleDeviceTile(
            bleDevice: bleDevice,
            bleController: bleController,
            controller: controller,
            onSwipe: () {},
          );
        },
      );
    });
  }

  Widget _buildDeviceTile({
    required Device device,
    required BleController bleController,
    required NewDeviceController controller,
    required VoidCallback onSwipe,
  }) {
    return Obx(() {
      final connectionState = bleController.connectionState.value;
      final connectedDevice = bleController.connectedDevice.value;
      final connectingDeviceMac = bleController.connectingDeviceMac.value;
      final discoveredDevices = bleController.discoveredDevices;
      
      final isConnected = connectionState == BleConnectionState.ready &&
          connectedDevice?.macAddress.toUpperCase() ==
              device.macAddress.toUpperCase();
      // Only show connecting for this specific device
      final isConnecting = (connectionState == BleConnectionState.connecting ||
          connectionState == BleConnectionState.discoveringServices) &&
          connectingDeviceMac == device.macAddress.toUpperCase();
      
      // Check if this onboarded device is also in nearby devices
      final isNearby = discoveredDevices.any(
        (d) => d.macAddress.toUpperCase() == device.macAddress.toUpperCase(),
      );
      
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: ListTile(
            leading: Stack(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppColors.secondaryGreen
                        : AppColors.textGreyLight,
                    shape: BoxShape.circle,
                  ),
                ),
                // Green dot indicator if device is nearby
                if (isNearby && !isConnected)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              device.displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.macAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                if (isConnected)
                  const Text(
                    'Connected',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryGreen,
                    ),
                  )
                else if (isConnecting)
                  const Text(
                    'Connecting...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                    ),
                  ),
              ],
            ),
            trailing: isConnected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          // Send Data command to RX characteristic
                          final success = await bleController.sendCommand('data');
                          if (success) {
                            // Navigate to result screen immediately
                            // The screen will subscribe to TX notifications
                            Get.toNamed(AppRoutes.configResult);
                          } else {
                            SnackbarHelper.showError('Failed to send command', title: 'Error');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryGreen,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingSmall,
                            vertical: AppDimensions.paddingSmall,
                          ),
                        ),
                        child: const Text(
                          'send data cmd',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSmall),
                      TextButton(
                        onPressed: () async {
                          await bleController.disconnect();
                          SnackbarHelper.showInfo('Disconnected from ${device.displayName}', title: 'Disconnected');
                        },
                        child: const Text(
                          'Disconnect',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: isConnecting
                        ? null
                        : () async {
                            await controller.connectToDevice(device);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMedium,
                        vertical: AppDimensions.paddingSmall,
                      ),
                    ),
                    child: isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                            ),
                          )
                        : const Text(
                            'Connect',
                            style: TextStyle(fontSize: 14),
                          ),
                  ),
          ),
        );
      });
  }

  Widget _buildBleDeviceTile({
    required BleDevice bleDevice,
    required BleController bleController,
    required NewDeviceController controller,
    required VoidCallback onSwipe,
  }) {
    return Obx(() {
      final connectionState = bleController.connectionState.value;
      final connectedDevice = bleController.connectedDevice.value;
      final connectingDeviceMac = bleController.connectingDeviceMac.value;
      final isConnected = connectionState == BleConnectionState.ready &&
          connectedDevice?.macAddress.toUpperCase() ==
              bleDevice.macAddress.toUpperCase();
      // Only show connecting for this specific device
      final isConnecting = (connectionState == BleConnectionState.connecting ||
          connectionState == BleConnectionState.discoveringServices) &&
          connectingDeviceMac == bleDevice.macAddress.toUpperCase();
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isConnected
                    ? AppColors.secondaryGreen
                    : AppColors.textGreyLight,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              bleDevice.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bleDevice.macAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                if (isConnected)
                  const Text(
                    'Connected',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryGreen,
                    ),
                  )
                else if (isConnecting)
                  const Text(
                    'Connecting...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                    ),
                  ),
              ],
            ),
            trailing: isConnected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          // Send Data command to RX characteristic
                          final success = await bleController.sendCommand('data');
                          if (success) {
                            // Navigate to result screen immediately
                            // The screen will subscribe to TX notifications
                            Get.toNamed(AppRoutes.configResult);
                          } else {
                            SnackbarHelper.showError('Failed to send command', title: 'Error');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryGreen,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingSmall,
                            vertical: AppDimensions.paddingSmall,
                          ),
                        ),
                        child: const Text(
                          'send data cmd',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSmall),
                      TextButton(
                        onPressed: () async {
                          await bleController.disconnect();
                          SnackbarHelper.showInfo('Disconnected from ${bleDevice.name}', title: 'Disconnected');
                        },
                        child: const Text(
                          'Disconnect',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: isConnecting
                        ? null
                        : () async {
                            await controller.connectToNearbyDevice(bleDevice);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMedium,
                        vertical: AppDimensions.paddingSmall,
                      ),
                    ),
                    child: isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                            ),
                          )
                        : const Text(
                            'Connect',
                            style: TextStyle(fontSize: 14),
                          ),
                  ),
          ),
        );
      });
  }
}

