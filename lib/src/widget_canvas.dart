import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:widget_canvas/src/domain/widget_canvas_elements.dart';
import 'package:widget_canvas/widget_canvas.dart';

export 'widget_canvas/widget_canvas_theme.dart';

class WidgetCanvas<T> extends TwoDimensionalScrollView {
  const WidgetCanvas._({
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

  factory WidgetCanvas({
    Key? key,
    required WidgetCanvasChildDelegate<T> delegate,
    double? cacheExtent,
    Clip clipBehavior = Clip.hardEdge,
    DiagonalDragBehavior diagonalDragBehavior = DiagonalDragBehavior.free,
    ScrollableDetails verticalDetails = const ScrollableDetails.vertical(),
    ScrollableDetails horizontalDetails = const ScrollableDetails.horizontal(),
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    Axis mainAxis = Axis.vertical,
    bool? primary,
  }) =>
      WidgetCanvas._(
        key: key,
        delegate: delegate,
        cacheExtent: cacheExtent,
        clipBehavior: clipBehavior,
        diagonalDragBehavior: diagonalDragBehavior,
        verticalDetails: verticalDetails,
        horizontalDetails: horizontalDetails,
        dragStartBehavior: dragStartBehavior,
        keyboardDismissBehavior: keyboardDismissBehavior,
        mainAxis: mainAxis,
        primary: primary,
      );

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return WidgetCanvasTwoDimensionalViewport<T>(
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

class WidgetCanvasTwoDimensionalViewport<T> extends TwoDimensionalViewport {
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
    final delegate = this.delegate as WidgetCanvasChildDelegate<T>;
    final renderViewport = WidgetCanvasRenderTwoDimensionalViewport<T>(
      context: context,
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

    delegate.renderViewport = renderViewport;

    return renderViewport;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant WidgetCanvasRenderTwoDimensionalViewport<T> renderObject,
  ) {
    renderObject
      ..delegate = ((delegate as WidgetCanvasChildDelegate<T>)
        ..renderViewport = renderObject)
      ..verticalAxisDirection = verticalAxisDirection
      ..verticalOffset = verticalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..horizontalOffset = horizontalOffset
      ..mainAxis = mainAxis
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior;
  }
}

class WidgetCanvasRenderTwoDimensionalViewport<T>
    extends RenderTwoDimensionalViewport {
  WidgetCanvasRenderTwoDimensionalViewport({
    required this.context,
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

  static const int rulerVerticalLayer = 1;
  static const int rulerHorizontalLayer = 2;
  static const int coordinateLayer = 3;
  static const int contentLayer = 10;

  final BuildContext context;

  List<CanvasElement<T>>? _visibleElements;

  Map<ChildVicinity, CanvasElement<T>?>? sortedElements = {};

  List<CanvasElement<T>> getVisibleElement(
    WidgetCanvasElements<T> elements, {
    required Offset topLeftView,
    required Offset bottomRightView,
  }) {
    sortedElements = null;
    sortedElements = {};

    (Offset topLeft, Offset bottomRight) getCorner(CanvasElement<T> element) {
      final topLeft = element.coordinate;
      final size = element.size.value;
      final bottomRight = topLeft + size.bottomRight(Offset.zero);
      return (topLeft, bottomRight);
    }

    BinaryList<CanvasElement<T>>? sorted = elements.list;
    sorted = sorted //
        .sort(WidgetCanvasChildDelegate.defaultCompare(Axis.horizontal))
        .whereIndexed((element) {
      final (topLeft, bottomRight) = getCorner(element);
      return switch (true) {
        _ when topLeft.dx < topLeftView.dx && bottomRight.dx < topLeftView.dx =>
          -1,
        _
            when topLeft.dx > bottomRightView.dx &&
                bottomRight.dx > bottomRightView.dx =>
          1,
        _ => 0,
      };
    });

    sorted = sorted //
        ?.sort(WidgetCanvasChildDelegate.defaultCompare(Axis.vertical))
        .whereIndexed((element) {
      final (topLeft, bottomRight) = getCorner(element);
      return switch (true) {
        _ when topLeft.dy < topLeftView.dy && bottomRight.dy < topLeftView.dy =>
          -1,
        _
            when topLeft.dy > bottomRightView.dy &&
                bottomRight.dy > bottomRightView.dy =>
          1,
        _ => 0,
      };
    });

    final list = sorted?.rawList ?? [];

    for (final selected in elements.perminantVisibleSet) {
      final index = list.indexOf(selected);
      if (index == -1) {
        list.add(selected);
      } else {
        list[index] = selected;
      }
    }

    for (final element in list) {
      sortedElements![element.vicinity] = element;
    }

    return list;
  }

  @override
  void dispose() {
    _visibleElements = null;
    sortedElements = null;
    super.dispose();
  }

  @override
  void layoutChildSequence() {
    final data = WidgetCanvasTheme.maybeOf(context) ??
        WidgetCanvasThemeData.defaultValue;

    if (_visibleElements case final elements?) {
      for (final element in elements) {
        element.removeListener(markNeedsLayout);
        element.size.removeListener(markNeedsLayout);
      }
    }

    final horizontalPixels = horizontalOffset.pixels;
    final verticalPixels = verticalOffset.pixels;
    final viewportHeight = viewportDimension.height;
    final viewportWidth = viewportDimension.width;

    var topLeft = Offset(horizontalPixels, verticalPixels);
    var bottomRight = Offset(horizontalPixels, verticalPixels) +
        Offset(viewportWidth, viewportHeight);

    final canvasDelegate = delegate as WidgetCanvasChildDelegate<T>;
    if (canvasDelegate.showGrid) {
      final rulerHeight = data.rulerHeight;
      final rulerWidth = data.rulerWidth;
      final thickness = data.rulerThickness * data.scaleFactor;

      final baseColumn = (horizontalPixels / rulerWidth).floor();
      final maxColumn = viewportWidth ~/ rulerWidth + 1;
      for (var column = 0; column <= maxColumn; column += 1) {
        if (buildOrObtainChildFor(
                ChildVicinity(xIndex: column, yIndex: rulerVerticalLayer))
            case final child?) {
          child.layout(constraints.loosen());
          parentDataOf(child).layoutOffset =
              Offset((baseColumn + column) * rulerWidth - thickness / 2, 0) -
                  Offset(horizontalPixels, 0);
        }
      }
      final baseRow = (verticalPixels / rulerHeight).floor();
      final maxRow = viewportHeight ~/ rulerHeight + 1;
      for (var row = 0; row <= maxRow; row += 1) {
        if (buildOrObtainChildFor(
                ChildVicinity(xIndex: row, yIndex: rulerHorizontalLayer))
            case final child?) {
          child.layout(constraints.loosen());
          parentDataOf(child).layoutOffset =
              Offset(0, (baseRow + row) * rulerHeight - thickness / 2) -
                  Offset(0, verticalPixels);
        }
      }
    }

    _visibleElements = getVisibleElement(
      canvasDelegate.elements,
      topLeftView: topLeft - Offset(cacheExtent, cacheExtent),
      bottomRightView: bottomRight + Offset(cacheExtent, cacheExtent),
    );

    for (final element in _visibleElements!) {
      if (buildOrObtainChildFor(element.vicinity) case final child?) {
        element.addListener(markNeedsLayout);
        element.size.addListener(markNeedsLayout);

        child.layout(
            BoxConstraints.tight(element.getScaledSize(data.scaleFactor)));
        parentDataOf(child).layoutOffset = element.coordinate - topLeft;
      }
    }

    verticalOffset.applyContentDimensions(
        double.negativeInfinity, double.infinity);
    horizontalOffset.applyContentDimensions(
        double.negativeInfinity, double.infinity);
  }
}
