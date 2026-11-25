import 'package:flutter/material.dart';

import '../core/domain/problem.dart';
import '../core/domain/units.dart';

/// Token warna. Warna besaran dipakai konsisten di seluruh aplikasi (signaling).
class AppColors {
  static const distance = Color(0xFF2F80ED); // biru jalan
  static const speed = Color(0xFFF2994A); // oranye speedometer
  static const time = Color(0xFF27AE60); // hijau lampu
  static const clock = Color(0xFF9B51E0); // ungu senja
  static const taxi = Color(0xFFF2C94C); // kuning taksi
  static const asphalt = Color(0xFF4F4F4F);
  static const focusBg = Color(0xFFFFFBF2);
  static const wrong = Color(0xFFEB5757);
  static const right = Color(0xFF27AE60);
  static const irrelevant = Color(0xFF9E9E9E);
  static const sky = Color(0xFF8ED1FC);
  static const grass = Color(0xFF9BD67A);
  static const ink = Color(0xFF2D2D2D);
}

extension TagKindStyle on TagKind {
  Color get color => switch (this) {
        TagKind.distance => AppColors.distance,
        TagKind.speed => AppColors.speed,
        TagKind.duration => AppColors.time,
        TagKind.clock => AppColors.clock,
        TagKind.irrelevant => AppColors.irrelevant,
      };

  IconData get icon => switch (this) {
        TagKind.distance => Icons.straighten,
        TagKind.speed => Icons.speed,
        TagKind.duration => Icons.timer_outlined,
        TagKind.clock => Icons.schedule,
        TagKind.irrelevant => Icons.block,
      };
}

extension DimensionStyle on Dimension {
  Color get color => switch (this) {
        Dimension.distance => AppColors.distance,
        Dimension.speed => AppColors.speed,
        Dimension.time => AppColors.time,
      };
  IconData get icon => switch (this) {
        Dimension.distance => Icons.straighten,
        Dimension.speed => Icons.speed,
        Dimension.time => Icons.timer_outlined,
      };
}

extension ErrorCategoryStyle on ErrorCategory {
  IconData get icon => switch (this) {
        ErrorCategory.unit => Icons.build,
        ErrorCategory.formula => Icons.swap_horiz,
        ErrorCategory.reading => Icons.menu_book,
        ErrorCategory.arithmetic => Icons.calculate,
        ErrorCategory.unknown => Icons.help_outline,
      };
  String get label => switch (this) {
        ErrorCategory.unit => 'Satuan',
        ErrorCategory.formula => 'Rumus',
        ErrorCategory.reading => 'Membaca soal',
        ErrorCategory.arithmetic => 'Hitungan',
        ErrorCategory.unknown => 'Lainnya',
      };
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.distance,
    primary: AppColors.distance,
    secondary: AppColors.taxi,
    surface: Colors.white,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.focusBg,
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink).copyWith(
          bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 17, height: 1.5),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.45),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.focusBg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.taxi,
        foregroundColor: AppColors.ink,
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEDE6D6)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );
}
