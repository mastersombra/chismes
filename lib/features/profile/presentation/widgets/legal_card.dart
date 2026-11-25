import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/legal/legal_document.dart';
import '../../../../core/legal/legal_document_screen.dart';
import 'settings_card.dart';

/// Perfil → Legal: Política de privacidad y Términos de uso (requisito de
/// App Store y Google Play: accesibles dentro de la app)
class LegalCard extends StatelessWidget {
  const LegalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: context.l10n.legalSectionTitle,
      icon: Icons.gavel_outlined,
      children: [
        ListTile(
          key: const Key('legalPrivacyPolicyTile'),
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(context.l10n.legalPrivacyPolicyTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              LegalDocumentScreen.open(context, LegalDocument.privacyPolicy),
        ),
        const Divider(height: 1),
        ListTile(
          key: const Key('legalTermsOfServiceTile'),
          leading: const Icon(Icons.description_outlined),
          title: Text(context.l10n.legalTermsOfServiceTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              LegalDocumentScreen.open(context, LegalDocument.termsOfService),
        ),
      ],
    );
  }
}
