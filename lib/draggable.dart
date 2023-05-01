import 'package:flutter/material.dart';

class DraggableWidget extends StatefulWidget {
  const DraggableWidget({Key? key}) : super(key: key);

  @override
  State<DraggableWidget> createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget> {
  Color acceptedColor = Colors.grey;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draggable Widget'),
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Draggable<Color>(
                // pass the data to the drag target
                data: Colors.blue,
                child: Container(
                  height: 100,
                  width: 100,
                  color: Colors.blue,
                ),
                // when you drag the widget, you can see the feedback widget
                feedback: Container(
                  height: 100,
                  width: 100,
                  color: Colors.blue.withOpacity(0.5),
                ),
                childWhenDragging: Container(
                  height: 100,
                  width: 100,
                  color: Colors.grey,
                ),
              ),
            ),
            DragTarget<Color>(
              onWillAccept: (value) => true,
              onAccept: (value) {
                setState(() {
                  acceptedColor = value;
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                    height: 100,
                    width: 100,
                    color: acceptedColor,
                    child: Center(
                      child: Text(
                        'Drag Here',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
