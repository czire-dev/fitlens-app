import 'package:flutter/material.dart';

class GarmentPreview extends StatelessWidget {
  const GarmentPreview({
    super.key,
    required this.assetPath,
    this.viewLabel,
    required this.artHeight,
  });

  final String assetPath;
  final String? viewLabel;
  final double artHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: RadialGradient(
          colors: [colors.surfaceContainerLow, colors.surfaceContainerHigh],
          radius: 0.9,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: artHeight,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text(
                    'Artwork unavailable',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            if (viewLabel case final label?) ...[
              const SizedBox(height: 6),
              Text(
                '$label · Sample artwork',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
