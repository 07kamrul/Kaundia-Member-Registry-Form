import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/member_repository.dart';
import '../presentation/bloc/property_request_form_bloc.dart';
import '../presentation/widgets/member_ui.dart';

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
const _docTypeOptions = ['khatian', 'mutation', 'ra_deed', 'other'];

/// 'ra_deed' -> 'Ra deed' — display only; the raw value is what gets sent.
String _humanize(String raw) {
  if (raw.isEmpty) return raw;
  final spaced = raw.replaceAll('_', ' ');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

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
          return _form(context, state, loc, bloc);
        },
      ),
    );
  }

  Widget _form(
    BuildContext context,
    PropertyRequestFormState state,
    AppLocalizations loc,
    PropertyRequestFormBloc bloc,
  ) {
    final submitting = state.status == PropertyRequestFormStatus.submitting;
    return PageBody(
      maxWidth: Breakpoints.formMaxWidth,
      children: [
        PageHeader(
          title: state.isEdit
              ? loc.memberPropertyRequestsEditTitle
              : loc.memberPropertyRequestsAddTitle,
          subtitle: loc.memberPropertyRequestsFormSubtitle,
          icon: Icons.home_work_outlined,
        ),
        _PropertyCard(state: state, bloc: bloc),
        _CoOwnersCard(state: state, bloc: bloc),
        if (state.isEdit) _ExistingDocsCard(state: state, bloc: bloc),
        _NewDocsCard(state: state, bloc: bloc),
        Gutter(
          vertical: 12,
          child: AppButton(
            label: submitting ? loc.commonLoading : loc.memberPropertyRequestsSubmitButton,
            icon: Icons.send_outlined,
            expanded: true,
            loading: submitting,
            onPressed: () => bloc.add(const PropertyRequestFormSubmitted()),
          ),
        ),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.state, required this.bloc});

  final PropertyRequestFormState state;
  final PropertyRequestFormBloc bloc;

  void _set(PropertyRequestFormFieldChanged event) => bloc.add(event);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      title: loc.memberPropertyRequestsPropertySectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _typeSection(context, loc),
          const SizedBox(height: 12),
          FieldGrid(children: _fields(loc)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: state.ownership.isEmpty ? null : state.ownership,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: loc.memberProfileOwnershipLabel,
              prefixIcon: const Icon(Icons.people_outline),
              errorText: state.ownershipMissing ? loc.registrationPropertyOwnershipRequired : null,
            ),
            items: const [
              DropdownMenuItem(value: 'একক', child: Text('একক')),
              DropdownMenuItem(value: 'যৌথ', child: Text('যৌথ')),
            ],
            onChanged: (v) => _set(PropertyRequestFormFieldChanged(ownership: v ?? '')),
          ),
        ],
      ),
    );
  }

  Widget _typeSection(BuildContext context, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(loc.registrationPropertyTypeLabel, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _propertyTypeOptions)
              FilterChip(
                label: Text(_humanize(t)),
                selected: state.propertyType.contains(t),
                onSelected: (sel) {
                  final next = [...state.propertyType];
                  sel ? next.add(t) : next.remove(t);
                  _set(PropertyRequestFormFieldChanged(propertyType: next));
                },
              ),
          ],
        ),
        if (state.propertyTypeMissing) _ErrorText(loc.registrationPropertyTypeRequired),
        const SizedBox(height: 12),
        SyncedTextField(
          label: loc.registrationPropertyTypeOtherPlaceholder,
          value: state.propertyTypeOther,
          icon: Icons.edit_outlined,
          onChanged: (v) => _set(PropertyRequestFormFieldChanged(propertyTypeOther: v)),
        ),
      ],
    );
  }

  List<Widget> _fields(AppLocalizations loc) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return [
      SyncedTextField(
        label: loc.memberProfileKhatianLabel,
        value: state.khatianNo,
        icon: Icons.description_outlined,
        errorText: state.khatianNoMissing ? loc.registrationPropertyKhatianNoRequired : null,
        onChanged: (v) => _set(PropertyRequestFormFieldChanged(khatianNo: v)),
      ),
      SyncedTextField(
        label: loc.memberProfileHoldingNumberLabel,
        value: state.holdingNumber,
        icon: Icons.home_outlined,
        onChanged: (v) => _set(PropertyRequestFormFieldChanged(holdingNumber: v)),
      ),
      SyncedTextField(
        label: 'CS ${loc.memberProfileDagNoCsLabel}',
        value: state.dagNoCs,
        icon: Icons.tag,
        errorText: state.dagNoCsMissing ? loc.registrationPropertyDagNoCsRequired : null,
        onChanged: (v) => _set(PropertyRequestFormFieldChanged(dagNoCs: v)),
      ),
      SyncedTextField(
        label: 'RS ${loc.memberProfileDagNoRsLabel}',
        value: state.dagNoRs,
        icon: Icons.tag,
        errorText: state.dagNoRsMissing ? loc.registrationPropertyDagNoRsRequired : null,
        onChanged: (v) => _set(PropertyRequestFormFieldChanged(dagNoRs: v)),
      ),
      SyncedTextField(
        label: loc.memberProfileLandQuantityLabel,
        value: state.landQuantity,
        icon: Icons.square_foot,
        keyboardType: decimal,
        errorText: state.landQuantityMissing
            ? loc.registrationPropertyLandQuantityRequired
            : (state.landQuantityInvalid ? loc.registrationPropertyLandQuantityInvalid : null),
        onChanged: (v) => _set(PropertyRequestFormFieldChanged(landQuantity: v)),
      ),
      SyncedTextField(
        label: loc.memberProfileMyShareQuantityLabel,
        value: state.myShareQuantity,
        icon: Icons.pie_chart_outline,
        keyboardType: decimal,
        errorText: state.myShareQuantityMissing
            ? loc.registrationPropertyMyShareQuantityRequired
            : (state.myShareQuantityInvalid
                ? loc.registrationPropertyMyShareQuantityInvalid
                : null),
        onChanged: (v) => _set(PropertyRequestFormFieldChanged(myShareQuantity: v)),
      ),
    ];
  }
}

