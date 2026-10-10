// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get adminAuditLogDetailsClose => 'Close';

  @override
  String get adminAuditLogDetailsTitle => 'Entry Details';

  @override
  String get adminAuditLogDetailsView => 'Details';

  @override
  String get adminAuditLogErrorsLoadFailed => 'Could not load the audit log.';

  @override
  String get adminAuditLogFiltersAction => 'Action';

  @override
  String get adminAuditLogFiltersActor => 'Admin';

  @override
  String get adminAuditLogFiltersAll => 'All';

  @override
  String get adminAuditLogFiltersDateFrom => 'From date';

  @override
  String get adminAuditLogFiltersDateTo => 'To date';

  @override
  String get adminAuditLogFiltersEntityType => 'Entity type';

  @override
  String get adminAuditLogNoEntries => 'No audit log entries yet.';

  @override
  String get adminAuditLogNoEntriesMatch =>
      'No entries match the selected filters.';

  @override
  String get adminAuditLogPaginationNext => 'Next';

  @override
  String get adminAuditLogPaginationPageSize => 'Per page';

  @override
  String get adminAuditLogPaginationPrev => 'Previous';

  @override
  String adminAuditLogPaginationRange(
      Object from_val, Object to_val, Object total) {
    return '$from_val–$to_val of $total';
  }

  @override
  String get adminAuditLogSubtitle =>
      'Who approved, rejected, or changed what, and when';

  @override
  String get adminAuditLogTableAction => 'Action';

  @override
  String get adminAuditLogTableActor => 'Admin';

  @override
  String get adminAuditLogTableDetail => 'Detail';

  @override
  String get adminAuditLogTableEntity => 'Entity';

  @override
  String get adminAuditLogTableTime => 'Time';

  @override
  String get adminAuditLogTitle => 'Audit Log';

  @override
  String get adminConfigListsActionsCancel => 'Cancel';

  @override
  String get adminConfigListsActionsEditLabel => 'Edit label';

  @override
  String get adminConfigListsActionsMoveDown => 'Move down';

  @override
  String get adminConfigListsActionsMoveUp => 'Move up';

  @override
  String get adminConfigListsActionsSave => 'Save';

  @override
  String get adminConfigListsActivate => 'Activate';

  @override
  String get adminConfigListsActive => 'Active';

  @override
  String get adminConfigListsAddItem => 'Add New Item';

  @override
  String get adminConfigListsCategoriesDocumentType => 'Document Types';

  @override
  String get adminConfigListsCategoriesEventCategory => 'Event Categories';

  @override
  String get adminConfigListsCategoriesFinanceExpenseCategory =>
      'Fund expense categories';

  @override
  String get adminConfigListsCategoriesFinanceIncomeCategory =>
      'Fund income categories';

  @override
  String get adminConfigListsCategoriesNoticeCategory => 'Notice Categories';

  @override
  String get adminConfigListsCategoriesPaymentAccount =>
      'Payment accounts (value = method, label = account details)';

  @override
  String get adminConfigListsCategoriesPropertyType => 'Property Types';

  @override
  String get adminConfigListsDeactivate => 'Deactivate';

  @override
  String get adminConfigListsErrorsLoadFailed =>
      'Could not load config list items.';

  @override
  String get adminConfigListsErrorsSaveFailed => 'Could not save the change.';

  @override
  String get adminConfigListsFormLabel => 'Label (optional)';

  @override
  String get adminConfigListsFormSubmit => 'Add Item';

  @override
  String get adminConfigListsFormValue => 'Value';

  @override
  String get adminConfigListsInactive => 'Inactive';

  @override
  String get adminConfigListsNoItems => 'No items in this category yet.';

  @override
  String get adminConfigListsSubtitle =>
      'Manage option lists used across the registration form and other screens';

  @override
  String get adminConfigListsTableActions => 'Actions';

  @override
  String get adminConfigListsTableLabel => 'Label';

  @override
  String get adminConfigListsTableStatus => 'Status';

  @override
  String get adminConfigListsTableValue => 'Value';

  @override
  String get adminConfigListsTitle => 'Config Lists';

  @override
  String get adminDashboardCostsOutstanding => 'Outstanding member dues';

  @override
  String get adminDashboardCostsQuarterTotal => 'This quarter\'s total';

  @override
  String get adminDashboardCostsTitle => 'Society costs this quarter';

  @override
  String get adminDashboardCostsViewAll => 'View all costs';

  @override
  String get adminDashboardDetailsLink => 'Details';

  @override
  String get adminDashboardErrorsLoadFailed =>
      'Could not load application list.';

  @override
  String get adminDashboardFinanceBalance => 'Current balance';

  @override
  String get adminDashboardFinanceMonthNet => 'This month\'s net';

  @override
  String get adminDashboardFinancePending => 'Pending approvals';

  @override
  String get adminDashboardFinanceTitle => 'Fund Transparency';

  @override
  String get adminDashboardFinanceViewAll => 'View all';

  @override
  String get adminDashboardNoPending => 'No pending applications';

  @override
  String get adminDashboardPendingTitle => 'Pending Applications';

  @override
  String get adminDashboardPropertiesUnit => '';

  @override
  String get adminDashboardSubtitle => 'Review new membership applications';

  @override
  String get adminDashboardTableHeadersApplicant => 'Applicant';

  @override
  String get adminDashboardTableHeadersMobile => 'Mobile';

  @override
  String get adminDashboardTableHeadersProperties => 'Properties';

  @override
  String get adminDashboardTableHeadersReference => 'Reference';

  @override
  String get adminDashboardTableHeadersSubmittedDate => 'Submitted Date';

  @override
  String get adminEventsCreate => 'New Event';

  @override
  String get adminEventsCreateFirst => 'Create your first event';

  @override
  String get adminEventsDeleteModalConfirmLabel => 'Delete';

  @override
  String get adminEventsDeleteModalMessageSuffix =>
      'will be permanently deleted.';

  @override
  String get adminEventsDeleteModalTitle => 'Delete event';

  @override
  String get adminEventsEmptyHelper =>
      'Published and draft events will appear here.';

  @override
  String get adminEventsErrorsDeleteFailed => 'Could not delete the event.';

  @override
  String get adminEventsErrorsLoadFailed => 'Could not load events.';

  @override
  String get adminEventsErrorsSaveFailed => 'Could not save the event.';

  @override
  String get adminEventsFiltersAll => 'All';

  @override
  String get adminEventsFiltersAllCategories => 'All categories';

  @override
  String get adminEventsFiltersCategory => 'Category filter';

  @override
  String get adminEventsFiltersDraft => 'Drafts';

  @override
  String get adminEventsFiltersPublished => 'Published';

  @override
  String get adminEventsFormCategory => 'Category';

  @override
  String get adminEventsFormCreate => 'Create';

  @override
  String get adminEventsFormCreateTitle => 'New event';

  @override
  String get adminEventsFormDescription => 'Description';

  @override
  String get adminEventsFormEditTitle => 'Edit event';

  @override
  String get adminEventsFormEndAt => 'Ends';

  @override
  String get adminEventsFormEndBeforeStart =>
      'End must be after the start time.';

  @override
  String get adminEventsFormLocation => 'Location';

  @override
  String get adminEventsFormMembersOnly =>
      'Members only (hidden from the public feed)';

  @override
  String get adminEventsFormNoCategory => 'No category';

  @override
  String get adminEventsFormPublished => 'Published';

  @override
  String get adminEventsFormStartAt => 'Starts';

  @override
  String get adminEventsFormStartAtRequired =>
      'Start date and time are required.';

  @override
  String get adminEventsFormTitle => 'Title';

  @override
  String get adminEventsMembersOnlyBadge => 'Members only';

  @override
  String get adminEventsNoItems => 'No events yet.';

  @override
  String get adminEventsPublish => 'Publish';

  @override
  String get adminEventsStatusDraft => 'Draft';

  @override
  String get adminEventsStatusPublished => 'Published';

  @override
  String get adminEventsSubtitle =>
      'Schedule the council\'s programme and publish it';

  @override
  String get adminEventsTableCategory => 'Category';

  @override
  String get adminEventsTableLocation => 'Location';

  @override
  String get adminEventsTableStatus => 'Status';

  @override
  String get adminEventsTableTitle => 'Title';

  @override
  String get adminEventsTableUntil => 'until';

  @override
  String get adminEventsTableWhen => 'When';

  @override
  String get adminEventsTitle => 'Events';

  @override
  String get adminEventsUnpublish => 'Unpublish';

  @override
  String get adminFeeSettingsActive => 'Active';

  @override
  String get adminFeeSettingsAddVersion => 'Add New Version';

  @override
  String get adminFeeSettingsCalculatorFee => 'Monthly Fee';

  @override
  String get adminFeeSettingsCalculatorLandSize => 'Land Size (decimal)';

  @override
  String get adminFeeSettingsCalculatorTitle => 'Fee Calculator';

  @override
  String get adminFeeSettingsConfirmMessage =>
      'The current version will be deactivated from today. Save the new version?';

  @override
  String get adminFeeSettingsConfirmTitle => 'Confirm New Version';

  @override
  String get adminFeeSettingsErrorsLoadFailed => 'Could not load fee settings.';

  @override
  String get adminFeeSettingsErrorsLoadHistoryFailed =>
      'Could not load fee setting history.';

  @override
  String get adminFeeSettingsErrorsSaveFailed =>
      'Could not save the new fee setting version.';

  @override
  String get adminFeeSettingsFormAdditionalRate =>
      'Additional Rate per Decimal';

  @override
  String get adminFeeSettingsFormAdditionalRateHint =>
      'Each additional decimal, or part of a decimal, is charged in full.';

  @override
  String get adminFeeSettingsFormBaseAmount => 'Base Amount';

  @override
  String get adminFeeSettingsFormBaseThreshold => 'Base Threshold (decimals)';

  @override
  String get adminFeeSettingsFormKey => 'Fee';

  @override
  String get adminFeeSettingsFormStartDate => 'Start Date (optional)';

  @override
  String get adminFeeSettingsFormStartDateHint =>
      'Leave empty to take effect from today';

  @override
  String get adminFeeSettingsFormSubmit => 'Save';

  @override
  String get adminFeeSettingsFormUnit => 'Unit';

  @override
  String get adminFeeSettingsFormValue => 'Value';

  @override
  String get adminFeeSettingsHideHistory => 'Hide History';

  @override
  String get adminFeeSettingsInactive => 'Inactive';

  @override
  String get adminFeeSettingsKeysAdmissionFee => 'Admission Fee';

  @override
  String get adminFeeSettingsKeysMonthlySubscription =>
      'Monthly Subscription Rate';

  @override
  String get adminFeeSettingsKeysMonthlySubscriptionAdditionalRate =>
      'Monthly Subscription Additional Rate';

  @override
  String get adminFeeSettingsKeysMonthlySubscriptionBaseAmount =>
      'Monthly Subscription Base Amount';

  @override
  String get adminFeeSettingsKeysMonthlySubscriptionBaseThreshold =>
      'Monthly Subscription Base Threshold';

  @override
  String get adminFeeSettingsKeysPicnicAdditionalHeadFee =>
      'Picnic Fee - Additional Head';

  @override
  String get adminFeeSettingsKeysPicnicHeadFee => 'Picnic Fee - Member Head';

  @override
  String get adminFeeSettingsNoSettings => 'No fee settings configured yet.';

  @override
  String get adminFeeSettingsPicnicNotConfigured =>
      'Picnic fee is not configured yet - members cannot pay until both picnic rates have an active version.';

  @override
  String get adminFeeSettingsSubtitle =>
      'Manage versioned fee rates with effective date ranges';

  @override
  String get adminFeeSettingsTableEndDate => 'End Date';

  @override
  String get adminFeeSettingsTableKey => 'Key';

  @override
  String get adminFeeSettingsTableStartDate => 'Start Date';

  @override
  String get adminFeeSettingsTableStatus => 'Status';

  @override
  String get adminFeeSettingsTableUnit => 'Unit';

  @override
  String get adminFeeSettingsTableValue => 'Value';

  @override
  String adminFeeSettingsTieredSummary(
      Object base, Object rate, Object threshold) {
    return '$base Taka up to $threshold decimal + $rate Taka for each additional decimal (a partial decimal counts as a full one)';
  }

  @override
  String get adminFeeSettingsTitle => 'Fee Settings';

  @override
  String get adminFeeSettingsUnitsPercent => '%';

  @override
  String get adminFeeSettingsUnitsTaka => 'Taka';

  @override
  String get adminFeeSettingsViewHistory => 'View History';

  @override
  String get adminFinanceManagementActionsApprove => 'Approve';

  @override
  String get adminFinanceManagementActionsReject => 'Reject';

  @override
  String get adminFinanceManagementActionsReverse => 'Reverse';

  @override
  String get adminFinanceManagementActionsSaveDraft => 'Save draft';

  @override
  String get adminFinanceManagementActionsSavePending => 'Save & submit';

  @override
  String get adminFinanceManagementActionsSubmit => 'Submit for approval';

  @override
  String get adminFinanceManagementCreate => 'New transaction';

  @override
  String get adminFinanceManagementCreateTitle => 'Add a transaction';

  @override
  String get adminFinanceManagementEditTitle => 'Edit transaction';

  @override
  String get adminFinanceManagementErrorsActionFailed =>
      'The action failed. Please retry.';

  @override
  String get adminFinanceManagementErrorsAmountRequired =>
      'Enter an amount greater than zero.';

  @override
  String get adminFinanceManagementErrorsAttachmentFailed =>
      'Attachment upload failed.';

  @override
  String get adminFinanceManagementErrorsCategoryAddFailed =>
      'Could not add the category.';

  @override
  String get adminFinanceManagementErrorsCategoryRequired =>
      'Select a category.';

  @override
  String get adminFinanceManagementErrorsDateRequired => 'Pick a date.';

  @override
  String get adminFinanceManagementErrorsDescriptionRequired =>
      'Enter a description.';

  @override
  String get adminFinanceManagementErrorsLoadFailed =>
      'Could not load the list. Please retry.';

  @override
  String get adminFinanceManagementErrorsReasonRequired =>
      'A reason is required.';

  @override
  String get adminFinanceManagementErrorsSaveFailed =>
      'Could not save. Please retry.';

  @override
  String get adminFinanceManagementFiltersAllCategories => 'All categories';

  @override
  String get adminFinanceManagementFiltersAllTypes => 'All types';

  @override
  String get adminFinanceManagementFiltersCategory => 'Category';

  @override
  String get adminFinanceManagementFiltersReset => 'Reset';

  @override
  String get adminFinanceManagementFiltersSearch =>
      'Search description/reference…';

  @override
  String get adminFinanceManagementFiltersType => 'Type';

  @override
  String get adminFinanceManagementFormAddCategory =>
      'Add new category (Enter)';

  @override
  String get adminFinanceManagementFormAmount => 'Amount';

  @override
  String get adminFinanceManagementFormAttachment => 'Attachment (image/PDF)';

  @override
  String get adminFinanceManagementFormCategory => 'Category';

  @override
  String get adminFinanceManagementFormCategoryNoMatch =>
      'No matching category';

  @override
  String get adminFinanceManagementFormCategorySearch =>
      'Search or type a category…';

  @override
  String get adminFinanceManagementFormDate => 'Date';

  @override
  String get adminFinanceManagementFormDescription => 'Description';

  @override
  String get adminFinanceManagementFormInternalNotes => 'Internal notes';

  @override
  String get adminFinanceManagementFormInternalNotesHint =>
      'Members never see these notes.';

  @override
  String get adminFinanceManagementFormReference => 'Reference no.';

  @override
  String get adminFinanceManagementFormReferenceAuto =>
      'Leave empty to auto-generate';

  @override
  String get adminFinanceManagementFormReferenceHint => 'FT-…';

  @override
  String get adminFinanceManagementFormType => 'Type';

  @override
  String get adminFinanceManagementLedgerAmount => 'Amount';

  @override
  String get adminFinanceManagementLedgerApprovedBy => 'Approved by';

  @override
  String get adminFinanceManagementLedgerCategory => 'Category';

  @override
  String adminFinanceManagementLedgerCount(Object count) {
    return '$count transactions';
  }

  @override
  String get adminFinanceManagementLedgerCreatedBy => 'Created by';

  @override
  String get adminFinanceManagementLedgerDate => 'Date';

  @override
  String get adminFinanceManagementLedgerDescription => 'Description';

  @override
  String get adminFinanceManagementLedgerEditWindowClosed =>
      'Direct edits close 7 days after approval — create a reversal to correct it.';

  @override
  String get adminFinanceManagementLedgerEmpty => 'No transactions';

  @override
  String get adminFinanceManagementLedgerEmptyHint =>
      'Add the first entry with \'New transaction\'.';

  @override
  String get adminFinanceManagementLedgerInternalNotes =>
      'Internal notes (committee only)';

  @override
  String get adminFinanceManagementLedgerLinkedPayment => 'Linked payment';

  @override
  String adminFinanceManagementLedgerPage(Object page, Object total) {
    return 'Page $page of $total';
  }

  @override
  String get adminFinanceManagementLedgerReference => 'Reference';

  @override
  String get adminFinanceManagementLedgerRejectionReason => 'Rejection reason';

  @override
  String get adminFinanceManagementLedgerReversalOf =>
      'Reversal of transaction';

  @override
  String get adminFinanceManagementLedgerStatus => 'Status';

  @override
  String get adminFinanceManagementLedgerType => 'Type';

  @override
  String get adminFinanceManagementLedgerViewAttachment => 'View attachment';

  @override
  String get adminFinanceManagementModalsApproveConfirm => 'Approve';

  @override
  String get adminFinanceManagementModalsApproveTitle => 'Approve transaction';

  @override
  String get adminFinanceManagementModalsApproveTwoPerson =>
      'Two-person control: the creator cannot approve their own entry — another committee member approves.';

  @override
  String get adminFinanceManagementModalsDeleteConfirm => 'Delete';

  @override
  String get adminFinanceManagementModalsDeleteReason =>
      'Reason (kept in the audit log)';

  @override
  String get adminFinanceManagementModalsDeleteTitle => 'Delete transaction';

  @override
  String get adminFinanceManagementModalsRejectConfirm => 'Reject';

  @override
  String get adminFinanceManagementModalsRejectReason => 'Rejection reason';

  @override
  String get adminFinanceManagementModalsRejectTitle => 'Reject transaction';

  @override
  String get adminFinanceManagementModalsReverseConfirm => 'Create reversal';

  @override
  String get adminFinanceManagementModalsReverseReason => 'Correction reason';

  @override
  String get adminFinanceManagementModalsReverseTitle =>
      'Reversal (correction entry)';

  @override
  String get adminFinanceManagementNoticeAll => 'All time';

  @override
  String get adminFinanceManagementNoticeDone => 'Notice published ✓';

  @override
  String get adminFinanceManagementNoticeMonth => 'This month';

  @override
  String get adminFinanceManagementNoticePeriod => 'Report period';

  @override
  String get adminFinanceManagementNoticePublish => 'Publish report notice';

  @override
  String get adminFinanceManagementNoticeYear => 'This year';

  @override
  String get adminFinanceManagementOverviewBalance => 'Current balance';

  @override
  String get adminFinanceManagementOverviewMonthNet => 'This month\'s net';

  @override
  String get adminFinanceManagementOverviewNoRecent => 'No transactions yet.';

  @override
  String get adminFinanceManagementOverviewPending => 'Pending approvals';

  @override
  String get adminFinanceManagementOverviewRecent => 'Last 5 transactions';

  @override
  String get adminFinanceManagementPaymentLinkAllSources => 'All sources';

  @override
  String adminFinanceManagementPaymentLinkAlreadyLinked(
      Object id, Object source) {
    return 'Currently linked: $source #$id';
  }

  @override
  String get adminFinanceManagementPaymentLinkEmpty =>
      'No unlinked payments match this filter.';

  @override
  String get adminFinanceManagementPaymentLinkSearchPlaceholder =>
      'Search member name…';

  @override
  String get adminFinanceManagementPaymentLinkTitle =>
      'Link an existing payment (avoids double counting)';

  @override
  String get adminFinanceManagementSourceCostShare => 'Cost share';

  @override
  String get adminFinanceManagementSourceInstallment => 'Monthly subscription';

  @override
  String get adminFinanceManagementSourcePicnicPayment => 'Picnic fee';

  @override
  String get adminFinanceManagementStatusAll => 'All';

  @override
  String get adminFinanceManagementStatusApproved => 'Approved';

  @override
  String get adminFinanceManagementStatusDraft => 'Draft';

  @override
  String get adminFinanceManagementStatusPending => 'Pending';

  @override
  String get adminFinanceManagementStatusRejected => 'Rejected';

  @override
  String get adminFinanceManagementSubtitle =>
      'Record, edit and approve fund transactions';

  @override
  String get adminFinanceManagementTitle => 'Finance Management';

  @override
  String get adminFinanceManagementTypeExpense => 'Expense';

  @override
  String get adminFinanceManagementTypeIncome => 'Income';

  @override
  String get adminInstallmentsErrorsLoadInstallmentsFailed =>
      'Could not load installment data.';

  @override
  String get adminInstallmentsErrorsLoadMembersFailed =>
      'Could not load member list.';

  @override
  String get adminInstallmentsErrorsMarkPaidFailed =>
      'Could not mark installment as paid.';

  @override
  String get adminInstallmentsMarkPaidButton => 'Mark as Paid';

  @override
  String get adminInstallmentsMonthsApril => 'April';

  @override
  String get adminInstallmentsMonthsAugust => 'August';

  @override
  String get adminInstallmentsMonthsDecember => 'December';

  @override
  String get adminInstallmentsMonthsFebruary => 'February';

  @override
  String get adminInstallmentsMonthsJanuary => 'January';

  @override
  String get adminInstallmentsMonthsJuly => 'July';

  @override
  String get adminInstallmentsMonthsJune => 'June';

  @override
  String get adminInstallmentsMonthsMarch => 'March';

  @override
  String get adminInstallmentsMonthsMay => 'May';

  @override
  String get adminInstallmentsMonthsNovember => 'November';

  @override
  String get adminInstallmentsMonthsOctober => 'October';

  @override
  String get adminInstallmentsMonthsSeptember => 'September';

  @override
  String get adminInstallmentsNoInstallments =>
      'This member has no installments.';

  @override
  String get adminInstallmentsNoMembers => 'No members found.';

  @override
  String get adminInstallmentsPaid => 'Paid';

  @override
  String get adminInstallmentsPermissionRequired => 'Permission required';

  @override
  String get adminInstallmentsSelectMember => 'Select a member.';

  @override
  String get adminInstallmentsSubtitle =>
      'Select a member to view and update monthly installment status';

  @override
  String get adminInstallmentsTitle => 'Subscription Management';

  @override
  String get adminMemberDetailClose => 'Close';

  @override
  String get adminMemberDetailDocsNone => 'No documents uploaded.';

  @override
  String get adminMemberDetailDue => 'Due';

  @override
  String get adminMemberDetailFAdmissionFee => 'Admission fee';

  @override
  String get adminMemberDetailFAmount => 'Amount';

  @override
  String get adminMemberDetailFApprovedBy => 'Reviewed by';

  @override
  String get adminMemberDetailFContribution => 'Contribution status';

  @override
  String get adminMemberDetailFCreated => 'Created';

  @override
  String get adminMemberDetailFDag => 'Dag no. (CS / RS)';

  @override
  String get adminMemberDetailFDate => 'Date';

  @override
  String get adminMemberDetailFDob => 'Date of birth';

  @override
  String get adminMemberDetailFDueTotal => 'Due total';

  @override
  String get adminMemberDetailFEmail => 'Email';

  @override
  String get adminMemberDetailFExtraHeads => 'Extra heads';

  @override
  String get adminMemberDetailFFatherOrHusband => 'Father\'s/husband\'s name';

  @override
  String get adminMemberDetailFGender => 'Gender';

  @override
  String get adminMemberDetailFHolding => 'Holding no.';

  @override
  String get adminMemberDetailFJoined => 'Applied on';

  @override
  String get adminMemberDetailFKhatian => 'Khatian no.';

  @override
  String get adminMemberDetailFLandSize => 'Land size (decimal)';

  @override
  String get adminMemberDetailFLastModifiedBy => 'Last modified by';

  @override
  String get adminMemberDetailFMemberId => 'Member ID';

  @override
  String get adminMemberDetailFMobile => 'Mobile';

  @override
  String get adminMemberDetailFMonth => 'Month';

  @override
  String get adminMemberDetailFMonthly => 'Monthly subscription';

  @override
  String get adminMemberDetailFMother => 'Mother\'s name';

  @override
  String get adminMemberDetailFMyShare => 'My share (decimal)';

  @override
  String get adminMemberDetailFName => 'Full name';

  @override
  String get adminMemberDetailFNid => 'NID / birth certificate';

  @override
  String get adminMemberDetailFNomineeMobile => 'Mobile';

  @override
  String get adminMemberDetailFNomineeRelation => 'Relation';

  @override
  String get adminMemberDetailFOccupation => 'Occupation';

  @override
  String get adminMemberDetailFOwnership => 'Ownership';

  @override
  String get adminMemberDetailFPaidOn => 'Paid on';

  @override
  String get adminMemberDetailFPaidTotal => 'Paid total';

  @override
  String get adminMemberDetailFPaymentMethod => 'Payment method';

  @override
  String get adminMemberDetailFPermanentAddress => 'Permanent address';

  @override
  String get adminMemberDetailFPresentAddress => 'Present address';

  @override
  String get adminMemberDetailFReceiptNo => 'Receipt no.';

  @override
  String get adminMemberDetailFRejectionReason => 'Rejection reason';

  @override
  String get adminMemberDetailFReviewedAt => 'Reviewed on';

  @override
  String get adminMemberDetailFStatus => 'Status';

  @override
  String get adminMemberDetailFTotal => 'Total';

  @override
  String get adminMemberDetailFUpdated => 'Last updated';

  @override
  String get adminMemberDetailFUrgentContact => 'Emergency contact';

  @override
  String get adminMemberDetailFullyPaid => 'Fully Paid';

  @override
  String get adminMemberDetailLoadFailed => 'Could not load member details.';

  @override
  String get adminMemberDetailMemberPhoto => 'Member photo';

  @override
  String get adminMemberDetailMonthsOverdue => 'months overdue';

  @override
  String get adminMemberDetailNoAudit => 'No audit entries.';

  @override
  String get adminMemberDetailNoInstallments => 'No installments yet.';

  @override
  String get adminMemberDetailNoNominees => 'No nominees.';

  @override
  String get adminMemberDetailNoPicnic => 'No picnic payments.';

  @override
  String get adminMemberDetailNoProperties => 'No properties.';

  @override
  String get adminMemberDetailOpenInstallments => 'Manage installments';

  @override
  String get adminMemberDetailPaid => 'Paid';

  @override
  String get adminMemberDetailReceiptPhoto => 'Payment receipt';

  @override
  String get adminMemberDetailRetry => 'Retry';

  @override
  String get adminMemberDetailSectionsAudit => 'Audit trail';

  @override
  String get adminMemberDetailSectionsContact => 'Contact';

  @override
  String get adminMemberDetailSectionsDocuments => 'Documents';

  @override
  String get adminMemberDetailSectionsFees => 'Fees & subscription';

  @override
  String get adminMemberDetailSectionsIdentity => 'Identity';

  @override
  String get adminMemberDetailSectionsInstallments => 'Installments';

  @override
  String get adminMemberDetailSectionsMembership => 'Membership status';

  @override
  String get adminMemberDetailSectionsNominees => 'Nominees';

  @override
  String get adminMemberDetailSectionsPicnic => 'Picnic payments';

  @override
  String get adminMemberDetailSectionsProperty => 'Property';

  @override
  String get adminMemberDetailSignature => 'Signature';

  @override
  String get adminMemberDetailTitle => 'Member Details';

  @override
  String get adminMembersListDeleteMemberTitle => 'Delete member';

  @override
  String get adminMembersListDeleteModalConfirmLabel => 'Delete';

  @override
  String get adminMembersListDeleteModalMessageSuffix =>
      '\'s member record will be permanently deleted. This action cannot be undone.';

  @override
  String get adminMembersListDeleteModalTitle => 'Delete Record?';

  @override
  String get adminMembersListErrorsDeleteFailed => 'Could not delete member.';

  @override
  String get adminMembersListErrorsLoadFailed => 'Could not load member list.';

  @override
  String get adminMembersListErrorsResetFailed =>
      'Could not reset the password.';

  @override
  String get adminMembersListFullyPaid => 'Fully Paid';

  @override
  String get adminMembersListMonthsOverdue => 'months overdue';

  @override
  String get adminMembersListNoMembers => 'No members found.';

  @override
  String get adminMembersListResetModalConfirmLabel => 'Reset & Email';

  @override
  String get adminMembersListResetModalMessageSuffix =>
      '\'s login password will be reset, and the new password will be emailed to the member\'s registered email address.';

  @override
  String adminMembersListResetModalSuccessMessage(Object name) {
    return 'Password reset successfully. A new password has been emailed to $name\'s registered email address.';
  }

  @override
  String get adminMembersListResetModalSuccessNoEmail =>
      'Password reset successfully, but the email could not be sent. Please share the new password with the member directly.';

  @override
  String get adminMembersListResetModalTitle => 'Reset Password?';

  @override
  String get adminMembersListResetPasswordTitle =>
      'Reset password and email new credentials';

  @override
  String get adminMembersListSubtitle =>
      'View members\' information and subscription status';

  @override
  String get adminMembersListTableHeadersActions => 'Actions';

  @override
  String get adminMembersListTableHeadersContributionStatus =>
      'Contribution Status';

  @override
  String get adminMembersListTableHeadersMemberId => 'Member ID';

  @override
  String get adminMembersListTableHeadersMobile => 'Mobile';

  @override
  String get adminMembersListTableHeadersName => 'Name';

  @override
  String get adminMembersListTableHeadersStatus => 'Status';

  @override
  String get adminMembersListTitle => 'All Members';

  @override
  String get adminMembersListViewContributionsTitle =>
      'View contribution status';

  @override
  String get adminMembersListViewDetailsTitle => 'View member details';

  @override
  String get adminNoticesCreate => 'New Notice';

  @override
  String get adminNoticesCreateFirst => 'Create your first notice';

  @override
  String get adminNoticesDeleteModalConfirmLabel => 'Delete';

  @override
  String get adminNoticesDeleteModalMessageSuffix =>
      'will be permanently deleted.';

  @override
  String get adminNoticesDeleteModalTitle => 'Delete notice';

  @override
  String get adminNoticesEmptyHelper =>
      'Published and draft notices will appear here.';

  @override
  String get adminNoticesErrorsDeleteFailed => 'Could not delete the notice.';

  @override
  String get adminNoticesErrorsLoadFailed => 'Could not load notices.';

  @override
  String get adminNoticesErrorsSaveFailed => 'Could not save the notice.';

  @override
  String get adminNoticesFiltersAll => 'All';

  @override
  String get adminNoticesFiltersAllCategories => 'All categories';

  @override
  String get adminNoticesFiltersCategory => 'Category filter';

  @override
  String get adminNoticesFiltersDraft => 'Drafts';

  @override
  String get adminNoticesFiltersPublished => 'Published';

  @override
  String get adminNoticesFormBody => 'Body';

  @override
  String get adminNoticesFormCategory => 'Category';

  @override
  String get adminNoticesFormCreate => 'Create';

  @override
  String get adminNoticesFormCreateTitle => 'New notice';

  @override
  String get adminNoticesFormEditTitle => 'Edit notice';

  @override
  String get adminNoticesFormMembersOnly =>
      'Members only (hidden from the public feed)';

  @override
  String get adminNoticesFormNoCategory => 'No category';

  @override
  String get adminNoticesFormPublishAt => 'Publish at';

  @override
  String get adminNoticesFormPublishAtHint =>
      'Optional. A scheduled notice stays hidden until this time passes.';

  @override
  String get adminNoticesFormPublishAtPast =>
      'Publish date/time cannot be in the past.';

  @override
  String get adminNoticesFormPublished => 'Published';

  @override
  String get adminNoticesFormTitle => 'Title';

  @override
  String get adminNoticesMembersOnlyBadge => 'Members only';

  @override
  String get adminNoticesNoItems => 'No notices yet.';

  @override
  String get adminNoticesPublish => 'Publish';

  @override
  String get adminNoticesStatusDraft => 'Draft';

  @override
  String get adminNoticesStatusPublished => 'Published';

  @override
  String get adminNoticesStatusScheduled => 'Scheduled';

  @override
  String get adminNoticesSubtitle =>
      'Write and publish bulletins to members and visitors';

  @override
  String get adminNoticesTableCategory => 'Category';

  @override
  String get adminNoticesTablePublishAt => 'Publish at';

  @override
  String get adminNoticesTableStatus => 'Status';

  @override
  String get adminNoticesTableTitle => 'Title';

  @override
  String get adminNoticesTitle => 'Notices';

  @override
  String get adminNoticesUnpublish => 'Unpublish';

  @override
  String get adminPaymentVerificationsActionError =>
      'Action failed. Please try again.';

  @override
  String get adminPaymentVerificationsApprove => 'Approve';

  @override
  String get adminPaymentVerificationsCancel => 'Cancel';

  @override
  String get adminPaymentVerificationsEmpty => 'Nothing here — all caught up.';

  @override
  String get adminPaymentVerificationsLoadError => 'Failed to load payments.';

  @override
  String get adminPaymentVerificationsMethod => 'Method';

  @override
  String get adminPaymentVerificationsPaidOn => 'Paid on';

  @override
  String get adminPaymentVerificationsReason => 'Reason shown to the member';

  @override
  String get adminPaymentVerificationsReasonPlaceholder =>
      'e.g. Transaction ID not found in bKash statement';

  @override
  String get adminPaymentVerificationsReference => 'Transaction ID';

  @override
  String get adminPaymentVerificationsReject => 'Reject';

  @override
  String get adminPaymentVerificationsRejectTitle => 'Reject payment';

  @override
  String get adminPaymentVerificationsSender => 'Paid from';

  @override
  String get adminPaymentVerificationsSubtitle =>
      'Verify installment payments submitted by members against your account statement.';

  @override
  String get adminPaymentVerificationsTitle => 'Payment Verifications';

  @override
  String get adminPaymentVerificationsViewProof => 'View receipt';

  @override
  String get adminPicnicPaymentsApply => 'Apply';

  @override
  String get adminPicnicPaymentsCount => 'Payments';

  @override
  String get adminPicnicPaymentsDateColumn => 'Date';

  @override
  String get adminPicnicPaymentsDateFrom => 'From';

  @override
  String get adminPicnicPaymentsDateRange => 'Date Range';

  @override
  String get adminPicnicPaymentsDateTo => 'To';

  @override
  String get adminPicnicPaymentsEmptyState =>
      'No picnic payments found for the selected filters.';

  @override
  String get adminPicnicPaymentsHeadsColumn => 'Additional Heads';

  @override
  String get adminPicnicPaymentsLoadError => 'Could not load picnic payments.';

  @override
  String get adminPicnicPaymentsMemberColumn => 'Member';

  @override
  String get adminPicnicPaymentsMemberFilter => 'Member ID (optional)';

  @override
  String get adminPicnicPaymentsMethodColumn => 'Method';

  @override
  String get adminPicnicPaymentsReceiptColumn => 'Receipt No';

  @override
  String get adminPicnicPaymentsReset => 'Reset';

  @override
  String get adminPicnicPaymentsSubtitle =>
      'All members\' picnic payments with filters and totals';

  @override
  String get adminPicnicPaymentsTitle => 'Picnic Payments';

  @override
  String get adminPicnicPaymentsTotalCollected => 'Total Collected';

  @override
  String get adminPicnicPaymentsTotalColumn => 'Total';

  @override
  String get adminPropertyRequestsActionsAdd => 'Add';

  @override
  String get adminPropertyRequestsActionsDelete => 'Delete';

  @override
  String get adminPropertyRequestsActionsEdit => 'Edit';

  @override
  String get adminPropertyRequestsApproveButton => 'Approve';

  @override
  String get adminPropertyRequestsApproveModalConfirmLabel => 'Approve';

  @override
  String get adminPropertyRequestsApproveModalMessageSuffix =>
      'will be applied to the member\'s records.';

  @override
  String get adminPropertyRequestsApproveModalTitle => 'Approve request';

  @override
  String get adminPropertyRequestsCancelButton => 'Cancel';

  @override
  String get adminPropertyRequestsCancelModalConfirmLabel => 'Cancel request';

  @override
  String get adminPropertyRequestsCancelModalMessageSuffix =>
      'will be cancelled.';

  @override
  String get adminPropertyRequestsCancelModalPlaceholder =>
      'Enter the reason for cancelling...';

  @override
  String get adminPropertyRequestsCancelModalTitle => 'Cancel request';

  @override
  String get adminPropertyRequestsCancelReasonLabel => 'Cancel reason';

  @override
  String get adminPropertyRequestsDeleteRequestNote =>
      'This member requested deletion of this property.';

  @override
  String get adminPropertyRequestsErrorsApproveFailed =>
      'Could not approve the request.';

  @override
  String get adminPropertyRequestsErrorsCancelFailed =>
      'Could not cancel the request.';

  @override
  String get adminPropertyRequestsErrorsLoadFailed => 'Could not load list.';

  @override
  String get adminPropertyRequestsErrorsReasonRequired =>
      'A reason is required to cancel.';

  @override
  String get adminPropertyRequestsNoRequests => 'No property requests found';

  @override
  String get adminPropertyRequestsStatusLabelsAll => 'All';

  @override
  String get adminPropertyRequestsStatusLabelsApproved => 'Approved';

  @override
  String get adminPropertyRequestsStatusLabelsCancelled => 'Cancelled';

  @override
  String get adminPropertyRequestsStatusLabelsPending => 'Pending';

  @override
  String get adminPropertyRequestsSubtitle =>
      'Review member requests to add, edit, or delete properties';

  @override
  String get adminPropertyRequestsTableHeadersAction => 'Action';

  @override
  String get adminPropertyRequestsTableHeadersActions => 'Actions';

  @override
  String get adminPropertyRequestsTableHeadersDate => 'Submitted';

  @override
  String get adminPropertyRequestsTableHeadersMember => 'Member';

  @override
  String get adminPropertyRequestsTableHeadersProperty => 'Property';

  @override
  String get adminPropertyRequestsTableHeadersReference => 'Reference';

  @override
  String get adminPropertyRequestsTableHeadersStatus => 'Status';

  @override
  String get adminPropertyRequestsTitle => 'Property Requests';

  @override
  String get adminRoadmapAdd => 'New item';

  @override
  String get adminRoadmapAddHere => 'Add';

  @override
  String get adminRoadmapArchiveAll =>
      'Archive everything and start a new cycle';

  @override
  String get adminRoadmapArchiveButton => 'Archive cycle';

  @override
  String get adminRoadmapArchiveConfirm => 'Archive';

  @override
  String adminRoadmapArchiveCycleSummary(Object done, Object total) {
    return '$done of $total done';
  }

  @override
  String adminRoadmapArchiveDone(Object n) {
    return '$n items archived.';
  }

  @override
  String get adminRoadmapArchiveEmpty => 'No cycles archived yet.';

  @override
  String get adminRoadmapArchiveHistory => 'Archived cycles';

  @override
  String get adminRoadmapArchiveMessage =>
      'Archived items leave the member page but stay in the history.';

  @override
  String get adminRoadmapArchiveOnlyDone =>
      'Archive completed items only (the rest carry over)';

  @override
  String get adminRoadmapArchiveTitle => 'Archive roadmap cycle';

  @override
  String get adminRoadmapDeleteTitle => 'Delete this roadmap item?';

  @override
  String get adminRoadmapErrorsGeneric =>
      'The action could not be completed. Please try again.';

  @override
  String get adminRoadmapErrorsNoteTooLong =>
      'The note can be at most 1000 characters.';

  @override
  String get adminRoadmapErrorsOwnerTooLong =>
      'The responsible person can be at most 120 characters.';

  @override
  String get adminRoadmapErrorsTextRequired => 'Describe the plan.';

  @override
  String get adminRoadmapErrorsTextTooLong =>
      'The plan can be at most 500 characters.';

  @override
  String get adminRoadmapErrorsTimeframe => 'Choose a timeframe.';

  @override
  String get adminRoadmapFormCreateTitle => 'Add roadmap item';

  @override
  String get adminRoadmapFormEditTitle => 'Edit roadmap item';

  @override
  String get adminRoadmapFormMoveHint =>
      'On save the item moves to the end of the selected timeframe.';

  @override
  String get adminRoadmapFormNote => 'Update / note (optional)';

  @override
  String get adminRoadmapFormNotePlaceholder =>
      'e.g. Sand filling has started, expected to finish by November';

  @override
  String get adminRoadmapFormNotify => 'Notify members';

  @override
  String get adminRoadmapFormOwner => 'Responsible (optional)';

  @override
  String get adminRoadmapFormOwnerPlaceholder => 'e.g. General Secretary';

  @override
  String get adminRoadmapFormStatus => 'Status';

  @override
  String get adminRoadmapFormTargetDate => 'Target date (optional)';

  @override
  String get adminRoadmapFormText => 'Plan';

  @override
  String get adminRoadmapFormTimeframe => 'Timeframe';

  @override
  String get adminRoadmapMoveDown => 'Move down';

  @override
  String get adminRoadmapMoveUp => 'Move up';

  @override
  String get adminRoadmapNotifyOnDone =>
      'Notify members when an item is completed';

  @override
  String adminRoadmapOverall(Object done, Object total) {
    return '$done of $total done';
  }

  @override
  String get adminRoadmapStatusAria => 'Change status';

  @override
  String get adminRoadmapSubtitle =>
      'Add, edit and update progress on short, mid and long term plans. Every change is recorded in the audit log.';

  @override
  String get adminRoadmapTitle => 'Roadmap Management';

  @override
  String get adminRoadmapViewAsMember => 'Member view';

  @override
  String get adminRoleManagementAllPermissionsAlways =>
      'All Permissions — Always';

  @override
  String get adminRoleManagementCreateAdminEmailLabel => 'Email';

  @override
  String get adminRoleManagementCreateAdminNameLabel => 'Name';

  @override
  String get adminRoleManagementCreateAdminNamePlaceholder => 'Full name';

  @override
  String get adminRoleManagementCreateAdminPasswordLabel => 'Password';

  @override
  String get adminRoleManagementCreateAdminPasswordPlaceholder => 'Password';

  @override
  String get adminRoleManagementCreateAdminRoleLabel => 'Role';

  @override
  String get adminRoleManagementCreateAdminSubmitButton =>
      'Create Administrator';

  @override
  String get adminRoleManagementCreateAdminSubtitle =>
      'Create a new administrator account with an email and password.';

  @override
  String get adminRoleManagementCreateAdminSuccessPrefix =>
      'New administrator created:';

  @override
  String get adminRoleManagementCreateAdminTitle => 'Create New Administrator';

  @override
  String get adminRoleManagementErrorsAssignRoleFailed =>
      'Could not assign role.';

  @override
  String get adminRoleManagementErrorsCreateUserFailed =>
      'Could not create new administrator.';

  @override
  String get adminRoleManagementErrorsLoadOverridesFailed =>
      'Could not load individual permissions.';

  @override
  String get adminRoleManagementErrorsLoadPermissionsFailed =>
      'Could not load permission list.';

  @override
  String get adminRoleManagementErrorsLoadRolesFailed =>
      'Could not load role list.';

  @override
  String get adminRoleManagementErrorsLoadUsersFailed =>
      'Could not load user list.';

  @override
  String get adminRoleManagementErrorsSaveChangeFailed =>
      'Could not save the change.';

  @override
  String get adminRoleManagementErrorsSaveOverridesFailed =>
      'Could not save individual permissions.';

  @override
  String get adminRoleManagementSubtitle => 'Set permissions for each role';

  @override
  String get adminRoleManagementTitle => 'Role & Permission Management';

  @override
  String get adminRoleManagementUserOverridesActionLabel => 'Action';

  @override
  String get adminRoleManagementUserOverridesApplyButton => 'Apply';

  @override
  String get adminRoleManagementUserOverridesAssignRoleLabel => 'Assign Role';

  @override
  String get adminRoleManagementUserOverridesGrantOption => 'Grant Extra';

  @override
  String get adminRoleManagementUserOverridesNoOverrides =>
      'This user has no individual permissions.';

  @override
  String get adminRoleManagementUserOverridesPermissionLabel => 'Permission';

  @override
  String get adminRoleManagementUserOverridesRevokeOption => 'Revoke';

  @override
  String get adminRoleManagementUserOverridesSaveRoleButton => 'Save Role';

  @override
  String get adminRoleManagementUserOverridesSubtitle =>
      'Grant or revoke additional permissions for a specific user, outside their role\'s defaults.';

  @override
  String get adminRoleManagementUserOverridesTitle => 'User-Specific Overrides';

  @override
  String get adminRoleManagementUserOverridesUserLabel => 'User';

  @override
  String get adminSocietyCostsCreate => 'New Cost';

  @override
  String get adminSocietyCostsCreateTitle => 'Record a society cost';

  @override
  String get adminSocietyCostsDeleteMessage =>
      'This will delete the cost and its split. This cannot be undone.';

  @override
  String get adminSocietyCostsDeleteTitle => 'Delete cost';

  @override
  String get adminSocietyCostsEdit => 'Edit';

  @override
  String get adminSocietyCostsEditTitle => 'Edit cost';

  @override
  String get adminSocietyCostsEmptyState => 'No costs recorded yet';

  @override
  String get adminSocietyCostsErrorsAmountRequired =>
      'Enter an amount greater than zero.';

  @override
  String get adminSocietyCostsErrorsCategoryAddFailed =>
      'Could not add the category.';

  @override
  String get adminSocietyCostsErrorsDateRequired =>
      'The incurred date is required.';

  @override
  String get adminSocietyCostsErrorsDeleteFailed =>
      'Could not delete the cost. It may already have payments recorded.';

  @override
  String get adminSocietyCostsErrorsLoadFailed =>
      'Could not load society costs. Please try again.';

  @override
  String get adminSocietyCostsErrorsPaymentFailed =>
      'Could not record the payment. Please try again.';

  @override
  String get adminSocietyCostsErrorsReceiptUploadFailed =>
      'The cost was saved, but the receipt upload failed. Try uploading it again from Edit.';

  @override
  String get adminSocietyCostsErrorsSaveFailed =>
      'Could not save the cost. Please try again.';

  @override
  String get adminSocietyCostsErrorsSplitFailed =>
      'Could not save the split. Please try again.';

  @override
  String get adminSocietyCostsErrorsSplitPreviewFailed =>
      'Could not compute the split preview.';

  @override
  String get adminSocietyCostsErrorsTitleRequired => 'A title is required.';

  @override
  String get adminSocietyCostsExportCsv => 'Export CSV';

  @override
  String get adminSocietyCostsFiltersAll => 'All';

  @override
  String get adminSocietyCostsFiltersAllCategories => 'All categories';

  @override
  String get adminSocietyCostsFiltersAllSources => 'All sources';

  @override
  String get adminSocietyCostsFiltersBilled => 'Billing status';

  @override
  String get adminSocietyCostsFiltersBilledOnly => 'Billed to members';

  @override
  String get adminSocietyCostsFiltersCategory => 'Category';

  @override
  String get adminSocietyCostsFiltersDateRange => 'Date range';

  @override
  String get adminSocietyCostsFiltersReset => 'Reset';

  @override
  String get adminSocietyCostsFiltersSearch => 'Search';

  @override
  String get adminSocietyCostsFiltersSearchPlaceholder => 'Search by title…';

  @override
  String get adminSocietyCostsFiltersSource => 'Payment source';

  @override
  String get adminSocietyCostsFiltersUnbilledOnly => 'Not billed';

  @override
  String get adminSocietyCostsFormAddCategory => 'Add category + Enter';

  @override
  String get adminSocietyCostsFormAmount => 'Amount (৳)';

  @override
  String get adminSocietyCostsFormCategory => 'Category';

  @override
  String get adminSocietyCostsFormDate => 'Incurred date';

  @override
  String get adminSocietyCostsFormDescription => 'Description';

  @override
  String get adminSocietyCostsFormNoCategory => 'No category';

  @override
  String get adminSocietyCostsFormNotes => 'Notes';

  @override
  String get adminSocietyCostsFormReceipt => 'Receipt (image/PDF)';

  @override
  String get adminSocietyCostsFormSource => 'Paid from';

  @override
  String get adminSocietyCostsFormTitle => 'Title';

  @override
  String get adminSocietyCostsNotBilled => 'Not billed';

  @override
  String get adminSocietyCostsPaymentAmount => 'Amount paid now (৳)';

  @override
  String get adminSocietyCostsPaymentRemaining => 'remaining';

  @override
  String get adminSocietyCostsPaymentTitle => 'Record payment';

  @override
  String get adminSocietyCostsRecordPayment => 'Record payment';

  @override
  String get adminSocietyCostsShareStatusPaid => 'Paid';

  @override
  String get adminSocietyCostsShareStatusPartial => 'Partial';

  @override
  String get adminSocietyCostsShareStatusUnpaid => 'Unpaid';

  @override
  String get adminSocietyCostsSourceMemberBilled => 'Member billed';

  @override
  String get adminSocietyCostsSourceSocietyFund => 'Society fund';

  @override
  String get adminSocietyCostsSplitConfirm => 'Confirm split';

  @override
  String get adminSocietyCostsSplitMethod => 'Split method';

  @override
  String get adminSocietyCostsSplitMismatchWarning =>
      'The amounts do not add up to the cost total. Adjust them, or confirm the override to save anyway.';

  @override
  String get adminSocietyCostsSplitNoMembers =>
      'No active members to split across.';

  @override
  String get adminSocietyCostsSplitOverride =>
      'Save anyway with mismatched total';

  @override
  String get adminSocietyCostsSplitRunningTotal => 'Running total';

  @override
  String adminSocietyCostsSplitSummaryLine(Object method, Object total) {
    return 'Splitting ৳$total across active members ($method)';
  }

  @override
  String get adminSocietyCostsSplitTitle => 'Split cost';

  @override
  String get adminSocietyCostsSplitAction => 'Split';

  @override
  String get adminSocietyCostsSplitMethodByLandQuantity => 'By land quantity';

  @override
  String get adminSocietyCostsSplitMethodEqual => 'Equal split';

  @override
  String get adminSocietyCostsSplitMethodManual => 'Manual';

  @override
  String get adminSocietyCostsSubtitle =>
      'Record every society expense, optionally split it among members';

  @override
  String get adminSocietyCostsSummaryOutstanding => 'Outstanding member dues';

  @override
  String get adminSocietyCostsSummarySocietyFund => 'Paid from society fund';

  @override
  String get adminSocietyCostsSummaryTotal => 'Total costs';

  @override
  String get adminSocietyCostsTableAmount => 'Amount';

  @override
  String get adminSocietyCostsTableCategory => 'Category';

  @override
  String get adminSocietyCostsTableDate => 'Date';

  @override
  String get adminSocietyCostsTableSource => 'Source';

  @override
  String get adminSocietyCostsTableSplit => 'Split';

  @override
  String get adminSocietyCostsTableTitle => 'Title';

  @override
  String get adminSocietyCostsTitle => 'Society Costs';

  @override
  String get adminSocietyCostsViewReceipt => 'View receipt';

  @override
  String get adminStatusLabelsAll => 'All';

  @override
  String get adminStatusLabelsApproved => 'Approved';

  @override
  String get adminStatusLabelsPending => 'Pending';

  @override
  String get adminStatusLabelsRejected => 'Rejected';

  @override
  String get adminSubmissionDetailAlsoEmergency => 'Same as emergency contact';

  @override
  String get adminSubmissionDetailAlsoNominee => 'Also nominee';

  @override
  String get adminSubmissionDetailApplicableDocs => 'Applicable Documents';

  @override
  String get adminSubmissionDetailApproveButton => 'Approve';

  @override
  String get adminSubmissionDetailApproveModalConfirmLabel =>
      'Confirm and Approve';

  @override
  String get adminSubmissionDetailApproveModalMessageSuffix =>
      'will be approved as a member; a member ID and login credentials will be created automatically.';

  @override
  String get adminSubmissionDetailApproveModalTitle => 'Approve Application';

  @override
  String get adminSubmissionDetailAttachments => 'Attachments';

  @override
  String get adminSubmissionDetailCall => 'Call';

  @override
  String get adminSubmissionDetailCollapse => 'Collapse';

  @override
  String get adminSubmissionDetailCopied => 'Copied';

  @override
  String get adminSubmissionDetailCopyValue => 'Copy value';

  @override
  String get adminSubmissionDetailCurrentAddress => 'Current Address';

  @override
  String get adminSubmissionDetailDecimalUnit => 'decimal';

  @override
  String get adminSubmissionDetailDownload => 'Download';

  @override
  String get adminSubmissionDetailErrorsApproveFailed => 'Approval failed.';

  @override
  String get adminSubmissionDetailErrorsDownloadFailed =>
      'Download failed. The file may be missing on the server.';

  @override
  String get adminSubmissionDetailErrorsLoadFailed =>
      'Could not load application details.';

  @override
  String get adminSubmissionDetailErrorsReasonRequired =>
      'Please enter a reason for rejection.';

  @override
  String get adminSubmissionDetailErrorsRejectEmailFailed =>
      'Rejected, but the applicant could not be notified by email.';

  @override
  String get adminSubmissionDetailErrorsRejectFailed => 'Rejection failed.';

  @override
  String get adminSubmissionDetailErrorsResendFailed =>
      'Could not resend the notification.';

  @override
  String get adminSubmissionDetailErrorsUploadFailed =>
      'Upload failed. Please try again.';

  @override
  String get adminSubmissionDetailExpand => 'Expand';

  @override
  String get adminSubmissionDetailFieldLabelsAddress => 'Address';

  @override
  String get adminSubmissionDetailFieldLabelsArea => 'Area';

  @override
  String get adminSubmissionDetailFieldLabelsDagNoCs => 'Dag No. (CS)';

  @override
  String get adminSubmissionDetailFieldLabelsDagNoRs => 'Dag No. (RS)';

  @override
  String get adminSubmissionDetailFieldLabelsDescription => 'Description';

  @override
  String get adminSubmissionDetailFieldLabelsDob => 'Date of Birth';

  @override
  String get adminSubmissionDetailFieldLabelsHoldingNumber => 'Holding No.';

  @override
  String get adminSubmissionDetailFieldLabelsKhatianNo => 'Khatian No.';

  @override
  String get adminSubmissionDetailFieldLabelsLandQuantity =>
      'Total Land Quantity (Decimal)';

  @override
  String get adminSubmissionDetailFieldLabelsMobile => 'Mobile';

  @override
  String get adminSubmissionDetailFieldLabelsMyShareQuantity =>
      'My Share Quantity (Decimal)';

  @override
  String get adminSubmissionDetailFieldLabelsName => 'Name';

  @override
  String get adminSubmissionDetailFieldLabelsNid => 'NID';

  @override
  String get adminSubmissionDetailFieldLabelsOwnership => 'Ownership';

  @override
  String get adminSubmissionDetailFieldLabelsPercentage => 'Percentage';

  @override
  String get adminSubmissionDetailFieldLabelsRelation => 'Relation';

  @override
  String get adminSubmissionDetailFieldLabelsType => 'Type';

  @override
  String get adminSubmissionDetailFieldLabelsValue => 'Value';

  @override
  String get adminSubmissionDetailFieldsAddress => 'Address';

  @override
  String get adminSubmissionDetailFieldsAdmissionFee => 'Admission Fee';

  @override
  String get adminSubmissionDetailFieldsDistrict => 'District';

  @override
  String get adminSubmissionDetailFieldsDivision => 'Division';

  @override
  String get adminSubmissionDetailFieldsDob => 'Date of Birth';

  @override
  String get adminSubmissionDetailFieldsEmail => 'Email';

  @override
  String get adminSubmissionDetailFieldsFatherOrHusband => 'Father/Husband';

  @override
  String get adminSubmissionDetailFieldsGender => 'Gender';

  @override
  String get adminSubmissionDetailFieldsHouse => 'House/Holding No.';

  @override
  String get adminSubmissionDetailFieldsMemberPhoto => 'Member Photo';

  @override
  String get adminSubmissionDetailFieldsMemberSignature => 'Member Signature';

  @override
  String get adminSubmissionDetailFieldsMobile => 'Mobile';

  @override
  String get adminSubmissionDetailFieldsMother => 'Mother';

  @override
  String get adminSubmissionDetailFieldsName => 'Name';

  @override
  String get adminSubmissionDetailFieldsNationality => 'Nationality';

  @override
  String get adminSubmissionDetailFieldsOccupation => 'Occupation';

  @override
  String get adminSubmissionDetailFieldsPaymentMethod => 'Payment Method';

  @override
  String get adminSubmissionDetailFieldsPostOffice => 'Post Office';

  @override
  String get adminSubmissionDetailFieldsReceiptNo => 'Receipt No.';

  @override
  String get adminSubmissionDetailFieldsReceiptPhoto => 'Receipt Photo';

  @override
  String get adminSubmissionDetailFieldsRejectionReason => 'Rejection Reason';

  @override
  String get adminSubmissionDetailFieldsRelation => 'Relation';

  @override
  String get adminSubmissionDetailFieldsRoad => 'Road/Village';

  @override
  String get adminSubmissionDetailFieldsStatus => 'Status';

  @override
  String get adminSubmissionDetailFieldsSubscription => 'Subscription';

  @override
  String get adminSubmissionDetailFieldsUpazila => 'Upazila/Thana';

  @override
  String get adminSubmissionDetailFileMissing =>
      'The file is missing on the server. Please upload it again.';

  @override
  String get adminSubmissionDetailJointOwnerCountLabel => 'Joint Owner Count';

  @override
  String get adminSubmissionDetailNoApplicableDocs => 'No documents attached.';

  @override
  String get adminSubmissionDetailNoAttachment => 'Not attached';

  @override
  String get adminSubmissionDetailNoNominees =>
      'No nominee information provided.';

  @override
  String get adminSubmissionDetailNoProperties =>
      'No property information provided.';

  @override
  String get adminSubmissionDetailNomineeCardTitle => 'Nominee';

  @override
  String adminSubmissionDetailNomineeCount(Object count) {
    return '$count total';
  }

  @override
  String get adminSubmissionDetailNominees => 'Nominees';

  @override
  String get adminSubmissionDetailNotNotified =>
      'The applicant has not been notified by email.';

  @override
  String get adminSubmissionDetailNotProvided => 'Not provided';

  @override
  String get adminSubmissionDetailPaymentSummary => 'Payment & Status';

  @override
  String get adminSubmissionDetailPermanentAddress => 'Permanent Address';

  @override
  String get adminSubmissionDetailPersonalInfo => 'Personal Information';

  @override
  String get adminSubmissionDetailProperties => 'Properties';

  @override
  String get adminSubmissionDetailPropertyCardTitle => 'Property';

  @override
  String adminSubmissionDetailPropertyCount(Object count) {
    return '$count total';
  }

  @override
  String get adminSubmissionDetailRejectButton => 'Reject';

  @override
  String get adminSubmissionDetailRejectModalConfirmLabel =>
      'Confirm Rejection';

  @override
  String get adminSubmissionDetailRejectModalMessageSuffix =>
      '\'s application — enter the reason for rejection. This will be shown to the applicant.';

  @override
  String get adminSubmissionDetailRejectModalPlaceholder =>
      'e.g., required documents are missing...';

  @override
  String get adminSubmissionDetailRejectModalTitle => 'Reject Application';

  @override
  String get adminSubmissionDetailReplaceFile => 'Replace file';

  @override
  String get adminSubmissionDetailResendButton => 'Resend notification';

  @override
  String get adminSubmissionDetailRoleApplicant => 'Applicant';

  @override
  String get adminSubmissionDetailRoleColumn => 'Role';

  @override
  String get adminSubmissionDetailRoleEmergency => 'Emergency';

  @override
  String get adminSubmissionDetailRoleNominee => 'Nominee';

  @override
  String adminSubmissionDetailShareTotal(Object value) {
    return 'Total share: $value%';
  }

  @override
  String adminSubmissionDetailShareWarning(Object value) {
    return 'Total share is $value% — must equal 100%';
  }

  @override
  String get adminSubmissionDetailSharedMobileWarning =>
      'This number is used by multiple co-owners';

  @override
  String get adminSubmissionDetailTitle => 'Application Details';

  @override
  String get adminSubmissionDetailUploadAgain => 'Upload again';

  @override
  String get adminSubmissionDetailUploading => 'Uploading…';

  @override
  String get adminSubmissionDetailUrgentContact => 'Emergency Contact';

  @override
  String get adminSubmissionDetailView => 'View';

  @override
  String get adminSubmissionDetailViewFile => 'View file';

  @override
  String get adminSubmissionsListAllOption => 'All';

  @override
  String get adminSubmissionsListDetailsLink => 'Details';

  @override
  String get adminSubmissionsListErrorsLoadFailed => 'Could not load list.';

  @override
  String get adminSubmissionsListFilterLabel => 'Filter by Status';

  @override
  String get adminSubmissionsListNoSubmissions => 'No applications found';

  @override
  String get adminSubmissionsListSubtitle =>
      'Review new membership applications';

  @override
  String get adminSubmissionsListTableHeadersDate => 'Date';

  @override
  String get adminSubmissionsListTableHeadersMobile => 'Mobile';

  @override
  String get adminSubmissionsListTableHeadersName => 'Name';

  @override
  String get adminSubmissionsListTableHeadersReference => 'Reference';

  @override
  String get adminSubmissionsListTableHeadersStatus => 'Status';

  @override
  String get adminSubmissionsListTitle => 'Applications';

  @override
  String get authForgotPasswordBackToLogin => 'Back to Login';

  @override
  String get authForgotPasswordErrorsRequestFailed =>
      'Could not send the reset request. Please try again.';

  @override
  String get authForgotPasswordIdentifierLabel =>
      'Member ID / Username / Email';

  @override
  String get authForgotPasswordIdentifierRequiredError =>
      'Member ID / username / email is required';

  @override
  String get authForgotPasswordSendingButton => 'Sending...';

  @override
  String get authForgotPasswordSentMessage =>
      'If an account exists for that identifier, a password reset link has been sent to its registered email address. Please check your inbox (and spam folder). The link expires in 30 minutes.';

  @override
  String get authForgotPasswordSubmitButton => 'Send Reset Link';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter your member ID, username or registered email address and we will email you a password reset link.';

  @override
  String get authForgotPasswordTitle => 'Forgot Password';

  @override
  String get authLoginBackToHome => 'Back to Home';

  @override
  String get authLoginForgotPasswordLink => 'Forgot password?';

  @override
  String get authLoginHidePassword => 'Hide password';

  @override
  String get authLoginIdentifierLabel => 'Username / Email / Member ID';

  @override
  String get authLoginIdentifierRequiredError =>
      'Username / email / member ID is required';

  @override
  String get authLoginLoggingInButton => 'Logging in...';

  @override
  String get authLoginLoginFailedError =>
      'Login failed. Information is incorrect.';

  @override
  String get authLoginLogoAlt =>
      'Uttar Kaundia Abashon Malik Kalyan Society Logo';

  @override
  String get authLoginNotAMemberYet => 'Not a member yet?';

  @override
  String get authLoginPasswordLabel => 'Password';

  @override
  String get authLoginPasswordRequiredError => 'Password is required';

  @override
  String get authLoginRegisterButton => 'Register as a New Member';

  @override
  String get authLoginShowPassword => 'Show password';

  @override
  String get authLoginSubmitButton => 'Enter';

  @override
  String get authLoginSubtitle => 'Enter as a member or administrator';

  @override
  String get authLoginTitle => 'Log In';

  @override
  String get authResetPasswordConfirmPasswordLabel => 'Confirm New Password';

  @override
  String get authResetPasswordErrorsResetFailed =>
      'Could not reset the password. Please try again.';

  @override
  String get authResetPasswordInvalidTokenError =>
      'This reset link is invalid or has expired. Please request a new one.';

  @override
  String get authResetPasswordMismatchError => 'Passwords do not match';

  @override
  String get authResetPasswordMissingTokenError =>
      'This reset link is invalid. Please request a new password reset email.';

  @override
  String get authResetPasswordNewPasswordLabel => 'New Password';

  @override
  String get authResetPasswordPasswordHint =>
      'Password must be at least 8 characters and include a number.';

  @override
  String get authResetPasswordPasswordRequiredError => 'Password is required';

  @override
  String get authResetPasswordResettingButton => 'Resetting...';

  @override
  String get authResetPasswordSubmitButton => 'Reset Password';

  @override
  String get authResetPasswordSubtitle =>
      'Choose a strong new password for your account.';

  @override
  String get authResetPasswordSuccessMessage =>
      'Your password has been reset successfully. You can now log in with your new password.';

  @override
  String get authResetPasswordTitle => 'Set a New Password';

  @override
  String get authResetPasswordWeakPasswordError =>
      'Password must be at least 8 characters and include a number.';

  @override
  String get brandName => 'Uttar Kaundia Society';

  @override
  String get brandOrg => 'Uttar Kaundia Abashon Malik Kalyan Society';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirmModalCancelButton => 'Cancel';

  @override
  String get commonConfirmModalConfirmButton => 'Confirm';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonMonthsApril => 'April';

  @override
  String get commonMonthsAugust => 'August';

  @override
  String get commonMonthsDecember => 'December';

  @override
  String get commonMonthsFebruary => 'February';

  @override
  String get commonMonthsJanuary => 'January';

  @override
  String get commonMonthsJuly => 'July';

  @override
  String get commonMonthsJune => 'June';

  @override
  String get commonMonthsMarch => 'March';

  @override
  String get commonMonthsMay => 'May';

  @override
  String get commonMonthsNovember => 'November';

  @override
  String get commonMonthsOctober => 'October';

  @override
  String get commonMonthsSeptember => 'September';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSelect => 'Select';

  @override
  String get commonSwitchToBangla => 'বাংলায় দেখুন';

  @override
  String get commonSwitchToEnglish => 'Switch to English';

  @override
  String get eventsBackToList => 'All events';

  @override
  String get eventsDetailEndsAt => 'Ends';

  @override
  String get eventsDetailLocation => 'Location';

  @override
  String get eventsDetailStartsAt => 'Starts';

  @override
  String get eventsErrorsLoadFailed => 'Could not load events.';

  @override
  String get eventsNoPast => 'No past events.';

  @override
  String get eventsNoUpcoming => 'No upcoming events.';

  @override
  String get eventsNotFound => 'This event is no longer available.';

  @override
  String get eventsPast => 'Past';

  @override
  String get eventsSubtitle =>
      'Meetings, programmes and gatherings of the council';

  @override
  String get eventsTitle => 'Events';

  @override
  String get eventsUpcoming => 'Upcoming';

  @override
  String get footerPrototypeNotice =>
      '© 2026 Uttar Kaundia Abashon Malik Kalyan Society. Developed by Anshin Tech.';

  @override
  String get footerPublicNotice =>
      'This is a member management portal. © 2026 Uttar Kaundia Abashon Malik Kalyan Society. Developed by Anshin Tech.';

  @override
  String get forbiddenBackToDashboard => 'Back to Dashboard';

  @override
  String get forbiddenMessage =>
      'You don\'t have permission to view this page.';

  @override
  String get forbiddenTitle => 'Access Denied';

  @override
  String get homeHeroApplicationReviewLabel => 'Pending Applications';

  @override
  String get homeHeroApplyButton => 'Apply for Membership';

  @override
  String get homeHeroEyebrow => 'Member Management Portal';

  @override
  String get homeHeroLoginButton => 'Already a member? Log in';

  @override
  String get homeHeroMemberIdLabel => 'Registered Members';

  @override
  String get homeHeroMonthlySubscriptionLabel => 'Monthly Subscription';

  @override
  String get homeHeroStatCardTitle => 'Right Now';

  @override
  String get homeHeroSubtitle =>
      'From membership applications to monthly subscription payments — the whole process is now online. No hassle of paper applications, no need to visit the office repeatedly.';

  @override
  String get homeHeroTitle => 'Uttar Kaundia<br />Landowners\' Welfare Council';

  @override
  String get homeStepsApplyDesc =>
      'Fill out the step-by-step form including personal information, address, land details, and payment information.';

  @override
  String get homeStepsApplyTitle => 'Apply';

  @override
  String get homeStepsMemberIdDesc =>
      'After approval, a member ID is automatically generated and login information is issued.';

  @override
  String get homeStepsMemberIdTitle => 'Member ID & Login';

  @override
  String get homeStepsReviewDesc =>
      'The executive committee and administration verify each application and approve or reject it.';

  @override
  String get homeStepsReviewTitle => 'Committee Review';

  @override
  String get idcardAddress => 'Address';

  @override
  String get idcardAuthority => 'Authority';

  @override
  String get idcardBack => 'Back';

  @override
  String get idcardBackTitle => 'Member ID Card';

  @override
  String get idcardButton => 'ID Card';

  @override
  String get idcardCardTitleEn => 'Member ID Card';

  @override
  String get idcardDob => 'Date of Birth';

  @override
  String get idcardDownload => 'Download Card (PNG)';

  @override
  String get idcardDownloadError =>
      'Could not generate the card. Please try again.';

  @override
  String get idcardEmergency => 'Emergency';

  @override
  String get idcardFather => 'Father/Husband';

  @override
  String get idcardFooter => 'Member ID Card · 2026';

  @override
  String get idcardFront => 'Front';

  @override
  String get idcardIssuedOn => 'Issued on';

  @override
  String get idcardLoadError => 'Could not load profile data.';

  @override
  String get idcardMobile => 'Mobile';

  @override
  String get idcardNid => 'NID';

  @override
  String get idcardPreparing => 'Preparing...';

  @override
  String get idcardReceiptNo => 'Receipt No.';

  @override
  String get idcardSectionContact => 'Contact';

  @override
  String get idcardSectionMembership => 'Membership';

  @override
  String get idcardSectionPersonal => 'Personal';

  @override
  String get idcardSocietyName => 'Uttar Kaundia Society';

  @override
  String get idcardSocietyOrg => 'Uttar Kaundia Abashon Malik Kalyan Society';

  @override
  String get idcardStatusApplicant => 'Applicant';

  @override
  String get idcardStatusApproved => 'Member';

  @override
  String get idcardStatusPending => 'Pending';

  @override
  String get idcardStatusRejected => 'Rejected';

  @override
  String get idcardTerms =>
      'This card is the property of Uttar Kaundia Abashon Malik Kalyan Society. It must be shown on request and returned upon termination of membership. Report loss to the authority immediately.';

  @override
  String get idcardTitle => 'Member ID Card';

  @override
  String get idcardVerify => 'Verifiable via QR code';

  @override
  String get memberChangePasswordChangeFailedError =>
      'Failed to change password.';

  @override
  String get memberChangePasswordConfirmPasswordLabel => 'Confirm New Password';

  @override
  String get memberChangePasswordCurrentPasswordLabel => 'Current Password';

  @override
  String get memberChangePasswordCurrentPasswordRequiredError =>
      'Current password is required.';

  @override
  String get memberChangePasswordNewPasswordLabel => 'New Password';

  @override
  String get memberChangePasswordPasswordMismatchError =>
      'Passwords do not match.';

  @override
  String get memberChangePasswordPasswordPolicyError =>
      'Password must be at least 8 characters and include a number.';

  @override
  String get memberChangePasswordSameAsCurrentError =>
      'New password must be different from the current password.';

  @override
  String get memberChangePasswordSaveButton => 'Save Change';

  @override
  String get memberChangePasswordSavingButton => 'Saving...';

  @override
  String get memberChangePasswordSuccessMessage =>
      'Password changed successfully.';

  @override
  String get memberChangePasswordTitle => 'Change password';

  @override
  String get memberCostSharesEmptyHint =>
      'Costs split among members will appear here.';

  @override
  String get memberCostSharesEmptyState => 'You have no outstanding dues';

  @override
  String get memberCostSharesLoadError =>
      'Could not load your cost shares. Please try again.';

  @override
  String get memberCostSharesStatusPaid => 'Paid';

  @override
  String get memberCostSharesStatusPartial => 'Partial';

  @override
  String get memberCostSharesStatusUnpaid => 'Unpaid';

  @override
  String get memberCostSharesSubtitle =>
      'Costs the society split to your account';

  @override
  String get memberCostSharesTableCost => 'Cost';

  @override
  String get memberCostSharesTableDate => 'Date';

  @override
  String get memberCostSharesTableDue => 'Due';

  @override
  String get memberCostSharesTablePaid => 'Paid';

  @override
  String get memberCostSharesTableStatus => 'Status';

  @override
  String get memberCostSharesTitle => 'Cost Shares';

  @override
  String get memberCostSharesTotalOutstanding => 'Total outstanding';

  @override
  String get memberDashboardDueMonthsLabel => 'Due Months';

  @override
  String get memberDashboardLoadError => 'Failed to load data.';

  @override
  String get memberDashboardMemberIdLabel => 'Member ID';

  @override
  String get memberDashboardPaidMonthsLabel => 'Paid Months';

  @override
  String get memberDashboardRecentStatusTitle => 'Recent Subscription Status';

  @override
  String get memberDashboardStatusDue => 'Due';

  @override
  String get memberDashboardStatusPaid => 'Paid';

  @override
  String get memberFundTransparencyChartsEmpty =>
      'Not enough data for a chart yet.';

  @override
  String get memberFundTransparencyChartsExpenseDonut => 'Expenses by category';

  @override
  String get memberFundTransparencyChartsMonthly => 'Monthly';

  @override
  String get memberFundTransparencyChartsTrend => 'Income vs expense trend';

  @override
  String get memberFundTransparencyChartsYearly => 'Yearly';

  @override
  String get memberFundTransparencyCurrentBalance => 'Current Balance';

  @override
  String get memberFundTransparencyDownloadPdf => 'Download report (PDF)';

  @override
  String get memberFundTransparencyEmptyHint =>
      'Once the committee records and approves transactions, all income and expenses will appear here.';

  @override
  String get memberFundTransparencyEmptyTitle =>
      'No transactions published yet';

  @override
  String get memberFundTransparencyErrorsCustomRange =>
      'Pick both start and end dates (start first).';

  @override
  String get memberFundTransparencyErrorsLoadFailed =>
      'Could not load the data. Please retry.';

  @override
  String get memberFundTransparencyErrorsPdfFailed =>
      'Could not generate the report. Try again shortly.';

  @override
  String get memberFundTransparencyExpenseBreakdown => 'Expenses by category';

  @override
  String get memberFundTransparencyExpenseBreakdownEmpty =>
      'No expenses in this period.';

  @override
  String get memberFundTransparencyFiltersAllCategories => 'All categories';

  @override
  String get memberFundTransparencyFiltersAllTypes => 'All types';

  @override
  String get memberFundTransparencyFiltersAmountRange => 'Amount range (৳)';

  @override
  String get memberFundTransparencyFiltersApprovedBy => 'Approved by';

  @override
  String get memberFundTransparencyFiltersCategory => 'Category';

  @override
  String get memberFundTransparencyFiltersClearAll => '✕ Clear all';

  @override
  String get memberFundTransparencyFiltersDateRange => 'Date range';

  @override
  String get memberFundTransparencyFiltersMax => 'Max';

  @override
  String get memberFundTransparencyFiltersMin => 'Min';

  @override
  String get memberFundTransparencyFiltersReference => 'Reference no.';

  @override
  String get memberFundTransparencyFiltersReset => 'Reset';

  @override
  String get memberFundTransparencyFiltersSearch => 'Search';

  @override
  String get memberFundTransparencyFiltersSearchPlaceholder =>
      'Search description or reference…';

  @override
  String get memberFundTransparencyFiltersType => 'Type';

  @override
  String memberFundTransparencyFlagsSpike(Object category, Object pct) {
    return '$category spending is $pct higher than the previous period';
  }

  @override
  String memberFundTransparencyFlagsTopCategories(Object categories) {
    return 'Biggest expenses: $categories';
  }

  @override
  String get memberFundTransparencyIncomeBreakdown => 'Collections by category';

  @override
  String get memberFundTransparencyIncomeBreakdownEmpty =>
      'No income in this period.';

  @override
  String get memberFundTransparencyLastUpdated => 'Last updated';

  @override
  String get memberFundTransparencyLedgerAmount => 'Amount';

  @override
  String get memberFundTransparencyLedgerApprovedBy => 'Approved by';

  @override
  String get memberFundTransparencyLedgerCategory => 'Category';

  @override
  String memberFundTransparencyLedgerCount(Object count) {
    return '$count transactions';
  }

  @override
  String get memberFundTransparencyLedgerDate => 'Date';

  @override
  String get memberFundTransparencyLedgerDescription => 'Description';

  @override
  String get memberFundTransparencyLedgerEmpty => 'No transactions found';

  @override
  String get memberFundTransparencyLedgerEmptyHint =>
      'Try changing the filters.';

  @override
  String memberFundTransparencyLedgerPage(Object page, Object total) {
    return 'Page $page of $total';
  }

  @override
  String get memberFundTransparencyLedgerReference => 'Reference';

  @override
  String get memberFundTransparencyLedgerReversalOf =>
      'Reversal of transaction';

  @override
  String get memberFundTransparencyLedgerType => 'Type';

  @override
  String get memberFundTransparencyLedgerViewAttachment => 'View attachment';

  @override
  String get memberFundTransparencyNetSaved => 'Net Saved';

  @override
  String get memberFundTransparencyPeriodAll => 'All time';

  @override
  String get memberFundTransparencyPeriodApply => 'Apply';

  @override
  String get memberFundTransparencyPeriodCustom => 'Custom range';

  @override
  String get memberFundTransparencyPeriodMonth => 'This month';

  @override
  String get memberFundTransparencyPeriodYear => 'This year';

  @override
  String get memberFundTransparencyPreviewMissing =>
      'The attachment is missing. Please notify the committee.';

  @override
  String get memberFundTransparencyPreviewTitle => 'Attachment preview';

  @override
  String get memberFundTransparencySubtitle =>
      'Every taka in and out of the society fund — open to every member';

  @override
  String memberFundTransparencySummaryLine(
      Object expense, Object income, Object net) {
    return 'This period: income $income, expense $expense, net $net.';
  }

  @override
  String get memberFundTransparencyTitle => 'Fund Transparency';

  @override
  String get memberFundTransparencyTopTag => 'Top';

  @override
  String get memberFundTransparencyTotalExpense => 'Total Expense';

  @override
  String get memberFundTransparencyTotalIncome => 'Total Income';

  @override
  String get memberFundTransparencyTypeExpense => 'Expense';

  @override
  String get memberFundTransparencyTypeIncome => 'Income';

  @override
  String get memberInstallmentsAmountColumn => 'Amount';

  @override
  String get memberInstallmentsEmptyFiltered =>
      'No payments found for this year.';

  @override
  String get memberInstallmentsEmptyState => 'No installments found';

  @override
  String get memberInstallmentsFilterAll => 'All Years';

  @override
  String get memberInstallmentsLoadError => 'Failed to load installment list.';

  @override
  String get memberInstallmentsMonthColumn => 'Month';

  @override
  String get memberInstallmentsPaidAtColumn => 'Paid On';

  @override
  String get memberInstallmentsPaymentNotice =>
      'Subscription payments are made directly at the office (cash/bKash/bank); the administration updates it here.';

  @override
  String get memberInstallmentsStatusColumn => 'Status';

  @override
  String get memberInstallmentsStatusDue => 'Due';

  @override
  String get memberInstallmentsStatusPaid => 'Paid';

  @override
  String get memberInstallmentsSubtitle =>
      'Your monthly subscription payments at a glance.';

  @override
  String get memberInstallmentsSummaryDue => 'Outstanding';

  @override
  String get memberInstallmentsSummaryPaid => 'Total Paid';

  @override
  String get memberInstallmentsSummaryPayments => 'Payments Made';

  @override
  String get memberInstallmentsTitle => 'Subscription History';

  @override
  String get memberPayDuesAmount => 'Amount';

  @override
  String get memberPayDuesBack => 'Back';

  @override
  String memberPayDuesBannerTitle(Object count) {
    return 'You have $count month(s) outstanding';
  }

  @override
  String get memberPayDuesClearAll => 'Clear all';

  @override
  String get memberPayDuesClose => 'Close';

  @override
  String get memberPayDuesContinue => 'Continue';

  @override
  String get memberPayDuesCopied => 'Copied';

  @override
  String get memberPayDuesCopy => 'Copy';

  @override
  String get memberPayDuesHistoryTitle => 'Recent online payments';

  @override
  String get memberPayDuesIHavePaid => 'I\'ve paid';

  @override
  String get memberPayDuesKeepReceipt =>
      'Keep the transaction ID from your SMS/receipt — you will need it next.';

  @override
  String get memberPayDuesMethodHint =>
      'Choose how you will pay, then send the exact amount to this account.';

  @override
  String get memberPayDuesMonths => 'month(s)';

  @override
  String get memberPayDuesNote => 'Note (optional)';

  @override
  String get memberPayDuesNotice =>
      'Pay online with “Pay dues”. Each payment is verified by the committee before it is marked paid.';

  @override
  String get memberPayDuesOldest => 'Oldest';

  @override
  String get memberPayDuesPaidOn => 'Payment date';

  @override
  String get memberPayDuesPayNow => 'Pay dues';

  @override
  String get memberPayDuesPaymentStatusApproved => 'Verified';

  @override
  String get memberPayDuesPaymentStatusPending => 'Pending verification';

  @override
  String get memberPayDuesPaymentStatusRejected => 'Rejected';

  @override
  String get memberPayDuesProof => 'Receipt / screenshot (optional)';

  @override
  String get memberPayDuesProofHint => 'JPG, PNG or PDF, up to 5 MB.';

  @override
  String get memberPayDuesProofSizeError => 'File must be 5 MB or smaller.';

  @override
  String get memberPayDuesProofTypeError =>
      'Only JPG, PNG or PDF files are allowed.';

  @override
  String get memberPayDuesRejectedReason => 'Reason';

  @override
  String get memberPayDuesSelectAll => 'Select all';

  @override
  String get memberPayDuesSelectHint =>
      'Oldest dues are pre-selected. Untick any month you are not paying now.';

  @override
  String get memberPayDuesSendTo => 'Send to';

  @override
  String get memberPayDuesSenderAccount => 'Paid from (your number / account)';

  @override
  String get memberPayDuesStatusPending => 'Verifying';

  @override
  String get memberPayDuesStep1 => 'Select months';

  @override
  String get memberPayDuesStep2 => 'Send payment';

  @override
  String get memberPayDuesStep3 => 'Confirm';

  @override
  String get memberPayDuesSubmit => 'Submit for verification';

  @override
  String get memberPayDuesSubmitError =>
      'Could not submit the payment. Please try again.';

  @override
  String get memberPayDuesSubmitted =>
      'Payment submitted! The committee will verify it shortly and you will be notified by email.';

  @override
  String get memberPayDuesSubmitting => 'Submitting...';

  @override
  String get memberPayDuesTitle => 'Pay monthly dues';

  @override
  String memberPayDuesTotalLabel(Object count) {
    return 'Total for $count month(s)';
  }

  @override
  String get memberPayDuesTransactionRef => 'Transaction ID';

  @override
  String get memberPayDuesTransactionRefError =>
      'Enter a valid transaction ID (4–64 letters/numbers).';

  @override
  String get memberPayDuesTransactionRefPlaceholder => 'e.g. 9KX7AB12CD';

  @override
  String get memberPicnicAccessDenied =>
      'You do not have access to picnic payments.';

  @override
  String get memberPicnicAdditionalHeads => 'Additional heads';

  @override
  String memberPicnicAdditionalHeadsHint(Object max) {
    return '0 to $max (spouse, children, guests)';
  }

  @override
  String get memberPicnicAdditionalHeadsLabel => 'Additional Heads';

  @override
  String get memberPicnicDateColumn => 'Date';

  @override
  String get memberPicnicDateLabel => 'Payment Date';

  @override
  String get memberPicnicEmptyState => 'No picnic payments yet.';

  @override
  String get memberPicnicFeeLoadFailed =>
      'Picnic fee rates could not be loaded.';

  @override
  String memberPicnicHeadNameLabel(Object n) {
    return 'Head $n Name';
  }

  @override
  String memberPicnicHeadRelationLabel(Object n) {
    return 'Head $n Relation';
  }

  @override
  String get memberPicnicHeadsColumn => 'Additional Heads';

  @override
  String get memberPicnicHistoryLoadFailed => 'Could not load payment history.';

  @override
  String get memberPicnicHistoryTitle => 'Payment History';

  @override
  String get memberPicnicLoadError => 'Could not load payment history.';

  @override
  String get memberPicnicMemberHead => 'Member head';

  @override
  String get memberPicnicMethodColumn => 'Method';

  @override
  String get memberPicnicMethodLabel => 'Payment Method';

  @override
  String get memberPicnicMethodsBankTransfer => 'Bank Transfer';

  @override
  String get memberPicnicMethodsCash => 'Cash';

  @override
  String get memberPicnicMethodsNagad => 'Nagad';

  @override
  String get memberPicnicMethodsOther => 'Other';

  @override
  String get memberPicnicMethodsBKash => 'bKash';

  @override
  String get memberPicnicNotConfigured =>
      'Picnic fee has not been set up yet. Please contact the committee.';

  @override
  String get memberPicnicReceiptColumn => 'Receipt No';

  @override
  String get memberPicnicReceiptNoLabel => 'Receipt No';

  @override
  String get memberPicnicRelationsChild => 'Child';

  @override
  String get memberPicnicRelationsGuest => 'Guest';

  @override
  String get memberPicnicRelationsSpouse => 'Spouse';

  @override
  String get memberPicnicRetry => 'Retry';

  @override
  String get memberPicnicSaveError => 'Could not record the payment.';

  @override
  String memberPicnicSaveSuccess(Object total) {
    return 'Payment recorded. Total: ৳ $total';
  }

  @override
  String get memberPicnicSaving => 'Saving…';

  @override
  String get memberPicnicSubmit => 'Confirm Payment';

  @override
  String get memberPicnicSubtitle =>
      'Pay for your own seat plus seats for spouse, children or guests';

  @override
  String get memberPicnicTaka => 'Taka';

  @override
  String get memberPicnicTitle => 'Picnic Fee Payment';

  @override
  String get memberPicnicTotal => 'Total';

  @override
  String get memberPicnicTotalColumn => 'Total';

  @override
  String get memberProfileAddressLabel => 'Address';

  @override
  String get memberProfileAddressTitle => 'Address';

  @override
  String get memberProfileAdmissionFeeLabel => 'Admission Fee';

  @override
  String get memberProfileCancelButton => 'Cancel';

  @override
  String get memberProfileChangePhotoButton => 'Change Photo';

  @override
  String get memberProfileCoOwnerLabel => 'Co-owner';

  @override
  String get memberProfileContactTitle => 'Contact';

  @override
  String get memberProfileCurrentAddressLabel => 'Current';

  @override
  String get memberProfileDagNoCsLabel => 'Dag No (CS)';

  @override
  String get memberProfileDagNoRsLabel => 'Dag No (RS)';

  @override
  String get memberProfileDecimalUnit => 'decimal';

  @override
  String get memberProfileDistrictLabel => 'District';

  @override
  String get memberProfileDivisionLabel => 'Division';

  @override
  String get memberProfileDobLabel => 'Date of Birth';

  @override
  String get memberProfileDocumentLabel => 'Document';

  @override
  String get memberProfileDownload => 'Download';

  @override
  String get memberProfileDownloadFailed =>
      'Download failed. Please try again.';

  @override
  String get memberProfileEditButton => 'Edit Profile';

  @override
  String get memberProfileEditTitle => 'Edit Profile';

  @override
  String get memberProfileEmailLabel => 'Email';

  @override
  String get memberProfileFatherOrHusbandLabel => 'Father/Husband';

  @override
  String get memberProfileFileMissing =>
      'The file is missing on the server. Please upload it again.';

  @override
  String get memberProfileGenderLabel => 'Gender';

  @override
  String get memberProfileHoldingNumberLabel => 'Holding Number';

  @override
  String get memberProfileHouseLabel => 'House';

  @override
  String get memberProfileKhatianLabel => 'Khatian';

  @override
  String get memberProfileLandQuantityLabel => 'Land Quantity';

  @override
  String get memberProfileLoadError => 'Failed to load profile.';

  @override
  String get memberProfileMemberIdLabel => 'Member ID';

  @override
  String get memberProfileMobileLabel => 'Mobile';

  @override
  String get memberProfileMotherLabel => 'Mother';

  @override
  String get memberProfileMyShareQuantityLabel => 'My Share';

  @override
  String get memberProfileNameLabel => 'Name';

  @override
  String get memberProfileNationalityLabel => 'Nationality';

  @override
  String get memberProfileNidLabel => 'NID';

  @override
  String get memberProfileNoNominees => 'No nominees provided.';

  @override
  String get memberProfileNoPropertyInfo => 'No property information provided.';

  @override
  String get memberProfileNomineesTitle => 'Nominees';

  @override
  String get memberProfileOccupationLabel => 'Occupation';

  @override
  String get memberProfileOwnershipLabel => 'Ownership';

  @override
  String get memberProfilePaymentMethodLabel => 'Payment Method';

  @override
  String get memberProfilePaymentTitle => 'Registration Payment';

  @override
  String get memberProfilePendingReviewNotice =>
      'Your membership is currently under review due to a recent profile update. Approved status will resume once reviewed.';

  @override
  String get memberProfilePermanentAddressLabel => 'Permanent';

  @override
  String get memberProfilePersonalInfoTitle => 'Personal Information';

  @override
  String get memberProfilePhotoLabel => 'Member photo';

  @override
  String get memberProfilePhotoSizeError => 'Photo size must be less than 3 MB';

  @override
  String get memberProfilePhotoTypeError =>
      'Please select an image file (JPG/PNG)';

  @override
  String get memberProfilePhotoUploadError =>
      'Failed to upload the photo. Please try again.';

  @override
  String get memberProfilePostOfficeLabel => 'Post Office';

  @override
  String get memberProfilePropertyItemLabel => 'Property';

  @override
  String get memberProfilePropertyTitle => 'Property';

  @override
  String get memberProfileReceiptNoLabel => 'Receipt No';

  @override
  String get memberProfileReceiptPhotoLabel => 'Payment Receipt';

  @override
  String get memberProfileRelationLabel => 'Relation';

  @override
  String get memberProfileRemovePhotoButton => 'Remove';

  @override
  String get memberProfileRequeueWarning =>
      'Changing this information will send your membership back for review by the management committee.';

  @override
  String get memberProfileRoadLabel => 'Road';

  @override
  String get memberProfileSameAsPermanentAddress => 'Same as permanent address';

  @override
  String get memberProfileSaveButton => 'Save Changes';

  @override
  String get memberProfileSaveError => 'Failed to save profile changes.';

  @override
  String get memberProfileSignatureLabel => 'Signature';

  @override
  String get memberProfileStatusApproved => 'Approved';

  @override
  String get memberProfileStatusPending => 'Under Review';

  @override
  String get memberProfileStatusRejected => 'Rejected';

  @override
  String get memberProfileSubmissionDateLabel => 'Registration Date';

  @override
  String get memberProfileSubscriptionLabel => 'Subscription';

  @override
  String get memberProfileTitle => 'Profile';

  @override
  String get memberProfileUpazilaLabel => 'Upazila';

  @override
  String get memberProfileUrgentContactTitle => 'Urgent Contact';

  @override
  String get memberProfileViewFile => 'View file';

  @override
  String get memberProfileVillageLabel => 'Village';

  @override
  String get memberPropertyRequestsActionsAdd => 'Add';

  @override
  String get memberPropertyRequestsActionsDelete => 'Delete';

  @override
  String get memberPropertyRequestsActionsEdit => 'Edit';

  @override
  String get memberPropertyRequestsAddButton => 'Add property';

  @override
  String get memberPropertyRequestsAddCoOwnerButton => 'Add co-owner';

  @override
  String get memberPropertyRequestsAddDocButton => 'Add document';

  @override
  String get memberPropertyRequestsAddTitle => 'Request property addition';

  @override
  String get memberPropertyRequestsBackButton => 'Back';

  @override
  String get memberPropertyRequestsCancelReasonLabel => 'Cancel reason';

  @override
  String get memberPropertyRequestsCoOwnerNamePlaceholder => 'Co-owner name';

  @override
  String get memberPropertyRequestsCoOwnerNameRequired =>
      'Each co-owner needs a name.';

  @override
  String get memberPropertyRequestsCoOwnersLabel => 'Co-owners';

  @override
  String get memberPropertyRequestsDeleteModalConfirmLabel =>
      'Send removal request';

  @override
  String get memberPropertyRequestsDeleteModalMessage =>
      'An admin will review your request to remove this property before it is deleted.';

  @override
  String get memberPropertyRequestsDeleteModalTitle =>
      'Request property removal';

  @override
  String get memberPropertyRequestsDocDropped => 'Removed';

  @override
  String get memberPropertyRequestsDocIncomplete =>
      'Select a document type and attach a file.';

  @override
  String get memberPropertyRequestsDocKept => 'Kept';

  @override
  String get memberPropertyRequestsDocsLabel => 'Documents';

  @override
  String get memberPropertyRequestsDocumentsSectionTitle => 'Documents';

  @override
  String get memberPropertyRequestsEditTitle => 'Request property edit';

  @override
  String get memberPropertyRequestsErrorsLoadFailed =>
      'Could not load property requests.';

  @override
  String get memberPropertyRequestsErrorsPropertyNotFound =>
      'The requested property was not found.';

  @override
  String get memberPropertyRequestsErrorsSubmitFailed =>
      'Could not send the request. Please try again.';

  @override
  String get memberPropertyRequestsErrorsWithdrawFailed =>
      'Could not withdraw the request.';

  @override
  String get memberPropertyRequestsExistingDocsLabel => 'Existing documents';

  @override
  String get memberPropertyRequestsFormSubtitle =>
      'Submit your change for admin review.';

  @override
  String get memberPropertyRequestsListTitle => 'Property requests';

  @override
  String get memberPropertyRequestsNewDocsLabel => 'Add new documents';

  @override
  String get memberPropertyRequestsNoExistingDocs =>
      'This property has no existing documents.';

  @override
  String get memberPropertyRequestsNoRequests => 'No property requests yet.';

  @override
  String get memberPropertyRequestsPendingPill => 'Request pending';

  @override
  String get memberPropertyRequestsPropertySectionTitle => 'Property details';

  @override
  String get memberPropertyRequestsStatusLabelsApproved => 'Approved';

  @override
  String get memberPropertyRequestsStatusLabelsCancelled => 'Cancelled';

  @override
  String get memberPropertyRequestsStatusLabelsPending => 'Pending';

  @override
  String get memberPropertyRequestsSubmitButton => 'Send request';

  @override
  String get memberPropertyRequestsSubmittedLabel => 'Submitted';

  @override
  String get memberPropertyRequestsSuccessSent =>
      'Your request has been sent for review.';

  @override
  String get memberPropertyRequestsWithdrawButton => 'Withdraw';

  @override
  String get memberPropertyRequestsWithdrawModalConfirmLabel =>
      'Withdraw request';

  @override
  String get memberPropertyRequestsWithdrawModalMessage =>
      'Your pending request will be cancelled. This cannot be undone.';

  @override
  String get memberPropertyRequestsWithdrawModalTitle => 'Withdraw request';

  @override
  String get memberPropertyRequestsWithdrawnSuccess =>
      'The request has been withdrawn.';

  @override
  String get memberRoadmapActionsImage => 'Image for sharing';

  @override
  String get memberRoadmapActionsPdf => 'A4 print / PDF';

  @override
  String get memberRoadmapActionsSlides => 'View as slides';

  @override
  String memberRoadmapCompletedOn(Object date) {
    return 'Completed $date';
  }

  @override
  String get memberRoadmapEmpty =>
      'No plans have been added to this timeframe yet.';

  @override
  String get memberRoadmapEmptyFiltered => 'No items match this filter.';

  @override
  String get memberRoadmapExportError =>
      'Could not prepare the download. Please try again.';

  @override
  String get memberRoadmapFilterAll => 'All';

  @override
  String get memberRoadmapFilterDone => 'Done';

  @override
  String get memberRoadmapFilterInProgress => 'In progress';

  @override
  String get memberRoadmapFilterPlanned => 'Planned';

  @override
  String get memberRoadmapFilterAria => 'Filter by status';

  @override
  String get memberRoadmapFocusNow => 'Current focus';

  @override
  String memberRoadmapItemCount(Object n) {
    return '$n items';
  }

  @override
  String memberRoadmapLastUpdated(Object date) {
    return 'Last updated: $date';
  }

  @override
  String get memberRoadmapLoadError =>
      'Could not load the roadmap. Please try again.';

  @override
  String memberRoadmapOverallAria(Object pct) {
    return 'Overall progress $pct percent';
  }

  @override
  String get memberRoadmapOverallProgress => 'Overall progress';

  @override
  String memberRoadmapProgressLabel(
      Object done, Object name, Object pct, Object total) {
    return '$name: $done/$total done — $pct%';
  }

  @override
  String memberRoadmapProgressShort(Object done, Object pct, Object total) {
    return '$done/$total done — $pct%';
  }

  @override
  String get memberRoadmapSlidesHint =>
      'Use ← → keys or swipe to move · Esc to close';

  @override
  String get memberRoadmapSlidesNext => 'Next slide';

  @override
  String get memberRoadmapSlidesPrev => 'Previous slide';

  @override
  String get memberRoadmapStatusDone => 'Done';

  @override
  String get memberRoadmapStatusInProgress => 'In progress';

  @override
  String get memberRoadmapStatusPlanned => 'Planned';

  @override
  String get memberRoadmapStepperAria => 'Roadmap timeline';

  @override
  String get memberRoadmapSubtitle =>
      'Where we are, where we are going, and how we get there.';

  @override
  String memberRoadmapTarget(Object date) {
    return 'Target: $date';
  }

  @override
  String get memberRoadmapTitle => 'Our Roadmap';

  @override
  String get memberRoadmapWeAreHere => 'We are here';

  @override
  String memberRoadmapWhereSummary(Object done, Object total) {
    return '$done of $total planned items are done.';
  }

  @override
  String get memberRoadmapWhereTitle => 'Where we are now';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navAuditLog => 'Audit Log';

  @override
  String get navChangePassword => 'Change Password';

  @override
  String get navChangeTheme => 'Change theme';

  @override
  String get navCloseMenu => 'Close menu';

  @override
  String get navConfigLists => 'Config Lists';

  @override
  String get navCostShares => 'Cost Shares';

  @override
  String get navDarkTheme => 'Dark theme';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navEvents => 'Events';

  @override
  String get navEventsManagement => 'Manage Events';

  @override
  String get navFeeSettings => 'Fee Settings';

  @override
  String get navFinanceManagement => 'Finance Management';

  @override
  String get navFundTransparency => 'Fund Transparency';

  @override
  String get navInstallments => 'Installments';

  @override
  String get navInstallmentsManagement => 'Installments Management';

  @override
  String get navLightTheme => 'Light theme';

  @override
  String get navLogin => 'Login';

  @override
  String get navLogout => 'Logout';

  @override
  String get navMembersList => 'Members List';

  @override
  String get navMoreOptions => 'More options';

  @override
  String get navNotices => 'Notices';

  @override
  String get navNoticesManagement => 'Manage Notices';

  @override
  String get navOpenMenu => 'Open menu';

  @override
  String get navPaymentVerifications => 'Payment Verifications';

  @override
  String get navPicnicPayment => 'Picnic Fee';

  @override
  String get navPicnicPayments => 'Picnic Payments';

  @override
  String get navProfile => 'Profile';

  @override
  String get navPropertyRequests => 'Property Requests';

  @override
  String get navRegister => 'Register';

  @override
  String get navResolutionBook => 'Resolution Book';

  @override
  String get navRoadmap => 'Our Roadmap';

  @override
  String get navRoadmapManagement => 'Roadmap Management';

  @override
  String get navRolesPermissions => 'Roles & Permissions';

  @override
  String get navSocietyCosts => 'Society Costs';

  @override
  String get navSubmissions => 'Submissions';

  @override
  String get noticesBackToList => 'All notices';

  @override
  String get noticesEmpty => 'No notices have been published yet.';

  @override
  String get noticesErrorsLoadFailed => 'Could not load notices.';

  @override
  String get noticesNotFound => 'This notice is no longer available.';

  @override
  String get noticesSubtitle =>
      'Announcements from the Uttar Kaundia Abashon Malik Kalyan Society';

  @override
  String get noticesTitle => 'Notices';

  @override
  String get passwordfieldHide => 'Hide password';

  @override
  String get passwordfieldShow => 'Show password';

  @override
  String get rbActionsAddMeeting => 'New Meeting';

  @override
  String get rbActionsEdit => 'Edit';

  @override
  String get rbActionsPdf => 'Download PDF';

  @override
  String get rbAttendanceAbsent => 'Absent';

  @override
  String get rbAttendancePresent => 'Present';

  @override
  String get rbDetailAgenda => 'Agenda';

  @override
  String get rbDetailAttendanceTitle => 'Attendance';

  @override
  String get rbDetailBack => 'Resolution Book';

  @override
  String get rbDetailChair => 'Chair';

  @override
  String rbDetailCreatedBy(Object name) {
    return 'Recorded by $name';
  }

  @override
  String rbDetailLastUpdated(Object date) {
    return 'last updated $date';
  }

  @override
  String get rbDetailNextMeeting => 'Next meeting';

  @override
  String get rbDetailNoAttendance => 'Attendance has not been recorded.';

  @override
  String get rbDetailNoResolutions => 'No resolutions recorded.';

  @override
  String get rbDetailNoSummary => 'No summary recorded.';

  @override
  String get rbDetailNotSet => 'Not set';

  @override
  String rbDetailResolutionNo(Object no) {
    return 'Resolution-$no';
  }

  @override
  String get rbDetailResolutionStatus => 'Resolution status';

  @override
  String get rbDetailStatus => 'Status';

  @override
  String get rbDetailSummary => 'Summary of discussion';

  @override
  String rbDetailVotesAria(Object against, Object for_val, Object neutral) {
    return 'For $for_val, against $against, neutral $neutral';
  }

  @override
  String get rbExportError => 'Could not generate the PDF. Please try again.';

  @override
  String get rbFiltersAllStatuses => 'All statuses';

  @override
  String get rbFiltersAllTypes => 'All types';

  @override
  String get rbFiltersApply => 'Search';

  @override
  String get rbFiltersClear => 'Clear';

  @override
  String get rbFiltersDateFrom => 'Date from';

  @override
  String get rbFiltersDateTo => 'Date to';

  @override
  String get rbFiltersSearch => 'Search';

  @override
  String get rbFiltersSearchPlaceholder =>
      'Search by meeting no, subject or chairperson…';

  @override
  String get rbFiltersStatus => 'Status';

  @override
  String get rbFiltersType => 'Meeting type';

  @override
  String get rbFormAddResolution => 'Add resolution';

  @override
  String get rbFormAgenda => 'Agenda';

  @override
  String get rbFormAgendaSummary => 'Agenda & summary';

  @override
  String get rbFormAssignee => 'Assigned to (optional)';

  @override
  String get rbFormAssigneePlaceholder => 'No one';

  @override
  String get rbFormAttachments => 'Recordings & attachments (optional)';

  @override
  String get rbFormAttendance => 'Attendance';

  @override
  String get rbFormAttendancePlaceholder => 'Select members…';

  @override
  String get rbFormAutoNo => 'auto-suggested';

  @override
  String get rbFormChairperson => 'Chairperson';

  @override
  String get rbFormChairpersonPlaceholder => 'Select a member…';

  @override
  String get rbFormDate => 'Date';

  @override
  String get rbFormDecision => 'Decision';

  @override
  String get rbFormDropzone =>
      'Tap to add files — video, audio, photo or chat log';

  @override
  String get rbFormDropzoneHint => 'Maximum 100 MB per file';

  @override
  String get rbFormDueDate => 'Due date (optional)';

  @override
  String get rbFormDuplicateNo =>
      'This meeting number is already in use. Please choose another.';

  @override
  String get rbFormEditTitle => 'Edit Meeting';

  @override
  String get rbFormFileTooLarge => 'A file exceeds the 100 MB limit.';

  @override
  String get rbFormMarkAllPresent => 'Mark all present';

  @override
  String get rbFormMeetingInfo => 'Meeting information';

  @override
  String get rbFormMeetingNo => 'Meeting no';

  @override
  String get rbFormNextMeeting => 'Next meeting date (optional)';

  @override
  String get rbFormNotify => 'Publish a notice for members';

  @override
  String rbFormPresentCount(Object present, Object total) {
    return '$present/$total present';
  }

  @override
  String get rbFormRemoveFile => 'Remove';

  @override
  String get rbFormRemoveResolution => 'Remove';

  @override
  String get rbFormResolutions => 'Resolutions';

  @override
  String get rbFormSave => 'Save changes';

  @override
  String get rbFormStatus => 'Status';

  @override
  String get rbFormSubmit => 'Save meeting record';

  @override
  String get rbFormSubmitError =>
      'Could not save the meeting. Please try again.';

  @override
  String get rbFormSubtitle =>
      'Meeting, attendance and resolutions are saved together in one submission.';

  @override
  String get rbFormSummary => 'Summary of discussion';

  @override
  String get rbFormTask => 'Task (optional)';

  @override
  String get rbFormTime => 'Time';

  @override
  String get rbFormTitle => 'New Meeting Record';

  @override
  String get rbFormType => 'Meeting type';

  @override
  String get rbFormVotesExceed =>
      'Total votes cannot exceed the number of members present.';

  @override
  String rbFormVotesExceedInline(Object present) {
    return 'Total votes of a resolution cannot exceed members present ($present).';
  }

  @override
  String rbListAttendance(Object present, Object total) {
    return '$present/$total present';
  }

  @override
  String get rbListEmpty => 'No meeting records yet.';

  @override
  String get rbListEmptyFiltered => 'No meetings matched your search.';

  @override
  String rbListResolutions(Object count) {
    return '$count resolutions';
  }

  @override
  String get rbListTitle => 'Recent meetings';

  @override
  String get rbLoadError => 'Could not load data. Please try again.';

  @override
  String get rbNavNext => 'Next';

  @override
  String get rbNavPrevious => 'Previous';

  @override
  String get rbRecordingsDownload => 'Download';

  @override
  String get rbRecordingsDownloadError => 'Download failed.';

  @override
  String get rbRecordingsEmpty => 'No recordings or attachments yet.';

  @override
  String get rbRecordingsTitle => 'Recordings & attachments';

  @override
  String get rbRecordingsUpload => 'Upload file';

  @override
  String get rbRecordingsUploadError =>
      'Upload failed. Check the file type and size.';

  @override
  String get rbResolutionDone => 'Done';

  @override
  String get rbResolutionInProgress => 'In Progress';

  @override
  String get rbResolutionPending => 'Pending';

  @override
  String get rbStatusCancelled => 'Cancelled';

  @override
  String get rbStatusCompleted => 'Completed';

  @override
  String get rbStatusScheduled => 'Scheduled';

  @override
  String get rbSubtitle =>
      'Meeting records, decisions and attendance — all in one place';

  @override
  String get rbSummaryAvgAttendance => 'Average attendance';

  @override
  String get rbSummaryOpenActions => 'Pending action items';

  @override
  String get rbSummaryThisYear => 'Meetings this year';

  @override
  String get rbSummaryTitle => 'Summary';

  @override
  String get rbSummaryTotalMeetings => 'Total meetings';

  @override
  String get rbTabsAttendance => 'Attendance';

  @override
  String get rbTabsOverview => 'Overview';

  @override
  String get rbTabsRecordings => 'Recordings';

  @override
  String get rbTabsResolutions => 'Resolutions';

  @override
  String get rbTitle => 'Resolution Book';

  @override
  String get rbTypeOffline => 'Offline';

  @override
  String get rbTypeOnline => 'Online';

  @override
  String get rbUpcomingLabel => 'Next meeting';

  @override
  String get rbVoteAgainst => 'Against';

  @override
  String get rbVoteFor => 'For';

  @override
  String get rbVoteNeutral => 'Neutral';

  @override
  String get registrationAddressInfoCurrentAddressTitle => 'Current Address';

  @override
  String get registrationAddressInfoDistrictLabel => 'District';

  @override
  String get registrationAddressInfoDistrictRequired => 'District is required';

  @override
  String get registrationAddressInfoDivisionLabel => 'Division';

  @override
  String get registrationAddressInfoDivisionRequired => 'Division is required';

  @override
  String get registrationAddressInfoHouseLabel => 'House/Holding No.';

  @override
  String get registrationAddressInfoHouseRequired =>
      'House/Holding No. is required';

  @override
  String get registrationAddressInfoPermanentAddressTitle =>
      'Permanent Address';

  @override
  String get registrationAddressInfoPostOfficeLabel => 'Post Office';

  @override
  String get registrationAddressInfoPostOfficeRequired =>
      'Post office is required';

  @override
  String get registrationAddressInfoRoadLabel => 'Road/Village';

  @override
  String get registrationAddressInfoRoadRequired => 'Road/Village is required';

  @override
  String get registrationAddressInfoSameAsCurrentLabel =>
      'Same as current address';

  @override
  String get registrationAddressInfoSelectPlaceholder => 'Select';

  @override
  String get registrationAddressInfoUpazilaLabel => 'Upazila/Thana';

  @override
  String get registrationAddressInfoUpazilaRequired =>
      'Upazila/Thana is required';

  @override
  String get registrationConfirmationApplicantLabel => 'Applicant:';

  @override
  String get registrationConfirmationMessage =>
      'Your application has been submitted successfully. Please wait for verification and approval.';

  @override
  String get registrationConfirmationNewFormButton => 'Fill Out a New Form';

  @override
  String get registrationConfirmationOkButton => 'OK';

  @override
  String get registrationConfirmationReferenceLabel => 'Application no:';

  @override
  String get registrationConfirmationTitle => 'Submission Successful!';

  @override
  String get registrationDeclarationConsentLabel =>
      'I agree to all the terms and conditions.';

  @override
  String get registrationDeclarationConsentRequired =>
      'Consent to the declaration is required';

  @override
  String get registrationDeclarationText =>
      'I pledge to abide by the constitution, rules, discipline, and decisions of the Uttar Kaundia Abashon Malik Kalyan Society, and I will not participate in any activity contrary to the organization\'s purpose and interests. I will responsibly cooperate with the organization\'s decisions regarding members\' rights, property security, mutual cooperation, social welfare, and local development. The above information is correct to the best of my knowledge and belief.';

  @override
  String get registrationDeclarationTitle => 'Declaration';

  @override
  String get registrationDraftDiscardDraft => 'Discard and start fresh';

  @override
  String get registrationDraftDraftRestoredToast =>
      'Your previous incomplete form was restored';

  @override
  String get registrationDraftDraftSaved => 'Draft saved';

  @override
  String get registrationDraftReattachFilesNotice =>
      'Please re-attach any files from the restored draft';

  @override
  String get registrationHeaderFormBadge =>
      'Member Registration & Ownership Information Form';

  @override
  String get registrationHeaderLoginLink => 'Login';

  @override
  String get registrationHeaderLogoAlt => 'Organization logo';

  @override
  String get registrationHeaderOrgLocation =>
      'Uttar Kaundia, Savar, Dhaka. | Established: 2026';

  @override
  String get registrationHeaderOrgName =>
      'Uttar Kaundia Abashon Malik Kalyan Society';

  @override
  String get registrationHeaderOrgSubtitle =>
      '(A united non-political housing organization for all land, house, and flat owners)';

  @override
  String get registrationHeaderStepperAriaLabel => 'Registration steps';

  @override
  String get registrationHeaderSubmissionDateLabel => 'Registration Date';

  @override
  String get registrationMemberInfoClearPhotoButton => 'Remove';

  @override
  String get registrationMemberInfoDobLabel => 'Date of Birth';

  @override
  String get registrationMemberInfoDobRequired => 'Date of birth is required';

  @override
  String get registrationMemberInfoEmailInvalid => 'Email is invalid';

  @override
  String get registrationMemberInfoEmailLabel => 'Email';

  @override
  String get registrationMemberInfoEmailRequired => 'Email is required';

  @override
  String get registrationMemberInfoFatherOrHusbandLabel => 'Father/Husband';

  @override
  String get registrationMemberInfoFatherOrHusbandRequired =>
      'Father/Husband is required';

  @override
  String get registrationMemberInfoFullNameLabel => 'Full Name';

  @override
  String get registrationMemberInfoFullNameRequired => 'Full name is required';

  @override
  String get registrationMemberInfoGenderFemale => 'Female';

  @override
  String get registrationMemberInfoGenderLabel => 'Gender';

  @override
  String get registrationMemberInfoGenderMale => 'Male';

  @override
  String get registrationMemberInfoGenderRequired => 'Please select gender';

  @override
  String get registrationMemberInfoMemberPhotoRequired =>
      'Member\'s photo is required';

  @override
  String get registrationMemberInfoMobileInvalid =>
      'Mobile number is invalid (01XXXXXXXXX)';

  @override
  String get registrationMemberInfoMobileLabel => 'Mobile (WhatsApp)';

  @override
  String get registrationMemberInfoMobileRequired => 'Mobile is required';

  @override
  String get registrationMemberInfoMotherLabel => 'Mother';

  @override
  String get registrationMemberInfoMotherRequired =>
      'Mother\'s name is required';

  @override
  String get registrationMemberInfoNationalityLabel => 'Nationality';

  @override
  String get registrationMemberInfoNidInvalid =>
      'NID number must be 10-17 digits';

  @override
  String get registrationMemberInfoNidLabel => 'NID No.';

  @override
  String get registrationMemberInfoNidPlaceholder => '10-17 digits';

  @override
  String get registrationMemberInfoNidRequired => 'NID number is required';

  @override
  String get registrationMemberInfoOccupationLabel => 'Occupation';

  @override
  String get registrationMemberInfoPhotoAlt => 'Member\'s photo';

  @override
  String get registrationMemberInfoPhotoPlaceholder => 'Member\'s photo';

  @override
  String get registrationMemberInfoPhotoSizeError =>
      'Photo size must be less than 3 MB';

  @override
  String get registrationMemberInfoPhotoTypeError =>
      'Please select an image file (JPG/PNG)';

  @override
  String get registrationNavNext => 'Next';

  @override
  String get registrationNavPrevious => 'Previous';

  @override
  String get registrationNavSubmit => 'Submit Form';

  @override
  String get registrationNavSubmitting => 'Submitting...';

  @override
  String get registrationNomineeAddMore => 'Add another nominee';

  @override
  String get registrationNomineeAdditionalNomineesTitle =>
      'Additional Nominees';

  @override
  String get registrationNomineeAddressLabel => 'Address';

  @override
  String get registrationNomineeMobileInvalid =>
      'Mobile number is invalid (01XXXXXXXXX)';

  @override
  String get registrationNomineeMobileLabel => 'Mobile';

  @override
  String get registrationNomineeMobileRequired => 'Mobile is required';

  @override
  String get registrationNomineeNameLabel => 'Name';

  @override
  String get registrationNomineeNameRequired => 'Name is required';

  @override
  String registrationNomineeNomineeNumberTitle(Object number) {
    return 'Nominee $number';
  }

  @override
  String get registrationNomineeRelationLabel => 'Father/Husband / Relation';

  @override
  String get registrationNomineeRelationShortLabel => 'Relation';

  @override
  String get registrationNomineeRemove => 'Remove';

  @override
  String get registrationNomineeSameAsUrgentContactLabel =>
      'Use the same information as urgent contact';

  @override
  String get registrationPaymentAccountNameLabel => 'Account Name';

  @override
  String get registrationPaymentAccountNumberLabel => 'Account Number';

  @override
  String get registrationPaymentAdmissionFeeHint =>
      'Current admission fee — set by the organization, not editable here';

  @override
  String get registrationPaymentAdmissionFeeLabel => 'Admission Fee (Taka)';

  @override
  String get registrationPaymentAdmissionFeeLoadFailed =>
      'Could not load the current admission fee. Please retry.';

  @override
  String get registrationPaymentAdmissionFeeLoading =>
      'Loading current admission fee…';

  @override
  String get registrationPaymentAdmissionFeeRequired =>
      'Admission fee is required';

  @override
  String get registrationPaymentAdmissionFeeRetry => 'Retry';

  @override
  String get registrationPaymentAttachReceipt => 'Attach receipt image';

  @override
  String get registrationPaymentBankNameLabel => 'Bank';

  @override
  String get registrationPaymentBranchLabel => 'Branch';

  @override
  String registrationPaymentFileSizeError(Object maxMb) {
    return 'File size must not exceed $maxMb MB';
  }

  @override
  String get registrationPaymentFileTypeError =>
      'Only JPG, PNG, or PDF files are accepted';

  @override
  String registrationPaymentMaxFileSizeHint(Object maxMb) {
    return 'Max $maxMb MB (JPG/PNG/PDF)';
  }

  @override
  String get registrationPaymentMethodLabel => 'Method';

  @override
  String get registrationPaymentMfsNumberLabel => 'MFS Number';

  @override
  String get registrationPaymentPaymentMethodRequired =>
      'Payment method is required';

  @override
  String get registrationPaymentReceiptImageLabel => 'Money Receipt Image';

  @override
  String get registrationPaymentReceiptNoLabel => 'Receipt No./Transaction ID';

  @override
  String get registrationPaymentRemoveFile => 'Remove';

  @override
  String get registrationPaymentRoutingNumberLabel => 'Routing Number';

  @override
  String registrationPaymentSubscriptionBaseSummary(Object amount) {
    return 'Base: $amount Tk';
  }

  @override
  String registrationPaymentSubscriptionExtraSummary(
      Object amount, Object extra) {
    return '+ extra $extra decimal(s) (a partial decimal counts as a full one) = $amount Tk';
  }

  @override
  String get registrationPaymentSubscriptionHint =>
      'Set by the organization, not editable here';

  @override
  String get registrationPaymentSubscriptionLabel => 'Subscription (Taka)';

  @override
  String get registrationPaymentSubscriptionLoadFailed =>
      'Could not calculate the subscription amount. Please retry.';

  @override
  String get registrationPaymentSubscriptionLoading =>
      'Calculating the subscription amount…';

  @override
  String get registrationPaymentSubscriptionRequired =>
      'Subscription is required';

  @override
  String get registrationPaymentSubscriptionRetry => 'Retry';

  @override
  String registrationPaymentTotalAmountSummary(Object amount) {
    return '= Total $amount Tk';
  }

  @override
  String get registrationPropertyApplicableDocsLabel => 'Applicable Documents';

  @override
  String get registrationPropertyApplicableDocsRequired =>
      'Please select applicable documents';

  @override
  String get registrationPropertyAttachFileButton => 'Attach file';

  @override
  String get registrationPropertyCountLabel => 'Number of Properties';

  @override
  String get registrationPropertyCountSelectPlaceholder => 'Select';

  @override
  String get registrationPropertyDagCsLabel => 'CS Dag No.';

  @override
  String get registrationPropertyDagNoCsRequired => 'CS dag no. is required';

  @override
  String get registrationPropertyDagNoLabel => 'Dag No.';

  @override
  String get registrationPropertyDagNoRsRequired => 'RS dag no. is required';

  @override
  String get registrationPropertyDagRsLabel => 'RS Dag No.';

  @override
  String get registrationPropertyDocFileMissing =>
      'A file must be attached for this document';

  @override
  String registrationPropertyDocFileSizeError(Object maxMb) {
    return 'File size must not exceed $maxMb MB';
  }

  @override
  String get registrationPropertyDocFileTypeError =>
      'Only JPG, PNG, or PDF files are accepted';

  @override
  String get registrationPropertyHoldingNumberLabel => 'Holding Number';

  @override
  String get registrationPropertyItemTitle => 'Property';

  @override
  String get registrationPropertyJointOwnerCountLabel => 'Joint Owner Count';

  @override
  String get registrationPropertyJointOwnerCountRequired =>
      'Joint owner count is required';

  @override
  String get registrationPropertyKhatianNoLabel => 'Khatian No.';

  @override
  String get registrationPropertyKhatianNoRequired => 'Khatian No. is required';

  @override
  String get registrationPropertyLandQuantityInvalid =>
      'Total land quantity must be greater than zero';

  @override
  String get registrationPropertyLandQuantityLabel =>
      'Total Land Quantity (Decimal):';

  @override
  String get registrationPropertyLandQuantityPlaceholder => 'e.g., 2.5';

  @override
  String get registrationPropertyLandQuantityRequired =>
      'Total land quantity is required';

  @override
  String registrationPropertyMaxFileSizeNote(Object maxMb) {
    return 'Max $maxMb MB (JPG/PNG/PDF)';
  }

  @override
  String get registrationPropertyMyShareQuantityExceedsTotal =>
      'My share quantity cannot exceed total land quantity';

  @override
  String get registrationPropertyMyShareQuantityInvalid =>
      'My share quantity must be greater than zero';

  @override
  String get registrationPropertyMyShareQuantityLabel =>
      'My Share Quantity (Decimal):';

  @override
  String get registrationPropertyMyShareQuantityPlaceholder => 'e.g., 1.25';

  @override
  String get registrationPropertyMyShareQuantityRequired =>
      'My share quantity is required';

  @override
  String get registrationPropertyOwnershipLabel => 'Ownership';

  @override
  String get registrationPropertyOwnershipRequired => 'Ownership is required';

  @override
  String get registrationPropertyRemoveFileButton => 'Remove';

  @override
  String get registrationPropertyTypeLabel => 'Property Type';

  @override
  String get registrationPropertyTypeOtherPlaceholder => 'Enter details';

  @override
  String get registrationPropertyTypeRequired => 'Property type is required';

  @override
  String get registrationReviewDeclarationAccepted => 'Consent has been given';

  @override
  String get registrationReviewDeclarationNotAccepted =>
      'Consent has not been given';

  @override
  String get registrationReviewDeclarationTitle => 'Declaration';

  @override
  String get registrationReviewEdit => 'Edit';

  @override
  String get registrationReviewEmailLabel => 'Email';

  @override
  String get registrationReviewFatherOrHusbandLabel => 'Father/Husband';

  @override
  String get registrationReviewIntro =>
      'Please verify the information below before submitting.';

  @override
  String get registrationReviewMemberInfoTitle => 'Member Information';

  @override
  String get registrationReviewMethodLabel => 'Method';

  @override
  String get registrationReviewMobileLabel => 'Mobile';

  @override
  String get registrationReviewNameLabel => 'Name';

  @override
  String get registrationReviewNomineeCountLabel => 'Number of nominees';

  @override
  String registrationReviewNomineeCountSummary(Object count) {
    return '$count';
  }

  @override
  String get registrationReviewPaymentInfoTitle => 'Payment Information';

  @override
  String get registrationReviewPropertyInfoTitle => 'Property Information';

  @override
  String get registrationReviewSubscriptionLabel => 'Subscription';

  @override
  String registrationReviewTotalPropertiesSummary(Object count) {
    return 'Total properties: $count';
  }

  @override
  String get registrationReviewUrgentContactAndNomineeTitle =>
      'Urgent Contact & Nominee';

  @override
  String get registrationReviewUrgentContactLabel => 'Urgent Contact';

  @override
  String get registrationSignatureSectionTitle => 'Signature';

  @override
  String get registrationSignatureHint =>
      'Draw your signature in the box below';

  @override
  String get registrationSignatureClearButton => 'Clear';

  @override
  String get registrationSignatureSaveButton => 'Save signature';

  @override
  String get registrationSignatureSavedButton => 'Signature saved';

  @override
  String get registrationStepShortLabelsMemberInfo => 'Member';

  @override
  String get registrationStepShortLabelsNominee => 'Nominee';

  @override
  String get registrationStepShortLabelsPayment => 'Payment';

  @override
  String get registrationStepShortLabelsProperty => 'Property';

  @override
  String get registrationStepShortLabelsReview => 'Review';

  @override
  String get registrationStepShortLabelsSignature => 'Signature';

  @override
  String get registrationStepTitlesAddressInfo => '2. Address Information';

  @override
  String get registrationStepTitlesContactAndNominee =>
      'Urgent Contact & Nominee';

  @override
  String get registrationStepTitlesDeclarationAndSignature =>
      'Declaration & Signature';

  @override
  String get registrationStepTitlesMemberInfo =>
      '1. Member\'s Personal Information';

  @override
  String get registrationStepTitlesNominee => '5. Nominee';

  @override
  String get registrationStepTitlesPayment => 'Payment Information';

  @override
  String get registrationStepTitlesProperty =>
      '3. Housing / Property Ownership Information';

  @override
  String get registrationStepTitlesReview => 'Review';

  @override
  String get registrationStepTitlesUrgentContact => '4. Urgent Contact';

  @override
  String get registrationSubmitDuplicateApproved =>
      'You are already registered as a member. Please login.';

  @override
  String get registrationSubmitDuplicateGeneric =>
      'An application with this information already exists.';

  @override
  String get registrationSubmitDuplicatePending =>
      'Your application is pending. Please wait for confirmation.';

  @override
  String get registrationSubmitDuplicateTitle => 'Application Already Exists';

  @override
  String registrationSubmitErrorCode(Object status) {
    return 'code $status';
  }

  @override
  String get registrationSubmitFeeNotConfigured =>
      'Admission fee has not been set yet. Please contact the office.';

  @override
  String get registrationSubmitFieldsAdmissionFee => 'Admission fee';

  @override
  String get registrationSubmitFieldsCurrentAddress => 'Current address';

  @override
  String get registrationSubmitFieldsDob => 'Date of birth';

  @override
  String get registrationSubmitFieldsEmail => 'Email';

  @override
  String get registrationSubmitFieldsFatherOrHusband => 'Father/Husband';

  @override
  String get registrationSubmitFieldsFullName => 'Full name';

  @override
  String get registrationSubmitFieldsGender => 'Gender';

  @override
  String get registrationSubmitFieldsMemberSignature => 'Member signature';

  @override
  String get registrationSubmitFieldsMobile => 'Mobile';

  @override
  String get registrationSubmitFieldsMother => 'Mother\'s name';

  @override
  String get registrationSubmitFieldsNationality => 'Nationality';

  @override
  String get registrationSubmitFieldsNid => 'NID number';

  @override
  String get registrationSubmitFieldsNominees => 'Nominee';

  @override
  String get registrationSubmitFieldsOccupation => 'Occupation';

  @override
  String get registrationSubmitFieldsPaymentMethod => 'Payment method';

  @override
  String get registrationSubmitFieldsPermanentAddress => 'Permanent address';

  @override
  String get registrationSubmitFieldsProperties => 'Property';

  @override
  String get registrationSubmitFieldsReceiptNo => 'Receipt no';

  @override
  String get registrationSubmitFieldsSubmissionDate => 'Registration date';

  @override
  String get registrationSubmitFieldsSubscription => 'Subscription';

  @override
  String get registrationSubmitFieldsUrgentContactAddress =>
      'Urgent contact address';

  @override
  String get registrationSubmitFieldsUrgentContactMobile =>
      'Urgent contact mobile';

  @override
  String get registrationSubmitFieldsUrgentContactName => 'Urgent contact name';

  @override
  String get registrationSubmitFieldsUrgentContactRelation =>
      'Urgent contact relation';

  @override
  String get registrationSubmitFileTooLarge =>
      'An uploaded photo or file is too large. Please use a smaller file (max 10 MB).';

  @override
  String get registrationSubmitGenericError => 'There was a problem submitting';

  @override
  String get registrationSubmitInvalidData =>
      'Some information or uploaded files are invalid. Please check and try again.';

  @override
  String get registrationSubmitInvalidShareQuantity =>
      'Land share quantity is invalid. Please check the property step.';

  @override
  String get registrationSubmitNetworkError =>
      'Network issue. Please try again.';

  @override
  String get registrationSubmitReasonsInvalid => 'the value is invalid';

  @override
  String get registrationSubmitReasonsRequired => 'this field is required';

  @override
  String get registrationSubmitServerError =>
      'Server problem. Please try again in a few minutes.';

  @override
  String get registrationUrgentContactAddressLabel => 'Address';

  @override
  String get registrationUrgentContactMobileInvalid =>
      'Mobile number is invalid (01XXXXXXXXX)';

  @override
  String get registrationUrgentContactMobileLabel => 'Mobile';

  @override
  String get registrationUrgentContactMobileRequired => 'Mobile is required';

  @override
  String get registrationUrgentContactNameLabel => 'Name';

  @override
  String get registrationUrgentContactNameRequired => 'Name is required';

  @override
  String get registrationUrgentContactRelationLabel => 'Relation';

  @override
  String get registrationValidationApplicableDocsRequired =>
      'Please select applicable documents';

  @override
  String get registrationValidationCurrentAddressLabel => 'Current Address';

  @override
  String get registrationValidationDobRequired => 'Date of birth is required';

  @override
  String registrationValidationDocFileRequired(Object docType) {
    return 'A file must be attached for \"$docType\"';
  }

  @override
  String get registrationValidationEmailInvalid => 'Email is invalid';

  @override
  String get registrationValidationFatherOrHusbandRequired =>
      'Father/Husband is required';

  @override
  String get registrationValidationFullNameRequired => 'Full name is required';

  @override
  String get registrationValidationGenderRequired => 'Please select gender';

  @override
  String get registrationValidationJointOwnerCountRequired =>
      'Joint owner count is required';

  @override
  String get registrationValidationLandQuantityInvalid =>
      'Total land quantity must be greater than zero';

  @override
  String get registrationValidationLandQuantityRequired =>
      'Total land quantity is required';

  @override
  String get registrationValidationMobileInvalid =>
      'Mobile number is invalid (01XXXXXXXXX)';

  @override
  String get registrationValidationMobileRequired => 'Mobile is required';

  @override
  String get registrationValidationMotherRequired =>
      'Mother\'s name is required';

  @override
  String get registrationValidationMyShareQuantityExceedsTotal =>
      'My share quantity cannot exceed total land quantity';

  @override
  String get registrationValidationMyShareQuantityInvalid =>
      'My share quantity must be greater than zero';

  @override
  String get registrationValidationMyShareQuantityRequired =>
      'My share quantity is required';

  @override
  String get registrationValidationNameRequired => 'Name is required';

  @override
  String get registrationValidationNidInvalid =>
      'NID number must be 10-17 digits';

  @override
  String registrationValidationNomineeLabel(Object number) {
    return 'Nominee #$number';
  }

  @override
  String get registrationValidationOwnershipRequired => 'Ownership is required';

  @override
  String get registrationValidationPermanentAddressLabel => 'Permanent Address';

  @override
  String get registrationValidationPropertyCountRequired =>
      'Please select the number of properties';

  @override
  String registrationValidationPropertyLabel(Object number) {
    return 'Property #$number';
  }

  @override
  String get registrationValidationPropertyTypeRequired =>
      'Property type is required';

  @override
  String get registrationValidationUrgentContactLabel => 'Urgent Contact';

  @override
  String welcome(Object name) {
    return 'Welcome, $name';
  }

  @override
  String get brandOrgName => 'Uttar Kaundia Abashon Malik Kalyan Society';

  @override
  String get commonLogout => 'Log out';

  @override
  String get commonLanguage => 'Language';

  @override
  String get commonTheme => 'Theme';

  @override
  String get commonStatusPending => 'Pending';

  @override
  String get commonStatusApproved => 'Approved';

  @override
  String get commonStatusRejected => 'Rejected';

  @override
  String get commonNoData => 'No data found';

  @override
  String get commonNetworkError => 'Network error — please retry';

  @override
  String get commonServerError => 'Server error — please try again later';

  @override
  String get commonUnauthorized => 'Session expired — please log in again';

  @override
  String get commonConfirmAction => 'Confirm';

  @override
  String get superadminTabsRoles => 'Roles';

  @override
  String get superadminTabsUsers => 'Users';

  @override
  String get superadminRolesEmpty => 'No roles found.';

  @override
  String get superadminUsersEmpty => 'No administrators yet.';

  @override
  String get superadminRoleAdministrator => 'Administrator';

  @override
  String get superadminRoleExecutiveCommittee => 'Executive Committee';

  @override
  String get superadminRoleSuperAdmin => 'Super Admin';

  @override
  String get superadminAuditClearFilters => 'Clear filters';

  @override
  String get memberProfileCurrentHouseLabel => 'Current house';

  @override
  String get memberProfileCurrentRoadLabel => 'Current road';

  @override
  String get memberProfileCurrentPostOfficeLabel => 'Current post office';

  @override
  String get memberProfileCurrentUpazilaLabel => 'Current upazila';

  @override
  String get memberProfileCurrentDistrictLabel => 'Current district';

  @override
  String get memberProfileCurrentDivisionLabel => 'Current division';

  @override
  String get memberProfileUrgentNameLabel => 'Contact name';

  @override
  String get memberProfileUrgentMobileLabel => 'Contact mobile';

  @override
  String get memberProfileMobileInvalid =>
      'Enter a valid mobile number (e.g. +8801XXXXXXXXX)';

  @override
  String get memberProfilePropertyTypesLabel => 'Property type';

  @override
  String get attachmentViewerMissing => 'The file is missing on the server.';

  @override
  String get attachmentViewerDownloadFailed =>
      'Download failed. Please try again.';

  @override
  String get attachmentViewerDownloadStarted => 'Download started.';

  @override
  String get attachmentViewerPreviewUnavailable =>
      'This file type cannot be previewed in the app.';

  @override
  String get attachmentViewerDownloadOpen => 'Download & open';

  @override
  String get memberFundTransparencyFiltersDateFrom => 'From date';

  @override
  String get memberFundTransparencyFiltersDateTo => 'To date';

  @override
  String get adminRoadmapStatusPlanned => 'Planned';

  @override
  String get adminRoadmapStatusInProgress => 'In progress';

  @override
  String get adminRoadmapStatusDone => 'Done';

  @override
  String get adminPropertyRequestsPayloadType => 'Property type';

  @override
  String get adminPropertyRequestsPayloadKhatianNo => 'Khatian no';

  @override
  String get adminPropertyRequestsPayloadDagNoCs => 'CS dag no';

  @override
  String get adminPropertyRequestsPayloadDagNoRs => 'RS dag no';

  @override
  String get adminPropertyRequestsPayloadHoldingNumber => 'Holding no';

  @override
  String get adminPropertyRequestsPayloadLandQuantity => 'Land quantity';

  @override
  String get adminPropertyRequestsPayloadMyShareQuantity => 'My share';

  @override
  String get adminPropertyRequestsPayloadOwnership => 'Ownership';

  @override
  String get adminPropertyRequestsPayloadCoOwners => 'Co-owners';

  @override
  String get adminPropertyRequestsPayloadDocs => 'Documents';

  @override
  String get adminSocietyCostsSummaryMemberBilled => 'Member billed';

  @override
  String get adminFinanceManagementFiltersApply => 'Apply';

  @override
  String get navNeighbours => 'Neighbours';

  @override
  String get memberNeighboursTitle => 'Neighbour plot owners';

  @override
  String memberNeighboursSubtitle(Object count) {
    return 'Reach the owners on your dag and the $count nearest dags';
  }

  @override
  String get memberNeighboursPrivacyNote =>
      'This information is only for contacting your neighbours — please don\'t share it.';

  @override
  String get memberNeighboursDagTypeLabel => 'Dag type';

  @override
  String get memberNeighboursDagTypeRs => 'RS dag';

  @override
  String get memberNeighboursDagTypeCs => 'CS dag';

  @override
  String get memberNeighboursOwnDag => 'Your dag';

  @override
  String get memberNeighboursTableOwnerName => 'Owner name';

  @override
  String get memberNeighboursTableMobile => 'Mobile number';

  @override
  String get memberNeighboursTableLandQuantity => 'Land quantity';

  @override
  String get memberNeighboursTableRsDag => 'RS dag';

  @override
  String get memberNeighboursTableCsDag => 'CS dag';

  @override
  String get memberNeighboursTablePosition => 'Position';

  @override
  String get memberNeighboursTableContact => 'Contact';

  @override
  String get memberNeighboursPositionSameDag => 'On your dag';

  @override
  String get memberNeighboursPositionAdjacent => 'Adjacent dag';

  @override
  String get memberNeighboursPositionNear => 'Nearby dag';

  @override
  String memberNeighboursLandUnit(Object value) {
    return '$value decimal';
  }

  @override
  String get memberNeighboursCall => 'Call';

  @override
  String memberNeighboursCallAria(Object name) {
    return 'Call $name';
  }

  @override
  String get memberNeighboursWhatsapp => 'WhatsApp';

  @override
  String memberNeighboursWhatsappAria(Object name) {
    return 'Message $name on WhatsApp';
  }

  @override
  String get memberNeighboursContactHidden => 'Number kept private';

  @override
  String get memberNeighboursEmptyState =>
      'No registered members were found around your dag';

  @override
  String get memberNeighboursEmptyHint =>
      'Neighbours will appear here as more members register.';

  @override
  String get memberNeighboursNoProperties =>
      'No property is recorded on your profile.';

  @override
  String memberNeighboursNoDag(Object type) {
    return 'This property has no $type number — try the other dag type.';
  }

  @override
  String get memberNeighboursLoadError =>
      'Could not load neighbour information.';

  @override
  String get memberNeighboursRateLimited =>
      'Too many lookups. Please try again in a little while.';

  @override
  String get memberNeighboursApprovedOnly =>
      'Only approved members can view neighbour information.';

  @override
  String get memberNeighboursDialerUnavailable =>
      'Calling isn\'t available on this device.';

  @override
  String get memberNeighboursWhatsappUnavailable =>
      'WhatsApp couldn\'t be opened.';

  @override
  String get memberProfileNeighbourDirectoryLabel =>
      'Show my mobile number to neighbours';

  @override
  String get memberProfileNeighbourDirectoryHint =>
      'When off, neighbours see only your name, land quantity and dags.';

  @override
  String get navPlotMap => 'Plot Boundaries';

  @override
  String get boundaryTitle => 'Plot Boundaries';

  @override
  String get boundarySubtitle =>
      'View plot boundaries on the map and draw your own';

  @override
  String get boundaryViewOnMap => 'View on map';

  @override
  String get boundaryDraw => 'Draw boundary';

  @override
  String get boundaryDisclaimer =>
      'This is a member-marked approximate boundary; it is not a substitute for an official survey or legal documents.';

  @override
  String get boundaryStatusDraft => 'Draft';

  @override
  String get boundaryStatusPendingReview => 'Pending review';

  @override
  String get boundaryStatusApproved => 'Approved';

  @override
  String get boundaryStatusRejected => 'Rejected';

  @override
  String get boundaryStatusDisputed => 'Disputed';

  @override
  String get boundaryStatusMine => 'My boundary';

  @override
  String get boundaryOwnerTitle => 'Owner details';

  @override
  String get boundaryOwnerContactHidden => 'Contact hidden';

  @override
  String get boundaryCall => 'Call';

  @override
  String get boundaryWhatsapp => 'WhatsApp';

  @override
  String get boundaryRsDag => 'RS dag';

  @override
  String get boundaryCsDag => 'CS dag';

  @override
  String get boundaryLandQuantity => 'Land quantity';

  @override
  String get boundaryAreaLabel => 'Area';

  @override
  String boundaryAreaValues(Object sqm, Object shotangsho) {
    return '$sqm m² · $shotangsho shotangsho';
  }

  @override
  String get boundaryAreaEstimateTag => 'estimate';

  @override
  String get boundaryOwnerLoadError => 'Could not load the owner details.';

  @override
  String get boundaryLoadError => 'Could not load the map data.';

  @override
  String get boundarySearchDagHint => 'Search by dag number';

  @override
  String get boundarySearchNoMatch => 'No boundary matches this dag number.';

  @override
  String get boundaryMyLocation => 'My location';

  @override
  String get boundaryLayerStreet => 'Street';

  @override
  String get boundaryLayerSatellite => 'Satellite';

  @override
  String get boundaryReport => 'Report a problem';

  @override
  String get boundaryReportNoteHint => 'Describe the problem';

  @override
  String get boundaryReportSubmit => 'Send report';

  @override
  String get boundaryReportSent => 'Report received.';

  @override
  String get boundaryReportError => 'Could not send the report.';

  @override
  String get boundaryEditorTitle => 'Draw boundary';

  @override
  String get boundaryEditorAddHint =>
      'Tap the map to add points; drag a point to move it.';

  @override
  String get boundaryEditorUndo => 'Undo';

  @override
  String get boundaryEditorClear => 'Clear';

  @override
  String get boundaryEditorSave => 'Submit';

  @override
  String get boundaryEditorPropertyLabel => 'Your plot';

  @override
  String get boundaryEditorNoProperty =>
      'None of your plots are without a boundary.';

  @override
  String boundaryEditorVertices(Object count) {
    return 'Points: $count';
  }

  @override
  String get boundarySaveSuccess =>
      'Boundary submitted; it is now pending review.';

  @override
  String get boundaryEditExisting => 'Edit boundary';

  @override
  String get boundaryErrorTooFewPoints => 'At least 3 points are required.';

  @override
  String get boundaryErrorSelfIntersecting =>
      'The boundary line crosses itself.';

  @override
  String get boundaryErrorOutsideSociety =>
      'The boundary goes outside the society area.';

  @override
  String get boundaryErrorZeroArea =>
      'The area is nearly zero; spread the points out.';

  @override
  String get boundaryErrorTooManyVertices => 'Too many points.';

  @override
  String get boundaryErrorInvalidGeometry => 'The boundary shape is invalid.';

  @override
  String get boundaryErrorNotYourProperty =>
      'You cannot draw a boundary for someone else\'s plot.';

  @override
  String get boundaryErrorBoundaryExists => 'This plot already has a boundary.';

  @override
  String get boundaryErrorRateLimited =>
      'Too many attempts; please try again later.';

  @override
  String get boundaryErrorNotApproved => 'This boundary is not approved yet.';

  @override
  String get boundaryErrorGeneric => 'Could not save the boundary.';

  @override
  String get boundaryReviewNote => 'Review note';

  @override
  String get boundaryMobile => 'Mobile';

  @override
  String get plotMapTitle => 'Plot Boundary Map';

  @override
  String get plotMapLocationError => 'Could not determine your location.';

  @override
  String get plotMapOutsideSociety =>
      'You are outside the Uttar Kaundia area — showing the society map instead.';

  @override
  String get plotMapLegend => 'Legend';

  @override
  String get plotMapStatusDraft => 'Draft';

  @override
  String get plotMapStatusPendingReview => 'Pending review';

  @override
  String get plotMapStatusApproved => 'Approved';

  @override
  String get plotMapStatusMine => 'Mine';

  @override
  String get plotMapStatusRejected => 'Rejected';

  @override
  String get plotMapStatusDisputed => 'Disputed';

  @override
  String get plotMapStatusPending => 'Waiting for approval';

  @override
  String get plotMapStatusSuperseded => 'Superseded';

  @override
  String get plotMapStatusWithdrawn => 'Withdrawn';

  @override
  String get plotMapStatusDeleted => 'Deleted';

  @override
  String get plotMapDetailsTitle => 'Plot details';

  @override
  String get plotMapDetailsLandQuantity => 'Declared land';

  @override
  String get plotMapDetailsArea => 'Computed area';

  @override
  String get plotMapDetailsShotangsho => 'শতাংশ';

  @override
  String get plotMapDetailsContactHidden => 'Contact hidden';

  @override
  String get plotMapOwnerRateLimited =>
      'Too many lookups - please wait a moment and try again.';

  @override
  String get plotMapOwnerNotApproved =>
      'This boundary is not approved yet, so owner details are unavailable.';

  @override
  String get plotMapOwnerLoadError => 'Could not load owner details.';

  @override
  String get plotMapDrawOpen => 'Draw boundary';

  @override
  String get plotMapDrawTitle => 'Draw your plot boundary';

  @override
  String get plotMapDrawEditTitle => 'Edit my boundary';

  @override
  String get plotMapDrawPickHint =>
      'Choose one of your properties that has no boundary yet, then draw its outline on the map.';

  @override
  String get plotMapDrawNoProperties =>
      'None of your properties is available for drawing - either all have boundaries already or no property is registered.';

  @override
  String get plotMapDrawStart => 'Draw on map';

  @override
  String get plotMapDrawMyBoundaries => 'My boundaries';

  @override
  String get plotMapDrawEdit => 'Edit';

  @override
  String get plotMapDrawErrorsInvalidGeometry =>
      'The drawn shape is not a valid polygon.';

  @override
  String get plotMapDrawErrorsSelfIntersecting =>
      'The outline crosses itself - fix the overlapping part and try again.';

  @override
  String get plotMapDrawErrorsOutsideSocietyArea =>
      'The outline goes outside the society area.';

  @override
  String get plotMapDrawErrorsZeroArea =>
      'The drawn shape has no area - add more points.';

  @override
  String get plotMapDrawErrorsTooManyVertices =>
      'Too many points - simplify the outline.';

  @override
  String get plotMapDrawErrorsNotYourProperty =>
      'This property does not belong to your account.';

  @override
  String get plotMapDrawErrorsBoundaryExists =>
      'This property already has a boundary.';

  @override
  String get plotMapDrawErrorsGeneric =>
      'Could not save the boundary. Please try again.';

  @override
  String get plotMapDrawWithdraw => 'Withdraw submission';

  @override
  String get plotMapDrawWithdrawTitle => 'Withdraw submission?';

  @override
  String get plotMapDrawWithdrawMessage =>
      'Your pending submission will be marked withdrawn. Any approved shape stays live.';

  @override
  String get plotMapDrawReplaceTitle => 'Replace pending submission?';

  @override
  String get plotMapDrawReplaceMessage =>
      'A submission is already awaiting review. Saving now replaces it with this shape.';

  @override
  String get plotMapValidationSelfIntersection =>
      'The outline crosses itself - fix the highlighted overlap.';

  @override
  String get plotMapValidationOutsideSociety =>
      'Part of the outline is outside the society area.';

  @override
  String get plotMapValidationAreaMismatch =>
      'The drawn area differs a lot from your declared land quantity.';

  @override
  String get plotMapValidationArea => 'Drawn area';

  @override
  String get plotMapValidationOk => 'The outline looks valid.';

  @override
  String get plotMapViewsTitle => 'Map views';

  @override
  String get plotMapViewsBoundaries => 'My plot boundary map';

  @override
  String get plotMapViewsBoundariesHint => 'Member-marked boundaries';

  @override
  String get plotMapViewsBds => 'BDS dag map';

  @override
  String get plotMapViewsBdsHint => 'Official mouza plot map';

  @override
  String get plotMapViewsRajuk => 'RAJUK masterplan (DAP)';

  @override
  String get plotMapViewsRajukHint => 'DAP RS plots of Uttar Kaundia';

  @override
  String get plotMapViewsLoading => 'Loading official map data…';

  @override
  String get plotMapViewsLoadError =>
      'Could not load the official map data. Please try again later.';

  @override
  String get plotMapViewsPartialData =>
      'Not all plots could be loaded for this view — zoom in to load the rest.';

  @override
  String get plotMapViewsBdsSearchPlaceholder => 'Search by BDS dag number';

  @override
  String get plotMapViewsRsSearchPlaceholder => 'Search by RS dag number';

  @override
  String get plotMapViewsDagNotFound => 'No plot found with this dag number.';

  @override
  String get plotMapViewsBdsInfoTitle => 'Dag / plot information';

  @override
  String get plotMapViewsDagNoLabel => 'Dag / plot no';

  @override
  String get plotMapViewsSurveyTypeLabel => 'Survey type';

  @override
  String get plotMapViewsSurveyTypeValue => 'BDS (2019) — Viti survey';

  @override
  String get plotMapViewsMouzaNameLabel => 'Mouza';

  @override
  String get plotMapViewsMouzaNameValue => 'Uttar Kaundia, Savar, Dhaka';

  @override
  String get plotMapViewsSheetNoLabel => 'Sheet no';

  @override
  String get plotMapViewsAreaLabel => 'Land area (hectare)';

  @override
  String get plotMapViewsKhatianNote =>
      'Khatian and ownership details are not available in this app. Verify them on the official settlement portal.';

  @override
  String get plotMapViewsMouzaLabel => 'Mouza: Uttar Kaundia';

  @override
  String get plotMapViewsThanaLabel => 'Savar Upazila, Dhaka';

  @override
  String get plotMapViewsRsPlotNo => 'RS Plot No';

  @override
  String get plotMapViewsRsJlNo => 'RS JL No';

  @override
  String get plotMapViewsStreetView => 'Google Street View';

  @override
  String get plotMapTimelineSubmitted => 'Submitted';

  @override
  String get plotMapTimelineUnderReview => 'Under review';

  @override
  String get plotMapTimelineApproved => 'Approved';

  @override
  String get plotMapTimelinePendingHint =>
      'Others will see this after the admin verifies it.';

  @override
  String get plotMapTimelineRejectionNote => 'Admin\'s note';

  @override
  String get plotMapDrawLoadError =>
      'Could not load your plots and boundaries.';

  @override
  String get plotMapSearchClear => 'Clear search';
}
