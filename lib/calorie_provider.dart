import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'local_variables.dart';
import 'meal_tracker.dart';

class CalorieProvider extends ChangeNotifier {
  double dailyGoal = 2150;
  double proteinGoal = 120, carbsGoal = 120, fatGoal = 80, fiberGoal = 104;
  double consumedProtein = 0.0, consumedCarbs = 0.0, consumedFat = 0.0, consumedFiber = 0.0;
  double consumedCalories = 0.0;
  double percent = 0.0;

  final MealService mealService = MealService();

  Future<void> fetchCalorieData() async {
    try {
      List<Map<String, dynamic>> fetchedMeals = await mealService.fetchMeals();

      double totalCalories = 0.0;
      double totalProtein = 0.0;
      double totalCarbs = 0.0;
      double totalFat = 0.0;
      double totalFiber = 0.0;

      for (var meal in fetchedMeals) {
        totalCalories += meal["calories"];
        totalProtein += meal["protein"];
        totalCarbs += meal["carbs"];
        totalFat += meal["fat"];
        totalFiber += meal["fiber"];
      }

      // Update state
      consumedProtein = totalProtein;
      consumedCarbs = totalCarbs;
      consumedFat = totalFat;
      consumedFiber = totalFiber;
      consumedCalories = totalCalories;
      percent = consumedCalories / dailyGoal;

      notifyListeners(); // Trigger UI update
    } catch (e) {
      print("Error fetching meals: $e");
    }
  }
}
