import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalorieProvider with ChangeNotifier {

  double dailyGoal = 2150.0;

  double _consumedCalories = 0.0;
  double _consumedProtein = 0.0;
  double _consumedCarbs = 0.0;
  double _consumedFat = 0.0;
  double _consumedFiber = 0.0;
  double _percent = 0.0;

  // Getters
  double get consumedCalories => _consumedCalories;
  double get consumedProtein => _consumedProtein;
  double get consumedCarbs => _consumedCarbs;
  double get consumedFat => _consumedFat;
  double get consumedFiber => _consumedFiber;
  double get percent => _percent;

  Future<void> fetchTodayCalorieData() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Get today's start and end timestamps
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('meals')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .get();

      double totalCalories = 0.0;
      double totalProtein = 0.0;
      double totalCarbs = 0.0;
      double totalFat = 0.0;
      double totalFiber = 0.0;

      for (var doc in querySnapshot.docs) {
        totalCalories += (doc['calories'] as num).toDouble();
        totalProtein += (doc['protein'] as num).toDouble();
        totalCarbs += (doc['carbs'] as num).toDouble();
        totalFat += (doc['fat'] as num).toDouble();
        totalFiber += (doc['fiber'] as num).toDouble();
      }

      _consumedCalories = totalCalories;
      _consumedProtein = totalProtein;
      _consumedCarbs = totalCarbs;
      _consumedFat = totalFat;
      _consumedFiber = totalFiber;
      _percent = _consumedCalories / dailyGoal;

      notifyListeners();
    } catch (e) {
      print("Error fetching today's calorie data: $e");
    }
  }

  // Reset all values to zero
  void resetValues() {
    _consumedCalories = 0.0;
    _consumedProtein = 0.0;
    _consumedCarbs = 0.0;
    _consumedFat = 0.0;
    _consumedFiber = 0.0;
    _percent = 0.0;
    notifyListeners();
  }
}