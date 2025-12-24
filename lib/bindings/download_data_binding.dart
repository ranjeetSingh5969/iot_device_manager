import 'package:get/get.dart';
import '../controllers/download_data_controller.dart';

class DownloadDataBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DownloadDataController>(() => DownloadDataController());
  }
}

