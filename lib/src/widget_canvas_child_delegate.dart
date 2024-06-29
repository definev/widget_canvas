import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

class WidgetCanvasChildDelegate<T> extends TwoDimensionalChildDelegate {
  WidgetCanvasChildDelegate({
    required this.elements,
    required this.builder,
    this.showGrid = true,
  });

  static Comparator<CanvasElement<T>> defaultCompare<T>(
          Axis axis, double scaleFactor) =>
      switch (axis) {
        Axis.horizontal => (a, b) => a
            .getScaledCoordinate(scaleFactor)
            .dx
            .compareTo(b.getScaledCoordinate(scaleFactor).dx),
        Axis.vertical => (a, b) => a
            .getScaledCoordinate(scaleFactor)
            .dy
            .compareTo(b.getScaledCoordinate(scaleFactor).dy),
      };

  final WidgetCanvasElements<T> elements;
  final Widget Function(BuildContext context, CanvasElement<T> element) builder;
  final bool showGrid;

  late WidgetCanvasRenderTwoDimensionalViewport<T> renderViewport;

  @override
  Widget? build(BuildContext context, ChildVicinity vicinity) {
    if (vicinity == const ChildVicinity(xIndex: -1, yIndex: 0)) {
      return const SizedBox.square();
    }

    if (vicinity.yIndex ==
        WidgetCanvasRenderTwoDimensionalViewport.rulerVerticalLayer) {
      return Builder(
        builder: (context) {
          final data = WidgetCanvasTheme.of(context);
          return ListenableBuilder(
            listenable: data,
            builder: (context, _) => IgnorePointer(
              child: VerticalDivider(
                width: data.value.scaleFactor,
                thickness: data.value.scaleFactor,
                color: data.value.rulerColor,
              ),
            ),
          );
        },
      );
    }
    if (vicinity.yIndex ==
        WidgetCanvasRenderTwoDimensionalViewport.rulerHorizontalLayer) {
      return Builder(
        builder: (context) {
          final data = WidgetCanvasTheme.of(context);
          return ListenableBuilder(
            listenable: data,
            builder: (context, _) => IgnorePointer(
              child: Divider(
                height: data.value.scaleFactor,
                thickness: data.value.scaleFactor,
                color: data.value.rulerColor,
              ),
            ),
          );
        },
      );
    }

    if (renderViewport.sortedElements![vicinity] case final element?) {
      return builder(context, element);
    }

    return null;
  }

  @override
  bool shouldRebuild(covariant WidgetCanvasChildDelegate<T> oldDelegate) =>
      elements != oldDelegate.elements;
}
