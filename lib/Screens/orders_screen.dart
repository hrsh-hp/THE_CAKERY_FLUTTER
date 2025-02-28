import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/accounts_screen.dart';
import 'dart:async';

import 'package:the_cakery/Screens/delivery_review_screen.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> pastOrders = [];
  Map<String, dynamic>? currentOrder;
  Timer? _timer;
  int _remainingTime = 900; // Example: 15 minutes for order delivery

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() {
    setState(() {
      pastOrders = [
        {
          "id": 1,
          "name": "Chocolate Cake",
          "imageUrl":
              "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_aHBROo9v_qSg_mhMLje2MX1az3HjbbOUQg&s",
          "price": 799.0,
          "date": "Feb 24, 2025",
          "reviewed": false,
        },
        {
          "id": 2,
          "name": "Vanilla Cake",
          "imageUrl":
              "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_aHBROo9v_qSg_mhMLje2MX1az3HjbbOUQg&s",
          "price": 999.0,
          "date": "Feb 20, 2025",
          "reviewed": true,
        },
      ];

      currentOrder = {
        "id": 3,
        "name": "Red Velvet Cake",
        "imageUrl":
            "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_aHBROo9v_qSg_mhMLje2MX1az3HjbbOUQg&s",
        "status": "Out for Delivery",
        "remainingTime": _remainingTime,
      };
    });

    if (currentOrder != null) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
          currentOrder!["remainingTime"] = _remainingTime;
        });
      } else {
        timer.cancel();
        setState(() {
          currentOrder = null;
        });
      }
    });
  }

  void _navigateToReviewScreen(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    Navigator.pushNamed(context, '/deliveryreview');
  }

  void _giveThumbsUp(int id) {
    setState(() {
      pastOrders.firstWhere((order) => order["id"] == id)["reviewed"] = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Thanks for your feedback!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("My Orders"),
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Custom back button
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const AccountsScreen(),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentOrder != null) ...[
              Text(
                "Current Order",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Image.network(
                    currentOrder!["imageUrl"],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    currentOrder!["name"],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Status: ${currentOrder!["status"]}\nDelivery in: ${(_remainingTime ~/ 60)}m ${_remainingTime % 60}s",
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
            Text(
              "Past Orders",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: pastOrders.length,
                itemBuilder: (context, index) {
                  final order = pastOrders[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Image.network(
                        order["imageUrl"],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(
                        order["name"],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Ordered on: ${order["date"]}"),
                      trailing:
                          order["reviewed"]
                              ? Icon(Icons.thumb_up, color: Colors.green)
                              : IconButton(
                                icon: Icon(Icons.thumb_up, color: Colors.grey),
                                onPressed: () => _giveThumbsUp(order["id"]),
                              ),
                      onTap: () => _navigateToReviewScreen(context, order),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
