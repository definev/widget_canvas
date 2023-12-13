import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:widget_canvas/src/widget_canvas_child_delegate.dart';

class WidgetCanvas extends TwoDimensionalScrollView {
  const WidgetCanvas({
    super.key,
    required super.delegate,
    super.cacheExtent,
    super.clipBehavior,
    super.diagonalDragBehavior,
    super.verticalDetails = const ScrollableDetails.vertical(),
    super.horizontalDetails = const ScrollableDetails.horizontal(),
    super.dragStartBehavior = DragStartBehavior.start,
    super.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.mainAxis = Axis.vertical,
    super.primary,
  });

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return WidgetCanvasTwoDimensionalViewport(
      delegate: delegate,
      horizontalAxisDirection: horizontalDetails.direction,
      horizontalOffset: horizontalOffset,
      verticalAxisDirection: verticalDetails.direction,
      verticalOffset: verticalOffset,
      mainAxis: mainAxis,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }
}

class WidgetCanvasTwoDimensionalViewport extends TwoDimensionalViewport {
  const WidgetCanvasTwoDimensionalViewport({
    super.key,
    required super.delegate,
    required super.horizontalAxisDirection,
    required super.horizontalOffset,
    required super.verticalAxisDirection,
    required super.verticalOffset,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior,
  });

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return WidgetCanvasRenderTwoDimensionalViewport(
      childManager: context as TwoDimensionalChildManager,
      delegate: delegate,
      horizontalAxisDirection: horizontalAxisDirection,
      horizontalOffset: horizontalOffset,
      verticalAxisDirection: verticalAxisDirection,
      verticalOffset: verticalOffset,
      mainAxis: mainAxis,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant WidgetCanvasRenderTwoDimensionalViewport renderObject,
  ) {
    renderObject
      ..delegate = delegate
      ..horizontalAxisDirection = horizontalAxisDirection
      ..horizontalOffset = horizontalOffset
      ..mainAxis = mainAxis
      ..verticalAxisDirection = verticalAxisDirection
      ..verticalOffset = verticalOffset
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior;
  }
}

class WidgetCanvasRenderTwoDimensionalViewport extends RenderTwoDimensionalViewport {
  WidgetCanvasRenderTwoDimensionalViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    required super.childManager,
    required super.cacheExtent,
    required super.clipBehavior,
  });

  @override
  void layoutChildSequence() {
    final horizontalPixels = horizontalOffset.pixels;
    final verticalPixels = verticalOffset.pixels;
    final viewportHeight = viewportDimension.height + cacheExtent;
    final viewportWidth = viewportDimension.width + cacheExtent;

    final canvasDelegate = delegate as WidgetCanvasChildDelegate;
    if (canvasDelegate.showGrid) {
      final dimension = canvasDelegate.dimension;
      final baseColumn = (horizontalPixels / dimension).floor();
      for (var column = 0; column < viewportWidth ~/ dimension; column += 1) {
        if (buildOrObtainChildFor(ChildVicinity(xIndex: column, yIndex: 1)) case final child?) {
          child.layout(constraints.loosen());
          parentDataOf(child).layoutOffset = Offset((baseColumn + column) * dimension, 0) - Offset(horizontalPixels, 0);
        }
      }
      final baseRow = (verticalPixels / dimension).floor();
      for (var row = 0; row < viewportHeight ~/ dimension; row += 1) {
        if (buildOrObtainChildFor(ChildVicinity(xIndex: row, yIndex: 2)) case final child?) {
          child.layout(constraints.loosen());
          parentDataOf(child).layoutOffset = Offset(0, (baseRow + row) * dimension) - Offset(0, verticalPixels);
        }
      }
    }

    final elements = canvasDelegate.getVisibleElement(
      Offset(horizontalPixels, verticalPixels) - Offset(cacheExtent, cacheExtent),
      Offset(horizontalPixels + viewportWidth, verticalPixels + viewportHeight),
    );

    if (elements.isEmpty) {
      if (buildOrObtainChildFor(const ChildVicinity(xIndex: -1, yIndex: 0)) case final child?) {
        child.layout(constraints.loosen());
        parentDataOf(child).layoutOffset = Offset(horizontalPixels, verticalPixels);
      }
      return;
    }

    for (final (vicinity, element) in elements) {
      if (buildOrObtainChildFor(vicinity) case final child?) {
        child.layout(constraints.loosen());
        parentDataOf(child).layoutOffset = element.offset - Offset(horizontalPixels, verticalPixels);
      }
    }

    verticalOffset.applyContentDimensions(double.negativeInfinity, double.infinity);
    horizontalOffset.applyContentDimensions(double.negativeInfinity, double.infinity);
  }
}
