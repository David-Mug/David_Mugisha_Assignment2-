import 'package:flutter/material.dart';

/// The main call-to-action button.
///
/// While [isLoading] is true it shows a spinner and ignores taps — this is
/// what prevents duplicate submissions when a user taps "Submit" repeatedly.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      // Keep the purple colour while loading instead of the grey "disabled" look.
      style: isLoading
          ? FilledButton.styleFrom(
              disabledBackgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      child: child,
    );
  }
}
