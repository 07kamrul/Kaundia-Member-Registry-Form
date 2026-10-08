import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/attachment_viewer.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/member_entities.dart';
import 'member_ui.dart';

/// View-mode building blocks for the member profile page.

/// A label/value pair that is skipped entirely when the value is empty.
class ProfileField {
  const ProfileField(this.label, this.value, this.icon);

  final String label;
  final String? value;
  final IconData icon;

  bool get isPresent => (value ?? '').trim().isNotEmpty;
}

/// Avatar, name, member id, contact chips, status and the edit action.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.profile,
    required this.status,
    required this.onEdit,
  });

  final MemberProfile profile;
  final Widget status;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final edit = AppButton(
      label: loc.memberProfileEditButton,
      icon: Icons.edit_outlined,
      onPressed: onEdit,
    );
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, c) {
          // Phones: avatar above centred details; wider: avatar beside them.
          if (c.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: ProfileAvatar(profile: profile, radius: 40)),
                const SizedBox(height: 12),
                _details(theme, centered: true),
                const SizedBox(height: 16),
                edit,
              ],
            );
          }
          final wide = c.maxWidth >= 600;
          final info = Row(
            children: [
              ProfileAvatar(profile: profile, radius: 40),
              const SizedBox(width: 16),
              Expanded(child: _details(theme, centered: false)),
            ],
          );
          if (wide) {
            return Row(children: [Expanded(child: info), const SizedBox(width: 16), edit]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [info, const SizedBox(height: 16), edit],
          );
        },
      ),
    );
  }

  Widget _details(ThemeData theme, {required bool centered}) {
    final align = centered ? WrapAlignment.center : WrapAlignment.start;
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          profile.fullName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: align,
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (profile.memberId.isNotEmpty) MetaChip(icon: Icons.badge_outlined, text: profile.memberId),
            status,
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: align,
          spacing: 14,
          runSpacing: 4,
          children: [
            MetaChip(icon: Icons.phone_outlined, text: profile.mobile),
            if ((profile.email ?? '').isNotEmpty) MetaChip(icon: Icons.email_outlined, text: profile.email!),
          ],
        ),
      ],
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.radius = 34, this.localImage});

  final MemberProfile profile;
  final double radius;

  /// A freshly picked (not yet uploaded) photo, shown instead of the remote one.
  final ImageProvider? localImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profile.fullName.trim();
    final image = localImage ??
        (profile.memberPhotoUrl.isEmpty ? null : NetworkImage(profile.memberPhotoUrl));
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: image,
        onBackgroundImageError: image == null ? null : (_, __) {},
        child: image != null
            ? null
            : Text(
                name.isEmpty ? '—' : name.substring(0, 1),
                style: TextStyle(fontSize: radius * 0.7, color: theme.colorScheme.primary),
              ),
      ),
    );
  }
}

/// Titled card of [ProfileField]s; empty values are hidden.
class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.fields,
    this.footer = const [],
    this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final List<ProfileField> fields;
  final List<Widget> footer;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final present = fields.where((f) => f.isPresent).toList();
    return AppCard(
      margin: EdgeInsets.zero,
      title: title,
      trailing: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (present.isEmpty && footer.isEmpty && emptyMessage != null)
            Text(emptyMessage!, style: Theme.of(context).textTheme.bodySmall),
          for (final f in present) DetailRow(label: f.label, value: f.value!, icon: f.icon),
          ...footer,
        ],
      ),
    );
  }
}

