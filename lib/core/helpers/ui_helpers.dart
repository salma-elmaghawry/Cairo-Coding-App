import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: isError ? colorScheme.error : null,
        content: Text(
          message,
          style: isError ? AppTextStyles.font14SemiBold.copyWith(color: colorScheme.onError) : null,
        ),
      ),
    );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message, style: AppTextStyles.font14Normal.secondary(dialogContext)),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(cancelLabel)),
        TextButton(
          style: destructive ? TextButton.styleFrom(foregroundColor: colorScheme.error) : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
