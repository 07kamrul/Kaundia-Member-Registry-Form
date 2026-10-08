import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/di/injector.dart';
import '../../core/layout/responsive.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'data/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import 'bloc/events_bloc.dart';
import 'domain/content_entities.dart';
import 'public_content_widgets.dart';

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
      create: (_) => EventsBloc(repository: ContentRepository(apiClient: sl<ApiClient>()))
        ..add(const EventsRequested()),
      child: Scaffold(
        appBar: publicAppBar(
          context,
          title: loc.eventsTitle,
          fallbackRoute: '/events',
          fallbackTooltip: loc.eventsBackToList,
        ),
        body: BlocBuilder<EventsBloc, EventsState>(
          builder: (context, state) {
            if (state is EventsFailure) {
              return InlineError(
                message: loc.eventsErrorsLoadFailed,
                onRetry: () => context.read<EventsBloc>().add(const EventsRequested()),
              );
            }
            if (state is! EventsLoaded) {
              return const PageBody(
                maxWidth: Breakpoints.formMaxWidth,
                children: [SizedBox(height: 16), SkeletonLoader(lines: 1, height: 280)],
              );
            }
            final matches = state.events.where((row) => row.id == eventId);
            if (matches.isEmpty) {
              return EmptyState(
                message: loc.eventsNotFound,
                icon: Icons.event_busy_outlined,
                action: AppButton(
                  label: loc.eventsBackToList,
                  icon: Icons.arrow_back,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.go('/events'),
                ),
              );
            }
            return PageBody(
              maxWidth: Breakpoints.formMaxWidth,
              children: [
                BackToListLink(label: loc.eventsBackToList, route: '/events'),
                _EventArticle(event: matches.first),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EventArticle extends StatelessWidget {
  const _EventArticle({required this.event});

  final EventItem event;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final start = DateTime.tryParse(event.startAt)?.toLocal();
    final end = event.endAt == null ? null : DateTime.tryParse(event.endAt!)?.toLocal();
    final isPast = start != null && start.isBefore(DateTime.now());
    final df = DateFormat('EEEE, MMM d, y, h:mm a');
    final location = event.location ?? '';
    final description = event.description ?? '';

    return AppCard(
      padding: EdgeInsets.all(context.responsive<double>(compact: 16, medium: 24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (start != null) ...[
                DateBadge(date: start, muted: isPast),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPast) ...[
                      StatusBadge(kind: StatusKind.neutral, label: loc.eventsPast),
                      const SizedBox(height: 8),
                    ],
                    SelectableText(
                      event.title,
                      style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (start != null || end != null || location.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  if (start != null)
                    DetailRow(
                      label: loc.eventsDetailStartsAt,
                      value: df.format(start),
                      icon: Icons.play_circle_outline,
                    ),
                  if (end != null)
                    DetailRow(
                      label: loc.eventsDetailEndsAt,
                      value: df.format(end),
                      icon: Icons.stop_circle_outlined,
                    ),
                  if (location.isNotEmpty)
                    DetailRow(
                      label: loc.eventsDetailLocation,
                      value: location,
                      icon: Icons.place_outlined,
                    ),
                ],
              ),
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            SelectableText(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
          ],
        ],
      ),
    );
  }
}
