import 'package:get/get.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/live_dashboard_screen.dart';
import '../screens/new_device_screen.dart';
import '../screens/download_data_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/device_list_screen.dart';
import '../screens/ble_scan_screen.dart';
import '../screens/device_info_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/data_sync_screen.dart';
import '../bindings/auth_binding.dart';
import '../bindings/dashboard_binding.dart';
import '../bindings/new_device_binding.dart';
import '../bindings/download_data_binding.dart';
import '../bindings/onboarding_binding.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.login;

  static final routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: AppRoutes.liveDashboard,
      page: () => const LiveDashboardScreen(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.newDevice,
      page: () => const NewDeviceScreen(),
      binding: NewDeviceBinding(),
    ),
    GetPage(
      name: AppRoutes.downloadData,
      page: () => const DownloadDataScreen(),
      binding: DownloadDataBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.deviceList,
      page: () => const DeviceListScreen(),
    ),
    GetPage(
      name: AppRoutes.bleScan,
      page: () => const BleScanScreen(),
    ),
    GetPage(
      name: AppRoutes.deviceInfo,
      page: () {
        final device = Get.arguments;
        return DeviceInfoScreen(device: device);
      },
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () {
        final device = Get.arguments;
        return DashboardScreen(device: device);
      },
    ),
    GetPage(
      name: AppRoutes.history,
      page: () {
        final device = Get.arguments;
        return HistoryScreen(device: device);
      },
    ),
    GetPage(
      name: AppRoutes.dataSync,
      page: () {
        final device = Get.arguments;
        return DataSyncScreen(device: device);
      },
    ),
  ];
}

