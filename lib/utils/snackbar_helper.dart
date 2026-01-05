import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarHelper {
  static void show({
    required String title,
    required String message,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 3),
    bool isError = false,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      duration: duration,
      backgroundColor: Colors.black,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: Icon(
        isError ? Icons.error_outline : Icons.info_outline,
        color: Colors.white,
      ),
      shouldIconPulse: false,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      animationDuration: const Duration(milliseconds: 300),
      barBlur: 0,
      overlayBlur: 0,
    );
  }

  static void showSuccess(String message, {String title = 'Success'}) {
    show(
      title: title,
      message: message,
      isError: false,
    );
  }

  static void showError(String message, {String title = 'Error'}) {
    show(
      title: title,
      message: message,
      isError: true,
    );
  }

  static void showInfo(String message, {String title = 'Info'}) {
    show(
      title: title,
      message: message,
      isError: false,
    );
  }
}