class _CoOwnersCard extends StatelessWidget {
  const _CoOwnersCard({required this.state, required this.bloc});

  final PropertyRequestFormState state;
  final PropertyRequestFormBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      title: loc.memberPropertyRequestsCoOwnersLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < state.coOwners.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _CoOwnerRow(index: i, row: state.coOwners[i], bloc: bloc),
          ],
          if (state.coOwnersInvalid) _ErrorText(loc.memberPropertyRequestsCoOwnerNameRequired),
          AddItemButton(
            label: loc.memberPropertyRequestsAddCoOwnerButton,
            icon: Icons.person_add_alt_outlined,
            onPressed: () => bloc.add(const PropertyRequestFormCoOwnerAdded()),
          ),
        ],
      ),
    );
  }
}

class _CoOwnerRow extends StatelessWidget {
  const _CoOwnerRow({required this.index, required this.row, required this.bloc});

  final int index;
  final FormCoOwnerRow row;
  final PropertyRequestFormBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FieldGrid(
            minFieldWidth: 200,
            children: [
              SyncedTextField(
                label: loc.memberPropertyRequestsCoOwnerNamePlaceholder,
                value: row.ownerName,
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                onChanged: (v) =>
                    bloc.add(PropertyRequestFormCoOwnerChanged(index, row.copyWith(ownerName: v))),
              ),
              SyncedTextField(
                label: loc.memberProfileMobileLabel,
                value: row.ownerPhone,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                onChanged: (v) =>
                    bloc.add(PropertyRequestFormCoOwnerChanged(index, row.copyWith(ownerPhone: v))),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: loc.commonDelete,
          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
          onPressed: () => bloc.add(PropertyRequestFormCoOwnerRemoved(index)),
        ),
      ],
    );
  }
}

class _ExistingDocsCard extends StatelessWidget {
  const _ExistingDocsCard({required this.state, required this.bloc});

  final PropertyRequestFormState state;
  final PropertyRequestFormBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final docs = state.existingDocs;
    return AppCard(
      title: loc.memberPropertyRequestsExistingDocsLabel,
      child: docs.isEmpty
          ? Text(loc.memberPropertyRequestsNoExistingDocs)
          : Column(
              children: [
                for (var i = 0; i < docs.length; i++)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    secondary: LeadingIcon(
                      icon: docs[i].keep ? Icons.description_outlined : Icons.block,
                      color: docs[i].keep ? null : Theme.of(context).colorScheme.error,
                      size: 36,
                    ),
                    title: Text(_humanize(docs[i].docType)),
                    subtitle: Text(docs[i].keep
                        ? loc.memberPropertyRequestsDocKept
                        : loc.memberPropertyRequestsDocDropped),
                    value: docs[i].keep,
                    onChanged: (v) =>
                        bloc.add(PropertyRequestFormExistingDocKeepChanged(i, keep: v ?? true)),
                  ),
              ],
            ),
    );
  }
}

class _NewDocsCard extends StatelessWidget {
  const _NewDocsCard({required this.state, required this.bloc});

  final PropertyRequestFormState state;
  final PropertyRequestFormBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      title: loc.memberPropertyRequestsNewDocsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < state.newDocs.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _NewDocRow(index: i, row: state.newDocs[i], bloc: bloc),
          ],
          if (state.docsInvalid) _ErrorText(loc.memberPropertyRequestsDocIncomplete),
          AddItemButton(
            label: loc.memberPropertyRequestsAddDocButton,
            icon: Icons.note_add_outlined,
            onPressed: () => bloc.add(const PropertyRequestFormDocAdded()),
          ),
        ],
      ),
    );
  }
}

class _NewDocRow extends StatelessWidget {
  const _NewDocRow({required this.index, required this.row, required this.bloc});

  final int index;
  final FormDocRow row;
  final PropertyRequestFormBloc bloc;

  Future<void> _pick() async {
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
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fileName = row.localPath?.split(RegExp(r'[\\/]')).last;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: row.docType.isEmpty ? null : row.docType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: loc.memberProfileDocumentLabel,
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                  items: [
                    for (final d in _docTypeOptions)
                      DropdownMenuItem(value: d, child: Text(_humanize(d))),
                  ],
                  onChanged: (v) =>
                      bloc.add(PropertyRequestFormDocChanged(index, row.copyWith(docType: v ?? ''))),
                ),
              ),
              IconButton(
                tooltip: loc.registrationPropertyRemoveFileButton,
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                onPressed: () => bloc.add(PropertyRequestFormDocRemoved(index)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pick,
            icon: Icon(fileName == null ? Icons.attach_file : Icons.check_circle_outline),
            label: Text(
              fileName ?? loc.registrationPropertyAttachFileButton,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (row.error != null) _ErrorText(row.error!),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}
