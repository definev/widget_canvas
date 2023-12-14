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
  final elements = <CanvasElement<int>>[] //
      .binaryList(WidgetCanvasChildDelegate.defaultCompare(Axis.horizontal))
      .toValueNotifier();

  final snap = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    elements.value = <CanvasElement<int>>[
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
              delegate: WidgetCanvasChildDelegate<int>(
                showGrid: true,
                elements: elements.value,
                builder: (context, element) => ListenableBuilder(
                  listenable: snap,
                  builder: (context, __) => MovableCanvasElement<int>(
                    snap: snap.value,
                    element: element,
                    elements: elements,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('${element.id} \n Coor: ${element.coordinate} \n Data: ${element.data}'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => snap.value = !snap.value,
            child: Text(snap.value ? 'Snap' : 'Unsnap'),
          ),
        ],
      ),
    );
  }
}
