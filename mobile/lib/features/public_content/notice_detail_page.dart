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

/// Port of Angular `notice-detail-page.component.*`: there is no single-row
/// public endpoint, so the detail view reads the same list feed and picks its
/// row out of it. Category chips are omitted (config lists not ported yet).
class NoticeDetailPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const NoticeDetailPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final noticeId = id ?? '';
    return BlocProvider(
      create: (_) =>
          NoticesBloc(repository: ContentRepository(apiClient: sl<ApiClient>()))
            ..add(const NoticesRequested()),
      child: Scaffold(
        appBar: AppBar(title: Text(loc.noticesTitle)),
        body: BlocBuilder<NoticesBloc, NoticesState>(
          builder: (context, state) {
            if (state is NoticesLoading) {
              return const SkeletonLoader(lines: 5);
            }
            if (state is NoticesFailure) {
              return InlineError(
                message: loc.noticesErrorsLoadFailed,
                onRetry: () =>
                    context.read<NoticesBloc>().add(const NoticesRequested()),
              );
            }
            if (state is NoticesLoaded) {
              final matches =
                  state.notices.where((row) => row.id == noticeId).toList();
              final notice = matches.isEmpty ? null : matches.first;
              if (notice == null) {
                return EmptyState(
                  message: loc.noticesNotFound,
                  action: AppButton(
                    label: loc.noticesBackToList,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.go('/notices'),
                  ),
                );
              }
              final date = DateTime.tryParse(notice.publishAt ?? notice.createdAt);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/notices'),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(loc.noticesBackToList),
                  ),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (date != null)
                            Text(
                              DateFormat.yMMMMd().format(date),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            notice.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            notice.body,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(height: 1.7),
                          ),
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
}
