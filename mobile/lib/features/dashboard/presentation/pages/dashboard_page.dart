import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/public_stats_repository.dart';
import '../bloc/dashboard_bloc.dart';

/// Dashboard — tier-aware. Public stats cards for everyone; own-status card
/// for members (profile.view_own). Data via [DashboardBloc]; no logic here.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.id, this.propertyId, this.returnUrl});

  final String? id;
  final String? propertyId;
  final String? returnUrl;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider<DashboardBloc>(
      create: (_) =>
          DashboardBloc(repository: sl<PublicStatsRepository>())..add(const DashboardStarted()),
      child: Scaffold(
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) => RefreshIndicator(
            onRefresh: () async =>
                context.read<DashboardBloc>().add(const DashboardStarted(forceRefresh: true)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                PageHeader(title: loc.navDashboard),
                switch (state) {
                  DashboardInitial() || DashboardLoading() => const SkeletonLoader(lines: 3),
                  DashboardFailure(:final error) => InlineError(
                      message: _errorMessage(context, error),
                      onRetry: () =>
                          context.read<DashboardBloc>().add(const DashboardStarted(forceRefresh: true)),
                    ),
                  DashboardLoaded() => _LoadedView(state: state),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _errorMessage(BuildContext context, ApiException error) {
    final loc = AppLocalizations.of(context);
    if (error.isNetwork) return loc.commonNetworkError;
    if (error.isServer) return loc.commonServerError;
    return error.message ?? loc.commonServerError;
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final stats = state.stats;
    return Column(
      children: [
        if (state.ownStatus != null)
          AppCard(
            title: loc.homeHeroApplicationReviewLabel,
            child: Row(
              children: [
                Expanded(child: Text(loc.commonStatusPending)),
                const StatusBadge(kind: StatusKind.pending),
              ],
            ),
          ),
        AppCard(
          title: loc.homeHeroStatCardTitle,
          child: Column(
            children: [
              _StatRow(label: loc.commonStatusPending, value: stats.pendingCount),
              const Divider(),
              _StatRow(label: loc.commonStatusApproved, value: stats.approvedCount),
              const Divider(),
              _StatRow(
                label: loc.homeHeroMonthlySubscriptionLabel,
                value: stats.monthlySubscriptionTotal,
              ),
            ],
          ),
        ),
        AppCard(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppButton(
                label: loc.homeHeroApplyButton,
                icon: Icons.app_registration,
                onPressed: () => context.go('/register'),
              ),
              AppButton(
                label: loc.homeHeroLoginButton,
                variant: AppButtonVariant.secondary,
                icon: Icons.login,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
