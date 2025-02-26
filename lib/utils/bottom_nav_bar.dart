import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  // final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    this.scaffoldKey,
    // required this.onItemTapped,
  });

  final List<IconData> _outlinedIcons = const [
    Icons.home_outlined,
    Icons.shopping_bag_outlined,
    Icons.favorite_border,
    Icons.shopping_cart_outlined,
    Icons.person_outlined,
  ];

  final List<IconData> _filledIcons = const [
    Icons.home,
    Icons.shopping_bag,
    Icons.favorite,
    Icons.shopping_cart,
    Icons.person,
  ];

  final List<String> _routes = const [
    "/home",
    "/orders",
    "/favorites",
    "/cart",
    "/account", // This is just a placeholder
  ];

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return; // Avoid redundant navigation

    if (index == 4) {
      // Open the drawer instead of navigating
      scaffoldKey?.currentState?.openDrawer();
    } else if (index == 0) {
      // Use pushReplacementNamed for index 1 (replace current screen)
      Navigator.pushNamedAndRemoveUntil(
        context,
        _routes[index],
        (route) => false,
      );
    } else {
      // Use pushNamed for all other indices (allow back navigation)
      Navigator.pushNamed(context, _routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: Colors.brown,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: List.generate(5, (index) {
        return BottomNavigationBarItem(
          icon: Icon(
            selectedIndex == index
                ? _filledIcons[index]
                : _outlinedIcons[index],
          ),
          label: ["Home", "My Orders", "Favorites", "Cart", "Account"][index],
        );
      }),
    );
  }
}
