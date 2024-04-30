import 'package:flutter/material.dart';
import 'package:widget_canvas/src/widget_canvas.dart';

typedef Coordinate = Offset;

class CanvasElement<T> extends ValueNotifier<Coordinate> implements Comparable<CanvasElement<Object?>> {
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

  Coordinate get coordinate => value;
  set coordinate(Coordinate coordinate) => value = coordinate;

  bool _isPerminantVisible = false;
  bool get isPerminantVisible => _isPerminantVisible;
  set isPerminantVisible(bool value) {
    if (_isPerminantVisible == value) return;
    _isPerminantVisible = value;
    notifyListeners();
  }

  late final ChildVicinity vicinity = ChildVicinity(
    xIndex: id,
    yIndex: layer ?? WidgetCanvasRenderTwoDimensionalViewport.contentLayer,
  );

  @override
  bool operator ==(Object other) =>
      other is CanvasElement ? value == other.value && id == other.id && layer == other.layer : false;

  @override
  int get hashCode => id;

  @override
  int compareTo(CanvasElement<Object?> other) => id.compareTo(other.id);
}
