import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage
import 'package:the_cakery/utils/constants.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String? _profilePicture;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    setState(() {
      _userName = Constants.prefs.getString('userName') ?? "-";
      _userEmail = Constants.prefs.getString('userEmail') ?? "-";
      _profilePicture = Constants.prefs.getString('userImage');
    });
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: <Widget>[
            // Use <Widget> for clarity
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Constants.prefs.remove('token');
                await Constants.prefs.remove('userSlug');
                await Constants.prefs.remove('userName');
                await Constants.prefs.remove('userEmail');
                await Constants.prefs.remove('userImage');
                await Constants.prefs.setBool("isLoggedIn", false);

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/login",
                  (route) => false,
                );
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          // Use <Widget> for clarity
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              // Add decoration for header background
              color:
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer, // Use primaryContainer for a softer background
            ),
            accountName: Text(
              _userName,
              style: TextStyle(
                fontWeight: FontWeight.bold, // Make username bolder
                color:
                    Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer, // Ensure text color is accessible
              ),
            ),
            accountEmail: Text(
              _userEmail,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer
                    .withOpacity(0.8), // Slightly less opaque email
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor:
                  Theme.of(context)
                      .colorScheme
                      .surfaceVariant, // Use surfaceVariant for a subtle background
              foregroundImage:
                  _profilePicture != null && _profilePicture!.isNotEmpty
                      ? CachedNetworkImageProvider(
                        // Use CachedNetworkImageProvider for better caching
                        _profilePicture!,
                      )
                      : null, // foregroundImage handles background color better than backgroundImage
              child:
                  _profilePicture == null || _profilePicture!.isEmpty
                      ? Icon(
                        Icons.person,
                        size: 50,
                        color:
                            Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant, // Use onSurfaceVariant for icon color
                      )
                      : null,
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.edit,
              color: Theme.of(context).iconTheme.color,
            ), // Use theme icon color
            title: Text(
              "Edit Profile",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ), // Use theme text color
            shape: LinearBorder.end(
              side: BorderSide(
                color: Colors.grey.shade300,
                width: 0.8,
              ), // Slightly thinner border
            ),
            onTap: () {
              Navigator.pushNamed(context, "/editprofile");
            },
          ),
          ..._buildAdminMenu(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).iconTheme.color,
            ), // Use theme icon color
            title: Text(
              "Logout",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ), // Use theme text color
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.grey.shade300,
                width: 0.8,
              ), // Slightly thinner border
              borderRadius: BorderRadius.zero,
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAdminMenu() {
    final role = Constants.prefs.getString('role');
    TextStyle listTileTextStyle = TextStyle(
      color: Theme.of(context).textTheme.bodyLarge?.color,
    ); // Define text style once
    Color listTileIconColor =
        Theme.of(context).iconTheme.color!; // Define icon color once
    BorderSide listTileBorderSide = BorderSide(
      color: Colors.grey.shade300,
      width: 0.8,
    ); // Define border side once

    if (role == 'admin') {
      return [
        ListTile(
          leading: Icon(
            Icons.add_box_rounded,
            color: listTileIconColor,
          ), // More relevant icon
          title: Text(
            "Add Cakes",
            style: listTileTextStyle,
          ), // More descriptive text
          shape: RoundedRectangleBorder(
            side: listTileBorderSide,
            borderRadius: BorderRadius.zero,
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              "/add_cakes",
            ); // Consider renaming route to "/manage_cakes"
          },
        ),
      ];
    }
    if (role == 'user') {
      return [
        ListTile(
          leading: Icon(
            Icons.cake_rounded,
            color: listTileIconColor,
          ), // More relevant icon
          title: Text("Create Your Cake", style: listTileTextStyle),
          shape: RoundedRectangleBorder(
            side: listTileBorderSide,
            borderRadius: BorderRadius.zero,
          ),
          onTap: () {
            Navigator.pushNamed(context, "/create_cakes");
          },
        ),
      ];
    }
    if (role == 'delivery_person') {
      return [
        ListTile(
          leading: Icon(
            Icons.delivery_dining_rounded,
            color: listTileIconColor,
          ), // More relevant icon
          title: Text(
            "Delivery Orders",
            style: listTileTextStyle,
          ), // More descriptive text
          shape: RoundedRectangleBorder(
            side: listTileBorderSide,
            borderRadius: BorderRadius.zero,
          ),
          onTap: () {
            Navigator.pushNamed(context, "/orders");
          },
        ),
      ];
    }
    return [];
  }
}
