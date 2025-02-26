import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/cart_screen.dart';
import 'package:the_cakery/Screens/edit_profile.dart';
import 'package:the_cakery/Screens/home_screen.dart';
import 'package:the_cakery/Screens/initial.dart';
import 'package:the_cakery/Screens/login.dart';
import 'package:the_cakery/Screens/orders_screen.dart';
import 'package:the_cakery/Screens/register.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart';
import 'package:the_cakery/utils/constants.dart';
import 'package:the_cakery/utils/navigations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Constants.init(context);
    return MaterialApp(
      title: 'THE CAKERY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: const InitialScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/login":
            return NavigationUtils.slideRoute(const LoginScreen());
          case "/signup":
            return NavigationUtils.slideRoute(const SignupScreen());
          case "/home":
            return NavigationUtils.fadeRoute(const HomeScreen());
          case "/orders":
            return NavigationUtils.fadeRoute(OrdersScreen());
          case "/cart":
            return NavigationUtils.fadeRoute(CartScreen());
          case "/editprofile":
            return NavigationUtils.slideRoute(EditProfileScreen());
        }
      },
    );
  }
}
