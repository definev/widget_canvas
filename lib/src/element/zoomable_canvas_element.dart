import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

class ZoomableCanvasElement<T> extends StatefulWidget {
  const ZoomableCanvasElement({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ZoomableCanvasElement<T>> createState() =>
      _ZoomableCanvasElementState<T>();
}

class _ZoomableCanvasElementState<T> extends State<ZoomableCanvasElement<T>> {
  late var canvasThemeNotifier = WidgetCanvasTheme.of(context)
    ..addListener(updateCanvasTheme);
  void updateCanvasTheme() => setState(() {});

  @override
  void dispose() {
    canvasThemeNotifier.removeListener(updateCanvasTheme);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasTheme = WidgetCanvasTheme.of(context);
    if (canvasTheme != canvasThemeNotifier) {
      canvasThemeNotifier.removeListener(updateCanvasTheme);
      canvasThemeNotifier = canvasTheme;
      canvasThemeNotifier.addListener(updateCanvasTheme);
    }

    return Transform.scale(
      alignment: Alignment.topLeft,
      scale: canvasThemeNotifier.value.scaleFactor,
      child: widget.child,
    );
  }
}
