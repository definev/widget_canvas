import 'package:flutter/material.dart';
import 'package:widget_canvas/src/domain/widget_canvas_elements.dart';
import 'package:widget_canvas/widget_canvas.dart';

class WidgetCanvasChildDelegate<T> extends TwoDimensionalChildDelegate {
  WidgetCanvasChildDelegate({
    required this.elements,
    required this.builder,
    this.showGrid = true,
  });

  static Comparator<CanvasElement<T>> defaultCompare<T>(Axis axis) => switch (axis) {
        Axis.horizontal => (a, b) => a.coordinate.dx.compareTo(b.coordinate.dx),
        Axis.vertical => (a, b) => a.coordinate.dy.compareTo(b.coordinate.dy),
      };

  final WidgetCanvasElements<T> elements;
  final Widget Function(BuildContext context, CanvasElement<T> element) builder;
  final bool showGrid;

  late WidgetCanvasRenderTwoDimensionalViewport<T> renderViewport;

  @override
  Widget? build(BuildContext context, ChildVicinity vicinity) {
    final theme = Theme.of(context);
    final data = WidgetCanvasTheme.maybeOf(context) ?? WidgetCanvasThemeData.defaultValue;
    final WidgetCanvasThemeData(:scaleFactor, :rulerColor, :rulerThickness) = data;

    if (vicinity == const ChildVicinity(xIndex: -1, yIndex: 0)) {
      return const SizedBox.square();
    }
    if (vicinity.yIndex == WidgetCanvasRenderTwoDimensionalViewport.rulerVerticalLayer) {
      return IgnorePointer(
        child: VerticalDivider(
          width: rulerThickness * scaleFactor,
          thickness: rulerThickness * scaleFactor,
          color: rulerColor,
        ),
      );
    }
    if (vicinity.yIndex == WidgetCanvasRenderTwoDimensionalViewport.rulerHorizontalLayer) {
      return IgnorePointer(
        child: Divider(
          height: rulerThickness * scaleFactor,
          thickness: rulerThickness * scaleFactor,
          color: rulerColor,
        ),
      );
    }

    if (renderViewport.sortedElements![vicinity] case final element?) {
      return WidgetCanvasTheme(
        data: data,
        child: Theme(
          data: theme.copyWith(
            textTheme: theme.textTheme.apply(fontSizeFactor: scaleFactor),
          ),
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return DefaultTextStyle(
                style: theme.textTheme.titleLarge!.copyWith(color: Colors.black),
                child: Builder(builder: (context) => builder(context, element)),
              );
            },
          ),
        ),
      );
    }

    return null;
  }

  @override
  bool shouldRebuild(covariant WidgetCanvasChildDelegate<T> oldDelegate) => elements != oldDelegate.elements;
}
