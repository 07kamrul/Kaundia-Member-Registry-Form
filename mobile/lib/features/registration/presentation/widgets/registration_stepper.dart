import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// 6-step wizard header (mirrors the Angular .stepper nav). Dots are joined by
/// connector lines that stretch to the available width; labels sit under each
/// dot when there is room, otherwise only the current step's label is shown.
/// Clicking a previous/current dot navigates; forward jumps are validated by
/// the bloc (StepGoToRequested).
class RegistrationStepper extends StatelessWidget {
  const RegistrationStepper({
    super.key,
    required this.currentStep,
    required this.onStepTapped,
  });

  static const int stepCount = 6;

  /// Per-step width needed to show every label under its dot.
  static const double _labelledStepWidth = 76;

  final int currentStep;
  final ValueChanged<int> onStepTapped;

  static final shortLabelKeys = <int, String Function(AppLocalizations)>{
    1: (l) => l.registrationStepShortLabelsMemberInfo,
    2: (l) => l.registrationStepShortLabelsProperty,
    3: (l) => l.registrationStepShortLabelsNominee,
    4: (l) => l.registrationStepShortLabelsPayment,
    5: (l) => l.registrationStepShortLabelsSignature,
    6: (l) => l.registrationStepShortLabelsReview,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      label: l10n.registrationHeaderStepperAriaLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showAllLabels = constraints.maxWidth / stepCount >= _labelledStepWidth;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var step = 1; step <= stepCount; step++)
                    Expanded(
                      child: _StepColumn(
                        step: step,
                        currentStep: currentStep,
                        label: shortLabelKeys[step]!(l10n),
                        showLabel: showAllLabels,
                        onTap: () => onStepTapped(step),
                      ),
                    ),
                ],
              ),
              if (!showAllLabels) ...[
                const SizedBox(height: 8),
                Text(
                  shortLabelKeys[currentStep]?.call(l10n) ?? '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StepColumn extends StatelessWidget {
  const _StepColumn({
    required this.step,
    required this.currentStep,
    required this.label,
    required this.showLabel,
    required this.onTap,
  });

  final int step;
  final int currentStep;
  final String label;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final idle = theme.colorScheme.outline;
    final isCurrent = step == currentStep;
    Widget connector(bool visible, bool done) => Expanded(
          child: Container(height: 2, color: visible ? (done ? primary : idle) : null),
        );

    return Column(
      children: [
        Row(
          children: [
            connector(step > 1, currentStep >= step),
            _StepDot(step: step, currentStep: currentStep, label: label, onTap: onTap),
            connector(step < RegistrationStepper.stepCount, currentStep > step),
          ],
        ),
        if (showLabel) ...[
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isCurrent ? primary : theme.colorScheme.onSurfaceVariant,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.step,
    required this.currentStep,
    required this.label,
    required this.onTap,
  });

  final int step;
  final int currentStep;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isCurrent = step == currentStep;
    final isDone = step < currentStep;
    final fill = isCurrent
        ? primary
        : (isDone ? theme.colorScheme.primaryContainer : theme.colorScheme.surface);
    final ink = isCurrent
        ? theme.colorScheme.onPrimary
        : (isDone ? primary : theme.colorScheme.onSurfaceVariant);

    return Semantics(
      button: true,
      selected: isCurrent,
      label: '$step. $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(
                color: isCurrent || isDone ? primary : theme.colorScheme.outline,
                width: isCurrent ? 2 : 1.5,
              ),
              boxShadow: isCurrent
                  ? [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 8)]
                  : null,
            ),
            alignment: Alignment.center,
            child: isDone
                ? Icon(Icons.check_rounded, size: 18, color: ink)
                : Text(
                    '$step',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: ink, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}
