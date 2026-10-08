import io, re, os, glob

PAGES = 'lib/features/management/pages/'

def cubit_to_bloc_name(n):
    return n.replace('Cubit', 'Bloc')

# method -> (event, param names in positional order)
# per-file overrides handled by PREFIX table
COMMON = {
  # members
  'load': None, # resolved per file
  'delete': ('MemberDeleted', ['memberId']),
  'resetPassword': ('MemberPasswordResetRequested', ['memberId']),
  # installments mgmt
  'loadMembers': ('InstallmentsMembersLoadRequested', []),
  'selectMember': ('InstallmentsMemberSelected', ['memberId']),
  'markPaid': ('InstallmentMarkPaid', ['installment']),
  # picnic (mgmt)
  'setMemberFilter': ('PicnicPaymentsMemberFilterChanged', ['raw']),
  # finance
  'init': ('FinanceInitRequested', []),
  'loadCategories': ('FinanceCategoriesLoadRequested', []),
  'loadOverview': ('FinanceOverviewLoadRequested', []),
  'refresh': ('FinanceRefreshRequested', []),
  'setFilters': ('FinanceFiltersChanged', ['statusFilter', 'typeFilter', 'search']),
  'setDateRange': ('FinanceDateRangeChanged', ['from', 'to']),
  'resetFilters': ('FinanceFiltersReset', []),
  'changePage': ('FinancePageChanged', ['delta']),
  'toggleExpanded': ('FinanceRowToggled', ['id']),
  'saveTransaction': ('FinanceTransactionSaved', ['input', 'editingId', 'attachmentPath']),
  'submitDraft': ('FinanceDraftSubmitted', ['txn']),
  'approve': None,  # per file
  'reject': None,   # per file
  'reverse': ('FinanceReversed', ['txn', 'reason']),
  'loadUnlinkedPayments': ('FinanceUnlinkedPaymentsRequested', ['sourceType', 'search']),
  'addCategory': ('FinanceCategoryAdded', ['label']),
  'publishReportNotice': ('FinanceReportNoticePublished', ['period']),
  'delete': ('FinanceDeleted', ['txn', 'reason']),
  # payment verifications
  'setStatusFilter': None,  # per file
  # roadmap mgmt
  'loadHistory': ('RoadmapHistoryLoadRequested', []),
  'setStatus': ('RoadmapStatusSet', ['item', 'status', 'notify']),
  'deleteItem': ('RoadmapItemDeleted', ['item']),
  'reorder': ('RoadmapItemsReordered', ['timeframe', 'index', 'delta']),
  'createItem': ('RoadmapItemCreated', ['timeframeId', 'text', 'status', 'targetDate', 'owner', 'note', 'notify']),
  'updateItem': ('RoadmapItemUpdated', ['item', 'text', 'timeframeId', 'targetDate', 'owner', 'note']),
  'archive': ('RoadmapArchived', ['onlyDone']),
  # property requests
  'cancel': ('PropertyRequestCancelled', ['request', 'reason']),
  # society
  'openSplit': ('SocietySplitOpened', ['cost']),
  'closeSplit': ('SocietySplitClosed', []),
  'setSplitMethod': ('SocietySplitMethodChanged', ['method']),
  'setManualAmount': ('SocietyManualAmountChanged', ['memberId', 'amount']),
  'refreshSplitPreview': ('SocietySplitPreviewRefreshed', []),
  'confirmSplit': ('SocietySplitConfirmed', ['allowMismatch']),
  'recordSharePayment': ('SocietySharePaymentRecorded', ['share', 'additionalAmount', 'receiptNo']),
  'saveCost': ('SocietyCostSaved', ['input', 'editingId', 'receiptPath']),
  'deleteCost': ('SocietyCostDeleted', ['cost']),
  # fee settings
  'loadActive': ('FeeSettingsLoadRequested', []),
  'toggleHistory': ('FeeSettingsHistoryToggled', ['key']),
  'createVersion': ('FeeSettingVersionCreateRequested', ['key', 'value', 'unit', 'startDate']),
  'createTieredVersion': ('FeeSettingTieredVersionCreateRequested', ['baseAmount', 'additionalRate', 'baseThreshold', 'unit', 'startDate']),
  # config lists
  'selectCategory': ('ConfigListsCategorySelected', ['category']),
  'addItem': ('ConfigListItemAddRequested', ['value', 'label']),
  'toggleActive': ('ConfigListItemToggleActiveRequested', ['item']),
  'startEdit': ('ConfigListItemEditStarted', ['item']),
  'saveLabel': ('ConfigListItemLabelSaveRequested', ['item', 'label']),
  'moveItem': ('ConfigListItemMoveRequested', ['index', 'direction']),
}

