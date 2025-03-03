
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
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

void main() async{
  Gemini.init(apiKey: GEMINI_API_KEY);
  final Gemini gemini = Gemini.instance;
  gemini.streamGenerateContent("make sure to give reply in plain text don't use bold or italic text. ");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await FirebaseAuth.instance.signInAnonymously();

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
