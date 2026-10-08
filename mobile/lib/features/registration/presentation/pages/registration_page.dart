import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/config_list_repository.dart';
import '../../data/fee_repository.dart';
import '../../data/geo_repository.dart';
import '../../data/registration_draft_service.dart';
import '../../data/registration_repository.dart';
import '../../domain/submission_error_mapper.dart';
import '../bloc/registration_bloc.dart';
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
  /// Below this window height the stepper scrolls with the form instead of
  /// staying pinned (landscape phones).
  static const double _pinnedStepperMinHeight = 560;

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navRegister),
        leading: context.canPop()
            ? null
            : IconButton(
                tooltip: l10n.authLoginBackToHome,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login, size: 18),
            label: Text(l10n.registrationHeaderLoginLink),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: BlocBuilder<RegistrationBloc, RegistrationState>(
        buildWhen: (p, c) => p.status != c.status,
        builder: (context, state) =>
            state.status == RegistrationStatus.loading ? const SizedBox.shrink() : const _NavBar(),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<RegistrationBloc, RegistrationState>(
            listenWhen: (prev, curr) =>
                prev.submitStatus != curr.submitStatus || prev.duplicateKind != curr.duplicateKind,
            listener: _onSubmitStateChanged,
          ),
          BlocListener<RegistrationBloc, RegistrationState>(
            listenWhen: (prev, curr) => prev.currentStep != curr.currentStep,
            listener: (_, __) => _scrollToTop(),
          ),
        ],
        child: BlocBuilder<RegistrationBloc, RegistrationState>(
          builder: (context, state) {
            if (state.status == RegistrationStatus.loading) {
              return const PageBody(
                maxWidth: Breakpoints.formMaxWidth,
                children: [SizedBox(height: 16), SkeletonLoader(lines: 6, height: 72)],
              );
            }
            return _buildForm(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, RegistrationState state) {
    final pinned = MediaQuery.sizeOf(context).height >= _pinnedStepperMinHeight;
    final gutter = context.pageGutter;
    final stepper = _StepperPanel(state: state);
    final scroll = SingleChildScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!pinned) stepper,
          ResponsiveCenter(
            maxWidth: Breakpoints.formMaxWidth,
            padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 24),
            child: _StepBody(state: state),
          ),
        ],
      ),
    );
    if (!pinned) return scroll;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [stepper, Expanded(child: scroll)],
    );
  }

  void _onSubmitStateChanged(BuildContext context, RegistrationState state) {
    if (state.submitStatus == SubmitStatus.duplicate && state.duplicateKind != null) {
      _showDuplicateDialog(context, state);
    }
    if (state.submitStatus == SubmitStatus.success) {
      _showSuccessDialog(context, state);
    }
  }

  void _showDuplicateDialog(BuildContext context, RegistrationState state) {
    final l10n = AppLocalizations.of(context);
    final approved = state.duplicateKind == DuplicateSubmissionKind.alreadyRegistered;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.info_outline, color: Theme.of(dialogContext).colorScheme.secondary),
        title: Text(l10n.registrationSubmitDuplicateTitle),
        content: Text(state.duplicateMessage.isNotEmpty
            ? state.duplicateMessage
            : (approved
                ? l10n.registrationSubmitDuplicateApproved
                : l10n.registrationSubmitDuplicatePending)),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              if (approved) {
                context.go('/login');
              }
            },
            child: Text(approved ? l10n.navLogin : l10n.registrationConfirmationOkButton),
          ),
        ],
      ),
    );
  }

  /// Non-dismissible confirmation; OK clears the draft and returns home.
  void _showSuccessDialog(BuildContext context, RegistrationState state) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 56),
        title: Text(l10n.registrationConfirmationTitle, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.registrationConfirmationMessage, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '${l10n.registrationConfirmationReferenceLabel} '),
                  TextSpan(
                    text: state.successId,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
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
}

/// Stepper + "draft saved" indicator on a surface strip.
class _StepperPanel extends StatelessWidget {
  const _StepperPanel({required this.state});

  final RegistrationState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gutter = context.pageGutter;
    final bloc = context.read<RegistrationBloc>();
    return Material(
      color: theme.colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
        ),
        child: ResponsiveCenter(
          maxWidth: Breakpoints.formMaxWidth,
          padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RegistrationStepper(
                currentStep: state.currentStep,
                onStepTapped: (s) => bloc.add(StepGoToRequested(s)),
              ),
              if (state.draftLastSaved != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_done_outlined,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.registrationDraftDraftSaved,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header (first step only), draft banner, the active step and error boxes.
class _StepBody extends StatelessWidget {
  const _StepBody({required this.state});

  final RegistrationState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final submitErrorMessages = [
      for (final item in state.submitErrors) submitItemMessage(l10n, item),
    ];
    final stepErrorMessages = [for (final e in state.stepErrors) regErrorMessage(l10n, e)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.currentStep == 1) const _Header(),
        if (state.draftRestored) const _DraftBanner(),
        _buildStep(state.currentStep),
        if (stepErrorMessages.isNotEmpty) RegErrorBox(messages: stepErrorMessages.take(8).toList()),
        if (submitErrorMessages.isNotEmpty) RegErrorBox(messages: submitErrorMessages),
      ],
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textAlign: TextAlign.center,
            textDirection: ui.TextDirection.rtl,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.registrationHeaderOrgName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.registrationHeaderOrgSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          Text(
            l10n.registrationHeaderOrgLocation,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.registrationHeaderFormBadge,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
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
  const _DraftBanner();

  Future<void> _confirmDiscard(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegistrationBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.registrationDraftDiscardDraft),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(RegistrationDraftDiscarded());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bloc = context.read<RegistrationBloc>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(Icons.history, color: theme.colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    l10n.registrationDraftDraftRestoredToast,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.commonClose,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => bloc.add(RegistrationDraftBannerDismissed()),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _confirmDiscard(context),
              label: Text(l10n.registrationDraftDiscardDraft),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky previous / next (or submit) bar at the bottom of the wizard.
class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gutter = context.pageGutter;
    final submitting = state.submitStatus == SubmitStatus.submitting;
    final busy = submitting ||
        state.feeStatus == FeeStatus.loading ||
        state.feeStatus == FeeStatus.error ||
        (state.currentStep == 4 && state.quoteStatus == QuoteStatus.loading);
    final isLast = state.currentStep >= RegistrationStepper.stepCount;

    final primary = isLast
        ? AppButton(
            label: submitting ? l10n.registrationNavSubmitting : l10n.registrationNavSubmit,
            icon: Icons.send_rounded,
            loading: submitting,
            expanded: true,
            onPressed: () => bloc.add(SubmitRequested()),
          )
        : AppButton(
            label: l10n.registrationNavNext,
            icon: Icons.arrow_forward_rounded,
            expanded: true,
            onPressed: busy ? null : () => bloc.add(StepNextRequested()),
          );

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: SafeArea(
        top: false,
        // heightFactor keeps the bar wrapped to its content height.
        child: Center(
          heightFactor: 1,
          child: Container(
            constraints: const BoxConstraints(maxWidth: Breakpoints.formMaxWidth),
            padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 10),
            child: Row(
              children: [
                Expanded(
                  child: state.currentStep > 1
                      ? AppButton(
                          label: l10n.registrationNavPrevious,
                          icon: Icons.arrow_back_rounded,
                          variant: AppButtonVariant.secondary,
                          expanded: true,
                          onPressed: submitting ? null : () => bloc.add(StepPrevRequested()),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                Expanded(child: primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
