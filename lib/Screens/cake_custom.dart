import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:the_cakery/utils/constants.dart';

class CakeCustomScreen extends StatefulWidget {
  final String slug;

  CakeCustomScreen({super.key, required this.slug});

  @override
  State<CakeCustomScreen> createState() => _CakeCustomScreenState();
}

class _CakeCustomScreenState extends State<CakeCustomScreen> {
  bool isLoading = true;
  bool isLiked = false;
  bool availableToppings = true;
  int likes = 0;
  int quantity = 1;
  String selectedSize = "Medium";
  double selectedPrice = 0.0;
  List<String> selectedToppings = [];
  String cakeName = "";
  String imageUrl = "";
  String description = "";
  Map<String, double> sizeOptions = {};

  // final List<String> toppings = ["Choco Chips", "Nuts", "Sprinkles", "Fruits"];

  @override
  void initState() {
    super.initState();
    print("Received slug: ${widget.slug}"); // Debugging
    fetchCakeDetails(); // If applicable
  }

  Future<void> fetchCakeDetails() async {
    String token = Constants.prefs.getString("token") ?? "";

    final url = Uri.parse("${Constants.baseUrl}/cake/full_cake/${widget.slug}");
    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)["data"];
        setState(() {
          cakeName = data["name"];
          imageUrl = data["image_url"];
          description = data["description"];
          isLiked = data["liked"];
          likes = data["likes_count"];
          availableToppings = data["available_toppings"];
          sizeOptions = {
            for (var size in data["sizes"])
              size["size"]: double.parse(size["price"]),
          };
          selectedPrice = sizeOptions[selectedSize] ?? 0.0;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching cake details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, isLiked); // Pass updated like status
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(cakeName.isNotEmpty ? cakeName : "Loading..."),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child:
                          imageUrl.isNotEmpty
                              ? Image.network(
                                imageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.broken_image,
                                    size: 100,
                                    color: Colors.grey,
                                  );
                                },
                              )
                              : Icon(
                                Icons.image,
                                size: 100,
                                color: Colors.grey,
                              ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cakeName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon:
                                  isLiked
                                      ? Icon(Icons.favorite, color: Colors.red)
                                      : Icon(
                                        Icons.favorite_outline,
                                        color: Colors.red,
                                      ),
                              onPressed: () async {
                                setState(() {
                                  isLiked = !isLiked;
                                  likes += isLiked ? 1 : -1;
                                });
                                try {
                                  final response = await http.post(
                                    Uri.parse(
                                      '${Constants.baseUrl}/cake/like/',
                                    ), // Replace with your API URL
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization':
                                          'Token ${Constants.prefs.getString("token")}', // Add authentication
                                    },
                                    body: jsonEncode({
                                      'cake_slug': widget.slug,
                                      'liked': isLiked,
                                    }),
                                  );

                                  if (response.statusCode != 200) {
                                    throw Exception(
                                      "Failed to update like status",
                                    );
                                  }
                                } catch (e) {
                                  setState(() {
                                    isLiked =
                                        !isLiked; // Revert UI if request fails
                                  });
                                  print("Error: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Error updating like status",
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            Text("$likes"),
                          ],
                        ),
                      ],
                    ),
                    Text(description, style: TextStyle(fontSize: 16)),
                    SizedBox(height: 20),
                    Text(
                      "Choose Size",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8.0,
                      children:
                          sizeOptions.keys.map((size) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ), // Adds spacing between chips
                              child: ChoiceChip(
                                label: Text(
                                  "$size - ₹${sizeOptions[size]!.toStringAsFixed(2)}",
                                ),
                                selected: selectedSize == size,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      selectedSize = size;
                                      selectedPrice = sizeOptions[size]!;
                                    });
                                  }
                                },
                                selectedColor:
                                    Colors.brown, // Change to your theme color
                                labelStyle: TextStyle(
                                  color:
                                      selectedSize == size
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Select Toppings",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8.0,
                      children:
                          ["Choco Chips", "Nuts", "Sprinkles", "Fruits"].map((
                            topping,
                          ) {
                            return ChoiceChip(
                              label: Text(topping),
                              selected: selectedToppings.contains(topping),
                              onSelected:
                                  availableToppings
                                      ? (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedToppings.add(topping);
                                          } else {
                                            selectedToppings.remove(topping);
                                          }
                                        });
                                      }
                                      : null, // Disables the chip when availableToppings is false
                              selectedColor: Colors.brown,
                              disabledColor:
                                  Colors
                                      .grey[300], // Light grey to indicate disabled
                              labelStyle: TextStyle(
                                color:
                                    selectedToppings.contains(topping)
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            );
                          }).toList(),
                    ),
                    // SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Quantity"),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed:
                                  quantity > 1
                                      ? () {
                                        setState(() => quantity--);
                                      }
                                      : null,
                            ),
                            Text("$quantity"),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                setState(() => quantity++);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    // SizedBox(height: 35),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Add to Cart Logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Added ${cakeName} ($selectedSize) x $quantity to cart!",
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                child: Text(
                  "Add to Cart - ₹${(selectedPrice * quantity).toStringAsFixed(2)}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
