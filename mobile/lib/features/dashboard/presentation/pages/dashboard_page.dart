import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
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
    return BlocProvider<DashboardBloc>(
      create: (_) =>
          DashboardBloc(repository: sl<PublicStatsRepository>())..add(const DashboardStarted()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  void _reload(BuildContext context) =>
      context.read<DashboardBloc>().add(const DashboardStarted(forceRefresh: true));

  /// Completes once the reload settles so the refresh spinner tracks it.
  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<DashboardBloc>();
    _reload(context);
    await bloc.stream.firstWhere(
      (s) => s is! DashboardLoading && !(s is DashboardLoaded && s.reloading),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final busy = state is DashboardLoading ||
              (state is DashboardLoaded && state.reloading);
          return PageBody(
            onRefresh: () => _refresh(context),
            children: [
              PageHeader(
                title: loc.navDashboard,
                subtitle: loc.homeHeroEyebrow,
                icon: Icons.space_dashboard_outlined,
                actions: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
                    icon: const Icon(Icons.refresh),
                    onPressed: busy ? null : () => _reload(context),
                  ),
                ],
              ),
              if (state is DashboardLoaded && state.reloading)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.pageGutter),
                  child: const LinearProgressIndicator(minHeight: 2),
                ),
              switch (state) {
                DashboardInitial() || DashboardLoading() =>
                  const SkeletonLoader(lines: 4, height: 76),
                DashboardFailure(:final error) => InlineError(
                    message: _errorMessage(loc, error),
                    onRetry: () => _reload(context),
                  ),
                DashboardLoaded() => _LoadedView(state: state),
              },
            ],
          );
        },
      ),
    );
  }

  String _errorMessage(AppLocalizations loc, ApiException error) {
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
    final gutter = context.pageGutter;
    final subscription =
        '৳ ${NumberFormat.decimalPattern().format(stats.monthlySubscriptionTotal)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.ownStatus != null) ...[
          AppCard(
            title: loc.homeHeroApplicationReviewLabel,
            trailing: const StatusBadge(kind: StatusKind.pending),
            child: Text(
              loc.commonStatusPending,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        SectionTitle(loc.homeHeroStatCardTitle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: ResponsiveGrid(
            minItemWidth: 220,
            maxColumns: 3,
            children: [
              StatTile(
                label: loc.commonStatusPending,
                value: '${stats.pendingCount}',
                icon: Icons.hourglass_top_rounded,
                accent: AppColors.goldStrong,
              ),
              StatTile(
                label: loc.commonStatusApproved,
                value: '${stats.approvedCount}',
                icon: Icons.verified_user_outlined,
              ),
              StatTile(
                label: loc.homeHeroMonthlySubscriptionLabel,
                value: subscription,
                icon: Icons.payments_outlined,
                accent: AppColors.emerald600,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
      ],
    );
  }
}
