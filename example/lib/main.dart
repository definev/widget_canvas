import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final elements = ValueNotifier<BinaryList<CanvasElement>>(
    <CanvasElement>[].binaryList(WidgetCanvasChildDelegate.defaultCompare(Axis.horizontal)),
  );

  @override
  void initState() {
    super.initState();
    elements.value = <CanvasElement>[
      for (int i = 4; i < 17; i += 1)
        CanvasElement(
          id: i,
          offset: Offset(i % 5 * 100.0, i ~/ 5 * 100.0),
        ),
    ].binaryList(WidgetCanvasChildDelegate.defaultCompare(Axis.horizontal));
    elements.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    elements.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App'),
      ),
      body: WidgetCanvas(
        diagonalDragBehavior: DiagonalDragBehavior.free,
        delegate: WidgetCanvasChildDelegate(
          showGrid: true,
          dimension: 100,
          elements: elements.value,
          builder: (context, element) => MovableCanvasElement(
            snap: ,
            dimension: 100,
            element: element,
            elements: elements,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${element.id} ${element.offset}'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
