import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'core/globals.dart';
import 'core/app_theme.dart';
import 'core/app_data.dart';
import 'services/local_storage_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  await AppData.loadFromStorage();
  
  if (!kIsWeb && !Platform.isWindows) {
    try { 
      cameras = await availableCameras(); 
    } catch (e) { 
      cameras = []; 
    }
  } else { 
    cameras = []; 
  }
  
  runApp(const SingsationsApp());
}

class SingsationsApp extends StatelessWidget {
  const SingsationsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.orangeBg,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}
