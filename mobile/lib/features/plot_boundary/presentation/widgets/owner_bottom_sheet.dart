import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../member/domain/finance_entities.dart' show toBanglaDigits;
import '../../domain/plot_boundary_entities.dart';
import '../bloc/plot_map_bloc.dart';

typedef DigitFormat = String Function(String text);

String formatDigits(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'bn'
        ? toBanglaDigits(text)
        : text;

/// Modal bottom sheet with the owner behind a map polygon. Pure presentation:
/// the page supplies [owner]/[status] and contact/report callbacks.
class BoundaryOwnerSheet extends StatelessWidget {
  const BoundaryOwnerSheet({
    super.key,
    required this.status,
    this.owner,
    this.failure,
    this.feature,
    required this.onCall,
    required this.onWhatsApp,
    required this.onReport,
    required this.onRetry,
    this.reported = false,
  });

  final OwnerLoadStatus status;

  /// The member already reported this plot in this session.
  final bool reported;
  final BoundaryOwner? owner;

  /// Message shown when the lookup failed.
  final String? failure;

  /// The map feature under the sheet (drives the status badge).
  final BoundaryFeature? feature;

  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onReport;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    String orDash(String? v) =>
        v == null || v.isEmpty ? '—' : formatDigits(context, v);

    Widget body;
    if (status == OwnerLoadStatus.loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (status == OwnerLoadStatus.failure) {
      body = InlineError(
        message: failure ?? loc.boundaryOwnerLoadError,
        onRetry: onRetry,
      );
    } else {
      final o = owner;
      final mobile = o?.mobile;
      final showContact = o != null && !o.contactHidden && mobile != null;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  _initial(o?.ownerName),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o?.ownerName ?? '—',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'RS: ${orDash(o?.rsDag)} · CS: ${orDash(o?.csDag)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (feature != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (feature!.isMine)
                    StatusBadge(
                      kind: StatusKind.pending,
                      label: loc.boundaryStatusMine,
                    ),
                  StatusBadge(
                    kind: _statusKind(feature!.status),
                    label: _statusLabel(context, feature!.status),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (showContact) ...[
            _line(context, Icons.phone_outlined, loc.boundaryMobile,
                formatDigits(context, mobile)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                    label: loc.boundaryCall,
                    icon: Icons.call_outlined,
                    onPressed: onCall),
                AppButton(
                  label: loc.boundaryWhatsapp,
                  icon: Icons.chat_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: onWhatsApp,
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.boundaryOwnerContactHidden,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: muted, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          if (o != null && (o.areaSqm != null || o.areaShotangsho != null))
            _line(context, Icons.square_foot_outlined, loc.boundaryAreaLabel,
                _areaText(context, loc, o)),
          _line(context, Icons.square_foot_outlined, loc.boundaryLandQuantity,
              orDash(o?.landQuantity)),
          _line(context, Icons.tag, loc.boundaryRsDag, orDash(o?.rsDag)),
          _line(context, Icons.tag, loc.boundaryCsDag, orDash(o?.csDag)),
          const SizedBox(height: 12),
          if (reported)
            Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 18, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(child: Text(loc.boundaryReportSent)),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.flag_outlined),
              label: Text(loc.boundaryReport),
            ),
        ],
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.boundaryOwnerTitle,
                style: theme.textTheme.titleSmall?.copyWith(color: muted)),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }

  static String _initial(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? '?' : String.fromCharCode(trimmed.runes.first);
  }

  StatusKind _statusKind(BoundaryStatus status) => switch (status) {
        BoundaryStatus.approved => StatusKind.approved,
        BoundaryStatus.disputed => StatusKind.rejected,
        BoundaryStatus.rejected => StatusKind.neutral,
        BoundaryStatus.pendingReview ||
        BoundaryStatus.draft =>
          StatusKind.pending,
      };

  String _statusLabel(BuildContext context, BoundaryStatus status) {
    final loc = AppLocalizations.of(context);
    return switch (status) {
      BoundaryStatus.approved => loc.boundaryStatusApproved,
      BoundaryStatus.disputed => loc.boundaryStatusDisputed,
      BoundaryStatus.rejected => loc.boundaryStatusRejected,
      BoundaryStatus.pendingReview ||
      BoundaryStatus.draft =>
        loc.boundaryStatusPendingReview,
    };
  }

  String _areaText(
      BuildContext context, AppLocalizations loc, BoundaryOwner o) {
    final sqm = o.areaSqm != null
        ? formatDigits(context, o.areaSqm!.toStringAsFixed(1))
        : '—';
    final sho = o.areaShotangsho != null
        ? formatDigits(context, o.areaShotangsho!.toStringAsFixed(2))
        : '—';
    return '${loc.boundaryAreaValues(sqm, sho)} (${loc.boundaryAreaEstimateTag})';
  }

  Widget _line(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 6),
          Text('$label: ',
              style: theme.textTheme.bodySmall?.copyWith(color: muted)),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
