import 'dart:typed_data';  // This is the correct import for Uint8List

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:intl/intl.dart';
import 'package:nutri_scan/consts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Import your theme provider
import 'meal_provider.dart';

class MealTrackerUI extends StatefulWidget {
  @override
  _MealTrackerUIState createState() => _MealTrackerUIState();
}


class _MealTrackerUIState extends State<MealTrackerUI> {


  final MealService mealService = MealService();

  List<Map<String, dynamic>> meals = []; // Store meals locally

  @override
  void initState() {
    super.initState();
    fetchMealsFromFirebase(); // Fetch meals when screen loads
  }

  Future<void> fetchMealsFromFirebase() async {
    try {
      List<Map<String, dynamic>> fetchedMeals = await mealService.fetchMeals();

      double totalCalories = 0.0;
      double totalProtein = 0.0;
      double totalCarbs = 0.0;
      double totalFat = 0.0;
      double totalFiber = 0.0;

      List<Map<String, dynamic>> updatedMeals = fetchedMeals.map((meal) {
        totalCalories += meal["calories"];
        totalProtein += meal["protein"];
        totalCarbs += meal["carbs"];
        totalFat += meal["fat"];
        totalFiber += meal["fiber"];

        return {
          "title": meal["mealName"] ?? "Food",
          "subtitle": "Calories: ${meal["calories"]} kcal",
          "calories": meal["calories"].toString(),
          "image": meal["imageUrl"] ?? "",
        };
      }).toList();

      setState(() {
        meals = updatedMeals;
        consumedCalories = totalCalories;
        percent = consumedCalories / dailyGoal;
        targetCalories = dailyGoal - consumedCalories;

        consumedProtein = totalProtein;
        consumedCarbs = totalCarbs;
        consumedFat = totalFat;
        consumedFiber = totalFiber;
      });
    } catch (e) {
      print("Error fetching meals: $e");
    }
  }


  final Gemini gemini = Gemini.instance;
  double dailyGoal = DailyGoal;
  double proteinGoal = 120, carbsGoal = 120, fatGoal = 80, fiberGoal = 104;
  double consumedProtein = 0.0, consumedCarbs = 0.0, consumedFat = 0.0, consumedFiber = 0.0;
  double consumedCalories = 0.0;
  double detectedCaloriesInDouble = 0.0;
  double detectedProteinsInDouble = 0.0;
  double detectedCarbsInDouble = 0.0;
  double detectedFatsInDouble = 0.0;
  double detectedFiberInDouble = 0.0;
  double targetCalories = 0.0;

  String detectedFood = "";
  String detectedCalories = "";
  String detectedProteins = "";
  String detectedCarbs = "";
  String detectedFats = "";
  String detectedFiber = "";

  double percent = 0.0;

  String _imagePath = "";

  String get _nutritionPrompt => """You are a professional nutritionist. Analyze the food items in the image and provide overall nutritional information. Follow these specific requirements:

        1. First identify all food items visible in the image
        2. Take an standard amount of weight like 1 serving of middle age human of food item.
     Display only guess numbers. provide the following nutritional values:

        Format your response exactly like this for each food item:

        Item: [food name]
        Calories: [number] kcal
        Protein: [number]g
        Carbs: [number]g
        Fat: [number]g
        Fiber: [number]g

        Important guidelines:
        - Use only numbers, no ranges
        - Do not include any explanations or additional text
        - Round all numbers to one decimal place
        - Base calculations on a standard 100g serving

        
        Remember to be precise and avoid any unnecessary text or explanations.
        Remember to give response in single line
        """;

  // void _pickImage() async {
  //   final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  //   if (pickedFile != null) {
  //     setState(() {
  //       _selectedImage = File(pickedFile.path);
  //       _sendMessage(_selectedImage!);
  //     });
  //   }
  // }

  void addNewMeal() async {
    try {
      await mealService.addMeal(
          detectedFood,
          detectedCaloriesInDouble,
          detectedProteinsInDouble,
          detectedCarbsInDouble,
          detectedFatsInDouble,
          detectedFiberInDouble,
          _imagePath
      );
      print("Meal added successfully!");
    } catch (e) {
      print("Error adding meal: $e");
    }
  }


