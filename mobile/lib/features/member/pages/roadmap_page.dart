import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/roadmap_repository.dart';
import '../domain/roadmap_entities.dart';
import '../presentation/bloc/roadmap_bloc.dart';
import '../presentation/widgets/member_ui.dart';
import '../presentation/widgets/roadmap_slides.dart';

/// Port of Angular RoadmapComponent (+ slides): overall progress, status
/// filters, per-timeframe collapsible item sections and PDF export. The
/// projector slides are adapted to a full-screen page-turn dialog.
class RoadmapPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const RoadmapPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoadmapBloc(repository: RoadmapRepository(apiClient: sl<ApiClient>()))
          ..add(const RoadmapLoadRequested()),
      child: const _RoadmapView(),
    );
  }
}

class _RoadmapView extends StatelessWidget {
  const _RoadmapView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocConsumer<RoadmapBloc, RoadmapState>(
        listener: (context, state) {
          final path = state.pdfSavedPath;
          if (path != null) {
            OpenFilex.open(path);
            context.read<RoadmapBloc>().add(const RoadmapPdfSavedPathCleared());
          }
        },
        builder: (context, state) {
          final bloc = context.read<RoadmapBloc>();
          return switch (state.status) {
            RoadmapPageStatus.loading when state.roadmap == null => const SkeletonLoader(lines: 8),
            RoadmapPageStatus.failure => InlineError(
                message: loc.memberRoadmapLoadError,
                onRetry: () => bloc.add(const RoadmapLoadRequested()),
              ),
            _ => _loaded(context, state, loc, bloc),
          };
        },
      ),
    );
  }

  Widget _loaded(
    BuildContext context,
    RoadmapState state,
    AppLocalizations loc,
    RoadmapBloc bloc,
  ) {
    final roadmap = state.roadmap;
    final header = PageHeader(
      title: loc.memberRoadmapTitle,
      subtitle: loc.memberRoadmapSubtitle,
      icon: Icons.map_outlined,
    );
    Future<void> refresh() => reloadAndWait<RoadmapState>(
          bloc,
          () => bloc.add(const RoadmapLoadRequested()),
          (s) => s.status != RoadmapPageStatus.loading,
        );
    if (roadmap == null || roadmap.timeframes.isEmpty) {
      return PageBody(
        onRefresh: refresh,
        children: [header, EmptyState(message: loc.memberRoadmapEmpty, icon: Icons.map_outlined)],
      );
    }
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final current = roadmap.timeframes[state.currentIndex];
    return PageBody(
      onRefresh: refresh,
      children: [
        header,
        _OverallCard(roadmap: roadmap, currentName: isBn ? current.nameBn : current.nameEn),
        _Actions(state: state, bloc: bloc, roadmap: roadmap, isBn: isBn),
        if (state.exportError)
          NoticeBanner(
            tone: NoticeTone.error,
            message: loc.memberRoadmapExportError,
            action: TextButton(
              onPressed: () => bloc.add(const RoadmapPdfDownloadRequested()),
              child: Text(loc.commonRetry),
            ),
          ),
        _Filters(state: state, bloc: bloc),
        Gutter(
          vertical: 6,
          child: ResponsiveGrid(
            minItemWidth: 420,
            maxColumns: 2,
            children: [
              for (final tf in roadmap.timeframes)
                _TimeframeCard(
                  timeframe: tf,
                  state: state,
                  isBn: isBn,
                  isCurrent: identical(tf, current),
                ),
            ],
          ),
        ),
        if ((roadmap.lastUpdated ?? '').isNotEmpty)
          Gutter(
            vertical: 8,
            child: Text(
              loc.memberRoadmapLastUpdated(roadmap.lastUpdated!),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.roadmap, required this.currentName});

  final Roadmap roadmap;
  final String currentName;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final totals = roadmap.totals;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(loc.memberRoadmapOverallProgress, style: theme.textTheme.titleMedium),
              ),
              Text(
                '${totals.percent.round()}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (totals.percent.toDouble() / 100).clamp(0, 1),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            loc.memberRoadmapWhereSummary(totals.done, totals.total),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Chip(
            avatar: const Icon(Icons.place_outlined, size: 18, color: AppColors.goldStrong),
            label: Text(
              '${loc.memberRoadmapWeAreHere}: $currentName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: theme.colorScheme.secondaryContainer,
            side: BorderSide.none,
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.bloc,
    required this.roadmap,
    required this.isBn,
  });

  final RoadmapState state;
  final RoadmapBloc bloc;
  final Roadmap roadmap;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Gutter(
      vertical: 6,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          AppButton(
            label: state.pdfDownloading ? loc.commonLoading : loc.memberRoadmapActionsPdf,
            variant: AppButtonVariant.secondary,
            icon: Icons.picture_as_pdf_outlined,
            loading: state.pdfDownloading,
            onPressed: () => bloc.add(const RoadmapPdfDownloadRequested()),
          ),
          AppButton(
            label: loc.memberRoadmapActionsSlides,
            variant: AppButtonVariant.secondary,
            icon: Icons.slideshow,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => RoadmapSlides(roadmap: roadmap, isBn: isBn),
            )),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.bloc});

  final RoadmapState state;
  final RoadmapBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final gutter = context.pageGutter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 4),
      child: Row(
        children: [
          for (final f in RoadmapStatusFilter.values) ...[
            if (f != RoadmapStatusFilter.values.first) const SizedBox(width: 8),
            ChoiceChip(
              label: Text('${_filterLabel(f, loc)} (${state.filterCount(f)})'),
              selected: state.filter == f,
              onSelected: (_) => bloc.add(RoadmapFilterChanged(f)),
            ),
          ],
        ],
      ),
    );
  }

  String _filterLabel(RoadmapStatusFilter f, AppLocalizations loc) => switch (f) {
        RoadmapStatusFilter.all => loc.memberRoadmapFilterAll,
        RoadmapStatusFilter.inProgress => loc.memberRoadmapFilterInProgress,
        RoadmapStatusFilter.done => loc.memberRoadmapFilterDone,
        RoadmapStatusFilter.planned => loc.memberRoadmapFilterPlanned,
      };
}

