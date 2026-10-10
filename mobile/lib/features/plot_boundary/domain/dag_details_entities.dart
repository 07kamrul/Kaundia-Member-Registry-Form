import 'package:equatable/equatable.dart';

/// Current stage of a khatian in the settlement process.
enum KhatianStage { objection, appeal, unknown }

class MouzaInfo extends Equatable {
  const MouzaInfo({
    this.nameBn,
    this.nameEn,
    this.upazilaBn,
    this.upazilaEn,
    this.districtBn,
    this.districtEn,
  });

  final String? nameBn;
  final String? nameEn;
  final String? upazilaBn;
  final String? upazilaEn;
  final String? districtBn;
  final String? districtEn;

  /// "mouza, upazila, district" in the requested language; missing parts are
  /// skipped.
  String display({required bool bangla}) => [
        bangla ? nameBn ?? nameEn : nameEn ?? nameBn,
        bangla ? upazilaBn ?? upazilaEn : upazilaEn ?? upazilaBn,
        bangla ? districtBn ?? districtEn : districtEn ?? districtBn,
      ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

  @override
  List<Object?> get props =>
      [nameBn, nameEn, upazilaBn, upazilaEn, districtBn, districtEn];
}

class TotalLand extends Equatable {
  const TotalLand({required this.value, required this.unit});

  /// The official figure, shown as-is.
  final double value;

  /// Raw unit from the source, e.g. `acre`.
  final String unit;

  bool get isAcre => unit.toLowerCase() == 'acre';

  /// 1 acre = 100 shatangsho (decimal).
  double? get shatangsho => isAcre ? value * 100 : null;

  @override
  List<Object?> get props => [value, unit];
}

class Khatian extends Equatable {
  const Khatian({
    required this.khatianNo,
    required this.owners,
    required this.stage,
    this.stageBn,
  });

  final String khatianNo;
  final List<String> owners;
  final KhatianStage stage;

  /// Raw stage label from the source; shown verbatim for [KhatianStage.unknown].
  final String? stageBn;

  @override
  List<Object?> get props => [khatianNo, owners, stage, stageBn];
}

/// Official settlement.gov.bd record of one dag. Contains personal data:
/// never log or persist it.
class DagDetails extends Equatable {
  const DagDetails({
    required this.survey,
    required this.sheet,
    required this.dag,
    required this.mouza,
    this.totalLand,
    this.khatians = const [],
    this.sourceNote,
    this.sourceName,
    this.fetchedAt,
  });

  final String survey;
  final String sheet;
  final String dag;
  final MouzaInfo mouza;
  final TotalLand? totalLand;
  final List<Khatian> khatians;
  final String? sourceNote;
  final String? sourceName;
  final DateTime? fetchedAt;

  @override
  List<Object?> get props => [
        survey,
        sheet,
        dag,
        mouza,
        totalLand,
        khatians,
        sourceNote,
        sourceName,
        fetchedAt,
      ];
}
