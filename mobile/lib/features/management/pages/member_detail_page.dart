import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/enums/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/members_bloc.dart';
import '../presentation/widgets/management_widgets.dart';
import 'submissions_list_page.dart';

String _joinAddress(
  String? house,
  String? road,
  String? po,
  String? up,
  String? dist,
  String? div,
) =>
    [house, road, po, up, dist, div]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .join(', ');

String _monthLabel(AppLocalizations loc, int month) => switch (month) {
      1 => loc.commonMonthsJanuary,
      2 => loc.commonMonthsFebruary,
      3 => loc.commonMonthsMarch,
      4 => loc.commonMonthsApril,
      5 => loc.commonMonthsMay,
      6 => loc.commonMonthsJune,
      7 => loc.commonMonthsJuly,
      8 => loc.commonMonthsAugust,
      9 => loc.commonMonthsSeptember,
      10 => loc.commonMonthsOctober,
      11 => loc.commonMonthsNovember,
      12 => loc.commonMonthsDecember,
      _ => '$month',
    };

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
    if (memberId == null) return EmptyState(message: loc.commonNoData);
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
      if (state.loading) return const SkeletonLoader(lines: 8);
      if (state.error != null) {
        return InlineError(
            message: loc.adminMemberDetailLoadFailed, onRetry: () => bloc.add(const MemberDetailLoadRequested()));
      }
      final p = state.profile;
      if (p == null) return EmptyState(message: loc.commonNoData);

      return ListView(
        children: [
          PageHeader(
            title: loc.adminMemberDetailTitle,
            subtitle: p.fullName,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: StatusBadge(
                  kind: switch (p.status) {
                    SubmissionStatus.pending => StatusKind.pending,
                    SubmissionStatus.approved => StatusKind.approved,
                    SubmissionStatus.rejected => StatusKind.rejected,
                    _ => StatusKind.neutral,
                  },
                  label: statusLabel(loc, p.status),
                ),
              ),
            ],
          ),
          _identitySection(context, loc, p),
          _contactSection(context, loc, p),
          _membershipSection(context, loc, p),
          _feesSection(context, loc, p),
          _installmentsSection(context, loc, p),
          _picnicSection(context, loc, p),
          _nomineesSection(context, loc, p),
          _propertySection(context, loc, p),
          _auditSection(context, loc, p),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppButton(
              label: loc.adminMemberDetailOpenInstallments,
              icon: Icons.calendar_month_outlined,
              expanded: true,
              onPressed: () => context.go('/installments-management'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
    });
  }

  Widget _identitySection(
      BuildContext context, AppLocalizations loc, MemberProfile p) {
    return AppCard(
      title: loc.adminMemberDetailSectionsIdentity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.memberPhotoUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  p.memberPhotoUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Text(
                      p.fullName.isEmpty ? '?' : p.fullName.substring(0, 1),
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                    label: loc.adminMemberDetailFMemberId,
                    value: p.memberId ?? '—'),
                InfoRow(label: loc.adminMemberDetailFName, value: p.fullName),
                InfoRow(
                    label: loc.adminMemberDetailFFatherOrHusband,
                    value: p.fatherOrHusband),
                InfoRow(label: loc.adminMemberDetailFMother, value: p.mother),
                InfoRow(label: loc.adminMemberDetailFNid, value: p.nid),
                InfoRow(label: loc.adminMemberDetailFDob, value: p.dob),
                InfoRow(label: loc.adminMemberDetailFGender, value: p.gender),
                InfoRow(
                    label: loc.adminMemberDetailFOccupation,
                    value: p.occupation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactSection(
      BuildContext context, AppLocalizations loc, MemberProfile p) {
    return AppCard(
      title: loc.adminMemberDetailSectionsContact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: loc.adminMemberDetailFMobile, value: p.mobile),
          InfoRow(label: loc.adminMemberDetailFEmail, value: p.email),
          InfoRow(
            label: loc.adminMemberDetailFPresentAddress,
            value: _joinAddress(
                p.currentHouse,
                p.currentRoad,
                p.currentPostOffice,
                p.currentUpazila,
                p.currentDistrict,
                p.currentDivision),
            expanded: true,
          ),
          InfoRow(
            label: loc.adminMemberDetailFPermanentAddress,
            value: _joinAddress(
                p.permanentHouse,
                p.permanentRoad,
                p.permanentPostOffice,
                p.permanentUpazila,
                p.permanentDistrict,
                p.permanentDivision),
            expanded: true,
          ),
          if (p.urgentContactName != null && p.urgentContactName!.isNotEmpty)
            InfoRow(
              label: loc.adminMemberDetailFUrgentContact,
              value:
                  '${p.urgentContactName} (${p.urgentContactRelation}) · ${p.urgentContactMobile}',
              expanded: true,
            ),
        ],
      ),
    );
  }

  Widget _membershipSection(
      BuildContext context, AppLocalizations loc, MemberProfile p) {
    return AppCard(
      title: loc.adminMemberDetailSectionsMembership,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: loc.adminMemberDetailFJoined, value: p.createdAt),
          InfoRow(label: loc.adminMemberDetailFUpdated, value: p.updatedAt),
          if (p.reviewedAt != null)
            InfoRow(
                label: loc.adminMemberDetailFReviewedAt,
                value: p.reviewedByName ?? p.reviewedAt!),
          InfoRow(
            label: loc.adminMemberDetailFAdmissionFee,
            value: '${p.admissionFee} (${p.receiptNo})',
          ),
        ],
      ),
    );
  }

  Widget _feesSection(
      BuildContext context, AppLocalizations loc, MemberProfile p) {
    final fee = p.feeSummary;
    return AppCard(
      title: loc.adminMemberDetailSectionsFees,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(
            label: loc.adminMemberDetailFPaidTotal,
            value:
                '${fee.paidCount} · ${formatTaka(fee.paidTotal, decimals: 0)}',
          ),
          InfoRow(
            label: loc.adminMemberDetailFDueTotal,
            value: '${fee.dueCount} · ${formatTaka(fee.dueTotal, decimals: 0)}',
          ),
          InfoRow(
            label: loc.adminMemberDetailFContribution,
            value: fee.dueCount > 0
                ? '${fee.dueCount} ${loc.adminMemberDetailMonthsOverdue}'
                : loc.adminMemberDetailFullyPaid,
          ),
        ],
      ),
    );
  }

  Widget _installmentsSection(
      BuildContext context, AppLocalizations loc, MemberProfile p) {
    if (p.installments.isEmpty) {
      return AppCard(
        title: loc.adminMemberDetailSectionsInstallments,
        child: Text(loc.adminMemberDetailNoInstallments),
      );
    }
    return AppCard(
      title: loc.adminMemberDetailSectionsInstallments,
      child: Column(
        children: [
          for (final i in p.installments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                  '${_monthLabel(loc, i.month)} ${i.year} — ${formatTaka(i.amount, decimals: 0)}'),
              trailing: i.isPaid
                  ? StatusBadge(
                      kind: StatusKind.approved,
                      label: loc.adminMemberDetailPaid)
                  : StatusBadge(
                      kind: StatusKind.pending,
                      label: loc.adminMemberDetailDue),
            ),
        ],
      ),
    );
  }

  Widget _picnicSection(
      BuildContext context, AppLocalizations loc, MemberProfile p) {
    if (p.picnicPayments.isEmpty) {
      return AppCard(
        title: loc.adminMemberDetailSectionsPicnic,
        child: Text(loc.adminMemberDetailNoPicnic),
      );
    }
    return AppCard(
      title: loc.adminMemberDetailSectionsPicnic,
      child: Column(
        children: [
          for (final pay in p.picnicPayments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                  '${pay.paymentDate} — ${formatTaka(pay.total, decimals: 0)} (+${pay.additionalCount})'),
              subtitle: pay.receiptNo != null ? Text(pay.receiptNo!) : null,
            ),
        ],
      ),
    );
  }

  Widget _nomineesSection(
      BuildContext context, AppLocalizations loc, MemberProfile p) {
    if (p.nominees.isEmpty) {
      return AppCard(
        title: loc.adminMemberDetailSectionsNominees,
        child: Text(loc.adminMemberDetailNoNominees),
      );
    }
    return AppCard(
      title: loc.adminMemberDetailSectionsNominees,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final n in p.nominees) ...[
            Text(
              n.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            InfoRow(
                label: loc.adminMemberDetailFNomineeRelation,
                value: n.relation),
            InfoRow(
                label: loc.adminMemberDetailFNomineeMobile, value: n.mobile),
            const Divider(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _propertySection(
      BuildContext context, AppLocalizations loc, MemberProfile p) {
    if (p.properties.isEmpty) {
      return AppCard(
        title: loc.adminMemberDetailSectionsProperty,
        child: Text(loc.adminMemberDetailNoProperties),
      );
    }
    return AppCard(
      title: loc.adminMemberDetailSectionsProperty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final prop in p.properties) ...[
            Text(
              prop.propertyType.join(', '),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (prop.khatianNo != null)
              InfoRow(
                  label: loc.adminMemberDetailFKhatian, value: prop.khatianNo!),
            if (prop.holdingNumber != null)
              InfoRow(
                  label: loc.adminMemberDetailFHolding,
                  value: prop.holdingNumber!),
            if (prop.landQuantity != null)
              InfoRow(
                  label: loc.adminMemberDetailFLandSize,
                  value: prop.landQuantity!),
            if (prop.myShareQuantity != null)
              InfoRow(
                  label: loc.adminMemberDetailFMyShare,
                  value: prop.myShareQuantity!),
            if (prop.ownership != null)
              InfoRow(
                  label: loc.adminMemberDetailFOwnership,
                  value: prop.ownership!),
            if (prop.applicableDocs.isNotEmpty)
              for (final doc in prop.applicableDocs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(doc.docType),
                  onTap: doc.fileUrl == null
                      ? null
                      : () =>
                          showImagePreview(context, doc.fileUrl!, doc.docType),
                ),
            const Divider(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _auditSection(
      BuildContext context, AppLocalizations loc, MemberProfile p) {
    if (p.auditTrail.isEmpty) {
      return AppCard(
        title: loc.adminMemberDetailSectionsAudit,
        child: Text(loc.adminMemberDetailNoAudit),
      );
    }
    return AppCard(
      title: loc.adminMemberDetailSectionsAudit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in p.auditTrail)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(entry.action),
              subtitle: Text('${entry.actorName ?? ''} · ${entry.createdAt}'),
              isThreeLine: false,
            ),
        ],
      ),
    );
  }
}
