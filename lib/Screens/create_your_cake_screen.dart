import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:the_cakery/utils/constants.dart';
import 'package:image_picker/image_picker.dart';

class CreateYourCakeScreen extends StatefulWidget {
  const CreateYourCakeScreen({Key? key}) : super(key: key);

  @override
  _CreateYourCakeScreenState createState() => _CreateYourCakeScreenState();
}

class _CreateYourCakeScreenState extends State<CreateYourCakeScreen>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;
  Map<String, dynamic> cakeData = {};
  Map<String, List<dynamic>> availableExtras = {};
  String errorMessage = '';
  double _spongePrice = 0.0;

  String selectedSize = "";
  double selectedPrice = 0.0;
  String selectedSpongeSlug = "";
  String selectedSponge = "";
  List<String> selectedToppings = [];
  Map<String, List<String>> selectedExtras = {
    'fillings': [],
    'candles': [],
    'colors': [],
    'decorations': [],
    'packaging': [],
  };
  int quantity = 1;
  File? _customCakeImage;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _userRequestController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _userRequestController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCakeModificationDetails();
    });
  }

  @override
  void dispose() {
    _userRequestController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        // Use your existing _picker
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        img.Image? originalImage = img.decodeImage(
          await imageFile.readAsBytes(),
        );

        if (originalImage != null) {
          img.Image compressedImage = img.copyResize(originalImage, width: 300);
          File compressedFile = File(imageFile.path)
            ..writeAsBytesSync(img.encodeJpg(compressedImage, quality: 60));

          int fileSize = await compressedFile.length();
          if (fileSize > 500 * 1024) {
            _showErrorSnackBar(
              "Image size must be less than 500KB",
            ); // Use the snackbar function below
            return;
          }

          setState(() {
            _customCakeImage = compressedFile; // Update _customCakeImage
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar(
        "Failed to pick image: $e",
      ); // Use the snackbar function below
    }
  }

  void _showErrorSnackBar(String message) {
    // Reusable error snackbar function
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _fetchCakeModificationDetails() async {
    setState(() => isLoading = true);
    try {
      final response = await http
          .get(
            Uri.parse('${Constants.baseUrl}/cake/for_modification'),
            headers: {
              "Authorization": "Token ${Constants.prefs.getString("token")}",
              "Content-Type": "application/json",
            },
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['error'] != true) {
        _processResponseData(responseData['data']);
      } else {
        setState(() {
          errorMessage =
              responseData['message'] ?? 'Failed to load cake details.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'Failed to load cake details. Check your internet connection.';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _processResponseData(Map<String, dynamic> data) {
    setState(() {
      cakeData = data;
      availableExtras =
          data['available_extras'] != null
              ? (data['available_extras'] as Map).cast<String, List<dynamic>>()
              : {};

      cakeData['sizes'] =
          (data['sizes'] as List<dynamic>?)
              ?.map(
                (size) => {
                  'size': size,
                  'price': '0',
                  'slug': size.toString().toLowerCase().replaceAll(' ', '_'),
                },
              )
              .toList() ??
          [];

      if (cakeData['sizes'].isNotEmpty) {
        final firstSize = cakeData['sizes'][0];
        selectedSize = firstSize['size'];
        selectedPrice = double.parse(firstSize['price']);
      }

      if (data['sponge'] != null && data['sponge'].isNotEmpty) {
        final firstSponge = data['sponge'][0];
        selectedSponge = firstSponge['sponge'];
        selectedSpongeSlug = firstSponge['slug'];
        _spongePrice = double.parse(firstSponge['price']);
      }

      errorMessage = '';
    });
  }

  double calculateTotalPrice() {
    double basePrice = selectedPrice;

    double toppingsPrice = selectedToppings.fold(0.0, (sum, toppingSlug) {
      final topping =
          (cakeData['toppings'] as List<dynamic>?)?.firstWhere(
            (t) => t['slug'] == toppingSlug,
            orElse: () => {'price': '0'},
          ) ??
          {'price': '0'};
      return sum + double.parse(topping['price'].toString());
    });

    double extrasPrice = selectedExtras.entries.fold(0.0, (sum, entry) {
      return sum +
          entry.value.fold(0.0, (categorySum, extraSlug) {
            final categoryExtras = availableExtras[entry.key] ?? [];
            final extra =
                categoryExtras.firstWhere(
                  (e) => e['slug'] == extraSlug,
                  orElse: () => {'price': '0'},
                ) ??
                {'price': '0'};
            return categorySum + double.parse(extra['price'].toString());
          });
    });

    return (basePrice + toppingsPrice + extrasPrice + _spongePrice) * quantity;
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.brown[800],
      ),
    ),
  );

  OutlineInputBorder _buildOutlinedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    );
  }

  OutlineInputBorder _buildFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.brown, width: 1.5),
    );
  }

  Widget _buildSpecialRequestsField() {
    return TextField(
      controller: _userRequestController,
      decoration: InputDecoration(
        hintText: "Special Requests",
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: _buildOutlinedBorder(),
        enabledBorder: _buildOutlinedBorder(),
        focusedBorder: _buildFocusedBorder(),
      ),
      maxLines: 3,
      maxLength: 250,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
    );
  }

  Widget _buildExtrasSection(String category, String title) {
    final options = availableExtras[category] ?? [];
    if (options.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List<Widget>.from(
                options.map((option) {
                  final extraOption = option as Map<String, dynamic>;
                  final isSelected =
                      selectedExtras[category]?.contains(extraOption['slug']) ??
                      false;

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 2),
                    child: FilterChip(
                      label: Text(
                        "${extraOption['name']} (+₹${extraOption['price']})",
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedExtras[category]?.add(extraOption['slug']);
                          } else {
                            selectedExtras[category]?.remove(
                              extraOption['slug'],
                            );
                          }
                        });
                      },
                      selectedColor: Colors.brown[400],
                      backgroundColor:
                          isSelected ? Colors.brown[200] : Colors.grey[200],
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToppingsSection() {
    final toppingsOptions = cakeData['toppings'] as List<dynamic>? ?? [];
    if (toppingsOptions.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Toppings"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List<Widget>.from(
                toppingsOptions.map((toppingData) {
                  final topping = toppingData as Map<String, dynamic>;
                  final isSelected = selectedToppings.contains(topping['slug']);
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 2),
                    child: FilterChip(
                      label: Text(
                        "${topping['name']} (+₹${topping['price']})",
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedToppings.add(topping['slug']);
                          } else {
                            selectedToppings.remove(topping['slug']);
                          }
                        });
                      },
                      selectedColor: Colors.brown[400],
                      backgroundColor:
                          isSelected ? Colors.brown[200] : Colors.grey[200],
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpongeSelection() {
    if (cakeData['sponge'] == null || cakeData['sponge'].isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Sponge"),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                value:
                    selectedSpongeSlug.isNotEmpty ? selectedSpongeSlug : null,
                hint: Text('Select Sponge'),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSpongeSlug = newValue!;
                    final selectedSpongeData = (cakeData['sponge']
                            as List<dynamic>)
                        .firstWhere((s) => s['slug'] == newValue);
                    selectedSponge = selectedSpongeData['sponge'];
                    _spongePrice = double.parse(selectedSpongeData['price']);
                  });
                },
                items:
                    (cakeData['sponge'] as List<dynamic>).map((sponge) {
                      return DropdownMenuItem<String>(
                        value: sponge['slug'] as String,
                        child: Text(
                          "${sponge['sponge']} (+₹${sponge['price']})",
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelection() {
    if (cakeData['sizes'] == null || cakeData['sizes'].isEmpty) {
      return SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Size"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cakeData['sizes']?.length ?? 0,
                separatorBuilder: (context, index) => SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final size = cakeData['sizes'][index] as Map<String, dynamic>;
                  final isSelected = selectedSize == size['size'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedSize = size['size'];
                        selectedPrice = double.parse(size['price']);
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.brown[400] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          "${size['size']}",
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isSelected ? Colors.white : Colors.brown[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart() async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse('${Constants.baseUrl}/cake/cart/add_modified/');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        "Authorization": "Token ${Constants.prefs.getString("token")}",
        "Content-Type": "multipart/form-data",
      });
      request.fields.addAll({
        'size': selectedSize,
        'quantity': quantity.toString(),
        'toppings': jsonEncode(selectedToppings),
        'extras': jsonEncode(selectedExtras),
        'user_request': _userRequestController.text,
        'sponge_slug': selectedSpongeSlug,
      });

      // Send the compressed image if _customCakeImage is not null
      if (_customCakeImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'cake_image', // Key for the image file (backend must expect this)
            _customCakeImage!.path,
            contentType: MediaType(
              'image',
              'jpeg',
            ), // Or determine dynamically if needed
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cake added to cart!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final responseData = json.decode(response.body);
        String message = 'Failed to add to cart.';
        if (responseData != null && responseData['message'] != null) {
          message = responseData['message'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add to cart. Try again later.'),
          backgroundColor: Colors.red,
        ),
      );
      print("Error adding to cart: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Customize Cake",
          style: TextStyle(
            color: Colors.brown[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.brown[900]),
        titleTextStyle: TextStyle(
          color: Colors.brown[900],
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            if (isLoading)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                ),
              )
            else if (errorMessage.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 60),
                      SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchCakeModificationDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 260,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            _customCakeImage != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(_customCakeImage!.path),
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Center(
                                      child: CachedNetworkImage(
                                        imageUrl: cakeData['image_url'] ?? '',
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) => Container(
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.brown.shade400),
                                                ),
                                              ),
                                            ),
                                        errorWidget:
                                            (context, url, error) =>
                                                Icon(Icons.error),
                                        imageBuilder:
                                            (context, imageProvider) =>
                                                Container(
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.camera_alt_outlined,
                                                      size: 40,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        "Share image if you have any",
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                    _buildSizeSelection(),
                    Divider(color: Colors.grey[300], height: 24),
                    _buildSpongeSelection(),
                    Divider(color: Colors.grey[300], height: 24),
                    _buildToppingsSection(),
                    Divider(color: Colors.grey[300], height: 24),
                    _buildExtrasSection('fillings', 'Filling'),
                    Divider(color: Colors.grey[300], height: 24),
                    _buildExtrasSection('candles', 'Candle'),
                    Divider(color: Colors.grey[300], height: 24),
                    _buildExtrasSection('colors', 'Color'),
                    Divider(color: Colors.grey[300], height: 24),
                    _buildExtrasSection('decorations', 'Decoration'),
                    Divider(color: Colors.grey[300], height: 24),
                    _buildExtrasSection('packaging', 'Packaging'),
                    Divider(color: Colors.grey[300], height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Special Requests"),
                          _buildSpecialRequestsField(),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.brown[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle("Quantity"),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove_rounded, size: 18),
                                    onPressed:
                                        quantity > 1
                                            ? () => setState(() => quantity--)
                                            : null,
                                    color: Colors.brown[600],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      "$quantity",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown[800],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_rounded, size: 18),
                                    onPressed: () => setState(() => quantity++),
                                    color: Colors.brown[600],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // SizedBox(height: 60),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isLoading ? null : _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child:
                isLoading
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Add to Cart • ₹${calculateTotalPrice().toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "( ${_spongePrice.toStringAsFixed(2)}₹ Sponge Price )",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
