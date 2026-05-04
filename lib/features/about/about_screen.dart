import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/img/app_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Deen Azkar',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Fortress of the Muslim',
              style: TextStyle(fontSize: 14, color: AppTheme.subTextColor),
            ),
            const SizedBox(height: 8),
            const Text(
              'حِصْنُ الْمُسْلِم',
              style: TextStyle(
                fontFamily: 'Uthmanic',
                fontSize: 22,
                color: AppTheme.primaryRed,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 32),
            const _AboutCard(
              title: 'About the Book',
              content:
                  'Deen Azkar is a collection of '
                  'duas (supplications) from the Quran and Sunnah compiled by '
                  'Sheikh Sa\'id bin Ali bin Wahf Al-Qahtani. It contains '
                  'authentic adhkar for all occasions of daily life.',
            ),
            const SizedBox(height: 12),
            const _AboutCard(
              title: 'Features',
              content:
                  '• 135+ authentic duas with Arabic text\n'
                  '• English translation and transliteration\n'
                  '• Audio recitation for each dua\n'
                  '• Bookmark your favorite duas\n'
                  '• Browse by category\n'
                  '• Zakat calculator\n'
                  '• Prayer times\n'
                  '• Hijri calendar',
            ),
            const SizedBox(height: 12),
            const _AboutCard(
              title: 'Disclaimer',
              content:
                  'This app is provided for educational and religious purposes. '
                  'All content has been sourced from authentic Islamic texts. '
                  'We ask Allah to accept this effort and make it beneficial '
                  'for all Muslims.',
            ),
            const SizedBox(height: 24),
            const Text(
              'May Allah accept this work from us.\nآمين',
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: AppTheme.subTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String title;
  final String content;

  const _AboutCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryRed)),
            const SizedBox(height: 8),
            Text(content,
                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
