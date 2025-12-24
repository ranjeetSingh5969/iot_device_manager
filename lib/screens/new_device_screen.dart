import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/new_device_controller.dart';
import '../controllers/ble_controller.dart';
import '../models/device.dart';
import '../models/ble_device.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class NewDeviceScreen extends StatelessWidget {
  const NewDeviceScreen({super.key});

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
      ),
      body: Column(
        children: [
          _buildTabs(controller),
          const SizedBox(height: AppDimensions.spacingMedium),
          Expanded(
            child: Obx(() {
              if (controller.selectedTab.value == DeviceTab.onboarded) {
                return _buildOnboardedDevicesList(controller);
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

  Widget _buildOnboardedDevicesList(NewDeviceController controller) {
    return Obx(() {
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
      if (bleController.discoveredDevices.isEmpty) {
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
                label: const Text('Scan Again'),
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
            onSwipe: () {},
          );
        },
      );
    });
  }

  Widget _buildDeviceTile({
    required Device device,
    required VoidCallback onSwipe,
  }) {
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
          decoration: const BoxDecoration(
            color: AppColors.secondaryGreen,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          device.displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        subtitle: Text(
          device.id,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textGrey,
        ),
      ),
    );
  }

  Widget _buildBleDeviceTile({
    required BleDevice bleDevice,
    required VoidCallback onSwipe,
  }) {
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
          decoration: const BoxDecoration(
            color: AppColors.secondaryGreen,
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
        subtitle: Text(
          bleDevice.macAddress,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}

