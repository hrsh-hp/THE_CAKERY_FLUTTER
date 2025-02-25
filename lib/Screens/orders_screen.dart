import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/accounts_screen.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart';

class OrdersScreen extends StatelessWidget {
  OrdersScreen({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer:const AccountsScreen(),
      bottomNavigationBar: BottomNavBar(selectedIndex: 1,scaffoldKey:_scaffoldKey),
      body: Center(child: Text("My Orders", style: TextStyle(fontSize: 24))),
    );
  }
}
