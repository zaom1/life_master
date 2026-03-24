import 'package:flutter/material.dart';

class FormFieldSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final double spacing;

  const FormFieldSection({
    super.key,
    this.title,
    required this.children,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final sectionChildren = <Widget>[];

    if (title != null && title!.isNotEmpty) {
      sectionChildren.add(
        Text(
          title!,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      );
      sectionChildren.add(const SizedBox(height: 8));
    }

    for (var i = 0; i < children.length; i++) {
      sectionChildren.add(children[i]);
      if (i < children.length - 1) {
        sectionChildren.add(SizedBox(height: spacing));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sectionChildren,
    );
  }
}
