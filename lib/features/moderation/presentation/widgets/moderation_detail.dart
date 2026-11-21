import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Sección con título de una pantalla de detalle de moderación
class DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const DetailSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

/// Fila ícono + texto de una pantalla de detalle
class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const DetailInfoRow({super.key, required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.xl, color: color ?? scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
