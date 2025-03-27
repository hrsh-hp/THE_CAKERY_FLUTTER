import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching maps and calls
import 'package:http/http.dart' as http; // For status updates
import 'dart:convert';
import 'package:the_cakery/utils/constants.dart'; // For base URL and token (Ensure this path is correct)

// Helper class for status styling (can be shared or redefined)
class StatusStyle {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  StatusStyle(this.icon, this.color, this.backgroundColor);
}

class DeliveryOrderDetailScreen extends StatefulWidget {
  final String orderSlug;
  final Map<String, dynamic> orderDetails;

  const DeliveryOrderDetailScreen({
    Key? key,
    required this.orderSlug,
    required this.orderDetails,
  }) : super(key: key);

  @override
  _DeliveryOrderDetailScreenState createState() =>
      _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState extends State<DeliveryOrderDetailScreen> {
  late Map<String, dynamic> _orderData;
  bool _isUpdatingStatus = false;
  String? _updateError;

  @override
  void initState() {
    super.initState();
    // Make a mutable copy in case we update the status locally
    _orderData = Map<String, dynamic>.from(widget.orderDetails);
  }

  // --- Helper Methods ---

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      // Example format: Aug 23, 2023 at 02:30 PM
      return dateTime.toString();
    } catch (e) {
      print("Error formatting date: $e"); // Log error
      return dateTimeString; // Return original if parsing fails
    }
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return "Unknown";
    // Capitalize first letter of each word, replace underscores
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  StatusStyle _getStatusStyle(ThemeData theme, String status) {
    // Reusing the logic from the list screen or define here
    switch (status.toLowerCase()) {
      case 'confirmed':
        return StatusStyle(
          Icons.thumb_up_alt_outlined,
          Colors.blue.shade800,
          Colors.blue.shade50,
        );
      case 'out_for_delivery':
        return StatusStyle(
          Icons.local_shipping_outlined,
          Colors.orange.shade800,
          Colors.orange.shade50,
        );
      case 'delivered':
        return StatusStyle(
          Icons.check_circle_outline,
          Colors.green.shade800,
          Colors.green.shade50,
        );
      case 'cancelled':
        return StatusStyle(
          Icons.cancel_outlined,
          Colors.red.shade700,
          Colors.red.shade50,
        );
      default:
        return StatusStyle(
          Icons.help_outline,
          theme.colorScheme.onSurfaceVariant,
          theme.colorScheme.surfaceVariant.withOpacity(0.5),
        );
    }
  }

  // --- Action Handlers ---

