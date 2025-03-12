import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:the_cakery/utils/constants.dart';

class CakeCustomScreen extends StatefulWidget {
  final String slug;

  const CakeCustomScreen({super.key, required this.slug});

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

  @override
  void initState() {
    super.initState();
    fetchCakeDetails();
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
            for (var size in (data["sizes"] ?? []))
              size["slug"]: {
                "name": size["size"] ?? "Unknown",
                "price":
                    double.tryParse(size["price"]?.toString() ?? "0.0") ?? 0.0,
              },
          };

          selectedSizeSlug = sizeOptions.keys.first;
          selectedSize = sizeOptions[selectedSizeSlug]?["name"] ?? "Medium";
          selectedPrice = sizeOptions[selectedSizeSlug]?["price"] ?? 0.0;

          toppingsOptions = {
            for (var topping in data["toppings"])
              topping["slug"]: {
                "name": topping["name"],
                "price": double.parse(topping["price"]),
                "selected": false,
              },
          };

          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to fetch cake details. Please try again."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

      if (response.statusCode == 200 &&
          responseData['data']["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Added $cakeName (${sizeOptions[sizeSlug]!['name']}) x $quantity to cart!",
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {"isLiked": isLiked, "likes": likes});
        return true;
      },
      child: Scaffold(
        body:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                  ),
                )
                : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.brown,
                                            ),
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.cake,
                                      size: 100,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          cakeName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                bool previousLikedState =
                                                    isLiked;
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
                                                      'Content-Type':
                                                          'application/json',
                                                      'Authorization':
                                                          'Token ${Constants.prefs.getString("token")}',
                                                    },
                                                    body: jsonEncode({
                                                      'cake_slug': widget.slug,
                                                      'liked': isLiked,
                                                    }),
                                                  );

                                                  if (response.statusCode !=
                                                      200) {
                                                    throw Exception(
                                                      "Failed to update like status",
                                                    );
                                                  }
                                                } catch (e) {
                                                  setState(() {
                                                    isLiked =
                                                        previousLikedState;
                                                    likes += isLiked ? -1 : 1;
                                                  });
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "Error updating like status",
                                                      ),
                                                      behavior:
                                                          SnackBarBehavior
                                                              .floating,
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Icon(
                                                isLiked
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: Colors.red,
                                                size: 24,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "$likes",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Description",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              "Choose Size",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ),
                            ),
                            SizedBox(height: 12),
                            SizedBox(
                              height: 50,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children:
                                    sizeOptions.keys.map((sizeSlug) {
                                      final sizeName =
                                          sizeOptions[sizeSlug]?["name"] ??
                                          "Unknown";
                                      final price =
                                          sizeOptions[sizeSlug]?["price"] ??
                                          0.0;
                                      final isSelected =
                                          selectedSizeSlug == sizeSlug;

                                      return Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Material(
                                          color:
                                              isSelected
                                                  ? Colors.brown
                                                  : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          elevation: isSelected ? 4 : 1,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                selectedSizeSlug = sizeSlug;
                                                selectedSize = sizeName;
                                                selectedPrice = price;
                                              });
                                            },
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 15,
                                              ),
                                              child: Text(
                                                "$sizeName - ₹${price.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : Colors.brown,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                            SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Select Toppings",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown[800],
                                  ),
                                ),
                                if (!availableToppings)
                                  Text(
                                    "(Not Available)",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  toppingsOptions.entries.map((entry) {
                                    final String toppingSlug = entry.key;
                                    final Map<String, dynamic> toppingData =
                                        entry.value;
                                    final String toppingName =
                                        toppingData["name"];
                                    final double toppingPrice =
                                        toppingData["price"];
                                    final bool isSelected = selectedToppings
                                        .contains(toppingSlug);

                                    return Material(
                                      color:
                                          isSelected
                                              ? Colors.brown[100]
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      elevation: isSelected ? 2 : 1,
                                      child: InkWell(
                                        onTap:
                                            availableToppings
                                                ? () {
                                                  setState(() {
                                                    if (isSelected) {
                                                      selectedToppings.remove(
                                                        toppingSlug,
                                                      );
                                                    } else {
                                                      selectedToppings.add(
                                                        toppingSlug,
                                                      );
                                                    }
                                                  });
                                                }
                                                : null,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                toppingName,
                                                style: TextStyle(
                                                  color:
                                                      isSelected
                                                          ? Colors.brown[900]
                                                          : Colors.grey[800],
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "+₹${toppingPrice.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  color:
                                                      isSelected
                                                          ? Colors.brown[700]
                                                          : Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            SizedBox(height: 24),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.brown[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Quantity",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown[800],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove),
                                          onPressed:
                                              quantity > 1
                                                  ? () =>
                                                      setState(() => quantity--)
                                                  : null,
                                          color: Colors.brown,
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            "$quantity",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add),
                                          onPressed:
                                              () => setState(() => quantity++),
                                          color: Colors.brown,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10), // Space for bottom button
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: Offset(0, -4),
                blurRadius: 8,
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed:
                  () => addToCart(
                    context,
                    cakeSlug,
                    selectedSizeSlug,
                    quantity,
                    selectedPrice,
                    cakeName,
                    selectedToppings,
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Add to Cart • ₹${calculateTotalPrice().toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
