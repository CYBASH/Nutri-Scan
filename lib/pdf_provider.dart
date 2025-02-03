import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PdfProvider extends ChangeNotifier {
  File? _pdfFile;
  String? _summary;
  bool _isLoading = false;
  String? _error;

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
        print("Extracted text: $text"); // Debugging: Print extracted text
        final summary = await _summarizeText(text);
        print("Summarized text: $summary"); // Debugging: Print summarized text

        _summary = summary;
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

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

  Future<String> _summarizeText(String text) async {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=AIzaSyCX8Y1DlsAL33OqtyIXIt_VojqmKSKkJIU'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": "Analyze the following text and find the diseases of the patitent and suggest the food not to be eaten and which exercises to be done for that disease :\n\n$text"
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
}