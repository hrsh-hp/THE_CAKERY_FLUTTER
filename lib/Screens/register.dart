import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:the_cakery/utils/constants.dart'; // Assuming Constants.baseUrl is defined here
import 'package:the_cakery/utils/validators.dart'; // Assuming Validators are defined here

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Text Editing Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // UI State
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // --- NEW: Role Selection State ---
  String?
  _selectedRole; // Holds the *backend* value ('user' or 'deliver_person')
  final Map<String, String> _roleOptions = {
    'I am a User': 'user', // Display Name -> Backend Value
    'I am a Delivery Person': 'deliver_person',
  };
  // --- END NEW ---

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!mounted) return;
    // Validate form (this will now include the role dropdown)
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse(
              "${Constants.baseUrl}/auth/register/",
            ), // Ensure Constants.baseUrl is correct
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": _emailController.text.trim(),
              "password": _passwordController.text.trim(),
              "first_name": _firstNameController.text.trim(),
              "last_name": _lastNameController.text.trim(),
              "phone": _phoneController.text.trim(),
              // --- NEW: Add selected role to backend request ---
              // The '!' is safe because validation ensures it's not null here
              "role": _selectedRole!,
              // --- END NEW ---
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final responseData = json.decode(response.body);

      // Improved success check (adapt if your API structure differs)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Assuming a 2xx status indicates success, you might still want
        // to check a specific field in responseData if applicable
        _showSuccessSnackBar(
          responseData["message"] ?? "Registration successful!",
        );
        if (!mounted) return;
        // Consider navigating to a verification screen or directly popping
        Navigator.pop(context);
      } else {
        // Handle specific error messages from backend if available
        String errorMessage = "Registration failed"; // Default
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        } else if (responseData is Map && responseData.containsKey('error')) {
          // Handle cases where error might be nested or have different keys
          var errorDetails = responseData['error'];
          if (errorDetails is Map && errorDetails.isNotEmpty) {
            // Example: Join multiple error messages if backend sends a map of errors
            errorMessage = errorDetails.entries
                .map((e) => "${e.key}: ${e.value.join(', ')}")
                .join('\n');
          } else if (errorDetails is String) {
            errorMessage = errorDetails;
          }
        } else if (response.reasonPhrase != null &&
            response.reasonPhrase!.isNotEmpty) {
          errorMessage = response.reasonPhrase!; // Use HTTP status reason
        }
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMessage = "Something went wrong. Please try again.";
      if (e is TimeoutException) {
        errorMessage = "Connection timed out. Check your internet connection.";
      } else if (e is http.ClientException ||
          e.toString().contains('SocketException')) {
        // Catch common network errors more broadly
        errorMessage = "Network error. Please check your connection.";
      } else if (e is FormatException) {
        errorMessage = "Invalid response from server. Please try again later.";
      }
      _showErrorSnackBar(errorMessage);
    }
  }

  // --- Snackbar Functions remain the same (minor message update) ---
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), // Use dynamic message
        backgroundColor: Colors.green[600], // Slightly darker green
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600], // Slightly darker red
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
        duration: const Duration(seconds: 5), // Give more time for errors
      ),
    );
  }
  // --- End Snackbar Functions ---

  // --- Helper function for consistent TextFormField decoration ---
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.brown[300]),
      prefixIcon: Icon(icon, color: Colors.brown[400]),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ), // Standardized padding
      // Add focused/error border styles for better feedback (optional but good UX)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none, // Keep it clean by default
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.brown.shade300,
          width: 1.5,
        ), // Highlight focus
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
      ),
    );
  }
  // --- End Helper ---

  // --- Helper for the consistent field container (shadow, background) ---
  Widget _buildTextFieldContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color:
            Colors
                .white, // Background is handled by TextFormField's fillcolor now
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.07), // Softer shadow
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
  // --- End Helper ---

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme; // Use theme for text styles

    return Scaffold(
      // Use AppBar for back button and title consistency (Optional)
      // appBar: AppBar(
      //   title: const Text("Create Account"),
      //   elevation: 0,
      //   backgroundColor: Colors.transparent, // Or your theme color
      // ),
      body: Container(
        // Consider using a background color from theme
        // color: Theme.of(context).colorScheme.background,
        height: double.infinity,
        width: double.infinity,
        child: Stack(
          children: [
            // Background Design (keep as is or simplify if needed)
            Positioned(
              top: -size.height * 0.15,
              right: -size.width * 0.4,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.brown[200]?.withOpacity(0.2),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              left: -size.width * 0.3,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.brown[100]?.withOpacity(0.3),
                ),
              ),
            ),

            // Main Content Area
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ), // Add vertical padding
                  child: Form(
                    // Move Form widget higher up to wrap all fields
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Center column items
                      children: [
                        // Logo Section (Reduced vertical space)
                        Container(/* ... Logo ... */),
                        SizedBox(height: size.height * 0.02),

                        // Welcome Text (Centered)
                        Text(
                          "Create Account",
                          style:
                              textTheme.headlineMedium?.copyWith(
                                // Use theme style
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ) ??
                              const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ), // Fallback style
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Sign up to get started",
                          style:
                              textTheme.titleMedium?.copyWith(
                                // Use theme style
                                color: Colors.brown[500],
                              ) ??
                              const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ), // Fallback style
                        ),
                        SizedBox(
                          height: size.height * 0.03,
                        ), // Increased spacing before form fields
                        // --- Registration Form Fields ---

                        // Name Fields
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextFieldContainer(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: _buildInputDecoration(
                                    hintText: "First Name",
                                    icon: Icons.person_outline,
                                  ),
                                  validator:
                                      (value) =>
                                          (value == null ||
                                                  value.trim().isEmpty)
                                              ? "Required"
                                              : null,
                                  textInputAction:
                                      TextInputAction
                                          .next, // Improve keyboard flow
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextFieldContainer(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: _buildInputDecoration(
                                    hintText: "Last Name",
                                    icon: Icons.person_outline,
                                  ),
                                  validator:
                                      (value) =>
                                          (value == null ||
                                                  value.trim().isEmpty)
                                              ? "Required"
                                              : null,
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Standardized spacing
                        // Email Field
                        _buildTextFieldContainer(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 16),
                            decoration: _buildInputDecoration(
                              hintText: "Email",
                              icon: Icons.email_outlined,
                            ),
                            validator:
                                Validators
                                    .validateEmail, // Use external validator
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phone Field
                        _buildTextFieldContainer(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 16),
                            decoration: _buildInputDecoration(
                              hintText: "Phone Number (10 digits)",
                              icon: Icons.phone_outlined,
                            ),
                            // validator: Validators.validatePhone, // Use external validator if available
                            validator: (value) {
                              // Or keep inline
                              if (value == null || value.trim().isEmpty) {
                                return "Phone number is required";
                              }
                              if (!RegExp(
                                r'^[0-9]{10}$',
                              ).hasMatch(value.trim())) {
                                return "Enter valid 10-digit number";
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- NEW: Role Dropdown ---
                        _buildTextFieldContainer(
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            items:
                                _roleOptions.entries.map((entry) {
                                  // Create DropdownMenuItem for each role option
                                  return DropdownMenuItem<String>(
                                    value:
                                        entry
                                            .value, // The value to store ('user' or 'deliver_person')
                                    child: Text(
                                      entry.key,
                                    ), // The text to display
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedRole = newValue;
                              });
                            },
                            decoration: _buildInputDecoration(
                              // Reuse decoration helper
                              hintText: "Select Role", // Changed to hintText
                              icon: Icons.badge_outlined, // Role/Badge icon
                            ).copyWith(
                              // Specific adjustments for dropdown if needed
                              // Example: Remove prefix icon if it feels crowded
                              // prefixIcon: null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ), // Adjust padding for dropdown arrow space
                            ),
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Please select a role'
                                        : null,
                            isExpanded:
                                true, // Make dropdown take full width inside container
                            dropdownColor: Colors.white, // Match background
                          ),
                        ),
                        const SizedBox(height: 16),
                        // --- END NEW ---

                        // Password Field
                        _buildTextFieldContainer(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(fontSize: 16),
                            decoration: _buildInputDecoration(
                              hintText: "Password",
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.brown[400],
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _isPasswordVisible =
                                              !_isPasswordVisible,
                                    ),
                              ),
                            ),
                            validator:
                                Validators
                                    .validatePassword, // Use external validator
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        _buildTextFieldContainer(
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            style: const TextStyle(fontSize: 16),
                            decoration: _buildInputDecoration(
                              hintText: "Confirm Password",
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons
                                          .visibility_off_outlined, // Use outlined icons
                                  color: Colors.brown[400],
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _isConfirmPasswordVisible =
                                              !_isConfirmPasswordVisible,
                                    ),
                              ),
                            ),
                            validator: (value) {
                              // Keep confirm password validator inline
                              if (value == null || value.isEmpty) {
                                return "Please confirm your password";
                              }
                              if (value != _passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                            textInputAction:
                                TextInputAction.done, // Final action
                            onFieldSubmitted:
                                (_) =>
                                    _isLoading
                                        ? null
                                        : _register(), // Allow submitting form via keyboard
                          ),
                        ),
                        SizedBox(
                          height: size.height * 0.03,
                        ), // More space before button
                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 55, // Slightly adjusted height
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.brown[500], // Consistent brown
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2, // Add subtle elevation
                              shadowColor: Colors.brown.withOpacity(0.2),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ), // Ensure vertical padding
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      /* ... Progress Indicator ... */
                                    )
                                    : Text(
                                      "Create Account",
                                      style:
                                          textTheme.titleMedium?.copyWith(
                                            // Use theme style
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ) ??
                                          const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ), // Fallback
                                    ),
                          ),
                        ),
                        SizedBox(
                          height: size.height * 0.02,
                        ), // More space after button
                        // Sign In Link (Improved styling)
                        _buildSignInLink(), // Extracted to helper method

                        SizedBox(height: size.height * 0.02), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget for Sign In Link ---
  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(
            color: Colors.grey[600], // Softer color
            fontSize: 15,
          ),
        ),
        InkWell(
          // Use InkWell for better tap feedback area
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(
            4,
          ), // Optional: for ripple effect shape
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4.0,
              vertical: 2.0,
            ), // Small padding for tap area
            child: Text(
              "Sign In",
              style: TextStyle(
                color: Colors.brown[700], // Theme color
                fontWeight: FontWeight.bold, // Bolder link
                fontSize: 15,
                // decoration: TextDecoration.underline, // Optional underline
                // decorationColor: Colors.brown[700],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- End Helper ---
}
