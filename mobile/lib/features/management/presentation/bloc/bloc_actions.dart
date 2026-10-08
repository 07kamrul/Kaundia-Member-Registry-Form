import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Awaits a mutating event's outcome via its optional `completer` channel —
/// the Bloc replacement for the old cubit methods' `Future<bool>` returns.
Future<bool> dispatchForBool(
    Bloc bloc, Object Function(Completer<bool> completer) build) {
  final completer = Completer<bool>();
  bloc.add(build(completer));
  return completer.future;
}
