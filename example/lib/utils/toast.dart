import 'package:flutter/material.dart';

class ToastUtils {
  static void showFailureToast(
    BuildContext context, {
    required String message,
  }) => showCenterToast(context, message);

  static void showCenterToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
