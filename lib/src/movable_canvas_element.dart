import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

class MovableCanvasElement<T> extends StatefulWidget {
  const MovableCanvasElement(
    this.data, {
    super.key,
    required this.elements,
    required this.onElementsChanged,
    required this.child,
    this.snap = false,
  });

  final CanvasElement<T> data;
  final WidgetCanvasElements<T> elements;
  final ValueChanged<WidgetCanvasElements<T>> onElementsChanged;
  final bool snap;
  final Widget child;

  @override
  State<MovableCanvasElement<T>> createState() => _MovableCanvasElementState<T>();
}

class _MovableCanvasElementState<T> extends State<MovableCanvasElement<T>> {
  ValueChanged<Offset> get onCanvasElementMove =>
      (coordinate) => widget.onElementsChanged(widget.elements.selectElement(widget.data..coordinate = coordinate));

  VoidCallback get onCanvasElementMoveEnd =>
      () => widget.onElementsChanged(widget.elements.unselectElement(widget.data));
  Offset? lastOffset;
  Offset? startPosition;

  @override
  Widget build(BuildContext context) {
    final WidgetCanvasSharedData(:rulerUnit) = WidgetCanvasSharedData.of(context);

    return Listener(
      onPointerDown: (details) {
        lastOffset = widget.data.coordinate;
        startPosition = details.localPosition;
      },
      onPointerMove: (details) {
        if (lastOffset == null) return;
        if (startPosition == null) return;

        final endPosition = details.localPosition;
        var delta = endPosition - startPosition!;
        var newOffset = lastOffset! + delta;
        if (widget.snap) {
          newOffset = Offset(
            (newOffset.dx / rulerUnit).round() * rulerUnit,
            (newOffset.dy / rulerUnit).round() * rulerUnit,
          );
        }

        onCanvasElementMove(newOffset);
      },
      onPointerCancel: (_) {
        lastOffset = null;
        startPosition = null;
        onCanvasElementMoveEnd();
      },
      onPointerUp: (_) {
        lastOffset = null;
        startPosition = null;
        onCanvasElementMoveEnd();
      },
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
