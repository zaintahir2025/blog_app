import 'package:flutter/material.dart';

import 'package:blog_app/theme/app_theme.dart';

class InkBackground extends StatelessWidget {
  const InkBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final showAmbientOrbs = width >= 1280;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient(colorScheme.brightness),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white
                                  .withValues(alpha: isDark ? 0.01 : 0.02),
                              Colors.transparent,
                              Colors.black
                                  .withValues(alpha: isDark ? 0.03 : 0.008),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showAmbientOrbs)
                    Positioned(
                      top: -90,
                      right: -40,
                      child: _InkOrb(
                        size: isDark ? 180 : 220,
                        color: colorScheme.primary.withValues(
                          alpha: isDark ? 0.05 : 0.08,
                        ),
                      ),
                    ),
                  if (showAmbientOrbs)
                    Positioned(
                      bottom: -80,
                      left: -50,
                      child: _InkOrb(
                        size: isDark ? 140 : 170,
                        color: colorScheme.primary.withValues(
                          alpha: isDark ? 0.025 : 0.04,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class InkPanel extends StatelessWidget {
  const InkPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
    this.color,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient ??
            AppTheme.panelGradient(
              colorScheme.brightness,
              colorScheme,
            ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.panelBorder(colorScheme)),
        boxShadow: AppTheme.panelShadows(colorScheme.brightness),
      ),
      child: child,
    );
  }
}

class InkHeroCard extends StatelessWidget {
  const InkHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 30,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = colorScheme.brightness;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(brightness),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.panelBorder(colorScheme)),
        boxShadow: AppTheme.panelShadows(brightness),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(
                      alpha: brightness == Brightness.dark ? 0.04 : 0.07,
                    ),
                    Colors.transparent,
                    colorScheme.secondary.withValues(
                      alpha: brightness == Brightness.dark ? 0.03 : 0.04,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

class InkEyebrow extends StatelessWidget {
  const InkEyebrow({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isDark ? Colors.white : colorScheme.primary,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isDark ? Colors.white : colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class InkSectionHeader extends StatelessWidget {
  const InkSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.action,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 760;

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );

    if (action == null || compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textBlock,
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: textBlock),
        const SizedBox(width: 16),
        action!,
      ],
    );
  }
}

class InkMetricPill extends StatelessWidget {
  const InkMetricPill({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.inverted = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedAccent = accentColor ?? colorScheme.primary;
    final isDark = colorScheme.brightness == Brightness.dark;
    final background = inverted
        ? (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03))
        : resolvedAccent.withValues(alpha: 0.08);
    final foreground = inverted
        ? (isDark ? Colors.white : colorScheme.onSurface)
        : resolvedAccent;
    final textColor = inverted
        ? (isDark ? Colors.white70 : colorScheme.onSurfaceVariant)
        : colorScheme.onSurfaceVariant;
    final valueColor = inverted ? foreground : colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: inverted
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : colorScheme.outlineVariant)
              : AppTheme.panelBorder(colorScheme),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 10),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: valueColor,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InkInfoBanner extends StatelessWidget {
  const InkInfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final useCompactLayout = compact;

    return InkPanel(
      padding: const EdgeInsets.all(18),
      radius: 22,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactBanner = useCompactLayout || constraints.maxWidth < 540;

          if (compactBanner) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InkInfoHeader(icon: icon, title: title),
                const SizedBox(height: 10),
                Text(
                  body,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 14),
                  action!,
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 3,
                child: _InkInfoHeader(icon: icon, title: title),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: Text(
                  body,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 14),
                action!,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InkInfoHeader extends StatelessWidget {
  const _InkInfoHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _InkOrb extends StatelessWidget {
  const _InkOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
