import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/accounts_screen.dart';
import 'package:the_cakery/Screens/cake_custom.dart';
import 'package:the_cakery/utils/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCakeItem(BuildContext context, Map<String, dynamic> cake) {
    return GestureDetector(
      onTap: () async {
        // In the future, replace this with API call to getCakeDetails
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CakeCustomScreen(
                  cakeName: cake["name"],
                  imageUrl: cake["image"],
                  basePrice: cake["price"],
                  description: cake["description"],
                  initialLikes: cake["likes"],
                ),
          ),
        );
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
                cake["image"],
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite, size: 16, color: Colors.red),
                          SizedBox(width: 2),
                          Text("${cake["likes"]}"),
                        ],
                      ),
                      Text(
                        "₹${cake["price"].toStringAsFixed(2)}",
                        style: TextStyle(
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

// Static Data (Replace Later with API Call)
final List<Map<String, dynamic>> cakes = [
  {
    "name": "Chocolate Cake",
    "image":
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_aHBROo9v_qSg_mhMLje2MX1az3HjbbOUQg&s",
    "price": 799.0,
    "description": "A rich and creamy chocolate cake.",
    "likes": 99,
  },
  {
    "name": "Vanilla Delight",
    "image":
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRR2WykAyo-XM2T6eu3T8xM6yIlBygrzcfxAw&s",
    "price": 699.0,
    "description": "A soft vanilla cake with smooth frosting.",
    "likes": 85,
  },
  // More cakes can be added here
];
