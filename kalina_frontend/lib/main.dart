import 'package:flutter/material.dart';
import 'login_page.dart';
import './globals.dart' as globals;
import './screens/nutrition_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  getUserId();
  Timer(Duration(milliseconds: 100), () {
    runApp(const MyApp());
  });
}

// Получение данных
Future<void> getUserId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey('userId')) {
    globals.userId = prefs.getInt('userId');
    globals.proteins = prefs.getInt('proteins')!;
    globals.fats = prefs.getInt('fats')!;
    globals.carbs = prefs.getInt('carbs')!;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalina',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: globals.userId == null ? LoginPage() : NutritionPage(),
    );
  }
}
