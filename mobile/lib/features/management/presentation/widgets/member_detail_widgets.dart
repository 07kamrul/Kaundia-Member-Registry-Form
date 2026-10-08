import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/admin_entities.dart';
import 'management_widgets.dart';
import 'submission_detail_widgets.dart' show joinAddress;

/// Section cards for the read-only member record page.

String memberMonthLabel(AppLocalizations loc, int month) => switch (month) {
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

class MemberIdentityCard extends StatelessWidget {
  const MemberIdentityCard({super.key, required this.profile});

  /// Below this card width the photo sits above the fields.
  static const double _stackBelow = 420;

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final p = profile;
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoRow(label: loc.adminMemberDetailFMemberId, value: p.memberId ?? '—'),
        InfoRow(label: loc.adminMemberDetailFName, value: p.fullName),
        InfoRow(
            label: loc.adminMemberDetailFFatherOrHusband,
            value: p.fatherOrHusband),
        InfoRow(label: loc.adminMemberDetailFMother, value: p.mother),
        InfoRow(label: loc.adminMemberDetailFNid, value: p.nid),
        InfoRow(label: loc.adminMemberDetailFDob, value: p.dob),
        InfoRow(label: loc.adminMemberDetailFGender, value: p.gender),
        InfoRow(label: loc.adminMemberDetailFOccupation, value: p.occupation),
      ],
    );
    return ManagementSectionCard(
      title: loc.adminMemberDetailSectionsIdentity,
      icon: Icons.badge_outlined,
      child: LayoutBuilder(
        builder: (context, c) {
          final photo = _MemberPhoto(url: p.memberPhotoUrl, name: p.fullName);
          if (c.maxWidth < _stackBelow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [photo, const SizedBox(height: 12), fields],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [photo, const SizedBox(width: 16), Expanded(child: fields)],
          );
        },
      ),
    );
  }
}

class _MemberPhoto extends StatelessWidget {
  const _MemberPhoto({required this.url, required this.name});

  static const double _size = 88;

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final link = url;
    final fallback = ManagementAvatar(name: name, radius: _size / 2);
    if (link == null || link.isEmpty) return fallback;
    return GestureDetector(
      onTap: () => showImagePreview(context, link, name),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Image.network(
          link,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

class MemberContactCard extends StatelessWidget {
  const MemberContactCard({super.key, required this.profile});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final p = profile;
    final urgent = p.urgentContactName;
    return ManagementSectionCard(
      title: loc.adminMemberDetailSectionsContact,
      icon: Icons.contact_mail_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: loc.adminMemberDetailFMobile, value: p.mobile),
          InfoRow(label: loc.adminMemberDetailFEmail, value: p.email),
          InfoRow(
            label: loc.adminMemberDetailFPresentAddress,
            value: joinAddress(p.currentHouse, p.currentRoad,
                p.currentPostOffice, p.currentUpazila, p.currentDistrict,
                p.currentDivision),
            expanded: true,
          ),
          InfoRow(
            label: loc.adminMemberDetailFPermanentAddress,
            value: joinAddress(p.permanentHouse, p.permanentRoad,
                p.permanentPostOffice, p.permanentUpazila, p.permanentDistrict,
                p.permanentDivision),
            expanded: true,
          ),
          if (urgent != null && urgent.isNotEmpty)
            InfoRow(
              label: loc.adminMemberDetailFUrgentContact,
              value:
                  '$urgent (${p.urgentContactRelation}) · ${p.urgentContactMobile}',
              expanded: true,
            ),
        ],
      ),
    );
  }
}

