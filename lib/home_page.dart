import 'package:flutter/material.dart';
import 'package:nutri_scan/settings.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'calorie_provider.dart';
import 'consts.dart';
import 'image_prompt_home_page.dart'; // Import Chatbot HomePage
import 'local_variables.dart';
import 'pdf_analyzer.dart'; // Import PDF Analyzer HomePage
import 'meal_tracker.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Import the ThemeProvider


class HomePage extends StatelessWidget {



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

  @override
  Widget build(BuildContext context) {

    final calorieProvider = Provider.of<CalorieProvider>(context);

    // Fetch data when HomePage builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      calorieProvider.fetchCalorieData();
    });


    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    double calories = Provider.of<CalorieProvider>(context).consumedCalories;
    double consumedProtein = Provider.of<CalorieProvider>(context).consumedProtein;
    double consumedCarbs = Provider.of<CalorieProvider>(context).consumedCarbs;
    double consumedFat = Provider.of<CalorieProvider>(context).consumedFat;
    double consumedFiber = Provider.of<CalorieProvider>(context).consumedFiber;
    double percent = Provider.of<CalorieProvider>(context).percent;



    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      drawer: MyDrawer(),
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
                      calorieText("Consumed: ", "${calories.toStringAsFixed(0)} cal"),
                      calorieText("Left: ", "${(dailyGoal - calories).toStringAsFixed(0)} cal"),
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
              // Text("Food Intake", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class MyDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Navigation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('Chatbot'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ImageScanHomePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('PDF Analyzer'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PDFAnalyzer()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Meal Tracker'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MealTrackerUI()),
              );
            },
          ),
          Divider(), // Add a divider before the settings option
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Navigate to settings page
              // Replace `SettingsPage()` with your actual settings page widget
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
