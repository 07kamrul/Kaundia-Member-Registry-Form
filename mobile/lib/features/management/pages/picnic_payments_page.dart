import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/picnic_payments_bloc.dart';
import '../presentation/widgets/management_widgets.dart';

/// Picnic payments management (Angular picnic-payments): member/date filters,
/// collected summary, payment list.
class PicnicPaymentsPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const PicnicPaymentsPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => PicnicPaymentsBloc(
          repository: AdminRepository(apiClient: sl<ApiClient>()))
        ..add(const PicnicPaymentsLoadRequested()),
      child: BlocBuilder<PicnicPaymentsBloc, PicnicPaymentsState>(
          builder: (context, state) {
        final bloc = context.read<PicnicPaymentsBloc>();
        final memberController = TextEditingController(
          text: state.memberFilter?.toString() ?? '',
        );
        return ListView(
          children: [
            PageHeader(
                title: loc.adminPicnicPaymentsTitle,
                subtitle: loc.adminPicnicPaymentsSubtitle),
            AppCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: memberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: loc.adminPicnicPaymentsMemberFilter,
                      border: const OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (raw) =>
                        bloc.add(PicnicPaymentsMemberFilterChanged(raw: raw)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DateField(
                          label: loc.adminPicnicPaymentsDateFrom,
                          value: state.dateFrom,
                          onChanged: (v) {
                            bloc.add(PicnicPaymentsDateRangeChanged(from: v));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DateField(
                          label: loc.adminPicnicPaymentsDateTo,
                          value: state.dateTo,
                          onChanged: (v) {
                            bloc.add(PicnicPaymentsDateRangeChanged(to: v));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: loc.adminPicnicPaymentsApply,
                          onPressed: () {
                            bloc.add(PicnicPaymentsMemberFilterChanged(
                                raw: memberController.text));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: loc.adminPicnicPaymentsReset,
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            memberController.clear();
                            bloc.add(const PicnicPaymentsFiltersReset());
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.adminPicnicPaymentsTotalCollected,
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          formatTaka(state.totalCollected, decimals: 0),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.adminPicnicPaymentsCount,
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('${state.count}',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (state.loading)
              const SkeletonLoader(lines: 5)
            else if (state.error != null)
              InlineError(
                  message: loc.adminPicnicPaymentsLoadError,
                  onRetry: () => bloc.add(const PicnicPaymentsLoadRequested()))
            else
              AppDataTableCards<AdminPicnicPayment>(
                items: state.items,
                rowBuilder: (context, p) => Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.memberName ?? '#${p.memberId}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              formatTaka(p.total, decimals: 0),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        InfoRow(
                            label: loc.adminPicnicPaymentsDateColumn,
                            value: p.paymentDate),
                        InfoRow(
                            label: loc.adminPicnicPaymentsHeadsColumn,
                            value: '${p.additionalCount}'),
                        InfoRow(
                            label: loc.adminPicnicPaymentsReceiptColumn,
                            value: p.receiptNo ?? '—'),
                        InfoRow(
                            label: loc.adminPicnicPaymentsMethodColumn,
                            value: p.paymentMethod ?? '—'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
