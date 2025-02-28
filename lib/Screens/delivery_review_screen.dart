import 'package:flutter/material.dart';

class DeliveryReviewScreen extends StatefulWidget {
  final String deliveryPerson = "Heinrich Klaasen ";

  DeliveryReviewScreen();

  @override
  _DeliveryReviewScreenState createState() => _DeliveryReviewScreenState();
}

class _DeliveryReviewScreenState extends State<DeliveryReviewScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  List<String> selectedTags = [];
  final List<String> tags = [
    "Fast Delivery",
    "Polite",
    "Needs Improvement",
    "On Time",
    "Great Service",
  ];

  void _toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
  }

  void _submitReview() {
    // Handle review submission
    print("Feedback: ${_feedbackController.text}");
    print("Selected Tags: $selectedTags");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Thanks for your feedback!")));
    // Add API call logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text("Delivery Review")),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Delivery Person: ${widget.deliveryPerson}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text("Leave Your Feedback Here:"),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Write your feedback...",
                ),
              ),
              SizedBox(height: 16),
              Text("Select Tags:"),
              Wrap(
                spacing: 8.0,
                children:
                    tags
                        .map(
                          (tag) => ChoiceChip(
                            label: Text(tag),
                            selected: selectedTags.contains(tag),
                            onSelected: (_) => _toggleTag(tag),
                          ),
                        )
                        .toList(),
              ),
              // Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _submitReview,
                  child: Text(
                    "Submit",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
