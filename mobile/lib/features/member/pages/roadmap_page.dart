import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/roadmap_repository.dart';
import '../domain/roadmap_entities.dart';
import '../presentation/bloc/roadmap_bloc.dart';

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
            RoadmapPageStatus.loading => const SkeletonLoader(lines: 8),
            RoadmapPageStatus.failure => InlineError(
                message: loc.memberRoadmapLoadError,
                onRetry: () => bloc.add(const RoadmapLoadRequested()),
              ),
            RoadmapPageStatus.loaded => _loaded(context, state, loc, bloc),
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
    if (roadmap == null || roadmap.timeframes.isEmpty) {
      return ListView(children: [
        PageHeader(title: loc.memberRoadmapTitle),
        EmptyState(message: loc.memberRoadmapEmpty, icon: Icons.map_outlined),
      ]);
    }
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PageHeader(title: loc.memberRoadmapTitle),
        // Overall progress bar.
        AppCard(
          title: loc.memberRoadmapOverallProgress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (roadmap.totals.percent.toDouble() / 100).clamp(0, 1),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 6),
              Text(loc.memberRoadmapProgressShort(
                  roadmap.totals.done, roadmap.totals.total, roadmap.totals.percent.round())),
              const SizedBox(height: 4),
              Text(
                '${loc.memberRoadmapWeAreHere}: ${_tfName(roadmap.timeframes[state.currentIndex], isBn)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // Actions: PDF + slides.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: state.pdfDownloading
                      ? loc.commonLoading
                      : loc.memberRoadmapActionsPdf,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: state.pdfDownloading ? null : () => bloc.add(const RoadmapPdfDownloadRequested()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: loc.memberRoadmapActionsSlides,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.slideshow,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _RoadmapSlides(roadmap: roadmap, isBn: isBn),
                  )),
                ),
              ),
            ],
          ),
        ),
        if (state.exportError)
          InlineError(message: loc.memberRoadmapExportError,
              onRetry: () => bloc.add(const RoadmapPdfDownloadRequested())),
        // Status filters.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Wrap(
            spacing: 8,
            children: [
              for (final f in RoadmapStatusFilter.values)
                ChoiceChip(
                  label: Text('${_filterLabel(f, loc)} (${state.filterCount(f)})'),
                  selected: state.filter == f,
                  onSelected: (_) => bloc.add(RoadmapFilterChanged(f)),
                ),
            ],
          ),
        ),
        for (final tf in roadmap.timeframes)
          _TimeframeCard(timeframe: tf, state: state, bloc: bloc, isBn: isBn),
      ],
    );
  }

  String _tfName(RoadmapTimeframe tf, bool isBn) => isBn ? tf.nameBn : tf.nameEn;

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
    required this.bloc,
    required this.isBn,
  });

  final RoadmapTimeframe timeframe;
  final RoadmapState state;
  final RoadmapBloc bloc;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final visible = timeframe.items.where((i) => state.itemMatches(i.status)).toList();
    return AppCard(
      title: isBn ? timeframe.nameBn : timeframe.nameEn,
      trailing: Text(loc.memberRoadmapProgressShort(
          timeframe.progress.done, timeframe.progress.total, timeframe.progress.percent.round())),
      child: visible.isEmpty
          ? Text(loc.memberRoadmapEmptyFiltered)
          : Column(
              children: [
                for (final item in visible)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      switch (item.status) {
                        RoadmapStatus.done => Icons.check_circle,
                        RoadmapStatus.inProgress => Icons.autorenew,
                        _ => Icons.radio_button_unchecked,
                      },
                      color: switch (item.status) {
                        RoadmapStatus.done => Colors.green.shade700,
                        RoadmapStatus.inProgress => Theme.of(context).colorScheme.primary,
                        _ => Theme.of(context).colorScheme.outline,
                      },
                    ),
                    title: Text(item.text),
                    subtitle: Text([
                      if (item.targetDate != null && item.targetDate!.isNotEmpty)
                        '${loc.memberRoadmapTarget}: ${item.targetDate}',
                      if (item.note != null && item.note!.isNotEmpty) item.note!,
                    ].join(' · ')),
                    trailing: item.status == RoadmapStatus.done && item.completedAt != null
                        ? Text(loc.memberRoadmapCompletedOn(item.completedAt!),
                            style: Theme.of(context).textTheme.bodySmall)
                        : StatusBadge(
                            kind: switch (item.status) {
                              RoadmapStatus.done => StatusKind.approved,
                              RoadmapStatus.inProgress => StatusKind.pending,
                              _ => StatusKind.neutral,
                            },
                            label: switch (item.status) {
                              RoadmapStatus.done => loc.memberRoadmapStatusDone,
                              RoadmapStatus.inProgress =>
                                loc.memberRoadmapStatusInProgress,
                              _ => loc.memberRoadmapStatusPlanned,
                            },
                          ),
                  ),
              ],
            ),
    );
  }
}

/// Mobile adaptation of RoadmapSlidesComponent: swipe through an overview and
/// one page per timeframe.
class _RoadmapSlides extends StatefulWidget {
  const _RoadmapSlides({required this.roadmap, required this.isBn});

  final Roadmap roadmap;
  final bool isBn;

  @override
  State<_RoadmapSlides> createState() => _RoadmapSlidesState();
}

class _RoadmapSlidesState extends State<_RoadmapSlides> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final slides = <Widget>[
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(loc.memberRoadmapOverallProgress,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(loc.memberRoadmapProgressShort(
                widget.roadmap.totals.done,
                widget.roadmap.totals.total,
                widget.roadmap.totals.percent.round())),
          ],
        ),
      ),
      for (final tf in widget.roadmap.timeframes)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isBnName(tf), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(isBnWindow(tf)),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    for (final item in tf.items.take(6))
                      ListTile(
                        dense: true,
                        leading: Icon(
                          item.status == RoadmapStatus.done
                              ? Icons.check_circle
                              : item.status == RoadmapStatus.inProgress
                                  ? Icons.autorenew
                                  : Icons.radio_button_unchecked,
                        ),
                        title: Text(item.text),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.memberRoadmapTitle),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
      body: PageView(
        controller: _controller,
        children: slides,
      ),
    );
  }

  String isBnName(RoadmapTimeframe tf) => widget.isBn ? tf.nameBn : tf.nameEn;
  String isBnWindow(RoadmapTimeframe tf) => widget.isBn ? tf.windowBn : tf.windowEn;
}
