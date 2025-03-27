import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:url_launcher/url_launcher.dart';

class AdminOrderDetailScreen extends StatelessWidget {
  final String orderSlug;
  final Map<String, dynamic> orderDetails;

  const AdminOrderDetailScreen({
    Key? key,
    required this.orderSlug,
    required this.orderDetails,
  }) : super(key: key);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber.toString());
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryPerson = orderDetails["delivery_person"] ?? {};
    final List<dynamic> items = orderDetails["items"] ?? [];
    final payment = orderDetails["payment"] ?? {};
    final isDelivered =
        orderDetails["status"]?.toString().toLowerCase() == "delivered";
    final isPending =
        orderDetails["status"]?.toString().toLowerCase() == "confirmed";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Order #${orderSlug.split('_').first}",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color:
                  isPending
                      ? Colors.orange[50]
                      : (isDelivered ? Colors.green[50] : Colors.red[50]),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isPending
                        ? Icons.pending
                        : (isDelivered ? Icons.check_circle : Icons.cancel),
                    color:
                        isPending
                            ? Colors.orange[700]
                            : (isDelivered
                                ? Colors.green[700]
                                : Colors.red[700]),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (orderDetails["status"] ?? "").toUpperCase(),
                        style: TextStyle(
                          color:
                              isPending
                                  ? Colors.orange[700]
                                  : (isDelivered
                                      ? Colors.green[700]
                                      : Colors.red[700]),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Order placed on ${orderDetails["created_at"] ?? 'Unknown date'}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Customer Details"),
                  _buildInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderDetails["user"] ?? "Unknown Customer",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                orderDetails["del_address"] ??
                                    "No address provided",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Order Items"),
                  ...items.map((item) => _buildOrderItem(item)).toList(),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Payment Details"),
                  _buildInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Payment Method",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              (payment["payment_method"] ?? "").toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Payment Status",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    payment["is_paid"] == true
                                        ? Colors.green[50]
                                        : Colors.orange[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                payment["is_paid"] == true ? "PAID" : "PENDING",
                                style: TextStyle(
                                  color:
                                      payment["is_paid"] == true
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (payment["transaction_id"] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Transaction ID",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                payment["transaction_id"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Amount",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "₹${orderDetails["total_price"] ?? '0.00'}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (deliveryPerson.isNotEmpty) ...[
                    _buildSectionTitle("Delivery Partner"),
                    _buildInfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.brown[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delivery_dining,
                                  color: Colors.brown[300],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      deliveryPerson["name"] ?? "Unknown",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Vehicle: ${deliveryPerson["vehicle_number"] ?? "N/A"}",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    () => _makePhoneCall(
                                      deliveryPerson["phone"].toString(),
                                    ),
                                icon: const Icon(
                                  Icons.phone,
                                  color: Colors.brown,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                item["image_url"] != null
                    ? CachedNetworkImage(
                      imageUrl: item["image_url"],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.cake, color: Colors.grey[400]),
                          ),
                    )
                    : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: Icon(Icons.cake, color: Colors.grey[400]),
                    ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["cake_name"] ?? "Unknown Cake",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Size: ${item["size"] ?? "N/A"}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  "Quantity: ${item["quantity"] ?? 1}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if ((item["toppings"] as List?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Toppings: ${(item["toppings"] as List).join(", ")}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  "₹${item["cake_price"] ?? '0.00'}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
