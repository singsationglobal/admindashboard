import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Web-only import for the video element.
import 'hero_video_web.dart' if (dart.library.io) 'hero_video_stub.dart';

import 'widgets/public_scaffold.dart';
// FIX 1: Import the download page so we can navigate to it directly
import 'app_download_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String heroVideoUrl =
      'https://storage.googleapis.com/singsationsadec/videossadec/9005827-hd_1920_1080_25fps.mp4';
  static const String heroPosterUrl = 'assets/images/ceo_video_thumb.jpg';

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      route: 'home',
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (kIsWeb)
                  buildHeroVideo(heroVideoUrl)
                else
                  Image.asset(
                    heroPosterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF0D0D0D),
                    ),
                  ),
                Container(color: Colors.black.withOpacity(0.45)),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'WELCOME TO',
                            style: TextStyle(
                              color: Color(0xFFFDB400),
                              letterSpacing: 6,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // PROTECTED: Will not cut off on mobile phones
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: const Text(
                              'SINGSATION',
                              style: TextStyle(
                                color: Color(0xFFFDB400),
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          const Text(
                            'SOUTH AFRICA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'The Biggest Karaoke Competition in South Africa',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // 1. EXTRA BUTTON: Takes them to the Download App screen
                          ElevatedButton.icon(
                            onPressed: () {
                              // FIX 2: Uses the exact same safe navigation pattern as your PublicNavBar
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const AppDownloadPage()),
                              );
                            },
                            icon: const Icon(Icons.download, color: Colors.black, size: 20),
                            label: const Text(
                              'Download APK',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFDB400),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              minimumSize: const Size(240, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),

                          // 2. KEPT INTACT: The two "Coming Soon" store buttons
                          Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: const [
                              _ComingSoonStoreButton(
                                icon: Icons.android,
                                label: 'Coming soon to\nGoogle Play',
                              ),
                              _ComingSoonStoreButton(
                                icon: Icons.apple,
                                label: 'Coming soon to\nthe App Store',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 780),
              child: const Text(
                'Singsation is South Africa\'s biggest karaoke competition — '
                'a chance for singers across the country to showcase their '
                'talent, compete for life-changing prizes, and be discovered. '
                'Join the movement.',
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STORE BUTTON — Kept exactly as it was
// ─────────────────────────────────────────────────────────────────────────────
class _ComingSoonStoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ComingSoonStoreButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDB400), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFDB400), size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
