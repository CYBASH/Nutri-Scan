import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _meals = [];

  List<Map<String, dynamic>> get meals => _meals;

  MealProvider() {
    fetchMeals();
  }

  Future<void> fetchMeals() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot snapshot = await firestore.collection('meals').get();

      _meals = snapshot.docs.map((doc) {
        return {
          "title": doc["title"] ?? "Unknown",
          "subtitle": doc["subtitle"] ?? "No details",
          "calories": doc["calories"] ?? 0,
          "image": doc["image"] ?? "",
        };
      }).toList();

      notifyListeners(); // Notify UI to rebuild
    } catch (e) {
      debugPrint("Error fetching meals: $e");
    }
  }
}
