import 'package:flutter/material.dart';
import '../widgets/public_scaffold.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const String _policy = '''
Singsation SADEC PTY (Ltd) — Privacy Policy

Last updated: 2025

1. INTRODUCTION
Singsation SADEC PTY (Ltd) ("we", "us", "our") respects your privacy and is committed to protecting your personal information in accordance with the Protection of Personal Information Act (POPIA) of South Africa.

2. INFORMATION WE COLLECT
We may collect the following information when you use our website, mobile application, or services:
• Name, surname, and contact details (email, phone number)
• Age and province of residence
• Payment transaction information
• Competition entry details
• Device and usage information

3. HOW WE USE YOUR INFORMATION
We use your information to:
• Administer competition entries and payments
• Communicate with you about your account, entries, and winnings
• Improve our services and user experience
• Comply with legal obligations

4. SHARING OF INFORMATION
We do not sell your personal information. We may share it with:
• Payment processors to complete transactions
• Service providers who help us operate the platform
• Authorities when required by law

5. DATA SECURITY
We use reasonable technical and organisational measures to protect your personal information against unauthorised access, loss, or misuse.

6. YOUR RIGHTS
Under POPIA you have the right to:
• Access the personal information we hold about you
• Request correction or deletion of your information
• Object to processing of your information
• Lodge a complaint with the Information Regulator of South Africa

7. CONTACT US
For any privacy-related questions, contact us at:
Email: info@sing-sation.com

8. CHANGES TO THIS POLICY
We may update this Privacy Policy from time to time. The latest version will always be available on this page.
''';

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      route: 'privacy',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const Text(
              'PRIVACY POLICY',
              style: TextStyle(
                color: Color(0xFFFDB400),
                fontSize: 56,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              constraints: const BoxConstraints(maxWidth: 780),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFFDB400).withOpacity(0.3)),
              ),
              child: const Text(
                _policy,
                style: TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
