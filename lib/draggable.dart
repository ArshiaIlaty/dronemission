import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';

// learning extention methods and widget in order to make a custom change in the others' library
extension CustomString on String {
  get firstLetterAndSecondLetter {
    return this[0] + this[1];
  }
}
// This approach helps us to write more clear and readable code and prevent of repeating the same code
extension MyExtention on Text{
  Container addBox(){
    return Container(
      child: this,
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
//Learning about the draggable widget
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
        title: Text('Merged Widget', style: GoogleFonts.acme(),),
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

// rating bar implementation
            Center(
              child: RatingBar(
                ratingWidget: RatingWidget(
                  full: const Icon(Icons.star, color: Colors.amber),
                  half: const Icon(Icons.star_half, color: Colors.amber),
                  empty: const Icon(Icons.star_border, color: Colors.amber),
                ),
                initialRating: 3,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                onRatingUpdate: (newRating) {
                  setState(() {
                    var rating = newRating;
                  });
                },
              ),
            ),
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
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
