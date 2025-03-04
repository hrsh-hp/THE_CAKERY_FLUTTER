import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:the_cakery/Screens/accounts_screen.dart';
import 'package:the_cakery/Screens/cake_custom.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart';
import 'package:the_cakery/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> cakes = [];
  bool isLoading = true;
  bool hasError = false; // to handle API errors

  @override
  void initState() {
    super.initState();
    fetchCakes();
  }

  Future<void> fetchCakes() async {
    String token = Constants.prefs.getString("token") ?? "";
    try {
      final response = await http.get(
        Uri.parse("${Constants.baseUrl}/cake/home_cake"),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        setState(() {
          cakes = data.cast<Map<String, dynamic>>(); // Convert to List<Map>
          isLoading = false;
          print("cakes $cakes");
        });
      } else {
        throw Exception("Failed to load cakes");
      }
    } catch (e) {
      setState(() {
        hasError = true;
        print("error here $e");
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const AccountsScreen(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              "https://img.freepik.com/free-photo/top-view-delicious-cake-arrangement_23-2148933608.jpg",
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                "CLASSIC CAKES",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "MENU",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // ScrollAction.getDirectionalIncrement(ScrollableState., intent)
                    },
                    child: Text(
                      "View all",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child:
                  isLoading
                      ? _buildLoadingShimmer() // Show Skeleton while loading
                      : hasError
                      ? Center(
                        child: Text("Failed to load data. Please try again."),
                      )
                      : _buildCakeGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: 4, // Show 4 shimmer items
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
          child: Column(
            children: [
              Container(
                height: 120,
                color: Colors.grey[300],
              ), // Image placeholder
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      color: Colors.grey[300],
                    ), // Name
                    const SizedBox(height: 5),
                    Container(
                      height: 14,
                      width: 50,
                      color: Colors.grey[300],
                    ), // Price
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCakeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: cakes.length,
      itemBuilder: (context, index) {
        return _buildCakeItem(context, cakes[index]);
      },
    );
  }

  Widget _buildCakeItem(BuildContext context, Map<String, dynamic> cake) {
    return GestureDetector(
      onTap: () async {
        try {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CakeCustomScreen(slug: cake["slug"]),
            ),
          );
          if (result != null) {
            fetchCakes();
          }
        } catch (e) {
          print("Navigation error: $e");
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: Image.network(
                cake["image_url"],
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cake["name"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          cake['liked']
                              ? const Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.red,
                              )
                              : const Icon(
                                Icons.favorite_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                          const SizedBox(width: 2),
                          Text("${cake["likes_count"]}"),
                        ],
                      ),
                      Text(
                        "₹${cake["price"]}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
