import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/gossip.dart';
import '../states/add_gossip_state.dart';
import '../../../../core/theme/app_spacing.dart';

/// Widget para seleccionar cómo publicar (anónimo o con perfil)
class PublishAsSelector extends StatelessWidget {
  final AddGossipState state;
  final ValueChanged<PublishAs> onPublishAsChanged;

  const PublishAsSelector({
    super.key,
    required this.state,
    required this.onPublishAsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'gossip.publish_as.title'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            RadioGroup<PublishAs>(
              groupValue: state.publishedAs,
              onChanged: (PublishAs? newValue) {
                if (newValue != null) {
                  onPublishAsChanged(newValue);
                }
              },
              child: Row(
                children: [
                  _buildRadioOption(
                    value: PublishAs.anonymous,
                    label: 'gossip.publish_as.anonymous'.tr(),
                    icon: Icons.person_off,
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  _buildRadioOption(
                    value: PublishAs.profile,
                    label: 'gossip.publish_as.with_profile'.tr(),
                    icon: Icons.person,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required PublishAs value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: RadioListTile<PublishAs>(
        value: value,
        title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}
