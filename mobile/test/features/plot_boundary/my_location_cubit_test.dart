import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/plot_boundary/domain/geo.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/my_location_cubit.dart';
import 'package:latlong2/latlong.dart';

const _society = SocietyBbox(
  minLng: 90.3000,
  minLat: 23.7800,
  maxLng: 90.3470,
  maxLat: 23.8380,
);

MyLocationCubit _cubit(PositionProvider provider) =>
    MyLocationCubit(society: _society, positionProvider: provider);

void main() {
  test('a position inside the society is reported as located', () async {
    final cubit = _cubit(() async => const LatLng(23.809, 90.323));

    await cubit.locate();

    expect(cubit.state.status, MyLocationStatus.located);
    expect(cubit.state.point, const LatLng(23.809, 90.323));
    await cubit.close();
  });

  test('a position within the 400 m tolerance still counts as inside',
      () async {
    final cubit = _cubit(() async => const LatLng(23.8400, 90.323));

    await cubit.locate();

    expect(cubit.state.status, MyLocationStatus.located);
    await cubit.close();
  });

  test('a position far away is outside and keeps the previous dot', () async {
    var calls = 0;
    final cubit = _cubit(() async {
      calls++;
      return calls == 1
          ? const LatLng(23.809, 90.323)
          : const LatLng(23.9, 90.5);
    });
    await cubit.locate();

    await cubit.locate();

    expect(cubit.state.status, MyLocationStatus.outsideSociety);
    expect(cubit.state.point, const LatLng(23.809, 90.323));
    await cubit.close();
  });

  test('denied permission is a failure', () async {
    final cubit = _cubit(() async => null);

    await cubit.locate();

    expect(cubit.state.status, MyLocationStatus.failure);
    await cubit.close();
  });

  test('platform and timeout errors are failures, not crashes', () async {
    for (final error in <Exception>[
      PlatformException(code: 'x'),
      TimeoutException('slow'),
    ]) {
      final cubit = _cubit(() async => throw error);

      await cubit.locate();

      expect(cubit.state.status, MyLocationStatus.failure);
      await cubit.close();
    }
  });

  test('every request bumps the serial and starts as locating', () async {
    final completer = Completer<LatLng?>();
    final cubit = _cubit(() => completer.future);

    final pending = cubit.locate();

    expect(cubit.state.status, MyLocationStatus.locating);
    expect(cubit.state.serial, 1);
    completer.complete(const LatLng(23.809, 90.323));
    await pending;
    expect(cubit.state.serial, 1);
    await cubit.close();
  });

  test('without a configured society every position is accepted', () async {
    final cubit = MyLocationCubit(
      positionProvider: () async => const LatLng(0, 0),
    );

    await cubit.locate();

    expect(cubit.state.status, MyLocationStatus.located);
    await cubit.close();
  });
}
