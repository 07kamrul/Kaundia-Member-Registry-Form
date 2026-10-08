import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../presentation/bloc/fee_settings_cubit.dart';
import '../presentation/widgets/management_widgets.dart';

/// Versioned fee settings (Angular fee-settings): active rows with expandable
/// history, add-version form with confirm dialog, tiered subscription group.
class FeeSettingsPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const FeeSettingsPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<FeeSettingsPage> createState() => _FeeSettingsPageState();
}

class _FeeSettingsPageState extends State<FeeSettingsPage> {
  String _draftKey = '';
  final _valueController = TextEditingController();
  final _baseController = TextEditingController();
  final _rateController = TextEditingController();
  final _thresholdController = TextEditingController();
  String _unit = '';
  String _startDate = '';

  static const _unitOptions = ['taka', 'percent'];

  @override
  void dispose() {
    _valueController.dispose();
    _baseController.dispose();
    _rateController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  String _keyLabel(AppLocalizations loc, String key) => switch (key) {
        'admission_fee' => loc.adminFeeSettingsKeysAdmissionFee,
        'picnic_head_fee' => loc.adminFeeSettingsKeysPicnicHeadFee,
        'picnic_additional_head_fee' =>
          loc.adminFeeSettingsKeysPicnicAdditionalHeadFee,
        monthlySubscriptionGroupKey =>
          loc.adminFeeSettingsKeysMonthlySubscription,
        _ => key,
      };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => FeeSettingsCubit(
          repository: AdminRepository(apiClient: sl<ApiClient>()))
        ..loadActive(),
      child: BlocConsumer<FeeSettingsCubit, FeeSettingsState>(
        listener: (context, state) {
          if (state.saveError != null) {
            showAppToast(context, loc.adminFeeSettingsErrorsSaveFailed,
                error: true);
          }
        },
        builder: (context, state) {
          final cubit = context.read<FeeSettingsCubit>();
          final tierBase = state.tierRow(monthlySubscriptionTierKeys.base);
          final tierRate = state.tierRow(monthlySubscriptionTierKeys.rate);
          final tierThreshold =
              state.tierRow(monthlySubscriptionTierKeys.threshold);
          final tableRows = state.active
              .where((s) => !monthlySubscriptionTierKeySet.contains(s.key))
              .toList();

          return ListView(
            children: [
              PageHeader(
                  title: loc.adminFeeSettingsTitle,
                  subtitle: loc.adminFeeSettingsSubtitle),
              if (state.error != null)
                InlineError(
                    message: loc.adminFeeSettingsErrorsLoadFailed,
                    onRetry: cubit.loadActive),

              _addVersionForm(context, loc, cubit, state),

              // Tiered calculator.
              if (tierBase != null && tierRate != null && tierThreshold != null)
                _TierCalculator(
                  base: tierBase.value,
                  rate: tierRate.value,
                  threshold: tierThreshold.value,
                ),

              if (!state.loading && !state.picnicConfigured)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    loc.adminFeeSettingsPicnicNotConfigured,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),

              if (state.loading)
                const SkeletonLoader(lines: 4)
              else ...[
                // Tiered summary row.
                if (tierBase != null &&
                    tierRate != null &&
                    tierThreshold != null)
                  AppCard(
                    title: loc.adminFeeSettingsKeysMonthlySubscription,
                    trailing: IconButton(
                      icon: const Icon(Icons.history),
                      tooltip: state.expandedKey == monthlySubscriptionGroupKey
                          ? loc.adminFeeSettingsHideHistory
                          : loc.adminFeeSettingsViewHistory,
                      onPressed: () =>
                          cubit.toggleHistory(monthlySubscriptionGroupKey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.adminFeeSettingsTieredSummary(
                          tierBase.value,
                          tierThreshold.value,
                          tierRate.value,
                        )),
                        InfoRow(
                            label: loc.adminFeeSettingsTableStartDate,
                            value: tierBase.startDate),
                      ],
                    ),
                  ),
                for (final row in tableRows)
                  AppCard(
                    title: '${_keyLabel(loc, row.key)} (${row.key})',
                    trailing: IconButton(
                      icon: const Icon(Icons.history),
                      tooltip: state.expandedKey == row.key
                          ? loc.adminFeeSettingsHideHistory
                          : loc.adminFeeSettingsViewHistory,
                      onPressed: () => cubit.toggleHistory(row.key),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InfoRow(
                                label: loc.adminFeeSettingsTableValue,
                                value: '${row.value} ${row.unit ?? ''}'.trim(),
                              ),
                            ),
                          ],
                        ),
                        InfoRow(
                            label: loc.adminFeeSettingsTableStartDate,
                            value: row.startDate),
                      ],
                    ),
                  ),
                // Expanded history panel.
                if (state.expandedKey != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: state.loadingHistory
                            ? const SkeletonLoader(lines: 2)
                            : _HistoryList(state: state, loc: loc),
                      ),
                    ),
                  ),
                if (tableRows.isEmpty &&
                    state.expandedKey == null &&
                    tierBase == null)
                  EmptyState(message: loc.adminFeeSettingsNoSettings),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _addVersionForm(BuildContext context, AppLocalizations loc,
      FeeSettingsCubit cubit, FeeSettingsState state) {
    final isTiered = _draftKey == monthlySubscriptionGroupKey;
    final canSave = _draftKey.isNotEmpty &&
        (isTiered
            ? _baseController.text.isNotEmpty &&
                _rateController.text.isNotEmpty &&
                _thresholdController.text.isNotEmpty
            : _valueController.text.isNotEmpty);

    return AppCard(
      title: loc.adminFeeSettingsAddVersion,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _draftKey.isEmpty ? null : _draftKey,
            decoration: InputDecoration(
              labelText: loc.adminFeeSettingsFormKey,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final k in knownFeeKeys)
                DropdownMenuItem<String>(
                    value: k, child: Text(_keyLabel(loc, k))),
            ],
            onChanged: (v) => setState(() => _draftKey = v ?? ''),
          ),
          if (isTiered) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _baseController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.adminFeeSettingsFormBaseAmount,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.adminFeeSettingsFormAdditionalRate,
                helperText: loc.adminFeeSettingsFormAdditionalRateHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.adminFeeSettingsFormBaseThreshold,
                border: const OutlineInputBorder(),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.adminFeeSettingsFormValue,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _unit.isEmpty ? null : _unit,
            decoration: InputDecoration(
              labelText: loc.adminFeeSettingsFormUnit,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final u in _unitOptions)
                DropdownMenuItem<String>(
                  value: u,
                  child: Text(u == 'taka'
                      ? loc.adminFeeSettingsUnitsTaka
                      : loc.adminFeeSettingsUnitsPercent),
                ),
            ],
            onChanged: (v) => setState(() => _unit = v ?? ''),
          ),
          const SizedBox(height: 12),
          DateField(
            label: loc.adminFeeSettingsFormStartDate,
            hint: loc.adminFeeSettingsFormStartDateHint,
            value: _startDate,
            onChanged: (v) => setState(() => _startDate = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: loc.adminFeeSettingsFormSubmit,
              onPressed: canSave && !state.saving
                  ? () async {
                      final confirmed = await confirmDialog(
                        context,
                        title: loc.adminFeeSettingsConfirmTitle,
                        message: loc.adminFeeSettingsConfirmMessage,
                        confirmLabel: loc.adminFeeSettingsFormSubmit,
                      );
                      if (!confirmed || !context.mounted) return;
                      final cubit = context.read<FeeSettingsCubit>();
                      final ok = isTiered
                          ? await cubit.createTieredVersion(
                              baseAmount:
                                  num.tryParse(_baseController.text) ?? 0,
                              additionalRate:
                                  num.tryParse(_rateController.text) ?? 0,
                              baseThreshold:
                                  num.tryParse(_thresholdController.text) ?? 0,
                              unit: _unit.isEmpty ? null : _unit,
                              startDate: _startDate.isEmpty ? null : _startDate,
                            )
                          : await cubit.createVersion(
                              key: _draftKey,
                              value: num.tryParse(_valueController.text) ?? 0,
                              unit: _unit.isEmpty ? null : _unit,
                              startDate: _startDate.isEmpty ? null : _startDate,
                            );
                      if (ok && mounted) {
                        setState(() {
                          _draftKey = '';
                          _valueController.clear();
                          _baseController.clear();
                          _rateController.clear();
                          _thresholdController.clear();
                          _unit = '';
                          _startDate = '';
                        });
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

final monthlySubscriptionTierKeySet = <String>{
  monthlySubscriptionTierKeys.base,
  monthlySubscriptionTierKeys.rate,
  monthlySubscriptionTierKeys.threshold,
};

class _TierCalculator extends StatefulWidget {
  const _TierCalculator({
    required this.base,
    required this.rate,
    required this.threshold,
  });

  final num base;
  final num rate;
  final num threshold;

  @override
  State<_TierCalculator> createState() => _TierCalculatorState();
}

class _TierCalculatorState extends State<_TierCalculator> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final landSize = num.tryParse(_controller.text);
    num? fee;
    if (landSize != null && landSize > 0) {
      if (landSize <= widget.threshold) {
        fee = widget.base;
      } else {
        final extra = (landSize - widget.threshold).ceil();
        fee = widget.base + extra * widget.rate;
      }
    }
    return AppCard(
      title: loc.adminFeeSettingsCalculatorTitle,
      child: Column(
        children: [
          TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: loc.adminFeeSettingsCalculatorLandSize,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              fee == null ? '—' : '${loc.adminFeeSettingsCalculatorFee}: $fee',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.state, required this.loc});

  final FeeSettingsState state;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final isTiered = state.expandedKey == monthlySubscriptionGroupKey;
    final rows = isTiered ? state.tieredHistory : state.history;
    if (rows.isEmpty) return Text(loc.commonNoData);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final h in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('${h.value} ${h.unit ?? ''}'.trim()),
            subtitle: Text('${h.startDate} → ${h.endDate ?? '—'}'),
            trailing: StatusBadge(
              kind: h.isActive ? StatusKind.approved : StatusKind.neutral,
              label: h.isActive
                  ? loc.adminFeeSettingsActive
                  : loc.adminFeeSettingsInactive,
            ),
          ),
      ],
    );
  }
}
