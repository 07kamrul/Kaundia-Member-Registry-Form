import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/neighbour_entities.dart';

/// Formats digits for the active locale (Bangla digits under `bn`).
typedef DigitFormatter = String Function(String text);

/// One neighbour owner: name, position badge, mobile (or privacy note),
/// land / dags and Call + WhatsApp actions (≥48dp).
class NeighbourOwnerCard extends StatelessWidget {
  const NeighbourOwnerCard({
    super.key,
    required this.owner,
    required this.digits,
    required this.onCall,
    required this.onWhatsApp,
  });

  final NeighbourOwner owner;
  final DigitFormatter digits;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    String orDash(String? v) => v == null || v.isEmpty ? '—' : digits(v);
    final land = owner.landQuantity;
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  owner.ownerName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              _positionBadge(owner.position, loc),
            ],
          ),
          const SizedBox(height: 8),
          if (owner.canContact)
            _InfoLine(
              icon: Icons.phone_outlined,
              label: loc.memberNeighboursTableMobile,
              value: digits(owner.mobile ?? ''),
            )
          else
            Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.memberNeighboursContactHidden,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          _InfoLine(
            icon: Icons.square_foot_outlined,
            label: loc.memberNeighboursTableLandQuantity,
            value: land == null || land.isEmpty
                ? '—'
                : loc.memberNeighboursLandUnit(digits(land)),
          ),
          _InfoLine(
            icon: Icons.tag,
            label: loc.memberNeighboursTableRsDag,
            value: orDash(owner.rsDag),
          ),
          _InfoLine(
            icon: Icons.tag,
            label: loc.memberNeighboursTableCsDag,
            value: orDash(owner.csDag),
          ),
          if (owner.canContact) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Semantics(
                  label: loc.memberNeighboursCallAria(owner.ownerName),
                  button: true,
                  excludeSemantics: true,
                  child: AppButton(
                    label: loc.memberNeighboursCall,
                    icon: Icons.call_outlined,
                    onPressed: onCall,
                  ),
                ),
                Semantics(
                  label: loc.memberNeighboursWhatsappAria(owner.ownerName),
                  button: true,
                  excludeSemantics: true,
                  child: AppButton(
                    label: loc.memberNeighboursWhatsapp,
                    icon: Icons.chat_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: onWhatsApp,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _positionBadge(NeighbourPosition position, AppLocalizations loc) {
    final (kind, label) = switch (position) {
      NeighbourPosition.sameDag =>
        (StatusKind.approved, loc.memberNeighboursPositionSameDag),
      NeighbourPosition.adjacent =>
        (StatusKind.pending, loc.memberNeighboursPositionAdjacent),
      NeighbourPosition.near =>
        (StatusKind.neutral, loc.memberNeighboursPositionNear),
      NeighbourPosition.unknown => (StatusKind.neutral, loc.commonNoData),
    };
    return StatusBadge(kind: kind, label: label);
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  TextSpan(
                    text: value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
