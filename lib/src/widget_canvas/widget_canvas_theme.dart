import 'package:flutter/material.dart';

class WidgetCanvasThemeData {
  const WidgetCanvasThemeData({
    this.rulerColor = const Color(0xAA000000),
    this.rulerHeight = defaultRulerHeight,
    this.rulerWidth = defaultRulerWidth,
    required this.scaleFactor,
    this.rulerThickness = 0.5,
  });

  static const double defaultRulerHeight = 50;
  static const double defaultRulerWidth = 50;

  static const defaultValue = WidgetCanvasThemeData(
    rulerColor: Colors.grey,
    rulerHeight: defaultRulerHeight,
    rulerWidth: defaultRulerWidth,
    scaleFactor: 1,
  );

  final Color rulerColor;
  final double rulerWidth;
  final double rulerHeight;
  final double rulerThickness;
  final double scaleFactor;

  WidgetCanvasThemeData operator *(double factor) {
    return WidgetCanvasThemeData(
      rulerColor: rulerColor,
      rulerHeight: rulerHeight * factor,
      rulerWidth: rulerWidth * factor,
      rulerThickness: rulerThickness * factor,
      scaleFactor: factor,
    );
  }

  @override
  operator ==(Object other) {
    if (other is WidgetCanvasThemeData) {
      return rulerColor == other.rulerColor &&
          rulerHeight == other.rulerHeight &&
          rulerWidth == other.rulerWidth &&
          rulerThickness == other.rulerThickness;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(rulerColor, rulerHeight, rulerWidth, rulerThickness);

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

  static WidgetCanvasThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WidgetCanvasTheme>()!.data;

  static WidgetCanvasThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WidgetCanvasTheme>()?.data;

  final WidgetCanvasThemeData data;

  @override
  bool updateShouldNotify(covariant WidgetCanvasTheme oldWidget) {
    return data != oldWidget.data;
  }
}

extension WidgetCanvasThemeX on Widget {
  Widget overrideWidgetCanvasTheme(WidgetCanvasThemeData canvasTheme) {
    return WidgetCanvasTheme(data: canvasTheme, child: this);
  }
}
