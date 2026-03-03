import 'package:core/core.dart';
import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      //duration: const Duration(seconds: 1),
      action: SnackBarAction(label: 'Ok'.i18n(), onPressed: () {}),
    ),
  );
}
