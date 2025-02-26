import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  File? _profileImage;

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
          _profileImage = imageFile;
        });
      }
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      print("profile updated");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Profile saved")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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
                                    : null,
                            child:
                                _profileImage == null
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
                              // border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty ? "Enter first name" : null,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: "Last Name",
                              // border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty ? "Enter last name" : null,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 15),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        // border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator:
                          (value) =>
                              value!.isEmpty ? "Enter phone number" : null,
                    ),

                    SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        // border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),

                    SizedBox(height: 15),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: "Address"),
                      validator:
                          (value) => value!.isEmpty ? "Enter address" : null,
                    ),

                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 50),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Save",
                        style: TextStyle(color: Colors.white, fontSize: 18),
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
