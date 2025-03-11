import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/accounts_screen.dart';
import 'package:the_cakery/Screens/delivery_review_screen.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:the_cakery/utils/constants.dart';
import 'dart:async';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = true;
  List<dynamic> pastOrders = [];
  List<dynamic> pendingOrders = [];
  Timer? _timer;
  int _remainingTime = 900;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/cake/orders'),
      headers: {
        "Authorization": "Token ${Constants.prefs.getString("token")}",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)["data"];
      setState(() {
        pastOrders = [];
        pendingOrders = [];

        for (var order in data) {
          if (order["status"] == "pending") {
            pendingOrders.add(order);
          } else {
            pastOrders.add(order);
          }
        }
        isLoading = false;
      });

      if (pendingOrders.isNotEmpty) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _markOrderCompleted(String orderSlug) async {
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/cake/orders/complete/'),
      headers: {
        "Authorization": "Token ${Constants.prefs.getString("token")}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"order_slug": orderSlug}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order marked as completed!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error completing order."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelOrder(String orderSlug) async {
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/cake/orders/cancel/'),
      headers: {
        "Authorization": "Token ${Constants.prefs.getString("token")}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"order_slug": orderSlug}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order cancelled successfully"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error cancelling order"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToDeliveryReview(Map<String, dynamic> order) {
    if (order['delivery_person'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => DeliveryReviewScreen(
                orderSlug: order["slug"],
                deliveryPerson: order["delivery_person"]["name"] ?? "Unknown",
                vehicleNumber: order["delivery_person"]["vehicle_number"],
                phoneNumber: order["delivery_person"]["phone_no"],
                deliveryPersonSlug: order["delivery_person"]["slug"],
                isReviewed: order["is_reviewed"],
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Delivery person information not available"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          "My Orders",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const AccountsScreen(),
      body: Container(
        color: Colors.grey[50],
        child:
            isLoading
                ? _buildSkeletonLoader()
                : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (pendingOrders.isNotEmpty) _buildCurrentOrders(),
                            // SizedBox(height: 24),
                            Text(
                              "Past Orders",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            // SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    _buildPastOrders(),
                  ],
                ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 12,
                        color: Colors.grey[200],
                      ),
                      SizedBox(height: 8),
                      Container(width: 80, height: 12, color: Colors.grey[200]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Current Orders",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        ...pendingOrders.map((order) {
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            order["items"][0]["image_url"] != null
                                ? Image.network(
                                  order["items"][0]["image_url"],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.cake,
                                    color: Colors.grey[400],
                                  ),
                                ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                order["status"].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "₹${order["total_price"]}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _cancelOrder(order["slug"]),
                            icon: Icon(
                              Icons.cancel_outlined,
                              color: Colors.red,
                            ),
                            label: Text(
                              "Cancel",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _markOrderCompleted(order["slug"]),
                            icon: Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            label: Text(
                              "Done",
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order["del_address"],
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "${order["payment"]["payment_method"].toUpperCase()} • ${order["payment"]["is_paid"] ? "Paid" : "Pending"}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPastOrders() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final order = pastOrders[index];
        final bool isCompleted = order["status"] == "delivered";
        final Color statusColor = isCompleted ? Colors.green : Colors.red;
        final Color statusBgColor =
            isCompleted ? Colors.green[50]! : Colors.red[50]!;

        return Container(
          margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap:
                  isCompleted ? () => _navigateToDeliveryReview(order) : null,
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          order["items"][0]["image_url"] != null
                              ? Image.network(
                                order["items"][0]["image_url"],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.cake,
                                  color: Colors.grey[400],
                                ),
                              ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order["status"].toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "₹${order["total_price"]}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Ordered on: ${order["created_at"]}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ),
        );
      }, childCount: pastOrders.length),
    );
  }
}
