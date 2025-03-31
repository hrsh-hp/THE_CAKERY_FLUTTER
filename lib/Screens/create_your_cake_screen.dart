import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart'; // Not used in the relevant part, can be removed if not used elsewhere
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

  String selectedSize =
      ""; // Stores the original string value like "0.5", "1.0"
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

  // --- Image Picking Logic (no changes) ---
  Future<void> _pickImage() async {
    // ... (image picking logic remains the same) ...
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
          // Optional: Resize if needed, adjust dimensions as required
          // img.Image compressedImage = img.copyResize(originalImage, width: 600);
          // File compressedFile = File(imageFile.path)..writeAsBytesSync(img.encodeJpg(compressedImage, quality: 75));

          // Use original picked file directly for now, ensure backend handles size limits
          File finalFile =
              imageFile; // Use original or compressedFile if you implement compression

          int fileSize = await finalFile.length();
          // Adjust size limit as needed (e.g., 1MB = 1024 * 1024)
          if (fileSize > 1 * 1024 * 1024) {
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
    // ... (snackbar logic remains the same) ...
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
    // ... (fetch logic remains the same) ...
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
            Duration(seconds: 15), // Increased timeout slightly
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
      print("Fetch Error: $e"); // Log the error for debugging
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // --- Processing Data (no changes) ---
  void _processResponseData(Map<String, dynamic> data) {
    // ... (processing logic remains the same) ...
    setState(() {
      cakeData = data;
      availableExtras =
          data['available_extras'] != null
              ? (data['available_extras'] as Map).cast<String, List<dynamic>>()
              : {};

      // Assuming sizes are now like ["0.3", "0.5", "1.0", "1.5"]
      cakeData['sizes'] =
          (data['sizes'] as List<dynamic>?)
              ?.map(
                (sizeValue) => {
                  'size': sizeValue.toString(), // Ensure it's a string
                  'price':
                      '0', // Assuming price comes from elsewhere or is calculated
                  'slug':
                      sizeValue
                          .toString(), // Use the value itself as slug or generate one
                },
              )
              .toList() ??
          [];

      // Set initial selected size if available
      if (cakeData['sizes'] != null && cakeData['sizes'].isNotEmpty) {
        final firstSize = cakeData['sizes'][0];
        selectedSize = firstSize['size']; // Store the string value "0.5" etc.
        selectedPrice = double.tryParse(firstSize['price'] ?? '0') ?? 0.0;
      } else {
        selectedSize = ""; // Reset if no sizes
        selectedPrice = 0.0;
      }

      // Set initial selected sponge if available
      if (data['sponge'] != null && data['sponge'].isNotEmpty) {
        final firstSponge = data['sponge'][0];
        selectedSponge = firstSponge['sponge'];
        selectedSpongeSlug = firstSponge['slug'];
        _spongePrice = double.tryParse(firstSponge['price'] ?? '0') ?? 0.0;
      } else {
        selectedSponge = ""; // Reset if no sponges
        selectedSpongeSlug = "";
        _spongePrice = 0.0;
      }

      errorMessage = ''; // Clear error on successful data processing
    });
  }

  // --- Price Calculation (no changes) ---
  double calculateTotalPrice() {
    // ... (price calculation logic remains the same) ...
    double basePrice =
        selectedPrice; // Base price is currently 0, needs logic if size affects price directly

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

    // Ensure _spongePrice is included
    return (basePrice + toppingsPrice + extrasPrice + _spongePrice) * quantity;
  }

  // --- UI Helpers (no changes) ---
  Widget _buildSectionTitle(String title) => Padding(
    // ... (remains the same) ...
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
    // ... (remains the same) ...
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    );
  }

  OutlineInputBorder _buildFocusedBorder() {
    // ... (remains the same) ...
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.brown, width: 1.5),
    );
  }

  Widget _buildSpecialRequestsField() {
    // ... (remains the same) ...
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
    // ... (remains the same) ...
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
    // ... (remains the same) ...
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
    // ... (remains the same) ...
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
                  if (newValue == null) return; // Handle null case if needed
                  setState(() {
                    selectedSpongeSlug = newValue;
                    final selectedSpongeData =
                        (cakeData['sponge'] as List<dynamic>).firstWhere(
                          (s) => s['slug'] == newValue,
                          orElse: () => null,
                        ); // Handle not found
                    if (selectedSpongeData != null) {
                      selectedSponge = selectedSpongeData['sponge'];
                      _spongePrice =
                          double.tryParse(
                            selectedSpongeData['price']?.toString() ?? '0',
                          ) ??
                          0.0;
                    } else {
                      // Handle case where selected slug somehow doesn't match data
                      selectedSponge = "";
                      _spongePrice = 0.0;
                    }
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
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please select a sponge'
                            : null, // Add validation
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Helper function to format size display ---
  String _formatSizeDisplay(String sizeValue) {
    final double? sizeNum = double.tryParse(sizeValue);
    if (sizeNum == null) {
      return sizeValue; // Return original if parsing fails
    }

    if (sizeNum < 1.0) {
      // Convert to grams
      final grams = (sizeNum * 1000).toInt();
      return "${grams}g";
    } else {
      // Display as kg, removing ".0" if it's a whole number
      if (sizeNum == sizeNum.toInt()) {
        return "${sizeNum.toInt()}kg";
      } else {
        return "${sizeNum}kg";
      }
    }
  }
  // --- END NEW HELPER ---

  // --- MODIFIED: Size Selection Widget ---
  Widget _buildSizeSelection() {
    if (cakeData['sizes'] == null || cakeData['sizes'].isEmpty) {
      return SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Size"), // Changed title slightly
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 0,
            ), // Adjusted padding
            child: SizedBox(
              height: 45, // Slightly increased height for better touch
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cakeData['sizes']?.length ?? 0,
                separatorBuilder:
                    (context, index) => SizedBox(width: 8), // Increased spacing
                itemBuilder: (context, index) {
                  final sizeData =
                      cakeData['sizes'][index] as Map<String, dynamic>;
                  final String sizeValue =
                      sizeData['size']; // e.g., "0.5", "1.0"
                  final bool isSelected = selectedSize == sizeValue;

                  // Use the helper function to get the display text
                  final String displaySize = _formatSizeDisplay(sizeValue);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedSize =
                            sizeValue; // Store the original value "0.5", "1.0"
                        // Update price if size affects base price (currently price is '0')
                        selectedPrice =
                            double.tryParse(sizeData['price'] ?? '0') ?? 0.0;
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
                            isSelected
                                ? Colors.brown[400]
                                : Colors.white, // Changed unselected color
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.brown[400]!
                                  : Colors.grey[300]!, // Dynamic border
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  // Add subtle shadow when selected
                                  BoxShadow(
                                    color: Colors.brown.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                                : [],
                      ),
                      child: Center(
                        child: Text(
                          displaySize, // Use the formatted display text
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

  // --- Add to Cart Logic (no changes) ---
  Future<void> _addToCart() async {
    // ... (add to cart logic remains the same) ...
    setState(() => isLoading = true); // Use the main isLoading flag
    try {
      final uri = Uri.parse('${Constants.baseUrl}/cake/cart/add_modified/');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        "Authorization": "Token ${Constants.prefs.getString("token")}",
        // Content-Type is set automatically for multipart requests
      });
      request.fields.addAll({
        'size':
            selectedSize, // Send the original string value ("0.5", "1.0", etc.)
        'quantity': quantity.toString(),
        'toppings': jsonEncode(selectedToppings),
        'extras': jsonEncode(selectedExtras),
        'user_request': _userRequestController.text.trim(), // Trim requests
        'sponge_slug': selectedSpongeSlug,
      });

      if (_customCakeImage != null) {
        // Determine content type based on file extension (basic example)
        String fileExtension =
            _customCakeImage!.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg'; // Default
        if (fileExtension == 'png') {
          mimeType = 'image/png';
        } else if (fileExtension == 'gif') {
          mimeType = 'image/gif';
        } // Add more types if needed

        request.files.add(
          await http.MultipartFile.fromPath(
            'cake_image',
            _customCakeImage!.path,
            contentType: MediaType.parse(mimeType), // Use parsed content type
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
      ); // Increased timeout for upload
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return; // Check mounted after await

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Accept 201 Created
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cake added to cart!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Optionally navigate away or clear the form
        // Navigator.pop(context);
      } else {
        String message = 'Failed to add to cart.';
        try {
          final responseData = json.decode(response.body);
          message =
              responseData['message'] ??
              'Failed to add to cart (Code: ${response.statusCode}).';
        } catch (_) {
          message = 'Failed to add to cart (Code: ${response.statusCode}).';
        }
        _showErrorSnackBar(message); // Use the helper
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
        setState(() => isLoading = false); // Reset the main isLoading flag
      }
    }
  }

  // --- Build Method (no changes) ---
  @override
  Widget build(BuildContext context) {
    super.build(context); // Keep state alive

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // ... (app bar remains the same) ...
        title: Text(
          "Customize Cake",
          style: TextStyle(
            color: Colors.brown[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1, // Add subtle elevation
        iconTheme: IconThemeData(color: Colors.brown[900]),
        titleTextStyle: TextStyle(
          color: Colors.brown[900],
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent, // Prevent tint on scroll
      ),
      body: GestureDetector(
        onTap:
            () =>
                FocusScope.of(
                  context,
                ).unfocus(), // Dismiss keyboard on tap outside
        child: Stack(
          children: [
            // --- Loading State ---
            if (isLoading &&
                cakeData
                    .isEmpty) // Show loader only if initial data isn't loaded yet
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                ),
              )
            // --- Error State ---
            else if (errorMessage.isNotEmpty)
              Center(
                // ... (error display remains the same) ...
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
                      ElevatedButton.icon(
                        // Added icon to retry button
                        icon: Icon(Icons.refresh),
                        label: Text('Retry'),
                        onPressed: _fetchCakeModificationDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
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
                // Allow pull-to-refresh
                onRefresh: _fetchCakeModificationDetails,
                color: Colors.brown,
                child: SingleChildScrollView(
                  physics:
                      AlwaysScrollableScrollPhysics(), // Ensure scroll even when content is short
                  padding: const EdgeInsets.only(
                    bottom: 100,
                  ), // Padding for bottom bar overlap
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Image Section ---
                      Padding(
                        // Add padding around image picker
                        padding: const EdgeInsets.all(12.0),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: AspectRatio(
                            // Maintain aspect ratio
                            aspectRatio: 16 / 10, // Adjust as needed
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Consistent rounding
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              clipBehavior:
                                  Clip.antiAlias, // Ensure image clips to rounded corners
                              child:
                                  _customCakeImage != null
                                      ? Image.file(
                                        _customCakeImage!,
                                        fit: BoxFit.cover,
                                      )
                                      : Stack(
                                        // Stack for overlay text/icon
                                        alignment: Alignment.center,
                                        children: [
                                          // Default image if available
                                          if (cakeData['image_url'] != null &&
                                              (cakeData['image_url'] as String)
                                                  .isNotEmpty)
                                            CachedNetworkImage(
                                              imageUrl: cakeData['image_url'],
                                              fit: BoxFit.cover,
                                              width:
                                                  double
                                                      .infinity, // Ensure it fills container
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
                                          else // Placeholder if no default image
                                            Icon(
                                              Icons.image_outlined,
                                              color: Colors.grey[400],
                                              size: 50,
                                            ),

                                          // Overlay Icon and Text
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              gradient: LinearGradient(
                                                // Subtle gradient overlay
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
                                            // Position text/icon at bottom
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
                                                SizedBox(width: 6),
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
                      SizedBox(height: 16),
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
                            color:
                                Colors
                                    .white, // Use white background for contrast
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle(
                                "Quantity",
                              ), // Reusing title style
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      Colors
                                          .grey[100], // Lighter background for buttons
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        size: 20,
                                      ), // Different icon
                                      onPressed:
                                          quantity > 1
                                              ? () => setState(() => quantity--)
                                              : null,
                                      color:
                                          quantity > 1
                                              ? Colors.brown[600]
                                              : Colors
                                                  .grey, // Indicate disabled state
                                      splashRadius: 20, // Smaller splash
                                      constraints:
                                          BoxConstraints(), // Remove default padding
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ), // More horizontal padding
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
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        size: 20,
                                      ), // Different icon
                                      onPressed:
                                          () => setState(() => quantity++),
                                      color: Colors.brown[600],
                                      splashRadius: 20,
                                      constraints: BoxConstraints(),
                                      padding: EdgeInsets.symmetric(
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
            if (isLoading &&
                cakeData.isNotEmpty) // Show overlay only during add-to-cart
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
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
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ), // Adjusted padding
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            // Add shadow for elevation effect
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
          // border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)), // Can remove border if shadow is used
        ),
        child: SafeArea(
          // Ensure content is within safe area (especially for notches)
          child: ElevatedButton(
            onPressed:
                isLoading
                    ? null
                    : _addToCart, // Disable button during any loading state
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ), // Increased padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ), // Consistent rounding
              elevation: 0, // Keep flat if desired, or add slight elevation
            ),
            child:
                isLoading &&
                        cakeData
                            .isNotEmpty // Show specific loader only for add-to-cart
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Column(
                      // Keep the column layout for price and sponge info
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
                        if (_spongePrice >
                            0) // Show sponge price only if it's selected and has a price
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              "(+ ₹${_spongePrice.toStringAsFixed(2)} Sponge)", // Clearer text
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
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
