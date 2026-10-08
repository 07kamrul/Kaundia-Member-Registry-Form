import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/management/data/admin_repository.dart';
import 'package:kaundia_app/features/management/domain/admin_entities.dart';
import 'package:kaundia_app/features/management/presentation/bloc/config_lists_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminRepository extends Mock implements AdminRepository {}

ConfigListItem _item(String id,
        {bool active = true, String label = 'লেবেল', int order = 0}) =>
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

  group('ConfigListsBloc', () {
    test('ConfigListsCategorySelected reloads the items for that category',
        () async {
      when(() => repository.listConfigListItems('document_type'))
          .thenAnswer((_) async => [_item('1')]);
      final bloc = ConfigListsBloc(repository: repository);
      bloc.add(const ConfigListsCategorySelected('document_type'));
      await bloc.stream.firstWhere((s) => !s.loading && s.items.isNotEmpty);
      expect(bloc.state.selectedCategory, 'document_type');
      expect(bloc.state.items.single.id, '1');
      verify(() => repository.listConfigListItems('document_type')).called(1);
      await bloc.close();
    });

    blocTest<ConfigListsBloc, ConfigListsState>(
      'ConfigListItemToggleActiveRequested flips the flag via PATCH and replaces the item',
      build: () {
        when(() => repository.updateConfigListItem(
              any(),
              label: any(named: 'label'),
              sortOrder: any(named: 'sortOrder'),
              isActive: any(named: 'isActive'),
            )).thenAnswer((_) async => _item('1', active: false));
        when(() => repository.listConfigListItems(any()))
            .thenAnswer((_) async => [_item('1')]);
        return ConfigListsBloc(repository: repository);
      },
      seed: () => ConfigListsData(
        items: [_item('1', active: true)],
        loading: false,
      ),
      act: (bloc) => bloc
          .add(ConfigListItemToggleActiveRequested(_item('1', active: true))),
      expect: () => [
        predicate<ConfigListsState>(
            (s) => s.busyId == '1' && s.items.single.isActive),
        predicate<ConfigListsState>(
            (s) => s.busyId == null && !s.items.single.isActive),
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

    blocTest<ConfigListsBloc, ConfigListsState>(
      'ConfigListItemToggleActiveRequested failure keeps item and sets error',
      build: () {
        when(() => repository.updateConfigListItem(
              any(),
              label: any(named: 'label'),
              sortOrder: any(named: 'sortOrder'),
              isActive: any(named: 'isActive'),
            )).thenThrow(const ApiException(type: ApiExceptionType.network));
        return ConfigListsBloc(repository: repository);
      },
      seed: () => ConfigListsData(items: [_item('1')], loading: false),
      act: (bloc) => bloc.add(ConfigListItemToggleActiveRequested(_item('1'))),
      expect: () => [
        predicate<ConfigListsState>((s) => s.busyId == '1'),
        predicate<ConfigListsState>((s) => s.busyId == null && s.error != null),
      ],
    );

    blocTest<ConfigListsBloc, ConfigListsState>(
      'inline label edit saves trimmed label and clears editing state',
      build: () {
        when(() => repository.updateConfigListItem(any(), label: 'নতুন'))
            .thenAnswer((_) async => _item('1', label: 'নতুন'));
        return ConfigListsBloc(repository: repository);
      },
      seed: () => ConfigListsData(
        items: [_item('1', label: 'পুরনো')],
        loading: false,
        editingId: '1',
      ),
      act: (bloc) => bloc.add(ConfigListItemLabelSaveRequested(
          _item('1', label: 'পুরনো'), ' নতুন ')),
      expect: () => [
        predicate<ConfigListsState>((s) => s.busyId == '1'),
        predicate<ConfigListsState>((s) =>
            s.busyId == null &&
            s.editingId == null &&
            s.items.single.label == 'নতুন'),
      ],
    );

    blocTest<ConfigListsBloc, ConfigListsState>(
      'inline label edit with unchanged label just cancels editing',
      build: () => ConfigListsBloc(repository: repository),
      seed: () => ConfigListsData(
        items: [_item('1', label: 'একই')],
        loading: false,
        editingId: '1',
      ),
      act: (bloc) => bloc.add(
          ConfigListItemLabelSaveRequested(_item('1', label: 'একই'), 'একই')),
      expect: () => [
        predicate<ConfigListsState>(
            (s) => s.editingId == null && s.busyId == null),
      ],
      verify: (_) {
        verifyNever(() =>
            repository.updateConfigListItem(any(), label: any(named: 'label')));
      },
    );

    blocTest<ConfigListsBloc, ConfigListsState>(
      'ConfigListItemAddRequested falls back to the value when the label is empty',
      build: () {
        when(() => repository.createConfigListItem(
              category: any(named: 'category'),
              value: any(named: 'value'),
              label: any(named: 'label'),
              sortOrder: any(named: 'sortOrder'),
            )).thenAnswer((_) async => _item('9'));
        return ConfigListsBloc(repository: repository);
      },
      act: (bloc) =>
          bloc.add(const ConfigListItemAddRequested('  নতুন ভ্যালু  ', '  ')),
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
