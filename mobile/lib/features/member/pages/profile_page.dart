import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/enums/enums.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/member_repository.dart';
import '../domain/member_entities.dart';
import '../presentation/bloc/profile_bloc.dart';
import '../presentation/widgets/member_ui.dart';
import '../presentation/widgets/profile_edit_view.dart';
import '../presentation/widgets/profile_sections.dart';

/// Port of Angular ProfileComponent: view mode (personal/contact/address/
/// payment/property/nominee sections), edit mode with the re-approval warning
/// for core fields, photo upload, and the property change-request list.
class ProfilePage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const ProfilePage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc(repository: MemberRepository(apiClient: sl<ApiClient>()))
        ..add(const ProfileLoaded()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) => _listen(context, state, loc),
        builder: (context, state) {
          final bloc = context.read<ProfileBloc>();
          return switch (state.status) {
            ProfileStatus.loading when state.profile == null => const SkeletonLoader(lines: 8),
            ProfileStatus.failure => InlineError(
                message: loc.memberProfileLoadError,
                onRetry: () => bloc.add(const ProfileLoaded()),
              ),
            _ when state.profile == null => const SkeletonLoader(lines: 8),
            _ => _loaded(context, state, loc, bloc),
          };
        },
      ),
    );
  }

  void _listen(BuildContext context, ProfileState state, AppLocalizations loc) {
    final success = state.requestSuccess;
    if (success != null) {
      showAppToast(
        context,
        switch (success) {
          'withdrawnSuccess' => loc.memberPropertyRequestsWithdrawnSuccess,
          'successSent' => loc.memberPropertyRequestsSuccessSent,
          _ => success,
        },
      );
      context.read<ProfileBloc>().add(const ProfileMessageCleared());
    }
    final actionError = state.requestActionError;
    if (actionError != null) {
      showAppToast(
        context,
        switch (actionError) {
          'withdrawFailed' => loc.memberPropertyRequestsErrorsWithdrawFailed,
          'submitFailed' => loc.memberPropertyRequestsErrorsSubmitFailed,
          _ => actionError,
        },
        error: true,
      );
    }
    if (state.saveError != null) {
      showAppToast(
        context,
        state.saveError == 'saveError' ? loc.memberProfileSaveError : state.saveError!,
        error: true,
      );
    }
    if (state.photoUploadError != null) {
      showAppToast(context, loc.memberProfilePhotoUploadError, error: true);
    }
  }

  Widget _loaded(
    BuildContext context,
    ProfileState state,
    AppLocalizations loc,
    ProfileBloc bloc,
  ) {
    final profile = state.profile!;
    if (state.editing) {
      return ProfileEditView(profile: profile, state: state);
    }
    return PageBody(
      onRefresh: () => reloadAndWait<ProfileState>(
        bloc,
        () => bloc.add(const ProfileLoaded()),
        (s) => s.status != ProfileStatus.loading,
      ),
      children: [
        PageHeader(title: loc.memberProfileTitle, icon: Icons.account_circle_outlined),
        if (profile.memberStatus == MemberStatus.pending)
          NoticeBanner(
            tone: NoticeTone.warning,
            icon: Icons.hourglass_top,
            message: loc.memberProfilePendingReviewNotice,
          ),
        ProfileIdentityCard(
          profile: profile,
          status: _statusBadge(profile.memberStatus, loc),
          onEdit: () => bloc.add(const ProfileEditStarted()),
        ),
        Gutter(
          vertical: 6,
          child: ResponsiveGrid(
            minItemWidth: 420,
            maxColumns: 2,
            children: _infoCards(context, profile, loc),
          ),
        ),
        ProfilePropertiesCard(profile: profile),
        ProfileRequestsCard(
          requests: state.requests,
          loading: state.requestsLoading,
          hasError: state.requestsError != null,
          onRetry: () => bloc.add(const ProfileRequestsLoaded()),
          onAdd: () => context.go('/property-requests/new'),
          onWithdraw: (r) => _confirmWithdraw(context, r, loc),
          actionLabel: (a) => requestActionLabel(a, loc),
          statusLabel: (s) => requestStatusLabel(s, loc),
        ),
      ],
    );
  }

  List<Widget> _infoCards(BuildContext context, MemberProfile p, AppLocalizations loc) {
    final urgent = [p.urgentContactName, p.urgentContactRelation, p.urgentContactMobile, p.urgentContactAddress]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return [
      ProfileInfoCard(
        title: loc.memberProfilePersonalInfoTitle,
        icon: Icons.person_outline,
        fields: [
          ProfileField(loc.memberProfileNameLabel, p.fullName, Icons.person_outline),
          ProfileField(loc.memberProfileFatherOrHusbandLabel, p.fatherOrHusband, Icons.family_restroom_outlined),
          ProfileField(loc.memberProfileMotherLabel, p.mother, Icons.family_restroom_outlined),
          ProfileField(loc.memberProfileDobLabel, p.dob, Icons.cake_outlined),
          ProfileField(loc.memberProfileNationalityLabel, p.nationality, Icons.flag_outlined),
          ProfileField(loc.memberProfileNidLabel, p.nid, Icons.badge_outlined),
          ProfileField(loc.memberProfileOccupationLabel, p.occupation, Icons.work_outline),
          ProfileField(loc.memberProfileGenderLabel, p.gender, Icons.wc_outlined),
        ],
      ),
      ProfileInfoCard(
        title: loc.memberProfileContactTitle,
        icon: Icons.contact_phone_outlined,
        fields: [
          ProfileField(loc.memberProfileMobileLabel, p.mobile, Icons.phone_outlined),
          ProfileField(loc.memberProfileEmailLabel, p.email, Icons.email_outlined),
          ProfileField(
            loc.memberProfileAddressLabel,
            _address(p.permanentHouse, p.permanentRoad, p.permanentPostOffice, p.permanentUpazila,
                p.permanentDistrict, p.permanentDivision),
            Icons.home_outlined,
          ),
          if (p.hasCurrentAddress())
            ProfileField(
              loc.memberProfileCurrentAddressLabel,
              _address(p.currentHouse, p.currentRoad, p.currentPostOffice, p.currentUpazila,
                  p.currentDistrict, p.currentDivision),
              Icons.location_on_outlined,
            ),
          ProfileField(loc.memberProfileUrgentContactTitle, urgent, Icons.contact_emergency_outlined),
        ],
      ),
      ProfileInfoCard(
        title: loc.memberProfilePaymentTitle,
        icon: Icons.receipt_long_outlined,
        fields: [
          ProfileField(loc.memberProfileAdmissionFeeLabel, p.admissionFee, Icons.payments_outlined),
          ProfileField(loc.memberProfileSubscriptionLabel, p.subscription, Icons.calendar_month_outlined),
          ProfileField(loc.memberProfileReceiptNoLabel, p.receiptNo, Icons.receipt_outlined),
          ProfileField(loc.memberProfilePaymentMethodLabel, p.paymentMethod, Icons.account_balance_wallet_outlined),
          ProfileField(loc.memberProfileSubmissionDateLabel, p.submissionDate, Icons.event_outlined),
        ],
        footer: [
          if (p.receiptPhotoUrl.isNotEmpty)
            ProfileFileButton(label: loc.memberProfileReceiptPhotoLabel, url: p.receiptPhotoUrl),
        ],
      ),
      if (p.nominees.isNotEmpty)
        ProfileInfoCard(
          title: loc.memberProfileNomineesTitle,
          icon: Icons.diversity_3_outlined,
          fields: [
            for (final n in p.nominees)
              ProfileField('${n.name} (${n.relation})', n.mobile, Icons.person_pin_outlined),
          ],
        ),
    ];
  }

  String _address(String? house, String? road, String? postOffice, String? upazila,
      String? district, String? division) {
    return [house, road, postOffice, upazila, district, division]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  Future<void> _confirmWithdraw(
    BuildContext context,
    MemberPropertyRequest request,
    AppLocalizations loc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.undo, color: Theme.of(ctx).colorScheme.error),
        title: Text(loc.memberPropertyRequestsWithdrawModalTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(loc.memberPropertyRequestsWithdrawModalMessage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.memberPropertyRequestsWithdrawModalConfirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ProfileBloc>().add(ProfileRequestWithdrawn(request.id));
    }
  }
}

