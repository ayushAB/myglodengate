import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Theme/design_system.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: margin ?? const EdgeInsets.all(AppSpacing.md),
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(AppRadii.lg),
        boxShadow: elevated ? AppShadows.card(context) : null,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}
