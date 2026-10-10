import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/dag_details_entities.dart';
import '../../domain/land_entities.dart';
import '../bloc/dag_info_cubit.dart';
import 'dag_info_tables.dart';
import 'owner_bottom_sheet.dart' show formatDigits;

const Color _gradientStart = Color(0xFF1F4FA8);
const Color _gradientEnd = Color(0xFF3B7DDD);
const Color _closeButtonFill = Color(0xFF212529);
const Color _footerButtonFill = Color(0xFF6C757D);
const double _sheetHeightFactor = 0.92;

/// Official-look dialog for a tapped BDS dag: fixed header, scrolling body,
/// fixed footer. Reads [DagInfoCubit] from the context.
class DagInfoSheet extends StatelessWidget {
  const DagInfoSheet({super.key, required this.dagNo});

  /// Dag number from the tapped feature; lets the header render instantly.
  final String dagNo;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    void close() => Navigator.of(context).maybePop();
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _Header(
            title: loc.dagInfoTitle(formatDigits(context, dagNo)),
            onClose: close,
          ),
          Expanded(
            child: BlocBuilder<DagInfoCubit, DagInfoState>(
              builder: (context, state) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _Body(dagNo: dagNo, state: state),
              ),
            ),
          ),
          _Footer(onClose: close),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_gradientStart, _gradientEnd]),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: loc.dagInfoCloseSemantics,
            excludeSemantics: true,
            child: GestureDetector(
              key: const Key('dag-info-close-x'),
              onTap: onClose,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _closeButtonFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70),
                ),
                child: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final dividerColor = Theme.of(context).dividerColor;
    return SafeArea(
      top: false,
      child: Container(
        decoration:
            BoxDecoration(border: Border(top: BorderSide(color: dividerColor))),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.centerRight,
        child: FilledButton(
          key: const Key('dag-info-close-button'),
          onPressed: onClose,
          style: FilledButton.styleFrom(
            backgroundColor: _footerButtonFill,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Text(loc.dagInfoClose),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.dagNo, required this.state});

  final String dagNo;
  final DagInfoState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      DagInfoLoading() => const _Skeleton(),
      DagInfoFailure(:final kind) => _Failure(kind: kind),
      DagInfoLoaded(:final details) => _Details(dagNo: dagNo, details: details),
      DagInfoEmpty(:final details) => _Details(dagNo: dagNo, details: details),
    };
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.dagNo, required this.details});

  final String dagNo;
  final DagDetails details;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final fetched = details.fetchedAt;
    final caption = loc.dagInfoSource(
      details.sourceName ?? 'settlement.gov.bd',
      fetched == null ? '—' : formatDigits(context, _isoDate(fetched)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DagInfoHeading(loc.dagInfoLandHeading),
        const SizedBox(height: 8),
        LandDetailsTable(details: details, dagNo: dagNo),
        const SizedBox(height: 20),
        DagInfoHeading(loc.dagInfoKhatianHeading),
        const SizedBox(height: 8),
        KhatianTable(khatians: details.khatians),
        const SizedBox(height: 12),
        Text(
          caption,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }

  static String _isoDate(DateTime d) {
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.kind});

  final DagInfoFailureKind kind;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final message = switch (kind) {
      DagInfoFailureKind.notFound => loc.dagInfoNotFound,
      DagInfoFailureKind.rateLimited => loc.dagInfoRateLimited,
      DagInfoFailureKind.other => loc.dagInfoFailure,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.error_outline,
              size: 36, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: loc.dagInfoRetrySemantics,
            excludeSemantics: true,
            child: OutlinedButton(
              key: const Key('dag-info-retry'),
              onPressed: context.read<DagInfoCubit>().retry,
              child: Text(loc.dagInfoRetry),
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    return Column(
      key: const Key('dag-info-skeleton'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar(140, 20),
        for (var i = 0; i < 4; i++) bar(double.infinity, 36),
        const SizedBox(height: 8),
        bar(120, 20),
        for (var i = 0; i < 3; i++) bar(double.infinity, 44),
      ],
    );
  }
}

/// Opens the official-look dag dialog for a tapped BDS [plot]. Returns when
/// the sheet is dismissed. Without a dag/sheet no request is made.
Future<void> showDagInfoSheet(
  BuildContext context, {
  required LandPlot plot,
  DagInfoCubit Function(String sheet, String dag)? createCubit,
}) {
  final dag = plot.displayDag;
  final sheet = plot.sheet ?? '';
  final height = MediaQuery.sizeOf(context).height * _sheetHeightFactor;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints.tightFor(height: height),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => BlocProvider(
      create: (_) => (createCubit?.call(sheet, dag) ??
          DagInfoCubit(sheet: sheet, dag: dag))
        ..load(),
      child: DagInfoSheet(dagNo: dag),
    ),
  );
}
