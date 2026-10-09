import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/neighbours/data/neighbour_dtos.dart';
import 'package:kaundia_app/features/neighbours/domain/neighbour_entities.dart';
import 'package:kaundia_app/features/neighbours/domain/neighbour_mappers.dart';

import 'neighbours_fixtures.dart';

void main() {
  test('maps every snake_case field to the camelCase entities', () {
    final d = NeighbourDirectoryDto.fromJson(neighboursJson()).toEntity();

    expect(d.dagType, DagType.rs);
    expect(d.plotLimit, 5);
    expect(d.properties, hasLength(2));

    final first = d.properties.first;
    expect(first.own.propertyId, '12');
    expect(first.own.rsDag, '830');
    expect(first.own.csDag, '412');
    expect(first.own.landQuantity, '5');
    expect(first.own.dagNumber, 830);
    expect(first.own.hasDag, isTrue);

    final same = first.sameDagOwners.single;
    expect(same.ownerName, 'রহিম উদ্দিন');
    expect(same.mobile, '+8801712345678');
    expect(same.contactHidden, isFalse);
    expect(same.landQuantity, '3');
    expect(same.rsDag, '830/1');
    expect(same.csDag, '412');
    expect(same.position, NeighbourPosition.sameDag);
    expect(same.canContact, isTrue);

    final hidden = first.neighbours[0];
    expect(hidden, karim);
    expect(hidden.canContact, isFalse);

    final unknown = first.neighbours[1];
    expect(unknown.position, NeighbourPosition.unknown);
    expect(unknown.mobile, '01812345678');
    expect(unknown.landQuantity, '2.5');
    expect(unknown.rsDag, '835');
    expect(unknown.csDag, '415');

    expect(first.owners.first, same, reason: 'same-dag owners come first');

    final noDag = d.properties.last;
    expect(noDag.own.propertyId, '13');
    expect(noDag.own.rsDag, isNull);
    expect(noDag.own.dagNumber, isNull);
    expect(noDag.own.hasDag, isFalse);
    expect(noDag.hasOwners, isFalse);
  });

  test('falls back safely on missing keys and unknown dag type', () {
    final d = NeighbourDirectoryDto.fromJson({'dag_type': 'xx'})
        .toEntity(requested: DagType.cs);
    expect(d.dagType, DagType.cs);
    expect(d.plotLimit, 0);
    expect(d.properties, isEmpty);
    expect(d.hasAnyOwner, isFalse);
  });

  test('a hidden contact never leaks a mobile number', () {
    final o = NeighbourOwnerDto.fromJson({
      'owner_name': 'X',
      'mobile': '+8801712345678',
      'contact_hidden': true,
      'position_label': 'near',
    }).toEntity();
    expect(o.mobile, isNull);
    expect(o.position, NeighbourPosition.near);
  });

  test('enum names round-trip', () {
    for (final p in NeighbourPosition.values.where((p) => p != NeighbourPosition.unknown)) {
      expect(NeighbourPositionX.fromName(p.apiName), p);
    }
    expect(DagTypeX.fromName('cs'), DagType.cs);
    expect(DagType.rs.apiName, 'rs');
    expect(DagType.rs.other, DagType.cs);
  });
}
