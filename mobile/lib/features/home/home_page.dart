import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../dashboard/data/public_stats_repository.dart';
import 'bloc/stats_bloc.dart';

/// Public landing page, port of Angular `home.component.*` (hero, apply/login
/// actions, live public stats card, how-it-works steps) plus the registration
/// header idiom (bismillah line, org name, logo) and notices/events teasers.
class HomePage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const HomePage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Registration header idiom (Angular registration-page).
                    Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textAlign: TextAlign.center,
                      textDirection: ui.TextDirection.rtl,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.groups, size: 40, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.registrationHeaderOrgName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.registrationHeaderOrgSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),

                    // Hero.
                    Text(
                      (loc.homeHeroTitle).replaceAll('<br />', '\n'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.homeHeroSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: loc.homeHeroApplyButton,
                            icon: Icons.description_outlined,
                            onPressed: () => context.go('/register'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: loc.homeHeroLoginButton,
                            icon: Icons.person_outline,
                            variant: AppButtonVariant.ghost,
                            onPressed: () => context.go('/login'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Public stats card.
                    _StatsCard(),
                    const SizedBox(height: 24),

                    // How it works.
                    _FeatureCard(
                      icon: Icons.description_outlined,
                      title: loc.homeStepsApplyTitle,
                      description: loc.homeStepsApplyDesc,
                    ),
                    _FeatureCard(
                      icon: Icons.people_outline,
                      title: loc.homeStepsReviewTitle,
                      description: loc.homeStepsReviewDesc,
                    ),
                    _FeatureCard(
                      icon: Icons.badge_outlined,
                      title: loc.homeStepsMemberIdTitle,
                      description: loc.homeStepsMemberIdDesc,
                    ),
                    const SizedBox(height: 24),

                    // Notices & events teasers.
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
                    const SizedBox(height: 16),
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

class _StatsCard extends StatefulWidget {
  const _StatsCard();
  @override
  State<_StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<_StatsCard> {
  late final StatsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = StatsBloc(repository: sl<PublicStatsRepository>());
    _bloc.add(const StatsLoadRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.homeHeroStatCardTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BlocBuilder<StatsBloc, StatsState>(
              bloc: _bloc,
              builder: (context, state) {
                final stats = state is StatsLoaded ? state.stats : null;
                String value(int Function() pick) =>
                    stats == null ? '—' : pick().toString();
                return Column(
                  children: [
                    _statRow(loc.homeHeroApplicationReviewLabel,
                        value(() => stats!.pendingCount)),
                    _statRow(loc.homeHeroMemberIdLabel,
                        value(() => stats!.approvedCount)),
                    _statRow(
                        loc.homeHeroMonthlySubscriptionLabel,
                        stats == null
                            ? '—'
                            : '৳ ${NumberFormat.decimalPattern().format(stats.monthlySubscriptionTotal)}'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
