import 'package:flutter/material.dart';

import '../models/fee_type.dart';
import '../models/payment.dart';
import '../theme.dart';
import '../utils/formatters.dart';

/// Biểu đồ tự vẽ bằng CustomPainter — không phụ thuộc thư viện ngoài,
/// nên build được với mọi phiên bản Flutter 3.x.

const double _kLeftAxis = 46;
const double _kBottomAxis = 24;
const double _kTopPad = 10;
const int _kGridLines = 4;

// =========================================================== BIỂU ĐỒ CỘT NHÓM

/// Cột cạnh nhau: mỗi tháng 3 cột (điện / phòng / quản lý).
class GroupedBarChart extends StatelessWidget {
  final List<MonthBook> books;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const GroupedBarChart({
    super.key,
    required this.books,
    required this.selectedIndex,
    required this.onSelect,
  });

  double get _maxValue {
    double m = 0;
    for (final b in books) {
      for (final p in b.all) {
        if (p.amount > m) m = p.amount;
      }
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = _niceCeil(_maxValue);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final index = _indexAt(details.localPosition.dx, constraints.maxWidth);
            if (index != null) onSelect(index);
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _GroupedBarPainter(
              books: books,
              maxY: maxY,
              selectedIndex: selectedIndex,
              colors: [
                for (final t in FeeType.values) FeeColors.of(context, t)
              ],
              gridColor: AppTheme.borderOf(context),
              labelColor: theme.colorScheme.onSurfaceVariant,
              highlightColor: tint(context, theme.colorScheme.primary, 0.09),
            ),
          ),
        );
      },
    );
  }

  int? _indexAt(double dx, double width) {
    if (books.isEmpty) return null;
    final plotWidth = width - _kLeftAxis;
    if (plotWidth <= 0) return null;
    final groupWidth = plotWidth / books.length;
    final i = ((dx - _kLeftAxis) / groupWidth).floor();
    if (i < 0 || i >= books.length) return null;
    return i;
  }
}

class _GroupedBarPainter extends CustomPainter {
  final List<MonthBook> books;
  final double maxY;
  final int? selectedIndex;
  final List<Color> colors;
  final Color gridColor;
  final Color labelColor;
  final Color highlightColor;

  _GroupedBarPainter({
    required this.books,
    required this.maxY,
    required this.selectedIndex,
    required this.colors,
    required this.gridColor,
    required this.labelColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (books.isEmpty) return;

    final plotLeft = _kLeftAxis;
    final plotTop = _kTopPad;
    final plotBottom = size.height - _kBottomAxis;
    final plotRight = size.width;
    final plotWidth = plotRight - plotLeft;
    final plotHeight = plotBottom - plotTop;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    final groupWidth = plotWidth / books.length;

    // Ô sáng đánh dấu tháng đang chọn.
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < books.length) {
      final rect = Rect.fromLTRB(
        plotLeft + groupWidth * selectedIndex!,
        plotTop - 4,
        plotLeft + groupWidth * (selectedIndex! + 1),
        plotBottom,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = highlightColor,
      );
    }

    // Lưới ngang + nhãn trục tung.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int g = 0; g <= _kGridLines; g++) {
      final value = maxY * g / _kGridLines;
      final y = plotBottom - plotHeight * (g / _kGridLines);
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);
      if (g > 0) {
        _paintText(
          canvas,
          formatMoneyShort(value),
          Offset(plotLeft - 6, y),
          labelColor,
          10.5,
          alignRight: true,
          alignMiddle: true,
        );
      }
    }

    // Cột.
    const barGap = 2.0;
    final available = groupWidth * 0.68 - barGap * 2;
    final barWidth = (available / 3).clamp(3.0, 12.0).toDouble();
    final clusterWidth = barWidth * 3 + barGap * 2;

    for (int i = 0; i < books.length; i++) {
      final book = books[i];
      final center = plotLeft + groupWidth * (i + 0.5);
      double x = center - clusterWidth / 2;

      for (int t = 0; t < FeeType.values.length; t++) {
        final amount = book.item(FeeType.values[t]).amount;
        if (amount > 0) {
          final h = plotHeight * (amount / maxY);
          final top = plotBottom - h;
          final rect = Rect.fromLTWH(x, top, barWidth, h < 2 ? 2 : h);
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              rect,
              topLeft: const Radius.circular(4),
              topRight: const Radius.circular(4),
            ),
            Paint()..color = colors[t],
          );
        }
        x += barWidth + barGap;
      }

      // Nhãn trục hoành.
      _paintText(
        canvas,
        'T${book.month}',
        Offset(center, plotBottom + 6),
        labelColor,
        10.5,
        alignCenter: true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GroupedBarPainter old) {
    return old.selectedIndex != selectedIndex ||
        old.maxY != maxY ||
        old.books.length != books.length ||
        old.gridColor != gridColor ||
        !identical(old.books, books);
  }
}

// ========================================================== BIỂU ĐỒ ĐƯỜNG

