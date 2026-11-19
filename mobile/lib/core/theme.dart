import 'package:flutter/material.dart';

/// Spacing and sizing tokens shared by all screens.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double minTap = 48;
  static const double maxFormWidth = 440;
  static const double page = lg;
  static const double section = lg;
}

/// Corner radii: small (chips, pills, banners), medium (cards, inputs, buttons), large (dialogs, sheets).
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

const _seed = Color(0xFF1B5E8C);

ThemeData buildTheme(Brightness brightness, {bool reduceMotion = false}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness)
      .copyWith(
        primary: dark ? null : _seed,
        secondary: const Color(0xFF104F58),
        onSecondary: Colors.white,
        surface: dark ? const Color(0xFF102126) : const Color(0xFFF1F9F9),
        onSurface: dark ? const Color(0xFFE8EDF5) : const Color(0xFF254653),
        onSurfaceVariant: dark
            ? const Color(0xFFBBC6D6)
            : const Color(0xFF4D5C70),
        surfaceContainerLow: dark ? const Color(0xFF192E34) : Colors.white,
        surfaceContainer: dark
            ? const Color(0xFF1F2B3C)
            : const Color(0xFFE7F2F3),
        surfaceContainerHigh: dark
            ? const Color(0xFF29374B)
            : const Color(0xFFE7ECF5),
        surfaceContainerHighest: dark
            ? const Color(0xFF314157)
            : const Color(0xFFE7ECF5),
        outlineVariant: dark
            ? const Color(0xFF40516A)
            : const Color(0xFFD8E5E8),
        primaryContainer: dark
            ? const Color(0xFF193B64)
            : const Color(0xFFDEF1F5),
        onPrimaryContainer: dark
            ? const Color(0xFFDCEAFF)
            : const Color(0xFF102F56),
        secondaryContainer: dark
            ? const Color(0xFF183E30)
            : const Color(0xFFE2F3E9),
        onSecondaryContainer: dark
            ? const Color(0xFFBDEBD0)
            : const Color(0xFF174F35),
        tertiaryContainer: dark
            ? const Color(0xFF493A15)
            : const Color(0xFFFFF1CC),
        onTertiaryContainer: dark
            ? const Color(0xFFF5D98A)
            : const Color(0xFF604500),
      );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final shapeMd = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.md),
  );
  final text = base.textTheme.copyWith(
    headlineMedium: base.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1.12,
    ),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    titleSmall: base.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.4),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      height: 1.4,
      color: scheme.onSurfaceVariant,
    ),
    labelLarge: base.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
      backgroundColor: scheme.surface,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: Space.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(Space.minTap),
        shape: shapeMd,
        backgroundColor: dark ? null : scheme.secondary,
        foregroundColor: dark ? null : scheme.onSecondary,
        elevation: dark ? 0 : 1,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(Space.minTap),
        shape: shapeMd,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide.none,
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.primaryContainer,
      labelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: shapeMd,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
      backgroundColor: scheme.surfaceContainer,
      labelTextStyle: WidgetStatePropertyAll(
        text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: reduceMotion
            ? const _NoTransition()
            : const FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}

/// Used instead of a transition when the OS asks for reduced motion.
class _NoTransition extends PageTransitionsBuilder {
  const _NoTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
