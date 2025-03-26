import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:the_cakery/utils/constants.dart';

class EditCakeScreen extends StatefulWidget {
  final String slug;

  const EditCakeScreen({super.key, required this.slug});

  @override
  _EditCakeScreenState createState() => _EditCakeScreenState();
}

class _EditCakeScreenState extends State<EditCakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Cake basic details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _availableToppings = true;
  XFile? _selectedImage;
  String? _currentImageUrl;

  // Size options
  List<Map<String, dynamic>> _sizes = [
    {'size': '', 'price': ''},
  ];

  // Available toppings from backend
  List<Map<String, dynamic>> _Toppings = [];
  List<Map<String, dynamic>> _Sponges = [];
  List<String> _selectedToppingSlugs = [];
  String? _selectedSpongeSlug;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCakeDetails();
    _fetchToppings();
    _fetchSponges();
  }

  Future<void> _fetchCakeDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/cake/full_cake/${widget.slug}'),
        headers: {
          "Authorization": "Token ${Constants.prefs.getString("token")}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)["data"];
        setState(() {
          _nameController.text = data["name"];
          _descriptionController.text = data["description"];
          _availableToppings = data["available_toppings"];
          _currentImageUrl = data["image_url"];
          _selectedSpongeSlug = data["sponge"]['slug'];
          _sizes = List<Map<String, dynamic>>.from(
            data["sizes"].map(
              (size) => {
                'size': size['size'],
                'price': size['price'].toString(),
                'slug': size['slug'],
              },
            ),
          );
          _selectedToppingSlugs = List<String>.from(
            data["toppings"].map((topping) => topping["slug"]),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to fetch cake details"),
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

  void _addSizeField() {
    setState(() {
      _sizes.add({'size': '', 'price': ''});
    });
  }

  void _removeSizeField(int index) {
    if (_sizes.length > 1) {
      setState(() {
        _sizes.removeAt(index);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/cake/edit/'),
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
        'slug': widget.slug,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'available_toppings': _availableToppings.toString(),
        'sizes': json.encode(_sizes),
        'toppings': json.encode(_selectedToppingSlugs),
        'sponge': _selectedSpongeSlug ?? '',
      });

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        Navigator.pop(context, true); // Pass true to indicate successful update
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cake updated successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(decodedResponse["message"] ?? "Failed to update cake");
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
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Cake",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                ),
              )
              : Form(
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
                                : _currentImageUrl != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        _currentImageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        color: Colors.black.withOpacity(0.1),
                                        child: Center(
                                          child: Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                      "Add Cake Image",
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
                      "Basic Details",
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
                        labelText: "Cake Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return "Please enter cake name";
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
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.brown,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      items:
                                          _Sponges.map((sponge) {
                                            return DropdownMenuItem<String>(
                                              value: sponge['slug'],
                                              child: Text(
                                                "${sponge['sponge']} - ${sponge['price']}",
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
                                          return "Please select a sponge";
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
                        labelText: "Description",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return "Please enter description";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    SwitchListTile(
                      title: Text("Available Toppings"),
                      value: _availableToppings,
                      onChanged: (value) {
                        setState(() {
                          _availableToppings = value;
                          if (!value) {
                            _selectedToppingSlugs.clear();
                          }
                        });
                      },
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Sizes Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Size Options",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[800],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addSizeField,
                          icon: Icon(Icons.add),
                          label: Text("Add Size"),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ..._sizes.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Map<String, dynamic> sizeData = entry.value;
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: sizeData['size'],
                                    decoration: InputDecoration(
                                      labelText: "Size Name",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return "Please enter size name";
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      _sizes[idx]['size'] = value;
                                    },
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: sizeData['price'],
                                    decoration: InputDecoration(
                                      labelText: "Price",
                                      prefixText: "₹",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return "Please enter price";
                                      }
                                      if (double.tryParse(value!) == null) {
                                        return "Invalid price";
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      _sizes[idx]['price'] = value;
                                    },
                                  ),
                                ),
                                if (_sizes.length > 1)
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeSizeField(idx),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    if (_availableToppings) ...[
                      SizedBox(height: 24),
                      Text(
                        "Available Toppings",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _Toppings.map((topping) {
                              final isSelected = _selectedToppingSlugs.contains(
                                topping['slug'],
                              );
                              return FilterChip(
                                label: Text(
                                  "${topping['name']} (₹${topping['price']})",
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedToppingSlugs.add(
                                        topping['slug'],
                                      );
                                    } else {
                                      _selectedToppingSlugs.remove(
                                        topping['slug'],
                                      );
                                    }
                                  });
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Colors.brown[100],
                                checkmarkColor: Colors.brown,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? Colors.brown
                                            : Colors.grey[300]!,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],

                    SizedBox(height: 32),
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
            onPressed: _isSaving ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child:
                _isSaving
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text(
                      "Save Changes",
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
