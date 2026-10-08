import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/bloc_actions.dart';
import '../presentation/bloc/fee_settings_bloc.dart';
import '../presentation/widgets/management_page_kit.dart';
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

final monthlySubscriptionTierKeySet = <String>{
  monthlySubscriptionTierKeys.base,
  monthlySubscriptionTierKeys.rate,
  monthlySubscriptionTierKeys.threshold,
};

final _numberFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

String _keyLabel(AppLocalizations loc, String key) => switch (key) {
      'admission_fee' => loc.adminFeeSettingsKeysAdmissionFee,
      'picnic_head_fee' => loc.adminFeeSettingsKeysPicnicHeadFee,
      'picnic_additional_head_fee' =>
        loc.adminFeeSettingsKeysPicnicAdditionalHeadFee,
      monthlySubscriptionGroupKey => loc.adminFeeSettingsKeysMonthlySubscription,
      _ => key,
    };

String _unitLabel(AppLocalizations loc, String? unit) => switch (unit) {
      'taka' => loc.adminFeeSettingsUnitsTaka,
      'percent' => loc.adminFeeSettingsUnitsPercent,
      _ => unit ?? '',
    };

String _valueText(AppLocalizations loc, FeeSetting s) =>
    '${s.value} ${_unitLabel(loc, s.unit)}'.trim();

class _FeeSettingsPageState extends State<FeeSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => FeeSettingsBloc(
          repository: AdminRepository(apiClient: sl<ApiClient>()))
        ..add(const FeeSettingsLoadRequested()),
      child: BlocConsumer<FeeSettingsBloc, FeeSettingsState>(
        listenWhen: (a, b) => a.saveError != b.saveError,
        listener: (context, state) {
          if (state.saveError != null) {
            showAppToast(context, loc.adminFeeSettingsErrorsSaveFailed,
                error: true);
          }
        },
        builder: (context, state) {
          final bloc = context.read<FeeSettingsBloc>();
          return PageBody(
            onRefresh: () => reloadAndWait<FeeSettingsEvent, FeeSettingsState>(
              bloc,
              const FeeSettingsLoadRequested(),
              (s) => s.loading,
            ),
            children: [
              PageHeader(
                icon: Icons.tune_rounded,
                title: loc.adminFeeSettingsTitle,
                subtitle: loc.adminFeeSettingsSubtitle,
              ),
              if (state.error != null)
                InlineError(
                  message: loc.adminFeeSettingsErrorsLoadFailed,
                  onRetry: () => bloc.add(const FeeSettingsLoadRequested()),
                ),
              if (!state.loading && !state.picnicConfigured)
                _Callout(text: loc.adminFeeSettingsPicnicNotConfigured),
              _layout(context, state),
            ],
          );
        },
      ),
    );
  }

  /// Active settings and the add-version form sit side by side on wide
  /// screens, stacked (settings first) on phones.
  Widget _layout(BuildContext context, FeeSettingsState state) {
    final settings = _ActiveSettings(state: state);
    final tools = _Tools(state: state);
    if (!context.isExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [settings, tools],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: settings),
        Expanded(flex: 2, child: tools),
      ],
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 6),
      color: scheme.errorContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: scheme.error),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: scheme.error))),
          ],
        ),
      ),
    );
  }
}

/// Current versions (tiered group first) with inline history.
class _ActiveSettings extends StatelessWidget {
  const _ActiveSettings({required this.state});

  final FeeSettingsState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (state.loading) return const SkeletonLoader(lines: 4);
    final tierBase = state.tierRow(monthlySubscriptionTierKeys.base);
    final tierRate = state.tierRow(monthlySubscriptionTierKeys.rate);
    final tierThreshold = state.tierRow(monthlySubscriptionTierKeys.threshold);
    final hasTier = tierBase != null && tierRate != null && tierThreshold != null;
    final rows = state.active
        .where((s) => !monthlySubscriptionTierKeySet.contains(s.key))
        .toList();
    if (rows.isEmpty && !hasTier) {
      return EmptyState(icon: Icons.tune_rounded, message: loc.adminFeeSettingsNoSettings);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(loc.adminFeeSettingsActive),
        CardGrid(
          minItemWidth: 300,
          maxColumns: 2,
          children: [
            if (hasTier)
              _SettingCard(
                state: state,
                historyKey: monthlySubscriptionGroupKey,
                title: loc.adminFeeSettingsKeysMonthlySubscription,
                value: loc.adminFeeSettingsTieredSummary(
                    tierBase.value, tierRate.value, tierThreshold.value),
                startDate: tierBase.startDate,
              ),
            for (final row in rows)
              _SettingCard(
                state: state,
                historyKey: row.key,
                title: _keyLabel(loc, row.key),
                caption: row.key,
                value: _valueText(loc, row),
                startDate: row.startDate,
                emphasise: true,
              ),
          ],
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.state,
    required this.historyKey,
    required this.title,
    required this.value,
    required this.startDate,
    this.caption,
    this.emphasise = false,
  });

