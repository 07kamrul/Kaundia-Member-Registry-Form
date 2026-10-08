import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/management/data/admin_repository.dart';
import 'package:kaundia_app/features/management/domain/admin_entities.dart';
import 'package:kaundia_app/features/management/presentation/bloc/config_lists_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminRepository extends Mock implements AdminRepository {}

ConfigListItem _item(String id, {bool active = true, String label = 'লেবেল', int order = 0}) =>
    ConfigListItem(
      id: id,
      category: 'property_type',
      value: 'value-$id',
      label: label,
      sortOrder: order,
      isActive: active,
    );

void main() {
  late _MockAdminRepository repository;

  setUp(() {
    repository = _MockAdminRepository();
    when(() => repository.listConfigListItems(any()))
        .thenAnswer((_) async => []);
  });

  group('ConfigListsCubit', () {
    test('selectCategory reloads the items for that category', () async {
      when(() => repository.listConfigListItems('document_type'))
          .thenAnswer((_) async => [_item('1')]);
      final cubit = ConfigListsCubit(repository: repository);
      cubit.selectCategory('document_type');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.selectedCategory, 'document_type');
      expect(cubit.state.items.single.id, '1');
      verify(() => repository.listConfigListItems(category: 'document_type')).called(1);
    });

    blocTest<ConfigListsCubit, ConfigListsState>(
      'toggleActive flips the flag via PATCH and replaces the item',
      build: () {
        when(() => repository.updateConfigListItem(
              any(),
              label: any(named: 'label'),
              sortOrder: any(named: 'sortOrder'),
              isActive: any(named: 'isActive'),
            )).thenAnswer((_) async => _item('1', active: false));
        when(() => repository.listConfigListItems(any()))
            .thenAnswer((_) async => [_item('1')]);
        return ConfigListsCubit(repository: repository)..load();
      },
      seed: () => ConfigListsState(
        items: [_item('1', active: true)],
        loading: false,
      ),
      act: (cubit) => cubit.toggleActive(_item('1', active: true)),
      expect: () => [
        predicate<ConfigListsState>((s) => s.busyId == '1' && s.items.single.isActive),
        predicate<ConfigListsState>((s) =>
            s.busyId == null && !s.items.single.isActive),
      ],
      verify: (_) {
        verify(() => repository.updateConfigListItem(
              '1',
              label: null,
              sortOrder: null,
              isActive: false,
            )).called(1);
      },
    );

    blocTest<ConfigListsCubit, ConfigListsState>(
      'toggleActive failure keeps item and sets error',
      build: () {
        when(() => repository.updateConfigListItem(
              any(),
              label: any(named: 'label'),
              sortOrder: any(named: 'sortOrder'),
              isActive: any(named: 'isActive'),
            )).thenThrow(const ApiException(type: ApiExceptionType.network));
        return ConfigListsCubit(repository: repository);
      },
      seed: () => ConfigListsState(items: [_item('1')], loading: false),
      act: (cubit) => cubit.toggleActive(_item('1')),
      expect: () => [
        predicate<ConfigListsState>((s) => s.busyId == '1'),
        predicate<ConfigListsState>((s) => s.busyId == null && s.error != null),
      ],
    );

    blocTest<ConfigListsCubit, ConfigListsState>(
      'inline label edit saves trimmed label and clears editing state',
      build: () {
        when(() => repository.updateConfigListItem(any(), label: 'নতুন'))
            .thenAnswer((_) async => _item('1', label: 'নতুন'));
        return ConfigListsCubit(repository: repository);
      },
      seed: () => ConfigListsState(
        items: [_item('1', label: 'পুরনো')],
        loading: false,
        editingId: '1',
      ),
      act: (cubit) => cubit.saveLabel(_item('1', label: 'পুরনো'), ' নতুন '),
      expect: () => [
        predicate<ConfigListsState>((s) => s.busyId == '1'),
        predicate<ConfigListsState>((s) =>
            s.busyId == null && s.editingId == null && s.items.single.label == 'নতুন'),
      ],
    );

    blocTest<ConfigListsCubit, ConfigListsState>(
      'inline label edit with unchanged label just cancels editing',
      build: () => ConfigListsCubit(repository: repository),
      seed: () => ConfigListsState(
        items: [_item('1', label: 'একই')],
        loading: false,
        editingId: '1',
      ),
      act: (cubit) => cubit.saveLabel(_item('1', label: 'একই'), 'একই'),
      expect: () => [
        predicate<ConfigListsState>((s) => s.editingId == null && s.busyId == null),
      ],
      verify: (_) {
        verifyNever(() => repository.updateConfigListItem(any(), label: any(named: 'label')));
      },
    );

    blocTest<ConfigListsCubit, ConfigListsState>(
      'addItem falls back to the value when the label is empty',
      build: () {
        when(() => repository.createConfigListItem(
              category: any(named: 'category'),
              value: any(named: 'value'),
              label: any(named: 'label'),
              sortOrder: any(named: 'sortOrder'),
            )).thenAnswer((_) async => _item('9'));
        return ConfigListsCubit(repository: repository);
      },
      act: (cubit) => cubit.addItem('  নতুন ভ্যালু  ', '  '),
      verify: (_) {
        verify(() => repository.createConfigListItem(
              category: 'property_type',
              value: 'নতুন ভ্যালু',
              label: 'নতুন ভ্যালু',
              sortOrder: 0,
            )).called(1);
      },
    );
  });
}
