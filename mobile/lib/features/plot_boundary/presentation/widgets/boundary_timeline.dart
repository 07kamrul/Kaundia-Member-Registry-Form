import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/plot_boundary_entities.dart';

/// Review progress of an own boundary: submitted → under review →
/// approved / rejected (Angular `.status-timeline`).
class BoundaryTimeline extends StatelessWidget {
  const BoundaryTimeline({super.key, required this.boundary});

  final PlotBoundary boundary;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final status = boundary.status;
    final isPending = status == BoundaryStatus.pendingReview;
    final isRejected = status == BoundaryStatus.rejected;
    final steps = [
      _Step(loc.plotMapTimelineSubmitted, _StepState.done),
      _Step(
        loc.plotMapTimelineUnderReview,
        isPending ? _StepState.active : _StepState.done,
      ),
      if (isRejected)
        _Step(loc.plotMapStatusRejected, _StepState.rejected)
      else
        _Step(
          loc.plotMapTimelineApproved,
          boundary.liveStatus == BoundaryStatus.approved
              ? _StepState.done
              : _StepState.todo,
        ),
    ];
    return Semantics(
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(child: _StepView(step: steps[i])),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: SizedBox(
                  width: 16,
                  child: Divider(
                    height: 2,
                    thickness: 2,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

enum _StepState { done, active, todo, rejected }

class _Step {
  const _Step(this.label, this.state);
  final String label;
  final _StepState state;
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (step.state) {
      _StepState.done => (Icons.check_circle, const Color(0xFF2E7D32)),
      _StepState.active => (Icons.timelapse, const Color(0xFFC9861E)),
      _StepState.todo => (Icons.radio_button_unchecked, scheme.outline),
      _StepState.rejected => (Icons.cancel, scheme.error),
    };
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          step.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            color: step.state == _StepState.todo
                ? scheme.onSurfaceVariant
                : scheme.onSurface,
            fontWeight: step.state == _StepState.active
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
