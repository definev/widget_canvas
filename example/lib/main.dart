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
  final elements = <CanvasElement>[] //
      .binaryList(WidgetCanvasChildDelegate.defaultCompare(Axis.horizontal))
      .toValueNotifier();

  @override
  void initState() {
    super.initState();
    elements.value = <CanvasElement>[
      for (int i = 0; i < 10; i += 1) CanvasElement(Offset(i * 100, i * 100), id: i, data: i),
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
      body: Column(
        children: [
          Expanded(
            child: WidgetCanvas(
              clipBehavior: Clip.none,
              diagonalDragBehavior: DiagonalDragBehavior.weightedEvent,
              delegate: WidgetCanvasChildDelegate(
                showGrid: true,
                elements: elements.value,
                builder: (context, element) => MovableCanvasElement(
                  snap: true,
                  element: element,
                  elements: elements,
                  child: const Text(''),
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              for (final element in elements.value.list) {
                print('${element.id} ${element.coordinate}');
              }
            },
            child: const Text('log elements'),
          ),
        ],
      ),
    );
  }
}
