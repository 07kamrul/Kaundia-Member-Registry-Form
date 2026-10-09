import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/features/member/data/member_repository.dart';
import 'package:kaundia_app/features/member/domain/member_entities.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

Map<String, dynamic> _profile([Map<String, dynamic> extra = const {}]) => {
      'member_id': 1,
      'status': 'approved',
      'full_name': 'A',
      'father_or_husband': 'B',
      'mother': 'C',
      'dob': '1990-01-01',
      'mobile': '+8801700000000',
      'properties': [],
      'nominees': [],
      ...extra,
    };

void main() {
  test('show_in_neighbour_directory defaults to true when absent', () {
    expect(memberProfileFromApi(_profile()).showInNeighbourDirectory, isTrue);
  });

  test('show_in_neighbour_directory false is mapped', () {
    expect(
      memberProfileFromApi(_profile({'show_in_neighbour_directory': false}))
          .showInNeighbourDirectory,
      isFalse,
    );
  });

  test('preference is non-core: never triggers re-review', () {
    final current = memberProfileFromApi(_profile());
    expect(
      const MemberProfileUpdate(showInNeighbourDirectory: false)
          .touchesCoreFields(current),
      isFalse,
    );
  });

  test('PATCH body carries the boolean', () async {
    final api = _MockApiClient();
    when(() => api.patch('/member/profile', any()))
        .thenAnswer((_) async => _profile({'show_in_neighbour_directory': false}));
    final updated = await MemberRepository(apiClient: api).updateProfile(
        const MemberProfileUpdate(showInNeighbourDirectory: false));
    final body = verify(() => api.patch('/member/profile', captureAny()))
        .captured
        .single as Map<String, Object?>;
    expect(body, {'show_in_neighbour_directory': false});
    expect(updated.showInNeighbourDirectory, isFalse);
  });
}