class MemberMembershipCard extends StatelessWidget {
  const MemberMembershipCard({super.key, required this.profile});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final p = profile;
    return ManagementSectionCard(
      title: loc.adminMemberDetailSectionsMembership,
      icon: Icons.card_membership_outlined,
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
}

class MemberFeesCard extends StatelessWidget {
  const MemberFeesCard({super.key, required this.profile});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final fee = profile.feeSummary;
    final overdue = fee.dueCount > 0;
    return ManagementSectionCard(
      title: loc.adminMemberDetailSectionsFees,
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(
            label: loc.adminMemberDetailFPaidTotal,
            value: '${fee.paidCount} · ${formatTaka(fee.paidTotal)}',
          ),
          InfoRow(
            label: loc.adminMemberDetailFDueTotal,
            value: '${fee.dueCount} · ${formatTaka(fee.dueTotal)}',
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(loc.adminMemberDetailFContribution,
                  style: Theme.of(context).textTheme.bodySmall),
              StatusBadge(
                kind: overdue ? StatusKind.pending : StatusKind.approved,
                label: overdue
                    ? '${fee.dueCount} ${loc.adminMemberDetailMonthsOverdue}'
                    : loc.adminMemberDetailFullyPaid,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MemberInstallmentsCard extends StatelessWidget {
  const MemberInstallmentsCard({super.key, required this.profile});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = profile.installments;
    return ManagementSectionCard(
      title: loc.adminMemberDetailSectionsInstallments,
      icon: Icons.calendar_month_outlined,
      child: items.isEmpty
          ? ManagementMutedText(loc.adminMemberDetailNoInstallments)
          : ResponsiveGrid(
              minItemWidth: 200,
              maxColumns: 2,
              spacing: 8,
              children: [for (final i in items) _InstallmentChip(item: i)],
            ),
    );
  }
}

class _InstallmentChip extends StatelessWidget {
  const _InstallmentChip({required this.item});

  final Installment item;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${memberMonthLabel(loc, item.month)} ${item.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall),
                Text(formatTaka(item.amount), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          StatusBadge(
            kind: item.isPaid ? StatusKind.approved : StatusKind.pending,
            label: item.isPaid
                ? loc.adminMemberDetailPaid
                : loc.adminMemberDetailDue,
          ),
        ],
      ),
    );
  }
}

class MemberPicnicCard extends StatelessWidget {
  const MemberPicnicCard({super.key, required this.profile});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final payments = profile.picnicPayments;
    return ManagementSectionCard(
      title: loc.adminMemberDetailSectionsPicnic,
      icon: Icons.park_outlined,
      child: payments.isEmpty
          ? ManagementMutedText(loc.adminMemberDetailNoPicnic)
          : Column(
              children: [
                for (final pay in payments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.receipt_outlined),
                    title: Text(
                      '${pay.paymentDate} — ${formatTaka(pay.total)} (+${pay.additionalCount})',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle:
                        pay.receiptNo != null ? Text(pay.receiptNo!) : null,
                  ),
              ],
            ),
    );
  }
}

class MemberNomineesCard extends StatelessWidget {
  const MemberNomineesCard({super.key, required this.profile});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final nominees = profile.nominees;
    return ManagementSectionCard(
      title: loc.adminMemberDetailSectionsNominees,
      icon: Icons.group_outlined,
      child: nominees.isEmpty
          ? ManagementMutedText(loc.adminMemberDetailNoNominees)
          : Column(
              children: [
                for (final n in nominees)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ManagementAvatar(name: n.name, radius: 16),
                    title: Text(n.name,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      [n.relation, n.mobile]
                          .where((e) => e.isNotEmpty)
                          .join(' · '),
                    ),
                  ),
              ],
            ),
    );
  }
}

class MemberPropertyCard extends StatelessWidget {
  const MemberPropertyCard({super.key, required this.profile});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final properties = profile.properties;
    return ManagementSectionCard(
      title: loc.adminMemberDetailSectionsProperty,
      icon: Icons.landscape_outlined,
      child: properties.isEmpty
          ? ManagementMutedText(loc.adminMemberDetailNoProperties)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < properties.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  _PropertyBlock(property: properties[i]),
                ],
              ],
            ),
    );
  }
}

class _PropertyBlock extends StatelessWidget {
  const _PropertyBlock({required this.property});

  final SubmissionProperty property;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final prop = property;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prop.propertyType.join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        if (prop.khatianNo != null)
          InfoRow(label: loc.adminMemberDetailFKhatian, value: prop.khatianNo!),
        if (prop.holdingNumber != null)
          InfoRow(
              label: loc.adminMemberDetailFHolding, value: prop.holdingNumber!),
        if (prop.landQuantity != null)
          InfoRow(
              label: loc.adminMemberDetailFLandSize, value: prop.landQuantity!),
        if (prop.myShareQuantity != null)
          InfoRow(
              label: loc.adminMemberDetailFMyShare,
              value: prop.myShareQuantity!),
        if (prop.ownership != null)
          InfoRow(
              label: loc.adminMemberDetailFOwnership, value: prop.ownership!),
        for (final doc in prop.applicableDocs)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.description_outlined),
            title: Text(doc.docType, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: doc.fileUrl == null
                ? null
                : const Icon(Icons.visibility_outlined, size: 18),
            onTap: doc.fileUrl == null
                ? null
                : () => showImagePreview(context, doc.fileUrl!, doc.docType),
          ),
      ],
    );
  }
}

class MemberAuditCard extends StatelessWidget {
  const MemberAuditCard({super.key, required this.profile});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final entries = profile.auditTrail;
    return ManagementSectionCard(
      title: loc.adminMemberDetailSectionsAudit,
      icon: Icons.history,
      child: entries.isEmpty
          ? ManagementMutedText(loc.adminMemberDetailNoAudit)
          : Column(
              children: [
                for (final entry in entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.circle,
                        size: 10,
                        color: Theme.of(context).colorScheme.secondary),
                    minLeadingWidth: 12,
                    title: Text(entry.action,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle:
                        Text('${entry.actorName ?? ''} · ${entry.createdAt}'),
                  ),
              ],
            ),
    );
  }
}
