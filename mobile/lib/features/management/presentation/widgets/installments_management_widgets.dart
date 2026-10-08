import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/admin_entities.dart';
import 'management_widgets.dart';

/// Member picker + month grid for the installments management page.

/// Wide layouts: scrollable, selectable member list (master pane).
class InstallmentsMemberList extends StatelessWidget {
  const InstallmentsMemberList({
    super.key,
    required this.members,
    required this.selectedId,
    required this.onSelected,
  });

  static const double _maxHeight = 600;

  final List<Member> members;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _maxHeight),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final m = members[index];
            return ListTile(
              selected: m.id == selectedId,
              selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.5),
              leading: ManagementAvatar(name: m.fullName, radius: 16),
              title: Text(m.fullName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: m.memberId == null ? null : Text(m.memberId!),
              onTap: () => onSelected(m.id),
            );
          },
        ),
      ),
    );
  }
}

/// Phones / tablets: member dropdown.
class InstallmentsMemberDropdown extends StatelessWidget {
  const InstallmentsMemberDropdown({
    super.key,
    required this.members,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Member> members;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SelectField<String>(
      // Rebuild when the bloc auto-selects (initialValue is read once).
      key: ValueKey(selectedId),
      label: loc.adminInstallmentsSelectMember,
      value: selectedId,
      items: [
        for (final m in members)
          DropdownMenuItem(
            value: m.id,
            child: Text(
              m.memberId == null ? m.fullName : '${m.fullName} · ${m.memberId}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (id) {
        if (id != null && id != selectedId) onSelected(id);
      },
    );
  }
}

/// Paid / due counts and outstanding total for the selected member.
class InstallmentsSummary extends StatelessWidget {
  const InstallmentsSummary({super.key, required this.installments});

  final List<Installment> installments;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final due = installments.where((i) => !i.isPaid).toList();
    final dueTotal = due.fold<num>(0, (sum, i) => sum + i.amount);
    return ManagementStatSummary(
      padding: const EdgeInsets.only(bottom: 8),
      stats: [
        ManagementStat(
          label: loc.adminInstallmentsPaid,
          value: '${installments.length - due.length}',
          icon: Icons.check_circle_outline,
          accent: AppColors.emerald600,
        ),
        ManagementStat(
          label: loc.adminMemberDetailDue,
          value: '${due.length}',
          icon: Icons.schedule_outlined,
          accent: AppColors.goldStrong,
        ),
        ManagementStat(
          label: loc.adminMemberDetailFDueTotal,
          value: formatTaka(dueTotal),
          icon: Icons.account_balance_wallet_outlined,
          accent: due.isEmpty ? AppColors.emerald600 : AppColors.red600,
        ),
      ],
    );
  }
}

class InstallmentMonthCard extends StatelessWidget {
  const InstallmentMonthCard({
    super.key,
    required this.label,
    required this.installment,
    required this.canManage,
    required this.busy,
    required this.onMarkPaid,
  });

  final String label;
  final Installment installment;
  final bool canManage;
  final bool busy;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final paid = installment.isPaid;
    return Card(
      margin: EdgeInsets.zero,
      color: paid ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(formatTaka(installment.amount),
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            if (paid)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                    kind: StatusKind.approved,
                    label: loc.adminInstallmentsPaid),
              )
            else
              AppButton(
                label: loc.adminInstallmentsMarkPaidButton,
                icon: Icons.done,
                expanded: true,
                loading: busy,
                onPressed: canManage ? onMarkPaid : null,
              ),
          ],
        ),
      ),
    );
  }
}
