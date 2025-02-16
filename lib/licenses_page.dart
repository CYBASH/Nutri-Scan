import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class LicensesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Third-Party Licenses'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Nutri Scan - Third-Party Licenses",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text("Version: 1.0.0", textAlign: TextAlign.center),
            Text("© 2025 CYBASH", textAlign: TextAlign.center),
            Divider(),
            _buildLicenseTile("flutter_gemini_bot", "MIT", "https://pub.dev/packages/flutter_gemini_bot"),
            _buildLicenseTile("file_picker", "MIT", "https://pub.dev/packages/file_picker"),
            _buildLicenseTile("provider", "MIT", "https://pub.dev/packages/provider"),
            _buildLicenseTile("pdf", "Apache-2.0", "https://pub.dev/packages/pdf"),
            _buildLicenseTile("dart_openai", "MIT", "https://pub.dev/packages/dart_openai"),
            _buildLicenseTile("http", "BSD-3-Clause", "https://pub.dev/packages/http"),
            _buildLicenseTile("syncfusion_flutter_pdf", "Syncfusion Community License", "https://pub.dev/packages/syncfusion_flutter_pdf"),
            _buildLicenseTile("flutter_spinkit", "MIT", "https://pub.dev/packages/flutter_spinkit"),
            _buildLicenseTile("flutter_gemini", "MIT", "https://pub.dev/packages/flutter_gemini"),
            _buildLicenseTile("image_picker", "MIT", "https://pub.dev/packages/image_picker"),
            _buildLicenseTile("dash_chat_2", "MIT", "https://pub.dev/packages/dash_chat_2"),
            _buildLicenseTile("pdf_gemini", "MIT", "https://pub.dev/packages/pdf_gemini"),
            _buildLicenseTile("percent_indicator", "MIT", "https://pub.dev/packages/percent_indicator"),
            _buildLicenseTile("google_fonts", "Apache-2.0", "https://pub.dev/packages/google_fonts"),
            _buildLicenseTile("shared_preferences", "BSD-3-Clause", "https://pub.dev/packages/shared_preferences"),
            _buildLicenseTile("firebase_core", "Apache-2.0", "https://pub.dev/packages/firebase_core"),
            _buildLicenseTile("cloud_firestore", "Apache-2.0", "https://pub.dev/packages/cloud_firestore"),
            _buildLicenseTile("flutter_riverpod", "MIT", "https://pub.dev/packages/flutter_riverpod"),
            _buildLicenseTile("firebase_auth", "Apache-2.0", "https://pub.dev/packages/firebase_auth"),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseTile(String package, String license, String url) {
    return ListTile(
      title: Text(package, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("License: $license"),
      trailing: Icon(Icons.open_in_new),
      onTap: () => _openLicenseUrl(url),
    );
  }

  Future<void> _openLicenseUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
