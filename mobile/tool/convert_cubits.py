import io, re, os

TABLE = {
 'roadmap_cubit.dart': ('RoadmapCubit','RoadmapBloc','RoadmapState','RoadmapEvent',[
   ('load','RoadmapLoadRequested',[],'void',{}),
   ('loadHistory','RoadmapHistoryLoadRequested',[],'void',{}),
   ('setStatus','RoadmapStatusSet',[('RoadmapItem','item','pos'),('RoadmapStatus','status','pos'),('bool','notify','opt')],'bool',{'notify':'true'}),
   ('deleteItem','RoadmapItemDeleted',[('RoadmapItem','item','pos')],'bool',{}),
   ('reorder','RoadmapItemsReordered',[('RoadmapTimeframe','timeframe','pos'),('int','index','pos'),('int','delta','pos')],'bool',{}),
   ('createItem','RoadmapItemCreated',[('int','timeframeId','namedreq'),('String','text','namedreq'),('RoadmapStatus','status','opt'),('String?','targetDate','named'),('String?','owner','named'),('String?','note','named'),('bool','notify','opt')],'bool',{'status':'RoadmapStatus.planned','notify':'true'}),
   ('updateItem','RoadmapItemUpdated',[('RoadmapItem','item','pos'),('String','text','namedreq'),('int?','timeframeId','named'),('String?','targetDate','named'),('String?','owner','named'),('String?','note','named')],'bool',{}),
   ('archive','RoadmapArchived',[('bool','onlyDone','namedreq')],'bool',{}),
 ]),
 'property_requests_cubit.dart': ('PropertyRequestsCubit','PropertyRequestsBloc','PropertyRequestsState','PropertyRequestsEvent',[
   ('load','PropertyRequestsLoadRequested',[],'void',{}),
   ('setStatusFilter','PropertyRequestsStatusFilterChanged',[('PropertyRequestStatus','status','pos')],'void',{}),
   ('approve','PropertyRequestApproved',[('MemberPropertyRequest','request','pos')],'bool',{}),
   ('cancel','PropertyRequestCancelled',[('MemberPropertyRequest','request','pos'),('String','reason','pos')],'bool',{}),
 ]),
 'finance_cubit.dart': ('FinanceCubit','FinanceBloc','FinanceState','FinanceEvent',[
   ('init','FinanceInitRequested',[],'void',{}),
   ('loadCategories','FinanceCategoriesLoadRequested',[],'void',{}),
   ('loadOverview','FinanceOverviewLoadRequested',[],'void',{}),
   ('refresh','FinanceRefreshRequested',[],'void',{}),
   ('setFilters','FinanceFiltersChanged',[('FinanceStatus?','statusFilter','named'),('FinanceType?','typeFilter','named'),('String?','search','named')],'void',{}),
   ('setDateRange','FinanceDateRangeChanged',[('String?','from','named'),('String?','to','named')],'void',{}),
   ('resetFilters','FinanceFiltersReset',[],'void',{}),
   ('changePage','FinancePageChanged',[('int','delta','pos')],'void',{}),
   ('toggleExpanded','FinanceRowToggled',[('int','id','pos')],'void',{}),
   ('saveTransaction','FinanceTransactionSaved',[('FinanceTransactionInput','input','namedreq'),('int?','editingId','named'),('String?','attachmentPath','named')],'bool',{}),
   ('submitDraft','FinanceDraftSubmitted',[('FinanceTransaction','txn','pos')],'bool',{}),
   ('approve','FinanceApproved',[('FinanceTransaction','txn','pos')],'bool',{}),
   ('reject','FinanceRejected',[('FinanceTransaction','txn','pos'),('String','reason','pos')],'bool',{}),
   ('reverse','FinanceReversed',[('FinanceTransaction','txn','pos'),('String','reason','pos')],'bool',{}),
   ('delete','FinanceDeleted',[('FinanceTransaction','txn','pos'),('String','reason','pos')],'bool',{}),
   ('loadUnlinkedPayments','FinanceUnlinkedPaymentsRequested',[('PaymentSourceType?','sourceType','named'),('String?','search','named')],'void',{}),
   ('addCategory','FinanceCategoryAdded',[('String','label','pos')],'FinanceCategory?',{}),
   ('publishReportNotice','FinanceReportNoticePublished',[('FinancePeriod','period','opt')],'bool',{'period':'FinancePeriod.month'}),
 ]),
 'installments_mgmt_cubit.dart': ('InstallmentsMgmtCubit','InstallmentsMgmtBloc','InstallmentsMgmtState','InstallmentsMgmtEvent',[
   ('loadMembers','InstallmentsMembersLoadRequested',[],'void',{}),
   ('selectMember','InstallmentsMemberSelected',[('String','memberId','pos')],'void',{}),
   ('markPaid','InstallmentMarkPaid',[('Installment','installment','pos')],'void',{}),
 ]),
 'society_costs_cubit.dart': ('SocietyCostsCubit','SocietyCostsBloc','SocietyCostsState','SocietyCostsEvent',[
   ('init','SocietyInitRequested',[],'void',{}),
   ('loadCategories','SocietyCategoriesLoadRequested',[],'void',{}),
   ('refresh','SocietyRefreshRequested',[],'void',{}),
   ('setFilters','SocietyFiltersChanged',[('String?','categoryFilter','named'),('String?','dateFrom','named'),('String?','dateTo','named'),('CostPaymentSource?','sourceFilter','named')],'void',{}),
   ('resetFilters','SocietyFiltersReset',[],'void',{}),
   ('toggleExpanded','SocietyRowToggled',[('int','id','pos')],'void',{}),
   ('addCategory','SocietyCategoryAdded',[('String','label','pos')],'String?',{}),
   ('saveCost','SocietyCostSaved',[('SocietyCostInput','input','namedreq'),('int?','editingId','named'),('String?','receiptPath','named')],'bool',{}),
   ('deleteCost','SocietyCostDeleted',[('SocietyCost','cost','pos')],'bool',{}),
   ('openSplit','SocietySplitOpened',[('SocietyCost','cost','pos')],'void',{}),
   ('closeSplit','SocietySplitClosed',[],'void',{}),
   ('setSplitMethod','SocietySplitMethodChanged',[('CostSplitMethod','method','pos')],'void',{}),
   ('setManualAmount','SocietyManualAmountChanged',[('int','memberId','pos'),('num?','amount','named')],'void',{}),
   ('refreshSplitPreview','SocietySplitPreviewRefreshed',[],'void',{}),
   ('confirmSplit','SocietySplitConfirmed',[('bool','allowMismatch','opt')],'bool',{'allowMismatch':'false'}),
   ('recordSharePayment','SocietySharePaymentRecorded',[('CostSplitShare','share','pos'),('num','additionalAmount','namedreq'),('String?','receiptNo','named')],'bool',{}),
 ]),
}

