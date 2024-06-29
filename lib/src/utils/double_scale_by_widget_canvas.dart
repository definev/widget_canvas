import 'package:flutter/material.dart';
import 'package:widget_canvas/src/widget_canvas/widget_canvas_theme.dart';

extension DoubleScaleByWidgetCanvas on double {
  double relativeValue(BuildContext context) {
    return this * WidgetCanvasTheme.of(context).scaleFactor;
  }
}
