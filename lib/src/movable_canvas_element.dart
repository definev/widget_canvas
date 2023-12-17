import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

class MovableCanvasElement<T> extends StatefulWidget {
  const MovableCanvasElement({
    super.key,
    required this.element,
    required this.elements,
    this.dimension = WidgetCanvasChildDelegate.rulerUnit,
    required this.child,
    this.snap = false,
  });

  final CanvasElement<T> element;
  final ValueNotifier<WidgetCanvasElements<T>> elements;
  final bool snap;
  final double dimension;
  final Widget child;

  @override
  State<MovableCanvasElement<T>> createState() => _MovableCanvasElementState<T>();
}

class _MovableCanvasElementState<T> extends State<MovableCanvasElement<T>> {
  ValueChanged<Offset> get onCanvasElementMove => (coordinate) => widget.elements.value =
      widget.elements.value.selectElement(widget.element..coordinate = coordinate);

  VoidCallback get onCanvasElementMoveEnd =>
      () => widget.elements.value = widget.elements.value.unselectElement(widget.element);
  Offset? lastOffset;
  Offset? startPosition;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (details) {
        lastOffset = widget.element.coordinate;
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
            (newOffset.dx / widget.dimension).round() * widget.dimension,
            (newOffset.dy / widget.dimension).round() * widget.dimension,
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
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}