def gen_events(ebase, methods):
    out = ['// ---------------------------------------------------------------------------',
           '// Events', '// ---------------------------------------------------------------------------',
           '', 'sealed class ' + ebase + ' extends Equatable {',
           '  const ' + ebase + '();', '  @override',
           '  List<Object?> get props => const [];', '}', '']
    for m, en, params, ret, defaults in methods:
        if not params and ret == 'void':
            out += ['final class ' + en + ' extends ' + ebase + ' {',
                    '  const ' + en + '();', '', '  @override',
                    '  List<Object?> get props => const [];', '}', '']
            continue
        lines = ['final class ' + en + ' extends ' + ebase + ' {', '  const ' + en + '({']
        for t, n, kind in params:
            if kind in ('pos', 'namedreq'):
                lines.append('    required this.' + n + ',')
            elif kind == 'opt':
                lines.append('    this.' + n + ' = ' + defaults[n] + ',')
            else:
                lines.append('    this.' + n + ',')
        if ret != 'void':
            lines.append('    this.completer,')
        lines.append('  });')
        lines.append('')
        for t, n, kind in params:
            lines.append('  final ' + t + ' ' + n + ';')
        if ret != 'void':
            lines.append('  final Completer<' + ret + '>? completer;')
        lines += ['', '  @override',
                  '  List<Object?> get props => [' + ', '.join(n for _, n, _ in params) + '];',
                  '}', '']
        out += lines
    return '\n'.join(out)

def gen_ctor(state, methods):
    regs = []
    for m, en, params, ret, defaults in methods:
        pos = [n for _, n, k in params if k == 'pos']
        named = [(n, k) for _, n, k in params if k in ('named', 'namedreq', 'opt')]
        parts = ['e.' + n for n in pos] + [n + ': e.' + n for n, _ in named]
        call = m + '(' + ', '.join(parts) + ')'
        if ret == 'void':
            regs.append('    on<' + en + '>((e, emit) => ' + call + ');')
        else:
            regs.append('    on<' + en + '>((e, emit) async {')
            regs.append('      final result = await ' + call + ';')
            regs.append('      e.completer?.complete(result);')
            regs.append('    });')
    return '\n' + '\n'.join(regs) + '\n  '

BLOC_DIR = 'lib/features/management/presentation/bloc/'

for fname, (cubit, bloc, state, ebase, methods) in TABLE.items():
    p = BLOC_DIR + fname
    if not os.path.exists(p):
        print('skip (already converted)', fname)
        continue
    s = io.open(p, encoding='utf-8').read()
    assert 'class ' + cubit + ' extends Cubit<' in s, fname
    events = gen_events(ebase, methods)
    ctor = gen_ctor(state, methods)
    if "import 'dart:async';" not in s:
        s = s.replace("import 'package:equatable/equatable.dart';",
                      "import 'dart:async';\n\nimport 'package:equatable/equatable.dart';", 1)
    s = s.replace('class ' + cubit + ' extends Cubit<' + state + '> {',
                  events + '\nclass ' + bloc + ' extends Bloc<' + ebase + ', ' + state + '> {')
    m = re.search(r'super\((?:const )?' + re.escape(state) + r'\(\)\);', s)
    assert m, fname
    s = s[:m.end()] + ctor + s[m.end():]
    s = s.replace(cubit, bloc)
    out = p.replace('_cubit.dart', '_bloc.dart')
    io.open(out, 'w', encoding='utf-8', newline='\n').write(s)
    os.remove(p)
    print('converted', fname, '->', os.path.basename(out))
