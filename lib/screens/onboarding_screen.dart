import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/onboarding_controller.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class MacAddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (text.length > 12) {
      text = text.substring(0, 12);
    }
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 2 == 0) {
        buffer.write(':');
      }
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    int cursorPosition = formatted.length;
    if (newValue.selection.baseOffset > oldValue.text.length) {
      cursorPosition = formatted.length;
    } else {
      final oldFormatted = _formatMacAddress(oldValue.text);
      final diff = formatted.length - oldFormatted.length;
      cursorPosition = (newValue.selection.baseOffset + diff).clamp(0, formatted.length);
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  String _formatMacAddress(String text) {
    final cleanText = text.toUpperCase().replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (cleanText.length > 12) {
      return cleanText.substring(0, 12);
    }
    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      if (i > 0 && i % 2 == 0) {
        buffer.write(':');
      }
      buffer.write(cleanText[i]);
    }
    return buffer.toString();
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Onboarding',
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: Obx(() {
                if (controller.selectedTab.value == OnboardingTab.tripDetails) {
                  return _buildTripDetailsForm(controller);
                } else {
                  return _buildDeviceDetailsForm(controller);
                }
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(OnboardingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => _buildTab(
              icon: Icons.memory,
              label: 'Device Details',
              isSelected: controller.selectedTab.value == OnboardingTab.deviceDetails,
              onTap: () => controller.switchTab(OnboardingTab.deviceDetails),
            )),
          ),
          const SizedBox(width: AppDimensions.spacingMedium),
          Expanded(
            child: Obx(() => _buildTab(
              icon: Icons.map,
              label: 'Trip Details',
              isSelected: controller.selectedTab.value == OnboardingTab.tripDetails,
              onTap: () => controller.switchTab(OnboardingTab.tripDetails),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingMedium,
          horizontal: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderGrey,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.textWhite : AppColors.textGrey,
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.textWhite : AppColors.textGrey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailsForm(OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        const Text(
          'Configure trip parameters and sensor assignment',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXLarge),
        _buildTextField(
          label: 'Start Location',
          hintText: 'e.g. New York',
          controller: controller.startLocationController,
          errorText: controller.startLocationError.value.isEmpty
              ? null
              : controller.startLocationError.value,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),
        _buildTextField(
          label: 'End Location',
          hintText: 'e.g. London',
          controller: controller.endLocationController,
          errorText: controller.endLocationError.value.isEmpty
              ? null
              : controller.endLocationError.value,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),
        _buildTransportModeDropdown(controller),
        const SizedBox(height: AppDimensions.spacingLarge),
        _buildDateField(controller),
        const SizedBox(height: AppDimensions.spacingLarge),
        _buildTemperatureLimits(controller),
        const SizedBox(height: AppDimensions.spacingLarge),
        _buildHumidityLimits(controller),
        const SizedBox(height: AppDimensions.spacingLarge),
        _buildTextField(
          label: 'Client Name',
          hintText: 'Enter client name',
          controller: controller.clientNameController,
          errorText: controller.clientNameError.value.isEmpty
              ? null
              : controller.clientNameError.value,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),
        _buildAssignSensors(controller),
        const SizedBox(height: AppDimensions.spacingXLarge),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.saveTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textWhite,
              minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLarge),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
              ),
            ),
            child: const Text(
              'Save Trip',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceDetailsForm(OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Device Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        const Text(
          'Register a new IoT sensor device',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXLarge),
        Obx(() => _buildMacAddressField(
          label: 'MAC Address',
          hintText: 'XX:XX:XX:XX:XX:XX',
          controller: controller.macAddressController,
          errorText: controller.macAddressError.value.isEmpty
              ? null
              : controller.macAddressError.value,
        )),
        const SizedBox(height: AppDimensions.spacingLarge),
        Obx(() => _buildTextField(
          label: 'Sensor Number',
          hintText: 'Enter sensor number',
          controller: controller.sensorNumberController,
          keyboardType: TextInputType.number,
          errorText: controller.sensorNumberError.value.isEmpty
              ? null
              : controller.sensorNumberError.value,
        )),
        const SizedBox(height: AppDimensions.spacingXLarge),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.saveDeviceDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textWhite,
              minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLarge),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
              ),
            ),
            child: const Text(
              'Save Device Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXLarge),
        Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registered Devices (${controller.availableDevices.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            if (controller.availableDevices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppDimensions.spacingLarge),
                child: Center(
                  child: Text(
                    'No devices registered yet',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...controller.availableDevices.map((device) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.memory,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimensions.spacingMedium),
                      Expanded(
                        child: Text(
                          device.macAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textBlack,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'Sensor #${device.sensorNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        )),
      ],
    );
  }

  Widget _buildMacAddressField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        TextField(
          controller: controller,
          inputFormatters: [
            MacAddressFormatter(),
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f:]')),
          ],
          style: const TextStyle(color: AppColors.textBlack),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textGreyLight),
            filled: true,
            fillColor: AppColors.backgroundGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide.none,
            ),
            errorText: errorText,
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.all(AppDimensions.inputPadding),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textBlack),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textGreyLight),
            filled: true,
            fillColor: AppColors.backgroundGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide.none,
            ),
            errorText: errorText,
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.all(AppDimensions.inputPadding),
          ),
        ),
      ],
    );
  }

  Widget _buildTransportModeDropdown(OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mode of Transportation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Obx(() => Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: DropdownButtonFormField<TransportMode>(
            value: controller.transportMode.value,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: BorderSide.none,
              ),
              errorText: controller.transportModeError.value.isEmpty
                  ? null
                  : controller.transportModeError.value,
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.error, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
              contentPadding: const EdgeInsets.all(AppDimensions.inputPadding),
            //   suffixIcon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey),
             ),
            dropdownColor: AppColors.backgroundWhite,
            style: const TextStyle(color: AppColors.textBlack),
            hint: const Text(
              'Select transport mode',
              style: TextStyle(color: AppColors.textGrey),
            ),
            items: TransportMode.values.map((mode) {
              return DropdownMenuItem<TransportMode>(
                value: mode,
                child: Text(
                  mode.name.toUpperCase(),
                  style: const TextStyle(color: AppColors.textBlack),
                ),
              );
            }).toList(),
            onChanged: controller.setTransportMode,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey),
          ),
        )),
      ],
    );
  }

  Widget _buildDateField(OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Start Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Obx(() => InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: Get.context!,
              initialDate: controller.startDate.value ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              controller.setStartDate(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.inputPadding),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: controller.startDateError.value.isNotEmpty
                  ? Border.all(color: AppColors.error, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.startDate.value != null
                      ? DateFormat('MM/dd/yyyy').format(controller.startDate.value!)
                      : 'Select date',
                  style: TextStyle(
                    color: controller.startDate.value != null
                        ? AppColors.textBlack
                        : AppColors.textGreyLight,
                  ),
                ),
                const Icon(Icons.calendar_today, color: AppColors.textGrey, size: 20),
              ],
            ),
          ),
        )),
        if (controller.startDateError.value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.spacingSmall),
            child: Text(
              controller.startDateError.value,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTemperatureLimits(OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Temperature Limits (°C)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Row(
          children: [
            Expanded(
              child: _buildLimitField(
                hintText: 'Lower',
                controller: controller.tempLowerController,
                errorText: controller.tempLowerError.value.isEmpty
                    ? null
                    : controller.tempLowerError.value,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingMedium),
              child: Text(
                'to',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            Expanded(
              child: _buildLimitField(
                hintText: 'Higher',
                controller: controller.tempHigherController,
                errorText: controller.tempHigherError.value.isEmpty
                    ? null
                    : controller.tempHigherError.value,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHumidityLimits(OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Humidity Limits (%)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Row(
          children: [
            Expanded(
              child: _buildLimitField(
                hintText: 'Lower',
                controller: controller.humidityLowerController,
                errorText: controller.humidityLowerError.value.isEmpty
                    ? null
                    : controller.humidityLowerError.value,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingMedium),
              child: Text(
                'to',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            Expanded(
              child: _buildLimitField(
                hintText: 'Higher',
                controller: controller.humidityHigherController,
                errorText: controller.humidityHigherError.value.isEmpty
                    ? null
                    : controller.humidityHigherError.value,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLimitField({
    required String hintText,
    required TextEditingController controller,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.textBlack),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textGreyLight),
        filled: true,
        fillColor: AppColors.backgroundGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide.none,
        ),
        errorText: errorText,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppDimensions.inputPadding),
      ),
    );
  }

  Widget _buildAssignSensors(OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => Text(
          'Assign Sensors (${controller.selectedDevices.length} selected)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textBlack,
          ),
        )),
        const SizedBox(height: AppDimensions.spacingSmall),
        const Divider(color: AppColors.borderGrey),
        const SizedBox(height: AppDimensions.spacingMedium),
        Obx(() {
          if (controller.availableDevices.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppDimensions.spacingLarge),
              child: Center(
                child: Text(
                  'No devices available',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }
          return Column(
            children: controller.availableDevices.map((device) {
              final isSelected = controller.selectedDevices.contains(device);
              return CheckboxListTile(
                title: Text(device.displayName),
                subtitle: Text(device.id),
                value: isSelected,
                onChanged: (_) => controller.toggleDeviceSelection(device),
                activeColor: AppColors.primaryBlue,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

