import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:the_cakery/Screens/accounts_screen.dart';
import 'package:the_cakery/Screens/cake_custom.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart';
import 'package:the_cakery/utils/constants.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> favoriteCakes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  void _updateLikedStatus(String cakeSlug) {
    setState(() {
      int index = favoriteCakes.indexWhere((cake) => cake["slug"] == cakeSlug);
      if (index != -1) {
        favoriteCakes[index]["liked"] = !favoriteCakes[index]["liked"];
      }
    });
  }

  void _fetchFavorites() async {
    setState(() => isLoading = true); // Show loading skeleton
    try {
      var response = await http.get(
        Uri.parse("${Constants.baseUrl}/cake/liked_cake"),
        headers: {
          "Authorization": "Token ${Constants.prefs.getString("token")}",
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        setState(() {
          favoriteCakes = List<Map<String, dynamic>>.from(jsonData['data']);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch favorites");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> _toggleLike(String cakeSlug, bool isLiked) async {
    try {
      var response = await http.post(
        Uri.parse('${Constants.baseUrl}/cake/like/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${Constants.prefs.getString("token")}',
        },
        body: jsonEncode({'cake_slug': cakeSlug, 'liked': !isLiked}),
      );

      if (response.statusCode == 200) {
        setState(() {
          int index = favoriteCakes.indexWhere(
            (cake) => cake["slug"] == cakeSlug,
          );
          favoriteCakes[index]["liked"] = !isLiked;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                !isLiked
                    ? Text("Added to favorites")
                    : Text("Removed from favorites"),
            duration: Duration(milliseconds: 500),
          ),
        );
      } else {
        throw Exception("Failed to update like status");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const AccountsScreen(),
      body: Column(
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
              "Favourite Cakes",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child:
                isLoading
                    ? _buildSkeletonLoader() // Show skeleton while loading
                    : favoriteCakes.isEmpty
                    ? const Center(child: Text("No favorites yet!"))
                    : _buildCakeGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6, // Number of skeleton items
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
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
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Static grey color
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                ), // Image placeholder
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ), // Name placeholder
                      const SizedBox(height: 5),
                      Container(
                        height: 14,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ), // Price placeholder
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCakeGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: favoriteCakes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          final cake = favoriteCakes[index];
          return GestureDetector(
            onTap: () async {
              try {
                final Map<String, dynamic>? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CakeCustomScreen(slug: cake["slug"]),
                  ),
                );
                print("result $result");
                print("result ${cake['liked']}");
                if (result != null) {
                  final bool newLikedStatus = result["isLiked"];
                  final int newLikeCount = result["likes"];
                  print("newliked $newLikedStatus");
                  // Only update if there is a change in like status or like count
                  if (cake["liked"] != newLikedStatus) {
                    _updateLikedStatus(cake["slug"]);
                  }
                }
              } catch (e) {
                print("Navigation error: $e");
              }
            },

            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child: Image.network(
                      cake["image_url"],
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            cake["name"],
                            softWrap: true,
                            maxLines: 2,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon:
                              cake["liked"]
                                  ? Icon(Icons.favorite, color: Colors.red)
                                  : Icon(
                                    Icons.favorite_outline,
                                    color: Colors.red,
                                  ),
                          onPressed:
                              () => _toggleLike(cake["slug"], cake["liked"]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
