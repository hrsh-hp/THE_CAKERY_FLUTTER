import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_cakery/Screens/add_cakes.dart';
import 'package:the_cakery/Screens/admin_orders.dart';
import 'package:the_cakery/Screens/cart_screen.dart';
import 'package:the_cakery/Screens/create_your_cake_screen.dart';
import 'package:the_cakery/Screens/delivery_person_orderes_screen.dart';
import 'package:the_cakery/Screens/edit_profile.dart';
import 'package:the_cakery/Screens/favourites_screen.dart';
import 'package:the_cakery/Screens/home_screen.dart';
import 'package:the_cakery/Screens/initial.dart';
import 'package:the_cakery/Screens/login.dart';
import 'package:the_cakery/Screens/manage_cake_options_screen.dart';
import 'package:the_cakery/Screens/orders_screen.dart';
import 'package:the_cakery/Screens/register.dart';
// import 'package:the_cakery/utils/bottom_nav_bar.dart';
import 'package:the_cakery/utils/constants.dart';
import 'package:the_cakery/utils/navigations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load();
  await dotenv.load(fileName: ".env");
  // print("API Key: ${dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'Not Found'}");
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    const platform = MethodChannel('google_maps');
    try {
      await platform.invokeMethod(
        'setApiKey',
        dotenv.env['GOOGLE_MAPS_API_KEY'],
      );
      print("✅ Google Maps API Key sent to iOS.");
    } catch (e) {
      print("❌ Error sending API Key to iOS: $e");
    }
  });

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
            if (Constants.prefs.getString('role') == 'admin') {
              return NavigationUtils.fadeRoute(AdminOrdersScreen());
            } else if (Constants.prefs.getString('role') == 'delivery_person') {
              return NavigationUtils.fadeRoute(DeliveryPersonOrdersScreen());
            } else {
              return NavigationUtils.fadeRoute(OrdersScreen());
            }
          case "/cart":
            return NavigationUtils.fadeRoute(CartScreen());
          case "/favorites":
            return NavigationUtils.fadeRoute(FavoritesScreen());
          case "/editprofile":
            return NavigationUtils.slideRoute(EditProfileScreen());
          case "/add_cakes":
            return NavigationUtils.slideRoute(AddCakeScreen());
          case "/create_cakes":
            return NavigationUtils.slideRoute(CreateYourCakeScreen());
          case "/manage_addons":
            return NavigationUtils.slideRoute(const ManageCakeOptionsScreen());
        }
        return null;
      },
    );
  }
}
