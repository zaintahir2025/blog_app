import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/theme/app_theme.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
    required this.heroTitle,
    required this.heroBody,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;
  final String heroTitle;
  final String heroBody;

  @override
  Widget build(BuildContext context) {
    final expanded = AppLayout.isExpanded(context);

    return Scaffold(
      body: InkBackground(
        child: SafeArea(
          child: expanded
              ? Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(48, 32, 24, 32),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: _AuthMarketingPanel(
                              heroTitle: heroTitle,
                              heroBody: heroBody,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 32, 48, 32),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: _AuthCard(
                              title: title,
                              subtitle: subtitle,
                              child: child,
                              footer: footer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: AppLayout.pagePadding(context),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AuthMarketingPanel(
                            heroTitle: heroTitle,
                            heroBody: heroBody,
                            compact: true,
                          ),
                          const SizedBox(height: 18),
                          _AuthCard(
                            title: title,
                            subtitle: subtitle,
                            child: child,
                            footer: footer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _AuthMarketingPanel extends StatelessWidget {
  const _AuthMarketingPanel({
    required this.heroTitle,
    required this.heroBody,
    this.compact = false,
  });

  final String heroTitle;
  final String heroBody;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alignment =
        compact ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return SizedBox(
      height: compact ? 420 : 640,
      child: Stack(
        children: [
          Positioned(
            top: compact ? 120 : 170,
            left: compact ? 0 : 40,
            right: compact ? 0 : null,
            child: Align(
              alignment: compact ? Alignment.center : Alignment.centerLeft,
              child: _GlowOrb(size: compact ? 220 : 320),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(compact ? 20 : 16),
              child: Column(
                crossAxisAlignment: alignment,
                children: [
                  Align(
                    alignment:
                        compact ? Alignment.center : Alignment.centerLeft,
                    child: const _BrandWordmark(),
                  ),
                  SizedBox(height: compact ? 36 : 70),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Text(
                      heroTitle,
                      textAlign: compact ? TextAlign.center : TextAlign.left,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: compact ? 32 : 54,
                            height: 1.04,
                          ),
                    ),
                  ).animate().fade(duration: 280.ms).slideY(begin: 0.05),
                  SizedBox(height: compact ? 14 : 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Text(
                      heroBody,
                      textAlign: compact ? TextAlign.center : TextAlign.left,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.7,
                          ),
                    ),
                  ).animate().fade(delay: 90.ms, duration: 280.ms),
                  const Spacer(),
                  Align(
                    alignment:
                        compact ? Alignment.center : Alignment.centerLeft,
                    child: Text(
                      'Personal blogging partner',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            letterSpacing: 0.1,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkPanel(
      padding: const EdgeInsets.all(28),
      radius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inkwell',
            style: GoogleFonts.playfairDisplay(
              color: colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 30,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 28),
          child,
          const SizedBox(height: 18),
          footer,
        ],
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'INK',
            style: GoogleFonts.playfairDisplay(
              color: colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'WELL',
            style: GoogleFonts.playfairDisplay(
              color: colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: '.',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.primaryColor,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.9),
            AppTheme.primaryColor.withValues(alpha: 0.38),
            AppTheme.primaryColor.withValues(alpha: 0),
          ],
          stops: const [0.16, 0.5, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.24),
            blurRadius: 54,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}
