import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:the_cakery/Screens/accounts_screen.dart';
import 'package:the_cakery/Screens/cake_custom.dart';
import 'package:the_cakery/Screens/create_your_cake_screen.dart';
import 'package:the_cakery/Screens/edit_cake_screen.dart';
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
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchCakes();
  }

  void _updateLikedStatus(String slug, bool isLiked, int likeCount) {
    setState(() {
      final index = cakes.indexWhere((cake) => cake["slug"] == slug);
      if (index != -1) {
        cakes[index]["liked"] = isLiked;
        cakes[index]["likes_count"] = likeCount;
      }
    });
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
          cakes = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load cakes");
      }
    } catch (e) {
      setState(() {
        hasError = true;
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
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateYourCakeScreen()),
            );
          },
          backgroundColor: Colors.brown[200],
          label: Row(
            children: [
              Icon(Icons.cake, color: Colors.brown[900]),
              SizedBox(width: 8),
              Text(
                "Customize",
                style: TextStyle(
                  color: Colors.brown[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      drawer: const AccountsScreen(),
      body: RefreshIndicator(
        onRefresh: fetchCakes,
        child: SingleChildScrollView(
          primary: true,
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      "https://img.freepik.com/free-photo/top-view-delicious-cake-arrangement_23-2148933608.jpg",
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "The Cakery",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Handcrafted with love",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Featured Cakes",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[800],
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "View All",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.brown[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // SizedBox(height: 16),
                    isLoading
                        ? _buildLoadingShimmer()
                        : hasError
                        ? _buildErrorState()
                        : _buildCakeGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            "Oops! Something went wrong",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Pull to refresh and try again",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.75,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
      padding: EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.75,
      ),
      itemCount: cakes.length,
      itemBuilder: (context, index) {
        return _buildCakeItem(context, cakes[index]);
      },
    );
  }

  Widget _buildCakeItem(BuildContext context, Map<String, dynamic> cake) {
    cake['image_url'] =
        cake['image_url'] is String && (cake['image_url'] as String).isNotEmpty
            ? cake['image_url'] as String
            : null;
    return GestureDetector(
      onTap: () async {
        try {
          if (Constants.prefs.getString("role") == "admin") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditCakeScreen(slug: cake["slug"]),
              ),
            );
          } else {
            final Map<String, dynamic>? result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CakeCustomScreen(slug: cake["slug"]),
              ),
            );

            if (result != null) {
              final bool newLikedStatus = result["isLiked"];
              final int newLikeCount = result["likes"];

              if (cake["liked"] != newLikedStatus ||
                  cake["likes_count"] != newLikeCount) {
                _updateLikedStatus(cake["slug"], newLikedStatus, newLikeCount);
              }
            }
          }
        } catch (e) {
          print("Navigation error: $e");
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    // Use SizedBox to manage dimensions, width comes from parent context
                    height: 150,
                    width:
                        double.infinity, // Ensure the child tries to fill width
                    child:
                        cake['image_url'] != null
                            ? Image.network(
                              cake['image_url'],
                              height: 150,
                              width:
                                  double
                                      .infinity, // Needs width for BoxFit.cover to work correctly
                              fit: BoxFit.cover,
                              // --- Crucial Part: Error Handling ---
                              errorBuilder: (context, error, stackTrace) {
                                // On error, return the specific placeholder for this context
                                return _buildCakeImageErrorPlaceholder();
                              },
                              // Optional: Basic loading indicator (can be removed)
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null)
                                  return child; // Image loaded
                                // Simple grey box matching dimensions while loading
                                return Container(
                                  height: 150,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                );
                              },
                            )
                            : _buildCakeImageErrorPlaceholder(), // Show placeholder if URL is null/empty initially
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cake['liked']
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "${cake["likes_count"]}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 20, // Ensure it has a defined height
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Text(
                          cake["name"],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[800],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₹${cake["price"]}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.brown[600],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.brown[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.brown[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCakeImageErrorPlaceholder() {
  return Container(
    height: 150,
    width: double.infinity,
    color: Colors.grey[300], // Simple background
    child: Center(
      // Center the icon within the available space
      child: Icon(
        Icons.cake_outlined, // Your desired icon
        color: Colors.grey[600],
        size: 60, // Adjusted size for the larger height
      ),
    ),
  );
}
