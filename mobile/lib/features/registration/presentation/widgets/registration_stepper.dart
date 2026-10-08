import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Horizontal 6-step wizard header (mirrors the Angular .stepper nav).
/// Clicking a previous/current circle navigates; forward jumps are validated
/// by the bloc (StepGoToRequested).
class RegistrationStepper extends StatelessWidget {
  const RegistrationStepper({
    super.key,
    required this.currentStep,
    required this.onStepTapped,
  });

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
    return Semantics(
      label: l10n.registrationHeaderStepperAriaLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var step = 1; step <= 6; step++) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => onStepTapped(step),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentStep == step
                            ? Theme.of(context).colorScheme.primary
                            : (currentStep > step
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                                : Theme.of(context).colorScheme.surfaceContainerHighest),
                        border: Border.all(color: Theme.of(context).colorScheme.primary),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$step',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: currentStep >= step ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 56,
                    child: Text(
                      shortLabelKeys[step]!(l10n),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: currentStep == step ? Theme.of(context).colorScheme.primary : AppColors.gray500,
                      ),
                    ),
                  ),
                ],
              ),
              if (step < 6)
                Container(
                  width: 24,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: currentStep > step ? Theme.of(context).colorScheme.primary : AppColors.gray200,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
