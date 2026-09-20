import 'package:flutter/material.dart';
import '../home_page.dart';
import '../about_page.dart';
import '../contact_page.dart';
import '../faq_page.dart';
import '../privacy_page.dart';

class PublicNavBar extends StatelessWidget {
  final String currentRoute;
  const PublicNavBar({super.key, required this.currentRoute});

  static const String logoAsset = 'assets/images/logo.png';

  void _go(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // LOGO on the LEFT
          GestureDetector(
            onTap: () => _go(context, const HomePage()),
            child: Image.asset(
              logoAsset,
              height: 50,
              errorBuilder: (_, __, ___) => const Text(
                'SINGSATION',
                style: TextStyle(
                  color: Color(0xFFFDB400),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const Spacer(),
          // MENU on the RIGHT (white text)
          if (!isMobile)
            Row(
              children: [
                _navItem(context, 'HOME', const HomePage(), 'home'),
                _navItem(context, 'ABOUT', const AboutPage(), 'about'),
                _navItem(context, 'CONTACT', const ContactPage(), 'contact'),
                _navItem(context, 'FAQ', const FaqPage(), 'faq'),
                _navItem(
                    context, 'PRIVACY', const PrivacyPolicyPage(), 'privacy'),
              ],
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.white),
              color: const Color(0xFF1A1A1A),
              onSelected: (route) {
                switch (route) {
                  case 'home':
                    _go(context, const HomePage());
                    break;
                  case 'about':
                    _go(context, const AboutPage());
                    break;
                  case 'contact':
                    _go(context, const ContactPage());
                    break;
                  case 'faq':
                    _go(context, const FaqPage());
                    break;
                  case 'privacy':
                    _go(context, const PrivacyPolicyPage());
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'home',
                    child: Text('HOME', style: TextStyle(color: Colors.white))),
                PopupMenuItem(
                    value: 'about',
                    child:
                        Text('ABOUT', style: TextStyle(color: Colors.white))),
                PopupMenuItem(
                    value: 'contact',
                    child: Text('CONTACT',
                        style: TextStyle(color: Colors.white))),
                PopupMenuItem(
                    value: 'faq',
                    child: Text('FAQ', style: TextStyle(color: Colors.white))),
                PopupMenuItem(
                    value: 'privacy',
                    child: Text('PRIVACY',
                        style: TextStyle(color: Colors.white))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _navItem(
      BuildContext context, String label, Widget page, String route) {
    final active = currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: () => _go(context, page),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFFDB400) : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
