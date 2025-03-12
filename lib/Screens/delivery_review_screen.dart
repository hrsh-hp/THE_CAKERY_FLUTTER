import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:the_cakery/utils/constants.dart';

class DeliveryReviewScreen extends StatefulWidget {
  final String orderSlug;
  final String deliveryPerson;
  final String? vehicleNumber;
  final int? phoneNumber;
  final String deliveryPersonSlug;
  final bool isReviewed;

  const DeliveryReviewScreen({
    super.key,
    required this.orderSlug,
    required this.deliveryPerson,
    this.vehicleNumber,
    this.phoneNumber,
    required this.deliveryPersonSlug,
    required this.isReviewed,
  });

  @override
  _DeliveryReviewScreenState createState() => _DeliveryReviewScreenState();
}

class _DeliveryReviewScreenState extends State<DeliveryReviewScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  double _rating = 0;
  bool isSubmitting = false;
  bool isLoading = true;
  List<String> selectedTags = [];
  Map<String, dynamic>? reviewDetails;

  final List<String> tags = [
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
    if (widget.isReviewed) {
      _fetchReviewDetails();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchReviewDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Constants.baseUrl}/cake/orders/review/${widget.orderSlug}',
        ),
        headers: {
          "Authorization": "Token ${Constants.prefs.getString("token")}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)["data"];
        setState(() {
          reviewDetails = data;
          _rating = data["rating"].toDouble();
          selectedTags = List<String>.from(data["tags"]);
          _feedbackController.text = data["feedback"] ?? "";
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch review details");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load review details"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _toggleTag(String tag) {
    if (!widget.isReviewed) {
      setState(() {
        if (selectedTags.contains(tag)) {
          selectedTags.remove(tag);
        } else {
          selectedTags.add(tag);
        }
      });
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a rating"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/cake/orders/review/'),
        headers: {
          "Authorization": "Token ${Constants.prefs.getString("token")}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "order_slug": widget.orderSlug,
          "delivery_person_slug": widget.deliveryPersonSlug,
          "rating": _rating,
          "feedback": _feedbackController.text.trim(),
          "tags": selectedTags,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Thank you for your feedback!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception("Failed to submit review");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit review. Please try again."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReviewed ? "Review Details" : "Delivery Review",
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
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                ),
              )
              : SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDeliveryPersonSection(),
                      SizedBox(height: 24),
                      _buildRatingSection(),
                      SizedBox(height: 24),
                      _buildTagsSection(),
                      SizedBox(height: 24),
                      _buildFeedbackSection(),
                      if (!widget.isReviewed) ...[
                        SizedBox(height: 32),
                        _buildSubmitButton(),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildDeliveryPersonSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.brown[100],
                child: Icon(Icons.person, size: 36, color: Colors.brown[800]),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delivery Partner",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.deliveryPerson,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.vehicleNumber != null || widget.phoneNumber != null) ...[
            SizedBox(height: 10),
            Divider(),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.vehicleNumber != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          widget.vehicleNumber!,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.phoneNumber != null)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          widget.phoneNumber!.toString(),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isReviewed ? "Rating" : "Rate your experience",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap:
                  widget.isReviewed
                      ? null
                      : () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  size: 36,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isReviewed ? "Feedback Tags" : "What went well?",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              tags.map((tag) {
                final isSelected = selectedTags.contains(tag);
                return GestureDetector(
                  onTap: widget.isReviewed ? null : () => _toggleTag(tag),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.brown : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.brown : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isReviewed ? "Your Feedback" : "Additional Feedback",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        widget.isReviewed
            ? Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _feedbackController.text.isEmpty
                    ? "No additional feedback provided"
                    : _feedbackController.text,
                style: TextStyle(fontSize: 15, color: Colors.grey[800]),
              ),
            )
            : TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Share your experience...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.brown),
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
        onPressed: isSubmitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child:
            isSubmitting
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
                  "Submit Review",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }
}
