import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PdfProvider extends ChangeNotifier {
  File? _pdfFile;
  String? _summary;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _history = [];

  List<Map<String, dynamic>> get history => _history;

  // Method to clear the history
  void clearHistory() {
    _history.clear();
    notifyListeners(); // Notify listeners to update the UI
  }

  void setPdfFile(File file) {
    _pdfFile = file;
    _summary = null; // Reset summary when a new file is picked
    _error = null; // Reset error when a new file is picked
    notifyListeners();
  }

  String? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> extractText() async {
    if (_pdfFile != null) {
      try {
        _isLoading = true;
        notifyListeners();

        final text = await _extractTextFromPdf(_pdfFile!);
        final summary = await _summarizeText(text);

        _summary = summary;

        // Add to history
        _history.add({
          'pdfFile': _pdfFile!.path,  // Save file path instead of the file itself
          'summary': summary,
        });

        // Save the updated history to shared preferences
        await _saveHistoryToLocalStorage();
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Method to load history from local storage
  Future<void> _loadHistoryFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('pdf_history');

    if (historyJson != null) {
      List<dynamic> historyList = jsonDecode(historyJson);
      _history = historyList.map((item) => Map<String, dynamic>.from(item)).toList();
      notifyListeners();
    }
  }

  // Method to save history to local storage
  Future<void> _saveHistoryToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(_history);
    prefs.setString('pdf_history', historyJson);
  }

  // Method to extract text from PDF (as before)
  Future<String> _extractTextFromPdf(File file) async {
    final document = PdfDocument(inputBytes: file.readAsBytesSync());
    final textExtractor = PdfTextExtractor(document);
    String extractedText = '';

    for (int i = 0; i < document.pages.count; i++) {
      final text = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
      extractedText += text;
    }
    print("\n--------------------------------------------------------------------\n" + extractedText);
    return extractedText;
  }

  // Method to summarize text (as before)
  Future<String> _summarizeText(String text) async {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyARtKqdqIqsDrqM0RKnQeuWbqqdiyFZHXI'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                // "text": "Analyze the following text and find the diseases of the patient and suggest the food not to be eaten and which exercises to be done for that disease :\n\n$text"
                // "text": "Analyze the following text and say what u have understand and also suggest the food not to be eaten and which exercises to be done for that disease. Note: Summarize the text in bullet points, use less theory. And also give me the disease that you have identified:\n\n$text"
                "text": """Analyze the following health report and identify any medical conditions mentioned. Summarize the key findings in bullet points with minimal theory. Based on the identified condition(s), provide:

              Foods to avoid
              Recommended exercises for management:\n\n$text"""
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final summary = jsonResponse['candidates'][0]['content']['parts'][0]['text'].trim();
      return summary;
    } else {
      throw Exception('Failed to summarize text: ${response.body}');
    }
  }

  // Constructor to load history when PdfProvider is initialized
  PdfProvider() {
    _loadHistoryFromLocalStorage();
  }
}
