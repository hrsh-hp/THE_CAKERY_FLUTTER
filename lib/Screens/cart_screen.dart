import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/accounts_screen.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:the_cakery/utils/constants.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = true;
  List<Map<String, dynamic>> cartItems = [];
  String selectedLocation = "";
  String deliveryTimeEstimate = "20-30 min";
  String selectedPaymentMethod = "UPI";
  final Map<String, double> charges = {
    "Subtotal": 0.0,
    "Taxes": 0.0,
    "Delivery Fee": 50.0,
    "Total": 0.0,
  };

  @override
  void initState() {
    super.initState();
    _fetchCartData();
  }

  Future<void> _fetchCartData() async {
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/cake/cart'),
      headers: {
        "Authorization": "Token ${Constants.prefs.getString("token")}",
        "Content-Type": "application/json",
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body)["data"];
      double cartTotal = double.parse(data["cart_total"]);
      double subtotal = cartTotal / 1.18;
      double tax = cartTotal - subtotal;
      setState(() {
        selectedLocation = data["del_address"];
        cartItems =
            (data["cart_items"] as List).map((item) {
              return {
                "cake_slug": item['slug'],
                "cake_name": item["cake_name"],
                "cake_price": double.parse(item["cake_price"]),
                "size": item["size"],
                "quantity": item["quantity"],
                "imageUrl": item["image_url"],
              };
            }).toList();
        charges["Subtotal"] = subtotal;
        charges["Taxes"] = tax;
        charges["Total"] = cartTotal + charges["Delivery Fee"]!;
        isLoading = false;
      });
    }
  }

  void _editAddress() {
    TextEditingController addressController = TextEditingController(
      text: selectedLocation,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Delivery Address"),
          content: TextField(
            controller: addressController,
            decoration: InputDecoration(hintText: "Enter new address"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedLocation = addressController.text;
                });
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _removeItem(String cake_slug) {
    setState(() {
      cartItems.removeWhere((item) => item["cake_slug"] == cake_slug);
      // _fetchCartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Your Cart"),
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Custom back button
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 3,
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const AccountsScreen(),
      body:
          isLoading
              ? _buildLoadingSkeleton()
              : cartItems.isEmpty
              ? Center(child: Text("Your cart is empty"))
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCartList(),
                    Divider(),
                    _buildAddressSection(),
                    Divider(),
                    _buildPaymentSection(),
                    Divider(),
                    _buildPriceDetails(),
                    SizedBox(height: 10),
                    _buildPlaceOrderButton(),
                  ],
                ),
              ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Container(width: 50, height: 50, color: Colors.grey[300]),
            title: Container(width: 100, height: 10, color: Colors.grey[300]),
            subtitle: Container(width: 50, height: 10, color: Colors.grey[300]),
          ),
        );
      },
    );
  }

  Widget _buildCartList() {
    return Column(
      children:
          cartItems.map((item) {
            return Card(
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                leading: Image.network(item["imageUrl"], width: 50, height: 50),
                title: Text("${item["cake_name"]} (${item["size"]})"),
                subtitle: Text("Qty: ${item["quantity"]}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "₹${item["cake_price"].toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 12),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _removeItem(item["cake_slug"]),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Delivery Address",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(selectedLocation, overflow: TextOverflow.ellipsis),
            ),
            TextButton(onPressed: _editAddress, child: Icon(Icons.edit)),
          ],
        ),
        SizedBox(height: 5),
        Row(
          children: [
            Icon(Icons.timer_outlined),
            SizedBox(width: 5),
            Text(deliveryTimeEstimate),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPaymentCard("UPI", Icons.mobile_friendly),
            _buildPaymentCard("Card", Icons.credit_card),
            _buildPaymentCard("Cash", Icons.money),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentCard(String method, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = method;
        });
      },
      child: Card(
        color:
            selectedPaymentMethod == method ? Colors.brown[200] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 30),
              SizedBox(height: 5),
              Text(method, style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...charges.entries.where((entry) => entry.key != "Total").map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key),
                Text("₹${entry.value.toStringAsFixed(2)}"),
              ],
            ),
          );
        }),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "₹${charges["Total"]!.toStringAsFixed(2)}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed:
            cartItems.isEmpty
                ? null
                : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Order placed successfully!")),
                  );
                },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          textStyle: TextStyle(fontSize: 18),
          backgroundColor: Colors.brown,
        ),
        child: Text(
          "Place Order",
          style: TextStyle(color: Theme.of(context).colorScheme.surfaceBright),
        ),
      ),
    );
  }
}
