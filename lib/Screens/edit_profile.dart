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
  double _longitude = 0.0;
  double _latitude = 0.0;

  final TextEditingController _emailController = TextEditingController(
    text: Constants.prefs.getString("userEmail"),
  );

  File? _profileImage;
  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  /// Image picker function
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());

      if (originalImage != null) {
        img.Image compressedImage = img.copyResize(originalImage, width: 300);
        File compressedFile = File(imageFile.path)
          ..writeAsBytesSync(img.encodeJpg(compressedImage, quality: 60));

        int fileSize = await compressedFile.length();
        if (fileSize > 500 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Image size must be less than 500KB")),
          );
          return;
        }

        setState(() {
          _profileImage = compressedFile;
        });
      }
    }
  }

  Future<void> _fetchUserDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      String apiUrl = "${Constants.baseUrl}/auth/get_user_details";
      String token = Constants.prefs.getString("token") ?? "";
      print("Stored Token: $token");

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        setState(() {
          _firstNameController.text =
              responseData['data']["user"]["first_name"] ?? "";
          _lastNameController.text =
              responseData['data']["user"]["last_name"] ?? "";
          _phoneController.text =
              responseData['data']["user"]["phone_no"]?.toString() ?? "";

          if (responseData['data']["user"]['address'] != null &&
              responseData['data']["user"]['address'].isNotEmpty) {
            _addressController.text =
                responseData['data']["user"]['address'][0]['address_text'] ??
                "";
            _longitude = double.parse(
              responseData['data']["user"]['address'][0]['longitude'],
            );
            _latitude = double.parse(
              responseData['data']["user"]['address'][0]['latitude'],
            );
          }

          if (responseData['data']["user"]['image_url'] != null &&
              responseData['data']["user"]['image_url'].isNotEmpty) {
            _imageUrl = responseData['data']["user"]['image_url'];
            _profileImage = Image.network(_imageUrl!).image as File;
          }
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load user details: ${response.body}");
      }
    } catch (e) {
      print("Error fetching user details: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load profile details")));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String apiUrl = "${Constants.baseUrl}/auth/update_profile/";
      String token = Constants.prefs.getString("token") ?? "";

      var request = http.MultipartRequest("POST", Uri.parse(apiUrl));
      request.headers["Authorization"] = "Token $token";
      request.headers["Content-Type"] = "multipart/form-data";

      // Add form data
      request.fields["first_name"] = _firstNameController.text.trim();
      request.fields["last_name"] = _lastNameController.text.trim();
      request.fields["phone_no"] = _phoneController.text.trim();

      // Address as JSON
      request.fields["address"] = json.encode({
        "address_text": _addressController.text.trim(),
        "longitude": _longitude,
        "latitude": _latitude,
      });

      // Add profile image if selected
      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'user_image',
            _profileImage!.path,
            contentType: MediaType('image', 'jpeg'), // Adjust format
          ),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = json.decode(await response.stream.bytesToString());
        if (!responseData["error"] && responseData["data"]["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile updated successfully")),
          );
          await Constants.prefs.setString(
            "userSlug",
            responseData['data']['user']['slug'],
          );
          await Constants.prefs.setString(
            "userEmail",
            responseData['data']['user']['email'],
          );
          await Constants.prefs.setString(
            "userName",
            responseData['data']['user']['name'] ?? "-",
          );
          await Constants.prefs.setString(
            "userImage",
            responseData['data']['user']['image_url'] ?? '-',
          );
        } else {
          throw Exception(responseData["message"]);
        }
      } else {
        throw Exception("Failed to update profile");
      }
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save profile: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator while fetching data
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage:
                                        _profileImage != null
                                            ? FileImage(_profileImage!)
                                            : _imageUrl != null
                                            ? NetworkImage(_imageUrl!)
                                                as ImageProvider
                                            : null,
                                    child:
                                        _profileImage == null &&
                                                _imageUrl == null
                                            ? Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.brown,
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: InputDecoration(
                                      labelText: "First Name",
                                    ),
                                    validator:
                                        (value) =>
                                            value!.isEmpty
                                                ? "Enter first name"
                                                : null,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: InputDecoration(
                                      labelText: "Last Name",
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
                            SizedBox(height: 15),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: "Phone Number",
                              ),
                              keyboardType: TextInputType.phone,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? "Enter phone number"
                                          : null,
                            ),
                            SizedBox(height: 15),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(labelText: "Email"),
                              enabled: false,
                            ),
                            SizedBox(height: 15),
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Address",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            _addressController.text.isEmpty
                                                ? "No address added"
                                                : _addressController.text,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Theme.of(context).primaryColor,
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
                                                  onSave: (
                                                    newAddress,
                                                    newlongitude,
                                                    newlatitude,
                                                  ) {
                                                    setState(() {
                                                      _addressController.text =
                                                          newAddress;
                                                      _longitude = newlongitude;
                                                      _latitude = newlatitude;
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
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 50),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Save",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
