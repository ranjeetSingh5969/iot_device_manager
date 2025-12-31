import 'package:get/get.dart';
import '../controllers/report_generator_controller.dart';

class ReportGeneratorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ReportGeneratorController());
  }
}

