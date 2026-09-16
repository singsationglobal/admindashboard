import 'package:flutter/material.dart';
import '../widgets/public_scaffold.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static const List<List<String>> _faqs = [
    [
      'What is Singsation?',
      'Singsation is South Africa\'s biggest karaoke competition. Singers from across the country compete for cash prizes and exposure.'
    ],
    [
      'Who can enter?',
      'Anyone 18 years or older and a resident of South Africa. See Terms & Conditions for full eligibility.'
    ],
    [
      'How do I enter?',
      'Download the Singsation app from the Play Store, register, pay the entry fee, and submit your performance.'
    ],
    [
      'How much does it cost?',
      'Entry fees are shown in the app at the point of payment. Fees may vary per competition round.'
    ],
    [
      'What can I win?',
      'Cash prizes — see the current competition poster and in-app details for the latest prize pool.'
    ],
    [
      'How are winners chosen?',
      'Winners are selected by judges based on performance quality, or by random draw for crowdfunding campaigns.'
    ],
    [
      'How will I know if I won?',
      'Winners are announced in the app, on our social media, and contacted directly via the details in their profile.'
    ],
    [
      'I have a problem with my entry. Who do I contact?',
      'Email us via the Contact page or open a complaint ticket from within the Singsation app.'
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return PublicScaffold(
      route: 'faq',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const Text(
              'FAQ',
              style: TextStyle(
                color: Color(0xFFFDB400),
                fontSize: 56,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Container(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Column(
                children: _faqs
                    .map(
                      (f) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  const Color(0xFFFDB400).withOpacity(0.3)),
                        ),
                        child: ExpansionTile(
                          iconColor: const Color(0xFFFDB400),
                          collapsedIconColor: const Color(0xFFFDB400),
                          title: Text(
                            f[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 0, 16, 16),
                              child: Text(
                                f[1],
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
