import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

class MovableCanvasElement extends StatefulWidget {
  const MovableCanvasElement({
    super.key,
    required this.element,
    required this.elements,
    required this.dimension,
    required this.child,
    this.snap = false,
  });

  final CanvasElement element;
  final ValueNotifier<BinaryList<CanvasElement>> elements;
  final bool snap;
  final double dimension;
  final Widget child;

  @override
  State<MovableCanvasElement> createState() => _MovableCanvasElementState();
}

class _MovableCanvasElementState extends State<MovableCanvasElement> {
  late CanvasElement element;

  @override
  void initState() {
    super.initState();
    element = widget.element;
  }

  @override
  void didUpdateWidget(MovableCanvasElement oldWidget) {
    super.didUpdateWidget(oldWidget);
    element = widget.element;
  }
  
  ValueChanged<Offset> get onCanvasElementMove => (offset) {
        if (offset == element.offset) return;
        widget.elements.value = widget.elements.value.lockAt(
          widget.element,
          (element) => element.copyWith(offset: offset, isSelected: true),
        );
      };

  VoidCallback get onCanvasElementMoveEnd => () => widget.elements.value = widget.elements.value.unlockAt(
        element,
        (element) => element.copyWith(isSelected: false),
      );

  Offset? lastOffset;
  Offset? startPosition;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (details) {
        lastOffset = element.offset;
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
      onPointerCancel: (_) => onCanvasElementMoveEnd(),
      onPointerUp: (details) {
        lastOffset = null;
        startPosition = null;
        onCanvasElementMoveEnd();
      },
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
