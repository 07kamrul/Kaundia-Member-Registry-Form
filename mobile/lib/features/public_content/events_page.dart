import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import 'data/content_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import 'bloc/events_bloc.dart';
import 'domain/content_entities.dart';

/// Port of Angular `events-page.component.*`: upcoming + past sections split
/// off the single events feed (server order preserved), with loading skeleton,
/// empty states and error-with-retry. Category chips are omitted (config lists
/// not ported yet).
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
        appBar: AppBar(title: Text(loc.eventsTitle)),
        body: BlocBuilder<EventsBloc, EventsState>(
          builder: (context, state) {
            if (state is EventsLoading) {
              return const SkeletonLoader(lines: 5);
            }
            if (state is EventsFailure) {
              return InlineError(
                message: loc.eventsErrorsLoadFailed,
                onRetry: () =>
                    context.read<EventsBloc>().add(const EventsRequested()),
              );
            }
            if (state is EventsLoaded) {
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _sectionTitle(context, loc.eventsUpcoming),
                  if (state.upcoming.isEmpty)
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(loc.eventsNoUpcoming),
                      ),
                    )
                  else
                    ...state.upcoming.map((event) => _EventCard(event: event, past: false)),
                  const SizedBox(height: 16),
                  _sectionTitle(context, loc.eventsPast),
                  if (state.past.isEmpty)
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(loc.eventsNoPast),
                      ),
                    )
                  else
                    ...state.past.map((event) => _EventCard(event: event, past: true)),
                  const SizedBox(height: 8),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
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
    final start = DateTime.tryParse(event.startAt);
    return Opacity(
      opacity: past ? 0.75 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/events/${event.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (start != null)
                  Text(
                    past
                        ? DateFormat.yMMMd().format(start)
                        : DateFormat('EEEE, MMM d, y, h:mm a').format(start),
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(height: 4),
                Text(event.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if ((event.location ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      event.location!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
