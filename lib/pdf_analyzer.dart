import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pdf_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'splash_screen.dart';

class PDFAnalyzer extends StatefulWidget {
  @override
  _PDFAnalyzerState createState() => _PDFAnalyzerState();
}

class _PDFAnalyzerState extends State<PDFAnalyzer> {
  File? _selectedPdf; // Internal state to track the selected PDF

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Summarizer'),
      ),
      body: Center( // Ensure all content is centered on the screen
        child: SingleChildScrollView( // Added to enable scrolling
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center items vertically
              crossAxisAlignment: CrossAxisAlignment.center, // Center items horizontally
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                    );

                    if (result != null) {
                      setState(() {
                        _selectedPdf = File(result.files.single.path!);
                      });
                      print("Picked file path: ${_selectedPdf!.path}"); // Debugging: Print file path
                      Provider.of<PdfProvider>(context, listen: false).setPdfFile(_selectedPdf!);
                      await Provider.of<PdfProvider>(context, listen: false).extractText();
                    }
                  },
                  child: const Text('Pick PDF'),
                ),
                const SizedBox(height: 20), // Added spacing
                Consumer<PdfProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const CircularProgressIndicator();
                    } else if (provider.error != null) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Error: ${provider.error}'),
                      );
                    } else if (provider.summary != null) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          provider.summary!,
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    } else {
                      return const Text('No summary available.');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
