import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/enums/enums.dart';
import '../../domain/registration_validators.dart';
import '../bloc/registration_bloc.dart';
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegSectionTitle(text: l10n.registrationStepTitlesProperty),
        RegSectionCard(
          child: RegDropdown(
            label: l10n.registrationPropertyCountLabel,
            required: true,
            value: f.propertyCount?.toString() ?? '',
            items: [for (var i = 1; i <= 9; i++) '$i'],
            error: findError(state.stepErrors, RegErrorKind.propertyCountRequired) != null
                ? l10n.registrationValidationPropertyCountRequired
                : null,
            onChanged: (v) => bloc.add(PropertyCountChanged(int.tryParse(v ?? '') ?? 0)),
          ),
        ),
        for (var i = 0; i < f.properties.length; i++) _PropertyCard(index: i),
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
  final theme = Theme.of(context);
  return Text(
    error.kind == FileErrorKind.type
        ? l10n.registrationPropertyDocFileTypeError
        : l10n.registrationPropertyDocFileSizeError(5),
    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
  );
}

/// Lays checkbox options out in two columns when there is room.
class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 440;
        final width = twoColumns ? (constraints.maxWidth - 8) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 8,
          children: [for (final c in children) SizedBox(width: width, child: c)],
        );
      },
    );
  }
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

    void change(PropertyField field, String v) => bloc.add(PropertyFieldChanged(index, field, v));

    return RegSectionCard(
      title: '${l10n.registrationPropertyItemTitle} #${index + 1}',
      icon: Icons.home_work_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegLabel(
            required: true,
            text: l10n.registrationPropertyTypeLabel,
            error: propErr(RegErrorKind.propertyTypeRequired),
          ),
          _OptionGrid(
            children: [
              for (final t in state.propertyTypes)
                RegCheckboxRow(
                  value: p.propertyType.contains(t),
                  label: t,
                  onChanged: (_) => bloc.add(PropertyTypeToggled(index, t)),
                ),
            ],
          ),
          if (p.propertyType.contains('অন্যান্য'))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: RegTextField(
                label: l10n.registrationPropertyTypeOtherPlaceholder,
                value: p.propertyTypeOther,
                onChanged: (v) => change(PropertyField.propertyTypeOther, v),
              ),
            ),
          const SizedBox(height: 12),
          RegFieldPair(
            first: RegTextField(
              label: l10n.registrationPropertyKhatianNoLabel,
              required: true,
              value: p.khatianNo,
              prefixIcon: Icons.tag,
              error: propErr(RegErrorKind.khatianRequired),
              onChanged: (v) => change(PropertyField.khatianNo, v),
            ),
            second: RegTextField(
              label: l10n.registrationPropertyHoldingNumberLabel,
              value: p.holdingNumber,
              prefixIcon: Icons.numbers,
              onChanged: (v) => change(PropertyField.holdingNumber, v),
            ),
          ),
          const SizedBox(height: 12),
          RegLabel(required: true, text: l10n.registrationPropertyDagNoLabel),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RegTextField(
                  label: 'CS',
                  value: p.dagNoCs,
                  error: _dagError(context, 'cs'),
                  onChanged: (v) => change(PropertyField.dagNoCs, v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RegTextField(
                  label: 'RS',
                  value: p.dagNoRs,
                  error: _dagError(context, 'rs'),
                  onChanged: (v) => change(PropertyField.dagNoRs, v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RegFieldPair(
            first: RegTextField(
              label: l10n.registrationPropertyLandQuantityLabel,
              required: true,
              value: p.landQuantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hint: l10n.registrationPropertyLandQuantityPlaceholder,
              error: propErr(RegErrorKind.landQuantityRequired) ??
                  propErr(RegErrorKind.landQuantityInvalid),
              onChanged: (v) => change(PropertyField.landQuantity, v),
            ),
            second: RegTextField(
              label: l10n.registrationPropertyMyShareQuantityLabel,
              required: true,
              value: p.myShareQuantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hint: l10n.registrationPropertyMyShareQuantityPlaceholder,
              error: propErr(RegErrorKind.shareQuantityRequired) ??
                  propErr(RegErrorKind.shareQuantityInvalid) ??
                  propErr(RegErrorKind.shareQuantityExceedsTotal),
              onChanged: (v) => change(PropertyField.myShareQuantity, v),
            ),
          ),
          const SizedBox(height: 12),
          _OwnershipField(index: index, error: propErr(RegErrorKind.ownershipRequired)),
          if (p.isJoint)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: RegTextField(
                label: l10n.registrationPropertyJointOwnerCountLabel,
                required: true,
                value: p.jointOwnerCount?.toString() ?? '',
                prefixIcon: Icons.groups_outlined,
                keyboardType: TextInputType.number,
                error: propErr(RegErrorKind.jointOwnerCountRequired),
                onChanged: (v) => bloc.add(JointOwnerCountChanged(index, int.tryParse(v))),
              ),
            ),
          const SizedBox(height: 16),
          RegLabel(
            required: true,
            text: l10n.registrationPropertyApplicableDocsLabel,
            error: propErr(RegErrorKind.applicableDocsRequired),
          ),
          for (final docType in state.documentOptions) _DocSection(index: index, docType: docType),
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

class _OwnershipField extends StatelessWidget {
  const _OwnershipField({required this.index, required this.error});

  final int index;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final p = state.form.properties[index];
    final group = p.ownership == OwnershipType.unknown ? null : p.ownership;
    return RegLabel(
      required: true,
      text: l10n.registrationPropertyOwnershipLabel,
      error: error,
      child: Row(
        children: [
          Expanded(
            child: RegRadioRow<OwnershipType>(
              value: OwnershipType.single,
              groupValue: group,
              label: 'একক',
              onChanged: (o) => bloc.add(OwnershipSelected(index, o)),
            ),
          ),
          Expanded(
            child: RegRadioRow<OwnershipType>(
              value: OwnershipType.joint,
              groupValue: group,
              label: 'যৌথ',
              onChanged: (o) => bloc.add(OwnershipSelected(index, o)),
            ),
          ),
        ],
      ),
    );
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
    final theme = Theme.of(context);
    final p = state.form.properties[index];
    final doc = p.applicableDocs.where((d) => d.type == docType).firstOrNull;
    final missing = findError(
          state.stepErrors,
          RegErrorKind.docFileRequired,
          propertyIndex: index,
          docType: docType,
        ) !=
        null;
    final errorStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegCheckboxRow(
            value: doc != null,
            label: docType,
            onChanged: (_) => bloc.add(DocToggled(index, docType)),
          ),
          if (doc != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 38, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (doc.hasFile)
                    RegFileChip(
                      fileName: doc.fileName,
                      removeLabel: l10n.registrationPropertyRemoveFileButton,
                      onRemove: () => bloc.add(DocFileRemoved(index, docType)),
                    )
                  else
                    OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: Text(l10n.registrationPropertyAttachFileButton),
                      onPressed: () => _pickFile(context),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.registrationPropertyMaxFileSizeNote(5),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                  if (missing && !doc.hasFile)
                    Text(l10n.registrationPropertyDocFileMissing, style: errorStyle),
                  if (doc.hasFile && !File(doc.path!).existsSync())
                    Text(l10n.registrationDraftReattachFilesNotice, style: errorStyle),
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
