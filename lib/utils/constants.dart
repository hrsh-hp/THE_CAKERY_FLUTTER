import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  static late SharedPreferences prefs;
  static late double screenWidth;
  static late double screenHeight;

  static void init(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }
}
