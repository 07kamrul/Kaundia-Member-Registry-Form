import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/member_detail_bloc.dart';
import '../presentation/widgets/management_widgets.dart';
import '../presentation/widgets/member_detail_widgets.dart';
import '../presentation/widgets/submission_detail_widgets.dart'
    show DetailSectionsPadding;
import 'submissions_list_page.dart';

/// Read-only member record (Angular member-detail-drawer as a page).
class MemberDetailPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const MemberDetailPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final memberId = id;
    if (memberId == null) {
      return EmptyState(
          message: loc.commonNoData, icon: Icons.person_off_outlined);
    }
    return BlocProvider(
      create: (_) => MemberDetailBloc(
        repository: AdminRepository(apiClient: sl<ApiClient>()),
        id: memberId,
      )..add(const MemberDetailLoadRequested()),
      child: const _MemberDetailView(),
    );
  }
}

class _MemberDetailView extends StatelessWidget {
  const _MemberDetailView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<MemberDetailBloc, MemberDetailState>(
      builder: (context, state) {
        final bloc = context.read<MemberDetailBloc>();
        if (state.loading) return const SkeletonLoader(lines: 8, height: 88);
        if (state.error != null) {
          return InlineError(
              message: loc.adminMemberDetailLoadFailed,
              onRetry: () => bloc.add(const MemberDetailLoadRequested()));
        }
        final p = state.profile;
        if (p == null) {
          return EmptyState(
              message: loc.commonNoData, icon: Icons.person_off_outlined);
        }
        return PageBody(
          onRefresh: () => reloadAndWait(
              bloc, const MemberDetailLoadRequested(), (s) => s.loading),
          children: _content(context, loc, p),
        );
      },
    );
  }

  List<Widget> _content(
      BuildContext context, AppLocalizations loc, MemberProfile p) {
    return [
      PageHeader(
        icon: Icons.badge_outlined,
        title: loc.adminMemberDetailTitle,
        subtitle: p.memberId == null ? p.fullName : '${p.fullName} · ${p.memberId}',
        actions: [
          StatusBadge(
            kind: submissionStatusKind(p.status),
            label: statusLabel(loc, p.status),
          ),
        ],
      ),
      DetailSectionsPadding(
        child: ManagementTwoPane(
          primary: [
            MemberIdentityCard(profile: p),
            MemberContactCard(profile: p),
            MemberMembershipCard(profile: p),
            MemberNomineesCard(profile: p),
            MemberPropertyCard(profile: p),
          ],
          secondary: [
            MemberFeesCard(profile: p),
            MemberInstallmentsCard(profile: p),
            MemberPicnicCard(profile: p),
            MemberAuditCard(profile: p),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ResponsiveCenter(
        maxWidth: Breakpoints.formMaxWidth,
        padding: EdgeInsets.symmetric(horizontal: context.pageGutter),
        child: AppButton(
          label: loc.adminMemberDetailOpenInstallments,
          icon: Icons.calendar_month_outlined,
          variant: AppButtonVariant.secondary,
          expanded: true,
          onPressed: () => context.go('/installments-management'),
        ),
      ),
    ];
  }
}
