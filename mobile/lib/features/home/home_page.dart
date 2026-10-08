import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/di/injector.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import '../dashboard/data/public_stats_repository.dart';
import 'bloc/stats_bloc.dart';

/// Public landing page, port of Angular `home.component.*` (hero, apply/login
/// actions, live public stats, how-it-works steps) plus the registration
/// header idiom (bismillah line, org name, logo) and notices/events teasers.
class HomePage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const HomePage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StatsBloc>(
      create: (_) =>
          StatsBloc(repository: sl<PublicStatsRepository>())..add(const StatsLoadRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<StatsBloc>();
    bloc.add(const StatsLoadRequested());
    await bloc.stream.firstWhere((s) => s is! StatsLoading);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final gutter = context.pageGutter;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              const _Hero(),
              SafeArea(
                top: false,
                child: ResponsiveCenter(
                  padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HomeSection(title: loc.homeHeroStatCardTitle, child: const _StatsGrid()),
                      const _HomeSection(child: _StepsGrid()),
                      _HomeSection(
                        title: '${loc.noticesTitle} · ${loc.eventsTitle}',
                        child: const _TeaserGrid(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section spacing with an optional muted heading (content is already inside
/// the page gutter, so [SectionTitle]'s own gutter is not wanted here).
class _HomeSection extends StatelessWidget {
  const _HomeSection({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Emerald gradient hero with logo, org name, headline and primary actions.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald900, AppColors.emerald700, AppColors.emerald600],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg * 1.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 32),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrgHeader(),
              SizedBox(height: 28),
              _HeroCopy(),
              SizedBox(height: 24),
              _HeroActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrgHeader extends StatelessWidget {
  const _OrgHeader();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          textAlign: TextAlign.center,
          textDirection: ui.TextDirection.rtl,
          style: theme.textTheme.titleMedium?.copyWith(color: AppColors.amber200),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Semantics(
              label: loc.registrationHeaderLogoAlt,
              image: true,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.amber200, width: 2),
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.registrationHeaderOrgName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  Text(
                    loc.registrationHeaderOrgSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final compact = context.isCompact;
    final align = compact ? TextAlign.start : TextAlign.center;
    return Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.amber200.withValues(alpha: 0.6)),
          ),
          child: Text(
            loc.homeHeroEyebrow,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.amber50,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          loc.homeHeroTitle.replaceAll('<br />', '\n'),
          textAlign: align,
          style: (compact ? theme.textTheme.headlineSmall : theme.textTheme.headlineMedium)
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.25),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.formMaxWidth),
          child: Text(
            loc.homeHeroSubtitle,
            textAlign: align,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
          ),
        ),
      ],
    );
  }
}

/// Gold primary + white outlined secondary, readable on the emerald hero.
class _HeroActions extends StatelessWidget {
  const _HeroActions();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final compact = context.isCompact;
    final heroTheme = theme.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: theme.filledButtonTheme.style?.copyWith(
          backgroundColor: const WidgetStatePropertyAll(AppColors.gold),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: theme.outlinedButtonTheme.style?.copyWith(
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          side: WidgetStatePropertyAll(
            BorderSide(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );
    final buttons = [
      AppButton(
        label: loc.homeHeroApplyButton,
        icon: Icons.description_outlined,
        expanded: compact,
        onPressed: () => context.go('/register'),
      ),
      AppButton(
        label: loc.homeHeroLoginButton,
        icon: Icons.login,
        variant: AppButtonVariant.secondary,
        expanded: compact,
        onPressed: () => context.go('/login'),
      ),
    ];
    return Theme(
      data: heroTheme,
      child: compact
          ? Column(children: [buttons[0], const SizedBox(height: 12), buttons[1]])
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: buttons,
            ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<StatsBloc, StatsState>(
      builder: (context, state) {
        final stats = state is StatsLoaded ? state.stats : null;
        String count(int Function() pick) => stats == null ? '—' : pick().toString();
        final subscription = stats == null
            ? '—'
            : '৳ ${NumberFormat.decimalPattern().format(stats.monthlySubscriptionTotal)}';
        return ResponsiveGrid(
          minItemWidth: 220,
          maxColumns: 3,
          children: [
            StatTile(
              label: loc.homeHeroApplicationReviewLabel,
              value: count(() => stats!.pendingCount),
              icon: Icons.hourglass_top_rounded,
              accent: AppColors.goldStrong,
            ),
            StatTile(
              label: loc.homeHeroMemberIdLabel,
              value: count(() => stats!.approvedCount),
              icon: Icons.verified_user_outlined,
            ),
            StatTile(
              label: loc.homeHeroMonthlySubscriptionLabel,
              value: subscription,
              icon: Icons.payments_outlined,
              accent: AppColors.emerald600,
            ),
          ],
        );
      },
    );
  }
}

class _StepsGrid extends StatelessWidget {
  const _StepsGrid();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ResponsiveGrid(
      minItemWidth: 260,
      maxColumns: 3,
      children: [
        _StepCard(
          number: 1,
          icon: Icons.description_outlined,
          title: loc.homeStepsApplyTitle,
          description: loc.homeStepsApplyDesc,
        ),
        _StepCard(
          number: 2,
          icon: Icons.fact_check_outlined,
          title: loc.homeStepsReviewTitle,
          description: loc.homeStepsReviewDesc,
        ),
        _StepCard(
          number: 3,
          icon: Icons.badge_outlined,
          title: loc.homeStepsMemberIdTitle,
          description: loc.homeStepsMemberIdDesc,
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final int number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeaserGrid extends StatelessWidget {
  const _TeaserGrid();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ResponsiveGrid(
      minItemWidth: 300,
      maxColumns: 2,
      children: [
        _TeaserCard(
          icon: Icons.campaign_outlined,
          title: loc.noticesTitle,
          subtitle: loc.noticesSubtitle,
          onTap: () => context.go('/notices'),
        ),
        _TeaserCard(
          icon: Icons.event_outlined,
          title: loc.eventsTitle,
          subtitle: loc.eventsSubtitle,
          onTap: () => context.go('/events'),
        ),
      ],
    );
  }
}

class _TeaserCard extends StatelessWidget {
  const _TeaserCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
