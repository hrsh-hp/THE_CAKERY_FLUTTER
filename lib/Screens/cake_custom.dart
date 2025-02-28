import 'package:flutter/material.dart';

class CakeCustomScreen extends StatefulWidget {
  final String cakeName;
  final String imageUrl;
  final double basePrice;
  final String description;
  final int initialLikes;
  final String? slug;
  bool isLiked;

  CakeCustomScreen({
    super.key,
    required this.cakeName,
    required this.imageUrl,
    required this.basePrice,
    required this.description,
    required this.initialLikes,
    this.slug,
    required this.isLiked,
  });

  @override
  State<CakeCustomScreen> createState() => _CakeCustomScreenState();
}

class _CakeCustomScreenState extends State<CakeCustomScreen> {
  int likes = 0;
  int quantity = 1;
  String selectedSize = "Medium";
  double selectedPrice = 0.0;
  List<String> selectedToppings = [];

  final Map<String, double> sizeOptions = {
    "Small": 499.0,
    "Medium": 799.0,
    "Large": 1199.0,
  };

  final List<String> toppings = ["Choco Chips", "Nuts", "Sprinkles", "Fruits"];

  @override
  void initState() {
    super.initState();
    likes = widget.initialLikes;
    selectedPrice = widget.basePrice;
    sizeOptions['Medium'] = widget.basePrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cakeName)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.network(
                    widget.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.cakeName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon:
                              widget.isLiked
                                  ? Icon(Icons.favorite, color: Colors.red)
                                  : Icon(
                                    Icons.favorite_outline,
                                    color: Colors.red,
                                  ),
                          onPressed: () {
                            setState(() {
                              if (widget.isLiked) {
                                likes--;
                              } else {
                                likes++;
                              }
                              widget.isLiked = !widget.isLiked;
                            });
                          },
                        ),
                        Text("$likes"),
                      ],
                    ),
                  ],
                ),
                Text(widget.description, style: TextStyle(fontSize: 16)),
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
                      toppings.map((topping) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4.0,
                          ), // Adds spacing between chips
                          child: ChoiceChip(
                            label: Text(topping),
                            selected: selectedToppings.contains(topping),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedToppings.add(topping);
                                } else {
                                  selectedToppings.remove(topping);
                                }
                              });
                            },
                            selectedColor:
                                Colors.brown, // Change to your theme color
                            labelStyle: TextStyle(
                              color:
                                  selectedToppings.contains(topping)
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                ),

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
                SizedBox(height: 35),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Add to Cart Logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Added ${widget.cakeName} ($selectedSize) x $quantity to cart!",
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
          ),
        ],
      ),
    );
  }
}
