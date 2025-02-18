import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _gender = 'Male'; // Default gender
  final List<String> _genderOptions = ['Male', 'Female', 'Others'];

  String? _profileImagePath;
  File? _imageFile;
  bool _isEmailEditable = false; // Make email non-editable permanently

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _user = _auth.currentUser;

    if (_user != null) {
      // Load the name, email, and additional fields from Firestore
      _nameController.text = _user!.displayName ?? '';
      _emailController.text = _user!.email ?? '';

      // Fetch user details from Firestore
      DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        _ageController.text = data['age'] ?? '';
        _heightController.text = data['height'] ?? '';
        _weightController.text = data['weight'] ?? '';
        _gender = data['gender'] ?? 'Male'; // Set gender from Firestore data
      }

      // Optionally load the profile image path from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _profileImagePath = prefs.getString('profile_image');
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _profileImagePath = pickedFile.path;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', pickedFile.path);
    }
  }

  Future<void> _updateProfile() async {
    try {
      if (_user != null) {
        // Update display name in Firebase Authentication
        await _user!.updateDisplayName(_nameController.text);
        await _user!.reload();
        _user = _auth.currentUser;

        // Save profile data to Firestore
        await _firestore.collection('users').doc(_user!.uid).set({
          'name': _nameController.text,
          'age': _ageController.text,
          'height': _heightController.text,
          'weight': _weightController.text,
          'gender': _gender,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated successfully!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: SingleChildScrollView(  // Wrap the body with SingleChildScrollView
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImagePath != null
                      ? FileImage(File(_profileImagePath!))
                      : null,  // No default image, shows nothing if no image
                  child: _profileImagePath == null
                      ? Icon(Icons.camera_alt, size: 30, color: Colors.grey)  // Icon shows if no image
                      : null,
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                SizedBox(width: 80, child: Text("Name", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Expanded(child: TextField(controller: _nameController)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                SizedBox(width: 80, child: Text("Email", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    enabled: _isEmailEditable, // Email is permanently non-editable
                    readOnly: true,  // Disable any editing on the email field
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                SizedBox(width: 80, child: Text("Age", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,  // For integer input
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],  // Allows only digits
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                SizedBox(width: 80, child: Text("Height", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),  // For floating point input
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                SizedBox(width: 80, child: Text("Weight", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),  // For floating point input
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                SizedBox(width: 80, child: Text("Gender", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Expanded(
                  child: DropdownButton<String>(
                    value: _gender,
                    onChanged: (String? newValue) {
                      setState(() {
                        _gender = newValue!;
                      });
                    },
                    items: _genderOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _updateProfile,
                child: Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
