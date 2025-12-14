import 'package:flutter/material.dart';

/// A custom styled filter chip for tags, categories, platforms.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    this.isTag = false,
    this.color,
    this.onTap,
    this.onDeleted,
  });

  final String label;
  final bool isTag;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color chipColor = color ?? colorScheme.secondary;
    if (isTag) {
      chipColor = colorScheme.tertiary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onDeleted != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDeleted,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: chipColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
