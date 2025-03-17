import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:the_cakery/Screens/edit_address.dart';
import 'package:the_cakery/utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(
    text: Constants.prefs.getString("userEmail"),
  );

  double _longitude = 0.0;
  double _latitude = 0.0;
  File? _profileImage;
  String? _imageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
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
            _showErrorSnackBar("Image size must be less than 500KB");
            return;
          }

          setState(() {
            _profileImage = compressedFile;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar("Failed to pick image: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchUserDetails() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse("${Constants.baseUrl}/auth/get_user_details"),
        headers: {
          "Authorization": "Token ${Constants.prefs.getString("token")}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final userData = responseData['data']["user"];

        setState(() {
          _firstNameController.text = userData["first_name"] ?? "";
          _lastNameController.text = userData["last_name"] ?? "";
          _phoneController.text = userData["phone_no"]?.toString() ?? "";

          if (userData['address'] != null && userData['address'].isNotEmpty) {
            final address = userData['address'][0];
            _addressController.text = address['address_text'] ?? "";
            _longitude = double.parse(address['longitude']);
            _latitude = double.parse(address['latitude']);
          }

          if (userData['image_url'] != null &&
              userData['image_url'].isNotEmpty) {
            _imageUrl = userData['image_url'];
          }
        });
      } else {
        throw Exception("Failed to load user details");
      }
    } catch (e) {
      _showErrorSnackBar("Failed to load profile details");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validatePhone(String phone) {
    if (phone.isEmpty) {
      setState(() => _phoneError = "Phone number is required");
      return false;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      setState(() => _phoneError = "Enter a valid 10-digit phone number");
      return false;
    }
    setState(() => _phoneError = null);
    return true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validatePhone(_phoneController.text.trim())) return;

    setState(() => _isSaving = true);

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${Constants.baseUrl}/auth/update_profile/"),
      );

      request.headers.addAll({
        "Authorization": "Token ${Constants.prefs.getString("token")}",
        "Content-Type": "multipart/form-data",
      });

      request.fields.addAll({
        "first_name": _firstNameController.text.trim(),
        "last_name": _lastNameController.text.trim(),
        "phone_no": _phoneController.text.trim(),
        "address": json.encode({
          "address_text": _addressController.text.trim(),
          "longitude": _longitude,
          "latitude": _latitude,
        }),
      });

      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'user_image',
            _profileImage!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var response = await request.send();
      var responseData = json.decode(await response.stream.bytesToString());

      if (response.statusCode == 200 &&
          responseData["data"]["success"] == true) {
        final userData = responseData['data']['user'];
        await Future.wait([
          Constants.prefs.setString("userSlug", userData['slug']),
          Constants.prefs.setString("userEmail", userData['email']),
          Constants.prefs.setString("userName", userData['name'] ?? "-"),
          Constants.prefs.setString("userImage", userData['image_url'] ?? '-'),
        ]);

        _showSuccessSnackBar("Profile updated successfully");
        Navigator.pop(context);
      } else {
        throw Exception(responseData["message"]);
      }
    } catch (e) {
      _showErrorSnackBar("Failed to save profile: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Profile",
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
              : SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.brown[50],
                                  backgroundImage:
                                      _profileImage != null
                                          ? FileImage(_profileImage!)
                                          : _imageUrl != null
                                          ? NetworkImage(_imageUrl!)
                                              as ImageProvider
                                          : null,
                                  child:
                                      _profileImage == null && _imageUrl == null
                                          ? Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.brown[300],
                                          )
                                          : null,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.brown,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _firstNameController,
                                      decoration: InputDecoration(
                                        labelText: "First Name",
                                        prefixIcon: Icon(Icons.person_outline),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      validator:
                                          (value) =>
                                              value!.isEmpty
                                                  ? "Enter first name"
                                                  : null,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lastNameController,
                                      decoration: InputDecoration(
                                        labelText: "Last Name",
                                        prefixIcon: Icon(Icons.person_outline),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      validator:
                                          (value) =>
                                              value!.isEmpty
                                                  ? "Enter last name"
                                                  : null,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: "Phone Number",
                                  prefixIcon: Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  errorText: _phoneError,
                                ),
                                keyboardType: TextInputType.phone,
                                onChanged: (value) => _validatePhone(value),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                enabled: false,
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Delivery Address",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            _addressController.text.isEmpty
                                                ? "Add your delivery address"
                                                : _addressController.text,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color:
                                                  _addressController
                                                          .text
                                                          .isEmpty
                                                      ? Colors.grey[400]
                                                      : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: Colors.brown,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => EditAddressScreen(
                                                  initialAddress:
                                                      _addressController.text,
                                                  initialLongitude: _longitude,
                                                  initialLatitude: _latitude,
                                                  onSave: (address, long, lat) {
                                                    setState(() {
                                                      _addressController.text =
                                                          address;
                                                      _longitude = long;
                                                      _latitude = lat;
                                                    });
                                                  },
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      "Save Changes",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
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
