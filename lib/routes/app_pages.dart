import 'package:get/get.dart';
import '../features/login/login_screen.dart';
import '../features/login/auth_binding.dart';
import '../features/home/home_screen.dart';
import '../features/live_dashboard/live_dashboard_screen.dart';
import '../features/live_dashboard/dashboard_binding.dart';
import '../features/new_device/new_device_screen.dart';
import '../features/new_device/new_device_binding.dart';
import '../features/download_data/download_data_screen.dart';
import '../features/download_data/download_data_binding.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/onboarding_binding.dart';
import '../features/device_list/device_list_screen.dart';
import '../features/ble_scan/ble_scan_screen.dart';
import '../features/device_info/device_info_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/data_sync/data_sync_screen.dart';
import '../features/report_generator/report_generator_screen.dart';
import '../features/report_generator/report_generator_binding.dart';
import '../features/config_result/config_result_screen.dart';
import '../features/config_result/config_result_binding.dart';
import '../features/live_dashboard/history_screen.dart';
import '../features/live_dashboard/history_binding.dart';
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
      page: () => const HistoryScreen(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.dataSync,
      page: () {
        final device = Get.arguments;
        return DataSyncScreen(device: device);
      },
    ),
    GetPage(
      name: AppRoutes.reportGenerator,
      page: () => const ReportGeneratorScreen(),
      binding: ReportGeneratorBinding(),
    ),
    GetPage(
      name: AppRoutes.configResult,
      page: () => const ConfigResultScreen(),
      binding: ConfigResultBinding(),
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => const HistoryScreen(),
      binding: HistoryBinding(),
    ),
  ];
}