  final FeeSettingsState state;
  final String historyKey;
  final String title;
  final String? caption;
  final String value;
  final String startDate;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final open = state.expandedKey == historyKey;
    return AppCard(
      margin: EdgeInsets.zero,
      title: title,
      trailing: IconButton(
        icon: Icon(open ? Icons.history_toggle_off : Icons.history),
        tooltip: open ? loc.adminFeeSettingsHideHistory : loc.adminFeeSettingsViewHistory,
        isSelected: open,
        onPressed: () =>
            context.read<FeeSettingsBloc>().add(FeeSettingsHistoryToggled(historyKey)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          if (caption != null)
            Text(caption!, style: theme.textTheme.labelSmall),
          Text(
            value,
            style: emphasise
                ? theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary, fontWeight: FontWeight.w700)
                : theme.textTheme.bodyMedium,
          ),
          MetaText(
            icon: Icons.event_available_outlined,
            text: '${loc.adminFeeSettingsTableStartDate}: $startDate',
          ),
          if (open) ...[
            const Divider(height: 16),
            if (state.loadingHistory)
              const LinearProgressIndicator()
            else
              _HistoryList(state: state),
          ],
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.state});

  final FeeSettingsState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isTiered = state.expandedKey == monthlySubscriptionGroupKey;
    final rows = isTiered ? state.tieredHistory : state.history;
    if (rows.isEmpty) {
      return Text(loc.commonNoData, style: theme.textTheme.bodySmall);
    }
    return Column(
      children: [
        for (final h in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTiered ? '${_keyLabel(loc, h.key)}: ${_valueText(loc, h)}' : _valueText(loc, h),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text('${h.startDate} → ${h.endDate ?? '—'}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  kind: h.isActive ? StatusKind.approved : StatusKind.neutral,
                  label: h.isActive
                      ? loc.adminFeeSettingsActive
                      : loc.adminFeeSettingsInactive,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Add-version form plus the tiered fee calculator.
class _Tools extends StatelessWidget {
  const _Tools({required this.state});

  final FeeSettingsState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final tierBase = state.tierRow(monthlySubscriptionTierKeys.base);
    final tierRate = state.tierRow(monthlySubscriptionTierKeys.rate);
    final tierThreshold = state.tierRow(monthlySubscriptionTierKeys.threshold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(loc.adminFeeSettingsAddVersion),
        _AddVersionForm(saving: state.saving),
        if (tierBase != null && tierRate != null && tierThreshold != null) ...[
          SectionTitle(loc.adminFeeSettingsCalculatorTitle),
          _TierCalculator(
            base: tierBase.value,
            rate: tierRate.value,
            threshold: tierThreshold.value,
          ),
        ],
      ],
    );
  }
}

class _AddVersionForm extends StatefulWidget {
  const _AddVersionForm({required this.saving});

  final bool saving;

  @override
  State<_AddVersionForm> createState() => _AddVersionFormState();
}

class _AddVersionFormState extends State<_AddVersionForm> {
  static const _unitOptions = ['taka', 'percent'];

  String _draftKey = '';
  final _valueController = TextEditingController();
  final _baseController = TextEditingController();
  final _rateController = TextEditingController();
  final _thresholdController = TextEditingController();
  String _unit = '';
  String _startDate = '';

  bool get _isTiered => _draftKey == monthlySubscriptionGroupKey;

  bool get _canSave =>
      _draftKey.isNotEmpty &&
      (_isTiered
          ? _baseController.text.isNotEmpty &&
              _rateController.text.isNotEmpty &&
              _thresholdController.text.isNotEmpty
          : _valueController.text.isNotEmpty);

  @override
  void dispose() {
    _valueController.dispose();
    _baseController.dispose();
    _rateController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          LabeledDropdown<String>(
            label: loc.adminFeeSettingsFormKey,
            value: _draftKey.isEmpty ? null : _draftKey,
            prefixIcon: Icons.key_outlined,
            options: [for (final k in knownFeeKeys) (k, _keyLabel(loc, k))],
            onChanged: (v) => setState(() => _draftKey = v ?? ''),
          ),
          if (_isTiered) ...[
            _numberField(_baseController, loc.adminFeeSettingsFormBaseAmount),
            FieldPair(
              first: _numberField(_rateController, loc.adminFeeSettingsFormAdditionalRate,
                  helper: loc.adminFeeSettingsFormAdditionalRateHint),
              second: _numberField(
                  _thresholdController, loc.adminFeeSettingsFormBaseThreshold),
            ),
          ] else
            _numberField(_valueController, loc.adminFeeSettingsFormValue),
          FieldPair(
            first: LabeledDropdown<String>(
              label: loc.adminFeeSettingsFormUnit,
              value: _unit.isEmpty ? null : _unit,
              options: [for (final u in _unitOptions) (u, _unitLabel(loc, u))],
              onChanged: (v) => setState(() => _unit = v ?? ''),
            ),
            second: DateField(
              label: loc.adminFeeSettingsFormStartDate,
              hint: loc.adminFeeSettingsFormStartDateHint,
              value: _startDate,
              onChanged: (v) => setState(() => _startDate = v),
            ),
          ),
          AppButton(
            label: loc.adminFeeSettingsFormSubmit,
            icon: Icons.add_task_rounded,
            expanded: true,
            loading: widget.saving,
            onPressed: _canSave ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label,
      {String? helper}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_numberFormatter],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
      ),
    );
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await confirmDialog(
      context,
      title: loc.adminFeeSettingsConfirmTitle,
      message: loc.adminFeeSettingsConfirmMessage,
      confirmLabel: loc.adminFeeSettingsFormSubmit,
    );
    if (!confirmed || !mounted) return;
    final bloc = context.read<FeeSettingsBloc>();
    final unit = _unit.isEmpty ? null : _unit;
    final startDate = _startDate.isEmpty ? null : _startDate;
    final ok = _isTiered
        ? await dispatchForBool(
            bloc,
            (c) => FeeSettingTieredVersionCreateRequested(
                completer: c,
                baseAmount: num.tryParse(_baseController.text) ?? 0,
                additionalRate: num.tryParse(_rateController.text) ?? 0,
                baseThreshold: num.tryParse(_thresholdController.text) ?? 0,
                unit: unit,
                startDate: startDate))
        : await dispatchForBool(
            bloc,
            (c) => FeeSettingVersionCreateRequested(
                completer: c,
                key: _draftKey,
                value: num.tryParse(_valueController.text) ?? 0,
                unit: unit,
                startDate: startDate));
    if (ok && mounted) _reset();
  }

  void _reset() {
    setState(() {
      _draftKey = '';
      _valueController.clear();
      _baseController.clear();
      _rateController.clear();
      _thresholdController.clear();
      _unit = '';
      _startDate = '';
    });
    showAppToast(context, AppLocalizations.of(context).commonSave);
  }
}

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

  num? _fee() {
    final landSize = num.tryParse(_controller.text);
    if (landSize == null || landSize <= 0) return null;
    if (landSize <= widget.threshold) return widget.base;
    final extra = (landSize - widget.threshold).ceil();
    return widget.base + extra * widget.rate;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fee = _fee();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_numberFormatter],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: loc.adminFeeSettingsCalculatorLandSize,
              prefixIcon: const Icon(Icons.square_foot_rounded),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(loc.adminFeeSettingsCalculatorFee,
                    style: theme.textTheme.bodyMedium),
              ),
              Text(
                fee == null
                    ? '—'
                    : formatTaka(fee, decimals: fee % 1 == 0 ? 0 : 2),
                style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
