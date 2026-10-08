import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/config_list_repository.dart';
import '../../data/fee_repository.dart';
import '../../data/geo_repository.dart';
import '../../data/registration_draft_service.dart';
import '../../data/registration_repository.dart';
import '../../domain/submission_error_mapper.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart';
import '../bloc/registration_state.dart';
import '../widgets/contact_step.dart';
import '../widgets/declaration_step.dart';
import '../widgets/member_info_step.dart';
import '../widgets/payment_step.dart';
import '../widgets/property_step.dart';
import '../widgets/registration_inputs.dart';
import '../widgets/registration_l10n.dart';
import '../widgets/registration_stepper.dart';
import '../widgets/review_step.dart';

/// Public 6-step registration wizard (registration-page.component).
class RegistrationPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const RegistrationPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegistrationBloc(
        registrationRepository: RegistrationRepository(apiClient: sl<ApiClient>()),
        feeRepository: FeeRepository(apiClient: sl()),
        geoRepository: GeoRepository(apiClient: sl()),
        configListRepository: ConfigListRepository(apiClient: sl()),
        draftService: RegistrationDraftService(preferences: sl()),
      )..add(RegistrationStarted()),
      child: const _RegistrationView(),
    );
  }
}

class _RegistrationView extends StatefulWidget {
  const _RegistrationView();

  @override
  State<_RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<_RegistrationView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: BlocConsumer<RegistrationBloc, RegistrationState>(
        listenWhen: (prev, curr) =>
            prev.submitStatus != curr.submitStatus || prev.duplicateKind != curr.duplicateKind,
        listener: (context, state) {
          if (state.submitStatus == SubmitStatus.duplicate && state.duplicateKind != null) {
            final approved = state.duplicateKind == DuplicateSubmissionKind.alreadyRegistered;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.registrationSubmitDuplicateTitle),
                content: Text(state.duplicateMessage.isNotEmpty
                    ? state.duplicateMessage
                    : (approved
                        ? l10n.registrationSubmitDuplicateApproved
                        : l10n.registrationSubmitDuplicatePending)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                      if (approved) {
                        context.go('/login');
                      }
                    },
                    child: Text(
                        approved ? l10n.navLogin : l10n.registrationConfirmationOkButton),
                  ),
                ],
              ),
            );
          }
          if (state.submitStatus == SubmitStatus.success) {
            // Non-dismissible confirmation; OK clears the draft and returns home.
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 12),
                    Text(l10n.registrationConfirmationTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(l10n.registrationConfirmationMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '${l10n.registrationConfirmationReferenceLabel} '),
                        TextSpan(
                          text: state.successId,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                      context.read<RegistrationBloc>().add(SubmitSuccessAcknowledged());
                      context.go('/');
                    },
                    child: Text(l10n.registrationConfirmationOkButton),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == RegistrationStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final bloc = context.read<RegistrationBloc>();
          final busy = state.submitStatus == SubmitStatus.submitting ||
              state.feeStatus == FeeStatus.loading ||
              state.feeStatus == FeeStatus.error ||
              (state.currentStep == 4 && state.quoteStatus == QuoteStatus.loading);

          final submitErrorMessages = [for (final item in state.submitErrors) submitItemMessage(l10n, item)];
          final stepErrorMessages = [for (final e in state.stepErrors) regErrorMessage(l10n, e)];

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(),
                        if (state.draftRestored)
                          _DraftBanner(state: state),
                        RegistrationStepper(
                          currentStep: state.currentStep,
                          onStepTapped: (s) => bloc.add(StepGoToRequested(s)),
                        ),
                        if (state.draftLastSaved != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              l10n.registrationDraftDraftSaved,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 12),
                        _buildStep(state.currentStep),
                        if (stepErrorMessages.isNotEmpty)
                          RegErrorBox(messages: stepErrorMessages.take(8).toList()),
                        if (submitErrorMessages.isNotEmpty)
                          RegErrorBox(messages: submitErrorMessages),
                        const SizedBox(height: 16),
                        _NavRow(busy: busy),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(int step) => switch (step) {
        1 => const MemberInfoStep(),
        2 => const PropertyStep(),
        3 => const ContactStep(),
        4 => const PaymentStep(),
        5 => const DeclarationStep(),
        _ => const ReviewStep(),
      };
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            l10n.registrationHeaderOrgName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(l10n.registrationHeaderOrgSubtitle, style: Theme.of(context).textTheme.bodyMedium),
          Text(l10n.registrationHeaderOrgLocation, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              l10n.registrationHeaderFormBadge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Previous incomplete form restored" banner with discard action.
class _DraftBanner extends StatelessWidget {
  const _DraftBanner({required this.state});

  final RegistrationState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegistrationBloc>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text(l10n.registrationDraftDraftRestoredToast)),
          TextButton(
            onPressed: () => bloc.add(RegistrationDraftDiscarded()),
            child: Text(l10n.registrationDraftDiscardDraft),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => bloc.add(RegistrationDraftBannerDismissed()),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final submitting = state.submitStatus == SubmitStatus.submitting;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (state.currentStep > 1)
          AppButton(
            label: l10n.registrationNavPrevious,
            variant: AppButtonVariant.secondary,
            onPressed: submitting ? null : () => bloc.add(StepPrevRequested()),
          )
        else
          const SizedBox.shrink(),
        if (state.currentStep < 6)
          AppButton(
            label: l10n.registrationNavNext,
            onPressed: busy ? null : () => bloc.add(StepNextRequested()),
          )
        else
          AppButton(
            label: submitting ? l10n.registrationNavSubmitting : l10n.registrationNavSubmit,
            onPressed: submitting ? null : () => bloc.add(SubmitRequested()),
          ),
      ],
    );
  }
}
