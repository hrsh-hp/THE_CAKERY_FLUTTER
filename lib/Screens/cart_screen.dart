import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_cakery/Screens/accounts_screen.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:the_cakery/utils/constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

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
  final Map<String, String> paymentMethods = {
    "UPI": "upi",
    "Card": "card",
    "Cash": "cash",
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
      double cartTotal =
          data["cart_total"] == 0 ? 0.0 : double.parse(data["cart_total"]);
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
                "imageUrl":
                    item['imageUrl'] is String &&
                            (item['imageUrl'] as String).isNotEmpty
                        ? item['imageUrl'] as String
                        : null,
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
    // --- 1. Still need Form key and Controllers ---
    final _formKey = GlobalKey<FormState>();
    final streetController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final zipController = TextEditingController();

    // Optional: Pre-fill logic remains the same if needed

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            "Edit Delivery Address",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            // --- 2. Wrap fields in Form ---
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- 3. Use TextFormField directly with inline validator ---
                  TextFormField(
                    controller: streetController,
                    decoration: InputDecoration(
                      labelText: "Street Address",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ), // Basic border
                    ),
                    validator: (value) {
                      // Inline validation
                      if (value == null || value.trim().isEmpty) {
                        return 'Street cannot be empty';
                      }
                      return null;
                    },
                    autovalidateMode:
                        AutovalidateMode
                            .onUserInteraction, // Optional: Immediate feedback
                  ),
                  SizedBox(height: 10), // Adjusted spacing
                  TextFormField(
                    controller: cityController,
                    decoration: InputDecoration(
                      labelText: "City",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'City cannot be empty';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: stateController,
                    decoration: InputDecoration(
                      labelText: "State",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'State cannot be empty';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: zipController,
                    decoration: InputDecoration(
                      labelText: "Zip Code",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ], // Keep formatter
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Zip Code cannot be empty';
                      }
                      // Optional: Add more specific zip code validation if needed
                      // if (value.length != 5) { // Example for US zip codes
                      //   return 'Enter a valid 5-digit Zip Code';
                      // }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // --- 4. Validate form on Save ---
                if (_formKey.currentState!.validate()) {
                  // Form is valid, proceed
                  setState(() {
                    selectedLocation =
                        "${streetController.text.trim()}, ${cityController.text.trim()}, ${stateController.text.trim()} - ${zipController.text.trim()}"; // Trim values
                  });
                  Navigator.pop(context);
                }
                // Else: Errors are shown automatically, do nothing here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
    );
  }

  void _removeItem(String cakeSlug) async {
    int itemIndex = cartItems.indexWhere(
      (item) => item["cake_slug"] == cakeSlug,
    );
    if (itemIndex == -1) return;
    Map<String, dynamic> removedItem = cartItems[itemIndex];
    setState(() {
      cartItems.removeAt(itemIndex);
    });
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/cake/cart/remove/'),
      headers: {
        "Authorization": "Token ${Constants.prefs.getString("token")}",
        "Content-Type": "application/json",
      },
      body: json.encode({"cart_item_slug": cakeSlug}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${removedItem["cake_name"]} removed from cart"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
      _fetchCartData();
    } else {
      setState(() {
        cartItems.insert(itemIndex, removedItem);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to remove ${removedItem["cake_name"]}"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> placeOrder(
    BuildContext context,
    String delAddress,
    String? paymentMethod,
    double? total,
  ) async {
    final url = Uri.parse('${Constants.baseUrl}/cake/cart/place_order/');

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Token ${Constants.prefs.getString("token")}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "del_address": delAddress,
          "payment_method": paymentMethod,
          "final_total": total,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 &&
          responseData["data"]["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order placed successfully!"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/orders');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${responseData["message"]}"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong. Please try again."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
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
          "Your Cart",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLoading && cartItems.isNotEmpty) _buildPlaceOrderButton(),
          BottomNavBar(selectedIndex: 3, scaffoldKey: _scaffoldKey),
        ],
      ),
      drawer: const AccountsScreen(),
      body: Container(
        color: Colors.grey[50],
        child:
            isLoading
                ? _buildLoadingSkeleton()
                : cartItems.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Your cart is empty",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCartList(),
                      SizedBox(height: 20),
                      _buildAddressSection(),
                      SizedBox(height: 20),
                      _buildPaymentSection(),
                      SizedBox(height: 20),
                      _buildPriceDetails(),
                      SizedBox(height: 10), // Space for bottom button
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
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
                  width: 80,
                  height: 80,
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
                        height: 16,
                        color: Colors.grey[200],
                      ),
                      SizedBox(height: 8),
                      Container(width: 80, height: 16, color: Colors.grey[200]),
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

  Widget _buildCartList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cart Items",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        ...cartItems.map((item) {
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        item['imageUrl'] != null
                            ? Image.network(
                              item['imageUrl'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              // --- Crucial Part: Error Handling ---
                              errorBuilder: (context, error, stackTrace) {
                                // On error, return the placeholder widget
                                return _buildImageErrorPlaceholder();
                              },
                              // Optional: Basic loading indicator (can be removed if too much)
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null)
                                  return child; // Image loaded
                                return Container(
                                  color: Colors.grey[200],
                                ); // Simple grey box while loading
                              },
                            )
                            : _buildImageErrorPlaceholder(), // Show placeholder if URL is null/empty initially
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["cake_name"],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Size: ${item["size"]}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Qty: ${item["quantity"]}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${item["cake_price"].toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                        ),
                        onPressed: () => _removeItem(item["cake_slug"]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300], // Simple background
      child: Icon(
        Icons.cake_outlined, // Your desired icon
        color: Colors.grey[600],
        size: 40,
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Delivery Address",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.brown),
                onPressed: _editAddress,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedLocation,
                  style: TextStyle(color: Colors.grey[800], fontSize: 15),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 20),
              SizedBox(width: 8),
              Text(
                "Estimated delivery time: $deliveryTimeEstimate",
                style: TextStyle(color: Colors.grey[800], fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Method",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                paymentMethods.keys.map((method) {
                  return _buildPaymentCard(method, _getPaymentIcon(method));
                }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case "UPI":
        return Icons.mobile_friendly;
      case "Card":
        return Icons.credit_card;
      case "Cash":
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPaymentCard(String method, IconData icon) {
    final isSelected = selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = method;
        });
      },
      child: Container(
        width: 80,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.brown.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.brown : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.brown : Colors.grey[600],
            ),
            SizedBox(height: 8),
            Text(
              method,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.brown : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetails() {
    return Container(
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Price Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          ...charges.entries.where((entry) => entry.key != "Total").map((
            entry,
          ) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                  Text(
                    "₹${entry.value.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                  ),
                ],
              ),
            );
          }),
          Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                "₹${charges["Total"]!.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed:
            cartItems.isEmpty
                ? null
                : () {
                  placeOrder(
                    context,
                    selectedLocation,
                    paymentMethods[selectedPaymentMethod],
                    charges["Total"],
                  );
                },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          "Place Order • ₹${charges["Total"]!.toStringAsFixed(2)}",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
