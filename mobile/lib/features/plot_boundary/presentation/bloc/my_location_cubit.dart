import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/geo.dart';

enum MyLocationStatus { idle, locating, located, outsideSociety, failure }

class MyLocationState extends Equatable {
  const MyLocationState({
    this.status = MyLocationStatus.idle,
    this.point,
    this.serial = 0,
  });

  final MyLocationStatus status;

  /// Last known device position inside the society (drives the map dot).
  final LatLng? point;

  /// Bumped on every locate request so the page re-centres even when the
  /// result equals the previous one.
  final int serial;

  @override
  List<Object?> get props => [status, point, serial];
}

/// Resolves the device position; null when permission is denied.
typedef PositionProvider = Future<LatLng?> Function();

/// ~400 m tolerance around the society edge (mirrors Angular `insideSociety`).
const double kSocietyTolerance = 0.004;

const Duration _locationTimeout = Duration(seconds: 15);

Future<LatLng?> _devicePosition() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(timeLimit: _locationTimeout),
  );
  return LatLng(pos.latitude, pos.longitude);
}

class MyLocationCubit extends Cubit<MyLocationState> {
  MyLocationCubit({SocietyBbox? society, PositionProvider? positionProvider})
      : _society = society,
        _positionProvider = positionProvider ?? _devicePosition,
        super(const MyLocationState());

  final SocietyBbox? _society;
  final PositionProvider _positionProvider;

  Future<void> locate() async {
    if (state.status == MyLocationStatus.locating) return;
    final serial = state.serial + 1;
    emit(MyLocationState(
      status: MyLocationStatus.locating,
      point: state.point,
      serial: serial,
    ));
    try {
      final point = await _positionProvider();
      if (isClosed) return;
      if (point == null) {
        emit(MyLocationState(
          status: MyLocationStatus.failure,
          point: state.point,
          serial: serial,
        ));
        return;
      }
      final society = _society;
      final inside = society == null ||
          society.inflated(kSocietyTolerance).contains(point);
      emit(MyLocationState(
        status:
            inside ? MyLocationStatus.located : MyLocationStatus.outsideSociety,
        point: inside ? point : state.point,
        serial: serial,
      ));
    } on PermissionDeniedException {
      _fail(serial);
    } on PlatformException {
      _fail(serial);
    } on LocationServiceDisabledException {
      _fail(serial);
    } on TimeoutException {
      _fail(serial);
    }
  }

  void _fail(int serial) {
    if (isClosed) return;
    emit(MyLocationState(
        status: MyLocationStatus.failure,
        point: state.point,
        serial: serial,
      ));
  }
}
