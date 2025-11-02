import 'package:flutter/material.dart';

/// Language switcher dropdown for Indian languages
class LanguageSwitcher extends StatelessWidget {
  final String currentLocale;
  final ValueChanged<String> onLanguageChanged;

  const LanguageSwitcher({
    super.key,
    required this.currentLocale,
    required this.onLanguageChanged,
  });

  static const Map<String, Map<String, String>> languages = {
    'en': {'name': 'English', 'native': 'English', 'flag': '🇬🇧'},
    'hi': {'name': 'Hindi', 'native': 'हिंदी', 'flag': '🇮🇳'},
    'ta': {'name': 'Tamil', 'native': 'தமிழ்', 'flag': '🇮🇳'},
    'te': {'name': 'Telugu', 'native': 'తెలుగు', 'flag': '🇮🇳'},
    'mr': {'name': 'Marathi', 'native': 'मराठी', 'flag': '🇮🇳'},
    'bn': {'name': 'Bengali', 'native': 'বাংলা', 'flag': '🇮🇳'},
    'gu': {'name': 'Gujarati', 'native': 'ગુજરાતી', 'flag': '🇮🇳'},
  };

  @override
  Widget build(BuildContext context) {
    final currentLang = languages[currentLocale] ?? languages['en']!;

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLang['flag']!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              currentLang['native']!,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[700],
              size: 20,
            ),
          ],
        ),
      ),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) {
        return languages.entries.map((entry) {
          final code = entry.key;
          final lang = entry.value;
          final isSelected = code == currentLocale;

          return PopupMenuItem<String>(
            value: code,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber.shade50 : null,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    lang['flag']!,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang['native']!,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.amber.shade900
                                : Colors.grey[800],
                          ),
                        ),
                        Text(
                          lang['name']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList();
      },
      onSelected: onLanguageChanged,
    );
  }
}

