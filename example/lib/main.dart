import 'package:flutter/material.dart';
import 'package:widget_canvas/widget_canvas.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  WidgetCanvasElements<dynamic> elements = WidgetCanvasElements.fromList([
    CanvasElement(
      Offset.zero,
      id: 0,
      data: null,
      size: ValueNotifier(const Size.square(300)),
    ),
    CanvasElement(
      const Offset(300, 200),
      id: 1,
      data: null,
      size: ValueNotifier(const Size.square(200)),
    ),
  ]);

  final scaleFactor = ValueNotifier(1.0);

  final horizontalScrollController = ScrollController();
  final verticalScrollController = ScrollController();

  late final horizontalDetails = ScrollableDetails.horizontal(
    controller: horizontalScrollController,
  );
  late final verticalDetails = ScrollableDetails.vertical(
    controller: verticalScrollController,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WidgetCanvasZoomDetector(
        scaleFactor: scaleFactor.value,
        onScaleFactorChanged: (value) =>
            setState(() => scaleFactor.value = value),
        minScaleFactor: 0.1,
        maxScaleFactor: 5,
        horizontalScrollController: horizontalScrollController,
        verticalScrollController: verticalScrollController,
        child: WidgetCanvas(
          horizontalDetails: horizontalDetails,
          verticalDetails: verticalDetails,
          delegate: WidgetCanvasChildDelegate(
            elements: elements,
            showGrid: true,
            builder: (context, element) => ZoomableCanvasElement(
              child: MovableCanvasElement(
                data: element,
                child: ColoredBox(
                    color: Colors.blue.shade100,
                    child: Column(
                      children: [
                        Text('Element ${element.id}'),
                        Text('Size: ${element.size.value}'),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Press me!'),
                        ),
                      ],
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
