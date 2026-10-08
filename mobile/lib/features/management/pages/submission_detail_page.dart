import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/enums/enums.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/bloc_actions.dart';
import '../presentation/bloc/submission_detail_bloc.dart';
import '../presentation/widgets/management_widgets.dart';
import '../presentation/widgets/submission_detail_widgets.dart';
import 'submissions_list_page.dart';

/// Full submission review (Angular submission-detail): every section of the
/// application, attachment previews, and approve/reject in review mode.
class SubmissionDetailPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const SubmissionDetailPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final id =
        this.id ?? (ModalRoute.of(context)?.settings.arguments as String?);
    if (id == null) {
      return EmptyState(
          message: loc.commonNoData, icon: Icons.assignment_late_outlined);
    }
    return BlocProvider(
      create: (_) => SubmissionDetailBloc(
        repository: AdminRepository(apiClient: sl<ApiClient>()),
        id: id,
      )..add(const SubmissionDetailLoadRequested()),
      child: const _SubmissionDetailView(),
    );
  }
}

class _SubmissionDetailView extends StatelessWidget {
  const _SubmissionDetailView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocConsumer<SubmissionDetailBloc, SubmissionDetailState>(
      listener: (context, state) {
        if (state.actionError != null) {
          showAppToast(context, describeApiError(context, state.actionError),
              error: true);
        }
      },
      builder: (context, state) {
        final bloc = context.read<SubmissionDetailBloc>();
        if (state.loading) {
          return const SkeletonLoader(lines: 8, height: 88);
        }
        if (state.error != null) {
          return InlineError(
              message: loc.adminSubmissionDetailErrorsLoadFailed,
              onRetry: () => bloc.add(const SubmissionDetailLoadRequested()));
        }
        final s = state.submission;
        if (s == null) {
          return EmptyState(
              message: loc.commonNoData, icon: Icons.assignment_late_outlined);
        }
        final body = PageBody(
          onRefresh: () => reloadAndWait(
              bloc, const SubmissionDetailLoadRequested(), (st) => st.loading),
          children: _content(context, loc, bloc, state, s),
        );
        if (s.status != SubmissionStatus.pending) return body;
        return Column(
          children: [
            Expanded(child: body),
            _ReviewActionBar(
                bloc: bloc, busy: state.busy, applicantName: s.fullName),
          ],
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, AppLocalizations loc,
      SubmissionDetailBloc bloc, SubmissionDetailState state,
      SubmissionDetail s) {
    final rejection = s.rejectionReason;
    return [
      PageHeader(
        icon: Icons.assignment_ind_outlined,
        title: loc.adminSubmissionDetailTitle,
        subtitle: s.fullName,
        actions: [
          StatusBadge(
            kind: submissionStatusKind(s.status),
            label: statusLabel(loc, s.status),
          ),
        ],
      ),
      DetailSectionsPadding(
        child: ManagementTwoPane(
          primary: [
            if (state.rejectionNotice != null)
              _ResendNotice(bloc: bloc, busy: state.busy),
            if (rejection != null && rejection.isNotEmpty)
              ManagementSectionCard(
                title: loc.adminSubmissionDetailFieldsRejectionReason,
                icon: Icons.block_outlined,
                child: Text(rejection),
              ),
            SubmissionPersonalCard(submission: s),
            SubmissionAddressCard(submission: s),
            SubmissionEmergencyCard(submission: s),
            SubmissionPaymentCard(submission: s),
          ],
          secondary: [
            SubmissionAttachmentsCard(
              submission: s,
              busy: state.busy,
              onReplace: (kind, path) => bloc
                  .add(SubmissionDetailAttachmentReplaceRequested(kind, path)),
            ),
            SubmissionPropertiesCard(
              submission: s,
              busy: state.busy,
              onReplaceDocument: (docId, path) => bloc
                  .add(SubmissionDetailDocumentReplaceRequested(docId, path)),
            ),
            SubmissionNomineesCard(submission: s),
          ],
        ),
      ),
    ];
  }
}

/// Rejected, but the applicant email failed: offer a resend.
class _ResendNotice extends StatelessWidget {
  const _ResendNotice({required this.bloc, required this.busy});

  final SubmissionDetailBloc bloc;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ManagementCallout(
        message: loc.adminSubmissionDetailErrorsRejectEmailFailed,
        icon: Icons.mark_email_unread_outlined,
        error: true,
        action: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AppButton(
            label: loc.adminSubmissionDetailResendButton,
            icon: Icons.send_outlined,
            variant: AppButtonVariant.secondary,
            loading: busy,
            onPressed: () =>
                bloc.add(const SubmissionDetailResendNotificationRequested()),
          ),
        ),
      ),
    );
  }
}

enum _ReviewAction { approve, reject }

/// Sticky approve (primary) / reject (danger) bar shown in review mode.
class _ReviewActionBar extends StatefulWidget {
  const _ReviewActionBar({
    required this.bloc,
    required this.busy,
    required this.applicantName,
  });

  final SubmissionDetailBloc bloc;
  final bool busy;
  final String applicantName;

  @override
  State<_ReviewActionBar> createState() => _ReviewActionBarState();
}

class _ReviewActionBarState extends State<_ReviewActionBar> {
  _ReviewAction? _active;

  bool _isLoading(_ReviewAction action) => widget.busy && _active == action;

  Future<void> _approve(AppLocalizations loc) async {
    final confirmed = await confirmDialog(
      context,
      title: loc.adminSubmissionDetailApproveModalTitle,
      message:
          '${widget.applicantName} ${loc.adminSubmissionDetailApproveModalMessageSuffix}',
      confirmLabel: loc.adminSubmissionDetailApproveModalConfirmLabel,
    );
    if (!confirmed || !mounted) return;
    setState(() => _active = _ReviewAction.approve);
    final ok = await dispatchForBool(widget.bloc,
        (c) => SubmissionDetailApproveRequested(completer: c));
    if (ok && mounted) context.go('/submissions');
  }

  Future<void> _reject(AppLocalizations loc) async {
    final reason = await showReasonDialog(
      context,
      title: loc.adminSubmissionDetailRejectModalTitle,
      summary:
          '${widget.applicantName}${loc.adminSubmissionDetailRejectModalMessageSuffix}',
      hint: loc.adminSubmissionDetailRejectModalPlaceholder,
      confirmLabel: loc.adminSubmissionDetailRejectModalConfirmLabel,
      validator: (text) =>
          text.isEmpty ? loc.adminSubmissionDetailErrorsReasonRequired : null,
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    setState(() => _active = _ReviewAction.reject);
    final emailSent = await dispatchForBool(widget.bloc,
        (c) => SubmissionDetailRejectRequested(reason, completer: c));
    if (emailSent && mounted) context.go('/submissions');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final busy = widget.busy;
    return ManagementActionBar(
      children: [
        AppButton(
          label: loc.adminSubmissionDetailRejectButton,
          variant: AppButtonVariant.danger,
          icon: Icons.close,
          expanded: true,
          loading: _isLoading(_ReviewAction.reject),
          onPressed: busy ? null : () => _reject(loc),
        ),
        AppButton(
          label: loc.adminSubmissionDetailApproveButton,
          icon: Icons.check,
          expanded: true,
          loading: _isLoading(_ReviewAction.approve),
          onPressed: busy ? null : () => _approve(loc),
        ),
      ],
    );
  }
}
