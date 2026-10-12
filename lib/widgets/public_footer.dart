import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_login_dialog.dart';

class PublicFooter extends StatelessWidget {
  const PublicFooter({super.key});

  static const String facebookUrl = 'https://facebook.com/';
  static const String instagramUrl = 'https://instagram.com/';
  static const String tiktokUrl = 'https://tiktok.com/';
  static const String youtubeUrl = 'https://youtube.com/';
  static const String contactEmail = 'info@sing-sation.com';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _social(Icons.facebook, facebookUrl),
              const SizedBox(width: 20),
              _social(Icons.camera_alt, instagramUrl),
              const SizedBox(width: 20),
              _social(Icons.music_note, tiktokUrl),
              const SizedBox(width: 20),
              _social(Icons.play_circle_fill, youtubeUrl),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© ${DateTime.now().year} Singsation SADEC PTY (Ltd) — All rights reserved.',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            'info@sing-sation.com',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // ================== HIDDEN STAFF ENTRY ==================
          // Tiny grey dot. Only staff know to click here.
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => const AdminLoginDialog(),
            ),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // =========================================================
        ],
      ),
    );
  }

  Widget _social(IconData icon, String url) => InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        child: Icon(icon, color: const Color(0xFFFDB400), size: 28),
      );
}
