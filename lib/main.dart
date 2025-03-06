
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
// import 'package:nutri_scan/telegram_service.dart';
import 'package:nutri_scan/theme_provider.dart';
import 'package:provider/provider.dart';
import 'consts.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'meal_provider.dart';
import 'splash_screen.dart';
import 'pdf_provider.dart';
import 'chat_provider.dart'; // Import ChatProvider
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'calorie_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'telegram_service.dart';

void main() async{
  Gemini.init(apiKey: GEMINI_API_KEY);
  final Gemini gemini = Gemini.instance;
  gemini.streamGenerateContent("make sure to give reply in plain text don't use bold or italic text. ");
  WidgetsFlutterBinding.ensureInitialized();
  await createFolders();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // startImageFetcher();
// Get internal storage directory
  final directory = await getExternalStorageDirectory();

  // Define folder paths
  final String folder1 = '${directory?.path}/CapturedImages';
  final String folder2 = '${directory?.path}/AnalyzedImages';

  // Create folders if they do not exist
  await Directory(folder1).create(recursive: true);
  await Directory(folder2).create(recursive: true);  // await FirebaseAuth.instance.signInAnonymously();

  startImageSync();

  // Call syncImages before starting the app

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // ChangeNotifierProvider(create: (context) => MealProvider()), // Add MealProvider
        ChangeNotifierProvider(create: (context) => CalorieProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


void startImageSync() {
  // Run syncImages immediately and then every 5 seconds


  IRImageScreen imgscreenobj = IRImageScreen();
  imgscreenobj.syncImages();

  Timer.periodic(Duration(seconds: 10), (timer) {
    imgscreenobj.syncImages();
  });
}


Future<void> createFolders() async {
  try {
    // Request storage permission
    var status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      print("Storage permission denied");
      return;
    }

    // Get external storage directory
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception("External storage not available");
    }

    // Define paths for 'old' and 'new' folders
    final oldFolder = Directory('${directory.path}/files/old');
    final newFolder = Directory('${directory.path}/files/new');

    // Create folders if they do not exist
    if (!await oldFolder.exists()) {
      await oldFolder.create(recursive: true);
      print("Created: ${oldFolder.path}");
    }
    if (!await newFolder.exists()) {
      await newFolder.create(recursive: true);
      print("Created: ${newFolder.path}");
    }
  } catch (e) {
    print("Error creating folders: $e");
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeProvider>(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PdfProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()), // Add ChatProvider
        ChangeNotifierProvider(create: (_) => CalorieProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeProvider.themeMode,
        // home: FirebaseAuth.instance.currentUser == null ? LoginPage() : SplashScreen(),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(),
          '/home': (context) => HomePage(),
          '/login': (context) => AuthScreen(), // ADD THIS LINE
        },
      ),
    );
  }
}
