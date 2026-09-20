import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/public_scaffold.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // ─── Team image URLs (with ?v=2 to bypass stale CORS cache) ───
  static const String teamJpUrl =
      'https://storage.googleapis.com/singsationsadec/coverssadec/Singsation-Covers-2026-JP.png?v=2';
  static const String teamCyprianUrl =
      'https://storage.googleapis.com/singsationsadec/coverssadec/Singsation-Covers-2026-Cyprian.png?v=2';

  static const String facebookUrl = 'https://facebook.com/';
  static const String instagramUrl = 'https://instagram.com/';
  static const String tiktokUrl = 'https://tiktok.com/';
  static const String youtubeUrl = 'https://youtube.com/';

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      route: 'about',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const Text(
              'ABOUT US',
              style: TextStyle(
                color: Color(0xFFFDB400),
                fontSize: 56,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 780),
              child: const Text(
                'Singsation SADEC is a South African entertainment company '
                'dedicated to discovering and celebrating vocal talent across '
                'the country. Through the Singsation Karaoke Competition, we '
                'give ordinary South Africans a platform to shine — with cash '
                'prizes, exposure, and a community that loves music.\n\n'
                'Our mission is to bring karaoke culture to every corner of '
                'South Africa and to create opportunities for aspiring '
                'singers to rise.',
                style: TextStyle(
                    color: Colors.white70, fontSize: 16, height: 1.7),
              ),
            ),
            const SizedBox(height: 60),
            const Text(
              'THE TEAM',
              style: TextStyle(
                color: Color(0xFFFDB400),
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 32),
            const Wrap(
              spacing: 32,
              runSpacing: 32,
              alignment: WrapAlignment.center,
              children: [
                _TeamCard(
                  name: 'JP LEGEND',
                  role: 'Founder & CEO',
                  imageUrl: teamJpUrl,
                  bio: 'Singer, songwriter, entrepreneur.',
                ),
                _TeamCard(
                  name: 'CYPRIAN HEYDEMAN',
                  role: 'IT Director',
                  imageUrl: teamCyprianUrl,
                  bio: 'Technology and platform lead.',
                ),
                _TeamCard(
                  name: 'TO BE ANNOUNCED',
                  role: 'Marketing Director',
                  imageUrl: null,
                  bio: 'Coming soon.',
                ),
              ],
            ),
            const SizedBox(height: 60),
            const Text(
              'FOLLOW US',
              style: TextStyle(
                color: Color(0xFFFDB400),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _social(Icons.facebook, facebookUrl),
                const SizedBox(width: 24),
                _social(Icons.camera_alt, instagramUrl),
                const SizedBox(width: 24),
                _social(Icons.music_note, tiktokUrl),
                const SizedBox(width: 24),
                _social(Icons.play_circle_fill, youtubeUrl),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _social(IconData icon, String url) => InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        child: Icon(icon, color: const Color(0xFFFDB400), size: 36),
      );
}

class _TeamCard extends StatelessWidget {
  final String name, role, bio;
  final String? imageUrl;

  const _TeamCard({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.bio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDB400).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          ClipOval(
            child: SizedBox(
              width: 120,
              height: 120,
              child: imageUrl == null
                  ? Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.person,
                          size: 60, color: Colors.white24),
                    )
                  : Image.network(
                      imageUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFDB400),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.person,
                            size: 60, color: Colors.white24),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFFFDB400),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
