// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get adminAuditLogDetailsClose => 'বন্ধ করুন';

  @override
  String get adminAuditLogDetailsTitle => 'এন্ট্রির বিস্তারিত';

  @override
  String get adminAuditLogDetailsView => 'বিস্তারিত';

  @override
  String get adminAuditLogErrorsLoadFailed => 'অডিট লগ লোড করা যায়নি।';

  @override
  String get adminAuditLogFiltersAction => 'কার্যক্রম';

  @override
  String get adminAuditLogFiltersActor => 'প্রশাসক';

  @override
  String get adminAuditLogFiltersAll => 'সব';

  @override
  String get adminAuditLogFiltersDateFrom => 'শুরুর তারিখ';

  @override
  String get adminAuditLogFiltersDateTo => 'শেষের তারিখ';

  @override
  String get adminAuditLogFiltersEntityType => 'সত্তার ধরন';

  @override
  String get adminAuditLogNoEntries => 'এখনো কোনো অডিট লগ এন্ট্রি নেই।';

  @override
  String get adminAuditLogNoEntriesMatch => 'এই ফিল্টারে কোনো এন্ট্রি মেলেনি।';

  @override
  String get adminAuditLogPaginationNext => 'পরবর্তী';

  @override
  String get adminAuditLogPaginationPageSize => 'প্রতি পৃষ্ঠায়';

  @override
  String get adminAuditLogPaginationPrev => 'পূর্ববর্তী';

  @override
  String adminAuditLogPaginationRange(
      Object from_val, Object to_val, Object total) {
    return '$from_val–$to_val / $total';
  }

  @override
  String get adminAuditLogSubtitle =>
      'কে কখন কী অনুমোদন, প্রত্যাখ্যান বা পরিবর্তন করেছেন';

  @override
  String get adminAuditLogTableAction => 'কার্যক্রম';

  @override
  String get adminAuditLogTableActor => 'প্রশাসক';

  @override
  String get adminAuditLogTableDetail => 'বিস্তারিত';

  @override
  String get adminAuditLogTableEntity => 'সত্তা';

  @override
  String get adminAuditLogTableTime => 'সময়';

  @override
  String get adminAuditLogTitle => 'অডিট লগ';

  @override
  String get adminConfigListsActionsCancel => 'বাতিল করুন';

  @override
  String get adminConfigListsActionsEditLabel => 'লেবেল সম্পাদনা করুন';

  @override
  String get adminConfigListsActionsMoveDown => 'নিচে সরান';

  @override
  String get adminConfigListsActionsMoveUp => 'উপরে সরান';

  @override
  String get adminConfigListsActionsSave => 'সংরক্ষণ করুন';

  @override
  String get adminConfigListsActivate => 'সক্রিয় করুন';

  @override
  String get adminConfigListsActive => 'সক্রিয়';

  @override
  String get adminConfigListsAddItem => 'নতুন আইটেম যোগ করুন';

  @override
  String get adminConfigListsCategoriesDocumentType => 'দলিলের ধরন';

  @override
  String get adminConfigListsCategoriesEventCategory => 'ইভেন্ট বিভাগ';

  @override
  String get adminConfigListsCategoriesFinanceExpenseCategory =>
      'ব্যয়ের খাত (ফান্ড)';

  @override
  String get adminConfigListsCategoriesFinanceIncomeCategory =>
      'আয়ের খাত (ফান্ড)';

  @override
  String get adminConfigListsCategoriesNoticeCategory => 'নোটিশ বিভাগ';

  @override
  String get adminConfigListsCategoriesPaymentAccount =>
      'পেমেন্ট অ্যাকাউন্ট (মান = মাধ্যম, লেবেল = অ্যাকাউন্ট বিবরণ)';

  @override
  String get adminConfigListsCategoriesPropertyType => 'সম্পত্তির ধরন';

  @override
  String get adminConfigListsDeactivate => 'নিষ্ক্রিয় করুন';

  @override
  String get adminConfigListsErrorsLoadFailed =>
      'কনফিগ তালিকা আইটেম লোড করা যায়নি।';

  @override
  String get adminConfigListsErrorsSaveFailed => 'পরিবর্তন সংরক্ষণ করা যায়নি।';

  @override
  String get adminConfigListsFormLabel => 'লেবেল (ঐচ্ছিক)';

  @override
  String get adminConfigListsFormSubmit => 'আইটেম যোগ করুন';

  @override
  String get adminConfigListsFormValue => 'মান';

  @override
  String get adminConfigListsInactive => 'নিষ্ক্রিয়';

  @override
  String get adminConfigListsNoItems => 'এই বিভাগে এখনো কোনো আইটেম নেই।';

  @override
  String get adminConfigListsSubtitle =>
      'নিবন্ধন ফর্ম ও অন্যান্য স্ক্রিনে ব্যবহৃত অপশন তালিকা পরিচালনা করুন';

  @override
  String get adminConfigListsTableActions => 'অ্যাকশন';

  @override
  String get adminConfigListsTableLabel => 'লেবেল';

  @override
  String get adminConfigListsTableStatus => 'অবস্থা';

  @override
  String get adminConfigListsTableValue => 'মান';

  @override
  String get adminConfigListsTitle => 'কনফিগ তালিকা';

  @override
  String get adminDashboardCostsOutstanding => 'সদস্যদের বকেয়া';

  @override
  String get adminDashboardCostsQuarterTotal => 'এই ত্রৈমাসিকের মোট';

  @override
  String get adminDashboardCostsTitle => 'এই ত্রৈমাসিকের সোসাইটি খরচ';

  @override
  String get adminDashboardCostsViewAll => 'সব খরচ দেখুন';

  @override
  String get adminDashboardDetailsLink => 'বিস্তারিত';

  @override
  String get adminDashboardErrorsLoadFailed => 'আবেদনের তালিকা লোড করা যায়নি।';

  @override
  String get adminDashboardFinanceBalance => 'বর্তমান ব্যালেন্স';

  @override
  String get adminDashboardFinanceMonthNet => 'এই মাসের নিট';

  @override
  String get adminDashboardFinancePending => 'অনুমোদনের অপেক্ষায়';

  @override
  String get adminDashboardFinanceTitle => 'ফান্ড স্বচ্ছতা';

  @override
  String get adminDashboardFinanceViewAll => 'সব দেখুন';

  @override
  String get adminDashboardNoPending => 'কোনো বিচারাধীন আবেদন নেই';

  @override
  String get adminDashboardPendingTitle => 'বিচারাধীন আবেদন';

  @override
  String get adminDashboardPropertiesUnit => 'টি';

  @override
  String get adminDashboardSubtitle =>
      'নতুন সদস্যপদের আবেদনসমূহ পর্যালোচনা করুন';

  @override
  String get adminDashboardTableHeadersApplicant => 'আবেদনকারী';

  @override
  String get adminDashboardTableHeadersMobile => 'মোবাইল';

  @override
  String get adminDashboardTableHeadersProperties => 'সম্পত্তি';

  @override
  String get adminDashboardTableHeadersReference => 'রেফারেন্স';

  @override
  String get adminDashboardTableHeadersSubmittedDate => 'জমার তারিখ';

  @override
  String get adminEventsCreate => 'নতুন অনুষ্ঠান';

  @override
  String get adminEventsCreateFirst => 'আপনার প্রথম অনুষ্ঠান তৈরি করুন';

  @override
  String get adminEventsDeleteModalConfirmLabel => 'মুছুন';

  @override
  String get adminEventsDeleteModalMessageSuffix =>
      'স্থায়ীভাবে মুছে ফেলা হবে।';

  @override
  String get adminEventsDeleteModalTitle => 'অনুষ্ঠান মুছুন';

  @override
  String get adminEventsEmptyHelper =>
      'প্রকাশিত ও খসড়া অনুষ্ঠান এখানে দেখা যাবে।';

  @override
  String get adminEventsErrorsDeleteFailed => 'অনুষ্ঠান মুছা যায়নি।';

  @override
  String get adminEventsErrorsLoadFailed => 'অনুষ্ঠান লোড করা যায়নি।';

  @override
  String get adminEventsErrorsSaveFailed => 'অনুষ্ঠান সংরক্ষণ করা যায়নি।';

  @override
  String get adminEventsFiltersAll => 'সব';

  @override
  String get adminEventsFiltersAllCategories => 'সব ক্যাটাগরি';

  @override
  String get adminEventsFiltersCategory => 'ক্যাটাগরি ফিল্টার';

  @override
  String get adminEventsFiltersDraft => 'খসড়া';

  @override
  String get adminEventsFiltersPublished => 'প্রকাশিত';

  @override
  String get adminEventsFormCategory => 'ক্যাটাগরি';

  @override
  String get adminEventsFormCreate => 'তৈরি করুন';

  @override
  String get adminEventsFormCreateTitle => 'নতুন অনুষ্ঠান';

  @override
  String get adminEventsFormDescription => 'বিবরণ';

  @override
  String get adminEventsFormEditTitle => 'অনুষ্ঠান সম্পাদনা';

  @override
  String get adminEventsFormEndAt => 'শেষ';

  @override
  String get adminEventsFormEndBeforeStart =>
      'শেষ সময় শুরুর সময়ের পরে হতে হবে।';

  @override
  String get adminEventsFormLocation => 'স্থান';

  @override
  String get adminEventsFormMembersOnly =>
      'শুধু সদস্যদের জন্য (সর্বসাধারণের তালিকায় দেখা যাবে না)';

  @override
  String get adminEventsFormNoCategory => 'ক্যাটাগরি নেই';

  @override
  String get adminEventsFormPublished => 'প্রকাশিত';

  @override
  String get adminEventsFormStartAt => 'শুরু';

  @override
  String get adminEventsFormStartAtRequired => 'শুরুর তারিখ ও সময় আবশ্যক।';

  @override
  String get adminEventsFormTitle => 'শিরোনাম';

  @override
  String get adminEventsMembersOnlyBadge => 'শুধু সদস্যদের জন্য';

  @override
  String get adminEventsNoItems => 'এখনো কোনো অনুষ্ঠান নেই।';

  @override
  String get adminEventsPublish => 'প্রকাশ করুন';

  @override
  String get adminEventsStatusDraft => 'খসড়া';

  @override
  String get adminEventsStatusPublished => 'প্রকাশিত';

  @override
  String get adminEventsSubtitle =>
      'পরিষদের অনুষ্ঠান তালিকা তৈরি ও প্রকাশ করুন';

  @override
  String get adminEventsTableCategory => 'ক্যাটাগরি';

  @override
  String get adminEventsTableLocation => 'স্থান';

  @override
  String get adminEventsTableStatus => 'অবস্থা';

  @override
  String get adminEventsTableTitle => 'শিরোনাম';

  @override
  String get adminEventsTableUntil => 'পর্যন্ত';

  @override
  String get adminEventsTableWhen => 'সময়';

  @override
  String get adminEventsTitle => 'অনুষ্ঠান';

  @override
  String get adminEventsUnpublish => 'প্রকাশ বন্ধ করুন';

  @override
  String get adminFeeSettingsActive => 'সক্রিয়';

  @override
  String get adminFeeSettingsAddVersion => 'নতুন ভার্সন যোগ করুন';

  @override
  String get adminFeeSettingsCalculatorFee => 'মাসিক ফি';

  @override
  String get adminFeeSettingsCalculatorLandSize => 'জমির আয়তন (ডেসিমেল)';

  @override
  String get adminFeeSettingsCalculatorTitle => 'ফি ক্যালকুলেটর';

  @override
  String get adminFeeSettingsConfirmMessage =>
      'বর্তমান ভার্সন আজ থেকে নিষ্ক্রিয় হবে। নতুন ভার্সন সংরক্ষণ করতে চান?';

  @override
  String get adminFeeSettingsConfirmTitle => 'নতুন ভার্সন নিশ্চিত করুন';

  @override
  String get adminFeeSettingsErrorsLoadFailed => 'ফি সেটিংস লোড করা যায়নি।';

  @override
  String get adminFeeSettingsErrorsLoadHistoryFailed =>
      'ফি সেটিংসের ইতিহাস লোড করা যায়নি।';

  @override
  String get adminFeeSettingsErrorsSaveFailed =>
      'নতুন ফি সেটিংস ভার্সন সংরক্ষণ করা যায়নি।';

  @override
  String get adminFeeSettingsFormAdditionalRate =>
      'প্রতি অতিরিক্ত ডেসিমেলে হার';

  @override
  String get adminFeeSettingsFormAdditionalRateHint =>
      'প্রতিটি অতিরিক্ত ডেসিমেল, অথবা ডেসিমেলের অংশ, সম্পূর্ণ হিসেবে চার্জ করা হয়।';

  @override
  String get adminFeeSettingsFormBaseAmount => 'বেস পরিমাণ';

  @override
  String get adminFeeSettingsFormBaseThreshold => 'বেস থ্রেশহোল্ড (ডেসিমেল)';

  @override
  String get adminFeeSettingsFormKey => 'ফি';

  @override
  String get adminFeeSettingsFormStartDate => 'শুরুর তারিখ (ঐচ্ছিক)';

  @override
  String get adminFeeSettingsFormStartDateHint => 'খালি রাখলে আজ থেকে কার্যকর';

  @override
  String get adminFeeSettingsFormSubmit => 'সংরক্ষণ করুন';

  @override
  String get adminFeeSettingsFormUnit => 'একক';

  @override
  String get adminFeeSettingsFormValue => 'মান';

  @override
  String get adminFeeSettingsHideHistory => 'ইতিহাস লুকান';

  @override
  String get adminFeeSettingsInactive => 'নিষ্ক্রিয়';

  @override
  String get adminFeeSettingsKeysAdmissionFee => 'ভর্তি ফি';

  @override
  String get adminFeeSettingsKeysMonthlySubscription => 'মাসিক চাঁদা হার';

  @override
  String get adminFeeSettingsKeysMonthlySubscriptionAdditionalRate =>
      'মাসিক চাঁদা অতিরিক্ত হার';

  @override
  String get adminFeeSettingsKeysMonthlySubscriptionBaseAmount =>
      'মাসিক চাঁদা বেস পরিমাণ';

  @override
  String get adminFeeSettingsKeysMonthlySubscriptionBaseThreshold =>
      'মাসিক চাঁদা বেস থ্রেশহোল্ড';

  @override
  String get adminFeeSettingsKeysPicnicAdditionalHeadFee =>
      'পিকনিক ফি - অতিরিক্ত প্রধান';

  @override
  String get adminFeeSettingsKeysPicnicHeadFee => 'পিকনিক ফি - সদস্য প্রধান';

  @override
  String get adminFeeSettingsNoSettings =>
      'এখনো কোনো ফি সেটিংস কনফিগার করা হয়নি।';

  @override
  String get adminFeeSettingsPicnicNotConfigured =>
      'পিকনিক ফি এখনও সম্পূর্ণভাবে নির্ধারিত হয়নি - উভয় পিকনিক রেটের সক্রিয় সংস্করণ না থাকলে সদস্যরা পেমেন্ট করতে পারবেন না।';

  @override
  String get adminFeeSettingsSubtitle =>
      'কার্যকর তারিখের পরিসরসহ ফি হারের সংস্করণ পরিচালনা করুন';

  @override
  String get adminFeeSettingsTableEndDate => 'শেষের তারিখ';

  @override
  String get adminFeeSettingsTableKey => 'কী';

  @override
  String get adminFeeSettingsTableStartDate => 'শুরুর তারিখ';

  @override
  String get adminFeeSettingsTableStatus => 'অবস্থা';

  @override
  String get adminFeeSettingsTableUnit => 'একক';

  @override
  String get adminFeeSettingsTableValue => 'মান';

  @override
  String adminFeeSettingsTieredSummary(
      Object base, Object rate, Object threshold) {
    return 'প্রথম $threshold ডেসিমেল পর্যন্ত $base টাকা + প্রতি অতিরিক্ত ডেসিমেলে $rate টাকা (আংশিক ডেসিমেলও পূর্ণ ধরা হয়)';
  }

  @override
  String get adminFeeSettingsTitle => 'ফি সেটিংস';

  @override
  String get adminFeeSettingsUnitsPercent => '%';

  @override
  String get adminFeeSettingsUnitsTaka => 'টাকা';

  @override
  String get adminFeeSettingsViewHistory => 'ইতিহাস দেখুন';

  @override
  String get adminFinanceManagementActionsApprove => 'অনুমোদন';

  @override
  String get adminFinanceManagementActionsReject => 'বাতিল';

  @override
  String get adminFinanceManagementActionsReverse => 'রিভার্সাল';

  @override
  String get adminFinanceManagementActionsSaveDraft => 'ড্রাফট সেভ';

  @override
  String get adminFinanceManagementActionsSavePending => 'সেভ ও অনুমোদনে পাঠান';

  @override
  String get adminFinanceManagementActionsSubmit => 'অনুমোদনে পাঠান';

  @override
  String get adminFinanceManagementCreate => 'নতুন লেনদেন';

  @override
  String get adminFinanceManagementCreateTitle => 'নতুন লেনদেন যোগ করুন';

  @override
  String get adminFinanceManagementEditTitle => 'লেনদেন সম্পাদনা';

  @override
  String get adminFinanceManagementErrorsActionFailed =>
      'কাজটি সম্পন্ন করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get adminFinanceManagementErrorsAmountRequired =>
      'শূন্যের বেশি পরিমাণ দিন।';

  @override
  String get adminFinanceManagementErrorsAttachmentFailed =>
      'সংযুক্তি আপলোড করা যায়নি।';

  @override
  String get adminFinanceManagementErrorsCategoryAddFailed =>
      'নতুন খাত যোগ করা যায়নি।';

  @override
  String get adminFinanceManagementErrorsCategoryRequired =>
      'খাত নির্বাচন করুন।';

  @override
  String get adminFinanceManagementErrorsDateRequired => 'তারিখ দিন।';

  @override
  String get adminFinanceManagementErrorsDescriptionRequired => 'বিবরণ দিন।';

  @override
  String get adminFinanceManagementErrorsLoadFailed =>
      'তালিকা লোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get adminFinanceManagementErrorsReasonRequired => 'কারণ লেখা আবশ্যক।';

  @override
  String get adminFinanceManagementErrorsSaveFailed =>
      'সেভ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get adminFinanceManagementFiltersAllCategories => 'সব খাত';

  @override
  String get adminFinanceManagementFiltersAllTypes => 'সব ধরন';

  @override
  String get adminFinanceManagementFiltersCategory => 'খাত';

  @override
  String get adminFinanceManagementFiltersReset => 'রিসেট';

  @override
  String get adminFinanceManagementFiltersSearch => 'বিবরণ/রেফারেন্স খুঁজুন…';

  @override
  String get adminFinanceManagementFiltersType => 'ধরন';

  @override
  String get adminFinanceManagementFormAddCategory =>
      'নতুন খাত যোগ করুন (Enter)';

  @override
  String get adminFinanceManagementFormAmount => 'পরিমাণ';

  @override
  String get adminFinanceManagementFormAttachment => 'সংযুক্তি (ছবি/PDF)';

  @override
  String get adminFinanceManagementFormCategory => 'খাত';

  @override
  String get adminFinanceManagementFormCategoryNoMatch =>
      'মিলে যাওয়া কোনো খাত নেই';

  @override
  String get adminFinanceManagementFormCategorySearch => 'খাত খুঁজুন বা লিখুন…';

  @override
  String get adminFinanceManagementFormDate => 'তারিখ';

  @override
  String get adminFinanceManagementFormDescription => 'বিবরণ';

  @override
  String get adminFinanceManagementFormInternalNotes => 'অভ্যন্তরীণ নোট';

  @override
  String get adminFinanceManagementFormInternalNotesHint =>
      'মেম্বাররা এই নোট দেখতে পাবে না।';

  @override
  String get adminFinanceManagementFormReference => 'রেফারেন্স নম্বর';

  @override
  String get adminFinanceManagementFormReferenceAuto =>
      'খালি রাখলে স্বয়ংক্রিয়ভাবে তৈরি হবে';

  @override
  String get adminFinanceManagementFormReferenceHint => 'FT-…';

  @override
  String get adminFinanceManagementFormType => 'ধরন';

  @override
  String get adminFinanceManagementLedgerAmount => 'পরিমাণ';

  @override
  String get adminFinanceManagementLedgerApprovedBy => 'অনুমোদনকারী';

  @override
  String get adminFinanceManagementLedgerCategory => 'খাত';

  @override
  String adminFinanceManagementLedgerCount(Object count) {
    return 'মোট $countটি লেনদেন';
  }

  @override
  String get adminFinanceManagementLedgerCreatedBy => 'তৈরি করেছেন';

  @override
  String get adminFinanceManagementLedgerDate => 'তারিখ';

  @override
  String get adminFinanceManagementLedgerDescription => 'বিবরণ';

  @override
  String get adminFinanceManagementLedgerEditWindowClosed =>
      'অনুমোদনের ৭ দিন পর সরাসরি সম্পাদনা বন্ধ — সংশোধনের জন্য রিভার্সাল তৈরি করুন।';

  @override
  String get adminFinanceManagementLedgerEmpty => 'কোনো লেনদেন নেই';

  @override
  String get adminFinanceManagementLedgerEmptyHint =>
      '\'নতুন লেনদেন\' বাটন থেকে প্রথম এন্ট্রি যোগ করুন।';

  @override
  String get adminFinanceManagementLedgerInternalNotes =>
      'অভ্যন্তরীণ নোট (শুধু কমিটি দেখে)';

  @override
  String get adminFinanceManagementLedgerLinkedPayment => 'সংযুক্ত পেমেন্ট';

  @override
  String adminFinanceManagementLedgerPage(Object page, Object total) {
    return 'পৃষ্ঠা $page / $total';
  }

  @override
  String get adminFinanceManagementLedgerReference => 'রেফারেন্স';

  @override
  String get adminFinanceManagementLedgerRejectionReason => 'বাতিলের কারণ';

  @override
  String get adminFinanceManagementLedgerReversalOf =>
      'রিভার্সাল হয়েছে লেনদেন';

  @override
  String get adminFinanceManagementLedgerStatus => 'অবস্থা';

  @override
  String get adminFinanceManagementLedgerType => 'ধরন';

  @override
  String get adminFinanceManagementLedgerViewAttachment => 'সংযুক্তি দেখুন';

  @override
  String get adminFinanceManagementModalsApproveConfirm => 'অনুমোদন করুন';

  @override
  String get adminFinanceManagementModalsApproveTitle => 'লেনদেন অনুমোদন';

  @override
  String get adminFinanceManagementModalsApproveTwoPerson =>
      'যিনি এন্ট্রি তৈরি করেছেন তিনি নিজে অনুমোদন করতে পারবেন না — অন্য কমিটি সদস্য অনুমোদন করবেন।';

  @override
  String get adminFinanceManagementModalsDeleteConfirm => 'মুছুন';

  @override
  String get adminFinanceManagementModalsDeleteReason =>
      'মুছে ফেলার কারণ (অডিটে থাকবে)';

  @override
  String get adminFinanceManagementModalsDeleteTitle => 'লেনদেন মুছুন';

  @override
  String get adminFinanceManagementModalsRejectConfirm => 'বাতিল করুন';

  @override
  String get adminFinanceManagementModalsRejectReason => 'বাতিলের কারণ';

  @override
  String get adminFinanceManagementModalsRejectTitle => 'লেনদেন বাতিল';

  @override
  String get adminFinanceManagementModalsReverseConfirm =>
      'রিভার্সাল তৈরি করুন';

  @override
  String get adminFinanceManagementModalsReverseReason => 'সংশোধনের কারণ';

  @override
  String get adminFinanceManagementModalsReverseTitle =>
      'রিভার্সাল (সংশোধন এন্ট্রি)';

  @override
  String get adminFinanceManagementNoticeAll => 'সর্বমোট';

  @override
  String get adminFinanceManagementNoticeDone => 'নোটিশ প্রকাশিত হয়েছে ✓';

  @override
  String get adminFinanceManagementNoticeMonth => 'এই মাস';

  @override
  String get adminFinanceManagementNoticePeriod => 'রিপোর্টের সময়কাল';

  @override
  String get adminFinanceManagementNoticePublish => 'রিপোর্ট নোটিশ প্রকাশ';

  @override
  String get adminFinanceManagementNoticeYear => 'এই বছর';

  @override
  String get adminFinanceManagementOverviewBalance => 'বর্তমান ব্যালেন্স';

  @override
  String get adminFinanceManagementOverviewMonthNet => 'এই মাসের নিট';

  @override
  String get adminFinanceManagementOverviewNoRecent => 'এখনো কোনো লেনদেন নেই।';

  @override
  String get adminFinanceManagementOverviewPending => 'অনুমোদনের অপেক্ষায়';

  @override
  String get adminFinanceManagementOverviewRecent => 'সর্বশেষ ৫টি লেনদেন';

  @override
  String get adminFinanceManagementPaymentLinkAllSources => 'সব সোর্স';

  @override
  String adminFinanceManagementPaymentLinkAlreadyLinked(
      Object id, Object source) {
    return 'বর্তমানে সংযুক্ত: $source #$id';
  }

  @override
  String get adminFinanceManagementPaymentLinkEmpty =>
      'এই ফিল্টারে লিংক করার মতো কোনো পেমেন্ট নেই।';

  @override
  String get adminFinanceManagementPaymentLinkSearchPlaceholder =>
      'মেম্বারের নাম খুঁজুন…';

  @override
  String get adminFinanceManagementPaymentLinkTitle =>
      'পেমেন্ট রেকর্ডের সাথে লিংক করুন (ডাবল এন্ট্রি এড়াতে)';

  @override
  String get adminFinanceManagementSourceCostShare => 'খরচের কিস্তি';

  @override
  String get adminFinanceManagementSourceInstallment => 'মাসিক চাঁদা';

  @override
  String get adminFinanceManagementSourcePicnicPayment => 'পিকনিক ফি';

  @override
  String get adminFinanceManagementStatusAll => 'সব';

  @override
  String get adminFinanceManagementStatusApproved => 'অনুমোদিত';

  @override
  String get adminFinanceManagementStatusDraft => 'ড্রাফট';

  @override
  String get adminFinanceManagementStatusPending => 'অপেক্ষমাণ';

  @override
  String get adminFinanceManagementStatusRejected => 'বাতিল';

  @override
  String get adminFinanceManagementSubtitle =>
      'ফান্ডের আয়-ব্যয়ের লেনদেন যোগ, সম্পাদনা ও অনুমোদন করুন';

  @override
  String get adminFinanceManagementTitle => 'আর্থিক ব্যবস্থাপনা';

  @override
  String get adminFinanceManagementTypeExpense => 'ব্যয়';

  @override
  String get adminFinanceManagementTypeIncome => 'আয়';

  @override
  String get adminInstallmentsErrorsLoadInstallmentsFailed =>
      'কিস্তির তথ্য লোড করা যায়নি।';

  @override
  String get adminInstallmentsErrorsLoadMembersFailed =>
      'সদস্য তালিকা লোড করা যায়নি।';

  @override
  String get adminInstallmentsErrorsMarkPaidFailed =>
      'কিস্তি পরিশোধিত হিসেবে চিহ্নিত করা যায়নি।';

  @override
  String get adminInstallmentsMarkPaidButton => 'পরিশোধিত হিসেবে চিহ্নিত করুন';

  @override
  String get adminInstallmentsMonthsApril => 'এপ্রিল';

  @override
  String get adminInstallmentsMonthsAugust => 'আগস্ট';

  @override
  String get adminInstallmentsMonthsDecember => 'ডিসেম্বর';

  @override
  String get adminInstallmentsMonthsFebruary => 'ফেব্রুয়ারি';

  @override
  String get adminInstallmentsMonthsJanuary => 'জানুয়ারি';

  @override
  String get adminInstallmentsMonthsJuly => 'জুলাই';

  @override
  String get adminInstallmentsMonthsJune => 'জুন';

  @override
  String get adminInstallmentsMonthsMarch => 'মার্চ';

  @override
  String get adminInstallmentsMonthsMay => 'মে';

  @override
  String get adminInstallmentsMonthsNovember => 'নভেম্বর';

  @override
  String get adminInstallmentsMonthsOctober => 'অক্টোবর';

  @override
  String get adminInstallmentsMonthsSeptember => 'সেপ্টেম্বর';

  @override
  String get adminInstallmentsNoInstallments => 'এই সদস্যের কোনো কিস্তি নেই।';

  @override
  String get adminInstallmentsNoMembers => 'কোনো সদস্য পাওয়া যায়নি।';

  @override
  String get adminInstallmentsPaid => 'পরিশোধিত';

  @override
  String get adminInstallmentsPermissionRequired => 'অনুমতি প্রয়োজন';

  @override
  String get adminInstallmentsSelectMember => 'সদস্য নির্বাচন করুন।';

  @override
  String get adminInstallmentsSubtitle =>
      'সদস্য নির্বাচন করে মাসিক কিস্তির অবস্থা দেখুন ও হালনাগাদ করুন';

  @override
  String get adminInstallmentsTitle => 'চাঁদা ব্যবস্থাপনা';

  @override
  String get adminMemberDetailClose => 'বন্ধ করুন';

  @override
  String get adminMemberDetailDocsNone => 'কোনো ডকুমেন্ট আপলোড করা হয়নি।';

  @override
  String get adminMemberDetailDue => 'বকেয়া';

  @override
  String get adminMemberDetailFAdmissionFee => 'ভর্তি ফি';

  @override
  String get adminMemberDetailFAmount => 'পরিমাণ';

  @override
  String get adminMemberDetailFApprovedBy => 'পর্যালোচনাকারী';

  @override
  String get adminMemberDetailFContribution => 'চাঁদার অবস্থা';

  @override
  String get adminMemberDetailFCreated => 'তৈরি';

  @override
  String get adminMemberDetailFDag => 'দাগ নং (সিএস / আরএস)';

  @override
  String get adminMemberDetailFDate => 'তারিখ';

  @override
  String get adminMemberDetailFDob => 'জন্ম তারিখ';

  @override
  String get adminMemberDetailFDueTotal => 'মোট বকেয়া';

  @override
  String get adminMemberDetailFEmail => 'ইমেইল';

  @override
  String get adminMemberDetailFExtraHeads => 'অতিরিক্ত জন';

  @override
  String get adminMemberDetailFFatherOrHusband => 'পিতা/স্বামীর নাম';

  @override
  String get adminMemberDetailFGender => 'লিঙ্গ';

  @override
  String get adminMemberDetailFHolding => 'হোল্ডিং নং';

  @override
  String get adminMemberDetailFJoined => 'আবেদনের তারিখ';

  @override
  String get adminMemberDetailFKhatian => 'খতিয়ান নং';

  @override
  String get adminMemberDetailFLandSize => 'জমির পরিমাণ (শতাংশ)';

  @override
  String get adminMemberDetailFLastModifiedBy => 'সর্বশেষ পরিবর্তনকারী';

  @override
  String get adminMemberDetailFMemberId => 'সদস্য আইডি';

  @override
  String get adminMemberDetailFMobile => 'মোবাইল';

  @override
  String get adminMemberDetailFMonth => 'মাস';

  @override
  String get adminMemberDetailFMonthly => 'মাসিক চাঁদা';

  @override
  String get adminMemberDetailFMother => 'মাতার নাম';

  @override
  String get adminMemberDetailFMyShare => 'আমার অংশ (শতাংশ)';

  @override
  String get adminMemberDetailFName => 'পূর্ণ নাম';

  @override
  String get adminMemberDetailFNid => 'এনআইডি / জন্মনিবন্ধন';

  @override
  String get adminMemberDetailFNomineeMobile => 'মোবাইল';

  @override
  String get adminMemberDetailFNomineeRelation => 'সম্পর্ক';

  @override
  String get adminMemberDetailFOccupation => 'পেশা';

  @override
  String get adminMemberDetailFOwnership => 'মালিকানা';

  @override
  String get adminMemberDetailFPaidOn => 'পরিশোধের তারিখ';

  @override
  String get adminMemberDetailFPaidTotal => 'মোট পরিশোধিত';

  @override
  String get adminMemberDetailFPaymentMethod => 'পরিশোধের মাধ্যম';

  @override
  String get adminMemberDetailFPermanentAddress => 'স্থায়ী ঠিকানা';

  @override
  String get adminMemberDetailFPresentAddress => 'বর্তমান ঠিকানা';

  @override
  String get adminMemberDetailFReceiptNo => 'রশিদ নং';

  @override
  String get adminMemberDetailFRejectionReason => 'বাতিলের কারণ';

  @override
  String get adminMemberDetailFReviewedAt => 'পর্যালোচনার তারিখ';

  @override
  String get adminMemberDetailFStatus => 'অবস্থা';

  @override
  String get adminMemberDetailFTotal => 'মোট';

  @override
  String get adminMemberDetailFUpdated => 'সর্বশেষ হালনাগাদ';

  @override
  String get adminMemberDetailFUrgentContact => 'জরুরি যোগাযোগ';

  @override
  String get adminMemberDetailFullyPaid => 'সম্পূর্ণ পরিশোধিত';

  @override
  String get adminMemberDetailLoadFailed => 'সদস্যের তথ্য লোড করা যায়নি।';

  @override
  String get adminMemberDetailMemberPhoto => 'সদস্যের ছবি';

  @override
  String get adminMemberDetailMonthsOverdue => 'মাস বকেয়া';

  @override
  String get adminMemberDetailNoAudit => 'কোনো অডিট এন্ট্রি নেই।';

  @override
  String get adminMemberDetailNoInstallments => 'কোনো কিস্তি নেই।';

  @override
  String get adminMemberDetailNoNominees => 'কোনো মনোনীত ব্যক্তি নেই।';

  @override
  String get adminMemberDetailNoPicnic => 'কোনো পিকনিক পরিশোধ নেই।';

  @override
  String get adminMemberDetailNoProperties => 'কোনো সম্পত্তি নেই।';

  @override
  String get adminMemberDetailOpenInstallments => 'কিস্তি ব্যবস্থাপনা';

  @override
  String get adminMemberDetailPaid => 'পরিশোধিত';

  @override
  String get adminMemberDetailReceiptPhoto => 'পেমেন্ট রশিদ';

  @override
  String get adminMemberDetailRetry => 'আবার চেষ্টা করুন';

  @override
  String get adminMemberDetailSectionsAudit => 'অডিট ট্রেইল';

  @override
  String get adminMemberDetailSectionsContact => 'যোগাযোগ';

  @override
  String get adminMemberDetailSectionsDocuments => 'ডকুমেন্ট';

  @override
  String get adminMemberDetailSectionsFees => 'ফি ও চাঁদা';

  @override
  String get adminMemberDetailSectionsIdentity => 'পরিচয়';

  @override
  String get adminMemberDetailSectionsInstallments => 'কিস্তি';

  @override
  String get adminMemberDetailSectionsMembership => 'সদস্যপদের অবস্থা';

  @override
  String get adminMemberDetailSectionsNominees => 'মনোনীত ব্যক্তি';

  @override
  String get adminMemberDetailSectionsPicnic => 'পিকনিক পরিশোধ';

  @override
  String get adminMemberDetailSectionsProperty => 'সম্পত্তি';

  @override
  String get adminMemberDetailSignature => 'স্বাক্ষর';

  @override
  String get adminMemberDetailTitle => 'সদস্যের বিস্তারিত';

  @override
  String get adminMembersListDeleteMemberTitle => 'সদস্য মুছে ফেলুন';

  @override
  String get adminMembersListDeleteModalConfirmLabel => 'মুছে ফেলুন';

  @override
  String get adminMembersListDeleteModalMessageSuffix =>
      'এর সদস্য রেকর্ড স্থায়ীভাবে মুছে যাবে। এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।';

  @override
  String get adminMembersListDeleteModalTitle => 'রেকর্ড মুছে ফেলুন?';

  @override
  String get adminMembersListErrorsDeleteFailed => 'সদস্য মুছে ফেলা যায়নি।';

  @override
  String get adminMembersListErrorsLoadFailed => 'সদস্য তালিকা লোড করা যায়নি।';

  @override
  String get adminMembersListErrorsResetFailed =>
      'পাসওয়ার্ড রিসেট করা যায়নি।';

  @override
  String get adminMembersListFullyPaid => 'সম্পূর্ণ পরিশোধিত';

  @override
  String get adminMembersListMonthsOverdue => 'মাস বকেয়া';

  @override
  String get adminMembersListNoMembers => 'কোনো সদস্য পাওয়া যায়নি।';

  @override
  String get adminMembersListResetModalConfirmLabel => 'রিসেট ও ইমেইল';

  @override
  String get adminMembersListResetModalMessageSuffix =>
      'এর লগইন পাসওয়ার্ড রিসেট করা হবে এবং নতুন পাসওয়ার্ড সদস্যের নিবন্ধিত ইমেইলে পাঠানো হবে।';

  @override
  String adminMembersListResetModalSuccessMessage(Object name) {
    return 'পাসওয়ার্ড সফলভাবে রিসেট হয়েছে। নতুন পাসওয়ার্ড $name-এর নিবন্ধিত ইমেইলে পাঠানো হয়েছে।';
  }

  @override
  String get adminMembersListResetModalSuccessNoEmail =>
      'পাসওয়ার্ড রিসেট সফল হয়েছে, তবে ইমেইল পাঠানো যায়নি। অনুগ্রহ করে সরাসরি সদস্যকে নতুন পাসওয়ার্ড জানিয়ে দিন।';

  @override
  String get adminMembersListResetModalTitle => 'পাসওয়ার্ড রিসেট করবেন?';

  @override
  String get adminMembersListResetPasswordTitle =>
      'পাসওয়ার্ড রিসেট করে নতুন তথ্য ইমেইল করুন';

  @override
  String get adminMembersListSubtitle => 'সদস্যদের তথ্য ও চাঁদার অবস্থা দেখুন';

  @override
  String get adminMembersListTableHeadersActions => 'কার্যক্রম';

  @override
  String get adminMembersListTableHeadersContributionStatus => 'চাঁদার অবস্থা';

  @override
  String get adminMembersListTableHeadersMemberId => 'সদস্য আইডি';

  @override
  String get adminMembersListTableHeadersMobile => 'মোবাইল';

  @override
  String get adminMembersListTableHeadersName => 'নাম';

  @override
  String get adminMembersListTableHeadersStatus => 'অবস্থা';

  @override
  String get adminMembersListTitle => 'সকল সদস্য';

  @override
  String get adminMembersListViewContributionsTitle => 'চাঁদার অবস্থা দেখুন';

  @override
  String get adminMembersListViewDetailsTitle => 'সদস্যের বিস্তারিত দেখুন';

  @override
  String get adminNoticesCreate => 'নতুন নোটিশ';

  @override
  String get adminNoticesCreateFirst => 'আপনার প্রথম নোটিশ তৈরি করুন';

  @override
  String get adminNoticesDeleteModalConfirmLabel => 'মুছুন';

  @override
  String get adminNoticesDeleteModalMessageSuffix =>
      'স্থায়ীভাবে মুছে ফেলা হবে।';

  @override
  String get adminNoticesDeleteModalTitle => 'নোটিশ মুছুন';

  @override
  String get adminNoticesEmptyHelper =>
      'প্রকাশিত ও খসড়া নোটিশ এখানে দেখা যাবে।';

  @override
  String get adminNoticesErrorsDeleteFailed => 'নোটিশ মুছা যায়নি।';

  @override
  String get adminNoticesErrorsLoadFailed => 'নোটিশ লোড করা যায়নি।';

  @override
  String get adminNoticesErrorsSaveFailed => 'নোটিশ সংরক্ষণ করা যায়নি।';

  @override
  String get adminNoticesFiltersAll => 'সব';

  @override
  String get adminNoticesFiltersAllCategories => 'সব ক্যাটাগরি';

  @override
  String get adminNoticesFiltersCategory => 'ক্যাটাগরি ফিল্টার';

  @override
  String get adminNoticesFiltersDraft => 'খসড়া';

  @override
  String get adminNoticesFiltersPublished => 'প্রকাশিত';

  @override
  String get adminNoticesFormBody => 'বিস্তারিত';

  @override
  String get adminNoticesFormCategory => 'ক্যাটাগরি';

  @override
  String get adminNoticesFormCreate => 'তৈরি করুন';

  @override
  String get adminNoticesFormCreateTitle => 'নতুন নোটিশ';

  @override
  String get adminNoticesFormEditTitle => 'নোটিশ সম্পাদনা';

  @override
  String get adminNoticesFormMembersOnly =>
      'শুধু সদস্যদের জন্য (সর্বসাধারণের তালিকায় দেখা যাবে না)';

  @override
  String get adminNoticesFormNoCategory => 'ক্যাটাগরি নেই';

  @override
  String get adminNoticesFormPublishAt => 'প্রকাশের সময়';

  @override
  String get adminNoticesFormPublishAtHint =>
      'ঐচ্ছিক। নির্ধারিত সময় না আসা পর্যন্ত সময়নির্ধারিত নোটিশ লুকানো থাকে।';

  @override
  String get adminNoticesFormPublishAtPast =>
      'প্রকাশের তারিখ/সময় অতীতে হতে পারবে না।';

  @override
  String get adminNoticesFormPublished => 'প্রকাশিত';

  @override
  String get adminNoticesFormTitle => 'শিরোনাম';

  @override
  String get adminNoticesMembersOnlyBadge => 'শুধু সদস্যদের জন্য';

  @override
  String get adminNoticesNoItems => 'এখনো কোনো নোটিশ নেই।';

  @override
  String get adminNoticesPublish => 'প্রকাশ করুন';

  @override
  String get adminNoticesStatusDraft => 'খসড়া';

  @override
  String get adminNoticesStatusPublished => 'প্রকাশিত';

  @override
  String get adminNoticesStatusScheduled => 'সময়নির্ধারিত';

  @override
  String get adminNoticesSubtitle =>
      'সদস্য ও দর্শকদের জন্য নোটিশ লিখে প্রকাশ করুন';

  @override
  String get adminNoticesTableCategory => 'ক্যাটাগরি';

  @override
  String get adminNoticesTablePublishAt => 'প্রকাশের সময়';

  @override
  String get adminNoticesTableStatus => 'অবস্থা';

  @override
  String get adminNoticesTableTitle => 'শিরোনাম';

  @override
  String get adminNoticesTitle => 'নোটিশ';

  @override
  String get adminNoticesUnpublish => 'প্রকাশ বন্ধ করুন';

  @override
  String get adminPaymentVerificationsActionError =>
      'কাজটি ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get adminPaymentVerificationsApprove => 'অনুমোদন';

  @override
  String get adminPaymentVerificationsCancel => 'বাতিল করুন';

  @override
  String get adminPaymentVerificationsEmpty => 'কিছু নেই — সব যাচাই সম্পন্ন।';

  @override
  String get adminPaymentVerificationsLoadError =>
      'পরিশোধ তালিকা লোড করা যায়নি।';

  @override
  String get adminPaymentVerificationsMethod => 'মাধ্যম';

  @override
  String get adminPaymentVerificationsPaidOn => 'পরিশোধের তারিখ';

  @override
  String get adminPaymentVerificationsReason => 'সদস্যকে দেখানো কারণ';

  @override
  String get adminPaymentVerificationsReasonPlaceholder =>
      'যেমন bKash স্টেটমেন্টে ট্রানজেকশন আইডি পাওয়া যায়নি';

  @override
  String get adminPaymentVerificationsReference => 'ট্রানজেকশন আইডি';

  @override
  String get adminPaymentVerificationsReject => 'বাতিল';

  @override
  String get adminPaymentVerificationsRejectTitle => 'পরিশোধ বাতিল';

  @override
  String get adminPaymentVerificationsSender => 'প্রেরক';

  @override
  String get adminPaymentVerificationsSubtitle =>
      'সদস্যদের জমা দেওয়া চাঁদা পরিশোধ অ্যাকাউন্ট স্টেটমেন্টের সাথে মিলিয়ে যাচাই করুন।';

  @override
  String get adminPaymentVerificationsTitle => 'পেমেন্ট যাচাই';

  @override
  String get adminPaymentVerificationsViewProof => 'রসিদ দেখুন';

  @override
  String get adminPicnicPaymentsApply => 'প্রয়োগ করুন';

  @override
  String get adminPicnicPaymentsCount => 'পরিশোধ সংখ্যা';

  @override
  String get adminPicnicPaymentsDateColumn => 'তারিখ';

  @override
  String get adminPicnicPaymentsDateFrom => 'থেকে';

  @override
  String get adminPicnicPaymentsDateRange => 'তারিখের পরিসর';

  @override
  String get adminPicnicPaymentsDateTo => 'পর্যন্ত';

  @override
  String get adminPicnicPaymentsEmptyState =>
      'নির্বাচিত ফিল্টারে কোনো পিকনিক পরিশোধ পাওয়া যায়নি।';

  @override
  String get adminPicnicPaymentsHeadsColumn => 'অতিরিক্ত জন';

  @override
  String get adminPicnicPaymentsLoadError => 'পিকনিক পরিশোধ লোড করা যায়নি।';

  @override
  String get adminPicnicPaymentsMemberColumn => 'সদস্য';

  @override
  String get adminPicnicPaymentsMemberFilter => 'সদস্য আইডি (ঐচ্ছিক)';

  @override
  String get adminPicnicPaymentsMethodColumn => 'পদ্ধতি';

  @override
  String get adminPicnicPaymentsReceiptColumn => 'রশিদ নম্বর';

  @override
  String get adminPicnicPaymentsReset => 'রিসেট';

  @override
  String get adminPicnicPaymentsSubtitle =>
      'ফিল্টার ও মোট সহ সকল সদস্যের পিকনিক পরিশোধ';

  @override
  String get adminPicnicPaymentsTitle => 'পিকনিক পরিশোধ';

  @override
  String get adminPicnicPaymentsTotalCollected => 'মোট আদায়';

  @override
  String get adminPicnicPaymentsTotalColumn => 'মোট';

  @override
  String get adminPropertyRequestsActionsAdd => 'সংযোজন';

  @override
  String get adminPropertyRequestsActionsDelete => 'মুছে ফেলা';

  @override
  String get adminPropertyRequestsActionsEdit => 'সংশোধন';

  @override
  String get adminPropertyRequestsApproveButton => 'অনুমোদন';

  @override
  String get adminPropertyRequestsApproveModalConfirmLabel => 'অনুমোদন করুন';

  @override
  String get adminPropertyRequestsApproveModalMessageSuffix =>
      'সদস্যের তথ্যে প্রয়োগ করা হবে।';

  @override
  String get adminPropertyRequestsApproveModalTitle => 'অনুরোধ অনুমোদন';

  @override
  String get adminPropertyRequestsCancelButton => 'বাতিল';

  @override
  String get adminPropertyRequestsCancelModalConfirmLabel =>
      'অনুরোধ বাতিল করুন';

  @override
  String get adminPropertyRequestsCancelModalMessageSuffix => 'বাতিল করা হবে।';

  @override
  String get adminPropertyRequestsCancelModalPlaceholder =>
      'বাতিলের কারণ লিখুন...';

  @override
  String get adminPropertyRequestsCancelModalTitle => 'অনুরোধ বাতিল';

  @override
  String get adminPropertyRequestsCancelReasonLabel => 'বাতিলের কারণ';

  @override
  String get adminPropertyRequestsDeleteRequestNote =>
      'সদস্য এই সম্পত্তিটি মুছে ফেলার অনুরোধ করেছেন।';

  @override
  String get adminPropertyRequestsErrorsApproveFailed =>
      'অনুরোধ অনুমোদন করা যায়নি।';

  @override
  String get adminPropertyRequestsErrorsCancelFailed =>
      'অনুরোধ বাতিল করা যায়নি।';

  @override
  String get adminPropertyRequestsErrorsLoadFailed => 'তালিকা লোড করা যায়নি।';

  @override
  String get adminPropertyRequestsErrorsReasonRequired =>
      'বাতিল করতে কারণ দিতে হবে।';

  @override
  String get adminPropertyRequestsNoRequests =>
      'কোনো সম্পত্তি সংক্রান্ত অনুরোধ পাওয়া যায়নি';

  @override
  String get adminPropertyRequestsStatusLabelsAll => 'সব';

  @override
  String get adminPropertyRequestsStatusLabelsApproved => 'অনুমোদিত';

  @override
  String get adminPropertyRequestsStatusLabelsCancelled => 'বাতিল';

  @override
  String get adminPropertyRequestsStatusLabelsPending => 'অপেক্ষমাণ';

  @override
  String get adminPropertyRequestsSubtitle =>
      'সদস্যদের সম্পত্তি সংযোজন, সংশোধন বা মুছে ফেলার অনুরোধ পর্যালোচনা করুন';

  @override
  String get adminPropertyRequestsTableHeadersAction => 'কার্য';

  @override
  String get adminPropertyRequestsTableHeadersActions => 'কার্যক্রম';

  @override
  String get adminPropertyRequestsTableHeadersDate => 'জমাদান';

  @override
  String get adminPropertyRequestsTableHeadersMember => 'সদস্য';

  @override
  String get adminPropertyRequestsTableHeadersProperty => 'সম্পত্তি';

  @override
  String get adminPropertyRequestsTableHeadersReference => 'রেফারেন্স';

  @override
  String get adminPropertyRequestsTableHeadersStatus => 'অবস্থা';

  @override
  String get adminPropertyRequestsTitle => 'সম্পত্তি সংক্রান্ত অনুরোধ';

  @override
  String get adminRoadmapAdd => 'নতুন পরিকল্পনা';

  @override
  String get adminRoadmapAddHere => 'যোগ করুন';

  @override
  String get adminRoadmapArchiveAll =>
      'সব পরিকল্পনা আর্কাইভ করে নতুন চক্র শুরু করুন';

  @override
  String get adminRoadmapArchiveButton => 'চক্র আর্কাইভ';

  @override
  String get adminRoadmapArchiveConfirm => 'আর্কাইভ করুন';

  @override
  String adminRoadmapArchiveCycleSummary(Object done, Object total) {
    return '$totalটির মধ্যে $doneটি সম্পন্ন';
  }

  @override
  String adminRoadmapArchiveDone(Object n) {
    return '$nটি পরিকল্পনা আর্কাইভ করা হয়েছে।';
  }

  @override
  String get adminRoadmapArchiveEmpty => 'এখনো কোনো চক্র আর্কাইভ করা হয়নি।';

  @override
  String get adminRoadmapArchiveHistory => 'আর্কাইভ করা চক্র';

  @override
  String get adminRoadmapArchiveMessage =>
      'আর্কাইভ করা পরিকল্পনা সদস্যদের পেজ থেকে সরে যাবে, তবে ইতিহাসে সংরক্ষিত থাকবে।';

  @override
  String get adminRoadmapArchiveOnlyDone =>
      'শুধু সম্পন্ন পরিকল্পনা আর্কাইভ করুন (বাকিগুলো নতুন চক্রে থাকবে)';

  @override
  String get adminRoadmapArchiveTitle => 'পরিকল্পনা চক্র আর্কাইভ করুন';

  @override
  String get adminRoadmapDeleteTitle => 'এই পরিকল্পনাটি মুছবেন?';

  @override
  String get adminRoadmapErrorsGeneric =>
      'কাজটি সম্পন্ন করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get adminRoadmapErrorsNoteTooLong =>
      'নোট সর্বোচ্চ ১০০০ অক্ষর হতে পারে।';

  @override
  String get adminRoadmapErrorsOwnerTooLong =>
      'দায়িত্বপ্রাপ্তের নাম সর্বোচ্চ ১২০ অক্ষর হতে পারে।';

  @override
  String get adminRoadmapErrorsTextRequired => 'পরিকল্পনার বিবরণ লিখুন।';

  @override
  String get adminRoadmapErrorsTextTooLong =>
      'পরিকল্পনার বিবরণ সর্বোচ্চ ৫০০ অক্ষর হতে পারে।';

  @override
  String get adminRoadmapErrorsTimeframe => 'একটি সময়সীমা নির্বাচন করুন।';

  @override
  String get adminRoadmapFormCreateTitle => 'নতুন পরিকল্পনা যোগ করুন';

  @override
  String get adminRoadmapFormEditTitle => 'পরিকল্পনা সম্পাদনা';

  @override
  String get adminRoadmapFormMoveHint =>
      'সংরক্ষণ করলে পরিকল্পনাটি নির্বাচিত সময়সীমার শেষে চলে যাবে।';

  @override
  String get adminRoadmapFormNote => 'হালনাগাদ / নোট (ঐচ্ছিক)';

  @override
  String get adminRoadmapFormNotePlaceholder =>
      'যেমন: বালু ভরাট শুরু হয়েছে, আশা করা হচ্ছে নভেম্বরের মধ্যে শেষ হবে';

  @override
  String get adminRoadmapFormNotify => 'সদস্যদের নোটিশ পাঠান';

  @override
  String get adminRoadmapFormOwner => 'দায়িত্বপ্রাপ্ত (ঐচ্ছিক)';

  @override
  String get adminRoadmapFormOwnerPlaceholder => 'যেমন: সাধারণ সম্পাদক';

  @override
  String get adminRoadmapFormStatus => 'অবস্থা';

  @override
  String get adminRoadmapFormTargetDate => 'লক্ষ্য তারিখ (ঐচ্ছিক)';

  @override
  String get adminRoadmapFormText => 'পরিকল্পনা';

  @override
  String get adminRoadmapFormTimeframe => 'সময়সীমা';

  @override
  String get adminRoadmapMoveDown => 'নিচে সরান';

  @override
  String get adminRoadmapMoveUp => 'উপরে সরান';

  @override
  String get adminRoadmapNotifyOnDone => 'সম্পন্ন হলে সদস্যদের নোটিশ পাঠান';

  @override
  String adminRoadmapOverall(Object done, Object total) {
    return 'মোট $totalটির মধ্যে $doneটি সম্পন্ন';
  }

  @override
  String get adminRoadmapStatusAria => 'অবস্থা পরিবর্তন';

  @override
  String get adminRoadmapSubtitle =>
      'স্বল্প, মধ্য ও দীর্ঘমেয়াদি পরিকল্পনা যোগ, সম্পাদনা ও অগ্রগতি হালনাগাদ করুন। প্রতিটি পরিবর্তন অডিট লগে সংরক্ষিত হয়।';

  @override
  String get adminRoadmapTitle => 'পরিকল্পনা ব্যবস্থাপনা';

  @override
  String get adminRoadmapViewAsMember => 'সদস্যদের ভিউ';

  @override
  String get adminRoleManagementAllPermissionsAlways => 'সকল অনুমতি — সর্বদা';

  @override
  String get adminRoleManagementCreateAdminEmailLabel => 'ইমেইল';

  @override
  String get adminRoleManagementCreateAdminNameLabel => 'নাম';

  @override
  String get adminRoleManagementCreateAdminNamePlaceholder => 'পূর্ণ নাম';

  @override
  String get adminRoleManagementCreateAdminPasswordLabel => 'পাসওয়ার্ড';

  @override
  String get adminRoleManagementCreateAdminPasswordPlaceholder => 'পাসওয়ার্ড';

  @override
  String get adminRoleManagementCreateAdminRoleLabel => 'ভূমিকা';

  @override
  String get adminRoleManagementCreateAdminSubmitButton => 'প্রশাসক তৈরি করুন';

  @override
  String get adminRoleManagementCreateAdminSubtitle =>
      'ইমেইল ও পাসওয়ার্ড দিয়ে একজন নতুন প্রশাসক অ্যাকাউন্ট তৈরি করুন।';

  @override
  String get adminRoleManagementCreateAdminSuccessPrefix =>
      'নতুন প্রশাসক তৈরি হয়েছে:';

  @override
  String get adminRoleManagementCreateAdminTitle => 'নতুন প্রশাসক তৈরি করুন';

  @override
  String get adminRoleManagementErrorsAssignRoleFailed =>
      'ভূমিকা নির্ধারণ করা যায়নি।';

  @override
  String get adminRoleManagementErrorsCreateUserFailed =>
      'নতুন প্রশাসক তৈরি করা যায়নি।';

  @override
  String get adminRoleManagementErrorsLoadOverridesFailed =>
      'স্বতন্ত্র অনুমতি লোড করা যায়নি।';

  @override
  String get adminRoleManagementErrorsLoadPermissionsFailed =>
      'অনুমতি তালিকা লোড করা যায়নি।';

  @override
  String get adminRoleManagementErrorsLoadRolesFailed =>
      'ভূমিকা তালিকা লোড করা যায়নি।';

  @override
  String get adminRoleManagementErrorsLoadUsersFailed =>
      'ব্যবহারকারী তালিকা লোড করা যায়নি।';

  @override
  String get adminRoleManagementErrorsSaveChangeFailed =>
      'পরিবর্তন সংরক্ষণ করা যায়নি।';

  @override
  String get adminRoleManagementErrorsSaveOverridesFailed =>
      'স্বতন্ত্র অনুমতি সংরক্ষণ করা যায়নি।';

  @override
  String get adminRoleManagementSubtitle =>
      'প্রতিটি ভূমিকার জন্য অনুমতি নির্ধারণ করুন';

  @override
  String get adminRoleManagementTitle => 'ভূমিকা ও অনুমতি ব্যবস্থাপনা';

  @override
  String get adminRoleManagementUserOverridesActionLabel => 'কার্যক্রম';

  @override
  String get adminRoleManagementUserOverridesApplyButton => 'প্রয়োগ করুন';

  @override
  String get adminRoleManagementUserOverridesAssignRoleLabel =>
      'ভূমিকা নির্ধারণ করুন';

  @override
  String get adminRoleManagementUserOverridesGrantOption =>
      'অতিরিক্ত গ্রান্ট করুন';

  @override
  String get adminRoleManagementUserOverridesNoOverrides =>
      'এই ব্যবহারকারীর জন্য কোনো স্বতন্ত্র অনুমতি নেই।';

  @override
  String get adminRoleManagementUserOverridesPermissionLabel => 'অনুমতি';

  @override
  String get adminRoleManagementUserOverridesRevokeOption => 'প্রত্যাহার করুন';

  @override
  String get adminRoleManagementUserOverridesSaveRoleButton =>
      'ভূমিকা সংরক্ষণ করুন';

  @override
  String get adminRoleManagementUserOverridesSubtitle =>
      'একজন নির্দিষ্ট ব্যবহারকারীর জন্য তার ভূমিকার ডিফল্টের বাইরে গিয়ে অতিরিক্ত অনুমতি দিন বা প্রত্যাহার করুন।';

  @override
  String get adminRoleManagementUserOverridesTitle =>
      'ব্যবহারকারী-ভিত্তিক ওভাররাইড';

  @override
  String get adminRoleManagementUserOverridesUserLabel => 'ব্যবহারকারী';

  @override
  String get adminSocietyCostsCreate => 'নতুন খরচ';

  @override
  String get adminSocietyCostsCreateTitle => 'খরচ লিপিবদ্ধ করুন';

  @override
  String get adminSocietyCostsDeleteMessage =>
      'খরচ ও তার ভাগ মুছে যাবে। এটি ফিরিয়ে আনা যাবে না।';

  @override
  String get adminSocietyCostsDeleteTitle => 'খরচ মুছুন';

  @override
  String get adminSocietyCostsEdit => 'সম্পাদনা';

  @override
  String get adminSocietyCostsEditTitle => 'খরচ সম্পাদনা';

  @override
  String get adminSocietyCostsEmptyState => 'এখনো কোনো খরচ লিপিবদ্ধ হয়নি';

  @override
  String get adminSocietyCostsErrorsAmountRequired =>
      'শূন্যের বেশি পরিমাণ লিখুন।';

  @override
  String get adminSocietyCostsErrorsCategoryAddFailed =>
      'ক্যাটাগরি যোগ করা যায়নি।';

  @override
  String get adminSocietyCostsErrorsDateRequired => 'খরচের তারিখ দিতে হবে।';

  @override
  String get adminSocietyCostsErrorsDeleteFailed =>
      'খরচ মুছা যায়নি। এর বিপক্ষে পেমেন্ট রেকর্ড থাকতে পারে।';

  @override
  String get adminSocietyCostsErrorsLoadFailed =>
      'সোসাইটি খরচ লোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get adminSocietyCostsErrorsPaymentFailed =>
      'পেমেন্ট রেকর্ড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get adminSocietyCostsErrorsReceiptUploadFailed =>
      'খরচ সেভ হয়েছে, কিন্তু রসিদ আপলোড ব্যর্থ হয়েছে। সম্পাদনা থেকে আবার চেষ্টা করুন।';

  @override
  String get adminSocietyCostsErrorsSaveFailed =>
      'খরচ সেভ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get adminSocietyCostsErrorsSplitFailed =>
      'ভাগ সেভ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get adminSocietyCostsErrorsSplitPreviewFailed =>
      'ভাগের প্রিভিউ হিসাব করা যায়নি।';

  @override
  String get adminSocietyCostsErrorsTitleRequired => 'শিরোনাম দিতে হবে।';

  @override
  String get adminSocietyCostsExportCsv => 'CSV এক্সপোর্ট';

  @override
  String get adminSocietyCostsFiltersAll => 'সব';

  @override
  String get adminSocietyCostsFiltersAllCategories => 'সব ক্যাটাগরি';

  @override
  String get adminSocietyCostsFiltersAllSources => 'সব';

  @override
  String get adminSocietyCostsFiltersBilled => 'বিলিং অবস্থা';

  @override
  String get adminSocietyCostsFiltersBilledOnly => 'সদস্যদের বিল করা';

  @override
  String get adminSocietyCostsFiltersCategory => 'ক্যাটাগরি';

  @override
  String get adminSocietyCostsFiltersDateRange => 'তারিখের পরিসর';

  @override
  String get adminSocietyCostsFiltersReset => 'রিসেট';

  @override
  String get adminSocietyCostsFiltersSearch => 'খুঁজুন';

  @override
  String get adminSocietyCostsFiltersSearchPlaceholder =>
      'শিরোনাম দিয়ে খুঁজুন…';

  @override
  String get adminSocietyCostsFiltersSource => 'পেমেন্ট সোর্স';

  @override
  String get adminSocietyCostsFiltersUnbilledOnly => 'বিল করা হয়নি';

  @override
  String get adminSocietyCostsFormAddCategory => 'ক্যাটাগরি যোগ + Enter';

  @override
  String get adminSocietyCostsFormAmount => 'পরিমাণ (৳)';

  @override
  String get adminSocietyCostsFormCategory => 'ক্যাটাগরি';

  @override
  String get adminSocietyCostsFormDate => 'খরচের তারিখ';

  @override
  String get adminSocietyCostsFormDescription => 'বিবরণ';

  @override
  String get adminSocietyCostsFormNoCategory => 'ক্যাটাগরি নেই';

  @override
  String get adminSocietyCostsFormNotes => 'নোট';

  @override
  String get adminSocietyCostsFormReceipt => 'রসিদ (ছবি/PDF)';

  @override
  String get adminSocietyCostsFormSource => 'পরিশোধ সূত্র';

  @override
  String get adminSocietyCostsFormTitle => 'শিরোনাম';

  @override
  String get adminSocietyCostsNotBilled => 'বিল করা হয়নি';

  @override
  String get adminSocietyCostsPaymentAmount => 'এখন পরিশোধিত পরিমাণ (৳)';

  @override
  String get adminSocietyCostsPaymentRemaining => 'বাকি';

  @override
  String get adminSocietyCostsPaymentTitle => 'পেমেন্ট রেকর্ড করুন';

  @override
  String get adminSocietyCostsRecordPayment => 'পেমেন্ট রেকর্ড করুন';

  @override
  String get adminSocietyCostsShareStatusPaid => 'পরিশোধিত';

  @override
  String get adminSocietyCostsShareStatusPartial => 'আংশিক';

  @override
  String get adminSocietyCostsShareStatusUnpaid => 'অনাদায়ী';

  @override
  String get adminSocietyCostsSourceMemberBilled => 'সদস্যদের কাছে বিল';

  @override
  String get adminSocietyCostsSourceSocietyFund => 'সোসাইটি ফান্ড';

  @override
  String get adminSocietyCostsSplitConfirm => 'ভাগ নিশ্চিত করুন';

  @override
  String get adminSocietyCostsSplitMethod => 'ভাগ করার পদ্ধতি';

  @override
  String get adminSocietyCostsSplitMismatchWarning =>
      'পরিমাণগুলো খরচের মোটের সাথে মিলছে না। ঠিক করুন, অথবা এভাবেই সেভ করতে ওভাররাইড নিশ্চিত করুন।';

  @override
  String get adminSocietyCostsSplitNoMembers =>
      'ভাগ করার মতো কোনো সক্রিয় সদস্য নেই।';

  @override
  String get adminSocietyCostsSplitOverride => 'অমিল সত্ত্বেও সেভ করুন';

  @override
  String get adminSocietyCostsSplitRunningTotal => 'চলতি মোট';

  @override
  String adminSocietyCostsSplitSummaryLine(Object method, Object total) {
    return '৳$total সক্রিয় সদস্যদের মধ্যে ভাগ হচ্ছে ($method)';
  }

  @override
  String get adminSocietyCostsSplitTitle => 'খরচ ভাগ করুন';

  @override
  String get adminSocietyCostsSplitAction => 'ভাগ করুন';

  @override
  String get adminSocietyCostsSplitMethodByLandQuantity =>
      'জমির পরিমাণ অনুযায়ী';

  @override
  String get adminSocietyCostsSplitMethodEqual => 'সমান ভাগ';

  @override
  String get adminSocietyCostsSplitMethodManual => 'ম্যানুয়াল';

  @override
  String get adminSocietyCostsSubtitle =>
      'সোসাইটির প্রতিটি খরচ লিপিবদ্ধ করুন, প্রয়োজনে সদস্যদের মধ্যে ভাগ করুন';

  @override
  String get adminSocietyCostsSummaryOutstanding => 'সদস্যদের বকেয়া';

  @override
  String get adminSocietyCostsSummarySocietyFund => 'সোসাইটি ফান্ড থেকে';

  @override
  String get adminSocietyCostsSummaryTotal => 'মোট খরচ';

  @override
  String get adminSocietyCostsTableAmount => 'পরিমাণ';

  @override
  String get adminSocietyCostsTableCategory => 'ক্যাটাগরি';

  @override
  String get adminSocietyCostsTableDate => 'তারিখ';

  @override
  String get adminSocietyCostsTableSource => 'সোর্স';

  @override
  String get adminSocietyCostsTableSplit => 'ভাগ';

  @override
  String get adminSocietyCostsTableTitle => 'শিরোনাম';

  @override
  String get adminSocietyCostsTitle => 'সোসাইটি খরচ';

  @override
  String get adminSocietyCostsViewReceipt => 'রসিদ দেখুন';

  @override
  String get adminStatusLabelsAll => 'সব';

  @override
  String get adminStatusLabelsApproved => 'অনুমোদিত';

  @override
  String get adminStatusLabelsPending => 'বিচারাধীন';

  @override
  String get adminStatusLabelsRejected => 'প্রত্যাখ্যাত';

  @override
  String get adminSubmissionDetailAlsoEmergency => 'জরুরি যোগাযোগের সাথে একই';

  @override
  String get adminSubmissionDetailAlsoNominee => 'মনোনীতও';

  @override
  String get adminSubmissionDetailApplicableDocs => 'প্রযোজ্য দলিল';

  @override
  String get adminSubmissionDetailApproveButton => 'অনুমোদন করুন';

  @override
  String get adminSubmissionDetailApproveModalConfirmLabel =>
      'নিশ্চিত করুন ও অনুমোদন করুন';

  @override
  String get adminSubmissionDetailApproveModalMessageSuffix =>
      'কে সদস্য হিসেবে অনুমোদন দিলে স্বয়ংক্রিয়ভাবে একটি সদস্য আইডি ও লগইন তথ্য তৈরি হবে।';

  @override
  String get adminSubmissionDetailApproveModalTitle => 'আবেদন অনুমোদন করুন';

  @override
  String get adminSubmissionDetailAttachments => 'সংযুক্তি';

  @override
  String get adminSubmissionDetailCall => 'কল করুন';

  @override
  String get adminSubmissionDetailCollapse => 'সংকুচিত করুন';

  @override
  String get adminSubmissionDetailCopied => 'কপি হয়েছে';

  @override
  String get adminSubmissionDetailCopyValue => 'কপি করুন';

  @override
  String get adminSubmissionDetailCurrentAddress => 'বর্তমান ঠিকানা';

  @override
  String get adminSubmissionDetailDecimalUnit => 'শতাংশ';

  @override
  String get adminSubmissionDetailDownload => 'ডাউনলোড';

  @override
  String get adminSubmissionDetailErrorsApproveFailed =>
      'অনুমোদন ব্যর্থ হয়েছে।';

  @override
  String get adminSubmissionDetailErrorsDownloadFailed =>
      'ডাউনলব্যর্থ হয়েছে। ফাইলটি সার্ভারে নেই বা নেটওয়ার্কে সমস্যা হয়েছে।';

  @override
  String get adminSubmissionDetailErrorsLoadFailed =>
      'আবেদনের তথ্য পাওয়া যায়নি।';

  @override
  String get adminSubmissionDetailErrorsReasonRequired => 'বাতিলের কারণ লিখুন।';

  @override
  String get adminSubmissionDetailErrorsRejectEmailFailed =>
      'প্রত্যাখ্যাত হয়েছে, কিন্তু ইমেইল পাঠানো যায়নি।';

  @override
  String get adminSubmissionDetailErrorsRejectFailed =>
      'বাতিল করা ব্যর্থ হয়েছে।';

  @override
  String get adminSubmissionDetailErrorsResendFailed =>
      'বিজ্ঞপ্তি আবার পাঠানো যায়নি।';

  @override
  String get adminSubmissionDetailErrorsUploadFailed =>
      'আপলোড ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get adminSubmissionDetailExpand => 'বিস্তারিত';

  @override
  String get adminSubmissionDetailFieldLabelsAddress => 'ঠিকানা';

  @override
  String get adminSubmissionDetailFieldLabelsArea => 'পরিমাণ';

  @override
  String get adminSubmissionDetailFieldLabelsDagNoCs => 'দাগ নং (সিএস)';

  @override
  String get adminSubmissionDetailFieldLabelsDagNoRs => 'দাগ নং (আরএস)';

  @override
  String get adminSubmissionDetailFieldLabelsDescription => 'বিবরণ';

  @override
  String get adminSubmissionDetailFieldLabelsDob => 'জন্ম তারিখ';

  @override
  String get adminSubmissionDetailFieldLabelsHoldingNumber => 'হোল্ডিং নং';

  @override
  String get adminSubmissionDetailFieldLabelsKhatianNo => 'খতিয়ান নং';

  @override
  String get adminSubmissionDetailFieldLabelsLandQuantity =>
      'মোট জমির পরিমাণ (শতাংশ)';

  @override
  String get adminSubmissionDetailFieldLabelsMobile => 'মোবাইল';

  @override
  String get adminSubmissionDetailFieldLabelsMyShareQuantity =>
      'আমার অংশের পরিমাণ (শতাংশ)';

  @override
  String get adminSubmissionDetailFieldLabelsName => 'নাম';

  @override
  String get adminSubmissionDetailFieldLabelsNid => 'NID';

  @override
  String get adminSubmissionDetailFieldLabelsOwnership => 'মালিকানা';

  @override
  String get adminSubmissionDetailFieldLabelsPercentage => 'শতাংশ';

  @override
  String get adminSubmissionDetailFieldLabelsRelation => 'সম্পর্ক';

  @override
  String get adminSubmissionDetailFieldLabelsType => 'ধরন';

  @override
  String get adminSubmissionDetailFieldLabelsValue => 'মান';

  @override
  String get adminSubmissionDetailFieldsAddress => 'ঠিকানা';

  @override
  String get adminSubmissionDetailFieldsAdmissionFee => 'ভর্তি ফি';

  @override
  String get adminSubmissionDetailFieldsDistrict => 'জেলা';

  @override
  String get adminSubmissionDetailFieldsDivision => 'বিভাগ';

  @override
  String get adminSubmissionDetailFieldsDob => 'জন্ম তারিখ';

  @override
  String get adminSubmissionDetailFieldsEmail => 'ইমেইল';

  @override
  String get adminSubmissionDetailFieldsFatherOrHusband => 'পিতা/স্বামী';

  @override
  String get adminSubmissionDetailFieldsGender => 'লিঙ্গ';

  @override
  String get adminSubmissionDetailFieldsHouse => 'বাসা/হোল্ডিং নং';

  @override
  String get adminSubmissionDetailFieldsMemberPhoto => 'সদস্যের ছবি';

  @override
  String get adminSubmissionDetailFieldsMemberSignature => 'সদস্যের স্বাক্ষর';

  @override
  String get adminSubmissionDetailFieldsMobile => 'মোবাইল';

  @override
  String get adminSubmissionDetailFieldsMother => 'মাতা';

  @override
  String get adminSubmissionDetailFieldsName => 'নাম';

  @override
  String get adminSubmissionDetailFieldsNationality => 'জাতীয়তা';

  @override
  String get adminSubmissionDetailFieldsOccupation => 'পেশা';

  @override
  String get adminSubmissionDetailFieldsPaymentMethod => 'পেমেন্ট মাধ্যম';

  @override
  String get adminSubmissionDetailFieldsPostOffice => 'ডাকঘর';

  @override
  String get adminSubmissionDetailFieldsReceiptNo => 'রশিদ নং';

  @override
  String get adminSubmissionDetailFieldsReceiptPhoto => 'রশিদের ছবি';

  @override
  String get adminSubmissionDetailFieldsRejectionReason => 'বাতিলের কারণ';

  @override
  String get adminSubmissionDetailFieldsRelation => 'সম্পর্ক';

  @override
  String get adminSubmissionDetailFieldsRoad => 'রাস্তা/গ্রাম';

  @override
  String get adminSubmissionDetailFieldsStatus => 'স্ট্যাটাস';

  @override
  String get adminSubmissionDetailFieldsSubscription => 'চাঁদা';

  @override
  String get adminSubmissionDetailFieldsUpazila => 'উপজেলা/থানা';

  @override
  String get adminSubmissionDetailFileMissing =>
      'ফাইলটি সার্ভারে পাওয়া যায়নি। অনুগ্রহ করে আবার আপলোড করুন।';

  @override
  String get adminSubmissionDetailJointOwnerCountLabel =>
      'যৌথ মালিকগণের সংখ্যা';

  @override
  String get adminSubmissionDetailNoApplicableDocs => 'কোনো দলিল সংযুক্ত নেই।';

  @override
  String get adminSubmissionDetailNoAttachment => 'সংযুক্ত নেই';

  @override
  String get adminSubmissionDetailNoNominees =>
      'কোনো মনোনীত ব্যক্তির তথ্য দেওয়া হয়নি।';

  @override
  String get adminSubmissionDetailNoProperties =>
      'কোনো সম্পত্তির তথ্য দেওয়া হয়নি।';

  @override
  String get adminSubmissionDetailNomineeCardTitle => 'মনোনীত ব্যক্তি';

  @override
  String adminSubmissionDetailNomineeCount(Object count) {
    return 'মোট $countজন';
  }

  @override
  String get adminSubmissionDetailNominees => 'মনোনীত ব্যক্তি';

  @override
  String get adminSubmissionDetailNotNotified =>
      'আবেদনকারীকে ইমেইলে জানানো হয়নি।';

  @override
  String get adminSubmissionDetailNotProvided => 'দেওয়া হয়নি';

  @override
  String get adminSubmissionDetailPaymentSummary => 'পেমেন্ট ও স্ট্যাটাস';

  @override
  String get adminSubmissionDetailPermanentAddress => 'স্থায়ী ঠিকানা';

  @override
  String get adminSubmissionDetailPersonalInfo => 'ব্যক্তিগত তথ্য';

  @override
  String get adminSubmissionDetailProperties => 'সম্পত্তিসমূহ';

  @override
  String get adminSubmissionDetailPropertyCardTitle => 'সম্পত্তি';

  @override
  String adminSubmissionDetailPropertyCount(Object count) {
    return 'মোট $countটি';
  }

  @override
  String get adminSubmissionDetailRejectButton => 'বাতিল করুন';

  @override
  String get adminSubmissionDetailRejectModalConfirmLabel =>
      'প্রত্যাখ্যান নিশ্চিত করুন';

  @override
  String get adminSubmissionDetailRejectModalMessageSuffix =>
      'এর আবেদন প্রত্যাখ্যানের কারণ লিখুন। এটি আবেদনকারীকে জানানো হবে।';

  @override
  String get adminSubmissionDetailRejectModalPlaceholder =>
      'যেমন: প্রয়োজনীয় দলিল সংযুক্ত নেই...';

  @override
  String get adminSubmissionDetailRejectModalTitle => 'আবেদন প্রত্যাখ্যান করুন';

  @override
  String get adminSubmissionDetailReplaceFile => 'ফাইল পরিবর্তন করুন';

  @override
  String get adminSubmissionDetailResendButton => 'আবার পাঠান';

  @override
  String get adminSubmissionDetailRoleApplicant => 'আবেদনকারী';

  @override
  String get adminSubmissionDetailRoleColumn => 'ভূমিকা';

  @override
  String get adminSubmissionDetailRoleEmergency => 'জরুরি';

  @override
  String get adminSubmissionDetailRoleNominee => 'মনোনীত';

  @override
  String adminSubmissionDetailShareTotal(Object value) {
    return 'মোট শতাংশ: $value%';
  }

  @override
  String adminSubmissionDetailShareWarning(Object value) {
    return 'মোট শতাংশ $value% — ১০০% হতে হবে';
  }

  @override
  String get adminSubmissionDetailSharedMobileWarning =>
      'এই নম্বরটি একাধিক সহ-মালিকের দ্বারা ব্যবহৃত হয়েছে';

  @override
  String get adminSubmissionDetailTitle => 'আবেদনের বিস্তারিত';

  @override
  String get adminSubmissionDetailUploadAgain => 'আবার আপলোড করুন';

  @override
  String get adminSubmissionDetailUploading => 'আপলোড হচ্ছে…';

  @override
  String get adminSubmissionDetailUrgentContact => 'জরুরি যোগাযোগ';

  @override
  String get adminSubmissionDetailView => 'দেখুন';

  @override
  String get adminSubmissionDetailViewFile => 'ফাইল দেখুন';

  @override
  String get adminSubmissionsListAllOption => 'সব';

  @override
  String get adminSubmissionsListDetailsLink => 'বিস্তারিত';

  @override
  String get adminSubmissionsListErrorsLoadFailed => 'তালিকা লোড করা যায়নি।';

  @override
  String get adminSubmissionsListFilterLabel => 'স্ট্যাটাস অনুযায়ী ফিল্টার';

  @override
  String get adminSubmissionsListNoSubmissions => 'কোনো আবেদন পাওয়া যায়নি';

  @override
  String get adminSubmissionsListSubtitle =>
      'নতুন সদস্যপদের আবেদন পর্যালোচনা করুন';

  @override
  String get adminSubmissionsListTableHeadersDate => 'তারিখ';

  @override
  String get adminSubmissionsListTableHeadersMobile => 'মোবাইল';

  @override
  String get adminSubmissionsListTableHeadersName => 'নাম';

  @override
  String get adminSubmissionsListTableHeadersReference => 'রেফারেন্স';

  @override
  String get adminSubmissionsListTableHeadersStatus => 'স্ট্যাটাস';

  @override
  String get adminSubmissionsListTitle => 'আবেদনসমূহ';

  @override
  String get authForgotPasswordBackToLogin => 'লগইনে ফিরে যান';

  @override
  String get authForgotPasswordErrorsRequestFailed =>
      'রিসেট অনুরোধ পাঠানো যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get authForgotPasswordIdentifierLabel =>
      'সদস্য আইডি / ইউজারনেম / ইমেইল';

  @override
  String get authForgotPasswordIdentifierRequiredError =>
      'সদস্য আইডি / ইউজারনেম / ইমেইল প্রয়োজন';

  @override
  String get authForgotPasswordSendingButton => 'পাঠানো হচ্ছে...';

  @override
  String get authForgotPasswordSentMessage =>
      'এই তথ্যের সাথে কোনো অ্যাকাউন্ট থাকলে পাসওয়ার্ড রিসেট লিংক নিবন্ধিত ইমেইলে পাঠানো হয়েছে। অনুগ্রহ করে আপনার ইনবক্স (এবং স্প্যাম ফোল্ডার) দেখুন। লিংকটি ৩০ মিনিট পর্যন্ত কার্যকর থাকবে।';

  @override
  String get authForgotPasswordSubmitButton => 'রিসেট লিংক পাঠান';

  @override
  String get authForgotPasswordSubtitle =>
      'আপনার সদস্য আইডি, ইউজারনেম বা নিবন্ধিত ইমেইল লিখুন — আমরা পাসওয়ার্ড রিসেট লিংক ইমেইলে পাঠিয়ে দেব।';

  @override
  String get authForgotPasswordTitle => 'পাসওয়ার্ড ভুলে গেছেন';

  @override
  String get authLoginBackToHome => 'হোমে ফিরুন';

  @override
  String get authLoginForgotPasswordLink => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get authLoginHidePassword => 'পাসওয়ার্ড লুকান';

  @override
  String get authLoginIdentifierLabel => 'ইউজারনেম / ইমেইল / সদস্য আইডি';

  @override
  String get authLoginIdentifierRequiredError =>
      'ইউজারনেম / ইমেইল / সদস্য আইডি আবশ্যক';

  @override
  String get authLoginLoggingInButton => 'লগইন হচ্ছে...';

  @override
  String get authLoginLoginFailedError => 'লগইন ব্যর্থ হয়েছে। তথ্য সঠিক নয়।';

  @override
  String get authLoginLogoAlt =>
      'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি লোগো';

  @override
  String get authLoginNotAMemberYet => 'এখনো সদস্য নন?';

  @override
  String get authLoginPasswordLabel => 'পাসওয়ার্ড';

  @override
  String get authLoginPasswordRequiredError => 'পাসওয়ার্ড আবশ্যক';

  @override
  String get authLoginRegisterButton => 'নতুন সদস্য নিবন্ধন করুন';

  @override
  String get authLoginShowPassword => 'পাসওয়ার্ড দেখুন';

  @override
  String get authLoginSubmitButton => 'প্রবেশ করুন';

  @override
  String get authLoginSubtitle => 'সদস্য অথবা প্রশাসক হিসেবে প্রবেশ করুন';

  @override
  String get authLoginTitle => 'লগইন করুন';

  @override
  String get authResetPasswordConfirmPasswordLabel =>
      'নতুন পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get authResetPasswordErrorsResetFailed =>
      'পাসওয়ার্ড রিসেট করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get authResetPasswordInvalidTokenError =>
      'এই রিসেট লিংকটি সঠিক নয় বা মেয়াদ শেষ হয়ে গেছে। অনুগ্রহ করে নতুন লিংকের অনুরোধ করুন।';

  @override
  String get authResetPasswordMismatchError => 'পাসওয়ার্ড দুটি মিলছে না';

  @override
  String get authResetPasswordMissingTokenError =>
      'এই রিসেট লিংকটি সঠিক নয়। অনুগ্রহ করে নতুন পাসওয়ার্ড রিসেট ইমেইলের অনুরোধ করুন।';

  @override
  String get authResetPasswordNewPasswordLabel => 'নতুন পাসওয়ার্ড';

  @override
  String get authResetPasswordPasswordHint =>
      'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে এবং এতে একটি সংখ্যা থাকতে হবে।';

  @override
  String get authResetPasswordPasswordRequiredError => 'পাসওয়ার্ড প্রয়োজন';

  @override
  String get authResetPasswordResettingButton => 'রিসেট হচ্ছে...';

  @override
  String get authResetPasswordSubmitButton => 'পাসওয়ার্ড রিসেট করুন';

  @override
  String get authResetPasswordSubtitle =>
      'আপনার অ্যাকাউন্টের জন্য একটি শক্তিশালী নতুন পাসওয়ার্ড দিন।';

  @override
  String get authResetPasswordSuccessMessage =>
      'আপনার পাসওয়ার্ড সফলভাবে রিসেট হয়েছে। এখন নতুন পাসওয়ার্ড দিয়ে লগইন করতে পারেন।';

  @override
  String get authResetPasswordTitle => 'নতুন পাসওয়ার্ড নির্ধারণ করুন';

  @override
  String get authResetPasswordWeakPasswordError =>
      'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে এবং এতে একটি সংখ্যা থাকতে হবে।';

  @override
  String get brandName => 'উত্তর কাউন্দিয়া সোসাইটি';

  @override
  String get brandOrg => 'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonClose => 'বন্ধ করুন';

  @override
  String get commonConfirmModalCancelButton => 'বাতিল';

  @override
  String get commonConfirmModalConfirmButton => 'নিশ্চিত করুন';

  @override
  String get commonDelete => 'মুছুন';

  @override
  String get commonEdit => 'সম্পাদনা';

  @override
  String get commonLoading => 'লোড হচ্ছে...';

  @override
  String get commonMonthsApril => 'এপ্রিল';

  @override
  String get commonMonthsAugust => 'আগস্ট';

  @override
  String get commonMonthsDecember => 'ডিসেম্বর';

  @override
  String get commonMonthsFebruary => 'ফেব্রুয়ারি';

  @override
  String get commonMonthsJanuary => 'জানুয়ারি';

  @override
  String get commonMonthsJuly => 'জুলাই';

  @override
  String get commonMonthsJune => 'জুন';

  @override
  String get commonMonthsMarch => 'মার্চ';

  @override
  String get commonMonthsMay => 'মে';

  @override
  String get commonMonthsNovember => 'নভেম্বর';

  @override
  String get commonMonthsOctober => 'অক্টোবর';

  @override
  String get commonMonthsSeptember => 'সেপ্টেম্বর';

  @override
  String get commonRetry => 'আবার চেষ্টা করুন';

  @override
  String get commonSave => 'সংরক্ষণ';

  @override
  String get commonSelect => 'নির্বাচন করুন';

  @override
  String get commonSwitchToBangla => 'বাংলায় দেখুন';

  @override
  String get commonSwitchToEnglish => 'Switch to English';

  @override
  String get eventsBackToList => 'সব অনুষ্ঠান';

  @override
  String get eventsDetailEndsAt => 'শেষ';

  @override
  String get eventsDetailLocation => 'স্থান';

  @override
  String get eventsDetailStartsAt => 'শুরু';

  @override
  String get eventsErrorsLoadFailed => 'অনুষ্ঠান লোড করা যায়নি।';

  @override
  String get eventsNoPast => 'কোনো অতীত অনুষ্ঠান নেই।';

  @override
  String get eventsNoUpcoming => 'কোনো আসন্ন অনুষ্ঠান নেই।';

  @override
  String get eventsNotFound => 'এই অনুষ্ঠানটি আর পাওয়া যাচ্ছে না।';

  @override
  String get eventsPast => 'অতীত';

  @override
  String get eventsSubtitle => 'পরিষদের সভা, কর্মসূচি ও অনুষ্ঠান';

  @override
  String get eventsTitle => 'অনুষ্ঠান';

  @override
  String get eventsUpcoming => 'আসন্ন';

  @override
  String get footerPrototypeNotice =>
      '© ২০২৬ উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি। নির্মাণে: Anshin Tech।';

  @override
  String get footerPublicNotice =>
      'এটি একটি সদস্য ব্যবস্থাপনা পোর্টাল। © ২০২৬ উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি। নির্মাণে: Anshin Tech।';

  @override
  String get forbiddenBackToDashboard => 'ড্যাশবোর্ডে ফিরে যান';

  @override
  String get forbiddenMessage => 'এই পাতাটি দেখার অনুমতি আপনার নেই।';

  @override
  String get forbiddenTitle => 'প্রবেশাধিকার নেই';

  @override
  String get homeHeroApplicationReviewLabel => 'পর্যালোচনাধীন আবেদন';

  @override
  String get homeHeroApplyButton => 'সদস্যপদের জন্য আবেদন করুন';

  @override
  String get homeHeroEyebrow => 'সদস্য ব্যবস্থাপনা পোর্টাল';

  @override
  String get homeHeroLoginButton => 'ইতিমধ্যে সদস্য? লগইন করুন';

  @override
  String get homeHeroMemberIdLabel => 'নিবন্ধিত সদস্য';

  @override
  String get homeHeroMonthlySubscriptionLabel => 'মাসিক চাঁদা';

  @override
  String get homeHeroStatCardTitle => 'এই মুহূর্তে';

  @override
  String get homeHeroSubtitle =>
      'সদস্যপদের আবেদন থেকে শুরু করে মাসিক চাঁদা পরিশোধ পর্যন্ত — পুরো প্রক্রিয়া এখন অনলাইনে। কাগজে আবেদন করার ঝামেলা নেই, অফিসে বারবার যাওয়ার প্রয়োজন নেই।';

  @override
  String get homeHeroTitle =>
      'উত্তর কাউন্দিয়ার<br />জমির মালিকদের কল্যাণ পরিষদ';

  @override
  String get homeStepsApplyDesc =>
      'ব্যক্তিগত তথ্য, ঠিকানা, জমির বিবরণ ও পেমেন্ট তথ্যসহ ধাপে ধাপে ফর্ম পূরণ করুন।';

  @override
  String get homeStepsApplyTitle => 'আবেদন করুন';

  @override
  String get homeStepsMemberIdDesc =>
      'অনুমোদনের পর স্বয়ংক্রিয়ভাবে সদস্য আইডি তৈরি হয় এবং লগইন তথ্য ইস্যু করা হয়।';

  @override
  String get homeStepsMemberIdTitle => 'সদস্য আইডি ও লগইন';

  @override
  String get homeStepsReviewDesc =>
      'কার্যনির্বাহী কমিটি ও প্রশাসন প্রতিটি আবেদন যাচাই করে অনুমোদন বা প্রত্যাখ্যান করেন।';

  @override
  String get homeStepsReviewTitle => 'কমিটির পর্যালোচনা';

  @override
  String get idcardAddress => 'ঠিকানা';

  @override
  String get idcardAuthority => 'কর্তৃপক্ষ';

  @override
  String get idcardBack => 'পিছনের পিঠ';

  @override
  String get idcardBackTitle => 'সদস্য পরিচয়পত্র';

  @override
  String get idcardButton => 'আইডি কার্ড';

  @override
  String get idcardCardTitleEn => 'Member ID Card';

  @override
  String get idcardDob => 'জন্ম তারিখ';

  @override
  String get idcardDownload => 'কার্ড ডাউনলোড (PNG)';

  @override
  String get idcardDownloadError => 'কার্ড তৈরি করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get idcardEmergency => 'জরুরি যোগাযোগ';

  @override
  String get idcardFather => 'পিতা/স্বামী';

  @override
  String get idcardFooter => 'সদস্য পরিচয়পত্র · ২০২৬';

  @override
  String get idcardFront => 'সামনের পিঠ';

  @override
  String get idcardIssuedOn => 'ইস্যুর তারিখ';

  @override
  String get idcardLoadError => 'প্রোফাইল তথ্য লোড করা যায়নি।';

  @override
  String get idcardMobile => 'মোবাইল';

  @override
  String get idcardNid => 'এনআইডি';

  @override
  String get idcardPreparing => 'তৈরি হচ্ছে...';

  @override
  String get idcardReceiptNo => 'রসিদ নম্বর';

  @override
  String get idcardSectionContact => 'যোগাযোগ';

  @override
  String get idcardSectionMembership => 'সদস্যপদ';

  @override
  String get idcardSectionPersonal => 'ব্যক্তিগত তথ্য';

  @override
  String get idcardSocietyName => 'উত্তর কাউন্দিয়া সোসাইটি';

  @override
  String get idcardSocietyOrg => 'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি';

  @override
  String get idcardStatusApplicant => 'আবেদনকারী';

  @override
  String get idcardStatusApproved => 'সদস্য';

  @override
  String get idcardStatusPending => 'অপেক্ষমাণ';

  @override
  String get idcardStatusRejected => 'বাতিল';

  @override
  String get idcardTerms =>
      'এই কার্ডটি উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটির সম্পত্তি। কর্তৃপক্ষের অনুরোধে কার্ডটি প্রদর্শন করতে হবে এবং সদস্যপদ শেষ হলে ফেরত দিতে হবে। কার্ডটি হারিয়ে গেলে দ্রুত কর্তৃপক্ষকে জানান।';

  @override
  String get idcardTitle => 'সদস্য পরিচয়পত্র';

  @override
  String get idcardVerify => 'কিউআর কোড দিয়ে যাচাই করা যায়';

  @override
  String get memberChangePasswordChangeFailedError =>
      'পাসওয়ার্ড পরিবর্তন ব্যর্থ হয়েছে।';

  @override
  String get memberChangePasswordConfirmPasswordLabel =>
      'নতুন পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get memberChangePasswordCurrentPasswordLabel => 'বর্তমান পাসওয়ার্ড';

  @override
  String get memberChangePasswordCurrentPasswordRequiredError =>
      'বর্তমান পাসওয়ার্ড দিন।';

  @override
  String get memberChangePasswordNewPasswordLabel => 'নতুন পাসওয়ার্ড';

  @override
  String get memberChangePasswordPasswordMismatchError =>
      'পাসওয়ার্ড মিলছে না।';

  @override
  String get memberChangePasswordPasswordPolicyError =>
      'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে এবং একটি সংখ্যা থাকতে হবে।';

  @override
  String get memberChangePasswordSameAsCurrentError =>
      'নতুন পাসওয়ার্ড বর্তমান পাসওয়ার্ড থেকে আলাদা হতে হবে।';

  @override
  String get memberChangePasswordSaveButton => 'পরিবর্তন সংরক্ষণ করুন';

  @override
  String get memberChangePasswordSavingButton => 'সংরক্ষণ হচ্ছে...';

  @override
  String get memberChangePasswordSuccessMessage =>
      'পাসওয়ার্ড সফলভাবে পরিবর্তন হয়েছে।';

  @override
  String get memberChangePasswordTitle => 'পাসওয়ার্ড পরিবর্তন';

  @override
  String get memberCostSharesEmptyHint =>
      'সদস্যদের মধ্যে ভাগ করা খরচ এখানে দেখা যাবে।';

  @override
  String get memberCostSharesEmptyState => 'আপনার কোনো বকেয়া নেই';

  @override
  String get memberCostSharesLoadError =>
      'আপনার খরচের ভাগ লোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get memberCostSharesStatusPaid => 'পরিশোধিত';

  @override
  String get memberCostSharesStatusPartial => 'আংশিক';

  @override
  String get memberCostSharesStatusUnpaid => 'অনাদায়ী';

  @override
  String get memberCostSharesSubtitle =>
      'সোসাইটির যেসব খরচ আপনার অ্যাকাউন্টে ভাগ হয়েছে';

  @override
  String get memberCostSharesTableCost => 'খরচ';

  @override
  String get memberCostSharesTableDate => 'তারিখ';

  @override
  String get memberCostSharesTableDue => 'দেয়';

  @override
  String get memberCostSharesTablePaid => 'পরিশোধিত';

  @override
  String get memberCostSharesTableStatus => 'অবস্থা';

  @override
  String get memberCostSharesTitle => 'খরচের ভাগ';

  @override
  String get memberCostSharesTotalOutstanding => 'মোট বকেয়া';

  @override
  String get memberDashboardDueMonthsLabel => 'বকেয়া মাস';

  @override
  String get memberDashboardLoadError => 'তথ্য লোড করা যায়নি।';

  @override
  String get memberDashboardMemberIdLabel => 'সদস্য আইডি';

  @override
  String get memberDashboardPaidMonthsLabel => 'পরিশোধিত মাস';

  @override
  String get memberDashboardRecentStatusTitle => 'সাম্প্রতিক চাঁদার অবস্থা';

  @override
  String get memberDashboardStatusDue => 'বকেয়া';

  @override
  String get memberDashboardStatusPaid => 'পরিশোধিত';

  @override
  String get memberFundTransparencyChartsEmpty =>
      'গ্রাফ দেখানোর মতো পর্যাপ্ত তথ্য এখনো নেই।';

  @override
  String get memberFundTransparencyChartsExpenseDonut =>
      'ব্যয়ের খাতভিত্তিক চিত্র';

  @override
  String get memberFundTransparencyChartsMonthly => 'মাসিক';

  @override
  String get memberFundTransparencyChartsTrend => 'আয়-ব্যয়ের প্রবণতা';

  @override
  String get memberFundTransparencyChartsYearly => 'বার্ষিক';

  @override
  String get memberFundTransparencyCurrentBalance => 'বর্তমান ব্যালেন্স';

  @override
  String get memberFundTransparencyDownloadPdf => 'রিপোর্ট ডাউনলোড (PDF)';

  @override
  String get memberFundTransparencyEmptyHint =>
      'কমিটি লেনদেন যোগ করে অনুমোদন করলে এখানে সোসাইটির সব আয়-ব্যয় দেখা যাবে।';

  @override
  String get memberFundTransparencyEmptyTitle =>
      'এখনো কোনো লেনদেন প্রকাশিত হয়নি';

  @override
  String get memberFundTransparencyErrorsCustomRange =>
      'কাস্টম রেঞ্জের জন্য শুরু ও শেষ তারিখ দুটোই দিন (শুরু তারিখ আগে হতে হবে)।';

  @override
  String get memberFundTransparencyErrorsLoadFailed =>
      'তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get memberFundTransparencyErrorsPdfFailed =>
      'রিপোর্ট তৈরি করা যায়নি। কিছুক্ষণ পর আবার চেষ্টা করুন।';

  @override
  String get memberFundTransparencyExpenseBreakdown =>
      'কোন কোন খাতে কত টাকা খরচ হয়েছে';

  @override
  String get memberFundTransparencyExpenseBreakdownEmpty =>
      'এই সময়কালে কোনো ব্যয় নেই।';

  @override
  String get memberFundTransparencyFiltersAllCategories => 'সব খাত';

  @override
  String get memberFundTransparencyFiltersAllTypes => 'সব ধরন';

  @override
  String get memberFundTransparencyFiltersAmountRange => 'পরিমাণ রেঞ্জ (৳)';

  @override
  String get memberFundTransparencyFiltersApprovedBy => 'অনুমোদনকারী';

  @override
  String get memberFundTransparencyFiltersCategory => 'খাত';

  @override
  String get memberFundTransparencyFiltersClearAll => '✕ সব মুছুন';

  @override
  String get memberFundTransparencyFiltersDateRange => 'তারিখ রেঞ্জ';

  @override
  String get memberFundTransparencyFiltersMax => 'সর্বোচ্চ';

  @override
  String get memberFundTransparencyFiltersMin => 'সর্বনিম্ন';

  @override
  String get memberFundTransparencyFiltersReference => 'রেফারেন্স নম্বর';

  @override
  String get memberFundTransparencyFiltersReset => 'রিসেট';

  @override
  String get memberFundTransparencyFiltersSearch => 'অনুসন্ধান';

  @override
  String get memberFundTransparencyFiltersSearchPlaceholder =>
      'বিবরণ বা রেফারেন্স খুঁজুন…';

  @override
  String get memberFundTransparencyFiltersType => 'ধরন';

  @override
  String memberFundTransparencyFlagsSpike(Object category, Object pct) {
    return 'এই সময়ে $category খরচ গত সময়ের চেয়ে $pct বেশি';
  }

  @override
  String memberFundTransparencyFlagsTopCategories(Object categories) {
    return 'সবচেয়ে বেশি খরচ: $categories';
  }

  @override
  String get memberFundTransparencyIncomeBreakdown =>
      'কোন কোন খাত থেকে কত টাকা কালেকশন হয়েছে';

  @override
  String get memberFundTransparencyIncomeBreakdownEmpty =>
      'এই সময়কালে কোনো আয় নেই।';

  @override
  String get memberFundTransparencyLastUpdated => 'সর্বশেষ আপডেট';

  @override
  String get memberFundTransparencyLedgerAmount => 'পরিমাণ';

  @override
  String get memberFundTransparencyLedgerApprovedBy => 'অনুমোদনকারী';

  @override
  String get memberFundTransparencyLedgerCategory => 'খাত';

  @override
  String memberFundTransparencyLedgerCount(Object count) {
    return 'মোট $countটি লেনদেন';
  }

  @override
  String get memberFundTransparencyLedgerDate => 'তারিখ';

  @override
  String get memberFundTransparencyLedgerDescription => 'বিবরণ';

  @override
  String get memberFundTransparencyLedgerEmpty => 'কোনো লেনদেন পাওয়া যায়নি';

  @override
  String get memberFundTransparencyLedgerEmptyHint =>
      'ফিল্টার পরিবর্তন করে আবার দেখুন।';

  @override
  String memberFundTransparencyLedgerPage(Object page, Object total) {
    return 'পৃষ্ঠা $page / $total';
  }

  @override
  String get memberFundTransparencyLedgerReference => 'রেফারেন্স';

  @override
  String get memberFundTransparencyLedgerReversalOf =>
      'রিভার্সাল হয়েছে লেনদেন';

  @override
  String get memberFundTransparencyLedgerType => 'ধরন';

  @override
  String get memberFundTransparencyLedgerViewAttachment => 'সংযুক্তি দেখুন';

  @override
  String get memberFundTransparencyNetSaved => 'নিট জমা';

  @override
  String get memberFundTransparencyPeriodAll => 'সর্বমোট';

  @override
  String get memberFundTransparencyPeriodApply => 'দেখান';

  @override
  String get memberFundTransparencyPeriodCustom => 'কাস্টম রেঞ্জ';

  @override
  String get memberFundTransparencyPeriodMonth => 'এই মাস';

  @override
  String get memberFundTransparencyPeriodYear => 'এই বছর';

  @override
  String get memberFundTransparencyPreviewMissing =>
      'সংযুক্তিটি পাওয়া যাচ্ছে না। কমিটিকে জানান।';

  @override
  String get memberFundTransparencyPreviewTitle => 'সংযুক্তি প্রিভিউ';

  @override
  String get memberFundTransparencySubtitle =>
      'সোসাইটির প্রতিটি আর্থিক লেনদেন সবার জন্য উন্মুক্ত — আয়, ব্যয় ও ব্যালেন্স এক নজরে';

  @override
  String memberFundTransparencySummaryLine(
      Object expense, Object income, Object net) {
    return 'এই সময়ে আয় হয়েছে $income টাকা, ব্যয় হয়েছে $expense টাকা, নিট জমা $net টাকা।';
  }

  @override
  String get memberFundTransparencyTitle => 'ফান্ড স্বচ্ছতা';

  @override
  String get memberFundTransparencyTopTag => 'সর্বোচ্চ';

  @override
  String get memberFundTransparencyTotalExpense => 'সর্বমোট ব্যয়';

  @override
  String get memberFundTransparencyTotalIncome => 'সর্বমোট আয়';

  @override
  String get memberFundTransparencyTypeExpense => 'ব্যয়';

  @override
  String get memberFundTransparencyTypeIncome => 'আয়';

  @override
  String get memberInstallmentsAmountColumn => 'পরিমাণ';

  @override
  String get memberInstallmentsEmptyFiltered =>
      'এই বছরের কোনো পেমেন্ট পাওয়া যায়নি।';

  @override
  String get memberInstallmentsEmptyState => 'কোনো কিস্তি নেই';

  @override
  String get memberInstallmentsFilterAll => 'সব বছর';

  @override
  String get memberInstallmentsLoadError => 'কিস্তির তালিকা লোড করা যায়নি।';

  @override
  String get memberInstallmentsMonthColumn => 'মাস';

  @override
  String get memberInstallmentsPaidAtColumn => 'পরিশোধের তারিখ';

  @override
  String get memberInstallmentsPaymentNotice =>
      'চাঁদা পরিশোধ অফিসে সরাসরি (নগদ/বিকাশ/ব্যাংক) করা হয়; প্রশাসন তা এখানে হালনাগাদ করেন।';

  @override
  String get memberInstallmentsStatusColumn => 'অবস্থা';

  @override
  String get memberInstallmentsStatusDue => 'বকেয়া';

  @override
  String get memberInstallmentsStatusPaid => 'পরিশোধিত';

  @override
  String get memberInstallmentsSubtitle =>
      'আপনার মাসিক চাঁদা পরিশোধের হিসাব এক নজরে।';

  @override
  String get memberInstallmentsSummaryDue => 'মোট বকেয়া';

  @override
  String get memberInstallmentsSummaryPaid => 'মোট পরিশোধিত';

  @override
  String get memberInstallmentsSummaryPayments => 'পরিশোধিত কিস্তি';

  @override
  String get memberInstallmentsTitle => 'চাঁদার ইতিহাস';

  @override
  String get memberPayDuesAmount => 'পরিমাণ';

  @override
  String get memberPayDuesBack => 'পেছনে';

  @override
  String memberPayDuesBannerTitle(Object count) {
    return 'আপনার $count মাসের চাঁদা বকেয়া';
  }

  @override
  String get memberPayDuesClearAll => 'সব বাদ';

  @override
  String get memberPayDuesClose => 'বন্ধ করুন';

  @override
  String get memberPayDuesContinue => 'পরবর্তী';

  @override
  String get memberPayDuesCopied => 'কপি হয়েছে';

  @override
  String get memberPayDuesCopy => 'কপি';

  @override
  String get memberPayDuesHistoryTitle => 'সাম্প্রতিক অনলাইন পরিশোধ';

  @override
  String get memberPayDuesIHavePaid => 'আমি পরিশোধ করেছি';

  @override
  String get memberPayDuesKeepReceipt =>
      'SMS/রসিদের ট্রানজেকশন আইডি সংরক্ষণ করুন — পরের ধাপে লাগবে।';

  @override
  String get memberPayDuesMethodHint =>
      'পরিশোধের মাধ্যম বেছে নিন, তারপর এই অ্যাকাউন্টে সঠিক পরিমাণ পাঠান।';

  @override
  String get memberPayDuesMonths => 'মাস';

  @override
  String get memberPayDuesNote => 'মন্তব্য (ঐচ্ছিক)';

  @override
  String get memberPayDuesNotice =>
      '“চাঁদা পরিশোধ” বাটনে অনলাইনে পরিশোধ করুন। কমিটি যাচাই করার পর তা পরিশোধিত হিসেবে দেখাবে।';

  @override
  String get memberPayDuesOldest => 'সবচেয়ে পুরনো';

  @override
  String get memberPayDuesPaidOn => 'পরিশোধের তারিখ';

  @override
  String get memberPayDuesPayNow => 'চাঁদা পরিশোধ';

  @override
  String get memberPayDuesPaymentStatusApproved => 'যাচাইকৃত';

  @override
  String get memberPayDuesPaymentStatusPending => 'যাচাইয়ের অপেক্ষায়';

  @override
  String get memberPayDuesPaymentStatusRejected => 'বাতিল';

  @override
  String get memberPayDuesProof => 'রসিদ / স্ক্রিনশট (ঐচ্ছিক)';

  @override
  String get memberPayDuesProofHint => 'JPG, PNG বা PDF, সর্বোচ্চ ৫ MB।';

  @override
  String get memberPayDuesProofSizeError => 'ফাইল ৫ MB-এর বেশি হতে পারবে না।';

  @override
  String get memberPayDuesProofTypeError =>
      'শুধু JPG, PNG বা PDF ফাইল দেওয়া যাবে।';

  @override
  String get memberPayDuesRejectedReason => 'কারণ';

  @override
  String get memberPayDuesSelectAll => 'সব নির্বাচন';

  @override
  String get memberPayDuesSelectHint =>
      'পুরনো বকেয়া আগে থেকেই নির্বাচিত। এখন যে মাস দিচ্ছেন না সেটির টিক তুলে দিন।';

  @override
  String get memberPayDuesSendTo => 'পাঠাবেন';

  @override
  String get memberPayDuesSenderAccount =>
      'যে নম্বর/অ্যাকাউন্ট থেকে পাঠিয়েছেন';

  @override
  String get memberPayDuesStatusPending => 'যাচাই চলছে';

  @override
  String get memberPayDuesStep1 => 'মাস নির্বাচন';

  @override
  String get memberPayDuesStep2 => 'টাকা পাঠান';

  @override
  String get memberPayDuesStep3 => 'নিশ্চিত করুন';

  @override
  String get memberPayDuesSubmit => 'যাচাইয়ের জন্য জমা দিন';

  @override
  String get memberPayDuesSubmitError =>
      'পরিশোধ জমা দেওয়া যায়নি। আবার চেষ্টা করুন।';

  @override
  String get memberPayDuesSubmitted =>
      'পরিশোধ জমা হয়েছে! কমিটি শীঘ্রই যাচাই করবে এবং আপনাকে ইমেইলে জানানো হবে।';

  @override
  String get memberPayDuesSubmitting => 'জমা হচ্ছে...';

  @override
  String get memberPayDuesTitle => 'মাসিক চাঁদা পরিশোধ';

  @override
  String memberPayDuesTotalLabel(Object count) {
    return '$count মাসের মোট';
  }

  @override
  String get memberPayDuesTransactionRef => 'ট্রানজেকশন আইডি';

  @override
  String get memberPayDuesTransactionRefError =>
      'সঠিক ট্রানজেকশন আইডি দিন (৪–৬৪ অক্ষর/সংখ্যা)।';

  @override
  String get memberPayDuesTransactionRefPlaceholder => 'যেমন 9KX7AB12CD';

  @override
  String get memberPicnicAccessDenied =>
      'আপনার পিকনিক পরিশোধে প্রবেশাধিকার নেই।';

  @override
  String get memberPicnicAdditionalHeads => 'অতিরিক্ত প্রধান';

  @override
  String memberPicnicAdditionalHeadsHint(Object max) {
    return '০ থেকে $max (স্ত্রী, সন্তান, অতিথি)';
  }

  @override
  String get memberPicnicAdditionalHeadsLabel => 'অতিরিক্ত জনসংখ্যা';

  @override
  String get memberPicnicDateColumn => 'তারিখ';

  @override
  String get memberPicnicDateLabel => 'পরিশোধের তারিখ';

  @override
  String get memberPicnicEmptyState => 'এখনও কোনো পিকনিক পরিশোধ নেই।';

  @override
  String get memberPicnicFeeLoadFailed => 'পিকনিক ফি লোড করা যায়নি।';

  @override
  String memberPicnicHeadNameLabel(Object n) {
    return 'প্রধান $n নাম';
  }

  @override
  String memberPicnicHeadRelationLabel(Object n) {
    return 'প্রধান $n সম্পর্ক';
  }

  @override
  String get memberPicnicHeadsColumn => 'অতিরিক্ত জন';

  @override
  String get memberPicnicHistoryLoadFailed => 'পরিশোধের ইতিহাস লোড করা যায়নি।';

  @override
  String get memberPicnicHistoryTitle => 'পরিশোধের ইতিহাস';

  @override
  String get memberPicnicLoadError => 'পরিশোধের ইতিহাস লোড করা যায়নি।';

  @override
  String get memberPicnicMemberHead => 'সদস্য প্রধান';

  @override
  String get memberPicnicMethodColumn => 'পদ্ধতি';

  @override
  String get memberPicnicMethodLabel => 'পরিশোধ পদ্ধতি';

  @override
  String get memberPicnicMethodsBankTransfer => 'ব্যাংক ট্রান্সফার';

  @override
  String get memberPicnicMethodsCash => 'ক্যাশ';

  @override
  String get memberPicnicMethodsNagad => 'নগদ';

  @override
  String get memberPicnicMethodsOther => 'অন্যান্য';

  @override
  String get memberPicnicMethodsBKash => 'বিকাশ';

  @override
  String get memberPicnicNotConfigured =>
      'পিকনিক ফি এখনও নির্ধারণ করা হয়নি। কমিটির সাথে যোগাযোগ করুন।';

  @override
  String get memberPicnicReceiptColumn => 'রশিদ নম্বর';

  @override
  String get memberPicnicReceiptNoLabel => 'রশিদ নম্বর';

  @override
  String get memberPicnicRelationsChild => 'সন্তান';

  @override
  String get memberPicnicRelationsGuest => 'অতিথি';

  @override
  String get memberPicnicRelationsSpouse => 'স্ত্রী/স্বামী';

  @override
  String get memberPicnicRetry => 'আবার চেষ্টা করুন';

  @override
  String get memberPicnicSaveError => 'পরিশোধ সংরক্ষণ করা যায়নি।';

  @override
  String memberPicnicSaveSuccess(Object total) {
    return 'পরিশোধ সংরক্ষিত হয়েছে। মোট: ৳ $total';
  }

  @override
  String get memberPicnicSaving => 'সংরক্ষণ হচ্ছে…';

  @override
  String get memberPicnicSubmit => 'পরিশোধ নিশ্চিত করুন';

  @override
  String get memberPicnicSubtitle =>
      'নিজের আসন এবং স্ত্রী, সন্তান বা অতিথিদের আসনের জন্য পরিশোধ করুন';

  @override
  String get memberPicnicTaka => 'টাকা';

  @override
  String get memberPicnicTitle => 'পিকনিক ফি পরিশোধ';

  @override
  String get memberPicnicTotal => 'মোট';

  @override
  String get memberPicnicTotalColumn => 'মোট';

  @override
  String get memberProfileAddressLabel => 'ঠিকানা';

  @override
  String get memberProfileAddressTitle => 'ঠিকানা';

  @override
  String get memberProfileAdmissionFeeLabel => 'ভর্তি ফি';

  @override
  String get memberProfileCancelButton => 'বাতিল';

  @override
  String get memberProfileChangePhotoButton => 'ছবি পরিবর্তন';

  @override
  String get memberProfileCoOwnerLabel => 'সহ-মালিক';

  @override
  String get memberProfileContactTitle => 'যোগাযোগ';

  @override
  String get memberProfileCurrentAddressLabel => 'বর্তমান';

  @override
  String get memberProfileDagNoCsLabel => 'দাগ নং (সিএস)';

  @override
  String get memberProfileDagNoRsLabel => 'দাগ নং (আরএস)';

  @override
  String get memberProfileDecimalUnit => 'শতাংশ';

  @override
  String get memberProfileDistrictLabel => 'জেলা';

  @override
  String get memberProfileDivisionLabel => 'বিভাগ';

  @override
  String get memberProfileDobLabel => 'জন্ম তারিখ';

  @override
  String get memberProfileDocumentLabel => 'দলিল';

  @override
  String get memberProfileDownload => 'ডাউনলোড';

  @override
  String get memberProfileDownloadFailed =>
      'ডাউনলোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get memberProfileEditButton => 'প্রোফাইল সম্পাদনা';

  @override
  String get memberProfileEditTitle => 'প্রোফাইল সম্পাদনা করুন';

  @override
  String get memberProfileEmailLabel => 'ইমেইল';

  @override
  String get memberProfileFatherOrHusbandLabel => 'পিতা/স্বামী';

  @override
  String get memberProfileFileMissing =>
      'ফাইলটি সার্ভারে পাওয়া যায়নি। অনুগ্রহ করে আবার আপলোড করুন।';

  @override
  String get memberProfileGenderLabel => 'লিঙ্গ';

  @override
  String get memberProfileHoldingNumberLabel => 'হোল্ডিং নম্বর';

  @override
  String get memberProfileHouseLabel => 'বাড়ি';

  @override
  String get memberProfileKhatianLabel => 'খতিয়ান';

  @override
  String get memberProfileLandQuantityLabel => 'জমির পরিমাণ';

  @override
  String get memberProfileLoadError => 'প্রোফাইল লোড করা যায়নি।';

  @override
  String get memberProfileMemberIdLabel => 'সদস্য আইডি';

  @override
  String get memberProfileMobileLabel => 'মোবাইল';

  @override
  String get memberProfileMotherLabel => 'মাতা';

  @override
  String get memberProfileMyShareQuantityLabel => 'আমার অংশ';

  @override
  String get memberProfileNameLabel => 'নাম';

  @override
  String get memberProfileNationalityLabel => 'জাতীয়তা';

  @override
  String get memberProfileNidLabel => 'এনআইডি';

  @override
  String get memberProfileNoNominees => 'কোনো নমিনির তথ্য দেওয়া হয়নি।';

  @override
  String get memberProfileNoPropertyInfo => 'কোনো সম্পত্তির তথ্য দেওয়া হয়নি।';

  @override
  String get memberProfileNomineesTitle => 'নমিনি';

  @override
  String get memberProfileOccupationLabel => 'পেশা';

  @override
  String get memberProfileOwnershipLabel => 'মালিকানা';

  @override
  String get memberProfilePaymentMethodLabel => 'পেমেন্ট পদ্ধতি';

  @override
  String get memberProfilePaymentTitle => 'নিবন্ধন পেমেন্ট';

  @override
  String get memberProfilePendingReviewNotice =>
      'সাম্প্রতিক প্রোফাইল হালনাগাদের কারণে আপনার সদস্যপদ বর্তমানে পর্যালোচনাধীন। পর্যালোচনার পর অনুমোদিত অবস্থা পুনরায় কার্যকর হবে।';

  @override
  String get memberProfilePermanentAddressLabel => 'স্থায়ী';

  @override
  String get memberProfilePersonalInfoTitle => 'ব্যক্তিগত তথ্য';

  @override
  String get memberProfilePhotoLabel => 'সদস্যের ছবি';

  @override
  String get memberProfilePhotoSizeError => 'ছবির আকার ৩ এমবি-র কম হতে হবে';

  @override
  String get memberProfilePhotoTypeError =>
      'অনুগ্রহ করে একটি ছবি নির্বাচন করুন (JPG/PNG)';

  @override
  String get memberProfilePhotoUploadError =>
      'ছবি আপলোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get memberProfilePostOfficeLabel => 'ডাকঘর';

  @override
  String get memberProfilePropertyItemLabel => 'সম্পত্তি';

  @override
  String get memberProfilePropertyTitle => 'সম্পত্তি';

  @override
  String get memberProfileReceiptNoLabel => 'রসিদ নং';

  @override
  String get memberProfileReceiptPhotoLabel => 'পেমেন্ট রসিদ';

  @override
  String get memberProfileRelationLabel => 'সম্পর্ক';

  @override
  String get memberProfileRemovePhotoButton => 'সরান';

  @override
  String get memberProfileRequeueWarning =>
      'এই তথ্য পরিবর্তন করলে আপনার সদস্যপদ ব্যবস্থাপনা কমিটির পর্যালোচনার জন্য পুনরায় পাঠানো হবে।';

  @override
  String get memberProfileRoadLabel => 'সড়ক';

  @override
  String get memberProfileSameAsPermanentAddress =>
      'একই — স্থায়ী ঠিকানার অনুরূপ';

  @override
  String get memberProfileSaveButton => 'পরিবর্তন সংরক্ষণ করুন';

  @override
  String get memberProfileSaveError => 'প্রোফাইল পরিবর্তন সংরক্ষণ করা যায়নি।';

  @override
  String get memberProfileSignatureLabel => 'স্বাক্ষর';

  @override
  String get memberProfileStatusApproved => 'অনুমোদিত';

  @override
  String get memberProfileStatusPending => 'পর্যালোচনাধীন';

  @override
  String get memberProfileStatusRejected => 'প্রত্যাখ্যাত';

  @override
  String get memberProfileSubmissionDateLabel => 'নিবন্ধনের তারিখ';

  @override
  String get memberProfileSubscriptionLabel => 'চাঁদা';

  @override
  String get memberProfileTitle => 'প্রোফাইল';

  @override
  String get memberProfileUpazilaLabel => 'উপজেলা';

  @override
  String get memberProfileUrgentContactTitle => 'জরুরি যোগাযোগ';

  @override
  String get memberProfileViewFile => 'ফাইল দেখুন';

  @override
  String get memberProfileVillageLabel => 'গ্রাম';

  @override
  String get memberPropertyRequestsActionsAdd => 'সংযোজন';

  @override
  String get memberPropertyRequestsActionsDelete => 'মুছে ফেলা';

  @override
  String get memberPropertyRequestsActionsEdit => 'সংশোধন';

  @override
  String get memberPropertyRequestsAddButton => 'সম্পত্তি যোগ করুন';

  @override
  String get memberPropertyRequestsAddCoOwnerButton => 'যৌথ মালিক যোগ করুন';

  @override
  String get memberPropertyRequestsAddDocButton => 'নথি যোগ করুন';

  @override
  String get memberPropertyRequestsAddTitle => 'সম্পত্তি সংযোজনের অনুরোধ';

  @override
  String get memberPropertyRequestsBackButton => 'ফিরে যান';

  @override
  String get memberPropertyRequestsCancelReasonLabel => 'বাতিলের কারণ';

  @override
  String get memberPropertyRequestsCoOwnerNamePlaceholder => 'যৌথ মালিকের নাম';

  @override
  String get memberPropertyRequestsCoOwnerNameRequired =>
      'প্রত্যেক যৌথ মালিকের নাম দিতে হবে।';

  @override
  String get memberPropertyRequestsCoOwnersLabel => 'যৌথ মালিকগণ';

  @override
  String get memberPropertyRequestsDeleteModalConfirmLabel =>
      'অপসারণের অনুরোধ পাঠান';

  @override
  String get memberPropertyRequestsDeleteModalMessage =>
      'এই সম্পত্তিটি মুছে ফেলার আগে একজন প্রশাসক আপনার অনুরোধটি পর্যালোচনা করবেন।';

  @override
  String get memberPropertyRequestsDeleteModalTitle =>
      'সম্পত্তি অপসারণের অনুরোধ';

  @override
  String get memberPropertyRequestsDocDropped => 'বাদ দেওয়া হবে';

  @override
  String get memberPropertyRequestsDocIncomplete =>
      'নথির ধরন নির্বাচন করে ফাইল সংযুক্ত করুন।';

  @override
  String get memberPropertyRequestsDocKept => 'রাখা হবে';

  @override
  String get memberPropertyRequestsDocsLabel => 'নথিপত্র';

  @override
  String get memberPropertyRequestsDocumentsSectionTitle => 'নথিপত্র';

  @override
  String get memberPropertyRequestsEditTitle => 'সম্পত্তি সংশোধনের অনুরোধ';

  @override
  String get memberPropertyRequestsErrorsLoadFailed =>
      'সম্পত্তি সংক্রান্ত অনুরোধ লোড করা যায়নি।';

  @override
  String get memberPropertyRequestsErrorsPropertyNotFound =>
      'অনুরোধকৃত সম্পত্তিটি পাওয়া যায়নি।';

  @override
  String get memberPropertyRequestsErrorsSubmitFailed =>
      'অনুরোধ পাঠানো যায়নি। আবার চেষ্টা করুন।';

  @override
  String get memberPropertyRequestsErrorsWithdrawFailed =>
      'অনুরোধ প্রত্যাহার করা যায়নি।';

  @override
  String get memberPropertyRequestsExistingDocsLabel => 'বিদ্যমান নথি';

  @override
  String get memberPropertyRequestsFormSubtitle =>
      'আপনার পরিবর্তনটি প্রশাসকের পর্যালোচনার জন্য জমা দিন।';

  @override
  String get memberPropertyRequestsListTitle => 'সম্পত্তি সংক্রান্ত অনুরোধ';

  @override
  String get memberPropertyRequestsNewDocsLabel => 'নতুন নথি যোগ করুন';

  @override
  String get memberPropertyRequestsNoExistingDocs =>
      'এই সম্পত্তিতে কোনো বিদ্যমান নথি নেই।';

  @override
  String get memberPropertyRequestsNoRequests =>
      'এখনও কোনো সম্পত্তি সংক্রান্ত অনুরোধ নেই।';

  @override
  String get memberPropertyRequestsPendingPill => 'অনুরোধ অপেক্ষমাণ';

  @override
  String get memberPropertyRequestsPropertySectionTitle => 'সম্পত্তির তথ্য';

  @override
  String get memberPropertyRequestsStatusLabelsApproved => 'অনুমোদিত';

  @override
  String get memberPropertyRequestsStatusLabelsCancelled => 'বাতিল';

  @override
  String get memberPropertyRequestsStatusLabelsPending => 'অপেক্ষমাণ';

  @override
  String get memberPropertyRequestsSubmitButton => 'অনুরোধ পাঠান';

  @override
  String get memberPropertyRequestsSubmittedLabel => 'জমাদান';

  @override
  String get memberPropertyRequestsSuccessSent =>
      'আপনার অনুরোধ পর্যালোচনার জন্য পাঠানো হয়েছে।';

  @override
  String get memberPropertyRequestsWithdrawButton => 'প্রত্যাহার';

  @override
  String get memberPropertyRequestsWithdrawModalConfirmLabel =>
      'প্রত্যাহার করুন';

  @override
  String get memberPropertyRequestsWithdrawModalMessage =>
      'আপনার অপেক্ষমাণ অনুরোধটি বাতিল হবে। এটি আর ফেরানো যাবে না।';

  @override
  String get memberPropertyRequestsWithdrawModalTitle => 'অনুরোধ প্রত্যাহার';

  @override
  String get memberPropertyRequestsWithdrawnSuccess =>
      'অনুরোধটি প্রত্যাহার করা হয়েছে।';

  @override
  String get memberRoadmapActionsImage => 'শেয়ার করার জন্য ছবি';

  @override
  String get memberRoadmapActionsPdf => 'A4 প্রিন্ট / PDF';

  @override
  String get memberRoadmapActionsSlides => 'স্লাইড আকারে দেখুন';

  @override
  String memberRoadmapCompletedOn(Object date) {
    return 'সম্পন্ন: $date';
  }

  @override
  String get memberRoadmapEmpty =>
      'এই সময়সীমায় এখনো কোনো পরিকল্পনা যোগ করা হয়নি।';

  @override
  String get memberRoadmapEmptyFiltered => 'এই ফিল্টারে কোনো পরিকল্পনা নেই।';

  @override
  String get memberRoadmapExportError =>
      'ডাউনলোড তৈরি করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get memberRoadmapFilterAll => 'সব';

  @override
  String get memberRoadmapFilterDone => 'সম্পন্ন';

  @override
  String get memberRoadmapFilterInProgress => 'চলমান';

  @override
  String get memberRoadmapFilterPlanned => 'পরিকল্পিত';

  @override
  String get memberRoadmapFilterAria => 'অবস্থা অনুযায়ী ফিল্টার';

  @override
  String get memberRoadmapFocusNow => 'এখন যেদিকে মনোযোগ';

  @override
  String memberRoadmapItemCount(Object n) {
    return '$nটি পরিকল্পনা';
  }

  @override
  String memberRoadmapLastUpdated(Object date) {
    return 'সর্বশেষ আপডেট: $date';
  }

  @override
  String get memberRoadmapLoadError =>
      'পরিকল্পনা লোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String memberRoadmapOverallAria(Object pct) {
    return 'সার্বিক অগ্রগতি $pct শতাংশ';
  }

  @override
  String get memberRoadmapOverallProgress => 'সার্বিক অগ্রগতি';

  @override
  String memberRoadmapProgressLabel(
      Object done, Object name, Object pct, Object total) {
    return '$name: $done/$total সম্পন্ন — $pct%';
  }

  @override
  String memberRoadmapProgressShort(Object done, Object pct, Object total) {
    return '$done/$total সম্পন্ন — $pct%';
  }

  @override
  String get memberRoadmapSlidesHint =>
      '← → কী অথবা সোয়াইপ করে স্লাইড বদলান · Esc চাপলে বন্ধ হবে';

  @override
  String get memberRoadmapSlidesNext => 'পরের স্লাইড';

  @override
  String get memberRoadmapSlidesPrev => 'আগের স্লাইড';

  @override
  String get memberRoadmapStatusDone => 'সম্পন্ন';

  @override
  String get memberRoadmapStatusInProgress => 'চলমান';

  @override
  String get memberRoadmapStatusPlanned => 'পরিকল্পিত';

  @override
  String get memberRoadmapStepperAria => 'পরিকল্পনার সময়রেখা';

  @override
  String get memberRoadmapSubtitle =>
      'আমরা কোথায় আছি, কোথায় যাচ্ছি এবং কীভাবে যাচ্ছি।';

  @override
  String memberRoadmapTarget(Object date) {
    return 'লক্ষ্য: $date';
  }

  @override
  String get memberRoadmapTitle => 'আমাদের পরিকল্পনা';

  @override
  String get memberRoadmapWeAreHere => 'আমরা এখানে';

  @override
  String memberRoadmapWhereSummary(Object done, Object total) {
    return 'মোট $totalটি পরিকল্পনার মধ্যে $doneটি সম্পন্ন হয়েছে।';
  }

  @override
  String get memberRoadmapWhereTitle => 'আমরা এখন কোথায় আছি';

  @override
  String get navAdmin => 'প্রশাসক';

  @override
  String get navAuditLog => 'অডিট লগ';

  @override
  String get navChangePassword => 'পাসওয়ার্ড পরিবর্তন';

  @override
  String get navChangeTheme => 'থিম পরিবর্তন';

  @override
  String get navCloseMenu => 'মেনু বন্ধ করুন';

  @override
  String get navConfigLists => 'কনফিগ তালিকা';

  @override
  String get navCostShares => 'খরচের ভাগ';

  @override
  String get navDarkTheme => 'গাঢ় থিম';

  @override
  String get navDashboard => 'ড্যাশবোর্ড';

  @override
  String get navEvents => 'অনুষ্ঠান';

  @override
  String get navEventsManagement => 'অনুষ্ঠান ব্যবস্থাপনা';

  @override
  String get navFeeSettings => 'ফি সেটিংস';

  @override
  String get navFinanceManagement => 'আর্থিক ব্যবস্থাপনা';

  @override
  String get navFundTransparency => 'ফান্ড স্বচ্ছতা';

  @override
  String get navInstallments => 'কিস্তি';

  @override
  String get navInstallmentsManagement => 'চাঁদা ব্যবস্থাপনা';

  @override
  String get navLightTheme => 'হালকা থিম';

  @override
  String get navLogin => 'লগইন';

  @override
  String get navLogout => 'বের হোন';

  @override
  String get navMembersList => 'সদস্য তালিকা';

  @override
  String get navMoreOptions => 'আরও বিকল্প';

  @override
  String get navNotices => 'নোটিশ';

  @override
  String get navNoticesManagement => 'নোটিশ ব্যবস্থাপনা';

  @override
  String get navOpenMenu => 'মেনু খুলুন';

  @override
  String get navPaymentVerifications => 'পেমেন্ট যাচাই';

  @override
  String get navPicnicPayment => 'পিকনিক ফি';

  @override
  String get navPicnicPayments => 'পিকনিক পরিশোধ';

  @override
  String get navProfile => 'প্রোফাইল';

  @override
  String get navPropertyRequests => 'সম্পত্তি সংক্রান্ত অনুরোধ';

  @override
  String get navRegister => 'আবেদন করুন';

  @override
  String get navResolutionBook => 'রেজোলিউশন বুক';

  @override
  String get navRoadmap => 'আমাদের পরিকল্পনা';

  @override
  String get navRoadmapManagement => 'পরিকল্পনা ব্যবস্থাপনা';

  @override
  String get navRolesPermissions => 'ভূমিকা ও অনুমতি';

  @override
  String get navSocietyCosts => 'সোসাইটি খরচ';

  @override
  String get navSubmissions => 'সাবমিশন';

  @override
  String get noticesBackToList => 'সব নোটিশ';

  @override
  String get noticesEmpty => 'এখনো কোনো নোটিশ প্রকাশ করা হয়নি।';

  @override
  String get noticesErrorsLoadFailed => 'নোটিশ লোড করা যায়নি।';

  @override
  String get noticesNotFound => 'এই নোটিশটি আর পাওয়া যাচ্ছে না।';

  @override
  String get noticesSubtitle =>
      'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটির ঘোষণা';

  @override
  String get noticesTitle => 'নোটিশ';

  @override
  String get passwordfieldHide => 'পাসওয়ার্ড লুকান';

  @override
  String get passwordfieldShow => 'পাসওয়ার্ড দেখুন';

  @override
  String get rbActionsAddMeeting => 'নতুন সভা';

  @override
  String get rbActionsEdit => 'সম্পাদনা';

  @override
  String get rbActionsPdf => 'পিডিএফ ডাউনলোড';

  @override
  String get rbAttendanceAbsent => 'অনুপস্থিত';

  @override
  String get rbAttendancePresent => 'উপস্থিত';

  @override
  String get rbDetailAgenda => 'আলোচ্যসূচি';

  @override
  String get rbDetailAttendanceTitle => 'উপস্থিতি';

  @override
  String get rbDetailBack => 'রেজোলিউশন বুক';

  @override
  String get rbDetailChair => 'সভাপতি';

  @override
  String rbDetailCreatedBy(Object name) {
    return 'রেকর্ড করেছেন $name';
  }

  @override
  String rbDetailLastUpdated(Object date) {
    return 'সর্বশেষ হালনাগাদ $date';
  }

  @override
  String get rbDetailNextMeeting => 'পরবর্তী সভা';

  @override
  String get rbDetailNoAttendance => 'উপস্থিতি রেকর্ড করা হয়নি।';

  @override
  String get rbDetailNoResolutions => 'কোনো সিদ্ধান্ত রেকর্ড করা হয়নি।';

  @override
  String get rbDetailNoSummary => 'কোনো সারসংক্ষেপ লেখা হয়নি।';

  @override
  String get rbDetailNotSet => 'নির্ধারিত নয়';

  @override
  String rbDetailResolutionNo(Object no) {
    return 'সিদ্ধান্ত-$no';
  }

  @override
  String get rbDetailResolutionStatus => 'সিদ্ধান্তের অবস্থা';

  @override
  String get rbDetailStatus => 'অবস্থা';

  @override
  String get rbDetailSummary => 'আলোচনার সারসংক্ষেপ';

  @override
  String rbDetailVotesAria(Object against, Object for_val, Object neutral) {
    return 'পক্ষে $for_val, বিপক্ষে $against, নিরপেক্ষ $neutral';
  }

  @override
  String get rbExportError => 'পিডিএফ তৈরি করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get rbFiltersAllStatuses => 'সব অবস্থা';

  @override
  String get rbFiltersAllTypes => 'সব ধরন';

  @override
  String get rbFiltersApply => 'খুঁজুন';

  @override
  String get rbFiltersClear => 'মুছুন';

  @override
  String get rbFiltersDateFrom => 'তারিখ থেকে';

  @override
  String get rbFiltersDateTo => 'তারিখ পর্যন্ত';

  @override
  String get rbFiltersSearch => 'খুঁজুন';

  @override
  String get rbFiltersSearchPlaceholder =>
      'সভা নম্বর, বিষয় বা সভাপতি দিয়ে খুঁজুন…';

  @override
  String get rbFiltersStatus => 'অবস্থা';

  @override
  String get rbFiltersType => 'সভার ধরন';

  @override
  String get rbFormAddResolution => 'সিদ্ধান্ত যোগ করুন';

  @override
  String get rbFormAgenda => 'আলোচ্যসূচি';

  @override
  String get rbFormAgendaSummary => 'আলোচ্যসূচি ও সারসংক্ষেপ';

  @override
  String get rbFormAssignee => 'দায়িত্বে (ঐচ্ছিক)';

  @override
  String get rbFormAssigneePlaceholder => 'কেউ নয়';

  @override
  String get rbFormAttachments => 'রেকর্ডিং ও সংযুক্তি (ঐচ্ছিক)';

  @override
  String get rbFormAttendance => 'উপস্থিতি';

  @override
  String get rbFormAttendancePlaceholder => 'সদস্য নির্বাচন করুন…';

  @override
  String get rbFormAutoNo => 'স্বয়ংক্রিয়ভাবে প্রস্তাবিত';

  @override
  String get rbFormChairperson => 'সভাপতি';

  @override
  String get rbFormChairpersonPlaceholder => 'সদস্য নির্বাচন করুন…';

  @override
  String get rbFormDate => 'তারিখ';

  @override
  String get rbFormDecision => 'সিদ্ধান্ত';

  @override
  String get rbFormDropzone =>
      'ফাইল যোগ করতে চাপ দিন — ভিডিও, অডিও, ছবি বা চ্যাট লগ';

  @override
  String get rbFormDropzoneHint => 'প্রতি ফাইল সর্বোচ্চ 100 MB';

  @override
  String get rbFormDueDate => 'শেষ তারিখ (ঐচ্ছিক)';

  @override
  String get rbFormDuplicateNo =>
      'এই সভা নম্বরটি ইতিমধ্যে ব্যবহৃত। অন্য নম্বর দিন।';

  @override
  String get rbFormEditTitle => 'সভা সম্পাদনা';

  @override
  String get rbFormFileTooLarge => 'একটি ফাইল 100 MB সীমা ছাড়িয়ে গেছে।';

  @override
  String get rbFormMarkAllPresent => 'সবাই উপস্থিত';

  @override
  String get rbFormMeetingInfo => 'সভার তথ্য';

  @override
  String get rbFormMeetingNo => 'সভা নম্বর';

  @override
  String get rbFormNextMeeting => 'পরবর্তী সভার তারিখ (ঐচ্ছিক)';

  @override
  String get rbFormNotify => 'সদস্যদের জন্য নোটিশ প্রকাশ করুন';

  @override
  String rbFormPresentCount(Object present, Object total) {
    return '$present/$total উপস্থিত';
  }

  @override
  String get rbFormRemoveFile => 'বাদ দিন';

  @override
  String get rbFormRemoveResolution => 'বাদ দিন';

  @override
  String get rbFormResolutions => 'গৃহীত সিদ্ধান্ত';

  @override
  String get rbFormSave => 'পরিবর্তন সংরক্ষণ করুন';

  @override
  String get rbFormStatus => 'অবস্থা';

  @override
  String get rbFormSubmit => 'সভার রেকর্ড সংরক্ষণ করুন';

  @override
  String get rbFormSubmitError =>
      'সভার রেকর্ড সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get rbFormSubtitle =>
      'সভা, উপস্থিতি ও সিদ্ধান্ত একসাথে এক বার জমা দিলেই সংরক্ষিত হবে।';

  @override
  String get rbFormSummary => 'আলোচনার সারসংক্ষেপ';

  @override
  String get rbFormTask => 'কাজ (ঐচ্ছিক)';

  @override
  String get rbFormTime => 'সময়';

  @override
  String get rbFormTitle => 'নতুন সভার রেকর্ড';

  @override
  String get rbFormType => 'সভার ধরন';

  @override
  String get rbFormVotesExceed =>
      'মোট ভোট উপস্থিত সদস্য সংখ্যার বেশি হতে পারে না।';

  @override
  String rbFormVotesExceedInline(Object present) {
    return 'একটি সিদ্ধান্তের মোট ভোট উপস্থিত সদস্য সংখ্যা ($present) এর বেশি হতে পারে না।';
  }

  @override
  String rbListAttendance(Object present, Object total) {
    return '$present/$total উপস্থিত';
  }

  @override
  String get rbListEmpty => 'এখনো কোনো সভার রেকর্ড নেই।';

  @override
  String get rbListEmptyFiltered =>
      'আপনার খোঁজার সাথে মেলে এমন কোনো সভা পাওয়া যায়নি।';

  @override
  String rbListResolutions(Object count) {
    return '$count টি সিদ্ধান্ত';
  }

  @override
  String get rbListTitle => 'সাম্প্রতিক সভা';

  @override
  String get rbLoadError => 'তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get rbNavNext => 'পরবর্তী';

  @override
  String get rbNavPrevious => 'পূর্ববর্তী';

  @override
  String get rbRecordingsDownload => 'ডাউনলোড';

  @override
  String get rbRecordingsDownloadError => 'ডাউনলোড ব্যর্থ হয়েছে।';

  @override
  String get rbRecordingsEmpty => 'এখনো কোনো রেকর্ডিং বা সংযুক্তি নেই।';

  @override
  String get rbRecordingsTitle => 'রেকর্ডিং ও সংযুক্তি';

  @override
  String get rbRecordingsUpload => 'ফাইল আপলোড';

  @override
  String get rbRecordingsUploadError =>
      'আপলোড ব্যর্থ হয়েছে। ফাইলের ধরন ও আকার দেখুন।';

  @override
  String get rbResolutionDone => 'সম্পন্ন';

  @override
  String get rbResolutionInProgress => 'চলমান';

  @override
  String get rbResolutionPending => 'অপেক্ষমাণ';

  @override
  String get rbStatusCancelled => 'বাতিল';

  @override
  String get rbStatusCompleted => 'সম্পন্ন';

  @override
  String get rbStatusScheduled => 'নির্ধারিত';

  @override
  String get rbSubtitle => 'সভার রেকর্ড, সিদ্ধান্ত ও উপস্থিতি — সব এক জায়গায়';

  @override
  String get rbSummaryAvgAttendance => 'গড় উপস্থিতি';

  @override
  String get rbSummaryOpenActions => 'অসম্পন্ন কাজ';

  @override
  String get rbSummaryThisYear => 'এই বছরের সভা';

  @override
  String get rbSummaryTitle => 'সারসংক্ষেপ';

  @override
  String get rbSummaryTotalMeetings => 'মোট সভা';

  @override
  String get rbTabsAttendance => 'উপস্থিতি';

  @override
  String get rbTabsOverview => 'সংক্ষিপ্ত বিবরণ';

  @override
  String get rbTabsRecordings => 'রেকর্ডিং';

  @override
  String get rbTabsResolutions => 'সিদ্ধান্ত';

  @override
  String get rbTitle => 'রেজোলিউশন বুক';

  @override
  String get rbTypeOffline => 'অফলাইন';

  @override
  String get rbTypeOnline => 'অনলাইন';

  @override
  String get rbUpcomingLabel => 'পরবর্তী সভা';

  @override
  String get rbVoteAgainst => 'বিপক্ষে';

  @override
  String get rbVoteFor => 'পক্ষে';

  @override
  String get rbVoteNeutral => 'নিরপেক্ষ';

  @override
  String get registrationAddressInfoCurrentAddressTitle => 'বর্তমান ঠিকানা';

  @override
  String get registrationAddressInfoDistrictLabel => 'জেলা';

  @override
  String get registrationAddressInfoDistrictRequired => 'জেলা আবশ্যক';

  @override
  String get registrationAddressInfoDivisionLabel => 'বিভাগ';

  @override
  String get registrationAddressInfoDivisionRequired => 'বিভাগ আবশ্যক';

  @override
  String get registrationAddressInfoHouseLabel => 'বাসা/হোল্ডিং নং';

  @override
  String get registrationAddressInfoHouseRequired => 'বাসা/হোল্ডিং নং আবশ্যক';

  @override
  String get registrationAddressInfoPermanentAddressTitle => 'স্থায়ী ঠিকানা';

  @override
  String get registrationAddressInfoPostOfficeLabel => 'ডাকঘর';

  @override
  String get registrationAddressInfoPostOfficeRequired => 'ডাকঘর আবশ্যক';

  @override
  String get registrationAddressInfoRoadLabel => 'রাস্তা/গ্রাম';

  @override
  String get registrationAddressInfoRoadRequired => 'রাস্তা/গ্রাম আবশ্যক';

  @override
  String get registrationAddressInfoSameAsCurrentLabel =>
      'বর্তমান ঠিকানার সাথে একই';

  @override
  String get registrationAddressInfoSelectPlaceholder => 'নির্বাচন করুন';

  @override
  String get registrationAddressInfoUpazilaLabel => 'উপজেলা/থানা';

  @override
  String get registrationAddressInfoUpazilaRequired => 'উপজেলা/থানা আবশ্যক';

  @override
  String get registrationConfirmationApplicantLabel => 'আবেদনকারী:';

  @override
  String get registrationConfirmationMessage =>
      'আপনার আবেদন সফলভাবে জমা হয়েছে। অনুগ্রহ করে যাচাই ও অনুমোদনের জন্য অপেক্ষা করুন।';

  @override
  String get registrationConfirmationNewFormButton => 'নতুন ফর্ম পূরণ করুন';

  @override
  String get registrationConfirmationOkButton => 'ঠিক আছে';

  @override
  String get registrationConfirmationReferenceLabel => 'আবেদন নং:';

  @override
  String get registrationConfirmationTitle => 'সাবমিট সফল হয়েছে!';

  @override
  String get registrationDeclarationConsentLabel =>
      'আমি সকল শর্তাবলীতে সম্মতি প্রদান করছি।';

  @override
  String get registrationDeclarationConsentRequired =>
      'অঙ্গীকারনামায় সম্মতি প্রদান আবশ্যক';

  @override
  String get registrationDeclarationText =>
      'আমি অঙ্গীকার করছি যে, উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটির গঠনতন্ত্র, নিয়ম-শৃঙ্খলা ও বিধি সংক্রান্ত সিদ্ধান্তসমূহ মেনে চলবো এবং সংগঠনের উদ্দেশ্য ও স্বার্থবিরোধী কোনো কর্মকাণ্ডে অংশগ্রহণ করবো না। সংগঠনের সিদ্ধান্তসমূহে সদস্যদের অধিকার, সম্পত্তির নিরাপত্তা, পারস্পরিক সহযোগিতা, সামাজিক কল্যাণ ও এলাকার উন্নয়নে দায়িত্বশীলভাবে সহযোগিতা করবো। উপরোক্ত তথ্যসমূহ আমার জ্ঞান ও বিশ্বাস অনুযায়ী সঠিক।';

  @override
  String get registrationDeclarationTitle => 'অঙ্গীকারনামা';

  @override
  String get registrationDraftDiscardDraft => 'বাতিল করে নতুন করে শুরু করুন';

  @override
  String get registrationDraftDraftRestoredToast =>
      'আপনার আগের অসম্পূর্ণ ফর্ম পুনরুদ্ধার করা হয়েছে';

  @override
  String get registrationDraftDraftSaved => 'খসড়া সংরক্ষিত';

  @override
  String get registrationDraftReattachFilesNotice =>
      'পুনরুদ্ধার করা ফর্মে সংযুক্ত ফাইলগুলো আবার সংযুক্ত করুন';

  @override
  String get registrationHeaderFormBadge => 'সদস্য নিবন্ধন ও মালিকানা তথ্য ফরম';

  @override
  String get registrationHeaderLoginLink => 'লগইন';

  @override
  String get registrationHeaderLogoAlt => 'সংগঠনের লোগো';

  @override
  String get registrationHeaderOrgLocation =>
      'উত্তর কাউন্দিয়া, সাভার, ঢাকা। | স্থাপিত : ২০২৬ ইং';

  @override
  String get registrationHeaderOrgName =>
      'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি';

  @override
  String get registrationHeaderOrgSubtitle =>
      '(সকল জমি, বাড়ি ও ফ্ল্যাট মালিকদের ঐক্যবদ্ধ অরাজনৈতিক আবাসন সংগঠন)';

  @override
  String get registrationHeaderStepperAriaLabel => 'নিবন্ধন ধাপসমূহ';

  @override
  String get registrationHeaderSubmissionDateLabel => 'নিবন্ধনের তারিখ';

  @override
  String get registrationMemberInfoClearPhotoButton => 'মুছুন';

  @override
  String get registrationMemberInfoDobLabel => 'জন্ম তারিখ';

  @override
  String get registrationMemberInfoDobRequired => 'জন্ম তারিখ আবশ্যক';

  @override
  String get registrationMemberInfoEmailInvalid => 'ই-মেইল সঠিক নয়';

  @override
  String get registrationMemberInfoEmailLabel => 'ই-মেইল';

  @override
  String get registrationMemberInfoEmailRequired => 'ই-মেইল আবশ্যক';

  @override
  String get registrationMemberInfoFatherOrHusbandLabel => 'পিতা/স্বামী';

  @override
  String get registrationMemberInfoFatherOrHusbandRequired =>
      'পিতা/স্বামী আবশ্যক';

  @override
  String get registrationMemberInfoFullNameLabel => 'পূর্ণ নাম';

  @override
  String get registrationMemberInfoFullNameRequired => 'পূর্ণ নাম আবশ্যক';

  @override
  String get registrationMemberInfoGenderFemale => 'মহিলা';

  @override
  String get registrationMemberInfoGenderLabel => 'লিঙ্গ';

  @override
  String get registrationMemberInfoGenderMale => 'পুরুষ';

  @override
  String get registrationMemberInfoGenderRequired => 'লিঙ্গ নির্বাচন করুন';

  @override
  String get registrationMemberInfoMemberPhotoRequired => 'সদস্যের ছবি আবশ্যক';

  @override
  String get registrationMemberInfoMobileInvalid =>
      'মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)';

  @override
  String get registrationMemberInfoMobileLabel => 'মোবাইল (WhatsApp)';

  @override
  String get registrationMemberInfoMobileRequired => 'মোবাইল আবশ্যক';

  @override
  String get registrationMemberInfoMotherLabel => 'মাতা';

  @override
  String get registrationMemberInfoMotherRequired => 'মাতা আবশ্যক';

  @override
  String get registrationMemberInfoNationalityLabel => 'জাতীয়তা';

  @override
  String get registrationMemberInfoNidInvalid =>
      'NID নম্বর ১০-১৭ সংখ্যার হতে হবে';

  @override
  String get registrationMemberInfoNidLabel => 'NID নং';

  @override
  String get registrationMemberInfoNidPlaceholder => '১০-১৭ সংখ্যা';

  @override
  String get registrationMemberInfoNidRequired => 'NID নম্বর আবশ্যক';

  @override
  String get registrationMemberInfoOccupationLabel => 'পেশা';

  @override
  String get registrationMemberInfoPhotoAlt => 'সদস্যের ছবি';

  @override
  String get registrationMemberInfoPhotoPlaceholder => 'সদস্যের ছবি';

  @override
  String get registrationMemberInfoPhotoSizeError =>
      'ছবির সাইজ ৩ এমবি-এর কম হতে হবে';

  @override
  String get registrationMemberInfoPhotoTypeError =>
      'ছবির ফাইল নির্বাচন করুন (JPG/PNG)';

  @override
  String get registrationNavNext => 'পরবর্তী';

  @override
  String get registrationNavPrevious => 'পূর্ববর্তী';

  @override
  String get registrationNavSubmit => 'ফর্ম সাবমিট করুন';

  @override
  String get registrationNavSubmitting => 'সাবমিট হচ্ছে...';

  @override
  String get registrationNomineeAddMore => 'আরও মনোনীত ব্যক্তি যোগ করুন';

  @override
  String get registrationNomineeAdditionalNomineesTitle =>
      'অতিরিক্ত মনোনীত ব্যক্তি';

  @override
  String get registrationNomineeAddressLabel => 'ঠিকানা';

  @override
  String get registrationNomineeMobileInvalid =>
      'মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)';

  @override
  String get registrationNomineeMobileLabel => 'মোবাইল';

  @override
  String get registrationNomineeMobileRequired => 'মোবাইল আবশ্যক';

  @override
  String get registrationNomineeNameLabel => 'নাম';

  @override
  String get registrationNomineeNameRequired => 'নাম আবশ্যক';

  @override
  String registrationNomineeNomineeNumberTitle(Object number) {
    return 'মনোনীত ব্যক্তি $number';
  }

  @override
  String get registrationNomineeRelationLabel => 'পিতা/স্বামী / সম্পর্ক';

  @override
  String get registrationNomineeRelationShortLabel => 'সম্পর্ক';

  @override
  String get registrationNomineeRemove => 'মুছুন';

  @override
  String get registrationNomineeSameAsUrgentContactLabel =>
      'জরুরি যোগাযোগের তথ্য থেকে একই তথ্য ব্যবহার করুন';

  @override
  String get registrationPaymentAccountNameLabel => 'হিসাবের নাম';

  @override
  String get registrationPaymentAccountNumberLabel => 'হিসাব নং';

  @override
  String get registrationPaymentAdmissionFeeHint =>
      'বর্তমান ভর্তি ফি — সংগঠন কর্তৃক নির্ধারিত, এখানে পরিবর্তনযোগ্য নয়';

  @override
  String get registrationPaymentAdmissionFeeLabel => 'ভর্তি ফি (টাকা)';

  @override
  String get registrationPaymentAdmissionFeeLoadFailed =>
      'বর্তমান ভর্তি ফি লোড করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get registrationPaymentAdmissionFeeLoading =>
      'বর্তমান ভর্তি ফি লোড হচ্ছে…';

  @override
  String get registrationPaymentAdmissionFeeRequired => 'ভর্তি ফি আবশ্যক';

  @override
  String get registrationPaymentAdmissionFeeRetry => 'পুনরায় চেষ্টা';

  @override
  String get registrationPaymentAttachReceipt => 'রসিদের ছবি সংযুক্ত করুন';

  @override
  String get registrationPaymentBankNameLabel => 'ব্যাংক';

  @override
  String get registrationPaymentBranchLabel => 'শাখা';

  @override
  String registrationPaymentFileSizeError(Object maxMb) {
    return 'ফাইলের সাইজ সর্বোচ্চ $maxMb এমবি হতে হবে';
  }

  @override
  String get registrationPaymentFileTypeError =>
      'শুধুমাত্র JPG, PNG বা PDF ফাইল গ্রহণযোগ্য';

  @override
  String registrationPaymentMaxFileSizeHint(Object maxMb) {
    return 'সর্বোচ্চ $maxMb এমবি (JPG/PNG/PDF)';
  }

  @override
  String get registrationPaymentMethodLabel => 'মাধ্যম';

  @override
  String get registrationPaymentMfsNumberLabel => 'MFS নম্বর';

  @override
  String get registrationPaymentPaymentMethodRequired =>
      'পেমেন্ট মাধ্যম আবশ্যক';

  @override
  String get registrationPaymentReceiptImageLabel => 'মানি রসিদের ছবি';

  @override
  String get registrationPaymentReceiptNoLabel => 'রসিদ নং/Transaction ID';

  @override
  String get registrationPaymentRemoveFile => 'মুছুন';

  @override
  String get registrationPaymentRoutingNumberLabel => 'রাউটিং নং';

  @override
  String registrationPaymentSubscriptionBaseSummary(Object amount) {
    return 'ভিত্তি: $amount টাকা';
  }

  @override
  String registrationPaymentSubscriptionExtraSummary(
      Object amount, Object extra) {
    return '+ অতিরিক্ত $extraটি শতাংশ (আংশিক শতাংশও পূর্ণ ধরা হয়) = $amount টাকা';
  }

  @override
  String get registrationPaymentSubscriptionHint =>
      'সংগঠন কর্তৃক নির্ধারিত, এখানে পরিবর্তনযোগ্য নয়';

  @override
  String get registrationPaymentSubscriptionLabel => 'চাঁদা (টাকা)';

  @override
  String get registrationPaymentSubscriptionLoadFailed =>
      'চাঁদার পরিমাণ হিসাব করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get registrationPaymentSubscriptionLoading =>
      'চাঁদার পরিমাণ হিসাব করা হচ্ছে…';

  @override
  String get registrationPaymentSubscriptionRequired => 'চাঁদা আবশ্যক';

  @override
  String get registrationPaymentSubscriptionRetry => 'পুনরায় চেষ্টা';

  @override
  String registrationPaymentTotalAmountSummary(Object amount) {
    return '= মোট $amount৳';
  }

  @override
  String get registrationPropertyApplicableDocsLabel => 'প্রযোজ্য কাগজ';

  @override
  String get registrationPropertyApplicableDocsRequired =>
      'প্রযোজ্য কাগজ নির্বাচন আবশ্যক';

  @override
  String get registrationPropertyAttachFileButton => 'ফাইল সংযুক্ত করুন';

  @override
  String get registrationPropertyCountLabel => 'সম্পত্তির সংখ্যা';

  @override
  String get registrationPropertyCountSelectPlaceholder => 'নির্বাচন করুন';

  @override
  String get registrationPropertyDagCsLabel => 'সিএস দাগ নং';

  @override
  String get registrationPropertyDagNoCsRequired => 'CS দাগ নং আবশ্যক';

  @override
  String get registrationPropertyDagNoLabel => 'দাগ নং';

  @override
  String get registrationPropertyDagNoRsRequired => 'RS দাগ নং আবশ্যক';

  @override
  String get registrationPropertyDagRsLabel => 'আরএস দাগ নং';

  @override
  String get registrationPropertyDocFileMissing =>
      'এই কাগজের ফাইল সংযুক্ত করা আবশ্যক';

  @override
  String registrationPropertyDocFileSizeError(Object maxMb) {
    return 'ফাইলের সাইজ সর্বোচ্চ $maxMb এমবি হতে হবে';
  }

  @override
  String get registrationPropertyDocFileTypeError =>
      'শুধুমাত্র JPG, PNG বা PDF ফাইল গ্রহণযোগ্য';

  @override
  String get registrationPropertyHoldingNumberLabel => 'হোল্ডিং নম্বর';

  @override
  String get registrationPropertyItemTitle => 'সম্পত্তি';

  @override
  String get registrationPropertyJointOwnerCountLabel => 'যৌথ মালিকগণের সংখ্যা';

  @override
  String get registrationPropertyJointOwnerCountRequired =>
      'যৌথ মালিকগণের সংখ্যা আবশ্যক';

  @override
  String get registrationPropertyKhatianNoLabel => 'খতিয়ান নং';

  @override
  String get registrationPropertyKhatianNoRequired => 'খতিয়ান নং আবশ্যক';

  @override
  String get registrationPropertyLandQuantityInvalid =>
      'মোট জমির পরিমাণ শূন্যের চেয়ে বেশি হতে হবে';

  @override
  String get registrationPropertyLandQuantityLabel =>
      'মোট জমির পরিমাণ (শতাংশ):';

  @override
  String get registrationPropertyLandQuantityPlaceholder => 'যেমন: ২.৫';

  @override
  String get registrationPropertyLandQuantityRequired =>
      'মোট জমির পরিমাণ আবশ্যক';

  @override
  String registrationPropertyMaxFileSizeNote(Object maxMb) {
    return 'সর্বোচ্চ $maxMb এমবি (JPG/PNG/PDF)';
  }

  @override
  String get registrationPropertyMyShareQuantityExceedsTotal =>
      'আমার অংশের পরিমাণ মোট জমির পরিমাণের চেয়ে বেশি হতে পারবে না';

  @override
  String get registrationPropertyMyShareQuantityInvalid =>
      'আমার অংশের পরিমাণ শূন্যের চেয়ে বেশি হতে হবে';

  @override
  String get registrationPropertyMyShareQuantityLabel =>
      'আমার অংশের পরিমাণ (শতাংশ):';

  @override
  String get registrationPropertyMyShareQuantityPlaceholder => 'যেমন: ১.২৫';

  @override
  String get registrationPropertyMyShareQuantityRequired =>
      'আমার অংশের পরিমাণ আবশ্যক';

  @override
  String get registrationPropertyOwnershipLabel => 'মালিকানা';

  @override
  String get registrationPropertyOwnershipRequired => 'মালিকানা আবশ্যক';

  @override
  String get registrationPropertyRemoveFileButton => 'মুছুন';

  @override
  String get registrationPropertyTypeLabel => 'সম্পত্তির ধরন';

  @override
  String get registrationPropertyTypeOtherPlaceholder => 'বিস্তারিত লিখুন';

  @override
  String get registrationPropertyTypeRequired => 'সম্পত্তির ধরন আবশ্যক';

  @override
  String get registrationReviewDeclarationAccepted =>
      'সম্মতি প্রদান করা হয়েছে';

  @override
  String get registrationReviewDeclarationNotAccepted =>
      'সম্মতি প্রদান করা হয়নি';

  @override
  String get registrationReviewDeclarationTitle => 'অঙ্গীকার';

  @override
  String get registrationReviewEdit => 'সম্পাদনা করুন';

  @override
  String get registrationReviewEmailLabel => 'ই-মেইল';

  @override
  String get registrationReviewFatherOrHusbandLabel => 'পিতা/স্বামী';

  @override
  String get registrationReviewIntro =>
      'সাবমিট করার আগে নিচের তথ্যগুলো যাচাই করে নিন।';

  @override
  String get registrationReviewMemberInfoTitle => 'সদস্যের তথ্য';

  @override
  String get registrationReviewMethodLabel => 'মাধ্যম';

  @override
  String get registrationReviewMobileLabel => 'মোবাইল';

  @override
  String get registrationReviewNameLabel => 'নাম';

  @override
  String get registrationReviewNomineeCountLabel => 'নমিনি সংখ্যা';

  @override
  String registrationReviewNomineeCountSummary(Object count) {
    return '$count জন';
  }

  @override
  String get registrationReviewPaymentInfoTitle => 'পেমেন্ট তথ্য';

  @override
  String get registrationReviewPropertyInfoTitle => 'সম্পত্তির তথ্য';

  @override
  String get registrationReviewSubscriptionLabel => 'চাঁদা';

  @override
  String registrationReviewTotalPropertiesSummary(Object count) {
    return 'মোট সম্পত্তি: $count টি';
  }

  @override
  String get registrationReviewUrgentContactAndNomineeTitle =>
      'জরুরি যোগাযোগ ও নমিনি';

  @override
  String get registrationReviewUrgentContactLabel => 'জরুরি যোগাযোগ';

  @override
  String get registrationSignatureSectionTitle => 'স্বাক্ষর';

  @override
  String get registrationSignatureHint => 'নিচের বাক্সে স্বাক্ষর আঁকুন';

  @override
  String get registrationSignatureClearButton => 'মুছে ফেলুন';

  @override
  String get registrationSignatureSaveButton => 'স্বাক্ষর সংরক্ষণ';

  @override
  String get registrationSignatureSavedButton => 'স্বাক্ষর সংরক্ষিত';

  @override
  String get registrationStepShortLabelsMemberInfo => 'সদস্য';

  @override
  String get registrationStepShortLabelsNominee => 'নমিনি';

  @override
  String get registrationStepShortLabelsPayment => 'পেমেন্ট';

  @override
  String get registrationStepShortLabelsProperty => 'সম্পত্তি';

  @override
  String get registrationStepShortLabelsReview => 'পর্যালোচনা';

  @override
  String get registrationStepShortLabelsSignature => 'স্বাক্ষর';

  @override
  String get registrationStepTitlesAddressInfo => '২. ঠিকানার তথ্য';

  @override
  String get registrationStepTitlesContactAndNominee => 'জরুরি যোগাযোগ ও নমিনি';

  @override
  String get registrationStepTitlesDeclarationAndSignature =>
      'অঙ্গীকার ও স্বাক্ষর';

  @override
  String get registrationStepTitlesMemberInfo => '১. সদস্যের ব্যক্তিগত তথ্য';

  @override
  String get registrationStepTitlesNominee => '৫. নমিনি';

  @override
  String get registrationStepTitlesPayment => 'পেমেন্টের তথ্য';

  @override
  String get registrationStepTitlesProperty =>
      '৩. আবাসন / সম্পত্তির মালিকানা তথ্য';

  @override
  String get registrationStepTitlesReview => 'পর্যালোচনা';

  @override
  String get registrationStepTitlesUrgentContact => '৪. জরুরি যোগাযোগ';

  @override
  String get registrationSubmitDuplicateApproved =>
      'আপনি ইতিমধ্যে সদস্য হিসেবে নিবন্ধিত। অনুগ্রহ করে লগইন করুন।';

  @override
  String get registrationSubmitDuplicateGeneric =>
      'এই তথ্য দিয়ে একটি আবেদন ইতিমধ্যে বিদ্যমান।';

  @override
  String get registrationSubmitDuplicatePending =>
      'আপনার আবেদনটি অপেক্ষমাণ। অনুগ্রহ করে নিশ্চিতকরণের জন্য অপেক্ষা করুন।';

  @override
  String get registrationSubmitDuplicateTitle => 'আবেদন ইতিমধ্যে বিদ্যমান';

  @override
  String registrationSubmitErrorCode(Object status) {
    return 'কোড $status';
  }

  @override
  String get registrationSubmitFeeNotConfigured =>
      'ভর্তি ফি এখনো নির্ধারণ করা হয়নি। অনুগ্রহ করে অফিসে যোগাযোগ করুন।';

  @override
  String get registrationSubmitFieldsAdmissionFee => 'ভর্তি ফি';

  @override
  String get registrationSubmitFieldsCurrentAddress => 'বর্তমান ঠিকানা';

  @override
  String get registrationSubmitFieldsDob => 'জন্ম তারিখ';

  @override
  String get registrationSubmitFieldsEmail => 'ইমেইল';

  @override
  String get registrationSubmitFieldsFatherOrHusband => 'পিতা/স্বামীর নাম';

  @override
  String get registrationSubmitFieldsFullName => 'পূর্ণ নাম';

  @override
  String get registrationSubmitFieldsGender => 'লিঙ্গ';

  @override
  String get registrationSubmitFieldsMemberSignature => 'সদস্যের স্বাক্ষর';

  @override
  String get registrationSubmitFieldsMobile => 'মোবাইল';

  @override
  String get registrationSubmitFieldsMother => 'মাতার নাম';

  @override
  String get registrationSubmitFieldsNationality => 'জাতীয়তা';

  @override
  String get registrationSubmitFieldsNid => 'জাতীয় পরিচয়পত্র নম্বর';

  @override
  String get registrationSubmitFieldsNominees => 'নমিনি';

  @override
  String get registrationSubmitFieldsOccupation => 'পেশা';

  @override
  String get registrationSubmitFieldsPaymentMethod => 'পরিশোধের মাধ্যম';

  @override
  String get registrationSubmitFieldsPermanentAddress => 'স্থায়ী ঠিকানা';

  @override
  String get registrationSubmitFieldsProperties => 'সম্পত্তি';

  @override
  String get registrationSubmitFieldsReceiptNo => 'রসিদ নম্বর';

  @override
  String get registrationSubmitFieldsSubmissionDate => 'নিবন্ধনের তারিখ';

  @override
  String get registrationSubmitFieldsSubscription => 'মাসিক চাঁদা';

  @override
  String get registrationSubmitFieldsUrgentContactAddress =>
      'জরুরি যোগাযোগের ঠিকানা';

  @override
  String get registrationSubmitFieldsUrgentContactMobile =>
      'জরুরি যোগাযোগের মোবাইল';

  @override
  String get registrationSubmitFieldsUrgentContactName => 'জরুরি যোগাযোগের নাম';

  @override
  String get registrationSubmitFieldsUrgentContactRelation =>
      'জরুরি যোগাযোগের সম্পর্ক';

  @override
  String get registrationSubmitFileTooLarge =>
      'আপলোড করা ছবি বা ফাইল খুব বড়। ছোট ফাইল দিন (সর্বোচ্চ ১০ MB)।';

  @override
  String get registrationSubmitGenericError => 'সাবমিটে সমস্যা হয়েছে';

  @override
  String get registrationSubmitInvalidData =>
      'কিছু তথ্য বা আপলোড করা ফাইল সঠিক নয়। যাচাই করে আবার চেষ্টা করুন।';

  @override
  String get registrationSubmitInvalidShareQuantity =>
      'জমির অংশের পরিমাণ সঠিক নয়। সম্পত্তির ধাপটি যাচাই করুন।';

  @override
  String get registrationSubmitNetworkError =>
      'নেটওয়ার্কে সমস্যা। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get registrationSubmitReasonsInvalid => 'তথ্যটি সঠিক নয়';

  @override
  String get registrationSubmitReasonsRequired => 'এই তথ্যটি আবশ্যক';

  @override
  String get registrationSubmitServerError =>
      'সার্ভারে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';

  @override
  String get registrationUrgentContactAddressLabel => 'ঠিকানা';

  @override
  String get registrationUrgentContactMobileInvalid =>
      'মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)';

  @override
  String get registrationUrgentContactMobileLabel => 'মোবাইল';

  @override
  String get registrationUrgentContactMobileRequired => 'মোবাইল আবশ্যক';

  @override
  String get registrationUrgentContactNameLabel => 'নাম';

  @override
  String get registrationUrgentContactNameRequired => 'নাম আবশ্যক';

  @override
  String get registrationUrgentContactRelationLabel => 'সম্পর্ক';

  @override
  String get registrationValidationApplicableDocsRequired =>
      'প্রযোজ্য কাগজ নির্বাচন আবশ্যক';

  @override
  String get registrationValidationCurrentAddressLabel => 'বর্তমান ঠিকানা';

  @override
  String get registrationValidationDobRequired => 'জন্ম তারিখ আবশ্যক';

  @override
  String registrationValidationDocFileRequired(Object docType) {
    return '\"$docType\" এর জন্য ফাইল সংযুক্ত করা আবশ্যক';
  }

  @override
  String get registrationValidationEmailInvalid => 'ই-মেইল সঠিক নয়';

  @override
  String get registrationValidationFatherOrHusbandRequired =>
      'পিতা/স্বামী আবশ্যক';

  @override
  String get registrationValidationFullNameRequired => 'পূর্ণ নাম আবশ্যক';

  @override
  String get registrationValidationGenderRequired => 'লিঙ্গ নির্বাচন করুন';

  @override
  String get registrationValidationJointOwnerCountRequired =>
      'যৌথ মালিকগণের সংখ্যা আবশ্যক';

  @override
  String get registrationValidationLandQuantityInvalid =>
      'মোট জমির পরিমাণ শূন্যের চেয়ে বেশি হতে হবে';

  @override
  String get registrationValidationLandQuantityRequired =>
      'মোট জমির পরিমাণ আবশ্যক';

  @override
  String get registrationValidationMobileInvalid =>
      'মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)';

  @override
  String get registrationValidationMobileRequired => 'মোবাইল আবশ্যক';

  @override
  String get registrationValidationMotherRequired => 'মাতা আবশ্যক';

  @override
  String get registrationValidationMyShareQuantityExceedsTotal =>
      'আমার অংশের পরিমাণ মোট জমির পরিমাণের চেয়ে বেশি হতে পারবে না';

  @override
  String get registrationValidationMyShareQuantityInvalid =>
      'আমার অংশের পরিমাণ শূন্যের চেয়ে বেশি হতে হবে';

  @override
  String get registrationValidationMyShareQuantityRequired =>
      'আমার অংশের পরিমাণ আবশ্যক';

  @override
  String get registrationValidationNameRequired => 'নাম আবশ্যক';

  @override
  String get registrationValidationNidInvalid =>
      'NID নম্বর ১০-১৭ সংখ্যার হতে হবে';

  @override
  String registrationValidationNomineeLabel(Object number) {
    return 'মনোনীত ব্যক্তি #$number';
  }

  @override
  String get registrationValidationOwnershipRequired => 'মালিকানা আবশ্যক';

  @override
  String get registrationValidationPermanentAddressLabel => 'স্থায়ী ঠিকানা';

  @override
  String get registrationValidationPropertyCountRequired =>
      'সম্পত্তির সংখ্যা নির্বাচন করুন';

  @override
  String registrationValidationPropertyLabel(Object number) {
    return 'সম্পত্তি #$number';
  }

  @override
  String get registrationValidationPropertyTypeRequired =>
      'সম্পত্তির ধরন আবশ্যক';

  @override
  String get registrationValidationUrgentContactLabel => 'জরুরি যোগাযোগ';

  @override
  String welcome(Object name) {
    return 'স্বাগতম, $name';
  }

  @override
  String get brandOrgName => 'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সমিতি';

  @override
  String get commonLogout => 'লগ আউট';

  @override
  String get commonLanguage => 'ভাষা';

  @override
  String get commonTheme => 'থিম';

  @override
  String get commonStatusPending => 'অপেক্ষমাণ';

  @override
  String get commonStatusApproved => 'অনুমোদিত';

  @override
  String get commonStatusRejected => 'প্রত্যাখ্যাত';

  @override
  String get commonNoData => 'কোনো তথ্য পাওয়া যায়নি';

  @override
  String get commonNetworkError => 'নেটওয়ার্ক সমস্যা — আবার চেষ্টা করুন';

  @override
  String get commonServerError =>
      'সার্ভারে সমস্যা হয়েছে — কিছুক্ষণ পরে চেষ্টা করুন';

  @override
  String get commonUnauthorized => 'অনুমতি নেই — আবার লগ ইন করুন';

  @override
  String get commonConfirmAction => 'নিশ্চিত করুন';

  @override
  String get superadminTabsRoles => 'ভূমিকা';

  @override
  String get superadminTabsUsers => 'ব্যবহারকারী';

  @override
  String get superadminRolesEmpty => 'কোনো ভূমিকা পাওয়া যায়নি।';

  @override
  String get superadminUsersEmpty => 'এখনও কোনো অ্যাডমিনিস্ট্রেটর নেই।';

  @override
  String get superadminRoleAdministrator => 'অ্যাডমিনিস্ট্রেটর';

  @override
  String get superadminRoleExecutiveCommittee => 'নির্বাহী কমিটি';

  @override
  String get superadminRoleSuperAdmin => 'সুপার অ্যাডমিন';

  @override
  String get superadminAuditClearFilters => 'ফিল্টার সরিয়ে ফেলুন';

  @override
  String get memberProfileCurrentHouseLabel => 'বর্তমান বাড়ি';

  @override
  String get memberProfileCurrentRoadLabel => 'বর্তমান রাস্তা';

  @override
  String get memberProfileCurrentPostOfficeLabel => 'বর্তমান ডাকঘর';

  @override
  String get memberProfileCurrentUpazilaLabel => 'বর্তমান উপজেলা';

  @override
  String get memberProfileCurrentDistrictLabel => 'বর্তমান জেলা';

  @override
  String get memberProfileCurrentDivisionLabel => 'বর্তমান বিভাগ';

  @override
  String get memberProfileUrgentNameLabel => 'যোগাযোগের নাম';

  @override
  String get memberProfileUrgentMobileLabel => 'যোগাযোগের মোবাইল';

  @override
  String get memberProfileMobileInvalid =>
      'সঠিক মোবাইল নম্বর দিন (যেমন +8801XXXXXXXXX)';

  @override
  String get memberProfilePropertyTypesLabel => 'সম্পত্তির ধরন';

  @override
  String get attachmentViewerMissing => 'ফাইলটি সার্ভারে নেই।';

  @override
  String get attachmentViewerDownloadFailed =>
      'ডাউনলোড ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get attachmentViewerDownloadStarted => 'ডাউনলোড শুরু হয়েছে।';

  @override
  String get attachmentViewerPreviewUnavailable =>
      'এই ফাইল ধরনটি অ্যাপে প্রিভিউ করা যায় না।';

  @override
  String get attachmentViewerDownloadOpen => 'ডাউনলোড করে খুলুন';

  @override
  String get memberFundTransparencyFiltersDateFrom => 'শুরুর তারিখ';

  @override
  String get memberFundTransparencyFiltersDateTo => 'শেষ তারিখ';

  @override
  String get adminRoadmapStatusPlanned => 'পরিকল্পিত';

  @override
  String get adminRoadmapStatusInProgress => 'চলমান';

  @override
  String get adminRoadmapStatusDone => 'সম্পন্ন';

  @override
  String get adminPropertyRequestsPayloadType => 'জমির ধরন';

  @override
  String get adminPropertyRequestsPayloadKhatianNo => 'খতিয়ান নং';

  @override
  String get adminPropertyRequestsPayloadDagNoCs => 'সিএস দাগ নং';

  @override
  String get adminPropertyRequestsPayloadDagNoRs => 'আরএস দাগ নং';

  @override
  String get adminPropertyRequestsPayloadHoldingNumber => 'হোল্ডিং নং';

  @override
  String get adminPropertyRequestsPayloadLandQuantity => 'জমির পরিমাণ';

  @override
  String get adminPropertyRequestsPayloadMyShareQuantity => 'আমার অংশ';

  @override
  String get adminPropertyRequestsPayloadOwnership => 'মালিকানা';

  @override
  String get adminPropertyRequestsPayloadCoOwners => 'যৌথ মালিক';

  @override
  String get adminPropertyRequestsPayloadDocs => 'দলিলপত্র';

  @override
  String get adminSocietyCostsSummaryMemberBilled => 'সদস্যদের বকেয়া';

  @override
  String get adminFinanceManagementFiltersApply => 'প্রয়োগ করুন';

  @override
  String get navNeighbours => 'প্রতিবেশী তথ্য';

  @override
  String get memberNeighboursTitle => 'প্রতিবেশী তথ্য';

  @override
  String memberNeighboursSubtitle(Object count) {
    return 'আপনার দাগ ও আশেপাশের নিকটতম $countটি দাগের মালিকদের সাথে সহজে যোগাযোগ করুন';
  }

  @override
  String get memberNeighboursPrivacyNote =>
      'এই তথ্য শুধুমাত্র প্রতিবেশীদের সাথে যোগাযোগের জন্য — অন্য কারো সাথে শেয়ার করবেন না।';

  @override
  String get memberNeighboursDagTypeLabel => 'দাগের ধরন';

  @override
  String get memberNeighboursDagTypeRs => 'আরএস দাগ';

  @override
  String get memberNeighboursDagTypeCs => 'সিএস দাগ';

  @override
  String get memberNeighboursOwnDag => 'আপনার দাগ';

  @override
  String get memberNeighboursTableOwnerName => 'মালিকের নাম';

  @override
  String get memberNeighboursTableMobile => 'মোবাইল নম্বর';

  @override
  String get memberNeighboursTableLandQuantity => 'জমির পরিমাণ';

  @override
  String get memberNeighboursTableRsDag => 'আরএস দাগ';

  @override
  String get memberNeighboursTableCsDag => 'সিএস দাগ';

  @override
  String get memberNeighboursTablePosition => 'অবস্থান';

  @override
  String get memberNeighboursTableContact => 'যোগাযোগ';

  @override
  String get memberNeighboursPositionSameDag => 'আপনার দাগে';

  @override
  String get memberNeighboursPositionAdjacent => 'পাশের দাগ';

  @override
  String get memberNeighboursPositionNear => 'কাছাকাছি দাগ';

  @override
  String memberNeighboursLandUnit(Object value) {
    return '$value শতাংশ';
  }

  @override
  String get memberNeighboursCall => 'কল';

  @override
  String memberNeighboursCallAria(Object name) {
    return '$name-কে কল করুন';
  }

  @override
  String get memberNeighboursWhatsapp => 'হোয়াটসঅ্যাপ';

  @override
  String memberNeighboursWhatsappAria(Object name) {
    return '$name-কে হোয়াটসঅ্যাপে বার্তা পাঠান';
  }

  @override
  String get memberNeighboursContactHidden => 'নম্বর গোপন রাখা হয়েছে';

  @override
  String get memberNeighboursEmptyState =>
      'আপনার দাগের আশেপাশে কোনো নিবন্ধিত সদস্য পাওয়া যায়নি';

  @override
  String get memberNeighboursEmptyHint =>
      'নতুন সদস্য যুক্ত হলে এখানে দেখা যাবে।';

  @override
  String get memberNeighboursNoProperties =>
      'আপনার প্রোফাইলে কোনো সম্পত্তি যুক্ত নেই।';

  @override
  String memberNeighboursNoDag(Object type) {
    return 'এই সম্পত্তিতে $type নম্বর নেই — অন্য দাগের ধরন বেছে নিন।';
  }

  @override
  String get memberNeighboursLoadError => 'প্রতিবেশী তথ্য লোড করা যায়নি।';

  @override
  String get memberNeighboursRateLimited =>
      'অনেকবার খোঁজা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।';

  @override
  String get memberNeighboursApprovedOnly =>
      'শুধুমাত্র অনুমোদিত সদস্যরা প্রতিবেশী তথ্য দেখতে পারেন।';

  @override
  String get memberNeighboursDialerUnavailable =>
      'এই ডিভাইসে কল করা যাচ্ছে না।';

  @override
  String get memberNeighboursWhatsappUnavailable =>
      'হোয়াটসঅ্যাপ খোলা যাচ্ছে না।';

  @override
  String get memberProfileNeighbourDirectoryLabel =>
      'প্রতিবেশী তথ্যে আমার মোবাইল নম্বর দেখান';

  @override
  String get memberProfileNeighbourDirectoryHint =>
      'বন্ধ করলে প্রতিবেশীরা শুধু আপনার নাম, জমির পরিমাণ ও দাগ দেখবেন।';

  @override
  String get navPlotMap => 'জমির সীমানা';

  @override
  String get boundaryTitle => 'জমির সীমানা';

  @override
  String get boundarySubtitle =>
      'ম্যাপে প্লটের সীমানা দেখুন ও নিজের সীমানা আঁকুন';

  @override
  String get boundaryViewOnMap => 'ম্যাপে দেখুন';

  @override
  String get boundaryDraw => 'সীমানা আঁকুন';

  @override
  String get boundaryDisclaimer =>
      'এটি সদস্য-চিহ্নিত আনুমানিক সীমানা; সরকারি জরিপ বা দলিলের বিকল্প নয়।';

  @override
  String get boundaryStatusDraft => 'খসড়া';

  @override
  String get boundaryStatusPendingReview => 'অনুমোদনের অপেক্ষায়';

  @override
  String get boundaryStatusApproved => 'অনুমোদিত';

  @override
  String get boundaryStatusRejected => 'প্রত্যাখ্যাত';

  @override
  String get boundaryStatusDisputed => 'মতবিরোধ';

  @override
  String get boundaryStatusMine => 'আমার সীমানা';

  @override
  String get boundaryOwnerTitle => 'মালিকের তথ্য';

  @override
  String get boundaryOwnerContactHidden => 'যোগাযোগ গোপন রাখা হয়েছে';

  @override
  String get boundaryCall => 'কল';

  @override
  String get boundaryWhatsapp => 'হোয়াটসঅ্যাপ';

  @override
  String get boundaryRsDag => 'আরএস দাগ';

  @override
  String get boundaryCsDag => 'সিএস দাগ';

  @override
  String get boundaryLandQuantity => 'জমির পরিমাণ';

  @override
  String get boundaryAreaLabel => 'এলাকা';

  @override
  String boundaryAreaValues(Object sqm, Object shotangsho) {
    return '$sqm বর্গমিটার · $shotangsho শতাংশ';
  }

  @override
  String get boundaryAreaEstimateTag => 'আনুমানিক';

  @override
  String get boundaryOwnerLoadError => 'মালিকের তথ্য আনা যায়নি।';

  @override
  String get boundaryLoadError => 'ম্যাপের তথ্য আনা যায়নি।';

  @override
  String get boundarySearchDagHint => 'দাগ নম্বর দিয়ে খুঁজুন';

  @override
  String get boundarySearchNoMatch =>
      'এই দাগ নম্বরে কোনো সীমানা পাওয়া যায়নি।';

  @override
  String get boundaryMyLocation => 'আমার অবস্থান';

  @override
  String get boundaryLayerStreet => 'স্ট্রিট';

  @override
  String get boundaryLayerSatellite => 'স্যাটেলাইট';

  @override
  String get boundaryReport => 'রিপোর্ট করুন';

  @override
  String get boundaryReportNoteHint => 'সমস্যাটি লিখুন';

  @override
  String get boundaryReportSubmit => 'রিপোর্ট পাঠান';

  @override
  String get boundaryReportSent => 'রিপোর্ট গৃহীত হয়েছে।';

  @override
  String get boundaryReportError => 'রিপোর্ট পাঠানো যায়নি।';

  @override
  String get boundaryEditorTitle => 'সীমানা আঁকুন';

  @override
  String get boundaryEditorAddHint =>
      'ম্যাপে ট্যাপ করে পয়েন্ট যোগ করুন; পয়েন্ট ড্র্যাগ করে সরান।';

  @override
  String get boundaryEditorUndo => 'আনডু';

  @override
  String get boundaryEditorClear => 'মুছুন';

  @override
  String get boundaryEditorSave => 'জমা দিন';

  @override
  String get boundaryEditorPropertyLabel => 'নিজের প্লট';

  @override
  String get boundaryEditorNoProperty =>
      'সীমানা ছাড়া কোনো প্লট পাওয়া যায়নি।';

  @override
  String boundaryEditorVertices(Object count) {
    return 'পয়েন্ট: $count';
  }

  @override
  String get boundarySaveSuccess =>
      'সীমানা জমা হয়েছে; এখন অনুমোদনের অপেক্ষায় আছে।';

  @override
  String get boundaryEditExisting => 'সীমানা সম্পাদনা';

  @override
  String get boundaryErrorTooFewPoints => 'কমপক্ষে ৩টি পয়েন্ট প্রয়োজন।';

  @override
  String get boundaryErrorSelfIntersecting => 'সীমানার রেখা নিজেকে ছেদ করছে।';

  @override
  String get boundaryErrorOutsideSociety =>
      'সীমানা সমিতির এলাকার বাইরে চলে গেছে।';

  @override
  String get boundaryErrorZeroArea =>
      'এলাকা প্রায় শূন্য; পয়েন্টগুলো আরও ছড়িয়ে দিন।';

  @override
  String get boundaryErrorTooManyVertices =>
      'সর্বোচ্চ পয়েন্ট সংখ্যা অতিক্রম হয়েছে।';

  @override
  String get boundaryErrorInvalidGeometry => 'সীমানার আকার অবৈধ।';

  @override
  String get boundaryErrorNotYourProperty =>
      'অন্যের প্লটের সীমানা আঁকা যাবে না।';

  @override
  String get boundaryErrorBoundaryExists => 'এই প্লটের সীমানা আগেই আছে।';

  @override
  String get boundaryErrorRateLimited =>
      'অনেকবার চেষ্টা হয়েছে; কিছুক্ষণ পর আবার চেষ্টা করুন।';

  @override
  String get boundaryErrorNotApproved => 'এই সীমানা এখনো অনুমোদিত হয়নি।';

  @override
  String get boundaryErrorGeneric => 'সীমানা সংরক্ষণ করা যায়নি।';

  @override
  String get boundaryReviewNote => 'পর্যালোচনার মন্তব্য';

  @override
  String get boundaryMobile => 'মোবাইল';
}
