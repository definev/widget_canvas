
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'widget_canvas.dart';

class WidgetCanvasZoomDetector extends StatefulWidget {
  const WidgetCanvasZoomDetector({
    super.key,
    required this.scaleFactor,
    required this.onUpdateScale,
    required this.minScaleFactor,
    required this.maxScaleFactor,
    required this.horizontalScrollController,
    required this.verticalScrollController,
    required this.child,
  });

  static Offset localToViewport(
    WidgetCanvasThemeData canvasTheme,
    Offset local, {
    required Offset origin,
  }) =>
      Offset(local.dx + origin.dx, local.dy + origin.dy);

  static Offset localToViewportPoint(
    WidgetCanvasThemeData canvasTheme,
    Offset local, {
    required Offset origin,
  }) {
    final result = Offset(
      (local.dx + origin.dx) / canvasTheme.rulerWidth,
      (local.dy + origin.dy) / canvasTheme.rulerHeight,
    );

    return result;
  }

  static Offset pointToOffset(WidgetCanvasThemeData canvasTheme, Offset delta) {
    final result = Offset(
      delta.dx * canvasTheme.rulerWidth,
      delta.dy * canvasTheme.rulerHeight,
    );
    return result;
  }

  final double scaleFactor;
  final ValueChanged<double> onUpdateScale;
  final WidgetCanvasThemeData Function(double scale) scaleCanvasThemeDataBuilder;

  final double minScaleFactor;
  final double maxScaleFactor;

  final ScrollController horizontalScrollController;
  final ScrollController verticalScrollController;

  final Widget child;

  @override
  State<WidgetCanvasZoomDetector> createState() => _WidgetCanvasZoomDetectorState();
}

class _WidgetCanvasZoomDetectorState extends State<WidgetCanvasZoomDetector> {
  Offset? _referenceFocalPoint;
  double? _scaleStart;

  WidgetCanvasThemeData getCanvasTheme(double scale) {
    return GateCanvas.defaultWidgetCanvasTheme * scale;
  }

  Offset _pointToOffset(WidgetCanvasThemeData canvasTheme, Offset delta) {
    final result = Offset(
      delta.dx * canvasTheme.rulerWidth,
      delta.dy * canvasTheme.rulerHeight,
    );
    return result;
  }

  void _translateCanvas(Offset translate) {
    widget.horizontalScrollController.jumpTo(widget.horizontalScrollController.offset + translate.dx);
    widget.verticalScrollController.jumpTo(widget.verticalScrollController.offset + translate.dy);
  }

  void onStartScale(WidgetCanvasThemeData canvasTheme, ScaleStartDetails details) {
    _referenceFocalPoint = WidgetCanvasZoomDetector.localToViewportPoint(
      canvasTheme,
      details.localFocalPoint,
      origin: Offset(widget.horizontalScrollController.offset, widget.verticalScrollController.offset),
    );
    _scaleStart = widget.scaleFactor;
  }

  void onUpdateScale(WidgetCanvasThemeData canvasTheme, ScaleUpdateDetails details) {
    assert(_referenceFocalPoint != null);
    assert(_scaleStart != null);

    final double desiredScale = _scaleStart! * details.scale;

    if (desiredScale < widget.minScaleFactor) return;
    if (desiredScale > widget.maxScaleFactor) return;

    widget.onUpdateScale(desiredScale);

    final newCanvasTheme = getCanvasTheme(desiredScale);

    final Offset focalPointSceneScaled = WidgetCanvasZoomDetector.localToViewportPoint(
      newCanvasTheme,
      details.localFocalPoint,
      origin: Offset(widget.horizontalScrollController.offset, widget.verticalScrollController.offset),
    );
    final Offset translate = _pointToOffset(newCanvasTheme, _referenceFocalPoint! - focalPointSceneScaled);
    _translateCanvas(translate);
  }

  void onEndScale() {
    _referenceFocalPoint = null;
    _scaleStart = null;
  }

  @override
  Widget build(BuildContext context) {
    final canvasTheme = getCanvasTheme(widget.scaleFactor);

    return RawGestureDetector(
      gestures: {
        ScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
          () => ScaleGestureRecognizer(),
          (instance) => instance
            ..onStart = (details) {
              onStartScale(canvasTheme, details);
            }
            ..onUpdate = (details) {
              onUpdateScale(canvasTheme, details);
            }
            ..onEnd = (details) {
              onEndScale();
            },
        ),
      },
      child: widget.child,
    );
  }
}