  void _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      try {
        final bytes = await File(pickedFile.path).readAsBytes();
        setState(() {
          _imagePath = pickedFile.path;
        });
        _sendMessage(imageData: bytes);
      } catch (e) {
        print('Error reading image: $e');
      }
    } else {
      print("No image selected.");
    }
  }




  String _cleanResponse(String response) {
    // Normalize the response by removing extra spaces and newlines
    response = response.replaceAll(RegExp(r'\s*\n\s*'), '\n'); // Remove extra newlines

    // Fix misplaced colons using replaceAllMapped
    response = response.replaceAllMapped(RegExp(r'(\w+)\s*:\s*\n'), (match) {
      return '${match.group(1)}: '; // Correctly formats the misplaced colon
    });

    return response.trim();
  }



  // Parse the cleaned response into a structured format
  Map<String, String> _parseNutritionData(String response) {
    Map<String, String> nutritionData = {};
    List<String> lines = response.split('\n');

    for (String line in lines) {
      if (line.contains(':')) {
        List<String> parts = line.split(':');
        String key = parts[0].trim();
        String value = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

        if (key.isNotEmpty && value.isNotEmpty) {
          nutritionData[key] = value;

          // Assign values to respective variables
          if (key.toLowerCase() == "item") {
            detectedFood = value;
          } else if (key.toLowerCase() == "calories") {
            detectedCalories = value;
            String temp = value.toString();
            detectedCaloriesInDouble = double.parse(extractDouble(temp));
          } else if (key.toLowerCase() == "protein") {
            detectedProteins = value;
            String temp = value.toString();
            detectedProteinsInDouble = double.parse(extractDouble(temp));
          } else if (key.toLowerCase() == "carbs") {
            detectedCarbs = value;
            String temp = value.toString();
            detectedCarbsInDouble = double.parse(extractDouble(temp));
          } else if (key.toLowerCase() == "fat") {
            detectedFats = value;
            String temp = value.toString();
            detectedFatsInDouble = double.parse(extractDouble(temp));
          } else if (key.toLowerCase() == "fiber") {
            detectedFiber = value;
            String temp = value.toString();
            detectedFiberInDouble = double.parse(extractDouble(temp));
          }
        }
      }
    }

    // Debugging output
    print("Detected Food: $detectedFood");
    print("Detected Calories: $detectedCalories");
    print("Detected Proteins: $detectedProteins");
    print("Detected Carbs: $detectedCarbs");
    print("Detected Fats: $detectedFats");
    print("Detected Fiber: $detectedFiber");

    calculateNutrients();
    // _addMeal("Food", detectedFood, detectedCalories, _selectedImage);
    addNewMeal();
    _addMeal("Food", detectedFood, detectedCalories, _imagePath);

    return nutritionData;
  }

  String extractDouble(String input) {
    RegExp regex = RegExp(r'[-+]?\d*\.?\d+'); // Matches integers & decimals
    Match? match = regex.firstMatch(input);
    return match?.group(0) ?? "0.0"; // Returns the number or "0.0" if not found
  }


  // Create widgets from parsed nutrition data
  Widget _createNutritionCard(Map<String, String> data, bool isTotal) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isTotal ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: entry.key == 'Item' || isTotal
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                Text(
                  entry.value,
                  style: TextStyle(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showNutritionDialog(BuildContext context, String response) {
    String cleanedResponse = _cleanResponse(response);
    Map<String, String> nutritionData = _parseNutritionData(cleanedResponse);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nutrition Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ...nutritionData.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(entry.value),
                      ],
                    ),
                  );
                }).toList(),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  // Modified _sendMessage method
  void _sendMessage({List<int>? imageData}) async {
    try {
      final images = imageData != null ? [Uint8List.fromList(imageData)] : null;
      String fullResponse = '';

      await for (final event in gemini.streamGenerateContent(
        _nutritionPrompt,
        images: images,
      )) {
        String response = event.content?.parts
            ?.fold("", (previous, current) => "$previous${current.text ?? ''}")
            .trim() ?? "";

        if (response.isNotEmpty) {
          // print(response);
          fullResponse +=  response;
        }
      }

      if (fullResponse.isNotEmpty) {

        fullResponse = formatNutritionResponse(fullResponse);
        _showNutritionDialog(context, fullResponse);
        print(fullResponse);
        print("------------------------------");
      }
    } catch (e) {
      print('Error in Gemini API call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to analyze image: ${e.toString()}')),
      );
    }
  }

  String formatNutritionResponse(String response) {
    // Normalize response by adding newlines between different fields
    response = response.replaceAllMapped(
      RegExp(r'(Calories:\s*\d+\.?\d*\s*kcal)(Protein:\s*\d+\.?\d*g)?'),
          (match) =>
      '${match.group(1)}\n${match.group(2) ?? ''}', // Ensure newline after Calories
    );

    response = response.replaceAllMapped(
      RegExp(r'(Protein:\s*\d+\.?\d*g)(Carbs:\s*\d+\.?\d*g)?'),
          (match) =>
      '${match.group(1)}\n${match.group(2) ?? ''}', // Ensure newline after Protein
    );

    response = response.replaceAllMapped(
      RegExp(r'(Carbs:\s*\d+\.?\d*g)(Fat:\s*\d+\.?\d*g)?'),
          (match) => '${match.group(1)}\n${match.group(2) ?? ''}', // Newline after Carbs
    );

    response = response.replaceAllMapped(
      RegExp(r'(Fat:\s*\d+\.?\d*g)(Fiber:\s*\d+\.?\d*g)?'),
          (match) => '${match.group(1)}\n${match.group(2) ?? ''}', // Newline after Fat
    );

    return response.trim(); // Ensure no trailing spaces or newlines
  }




  // void _addMeal(String title, String subtitle, String calories, File? image) {
  void _addMeal(String title, String subtitle, String calories, String image) {
    setState(() {
      meals.add({"title": title, "subtitle": subtitle, "calories": calories, "image": image});
    });
  }

  void calculateNutrients() {
    consumedCalories += detectedCaloriesInDouble;
    percent = consumedCalories / dailyGoal;
    targetCalories = dailyGoal - consumedCalories;

    consumedProtein = consumedProtein + (detectedProteinsInDouble * 4);
    consumedCarbs = consumedCarbs + (detectedCarbsInDouble * 4);
    consumedFat = consumedFat + (detectedFatsInDouble * 9);
    consumedFiber = consumedFiber + (detectedFiberInDouble * 2);
  }



  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEE d').format(now);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(formattedDate.split(' ')[0], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                SizedBox(width: 4),
                Text(formattedDate.split(' ')[1], style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
              ],
            ),
            IconButton(
              icon: Icon(Icons.calendar_today, color: isDarkMode ? Colors.white : Colors.black),
              onPressed: () {
                showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                ).then((selectedDate) {
                  if (selectedDate != null) {
                    print("Selected Date: ${DateFormat('EEE d').format(selectedDate)}");
                  }
                });
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Calorie Goal", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                children: [
                  CircularPercentIndicator(
                    radius: 60.0,
                    lineWidth: 10.0,
                    percent: percent,
                    center: Text("${(percent * 100).toStringAsFixed(1)}%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    progressColor: isDarkMode ? Colors.lightBlueAccent : Colors.blue[1000],
                    backgroundColor: isDarkMode ? Colors.white : Colors.black,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      calorieText("Daily Goal: ", "${dailyGoal.toStringAsFixed(0)} cal"),
                      calorieText("Consumed: ", "${consumedCalories.toStringAsFixed(0)} cal"),
                      calorieText("Left: ", "${(dailyGoal - consumedCalories).toStringAsFixed(0)} cal"),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  nutrientInfo("Protein", "${consumedProtein.toStringAsFixed(0)}/${proteinGoal.toStringAsFixed(0)} g"),
                  nutrientInfo("Carbs", "${consumedCarbs.toStringAsFixed(0)}/${carbsGoal.toStringAsFixed(0)} g"),
                  nutrientInfo("Fat", "${consumedFat.toStringAsFixed(0)}/${fatGoal.toStringAsFixed(0)} g"),
                  nutrientInfo("Fiber", "${consumedFiber.toStringAsFixed(0)}/${fiberGoal.toStringAsFixed(0)} g"),
                ],
              ),
              Divider(color: Colors.grey.shade800, thickness: 1),
              SizedBox(height: 20),
              Text("Food Intake", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              mealCard("Add Food", Icons.add, null, null, _pickImage),
              ...meals.map((meal) => mealCard(meal["title"]!, null, meal["subtitle"], meal["calories"], null, meal["image"])).toList(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // body: SingleChildScrollView(
      //   child: Padding(
      //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      //     child: Column(
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: [
      //         Text("Calorie Goal", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      //         SizedBox(height: 10),
      //         Row(
      //           children: [
      //             CircularPercentIndicator(
      //               radius: 60.0,
      //               lineWidth: 10.0,
      //               percent: percent,
      //               center: Text("${(percent * 100).toStringAsFixed(1)}%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      //               progressColor: isDarkMode ? Colors.lightBlueAccent : Colors.blue[1000],
      //               backgroundColor: isDarkMode ? Colors.white : Colors.black,
      //               circularStrokeCap: CircularStrokeCap.round,
      //             ),
      //             SizedBox(width: 20),
      //             Column(
      //               crossAxisAlignment: CrossAxisAlignment.start,
      //               children: [
      //                 calorieText("Daily Goal: ", "${dailyGoal.toStringAsFixed(0)} cal"),
      //                 calorieText("Consumed: ", "${consumedCalories.toStringAsFixed(0)} cal"),
      //                 calorieText("Left: ", "${(dailyGoal - consumedCalories).toStringAsFixed(0)} cal"),
      //               ],
      //             ),
      //           ],
      //         ),
      //         SizedBox(height: 20),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: [
      //             nutrientInfo("Protein", "${consumedProtein.toStringAsFixed(0)}/${proteinGoal.toStringAsFixed(0)} g"),
      //             nutrientInfo("Carbs", "${consumedCarbs.toStringAsFixed(0)}/${carbsGoal.toStringAsFixed(0)} g"),
      //             nutrientInfo("Fat", "${consumedFat.toStringAsFixed(0)}/${fatGoal.toStringAsFixed(0)} g"),
      //             nutrientInfo("Fiber", "${consumedFiber.toStringAsFixed(0)}/${fiberGoal.toStringAsFixed(0)} g"),
      //           ],
      //         ),
      //         Divider(color: Colors.grey.shade800, thickness: 1),
      //         SizedBox(height: 20),
      //         Text("Food Intake", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      //         SizedBox(height: 10),
      //         mealCard("Add Food", Icons.add, null, null, _pickImage),
      //         ...meals.map((meal) => mealCard(meal["title"]!, null, meal["subtitle"], meal["calories"], null, meal["image"])).toList(),
      //         SizedBox(height: 20),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }

  Widget calorieText(String title, String value) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget nutrientInfo(String name, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  // Widget mealCard(String title, IconData? icon, String? subtitle, String? calories, VoidCallback? onTap, [String? imagePath]) {
  //   return Container(
  //     margin: EdgeInsets.symmetric(vertical: 8),
  //     child: ListTile(
  //       leading: imagePath != null && imagePath.isNotEmpty ? Image.file(File(imagePath), width: 40, height: 40, fit: BoxFit.cover) : (icon != null ? Icon(icon, color: Colors.grey) : null),
  //       title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //       subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey.shade900)) : null,
  //       trailing: calories != null ? Text(calories, style: TextStyle(fontWeight: FontWeight.bold)) : null,
  //       onTap: onTap,
  //     ),
  //   );
  // }

  Widget mealCard(
      String title,
      IconData? icon,
      String? subtitle,
      String? calories,
      VoidCallback? onTap,
      [String? imagePath]
      ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: imagePath != null && File(imagePath).existsSync()
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(imagePath),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.broken_image, color: Colors.grey),
          ),
        )
            : (icon != null
            ? Icon(icon, color: Colors.grey, size: 40)
            : Image.asset('assets/splash_screen/logo_nutriscan.png', width: 50, height: 50, fit: BoxFit.cover)), // Default placeholder
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(/*color: Colors.grey.shade900*/)) : null,
        trailing: calories != null ? Text(calories, style: TextStyle(fontWeight: FontWeight.bold)) : null,
        onTap: onTap,
      ),
    );
  }


}

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addMeal(
      String mealName,
      double calories,
      double protein,
      double carbs,
      double fat,
      double fiber,
      String imageUrl) async {

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in");
    }

    DocumentReference mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc();

    await mealRef.set({
      'mealId': mealRef.id,
      'mealName': mealName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }


  Future<List<Map<String, dynamic>>> fetchMeals() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in");
    }

    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'mealId': doc.id,
        'mealName': doc['mealName'] ?? 'Unknown',
        'calories': (doc['calories'] as num?)?.toDouble() ?? 0.0,
        'protein': (doc['protein'] as num?)?.toDouble() ?? 0.0,
        'carbs': (doc['carbs'] as num?)?.toDouble() ?? 0.0,
        'fat': (doc['fat'] as num?)?.toDouble() ?? 0.0,
        'fiber': (doc['fiber'] as num?)?.toDouble() ?? 0.0,
        'imageUrl': doc['imageUrl'] ?? '',
      };
    }).toList();
  }





}





