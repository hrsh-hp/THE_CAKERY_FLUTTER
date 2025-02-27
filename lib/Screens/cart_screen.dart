import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/accounts_screen.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> cartItems = [
    {
      "id": 1,
      "name": "Chocolate Cake",
      "size": "Medium",
      "quantity": 2,
      "price": 799.0,
      "imageUrl":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_aHBROo9v_qSg_mhMLje2MX1az3HjbbOUQg&s",
    },
    {
      "id": 2,
      "name": "Vanilla Cake",
      "size": "Large",
      "quantity": 1,
      "price": 1199.0,
      "imageUrl":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_aHBROo9v_qSg_mhMLje2MX1az3HjbbOUQg&s",
    },
  ];

  String selectedLocation = "Home, 123 Street, City";
  String deliveryTimeEstimate = "20-30 min";
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            cartItems.isEmpty
                ? Center(child: Text("Your cart is empty"))
                : Column(
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
          ],
        ),
      ),
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

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Delivery Address",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 5),
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
            _buildPaymentCard("Card", Icons.credit_card),
            _buildPaymentCard("UPI", Icons.mobile_friendly),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
