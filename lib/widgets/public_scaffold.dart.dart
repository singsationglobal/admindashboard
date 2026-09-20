import 'package:flutter/material.dart';
import 'public_nav_bar.dart';
import 'public_footer.dart';

class PublicScaffold extends StatelessWidget {
  final String route;
  final Widget child;

  const PublicScaffold({
    super.key,
    required this.route,
    required this.child,
  });

  static const String heroBg = 'assets/images/hero_bg.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // FULL-SCREEN BACKGROUND IMAGE (placeholder until file swapped)
          Positioned.fill(
            child: Image.asset(
              heroBg,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
                  ),
                ),
              ),
            ),
          ),
          // DARK OVERLAY so white text stays readable
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          // CONTENT
          SafeArea(
            child: Column(
              children: [
                PublicNavBar(currentRoute: route),
                Expanded(child: SingleChildScrollView(child: child)),
                const PublicFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}