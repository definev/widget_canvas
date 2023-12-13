typedef DistanceFunction<T> = int Function(T object);

enum SortingStrategy {
  quick,
  none,
}

class BinaryList<T> {
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

  void add(T element) {
    _list.add(element);
    _sort();
  }

  void addAll(Iterable<T> elements) {
    _list.addAll(elements);
    _sort();
  }

  void remove(T element) {
    _list.remove(element);
    _sort();
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

  BinaryList<T> lockAt(T element, T Function(T element) onUpdate) {
    final index = listBinarySearch(_list, element, comparator: _compare);
    if (index == -1) return this;
    _selectedSet.remove(element);
    final updatedElement = onUpdate(element);
    _selectedSet.add(updatedElement);
    _list[index] = updatedElement;

    return BinaryList(
      list: _list,
      compare: _compare,
      selectedSet: _selectedSet,
      sortingStrategy: SortingStrategy.quick,
    );
  }

  BinaryList<T> unlockAt(T element, T Function(T element) onUpdate) {
    final index = listBinarySearch(_list, element, comparator: _compare);
    if (index == -1) return this;
    _selectedSet.remove(element);
    final updatedElement = onUpdate(element);
    _list[index] = updatedElement;

    return BinaryList(
      list: _list,
      selectedSet: _selectedSet,
      compare: _compare,
      sortingStrategy: SortingStrategy.quick,
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

extension IListToBinaryListX<T> on List<T> {
  BinaryList<T> binaryList(Comparator<T> compare) => BinaryList(list: this, compare: compare);
}

extension BinaryIListX<T> on BinaryList<T> {
  BinaryList<T> binaryList(Comparator<T> compare) =>
      BinaryList(list: list, compare: compare, selectedSet: selectedSet);
}

int listBinarySearch<T>(List<T> sortedList, T value, {required Comparator<T> comparator}) {
  int min = 0;
  int max = sortedList.length;
  while (min < max) {
    final int mid = min + ((max - min) >> 1);
    final T element = sortedList[mid];
    final int comp = comparator(element, value);
    if (comp == 0) {
      return mid;
    }
    if (comp < 0) {
      min = mid + 1;
    } else {
      max = mid;
    }
  }
  return -1;
}
