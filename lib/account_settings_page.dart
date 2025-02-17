import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountSettingsPage extends StatefulWidget {
  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _auth = FirebaseAuth.instance;
  User? _user;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _user = _auth.currentUser;
    if (_user != null) {
      _nameController.text = _user!.displayName ?? '';
    }
  }

  Future<void> _updateDisplayName() async {
    if (_user != null && _nameController.text.isNotEmpty) {
      await _user!.updateDisplayName(_nameController.text);
      await _user!.reload();
      setState(() {
        _user = _auth.currentUser;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Name updated successfully!")),
      );
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
          (route) => false, // Remove all previous routes
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account Settings')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${_user?.email ?? 'Not available'}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Display Name"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updateDisplayName,
              child: Text("Update Name"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                "Sign Out",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
