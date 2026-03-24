import 'package:flutter/material.dart';

Future<void> showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() onConfirm,
  String cancelText = 'Cancel',
  String confirmText = 'Delete',
  Color confirmColor = Colors.red,
  IconData icon = Icons.warning_amber_rounded,
}) {
  var isSubmitting = false;
  return showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: confirmColor, size: 24),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    setState(() => isSubmitting = true);
                    try {
                      await onConfirm();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } finally {
                      if (context.mounted) {
                        setState(() => isSubmitting = false);
                      }
                    }
                  },
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(confirmText),
          ),
        ],
      ),
    ),
  );
}
