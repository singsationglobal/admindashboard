import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/admin_theme.dart';
import 'core/admin_local_storage.dart';
import 'screens/admin/dashboard_screen.dart';
import 'home_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SingsationAdminApp());
}

class SingsationAdminApp extends StatefulWidget {
  const SingsationAdminApp({super.key});

  @override
  State<SingsationAdminApp> createState() => _SingsationAdminAppState();
}

class _SingsationAdminAppState extends State<SingsationAdminApp> {
  bool? _isLoggedIn;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final loggedIn = await AdminLocalStorage.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    return MaterialApp(
      title: 'Singsation Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AdminTheme.primary,
        scaffoldBackgroundColor: AdminTheme.background,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: AdminTheme.surface,
          foregroundColor: AdminTheme.textLight,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminTheme.primary, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primary,
            foregroundColor: AdminTheme.textLight,
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      // ✅ FIX: Actually use the _isLoggedIn state to route correctly!
      home: _isLoggedIn == true ? const DashboardScreen() : const HomePage(),
    );
  }
}
