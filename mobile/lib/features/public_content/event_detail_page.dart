import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import 'data/content_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import 'bloc/content_bloc.dart';

/// Port of Angular `event-detail-page.component.*`: no single-row public read,
/// so the detail view picks its row out of the events feed. Shows a "past"
/// badge, start/end/location rows and the description. Category chips are
/// omitted (config lists not ported yet).
class EventDetailPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const EventDetailPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final eventId = id ?? '';
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
              final matches =
                  state.events.where((row) => row.id == eventId).toList();
              final event = matches.isEmpty ? null : matches.first;
              if (event == null) {
                return EmptyState(
                  message: loc.eventsNotFound,
                  action: AppButton(
                    label: loc.eventsBackToList,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.go('/events'),
                  ),
                );
              }
              final start = DateTime.tryParse(event.startAt);
              final end = event.endAt == null ? null : DateTime.tryParse(event.endAt!);
              final isPast = start != null && start.isBefore(DateTime.now());
              final df = DateFormat('EEEE, MMM d, y, h:mm a');

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/events'),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(loc.eventsBackToList),
                  ),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (isPast)
                                StatusBadge(kind: StatusKind.neutral, label: loc.eventsPast),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                if (start != null)
                                  _detailRow(context, loc.eventsDetailStartsAt, df.format(start)),
                                if (end != null)
                                  _detailRow(context, loc.eventsDetailEndsAt, df.format(end)),
                                if ((event.location ?? '').isNotEmpty)
                                  _detailRow(context, loc.eventsDetailLocation, event.location!),
                              ],
                            ),
                          ),
                          if ((event.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              event.description!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(height: 1.7),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
