import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:the_cakery/utils/constants.dart';
import 'package:the_cakery/utils/validators.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    final url = Uri.parse("${Constants.baseUrl}/auth/login/");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      final responseData = jsonDecode(response.body);
      print(responseData);
      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 200) {
        if (!responseData['error']) {
          print(responseData['data']);
          String token = responseData['data']['token'];
          String userSlug = responseData['data']['user']['slug'];
          String userEmail = responseData['data']['user']['email'];
          String userName = responseData['data']['user']['name'] ?? "-";
          String imageUrl = responseData['data']['user']['image_url'] ?? '-';
          String role = responseData['data']['user']['role'] ?? '-';

          await Constants.prefs.setString("token", token);
          await Constants.prefs.setString("userSlug", userSlug);
          await Constants.prefs.setString("userEmail", userEmail);
          await Constants.prefs.setString("userName", userName);
          await Constants.prefs.setString("userImage", imageUrl);
          await Constants.prefs.setBool("isLoggedIn", true);
          await Constants.prefs.setString("role", role);
          print("Login successful!");
          print("Token: $token");
          print("Slug: $userSlug");
          Navigator.pushReplacementNamed(context, "/home");
        } else {
          _showErrorDialog(responseData['message']);
        }
      } else {
        _showErrorDialog("Invalid Email or Password!!");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Our error is : ${e.toString()}");
      _showErrorDialog("Something went wrong! Try Again later");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text("Login Failed"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text("Ok"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text("Login"), centerTitle: true),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF3E7), Color(0xFFEED6C4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: ClipOval(
                          child: Image.asset(
                            "assets/Logo.png",
                            width: 120,
                            height: 120,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Welcome Back,",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Login to your Account,",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Color(0xff707070),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      //Email field is here
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          hintText: "Enter your email",
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 15,
                          ),
                        ),
                        validator: Validators.validateEmail,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 15),
                      //Password field is here
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 15,
                          ),
                        ),
                        validator: Validators.validatePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (value) {
                          _login();
                        },
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                          ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, "/signup");
                            },
                            child: Text(
                              "Sign Up",
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
