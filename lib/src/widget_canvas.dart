import 'dart:math' as math;

import 'package:boxy/padding.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

import 'domain/binary_list.dart';
import 'domain/canvas_element.dart';

// Given a velocity and drag, calculate the time at which motion will come to
// a stop, within the margin of effectivelyMotionless.
double _getFinalTime(double velocity, double drag, {double effectivelyMotionless = 10}) {
  return math.log(effectivelyMotionless / velocity) / math.log(drag / 100);
}

class ZoomableWidgetCanvas<T> extends StatefulWidget {
  final TransformationController? transformationController;
  final double minScale;
  final double maxScale;

  /// Changes the deceleration behavior after a gesture.
  ///
  /// Defaults to 0.0000135.
  ///
  /// Must be a finite number greater than zero.
  final double interactionEndFrictionCoefficient;

  /// Determines the amount of scale to be performed per pointer scroll.
  ///
  /// Defaults to [kDefaultMouseScrollToScaleFactor].
  ///
  /// Increasing this value above the default causes scaling to feel slower,
  /// while decreasing it causes scaling to feel faster.
  ///
  /// The amount of scale is calculated as the exponential function of the
  /// [PointerScrollEvent.scrollDelta] to [scaleFactor] ratio. In the Flutter
  /// engine, the mousewheel [PointerScrollEvent.scrollDelta] is hardcoded to 20
  /// per scroll, while a trackpad scroll can be any amount.
  ///
  /// Affects only pointer device scrolling, not pinch to zoom.
  final double scaleFactor;

  final WidgetCanvasChildDelegate<T> delegate;
  final double? cacheExtent;
  final Clip clipBehavior;
  final DiagonalDragBehavior diagonalDragBehavior;
  final ScrollableDetails verticalDetails;
  final ScrollableDetails horizontalDetails;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final Axis mainAxis;
  final bool? primary;

  const ZoomableWidgetCanvas({
    super.key,
    required this.delegate,
    this.transformationController,
    this.cacheExtent,
    this.clipBehavior = Clip.hardEdge,
    this.diagonalDragBehavior = DiagonalDragBehavior.free,
    this.verticalDetails = const ScrollableDetails.vertical(),
    this.horizontalDetails = const ScrollableDetails.horizontal(),
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.mainAxis = Axis.vertical,
    this.primary,
    this.minScale = 0.7,
    this.maxScale = 2.5,
    this.interactionEndFrictionCoefficient = 0.0000135,
    this.scaleFactor = 200,
  });

  @override
  State<ZoomableWidgetCanvas<T>> createState() => _ZoomableWidgetCanvasState<T>();
}

class _ZoomableWidgetCanvasState<T> extends State<ZoomableWidgetCanvas<T>> with SingleTickerProviderStateMixin {
  double getMaxAxis(double maxValue) => switch (_transformationController.value.getMaxScaleOnAxis()) {
        final scale when scale == 1 => maxValue,
        final scale when scale > 1 => maxValue * (scale - 1),
        final scale when scale < 1 => maxValue * (1 + (1 - scale)),
        _ => throw Exception(),
      };

  double getMaxWidth(BoxConstraints constraints) => getMaxAxis(constraints.maxWidth);
  double getMaxHeight(BoxConstraints constraints) => getMaxAxis(constraints.maxHeight);

  late TransformationController _transformationController;

  Animation<double>? _scaleAnimation;
  late AnimationController _scaleController;
  double? _scaleStart; // Scale value at start of scaling gesture.

  Matrix4 _matrixScale(Matrix4 matrix, double scale) {
    if (scale == 1.0) {
      return matrix.clone();
    }
    assert(scale != 0.0);

    // Don't allow a scale that results in an overall scale beyond min/max
    // scale.
    final double currentScale = _transformationController.value.getMaxScaleOnAxis();
    final double totalScale = currentScale * scale;
    final double clampedTotalScale = totalScale.clamp(
      widget.minScale,
      widget.maxScale,
    );
    final double clampedScale = clampedTotalScale / currentScale;
    return matrix.clone()..scale(clampedScale);
  }

