import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/report_reason.dart';

/// Diálogo para reportar un gossip
///
/// Muestra las opciones de reporte disponibles y permite
/// agregar detalles adicionales opcionales.
class ReportGossipDialog extends StatefulWidget {
  const ReportGossipDialog({super.key});

  @override
  State<ReportGossipDialog> createState() => _ReportGossipDialogState();
}

class _ReportGossipDialogState extends State<ReportGossipDialog> {
  ReportReason? _selectedReason;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.gossipReportTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Por qué reportas este chisme?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSpacing.md),

            // Lista de razones
            ...ReportReason.values.map((reason) {
              return ListTile(
                title: Text(reason.displayName),
                leading: Radio<ReportReason>(
                  value: reason,
                  // ignore: deprecated_member_use
                  groupValue: _selectedReason,
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _selectedReason = reason;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),

            const SizedBox(height: AppSpacing.md),

            // Campo de detalles opcionales
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Detalles adicionales (opcional)',
                hintText: 'Describe el problema...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.cancel),
        ),
        FilledButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  Navigator.pop(context, {
                    'reason': _selectedReason!,
                    'details': _detailsController.text.trim().isEmpty
                        ? null
                        : _detailsController.text.trim(),
                  });
                },
          child: Text(AppLocalizations.gossipReportButton),
        ),
      ],
    );
  }
}
