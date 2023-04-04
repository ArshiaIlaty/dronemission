import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class OptScreen extends StatelessWidget {
  OptScreen({Key? key}) : super(key: key);

  Color accentPurpleColor = Color(0xFF6A53A1);
  Color primaryColor = Color(0xFF121212);
  Color accentPinkColor = Color(0xFFF99BBD);
  Color accentDarkGreenColor = Color(0xFF115C49);
  Color accentYellowColor = Color(0xFFFFB612);
  Color accentOrangeColor = Color(0xFFEA7A3B);

  List<TextStyle> otpTextStyles(BuildContext context) => [
    createStyle(context, accentPurpleColor),
    createStyle(context, accentYellowColor),
    createStyle(context, accentDarkGreenColor),
    createStyle(context, accentOrangeColor),
    createStyle(context, accentPinkColor),
    createStyle(context, accentPurpleColor),
  ];

  TextStyle createStyle(BuildContext context, Color color) {
    ThemeData theme = Theme.of(context);
    return theme.textTheme.headline3?.copyWith(color: color) ?? TextStyle(color: color);
  }

  List<TextEditingController?> otpController = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: OtpTextField(
            numberOfFields: 6,
            borderColor: accentPurpleColor,
            focusedBorderColor: accentPurpleColor,
            styles: otpTextStyles(context),
            borderRadius: BorderRadius.circular(15),
            showFieldAsBox: false,
            borderWidth: 4.0,
            keyboardType: TextInputType.number,
            onCodeChanged: (String code) {
              // Handle validation or checks here if necessary
            },
            onSubmit: (String verificationCode) {
              // Handle the submission of the OTP code here

            },
            //helps you to read the text form the message sent to client's phone
            handleControllers: (controllers){
              otpController = controllers;
            },
          ),
        ),
      ),
    );
  }
}
