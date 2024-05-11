import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

class MovableCanvasElementWidget<T> extends StatefulWidget {
  const MovableCanvasElementWidget(
    this.data, {
    super.key,
    required this.elements,
    required this.onElementsChanged,
    required this.child,
    this.onCanvasElementMove,
    this.snap = false,
  });

  final CanvasElement<T> data;
  final WidgetCanvasElements<T> elements;
  final ValueChanged<WidgetCanvasElements<T>> onElementsChanged;
  final ValueChanged<Offset>? onCanvasElementMove;
  final bool snap;
  final Widget child;

  @override
  State<MovableCanvasElementWidget<T>> createState() => _MovableCanvasElementWidgetState<T>();
}

class _MovableCanvasElementWidgetState<T> extends State<MovableCanvasElementWidget<T>> {
  ValueChanged<Offset> get onCanvasElementMove => (coordinate) {
        widget.onCanvasElementMove?.call(coordinate);
        widget.onElementsChanged(widget.elements.markElementIsPerminantVisible(widget.data..coordinate = coordinate));
      };

  VoidCallback get onCanvasElementMoveEnd => () {
        lastOffset = null;
        startPosition = null;
        widget.onElementsChanged(widget.elements.unmarkElementIsPerminantVisible(widget.data));
      };

  Offset? lastOffset;
  Offset? startPosition;

  @override
  Widget build(BuildContext context) {
    final WidgetCanvasSharedData(
      :rulerHeight,
      :rulerWidth,
    ) = WidgetCanvasShared.of(context);

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
        lastOffset = widget.data.coordinate;
        startPosition = details.localPosition;
      },
      onVerticalDragUpdate: (details) {
        if (lastOffset == null) return;
        if (startPosition == null) return;

        final endPosition = details.localPosition;
        var delta = endPosition - startPosition!;
        var newOffset = lastOffset! + delta;
        if (widget.snap) {
          newOffset = Offset(
            (newOffset.dx / rulerWidth).round() * rulerWidth,
            (newOffset.dy / rulerHeight).round() * rulerHeight,
          );
        }

        onCanvasElementMove(newOffset);
      },
      onVerticalDragCancel: () => onCanvasElementMoveEnd(),
      onVerticalDragEnd: (_) => onCanvasElementMoveEnd(),

      //

      onHorizontalDragStart: (details) {
        lastOffset = widget.data.coordinate;
        startPosition = details.localPosition;
        widget.data.isPerminantVisible = true;
      },
      onHorizontalDragUpdate: (details) {
        if (lastOffset == null) return;
        if (startPosition == null) return;

        final endPosition = details.localPosition;
        var delta = endPosition - startPosition!;
        var newOffset = lastOffset! + delta;
        if (widget.snap) {
          newOffset = Offset(
            (newOffset.dx / rulerWidth).round() * rulerWidth,
            (newOffset.dy / rulerHeight).round() * rulerHeight,
          );
        }

        onCanvasElementMove(newOffset);
      },
      onHorizontalDragCancel: () => onCanvasElementMoveEnd(),
      onHorizontalDragEnd: (_) => onCanvasElementMoveEnd(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
