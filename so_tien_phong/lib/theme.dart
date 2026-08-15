import 'package:flutter/material.dart';

import 'models/fee_type.dart';

/// Bảng màu cho 3 loại phí.
/// Đã kiểm tra tương phản + phân biệt được với người mù màu ở cả 2 chế độ sáng/tối.
class FeeColors {
  static const Map<FeeType, Color> light = {
    FeeType.electricity: Color(0xFFF59E0B), // hổ phách
    FeeType.room: Color(0xFF4F7CF7), // xanh dương
    FeeType.management: Color(0xFF14B8A6), // xanh ngọc
  };

  static const Map<FeeType, Color> dark = {
    FeeType.electricity: Color(0xFFBE7F1C),
    FeeType.room: Color(0xFF7268EC),
    FeeType.management: Color(0xFF0C9077),
  };

  static Color of(BuildContext context, FeeType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? dark[type] : light[type]) ?? Colors.grey;
  }

  static Color ofBrightness(Brightness b, FeeType type) {
    return (b == Brightness.dark ? dark[type] : light[type]) ?? Colors.grey;
  }
}

/// Màu trạng thái — không bao giờ dùng lại cho series biểu đồ.
class StatusColors {
  static const paid = Color(0xFF2E9E5B);
  static const paidDark = Color(0xFF3DBE70);
  static const unpaid = Color(0xFFD4573B);
  static const unpaidDark = Color(0xFFE87A5F);
  static const pending = Color(0xFFB98218);

  static Color ok(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? paidDark : paid;

  static Color bad(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? unpaidDark : unpaid;
}

class AppTheme {
  static const _seed = Color(0xFF4F7CF7);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF121211) : const Color(0xFFF6F6F4),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor:
            isDark ? const Color(0xFF121211) : const Color(0xFFF6F6F4),
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF232320) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF35352F) : const Color(0xFFDDDDD6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF35352F) : const Color(0xFFDDDDD6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF2E2E2B) : const Color(0xFFE7E7E2),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1C)
          : Colors.white;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2E2E2B)
          : const Color(0xFFE7E7E2);
}

/// Pha màu [color] vào nền [base] theo tỉ lệ [t] (0..1).
/// Dùng thay cho withOpacity/withValues để chạy được trên mọi bản Flutter 3.x.
Color blend(Color base, Color color, double t) =>
    Color.lerp(base, color, t) ?? color;

/// Pha màu vào nền thẻ hiện tại.
Color tint(BuildContext context, Color color, double t) =>
    blend(AppTheme.surfaceOf(context), color, t);

/// Pha màu vào nền màn hình hiện tại.
Color tintScaffold(BuildContext context, Color color, double t) =>
    blend(Theme.of(context).scaffoldBackgroundColor, color, t);

/// Thẻ nền dùng chung — thay cho CardTheme để tương thích mọi bản Flutter 3.x.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? background;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.background,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Material(
      color: background ?? AppTheme.surfaceOf(context),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: borderColor ?? AppTheme.borderOf(context)),
          ),
          padding: padding,
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}
