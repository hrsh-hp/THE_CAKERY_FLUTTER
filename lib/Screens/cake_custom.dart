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
                Column(
                  children:
                      sizeOptions.keys.map((size) {
                        int index = sizeOptions.keys.toList().indexOf(size);
                        return Column(
                          children: [
                            RadioListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                "$size - ₹${sizeOptions[size]!.toStringAsFixed(2)}",
                              ),
                              value: size,
                              groupValue: selectedSize,
                              onChanged: (value) {
                                setState(() {
                                  selectedSize = value.toString();
                                  selectedPrice = sizeOptions[value]!;
                                });
                              },
                            ),
                            if (index < sizeOptions.length - 1)
                              Divider(thickness: 0.5, height: 1),
                          ],
                        );
                      }).toList(),
                ),
                SizedBox(height: 20),
                Text(
                  "Select Toppings",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Column(
                  children:
                      toppings.map((topping) {
                        int index = toppings.indexOf(topping);
                        return Column(
                          children: [
                            CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(topping),
                              value: selectedToppings.contains(topping),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedToppings.add(topping);
                                  } else {
                                    selectedToppings.remove(topping);
                                  }
                                });
                              },
                            ),
                            if (index < toppings.length - 1)
                              Divider(thickness: 0.5, height: 5),
                          ],
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
