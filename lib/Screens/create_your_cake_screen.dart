import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:the_cakery/utils/constants.dart';

class CreateYourCakeScreen extends StatefulWidget {
  const CreateYourCakeScreen({super.key});

  @override
  _CreateYourCakeScreenState createState() => _CreateYourCakeScreenState();
}

class _CreateYourCakeScreenState extends State<CreateYourCakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Cake basic details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _availableToppings = true;
  XFile? _selectedImage;
  int quantity = 1;
  String selectedSize = "";
  double selectedPrice = 0.0;
  String selectedSizeSlug = "";

  // Size options
  List<Map<String, dynamic>> sizeOptions = [];

  // Available toppings and sponges from backend
  List<Map<String, dynamic>> _Toppings = [];
  List<Map<String, dynamic>> _Sponges = [];
  List<String> _selectedToppingSlugs = [];
  bool _isLoading = false;
  String? _selectedSpongeSlug;

  @override
  void initState() {
    super.initState();
    _fetchToppings();
    _fetchSponges();
    _fetchSizes();
  }

  Future<void> _fetchSizes() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/cake/sizes'),
        headers: {
          "Authorization": "Token ${Constants.prefs.getString("token")}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)["data"];
        setState(() {
          sizeOptions = List<Map<String, dynamic>>.from(data);
          if (sizeOptions.isNotEmpty) {
            selectedSizeSlug = sizeOptions[0]['slug'];
            selectedSize = sizeOptions[0]['size'];
            selectedPrice = double.parse(sizeOptions[0]['price'].toString());
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to fetch sizes"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchToppings() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/cake/toppings'),
        headers: {
          "Authorization": "Token ${Constants.prefs.getString("token")}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)["data"];
        setState(() {
          _Toppings = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to fetch toppings"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchSponges() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/cake/sponges'),
        headers: {
          "Authorization": "Token ${Constants.prefs.getString("token")}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)["data"];
        setState(() {
          _Sponges = List<Map<String, dynamic>>.from(data);
          if (_Sponges.isNotEmpty) {
            _selectedSpongeSlug = _Sponges.first['slug'];
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to fetch sponges"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to pick image"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  double calculateTotalPrice() {
    double toppingPrice = _selectedToppingSlugs.fold(0, (sum, toppingSlug) {
      final topping = _Toppings.firstWhere(
        (t) => t['slug'] == toppingSlug,
        orElse: () => {'price': '0'},
      );
      return sum + double.parse(topping['price'].toString());
    });
    return (selectedPrice + toppingPrice) * quantity;
  }

  Future<void> _addToCart() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/cake/custom/add_to_cart/'),
      );

      request.headers.addAll({
        "Authorization": "Token ${Constants.prefs.getString("token")}",
      });

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );
      }

      request.fields.addAll({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'size_slug': selectedSizeSlug,
        'quantity': quantity.toString(),
        'toppings': json.encode(_selectedToppingSlugs),
        'sponge': _selectedSpongeSlug ?? '',
      });

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedResponse = json.decode(responseData);

      if (response.statusCode == 200 && decodedResponse["success"] == true) {
        Navigator.pushReplacementNamed(context, '/cart');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Custom cake added to cart!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(decodedResponse["message"] ?? "Failed to add to cart");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create Your Own Cake",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Image Selection
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child:
                    _selectedImage != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Add Reference Image (Optional)",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            SizedBox(height: 24),

            // Basic Details
            Text(
              "Cake Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Give your cake a name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return "Please enter a name for your cake";
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Sponge Selection
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      "Select Sponge",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.brown[800],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child:
                        _Sponges.isEmpty
                            ? Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  "No sponges available",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            : DropdownButtonFormField<String>(
                              value: _selectedSpongeSlug,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.brown,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                hintText: "Select a sponge type",
                                errorStyle: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down_circle_outlined,
                                color: Colors.brown,
                              ),
                              isExpanded: true,
                              items:
                                  _Sponges.map<DropdownMenuItem<String>>((
                                    sponge,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: sponge['slug'],
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.brown[100],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.cake_outlined,
                                              size: 14,
                                              color: Colors.brown,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              "${sponge['sponge']} - ${sponge['price']}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSpongeSlug = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please select a sponge type";
                                }
                                return null;
                              },
                            ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Special Instructions",
                hintText: "Add any special requirements or instructions",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return "Please add some instructions";
                }
                return null;
              },
            ),
            SizedBox(height: 24),

            // Size Selection
            Text(
              "Choose Size",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 12),
            Container(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    sizeOptions.map((size) {
                      final isSelected = selectedSizeSlug == size['slug'];
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Material(
                          color: isSelected ? Colors.brown : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          elevation: isSelected ? 4 : 1,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedSizeSlug = size['slug'];
                                selectedSize = size['size'];
                                selectedPrice = double.parse(
                                  size['price'].toString(),
                                );
                              });
                            },
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Text(
                                "${size['size']} - ₹${double.parse(size['price'].toString()).toStringAsFixed(2)}",
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.brown,
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

            // Toppings Selection
            Text(
              "Select Toppings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _Toppings.map((topping) {
                    final isSelected = _selectedToppingSlugs.contains(
                      topping['slug'],
                    );
                    return FilterChip(
                      label: Text("${topping['name']} (₹${topping['price']})"),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedToppingSlugs.add(topping['slug']);
                          } else {
                            _selectedToppingSlugs.remove(topping['slug']);
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.brown[100],
                      checkmarkColor: Colors.brown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.brown : Colors.grey[300]!,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: 24),

            // Quantity Selection
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.brown[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  ? () => setState(() => quantity--)
                                  : null,
                          color: Colors.brown,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
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
                          onPressed: () => setState(() => quantity++),
                          color: Colors.brown,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12), // Space for bottom button
          ],
        ),
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
            onPressed: _isLoading ? null : _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child:
                _isLoading
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text(
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
    );
  }
}
