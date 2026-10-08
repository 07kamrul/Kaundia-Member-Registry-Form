import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import '../layout/responsive.dart';
import '../theme/app_theme.dart';

/// Friendly 403 screen shown when the route guard rejects a permission.
class ForbiddenPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const ForbiddenPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.pageGutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _ForbiddenIllustration(),
                  const SizedBox(height: 24),
                  Text(
                    '403',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.forbiddenTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.forbiddenMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: loc.forbiddenBackToDashboard,
                    icon: Icons.dashboard_outlined,
                    expanded: true,
                    onPressed: () => context.go('/dashboard'),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: loc.authLoginBackToHome,
                    icon: Icons.home_outlined,
                    variant: AppButtonVariant.ghost,
                    expanded: true,
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForbiddenIllustration extends StatelessWidget {
  const _ForbiddenIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
        border: Border.all(color: AppColors.amber200.withValues(alpha: 0.6), width: 2),
      ),
      child: Icon(Icons.lock_person_outlined, size: 52, color: theme.colorScheme.primary),
    );
  }
}