/// "View file" button opening the in-app attachment viewer.
class ProfileFileButton extends StatelessWidget {
  const ProfileFileButton({super.key, required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OutlinedButton.icon(
        onPressed: () => showAttachmentViewer(context, rawPathOrUrl: url, title: label),
        icon: const Icon(Icons.attach_file, size: 18),
        label: Text('$label · ${loc.memberProfileViewFile}', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class ProfilePropertiesCard extends StatelessWidget {
  const ProfilePropertiesCard({super.key, required this.profile});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppCard(
      title: loc.memberProfilePropertyTitle,
      trailing: Icon(Icons.landscape_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
      child: profile.properties.isEmpty
          ? Text(loc.memberProfileNoPropertyInfo, style: theme.textTheme.bodySmall)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < profile.properties.length; i++) ...[
                  if (i > 0) const Divider(height: 28),
                  _PropertyBlock(property: profile.properties[i]),
                ],
              ],
            ),
    );
  }
}

class _PropertyBlock extends StatelessWidget {
  const _PropertyBlock({required this.property});

  final MemberProperty property;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = property;
    final fields = [
      ProfileField(
        loc.memberProfilePropertyTypesLabel,
        [...p.propertyType, p.propertyTypeOther].whereType<String>().where((s) => s.isNotEmpty).join(' / '),
        Icons.category_outlined,
      ),
      ProfileField(loc.memberProfileKhatianLabel, p.khatianNo, Icons.description_outlined),
      ProfileField(loc.memberProfileDagNoCsLabel, p.dagNoCs, Icons.tag),
      ProfileField(loc.memberProfileDagNoRsLabel, p.dagNoRs, Icons.tag),
      ProfileField(loc.memberProfileHoldingNumberLabel, p.holdingNumber, Icons.home_outlined),
      ProfileField(loc.memberProfileLandQuantityLabel, p.landQuantity, Icons.square_foot),
      ProfileField(loc.memberProfileMyShareQuantityLabel, p.myShareQuantity, Icons.pie_chart_outline),
      ProfileField(loc.memberProfileOwnershipLabel, p.ownership, Icons.people_outline),
      if (p.coOwners.isNotEmpty)
        ProfileField(
          loc.memberProfileCoOwnerLabel,
          p.coOwners.map((c) => '${c.ownerName} (${c.ownerPhone})').join(', '),
          Icons.group_outlined,
        ),
    ].where((f) => f.isPresent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${loc.memberProfilePropertyItemLabel} #${p.id}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        for (final f in fields) DetailRow(label: f.label, value: f.value!, icon: f.icon),
        for (final doc in p.applicableDocs)
          if (doc.fileUrl != null) ProfileFileButton(label: doc.docType, url: doc.fileUrl!),
      ],
    );
  }
}

/// Property change requests with withdraw for pending ones.
class ProfileRequestsCard extends StatelessWidget {
  const ProfileRequestsCard({
    super.key,
    required this.requests,
    required this.loading,
    required this.hasError,
    required this.onRetry,
    required this.onAdd,
    required this.onWithdraw,
    required this.actionLabel,
    required this.statusLabel,
  });

  final List<MemberPropertyRequest> requests;
  final bool loading;
  final bool hasError;
  final VoidCallback onRetry;
  final VoidCallback onAdd;
  final ValueChanged<MemberPropertyRequest> onWithdraw;
  final String Function(PropertyRequestAction action) actionLabel;
  final String Function(PropertyRequestStatus status) statusLabel;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      title: loc.memberPropertyRequestsListTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _body(context, loc),
          AddItemButton(
            label: loc.memberPropertyRequestsAddButton,
            icon: Icons.add_home_outlined,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations loc) {
    if (loading) return const LinearProgressIndicator();
    if (hasError) {
      return NoticeBanner(
        margin: EdgeInsets.zero,
        tone: NoticeTone.error,
        message: loc.memberPropertyRequestsErrorsLoadFailed,
        action: TextButton(onPressed: onRetry, child: Text(loc.commonRetry)),
      );
    }
    if (requests.isEmpty) {
      return Text(loc.memberPropertyRequestsNoRequests, style: Theme.of(context).textTheme.bodySmall);
    }
    return Column(
      children: [
        for (var i = 0; i < requests.length; i++) ...[
          if (i > 0) const Divider(height: 16),
          _RequestRow(
            request: requests[i],
            actionLabel: actionLabel(requests[i].action),
            statusLabel: statusLabel(requests[i].status),
            onWithdraw: () => onWithdraw(requests[i]),
          ),
        ],
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.actionLabel,
    required this.statusLabel,
    required this.onWithdraw,
  });

  final MemberPropertyRequest request;
  final String actionLabel;
  final String statusLabel;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pending = request.status == PropertyRequestStatus.pending;
    final kind = switch (request.status) {
      PropertyRequestStatus.pending => StatusKind.pending,
      PropertyRequestStatus.approved => StatusKind.approved,
      PropertyRequestStatus.cancelled => StatusKind.rejected,
      PropertyRequestStatus.unknown => StatusKind.neutral,
    };
    final icon = switch (request.action) {
      PropertyRequestAction.add => Icons.add_home_outlined,
      PropertyRequestAction.edit => Icons.edit_outlined,
      PropertyRequestAction.delete => Icons.delete_outline,
      PropertyRequestAction.unknown => Icons.help_outline,
    };
    return Row(
      children: [
        LeadingIcon(icon: icon, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.reference, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(actionLabel, style: theme.textTheme.bodySmall),
                  StatusBadge(kind: kind, label: statusLabel),
                ],
              ),
            ],
          ),
        ),
        if (pending)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: onWithdraw,
            child: Text(loc.memberPropertyRequestsWithdrawButton),
          ),
      ],
    );
  }
}
