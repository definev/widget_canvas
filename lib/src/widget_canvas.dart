import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'domain/binary_list.dart';
import 'domain/canvas_element.dart';

class WidgetCanvasSharedData extends InheritedWidget {
  const WidgetCanvasSharedData({
    super.key,
    this.rulerUnit = WidgetCanvasChildDelegate.rulerUnit,
    required super.child,
  });

  static WidgetCanvasSharedData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WidgetCanvasSharedData>()!;
  }

  final double rulerUnit;

  double get scaleFactor => rulerUnit / WidgetCanvasChildDelegate.rulerUnit;

  @override
  bool updateShouldNotify(covariant WidgetCanvasSharedData oldWidget) {
    return rulerUnit != oldWidget.rulerUnit;
  }
}

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
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
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
    return WidgetCanvasRenderTwoDimensionalViewport<T>(
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
      ..verticalAxisDirection = verticalAxisDirection
      ..verticalOffset = verticalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..horizontalOffset = horizontalOffset
      ..mainAxis = mainAxis
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior;
  }
}

class WidgetCanvasRenderTwoDimensionalViewport<T> extends RenderTwoDimensionalViewport {
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

  static const int rulerVerticalLayer = 1;
  static const int rulerHorizontalLayer = 2;
  static const int contentLayer = 3;

  List<CanvasElement<T>>? _visibleElements;

  Map<ChildVicinity, CanvasElement<T>?>? _sortedElements;

  List<CanvasElement<T>> getVisibleElement(
    WidgetCanvasElements<T> elements, {
    required Offset topLeftScreen,
    required Offset bottomRightScreen,
  }) {
    _sortedElements = null;
    _sortedElements = {};

    (Offset topLeft, Offset bottomRight) getCorner(CanvasElement<T> element) {
      final topLeft = element.coordinate;
      final size = element.size.value;
      final bottomRight = topLeft + size.bottomRight(Offset.zero);
      return (topLeft, bottomRight);
    }

    var sorted = elements.list.whereIndexed(
      (element) {
        final (topLeft, bottomRight) = getCorner(element);
        return switch (true) {
          _ when topLeft.dx < topLeftScreen.dx && bottomRight.dx < topLeftScreen.dx => -1,
          _ when topLeft.dx > bottomRightScreen.dx && bottomRight.dx > bottomRightScreen.dx => 1,
          _ => 0,
        };
      },
    );

    sorted = sorted //
        ?.binaryList(WidgetCanvasChildDelegate.defaultCompare(Axis.vertical))
        .whereIndexed(
      (element) {
        final (topLeft, bottomRight) = getCorner(element);
        return switch (true) {
          _ when topLeft.dy < topLeftScreen.dy && bottomRight.dy < topLeftScreen.dy => -1,
          _ when topLeft.dy > bottomRightScreen.dy && bottomRight.dy > bottomRightScreen.dy => 1,
          _ => 0,
        };
      },
    );

    final list = sorted?.list ?? [];

    for (final selected in elements.perminantVisibleSet) {
      final index = list.indexOf(selected);
      if (index == -1) {
        list.add(selected);
      } else {
        list[index] = selected;
      }
    }

    for (final element in list) {
      _sortedElements![element.vicinity] = element;
    }

    (delegate as WidgetCanvasChildDelegate)._sortedElements = _sortedElements!;
    return list;
  }

  @override
  void dispose() {
    _visibleElements = null;
    _sortedElements = null;
    super.dispose();
  }

  @override
  void layoutChildSequence() {
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
    var bottomRight = Offset(horizontalPixels, verticalPixels) + Offset(viewportWidth, viewportHeight);

    final canvasDelegate = delegate as WidgetCanvasChildDelegate<T>;
    if (canvasDelegate.showGrid) {
      final dimension = canvasDelegate.unit;
      final baseColumn = (horizontalPixels / dimension).floor();
      for (var column = 0; column <= (viewportWidth + cacheExtent) ~/ dimension; column += 1) {
        if (buildOrObtainChildFor(ChildVicinity(xIndex: column, yIndex: rulerVerticalLayer)) case final child?) {
          child.layout(constraints.loosen());
          parentDataOf(child).layoutOffset = Offset((baseColumn + column) * dimension, 0) - Offset(horizontalPixels, 0);
        }
      }
      final baseRow = (verticalPixels / dimension).floor();
      for (var row = 0; row <= (viewportHeight + cacheExtent) ~/ dimension; row += 1) {
        if (buildOrObtainChildFor(ChildVicinity(xIndex: row, yIndex: rulerHorizontalLayer)) case final child?) {
          child.layout(constraints.loosen());
          parentDataOf(child).layoutOffset = Offset(0, (baseRow + row) * dimension) - Offset(0, verticalPixels);
        }
      }
    }

    _visibleElements = getVisibleElement(
      canvasDelegate.elements,
      topLeftScreen: topLeft - Offset(cacheExtent, cacheExtent),
      bottomRightScreen: bottomRight + Offset(cacheExtent, cacheExtent),
    );

    for (final element in _visibleElements!) {
      if (buildOrObtainChildFor(element.vicinity) case final child?) {
        element.addListener(markNeedsLayout);
        element.size.addListener(markNeedsLayout);

        child.layout(BoxConstraints.tight(element.size.value));
        parentDataOf(child).layoutOffset = element.coordinate - topLeft;
      }
    }

    verticalOffset.applyContentDimensions(double.negativeInfinity, double.infinity);
    horizontalOffset.applyContentDimensions(double.negativeInfinity, double.infinity);
  }
}

class WidgetCanvasChildDelegate<T> extends TwoDimensionalChildDelegate {
  WidgetCanvasChildDelegate({
    required this.elements,
    required this.builder,
    this.showGrid = true,
    this.unit = rulerUnit,
  });

  static const double rulerUnit = 100;

  static Comparator<CanvasElement<T>> defaultCompare<T>(Axis axis) => switch (axis) {
        Axis.horizontal => (a, b) => a.coordinate.dx.compareTo(b.coordinate.dx),
        Axis.vertical => (a, b) => a.coordinate.dy.compareTo(b.coordinate.dy),
      };

  final WidgetCanvasElements<T> elements;
  final Widget Function(BuildContext context, CanvasElement<T> element) builder;
  final bool showGrid;
  final double unit;

  Map<ChildVicinity, CanvasElement<T>?> _sortedElements = {};

  @override
  Widget? build(BuildContext context, ChildVicinity vicinity) {
    if (vicinity == const ChildVicinity(xIndex: -1, yIndex: 0)) {
      return const SizedBox.square();
    }
    if (vicinity.yIndex == WidgetCanvasRenderTwoDimensionalViewport.rulerVerticalLayer) {
      return const VerticalDivider(width: 1);
    }
    if (vicinity.yIndex == WidgetCanvasRenderTwoDimensionalViewport.rulerHorizontalLayer) {
      return const Divider(height: 1);
    }
    if (_sortedElements[vicinity] case final element?) {
      return WidgetCanvasSharedData(
        rulerUnit: unit,
        child: Builder(builder: (context) => builder(context, element)),
      );
    }

    return null;
  }

  @override
  bool shouldRebuild(covariant WidgetCanvasChildDelegate<T> oldDelegate) => elements != oldDelegate.elements;
}
