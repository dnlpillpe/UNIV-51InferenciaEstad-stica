import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/simulation/city_survey.dart';
import 'chart_kit.dart';

/// Mapa de Villa Muestra: un punto por residente, distritos sombreados y
/// la última muestra resaltada con un anillo.
class CityGridPainter extends CustomPainter {
  CityGridPainter({
    required this.city,
    required this.selected,
    required this.palette,
    required this.highlight,
  });

  final CitySurvey city;
  final Set<int> selected;
  final ChartPalette palette;
  final Color highlight;

  static const List<Color> _districtTints = [
    Color(0x332E86AB),
    Color(0x22F2A541),
    Color(0x226C4AB6),
    Color(0x221F9E89),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / CitySurvey.cols;
    final ch = size.height / CitySurvey.rows;
    for (var d = 0; d < CitySurvey.districts.length; d++) {
      final dist = CitySurvey.districts[d];
      final r = Rect.fromLTRB(dist.colStart * cw, dist.rowStart * ch, dist.colEnd * cw, dist.rowEnd * ch);
      canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(6)),
          Paint()..color = _districtTints[d]);
      drawLabel(canvas, dist.name, r.topLeft + const Offset(6, 3),
          color: palette.ink.withValues(alpha: 0.75), fontSize: 10, weight: FontWeight.w700, align: TextAlign.left);
    }
    final rad = (cw < ch ? cw : ch) * 0.28;
    final yes = Paint()..color = palette.sample;
    final no = Paint()..color = palette.muted.withValues(alpha: 0.35);
    final ring = Paint()
      ..color = highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (final r in city.residents) {
      final c = Offset((r.col + 0.5) * cw, (r.row + 0.5) * ch + 4);
      canvas.drawCircle(c, rad, r.usesTransit ? yes : no);
      if (selected.contains(r.index)) canvas.drawCircle(c, rad + 2.2, ring);
    }
  }

  @override
  bool shouldRepaint(covariant CityGridPainter old) => true;
}

class StripRow {
  const StripRow(this.label, this.values, this.color);
  final String label;
  final List<double> values;
  final Color color;
}

/// Filas de estimaciones repetidas frente al valor verdadero.
class StripPlotPainter extends CustomPainter {
  StripPlotPainter({required this.rows, required this.truth, required this.palette, this.min = 0, this.max = 1});

  final List<StripRow> rows;
  final double truth;
  final ChartPalette palette;
  final double min, max;

  @override
  void paint(Canvas canvas, Size size) {
    final f = ChartFrame(size, xMin: min, xMax: max, yMax: 1, top: 18, bottom: 24);
    final rowH = f.plot.height / rows.length;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final cy = f.plot.top + (i + 0.5) * rowH;
      canvas.drawLine(Offset(f.plot.left, cy), Offset(f.plot.right, cy), Paint()..color = palette.grid);
      drawLabel(canvas, row.label, Offset(f.plot.left, f.plot.top + i * rowH + 2),
          color: row.color, fontSize: 10, weight: FontWeight.w800, align: TextAlign.left);
      final p = Paint()..color = row.color.withValues(alpha: 0.55);
      for (var k = 0; k < row.values.length; k++) {
        // Desplazamiento vertical determinista para que los puntos no se tapen.
        final jitter = ((k * 37) % 11 - 5) / 5 * rowH * 0.22;
        canvas.drawCircle(Offset(f.x(row.values[k]), cy + jitter + 4), 3.2, p);
      }
      if (row.values.isNotEmpty) {
        final m = row.values.reduce((a, b) => a + b) / row.values.length;
        final mx = f.x(m);
        canvas.drawLine(Offset(mx, cy - rowH * 0.34 + 4), Offset(mx, cy + rowH * 0.34 + 4),
            Paint()..color = row.color..strokeWidth = 3);
      }
    }
    drawXAxis(canvas, f, palette, format: (v) => Fmt.percent(v, 0));
    drawMarker(canvas, f, ChartMarker(truth, palette.parameter, label: 'Real ${Fmt.percent(truth, 1)}', width: 2));
  }

  @override
  bool shouldRepaint(covariant StripPlotPainter old) => true;
}
