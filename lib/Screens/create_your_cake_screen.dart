import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart'; // Not used in the relevant part, can be removed if not used elsewhere
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:the_cakery/utils/constants.dart'; // Assuming this defines Constants.baseUrl and Constants.prefs
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

  // --- State Variables for Selection ---
  String selectedSize =
      ""; // Stores the original string value like "0.5", "1.0"
  double selectedPrice = 0.0; // Stores the price of the SELECTED size
  String selectedSpongeSlug = "";
  String selectedSponge = "";
  double _spongePrice = 0.0; // Stores the price of the SELECTED sponge
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

  // --- Image Picking Logic (no changes) ---
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
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
          // Optional: Resize if needed
          // img.Image compressedImage = img.copyResize(originalImage, width: 600);
          // File compressedFile = File(imageFile.path)..writeAsBytesSync(img.encodeJpg(compressedImage, quality: 75));

          File finalFile = imageFile; // Use original for now

          int fileSize = await finalFile.length();
          if (fileSize > 1 * 1024 * 1024) {
            // 1MB limit
            _showErrorSnackBar("Image size must be less than 1MB");
            return;
          }

          setState(() {
            _customCakeImage = finalFile;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar("Failed to pick image: $e");
    }
  }

  // --- Snackbar (no changes) ---
  void _showErrorSnackBar(String message) {
    if (!mounted) return; // Check if widget is still in the tree
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- Fetching Data (no changes) ---
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
            const Duration(seconds: 20), // Adjusted timeout
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

      if (!mounted) return; // Check mounted after await

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['error'] != true) {
        _processResponseData(responseData['data']);
      } else {
        setState(() {
          errorMessage =
              responseData['message'] ??
              'Failed to load cake details (Code: ${response.statusCode}).';
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load details: Connection timed out.';
      });
    } on SocketException {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load details: No Internet connection.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'An unexpected error occurred: $e';
      });
      print("Fetch Error: $e"); // Log the error
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // --- MODIFIED: Processing Data ---
  void _processResponseData(Map<String, dynamic> data) {
    // Process sizes map into a list of maps
    Map<String, dynamic>? rawSizes = data['sizes'] as Map<String, dynamic>?;
    List<Map<String, dynamic>> processedSizes = [];
    if (rawSizes != null) {
      rawSizes.forEach((sizeKey, sizePrice) {
        processedSizes.add({
          'size': sizeKey, // The string key "0.3", "0.5" etc.
          'price':
              (sizePrice as num?)?.toDouble() ?? 0.0, // Ensure price is double
          'slug': sizeKey, // Use size as slug for simplicity, adjust if needed
        });
      });
      // Optional: Sort sizes numerically if they aren't guaranteed to be sorted
      processedSizes.sort((a, b) {
        double? sizeA = double.tryParse(a['size']);
        double? sizeB = double.tryParse(b['size']);
        if (sizeA != null && sizeB != null) {
          return sizeA.compareTo(sizeB);
        }
        return 0; // Keep original order if parsing fails
      });
    }

    setState(() {
      cakeData = data; // Keep the original data structure for other fields
      cakeData['sizes'] =
          processedSizes; // Store the processed list in cakeData

      availableExtras =
          data['available_extras'] != null
              ? (data['available_extras'] as Map).cast<String, List<dynamic>>()
              : {};

      // Set initial selected size and its price
      if (processedSizes.isNotEmpty) {
        final firstSize = processedSizes[0];
        selectedSize = firstSize['size']; // e.g., "0.3"
        selectedPrice = firstSize['price']; // e.g., 120.0
      } else {
        selectedSize = "";
        selectedPrice = 0.0;
      }

      // Set initial selected sponge and its price
      if (data['sponge'] != null && data['sponge'].isNotEmpty) {
        final firstSponge = data['sponge'][0];
        selectedSponge = firstSponge['sponge'];
        selectedSpongeSlug = firstSponge['slug'];
        _spongePrice =
            double.tryParse(firstSponge['price']?.toString() ?? '0') ?? 0.0;
      } else {
        selectedSponge = "";
        selectedSpongeSlug = "";
        _spongePrice = 0.0;
      }

      errorMessage = ''; // Clear error on success
    });
  }
  // --- END MODIFIED ---

  // --- MODIFIED: Price Calculation ---
  double calculateTotalPrice() {
    // Base price is now the price of the selected size
    double basePrice = selectedPrice;

    // Calculate price from selected toppings
    double toppingsPrice = selectedToppings.fold(0.0, (sum, toppingSlug) {
      final topping =
          (cakeData['toppings'] as List<dynamic>?)?.firstWhere(
            (t) => t['slug'] == toppingSlug,
            orElse: () => {'price': '0'},
          ) ??
          {'price': '0'};
      return sum +
          (double.tryParse(topping['price']?.toString() ?? '0') ?? 0.0);
    });

    // Calculate price from selected extras
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
            return categorySum +
                (double.tryParse(extra['price']?.toString() ?? '0') ?? 0.0);
          });
    });

    // Add the selected sponge price
    // The total is (Size Price + Toppings Price + Extras Price + Sponge Price) * Quantity
    return (basePrice + toppingsPrice + extrasPrice + _spongePrice) * quantity;
  }
  // --- END MODIFIED ---

  // --- UI Helpers (no changes) ---
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
        hintText: "Any special instructions? (e.g., 'Happy Birthday John')",
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
                  final price =
                      double.tryParse(
                        extraOption['price']?.toString() ?? '0',
                      ) ??
                      0.0;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: FilterChip(
                      label: Text(
                        "${extraOption['name']}${price > 0 ? ' (+₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)})' : ''}",
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
    if (toppingsOptions.isEmpty) return SizedBox.shrink();

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
                  final price =
                      double.tryParse(topping['price']?.toString() ?? '0') ??
                      0.0;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: FilterChip(
                      label: Text(
                        "${topping['name']}${price > 0 ? ' (+₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)})' : ''}",
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
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                value:
                    selectedSpongeSlug.isNotEmpty ? selectedSpongeSlug : null,
                hint: const Text('Select Sponge'),
                onChanged: (String? newValue) {
                  if (newValue == null) return;
                  setState(() {
                    selectedSpongeSlug = newValue;
                    final selectedSpongeData =
                        (cakeData['sponge'] as List<dynamic>).firstWhere(
                          (s) => s['slug'] == newValue,
                          orElse: () => null,
                        );
                    if (selectedSpongeData != null) {
                      selectedSponge = selectedSpongeData['sponge'];
                      _spongePrice =
                          double.tryParse(
                            selectedSpongeData['price']?.toString() ?? '0',
                          ) ??
                          0.0;
                    } else {
                      selectedSponge = "";
                      _spongePrice = 0.0;
                    }
                  });
                },
                items:
                    (cakeData['sponge'] as List<dynamic>).map((sponge) {
                      final price =
                          double.tryParse(sponge['price']?.toString() ?? '0') ??
                          0.0;
                      return DropdownMenuItem<String>(
                        value: sponge['slug'] as String,
                        child: Text(
                          "${sponge['sponge']}${price > 0 ? ' (+₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)})' : ''}",
                        ),
                      );
                    }).toList(),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please select a sponge'
                            : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper function to format size display (no changes needed here) ---
  String _formatSizeDisplay(String sizeValue) {
    final double? sizeNum = double.tryParse(sizeValue);
    if (sizeNum == null) return sizeValue;

    if (sizeNum < 1.0) {
      final grams = (sizeNum * 1000).toInt();
      return "${grams}g";
    } else {
      if (sizeNum == sizeNum.toInt()) {
        return "${sizeNum.toInt()}kg";
      } else {
        return "${sizeNum}kg";
      }
    }
  }

  // --- MODIFIED: Size Selection Widget ---
  Widget _buildSizeSelection() {
    final sizesList =
        cakeData['sizes'] as List<dynamic>?; // Now expecting a List<Map>
    if (sizesList == null || sizesList.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Size"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: SizedBox(
              height: 45,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sizesList.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sizeData = sizesList[index] as Map<String, dynamic>;
                  final String sizeValue = sizeData['size']; // e.g., "0.5"
                  final double sizePrice = sizeData['price']; // e.g., 200.0
                  final bool isSelected = selectedSize == sizeValue;
                  final String displaySize = _formatSizeDisplay(
                    sizeValue,
                  ); // e.g., "500g"

                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedSize = sizeValue; // Update selected size string
                        selectedPrice = sizePrice; // Update selected size price
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.brown[400] : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.brown[400]!
                                  : Colors.grey[300]!,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: Colors.brown.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : [],
                      ),
                      child: Center(
                        child: Text(
                          displaySize, // Show formatted size (e.g., "500g", "1kg")
                          // Optional: Display price alongside size if needed
                          // displaySize + " (₹${sizePrice.toStringAsFixed(0)})",
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
  // --- END MODIFIED ---

  // --- Add to Cart Logic (no changes needed for API call structure) ---
  Future<void> _addToCart() async {
    // Basic validation before proceeding
    if (selectedSize.isEmpty) {
      _showErrorSnackBar('Please select a size.');
      return;
    }
    if (selectedSpongeSlug.isEmpty) {
      _showErrorSnackBar('Please select a sponge.');
      return;
    }

    setState(() => isLoading = true);
    try {
      final uri = Uri.parse('${Constants.baseUrl}/cake/cart/add_modified/');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        "Authorization": "Token ${Constants.prefs.getString("token")}",
      });
      request.fields.addAll({
        'size': selectedSize, // Send the string key like "0.5", "1.0"
        'quantity': quantity.toString(),
        'toppings': jsonEncode(selectedToppings),
        'extras': jsonEncode(selectedExtras),
        'user_request': _userRequestController.text.trim(),
        'sponge_slug': selectedSpongeSlug,
      });

      if (_customCakeImage != null) {
        String fileExtension =
            _customCakeImage!.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg'; // Default
        if (fileExtension == 'png')
          mimeType = 'image/png';
        else if (fileExtension == 'gif')
          mimeType = 'image/gif';

        request.files.add(
          await http.MultipartFile.fromPath(
            'cake_image',
            _customCakeImage!.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cake added to cart!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Optional: Clear form or navigate away
        // _resetForm();
        // Navigator.pop(context);
      } else {
        String message = 'Failed to add to cart.';
        try {
          final responseData = json.decode(response.body);
          message =
              responseData['message'] ??
              'Failed to add to cart (Code: ${response.statusCode}).';
        } catch (_) {
          message =
              'Failed to add to cart (Code: ${response.statusCode}). Response: ${response.body}';
        }
        _showErrorSnackBar(message);
      }
    } on TimeoutException {
      if (!mounted) return;
      _showErrorSnackBar('Failed to add to cart: Request timed out.');
    } on SocketException {
      if (!mounted) return;
      _showErrorSnackBar('Failed to add to cart: No Internet connection.');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(
        'Failed to add to cart. An unexpected error occurred.',
      );
      print("Error adding to cart: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // --- Build Method (Structure remains the same, uses updated widgets/calculations) ---
  @override
  Widget build(BuildContext context) {
    super.build(context); // Keep state alive

    // Determine if it's the initial load vs. add-to-cart load
    final bool isInitialLoading = isLoading && cakeData.isEmpty;
    final bool isAddingToCart = isLoading && cakeData.isNotEmpty;

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
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.brown[900]),
        titleTextStyle: TextStyle(
          color: Colors.brown[900],
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // --- Initial Loading State ---
            if (isInitialLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                ),
              )
            // --- Error State ---
            else if (errorMessage.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: _fetchCakeModificationDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // --- Content ---
            else
              RefreshIndicator(
                onRefresh: _fetchCakeModificationDetails,
                color: Colors.brown,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    bottom: 100,
                  ), // Padding for bottom bar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Image Section ---
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child:
                                  _customCakeImage != null
                                      ? Image.file(
                                        _customCakeImage!,
                                        fit: BoxFit.cover,
                                      )
                                      : Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Default image
                                          if (cakeData['image_url'] != null &&
                                              (cakeData['image_url'] as String)
                                                  .isNotEmpty)
                                            CachedNetworkImage(
                                              imageUrl: cakeData['image_url'],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              placeholder:
                                                  (context, url) => Center(
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            Colors
                                                                .brown
                                                                .shade200,
                                                          ),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) => Icon(
                                                    Icons.broken_image_outlined,
                                                    color: Colors.grey[400],
                                                    size: 40,
                                                  ),
                                            )
                                          else // Placeholder icon
                                            Icon(
                                              Icons.image_outlined,
                                              color: Colors.grey[400],
                                              size: 50,
                                            ),
                                          // Overlay
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.black.withOpacity(0.0),
                                                  Colors.black.withOpacity(0.4),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 10,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.camera_alt_outlined,
                                                  size: 16,
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _customCakeImage == null
                                                      ? "Upload Reference Image (Optional)"
                                                      : "Change Image",
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                      ),
                      // --- Options Sections ---
                      _buildSizeSelection(), // Uses the modified widget
                      Divider(
                        color: Colors.grey[200],
                        height: 20,
                        indent: 12,
                        endIndent: 12,
                      ),
                      _buildSpongeSelection(),
                      Divider(
                        color: Colors.grey[200],
                        height: 20,
                        indent: 12,
                        endIndent: 12,
                      ),
                      _buildToppingsSection(),
                      Divider(
                        color: Colors.grey[200],
                        height: 20,
                        indent: 12,
                        endIndent: 12,
                      ),
                      _buildExtrasSection('fillings', 'Filling'),
                      Divider(
                        color: Colors.grey[200],
                        height: 20,
                        indent: 12,
                        endIndent: 12,
                      ),
                      _buildExtrasSection('candles', 'Candle'),
                      Divider(
                        color: Colors.grey[200],
                        height: 20,
                        indent: 12,
                        endIndent: 12,
                      ),
                      _buildExtrasSection('colors', 'Color'),
                      Divider(
                        color: Colors.grey[200],
                        height: 20,
                        indent: 12,
                        endIndent: 12,
                      ),
                      _buildExtrasSection('decorations', 'Decoration'),
                      Divider(
                        color: Colors.grey[200],
                        height: 20,
                        indent: 12,
                        endIndent: 12,
                      ),
                      _buildExtrasSection('packaging', 'Packaging'),
                      Divider(
                        color: Colors.grey[200],
                        height: 20,
                        indent: 12,
                        endIndent: 12,
                      ),
                      // --- Special Requests ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Special Requests"),
                            _buildSpecialRequestsField(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // --- Quantity Selector ---
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle("Quantity"),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 20,
                                      ),
                                      onPressed:
                                          quantity > 1
                                              ? () => setState(() => quantity--)
                                              : null,
                                      color:
                                          quantity > 1
                                              ? Colors.brown[600]
                                              : Colors.grey,
                                      splashRadius: 20,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
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
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 20,
                                      ),
                                      onPressed:
                                          () => setState(() => quantity++),
                                      color: Colors.brown[600],
                                      splashRadius: 20,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // --- Loading Overlay for Add to Cart ---
            if (isAddingToCart)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed:
                isLoading
                    ? null
                    : _addToCart, // Disable button during ANY loading
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child:
                isAddingToCart // Show loader only when adding to cart
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Column(
                      // Use Column to potentially show base price breakdown later
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          // Display the FINAL calculated price
                          "Add to Cart • ₹${calculateTotalPrice().toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // Removed the sponge price display here for simplicity,
                        // as the total price now correctly includes everything.
                        // You could add it back if explicitly needed:
                        // if (_spongePrice > 0)
                        //   Padding(...)
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
