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

/// Port of Angular `notices-page.component.*`: published notices feed with
/// loading skeleton, empty state, error-with-retry and pull-to-refresh.
/// Category chips are omitted (the config-list service they come from is not
/// ported yet).
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
        appBar: publicAppBar(
          context,
          title: loc.noticesTitle,
          fallbackRoute: '/',
          fallbackTooltip: loc.authLoginBackToHome,
        ),
        body: BlocBuilder<NoticesBloc, NoticesState>(
          // A pull-to-refresh keeps the current list on screen while reloading.
          buildWhen: (prev, curr) => !(prev is NoticesLoaded && curr is NoticesLoading),
          builder: (context, state) => PageBody(
            onRefresh: () => _refresh(context),
            children: [
              PublicIntro(text: loc.noticesSubtitle, icon: Icons.campaign_outlined),
              const SizedBox(height: 8),
              _content(context, loc, state),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<NoticesBloc>();
    bloc.add(const NoticesRequested());
    await bloc.stream.firstWhere((s) => s is NoticesLoaded || s is NoticesFailure);
  }

  Widget _content(BuildContext context, AppLocalizations loc, NoticesState state) {
    return switch (state) {
      NoticesFailure() => InlineError(
          message: loc.noticesErrorsLoadFailed,
          onRetry: () => context.read<NoticesBloc>().add(const NoticesRequested()),
        ),
      NoticesLoaded(:final notices) when notices.isEmpty => EmptyState(
          message: loc.noticesEmpty,
          icon: Icons.campaign_outlined,
        ),
      NoticesLoaded(:final notices) => Padding(
          padding: EdgeInsets.symmetric(horizontal: context.pageGutter),
          child: ResponsiveGrid(
            minItemWidth: 340,
            maxColumns: 3,
            children: [for (final notice in notices) _NoticeCard(notice: notice)],
          ),
        ),
      _ => const SkeletonLoader(lines: 5, height: 96),
    };
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(notice.publishAt ?? notice.createdAt);
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: () => context.go('/notices/${notice.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date != null) ...[
            MetaLine(
              icon: Icons.calendar_today_outlined,
              text: DateFormat.yMMMd().format(date.toLocal()),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            notice.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            notice.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Icon(Icons.arrow_forward, size: 18, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
