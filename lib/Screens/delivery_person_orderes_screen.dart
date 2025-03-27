import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/accounts_screen.dart'; // TODO: Replace with DeliveryPerson specific drawer if needed
import 'package:the_cakery/Screens/delivey_order_Detail._Screen.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart'; // TODO: Adjust selectedIndex if needed for delivery flow
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:the_cakery/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:intl/intl.dart'; // For date formatting

// TODO: Import the actual DeliveryOrderDetailScreen
// import 'delivery_order_detail_screen.dart';

// Placeholder for the detail screen navigation

class DeliveryPersonOrdersScreen extends StatefulWidget {
  const DeliveryPersonOrdersScreen({Key? key}) : super(key: key);

  @override
  _DeliveryPersonOrdersScreenState createState() =>
      _DeliveryPersonOrdersScreenState();
}

class _DeliveryPersonOrdersScreenState
    extends State<DeliveryPersonOrdersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<dynamic> _activeDeliveries = [];
  List<dynamic> _deliveryHistory = [];

  // Define delivery-relevant statuses
  final Set<String> _activeStatuses = {
    "confirmed",
    "ready_for_pickup", // Example status
    "out_for_delivery", // Example status
  };
  final Set<String> _historyStatuses = {
    "delivered",
    "cancelled",
    "failed_delivery", // Example status
  };

  @override
  void initState() {
    super.initState();
    _fetchAssignedOrders();
  }

  // --- Data Fetching ---
  Future<void> _fetchAssignedOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // TODO: Replace with the correct API endpoint for fetching orders assigned to the delivery person
      final response = await http.get(
        // Example endpoint: Adjust as per your backend API
        Uri.parse('${Constants.baseUrl}/cake/orders'),
        headers: {
          "Authorization": "Token ${Constants.prefs.getString("token") ?? ''}",
          "Content-Type": "application/json",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        // Adjust based on your API response structure
        final List<dynamic> data = responseData["data"] ?? [];

        List<dynamic> active = [];
        List<dynamic> history = [];

        for (var order in data) {
          String status = (order["status"] ?? "").toString().toLowerCase();
          if (_activeStatuses.contains(status)) {
            active.add(order);
          } else if (_historyStatuses.contains(status)) {
            history.add(order);
          }
          // Orders with other statuses might be ignored or handled differently
        }

        // Sort active orders (e.g., by creation date or urgency)
        active.sort(
          (a, b) => (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''),
        );
        // Sort history orders (e.g., newest first)
        history.sort(
          (a, b) => (b['updated_at'] ?? '').compareTo(a['updated_at'] ?? ''),
        );

        setState(() {
          _activeDeliveries = active;
          _deliveryHistory = history;
          _isLoading = false;
        });
      } else {
        // Try to parse a more specific error message from the backend
        String message =
            "Failed to load assigned orders. Status code: ${response.statusCode}";
        try {
          message = json.decode(response.body)["message"] ?? message;
        } catch (_) {
          // Ignore if parsing fails, use the generic message
        }
        throw Exception(message);
      }
    } catch (e) {
      if (!mounted) return;
      print(
        "Error fetching delivery orders: $e",
      ); // Log the error for debugging
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        ); // Cleaner error message
      });

      // Show a more informative SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $_errorMessage'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating, // Modern look
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _fetchAssignedOrders,
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  // --- Navigation ---
  void _navigateToOrderDetail(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DeliveryOrderDetailScreen(
              // Navigate to the correct screen
              orderSlug: order["slug"] ?? '',
              orderDetails: order,
            ),
      ),
    ).then((_) {
      // Optional: Refresh list if status might have changed after viewing details
      // _fetchAssignedOrders();
    });
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Use theme for consistent styling

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          "My Deliveries",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface, // Use theme color
          ),
        ),
        elevation: 1, // Subtle elevation
        shadowColor: Colors.black.withOpacity(0.1),
        backgroundColor: theme.colorScheme.surface, // Use theme color
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Open Menu', // Accessibility
        ),
        // Optional: Add actions like a refresh button or availability toggle
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
        //     onPressed: _fetchAssignedOrders,
        //     tooltip: 'Refresh Orders',
        //   ),
        // ],
      ),
      // TODO: Adjust selectedIndex based on the delivery person's navigation flow
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        scaffoldKey: _scaffoldKey,
      ),
      // TODO: Replace with a delivery-person specific drawer if available
      drawer: const AccountsScreen(),
      backgroundColor: theme.colorScheme.background, // Use theme background
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return _buildSkeletonLoader(theme);
    }
    if (_hasError) {
      return _buildErrorState(theme);
    }
    if (_activeDeliveries.isEmpty && _deliveryHistory.isEmpty) {
      return _buildEmptyState(
        theme,
        "No Deliveries Yet",
        "You currently have no assigned or past deliveries.",
        Icons.motorcycle_outlined, // Relevant icon
        showRetryButton: true,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAssignedOrders,
      color: theme.primaryColor, // Use primary color for indicator
      child: CustomScrollView(
        slivers: [
          // --- Active Deliveries Section ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
              child: Text(
                "Active Deliveries",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ),
          ),
          if (_activeDeliveries.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildEmptyState(
                  theme,
                  "No Active Deliveries",
                  "No orders currently require your action.",
                  Icons.notifications_paused_outlined,
                  showRetryButton: false, // No retry needed here specifically
                ),
              ),
            )
          else
            _buildActiveDeliveriesList(theme),

          // --- Delivery History Section ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Text(
                "Delivery History",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ),
          ),
          if (_deliveryHistory.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildEmptyState(
                  theme,
                  "No Delivery History",
                  "You haven't completed any deliveries yet.",
                  Icons.history_toggle_off_outlined,
                  showRetryButton: false,
                ),
              ),
            )
          else
            _buildDeliveryHistoryList(theme),

          // Add some bottom padding
          // const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  // --- State Specific Widgets ---

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Deliveries',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: _fetchAssignedOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon, {
    bool showRetryButton = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.secondary.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (showRetryButton) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              onPressed: _fetchAssignedOrders,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primaryColor,
                side: BorderSide(color: theme.primaryColor.withOpacity(0.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme) {
    // Simple shimmer effect placeholder
    Color baseColor = Colors.grey[300]!;
    Color highlightColor = Colors.grey[100]!;

    Widget skeletonItem() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 50, height: 50, color: baseColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 14, color: baseColor),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: baseColor,
                  ),
                  const SizedBox(height: 6),
                  Container(width: 150, height: 12, color: baseColor),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Use ListView for shimmer effect (requires shimmer package)
    // Or just repeat static placeholders
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => skeletonItem(),
    );

    /* // Without shimmer package:
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: List.generate(5, (_) => skeletonItem()),
      ),
    );
    */
  }

  // --- List Builders ---

  Widget _buildActiveDeliveriesList(ThemeData theme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final order = _activeDeliveries[index];
        return _buildDeliveryCard(theme, order, isActive: true);
      }, childCount: _activeDeliveries.length),
    );
  }

  Widget _buildDeliveryHistoryList(ThemeData theme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final order = _deliveryHistory[index];
        return _buildDeliveryCard(theme, order, isActive: false);
      }, childCount: _deliveryHistory.length),
    );
  }

  // --- Reusable Card Widget ---

  Widget _buildDeliveryCard(
    ThemeData theme,
    Map<String, dynamic> order, {
    required bool isActive,
  }) {
    final List<dynamic> items = order["items"] ?? [];
    final String imageUrl = items.isNotEmpty ? items[0]["image_url"] ?? '' : '';
    final String status = (order["status"] ?? "Unknown").toString();
    final String address = order["del_address"] ?? 'No address provided';
    final String orderId =
        order["slug"] ?? order["id"]?.toString() ?? 'N/A'; // Use slug or ID
    final String totalPrice = "₹${order["total_price"] ?? '0.00'}";
    final String customerName =
        order["user"] ?? 'Customer'; // Assuming 'user' holds name/identifier

    // Determine status color and icon
    final StatusStyle statusStyle = _getStatusStyle(theme, status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Ensures InkWell respects border radius
      color: theme.colorScheme.outlineVariant, // Use theme surface color
      child: InkWell(
        onTap: () => _navigateToOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    width: 55,
                                    height: 55,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(
                                        Icons.cake_outlined,
                                        color: Colors.grey[400],
                                        size: 24,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    width: 55,
                                    height: 55,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.grey[400],
                                        size: 24,
                                      ),
                                    ),
                                  ),
                            )
                            : Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  color: Colors.grey[400],
                                  size: 24,
                                ),
                              ),
                            ),
                  ),
                  const SizedBox(width: 16),
                  // Order Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #$customerName', // Display Order ID/Slug
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customerName, // Display Customer Name
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Status Chip
                        Chip(
                          avatar: Icon(
                            statusStyle.icon,
                            size: 16,
                            color: statusStyle.color,
                          ),
                          label: Text(
                            _formatStatus(status),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: statusStyle.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: statusStyle.backgroundColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                  // Price (optional, maybe less prominent for delivery)
                  // Text(
                  //   totalPrice,
                  //   style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  // ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
              const SizedBox(height: 12),
              // Address Info
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Optional: Add Delivery Time/Date if available
              if (!isActive && order['updated_at'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      status.toLowerCase() == 'delivered'
                          ? Icons.check_circle_outline
                          : Icons.history_outlined,
                      size: 18,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_getStatusActionText(status)}: ${_formatDateTime(order['updated_at'])}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Methods ---

  String _formatStatus(String status) {
    if (status.isEmpty) return "Unknown";
    // Replace underscores and capitalize words
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      // Format as 'MMM dd, hh:mm a' (e.g., Aug 23, 02:30 PM)
      return dateTime.toString();
    } catch (e) {
      return dateTimeString; // Return original string if parsing fails
    }
  }

  String _getStatusActionText(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'failed_delivery':
        return 'Attempted';
      default:
        return 'Updated';
    }
  }

  StatusStyle _getStatusStyle(ThemeData theme, String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return StatusStyle(
          Icons.thumb_up_alt_outlined,
          Colors.blue.shade800,
          Colors.blue.shade50,
        );
      case 'ready_for_pickup':
        return StatusStyle(
          Icons.inventory_2_outlined,
          Colors.deepPurple.shade700,
          Colors.deepPurple.shade50,
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
      case 'failed_delivery':
        return StatusStyle(
          Icons.warning_amber_outlined,
          Colors.amber.shade800,
          Colors.amber.shade50,
        );
      default:
        return StatusStyle(
          Icons.help_outline,
          theme.colorScheme.onSurfaceVariant,
          theme.colorScheme.surfaceVariant,
        );
    }
  }
}

// Helper class for status styling
class StatusStyle {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  StatusStyle(this.icon, this.color, this.backgroundColor);
}
