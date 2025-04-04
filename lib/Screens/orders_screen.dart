import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/accounts_screen.dart'; // Assuming this exists
import 'package:the_cakery/Screens/delivery_review_screen.dart'; // Assuming this exists
import 'package:the_cakery/utils/bottom_nav_bar.dart'; // Assuming this exists
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:the_cakery/utils/constants.dart'; // Assuming this exists
import 'dart:async';

// --- Placeholder for your Color Palette ---
// Replace with your actual theme colors
class ColorPalette {
  static const Color primary = Colors.brown; // Example
  static const Color secondary = Colors.orange; // Example
  static const Color accent = Colors.pinkAccent; // Example
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color background = Color(0xFFF8F8F8); // Light grey background
  static const Color cardBackground = Colors.white;
  static const Color greyLight = Color(0xFFEEEEEE);
  static const Color greyMedium = Color(0xFFBDBDBD);
}
// --- End Placeholder ---

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _pastOrders = [];
  List<dynamic> _pendingOrders = [];

  // Date formatter
  // final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors on refresh/retry
    });

    try {
      final response = await http
          .get(
            Uri.parse('${Constants.baseUrl}/cake/orders'),
            headers: {
              "Authorization": "Token ${Constants.prefs.getString("token")}",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 15)); // Add a timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body)["data"];
        final List<dynamic> tempPast = [];
        final List<dynamic> tempPending = [];

        for (var order in data) {
          // Define pending statuses clearly
          final isPending =
              order["status"] == "confirmed" ||
              order["status"] == "out_for_delivery" ||
              order["status"] == "pending"; // Added 'pending' just in case

          if (isPending) {
            tempPending.add(order);
          } else {
            tempPast.add(order);
          }
        }
        // Sort orders by creation date (newest first)
        tempPending.sort(
          (a, b) => DateTime.parse(
            b['created_at'],
          ).compareTo(DateTime.parse(a['created_at'])),
        );
        tempPast.sort(
          (a, b) => DateTime.parse(
            b['created_at'],
          ).compareTo(DateTime.parse(a['created_at'])),
        );

        setState(() {
          _pendingOrders = tempPending;
          _pastOrders = tempPast;
          _isLoading = false;
        });
      } else {
        // Handle non-200 status codes (e.g., 401 Unauthorized, 404 Not Found)
        final errorData = json.decode(response.body);
        _setErrorState(
          'Failed to load orders: ${errorData['message'] ?? response.reasonPhrase} (Code: ${response.statusCode})',
        );
      }
    } on TimeoutException {
      _setErrorState(
        'Request timed out. Please check your connection and try again.',
      );
    } on http.ClientException catch (e) {
      _setErrorState(
        'Network error: Failed to connect to the server. ${e.message}',
      );
    } catch (e) {
      // Catch any other unexpected errors
      _setErrorState('An unexpected error occurred: $e');
    }
  }

  void _setErrorState(String message) {
    setState(() {
      _isLoading = false;
      _errorMessage = message;
      _pendingOrders = []; // Clear data on error
      _pastOrders = [];
    });
    _showErrorSnackBar(message); // Optionally show snackbar as well
  }

  Future<void> _cancelOrder(String orderSlug) async {
    // Show confirmation dialog
    final bool? confirmCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: const Text('Are you sure you want to cancel this order?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: ColorPalette.error),
              child: const Text('Yes, Cancel'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmCancel != true) {
      return; // User chose not to cancel
    }

    // Show loading indicator while cancelling
    _showLoadingDialog("Cancelling order...");

    try {
      final response = await http
          .post(
            Uri.parse('${Constants.baseUrl}/cake/orders/cancel/'),
            headers: {
              "Authorization": "Token ${Constants.prefs.getString("token")}",
              "Content-Type": "application/json",
            },
            body: jsonEncode({"order_slug": orderSlug}),
          )
          .timeout(const Duration(seconds: 10));

      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        _showSuccessSnackBar("Order cancelled successfully");
        _fetchOrders(); // Refresh the list
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar(
          "Error cancelling order: ${errorData['message'] ?? response.reasonPhrase}",
        );
      }
    } on TimeoutException {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar('Request timed out. Please try again.');
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar("An error occurred: $e");
    }
  }

  void _navigateToDetailsOrReview(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DeliveryReviewScreen(
              order: order,
              // isReviewed is useful to immediately know if we should fetch review details
              // or show the submission form (if delivered)
              isReviewed: order['is_reviewed'] ?? false,
            ),
      ),
      // Optionally, use .then() if you need to refresh OrdersScreen after review submission
    ).then((_) {
      // This block executes when DeliveryReviewScreen is popped.
      // You might want to refresh the orders list here if a review was submitted.
      print("Returned from DeliveryReviewScreen. Refreshing orders...");
      _fetchOrders(); // Assuming _fetchOrders is your refresh method
    });
  }
  // --- UI Helper Methods ---

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorPalette.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorPalette.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5), // Show errors longer
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      return dateString;
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          "My Orders",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ColorPalette.textPrimary,
          ),
        ),
        automaticallyImplyLeading:
            false, // Keep this if using custom back button
        centerTitle: true,
        elevation: 1, // Subtle elevation
        backgroundColor: ColorPalette.cardBackground, // White background
        surfaceTintColor: Colors.transparent, // Prevent color tinting on scroll
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: ColorPalette.textPrimary,
            size: 20,
          ),
          onPressed:
              () => Navigator.pushReplacementNamed(
                context,
                '/home',
              ), // Or Navigator.pop(context)
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        // Assuming this is correctly implemented
        selectedIndex: 1,
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const AccountsScreen(), // Assuming this is correctly implemented
      backgroundColor: ColorPalette.background, // Use a light background color
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: ColorPalette.primary,
        child: _buildBodyContent(),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return _buildSkeletonLoader();
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_pendingOrders.isEmpty && _pastOrders.isEmpty) {
      return _buildEmptyState(
        "No Orders Yet",
        "Your current and past orders will appear here.",
        Icons.receipt_long_outlined,
      );
    }

    // Use CustomScrollView for combining lists and other elements
    return CustomScrollView(
      slivers: [
        // --- Current Orders Section ---
        _buildSectionHeader("Current Orders"),
        if (_pendingOrders.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildOrderCard(
                    _pendingOrders[index],
                    isCurrent: true,
                  ),
                );
              }, childCount: _pendingOrders.length),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: _buildEmptySectionPlaceholder(
                "No current orders",
                Icons.local_shipping_outlined,
              ),
            ),
          ),

        // --- Past Orders Section ---
        _buildSectionHeader("Past Orders"),
        if (_pastOrders.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildOrderCard(_pastOrders[index], isCurrent: false),
                );
              }, childCount: _pastOrders.length),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: _buildEmptySectionPlaceholder(
                "No past orders",
                Icons.history_outlined,
              ),
            ),
          ),

        // Add some bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  // Header for sections (Current/Past Orders)
  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: ColorPalette.textPrimary,
          ),
        ),
      ),
    );
  }

  // Generic Order Card (for both current and past)
  Widget _buildOrderCard(
    Map<String, dynamic> order, {
    required bool isCurrent,
  }) {
    // Variable definitions seem correct
    final String status = order['status'] ?? 'unknown';
    final dynamic imageUrlDynamic =
        order['items']?.isNotEmpty == true
            ? order['items'][0]['image_url']
            : null;
    final String? imageUrl =
        (imageUrlDynamic is String && imageUrlDynamic.isNotEmpty)
            ? imageUrlDynamic // Use if it's a non-empty string
            : null;
    final String totalPrice = order['total_price']?.toString() ?? 'N/A';
    final String orderId = order['slug']?.toString().split('_').first ?? 'N/A';
    // Assume _formatDate exists elsewhere in the class
    final String createdAt = _formatDate(order['created_at']);
    final String deliveryAddress = order['del_address'] ?? 'N/A';
    final String paymentMethod =
        order['payment']?['payment_method']?.toUpperCase() ?? 'N/A';
    final bool isPaid = order['payment']?['is_paid'] ?? false;

    // Widget structure starts here
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      // Ensure ColorPalette is defined/imported
      color: ColorPalette.cardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        // Assume _navigateToDetailsOrReview exists elsewhere
        onTap: () => _navigateToDetailsOrReview(order),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    // Ternary operator for image/placeholder is correct
                    child:
                        (imageUrl != null)
                            ? Image.network(
                              imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              // errorBuilder signature is correct
                              errorBuilder: (context, error, stackTrace) {
                                // Ensure buildImagePlaceholder is defined
                                return buildImagePlaceholder();
                              },
                              // loadingBuilder signature is correct
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    // Ensure ColorPalette is defined/imported
                                    color: ColorPalette.greyLight,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      // Ternary operator for progress value is correct
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                            )
                            // Ternary operator's ':' part is correct
                            : buildImagePlaceholder(),
                  ),
                  const SizedBox(width: 16), // Correct
                  // Order Info Section
                  Expanded(
                    // Correct
                    child: Column(
                      // Correct
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Assume _buildStatusChip exists elsewhere
                        _buildStatusChip(status),
                        const SizedBox(height: 6), // Correct
                        Text(
                          // Correct
                          "Code for Delivery: $orderId",
                          style: Theme.of(context).textTheme.bodySmall
                          // Ensure ColorPalette is defined/imported
                          ?.copyWith(color: ColorPalette.textSecondary),
                        ),
                        const SizedBox(height: 4), // Correct
                        Text(
                          // Correct
                          "₹$totalPrice",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            // Ensure ColorPalette is defined/imported
                            color: ColorPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4), // Correct
                        Text(
                          // Correct
                          "Ordered on: $createdAt",
                          style: Theme.of(context).textTheme.bodySmall
                          // Ensure ColorPalette is defined/imported
                          ?.copyWith(color: ColorPalette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Action Button Section
                  // if/else structure is correct
                  if (isCurrent) // Ensure isCurrent is passed correctly
                    Padding(
                      // Correct
                      padding: const EdgeInsets.only(left: 8.0),
                      child: IconButton(
                        // Correct
                        icon: const Icon(
                          Icons.cancel_outlined,
                          // Ensure ColorPalette is defined/imported
                          color: ColorPalette.error,
                        ),
                        tooltip: 'Cancel Order',
                        // Assume _cancelOrder exists elsewhere
                        onPressed: () => _cancelOrder(order["slug"]),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  else // Correct
                    Padding(
                      // Correct
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        // Correct
                        Icons.chevron_right,
                        // Ensure ColorPalette is defined/imported
                        color: ColorPalette.greyMedium,
                      ),
                    ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5), // Correct
              // Address/Payment Info
              // Assume _buildInfoRow exists elsewhere
              _buildInfoRow(Icons.location_on_outlined, deliveryAddress),
              const SizedBox(height: 8), // Correct
              // Assume _buildInfoRow exists elsewhere
              _buildInfoRow(
                Icons.payment_outlined,
                // String interpolation with ternary is correct
                "$paymentMethod • ${isPaid ? "Paid" : "Pending"}",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for icon + text rows (Address, Payment)
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: ColorPalette.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ColorPalette.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Status Chip Widget
  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'confirmed':
        chipColor = ColorPalette.info.withOpacity(0.1);
        textColor = ColorPalette.info;
        icon = Icons.thumb_up_alt_outlined;
        break;
      case 'out_for_delivery':
        chipColor = ColorPalette.warning.withOpacity(0.1);
        textColor = ColorPalette.warning;
        icon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
        chipColor = ColorPalette.success.withOpacity(0.1);
        textColor = ColorPalette.success;
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
      case 'failed': // Assuming 'failed' might be a status
        chipColor = ColorPalette.error.withOpacity(0.1);
        textColor = ColorPalette.error;
        icon = Icons.cancel_outlined;
        break;
      default: // Pending or unknown
        chipColor = ColorPalette.greyMedium.withOpacity(0.1);
        textColor = ColorPalette.textSecondary;
        icon = Icons.hourglass_empty_outlined;
    }

    return Chip(
      avatar: icon != null ? Icon(icon, size: 14, color: textColor) : null,
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(), // Make it readable
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
      labelPadding: EdgeInsets.only(
        left: icon != null ? 0 : 4,
        right: 4,
      ), // Adjust padding based on icon
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }

  Widget buildImagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: ColorPalette.greyLight,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Icon(
        Icons.cake_outlined, // Your desired cake icon
        color: ColorPalette.greyMedium,
        size: 35,
      ),
    );
  }

  // Skeleton Loader Widget
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Show a few skeleton items
      itemBuilder: (context, index) {
        return Card(
          elevation: 2.0,
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 18,
                            color: Colors.grey[200],
                          ), // Status chip
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 14,
                            color: Colors.grey[200],
                          ), // Order ID
                          const SizedBox(height: 6),
                          Container(
                            width: 60,
                            height: 16,
                            color: Colors.grey[200],
                          ), // Price
                          const SizedBox(height: 6),
                          Container(
                            width: 140,
                            height: 12,
                            color: Colors.grey[200],
                          ), // Date
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.5),
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.grey[200],
                ), // Address line
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 14,
                  color: Colors.grey[200],
                ), // Payment line
              ],
            ),
          ),
        );
      },
    );
  }

  // Empty State Widget (for entire screen)
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: ColorPalette.greyMedium),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ColorPalette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder for empty sections (Current/Past)
  Widget _buildEmptySectionPlaceholder(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      decoration: BoxDecoration(
        color: ColorPalette.cardBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: ColorPalette.greyLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: ColorPalette.textSecondary),
          const SizedBox(width: 12),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ColorPalette.textSecondary),
          ),
        ],
      ),
    );
  }

  // Error State Widget
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: ColorPalette.error,
            ),
            const SizedBox(height: 24),
            Text(
              "Oops! Something went wrong",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ColorPalette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              onPressed: _fetchOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
