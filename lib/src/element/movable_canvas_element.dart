import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

class MovableCanvasElement<T> extends StatefulWidget {
  const MovableCanvasElement({
    super.key,
    required this.data,
    required this.child,
    this.onCanvasElementMove,
    this.snap = false,
  });

  final CanvasElement<T> data;
  final ValueChanged<Offset>? onCanvasElementMove;
  final bool snap;
  final Widget child;

  @override
  State<MovableCanvasElement<T>> createState() =>
      _MovableCanvasElementState<T>();
}

class _MovableCanvasElementState<T> extends State<MovableCanvasElement<T>> {
  ValueChanged<Offset> onCanvasElementMove(double scaleFactor) => (coordinate) {
        widget.onCanvasElementMove?.call(coordinate);
        widget.data.setOriginalCoordinate(coordinate, scaleFactor);
      };

  VoidCallback get onCanvasElementMoveEnd => () {
        lastOffset = null;
        startPosition = null;
      };

  Offset? lastOffset;
  Offset? startPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      dragStartBehavior: DragStartBehavior.down,
      trackpadScrollCausesScale: true,
      supportedDevices: const {
        PointerDeviceKind.touch,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.stylus,
        PointerDeviceKind.mouse,
        PointerDeviceKind.unknown,
      },
      onVerticalDragStart: (details) {
        final canvasTheme = WidgetCanvasTheme.canvasThemeOf(context);
        lastOffset = widget.data.getScaledCoordinate(canvasTheme.scaleFactor);
        startPosition = details.localPosition;
      },
      onVerticalDragUpdate: (details) {
        final canvasTheme = WidgetCanvasTheme.canvasThemeOf(context);

        if (lastOffset == null) return;
        if (startPosition == null) return;

        final endPosition = details.localPosition;
        var delta = endPosition - startPosition!;
        var newOffset = lastOffset! + delta;
        if (widget.snap) {
          newOffset = Offset(
            (newOffset.dx / canvasTheme.rulerWidth).round() *
                canvasTheme.rulerWidth,
            (newOffset.dy / canvasTheme.rulerHeight).round() *
                canvasTheme.rulerHeight,
          );
        }

        onCanvasElementMove(canvasTheme.scaleFactor)(newOffset);
      },
      onVerticalDragCancel: () => onCanvasElementMoveEnd(),
      onVerticalDragEnd: (_) => onCanvasElementMoveEnd(),

      //

      onHorizontalDragStart: (details) {
        final canvasTheme = WidgetCanvasTheme.canvasThemeOf(context);

        lastOffset = widget.data.getScaledCoordinate(canvasTheme.scaleFactor);
        startPosition = details.localPosition;
        widget.data.isPerminantVisible = true;
      },
      onHorizontalDragUpdate: (details) {
        final canvasTheme = WidgetCanvasTheme.canvasThemeOf(context);

        if (lastOffset == null) return;
        if (startPosition == null) return;

        final endPosition = details.localPosition;
        var delta = endPosition - startPosition!;
        var newOffset = lastOffset! + delta;
        if (widget.snap) {
          newOffset = Offset(
            (newOffset.dx / canvasTheme.rulerWidth).round() *
                canvasTheme.rulerWidth,
            (newOffset.dy / canvasTheme.rulerHeight).round() *
                canvasTheme.rulerHeight,
          );
        }

        onCanvasElementMove(canvasTheme.scaleFactor)(newOffset);
      },
      onHorizontalDragCancel: () => onCanvasElementMoveEnd(),
      onHorizontalDragEnd: (_) => onCanvasElementMoveEnd(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
