import 'dart:convert';
import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class IRImageScreen {
  String? savedImagePath;

  Future<void> fetchImageList() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.201.20:5000/list_images"));

      if (response.statusCode == 200) {
        // Decode JSON response
        Map<String, dynamic> data = json.decode(response.body);
        List<String> imageList = List<String>.from(data["images"]);

        print("--------------------------------------------Image List: $imageList"); // Debug output

      } else {
        print("Failed to fetch images: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching images: $e");
    }
  }

  Future<void> syncImages() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.201.20:5000/list_images"));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<String> imageList = List<String>.from(data["images"]);

        final directory = await getExternalStorageDirectory();
        String savedFolderPath = '${directory?.path}/CapturedImages';
        Directory(savedFolderPath).createSync(recursive: true);

        for (String imageName in imageList) {
          String filePath = '$savedFolderPath/$imageName';

          // Check if the image is already saved
          if (!File(filePath).existsSync()) {
            print("Downloading $imageName...");
            await downloadImage(imageName, filePath);
          } else {
            print("$imageName already exists, skipping...");
          }
        }
      } else {
        print("Failed to fetch image list: ${response.statusCode}");
      }
    } catch (e) {
      print("Error syncing images: $e");
    }
  }

  // Function to fetch image from Flask server
  Future<void> downloadImage(String imageName, String filePath) async {
    try {
      final response = await http.get(Uri.parse("http://192.168.201.20:5000/get_image/$imageName"));

      if (response.statusCode == 200) {
        File imageFile = File(filePath);
        await imageFile.writeAsBytes(response.bodyBytes);
        print("Saved: $filePath");
      } else {
        print("Failed to download $imageName: ${response.statusCode}");
      }
    } catch (e) {
      print("Error downloading image: $e");
    }
  }
}
