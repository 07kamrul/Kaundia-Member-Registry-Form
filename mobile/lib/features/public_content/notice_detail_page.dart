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
import 'bloc/notices_bloc.dart';
import 'domain/content_entities.dart';
import 'public_content_widgets.dart';

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
        appBar: publicAppBar(
          context,
          title: loc.noticesTitle,
          fallbackRoute: '/notices',
          fallbackTooltip: loc.noticesBackToList,
        ),
        body: BlocBuilder<NoticesBloc, NoticesState>(
          builder: (context, state) {
            if (state is NoticesFailure) {
              return InlineError(
                message: loc.noticesErrorsLoadFailed,
                onRetry: () => context.read<NoticesBloc>().add(const NoticesRequested()),
              );
            }
            if (state is! NoticesLoaded) {
              return const PageBody(
                maxWidth: Breakpoints.formMaxWidth,
                children: [SizedBox(height: 16), SkeletonLoader(lines: 1, height: 280)],
              );
            }
            final matches = state.notices.where((row) => row.id == noticeId);
            if (matches.isEmpty) {
              return EmptyState(
                message: loc.noticesNotFound,
                icon: Icons.search_off_rounded,
                action: AppButton(
                  label: loc.noticesBackToList,
                  icon: Icons.arrow_back,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.go('/notices'),
                ),
              );
            }
            return PageBody(
              maxWidth: Breakpoints.formMaxWidth,
              children: [
                BackToListLink(label: loc.noticesBackToList, route: '/notices'),
                _NoticeArticle(notice: matches.first),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NoticeArticle extends StatelessWidget {
  const _NoticeArticle({required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(notice.publishAt ?? notice.createdAt);
    return AppCard(
      padding: EdgeInsets.all(context.responsive<double>(compact: 16, medium: 24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date != null) ...[
            MetaLine(
              icon: Icons.calendar_today_outlined,
              text: DateFormat.yMMMMd().format(date.toLocal()),
            ),
            const SizedBox(height: 8),
          ],
          SelectableText(
            notice.title,
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          SelectableText(
            notice.body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}