String requestActionLabel(PropertyRequestAction action, AppLocalizations loc) =>
    switch (action) {
      PropertyRequestAction.add => loc.memberPropertyRequestsActionsAdd,
      PropertyRequestAction.edit => loc.memberPropertyRequestsActionsEdit,
      PropertyRequestAction.delete => loc.memberPropertyRequestsActionsDelete,
      PropertyRequestAction.unknown => action.name,
    };

String requestStatusLabel(PropertyRequestStatus status, AppLocalizations loc) =>
    switch (status) {
      PropertyRequestStatus.pending => loc.memberPropertyRequestsStatusLabelsPending,
      PropertyRequestStatus.approved =>
        loc.memberPropertyRequestsStatusLabelsApproved,
      PropertyRequestStatus.cancelled =>
        loc.memberPropertyRequestsStatusLabelsCancelled,
      PropertyRequestStatus.unknown => status.name,
    };

Widget _statusBadge(MemberStatus status, AppLocalizations loc) {
  final (kind, label) = switch (status) {
    MemberStatus.approved => (StatusKind.approved, loc.memberProfileStatusApproved),
    MemberStatus.rejected => (StatusKind.rejected, loc.memberProfileStatusRejected),
    _ => (StatusKind.pending, loc.memberProfileStatusPending),
  };
  return StatusBadge(kind: kind, label: label);
}
