import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class CandleData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class StockCandleChart extends StatefulWidget {
  final List<CandleData> candles;

  const StockCandleChart({
    super.key,
    required this.candles,
  });

  @override
  State<StockCandleChart> createState() => _StockCandleChartState();
}

class _StockCandleChartState extends State<StockCandleChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return const SizedBox(height: 220);
    }

    return GestureDetector(
      onPanUpdate: (details) =>
          _handleTouch(details.localPosition),
      onPanDown: (details) =>
          _handleTouch(details.localPosition),
      onPanEnd: (_) =>
          setState(() => _selectedIndex = null),
      onTapUp: (_) =>
          setState(() => _selectedIndex = null),
      child: CustomPaint(
        size: const Size(double.infinity, 220),
        painter: _CandleChartPainter(
          candles: widget.candles,
          selectedIndex: _selectedIndex,
          upColor: context.colors.chartLineUp,
          downColor: context.colors.chartLineDown,
          axisColor: context.colors.chartAxisLabel,
          tooltipBg: context.colors.surfaceRaised,
          textColor: context.colors.textPrimary,
        ),
      ),
    );
  }

  void _handleTouch(Offset localPosition) {
    final width = context.size?.width ?? 0;

    if (width == 0) return;

    // 오른쪽 가격 라벨 영역을 제외한 실제 차트 영역
    const rightLabelWidth = 52.0;
    final chartWidth = width - rightLabelWidth;

    if (chartWidth <= 0) return;

    // 가격 라벨 영역을 터치한 경우 무시
    if (localPosition.dx >= chartWidth) return;

    final count = widget.candles.length;
    final candleWidth = chartWidth / count;

    final index = (localPosition.dx / candleWidth)
        .clamp(0, count - 1)
        .toInt();

    setState(() {
      _selectedIndex = index;
    });
  }
}

class _CandleChartPainter extends CustomPainter {
  final List<CandleData> candles;
  final int? selectedIndex;
  final Color upColor;
  final Color downColor;
  final Color axisColor;
  final Color tooltipBg;
  final Color textColor;

