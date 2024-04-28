import 'package:flutter/material.dart';
import 'package:widget_canvas/src/widget_canvas.dart';

typedef Coordinate = Offset;

class CanvasElement<T> extends ValueNotifier<Coordinate> implements Comparable<CanvasElement<Object?>> {
  CanvasElement(
    super._value, {
    required this.id,
    required this.data,
    this.layer,
  });

  final int id;
  final T data;
  final int? layer;

  Coordinate get coordinate => value;
  set coordinate(Coordinate coordinate) => value = coordinate;

  bool _isSelected = false;
  bool get isSelected => _isSelected;
  set isSelected(bool value) {
    if (_isSelected == value) return;
    _isSelected = value;
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

  CanvasElement<E> cast<E>() => CanvasElement(
        value,
        id: id,
        data: data as E,
        layer: layer,
      );
}
