import 'package:dronemission/slidebar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:logger/logger.dart';

import 'clock_widget.dart';

extension RouterContext on BuildContext {
  //{} this means optional argument in this section, this helps us to send data for some of our navigations
  toNamed(String routeName, {Object? arg}) {
    Navigator.of(this).pushNamed(routeName, arguments: arg);
  }
  toNamedUntil(String routeName) {
    Navigator.of(this).pushNamedAndRemoveUntil(routeName, (route) => false);
  } 
  toPushReplacement(Widget page) {
    Navigator.of(this).pushReplacement(MaterialPageRoute(builder: (context) => page));
  } 
  // push(Widget page) {
  //   Navigator.of(this).push(MaterialPageRoute(builder: (context) => page));
  // }
}

// learning extention methods and widget in order to make a custom change in the others' library
extension CustomString on String {
  get firstLetterAndSecondLetter {
    return this[0] + this[1];
  }
}

// This approach helps us to write more clear and readable code and prevent of repeating the same code
extension MyExtention on Text {
  Container addBox() {
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
    
    //Learning about the loggers in oder to find the bugs and errors
    var logger = Logger();
    logger.d("This is a debug message");
    logger.e("This is an error message");
    logger.w("This is a warning message");
    logger.i("This is an info message");
    logger.v("This is a verbose message");
    logger.w("This is a warning message");

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Merged Widget',
          style: GoogleFonts.acme(),
        ),
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
