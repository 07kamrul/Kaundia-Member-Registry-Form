import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Branded layout shared by the login / forgot / reset password screens.
///
/// - Phones (portrait): emerald gradient header with the society logo, the
///   form card overlapping its bottom edge.
/// - Tablets / landscape: brand panel on the left, form card on the right.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer = const [],
  });

  /// Wide enough to host the brand panel and a comfortable form side by side.
  static const double _splitMinWidth = 720;
  static const double _formMaxWidth = 440;

  final String title;
  final String? subtitle;

  /// Form content (fields, messages, primary action).
  final Widget child;

  /// Secondary links rendered under a divider at the bottom of the card.
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final card = _AuthCard(title: title, subtitle: subtitle, footer: footer, child: child);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _splitMinWidth) {
              return _SplitLayout(card: card);
            }
            return _StackedLayout(card: card);
          },
        ),
      ),
    );
  }
}

class _SplitLayout extends StatelessWidget {
  const _SplitLayout({required this.card});

  final Widget card;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(child: _BrandPanel(expanded: true)),
        Expanded(
          child: SafeArea(
            left: false,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.pageGutter),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AuthScaffold._formMaxWidth),
                  child: card,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StackedLayout extends StatelessWidget {
  const _StackedLayout({required this.card});

  /// How far the card slides up over the gradient header.
  static const double _overlap = 32;

  final Widget card;

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BrandPanel(expanded: false, bottomInset: _overlap),
          Transform.translate(
            offset: const Offset(0, -_overlap),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AuthScaffold._formMaxWidth),
                    child: card,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Emerald gradient with the society logo and name.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.expanded, this.bottomInset = 0});

  final bool expanded;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final onBrand = Colors.white.withValues(alpha: 0.82);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: expanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        _Logo(size: expanded ? 88 : 72, label: loc.authLoginLogoAlt),
        SizedBox(height: expanded ? 24 : 12),
        Text(
          loc.homeHeroEyebrow.toUpperCase(),
          textAlign: expanded ? TextAlign.start : TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.amber200,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          loc.registrationHeaderOrgName,
          textAlign: expanded ? TextAlign.start : TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: (expanded ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge)
              ?.copyWith(color: Colors.white),
        ),
        if (expanded) ...[
          const SizedBox(height: 12),
          Text(
            loc.registrationHeaderOrgSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: onBrand),
          ),
          const SizedBox(height: 24),
          Container(width: 48, height: 3, color: AppColors.amber200),
          const SizedBox(height: 12),
          Text(
            loc.registrationHeaderOrgLocation,
            style: theme.textTheme.bodySmall?.copyWith(color: onBrand),
          ),
        ],
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald900, AppColors.emerald700, AppColors.emerald600],
        ),
        borderRadius: expanded
            ? null
            : const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg * 1.5)),
      ),
      child: SafeArea(
        right: !expanded,
        bottom: expanded,
        child: Padding(
          padding: expanded
              ? const EdgeInsets.all(48)
              : EdgeInsets.fromLTRB(24, 28, 24, 28 + bottomInset),
          child: expanded
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(child: content),
                )
              : content,
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size, required this.label});

  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: AppColors.amber200, width: 2),
        ),
        child: Icon(Icons.groups_rounded, size: size * 0.5, color: Colors.white),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final List<Widget> footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = context.responsive<double>(compact: 20, medium: 28);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 20),
            child,
            if (footer.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...footer,
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline success / error message box used by the auth forms.
class AuthNotice extends StatelessWidget {
  const AuthNotice({super.key, required this.message, this.isError = true});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.mark_email_read_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isError ? color : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Footer link with a leading icon (e.g. "Back to Login").
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_back,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
