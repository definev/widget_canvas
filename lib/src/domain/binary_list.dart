import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

typedef DistanceFunction<T> = int Function(T object);

enum SortingStrategy { quick, none }

class BinaryList<T extends Comparable<Object>> {
  BinaryList({
    required List<T> list,
    required int Function(T a, T b) compare,
    SortingStrategy sortingStrategy = SortingStrategy.quick,
  })  : _list = list,
        _compare = compare {
    switch (sortingStrategy) {
      case SortingStrategy.quick:
        _sort();
      case SortingStrategy.none:
    }
  }

  static DistanceFunction<T> isInRange<T>(T start, T end, Comparator<T> comparator) {
    assert(comparator(start, end) <= 0);
    return (object) {
      final compareWithStart = comparator(object, start);
      if (compareWithStart < 0) return -1;
      final compareWithEnd = comparator(object, end);
      if (compareWithEnd > 0) return 1;
      return 0;
    };
  }

  final List<T> _list;
  List<T> get list => _list;
  final Comparator<T> _compare;
  Comparator<T> get compare => _compare;

  void _sort() {
    _list.sort(_compare);
  }

  BinaryList<T> add(T element) {
    return BinaryList(
      list: [...list, element],
      compare: _compare,
    );
  }

  BinaryList<T> addAll(Iterable<T> elements) {
    return BinaryList(
      list: [...list, ...elements],
      compare: _compare,
    );
  }

  BinaryList<T> remove(T element) {
    return BinaryList(
      list: [..._list]..remove(element),
      compare: _compare,
      sortingStrategy: SortingStrategy.none,
    );
  }

  BinaryList<T> slice(int start, int end) {
    return BinaryList(
      list: _list.sublist(start, end),
      compare: _compare,
      sortingStrategy: SortingStrategy.none,
    );
  }

  (int, int, int)? _binarySearch((int, int) range, DistanceFunction<T> test) {
    var (min, max) = range;

    while (max > min) {
      final mid = min + ((max - min) >> 1);
      final element = _list[mid];
      final compare = test(element);
      if (compare == 0) {
        if (min == mid) return (min, mid, min);
        return (min, mid, max);
      }
      if (compare > 0) max = mid;
      if (compare < 0) min = mid + 1;
    }

    return null;
  }

  BinaryList<T>? whereIndexed(DistanceFunction<T> test) {
    var (
      min, minPivot, //
      maxPivot, max, //
      mid,
    ) = (0, 0, 0, _list.length, 0);

    if (_binarySearch((min, max), test) case final result?) {
      (min, mid, max) = result;
      if (min == mid && mid == max) return slice(mid, mid + 1);
      minPivot = mid;
      maxPivot = mid;
    } else {
      return null;
    }

    while (min != minPivot) {
      if (_binarySearch((min, minPivot), test) case final result?) {
        (min, mid, _) = result;
        minPivot = mid;
      } else {
        min = minPivot;
        break;
      }
    }

    while (max != maxPivot) {
      if (_binarySearch((maxPivot, max), test) case final result?) {
        (_, mid, max) = result;
        maxPivot = mid + 1;
      } else {
        max = maxPivot;
        break;
      }
    }

    return slice(min, max);
  }

  @override
  String toString() {
    final buf = StringBuffer();
    for (final element in list) {
      buf.write('$element, ');
    }

    return buf.toString();
  }
}

extension ListToBinaryListX<T extends Comparable<Object>> on List<T> {
  BinaryList<T> binaryList(Comparator<T> compare) => BinaryList(list: this, compare: compare);
}

extension BinaryListX<T extends Comparable<Object>> on BinaryList<T> {
  ValueNotifier<BinaryList<T>> toValueNotifier() => ValueNotifier(this);

  BinaryList<T> sort(Comparator<T> compare) => BinaryList(list: list, compare: compare);
}

class WidgetCanvasElements<T> {
  WidgetCanvasElements._({
    required BinaryList<CanvasElement<T>> list,
    required Set<CanvasElement<T>> perminantVisibleSet,
  })  : _list = list,
        _perminantVisibleSet = perminantVisibleSet;

  factory WidgetCanvasElements.fromList(List<CanvasElement<T>> elements) {
    return WidgetCanvasElements._(
      list: elements.binaryList(WidgetCanvasChildDelegate.defaultCompare(Axis.horizontal)),
      perminantVisibleSet: {},
    );
  }

  final BinaryList<CanvasElement<T>> _list;
  BinaryList<CanvasElement<T>> get list => _list;

  WidgetCanvasElements<T> copyWith({
    BinaryList<CanvasElement<T>>? binaryList,
    Set<CanvasElement<T>>? perminantVisibleSet,
  }) {
    return WidgetCanvasElements._(
      list: binaryList ?? _list,
      perminantVisibleSet: perminantVisibleSet ?? _perminantVisibleSet,
    );
  }

  int get _nextId {
    final sortedByIdList = BinaryList(
      list: [..._list.list],
      compare: (a, b) => a.id.compareTo(b.id),
      sortingStrategy: SortingStrategy.quick,
    );
    return (sortedByIdList.list.lastOrNull?.id ?? -1) + 1;
  }

  WidgetCanvasElements<T> insert({required CanvasElement<T> Function(int id) builder}) {
    return WidgetCanvasElements<T>._(
      list: BinaryList<CanvasElement<T>>(
        list: [..._list._list, builder(_nextId)],
        compare: _list._compare,
        sortingStrategy: SortingStrategy.quick,
      ),
      perminantVisibleSet: _perminantVisibleSet,
    );
  }

  WidgetCanvasElements<T> remove(int id) {
    var result = _list.whereIndexed((element) => element.id.compareTo(id));
    if (result case final result?) {
      final first = result.list.firstOrNull;
      if (first != null) {
        return WidgetCanvasElements<T>._(
          list: _list.remove(first),
          perminantVisibleSet: _perminantVisibleSet,
        );
      }
    }

    final newElements = BinaryList<CanvasElement<T>>(
      list: [..._list.list],
      compare: (a, b) => a.id.compareTo(b.id),
      sortingStrategy: SortingStrategy.quick,
    );

    result = newElements.whereIndexed((element) => element.id.compareTo(id));
    if (result == null || result.list.isEmpty) return this;

    return WidgetCanvasElements<T>._(
      list: _list.remove(result.list.first),
      perminantVisibleSet: _perminantVisibleSet,
    );
  }

  WidgetCanvasElements<T> removeElement(CanvasElement<T> element) {
    return WidgetCanvasElements<T>._(
      list: _list.remove(element),
      perminantVisibleSet: _perminantVisibleSet,
    );
  }

  final Set<CanvasElement<T>> _perminantVisibleSet;
  Set<CanvasElement<T>> get perminantVisibleSet => _perminantVisibleSet;

  WidgetCanvasElements<T> markElementIsPerminantVisible(CanvasElement<T> value) {
    final index = binarySearch(_list._list, value);
    if (index == -1) return this;
    value.isPerminantVisible = true;
    _perminantVisibleSet.add(value);
    _list._list[index] = value;

    return WidgetCanvasElements<T>._(
      list: _list,
      perminantVisibleSet: _perminantVisibleSet,
    );
  }

  WidgetCanvasElements<T> unmarkElementIsPerminantVisible(CanvasElement<T> value) {
    final index = binarySearch(_list._list, value);
    if (index == -1) return this;
    value.isPerminantVisible = false;
    _perminantVisibleSet.remove(value);

    return WidgetCanvasElements<T>._(
      list: _list,
      perminantVisibleSet: _perminantVisibleSet,
    );
  }
}
