import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/public_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String heroBg = 'assets/images/hero_bg.jpg';
  static const String ceoThumb = 'assets/images/ceo_video_thumb.jpg';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.singsation';
  static const String ceoVideoUrl = 'https://www.youtube.com/embed/VIDEO_ID';

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      route: 'home',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const SizedBox(height: 20),
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
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // CEO VIDEO PLACEHOLDER
            Container(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      ceoThumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1A1A1A),
                        child: const Center(
                          child: Text(
                            'CEO WELCOME VIDEO\n(placeholder image)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      ),
                    ),
                    Container(color: Colors.black.withOpacity(0.35)),
                    Center(
                      child: IconButton(
                        iconSize: 72,
                        icon: const Icon(Icons.play_circle_fill,
                            color: Color(0xFFFDB400)),
                        onPressed: () => launchUrl(
                          Uri.parse(ceoVideoUrl),
                          webOnlyWindowName: '_blank',
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 12,
                      left: 16,
                      child: Text(
                        'WELCOMING VIDEO FROM CEO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // PLAY STORE BUTTON
            ElevatedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(playStoreUrl),
                webOnlyWindowName: '_blank',
              ),
              icon: const Icon(Icons.download, color: Colors.black),
              label: const Text(
                'DOWNLOAD FROM PLAY STORE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDB400),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),

            const SizedBox(height: 60),

            Container(
              constraints: const BoxConstraints(maxWidth: 780),
              child: const Text(
                'Singsation is South Africa\'s biggest karaoke competition — '
                'a chance for singers across the country to showcase their '
                'talent, compete for life-changing prizes, and be discovered. '
                'Join the movement.',
                style: TextStyle(
                    color: Colors.white70, fontSize: 16, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
