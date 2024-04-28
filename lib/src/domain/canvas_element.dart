import 'package:flutter/material.dart';
import 'package:widget_canvas/src/widget_canvas.dart';

typedef Coordinate = Offset;

class CanvasElement<T> extends ValueNotifier<Coordinate> implements Comparable<CanvasElement<Object?>> {
  CanvasElement(
    super._value, {
    required this.id,
    required this.data,
  });

  final int id;
  final T data;
  Coordinate get coordinate => value;
  set coordinate(Coordinate coordinate) => value = coordinate;

  late final ChildVicinity vicinity =
      ChildVicinity(xIndex: id, yIndex: WidgetCanvasRenderTwoDimensionalViewport.contentLayer);

  @override
  bool operator ==(Object other) => other is CanvasElement ? value == other.value : false;

  @override
  int get hashCode => id;

  @override
  int compareTo(CanvasElement<Object?> other) => id.compareTo(other.id);
}