def notices_map():
    m = dict(COMMON)
    m.update({
      'load': ('NoticesLoadRequested', []),
      'init': ('NoticesInitRequested', []),
      'cancelEdit': ('ConfigListItemEditCancelled', []),
      'setStatusFilter': ('NoticesStatusFilterChanged', ['index']),
      'setCategoryFilter': ('NoticesCategoryFilterChanged', ['categoryId']),
      'save': ('NoticeSaveRequested', ['payload', 'editingId']),
      'togglePublished': ('NoticePublishToggled', ['notice']),
      'delete': ('NoticeDeleteRequested', ['notice']),
    })
    return m

def events_map():
    m = dict(COMMON)
    m.update({
      'load': ('EventsLoadRequested', []),
      'init': ('EventsInitRequested', []),
      'setStatusFilter': ('EventsStatusFilterChanged', ['index']),
      'setCategoryFilter': ('EventsCategoryFilterChanged', ['categoryId']),
      'save': ('EventSaveRequested', ['payload', 'editingId']),
      'togglePublished': ('EventPublishToggled', ['event']),
      'delete': ('EventDeleteRequested', ['event']),
    })
    return m

def submissions_map():
    m = dict(COMMON)
    m.update({
      'load': ('SubmissionsLoadRequested', []),
      'setFilter': ('SubmissionsFilterChanged', ['filter']),
      'approve': ('SubmissionDetailApproveRequested', []),
      'reject': ('SubmissionDetailRejectRequested', ['reason']),
      'resendNotification': ('SubmissionDetailResendNotificationRequested', []),
      'replaceAttachment': ('SubmissionDetailAttachmentReplaceRequested', ['kind', 'filePath']),
      'replaceDocument': ('SubmissionDetailDocumentReplaceRequested', ['docId', 'filePath']),
    })
    return m

def members_map():
    m = dict(COMMON)
    m.update({
      'load': ('MembersLoadRequested', []),
      'approve': ('PropertyRequestApproved', ['request']),
    })
    return m

def detail_map():
    m = members_map()
    m['load'] = ('MemberDetailLoadRequested', [])
    return m

def society_map():
    m = dict(COMMON)
    m.update({
      'approve': ('PropertyRequestApproved', ['request']),
      'reject': ('PaymentVerificationsRejected', ['payment', 'reason']),
    })
    return m

def picnic_map():
    m = dict(COMMON)
    m.update({
      'load': ('PicnicPaymentsLoadRequested', []),
      'resetFilters': ('PicnicPaymentsFiltersReset', []),
      'setDateRange': ('PicnicPaymentsDateRangeChanged', ['from', 'to']),
    })
    return m

def installments_map():
    m = dict(COMMON)
    m.update({'load': ('InstallmentsMembersLoadRequested', [])})
    return m

def verifications_map():
    m = dict(COMMON)
    m.update({
      'load': ('PaymentVerificationsLoadRequested', []),
      'setStatusFilter': ('PaymentVerificationsStatusFilterChanged', ['status']),
      'approve': ('PaymentVerificationsApproved', ['payment']),
      'reject': ('PaymentVerificationsRejected', ['payment', 'reason']),
    })
    return m

COMMON_OK = dict(COMMON)
COMMON_OK['load'] = ('ConfigListsLoadRequested', [])
COMMON_OK['cancelEdit'] = ('ConfigListItemEditCancelled', [])
COMMON_OK['init'] = ('ConfigListsLoadRequested', [])
COMMON_OK['approve'] = ('PropertyRequestApproved', ['request'])
COMMON_OK['reject'] = ('PaymentVerificationsRejected', ['payment', 'reason'])
COMMON_OK['setStatusFilter'] = ('PropertyRequestsStatusFilterChanged', ['status'])

def finance_map():
    m = dict(COMMON)
    m.update({'load': ('FinanceRefreshRequested', [])})
    return m

POSITIONAL = {
  'ConfigListsCategorySelected', 'ConfigListItemAddRequested',
  'ConfigListItemToggleActiveRequested', 'ConfigListItemEditStarted',
  'ConfigListItemLabelSaveRequested', 'ConfigListItemMoveRequested',
  'FeeSettingsHistoryToggled', 'NoticesStatusFilterChanged',
  'NoticesCategoryFilterChanged', 'NoticePublishToggled', 'NoticeDeleteRequested',
  'EventsStatusFilterChanged', 'EventsCategoryFilterChanged',
  'EventPublishToggled', 'EventDeleteRequested',
  'SubmissionsFilterChanged', 'SubmissionDetailRejectRequested',
  'SubmissionDetailAttachmentReplaceRequested',
  'SubmissionDetailDocumentReplaceRequested',
}

