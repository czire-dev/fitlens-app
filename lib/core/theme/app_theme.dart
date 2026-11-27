import 'package:flutter/material.dart';

const _ivory = Color(0xFFF8F0E6);
const _softWhite = Color(0xFFFFFDFA);
const _charcoal = Color(0xFF1C1C1C);
const _champagne = Color(0xFFB9A181);
const _warmGray = Color(0xFF6F665C);

ThemeData buildFitLensTheme() {
  final colors = ColorScheme.fromSeed(seedColor: _champagne).copyWith(
    primary: _charcoal,
    onPrimary: _ivory,
    secondaryContainer: _champagne,
    onSecondaryContainer: _charcoal,
    surface: _ivory,
    onSurface: _charcoal,
    onSurfaceVariant: _warmGray,
    surfaceContainerLow: _softWhite,
    surfaceContainerHigh: const Color(0xFFF1E7DA),
    outline: const Color(0xFF8D8174),
    outlineVariant: const Color(0xFFDDD0C0),
  );
  final base = ThemeData(colorScheme: colors);
  final text = base.textTheme;

  // Keep the selected colors here so the detail page only manages selection.
  const selectedChipFill = _charcoal;
  const selectedChipInk = _ivory;
  return base.copyWith(
    scaffoldBackgroundColor: _ivory,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: const AppBarTheme(
      backgroundColor: _ivory,
      foregroundColor: _charcoal,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: _charcoal,
        fontSize: 21,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    textTheme: text.copyWith(
      displaySmall: text.displaySmall?.copyWith(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        height: 0.99,
        letterSpacing: -1.6,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.12,
        letterSpacing: -0.65,
      ),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: text.bodyMedium?.copyWith(color: _warmGray),
      labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    chipTheme: ChipThemeData(
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? selectedChipFill
            : _softWhite,
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? selectedChipInk
              : _charcoal,
        ),
      ),
      checkmarkColor: selectedChipInk,
      showCheckmark: true,
      labelPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(8),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? selectedChipFill
              : colors.outline,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
