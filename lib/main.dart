import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login.dart';

const Color kDeepNavy = Color(0xFF0B1F3A);
const Color kMountainBlue = Color(0xFF1E3F73);
const Color kSunsetOrange = Color(0xFFFF8A3D);
const Color kCoralPink = Color(0xFFF45B8D);
const Color kAdventurePurple = Color(0xFF8B3FBF);
const Color kSkyCream = Color(0xFFF7F3EE);
const Color kRiverCyan = Color(0xFF67D6E8);
const Color kForestShadow = Color(0xFF12263F);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wandergram',
      home: const LoginPage(),
    );
  }
}