  Future<void> _launchMaps(String address) async {
    if (address == 'No address provided') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No address available to navigate.')),
      );
      return;
    }
    try {
      final query = Uri.encodeComponent(address);
      // Universal link for Google Maps
      final mapUrl = Uri.parse('https://maps.google.com/maps?q=$query');

      if (await canLaunchUrl(mapUrl)) {
        await launchUrl(
          mapUrl,
          mode: LaunchMode.externalApplication,
        ); // Prefer external app
      } else {
        throw Exception('Could not launch $mapUrl');
      }
    } catch (e) {
      print("Error launching maps: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps application.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _launchPhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this customer.'),
        ),
      );
      return;
    }
    try {
      final phoneUrl = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
      } else {
        throw Exception('Could not launch $phoneUrl');
      }
    } catch (e) {
      print("Error launching phone call: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not initiate phone call.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(
    String newStatus, {
    String? confirmationCode,
  }) async {
    if (_isUpdatingStatus) return; // Prevent multiple updates

    setState(() {
      _isUpdatingStatus = true;
      _updateError = null;
    });
    Uri endpoint;
    Map<String, dynamic> requestBody = {};
    try {
      String statusLower = newStatus.toLowerCase();

      // Add confirmation code ONLY if the status is 'delivered'
      if (statusLower == 'delivered') {
        if (confirmationCode != null && confirmationCode.isNotEmpty) {
          // TODO: Adjust the key 'delivery_confirmation_code'
          requestBody['delivery_confirmation_code'] = confirmationCode;
        }
        if (confirmationCode == null || confirmationCode.isEmpty) {
          throw Exception(
            "Confirmation code is required to mark order as delivered.",
          );
        }
        requestBody = {
          'order_slug':
              widget.orderSlug, // Assuming this endpoint needs slug in body
          'status':
              newStatus, // May or may not be needed if endpoint implies 'delivered'
          'delivery_confirmation_code':
              confirmationCode, // Key name might differ
        };
      } else if (statusLower == 'out_for_delivery' ||
          statusLower == 'failed_delivery') {
        requestBody = {'status': newStatus, 'order_slug': widget.orderSlug};
      } else {
        // Handle unexpected status if necessary
        throw Exception("Unsupported status update: $newStatus");
      }

      endpoint = Uri.parse('${Constants.baseUrl}/cake/orders/complete/');
      // httpMethod = 'POST';
      http.Response response;
      final headers = {
        "Authorization": "Token ${Constants.prefs.getString("token") ?? ''}",
        "Content-Type": "application/json",
        "Accept": "application/json",
      };
      // TODO: Adjust API endpoint and HTTP method (PUT/POST) as needed
      response = await http.post(
        endpoint,
        headers: headers,
        body: json.encode(requestBody),
      );
      // Check if widget is still in the tree

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        // Successfully updated
        setState(() {
          // Update local data to reflect the change immediately
          _orderData['status'] = newStatus;
          // Optionally update other fields if the response contains them (e.g., updated_at)
          // Example: if API returns updated order: _orderData = json.decode(response.body)['data'];
          _isUpdatingStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order status updated to ${_formatStatus(newStatus)}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // Modern look
          ),
        );
        // Optional: Pop back to the list screen after successful final status update
        if (newStatus == 'delivered' ||
            newStatus == 'cancelled' ||
            newStatus == 'failed_delivery') {
          // Delay slightly to allow user to see the snackbar
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted)
              Navigator.pushReplacementNamed(
                context,
                '/orders',
              ); // Pass true to indicate an update occurred
          });
        }
      } else {
        // Handle API error
        String errorMessage =
            "Failed to update status. Server responded with ${response.statusCode}";
        try {
          // Try to parse a more specific error message from the backend
          final responseBody = json.decode(response.body);
          errorMessage =
              responseBody["message"] ?? responseBody["error"] ?? errorMessage;
        } catch (_) {
          // Ignore parsing errors, use the generic message
          print(
            "Response body was not valid JSON or did not contain 'message'/'error'. Body: ${response.body}",
          );
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      print("Error updating status: $e");
      setState(() {
        _isUpdatingStatus = false;
        // Keep the error message specific if it's about the missing code
        _updateError = e.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $_updateError'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showDeliveryConfirmationDialog() async {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>(); // For validation

    // Use dialogContext to avoid issues if the main context changes during async operations
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text('Confirm Delivery'),
          content: SingleChildScrollView(
            // Prevents overflow if keyboard appears
            child: Form(
              // Use a Form for validation
              key: formKey,
              child: ListBody(
                children: <Widget>[
                  const Text(
                    'Please enter the confirmation code provided by the customer.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: codeController,
                    keyboardType: TextInputType.numberWithOptions(
                      signed: false,
                      decimal: false,
                    ), // Common for codes
                    textInputAction:
                        TextInputAction.done, // Show 'Done' on keyboard
                    autofocus: true, // Focus the field immediately
                    decoration: InputDecoration(
                      labelText: 'Confirmation Code',
                      hintText: 'Enter code here',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the confirmation code';
                      }
                      // Optional: Add more specific validation (length, format)
                      // Example: Check if it's exactly 6 digits
                      // if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                      //   return 'Code must be 6 digits';
                      // }
                      return null; // Valid
                    },
                    onFieldSubmitted: (_) {
                      // Allow submitting via keyboard 'Done' button
                      if (formKey.currentState!.validate()) {
                        final enteredCode = codeController.text.trim();
                        _updateOrderStatus(
                          'delivered',
                          confirmationCode: enteredCode,
                        );
                        Navigator.of(dialogContext).pop(); // Close dialog
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                try {
                  Navigator.of(dialogContext).pop();
                } catch (e, s) {
                  print("--- ERROR Popping Dialog (Cancel): $e ---");
                  print(s); // Print stack trace
                }
                // Close the dialog
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Confirm Delivery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: () {
                // Validate the form before proceeding
                if (formKey.currentState!.validate()) {
                  final enteredCode = codeController.text.trim();
                  Navigator.of(dialogContext).pop(); // Close the dialog first
                  // Call update status with the code
                  _updateOrderStatus(
                    'delivered',
                    confirmationCode: enteredCode,
                  );
                }
              },
            ),
          ],
        );
      },
    ).whenComplete(() {
      // Ensure the controller is disposed when the dialog is dismissed
      Future.delayed(const Duration(milliseconds: 300), () {
        // Adjust delay if needed, often small is enough
        try {
          codeController.dispose();
        } catch (e, s) {
          // Log if disposal itself fails, though rare
          print(s);
        }
      });
    });
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Ensure status is read correctly and lowercased for comparisons
    final String currentStatus =
        (_orderData["status"]?.toString() ?? "unknown").toLowerCase();
    final statusStyle = _getStatusStyle(theme, currentStatus);

    // Extract data with null safety and provide defaults
    final String customerName = _orderData["user"]?.toString() ?? 'Customer';
    // TODO: Ensure 'user_phone' key exists in your orderDetails map from the API
    final String customerPhone = _orderData["user_phone"]?.toString() ?? '';
    final String deliveryAddress =  
        _orderData["del_address"]?.toString() ?? 'No address provided';
    final String orderDate = _formatDateTime(
      _orderData["created_at"]?.toString(),
    );
    final String totalPrice = "₹${_orderData["total_price"] ?? '0.00'}";
    final Map<String, dynamic> payment =
        _orderData["payment"] is Map ? _orderData["payment"] : {};
    final String paymentMethod =
        (payment["payment_method"]?.toString() ?? "N/A").toUpperCase();
    final bool isPaid = payment["is_paid"] == true;
    final String paymentStatusText =
        isPaid ? "Paid" : (paymentMethod == 'COD' ? "Collect Cash" : "Pending");
    final List<dynamic> items =
        _orderData["items"] is List ? _orderData["items"] : [];
    // TODO: Ensure 'special_instructions' key exists in your orderDetails map from the API
    final String? specialInstructions =
        _orderData["special_instructions"]?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #${_orderData['user']}', // Use the passed slug
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: IconThemeData(
          color: theme.colorScheme.onSurface,
        ), // Back button color
      ),
      backgroundColor: theme.colorScheme.background, // Use theme background
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          16.0,
        ), // Add padding bottom for BottomAppBar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Chip
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: Icon(
                  statusStyle.icon,
                  size: 18,
                  color: statusStyle.color,
                ),
                label: Text(
                  _formatStatus(currentStatus),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: statusStyle.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: statusStyle.backgroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 20),

            // Customer & Delivery Info Card
            _buildInfoCard(
              theme: theme,
              title: 'Delivery Details',
              children: [
                _buildDetailRow(
                  theme,
                  Icons.person_outline,
                  'Customer',
                  customerName,
                ),
                // Only show phone row if number exists
                if (customerPhone.isNotEmpty)
                  _buildDetailRow(
                    theme,
                    Icons.phone_outlined,
                    'Contact',
                    customerPhone,
                    action: IconButton(
                      icon: Icon(
                        Icons.call_outlined,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                      onPressed: () => _launchPhoneCall(customerPhone),
                      tooltip: 'Call Customer',
                      visualDensity:
                          VisualDensity.compact, // Make button smaller
                      padding: EdgeInsets.zero,
                    ),
                  ),
                _buildDetailRow(
                  theme,
                  Icons.location_on_outlined,
                  'Address',
                  deliveryAddress,
                  isAddress: true, // Allows text wrapping
                  action: IconButton(
                    icon: Icon(
                      Icons.directions_outlined,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                    onPressed:
                        deliveryAddress != 'No address provided'
                            ? () => _launchMaps(deliveryAddress)
                            : null, // Disable if no address
                    tooltip: 'Navigate',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
                // Only show instructions row if they exist and are not empty
                if (specialInstructions != null &&
                    specialInstructions.trim().isNotEmpty) ...[
                  const Divider(height: 20, thickness: 0.5),
                  _buildDetailRow(
                    theme,
                    Icons.speaker_notes_outlined,
                    'Instructions',
                    specialInstructions,
                    isAddress: true,
                  ), // Use isAddress for wrapping
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Order Summary Card
            _buildInfoCard(
              theme: theme,
              title: 'Order Summary',
              children: [
                _buildDetailRow(
                  theme,
                  Icons.calendar_today_outlined,
                  'Placed On',
                  orderDate,
                ),
                _buildDetailRow(
                  theme,
                  Icons.receipt_long_outlined,
                  'Total Amount',
                  totalPrice,
                ),
                _buildDetailRow(
                  theme,
                  Icons.payment_outlined,
                  'Payment',
                  '$paymentMethod ($paymentStatusText)',
                  highlightValue:
                      !isPaid &&
                      paymentMethod ==
                          'COD', // Highlight if COD and needs collection
                  highlightColor:
                      theme.colorScheme.error, // Use error color for emphasis
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Items Card
            _buildInfoCard(
              theme: theme,
              title: 'Items (${items.length})',
              children:
                  items.isEmpty
                      ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No items information available.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ]
                      : items
                          .map(
                            (item) => _buildItemRow(
                              theme,
                              item as Map<String, dynamic>,
                            ),
                          )
                          .toList(), // Cast item
            ),

            // Add some extra space at the bottom if needed, handled by main padding now
            // const SizedBox(height: 20),
          ],
        ),
      ),
      // Bottom Action Bar for Status Updates - only shown if actions are possible
      bottomNavigationBar: _buildActionButtons(theme, currentStatus),
    );
  }

  // --- Helper Widgets ---

  Widget _buildInfoCard({
    required ThemeData theme,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero, // Let the parent padding handle spacing
      clipBehavior: Clip.antiAlias, // Ensures content respects border radius
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Divider(height: 20, thickness: 0.5),
            // Use Column for children to ensure proper layout within the card padding
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    Widget? action,
    bool isAddress = false,
    bool highlightValue = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        // Align icon to top if value text might wrap (like address/instructions)
        crossAxisAlignment:
            isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            // Add slight top padding to icon if aligning to start
            padding: EdgeInsets.only(top: isAddress ? 2.0 : 0),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        highlightValue ? FontWeight.bold : FontWeight.normal,
                    color:
                        highlightValue
                            ? (highlightColor ?? theme.colorScheme.primary)
                            : theme.colorScheme.onSurface,
                  ),
                  // Let the text wrap if needed (for address/instructions)
                  softWrap: true,
                ),
              ],
            ),
          ),
          // If an action widget exists, add it to the end
          if (action != null) ...[const SizedBox(width: 8), action],
        ],
      ),
    );
  }

  Widget _buildItemRow(ThemeData theme, Map<String, dynamic> item) {
    // Safely access item properties with defaults
    final String imageUrl = item['image_url']?.toString() ?? '';
    final String name = item['cake_name']?.toString() ?? 'Unknown Item';
    final int quantity = item['quantity'] is int ? item['quantity'] : 1;
    // final String price = "₹${item['price'] ?? '?.??'}"; // Price per item if needed

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child:
                imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            width: 45,
                            height: 45,
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 20,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            width: 45,
                            height: 45,
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 20,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                    )
                    // Placeholder if no image URL
                    : Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.cake_outlined,
                          size: 24,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$name (x$quantity)', // Show name and quantity
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Optional: Show price per item or total for item
          // Text(price, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget? _buildActionButtons(ThemeData theme, String currentStatus) {
    List<Widget> buttons = [];

    // Determine possible actions based on the current status
    switch (currentStatus) {
      case 'confirmed': // Can start delivery directly from confirmed
      case 'ready_for_pickup': // Or after picking up
        buttons.add(
          _buildStatusButton(
            theme,
            'Start Delivery', // Clearer label
            'out_for_delivery',
            Icons.local_shipping_outlined,
            isPrimary: true, // Make this the main action
          ),
        );
        break;
      case 'out_for_delivery':
        // Action to mark as delivered (triggers confirmation dialog)
        buttons.add(
          _buildStatusButton(
            theme,
            'Mark Delivered',
            'delivered', // The status to set *after* confirmation
            Icons.check_circle_outline,
            isPrimary: true,
            // This button's action is overridden to show the dialog
            onPressedCallback: _showDeliveryConfirmationDialog,
          ),
        );
        // Action for failed delivery attempt
        buttons.add(
          _buildStatusButton(
            theme,
            'Delivery Failed',
            'failed_delivery',
            Icons.warning_amber_outlined,
            isDestructive: true, // Use destructive styling
          ),
        );
        break;
      // No actions needed for final states on this screen
      case 'delivered':
      case 'cancelled':
      case 'failed_delivery':
      default:
        return null; // Return null if no actions are available
    }

    // If no buttons are defined for the current status, return null
    if (buttons.isEmpty) return null;

    // Build the BottomAppBar containing the buttons
    return BottomAppBar(
      elevation: 8, // Give it some shadow
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        // Show loading indicator if updating, otherwise show buttons
        child:
            _isUpdatingStatus
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
                : (buttons.length == 1
                    // If only one button, let it expand
                    ? SizedBox(width: double.infinity, child: buttons.first)
                    // If multiple buttons, space them out in a Row
                    : Row(
                      children:
                          buttons
                              .map(
                                (btn) => Expanded(
                                  child: Padding(
                                    // Add small horizontal padding between buttons
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: btn,
                                  ),
                                ),
                              )
                              .toList(),
                    )),
      ),
    );
  }

  // Helper to build styled ElevatedButton for status updates
  Widget _buildStatusButton(
    ThemeData theme,
    String label,
    String newStatus,
    IconData icon, {
    bool isPrimary = false,
    bool isDestructive = false,
    VoidCallback? onPressedCallback,
  }) {
    // Determine button style based on flags
    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor:
          isPrimary
              ? theme.primaryColor
              : (isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.secondary),
      foregroundColor:
          isPrimary
              ? theme.colorScheme.onPrimary
              : (isDestructive
                  ? theme.colorScheme.onError
                  : theme.colorScheme.onSecondary),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2, // Add subtle elevation to buttons
    );

    return ElevatedButton.icon(
      // icon: Icon(icon, size: 18),
      label: Text(label, textAlign: TextAlign.center),
      // Use the provided callback if available (for 'Mark Delivered'),
      // otherwise default to calling _updateOrderStatus directly.
      onPressed: onPressedCallback ?? () => _updateOrderStatus(newStatus),
      style: style,
    );
  }
}
