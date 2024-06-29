import 'package:flutter/material.dart';
import 'package:widget_canvas/src/widget_canvas.dart';

typedef Coordinate = Offset;

class CanvasElement<T> extends ValueNotifier<Coordinate>
    implements Comparable<CanvasElement<Object?>> {
  CanvasElement(
    super._value, {
    required this.id,
    required this.data,
    required this.size,
    this.layer,
  });

  final int id;
  final T data;
  final int? layer;
  final ValueNotifier<Size> size;
  Size getScaledSize(double scaleFactor) {
    if (scaleFactor < 1.0) return size.value;
    return Size(
      size.value.width * scaleFactor,
      size.value.height * scaleFactor,
    );
  }

  Coordinate get coordinate => value;
  set coordinate(Coordinate coordinate) => value = coordinate;

  final ValueNotifier<bool> _isPerminantVisible = ValueNotifier(false);
  late ValueNotifier<bool> isPerminantVisibleNotifier = _isPerminantVisible;
  bool get isPerminantVisible => _isPerminantVisible.value;
  set isPerminantVisible(bool value) {
    if (_isPerminantVisible.value == value) return;
    _isPerminantVisible.value = value;
  }

  late final ChildVicinity vicinity = ChildVicinity(
    xIndex: id,
    yIndex: layer ?? WidgetCanvasRenderTwoDimensionalViewport.contentLayer,
  );

  @override
  bool operator ==(Object other) => other is CanvasElement
      ? value == other.value && id == other.id && layer == other.layer
      : false;

  @override
  int get hashCode => id;

  @override
  int compareTo(CanvasElement<Object?> other) => id.compareTo(other.id);
}
