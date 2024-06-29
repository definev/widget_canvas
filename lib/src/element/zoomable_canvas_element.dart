import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

class ZoomableCanvasElement<T> extends StatelessWidget {
  const ZoomableCanvasElement({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canvasTheme = WidgetCanvasTheme.of(context);

    return Transform.scale(
      alignment: Alignment.topLeft,
      scale: canvasTheme.scaleFactor,
      child: child,
    );
  }
}
