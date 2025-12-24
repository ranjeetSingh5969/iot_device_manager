import 'package:get/get.dart';
import '../controllers/new_device_controller.dart';

class NewDeviceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NewDeviceController>(() => NewDeviceController());
  }
}

