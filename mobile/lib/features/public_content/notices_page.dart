import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import 'data/content_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import 'bloc/notices_bloc.dart';

/// Port of Angular `notices-page.component.*`: published notices feed with
/// loading skeleton, empty state and error-with-retry. Category chips are
/// omitted (the config-list service they come from is not ported yet).
class NoticesPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const NoticesPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
              if (state.notices.isEmpty) {
                return EmptyState(message: loc.noticesEmpty);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.notices.length,
                itemBuilder: (context, index) {
                  final notice = state.notices[index];
                  final dateRaw = notice.publishAt ?? notice.createdAt;
                  final date = DateTime.tryParse(dateRaw);
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.go('/notices/${notice.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (date != null)
                              Text(
                                DateFormat.yMMMd().format(date),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              notice.title,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notice.body.length > 160
                                  ? '${notice.body.substring(0, 160)}…'
                                  : notice.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
