import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/controllers/auth_controller.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildLogo() {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.logoBlue,
            AppColors.logoGreen,
            AppColors.logoBlueDark,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: const Icon(
        Icons.graphic_eq,
        size: 24,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        side: const BorderSide(
          color: AppColors.borderGrey,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildLogo(),
                      const SizedBox(width: AppDimensions.spacingMedium),
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () async {
                      await authController.logout();
                      Get.offAllNamed(AppRoutes.login);
                    },
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXLarge),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              const Text(
                'Manage your IoT devices',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXLarge),
              _buildMenuCard(
                icon: Icons.bluetooth,
                iconColor: AppColors.primaryBlue,
                title: 'New Device',
                description: 'Connect and onboard new IoT devices via Bluetooth',
                onTap: () {
                  Get.toNamed(AppRoutes.newDevice);
                },
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              _buildMenuCard(
                icon: Icons.bar_chart,
                iconColor: AppColors.secondaryGreen,
                title: 'Dashboard',
                description: 'View temperature graphs and device analytics',
                onTap: () {
                  Get.toNamed(AppRoutes.liveDashboard);
                },
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              _buildMenuCard(
                icon: Icons.cloud_download,
                iconColor: Colors.purple,
                title: 'Download Data',
                description: 'Export and upload sensor data to cloud',
                onTap: () {
                  Get.toNamed(AppRoutes.downloadData);
                },
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              _buildMenuCard(
                icon: Icons.info_outline,
                iconColor: Colors.orange,
                title: 'Device Info',
                description: 'View and manage connected device details',
                onTap: () {
                  // TODO: Navigate to device info screen
                },
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              _buildMenuCard(
                icon: Icons.add_circle_outline,
                iconColor: Colors.pink,
                title: 'Onboarding',
                description: 'Register new devices and configure trips',
                onTap: () {
                  Get.toNamed(AppRoutes.onboarding);
                },
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              _buildMenuCard(
                icon: Icons.description,
                iconColor: AppColors.primaryBlue,
                title: 'Report Generator',
                description: 'Generate daily sensor reports with alerts',
                onTap: () {
                  Get.toNamed(AppRoutes.reportGenerator);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