  _CandleChartPainter({
    required this.candles,
    required this.selectedIndex,
    required this.upColor,
    required this.downColor,
    required this.axisColor,
    required this.tooltipBg,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // 오른쪽 가격 축 영역
    const rightLabelWidth = 52.0;

    // 실제 캔들이 그려지는 영역
    final chartWidth = size.width - rightLabelWidth;

    if (chartWidth <= 0) return;

    double minPrice = candles.first.low;
    double maxPrice = candles.first.high;

    for (final candle in candles) {
      if (candle.low < minPrice) {
        minPrice = candle.low;
      }

      if (candle.high > maxPrice) {
        maxPrice = candle.high;
      }
    }

    final priceRange =
        (maxPrice - minPrice) == 0
            ? 1.0
            : (maxPrice - minPrice);

    final count = candles.length;

    final candleWidth = chartWidth / count;

    final bodyWidth =
        (candleWidth * 0.65).clamp(2.0, 14.0);

    // ------------------------------------------
    // 가격 축 가이드라인
    // ------------------------------------------

    final gridPaint = Paint()
      ..color = axisColor.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    const labelCount = 4;

    for (int i = 0; i < labelCount; i++) {
      final ratio =
          i / (labelCount - 1);

      final y =
          size.height * ratio;

      canvas.drawLine(
        Offset(0, y),
        Offset(chartWidth, y),
        gridPaint,
      );
    }

    // ------------------------------------------
    // 캔들 렌더링
    // ------------------------------------------

    for (int i = 0; i < count; i++) {
      final candle = candles[i];

      final isUp = candle.close >= candle.open;

      final color =
          isUp ? upColor : downColor;

      final x =
          (i * candleWidth) +
          (candleWidth / 2);

      final highY =
          size.height -
          ((candle.high - minPrice) /
                  priceRange *
              size.height);

      final lowY =
          size.height -
          ((candle.low - minPrice) /
                  priceRange *
              size.height);

      final openY =
          size.height -
          ((candle.open - minPrice) /
                  priceRange *
              size.height);

      final closeY =
          size.height -
          ((candle.close - minPrice) /
                  priceRange *
              size.height);

      // High-Low 꼬리선
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 1.2;

      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        linePaint,
      );

      // Open-Close 몸통
      final topY =
          isUp ? closeY : openY;

      final bottomY =
          isUp ? openY : closeY;

      final bodyHeight =
          (bottomY - topY)
              .abs()
              .clamp(1.5, size.height);

      final bodyPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(
            x,
            topY + bodyHeight / 2,
          ),
          width: bodyWidth,
          height: bodyHeight,
        ),
        bodyPaint,
      );
    }

    // ------------------------------------------
    // 가격 축 숫자 라벨
    // ------------------------------------------

    _drawPriceLabels(
      canvas,
      size,
      chartWidth,
      minPrice,
      maxPrice,
    );

    // ------------------------------------------
    // 터치 크로스헤어 및 툴팁
    // ------------------------------------------

    if (selectedIndex != null &&
        selectedIndex! < candles.length) {
      final index = selectedIndex!;

      final candle = candles[index];

      final x =
          (index * candleWidth) +
          (candleWidth / 2);

      final closeY =
          size.height -
          ((candle.close - minPrice) /
                  priceRange *
              size.height);

      // Crosshair
      final crosshairPaint = Paint()
        ..color =
            axisColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.0;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        crosshairPaint,
      );

      canvas.drawLine(
        Offset(0, closeY),
        Offset(chartWidth, closeY),
        crosshairPaint,
      );

      // 터치 포인트 하이라이트
      canvas.drawCircle(
        Offset(x, closeY),
        4.0,
        Paint()..color = textColor,
      );

      // 툴팁
      _drawTooltip(
        canvas,
        size,
        Offset(x, closeY),
        candle,
      );
    }
  }

  // ------------------------------------------
  // 가격 축 라벨
  // ------------------------------------------

  void _drawPriceLabels(
    Canvas canvas,
    Size size,
    double chartWidth,
    double minPrice,
    double maxPrice,
  ) {
    const rightLabelWidth = 52.0;
    const labelCount = 4;

    for (int i = 0; i < labelCount; i++) {
      final ratio =
          i / (labelCount - 1);

      // 위에서 아래로 가격이 낮아짐
      final price =
          maxPrice -
          ((maxPrice - minPrice) * ratio);

      final y =
          size.height * ratio;

      final text = _formatPrice(price);

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: axisColor,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(
        maxWidth: 48,
      );

      // 숫자가 차트 오른쪽 영역에 들어가도록 배치
      final x =
          chartWidth +
          (rightLabelWidth -
              textPainter.width) /
              2;

      // 텍스트 중앙 정렬
      final textY =
          y - textPainter.height / 2;

      textPainter.paint(
        canvas,
        Offset(
          x,
          textY.clamp(
            0.0,
            size.height -
                textPainter.height,
          ),
        ),
      );
    }
  }

  // ------------------------------------------
  // 가격 숫자 포맷
  // ------------------------------------------

  String _formatPrice(double price) {
    final value = price.round();

    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(1)}억';
    }

    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}만';
    }

    return value
        .toString()
        .replaceAllMapped(
          RegExp(
            r'(\d{1,3})(?=(\d{3})+(?!\d))',
          ),
          (match) => '${match[1]},',
        );
  }

  // ------------------------------------------
  // 툴팁
  // ------------------------------------------

  void _drawTooltip(
    Canvas canvas,
    Size size,
    Offset point,
    CandleData candle,
  ) {
    final textSpan = TextSpan(
      text:
          '${candle.close.toInt()}원\n'
          '(${candle.date.month}.${candle.date.day})',
      style: TextStyle(
        color: textColor,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    const padding = 6.0;

    final tooltipWidth =
        textPainter.width +
        (padding * 2);

    final tooltipHeight =
        textPainter.height +
        (padding * 2);

    double tooltipX =
        point.dx -
        (tooltipWidth / 2);

    if (tooltipX < 0) {
      tooltipX = 4;
    }

    if (tooltipX + tooltipWidth >
        size.width) {
      tooltipX =
          size.width -
          tooltipWidth -
          4;
    }

    double tooltipY =
        point.dy -
        tooltipHeight -
        8;

    if (tooltipY < 0) {
      tooltipY =
          point.dy + 8;
    }

    final bgPaint = Paint()
      ..color = tooltipBg
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color =
          axisColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect =
        RRect.fromRectAndRadius(
      Rect.fromLTWH(
        tooltipX,
        tooltipY,
        tooltipWidth,
        tooltipHeight,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      rect,
      bgPaint,
    );

    canvas.drawRRect(
      rect,
      borderPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        tooltipX + padding,
        tooltipY + padding,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant _CandleChartPainter oldDelegate,
  ) {
    return oldDelegate.candles != candles ||
        oldDelegate.selectedIndex !=
            selectedIndex;
  }
}
