import 'package:flutter/foundation.dart';

typedef DistanceFunction<T> = int Function(T object);

enum SortingStrategy { quick, none }

class BinaryList<T extends Comparable<Object>> {
  BinaryList({
    required List<T> list,
    Set<T>? selectedSet,
    required int Function(T a, T b) compare,
    SortingStrategy sortingStrategy = SortingStrategy.quick,
  })  : _list = list,
        _selectedSet = selectedSet ?? {},
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
  final Set<T> _selectedSet;
  Set<T> get selectedSet => _selectedSet;

  final Comparator<T> _compare;

  void _sort() {
    _list.sort(_compare);
  }

  BinaryList<T> add(T element) {
    return BinaryList(
      list: [..._list, element],
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
      selectedSet: _selectedSet,
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

  BinaryList<T> selectElement(T oldValue, T newValue) {
    final index = binarySearch<T>(_list, oldValue);
    if (index == -1) return this;
    _selectedSet.remove(oldValue);
    _selectedSet.add(newValue);
    _list[index] = newValue;

    return BinaryList(
      list: _list,
      compare: _compare,
      selectedSet: _selectedSet,
      sortingStrategy: SortingStrategy.quick,
    );
  }

  BinaryList<T> unselectElement(T value) {
    final index = binarySearch(_list, value);
    if (index == -1) return this;
    _selectedSet.remove(value);

    return BinaryList(
      list: _list,
      selectedSet: _selectedSet,
      compare: _compare,
      sortingStrategy: SortingStrategy.none,
    );
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

extension BinaryIListX<T extends Comparable<Object>> on BinaryList<T> {
  ValueNotifier<BinaryList<T>> toValueNotifier() => ValueNotifier(this);

  BinaryList<T> binaryList(Comparator<T> compare) => BinaryList(list: list, compare: compare, selectedSet: selectedSet);
}
