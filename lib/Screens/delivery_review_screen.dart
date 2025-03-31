import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:the_cakery/utils/constants.dart'; // Assuming this exists
// import 'package:intl/intl.dart'; // For date formatting
import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

// --- Placeholder for your Color Palette ---
// Replace with your actual theme colors
class ColorPalette {
  static const Color primary = Colors.brown;
  static const Color secondary = Colors.orange;
  static const Color accent = Colors.pinkAccent;
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color background = Color(0xFFF8F8F8);
  static const Color cardBackground = Colors.white;
  static const Color greyLight = Color(0xFFEEEEEE);
  static const Color greyMedium = Color(0xFFBDBDBD);
}
// --- End Placeholder ---

class DeliveryReviewScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final bool isReviewed; // Passed explicitly for initial state control

  const DeliveryReviewScreen({
    super.key,
    required this.order,
    required this.isReviewed,
  });

  @override
  State<DeliveryReviewScreen> createState() => _DeliveryReviewScreenState();
}

class _DeliveryReviewScreenState extends State<DeliveryReviewScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;
  bool _isLoadingReview = false; // Separate loading state for review fetching
  String? _loadingError;
  List<String> _selectedTags = [];
  Map<String, dynamic>? _fetchedReviewDetails; // Store fetched review

  // Safely extract data from the order map
  late String orderSlug;
  late String orderStatus;
  late String deliveryPersonName;
  late String? vehicleNumber;
  late String? phoneNumber;
  late String deliveryPersonSlug;
  late bool isActuallyReviewed; // Derived from order data if needed
  late bool canReview; // Determines if review section should be shown

  // final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

  final List<String> _tags = [
    "Fast Delivery",
    "Polite",
    "Professional",
    "On Time",
    "Great Service",
    "Careful Handling",
    "Friendly",
    "Needs Improvement",
  ];

  @override
  void initState() {
    super.initState();
    _extractOrderData();

    // Determine if the review section should be accessible
    canReview = orderStatus.toLowerCase() == 'delivered';

    // Fetch review details only if the order is marked as reviewed AND delivered
    if (widget.isReviewed && canReview) {
      _fetchReviewDetails();
    } else {
      // If not reviewed or not delivered, no need to fetch review
      _isLoadingReview = false;
    }
  }

  void _extractOrderData() {
    orderSlug = widget.order['slug'] ?? 'unknown_slug';
    orderStatus = widget.order['status'] ?? 'unknown';
    isActuallyReviewed = widget.order['is_reviewed'] ?? false;

    final deliveryPersonData = widget.order['delivery_person'];
    deliveryPersonName = deliveryPersonData?['name'] ?? 'N/A';
    vehicleNumber = deliveryPersonData?['vehicle_number'];
    // Handle phone number potentially being int or String
    phoneNumber = deliveryPersonData?['phone_no']?.toString();
    deliveryPersonSlug = deliveryPersonData?['slug'] ?? 'unknown_dp_slug';
  }

  Future<void> _fetchReviewDetails() async {
    setState(() {
      _isLoadingReview = true;
      _loadingError = null;
    });
    try {
      final response = await http
          .get(
            Uri.parse('${Constants.baseUrl}/cake/orders/review/$orderSlug'),
            headers: {
              "Authorization": "Token ${Constants.prefs.getString("token")}",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)["data"];
        setState(() {
          _fetchedReviewDetails = data;
          _rating = (data["rating"] ?? 0).toDouble();
          _selectedTags = List<String>.from(data["tags"] ?? []);
          _feedbackController.text = data["feedback"] ?? "";
          _isLoadingReview = false;
        });
      } else {
        throw Exception(
          "Server error: ${response.statusCode} ${response.reasonPhrase}",
        );
      }
    } on TimeoutException {
      _setErrorState('Request timed out. Please check your connection.');
    } catch (e) {
      _setErrorState("Failed to load review details: $e");
    }
  }

  void _setErrorState(String message) {
    setState(() {
      _isLoadingReview = false;
      _loadingError = message;
    });
    _showErrorSnackBar(message);
  }

  void _toggleTag(String tag) {
    // Allow toggling only when submitting a new review
    if (canReview && !widget.isReviewed) {
      setState(() {
        if (_selectedTags.contains(tag)) {
          _selectedTags.remove(tag);
        } else {
          _selectedTags.add(tag);
        }
      });
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      _showErrorSnackBar("Please select a rating (tap the stars)");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('${Constants.baseUrl}/cake/orders/review/'),
            headers: {
              "Authorization": "Token ${Constants.prefs.getString("token")}",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "order_slug": orderSlug,
              "delivery_person_slug": deliveryPersonSlug,
              "rating": _rating,
              "feedback": _feedbackController.text.trim(),
              "tags": _selectedTags,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle 201 Created as well
        _showSuccessSnackBar("Thank you for your feedback!");
        // Pop back to the orders list, which should refresh
        Navigator.pop(context);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          "Failed to submit review: ${errorData['message'] ?? response.reasonPhrase}",
        );
      }
    } on TimeoutException {
      _showErrorSnackBar('Request timed out. Please try again.');
    } catch (e) {
      _showErrorSnackBar("Error submitting review: $e");
    } finally {
      // Ensure submit state is reset even if widget is disposed during async gap
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // --- UI Helper Methods ---

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorPalette.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorPalette.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
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

  Future<void> _makePhoneCall(String? number) async {
    if (number == null || number.isEmpty) {
      _showErrorSnackBar("Phone number is not available.");
      return;
    }
    // Prepend 'tel:' scheme
    final Uri launchUri = Uri(scheme: 'tel', path: number);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showErrorSnackBar('Could not launch phone dialer.');
        // Log error for debugging: print('Could not launch $launchUri');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred while trying to call.');
      // Log error for debugging: print('Error launching call: $e');
    }
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    String title = "Order Details";
    if (canReview) {
      title = widget.isReviewed ? "Review Details" : "Rate Delivery";
    } else if (orderStatus.toLowerCase() == 'cancelled' ||
        orderStatus.toLowerCase() == 'failed') {
      title = "Order Cancelled";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: ColorPalette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorPalette.cardBackground,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: ColorPalette.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: ColorPalette.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always show Order Summary
            _buildOrderSummary(),
            const SizedBox(height: 16),

            // Show Status Info (especially useful if not delivered)
            if (!canReview) _buildStatusInfo(),

            // Show Delivery Person details if available and order not cancelled/failed
            if (deliveryPersonName != 'N/A' &&
                orderStatus.toLowerCase() != 'cancelled' &&
                orderStatus.toLowerCase() != 'failed') ...[
              const SizedBox(height: 16),
              _buildDeliveryPersonSection(),
            ],

            // Show Review Section ONLY if order is delivered
            if (canReview) ...[
              const SizedBox(height: 24),
              _buildReviewSectionContainer(), // Contains loading/error/content for review
            ],

            // Show Submit Button ONLY if order is delivered and NOT already reviewed
            if (canReview && !widget.isReviewed) ...[
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final String totalPrice = widget.order['total_price']?.toString() ?? 'N/A';
    final String createdAt = _formatDate(widget.order['created_at']);
    final String deliveryAddress = widget.order['del_address'] ?? 'N/A';
    final List<dynamic> items = widget.order['items'] ?? [];
    final String paymentMethod =
        widget.order['payment']?['payment_method']?.toUpperCase() ?? 'N/A';
    final bool isPaid = widget.order['payment']?['is_paid'] ?? false;

    return Card(
      elevation: 2.0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: ColorPalette.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Summary",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildInfoRow(Icons.receipt_long_outlined, "Order ID: $orderSlug"),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              "Placed on: $createdAt",
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.currency_rupee_rounded, "Total: $totalPrice"),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.payment_outlined,
              "Payment: $paymentMethod ${isPaid ? '(Paid)' : '(Pending)'}",
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on_outlined,
              "Address: $deliveryAddress",
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.cake_outlined,
                "Items: ${items.length} item(s)",
              ),
              // Optionally, list item names here if needed
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: ColorPalette.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Status",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(
                  orderStatus,
                ), // Reuse the chip from OrdersScreen
                const Spacer(),
                if (orderStatus.toLowerCase() == 'confirmed' ||
                    orderStatus.toLowerCase() == 'out_for_delivery')
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: ColorPalette.primary,
                  ),
                if (orderStatus.toLowerCase() == 'cancelled' ||
                    orderStatus.toLowerCase() == 'failed')
                  const Icon(Icons.error_outline, color: ColorPalette.error),
              ],
            ),
            if (!canReview &&
                orderStatus.toLowerCase() != 'cancelled' &&
                orderStatus.toLowerCase() != 'failed') ...[
              const SizedBox(height: 12),
              Text(
                "You can rate the delivery once the order is marked as 'Delivered'.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColorPalette.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryPersonSection() {
    // Check if phone number is valid for showing the call button
    final bool hasValidPhoneNumber =
        phoneNumber != null && phoneNumber!.isNotEmpty;

    return Card(
      elevation: 2.0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: ColorPalette.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Delivery Partner Details",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: ColorPalette.primary.withOpacity(0.1),
                  child: const Icon(
                    Icons.person_outline,
                    size: 30,
                    color: ColorPalette.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliveryPersonName,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Your delivery partner", // Generic description
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorPalette.textSecondary,
                        ),
                      ),
                    ],
                    ),
                ),
                // --- Add Call Button Here (conditionally) ---
                if (hasValidPhoneNumber)
                  IconButton(
                    icon: const Icon(Icons.call_outlined),
                    color: ColorPalette.primary,
                    tooltip: 'Call ${deliveryPersonName}',
                    onPressed: () => _makePhoneCall(phoneNumber),
                  ),
                // --- End Call Button ---
              ],
            ),
            // Optional Details (Vehicle, Phone - keep phone display for info)
            if (vehicleNumber != null || phoneNumber != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 10, thickness: 0.5),
              const SizedBox(height: 6),
              if (vehicleNumber != null)
                _buildInfoRow(
                  Icons.directions_car_outlined,
                  "Vehicle: $vehicleNumber",
                ),
              if (vehicleNumber != null && phoneNumber != null)
                const SizedBox(height: 8),
              // Display phone number text (even with the button present)
              if (phoneNumber != null)
                _buildInfoRow(Icons.phone_outlined, "Phone: $phoneNumber"),
            ],
          ],
        ),
      ),
    );
  }

  // Container to handle loading/error state specifically for the review section
  Widget _buildReviewSectionContainer() {
    if (_isLoadingReview) {
      return const Center(
        child: CircularProgressIndicator(color: ColorPalette.primary),
      );
    }

    if (_loadingError != null) {
      return Card(
        color: ColorPalette.error.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                "Error loading review: $_loadingError",
                style: const TextStyle(color: ColorPalette.error),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Retry"),
                onPressed: _fetchReviewDetails,
              ),
            ],
          ),
        ),
      );
    }

    // If loaded successfully (or no review to load), show the actual review form/details
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingSection(),
        const SizedBox(height: 24),
        _buildTagsSection(),
        const SizedBox(height: 24),
        _buildFeedbackSection(),
      ],
    );
  }

  Widget _buildRatingSection() {
    bool readOnly =
        !canReview ||
        widget.isReviewed; // ReadOnly if not deliverd OR already reviewed

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isReviewed ? "Your Rating" : "Rate your experience",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap:
                  readOnly
                      ? null
                      : () {
                        setState(() {
                          _rating = index + 1.0;
                        });
                      },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < _rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 40, // Slightly larger stars
                  color: Colors.amber,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    bool readOnly = !canReview || widget.isReviewed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isReviewed ? "Feedback Tags" : "What went well? (Optional)",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return AbsorbPointer(
                  // Makes the chip non-interactive if readOnly
                  absorbing: readOnly,
                  child: ChoiceChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: readOnly ? null : (selected) => _toggleTag(tag),
                    selectedColor: ColorPalette.primary,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : ColorPalette.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: ColorPalette.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            isSelected
                                ? ColorPalette.primary
                                : ColorPalette.greyMedium,
                      ),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    bool readOnly = !canReview || widget.isReviewed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isReviewed
              ? "Your Feedback"
              : "Additional Feedback (Optional)",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _feedbackController,
          readOnly: readOnly,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText:
                readOnly
                    ? (_feedbackController.text.isEmpty
                        ? "No additional feedback provided."
                        : null)
                    : "Share more details about your experience...",
            filled: true,
            fillColor:
                readOnly
                    ? ColorPalette.background
                    : ColorPalette.cardBackground,
            hintStyle: const TextStyle(color: ColorPalette.greyMedium),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ColorPalette.greyLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    readOnly ? ColorPalette.greyLight : ColorPalette.greyMedium,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    readOnly ? ColorPalette.greyMedium : ColorPalette.primary,
                width: readOnly ? 1 : 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              // Style for readOnly state
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ColorPalette.greyLight),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primary,
          foregroundColor: Colors.white, // Text color
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text("Submit Review"),
      ),
    );
  }

  // Helper for icon + text rows used in summaries
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ColorPalette.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ColorPalette.textPrimary),
          ),
        ),
      ],
    );
  }

  // Status Chip Widget (copied/adapted from OrdersScreen enhancement)
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
      case 'failed':
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
      avatar: icon != null ? Icon(icon, size: 16, color: textColor) : null,
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
      labelPadding: EdgeInsets.only(left: icon != null ? 2 : 6, right: 6),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}