class _TimeframeCard extends StatelessWidget {
  const _TimeframeCard({
    required this.timeframe,
    required this.state,
    required this.isBn,
    required this.isCurrent,
  });

  final RoadmapTimeframe timeframe;
  final RoadmapState state;
  final bool isBn;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final visible = timeframe.items.where((i) => state.itemMatches(i.status)).toList();
    final progress = timeframe.progress;
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(isBn ? timeframe.nameBn : timeframe.nameEn, style: theme.textTheme.titleMedium),
              if (isCurrent) StatusBadge(kind: StatusKind.pending, label: loc.memberRoadmapFocusNow),
            ],
          ),
          Text(isBn ? timeframe.windowBn : timeframe.windowEn, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progress.percent.toDouble() / 100).clamp(0, 1),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.memberRoadmapProgressShort(progress.done, progress.total, progress.percent.round()),
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 20),
          if (visible.isEmpty)
            Text(
              loc.memberRoadmapEmptyFiltered,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            for (final item in visible) _ItemRow(item: item),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final RoadmapItem item;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (IconData icon, Color color, StatusKind kind, String label) = switch (item.status) {
      RoadmapStatus.done => (Icons.check_circle, theme.colorScheme.primary, StatusKind.approved, loc.memberRoadmapStatusDone),
      RoadmapStatus.inProgress => (Icons.autorenew, AppColors.gold, StatusKind.pending, loc.memberRoadmapStatusInProgress),
      _ => (Icons.radio_button_unchecked, theme.colorScheme.onSurfaceVariant, StatusKind.neutral, loc.memberRoadmapStatusPlanned),
    };
    final hasTarget = (item.targetDate ?? '').isNotEmpty;
    final hasNote = (item.note ?? '').isNotEmpty;
    final completed = item.status == RoadmapStatus.done && item.completedAt != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.text, style: theme.textTheme.bodyMedium),
                if (hasNote) Text(item.note!, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(kind: kind, label: label),
                    if (hasTarget)
                      MetaChip(icon: Icons.flag_outlined, text: loc.memberRoadmapTarget(item.targetDate!)),
                    if (completed)
                      MetaChip(icon: Icons.event_available, text: loc.memberRoadmapCompletedOn(item.completedAt!)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
