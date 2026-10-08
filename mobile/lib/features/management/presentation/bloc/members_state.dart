part of 'members_bloc.dart';

// ----- Members list -----

class MembersState extends Equatable {
  const MembersState(
      {this.items = const [], this.loading = false, this.error, this.busyId});

  final List<Member> items;
  final bool loading;
  final Object? error;

  /// Member currently being mutated (delete/reset password).
  final String? busyId;

  MembersState copyWith({
    List<Member>? items,
    bool? loading,
    Object? Function() error = _same,
    String? Function() busyId = _same,
  }) =>
      MembersState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error == _same ? this.error : error(),
        busyId: busyId == _same ? this.busyId : busyId(),
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

  @override
  List<Object?> get props => [items, loading, error, busyId];
}
