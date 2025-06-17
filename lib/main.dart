import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/manga_creator/data/services/ai_service.dart';
import 'features/manga_creator/presentation/bloc/manga_creator_cubit.dart';
import 'features/manga_creator/presentation/manga_creator_screen.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MaterialApp(
      title: 'AI Manga Storyteller',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple.shade700,
          primary: Colors.deepPurple.shade700,
          onPrimary: Colors.white,
          secondary: Colors.amber.shade700,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black87,
          surfaceBright: Colors.deepPurple.shade50,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.zillaSlabTextTheme(
          const TextTheme(
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
        ).apply(bodyColor: Colors.black87, displayColor: Colors.black),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple.shade700,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.zillaSlab(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 24.0),
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
          fillColor: Colors.deepPurple.shade50.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 15.0,
          ),
          labelStyle: GoogleFonts.zillaSlab(color: Colors.deepPurple.shade700),
          hintStyle: GoogleFonts.zillaSlab(color: Colors.grey.shade600),
        ),
      ),
      home: BlocProvider(
        create: (context) => MangaCreatorCubit(AiService()),
        child: const MangaCreatorScreen(),
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}
