import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CalorieProvider with ChangeNotifier {
  double dailyGoal = 0.0;

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

  // Fetch today's calorie data
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

  Future<void> fetchDailyGoalForDate(DateTime selectedDate) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Format the selected date as YYYY-MM-DD (to match Firestore document ID)
      // String formattedDate =
      //     "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      String formattedDate = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
      // Reference the specific day's goal in Firestore
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('DailyGoals')
          .doc(formattedDate)
          .get();

      if (docSnapshot.exists) {
        Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('dailyGoal')) {
            dailyGoal = (data['dailyGoal'] as num).toDouble();
        }
      } else {
        print("No daily goal found for $formattedDate.");
        // You can optionally reset the dailyGoal to a default value if none is found
      }
    } catch (e) {
      print("Error fetching daily goal for date: $e");
    }
  }

  // Setter for setting the daily goal and saving it in Firestore
  Future<void> setDailyGoal(double newGoal) async {
    dailyGoal = newGoal;

    // Store the new daily goal in Firestore
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      DateTime now = DateTime.now();
      String formattedDate = "${now.year}-${now.month}-${now.day}";
      if (userId != null) {
        DocumentReference daily_goal = _firestore
            .collection('users')
            .doc(userId)
            .collection('DailyGoals')
            .doc(formattedDate);


        // if (docSnapshot.exists) {
        //   // Cast the document data to a Map
        //   Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;
        //
        //   if (data != null && data.containsKey('dailyGoal')) {
        //     // If 'dailyGoal' exists, update it
        //     await userDocRef.update({'dailyGoal': newGoal});
        //   } else {
        //     // If 'dailyGoal' doesn't exist, create it
        //     await userDocRef.set({'dailyGoal': newGoal}, SetOptions(merge: true));
        //   }
        // } else {
        //   // If the document doesn't exist, create it and set the 'dailyGoal'
        //   await userDocRef.set({'dailyGoal': newGoal});
        // }
        await daily_goal.set({
          'dailyGoal': newGoal,
          'timestamp': FieldValue.serverTimestamp(),
        });

      }
    } catch (e) {
      print("Error updating daily goal in Firestore: $e");
    }

    // Recalculate the percentages and notify listeners
    _percent = _consumedCalories / dailyGoal;
    if (_percent > 1.0) {
      _percent = 1.0;
    }
    notifyListeners(); // Notify listeners that the state has changed
  }


}
