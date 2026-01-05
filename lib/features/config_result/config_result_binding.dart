import 'package:get/get.dart';
import 'config_result_controller.dart';

class ConfigResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConfigResultController>(() => ConfigResultController());
  }
}

