part of 'submissions_bloc.dart';

class SubmissionsState extends Equatable {
  const SubmissionsState({
    this.filter,
    this.items = const [],
    this.loading = false,
    this.error,
  });

  final SubmissionStatus? filter;
  final List<SubmissionSummary> items;
  final bool loading;
  final Object? error;

  SubmissionsState copyWith({
    SubmissionStatus? Function()? filter,
    List<SubmissionSummary>? items,
    bool? loading,
    Object? Function()? error,
  }) =>
      SubmissionsState(
        filter: filter == null ? this.filter : filter(),
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
      );

  @override
  List<Object?> get props => [filter, items, loading, error];
}

final class SubmissionsData extends SubmissionsState {
  const SubmissionsData(
      {super.filter, super.items, super.loading, super.error});
}
