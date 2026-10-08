import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/member_repository.dart';
import '../presentation/bloc/property_request_form_bloc.dart';

/// Port of Angular PropertyRequestFormComponent: add/edit property change
/// request — property details, co-owners, kept existing docs + new doc uploads,
/// submitted as multipart (action / property_id / payload JSON / doc_files[]).
class PropertyRequestFormPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const PropertyRequestFormPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PropertyRequestFormBloc(
        repository: MemberRepository(apiClient: sl<ApiClient>()),
      )..add(PropertyRequestFormInitialized(propertyId: propertyId)),
      child: const _FormView(),
    );
  }
}

const _propertyTypeOptions = ['land', 'flat', 'commercial', 'other'];

class _FormView extends StatelessWidget {
  const _FormView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocConsumer<PropertyRequestFormBloc, PropertyRequestFormState>(
        listener: (context, state) {
          if (state.status == PropertyRequestFormStatus.submitted) {
            showAppToast(context, loc.memberPropertyRequestsSuccessSent);
            Future<void>.delayed(const Duration(milliseconds: 1200), () {
              if (context.mounted) context.go('/profile');
            });
          }
          final err = state.submitError;
          if (err != null) {
            showAppToast(
              context,
              switch (err) {
                'submitFailed' => loc.memberPropertyRequestsErrorsSubmitFailed,
                'docFileSizeError' => loc.registrationPropertyDocFileSizeError(10),
                _ => err,
              },
              error: true,
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<PropertyRequestFormBloc>();
          if (state.status == PropertyRequestFormStatus.loading) {
            return const SkeletonLoader(lines: 6);
          }
          if (state.error) {
            return InlineError(
              message: loc.memberPropertyRequestsErrorsPropertyNotFound,
              onRetry: () => bloc.add(
                  PropertyRequestFormInitialized(propertyId: state.propertyId)),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              PageHeader(
                title: state.isEdit
                    ? loc.memberPropertyRequestsEditTitle
                    : loc.memberPropertyRequestsAddTitle,
                subtitle: loc.memberPropertyRequestsFormSubtitle,
              ),
              AppCard(
                title: loc.memberPropertyRequestsPropertySectionTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.registrationPropertyTypeLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Wrap(
                      children: [
                        for (final t in _propertyTypeOptions)
                          FilterChip(
                            label: Text(t),
                            selected: state.propertyType.contains(t),
                            onSelected: (sel) {
                              final next = [...state.propertyType];
                              sel ? next.add(t) : next.remove(t);
                              bloc.add(PropertyRequestFormFieldChanged(propertyType: next));
                            },
                          ),
                      ],
                    ),
                    if (state.propertyTypeMissing)
                      _error(loc.registrationPropertyTypeRequired),
                    const SizedBox(height: 8),
                    _field(
                      loc.registrationPropertyTypeOtherPlaceholder,
                      state.propertyTypeOther,
                      (v) => bloc.add(PropertyRequestFormFieldChanged(propertyTypeOther: v)),
                    ),
                    _field(loc.memberProfileKhatianLabel, state.khatianNo,
                        (v) => bloc.add(PropertyRequestFormFieldChanged(khatianNo: v)),
                        error: state.khatianNoMissing ? loc.registrationPropertyKhatianNoRequired : null),
                    _field('CS ${loc.memberProfileDagNoCsLabel}', state.dagNoCs,
                        (v) => bloc.add(PropertyRequestFormFieldChanged(dagNoCs: v)),
                        error: state.dagNoCsMissing ? loc.registrationPropertyDagNoCsRequired : null),
                    _field('RS ${loc.memberProfileDagNoRsLabel}', state.dagNoRs,
                        (v) => bloc.add(PropertyRequestFormFieldChanged(dagNoRs: v)),
                        error: state.dagNoRsMissing ? loc.registrationPropertyDagNoRsRequired : null),
                    _field(loc.memberProfileHoldingNumberLabel, state.holdingNumber,
                        (v) => bloc.add(PropertyRequestFormFieldChanged(holdingNumber: v))),
                    _field(loc.memberProfileLandQuantityLabel, state.landQuantity,
                        (v) => bloc.add(PropertyRequestFormFieldChanged(landQuantity: v)),
                        error: state.landQuantityMissing
                            ? loc.registrationPropertyLandQuantityRequired
                            : (state.landQuantityInvalid
                                ? loc.registrationPropertyLandQuantityInvalid
                                : null)),
                    _field(loc.memberProfileMyShareQuantityLabel, state.myShareQuantity,
                        (v) => bloc.add(PropertyRequestFormFieldChanged(myShareQuantity: v)),
                        error: state.myShareQuantityMissing
                            ? loc.registrationPropertyMyShareQuantityRequired
                            : (state.myShareQuantityInvalid
                                ? loc.registrationPropertyMyShareQuantityInvalid
                                : null)),
                    DropdownButtonFormField<String>(
                      initialValue:
                          state.ownership.isEmpty ? null : state.ownership,
                      decoration: InputDecoration(
                        labelText: loc.memberProfileOwnershipLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'একক', child: Text('একক')),
                        DropdownMenuItem(value: 'যৌথ', child: Text('যৌথ')),
                      ],
                      onChanged: (v) =>
                          bloc.add(PropertyRequestFormFieldChanged(ownership: v ?? '')),
                    ),
                    if (state.ownershipMissing) _error(loc.registrationPropertyOwnershipRequired),
                  ].expand((w) sync* {
                    yield w;
                    yield const SizedBox(height: 10);
                  }).toList(),
                ),
              ),
              // Co-owners.
              AppCard(
                title: loc.memberPropertyRequestsCoOwnersLabel,
                trailing: IconButton(
                  tooltip: loc.memberPropertyRequestsAddCoOwnerButton,
                  icon: const Icon(Icons.add),
                  onPressed: () => bloc.add(const PropertyRequestFormCoOwnerAdded()),
                ),
                child: state.coOwners.isEmpty
                    ? Text(loc.commonNoData)
                    : Column(
                        children: [
                          for (var i = 0; i < state.coOwners.length; i++)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: loc.memberPropertyRequestsCoOwnerNamePlaceholder,
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (v) => bloc.add(
                                        PropertyRequestFormCoOwnerChanged(
                                            i, state.coOwners[i].copyWith(ownerName: v))),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: loc.memberProfileMobileLabel,
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    onChanged: (v) => bloc.add(
                                        PropertyRequestFormCoOwnerChanged(
                                            i, state.coOwners[i].copyWith(ownerPhone: v))),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      bloc.add(PropertyRequestFormCoOwnerRemoved(i)),
                                ),
                              ],
                            ),
                        ],
                      ),
              ),
              // Existing docs (edit mode).
              if (state.isEdit)
                AppCard(
                  title: loc.memberPropertyRequestsExistingDocsLabel,
                  child: state.existingDocs.isEmpty
                      ? Text(loc.memberPropertyRequestsNoExistingDocs)
                      : Column(
                          children: [
                            for (var i = 0; i < state.existingDocs.length; i++)
                              CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(state.existingDocs[i].docType),
                                subtitle: Text(state.existingDocs[i].keep
                                    ? loc.memberPropertyRequestsDocKept
                                    : loc.memberPropertyRequestsDocDropped),
                                value: state.existingDocs[i].keep,
                                onChanged: (v) => bloc.add(
                                    PropertyRequestFormExistingDocKeepChanged(i,
                                        keep: v ?? true)),
                              ),
                          ],
                        ),
                ),
              // New docs.
              AppCard(
                title: loc.memberPropertyRequestsNewDocsLabel,
                trailing: IconButton(
                  tooltip: loc.memberPropertyRequestsAddDocButton,
                  icon: const Icon(Icons.add),
                  onPressed: () => bloc.add(const PropertyRequestFormDocAdded()),
                ),
                child: state.newDocs.isEmpty
                    ? Text(loc.memberPropertyRequestsDocsLabel)
                    : Column(
                        children: [
                          for (var i = 0; i < state.newDocs.length; i++)
                            _newDocRow(context, bloc, state, i, loc),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppButton(
                  label: state.status == PropertyRequestFormStatus.submitting
                      ? loc.commonLoading
                      : loc.memberPropertyRequestsSubmitButton,
                  expanded: true,
                  onPressed: state.status == PropertyRequestFormStatus.submitting
                      ? null
                      : () => bloc.add(const PropertyRequestFormSubmitted()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _newDocRow(
    BuildContext context,
    PropertyRequestFormBloc bloc,
    PropertyRequestFormState state,
    int index,
    AppLocalizations loc,
  ) {
    final row = state.newDocs[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: row.docType.isEmpty ? null : row.docType,
              decoration: InputDecoration(
                labelText: loc.memberProfileDocumentLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final d in const ['khatian', 'mutation', 'ra_deed', 'other'])
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (v) =>
                  bloc.add(PropertyRequestFormDocChanged(index, row.copyWith(docType: v ?? ''))),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.localPath?.split('/').last ?? loc.rbFormDropzoneHint,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppButton(
                  label: loc.registrationPropertyAttachFileButton,
                  variant: AppButtonVariant.ghost,
                  icon: Icons.attach_file,
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                    );
                    final path = result?.files.single.path;
                    if (path == null) return;
                    bloc.add(PropertyRequestFormDocChanged(
                      index,
                      row.copyWith(localPath: path, clearError: true),
                    ));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => bloc.add(PropertyRequestFormDocRemoved(index)),
                ),
              ],
            ),
            if (row.error != null)
              Text(row.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value, ValueChanged<String> onChanged,
      {String? error}) {
    return TextField(
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  Widget _error(String message) => Text(
        message,
        style: const TextStyle(color: Color(0xFF9C3A2C)),
      );
}
