import 'package:get/get.dart';
import 'download_data_controller.dart';

class DownloadDataBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DownloadDataController>(() => DownloadDataController());
  }
}

