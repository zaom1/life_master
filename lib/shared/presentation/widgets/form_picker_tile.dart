import 'package:flutter/material.dart';

class FormPickerTile extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Widget content;
  final Widget? trailing;
  final Color? iconColor;

  const FormPickerTile({
    super.key,
    required this.onTap,
    required this.icon,
    required this.content,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(child: content),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
