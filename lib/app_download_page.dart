import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/public_scaffold.dart';

class AppDownloadPage extends StatelessWidget {
  const AppDownloadPage({super.key});

  // ─── CHANGE THESE TWO URLS LATER WHEN THE APP IS PUBLISHED ───
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.singsation';
  static const String appStoreUrl =
      'https://apps.apple.com/za/app/singsation/id0000000000';

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

            // ─── PHONE MOCKUP PLACEHOLDER ───
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
              child: const Center(
                child: Icon(
                  Icons.phone_android,
                  size: 80,
                  color: Color(0xFFFDB400),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ─── STORE BUTTONS ───
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _storeButton(
                  icon: Icons.android,
                  label: 'GET IT ON\nGoogle Play',
                  url: playStoreUrl,
                ),
                _storeButton(
                  icon: Icons.apple,
                  label: 'Download on the\nApp Store',
                  url: appStoreUrl,
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

            const SizedBox(height: 60),

            ElevatedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(playStoreUrl),
                webOnlyWindowName: '_blank',
              ),
              icon: const Icon(Icons.download, color: Colors.black),
              label: const Text(
                'DOWNLOAD NOW',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDB400),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeButton({
    required IconData icon,
    required String label,
    required String url,
  }) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), webOnlyWindowName: '_blank'),
      child: Container(
        width: 220,
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
