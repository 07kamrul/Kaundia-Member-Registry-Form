import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/di/injector.dart';
import '../../core/layout/responsive.dart';
import '../../core/network/api_client.dart';
import 'data/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import 'bloc/events_bloc.dart';
import 'domain/content_entities.dart';
import 'public_content_widgets.dart';

/// Port of Angular `events-page.component.*`: upcoming + past sections split
/// off the single events feed (server order preserved), with loading skeleton,
/// empty states, error-with-retry and pull-to-refresh. Category chips are
/// omitted (config lists not ported yet).
class EventsPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const EventsPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) =>
          EventsBloc(repository: ContentRepository(apiClient: sl<ApiClient>()))
            ..add(const EventsRequested()),
      child: Scaffold(
        appBar: publicAppBar(
          context,
          title: loc.eventsTitle,
          fallbackRoute: '/',
          fallbackTooltip: loc.authLoginBackToHome,
        ),
        body: BlocBuilder<EventsBloc, EventsState>(
          // A pull-to-refresh keeps the current sections on screen while reloading.
          buildWhen: (prev, curr) => !(prev is EventsLoaded && curr is EventsLoading),
          builder: (context, state) => PageBody(
            onRefresh: () => _refresh(context),
            children: [
              PublicIntro(text: loc.eventsSubtitle, icon: Icons.event_outlined),
              ..._content(context, loc, state),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<EventsBloc>();
    bloc.add(const EventsRequested());
    await bloc.stream.firstWhere((s) => s is EventsLoaded || s is EventsFailure);
  }

  List<Widget> _content(BuildContext context, AppLocalizations loc, EventsState state) {
    if (state is EventsFailure) {
      return [
        InlineError(
          message: loc.eventsErrorsLoadFailed,
          onRetry: () => context.read<EventsBloc>().add(const EventsRequested()),
        ),
      ];
    }
    if (state is! EventsLoaded) {
      return const [SizedBox(height: 8), SkeletonLoader(lines: 5, height: 88)];
    }
    final upcoming = state.upcoming;
    final past = state.past;
    return [
      _SectionHeader(title: loc.eventsUpcoming, count: upcoming.length),
      _EventSection(events: upcoming, past: false, emptyText: loc.eventsNoUpcoming),
      const SizedBox(height: 8),
      _SectionHeader(title: loc.eventsPast, count: past.length),
      _EventSection(events: past, past: true, emptyText: loc.eventsNoPast),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SectionTitle(
      title,
      trailing: count == 0 ? null : StatusBadge(kind: StatusKind.neutral, label: '$count'),
    );
  }
}

class _EventSection extends StatelessWidget {
  const _EventSection({required this.events, required this.past, required this.emptyText});

  final List<EventItem> events;
  final bool past;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (events.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            Icon(Icons.event_busy_outlined, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(emptyText, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageGutter),
      child: ResponsiveGrid(
        minItemWidth: 340,
        maxColumns: 3,
        children: [for (final event in events) _EventCard(event: event, past: past)],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.past});

  final EventItem event;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = DateTime.tryParse(event.startAt)?.toLocal();
    final location = event.location ?? '';
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: () => context.go('/events/${event.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (start != null) ...[
            DateBadge(date: start, muted: past),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: past ? theme.colorScheme.onSurfaceVariant : null,
                  ),
                ),
                const SizedBox(height: 6),
                if (start != null)
                  MetaLine(
                    icon: Icons.schedule_outlined,
                    text: past
                        ? DateFormat.yMMMd().format(start)
                        : DateFormat('EEE, MMM d, y · h:mm a').format(start),
                  ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  MetaLine(icon: Icons.place_outlined, text: location),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
