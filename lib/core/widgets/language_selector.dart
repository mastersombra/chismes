import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../localization/locale_detector.dart';

/// Selector de idioma para la aplicación
///
/// Muestra un PopupMenu con los idiomas disponibles.
/// El idioma seleccionado se guarda automáticamente con easy_localization.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return PopupMenuButton<Locale>(
      icon: Text(
        _getFlag(currentLocale),
        style: const TextStyle(fontSize: 24),
      ),
      tooltip: 'Cambiar idioma',
      onSelected: (locale) {
        context.setLocale(locale);
      },
      itemBuilder: (context) => [
        _buildMenuItem(
          locale: const Locale('es'),
          isSelected: currentLocale.languageCode == 'es',
        ),
        _buildMenuItem(
          locale: const Locale('en'),
          isSelected: currentLocale.languageCode == 'en',
        ),
      ],
    );
  }

  PopupMenuItem<Locale> _buildMenuItem({
    required Locale locale,
    required bool isSelected,
  }) {
    final info = LocaleDetector.getLocaleInfo(locale);

    return PopupMenuItem<Locale>(
      value: locale,
      child: Row(
        children: [
          Text(
            info['emoji']!,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Text(
            info['nativeName']!,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, size: 20),
          ],
        ],
      ),
    );
  }

  String _getFlag(Locale locale) {
    return LocaleDetector.getLocaleInfo(locale)['emoji']!;
  }
}
