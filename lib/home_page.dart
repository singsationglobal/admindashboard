import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

// Web-only import for the video element.
// On non-web platforms, this import is a no-op.
import 'hero_video_web.dart' if (dart.library.io) 'hero_video_stub.dart';

import 'widgets/public_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ─── CORRECT video URL ───
  // Note: folder is `videossadec` (not `videos`) and host is `storage.googleapis.com`
  // (not `storage.cloud.google.com`).
  static const String heroVideoUrl =
      'https://storage.googleapis.com/singsationsadec/videossadec/9005827-hd_1920_1080_25fps.mp4';

  static const String heroPosterUrl = 'assets/images/ceo_video_thumb.jpg';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.singsation';
  static const String appStoreUrl =
      'https://apps.apple.com/za/app/singsation/id0000000000';

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      route: 'home',
      child: Column(
        children: [
          // ─────────────────────────────────────────────
          // HERO — full-width video with overlay + CTA
          // ─────────────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. VIDEO BACKGROUND (web) or placeholder (other platforms)
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

                // 2. DARK OVERLAY so text is readable over video
                Container(color: Colors.black.withOpacity(0.45)),

                // 3. CENTERED CONTENT ON TOP OF VIDEO
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 40),
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
                          const Text(
                            'SINGSATION',
                            style: TextStyle(
                              color: Color(0xFFFDB400),
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                            textAlign: TextAlign.center,
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
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // ─── STORE BUTTONS ROW ───
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

                          const SizedBox(height: 20),

                          // ─── DISABLED CTA BUTTON ───
                          ElevatedButton.icon(
                            onPressed: null, // disabled — coming soon
                            icon: const Icon(Icons.download,
                                color: Colors.black54),
                            label: const Text(
                              'COMING SOON',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFFDB400).withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─────────────────────────────────────────────
          // BODY BELOW THE HERO — the mission statement
          // ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 780),
              child: const Text(
                'Singsation is South Africa\'s biggest karaoke competition — '
                'a chance for singers across the country to showcase their '
                'talent, compete for life-changing prizes, and be discovered. '
                'Join the movement.',
                style:
                    TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
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
// STORE BUTTON — shows a store icon + "Coming soon" label
// Visually matches the store buttons on the App Download page.
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
