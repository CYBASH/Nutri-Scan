import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'licenses_page.dart'; // Import the custom Licenses Page

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text('Dark Mode'),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            subtitle: Text('Manage notification settings'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Account'),
            subtitle: Text('Manage your account settings'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            subtitle: Text('App version and details'),
            onTap: () {
              _showCustomAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showCustomAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Nutri Scan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Version 1.0.0"),
              SizedBox(height: 5),
              Text("© 2025 CYBASH"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LicensesPage()),
                );
              },
              child: Text('View Licenses'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
