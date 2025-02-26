import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [
    {
      "id": 1,
      "name": "Chocolate Cake",
      "size": "Medium",
      "quantity": 2,
      "price": 799.0,
      "imageUrl":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRR2WykAyo-XM2T6eu3T8xM6yIlBygrzcfxAw&s",
    },
    {
      "id": 2,
      "name": "Vanilla Cake",
      "size": "Large",
      "quantity": 1,
      "price": 1199.0,
      "imageUrl":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRR2WykAyo-XM2T6eu3T8xM6yIlBygrzcfxAw&s",
    },
  ];

  String selectedLocation = "Home";
  String selectedTime = "Morning (9 AM - 12 PM)";
  String selectedPaymentMethod = "Credit Card";

  final Map<String, double> charges = {
    "Subtotal": 0.0,
    "Delivery Fee": 50.0,
    "Taxes": 30.0,
  };

  @override
  void initState() {
    super.initState();
    _calculateSubtotal();
  }

  void _calculateSubtotal() {
    double subtotal = cartItems.fold(
      0,
      (sum, item) => sum + (item["price"] * item["quantity"]),
    );
    setState(() {
      charges["Subtotal"] = subtotal;
    });
  }

  void _removeItem(int id) {
    setState(() {
      cartItems.removeWhere((item) => item["id"] == id);
      _calculateSubtotal();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Item removed from cart")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Cart")),
      body:
          cartItems.isEmpty
              ? Center(child: Text("Your cart is empty"))
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCartList(),
                    Divider(),
                    _buildDeliverySection(),
                    Divider(),
                    _buildPaymentSection(),
                    Divider(),
                    _buildPriceDetails(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
      bottomNavigationBar: cartItems.isNotEmpty ? _buildOrderButton() : null,
    );
  }

  Widget _buildCartList() {
    return Column(
      children:
          cartItems.map((item) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Image.network(item["imageUrl"], width: 50, height: 50),
                title: Text("${item["name"]} (${item["size"]})"),
                subtitle: Text("Qty: ${item["quantity"]}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "₹${(item["price"] * item["quantity"]).toStringAsFixed(2)}",
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItem(item["id"]),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Delivery Location",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        DropdownButton<String>(
          value: selectedLocation,
          isExpanded: true,
          items:
              ["Home", "Office", "Custom"].map((location) {
                return DropdownMenuItem(value: location, child: Text(location));
              }).toList(),
          onChanged: (value) {
            setState(() {
              selectedLocation = value!;
            });
          },
        ),
        SizedBox(height: 10),
        Text("Delivery Time", style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: selectedTime,
          isExpanded: true,
          items:
              [
                "Morning (9 AM - 12 PM)",
                "Afternoon (12 PM - 3 PM)",
                "Evening (6 PM - 9 PM)",
              ].map((time) {
                return DropdownMenuItem(value: time, child: Text(time));
              }).toList(),
          onChanged: (value) {
            setState(() {
              selectedTime = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold)),
        Column(
          children:
              ["Credit Card", "UPI", "Cash on Delivery"].map((method) {
                return RadioListTile(
                  title: Text(method),
                  value: method,
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value.toString();
                    });
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceDetails() {
    double total =
        charges["Subtotal"]! + charges["Delivery Fee"]! + charges["Taxes"]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Price Details", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        ...charges.entries.map((entry) {
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
              "₹${total.toStringAsFixed(2)}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderButton() {
    return BottomAppBar(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Order placed successfully!")),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15),
              textStyle: TextStyle(fontSize: 18),
            ),
            child: Text("Place Order"),
          ),
        ),
      ),
    );
  }
}
