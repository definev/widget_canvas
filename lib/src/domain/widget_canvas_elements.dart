import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

class WidgetCanvasElements<T> {
  WidgetCanvasElements.raw({
    required BinaryList<CanvasElement<T>> list,
    required Set<CanvasElement<T>> perminantVisibleSet,
  })  : _list = list,
        _perminantVisibleSet = perminantVisibleSet;

  factory WidgetCanvasElements.fromList(List<CanvasElement<T>> elements) {
    return WidgetCanvasElements.raw(
      list: elements.binaryList(WidgetCanvasChildDelegate.defaultCompare(Axis.horizontal)),
      perminantVisibleSet: {},
    );
  }

  final BinaryList<CanvasElement<T>> _list;
  BinaryList<CanvasElement<T>> get list => _list;

  int get _nextId {
    final sortedByIdList = BinaryList(
      list: [..._list.rawList],
      compare: (a, b) => a.id.compareTo(b.id),
      sortingStrategy: SortingStrategy.quick,
    );
    return (sortedByIdList.rawList.lastOrNull?.id ?? -1) + 1;
  }


  WidgetCanvasElements<T> copyWith({
    BinaryList<CanvasElement<T>>? binaryList,
    Set<CanvasElement<T>>? perminantVisibleSet,
  }) {
    return WidgetCanvasElements.raw(
      list: binaryList ?? _list,
      perminantVisibleSet: perminantVisibleSet ?? _perminantVisibleSet,
    );
  }

  WidgetCanvasElements<T> insert({required CanvasElement<T> Function(int id) builder}) {
    return WidgetCanvasElements<T>.raw(
      list: BinaryList<CanvasElement<T>>(
        list: [..._list.rawList, builder(_nextId)],
        compare: _list.compare,
        sortingStrategy: SortingStrategy.quick,
      ),
      perminantVisibleSet: _perminantVisibleSet,
    );
  }

  WidgetCanvasElements<T> remove(int id) {
    var result = _list.whereIndexed((element) => element.id.compareTo(id));
    if (result case final result?) {
      final first = result.rawList.firstOrNull;
      if (first != null) {
        return WidgetCanvasElements<T>.raw(
          list: _list.remove(first),
          perminantVisibleSet: _perminantVisibleSet,
        );
      }
    }

    final newElements = BinaryList<CanvasElement<T>>(
      list: [..._list.rawList],
      compare: (a, b) => a.id.compareTo(b.id),
      sortingStrategy: SortingStrategy.quick,
    );

    result = newElements.whereIndexed((element) => element.id.compareTo(id));
    if (result == null || result.rawList.isEmpty) return this;

    return WidgetCanvasElements<T>.raw(
      list: _list.remove(result.rawList.first),
      perminantVisibleSet: _perminantVisibleSet,
    );
  }

  WidgetCanvasElements<T> removeElement(CanvasElement<T> element) {
    return WidgetCanvasElements<T>.raw(
      list: _list.remove(element),
      perminantVisibleSet: _perminantVisibleSet,
    );
  }

  final Set<CanvasElement<T>> _perminantVisibleSet;
  Set<CanvasElement<T>> get perminantVisibleSet => _perminantVisibleSet;

  WidgetCanvasElements<T> markElementIsPerminantVisible(CanvasElement<T> value) {
    final index = binarySearch(_list.rawList, value);
    if (index == -1) return this;
    value.isPerminantVisible = true;
    _perminantVisibleSet.add(value);
    _list.rawList[index] = value;

    return WidgetCanvasElements<T>.raw(
      list: _list,
      perminantVisibleSet: _perminantVisibleSet,
    );
  }

  WidgetCanvasElements<T> unmarkElementIsPerminantVisible(CanvasElement<T> value) {
    final index = binarySearch(_list.rawList, value);
    if (index == -1) return this;
    value.isPerminantVisible = false;
    _perminantVisibleSet.remove(value);

    return WidgetCanvasElements<T>.raw(
      list: _list,
      perminantVisibleSet: _perminantVisibleSet,
    );
  }
}
