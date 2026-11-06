import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/validation/form_validators.dart';

/// Widget para los campos de texto del gossip (subject y content)
class GossipTextFields extends StatelessWidget {
  final TextEditingController subjectController;
  final TextEditingController contentController;
  final ValueChanged<String> onSubjectChanged;
  final ValueChanged<String> onContentChanged;

  const GossipTextFields({
    super.key,
    required this.subjectController,
    required this.contentController,
    required this.onSubjectChanged,
    required this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSubjectField(),
        const SizedBox(height: AppSpacing.lg),
        _buildContentField(),
      ],
    );
  }

  Widget _buildSubjectField() {
    return TextFormField(
      controller: subjectController,
      decoration: InputDecoration(
        labelText: 'gossip.text_fields.subject_label'.tr(),
        hintText: 'gossip.text_fields.subject_hint'.tr(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        prefixIcon: const Icon(Icons.person),
      ),
      onChanged: onSubjectChanged,
      maxLength: 200,
      validator: (value) => FormValidators.requiredWithMessage(
        value,
        'gossip.text_fields.subject_validation'.tr(),
      ),
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: contentController,
      decoration: InputDecoration(
        labelText: 'gossip.text_fields.content_label'.tr(),
        hintText: 'gossip.text_fields.content_hint'.tr(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        prefixIcon: const Icon(Icons.chat_bubble),
      ),
      onChanged: onContentChanged,
      maxLines: 5,
      maxLength: 1000,
      validator: (value) => FormValidators.requiredWithMessage(
        value,
        'gossip.text_fields.content_validation'.tr(),
      ),
    );
  }
}
