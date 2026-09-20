import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/public_scaffold.dart';

class AppDownloadPage extends StatelessWidget {
  const AppDownloadPage({super.key});

  static const String splashImageUrl =
      'https://storage.googleapis.com/singsationsadec/splashsadec/Singsation-Splash-2026.png';

  // ─── APK download URL ───
  static const String apkDownloadUrl =
      'https://storage.googleapis.com/singsationsadec/apksadec/app-armeabi-v7a-release.apk';

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      route: 'download',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const Text(
              'DOWNLOAD THE APP',
              style: TextStyle(
                color: Color(0xFFFDB400),
                fontSize: 56,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Get Singsation on your phone and start competing today.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // ─── PHONE MOCKUP WITH SPLASH IMAGE INSIDE ───
            Container(
              width: 220,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFFDB400).withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.network(
                  splashImageUrl,
                  width: 220,
                  height: 400,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFDB400),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.phone_android,
                      size: 80,
                      color: Color(0xFFFDB400),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ─── DOWNLOAD APK BUTTON (smaller, pill shape) ───
            ElevatedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(apkDownloadUrl),
                webOnlyWindowName: '_blank',
              ),
              icon: const Icon(Icons.download, color: Colors.black, size: 20),
              label: const Text(
                'DOWNLOAD APK',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDB400),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ─── STORE BUTTONS (Coming soon style) ───
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

            const SizedBox(height: 60),

            // ─── WHY DOWNLOAD ───
            Container(
              constraints: const BoxConstraints(maxWidth: 780),
              child: const Column(
                children: [
                  Text(
                    'WHY DOWNLOAD?',
                    style: TextStyle(
                      color: Color(0xFFFDB400),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 24),
                  _FeatureRow(
                    icon: Icons.mic,
                    title: 'Sing & Compete',
                    description:
                        'Record your karaoke performance and enter the competition from anywhere in South Africa.',
                  ),
                  _FeatureRow(
                    icon: Icons.emoji_events,
                    title: 'Win Cash Prizes',
                    description:
                        'Compete against the best voices in the country for life-changing cash prizes.',
                  ),
                  _FeatureRow(
                    icon: Icons.library_music,
                    title: 'Huge Song Library',
                    description:
                        'Thousands of karaoke tracks — from local favourites to international hits.',
                  ),
                  _FeatureRow(
                    icon: Icons.people,
                    title: 'Join the Community',
                    description:
                        'Connect with singers from every province and be discovered by industry scouts.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

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

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFDB400).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFDB400), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFDB400),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
