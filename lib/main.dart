import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
// Note: firebase_ai and other specific imports are often not directly used in main.dart
// but are included here for completeness based on previous context.
import 'package:firebase_ai/firebase_ai.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import 'firebase_options.dart';
import 'manga_creator_screen.dart';

// Define a GlobalKey for the Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MaterialApp(
      title: 'AI Manga Storyteller',
      navigatorKey: navigatorKey, // <--- Assign the global key here
      theme: ThemeData(
        // Use a more modern color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple.shade700, // A richer purple
          primary: Colors.deepPurple.shade700,
          onPrimary: Colors.white,
          secondary: Colors.amber.shade700, // A vibrant accent for highlights
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black87,
          background:
              Colors.deepPurple.shade50, // A light background for warmth
        ),
        useMaterial3: true,
        // Apply a Google Font globally
        textTheme:
            GoogleFonts.zillaSlabTextTheme(
              const TextTheme(
                // Provide a default TextTheme here
                bodyLarge: TextStyle(color: Colors.black87),
                bodyMedium: TextStyle(color: Colors.black87),
                bodySmall: TextStyle(color: Colors.black87),
                displayLarge: TextStyle(color: Colors.black),
                displayMedium: TextStyle(color: Colors.black),
                displaySmall: TextStyle(color: Colors.black),
                headlineLarge: TextStyle(color: Colors.black),
                headlineMedium: TextStyle(color: Colors.black),
                headlineSmall: TextStyle(color: Colors.black),
                titleLarge: TextStyle(color: Colors.black),
                titleMedium: TextStyle(color: Colors.black),
                titleSmall: TextStyle(color: Colors.black),
                labelLarge: TextStyle(color: Colors.black87),
                labelMedium: TextStyle(color: Colors.black87),
                labelSmall: TextStyle(color: Colors.black87),
              ),
            ).apply(
              // Then apply global color overrides if desired
              bodyColor: Colors.black87,
              displayColor: Colors.black,
            ),
        appBarTheme: AppBarTheme(
          backgroundColor:
              Colors.deepPurple.shade700, // Consistent app bar color
          foregroundColor: Colors.white, // App bar text/icon color
          titleTextStyle: GoogleFonts.zillaSlab(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 6, // Slightly more pronounced shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 24.0), // Spacing between cards
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            elevation: 5,
            textStyle: GoogleFonts.zillaSlab(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.deepPurple.shade50.withOpacity(
            0.5,
          ), // Lighter, more integrated fill
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 15.0,
          ),
          labelStyle: GoogleFonts.zillaSlab(color: Colors.deepPurple.shade700),
          hintStyle: GoogleFonts.zillaSlab(color: Colors.grey.shade600),
        ),
      ),
      home: const MangaCreatorScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
