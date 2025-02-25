import 'package:flutter/material.dart';
import 'package:the_cakery/Screens/login.dart';
import 'package:the_cakery/utils/constants.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  String _userName = "Loading...";
  String _userEmail = "Loading...";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    setState(() {
      _userName = Constants.prefs.getString('userName') ?? "-";
      _userEmail = Constants.prefs.getString('userEmail') ?? "-";
    });
  }

  void _logout(context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
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
                await Constants.prefs.remove('slug');

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
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_userName),
            accountEmail: Text(_userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
              child: const Icon(Icons.person, size: 50, color: Colors.brown),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit Profile"),
            shape: LinearBorder.end(
              side: BorderSide(color: Colors.grey.shade300, width: 1),
              // borderRadius: BorderRadius.zero,
            ),
            onTap: () {
              // Navigator.pop(context); // Close drawer
              // Navigate to edit profile screen (if required)
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300, width: 1),
              borderRadius: BorderRadius.zero,
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
