import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/plot_boundary_entities.dart';
import '../bloc/my_boundaries_cubit.dart';
import 'boundary_status_labels.dart';
import 'boundary_timeline.dart';
import 'owner_bottom_sheet.dart' show formatDigits;

/// What the member chose in the draw panel; the page navigates accordingly.
sealed class DrawPanelResult {
  const DrawPanelResult();
}

final class DrawNewBoundary extends DrawPanelResult {
  const DrawNewBoundary(this.propertyId);
  final String propertyId;
}

final class EditBoundary extends DrawPanelResult {
  const EditBoundary(this.boundary);
  final PlotBoundary boundary;
}

/// Opens the draw panel. [createCubit] is a test seam.
Future<DrawPanelResult?> showDrawPanelSheet(
  BuildContext context, {
  MyBoundariesCubit Function()? createCubit,
}) {
  return showModalBottomSheet<DrawPanelResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    builder: (_) => BlocProvider(
      create: (_) => (createCubit?.call() ?? MyBoundariesCubit())..load(),
      child: const DrawPanelSheet(),
    ),
  );
}

class DrawPanelSheet extends StatelessWidget {
  const DrawPanelSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: BlocConsumer<MyBoundariesCubit, MyBoundariesState>(
        listenWhen: (a, b) => !a.withdrawFailed && b.withdrawFailed,
        listener: (context, _) =>
            showAppToast(context, loc.plotMapDrawErrorsGeneric, error: true),
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.plotMapDrawTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: loc.commonClose,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(child: _Body(state: state)),
            ],
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final MyBoundariesState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<MyBoundariesCubit>();
    switch (state.status) {
      case MyBoundariesStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(20),
          child: SkeletonLoader(lines: 3),
        );
      case MyBoundariesStatus.failure:
        return Padding(
          padding: const EdgeInsets.all(20),
          child: InlineError(
            message: loc.plotMapDrawLoadError,
            onRetry: cubit.load,
          ),
        );
      case MyBoundariesStatus.ready:
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            _PickSection(state: state),
            if (state.boundaries.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                loc.plotMapDrawMyBoundaries,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final boundary in state.boundaries)
                _BoundaryCard(
                  boundary: boundary,
                  isWithdrawing: state.withdrawingId == boundary.id,
                ),
            ],
          ],
        );
    }
  }
}

class _PickSection extends StatelessWidget {
  const _PickSection({required this.state});

  final MyBoundariesState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final available = state.availableProperties;
    if (available.isEmpty) {
      return Text(
        loc.plotMapDrawNoProperties,
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    final cubit = context.read<MyBoundariesCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(loc.plotMapDrawPickHint, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: state.selectedPropertyId,
          onChanged: (id) {
            if (id != null) cubit.selectProperty(id);
          },
          child: Column(
            children: [
              for (final p in available)
                _PropertyOption(
                  property: p,
                  selected: state.selectedPropertyId == p.propertyId,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: loc.plotMapDrawStart,
          icon: Icons.edit_outlined,
          expanded: true,
          onPressed: state.selectedPropertyId == null
              ? null
              : () => Navigator.of(context)
                  .pop(DrawNewBoundary(state.selectedPropertyId!)),
        ),
      ],
    );
  }
}

class _PropertyOption extends StatelessWidget {
  const _PropertyOption({required this.property, required this.selected});

  final OwnProperty property;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    String d(String? v) =>
        v == null || v.isEmpty ? '—' : formatDigits(context, v);
    final quantity = property.landQuantity;
    final label = '${loc.boundaryRsDag} ${d(property.rsDag)} / '
        '${loc.boundaryCsDag} ${d(property.csDag)}'
        '${quantity == null ? '' : ' · ${d(quantity)} ${loc.plotMapDetailsShotangsho}'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: RadioListTile<String>(
          value: property.propertyId,
          title: Text(label),
          dense: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _BoundaryCard extends StatelessWidget {
  const _BoundaryCard({required this.boundary, required this.isWithdrawing});

  final PlotBoundary boundary;
  final bool isWithdrawing;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<MyBoundariesCubit>();
    String d(String? v) =>
        v == null || v.isEmpty ? '—' : formatDigits(context, v);
    final dags = [boundary.rsDag, boundary.csDag]
        .whereType<String>()
        .map(d)
        .join(' / ');
    final note = boundary.reviewNote;
    final isRejected = boundary.status == BoundaryStatus.rejected;
    final isPending = boundary.status == BoundaryStatus.pendingReview;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(
                  kind: boundaryStatusKind(boundary.status),
                  label: boundaryStatusLabel(loc, boundary.status),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dags.isEmpty ? '#${boundary.propertyId}' : 'দাগ $dags',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BoundaryTimeline(boundary: boundary),
            if (isPending)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  loc.plotMapTimelinePendingHint,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            if (isRejected && note != null && note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${loc.plotMapTimelineRejectionNote}: $note',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  label: loc.plotMapDrawEdit,
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: isWithdrawing
                      ? null
                      : () => Navigator.of(context)
                          .pop(EditBoundary(boundary)),
                ),
                if (boundary.hasPending)
                  AppButton(
                    label: loc.plotMapDrawWithdraw,
                    variant: AppButtonVariant.danger,
                    loading: isWithdrawing,
                    onPressed: () async {
                      final confirmed = await confirmAction(
                        context,
                        title: loc.plotMapDrawWithdrawTitle,
                        message: loc.plotMapDrawWithdrawMessage,
                        confirmLabel: loc.plotMapDrawWithdraw,
                        destructive: true,
                      );
                      if (confirmed) await cubit.withdraw(boundary.id);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Yes/no dialog returning a plain bool (the shared `AppDialog.confirm`
/// returns `Future<void>`, so callers cannot read the answer).
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final loc = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(loc.commonCancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
