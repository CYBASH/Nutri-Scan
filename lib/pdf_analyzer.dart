import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pdf_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'theme_provider.dart'; // Import your ThemeProvider

class PDFAnalyzer extends StatefulWidget {
  @override
  _PDFAnalyzerState createState() => _PDFAnalyzerState();
}

class _PDFAnalyzerState extends State<PDFAnalyzer> {
  File? _selectedPdf; // Internal state to track the selected PDF

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue, // Button background color
                    foregroundColor: Colors.white, // Button text color
                  ),
                  child: const Text('Pick PDF'),
                ),
                const SizedBox(height: 20), // Added spacing

                // Display the summary or loading/error message
                Consumer<PdfProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const CircularProgressIndicator();
                    } else if (provider.error != null) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Error: ${provider.error}'),
                      );
                    } else if (provider.history.isNotEmpty) {
                      // Display the most recent summary
                      final recentSummary = provider.history.last['summary'];
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recentSummary,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    } else {
                      return const Text('No summary available.');
                    }
                  },
                ),


                const SizedBox(height: 20), // Added spacing

                // Button to navigate to the HistoryPage
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.green[800] : Colors.green,
                    foregroundColor: Colors.white,
                  ),
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.red,  // Set the icon color to red
            ),
            onPressed: () {
              // Show a confirmation dialog before clearing history
              _showClearHistoryDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<PdfProvider>(
        builder: (context, provider, child) {
          if (provider.history.isEmpty) {
            return Center(child: Text("No previous analyses."));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final historyItem = provider.history[index];
                final String filePath = historyItem['pdfFile']; // Stored as a String
                final String fileName = filePath.split('/').last; // Extract only file name

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ListTile(
                    title: Text(fileName), // Display only file name
                    onTap: () {
                      _showSummaryDialog(context, historyItem['summary']);
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  // Function to show the summary in a dialog when the card is tapped
  void _showSummaryDialog(BuildContext context, String summary) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Summary'),
          content: SingleChildScrollView(
            child: Text(summary),
          ),
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

  // Function to show confirmation dialog before clearing history
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear History'),
          content: Text('Are you sure you want to clear all history?'),
          actions: [
            TextButton(
              onPressed: () {
                // Clear the history using the PdfProvider
                context.read<PdfProvider>().clearHistory();
                Navigator.of(context).pop();
              },
              child: Text("Yes"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("No"),
            ),
          ],
        );
      },
    );
  }
}

