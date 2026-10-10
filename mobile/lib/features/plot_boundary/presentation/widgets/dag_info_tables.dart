import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/dag_details_entities.dart';
import 'owner_bottom_sheet.dart' show formatDigits;

/// Official settlement.gov.bd accent for the section headings.
const Color kDagInfoAccent = Color(0xFFE8710A);

const int _labelFlex = 48;
const int _valueFlex = 52;
const int _khatianNoFlex = 2;
const int _ownerFlex = 5;
const int _stageFlex = 3;
const EdgeInsets _cellPadding =
    EdgeInsets.symmetric(horizontal: 10, vertical: 9);

class _TableColors {
  const _TableColors({
    required this.border,
    required this.header,
    required this.stripe,
    required this.plain,
  });

  factory _TableColors.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const _TableColors(
            border: Color(0xFF454B54),
            header: Color(0xFF30353C),
            stripe: Color(0xFF282C32),
            plain: Color(0xFF1E2126),
          )
        : const _TableColors(
            border: Color(0xFFDEE2E6),
            header: Color(0xFFE9ECEF),
            stripe: Color(0xFFF2F2F2),
            plain: Color(0xFFFFFFFF),
          );
  }

  final Color border;
  final Color header;
  final Color stripe;
  final Color plain;
}

BorderSide _side(_TableColors c) => BorderSide(color: c.border);

/// Orange bold section heading.
class DagInfoHeading extends StatelessWidget {
  const DagInfoHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: kDagInfoAccent,
              fontWeight: FontWeight.w800,
            ),
      );
}

/// 2-column land-details table (label ~48%).
class LandDetailsTable extends StatelessWidget {
  const LandDetailsTable(
      {super.key, required this.details, required this.dagNo});

  final DagDetails details;
  final String dagNo;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    String digits(String v) => formatDigits(context, v);
    final rows = <(String, String)>[
      (loc.dagInfoPlotNo, digits(dagNo)),
      (loc.dagInfoSurveyType, _survey(loc)),
      (loc.dagInfoMouza, details.mouza.display(bangla: bangla)),
      (loc.dagInfoTotalLand, _totalLand(loc, digits)),
    ];
    final colors = _TableColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.fromBorderSide(_side(colors))),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(top: _side(colors)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: _labelFlex,
                      child: Container(
                        color: colors.header,
                        padding: _cellPadding,
                        child: Text(
                          rows[i].$1,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: _valueFlex,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(left: _side(colors)),
                        ),
                        padding: _cellPadding,
                        child: Text(rows[i].$2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _survey(AppLocalizations loc) => details.survey.toLowerCase() == 'bds'
      ? loc.dagInfoSurveyBds
      : details.survey.toUpperCase();

  String _totalLand(AppLocalizations loc, String Function(String) digits) {
    final land = details.totalLand;
    if (land == null) return '—';
    final unit = land.isAcre ? loc.dagInfoUnitAcre : land.unit;
    final lines = ['${digits(land.value.toString())} $unit'];
    final decimals = land.shatangsho;
    if (decimals != null) {
      lines.add(loc.dagInfoShatangsho(digits(decimals.toStringAsFixed(2))));
    }
    return lines.join('\n');
  }
}

/// 3-column khatian table. One khatian is one row group; the number and stage
/// cells span every owner row (rowspan emulation).
class KhatianTable extends StatelessWidget {
  const KhatianTable({super.key, required this.khatians});

  final List<Khatian> khatians;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = _TableColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.fromBorderSide(_side(colors))),
      child: Column(
        children: [
          _headerRow(loc, colors),
          if (khatians.isEmpty)
            DecoratedBox(
              decoration: BoxDecoration(border: Border(top: _side(colors))),
              child: Container(
                key: const Key('khatian-empty-row'),
                width: double.infinity,
                padding: _cellPadding,
                alignment: Alignment.center,
                child: Text(loc.dagInfoNoKhatian, textAlign: TextAlign.center),
              ),
            )
          else
            for (var i = 0; i < khatians.length; i++)
              _KhatianGroup(index: i, khatian: khatians[i], colors: colors),
        ],
      ),
    );
  }

  Widget _headerRow(AppLocalizations loc, _TableColors colors) {
    Widget cell(String text, int flex, {bool first = false}) => Expanded(
          flex: flex,
          child: Container(
            decoration: BoxDecoration(
              border: first ? null : Border(left: _side(colors)),
            ),
            padding: _cellPadding,
            alignment: Alignment.center,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
    return Container(
      color: colors.header,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(loc.dagInfoKhatianNo, _khatianNoFlex, first: true),
            cell(loc.dagInfoOwnerName, _ownerFlex),
            cell(loc.dagInfoCurrentStage, _stageFlex),
          ],
        ),
      ),
    );
  }
}

class _KhatianGroup extends StatelessWidget {
  const _KhatianGroup({
    required this.index,
    required this.khatian,
    required this.colors,
  });

  final int index;
  final Khatian khatian;
  final _TableColors colors;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final stage = switch (khatian.stage) {
      KhatianStage.objection => loc.dagInfoStageObjection,
      KhatianStage.appeal => loc.dagInfoStageAppeal,
      KhatianStage.unknown => khatian.stageBn ?? '—',
    };
    final owners = khatian.owners.isEmpty ? const ['—'] : khatian.owners;

    Widget spanCell(String text, int flex, {bool leftBorder = false}) =>
        Expanded(
          flex: flex,
          child: Container(
            decoration: BoxDecoration(
              color: colors.plain,
              border: leftBorder ? Border(left: _side(colors)) : null,
            ),
            padding: _cellPadding,
            alignment: Alignment.center,
            child: Text(text, textAlign: TextAlign.center),
          ),
        );

    return DecoratedBox(
      key: Key('khatian-group-$index'),
      decoration: BoxDecoration(border: Border(top: _side(colors))),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            spanCell(formatDigits(context, khatian.khatianNo), _khatianNoFlex),
            Expanded(
              flex: _ownerFlex,
              child: Container(
                decoration: BoxDecoration(border: Border(left: _side(colors))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < owners.length; j++)
                      Container(
                        key: Key('owner-$index-$j'),
                        color: j.isEven ? colors.stripe : colors.plain,
                        padding: _cellPadding,
                        child: Text(owners[j]),
                      ),
                  ],
                ),
              ),
            ),
            spanCell(stage, _stageFlex, leftBorder: true),
          ],
        ),
      ),
    );
  }
}
