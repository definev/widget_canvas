import 'package:flutter/material.dart';

class WidgetCanvasThemeData {
  WidgetCanvasThemeData({
    this.rulerColor = const Color(0xAA000000),
    this.rulerHeight = defaultRulerHeight,
    this.rulerWidth = defaultRulerWidth,
    required this.scaleFactor,
    this.rulerThickness = 0.5,
  });

  static const double defaultRulerHeight = 50;
  static const double defaultRulerWidth = 50;

  static final defaultValue = WidgetCanvasThemeData(
    rulerColor: Colors.grey,
    rulerHeight: defaultRulerHeight,
    rulerWidth: defaultRulerWidth,
    scaleFactor: 1,
  );

  final Color rulerColor;
  final double rulerWidth;
  late final double scaledRulerWidth = rulerWidth * scaleFactor;
  final double rulerHeight;
  late final double scaledRulerHeight = rulerHeight * scaleFactor;
  final double rulerThickness;
  late final double scaledRulerThickness = rulerThickness * scaleFactor;
  final double scaleFactor;

  WidgetCanvasThemeData operator *(double factor) {
    return WidgetCanvasThemeData(
      rulerColor: rulerColor,
      rulerHeight: rulerHeight,
      rulerWidth: rulerWidth,
      rulerThickness: rulerThickness,
      scaleFactor: factor,
    );
  }

  @override
  operator ==(Object other) {
    if (other is WidgetCanvasThemeData) {
      return rulerColor == other.rulerColor &&
          rulerHeight == other.rulerHeight &&
          rulerWidth == other.rulerWidth &&
          rulerThickness == other.rulerThickness &&
          scaleFactor == other.scaleFactor;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
      rulerColor, rulerHeight, rulerWidth, rulerThickness, scaleFactor);

  WidgetCanvasThemeData copyWith({
    Color? rulerColor,
    double? rulerHeight,
    double? rulerWidth,
    double? rulerThickness,
    double? scaleFactor,
  }) {
    return WidgetCanvasThemeData(
      rulerColor: rulerColor ?? this.rulerColor,
      rulerHeight: rulerHeight ?? this.rulerHeight,
      rulerWidth: rulerWidth ?? this.rulerWidth,
      rulerThickness: rulerThickness ?? this.rulerThickness,
      scaleFactor: scaleFactor ?? this.scaleFactor,
    );
  }
}

class WidgetCanvasTheme extends InheritedWidget {
  const WidgetCanvasTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static ValueNotifier<WidgetCanvasThemeData> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WidgetCanvasTheme>()!.data;

  static WidgetCanvasThemeData canvasThemeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<WidgetCanvasTheme>()!
      .data
      .value;

  static WidgetCanvasThemeData? maybeCanvasThemeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WidgetCanvasTheme>()
          ?.data
          .value;

  final ValueNotifier<WidgetCanvasThemeData> data;

  @override
  bool updateShouldNotify(covariant WidgetCanvasTheme oldWidget) {
    return data != oldWidget.data;
  }
}
