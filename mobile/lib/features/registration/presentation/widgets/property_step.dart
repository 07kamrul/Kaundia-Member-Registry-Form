import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/enums/enums.dart';
import '../../domain/registration_validators.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart';
import '../bloc/registration_state.dart';
import 'registration_inputs.dart';
import 'registration_l10n.dart';

/// Step 2: property count + N serially-numbered property blocks
/// (property-list/property-item components).
class PropertyStep extends StatelessWidget {
  const PropertyStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final f = state.form;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegSectionTitle(text: l10n.registrationStepTitlesProperty),
        RegDropdown(
          label: l10n.registrationPropertyCountLabel,
          required: true,
          value: f.propertyCount?.toString() ?? '',
          items: [for (var i = 1; i <= 9; i++) '$i'],
          error: findError(state.stepErrors, RegErrorKind.propertyCountRequired) != null
              ? l10n.registrationValidationPropertyCountRequired
              : null,
          onChanged: (v) => bloc.add(PropertyCountChanged(int.tryParse(v ?? '') ?? 0)),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < f.properties.length; i++)
          _PropertyCard(index: i),
        if (state.fileError != null && state.fileError!.propertyIndex != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _fileErrorText(context, state.fileError!),
          ),
      ],
    );
  }
}

Widget _fileErrorText(BuildContext context, FilePickError error) {
  final l10n = AppLocalizations.of(context);
  return Text(
    error.kind == FileErrorKind.type
        ? l10n.registrationPropertyDocFileTypeError
        : l10n.registrationPropertyDocFileSizeError(5),
    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
  );
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final p = state.form.properties[index];
    final errs = state.stepErrors;

    String? propErr(RegErrorKind kind) {
      final e = findError(errs, kind, propertyIndex: index);
      return e == null ? null : regErrorMessage(l10n, e);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.registrationPropertyItemTitle} #${index + 1}',
            style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 12),
          RegLabel(required: true, text: l10n.registrationPropertyTypeLabel, error: propErr(RegErrorKind.propertyTypeRequired)),
          Wrap(
            children: [
              for (final t in state.propertyTypes)
                SizedBox(
                  width: 220,
                  child: RegCheckboxRow(
                    value: p.propertyType.contains(t),
                    label: t,
                    onChanged: (_) => bloc.add(PropertyTypeToggled(index, t)),
                  ),
                ),
            ],
          ),
          if (p.propertyType.contains('অন্যান্য'))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: RegTextField(
                label: l10n.registrationPropertyTypeOtherPlaceholder,
                value: p.propertyTypeOther,
                onChanged: (v) => bloc.add(PropertyFieldChanged(index, PropertyField.propertyTypeOther, v)),
              ),
            ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final fields = <Widget>[
              RegTextField(
                label: l10n.registrationPropertyKhatianNoLabel,
                required: true,
                value: p.khatianNo,
                error: propErr(RegErrorKind.khatianRequired),
                onChanged: (v) => bloc.add(PropertyFieldChanged(index, PropertyField.khatianNo, v)),
              ),
              RegTextField(
                label: l10n.registrationPropertyHoldingNumberLabel,
                value: p.holdingNumber,
                onChanged: (v) => bloc.add(PropertyFieldChanged(index, PropertyField.holdingNumber, v)),
              ),
            ];
            if (constraints.maxWidth >= 600) {
              return Row(children: [for (final f in fields) Expanded(child: f)]);
            }
            return Column(children: fields);
          }),
          const SizedBox(height: 12),
          RegLabel(required: true, text: l10n.registrationPropertyDagNoLabel),
          Row(
            children: [
              Expanded(
                child: RegTextField(
                  label: 'CS',
                  value: p.dagNoCs,
                  error: _dagError(context, 'cs'),
                  onChanged: (v) => bloc.add(PropertyFieldChanged(index, PropertyField.dagNoCs, v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RegTextField(
                  label: 'RS',
                  value: p.dagNoRs,
                  error: _dagError(context, 'rs'),
                  onChanged: (v) => bloc.add(PropertyFieldChanged(index, PropertyField.dagNoRs, v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RegTextField(
            label: l10n.registrationPropertyLandQuantityLabel,
            required: true,
            value: p.landQuantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hint: l10n.registrationPropertyLandQuantityPlaceholder,
            error: propErr(RegErrorKind.landQuantityRequired) ?? propErr(RegErrorKind.landQuantityInvalid),
            onChanged: (v) => bloc.add(PropertyFieldChanged(index, PropertyField.landQuantity, v)),
          ),
          const SizedBox(height: 12),
          RegTextField(
            label: l10n.registrationPropertyMyShareQuantityLabel,
            required: true,
            value: p.myShareQuantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hint: l10n.registrationPropertyMyShareQuantityPlaceholder,
            error: propErr(RegErrorKind.shareQuantityRequired) ??
                propErr(RegErrorKind.shareQuantityInvalid) ??
                propErr(RegErrorKind.shareQuantityExceedsTotal),
            onChanged: (v) => bloc.add(PropertyFieldChanged(index, PropertyField.myShareQuantity, v)),
          ),
          const SizedBox(height: 12),
          RegLabel(
            required: true,
            text: l10n.registrationPropertyOwnershipLabel,
            error: propErr(RegErrorKind.ownershipRequired),
          ),
          Row(
            children: [
              Expanded(
                child: RegRadioRow<OwnershipType>(
                  value: OwnershipType.single,
                  groupValue: p.ownership == OwnershipType.unknown ? null : p.ownership,
                  label: 'একক',
                  onChanged: (o) => bloc.add(OwnershipSelected(index, o)),
                ),
              ),
              Expanded(
                child: RegRadioRow<OwnershipType>(
                  value: OwnershipType.joint,
                  groupValue: p.ownership == OwnershipType.unknown ? null : p.ownership,
                  label: 'যৌথ',
                  onChanged: (o) => bloc.add(OwnershipSelected(index, o)),
                ),
              ),
            ],
          ),
          if (p.isJoint)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: RegTextField(
                label: l10n.registrationPropertyJointOwnerCountLabel,
                required: true,
                value: p.jointOwnerCount?.toString() ?? '',
                keyboardType: TextInputType.number,
                error: propErr(RegErrorKind.jointOwnerCountRequired),
                onChanged: (v) => bloc.add(JointOwnerCountChanged(index, int.tryParse(v))),
              ),
            ),
          const SizedBox(height: 12),
          RegLabel(
            required: true,
            text: l10n.registrationPropertyApplicableDocsLabel,
            error: propErr(RegErrorKind.applicableDocsRequired),
          ),
          for (final docType in state.documentOptions)
            _DocSection(index: index, docType: docType),
        ],
      ),
    );
  }

  String? _dagError(BuildContext context, String which) {
    final state = context.watch<RegistrationBloc>().state;
    final l10n = AppLocalizations.of(context);
    final kind = which == 'cs' ? RegErrorKind.dagCsRequired : RegErrorKind.dagRsRequired;
    final e = findError(state.stepErrors, kind, propertyIndex: index);
    return e == null ? null : regErrorMessage(l10n, e).split(': ').last;
  }
}

/// One checkbox + per-doc attachment picker (JPG/PNG/PDF ≤5MB).
class _DocSection extends StatelessWidget {
  const _DocSection({required this.index, required this.docType});

  final int index;
  final String docType;

  Future<void> _pickFile(BuildContext context) async {
    final bloc = context.read<RegistrationBloc>();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final file = result?.files.singleOrNull;
    if (file == null || file.path == null) return;
    bloc.add(DocFileAttached(index, docType, file.path!, file.name));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final p = state.form.properties[index];
    final doc = p.applicableDocs.where((d) => d.type == docType).firstOrNull;
    final missing = findError(state.stepErrors, RegErrorKind.docFileRequired, propertyIndex: index, docType: docType) != null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RegCheckboxRow(
            value: doc != null,
            label: docType,
            onChanged: (_) => bloc.add(DocToggled(index, docType)),
          ),
          if (doc != null)
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (doc.hasFile)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doc.fileName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () => bloc.add(DocFileRemoved(index, docType)),
                          child: Text(l10n.registrationPropertyRemoveFileButton),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: Text(l10n.registrationPropertyAttachFileButton),
                      onPressed: () => _pickFile(context),
                    ),
                  Text(l10n.registrationPropertyMaxFileSizeNote(5), style: const TextStyle(fontSize: 11)),
                  if (missing && !doc.hasFile)
                    Text(
                      l10n.registrationPropertyDocFileMissing,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 11),
                    ),
                  if (doc.hasFile && !File(doc.path!).existsSync())
                    Text(
                      l10n.registrationDraftReattachFilesNotice,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 11),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

extension _SingleOrNull<T> on Iterable<T> {
  T? get singleOrNull => isEmpty ? null : (length == 1 ? first : null);
}
