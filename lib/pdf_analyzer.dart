import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart'; // Import open_file package
import 'pdf_provider.dart';
import 'theme_provider.dart';

class PDFAnalyzer extends StatefulWidget {
  @override
  _PDFAnalyzerState createState() => _PDFAnalyzerState();
}

class _PDFAnalyzerState extends State<PDFAnalyzer> {
  File? _selectedPdf;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Summarizer'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                      Provider.of<PdfProvider>(context, listen: false).setPdfFile(_selectedPdf!);
                      await Provider.of<PdfProvider>(context, listen: false).extractText();
                    }
                  },
                  child: const Text('Pick PDF'),
                ),
                const SizedBox(height: 20),
                Consumer<PdfProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const CircularProgressIndicator();
                    } else if (provider.error != null) {
                      return Text('Error: ${provider.error}');
                    } else if (provider.history.isNotEmpty) {
                      return Text(provider.history.last['summary']);
                    } else {
                      return const Text('No summary available.');
                    }
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryPage()),
                    );
                  },
                  child: const Text('Show History'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Consumer<PdfProvider>(
        builder: (context, provider, child) {
          if (provider.history.isEmpty) {
            return Center(child: Text("No previous analyses."));
          } else {
            return ListView.builder(
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final historyItem = provider.history[index];
                final String filePath = historyItem['pdfFile'];
                final String fileName = filePath.split('/').last;

                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(fileName),
                        onTap: () {
                          _showSummaryDialog(context, historyItem['summary']);
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          OpenFile.open(filePath);
                        },
                        child: const Text('Open PDF'),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showSummaryDialog(BuildContext context, String summary) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Summary'),
          content: Text(summary),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
