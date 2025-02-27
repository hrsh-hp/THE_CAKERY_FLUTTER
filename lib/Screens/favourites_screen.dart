import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/accounts_screen.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> favoriteCakes = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  void _fetchFavorites() {
    setState(() {
      favoriteCakes = [
        {
          "id": 1,
          "name": "Chocolate Cake",
          "imageUrl":
              "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_aHBROo9v_qSg_mhMLje2MX1az3HjbbOUQg&s",
          "isLiked": true,
        },
        {
          "id": 2,
          "name": "Vanilla Cake",
          "imageUrl":
              "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_aHBROo9v_qSg_mhMLje2MX1az3HjbbOUQg&s",
          "isLiked": true,
        },
        {
          "id": 3,
          "name": "Red Velvet Cake",
          "imageUrl":
              "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_aHBROo9v_qSg_mhMLje2MX1az3HjbbOUQg&s",
          "isLiked": true,
        },
      ];
    });
  }

  void _removeFromFavorites(int id) {
    int index = favoriteCakes.indexWhere((cake) => cake["id"] == id);

    setState(() {
      // favoriteCakes.removeWhere((cake) => cake["id"] == id);
      favoriteCakes[index]['isLiked'] = !favoriteCakes[index]['isLiked'];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            !favoriteCakes[index]['isLiked']
                ? Text("Removed from favorites")
                : Text("Added to favorites"),
      ),
    );
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
                favoriteCakes.isEmpty
                    ? Center(child: Text("No favorites yet!"))
                    : Padding(
                      padding: EdgeInsets.all(8),
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: favoriteCakes.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.9,
                        ),
                        itemBuilder: (context, index) {
                          final cake = favoriteCakes[index];
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(10),
                                  ),
                                  child: Image.network(
                                    cake["imageUrl"],
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          cake["name"],
                                          softWrap: true,
                                          maxLines: 2, // Allow up to 2 lines
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon:
                                            cake['isLiked']
                                                ? Icon(
                                                  Icons.favorite,
                                                  color: Colors.red,
                                                )
                                                : Icon(
                                                  Icons.favorite_outline,
                                                  color: Colors.red,
                                                ),
                                        onPressed:
                                            () => _removeFromFavorites(
                                              cake["id"],
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