/// Đường tổng chi mỗi tháng.
class TotalLineChart extends StatelessWidget {
  final List<MonthBook> books;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const TotalLineChart({
    super.key,
    required this.books,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double m = 0;
    for (final b in books) {
      if (b.total > m) m = b.total;
    }
    final maxY = _niceCeil(m);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final i = _indexAt(details.localPosition.dx, constraints.maxWidth);
            if (i != null) onSelect(i);
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _LinePainter(
              books: books,
              maxY: maxY,
              selectedIndex: selectedIndex,
              lineColor: theme.colorScheme.primary,
              fillColor: tint(context, theme.colorScheme.primary, 0.13),
              surface: AppTheme.surfaceOf(context),
              gridColor: AppTheme.borderOf(context),
              labelColor: theme.colorScheme.onSurfaceVariant,
              labelBg: tint(context, theme.colorScheme.primary, 0.14),
              labelFg: theme.colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  int? _indexAt(double dx, double width) {
    if (books.isEmpty) return null;
    final plotWidth = width - _kLeftAxis;
    if (plotWidth <= 0) return null;
    if (books.length == 1) return 0;
    final step = plotWidth / (books.length - 1);
    final i = ((dx - _kLeftAxis) / step).round();
    if (i < 0 || i >= books.length) return null;
    return i;
  }
}

class _LinePainter extends CustomPainter {
  final List<MonthBook> books;
  final double maxY;
  final int? selectedIndex;
  final Color lineColor;
  final Color fillColor;
  final Color surface;
  final Color gridColor;
  final Color labelColor;
  final Color labelBg;
  final Color labelFg;

  _LinePainter({
    required this.books,
    required this.maxY,
    required this.selectedIndex,
    required this.lineColor,
    required this.fillColor,
    required this.surface,
    required this.gridColor,
    required this.labelColor,
    required this.labelBg,
    required this.labelFg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (books.isEmpty) return;

    final plotLeft = _kLeftAxis;
    final plotTop = _kTopPad + 14; // chừa chỗ cho nhãn giá trị
    final plotBottom = size.height - _kBottomAxis;
    final plotRight = size.width - 6;
    final plotWidth = plotRight - plotLeft;
    final plotHeight = plotBottom - plotTop;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    // Lưới + nhãn trục tung.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int g = 0; g <= _kGridLines; g++) {
      final value = maxY * g / _kGridLines;
      final y = plotBottom - plotHeight * (g / _kGridLines);
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);
      if (g > 0) {
        _paintText(
          canvas,
          formatMoneyShort(value),
          Offset(plotLeft - 6, y),
          labelColor,
          10.5,
          alignRight: true,
          alignMiddle: true,
        );
      }
    }

    // Toạ độ các điểm.
    final points = <Offset>[];
    for (int i = 0; i < books.length; i++) {
      final x = books.length == 1
          ? plotLeft + plotWidth / 2
          : plotLeft + plotWidth * (i / (books.length - 1));
      final y = plotBottom - plotHeight * (books[i].total / maxY);
      points.add(Offset(x, y));
      _paintText(
        canvas,
        'T${books[i].month}',
        Offset(x, plotBottom + 6),
        labelColor,
        10.5,
        alignCenter: true,
      );
    }

    if (points.length > 1) {
      // Vùng tô dưới đường.
      final fill = Path()..moveTo(points.first.dx, plotBottom);
      for (final p in points) {
        fill.lineTo(p.dx, p.dy);
      }
      fill
        ..lineTo(points.last.dx, plotBottom)
        ..close();
      canvas.drawPath(fill, Paint()..color = fillColor);

      // Đường.
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Điểm dữ liệu: vòng nền cùng màu nền thẻ để tách khỏi đường.
    for (int i = 0; i < points.length; i++) {
      final selected = selectedIndex == i;
      final radius = selected ? 6.0 : 4.0;
      canvas.drawCircle(points[i], radius + 2, Paint()..color = surface);
      canvas.drawCircle(points[i], radius, Paint()..color = lineColor);
    }

    // Nhãn trực tiếp: điểm cuối, và điểm đang chọn nếu khác điểm cuối.
    final labelIndexes = <int>{points.length - 1};
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < points.length) {
      labelIndexes.add(selectedIndex!);
    }
    for (final i in labelIndexes) {
      if (books[i].total <= 0) continue;
      _paintPill(
        canvas,
        formatMoneyShort(books[i].total),
        Offset(points[i].dx, points[i].dy - 14),
        labelBg,
        labelFg,
        size.width,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) {
    return old.selectedIndex != selectedIndex ||
        old.maxY != maxY ||
        old.books.length != books.length ||
        !identical(old.books, books);
  }
}

// ================================================================== tiện ích

/// Làm tròn trần lên số "đẹp" để trục tung dễ đọc.
double _niceCeil(double value) {
  if (value <= 0) return 1000000;
  final target = value * 1.15;
  final magnitude = _pow10(target);
  for (final step in const [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 7.5, 10.0]) {
    final candidate = step * magnitude;
    if (candidate >= target) return candidate;
  }
  return 10 * magnitude;
}

double _pow10(double value) {
  double m = 1;
  while (m * 10 <= value) {
    m *= 10;
  }
  while (m > value && m > 1) {
    m /= 10;
  }
  return m;
}

void _paintText(
  Canvas canvas,
  String text,
  Offset anchor,
  Color color,
  double fontSize, {
  bool alignRight = false,
  bool alignCenter = false,
  bool alignMiddle = false,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: fontSize),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  double dx = anchor.dx;
  double dy = anchor.dy;
  if (alignRight) dx -= painter.width;
  if (alignCenter) dx -= painter.width / 2;
  if (alignMiddle) dy -= painter.height / 2;
  painter.paint(canvas, Offset(dx, dy));
}

void _paintPill(
  Canvas canvas,
  String text,
  Offset center,
  Color background,
  Color foreground,
  double maxWidth,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: foreground,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  const padH = 6.0;
  const padV = 3.0;
  final w = painter.width + padH * 2;
  final h = painter.height + padV * 2;

  double left = center.dx - w / 2;
  if (left < 0) left = 0;
  if (left + w > maxWidth) left = maxWidth - w;
  double top = center.dy - h;
  if (top < 0) top = 0;

  final rect = Rect.fromLTWH(left, top, w, h);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(7)),
    Paint()..color = background,
  );
  painter.paint(canvas, Offset(left + padH, top + padV));
}
