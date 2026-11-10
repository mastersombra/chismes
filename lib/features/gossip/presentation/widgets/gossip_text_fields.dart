
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/validation/form_validators.dart';
import 'package:chismes/core/l10n/l10n.dart';

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
        labelText: context.l10n.gossipTextFieldsSubjectLabel,
        hintText: context.l10n.gossipTextFieldsSubjectHint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        prefixIcon: const Icon(Icons.person),
      ),
      onChanged: onSubjectChanged,
      maxLength: 200,
      validator: (value) => FormValidators.requiredWithMessage(
        value,
        context.l10n.gossipTextFieldsSubjectValidation,
      ),
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: contentController,
      decoration: InputDecoration(
        labelText: context.l10n.gossipTextFieldsContentLabel,
        hintText: context.l10n.gossipTextFieldsContentHint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        prefixIcon: const Icon(Icons.chat_bubble),
      ),
      onChanged: onContentChanged,
      maxLines: 5,
      maxLength: 1000,
      validator: (value) => FormValidators.requiredWithMessage(
        value,
        context.l10n.gossipTextFieldsContentValidation,
      ),
    );
  }
}
