import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'home_page.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool _isChecked = false;
  bool _showPassword = false; // For toggling password visibility

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // Use AuthService

  Future<void> _authenticate() async {
    try {
      UserCredential userCredential;
      if (isLogin) {
        // Login User
        userCredential = await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Check if email is verified
        if (userCredential.user?.emailVerified ?? false) {
          // Navigate to HomePage if email is verified
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          // Ask the user to verify their email
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please verify your email first!')),
          );
        }
      } else {
        // Sign Up User
        if (!_isChecked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You must agree to the terms and conditions.')),
          );
          return; // Prevent sign up if the checkbox is not checked
        }

        userCredential = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Send email verification
        await userCredential.user?.sendEmailVerification();

        // Notify user to check email for verification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check your email for verification!')),
        );
      }
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again later.';

      if (e is FirebaseAuthException) {
        print("E code ----------------> " + e.code);
        // Handle specific Firebase errors
        if (e.code == 'invalid-credential') {
          errorMessage = 'Enter correct email or password.';
        } else if (e.code == 'channel-error') {
          errorMessage = 'The email address is not valid.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'The email address is already in use.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'The password is too weak.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is invalid.';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Sign Up / Log In',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Good to see you back!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: UnderlineInputBorder(),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _showPassword,
                  onChanged: (bool? value) {
                    setState(() {
                      _showPassword = value ?? false;
                    });
                  },
                ),
                Text('Show Password'),
              ],
            ),
            if (!isLogin)
              Row(
                children: [
                  Checkbox(
                    value: _isChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        _isChecked = value ?? false;
                      });
                    },
                  ),
                  Text('I agree to all the Terms & Conditions')
                ],
              ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _authenticate,
                child: Text(
                  isLogin ? 'Log in' : 'Sign Up',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(isLogin ? 'Create an Account' : 'Already have an account? Log In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