def convert_tearoffs(s, mapping):
    # `bloc.method` used as a callback tear-off (not followed by '(')
    def rep(m):
        meth = m.group(3)
        recv = m.group(2)
        entry = mapping.get(meth)
        if entry is None:
            return m.group(0)
        event = entry[0]
        return m.group(1) + '() => ' + recv + '.add(const ' + event + '())'
    return re.sub(r'(onRetry:\s*|onPressed:\s*)(_?bloc)\.(\w+)(?!\s*\()', rep, s)

FILE_MAP = {
  'members_list_page.dart': members_map(),
  'member_detail_page.dart': detail_map(),
  'notices_management_page.dart': notices_map(),
  'events_management_page.dart': events_map(),
  'submissions_list_page.dart': submissions_map(),
  'submission_detail_page.dart': submissions_map(),
  'finance_management_page.dart': finance_map(),
  'payment_verifications_page.dart': verifications_map(),
  'installments_management_page.dart': installments_map(),
  'picnic_payments_page.dart': picnic_map(),
  'society_costs_page.dart': COMMON_OK,
  'roadmap_management_page.dart': COMMON_OK,
  'property_requests_page.dart': COMMON_OK,
  'config_lists_page.dart': COMMON_OK,
  'fee_settings_page.dart': COMMON_OK,
}

CUBIT_CLASSES = [
  'MembersCubit', 'MemberDetailCubit', 'NoticesCubit', 'EventsCubit',
  'SubmissionsCubit', 'SubmissionDetailCubit', 'FinanceCubit',
  'PaymentVerificationsCubit', 'InstallmentsMgmtCubit', 'PicnicPaymentsCubit',
  'SocietyCostsCubit', 'RoadmapCubit', 'PropertyRequestsCubit',
  'ConfigListsCubit', 'FeeSettingsCubit',
]

def find_close(s, open_idx):
    depth = 0
    for i in range(open_idx, len(s)):
        if s[i] == '(':
            depth += 1
        elif s[i] == ')':
            depth -= 1
            if depth == 0:
                return i
    return -1

def split_args(argstr):
    args, depth, cur = [], 0, ''
    for ch in argstr:
        if ch in '([{':
            depth += 1
        elif ch in ')]}':
            depth -= 1
        if ch == ',' and depth == 0:
            args.append(cur.strip())
            cur = ''
        else:
            cur += ch
    if cur.strip():
        args.append(cur.strip())
    return args

def convert_calls(s, mapping, positional_events=frozenset()):
    out = []
    i = 0
    n = len(s)
    while True:
        m = re.search(r'\bbloc\.(\w+)\(', s[i:])
        if not m:
            out.append(s[i:])
            break
        start = i + m.start()
        meth = m.group(1)
        open_idx = i + m.end() - 1
        close_idx = find_close(s, open_idx)
        if meth not in mapping or close_idx < 0:
            out.append(s[i:close_idx + 1 if close_idx > 0 else i + m.end()])
            i = (close_idx + 1) if close_idx > 0 else i + m.end()
            continue
        entry = mapping[meth]
        if entry is None:
            out.append(s[i:close_idx + 1])
            i = close_idx + 1
            continue
        event, params = entry[0], entry[1] if len(entry) > 1 else []
        positional = event in positional_events
        args = split_args(s[open_idx + 1:close_idx])
        named, pos_i = [], 0
        for a in args:
            if re.match(r'^[a-zA-Z_]\w*\s*:', a) or '=' in a.split('(')[0]:
                named.append(a)
            else:
                if pos_i < len(params) and not positional:
                    named.append(params[pos_i] + ': ' + a)
                else:
                    named.append(a)
                pos_i += 1
        argstr = ', '.join(named)
        out.append(s[i:start])
        out.append('bloc.add(' + event + '(' + argstr + '))')
        i = close_idx + 1
    return ''.join(out)

for fname, mapping in FILE_MAP.items():
    p = PAGES + fname
    if not os.path.exists(p):
        print('MISSING', fname)
        continue
    s = io.open(p, encoding='utf-8').read()
    orig = s
    # imports
    s = s.replace("_cubit.dart';", "_bloc.dart';")
    # class names
    for c in CUBIT_CLASSES:
        s = re.sub(r'\b' + c + r'\b', cubit_to_bloc_name(c), s)
    # identifiers
    s = re.sub(r'\b_cubit\b', '_bloc', s)
    s = re.sub(r'\bcubit\b', 'bloc', s)
    # method -> event dispatch
    pos = POSITIONAL
    s = convert_calls(s, mapping, pos)
    s = convert_tearoffs(s, mapping)
    # strip stray `await bloc.add(` (results no longer returned synchronously)
    s = re.sub(r'\bawait (bloc\.add\()', r'\1', s)
    if s != orig:
        io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
        print('converted', fname)
print('done')
