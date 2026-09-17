import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. Define your core university colors as constants
const Color universityGreen = Color(0xFF00A650); // Replacing the Blue
const Color universityRed = Color(0xFFED1C24);   // Replacing the Red
const Color universityWhite = Color(0xFFFFFFFF);
const Color universityBlack = Color(0xFF000000);

// 2. Create your Light and Dark Color Schemes from those seeds
final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: universityGreen,
  brightness: Brightness.light,
  secondary: universityRed, // Specify your secondary accent
);

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF006B00), // Replacing the Blue seed with custom green
  brightness: Brightness.dark,
  primary: const Color(0xFF006B00),
  secondary: universityRed, 
  surface: const Color(0xFF001900),
);

// 3. Define the actual ThemeData variables
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: lightColorScheme,
  scaffoldBackgroundColor: universityWhite,
  fontFamily: GoogleFonts.cairo().fontFamily,
  textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: darkColorScheme,
  scaffoldBackgroundColor: const Color(0xFF001600),
  fontFamily: GoogleFonts.cairo().fontFamily,
  textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF001600),
    foregroundColor: Colors.white,
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF001600),
    selectedItemColor: Color(0xFFED1C24),
    unselectedItemColor: Color(0xFF00A650),
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
);
