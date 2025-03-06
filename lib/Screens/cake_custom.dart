import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:the_cakery/utils/constants.dart';

class CakeCustomScreen extends StatefulWidget {
  // final Function(String, bool) onLikeUpdate;
  final String slug;

  CakeCustomScreen({super.key, required this.slug});

  @override
  State<CakeCustomScreen> createState() => _CakeCustomScreenState();
}

class _CakeCustomScreenState extends State<CakeCustomScreen> {
  bool isLoading = true;
  bool isLiked = false;
  bool initialLikeStatus = false;
  bool availableToppings = true;
  int likes = 0;
  int quantity = 1;
  String selectedSize = "Medium";
  double selectedPrice = 0.0;
  List<String> selectedToppings = [];
  String cakeName = "";
  String imageUrl = "";
  String description = "";
  String cakeSlug = "";
  String selectedSizeSlug = "";
  Map<String, dynamic> toppingsOptions = {};
  Map<String, Map<String, dynamic>> sizeOptions = {};

  // final List<String> toppings = ["Choco Chips", "Nuts", "Sprinkles", "Fruits"];

  @override
  void initState() {
    super.initState();
    print("Received slug: ${widget.slug}"); // Debugging
    fetchCakeDetails(); // If applicable
  }

  double calculateTotalPrice() {
    double toppingPrice = selectedToppings.fold(0, (sum, toppingSlug) {
      return sum + (toppingsOptions[toppingSlug]?["price"] ?? 0.0);
    });

    return (selectedPrice + toppingPrice) * quantity;
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
          initialLikeStatus = isLiked;
          likes = data["likes_count"];
          cakeSlug = data["slug"];
          availableToppings = data["available_toppings"];

          sizeOptions = {
            for (var size in (data["sizes"] ?? [])) // Use null-aware operator
              size["slug"]: {
                "name": size["size"] ?? "Unknown",
                "price":
                    double.tryParse(size["price"]?.toString() ?? "0.0") ?? 0.0,
              },
          };
          selectedSizeSlug = sizeOptions.keys.first;
          selectedSize =
              sizeOptions[selectedSizeSlug]?["name"] ??
              "Medium"; // Get size name
          selectedPrice = sizeOptions[selectedSizeSlug]?["price"] ?? 0.0;
          toppingsOptions = {
            for (var topping in data["toppings"])
              topping["slug"]: {
                "name": topping["name"],
                "price": double.parse(topping["price"]),
                "selected": false, // Default: topping not selected
              },
          };
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching cake details: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to fetch cake details. Please try again."),
        ),
      );
    }
  }

  //add to cart logic here
  Future<void> addToCart(
    BuildContext context,
    String cakeSlug,
    String sizeSlug,
    int quantity,
    double selectedPrice,
    String cakeName,
    List<String> selectedToppings,
  ) async {
    final String apiUrl = "${Constants.baseUrl}/cake/cart/add/";
    final Map<String, dynamic> requestData = {
      "cake_slug": cakeSlug,
      "size_slug": sizeSlug,
      "quantity": quantity,
      "toppings": selectedToppings,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Token ${Constants.prefs.getString("token")}",
        },
        body: jsonEncode(requestData),
      );

      final responseData = jsonDecode(response.body);
      print("responseData: $responseData");

      if (response.statusCode == 200 &&
          responseData['data']["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Added $cakeName (${sizeOptions[sizeSlug]!['name']}) x $quantity to cart!",
            ),
          ),
        );
      } else {
        throw Exception(responseData["message"] ?? "Failed to add to cart");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // widget.onLikeUpdate(widget.slug, isLiked);
        Navigator.pop(context, {
          "isLiked": isLiked,
          "likes": likes,
        }); // Pass updated like status
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
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => LinearProgressIndicator(),
                        errorWidget:
                            (context, url, error) => Icon(
                              Icons.image,
                              size: 100,
                              color: Colors.grey,
                            ),
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
                                bool previousLikedState = isLiked;
                                setState(() {
                                  isLiked = !isLiked;
                                  likes += isLiked ? 1 : -1;
                                });

                                try {
                                  final response = await http.post(
                                    Uri.parse(
                                      '${Constants.baseUrl}/cake/like/',
                                    ),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization':
                                          'Token ${Constants.prefs.getString("token")}',
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
                                    isLiked = previousLikedState; // Revert UI
                                    likes += isLiked ? -1 : 1;
                                  });
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
                          sizeOptions.keys.map((sizeSlug) {
                            final sizeName =
                                sizeOptions[sizeSlug]?["name"] ?? "Unknown";
                            final price =
                                sizeOptions[sizeSlug]?["price"] ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: ChoiceChip(
                                label: Text(
                                  "$sizeName - ₹${price.toStringAsFixed(2)}",
                                ),
                                selected: selectedSizeSlug == sizeSlug,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      selectedSizeSlug = sizeSlug;
                                      selectedSize = sizeName;
                                      selectedPrice = price;
                                    });
                                  }
                                },
                                selectedColor:
                                    Colors.brown, // Change to your theme color
                                labelStyle: TextStyle(
                                  color:
                                      selectedSizeSlug == sizeSlug
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
                          toppingsOptions.entries.map((entry) {
                            final String toppingSlug = entry.key;
                            final Map<String, dynamic> toppingData =
                                entry.value;
                            final String toppingName = toppingData["name"];
                            final double toppingPrice = toppingData["price"];
                            final bool isSelected = selectedToppings.contains(
                              toppingSlug,
                            );

                            return ChoiceChip(
                              label: Text(
                                "$toppingName (+₹${toppingPrice.toStringAsFixed(2)})",
                              ),
                              selected: isSelected,
                              onSelected:
                                  availableToppings
                                      ? (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedToppings.add(toppingSlug);
                                          } else {
                                            selectedToppings.remove(
                                              toppingSlug,
                                            );
                                          }
                                        });
                                      }
                                      : null, // Disables the chip when availableToppings is false
                              selectedColor: Colors.brown,
                              disabledColor:
                                  Colors
                                      .grey[300], // Light grey to indicate disabled
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
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
                onPressed: () async {
                  // Call API
                  await addToCart(
                    context,
                    cakeSlug,
                    selectedSizeSlug,
                    quantity,
                    selectedPrice,
                    cakeName,
                    selectedToppings,
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
                  "Add to Cart - ₹${calculateTotalPrice().toStringAsFixed(2)}",
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
