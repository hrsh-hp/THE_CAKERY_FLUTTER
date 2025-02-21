import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/home.dart';
import 'package:the_cakery/Screens/initial.dart';
import 'package:the_cakery/Screens/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'THE CAKERY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: const InitialScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
