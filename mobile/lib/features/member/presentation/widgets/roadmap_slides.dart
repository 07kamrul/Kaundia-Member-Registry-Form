import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/roadmap_entities.dart';

/// Items shown per timeframe slide (projector-friendly, mirrors the web).
const int _itemsPerSlide = 6;

/// Mobile adaptation of RoadmapSlidesComponent: swipe through an overview and
/// one page per timeframe, with explicit previous/next controls.
class RoadmapSlides extends StatefulWidget {
  const RoadmapSlides({super.key, required this.roadmap, required this.isBn});

  final Roadmap roadmap;
  final bool isBn;

  @override
  State<RoadmapSlides> createState() => _RoadmapSlidesState();
}

class _RoadmapSlidesState extends State<RoadmapSlides> {
  final _controller = PageController();
  int _page = 0;

  int get _count => widget.roadmap.timeframes.length + 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) => _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.memberRoadmapTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: loc.commonClose,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _OverviewSlide(roadmap: widget.roadmap),
                  for (final tf in widget.roadmap.timeframes)
                    _TimeframeSlide(timeframe: tf, isBn: widget.isBn),
                ],
              ),
            ),
            _SlideControls(
              page: _page,
              count: _count,
              onPrevious: _page > 0 ? () => _go(_page - 1) : null,
              onNext: _page < _count - 1 ? () => _go(_page + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewSlide extends StatelessWidget {
  const _OverviewSlide({required this.roadmap});

  final Roadmap roadmap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final totals = roadmap.totals;
    final percent = (totals.percent.toDouble() / 100).clamp(0.0, 1.0);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.memberRoadmapOverallProgress, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 12,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  Center(
                    child: Text(
                      '${totals.percent.round()}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.memberRoadmapProgressShort(totals.done, totals.total, totals.percent.round()),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeframeSlide extends StatelessWidget {
  const _TimeframeSlide({required this.timeframe, required this.isBn});

  final RoadmapTimeframe timeframe;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveCenter(
      maxWidth: Breakpoints.formMaxWidth,
      child: ListView(
        padding: EdgeInsets.all(context.pageGutter + 8),
        children: [
          Text(isBn ? timeframe.nameBn : timeframe.nameEn, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(isBn ? timeframe.windowBn : timeframe.windowEn, style: theme.textTheme.bodyMedium),
          const Divider(height: 32),
          for (final item in timeframe.items.take(_itemsPerSlide))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    switch (item.status) {
                      RoadmapStatus.done => Icons.check_circle,
                      RoadmapStatus.inProgress => Icons.autorenew,
                      _ => Icons.radio_button_unchecked,
                    },
                    color: item.status == RoadmapStatus.planned ||
                            item.status == RoadmapStatus.unknown
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.text, style: theme.textTheme.titleMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SlideControls extends StatelessWidget {
  const _SlideControls({
    required this.page,
    required this.count,
    this.onPrevious,
    this.onNext,
  });

  final int page;
  final int count;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          IconButton.outlined(
            tooltip: loc.memberRoadmapSlidesPrev,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == page ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == page ? scheme.primary : scheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
          IconButton.outlined(
            tooltip: loc.memberRoadmapSlidesNext,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
