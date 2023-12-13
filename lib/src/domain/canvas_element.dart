import 'package:flutter/material.dart';

class CanvasElement {
  CanvasElement({
    required this.id,
    required this.offset,
    this.isSelected = false,
  });

  final int id;
  final Offset offset;
  final bool isSelected;

  late final ChildVicinity vicinity = ChildVicinity(xIndex: id, yIndex: 3);

  @override
  bool operator ==(Object? other) => other is CanvasElement ? id == other.id : false;

  @override
  int get hashCode => id;

  CanvasElement copyWith({
    int? id,
    Offset? offset,
    bool? isSelected,
  }) =>
      CanvasElement(
        id: id ?? this.id,
        offset: offset ?? this.offset,
        isSelected: isSelected ?? this.isSelected,
      );
}
