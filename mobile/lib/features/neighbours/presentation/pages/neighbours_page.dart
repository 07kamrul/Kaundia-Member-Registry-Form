import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/external_link_launcher.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../member/domain/finance_entities.dart' show toBanglaDigits;
import '../../../member/presentation/widgets/member_ui.dart';
import '../../domain/neighbour_entities.dart';
import '../../domain/neighbours_failure.dart';
import '../../domain/phone_links.dart';
import '../bloc/neighbours_bloc.dart';
import '../widgets/neighbour_owner_card.dart';

/// Neighbour plot-owner directory (প্রতিবেশী তথ্য).
class NeighboursPage extends StatelessWidget {
  const NeighboursPage({
    super.key,
    this.createBloc,
    this.launcher = const UrlLauncherExternalLinkLauncher(),
  });

  /// Test seam; defaults to a bloc wired to the live API.
  final NeighboursBloc Function()? createBloc;
  final ExternalLinkLauncher launcher;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (createBloc?.call() ?? NeighboursBloc())
        ..add(const NeighboursLoadRequested()),
      child: _NeighboursView(launcher: launcher),
    );
  }
}

class _NeighboursView extends StatelessWidget {
  const _NeighboursView({required this.launcher});

  final ExternalLinkLauncher launcher;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocBuilder<NeighboursBloc, NeighboursState>(
        builder: (context, state) {
          final bloc = context.read<NeighboursBloc>();
          final directory = state.directory;
          final loading = state.status == NeighboursStatus.loading;
          if (loading && directory == null) {
            return const SkeletonLoader(lines: 6);
          }
          if (state.status == NeighboursStatus.failure) {
            return InlineError(
              message: _failureMessage(state.failureKind, loc),
              onRetry: () => bloc.add(const NeighboursLoadRequested()),
            );
          }
          if (directory == null) return const SizedBox.shrink();
          return PageBody(
            onRefresh: () => reloadAndWait<NeighboursState>(
              bloc,
              () => bloc.add(const NeighboursLoadRequested()),
              (s) => s.status != NeighboursStatus.loading,
            ),
            children: [
              if (loading) const LinearProgressIndicator(),
              PageHeader(
                title: loc.memberNeighboursTitle,
                subtitle: loc.memberNeighboursSubtitle(
                    _digits(context, '${directory.plotLimit}')),
                icon: Icons.holiday_village_outlined,
              ),
              NoticeBanner(
                message: loc.memberNeighboursPrivacyNote,
                icon: Icons.privacy_tip_outlined,
              ),
              ..._content(context, state, directory, loc),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    NeighboursState state,
    NeighbourDirectory directory,
    AppLocalizations loc,
  ) {
    if (directory.properties.isEmpty) {
      return [
        EmptyState(
          message: loc.memberNeighboursNoProperties,
          icon: Icons.home_work_outlined,
        ),
      ];
    }
    final group = state.selectedGroup;
    return [
      _DagTypeToggle(selected: state.dagType ?? directory.dagType),
      if (directory.properties.length > 1)
        _PropertySelector(
          groups: directory.properties,
          selectedId: group?.own.propertyId,
          dagType: directory.dagType,
        ),
      if (group != null) ..._group(context, group, directory.dagType, loc),
    ];
  }

  List<Widget> _group(
    BuildContext context,
    NeighbourGroup group,
    DagType dagType,
    AppLocalizations loc,
  ) {
    final own = group.own;
    final dag = own.dagFor(dagType);
    final land = own.landQuantity;
    final header = [
      '${loc.memberNeighboursOwnDag}: ${dag == null ? '—' : _digits(context, dag)}',
      if (land != null) loc.memberNeighboursLandUnit(_digits(context, land)),
    ].join(' · ');
    return [
      SectionTitle(header),
      if (!own.hasDag)
        NoticeBanner(
          tone: NoticeTone.warning,
          message: loc.memberNeighboursNoDag(_dagLabel(dagType, loc)),
        )
      else if (!group.hasOwners)
        EmptyState(
          message: loc.memberNeighboursEmptyState,
          icon: Icons.people_outline,
          action: Text(
            loc.memberNeighboursEmptyHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        )
      else
        Gutter(
          child: ResponsiveGrid(
            minItemWidth: 320,
            maxColumns: 2,
            children: [
              for (final owner in group.owners)
                NeighbourOwnerCard(
                  owner: owner,
                  digits: (t) => _digits(context, t),
                  onCall: () => _open(
                    context,
                    telUri(owner.mobile),
                    loc.memberNeighboursDialerUnavailable,
                  ),
                  onWhatsApp: () => _open(
                    context,
                    whatsAppUri(owner.mobile),
                    loc.memberNeighboursWhatsappUnavailable,
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  Future<void> _open(BuildContext context, Uri? uri, String failure) async {
    final opened = uri != null && await launcher.open(uri);
    if (!opened && context.mounted) showAppToast(context, failure, error: true);
  }
}

String _digits(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'bn'
        ? toBanglaDigits(text)
        : text;

String _dagLabel(DagType type, AppLocalizations loc) => switch (type) {
      DagType.rs => loc.memberNeighboursDagTypeRs,
      DagType.cs => loc.memberNeighboursDagTypeCs,
    };

String _failureMessage(NeighboursFailureKind? kind, AppLocalizations loc) =>
    switch (kind) {
      NeighboursFailureKind.network => loc.commonNetworkError,
      NeighboursFailureKind.rateLimited => loc.memberNeighboursRateLimited,
      NeighboursFailureKind.approvedOnly => loc.memberNeighboursApprovedOnly,
      NeighboursFailureKind.other || null => loc.memberNeighboursLoadError,
    };

class _DagTypeToggle extends StatelessWidget {
  const _DagTypeToggle({required this.selected});

  final DagType selected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Gutter(
      vertical: 8,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(loc.memberNeighboursDagTypeLabel,
              style: Theme.of(context).textTheme.labelLarge),
          SegmentedButton<DagType>(
            showSelectedIcon: false,
            segments: [
              for (final t in DagType.values)
                ButtonSegment(value: t, label: Text(_dagLabel(t, loc))),
            ],
            selected: {selected},
            onSelectionChanged: (s) => context
                .read<NeighboursBloc>()
                .add(NeighboursDagTypeChanged(s.first)),
          ),
        ],
      ),
    );
  }
}

class _PropertySelector extends StatelessWidget {
  const _PropertySelector({
    required this.groups,
    required this.selectedId,
    required this.dagType,
  });

  final List<NeighbourGroup> groups;
  final String? selectedId;
  final DagType dagType;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final gutter = context.pageGutter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 4),
      child: Row(
        children: [
          for (final g in groups) ...[
            if (g != groups.first) const SizedBox(width: 8),
            ChoiceChip(
              label: Text(
                  '${loc.memberNeighboursOwnDag} ${_digits(context, g.own.dagFor(dagType) ?? '—')}'),
              selected: g.own.propertyId == selectedId,
              onSelected: (_) => context
                  .read<NeighboursBloc>()
                  .add(NeighboursPropertySelected(g.own.propertyId)),
            ),
          ],
        ],
      ),
    );
  }
}