  // Handle the start of a gesture. All of pan, scale, and rotate are handled
  // with GestureDetector's scale gesture.
  void _onScaleStart(ScaleStartDetails details) {
    if (_scaleController.isAnimating) {
      _scaleController.stop();
      _scaleController.reset();
      _scaleAnimation?.removeListener(_onScaleAnimate);
      _scaleAnimation = null;
    }

    _scaleStart = _transformationController.value.getMaxScaleOnAxis();
  }

  // Handle an update to an ongoing gesture. All of pan, scale, and rotate are
  // handled with GestureDetector's scale gesture.
  void _onScaleUpdate(ScaleUpdateDetails details) {
    final double scale = _transformationController.value.getMaxScaleOnAxis();

    final double desiredScale = _scaleStart! * details.scale;
    final double scaleChange = desiredScale / scale;
    _transformationController.value = _matrixScale(
      _transformationController.value,
      scaleChange,
    );
  }

  // Handle the end of a gesture of _GestureType. All of pan, scale, and rotate
  // are handled with GestureDetector's scale gesture.
  void _onScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;

    _scaleAnimation?.removeListener(_onScaleAnimate);
    _scaleController.reset();

    if (details.scaleVelocity.abs() < 0.1) {
      return;
    }
    final double scale = _transformationController.value.getMaxScaleOnAxis();
    final FrictionSimulation frictionSimulation = FrictionSimulation(
        widget.interactionEndFrictionCoefficient * widget.scaleFactor, scale, details.scaleVelocity / 10);
    final double tFinal = _getFinalTime(details.scaleVelocity.abs(), widget.interactionEndFrictionCoefficient,
        effectivelyMotionless: 0.1);
    _scaleAnimation = Tween<double>(begin: scale, end: frictionSimulation.x(tFinal))
        .animate(CurvedAnimation(parent: _scaleController, curve: Curves.decelerate));
    _scaleController.duration = Duration(milliseconds: (tFinal * 1000).round());
    _scaleAnimation!.addListener(_onScaleAnimate);
    _scaleController.forward();
  }

  // Handle mousewheel and web trackpad scroll events.
  void _receivedPointerSignal(PointerSignalEvent event) {
    final double scaleChange;
    if (event is PointerScrollEvent) {
      if (event.kind == PointerDeviceKind.trackpad) {
        // Trackpad scroll, so treat it as a pan.
        return;
      }
      // Ignore left and right mouse wheel scroll.
      if (event.scrollDelta.dy == 0.0) {
        return;
      }
      scaleChange = math.exp(-event.scrollDelta.dy / widget.scaleFactor);
    } else if (event is PointerScaleEvent) {
      scaleChange = event.scale;
    } else {
      return;
    }

    _transformationController.value = _matrixScale(
      _transformationController.value,
      scaleChange,
    );
  }

  // Handle inertia scale animation.
  void _onScaleAnimate() {
    if (!_scaleController.isAnimating) {
      _scaleAnimation?.removeListener(_onScaleAnimate);
      _scaleAnimation = null;
      _scaleController.reset();
      return;
    }
    final double desiredScale = _scaleAnimation!.value;
    final double scaleChange = desiredScale / _transformationController.value.getMaxScaleOnAxis();

    _transformationController.value = _matrixScale(
      _transformationController.value,
      scaleChange,
    );
  }

  void _onTransformationControllerChange() {
    // A change to the TransformationController's value is a change to the
    // state.
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _transformationController = widget.transformationController ?? TransformationController();
    _transformationController.addListener(_onTransformationControllerChange);
    _scaleController = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(ZoomableWidgetCanvas<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle all cases of needing to dispose and initialize
    // transformationControllers.
    if (oldWidget.transformationController != widget.transformationController) {
      _transformationController.removeListener(_onTransformationControllerChange);
      _transformationController.dispose();
      _transformationController = widget.transformationController ?? TransformationController();
      _transformationController.addListener(_onTransformationControllerChange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _receivedPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Necessary when panning off screen.
        onScaleEnd: _onScaleEnd,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        trackpadScrollCausesScale: false,
        trackpadScrollToScaleFactor: Offset(0, -1 / widget.scaleFactor),
        child: Transform(
          transform: _transformationController.value,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = getMaxHeight(constraints);
              final maxWidth = getMaxWidth(constraints);
              print(maxHeight);
              print(maxWidth);

              return OverflowPadding(
                padding: EdgeInsets.symmetric(
                  vertical: -maxHeight / 2,
                  horizontal: -maxWidth / 2,
                ),
                child: WidgetCanvas<T>(
                  delegate: widget.delegate,
                  cacheExtent: widget.cacheExtent,
                  clipBehavior: Clip.hardEdge,
                  diagonalDragBehavior: widget.diagonalDragBehavior,
                  verticalDetails: widget.verticalDetails,
                  horizontalDetails: widget.horizontalDetails,
                  dragStartBehavior: widget.dragStartBehavior,
                  keyboardDismissBehavior: widget.keyboardDismissBehavior,
                  mainAxis: widget.mainAxis,
                  primary: widget.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
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

  List<CanvasElement<T>> getVisibleElement(WidgetCanvasElements<T> elements, Offset topLeft, Offset bottomRight) {
    _sortedElements = null;
    _sortedElements = {};
    var sorted = elements.list.whereIndexed(
      (element) => BinaryList //
              .isInRange(topLeft.dx, bottomRight.dx, (a, b) => a.compareTo(b)) //
          (element.coordinate.dx),
    );
    if (sorted == null) return <CanvasElement<T>>[];
    sorted = sorted //
        .binaryList(WidgetCanvasChildDelegate.defaultCompare(Axis.vertical))
        .whereIndexed(
          (element) => BinaryList //
                  .isInRange(topLeft.dy, bottomRight.dy, (a, b) => a.compareTo(b)) //
              (element.coordinate.dy),
        );
    if (sorted == null) return <CanvasElement<T>>[];

    final list = sorted.list;

    for (final selected in elements.selected) {
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
      }
    }

    final horizontalPixels = horizontalOffset.pixels;
    final verticalPixels = verticalOffset.pixels;
    final viewportHeight = viewportDimension.height + cacheExtent;
    final viewportWidth = viewportDimension.width + cacheExtent;

    final topLeft = Offset(horizontalPixels, verticalPixels);
    final bottomRight = Offset(horizontalPixels, verticalPixels) + Offset(viewportWidth, viewportHeight);

    final canvasDelegate = delegate as WidgetCanvasChildDelegate<T>;
    if (canvasDelegate.showGrid) {
      final dimension = canvasDelegate.unit;
      final baseColumn = (horizontalPixels / dimension).floor();
      for (var column = 0; column < viewportWidth ~/ dimension; column += 1) {
        if (buildOrObtainChildFor(ChildVicinity(xIndex: column, yIndex: rulerVerticalLayer)) case final child?) {
          child.layout(constraints.loosen());
          parentDataOf(child).layoutOffset = Offset((baseColumn + column) * dimension, 0) - Offset(horizontalPixels, 0);
        }
      }
      final baseRow = (verticalPixels / dimension).floor();
      for (var row = 0; row < viewportHeight ~/ dimension; row += 1) {
        if (buildOrObtainChildFor(ChildVicinity(xIndex: row, yIndex: rulerHorizontalLayer)) case final child?) {
          child.layout(constraints.loosen());
          parentDataOf(child).layoutOffset = Offset(0, (baseRow + row) * dimension) - Offset(0, verticalPixels);
        }
      }
    }

    _visibleElements = getVisibleElement(
      canvasDelegate.elements,
      topLeft - Offset(cacheExtent, cacheExtent),
      bottomRight,
    );

    for (final element in _visibleElements!) {
      if (buildOrObtainChildFor(element.vicinity) case final child?) {
        element.addListener(markNeedsLayout);
        child.layout(constraints.loosen());
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
      return builder(context, element);
    }

    return null;
  }

  @override
  bool shouldRebuild(covariant WidgetCanvasChildDelegate<T> oldDelegate) => false;
}
