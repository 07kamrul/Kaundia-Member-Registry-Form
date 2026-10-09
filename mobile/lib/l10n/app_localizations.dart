import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en')
  ];

  /// No description provided for @adminAuditLogDetailsClose.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করুন'**
  String get adminAuditLogDetailsClose;

  /// No description provided for @adminAuditLogDetailsTitle.
  ///
  /// In bn, this message translates to:
  /// **'এন্ট্রির বিস্তারিত'**
  String get adminAuditLogDetailsTitle;

  /// No description provided for @adminAuditLogDetailsView.
  ///
  /// In bn, this message translates to:
  /// **'বিস্তারিত'**
  String get adminAuditLogDetailsView;

  /// No description provided for @adminAuditLogErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'অডিট লগ লোড করা যায়নি।'**
  String get adminAuditLogErrorsLoadFailed;

  /// No description provided for @adminAuditLogFiltersAction.
  ///
  /// In bn, this message translates to:
  /// **'কার্যক্রম'**
  String get adminAuditLogFiltersAction;

  /// No description provided for @adminAuditLogFiltersActor.
  ///
  /// In bn, this message translates to:
  /// **'প্রশাসক'**
  String get adminAuditLogFiltersActor;

  /// No description provided for @adminAuditLogFiltersAll.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get adminAuditLogFiltersAll;

  /// No description provided for @adminAuditLogFiltersDateFrom.
  ///
  /// In bn, this message translates to:
  /// **'শুরুর তারিখ'**
  String get adminAuditLogFiltersDateFrom;

  /// No description provided for @adminAuditLogFiltersDateTo.
  ///
  /// In bn, this message translates to:
  /// **'শেষের তারিখ'**
  String get adminAuditLogFiltersDateTo;

  /// No description provided for @adminAuditLogFiltersEntityType.
  ///
  /// In bn, this message translates to:
  /// **'সত্তার ধরন'**
  String get adminAuditLogFiltersEntityType;

  /// No description provided for @adminAuditLogNoEntries.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো অডিট লগ এন্ট্রি নেই।'**
  String get adminAuditLogNoEntries;

  /// No description provided for @adminAuditLogNoEntriesMatch.
  ///
  /// In bn, this message translates to:
  /// **'এই ফিল্টারে কোনো এন্ট্রি মেলেনি।'**
  String get adminAuditLogNoEntriesMatch;

  /// No description provided for @adminAuditLogPaginationNext.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী'**
  String get adminAuditLogPaginationNext;

  /// No description provided for @adminAuditLogPaginationPageSize.
  ///
  /// In bn, this message translates to:
  /// **'প্রতি পৃষ্ঠায়'**
  String get adminAuditLogPaginationPageSize;

  /// No description provided for @adminAuditLogPaginationPrev.
  ///
  /// In bn, this message translates to:
  /// **'পূর্ববর্তী'**
  String get adminAuditLogPaginationPrev;

  /// No description provided for @adminAuditLogPaginationRange.
  ///
  /// In bn, this message translates to:
  /// **'{from_val}–{to_val} / {total}'**
  String adminAuditLogPaginationRange(
      Object from_val, Object to_val, Object total);

  /// No description provided for @adminAuditLogSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'কে কখন কী অনুমোদন, প্রত্যাখ্যান বা পরিবর্তন করেছেন'**
  String get adminAuditLogSubtitle;

  /// No description provided for @adminAuditLogTableAction.
  ///
  /// In bn, this message translates to:
  /// **'কার্যক্রম'**
  String get adminAuditLogTableAction;

  /// No description provided for @adminAuditLogTableActor.
  ///
  /// In bn, this message translates to:
  /// **'প্রশাসক'**
  String get adminAuditLogTableActor;

  /// No description provided for @adminAuditLogTableDetail.
  ///
  /// In bn, this message translates to:
  /// **'বিস্তারিত'**
  String get adminAuditLogTableDetail;

  /// No description provided for @adminAuditLogTableEntity.
  ///
  /// In bn, this message translates to:
  /// **'সত্তা'**
  String get adminAuditLogTableEntity;

  /// No description provided for @adminAuditLogTableTime.
  ///
  /// In bn, this message translates to:
  /// **'সময়'**
  String get adminAuditLogTableTime;

  /// No description provided for @adminAuditLogTitle.
  ///
  /// In bn, this message translates to:
  /// **'অডিট লগ'**
  String get adminAuditLogTitle;

  /// No description provided for @adminConfigListsActionsCancel.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল করুন'**
  String get adminConfigListsActionsCancel;

  /// No description provided for @adminConfigListsActionsEditLabel.
  ///
  /// In bn, this message translates to:
  /// **'লেবেল সম্পাদনা করুন'**
  String get adminConfigListsActionsEditLabel;

  /// No description provided for @adminConfigListsActionsMoveDown.
  ///
  /// In bn, this message translates to:
  /// **'নিচে সরান'**
  String get adminConfigListsActionsMoveDown;

  /// No description provided for @adminConfigListsActionsMoveUp.
  ///
  /// In bn, this message translates to:
  /// **'উপরে সরান'**
  String get adminConfigListsActionsMoveUp;

  /// No description provided for @adminConfigListsActionsSave.
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষণ করুন'**
  String get adminConfigListsActionsSave;

  /// No description provided for @adminConfigListsActivate.
  ///
  /// In bn, this message translates to:
  /// **'সক্রিয় করুন'**
  String get adminConfigListsActivate;

  /// No description provided for @adminConfigListsActive.
  ///
  /// In bn, this message translates to:
  /// **'সক্রিয়'**
  String get adminConfigListsActive;

  /// No description provided for @adminConfigListsAddItem.
  ///
  /// In bn, this message translates to:
  /// **'নতুন আইটেম যোগ করুন'**
  String get adminConfigListsAddItem;

  /// No description provided for @adminConfigListsCategoriesDocumentType.
  ///
  /// In bn, this message translates to:
  /// **'দলিলের ধরন'**
  String get adminConfigListsCategoriesDocumentType;

  /// No description provided for @adminConfigListsCategoriesEventCategory.
  ///
  /// In bn, this message translates to:
  /// **'ইভেন্ট বিভাগ'**
  String get adminConfigListsCategoriesEventCategory;

  /// No description provided for @adminConfigListsCategoriesFinanceExpenseCategory.
  ///
  /// In bn, this message translates to:
  /// **'ব্যয়ের খাত (ফান্ড)'**
  String get adminConfigListsCategoriesFinanceExpenseCategory;

  /// No description provided for @adminConfigListsCategoriesFinanceIncomeCategory.
  ///
  /// In bn, this message translates to:
  /// **'আয়ের খাত (ফান্ড)'**
  String get adminConfigListsCategoriesFinanceIncomeCategory;

  /// No description provided for @adminConfigListsCategoriesNoticeCategory.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ বিভাগ'**
  String get adminConfigListsCategoriesNoticeCategory;

  /// No description provided for @adminConfigListsCategoriesPaymentAccount.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট অ্যাকাউন্ট (মান = মাধ্যম, লেবেল = অ্যাকাউন্ট বিবরণ)'**
  String get adminConfigListsCategoriesPaymentAccount;

  /// No description provided for @adminConfigListsCategoriesPropertyType.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তির ধরন'**
  String get adminConfigListsCategoriesPropertyType;

  /// No description provided for @adminConfigListsDeactivate.
  ///
  /// In bn, this message translates to:
  /// **'নিষ্ক্রিয় করুন'**
  String get adminConfigListsDeactivate;

  /// No description provided for @adminConfigListsErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'কনফিগ তালিকা আইটেম লোড করা যায়নি।'**
  String get adminConfigListsErrorsLoadFailed;

  /// No description provided for @adminConfigListsErrorsSaveFailed.
  ///
  /// In bn, this message translates to:
  /// **'পরিবর্তন সংরক্ষণ করা যায়নি।'**
  String get adminConfigListsErrorsSaveFailed;

  /// No description provided for @adminConfigListsFormLabel.
  ///
  /// In bn, this message translates to:
  /// **'লেবেল (ঐচ্ছিক)'**
  String get adminConfigListsFormLabel;

  /// No description provided for @adminConfigListsFormSubmit.
  ///
  /// In bn, this message translates to:
  /// **'আইটেম যোগ করুন'**
  String get adminConfigListsFormSubmit;

  /// No description provided for @adminConfigListsFormValue.
  ///
  /// In bn, this message translates to:
  /// **'মান'**
  String get adminConfigListsFormValue;

  /// No description provided for @adminConfigListsInactive.
  ///
  /// In bn, this message translates to:
  /// **'নিষ্ক্রিয়'**
  String get adminConfigListsInactive;

  /// No description provided for @adminConfigListsNoItems.
  ///
  /// In bn, this message translates to:
  /// **'এই বিভাগে এখনো কোনো আইটেম নেই।'**
  String get adminConfigListsNoItems;

  /// No description provided for @adminConfigListsSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'নিবন্ধন ফর্ম ও অন্যান্য স্ক্রিনে ব্যবহৃত অপশন তালিকা পরিচালনা করুন'**
  String get adminConfigListsSubtitle;

  /// No description provided for @adminConfigListsTableActions.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকশন'**
  String get adminConfigListsTableActions;

  /// No description provided for @adminConfigListsTableLabel.
  ///
  /// In bn, this message translates to:
  /// **'লেবেল'**
  String get adminConfigListsTableLabel;

  /// No description provided for @adminConfigListsTableStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get adminConfigListsTableStatus;

  /// No description provided for @adminConfigListsTableValue.
  ///
  /// In bn, this message translates to:
  /// **'মান'**
  String get adminConfigListsTableValue;

  /// No description provided for @adminConfigListsTitle.
  ///
  /// In bn, this message translates to:
  /// **'কনফিগ তালিকা'**
  String get adminConfigListsTitle;

  /// No description provided for @adminDashboardCostsOutstanding.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের বকেয়া'**
  String get adminDashboardCostsOutstanding;

  /// No description provided for @adminDashboardCostsQuarterTotal.
  ///
  /// In bn, this message translates to:
  /// **'এই ত্রৈমাসিকের মোট'**
  String get adminDashboardCostsQuarterTotal;

  /// No description provided for @adminDashboardCostsTitle.
  ///
  /// In bn, this message translates to:
  /// **'এই ত্রৈমাসিকের সোসাইটি খরচ'**
  String get adminDashboardCostsTitle;

  /// No description provided for @adminDashboardCostsViewAll.
  ///
  /// In bn, this message translates to:
  /// **'সব খরচ দেখুন'**
  String get adminDashboardCostsViewAll;

  /// No description provided for @adminDashboardDetailsLink.
  ///
  /// In bn, this message translates to:
  /// **'বিস্তারিত'**
  String get adminDashboardDetailsLink;

  /// No description provided for @adminDashboardErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'আবেদনের তালিকা লোড করা যায়নি।'**
  String get adminDashboardErrorsLoadFailed;

  /// No description provided for @adminDashboardFinanceBalance.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ব্যালেন্স'**
  String get adminDashboardFinanceBalance;

  /// No description provided for @adminDashboardFinanceMonthNet.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসের নিট'**
  String get adminDashboardFinanceMonthNet;

  /// No description provided for @adminDashboardFinancePending.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদনের অপেক্ষায়'**
  String get adminDashboardFinancePending;

  /// No description provided for @adminDashboardFinanceTitle.
  ///
  /// In bn, this message translates to:
  /// **'ফান্ড স্বচ্ছতা'**
  String get adminDashboardFinanceTitle;

  /// No description provided for @adminDashboardFinanceViewAll.
  ///
  /// In bn, this message translates to:
  /// **'সব দেখুন'**
  String get adminDashboardFinanceViewAll;

  /// No description provided for @adminDashboardNoPending.
  ///
  /// In bn, this message translates to:
  /// **'কোনো বিচারাধীন আবেদন নেই'**
  String get adminDashboardNoPending;

  /// No description provided for @adminDashboardPendingTitle.
  ///
  /// In bn, this message translates to:
  /// **'বিচারাধীন আবেদন'**
  String get adminDashboardPendingTitle;

  /// No description provided for @adminDashboardPropertiesUnit.
  ///
  /// In bn, this message translates to:
  /// **'টি'**
  String get adminDashboardPropertiesUnit;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন সদস্যপদের আবেদনসমূহ পর্যালোচনা করুন'**
  String get adminDashboardSubtitle;

  /// No description provided for @adminDashboardTableHeadersApplicant.
  ///
  /// In bn, this message translates to:
  /// **'আবেদনকারী'**
  String get adminDashboardTableHeadersApplicant;

  /// No description provided for @adminDashboardTableHeadersMobile.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get adminDashboardTableHeadersMobile;

  /// No description provided for @adminDashboardTableHeadersProperties.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি'**
  String get adminDashboardTableHeadersProperties;

  /// No description provided for @adminDashboardTableHeadersReference.
  ///
  /// In bn, this message translates to:
  /// **'রেফারেন্স'**
  String get adminDashboardTableHeadersReference;

  /// No description provided for @adminDashboardTableHeadersSubmittedDate.
  ///
  /// In bn, this message translates to:
  /// **'জমার তারিখ'**
  String get adminDashboardTableHeadersSubmittedDate;

  /// No description provided for @adminEventsCreate.
  ///
  /// In bn, this message translates to:
  /// **'নতুন অনুষ্ঠান'**
  String get adminEventsCreate;

  /// No description provided for @adminEventsCreateFirst.
  ///
  /// In bn, this message translates to:
  /// **'আপনার প্রথম অনুষ্ঠান তৈরি করুন'**
  String get adminEventsCreateFirst;

  /// No description provided for @adminEventsDeleteModalConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get adminEventsDeleteModalConfirmLabel;

  /// No description provided for @adminEventsDeleteModalMessageSuffix.
  ///
  /// In bn, this message translates to:
  /// **'স্থায়ীভাবে মুছে ফেলা হবে।'**
  String get adminEventsDeleteModalMessageSuffix;

  /// No description provided for @adminEventsDeleteModalTitle.
  ///
  /// In bn, this message translates to:
  /// **'অনুষ্ঠান মুছুন'**
  String get adminEventsDeleteModalTitle;

  /// No description provided for @adminEventsEmptyHelper.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশিত ও খসড়া অনুষ্ঠান এখানে দেখা যাবে।'**
  String get adminEventsEmptyHelper;

  /// No description provided for @adminEventsErrorsDeleteFailed.
  ///
  /// In bn, this message translates to:
  /// **'অনুষ্ঠান মুছা যায়নি।'**
  String get adminEventsErrorsDeleteFailed;

  /// No description provided for @adminEventsErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'অনুষ্ঠান লোড করা যায়নি।'**
  String get adminEventsErrorsLoadFailed;

  /// No description provided for @adminEventsErrorsSaveFailed.
  ///
  /// In bn, this message translates to:
  /// **'অনুষ্ঠান সংরক্ষণ করা যায়নি।'**
  String get adminEventsErrorsSaveFailed;

  /// No description provided for @adminEventsFiltersAll.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get adminEventsFiltersAll;

  /// No description provided for @adminEventsFiltersAllCategories.
  ///
  /// In bn, this message translates to:
  /// **'সব ক্যাটাগরি'**
  String get adminEventsFiltersAllCategories;

  /// No description provided for @adminEventsFiltersCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি ফিল্টার'**
  String get adminEventsFiltersCategory;

  /// No description provided for @adminEventsFiltersDraft.
  ///
  /// In bn, this message translates to:
  /// **'খসড়া'**
  String get adminEventsFiltersDraft;

  /// No description provided for @adminEventsFiltersPublished.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশিত'**
  String get adminEventsFiltersPublished;

  /// No description provided for @adminEventsFormCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি'**
  String get adminEventsFormCategory;

  /// No description provided for @adminEventsFormCreate.
  ///
  /// In bn, this message translates to:
  /// **'তৈরি করুন'**
  String get adminEventsFormCreate;

  /// No description provided for @adminEventsFormCreateTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন অনুষ্ঠান'**
  String get adminEventsFormCreateTitle;

  /// No description provided for @adminEventsFormDescription.
  ///
  /// In bn, this message translates to:
  /// **'বিবরণ'**
  String get adminEventsFormDescription;

  /// No description provided for @adminEventsFormEditTitle.
  ///
  /// In bn, this message translates to:
  /// **'অনুষ্ঠান সম্পাদনা'**
  String get adminEventsFormEditTitle;

  /// No description provided for @adminEventsFormEndAt.
  ///
  /// In bn, this message translates to:
  /// **'শেষ'**
  String get adminEventsFormEndAt;

  /// No description provided for @adminEventsFormEndBeforeStart.
  ///
  /// In bn, this message translates to:
  /// **'শেষ সময় শুরুর সময়ের পরে হতে হবে।'**
  String get adminEventsFormEndBeforeStart;

  /// No description provided for @adminEventsFormLocation.
  ///
  /// In bn, this message translates to:
  /// **'স্থান'**
  String get adminEventsFormLocation;

  /// No description provided for @adminEventsFormMembersOnly.
  ///
  /// In bn, this message translates to:
  /// **'শুধু সদস্যদের জন্য (সর্বসাধারণের তালিকায় দেখা যাবে না)'**
  String get adminEventsFormMembersOnly;

  /// No description provided for @adminEventsFormNoCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি নেই'**
  String get adminEventsFormNoCategory;

  /// No description provided for @adminEventsFormPublished.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশিত'**
  String get adminEventsFormPublished;

  /// No description provided for @adminEventsFormStartAt.
  ///
  /// In bn, this message translates to:
  /// **'শুরু'**
  String get adminEventsFormStartAt;

  /// No description provided for @adminEventsFormStartAtRequired.
  ///
  /// In bn, this message translates to:
  /// **'শুরুর তারিখ ও সময় আবশ্যক।'**
  String get adminEventsFormStartAtRequired;

  /// No description provided for @adminEventsFormTitle.
  ///
  /// In bn, this message translates to:
  /// **'শিরোনাম'**
  String get adminEventsFormTitle;

  /// No description provided for @adminEventsMembersOnlyBadge.
  ///
  /// In bn, this message translates to:
  /// **'শুধু সদস্যদের জন্য'**
  String get adminEventsMembersOnlyBadge;

  /// No description provided for @adminEventsNoItems.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো অনুষ্ঠান নেই।'**
  String get adminEventsNoItems;

  /// No description provided for @adminEventsPublish.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশ করুন'**
  String get adminEventsPublish;

  /// No description provided for @adminEventsStatusDraft.
  ///
  /// In bn, this message translates to:
  /// **'খসড়া'**
  String get adminEventsStatusDraft;

  /// No description provided for @adminEventsStatusPublished.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশিত'**
  String get adminEventsStatusPublished;

  /// No description provided for @adminEventsSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'পরিষদের অনুষ্ঠান তালিকা তৈরি ও প্রকাশ করুন'**
  String get adminEventsSubtitle;

  /// No description provided for @adminEventsTableCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি'**
  String get adminEventsTableCategory;

  /// No description provided for @adminEventsTableLocation.
  ///
  /// In bn, this message translates to:
  /// **'স্থান'**
  String get adminEventsTableLocation;

  /// No description provided for @adminEventsTableStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get adminEventsTableStatus;

  /// No description provided for @adminEventsTableTitle.
  ///
  /// In bn, this message translates to:
  /// **'শিরোনাম'**
  String get adminEventsTableTitle;

  /// No description provided for @adminEventsTableUntil.
  ///
  /// In bn, this message translates to:
  /// **'পর্যন্ত'**
  String get adminEventsTableUntil;

  /// No description provided for @adminEventsTableWhen.
  ///
  /// In bn, this message translates to:
  /// **'সময়'**
  String get adminEventsTableWhen;

  /// No description provided for @adminEventsTitle.
  ///
  /// In bn, this message translates to:
  /// **'অনুষ্ঠান'**
  String get adminEventsTitle;

  /// No description provided for @adminEventsUnpublish.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশ বন্ধ করুন'**
  String get adminEventsUnpublish;

  /// No description provided for @adminFeeSettingsActive.
  ///
  /// In bn, this message translates to:
  /// **'সক্রিয়'**
  String get adminFeeSettingsActive;

  /// No description provided for @adminFeeSettingsAddVersion.
  ///
  /// In bn, this message translates to:
  /// **'নতুন ভার্সন যোগ করুন'**
  String get adminFeeSettingsAddVersion;

  /// No description provided for @adminFeeSettingsCalculatorFee.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক ফি'**
  String get adminFeeSettingsCalculatorFee;

  /// No description provided for @adminFeeSettingsCalculatorLandSize.
  ///
  /// In bn, this message translates to:
  /// **'জমির আয়তন (ডেসিমেল)'**
  String get adminFeeSettingsCalculatorLandSize;

  /// No description provided for @adminFeeSettingsCalculatorTitle.
  ///
  /// In bn, this message translates to:
  /// **'ফি ক্যালকুলেটর'**
  String get adminFeeSettingsCalculatorTitle;

  /// No description provided for @adminFeeSettingsConfirmMessage.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ভার্সন আজ থেকে নিষ্ক্রিয় হবে। নতুন ভার্সন সংরক্ষণ করতে চান?'**
  String get adminFeeSettingsConfirmMessage;

  /// No description provided for @adminFeeSettingsConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন ভার্সন নিশ্চিত করুন'**
  String get adminFeeSettingsConfirmTitle;

  /// No description provided for @adminFeeSettingsErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'ফি সেটিংস লোড করা যায়নি।'**
  String get adminFeeSettingsErrorsLoadFailed;

  /// No description provided for @adminFeeSettingsErrorsLoadHistoryFailed.
  ///
  /// In bn, this message translates to:
  /// **'ফি সেটিংসের ইতিহাস লোড করা যায়নি।'**
  String get adminFeeSettingsErrorsLoadHistoryFailed;

  /// No description provided for @adminFeeSettingsErrorsSaveFailed.
  ///
  /// In bn, this message translates to:
  /// **'নতুন ফি সেটিংস ভার্সন সংরক্ষণ করা যায়নি।'**
  String get adminFeeSettingsErrorsSaveFailed;

  /// No description provided for @adminFeeSettingsFormAdditionalRate.
  ///
  /// In bn, this message translates to:
  /// **'প্রতি অতিরিক্ত ডেসিমেলে হার'**
  String get adminFeeSettingsFormAdditionalRate;

  /// No description provided for @adminFeeSettingsFormAdditionalRateHint.
  ///
  /// In bn, this message translates to:
  /// **'প্রতিটি অতিরিক্ত ডেসিমেল, অথবা ডেসিমেলের অংশ, সম্পূর্ণ হিসেবে চার্জ করা হয়।'**
  String get adminFeeSettingsFormAdditionalRateHint;

  /// No description provided for @adminFeeSettingsFormBaseAmount.
  ///
  /// In bn, this message translates to:
  /// **'বেস পরিমাণ'**
  String get adminFeeSettingsFormBaseAmount;

  /// No description provided for @adminFeeSettingsFormBaseThreshold.
  ///
  /// In bn, this message translates to:
  /// **'বেস থ্রেশহোল্ড (ডেসিমেল)'**
  String get adminFeeSettingsFormBaseThreshold;

  /// No description provided for @adminFeeSettingsFormKey.
  ///
  /// In bn, this message translates to:
  /// **'ফি'**
  String get adminFeeSettingsFormKey;

  /// No description provided for @adminFeeSettingsFormStartDate.
  ///
  /// In bn, this message translates to:
  /// **'শুরুর তারিখ (ঐচ্ছিক)'**
  String get adminFeeSettingsFormStartDate;

  /// No description provided for @adminFeeSettingsFormStartDateHint.
  ///
  /// In bn, this message translates to:
  /// **'খালি রাখলে আজ থেকে কার্যকর'**
  String get adminFeeSettingsFormStartDateHint;

  /// No description provided for @adminFeeSettingsFormSubmit.
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষণ করুন'**
  String get adminFeeSettingsFormSubmit;

  /// No description provided for @adminFeeSettingsFormUnit.
  ///
  /// In bn, this message translates to:
  /// **'একক'**
  String get adminFeeSettingsFormUnit;

  /// No description provided for @adminFeeSettingsFormValue.
  ///
  /// In bn, this message translates to:
  /// **'মান'**
  String get adminFeeSettingsFormValue;

  /// No description provided for @adminFeeSettingsHideHistory.
  ///
  /// In bn, this message translates to:
  /// **'ইতিহাস লুকান'**
  String get adminFeeSettingsHideHistory;

  /// No description provided for @adminFeeSettingsInactive.
  ///
  /// In bn, this message translates to:
  /// **'নিষ্ক্রিয়'**
  String get adminFeeSettingsInactive;

  /// No description provided for @adminFeeSettingsKeysAdmissionFee.
  ///
  /// In bn, this message translates to:
  /// **'ভর্তি ফি'**
  String get adminFeeSettingsKeysAdmissionFee;

  /// No description provided for @adminFeeSettingsKeysMonthlySubscription.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক চাঁদা হার'**
  String get adminFeeSettingsKeysMonthlySubscription;

  /// No description provided for @adminFeeSettingsKeysMonthlySubscriptionAdditionalRate.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক চাঁদা অতিরিক্ত হার'**
  String get adminFeeSettingsKeysMonthlySubscriptionAdditionalRate;

  /// No description provided for @adminFeeSettingsKeysMonthlySubscriptionBaseAmount.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক চাঁদা বেস পরিমাণ'**
  String get adminFeeSettingsKeysMonthlySubscriptionBaseAmount;

  /// No description provided for @adminFeeSettingsKeysMonthlySubscriptionBaseThreshold.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক চাঁদা বেস থ্রেশহোল্ড'**
  String get adminFeeSettingsKeysMonthlySubscriptionBaseThreshold;

  /// No description provided for @adminFeeSettingsKeysPicnicAdditionalHeadFee.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক ফি - অতিরিক্ত প্রধান'**
  String get adminFeeSettingsKeysPicnicAdditionalHeadFee;

  /// No description provided for @adminFeeSettingsKeysPicnicHeadFee.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক ফি - সদস্য প্রধান'**
  String get adminFeeSettingsKeysPicnicHeadFee;

  /// No description provided for @adminFeeSettingsNoSettings.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো ফি সেটিংস কনফিগার করা হয়নি।'**
  String get adminFeeSettingsNoSettings;

  /// No description provided for @adminFeeSettingsPicnicNotConfigured.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক ফি এখনও সম্পূর্ণভাবে নির্ধারিত হয়নি - উভয় পিকনিক রেটের সক্রিয় সংস্করণ না থাকলে সদস্যরা পেমেন্ট করতে পারবেন না।'**
  String get adminFeeSettingsPicnicNotConfigured;

  /// No description provided for @adminFeeSettingsSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'কার্যকর তারিখের পরিসরসহ ফি হারের সংস্করণ পরিচালনা করুন'**
  String get adminFeeSettingsSubtitle;

  /// No description provided for @adminFeeSettingsTableEndDate.
  ///
  /// In bn, this message translates to:
  /// **'শেষের তারিখ'**
  String get adminFeeSettingsTableEndDate;

  /// No description provided for @adminFeeSettingsTableKey.
  ///
  /// In bn, this message translates to:
  /// **'কী'**
  String get adminFeeSettingsTableKey;

  /// No description provided for @adminFeeSettingsTableStartDate.
  ///
  /// In bn, this message translates to:
  /// **'শুরুর তারিখ'**
  String get adminFeeSettingsTableStartDate;

  /// No description provided for @adminFeeSettingsTableStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get adminFeeSettingsTableStatus;

  /// No description provided for @adminFeeSettingsTableUnit.
  ///
  /// In bn, this message translates to:
  /// **'একক'**
  String get adminFeeSettingsTableUnit;

  /// No description provided for @adminFeeSettingsTableValue.
  ///
  /// In bn, this message translates to:
  /// **'মান'**
  String get adminFeeSettingsTableValue;

  /// No description provided for @adminFeeSettingsTieredSummary.
  ///
  /// In bn, this message translates to:
  /// **'প্রথম {threshold} ডেসিমেল পর্যন্ত {base} টাকা + প্রতি অতিরিক্ত ডেসিমেলে {rate} টাকা (আংশিক ডেসিমেলও পূর্ণ ধরা হয়)'**
  String adminFeeSettingsTieredSummary(
      Object base, Object rate, Object threshold);

  /// No description provided for @adminFeeSettingsTitle.
  ///
  /// In bn, this message translates to:
  /// **'ফি সেটিংস'**
  String get adminFeeSettingsTitle;

  /// No description provided for @adminFeeSettingsUnitsPercent.
  ///
  /// In bn, this message translates to:
  /// **'%'**
  String get adminFeeSettingsUnitsPercent;

  /// No description provided for @adminFeeSettingsUnitsTaka.
  ///
  /// In bn, this message translates to:
  /// **'টাকা'**
  String get adminFeeSettingsUnitsTaka;

  /// No description provided for @adminFeeSettingsViewHistory.
  ///
  /// In bn, this message translates to:
  /// **'ইতিহাস দেখুন'**
  String get adminFeeSettingsViewHistory;

  /// No description provided for @adminFinanceManagementActionsApprove.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদন'**
  String get adminFinanceManagementActionsApprove;

  /// No description provided for @adminFinanceManagementActionsReject.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get adminFinanceManagementActionsReject;

  /// No description provided for @adminFinanceManagementActionsReverse.
  ///
  /// In bn, this message translates to:
  /// **'রিভার্সাল'**
  String get adminFinanceManagementActionsReverse;

  /// No description provided for @adminFinanceManagementActionsSaveDraft.
  ///
  /// In bn, this message translates to:
  /// **'ড্রাফট সেভ'**
  String get adminFinanceManagementActionsSaveDraft;

  /// No description provided for @adminFinanceManagementActionsSavePending.
  ///
  /// In bn, this message translates to:
  /// **'সেভ ও অনুমোদনে পাঠান'**
  String get adminFinanceManagementActionsSavePending;

  /// No description provided for @adminFinanceManagementActionsSubmit.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদনে পাঠান'**
  String get adminFinanceManagementActionsSubmit;

  /// No description provided for @adminFinanceManagementCreate.
  ///
  /// In bn, this message translates to:
  /// **'নতুন লেনদেন'**
  String get adminFinanceManagementCreate;

  /// No description provided for @adminFinanceManagementCreateTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন লেনদেন যোগ করুন'**
  String get adminFinanceManagementCreateTitle;

  /// No description provided for @adminFinanceManagementEditTitle.
  ///
  /// In bn, this message translates to:
  /// **'লেনদেন সম্পাদনা'**
  String get adminFinanceManagementEditTitle;

  /// No description provided for @adminFinanceManagementErrorsActionFailed.
  ///
  /// In bn, this message translates to:
  /// **'কাজটি সম্পন্ন করা যায়নি। আবার চেষ্টা করুন।'**
  String get adminFinanceManagementErrorsActionFailed;

  /// No description provided for @adminFinanceManagementErrorsAmountRequired.
  ///
  /// In bn, this message translates to:
  /// **'শূন্যের বেশি পরিমাণ দিন।'**
  String get adminFinanceManagementErrorsAmountRequired;

  /// No description provided for @adminFinanceManagementErrorsAttachmentFailed.
  ///
  /// In bn, this message translates to:
  /// **'সংযুক্তি আপলোড করা যায়নি।'**
  String get adminFinanceManagementErrorsAttachmentFailed;

  /// No description provided for @adminFinanceManagementErrorsCategoryAddFailed.
  ///
  /// In bn, this message translates to:
  /// **'নতুন খাত যোগ করা যায়নি।'**
  String get adminFinanceManagementErrorsCategoryAddFailed;

  /// No description provided for @adminFinanceManagementErrorsCategoryRequired.
  ///
  /// In bn, this message translates to:
  /// **'খাত নির্বাচন করুন।'**
  String get adminFinanceManagementErrorsCategoryRequired;

  /// No description provided for @adminFinanceManagementErrorsDateRequired.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ দিন।'**
  String get adminFinanceManagementErrorsDateRequired;

  /// No description provided for @adminFinanceManagementErrorsDescriptionRequired.
  ///
  /// In bn, this message translates to:
  /// **'বিবরণ দিন।'**
  String get adminFinanceManagementErrorsDescriptionRequired;

  /// No description provided for @adminFinanceManagementErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'তালিকা লোড করা যায়নি। আবার চেষ্টা করুন।'**
  String get adminFinanceManagementErrorsLoadFailed;

  /// No description provided for @adminFinanceManagementErrorsReasonRequired.
  ///
  /// In bn, this message translates to:
  /// **'কারণ লেখা আবশ্যক।'**
  String get adminFinanceManagementErrorsReasonRequired;

  /// No description provided for @adminFinanceManagementErrorsSaveFailed.
  ///
  /// In bn, this message translates to:
  /// **'সেভ করা যায়নি। আবার চেষ্টা করুন।'**
  String get adminFinanceManagementErrorsSaveFailed;

  /// No description provided for @adminFinanceManagementFiltersAllCategories.
  ///
  /// In bn, this message translates to:
  /// **'সব খাত'**
  String get adminFinanceManagementFiltersAllCategories;

  /// No description provided for @adminFinanceManagementFiltersAllTypes.
  ///
  /// In bn, this message translates to:
  /// **'সব ধরন'**
  String get adminFinanceManagementFiltersAllTypes;

  /// No description provided for @adminFinanceManagementFiltersCategory.
  ///
  /// In bn, this message translates to:
  /// **'খাত'**
  String get adminFinanceManagementFiltersCategory;

  /// No description provided for @adminFinanceManagementFiltersReset.
  ///
  /// In bn, this message translates to:
  /// **'রিসেট'**
  String get adminFinanceManagementFiltersReset;

  /// No description provided for @adminFinanceManagementFiltersSearch.
  ///
  /// In bn, this message translates to:
  /// **'বিবরণ/রেফারেন্স খুঁজুন…'**
  String get adminFinanceManagementFiltersSearch;

  /// No description provided for @adminFinanceManagementFiltersType.
  ///
  /// In bn, this message translates to:
  /// **'ধরন'**
  String get adminFinanceManagementFiltersType;

  /// No description provided for @adminFinanceManagementFormAddCategory.
  ///
  /// In bn, this message translates to:
  /// **'নতুন খাত যোগ করুন (Enter)'**
  String get adminFinanceManagementFormAddCategory;

  /// No description provided for @adminFinanceManagementFormAmount.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get adminFinanceManagementFormAmount;

  /// No description provided for @adminFinanceManagementFormAttachment.
  ///
  /// In bn, this message translates to:
  /// **'সংযুক্তি (ছবি/PDF)'**
  String get adminFinanceManagementFormAttachment;

  /// No description provided for @adminFinanceManagementFormCategory.
  ///
  /// In bn, this message translates to:
  /// **'খাত'**
  String get adminFinanceManagementFormCategory;

  /// No description provided for @adminFinanceManagementFormCategoryNoMatch.
  ///
  /// In bn, this message translates to:
  /// **'মিলে যাওয়া কোনো খাত নেই'**
  String get adminFinanceManagementFormCategoryNoMatch;

  /// No description provided for @adminFinanceManagementFormCategorySearch.
  ///
  /// In bn, this message translates to:
  /// **'খাত খুঁজুন বা লিখুন…'**
  String get adminFinanceManagementFormCategorySearch;

  /// No description provided for @adminFinanceManagementFormDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get adminFinanceManagementFormDate;

  /// No description provided for @adminFinanceManagementFormDescription.
  ///
  /// In bn, this message translates to:
  /// **'বিবরণ'**
  String get adminFinanceManagementFormDescription;

  /// No description provided for @adminFinanceManagementFormInternalNotes.
  ///
  /// In bn, this message translates to:
  /// **'অভ্যন্তরীণ নোট'**
  String get adminFinanceManagementFormInternalNotes;

  /// No description provided for @adminFinanceManagementFormInternalNotesHint.
  ///
  /// In bn, this message translates to:
  /// **'মেম্বাররা এই নোট দেখতে পাবে না।'**
  String get adminFinanceManagementFormInternalNotesHint;

  /// No description provided for @adminFinanceManagementFormReference.
  ///
  /// In bn, this message translates to:
  /// **'রেফারেন্স নম্বর'**
  String get adminFinanceManagementFormReference;

  /// No description provided for @adminFinanceManagementFormReferenceAuto.
  ///
  /// In bn, this message translates to:
  /// **'খালি রাখলে স্বয়ংক্রিয়ভাবে তৈরি হবে'**
  String get adminFinanceManagementFormReferenceAuto;

  /// No description provided for @adminFinanceManagementFormReferenceHint.
  ///
  /// In bn, this message translates to:
  /// **'FT-…'**
  String get adminFinanceManagementFormReferenceHint;

  /// No description provided for @adminFinanceManagementFormType.
  ///
  /// In bn, this message translates to:
  /// **'ধরন'**
  String get adminFinanceManagementFormType;

  /// No description provided for @adminFinanceManagementLedgerAmount.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get adminFinanceManagementLedgerAmount;

  /// No description provided for @adminFinanceManagementLedgerApprovedBy.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদনকারী'**
  String get adminFinanceManagementLedgerApprovedBy;

  /// No description provided for @adminFinanceManagementLedgerCategory.
  ///
  /// In bn, this message translates to:
  /// **'খাত'**
  String get adminFinanceManagementLedgerCategory;

  /// No description provided for @adminFinanceManagementLedgerCount.
  ///
  /// In bn, this message translates to:
  /// **'মোট {count}টি লেনদেন'**
  String adminFinanceManagementLedgerCount(Object count);

  /// No description provided for @adminFinanceManagementLedgerCreatedBy.
  ///
  /// In bn, this message translates to:
  /// **'তৈরি করেছেন'**
  String get adminFinanceManagementLedgerCreatedBy;

  /// No description provided for @adminFinanceManagementLedgerDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get adminFinanceManagementLedgerDate;

  /// No description provided for @adminFinanceManagementLedgerDescription.
  ///
  /// In bn, this message translates to:
  /// **'বিবরণ'**
  String get adminFinanceManagementLedgerDescription;

  /// No description provided for @adminFinanceManagementLedgerEditWindowClosed.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদনের ৭ দিন পর সরাসরি সম্পাদনা বন্ধ — সংশোধনের জন্য রিভার্সাল তৈরি করুন।'**
  String get adminFinanceManagementLedgerEditWindowClosed;

  /// No description provided for @adminFinanceManagementLedgerEmpty.
  ///
  /// In bn, this message translates to:
  /// **'কোনো লেনদেন নেই'**
  String get adminFinanceManagementLedgerEmpty;

  /// No description provided for @adminFinanceManagementLedgerEmptyHint.
  ///
  /// In bn, this message translates to:
  /// **'\'নতুন লেনদেন\' বাটন থেকে প্রথম এন্ট্রি যোগ করুন।'**
  String get adminFinanceManagementLedgerEmptyHint;

  /// No description provided for @adminFinanceManagementLedgerInternalNotes.
  ///
  /// In bn, this message translates to:
  /// **'অভ্যন্তরীণ নোট (শুধু কমিটি দেখে)'**
  String get adminFinanceManagementLedgerInternalNotes;

  /// No description provided for @adminFinanceManagementLedgerLinkedPayment.
  ///
  /// In bn, this message translates to:
  /// **'সংযুক্ত পেমেন্ট'**
  String get adminFinanceManagementLedgerLinkedPayment;

  /// No description provided for @adminFinanceManagementLedgerPage.
  ///
  /// In bn, this message translates to:
  /// **'পৃষ্ঠা {page} / {total}'**
  String adminFinanceManagementLedgerPage(Object page, Object total);

  /// No description provided for @adminFinanceManagementLedgerReference.
  ///
  /// In bn, this message translates to:
  /// **'রেফারেন্স'**
  String get adminFinanceManagementLedgerReference;

  /// No description provided for @adminFinanceManagementLedgerRejectionReason.
  ///
  /// In bn, this message translates to:
  /// **'বাতিলের কারণ'**
  String get adminFinanceManagementLedgerRejectionReason;

  /// No description provided for @adminFinanceManagementLedgerReversalOf.
  ///
  /// In bn, this message translates to:
  /// **'রিভার্সাল হয়েছে লেনদেন'**
  String get adminFinanceManagementLedgerReversalOf;

  /// No description provided for @adminFinanceManagementLedgerStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get adminFinanceManagementLedgerStatus;

  /// No description provided for @adminFinanceManagementLedgerType.
  ///
  /// In bn, this message translates to:
  /// **'ধরন'**
  String get adminFinanceManagementLedgerType;

  /// No description provided for @adminFinanceManagementLedgerViewAttachment.
  ///
  /// In bn, this message translates to:
  /// **'সংযুক্তি দেখুন'**
  String get adminFinanceManagementLedgerViewAttachment;

  /// No description provided for @adminFinanceManagementModalsApproveConfirm.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদন করুন'**
  String get adminFinanceManagementModalsApproveConfirm;

  /// No description provided for @adminFinanceManagementModalsApproveTitle.
  ///
  /// In bn, this message translates to:
  /// **'লেনদেন অনুমোদন'**
  String get adminFinanceManagementModalsApproveTitle;

  /// No description provided for @adminFinanceManagementModalsApproveTwoPerson.
  ///
  /// In bn, this message translates to:
  /// **'যিনি এন্ট্রি তৈরি করেছেন তিনি নিজে অনুমোদন করতে পারবেন না — অন্য কমিটি সদস্য অনুমোদন করবেন।'**
  String get adminFinanceManagementModalsApproveTwoPerson;

  /// No description provided for @adminFinanceManagementModalsDeleteConfirm.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get adminFinanceManagementModalsDeleteConfirm;

  /// No description provided for @adminFinanceManagementModalsDeleteReason.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলার কারণ (অডিটে থাকবে)'**
  String get adminFinanceManagementModalsDeleteReason;

  /// No description provided for @adminFinanceManagementModalsDeleteTitle.
  ///
  /// In bn, this message translates to:
  /// **'লেনদেন মুছুন'**
  String get adminFinanceManagementModalsDeleteTitle;

  /// No description provided for @adminFinanceManagementModalsRejectConfirm.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল করুন'**
  String get adminFinanceManagementModalsRejectConfirm;

  /// No description provided for @adminFinanceManagementModalsRejectReason.
  ///
  /// In bn, this message translates to:
  /// **'বাতিলের কারণ'**
  String get adminFinanceManagementModalsRejectReason;

  /// No description provided for @adminFinanceManagementModalsRejectTitle.
  ///
  /// In bn, this message translates to:
  /// **'লেনদেন বাতিল'**
  String get adminFinanceManagementModalsRejectTitle;

  /// No description provided for @adminFinanceManagementModalsReverseConfirm.
  ///
  /// In bn, this message translates to:
  /// **'রিভার্সাল তৈরি করুন'**
  String get adminFinanceManagementModalsReverseConfirm;

  /// No description provided for @adminFinanceManagementModalsReverseReason.
  ///
  /// In bn, this message translates to:
  /// **'সংশোধনের কারণ'**
  String get adminFinanceManagementModalsReverseReason;

  /// No description provided for @adminFinanceManagementModalsReverseTitle.
  ///
  /// In bn, this message translates to:
  /// **'রিভার্সাল (সংশোধন এন্ট্রি)'**
  String get adminFinanceManagementModalsReverseTitle;

  /// No description provided for @adminFinanceManagementNoticeAll.
  ///
  /// In bn, this message translates to:
  /// **'সর্বমোট'**
  String get adminFinanceManagementNoticeAll;

  /// No description provided for @adminFinanceManagementNoticeDone.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ প্রকাশিত হয়েছে ✓'**
  String get adminFinanceManagementNoticeDone;

  /// No description provided for @adminFinanceManagementNoticeMonth.
  ///
  /// In bn, this message translates to:
  /// **'এই মাস'**
  String get adminFinanceManagementNoticeMonth;

  /// No description provided for @adminFinanceManagementNoticePeriod.
  ///
  /// In bn, this message translates to:
  /// **'রিপোর্টের সময়কাল'**
  String get adminFinanceManagementNoticePeriod;

  /// No description provided for @adminFinanceManagementNoticePublish.
  ///
  /// In bn, this message translates to:
  /// **'রিপোর্ট নোটিশ প্রকাশ'**
  String get adminFinanceManagementNoticePublish;

  /// No description provided for @adminFinanceManagementNoticeYear.
  ///
  /// In bn, this message translates to:
  /// **'এই বছর'**
  String get adminFinanceManagementNoticeYear;

  /// No description provided for @adminFinanceManagementOverviewBalance.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ব্যালেন্স'**
  String get adminFinanceManagementOverviewBalance;

  /// No description provided for @adminFinanceManagementOverviewMonthNet.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসের নিট'**
  String get adminFinanceManagementOverviewMonthNet;

  /// No description provided for @adminFinanceManagementOverviewNoRecent.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো লেনদেন নেই।'**
  String get adminFinanceManagementOverviewNoRecent;

  /// No description provided for @adminFinanceManagementOverviewPending.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদনের অপেক্ষায়'**
  String get adminFinanceManagementOverviewPending;

  /// No description provided for @adminFinanceManagementOverviewRecent.
  ///
  /// In bn, this message translates to:
  /// **'সর্বশেষ ৫টি লেনদেন'**
  String get adminFinanceManagementOverviewRecent;

  /// No description provided for @adminFinanceManagementPaymentLinkAllSources.
  ///
  /// In bn, this message translates to:
  /// **'সব সোর্স'**
  String get adminFinanceManagementPaymentLinkAllSources;

  /// No description provided for @adminFinanceManagementPaymentLinkAlreadyLinked.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমানে সংযুক্ত: {source} #{id}'**
  String adminFinanceManagementPaymentLinkAlreadyLinked(
      Object id, Object source);

  /// No description provided for @adminFinanceManagementPaymentLinkEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই ফিল্টারে লিংক করার মতো কোনো পেমেন্ট নেই।'**
  String get adminFinanceManagementPaymentLinkEmpty;

  /// No description provided for @adminFinanceManagementPaymentLinkSearchPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'মেম্বারের নাম খুঁজুন…'**
  String get adminFinanceManagementPaymentLinkSearchPlaceholder;

  /// No description provided for @adminFinanceManagementPaymentLinkTitle.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট রেকর্ডের সাথে লিংক করুন (ডাবল এন্ট্রি এড়াতে)'**
  String get adminFinanceManagementPaymentLinkTitle;

  /// No description provided for @adminFinanceManagementSourceCostShare.
  ///
  /// In bn, this message translates to:
  /// **'খরচের কিস্তি'**
  String get adminFinanceManagementSourceCostShare;

  /// No description provided for @adminFinanceManagementSourceInstallment.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক চাঁদা'**
  String get adminFinanceManagementSourceInstallment;

  /// No description provided for @adminFinanceManagementSourcePicnicPayment.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক ফি'**
  String get adminFinanceManagementSourcePicnicPayment;

  /// No description provided for @adminFinanceManagementStatusAll.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get adminFinanceManagementStatusAll;

  /// No description provided for @adminFinanceManagementStatusApproved.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদিত'**
  String get adminFinanceManagementStatusApproved;

  /// No description provided for @adminFinanceManagementStatusDraft.
  ///
  /// In bn, this message translates to:
  /// **'ড্রাফট'**
  String get adminFinanceManagementStatusDraft;

  /// No description provided for @adminFinanceManagementStatusPending.
  ///
  /// In bn, this message translates to:
  /// **'অপেক্ষমাণ'**
  String get adminFinanceManagementStatusPending;

  /// No description provided for @adminFinanceManagementStatusRejected.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get adminFinanceManagementStatusRejected;

  /// No description provided for @adminFinanceManagementSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'ফান্ডের আয়-ব্যয়ের লেনদেন যোগ, সম্পাদনা ও অনুমোদন করুন'**
  String get adminFinanceManagementSubtitle;

  /// No description provided for @adminFinanceManagementTitle.
  ///
  /// In bn, this message translates to:
  /// **'আর্থিক ব্যবস্থাপনা'**
  String get adminFinanceManagementTitle;

  /// No description provided for @adminFinanceManagementTypeExpense.
  ///
  /// In bn, this message translates to:
  /// **'ব্যয়'**
  String get adminFinanceManagementTypeExpense;

  /// No description provided for @adminFinanceManagementTypeIncome.
  ///
  /// In bn, this message translates to:
  /// **'আয়'**
  String get adminFinanceManagementTypeIncome;

  /// No description provided for @adminInstallmentsErrorsLoadInstallmentsFailed.
  ///
  /// In bn, this message translates to:
  /// **'কিস্তির তথ্য লোড করা যায়নি।'**
  String get adminInstallmentsErrorsLoadInstallmentsFailed;

  /// No description provided for @adminInstallmentsErrorsLoadMembersFailed.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য তালিকা লোড করা যায়নি।'**
  String get adminInstallmentsErrorsLoadMembersFailed;

  /// No description provided for @adminInstallmentsErrorsMarkPaidFailed.
  ///
  /// In bn, this message translates to:
  /// **'কিস্তি পরিশোধিত হিসেবে চিহ্নিত করা যায়নি।'**
  String get adminInstallmentsErrorsMarkPaidFailed;

  /// No description provided for @adminInstallmentsMarkPaidButton.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত হিসেবে চিহ্নিত করুন'**
  String get adminInstallmentsMarkPaidButton;

  /// No description provided for @adminInstallmentsMonthsApril.
  ///
  /// In bn, this message translates to:
  /// **'এপ্রিল'**
  String get adminInstallmentsMonthsApril;

  /// No description provided for @adminInstallmentsMonthsAugust.
  ///
  /// In bn, this message translates to:
  /// **'আগস্ট'**
  String get adminInstallmentsMonthsAugust;

  /// No description provided for @adminInstallmentsMonthsDecember.
  ///
  /// In bn, this message translates to:
  /// **'ডিসেম্বর'**
  String get adminInstallmentsMonthsDecember;

  /// No description provided for @adminInstallmentsMonthsFebruary.
  ///
  /// In bn, this message translates to:
  /// **'ফেব্রুয়ারি'**
  String get adminInstallmentsMonthsFebruary;

  /// No description provided for @adminInstallmentsMonthsJanuary.
  ///
  /// In bn, this message translates to:
  /// **'জানুয়ারি'**
  String get adminInstallmentsMonthsJanuary;

  /// No description provided for @adminInstallmentsMonthsJuly.
  ///
  /// In bn, this message translates to:
  /// **'জুলাই'**
  String get adminInstallmentsMonthsJuly;

  /// No description provided for @adminInstallmentsMonthsJune.
  ///
  /// In bn, this message translates to:
  /// **'জুন'**
  String get adminInstallmentsMonthsJune;

  /// No description provided for @adminInstallmentsMonthsMarch.
  ///
  /// In bn, this message translates to:
  /// **'মার্চ'**
  String get adminInstallmentsMonthsMarch;

  /// No description provided for @adminInstallmentsMonthsMay.
  ///
  /// In bn, this message translates to:
  /// **'মে'**
  String get adminInstallmentsMonthsMay;

  /// No description provided for @adminInstallmentsMonthsNovember.
  ///
  /// In bn, this message translates to:
  /// **'নভেম্বর'**
  String get adminInstallmentsMonthsNovember;

  /// No description provided for @adminInstallmentsMonthsOctober.
  ///
  /// In bn, this message translates to:
  /// **'অক্টোবর'**
  String get adminInstallmentsMonthsOctober;

  /// No description provided for @adminInstallmentsMonthsSeptember.
  ///
  /// In bn, this message translates to:
  /// **'সেপ্টেম্বর'**
  String get adminInstallmentsMonthsSeptember;

  /// No description provided for @adminInstallmentsNoInstallments.
  ///
  /// In bn, this message translates to:
  /// **'এই সদস্যের কোনো কিস্তি নেই।'**
  String get adminInstallmentsNoInstallments;

  /// No description provided for @adminInstallmentsNoMembers.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সদস্য পাওয়া যায়নি।'**
  String get adminInstallmentsNoMembers;

  /// No description provided for @adminInstallmentsPaid.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত'**
  String get adminInstallmentsPaid;

  /// No description provided for @adminInstallmentsPermissionRequired.
  ///
  /// In bn, this message translates to:
  /// **'অনুমতি প্রয়োজন'**
  String get adminInstallmentsPermissionRequired;

  /// No description provided for @adminInstallmentsSelectMember.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য নির্বাচন করুন।'**
  String get adminInstallmentsSelectMember;

  /// No description provided for @adminInstallmentsSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য নির্বাচন করে মাসিক কিস্তির অবস্থা দেখুন ও হালনাগাদ করুন'**
  String get adminInstallmentsSubtitle;

  /// No description provided for @adminInstallmentsTitle.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদা ব্যবস্থাপনা'**
  String get adminInstallmentsTitle;

  /// No description provided for @adminMemberDetailClose.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করুন'**
  String get adminMemberDetailClose;

  /// No description provided for @adminMemberDetailDocsNone.
  ///
  /// In bn, this message translates to:
  /// **'কোনো ডকুমেন্ট আপলোড করা হয়নি।'**
  String get adminMemberDetailDocsNone;

  /// No description provided for @adminMemberDetailDue.
  ///
  /// In bn, this message translates to:
  /// **'বকেয়া'**
  String get adminMemberDetailDue;

  /// No description provided for @adminMemberDetailFAdmissionFee.
  ///
  /// In bn, this message translates to:
  /// **'ভর্তি ফি'**
  String get adminMemberDetailFAdmissionFee;

  /// No description provided for @adminMemberDetailFAmount.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get adminMemberDetailFAmount;

  /// No description provided for @adminMemberDetailFApprovedBy.
  ///
  /// In bn, this message translates to:
  /// **'পর্যালোচনাকারী'**
  String get adminMemberDetailFApprovedBy;

  /// No description provided for @adminMemberDetailFContribution.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদার অবস্থা'**
  String get adminMemberDetailFContribution;

  /// No description provided for @adminMemberDetailFCreated.
  ///
  /// In bn, this message translates to:
  /// **'তৈরি'**
  String get adminMemberDetailFCreated;

  /// No description provided for @adminMemberDetailFDag.
  ///
  /// In bn, this message translates to:
  /// **'দাগ নং (সিএস / আরএস)'**
  String get adminMemberDetailFDag;

  /// No description provided for @adminMemberDetailFDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get adminMemberDetailFDate;

  /// No description provided for @adminMemberDetailFDob.
  ///
  /// In bn, this message translates to:
  /// **'জন্ম তারিখ'**
  String get adminMemberDetailFDob;

  /// No description provided for @adminMemberDetailFDueTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট বকেয়া'**
  String get adminMemberDetailFDueTotal;

  /// No description provided for @adminMemberDetailFEmail.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get adminMemberDetailFEmail;

  /// No description provided for @adminMemberDetailFExtraHeads.
  ///
  /// In bn, this message translates to:
  /// **'অতিরিক্ত জন'**
  String get adminMemberDetailFExtraHeads;

  /// No description provided for @adminMemberDetailFFatherOrHusband.
  ///
  /// In bn, this message translates to:
  /// **'পিতা/স্বামীর নাম'**
  String get adminMemberDetailFFatherOrHusband;

  /// No description provided for @adminMemberDetailFGender.
  ///
  /// In bn, this message translates to:
  /// **'লিঙ্গ'**
  String get adminMemberDetailFGender;

  /// No description provided for @adminMemberDetailFHolding.
  ///
  /// In bn, this message translates to:
  /// **'হোল্ডিং নং'**
  String get adminMemberDetailFHolding;

  /// No description provided for @adminMemberDetailFJoined.
  ///
  /// In bn, this message translates to:
  /// **'আবেদনের তারিখ'**
  String get adminMemberDetailFJoined;

  /// No description provided for @adminMemberDetailFKhatian.
  ///
  /// In bn, this message translates to:
  /// **'খতিয়ান নং'**
  String get adminMemberDetailFKhatian;

  /// No description provided for @adminMemberDetailFLandSize.
  ///
  /// In bn, this message translates to:
  /// **'জমির পরিমাণ (শতাংশ)'**
  String get adminMemberDetailFLandSize;

  /// No description provided for @adminMemberDetailFLastModifiedBy.
  ///
  /// In bn, this message translates to:
  /// **'সর্বশেষ পরিবর্তনকারী'**
  String get adminMemberDetailFLastModifiedBy;

  /// No description provided for @adminMemberDetailFMemberId.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য আইডি'**
  String get adminMemberDetailFMemberId;

  /// No description provided for @adminMemberDetailFMobile.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get adminMemberDetailFMobile;

  /// No description provided for @adminMemberDetailFMonth.
  ///
  /// In bn, this message translates to:
  /// **'মাস'**
  String get adminMemberDetailFMonth;

  /// No description provided for @adminMemberDetailFMonthly.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক চাঁদা'**
  String get adminMemberDetailFMonthly;

  /// No description provided for @adminMemberDetailFMother.
  ///
  /// In bn, this message translates to:
  /// **'মাতার নাম'**
  String get adminMemberDetailFMother;

  /// No description provided for @adminMemberDetailFMyShare.
  ///
  /// In bn, this message translates to:
  /// **'আমার অংশ (শতাংশ)'**
  String get adminMemberDetailFMyShare;

  /// No description provided for @adminMemberDetailFName.
  ///
  /// In bn, this message translates to:
  /// **'পূর্ণ নাম'**
  String get adminMemberDetailFName;

  /// No description provided for @adminMemberDetailFNid.
  ///
  /// In bn, this message translates to:
  /// **'এনআইডি / জন্মনিবন্ধন'**
  String get adminMemberDetailFNid;

  /// No description provided for @adminMemberDetailFNomineeMobile.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get adminMemberDetailFNomineeMobile;

  /// No description provided for @adminMemberDetailFNomineeRelation.
  ///
  /// In bn, this message translates to:
  /// **'সম্পর্ক'**
  String get adminMemberDetailFNomineeRelation;

  /// No description provided for @adminMemberDetailFOccupation.
  ///
  /// In bn, this message translates to:
  /// **'পেশা'**
  String get adminMemberDetailFOccupation;

  /// No description provided for @adminMemberDetailFOwnership.
  ///
  /// In bn, this message translates to:
  /// **'মালিকানা'**
  String get adminMemberDetailFOwnership;

  /// No description provided for @adminMemberDetailFPaidOn.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধের তারিখ'**
  String get adminMemberDetailFPaidOn;

  /// No description provided for @adminMemberDetailFPaidTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট পরিশোধিত'**
  String get adminMemberDetailFPaidTotal;

  /// No description provided for @adminMemberDetailFPaymentMethod.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধের মাধ্যম'**
  String get adminMemberDetailFPaymentMethod;

  /// No description provided for @adminMemberDetailFPermanentAddress.
  ///
  /// In bn, this message translates to:
  /// **'স্থায়ী ঠিকানা'**
  String get adminMemberDetailFPermanentAddress;

  /// No description provided for @adminMemberDetailFPresentAddress.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ঠিকানা'**
  String get adminMemberDetailFPresentAddress;

  /// No description provided for @adminMemberDetailFReceiptNo.
  ///
  /// In bn, this message translates to:
  /// **'রশিদ নং'**
  String get adminMemberDetailFReceiptNo;

  /// No description provided for @adminMemberDetailFRejectionReason.
  ///
  /// In bn, this message translates to:
  /// **'বাতিলের কারণ'**
  String get adminMemberDetailFRejectionReason;

  /// No description provided for @adminMemberDetailFReviewedAt.
  ///
  /// In bn, this message translates to:
  /// **'পর্যালোচনার তারিখ'**
  String get adminMemberDetailFReviewedAt;

  /// No description provided for @adminMemberDetailFStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get adminMemberDetailFStatus;

  /// No description provided for @adminMemberDetailFTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট'**
  String get adminMemberDetailFTotal;

  /// No description provided for @adminMemberDetailFUpdated.
  ///
  /// In bn, this message translates to:
  /// **'সর্বশেষ হালনাগাদ'**
  String get adminMemberDetailFUpdated;

  /// No description provided for @adminMemberDetailFUrgentContact.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগ'**
  String get adminMemberDetailFUrgentContact;

  /// No description provided for @adminMemberDetailFullyPaid.
  ///
  /// In bn, this message translates to:
  /// **'সম্পূর্ণ পরিশোধিত'**
  String get adminMemberDetailFullyPaid;

  /// No description provided for @adminMemberDetailLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের তথ্য লোড করা যায়নি।'**
  String get adminMemberDetailLoadFailed;

  /// No description provided for @adminMemberDetailMemberPhoto.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের ছবি'**
  String get adminMemberDetailMemberPhoto;

  /// No description provided for @adminMemberDetailMonthsOverdue.
  ///
  /// In bn, this message translates to:
  /// **'মাস বকেয়া'**
  String get adminMemberDetailMonthsOverdue;

  /// No description provided for @adminMemberDetailNoAudit.
  ///
  /// In bn, this message translates to:
  /// **'কোনো অডিট এন্ট্রি নেই।'**
  String get adminMemberDetailNoAudit;

  /// No description provided for @adminMemberDetailNoInstallments.
  ///
  /// In bn, this message translates to:
  /// **'কোনো কিস্তি নেই।'**
  String get adminMemberDetailNoInstallments;

  /// No description provided for @adminMemberDetailNoNominees.
  ///
  /// In bn, this message translates to:
  /// **'কোনো মনোনীত ব্যক্তি নেই।'**
  String get adminMemberDetailNoNominees;

  /// No description provided for @adminMemberDetailNoPicnic.
  ///
  /// In bn, this message translates to:
  /// **'কোনো পিকনিক পরিশোধ নেই।'**
  String get adminMemberDetailNoPicnic;

  /// No description provided for @adminMemberDetailNoProperties.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সম্পত্তি নেই।'**
  String get adminMemberDetailNoProperties;

  /// No description provided for @adminMemberDetailOpenInstallments.
  ///
  /// In bn, this message translates to:
  /// **'কিস্তি ব্যবস্থাপনা'**
  String get adminMemberDetailOpenInstallments;

  /// No description provided for @adminMemberDetailPaid.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত'**
  String get adminMemberDetailPaid;

  /// No description provided for @adminMemberDetailReceiptPhoto.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট রশিদ'**
  String get adminMemberDetailReceiptPhoto;

  /// No description provided for @adminMemberDetailRetry.
  ///
  /// In bn, this message translates to:
  /// **'আবার চেষ্টা করুন'**
  String get adminMemberDetailRetry;

  /// No description provided for @adminMemberDetailSectionsAudit.
  ///
  /// In bn, this message translates to:
  /// **'অডিট ট্রেইল'**
  String get adminMemberDetailSectionsAudit;

  /// No description provided for @adminMemberDetailSectionsContact.
  ///
  /// In bn, this message translates to:
  /// **'যোগাযোগ'**
  String get adminMemberDetailSectionsContact;

  /// No description provided for @adminMemberDetailSectionsDocuments.
  ///
  /// In bn, this message translates to:
  /// **'ডকুমেন্ট'**
  String get adminMemberDetailSectionsDocuments;

  /// No description provided for @adminMemberDetailSectionsFees.
  ///
  /// In bn, this message translates to:
  /// **'ফি ও চাঁদা'**
  String get adminMemberDetailSectionsFees;

  /// No description provided for @adminMemberDetailSectionsIdentity.
  ///
  /// In bn, this message translates to:
  /// **'পরিচয়'**
  String get adminMemberDetailSectionsIdentity;

  /// No description provided for @adminMemberDetailSectionsInstallments.
  ///
  /// In bn, this message translates to:
  /// **'কিস্তি'**
  String get adminMemberDetailSectionsInstallments;

  /// No description provided for @adminMemberDetailSectionsMembership.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যপদের অবস্থা'**
  String get adminMemberDetailSectionsMembership;

  /// No description provided for @adminMemberDetailSectionsNominees.
  ///
  /// In bn, this message translates to:
  /// **'মনোনীত ব্যক্তি'**
  String get adminMemberDetailSectionsNominees;

  /// No description provided for @adminMemberDetailSectionsPicnic.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক পরিশোধ'**
  String get adminMemberDetailSectionsPicnic;

  /// No description provided for @adminMemberDetailSectionsProperty.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি'**
  String get adminMemberDetailSectionsProperty;

  /// No description provided for @adminMemberDetailSignature.
  ///
  /// In bn, this message translates to:
  /// **'স্বাক্ষর'**
  String get adminMemberDetailSignature;

  /// No description provided for @adminMemberDetailTitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের বিস্তারিত'**
  String get adminMemberDetailTitle;

  /// No description provided for @adminMembersListDeleteMemberTitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য মুছে ফেলুন'**
  String get adminMembersListDeleteMemberTitle;

  /// No description provided for @adminMembersListDeleteModalConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলুন'**
  String get adminMembersListDeleteModalConfirmLabel;

  /// No description provided for @adminMembersListDeleteModalMessageSuffix.
  ///
  /// In bn, this message translates to:
  /// **'এর সদস্য রেকর্ড স্থায়ীভাবে মুছে যাবে। এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।'**
  String get adminMembersListDeleteModalMessageSuffix;

  /// No description provided for @adminMembersListDeleteModalTitle.
  ///
  /// In bn, this message translates to:
  /// **'রেকর্ড মুছে ফেলুন?'**
  String get adminMembersListDeleteModalTitle;

  /// No description provided for @adminMembersListErrorsDeleteFailed.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য মুছে ফেলা যায়নি।'**
  String get adminMembersListErrorsDeleteFailed;

  /// No description provided for @adminMembersListErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য তালিকা লোড করা যায়নি।'**
  String get adminMembersListErrorsLoadFailed;

  /// No description provided for @adminMembersListErrorsResetFailed.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড রিসেট করা যায়নি।'**
  String get adminMembersListErrorsResetFailed;

  /// No description provided for @adminMembersListFullyPaid.
  ///
  /// In bn, this message translates to:
  /// **'সম্পূর্ণ পরিশোধিত'**
  String get adminMembersListFullyPaid;

  /// No description provided for @adminMembersListMonthsOverdue.
  ///
  /// In bn, this message translates to:
  /// **'মাস বকেয়া'**
  String get adminMembersListMonthsOverdue;

  /// No description provided for @adminMembersListNoMembers.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সদস্য পাওয়া যায়নি।'**
  String get adminMembersListNoMembers;

  /// No description provided for @adminMembersListResetModalConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'রিসেট ও ইমেইল'**
  String get adminMembersListResetModalConfirmLabel;

  /// No description provided for @adminMembersListResetModalMessageSuffix.
  ///
  /// In bn, this message translates to:
  /// **'এর লগইন পাসওয়ার্ড রিসেট করা হবে এবং নতুন পাসওয়ার্ড সদস্যের নিবন্ধিত ইমেইলে পাঠানো হবে।'**
  String get adminMembersListResetModalMessageSuffix;

  /// No description provided for @adminMembersListResetModalSuccessMessage.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড সফলভাবে রিসেট হয়েছে। নতুন পাসওয়ার্ড {name}-এর নিবন্ধিত ইমেইলে পাঠানো হয়েছে।'**
  String adminMembersListResetModalSuccessMessage(Object name);

  /// No description provided for @adminMembersListResetModalSuccessNoEmail.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড রিসেট সফল হয়েছে, তবে ইমেইল পাঠানো যায়নি। অনুগ্রহ করে সরাসরি সদস্যকে নতুন পাসওয়ার্ড জানিয়ে দিন।'**
  String get adminMembersListResetModalSuccessNoEmail;

  /// No description provided for @adminMembersListResetModalTitle.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড রিসেট করবেন?'**
  String get adminMembersListResetModalTitle;

  /// No description provided for @adminMembersListResetPasswordTitle.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড রিসেট করে নতুন তথ্য ইমেইল করুন'**
  String get adminMembersListResetPasswordTitle;

  /// No description provided for @adminMembersListSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের তথ্য ও চাঁদার অবস্থা দেখুন'**
  String get adminMembersListSubtitle;

  /// No description provided for @adminMembersListTableHeadersActions.
  ///
  /// In bn, this message translates to:
  /// **'কার্যক্রম'**
  String get adminMembersListTableHeadersActions;

  /// No description provided for @adminMembersListTableHeadersContributionStatus.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদার অবস্থা'**
  String get adminMembersListTableHeadersContributionStatus;

  /// No description provided for @adminMembersListTableHeadersMemberId.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য আইডি'**
  String get adminMembersListTableHeadersMemberId;

  /// No description provided for @adminMembersListTableHeadersMobile.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get adminMembersListTableHeadersMobile;

  /// No description provided for @adminMembersListTableHeadersName.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get adminMembersListTableHeadersName;

  /// No description provided for @adminMembersListTableHeadersStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get adminMembersListTableHeadersStatus;

  /// No description provided for @adminMembersListTitle.
  ///
  /// In bn, this message translates to:
  /// **'সকল সদস্য'**
  String get adminMembersListTitle;

  /// No description provided for @adminMembersListViewContributionsTitle.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদার অবস্থা দেখুন'**
  String get adminMembersListViewContributionsTitle;

  /// No description provided for @adminMembersListViewDetailsTitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের বিস্তারিত দেখুন'**
  String get adminMembersListViewDetailsTitle;

  /// No description provided for @adminNoticesCreate.
  ///
  /// In bn, this message translates to:
  /// **'নতুন নোটিশ'**
  String get adminNoticesCreate;

  /// No description provided for @adminNoticesCreateFirst.
  ///
  /// In bn, this message translates to:
  /// **'আপনার প্রথম নোটিশ তৈরি করুন'**
  String get adminNoticesCreateFirst;

  /// No description provided for @adminNoticesDeleteModalConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get adminNoticesDeleteModalConfirmLabel;

  /// No description provided for @adminNoticesDeleteModalMessageSuffix.
  ///
  /// In bn, this message translates to:
  /// **'স্থায়ীভাবে মুছে ফেলা হবে।'**
  String get adminNoticesDeleteModalMessageSuffix;

  /// No description provided for @adminNoticesDeleteModalTitle.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ মুছুন'**
  String get adminNoticesDeleteModalTitle;

  /// No description provided for @adminNoticesEmptyHelper.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশিত ও খসড়া নোটিশ এখানে দেখা যাবে।'**
  String get adminNoticesEmptyHelper;

  /// No description provided for @adminNoticesErrorsDeleteFailed.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ মুছা যায়নি।'**
  String get adminNoticesErrorsDeleteFailed;

  /// No description provided for @adminNoticesErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ লোড করা যায়নি।'**
  String get adminNoticesErrorsLoadFailed;

  /// No description provided for @adminNoticesErrorsSaveFailed.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ সংরক্ষণ করা যায়নি।'**
  String get adminNoticesErrorsSaveFailed;

  /// No description provided for @adminNoticesFiltersAll.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get adminNoticesFiltersAll;

  /// No description provided for @adminNoticesFiltersAllCategories.
  ///
  /// In bn, this message translates to:
  /// **'সব ক্যাটাগরি'**
  String get adminNoticesFiltersAllCategories;

  /// No description provided for @adminNoticesFiltersCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি ফিল্টার'**
  String get adminNoticesFiltersCategory;

  /// No description provided for @adminNoticesFiltersDraft.
  ///
  /// In bn, this message translates to:
  /// **'খসড়া'**
  String get adminNoticesFiltersDraft;

  /// No description provided for @adminNoticesFiltersPublished.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশিত'**
  String get adminNoticesFiltersPublished;

  /// No description provided for @adminNoticesFormBody.
  ///
  /// In bn, this message translates to:
  /// **'বিস্তারিত'**
  String get adminNoticesFormBody;

  /// No description provided for @adminNoticesFormCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি'**
  String get adminNoticesFormCategory;

  /// No description provided for @adminNoticesFormCreate.
  ///
  /// In bn, this message translates to:
  /// **'তৈরি করুন'**
  String get adminNoticesFormCreate;

  /// No description provided for @adminNoticesFormCreateTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন নোটিশ'**
  String get adminNoticesFormCreateTitle;

  /// No description provided for @adminNoticesFormEditTitle.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ সম্পাদনা'**
  String get adminNoticesFormEditTitle;

  /// No description provided for @adminNoticesFormMembersOnly.
  ///
  /// In bn, this message translates to:
  /// **'শুধু সদস্যদের জন্য (সর্বসাধারণের তালিকায় দেখা যাবে না)'**
  String get adminNoticesFormMembersOnly;

  /// No description provided for @adminNoticesFormNoCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি নেই'**
  String get adminNoticesFormNoCategory;

  /// No description provided for @adminNoticesFormPublishAt.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশের সময়'**
  String get adminNoticesFormPublishAt;

  /// No description provided for @adminNoticesFormPublishAtHint.
  ///
  /// In bn, this message translates to:
  /// **'ঐচ্ছিক। নির্ধারিত সময় না আসা পর্যন্ত সময়নির্ধারিত নোটিশ লুকানো থাকে।'**
  String get adminNoticesFormPublishAtHint;

  /// No description provided for @adminNoticesFormPublishAtPast.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশের তারিখ/সময় অতীতে হতে পারবে না।'**
  String get adminNoticesFormPublishAtPast;

  /// No description provided for @adminNoticesFormPublished.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশিত'**
  String get adminNoticesFormPublished;

  /// No description provided for @adminNoticesFormTitle.
  ///
  /// In bn, this message translates to:
  /// **'শিরোনাম'**
  String get adminNoticesFormTitle;

  /// No description provided for @adminNoticesMembersOnlyBadge.
  ///
  /// In bn, this message translates to:
  /// **'শুধু সদস্যদের জন্য'**
  String get adminNoticesMembersOnlyBadge;

  /// No description provided for @adminNoticesNoItems.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো নোটিশ নেই।'**
  String get adminNoticesNoItems;

  /// No description provided for @adminNoticesPublish.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশ করুন'**
  String get adminNoticesPublish;

  /// No description provided for @adminNoticesStatusDraft.
  ///
  /// In bn, this message translates to:
  /// **'খসড়া'**
  String get adminNoticesStatusDraft;

  /// No description provided for @adminNoticesStatusPublished.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশিত'**
  String get adminNoticesStatusPublished;

  /// No description provided for @adminNoticesStatusScheduled.
  ///
  /// In bn, this message translates to:
  /// **'সময়নির্ধারিত'**
  String get adminNoticesStatusScheduled;

  /// No description provided for @adminNoticesSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য ও দর্শকদের জন্য নোটিশ লিখে প্রকাশ করুন'**
  String get adminNoticesSubtitle;

  /// No description provided for @adminNoticesTableCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি'**
  String get adminNoticesTableCategory;

  /// No description provided for @adminNoticesTablePublishAt.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশের সময়'**
  String get adminNoticesTablePublishAt;

  /// No description provided for @adminNoticesTableStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get adminNoticesTableStatus;

  /// No description provided for @adminNoticesTableTitle.
  ///
  /// In bn, this message translates to:
  /// **'শিরোনাম'**
  String get adminNoticesTableTitle;

  /// No description provided for @adminNoticesTitle.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ'**
  String get adminNoticesTitle;

  /// No description provided for @adminNoticesUnpublish.
  ///
  /// In bn, this message translates to:
  /// **'প্রকাশ বন্ধ করুন'**
  String get adminNoticesUnpublish;

  /// No description provided for @adminPaymentVerificationsActionError.
  ///
  /// In bn, this message translates to:
  /// **'কাজটি ব্যর্থ হয়েছে। আবার চেষ্টা করুন।'**
  String get adminPaymentVerificationsActionError;

  /// No description provided for @adminPaymentVerificationsApprove.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদন'**
  String get adminPaymentVerificationsApprove;

  /// No description provided for @adminPaymentVerificationsCancel.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল করুন'**
  String get adminPaymentVerificationsCancel;

  /// No description provided for @adminPaymentVerificationsEmpty.
  ///
  /// In bn, this message translates to:
  /// **'কিছু নেই — সব যাচাই সম্পন্ন।'**
  String get adminPaymentVerificationsEmpty;

  /// No description provided for @adminPaymentVerificationsLoadError.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধ তালিকা লোড করা যায়নি।'**
  String get adminPaymentVerificationsLoadError;

  /// No description provided for @adminPaymentVerificationsMethod.
  ///
  /// In bn, this message translates to:
  /// **'মাধ্যম'**
  String get adminPaymentVerificationsMethod;

  /// No description provided for @adminPaymentVerificationsPaidOn.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধের তারিখ'**
  String get adminPaymentVerificationsPaidOn;

  /// No description provided for @adminPaymentVerificationsReason.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যকে দেখানো কারণ'**
  String get adminPaymentVerificationsReason;

  /// No description provided for @adminPaymentVerificationsReasonPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'যেমন bKash স্টেটমেন্টে ট্রানজেকশন আইডি পাওয়া যায়নি'**
  String get adminPaymentVerificationsReasonPlaceholder;

  /// No description provided for @adminPaymentVerificationsReference.
  ///
  /// In bn, this message translates to:
  /// **'ট্রানজেকশন আইডি'**
  String get adminPaymentVerificationsReference;

  /// No description provided for @adminPaymentVerificationsReject.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get adminPaymentVerificationsReject;

  /// No description provided for @adminPaymentVerificationsRejectTitle.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধ বাতিল'**
  String get adminPaymentVerificationsRejectTitle;

  /// No description provided for @adminPaymentVerificationsSender.
  ///
  /// In bn, this message translates to:
  /// **'প্রেরক'**
  String get adminPaymentVerificationsSender;

  /// No description provided for @adminPaymentVerificationsSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের জমা দেওয়া চাঁদা পরিশোধ অ্যাকাউন্ট স্টেটমেন্টের সাথে মিলিয়ে যাচাই করুন।'**
  String get adminPaymentVerificationsSubtitle;

  /// No description provided for @adminPaymentVerificationsTitle.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট যাচাই'**
  String get adminPaymentVerificationsTitle;

  /// No description provided for @adminPaymentVerificationsViewProof.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ দেখুন'**
  String get adminPaymentVerificationsViewProof;

  /// No description provided for @adminPicnicPaymentsApply.
  ///
  /// In bn, this message translates to:
  /// **'প্রয়োগ করুন'**
  String get adminPicnicPaymentsApply;

  /// No description provided for @adminPicnicPaymentsCount.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধ সংখ্যা'**
  String get adminPicnicPaymentsCount;

  /// No description provided for @adminPicnicPaymentsDateColumn.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get adminPicnicPaymentsDateColumn;

  /// No description provided for @adminPicnicPaymentsDateFrom.
  ///
  /// In bn, this message translates to:
  /// **'থেকে'**
  String get adminPicnicPaymentsDateFrom;

  /// No description provided for @adminPicnicPaymentsDateRange.
  ///
  /// In bn, this message translates to:
  /// **'তারিখের পরিসর'**
  String get adminPicnicPaymentsDateRange;

  /// No description provided for @adminPicnicPaymentsDateTo.
  ///
  /// In bn, this message translates to:
  /// **'পর্যন্ত'**
  String get adminPicnicPaymentsDateTo;

  /// No description provided for @adminPicnicPaymentsEmptyState.
  ///
  /// In bn, this message translates to:
  /// **'নির্বাচিত ফিল্টারে কোনো পিকনিক পরিশোধ পাওয়া যায়নি।'**
  String get adminPicnicPaymentsEmptyState;

  /// No description provided for @adminPicnicPaymentsHeadsColumn.
  ///
  /// In bn, this message translates to:
  /// **'অতিরিক্ত জন'**
  String get adminPicnicPaymentsHeadsColumn;

  /// No description provided for @adminPicnicPaymentsLoadError.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক পরিশোধ লোড করা যায়নি।'**
  String get adminPicnicPaymentsLoadError;

  /// No description provided for @adminPicnicPaymentsMemberColumn.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get adminPicnicPaymentsMemberColumn;

  /// No description provided for @adminPicnicPaymentsMemberFilter.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য আইডি (ঐচ্ছিক)'**
  String get adminPicnicPaymentsMemberFilter;

  /// No description provided for @adminPicnicPaymentsMethodColumn.
  ///
  /// In bn, this message translates to:
  /// **'পদ্ধতি'**
  String get adminPicnicPaymentsMethodColumn;

  /// No description provided for @adminPicnicPaymentsReceiptColumn.
  ///
  /// In bn, this message translates to:
  /// **'রশিদ নম্বর'**
  String get adminPicnicPaymentsReceiptColumn;

  /// No description provided for @adminPicnicPaymentsReset.
  ///
  /// In bn, this message translates to:
  /// **'রিসেট'**
  String get adminPicnicPaymentsReset;

  /// No description provided for @adminPicnicPaymentsSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'ফিল্টার ও মোট সহ সকল সদস্যের পিকনিক পরিশোধ'**
  String get adminPicnicPaymentsSubtitle;

  /// No description provided for @adminPicnicPaymentsTitle.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক পরিশোধ'**
  String get adminPicnicPaymentsTitle;

  /// No description provided for @adminPicnicPaymentsTotalCollected.
  ///
  /// In bn, this message translates to:
  /// **'মোট আদায়'**
  String get adminPicnicPaymentsTotalCollected;

  /// No description provided for @adminPicnicPaymentsTotalColumn.
  ///
  /// In bn, this message translates to:
  /// **'মোট'**
  String get adminPicnicPaymentsTotalColumn;

  /// No description provided for @adminPropertyRequestsActionsAdd.
  ///
  /// In bn, this message translates to:
  /// **'সংযোজন'**
  String get adminPropertyRequestsActionsAdd;

  /// No description provided for @adminPropertyRequestsActionsDelete.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলা'**
  String get adminPropertyRequestsActionsDelete;

  /// No description provided for @adminPropertyRequestsActionsEdit.
  ///
  /// In bn, this message translates to:
  /// **'সংশোধন'**
  String get adminPropertyRequestsActionsEdit;

  /// No description provided for @adminPropertyRequestsApproveButton.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদন'**
  String get adminPropertyRequestsApproveButton;

  /// No description provided for @adminPropertyRequestsApproveModalConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদন করুন'**
  String get adminPropertyRequestsApproveModalConfirmLabel;

  /// No description provided for @adminPropertyRequestsApproveModalMessageSuffix.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের তথ্যে প্রয়োগ করা হবে।'**
  String get adminPropertyRequestsApproveModalMessageSuffix;

  /// No description provided for @adminPropertyRequestsApproveModalTitle.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ অনুমোদন'**
  String get adminPropertyRequestsApproveModalTitle;

  /// No description provided for @adminPropertyRequestsCancelButton.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get adminPropertyRequestsCancelButton;

  /// No description provided for @adminPropertyRequestsCancelModalConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ বাতিল করুন'**
  String get adminPropertyRequestsCancelModalConfirmLabel;

  /// No description provided for @adminPropertyRequestsCancelModalMessageSuffix.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল করা হবে।'**
  String get adminPropertyRequestsCancelModalMessageSuffix;

  /// No description provided for @adminPropertyRequestsCancelModalPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'বাতিলের কারণ লিখুন...'**
  String get adminPropertyRequestsCancelModalPlaceholder;

  /// No description provided for @adminPropertyRequestsCancelModalTitle.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ বাতিল'**
  String get adminPropertyRequestsCancelModalTitle;

  /// No description provided for @adminPropertyRequestsCancelReasonLabel.
  ///
  /// In bn, this message translates to:
  /// **'বাতিলের কারণ'**
  String get adminPropertyRequestsCancelReasonLabel;

  /// No description provided for @adminPropertyRequestsDeleteRequestNote.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য এই সম্পত্তিটি মুছে ফেলার অনুরোধ করেছেন।'**
  String get adminPropertyRequestsDeleteRequestNote;

  /// No description provided for @adminPropertyRequestsErrorsApproveFailed.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ অনুমোদন করা যায়নি।'**
  String get adminPropertyRequestsErrorsApproveFailed;

  /// No description provided for @adminPropertyRequestsErrorsCancelFailed.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ বাতিল করা যায়নি।'**
  String get adminPropertyRequestsErrorsCancelFailed;

  /// No description provided for @adminPropertyRequestsErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'তালিকা লোড করা যায়নি।'**
  String get adminPropertyRequestsErrorsLoadFailed;

  /// No description provided for @adminPropertyRequestsErrorsReasonRequired.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল করতে কারণ দিতে হবে।'**
  String get adminPropertyRequestsErrorsReasonRequired;

  /// No description provided for @adminPropertyRequestsNoRequests.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সম্পত্তি সংক্রান্ত অনুরোধ পাওয়া যায়নি'**
  String get adminPropertyRequestsNoRequests;

  /// No description provided for @adminPropertyRequestsStatusLabelsAll.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get adminPropertyRequestsStatusLabelsAll;

  /// No description provided for @adminPropertyRequestsStatusLabelsApproved.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদিত'**
  String get adminPropertyRequestsStatusLabelsApproved;

  /// No description provided for @adminPropertyRequestsStatusLabelsCancelled.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get adminPropertyRequestsStatusLabelsCancelled;

  /// No description provided for @adminPropertyRequestsStatusLabelsPending.
  ///
  /// In bn, this message translates to:
  /// **'অপেক্ষমাণ'**
  String get adminPropertyRequestsStatusLabelsPending;

  /// No description provided for @adminPropertyRequestsSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের সম্পত্তি সংযোজন, সংশোধন বা মুছে ফেলার অনুরোধ পর্যালোচনা করুন'**
  String get adminPropertyRequestsSubtitle;

  /// No description provided for @adminPropertyRequestsTableHeadersAction.
  ///
  /// In bn, this message translates to:
  /// **'কার্য'**
  String get adminPropertyRequestsTableHeadersAction;

  /// No description provided for @adminPropertyRequestsTableHeadersActions.
  ///
  /// In bn, this message translates to:
  /// **'কার্যক্রম'**
  String get adminPropertyRequestsTableHeadersActions;

  /// No description provided for @adminPropertyRequestsTableHeadersDate.
  ///
  /// In bn, this message translates to:
  /// **'জমাদান'**
  String get adminPropertyRequestsTableHeadersDate;

  /// No description provided for @adminPropertyRequestsTableHeadersMember.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get adminPropertyRequestsTableHeadersMember;

  /// No description provided for @adminPropertyRequestsTableHeadersProperty.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি'**
  String get adminPropertyRequestsTableHeadersProperty;

  /// No description provided for @adminPropertyRequestsTableHeadersReference.
  ///
  /// In bn, this message translates to:
  /// **'রেফারেন্স'**
  String get adminPropertyRequestsTableHeadersReference;

  /// No description provided for @adminPropertyRequestsTableHeadersStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get adminPropertyRequestsTableHeadersStatus;

  /// No description provided for @adminPropertyRequestsTitle.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি সংক্রান্ত অনুরোধ'**
  String get adminPropertyRequestsTitle;

  /// No description provided for @adminRoadmapAdd.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পরিকল্পনা'**
  String get adminRoadmapAdd;

  /// No description provided for @adminRoadmapAddHere.
  ///
  /// In bn, this message translates to:
  /// **'যোগ করুন'**
  String get adminRoadmapAddHere;

  /// No description provided for @adminRoadmapArchiveAll.
  ///
  /// In bn, this message translates to:
  /// **'সব পরিকল্পনা আর্কাইভ করে নতুন চক্র শুরু করুন'**
  String get adminRoadmapArchiveAll;

  /// No description provided for @adminRoadmapArchiveButton.
  ///
  /// In bn, this message translates to:
  /// **'চক্র আর্কাইভ'**
  String get adminRoadmapArchiveButton;

  /// No description provided for @adminRoadmapArchiveConfirm.
  ///
  /// In bn, this message translates to:
  /// **'আর্কাইভ করুন'**
  String get adminRoadmapArchiveConfirm;

  /// No description provided for @adminRoadmapArchiveCycleSummary.
  ///
  /// In bn, this message translates to:
  /// **'{total}টির মধ্যে {done}টি সম্পন্ন'**
  String adminRoadmapArchiveCycleSummary(Object done, Object total);

  /// No description provided for @adminRoadmapArchiveDone.
  ///
  /// In bn, this message translates to:
  /// **'{n}টি পরিকল্পনা আর্কাইভ করা হয়েছে।'**
  String adminRoadmapArchiveDone(Object n);

  /// No description provided for @adminRoadmapArchiveEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো চক্র আর্কাইভ করা হয়নি।'**
  String get adminRoadmapArchiveEmpty;

  /// No description provided for @adminRoadmapArchiveHistory.
  ///
  /// In bn, this message translates to:
  /// **'আর্কাইভ করা চক্র'**
  String get adminRoadmapArchiveHistory;

  /// No description provided for @adminRoadmapArchiveMessage.
  ///
  /// In bn, this message translates to:
  /// **'আর্কাইভ করা পরিকল্পনা সদস্যদের পেজ থেকে সরে যাবে, তবে ইতিহাসে সংরক্ষিত থাকবে।'**
  String get adminRoadmapArchiveMessage;

  /// No description provided for @adminRoadmapArchiveOnlyDone.
  ///
  /// In bn, this message translates to:
  /// **'শুধু সম্পন্ন পরিকল্পনা আর্কাইভ করুন (বাকিগুলো নতুন চক্রে থাকবে)'**
  String get adminRoadmapArchiveOnlyDone;

  /// No description provided for @adminRoadmapArchiveTitle.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পনা চক্র আর্কাইভ করুন'**
  String get adminRoadmapArchiveTitle;

  /// No description provided for @adminRoadmapDeleteTitle.
  ///
  /// In bn, this message translates to:
  /// **'এই পরিকল্পনাটি মুছবেন?'**
  String get adminRoadmapDeleteTitle;

  /// No description provided for @adminRoadmapErrorsGeneric.
  ///
  /// In bn, this message translates to:
  /// **'কাজটি সম্পন্ন করা যায়নি। আবার চেষ্টা করুন।'**
  String get adminRoadmapErrorsGeneric;

  /// No description provided for @adminRoadmapErrorsNoteTooLong.
  ///
  /// In bn, this message translates to:
  /// **'নোট সর্বোচ্চ ১০০০ অক্ষর হতে পারে।'**
  String get adminRoadmapErrorsNoteTooLong;

  /// No description provided for @adminRoadmapErrorsOwnerTooLong.
  ///
  /// In bn, this message translates to:
  /// **'দায়িত্বপ্রাপ্তের নাম সর্বোচ্চ ১২০ অক্ষর হতে পারে।'**
  String get adminRoadmapErrorsOwnerTooLong;

  /// No description provided for @adminRoadmapErrorsTextRequired.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পনার বিবরণ লিখুন।'**
  String get adminRoadmapErrorsTextRequired;

  /// No description provided for @adminRoadmapErrorsTextTooLong.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পনার বিবরণ সর্বোচ্চ ৫০০ অক্ষর হতে পারে।'**
  String get adminRoadmapErrorsTextTooLong;

  /// No description provided for @adminRoadmapErrorsTimeframe.
  ///
  /// In bn, this message translates to:
  /// **'একটি সময়সীমা নির্বাচন করুন।'**
  String get adminRoadmapErrorsTimeframe;

  /// No description provided for @adminRoadmapFormCreateTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পরিকল্পনা যোগ করুন'**
  String get adminRoadmapFormCreateTitle;

  /// No description provided for @adminRoadmapFormEditTitle.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পনা সম্পাদনা'**
  String get adminRoadmapFormEditTitle;

  /// No description provided for @adminRoadmapFormMoveHint.
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষণ করলে পরিকল্পনাটি নির্বাচিত সময়সীমার শেষে চলে যাবে।'**
  String get adminRoadmapFormMoveHint;

  /// No description provided for @adminRoadmapFormNote.
  ///
  /// In bn, this message translates to:
  /// **'হালনাগাদ / নোট (ঐচ্ছিক)'**
  String get adminRoadmapFormNote;

  /// No description provided for @adminRoadmapFormNotePlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: বালু ভরাট শুরু হয়েছে, আশা করা হচ্ছে নভেম্বরের মধ্যে শেষ হবে'**
  String get adminRoadmapFormNotePlaceholder;

  /// No description provided for @adminRoadmapFormNotify.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের নোটিশ পাঠান'**
  String get adminRoadmapFormNotify;

  /// No description provided for @adminRoadmapFormOwner.
  ///
  /// In bn, this message translates to:
  /// **'দায়িত্বপ্রাপ্ত (ঐচ্ছিক)'**
  String get adminRoadmapFormOwner;

  /// No description provided for @adminRoadmapFormOwnerPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: সাধারণ সম্পাদক'**
  String get adminRoadmapFormOwnerPlaceholder;

  /// No description provided for @adminRoadmapFormStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get adminRoadmapFormStatus;

  /// No description provided for @adminRoadmapFormTargetDate.
  ///
  /// In bn, this message translates to:
  /// **'লক্ষ্য তারিখ (ঐচ্ছিক)'**
  String get adminRoadmapFormTargetDate;

  /// No description provided for @adminRoadmapFormText.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পনা'**
  String get adminRoadmapFormText;

  /// No description provided for @adminRoadmapFormTimeframe.
  ///
  /// In bn, this message translates to:
  /// **'সময়সীমা'**
  String get adminRoadmapFormTimeframe;

  /// No description provided for @adminRoadmapMoveDown.
  ///
  /// In bn, this message translates to:
  /// **'নিচে সরান'**
  String get adminRoadmapMoveDown;

  /// No description provided for @adminRoadmapMoveUp.
  ///
  /// In bn, this message translates to:
  /// **'উপরে সরান'**
  String get adminRoadmapMoveUp;

  /// No description provided for @adminRoadmapNotifyOnDone.
  ///
  /// In bn, this message translates to:
  /// **'সম্পন্ন হলে সদস্যদের নোটিশ পাঠান'**
  String get adminRoadmapNotifyOnDone;

  /// No description provided for @adminRoadmapOverall.
  ///
  /// In bn, this message translates to:
  /// **'মোট {total}টির মধ্যে {done}টি সম্পন্ন'**
  String adminRoadmapOverall(Object done, Object total);

  /// No description provided for @adminRoadmapStatusAria.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা পরিবর্তন'**
  String get adminRoadmapStatusAria;

  /// No description provided for @adminRoadmapSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'স্বল্প, মধ্য ও দীর্ঘমেয়াদি পরিকল্পনা যোগ, সম্পাদনা ও অগ্রগতি হালনাগাদ করুন। প্রতিটি পরিবর্তন অডিট লগে সংরক্ষিত হয়।'**
  String get adminRoadmapSubtitle;

  /// No description provided for @adminRoadmapTitle.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পনা ব্যবস্থাপনা'**
  String get adminRoadmapTitle;

  /// No description provided for @adminRoadmapViewAsMember.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের ভিউ'**
  String get adminRoadmapViewAsMember;

  /// No description provided for @adminRoleManagementAllPermissionsAlways.
  ///
  /// In bn, this message translates to:
  /// **'সকল অনুমতি — সর্বদা'**
  String get adminRoleManagementAllPermissionsAlways;

  /// No description provided for @adminRoleManagementCreateAdminEmailLabel.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get adminRoleManagementCreateAdminEmailLabel;

  /// No description provided for @adminRoleManagementCreateAdminNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get adminRoleManagementCreateAdminNameLabel;

  /// No description provided for @adminRoleManagementCreateAdminNamePlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'পূর্ণ নাম'**
  String get adminRoleManagementCreateAdminNamePlaceholder;

  /// No description provided for @adminRoleManagementCreateAdminPasswordLabel.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড'**
  String get adminRoleManagementCreateAdminPasswordLabel;

  /// No description provided for @adminRoleManagementCreateAdminPasswordPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড'**
  String get adminRoleManagementCreateAdminPasswordPlaceholder;

  /// No description provided for @adminRoleManagementCreateAdminRoleLabel.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা'**
  String get adminRoleManagementCreateAdminRoleLabel;

  /// No description provided for @adminRoleManagementCreateAdminSubmitButton.
  ///
  /// In bn, this message translates to:
  /// **'প্রশাসক তৈরি করুন'**
  String get adminRoleManagementCreateAdminSubmitButton;

  /// No description provided for @adminRoleManagementCreateAdminSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল ও পাসওয়ার্ড দিয়ে একজন নতুন প্রশাসক অ্যাকাউন্ট তৈরি করুন।'**
  String get adminRoleManagementCreateAdminSubtitle;

  /// No description provided for @adminRoleManagementCreateAdminSuccessPrefix.
  ///
  /// In bn, this message translates to:
  /// **'নতুন প্রশাসক তৈরি হয়েছে:'**
  String get adminRoleManagementCreateAdminSuccessPrefix;

  /// No description provided for @adminRoleManagementCreateAdminTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন প্রশাসক তৈরি করুন'**
  String get adminRoleManagementCreateAdminTitle;

  /// No description provided for @adminRoleManagementErrorsAssignRoleFailed.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা নির্ধারণ করা যায়নি।'**
  String get adminRoleManagementErrorsAssignRoleFailed;

  /// No description provided for @adminRoleManagementErrorsCreateUserFailed.
  ///
  /// In bn, this message translates to:
  /// **'নতুন প্রশাসক তৈরি করা যায়নি।'**
  String get adminRoleManagementErrorsCreateUserFailed;

  /// No description provided for @adminRoleManagementErrorsLoadOverridesFailed.
  ///
  /// In bn, this message translates to:
  /// **'স্বতন্ত্র অনুমতি লোড করা যায়নি।'**
  String get adminRoleManagementErrorsLoadOverridesFailed;

  /// No description provided for @adminRoleManagementErrorsLoadPermissionsFailed.
  ///
  /// In bn, this message translates to:
  /// **'অনুমতি তালিকা লোড করা যায়নি।'**
  String get adminRoleManagementErrorsLoadPermissionsFailed;

  /// No description provided for @adminRoleManagementErrorsLoadRolesFailed.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা তালিকা লোড করা যায়নি।'**
  String get adminRoleManagementErrorsLoadRolesFailed;

  /// No description provided for @adminRoleManagementErrorsLoadUsersFailed.
  ///
  /// In bn, this message translates to:
  /// **'ব্যবহারকারী তালিকা লোড করা যায়নি।'**
  String get adminRoleManagementErrorsLoadUsersFailed;

  /// No description provided for @adminRoleManagementErrorsSaveChangeFailed.
  ///
  /// In bn, this message translates to:
  /// **'পরিবর্তন সংরক্ষণ করা যায়নি।'**
  String get adminRoleManagementErrorsSaveChangeFailed;

  /// No description provided for @adminRoleManagementErrorsSaveOverridesFailed.
  ///
  /// In bn, this message translates to:
  /// **'স্বতন্ত্র অনুমতি সংরক্ষণ করা যায়নি।'**
  String get adminRoleManagementErrorsSaveOverridesFailed;

  /// No description provided for @adminRoleManagementSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'প্রতিটি ভূমিকার জন্য অনুমতি নির্ধারণ করুন'**
  String get adminRoleManagementSubtitle;

  /// No description provided for @adminRoleManagementTitle.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা ও অনুমতি ব্যবস্থাপনা'**
  String get adminRoleManagementTitle;

  /// No description provided for @adminRoleManagementUserOverridesActionLabel.
  ///
  /// In bn, this message translates to:
  /// **'কার্যক্রম'**
  String get adminRoleManagementUserOverridesActionLabel;

  /// No description provided for @adminRoleManagementUserOverridesApplyButton.
  ///
  /// In bn, this message translates to:
  /// **'প্রয়োগ করুন'**
  String get adminRoleManagementUserOverridesApplyButton;

  /// No description provided for @adminRoleManagementUserOverridesAssignRoleLabel.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা নির্ধারণ করুন'**
  String get adminRoleManagementUserOverridesAssignRoleLabel;

  /// No description provided for @adminRoleManagementUserOverridesGrantOption.
  ///
  /// In bn, this message translates to:
  /// **'অতিরিক্ত গ্রান্ট করুন'**
  String get adminRoleManagementUserOverridesGrantOption;

  /// No description provided for @adminRoleManagementUserOverridesNoOverrides.
  ///
  /// In bn, this message translates to:
  /// **'এই ব্যবহারকারীর জন্য কোনো স্বতন্ত্র অনুমতি নেই।'**
  String get adminRoleManagementUserOverridesNoOverrides;

  /// No description provided for @adminRoleManagementUserOverridesPermissionLabel.
  ///
  /// In bn, this message translates to:
  /// **'অনুমতি'**
  String get adminRoleManagementUserOverridesPermissionLabel;

  /// No description provided for @adminRoleManagementUserOverridesRevokeOption.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যাহার করুন'**
  String get adminRoleManagementUserOverridesRevokeOption;

  /// No description provided for @adminRoleManagementUserOverridesSaveRoleButton.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা সংরক্ষণ করুন'**
  String get adminRoleManagementUserOverridesSaveRoleButton;

  /// No description provided for @adminRoleManagementUserOverridesSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'একজন নির্দিষ্ট ব্যবহারকারীর জন্য তার ভূমিকার ডিফল্টের বাইরে গিয়ে অতিরিক্ত অনুমতি দিন বা প্রত্যাহার করুন।'**
  String get adminRoleManagementUserOverridesSubtitle;

  /// No description provided for @adminRoleManagementUserOverridesTitle.
  ///
  /// In bn, this message translates to:
  /// **'ব্যবহারকারী-ভিত্তিক ওভাররাইড'**
  String get adminRoleManagementUserOverridesTitle;

  /// No description provided for @adminRoleManagementUserOverridesUserLabel.
  ///
  /// In bn, this message translates to:
  /// **'ব্যবহারকারী'**
  String get adminRoleManagementUserOverridesUserLabel;

  /// No description provided for @adminSocietyCostsCreate.
  ///
  /// In bn, this message translates to:
  /// **'নতুন খরচ'**
  String get adminSocietyCostsCreate;

  /// No description provided for @adminSocietyCostsCreateTitle.
  ///
  /// In bn, this message translates to:
  /// **'খরচ লিপিবদ্ধ করুন'**
  String get adminSocietyCostsCreateTitle;

  /// No description provided for @adminSocietyCostsDeleteMessage.
  ///
  /// In bn, this message translates to:
  /// **'খরচ ও তার ভাগ মুছে যাবে। এটি ফিরিয়ে আনা যাবে না।'**
  String get adminSocietyCostsDeleteMessage;

  /// No description provided for @adminSocietyCostsDeleteTitle.
  ///
  /// In bn, this message translates to:
  /// **'খরচ মুছুন'**
  String get adminSocietyCostsDeleteTitle;

  /// No description provided for @adminSocietyCostsEdit.
  ///
  /// In bn, this message translates to:
  /// **'সম্পাদনা'**
  String get adminSocietyCostsEdit;

  /// No description provided for @adminSocietyCostsEditTitle.
  ///
  /// In bn, this message translates to:
  /// **'খরচ সম্পাদনা'**
  String get adminSocietyCostsEditTitle;

  /// No description provided for @adminSocietyCostsEmptyState.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো খরচ লিপিবদ্ধ হয়নি'**
  String get adminSocietyCostsEmptyState;

  /// No description provided for @adminSocietyCostsErrorsAmountRequired.
  ///
  /// In bn, this message translates to:
  /// **'শূন্যের বেশি পরিমাণ লিখুন।'**
  String get adminSocietyCostsErrorsAmountRequired;

  /// No description provided for @adminSocietyCostsErrorsCategoryAddFailed.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি যোগ করা যায়নি।'**
  String get adminSocietyCostsErrorsCategoryAddFailed;

  /// No description provided for @adminSocietyCostsErrorsDateRequired.
  ///
  /// In bn, this message translates to:
  /// **'খরচের তারিখ দিতে হবে।'**
  String get adminSocietyCostsErrorsDateRequired;

  /// No description provided for @adminSocietyCostsErrorsDeleteFailed.
  ///
  /// In bn, this message translates to:
  /// **'খরচ মুছা যায়নি। এর বিপক্ষে পেমেন্ট রেকর্ড থাকতে পারে।'**
  String get adminSocietyCostsErrorsDeleteFailed;

  /// No description provided for @adminSocietyCostsErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'সোসাইটি খরচ লোড করা যায়নি। আবার চেষ্টা করুন।'**
  String get adminSocietyCostsErrorsLoadFailed;

  /// No description provided for @adminSocietyCostsErrorsPaymentFailed.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট রেকর্ড করা যায়নি। আবার চেষ্টা করুন।'**
  String get adminSocietyCostsErrorsPaymentFailed;

  /// No description provided for @adminSocietyCostsErrorsReceiptUploadFailed.
  ///
  /// In bn, this message translates to:
  /// **'খরচ সেভ হয়েছে, কিন্তু রসিদ আপলোড ব্যর্থ হয়েছে। সম্পাদনা থেকে আবার চেষ্টা করুন।'**
  String get adminSocietyCostsErrorsReceiptUploadFailed;

  /// No description provided for @adminSocietyCostsErrorsSaveFailed.
  ///
  /// In bn, this message translates to:
  /// **'খরচ সেভ করা যায়নি। আবার চেষ্টা করুন।'**
  String get adminSocietyCostsErrorsSaveFailed;

  /// No description provided for @adminSocietyCostsErrorsSplitFailed.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ সেভ করা যায়নি। আবার চেষ্টা করুন।'**
  String get adminSocietyCostsErrorsSplitFailed;

  /// No description provided for @adminSocietyCostsErrorsSplitPreviewFailed.
  ///
  /// In bn, this message translates to:
  /// **'ভাগের প্রিভিউ হিসাব করা যায়নি।'**
  String get adminSocietyCostsErrorsSplitPreviewFailed;

  /// No description provided for @adminSocietyCostsErrorsTitleRequired.
  ///
  /// In bn, this message translates to:
  /// **'শিরোনাম দিতে হবে।'**
  String get adminSocietyCostsErrorsTitleRequired;

  /// No description provided for @adminSocietyCostsExportCsv.
  ///
  /// In bn, this message translates to:
  /// **'CSV এক্সপোর্ট'**
  String get adminSocietyCostsExportCsv;

  /// No description provided for @adminSocietyCostsFiltersAll.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get adminSocietyCostsFiltersAll;

  /// No description provided for @adminSocietyCostsFiltersAllCategories.
  ///
  /// In bn, this message translates to:
  /// **'সব ক্যাটাগরি'**
  String get adminSocietyCostsFiltersAllCategories;

  /// No description provided for @adminSocietyCostsFiltersAllSources.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get adminSocietyCostsFiltersAllSources;

  /// No description provided for @adminSocietyCostsFiltersBilled.
  ///
  /// In bn, this message translates to:
  /// **'বিলিং অবস্থা'**
  String get adminSocietyCostsFiltersBilled;

  /// No description provided for @adminSocietyCostsFiltersBilledOnly.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের বিল করা'**
  String get adminSocietyCostsFiltersBilledOnly;

  /// No description provided for @adminSocietyCostsFiltersCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি'**
  String get adminSocietyCostsFiltersCategory;

  /// No description provided for @adminSocietyCostsFiltersDateRange.
  ///
  /// In bn, this message translates to:
  /// **'তারিখের পরিসর'**
  String get adminSocietyCostsFiltersDateRange;

  /// No description provided for @adminSocietyCostsFiltersReset.
  ///
  /// In bn, this message translates to:
  /// **'রিসেট'**
  String get adminSocietyCostsFiltersReset;

  /// No description provided for @adminSocietyCostsFiltersSearch.
  ///
  /// In bn, this message translates to:
  /// **'খুঁজুন'**
  String get adminSocietyCostsFiltersSearch;

  /// No description provided for @adminSocietyCostsFiltersSearchPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'শিরোনাম দিয়ে খুঁজুন…'**
  String get adminSocietyCostsFiltersSearchPlaceholder;

  /// No description provided for @adminSocietyCostsFiltersSource.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট সোর্স'**
  String get adminSocietyCostsFiltersSource;

  /// No description provided for @adminSocietyCostsFiltersUnbilledOnly.
  ///
  /// In bn, this message translates to:
  /// **'বিল করা হয়নি'**
  String get adminSocietyCostsFiltersUnbilledOnly;

  /// No description provided for @adminSocietyCostsFormAddCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি যোগ + Enter'**
  String get adminSocietyCostsFormAddCategory;

  /// No description provided for @adminSocietyCostsFormAmount.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ (৳)'**
  String get adminSocietyCostsFormAmount;

  /// No description provided for @adminSocietyCostsFormCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি'**
  String get adminSocietyCostsFormCategory;

  /// No description provided for @adminSocietyCostsFormDate.
  ///
  /// In bn, this message translates to:
  /// **'খরচের তারিখ'**
  String get adminSocietyCostsFormDate;

  /// No description provided for @adminSocietyCostsFormDescription.
  ///
  /// In bn, this message translates to:
  /// **'বিবরণ'**
  String get adminSocietyCostsFormDescription;

  /// No description provided for @adminSocietyCostsFormNoCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি নেই'**
  String get adminSocietyCostsFormNoCategory;

  /// No description provided for @adminSocietyCostsFormNotes.
  ///
  /// In bn, this message translates to:
  /// **'নোট'**
  String get adminSocietyCostsFormNotes;

  /// No description provided for @adminSocietyCostsFormReceipt.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ (ছবি/PDF)'**
  String get adminSocietyCostsFormReceipt;

  /// No description provided for @adminSocietyCostsFormSource.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধ সূত্র'**
  String get adminSocietyCostsFormSource;

  /// No description provided for @adminSocietyCostsFormTitle.
  ///
  /// In bn, this message translates to:
  /// **'শিরোনাম'**
  String get adminSocietyCostsFormTitle;

  /// No description provided for @adminSocietyCostsNotBilled.
  ///
  /// In bn, this message translates to:
  /// **'বিল করা হয়নি'**
  String get adminSocietyCostsNotBilled;

  /// No description provided for @adminSocietyCostsPaymentAmount.
  ///
  /// In bn, this message translates to:
  /// **'এখন পরিশোধিত পরিমাণ (৳)'**
  String get adminSocietyCostsPaymentAmount;

  /// No description provided for @adminSocietyCostsPaymentRemaining.
  ///
  /// In bn, this message translates to:
  /// **'বাকি'**
  String get adminSocietyCostsPaymentRemaining;

  /// No description provided for @adminSocietyCostsPaymentTitle.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট রেকর্ড করুন'**
  String get adminSocietyCostsPaymentTitle;

  /// No description provided for @adminSocietyCostsRecordPayment.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট রেকর্ড করুন'**
  String get adminSocietyCostsRecordPayment;

  /// No description provided for @adminSocietyCostsShareStatusPaid.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত'**
  String get adminSocietyCostsShareStatusPaid;

  /// No description provided for @adminSocietyCostsShareStatusPartial.
  ///
  /// In bn, this message translates to:
  /// **'আংশিক'**
  String get adminSocietyCostsShareStatusPartial;

  /// No description provided for @adminSocietyCostsShareStatusUnpaid.
  ///
  /// In bn, this message translates to:
  /// **'অনাদায়ী'**
  String get adminSocietyCostsShareStatusUnpaid;

  /// No description provided for @adminSocietyCostsSourceMemberBilled.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের কাছে বিল'**
  String get adminSocietyCostsSourceMemberBilled;

  /// No description provided for @adminSocietyCostsSourceSocietyFund.
  ///
  /// In bn, this message translates to:
  /// **'সোসাইটি ফান্ড'**
  String get adminSocietyCostsSourceSocietyFund;

  /// No description provided for @adminSocietyCostsSplitConfirm.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ নিশ্চিত করুন'**
  String get adminSocietyCostsSplitConfirm;

  /// No description provided for @adminSocietyCostsSplitMethod.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ করার পদ্ধতি'**
  String get adminSocietyCostsSplitMethod;

  /// No description provided for @adminSocietyCostsSplitMismatchWarning.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণগুলো খরচের মোটের সাথে মিলছে না। ঠিক করুন, অথবা এভাবেই সেভ করতে ওভাররাইড নিশ্চিত করুন।'**
  String get adminSocietyCostsSplitMismatchWarning;

  /// No description provided for @adminSocietyCostsSplitNoMembers.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ করার মতো কোনো সক্রিয় সদস্য নেই।'**
  String get adminSocietyCostsSplitNoMembers;

  /// No description provided for @adminSocietyCostsSplitOverride.
  ///
  /// In bn, this message translates to:
  /// **'অমিল সত্ত্বেও সেভ করুন'**
  String get adminSocietyCostsSplitOverride;

  /// No description provided for @adminSocietyCostsSplitRunningTotal.
  ///
  /// In bn, this message translates to:
  /// **'চলতি মোট'**
  String get adminSocietyCostsSplitRunningTotal;

  /// No description provided for @adminSocietyCostsSplitSummaryLine.
  ///
  /// In bn, this message translates to:
  /// **'৳{total} সক্রিয় সদস্যদের মধ্যে ভাগ হচ্ছে ({method})'**
  String adminSocietyCostsSplitSummaryLine(Object method, Object total);

  /// No description provided for @adminSocietyCostsSplitTitle.
  ///
  /// In bn, this message translates to:
  /// **'খরচ ভাগ করুন'**
  String get adminSocietyCostsSplitTitle;

  /// No description provided for @adminSocietyCostsSplitAction.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ করুন'**
  String get adminSocietyCostsSplitAction;

  /// No description provided for @adminSocietyCostsSplitMethodByLandQuantity.
  ///
  /// In bn, this message translates to:
  /// **'জমির পরিমাণ অনুযায়ী'**
  String get adminSocietyCostsSplitMethodByLandQuantity;

  /// No description provided for @adminSocietyCostsSplitMethodEqual.
  ///
  /// In bn, this message translates to:
  /// **'সমান ভাগ'**
  String get adminSocietyCostsSplitMethodEqual;

  /// No description provided for @adminSocietyCostsSplitMethodManual.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানুয়াল'**
  String get adminSocietyCostsSplitMethodManual;

  /// No description provided for @adminSocietyCostsSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সোসাইটির প্রতিটি খরচ লিপিবদ্ধ করুন, প্রয়োজনে সদস্যদের মধ্যে ভাগ করুন'**
  String get adminSocietyCostsSubtitle;

  /// No description provided for @adminSocietyCostsSummaryOutstanding.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের বকেয়া'**
  String get adminSocietyCostsSummaryOutstanding;

  /// No description provided for @adminSocietyCostsSummarySocietyFund.
  ///
  /// In bn, this message translates to:
  /// **'সোসাইটি ফান্ড থেকে'**
  String get adminSocietyCostsSummarySocietyFund;

  /// No description provided for @adminSocietyCostsSummaryTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট খরচ'**
  String get adminSocietyCostsSummaryTotal;

  /// No description provided for @adminSocietyCostsTableAmount.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get adminSocietyCostsTableAmount;

  /// No description provided for @adminSocietyCostsTableCategory.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাটাগরি'**
  String get adminSocietyCostsTableCategory;

  /// No description provided for @adminSocietyCostsTableDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get adminSocietyCostsTableDate;

  /// No description provided for @adminSocietyCostsTableSource.
  ///
  /// In bn, this message translates to:
  /// **'সোর্স'**
  String get adminSocietyCostsTableSource;

  /// No description provided for @adminSocietyCostsTableSplit.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ'**
  String get adminSocietyCostsTableSplit;

  /// No description provided for @adminSocietyCostsTableTitle.
  ///
  /// In bn, this message translates to:
  /// **'শিরোনাম'**
  String get adminSocietyCostsTableTitle;

  /// No description provided for @adminSocietyCostsTitle.
  ///
  /// In bn, this message translates to:
  /// **'সোসাইটি খরচ'**
  String get adminSocietyCostsTitle;

  /// No description provided for @adminSocietyCostsViewReceipt.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ দেখুন'**
  String get adminSocietyCostsViewReceipt;

  /// No description provided for @adminStatusLabelsAll.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get adminStatusLabelsAll;

  /// No description provided for @adminStatusLabelsApproved.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদিত'**
  String get adminStatusLabelsApproved;

  /// No description provided for @adminStatusLabelsPending.
  ///
  /// In bn, this message translates to:
  /// **'বিচারাধীন'**
  String get adminStatusLabelsPending;

  /// No description provided for @adminStatusLabelsRejected.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যাখ্যাত'**
  String get adminStatusLabelsRejected;

  /// No description provided for @adminSubmissionDetailAlsoEmergency.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগের সাথে একই'**
  String get adminSubmissionDetailAlsoEmergency;

  /// No description provided for @adminSubmissionDetailAlsoNominee.
  ///
  /// In bn, this message translates to:
  /// **'মনোনীতও'**
  String get adminSubmissionDetailAlsoNominee;

  /// No description provided for @adminSubmissionDetailApplicableDocs.
  ///
  /// In bn, this message translates to:
  /// **'প্রযোজ্য দলিল'**
  String get adminSubmissionDetailApplicableDocs;

  /// No description provided for @adminSubmissionDetailApproveButton.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদন করুন'**
  String get adminSubmissionDetailApproveButton;

  /// No description provided for @adminSubmissionDetailApproveModalConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'নিশ্চিত করুন ও অনুমোদন করুন'**
  String get adminSubmissionDetailApproveModalConfirmLabel;

  /// No description provided for @adminSubmissionDetailApproveModalMessageSuffix.
  ///
  /// In bn, this message translates to:
  /// **'কে সদস্য হিসেবে অনুমোদন দিলে স্বয়ংক্রিয়ভাবে একটি সদস্য আইডি ও লগইন তথ্য তৈরি হবে।'**
  String get adminSubmissionDetailApproveModalMessageSuffix;

  /// No description provided for @adminSubmissionDetailApproveModalTitle.
  ///
  /// In bn, this message translates to:
  /// **'আবেদন অনুমোদন করুন'**
  String get adminSubmissionDetailApproveModalTitle;

  /// No description provided for @adminSubmissionDetailAttachments.
  ///
  /// In bn, this message translates to:
  /// **'সংযুক্তি'**
  String get adminSubmissionDetailAttachments;

  /// No description provided for @adminSubmissionDetailCall.
  ///
  /// In bn, this message translates to:
  /// **'কল করুন'**
  String get adminSubmissionDetailCall;

  /// No description provided for @adminSubmissionDetailCollapse.
  ///
  /// In bn, this message translates to:
  /// **'সংকুচিত করুন'**
  String get adminSubmissionDetailCollapse;

  /// No description provided for @adminSubmissionDetailCopied.
  ///
  /// In bn, this message translates to:
  /// **'কপি হয়েছে'**
  String get adminSubmissionDetailCopied;

  /// No description provided for @adminSubmissionDetailCopyValue.
  ///
  /// In bn, this message translates to:
  /// **'কপি করুন'**
  String get adminSubmissionDetailCopyValue;

  /// No description provided for @adminSubmissionDetailCurrentAddress.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ঠিকানা'**
  String get adminSubmissionDetailCurrentAddress;

  /// No description provided for @adminSubmissionDetailDecimalUnit.
  ///
  /// In bn, this message translates to:
  /// **'শতাংশ'**
  String get adminSubmissionDetailDecimalUnit;

  /// No description provided for @adminSubmissionDetailDownload.
  ///
  /// In bn, this message translates to:
  /// **'ডাউনলোড'**
  String get adminSubmissionDetailDownload;

  /// No description provided for @adminSubmissionDetailErrorsApproveFailed.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদন ব্যর্থ হয়েছে।'**
  String get adminSubmissionDetailErrorsApproveFailed;

  /// No description provided for @adminSubmissionDetailErrorsDownloadFailed.
  ///
  /// In bn, this message translates to:
  /// **'ডাউনলব্যর্থ হয়েছে। ফাইলটি সার্ভারে নেই বা নেটওয়ার্কে সমস্যা হয়েছে।'**
  String get adminSubmissionDetailErrorsDownloadFailed;

  /// No description provided for @adminSubmissionDetailErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'আবেদনের তথ্য পাওয়া যায়নি।'**
  String get adminSubmissionDetailErrorsLoadFailed;

  /// No description provided for @adminSubmissionDetailErrorsReasonRequired.
  ///
  /// In bn, this message translates to:
  /// **'বাতিলের কারণ লিখুন।'**
  String get adminSubmissionDetailErrorsReasonRequired;

  /// No description provided for @adminSubmissionDetailErrorsRejectEmailFailed.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যাখ্যাত হয়েছে, কিন্তু ইমেইল পাঠানো যায়নি।'**
  String get adminSubmissionDetailErrorsRejectEmailFailed;

  /// No description provided for @adminSubmissionDetailErrorsRejectFailed.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল করা ব্যর্থ হয়েছে।'**
  String get adminSubmissionDetailErrorsRejectFailed;

  /// No description provided for @adminSubmissionDetailErrorsResendFailed.
  ///
  /// In bn, this message translates to:
  /// **'বিজ্ঞপ্তি আবার পাঠানো যায়নি।'**
  String get adminSubmissionDetailErrorsResendFailed;

  /// No description provided for @adminSubmissionDetailErrorsUploadFailed.
  ///
  /// In bn, this message translates to:
  /// **'আপলোড ব্যর্থ হয়েছে। আবার চেষ্টা করুন।'**
  String get adminSubmissionDetailErrorsUploadFailed;

  /// No description provided for @adminSubmissionDetailExpand.
  ///
  /// In bn, this message translates to:
  /// **'বিস্তারিত'**
  String get adminSubmissionDetailExpand;

  /// No description provided for @adminSubmissionDetailFieldLabelsAddress.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা'**
  String get adminSubmissionDetailFieldLabelsAddress;

  /// No description provided for @adminSubmissionDetailFieldLabelsArea.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get adminSubmissionDetailFieldLabelsArea;

  /// No description provided for @adminSubmissionDetailFieldLabelsDagNoCs.
  ///
  /// In bn, this message translates to:
  /// **'দাগ নং (সিএস)'**
  String get adminSubmissionDetailFieldLabelsDagNoCs;

  /// No description provided for @adminSubmissionDetailFieldLabelsDagNoRs.
  ///
  /// In bn, this message translates to:
  /// **'দাগ নং (আরএস)'**
  String get adminSubmissionDetailFieldLabelsDagNoRs;

  /// No description provided for @adminSubmissionDetailFieldLabelsDescription.
  ///
  /// In bn, this message translates to:
  /// **'বিবরণ'**
  String get adminSubmissionDetailFieldLabelsDescription;

  /// No description provided for @adminSubmissionDetailFieldLabelsDob.
  ///
  /// In bn, this message translates to:
  /// **'জন্ম তারিখ'**
  String get adminSubmissionDetailFieldLabelsDob;

  /// No description provided for @adminSubmissionDetailFieldLabelsHoldingNumber.
  ///
  /// In bn, this message translates to:
  /// **'হোল্ডিং নং'**
  String get adminSubmissionDetailFieldLabelsHoldingNumber;

  /// No description provided for @adminSubmissionDetailFieldLabelsKhatianNo.
  ///
  /// In bn, this message translates to:
  /// **'খতিয়ান নং'**
  String get adminSubmissionDetailFieldLabelsKhatianNo;

  /// No description provided for @adminSubmissionDetailFieldLabelsLandQuantity.
  ///
  /// In bn, this message translates to:
  /// **'মোট জমির পরিমাণ (শতাংশ)'**
  String get adminSubmissionDetailFieldLabelsLandQuantity;

  /// No description provided for @adminSubmissionDetailFieldLabelsMobile.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get adminSubmissionDetailFieldLabelsMobile;

  /// No description provided for @adminSubmissionDetailFieldLabelsMyShareQuantity.
  ///
  /// In bn, this message translates to:
  /// **'আমার অংশের পরিমাণ (শতাংশ)'**
  String get adminSubmissionDetailFieldLabelsMyShareQuantity;

  /// No description provided for @adminSubmissionDetailFieldLabelsName.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get adminSubmissionDetailFieldLabelsName;

  /// No description provided for @adminSubmissionDetailFieldLabelsNid.
  ///
  /// In bn, this message translates to:
  /// **'NID'**
  String get adminSubmissionDetailFieldLabelsNid;

  /// No description provided for @adminSubmissionDetailFieldLabelsOwnership.
  ///
  /// In bn, this message translates to:
  /// **'মালিকানা'**
  String get adminSubmissionDetailFieldLabelsOwnership;

  /// No description provided for @adminSubmissionDetailFieldLabelsPercentage.
  ///
  /// In bn, this message translates to:
  /// **'শতাংশ'**
  String get adminSubmissionDetailFieldLabelsPercentage;

  /// No description provided for @adminSubmissionDetailFieldLabelsRelation.
  ///
  /// In bn, this message translates to:
  /// **'সম্পর্ক'**
  String get adminSubmissionDetailFieldLabelsRelation;

  /// No description provided for @adminSubmissionDetailFieldLabelsType.
  ///
  /// In bn, this message translates to:
  /// **'ধরন'**
  String get adminSubmissionDetailFieldLabelsType;

  /// No description provided for @adminSubmissionDetailFieldLabelsValue.
  ///
  /// In bn, this message translates to:
  /// **'মান'**
  String get adminSubmissionDetailFieldLabelsValue;

  /// No description provided for @adminSubmissionDetailFieldsAddress.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা'**
  String get adminSubmissionDetailFieldsAddress;

  /// No description provided for @adminSubmissionDetailFieldsAdmissionFee.
  ///
  /// In bn, this message translates to:
  /// **'ভর্তি ফি'**
  String get adminSubmissionDetailFieldsAdmissionFee;

  /// No description provided for @adminSubmissionDetailFieldsDistrict.
  ///
  /// In bn, this message translates to:
  /// **'জেলা'**
  String get adminSubmissionDetailFieldsDistrict;

  /// No description provided for @adminSubmissionDetailFieldsDivision.
  ///
  /// In bn, this message translates to:
  /// **'বিভাগ'**
  String get adminSubmissionDetailFieldsDivision;

  /// No description provided for @adminSubmissionDetailFieldsDob.
  ///
  /// In bn, this message translates to:
  /// **'জন্ম তারিখ'**
  String get adminSubmissionDetailFieldsDob;

  /// No description provided for @adminSubmissionDetailFieldsEmail.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get adminSubmissionDetailFieldsEmail;

  /// No description provided for @adminSubmissionDetailFieldsFatherOrHusband.
  ///
  /// In bn, this message translates to:
  /// **'পিতা/স্বামী'**
  String get adminSubmissionDetailFieldsFatherOrHusband;

  /// No description provided for @adminSubmissionDetailFieldsGender.
  ///
  /// In bn, this message translates to:
  /// **'লিঙ্গ'**
  String get adminSubmissionDetailFieldsGender;

  /// No description provided for @adminSubmissionDetailFieldsHouse.
  ///
  /// In bn, this message translates to:
  /// **'বাসা/হোল্ডিং নং'**
  String get adminSubmissionDetailFieldsHouse;

  /// No description provided for @adminSubmissionDetailFieldsMemberPhoto.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের ছবি'**
  String get adminSubmissionDetailFieldsMemberPhoto;

  /// No description provided for @adminSubmissionDetailFieldsMemberSignature.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের স্বাক্ষর'**
  String get adminSubmissionDetailFieldsMemberSignature;

  /// No description provided for @adminSubmissionDetailFieldsMobile.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get adminSubmissionDetailFieldsMobile;

  /// No description provided for @adminSubmissionDetailFieldsMother.
  ///
  /// In bn, this message translates to:
  /// **'মাতা'**
  String get adminSubmissionDetailFieldsMother;

  /// No description provided for @adminSubmissionDetailFieldsName.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get adminSubmissionDetailFieldsName;

  /// No description provided for @adminSubmissionDetailFieldsNationality.
  ///
  /// In bn, this message translates to:
  /// **'জাতীয়তা'**
  String get adminSubmissionDetailFieldsNationality;

  /// No description provided for @adminSubmissionDetailFieldsOccupation.
  ///
  /// In bn, this message translates to:
  /// **'পেশা'**
  String get adminSubmissionDetailFieldsOccupation;

  /// No description provided for @adminSubmissionDetailFieldsPaymentMethod.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট মাধ্যম'**
  String get adminSubmissionDetailFieldsPaymentMethod;

  /// No description provided for @adminSubmissionDetailFieldsPostOffice.
  ///
  /// In bn, this message translates to:
  /// **'ডাকঘর'**
  String get adminSubmissionDetailFieldsPostOffice;

  /// No description provided for @adminSubmissionDetailFieldsReceiptNo.
  ///
  /// In bn, this message translates to:
  /// **'রশিদ নং'**
  String get adminSubmissionDetailFieldsReceiptNo;

  /// No description provided for @adminSubmissionDetailFieldsReceiptPhoto.
  ///
  /// In bn, this message translates to:
  /// **'রশিদের ছবি'**
  String get adminSubmissionDetailFieldsReceiptPhoto;

  /// No description provided for @adminSubmissionDetailFieldsRejectionReason.
  ///
  /// In bn, this message translates to:
  /// **'বাতিলের কারণ'**
  String get adminSubmissionDetailFieldsRejectionReason;

  /// No description provided for @adminSubmissionDetailFieldsRelation.
  ///
  /// In bn, this message translates to:
  /// **'সম্পর্ক'**
  String get adminSubmissionDetailFieldsRelation;

  /// No description provided for @adminSubmissionDetailFieldsRoad.
  ///
  /// In bn, this message translates to:
  /// **'রাস্তা/গ্রাম'**
  String get adminSubmissionDetailFieldsRoad;

  /// No description provided for @adminSubmissionDetailFieldsStatus.
  ///
  /// In bn, this message translates to:
  /// **'স্ট্যাটাস'**
  String get adminSubmissionDetailFieldsStatus;

  /// No description provided for @adminSubmissionDetailFieldsSubscription.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদা'**
  String get adminSubmissionDetailFieldsSubscription;

  /// No description provided for @adminSubmissionDetailFieldsUpazila.
  ///
  /// In bn, this message translates to:
  /// **'উপজেলা/থানা'**
  String get adminSubmissionDetailFieldsUpazila;

  /// No description provided for @adminSubmissionDetailFileMissing.
  ///
  /// In bn, this message translates to:
  /// **'ফাইলটি সার্ভারে পাওয়া যায়নি। অনুগ্রহ করে আবার আপলোড করুন।'**
  String get adminSubmissionDetailFileMissing;

  /// No description provided for @adminSubmissionDetailJointOwnerCountLabel.
  ///
  /// In bn, this message translates to:
  /// **'যৌথ মালিকগণের সংখ্যা'**
  String get adminSubmissionDetailJointOwnerCountLabel;

  /// No description provided for @adminSubmissionDetailNoApplicableDocs.
  ///
  /// In bn, this message translates to:
  /// **'কোনো দলিল সংযুক্ত নেই।'**
  String get adminSubmissionDetailNoApplicableDocs;

  /// No description provided for @adminSubmissionDetailNoAttachment.
  ///
  /// In bn, this message translates to:
  /// **'সংযুক্ত নেই'**
  String get adminSubmissionDetailNoAttachment;

  /// No description provided for @adminSubmissionDetailNoNominees.
  ///
  /// In bn, this message translates to:
  /// **'কোনো মনোনীত ব্যক্তির তথ্য দেওয়া হয়নি।'**
  String get adminSubmissionDetailNoNominees;

  /// No description provided for @adminSubmissionDetailNoProperties.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সম্পত্তির তথ্য দেওয়া হয়নি।'**
  String get adminSubmissionDetailNoProperties;

  /// No description provided for @adminSubmissionDetailNomineeCardTitle.
  ///
  /// In bn, this message translates to:
  /// **'মনোনীত ব্যক্তি'**
  String get adminSubmissionDetailNomineeCardTitle;

  /// No description provided for @adminSubmissionDetailNomineeCount.
  ///
  /// In bn, this message translates to:
  /// **'মোট {count}জন'**
  String adminSubmissionDetailNomineeCount(Object count);

  /// No description provided for @adminSubmissionDetailNominees.
  ///
  /// In bn, this message translates to:
  /// **'মনোনীত ব্যক্তি'**
  String get adminSubmissionDetailNominees;

  /// No description provided for @adminSubmissionDetailNotNotified.
  ///
  /// In bn, this message translates to:
  /// **'আবেদনকারীকে ইমেইলে জানানো হয়নি।'**
  String get adminSubmissionDetailNotNotified;

  /// No description provided for @adminSubmissionDetailNotProvided.
  ///
  /// In bn, this message translates to:
  /// **'দেওয়া হয়নি'**
  String get adminSubmissionDetailNotProvided;

  /// No description provided for @adminSubmissionDetailPaymentSummary.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট ও স্ট্যাটাস'**
  String get adminSubmissionDetailPaymentSummary;

  /// No description provided for @adminSubmissionDetailPermanentAddress.
  ///
  /// In bn, this message translates to:
  /// **'স্থায়ী ঠিকানা'**
  String get adminSubmissionDetailPermanentAddress;

  /// No description provided for @adminSubmissionDetailPersonalInfo.
  ///
  /// In bn, this message translates to:
  /// **'ব্যক্তিগত তথ্য'**
  String get adminSubmissionDetailPersonalInfo;

  /// No description provided for @adminSubmissionDetailProperties.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তিসমূহ'**
  String get adminSubmissionDetailProperties;

  /// No description provided for @adminSubmissionDetailPropertyCardTitle.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি'**
  String get adminSubmissionDetailPropertyCardTitle;

  /// No description provided for @adminSubmissionDetailPropertyCount.
  ///
  /// In bn, this message translates to:
  /// **'মোট {count}টি'**
  String adminSubmissionDetailPropertyCount(Object count);

  /// No description provided for @adminSubmissionDetailRejectButton.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল করুন'**
  String get adminSubmissionDetailRejectButton;

  /// No description provided for @adminSubmissionDetailRejectModalConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যাখ্যান নিশ্চিত করুন'**
  String get adminSubmissionDetailRejectModalConfirmLabel;

  /// No description provided for @adminSubmissionDetailRejectModalMessageSuffix.
  ///
  /// In bn, this message translates to:
  /// **'এর আবেদন প্রত্যাখ্যানের কারণ লিখুন। এটি আবেদনকারীকে জানানো হবে।'**
  String get adminSubmissionDetailRejectModalMessageSuffix;

  /// No description provided for @adminSubmissionDetailRejectModalPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: প্রয়োজনীয় দলিল সংযুক্ত নেই...'**
  String get adminSubmissionDetailRejectModalPlaceholder;

  /// No description provided for @adminSubmissionDetailRejectModalTitle.
  ///
  /// In bn, this message translates to:
  /// **'আবেদন প্রত্যাখ্যান করুন'**
  String get adminSubmissionDetailRejectModalTitle;

  /// No description provided for @adminSubmissionDetailReplaceFile.
  ///
  /// In bn, this message translates to:
  /// **'ফাইল পরিবর্তন করুন'**
  String get adminSubmissionDetailReplaceFile;

  /// No description provided for @adminSubmissionDetailResendButton.
  ///
  /// In bn, this message translates to:
  /// **'আবার পাঠান'**
  String get adminSubmissionDetailResendButton;

  /// No description provided for @adminSubmissionDetailRoleApplicant.
  ///
  /// In bn, this message translates to:
  /// **'আবেদনকারী'**
  String get adminSubmissionDetailRoleApplicant;

  /// No description provided for @adminSubmissionDetailRoleColumn.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা'**
  String get adminSubmissionDetailRoleColumn;

  /// No description provided for @adminSubmissionDetailRoleEmergency.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি'**
  String get adminSubmissionDetailRoleEmergency;

  /// No description provided for @adminSubmissionDetailRoleNominee.
  ///
  /// In bn, this message translates to:
  /// **'মনোনীত'**
  String get adminSubmissionDetailRoleNominee;

  /// No description provided for @adminSubmissionDetailShareTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট শতাংশ: {value}%'**
  String adminSubmissionDetailShareTotal(Object value);

  /// No description provided for @adminSubmissionDetailShareWarning.
  ///
  /// In bn, this message translates to:
  /// **'মোট শতাংশ {value}% — ১০০% হতে হবে'**
  String adminSubmissionDetailShareWarning(Object value);

  /// No description provided for @adminSubmissionDetailSharedMobileWarning.
  ///
  /// In bn, this message translates to:
  /// **'এই নম্বরটি একাধিক সহ-মালিকের দ্বারা ব্যবহৃত হয়েছে'**
  String get adminSubmissionDetailSharedMobileWarning;

  /// No description provided for @adminSubmissionDetailTitle.
  ///
  /// In bn, this message translates to:
  /// **'আবেদনের বিস্তারিত'**
  String get adminSubmissionDetailTitle;

  /// No description provided for @adminSubmissionDetailUploadAgain.
  ///
  /// In bn, this message translates to:
  /// **'আবার আপলোড করুন'**
  String get adminSubmissionDetailUploadAgain;

  /// No description provided for @adminSubmissionDetailUploading.
  ///
  /// In bn, this message translates to:
  /// **'আপলোড হচ্ছে…'**
  String get adminSubmissionDetailUploading;

  /// No description provided for @adminSubmissionDetailUrgentContact.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগ'**
  String get adminSubmissionDetailUrgentContact;

  /// No description provided for @adminSubmissionDetailView.
  ///
  /// In bn, this message translates to:
  /// **'দেখুন'**
  String get adminSubmissionDetailView;

  /// No description provided for @adminSubmissionDetailViewFile.
  ///
  /// In bn, this message translates to:
  /// **'ফাইল দেখুন'**
  String get adminSubmissionDetailViewFile;

  /// No description provided for @adminSubmissionsListAllOption.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get adminSubmissionsListAllOption;

  /// No description provided for @adminSubmissionsListDetailsLink.
  ///
  /// In bn, this message translates to:
  /// **'বিস্তারিত'**
  String get adminSubmissionsListDetailsLink;

  /// No description provided for @adminSubmissionsListErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'তালিকা লোড করা যায়নি।'**
  String get adminSubmissionsListErrorsLoadFailed;

  /// No description provided for @adminSubmissionsListFilterLabel.
  ///
  /// In bn, this message translates to:
  /// **'স্ট্যাটাস অনুযায়ী ফিল্টার'**
  String get adminSubmissionsListFilterLabel;

  /// No description provided for @adminSubmissionsListNoSubmissions.
  ///
  /// In bn, this message translates to:
  /// **'কোনো আবেদন পাওয়া যায়নি'**
  String get adminSubmissionsListNoSubmissions;

  /// No description provided for @adminSubmissionsListSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন সদস্যপদের আবেদন পর্যালোচনা করুন'**
  String get adminSubmissionsListSubtitle;

  /// No description provided for @adminSubmissionsListTableHeadersDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get adminSubmissionsListTableHeadersDate;

  /// No description provided for @adminSubmissionsListTableHeadersMobile.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get adminSubmissionsListTableHeadersMobile;

  /// No description provided for @adminSubmissionsListTableHeadersName.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get adminSubmissionsListTableHeadersName;

  /// No description provided for @adminSubmissionsListTableHeadersReference.
  ///
  /// In bn, this message translates to:
  /// **'রেফারেন্স'**
  String get adminSubmissionsListTableHeadersReference;

  /// No description provided for @adminSubmissionsListTableHeadersStatus.
  ///
  /// In bn, this message translates to:
  /// **'স্ট্যাটাস'**
  String get adminSubmissionsListTableHeadersStatus;

  /// No description provided for @adminSubmissionsListTitle.
  ///
  /// In bn, this message translates to:
  /// **'আবেদনসমূহ'**
  String get adminSubmissionsListTitle;

  /// No description provided for @authForgotPasswordBackToLogin.
  ///
  /// In bn, this message translates to:
  /// **'লগইনে ফিরে যান'**
  String get authForgotPasswordBackToLogin;

  /// No description provided for @authForgotPasswordErrorsRequestFailed.
  ///
  /// In bn, this message translates to:
  /// **'রিসেট অনুরোধ পাঠানো যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।'**
  String get authForgotPasswordErrorsRequestFailed;

  /// No description provided for @authForgotPasswordIdentifierLabel.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য আইডি / ইউজারনেম / ইমেইল'**
  String get authForgotPasswordIdentifierLabel;

  /// No description provided for @authForgotPasswordIdentifierRequiredError.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য আইডি / ইউজারনেম / ইমেইল প্রয়োজন'**
  String get authForgotPasswordIdentifierRequiredError;

  /// No description provided for @authForgotPasswordSendingButton.
  ///
  /// In bn, this message translates to:
  /// **'পাঠানো হচ্ছে...'**
  String get authForgotPasswordSendingButton;

  /// No description provided for @authForgotPasswordSentMessage.
  ///
  /// In bn, this message translates to:
  /// **'এই তথ্যের সাথে কোনো অ্যাকাউন্ট থাকলে পাসওয়ার্ড রিসেট লিংক নিবন্ধিত ইমেইলে পাঠানো হয়েছে। অনুগ্রহ করে আপনার ইনবক্স (এবং স্প্যাম ফোল্ডার) দেখুন। লিংকটি ৩০ মিনিট পর্যন্ত কার্যকর থাকবে।'**
  String get authForgotPasswordSentMessage;

  /// No description provided for @authForgotPasswordSubmitButton.
  ///
  /// In bn, this message translates to:
  /// **'রিসেট লিংক পাঠান'**
  String get authForgotPasswordSubmitButton;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার সদস্য আইডি, ইউজারনেম বা নিবন্ধিত ইমেইল লিখুন — আমরা পাসওয়ার্ড রিসেট লিংক ইমেইলে পাঠিয়ে দেব।'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড ভুলে গেছেন'**
  String get authForgotPasswordTitle;

  /// No description provided for @authLoginBackToHome.
  ///
  /// In bn, this message translates to:
  /// **'হোমে ফিরুন'**
  String get authLoginBackToHome;

  /// No description provided for @authLoginForgotPasswordLink.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড ভুলে গেছেন?'**
  String get authLoginForgotPasswordLink;

  /// No description provided for @authLoginHidePassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড লুকান'**
  String get authLoginHidePassword;

  /// No description provided for @authLoginIdentifierLabel.
  ///
  /// In bn, this message translates to:
  /// **'ইউজারনেম / ইমেইল / সদস্য আইডি'**
  String get authLoginIdentifierLabel;

  /// No description provided for @authLoginIdentifierRequiredError.
  ///
  /// In bn, this message translates to:
  /// **'ইউজারনেম / ইমেইল / সদস্য আইডি আবশ্যক'**
  String get authLoginIdentifierRequiredError;

  /// No description provided for @authLoginLoggingInButton.
  ///
  /// In bn, this message translates to:
  /// **'লগইন হচ্ছে...'**
  String get authLoginLoggingInButton;

  /// No description provided for @authLoginLoginFailedError.
  ///
  /// In bn, this message translates to:
  /// **'লগইন ব্যর্থ হয়েছে। তথ্য সঠিক নয়।'**
  String get authLoginLoginFailedError;

  /// No description provided for @authLoginLogoAlt.
  ///
  /// In bn, this message translates to:
  /// **'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি লোগো'**
  String get authLoginLogoAlt;

  /// No description provided for @authLoginNotAMemberYet.
  ///
  /// In bn, this message translates to:
  /// **'এখনো সদস্য নন?'**
  String get authLoginNotAMemberYet;

  /// No description provided for @authLoginPasswordLabel.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড'**
  String get authLoginPasswordLabel;

  /// No description provided for @authLoginPasswordRequiredError.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড আবশ্যক'**
  String get authLoginPasswordRequiredError;

  /// No description provided for @authLoginRegisterButton.
  ///
  /// In bn, this message translates to:
  /// **'নতুন সদস্য নিবন্ধন করুন'**
  String get authLoginRegisterButton;

  /// No description provided for @authLoginShowPassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড দেখুন'**
  String get authLoginShowPassword;

  /// No description provided for @authLoginSubmitButton.
  ///
  /// In bn, this message translates to:
  /// **'প্রবেশ করুন'**
  String get authLoginSubmitButton;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য অথবা প্রশাসক হিসেবে প্রবেশ করুন'**
  String get authLoginSubtitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In bn, this message translates to:
  /// **'লগইন করুন'**
  String get authLoginTitle;

  /// No description provided for @authResetPasswordConfirmPasswordLabel.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পাসওয়ার্ড নিশ্চিত করুন'**
  String get authResetPasswordConfirmPasswordLabel;

  /// No description provided for @authResetPasswordErrorsResetFailed.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড রিসেট করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।'**
  String get authResetPasswordErrorsResetFailed;

  /// No description provided for @authResetPasswordInvalidTokenError.
  ///
  /// In bn, this message translates to:
  /// **'এই রিসেট লিংকটি সঠিক নয় বা মেয়াদ শেষ হয়ে গেছে। অনুগ্রহ করে নতুন লিংকের অনুরোধ করুন।'**
  String get authResetPasswordInvalidTokenError;

  /// No description provided for @authResetPasswordMismatchError.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড দুটি মিলছে না'**
  String get authResetPasswordMismatchError;

  /// No description provided for @authResetPasswordMissingTokenError.
  ///
  /// In bn, this message translates to:
  /// **'এই রিসেট লিংকটি সঠিক নয়। অনুগ্রহ করে নতুন পাসওয়ার্ড রিসেট ইমেইলের অনুরোধ করুন।'**
  String get authResetPasswordMissingTokenError;

  /// No description provided for @authResetPasswordNewPasswordLabel.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পাসওয়ার্ড'**
  String get authResetPasswordNewPasswordLabel;

  /// No description provided for @authResetPasswordPasswordHint.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে এবং এতে একটি সংখ্যা থাকতে হবে।'**
  String get authResetPasswordPasswordHint;

  /// No description provided for @authResetPasswordPasswordRequiredError.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড প্রয়োজন'**
  String get authResetPasswordPasswordRequiredError;

  /// No description provided for @authResetPasswordResettingButton.
  ///
  /// In bn, this message translates to:
  /// **'রিসেট হচ্ছে...'**
  String get authResetPasswordResettingButton;

  /// No description provided for @authResetPasswordSubmitButton.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড রিসেট করুন'**
  String get authResetPasswordSubmitButton;

  /// No description provided for @authResetPasswordSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার অ্যাকাউন্টের জন্য একটি শক্তিশালী নতুন পাসওয়ার্ড দিন।'**
  String get authResetPasswordSubtitle;

  /// No description provided for @authResetPasswordSuccessMessage.
  ///
  /// In bn, this message translates to:
  /// **'আপনার পাসওয়ার্ড সফলভাবে রিসেট হয়েছে। এখন নতুন পাসওয়ার্ড দিয়ে লগইন করতে পারেন।'**
  String get authResetPasswordSuccessMessage;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পাসওয়ার্ড নির্ধারণ করুন'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordWeakPasswordError.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে এবং এতে একটি সংখ্যা থাকতে হবে।'**
  String get authResetPasswordWeakPasswordError;

  /// No description provided for @brandName.
  ///
  /// In bn, this message translates to:
  /// **'উত্তর কাউন্দিয়া সোসাইটি'**
  String get brandName;

  /// No description provided for @brandOrg.
  ///
  /// In bn, this message translates to:
  /// **'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি'**
  String get brandOrg;

  /// No description provided for @commonCancel.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করুন'**
  String get commonClose;

  /// No description provided for @commonConfirmModalCancelButton.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get commonConfirmModalCancelButton;

  /// No description provided for @commonConfirmModalConfirmButton.
  ///
  /// In bn, this message translates to:
  /// **'নিশ্চিত করুন'**
  String get commonConfirmModalConfirmButton;

  /// No description provided for @commonDelete.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In bn, this message translates to:
  /// **'সম্পাদনা'**
  String get commonEdit;

  /// No description provided for @commonLoading.
  ///
  /// In bn, this message translates to:
  /// **'লোড হচ্ছে...'**
  String get commonLoading;

  /// No description provided for @commonMonthsApril.
  ///
  /// In bn, this message translates to:
  /// **'এপ্রিল'**
  String get commonMonthsApril;

  /// No description provided for @commonMonthsAugust.
  ///
  /// In bn, this message translates to:
  /// **'আগস্ট'**
  String get commonMonthsAugust;

  /// No description provided for @commonMonthsDecember.
  ///
  /// In bn, this message translates to:
  /// **'ডিসেম্বর'**
  String get commonMonthsDecember;

  /// No description provided for @commonMonthsFebruary.
  ///
  /// In bn, this message translates to:
  /// **'ফেব্রুয়ারি'**
  String get commonMonthsFebruary;

  /// No description provided for @commonMonthsJanuary.
  ///
  /// In bn, this message translates to:
  /// **'জানুয়ারি'**
  String get commonMonthsJanuary;

  /// No description provided for @commonMonthsJuly.
  ///
  /// In bn, this message translates to:
  /// **'জুলাই'**
  String get commonMonthsJuly;

  /// No description provided for @commonMonthsJune.
  ///
  /// In bn, this message translates to:
  /// **'জুন'**
  String get commonMonthsJune;

  /// No description provided for @commonMonthsMarch.
  ///
  /// In bn, this message translates to:
  /// **'মার্চ'**
  String get commonMonthsMarch;

  /// No description provided for @commonMonthsMay.
  ///
  /// In bn, this message translates to:
  /// **'মে'**
  String get commonMonthsMay;

  /// No description provided for @commonMonthsNovember.
  ///
  /// In bn, this message translates to:
  /// **'নভেম্বর'**
  String get commonMonthsNovember;

  /// No description provided for @commonMonthsOctober.
  ///
  /// In bn, this message translates to:
  /// **'অক্টোবর'**
  String get commonMonthsOctober;

  /// No description provided for @commonMonthsSeptember.
  ///
  /// In bn, this message translates to:
  /// **'সেপ্টেম্বর'**
  String get commonMonthsSeptember;

  /// No description provided for @commonRetry.
  ///
  /// In bn, this message translates to:
  /// **'আবার চেষ্টা করুন'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষণ'**
  String get commonSave;

  /// No description provided for @commonSelect.
  ///
  /// In bn, this message translates to:
  /// **'নির্বাচন করুন'**
  String get commonSelect;

  /// No description provided for @commonSwitchToBangla.
  ///
  /// In bn, this message translates to:
  /// **'বাংলায় দেখুন'**
  String get commonSwitchToBangla;

  /// No description provided for @commonSwitchToEnglish.
  ///
  /// In bn, this message translates to:
  /// **'Switch to English'**
  String get commonSwitchToEnglish;

  /// No description provided for @eventsBackToList.
  ///
  /// In bn, this message translates to:
  /// **'সব অনুষ্ঠান'**
  String get eventsBackToList;

  /// No description provided for @eventsDetailEndsAt.
  ///
  /// In bn, this message translates to:
  /// **'শেষ'**
  String get eventsDetailEndsAt;

  /// No description provided for @eventsDetailLocation.
  ///
  /// In bn, this message translates to:
  /// **'স্থান'**
  String get eventsDetailLocation;

  /// No description provided for @eventsDetailStartsAt.
  ///
  /// In bn, this message translates to:
  /// **'শুরু'**
  String get eventsDetailStartsAt;

  /// No description provided for @eventsErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'অনুষ্ঠান লোড করা যায়নি।'**
  String get eventsErrorsLoadFailed;

  /// No description provided for @eventsNoPast.
  ///
  /// In bn, this message translates to:
  /// **'কোনো অতীত অনুষ্ঠান নেই।'**
  String get eventsNoPast;

  /// No description provided for @eventsNoUpcoming.
  ///
  /// In bn, this message translates to:
  /// **'কোনো আসন্ন অনুষ্ঠান নেই।'**
  String get eventsNoUpcoming;

  /// No description provided for @eventsNotFound.
  ///
  /// In bn, this message translates to:
  /// **'এই অনুষ্ঠানটি আর পাওয়া যাচ্ছে না।'**
  String get eventsNotFound;

  /// No description provided for @eventsPast.
  ///
  /// In bn, this message translates to:
  /// **'অতীত'**
  String get eventsPast;

  /// No description provided for @eventsSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'পরিষদের সভা, কর্মসূচি ও অনুষ্ঠান'**
  String get eventsSubtitle;

  /// No description provided for @eventsTitle.
  ///
  /// In bn, this message translates to:
  /// **'অনুষ্ঠান'**
  String get eventsTitle;

  /// No description provided for @eventsUpcoming.
  ///
  /// In bn, this message translates to:
  /// **'আসন্ন'**
  String get eventsUpcoming;

  /// No description provided for @footerPrototypeNotice.
  ///
  /// In bn, this message translates to:
  /// **'© ২০২৬ উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি। নির্মাণে: Anshin Tech।'**
  String get footerPrototypeNotice;

  /// No description provided for @footerPublicNotice.
  ///
  /// In bn, this message translates to:
  /// **'এটি একটি সদস্য ব্যবস্থাপনা পোর্টাল। © ২০২৬ উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি। নির্মাণে: Anshin Tech।'**
  String get footerPublicNotice;

  /// No description provided for @forbiddenBackToDashboard.
  ///
  /// In bn, this message translates to:
  /// **'ড্যাশবোর্ডে ফিরে যান'**
  String get forbiddenBackToDashboard;

  /// No description provided for @forbiddenMessage.
  ///
  /// In bn, this message translates to:
  /// **'এই পাতাটি দেখার অনুমতি আপনার নেই।'**
  String get forbiddenMessage;

  /// No description provided for @forbiddenTitle.
  ///
  /// In bn, this message translates to:
  /// **'প্রবেশাধিকার নেই'**
  String get forbiddenTitle;

  /// No description provided for @homeHeroApplicationReviewLabel.
  ///
  /// In bn, this message translates to:
  /// **'পর্যালোচনাধীন আবেদন'**
  String get homeHeroApplicationReviewLabel;

  /// No description provided for @homeHeroApplyButton.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যপদের জন্য আবেদন করুন'**
  String get homeHeroApplyButton;

  /// No description provided for @homeHeroEyebrow.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য ব্যবস্থাপনা পোর্টাল'**
  String get homeHeroEyebrow;

  /// No description provided for @homeHeroLoginButton.
  ///
  /// In bn, this message translates to:
  /// **'ইতিমধ্যে সদস্য? লগইন করুন'**
  String get homeHeroLoginButton;

  /// No description provided for @homeHeroMemberIdLabel.
  ///
  /// In bn, this message translates to:
  /// **'নিবন্ধিত সদস্য'**
  String get homeHeroMemberIdLabel;

  /// No description provided for @homeHeroMonthlySubscriptionLabel.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক চাঁদা'**
  String get homeHeroMonthlySubscriptionLabel;

  /// No description provided for @homeHeroStatCardTitle.
  ///
  /// In bn, this message translates to:
  /// **'এই মুহূর্তে'**
  String get homeHeroStatCardTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যপদের আবেদন থেকে শুরু করে মাসিক চাঁদা পরিশোধ পর্যন্ত — পুরো প্রক্রিয়া এখন অনলাইনে। কাগজে আবেদন করার ঝামেলা নেই, অফিসে বারবার যাওয়ার প্রয়োজন নেই।'**
  String get homeHeroSubtitle;

  /// No description provided for @homeHeroTitle.
  ///
  /// In bn, this message translates to:
  /// **'উত্তর কাউন্দিয়ার<br />জমির মালিকদের কল্যাণ পরিষদ'**
  String get homeHeroTitle;

  /// No description provided for @homeStepsApplyDesc.
  ///
  /// In bn, this message translates to:
  /// **'ব্যক্তিগত তথ্য, ঠিকানা, জমির বিবরণ ও পেমেন্ট তথ্যসহ ধাপে ধাপে ফর্ম পূরণ করুন।'**
  String get homeStepsApplyDesc;

  /// No description provided for @homeStepsApplyTitle.
  ///
  /// In bn, this message translates to:
  /// **'আবেদন করুন'**
  String get homeStepsApplyTitle;

  /// No description provided for @homeStepsMemberIdDesc.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদনের পর স্বয়ংক্রিয়ভাবে সদস্য আইডি তৈরি হয় এবং লগইন তথ্য ইস্যু করা হয়।'**
  String get homeStepsMemberIdDesc;

  /// No description provided for @homeStepsMemberIdTitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য আইডি ও লগইন'**
  String get homeStepsMemberIdTitle;

  /// No description provided for @homeStepsReviewDesc.
  ///
  /// In bn, this message translates to:
  /// **'কার্যনির্বাহী কমিটি ও প্রশাসন প্রতিটি আবেদন যাচাই করে অনুমোদন বা প্রত্যাখ্যান করেন।'**
  String get homeStepsReviewDesc;

  /// No description provided for @homeStepsReviewTitle.
  ///
  /// In bn, this message translates to:
  /// **'কমিটির পর্যালোচনা'**
  String get homeStepsReviewTitle;

  /// No description provided for @idcardAddress.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা'**
  String get idcardAddress;

  /// No description provided for @idcardAuthority.
  ///
  /// In bn, this message translates to:
  /// **'কর্তৃপক্ষ'**
  String get idcardAuthority;

  /// No description provided for @idcardBack.
  ///
  /// In bn, this message translates to:
  /// **'পিছনের পিঠ'**
  String get idcardBack;

  /// No description provided for @idcardBackTitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য পরিচয়পত্র'**
  String get idcardBackTitle;

  /// No description provided for @idcardButton.
  ///
  /// In bn, this message translates to:
  /// **'আইডি কার্ড'**
  String get idcardButton;

  /// No description provided for @idcardCardTitleEn.
  ///
  /// In bn, this message translates to:
  /// **'Member ID Card'**
  String get idcardCardTitleEn;

  /// No description provided for @idcardDob.
  ///
  /// In bn, this message translates to:
  /// **'জন্ম তারিখ'**
  String get idcardDob;

  /// No description provided for @idcardDownload.
  ///
  /// In bn, this message translates to:
  /// **'কার্ড ডাউনলোড (PNG)'**
  String get idcardDownload;

  /// No description provided for @idcardDownloadError.
  ///
  /// In bn, this message translates to:
  /// **'কার্ড তৈরি করা যায়নি। আবার চেষ্টা করুন।'**
  String get idcardDownloadError;

  /// No description provided for @idcardEmergency.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগ'**
  String get idcardEmergency;

  /// No description provided for @idcardFather.
  ///
  /// In bn, this message translates to:
  /// **'পিতা/স্বামী'**
  String get idcardFather;

  /// No description provided for @idcardFooter.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য পরিচয়পত্র · ২০২৬'**
  String get idcardFooter;

  /// No description provided for @idcardFront.
  ///
  /// In bn, this message translates to:
  /// **'সামনের পিঠ'**
  String get idcardFront;

  /// No description provided for @idcardIssuedOn.
  ///
  /// In bn, this message translates to:
  /// **'ইস্যুর তারিখ'**
  String get idcardIssuedOn;

  /// No description provided for @idcardLoadError.
  ///
  /// In bn, this message translates to:
  /// **'প্রোফাইল তথ্য লোড করা যায়নি।'**
  String get idcardLoadError;

  /// No description provided for @idcardMobile.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get idcardMobile;

  /// No description provided for @idcardNid.
  ///
  /// In bn, this message translates to:
  /// **'এনআইডি'**
  String get idcardNid;

  /// No description provided for @idcardPreparing.
  ///
  /// In bn, this message translates to:
  /// **'তৈরি হচ্ছে...'**
  String get idcardPreparing;

  /// No description provided for @idcardReceiptNo.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ নম্বর'**
  String get idcardReceiptNo;

  /// No description provided for @idcardSectionContact.
  ///
  /// In bn, this message translates to:
  /// **'যোগাযোগ'**
  String get idcardSectionContact;

  /// No description provided for @idcardSectionMembership.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যপদ'**
  String get idcardSectionMembership;

  /// No description provided for @idcardSectionPersonal.
  ///
  /// In bn, this message translates to:
  /// **'ব্যক্তিগত তথ্য'**
  String get idcardSectionPersonal;

  /// No description provided for @idcardSocietyName.
  ///
  /// In bn, this message translates to:
  /// **'উত্তর কাউন্দিয়া সোসাইটি'**
  String get idcardSocietyName;

  /// No description provided for @idcardSocietyOrg.
  ///
  /// In bn, this message translates to:
  /// **'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি'**
  String get idcardSocietyOrg;

  /// No description provided for @idcardStatusApplicant.
  ///
  /// In bn, this message translates to:
  /// **'আবেদনকারী'**
  String get idcardStatusApplicant;

  /// No description provided for @idcardStatusApproved.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get idcardStatusApproved;

  /// No description provided for @idcardStatusPending.
  ///
  /// In bn, this message translates to:
  /// **'অপেক্ষমাণ'**
  String get idcardStatusPending;

  /// No description provided for @idcardStatusRejected.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get idcardStatusRejected;

  /// No description provided for @idcardTerms.
  ///
  /// In bn, this message translates to:
  /// **'এই কার্ডটি উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটির সম্পত্তি। কর্তৃপক্ষের অনুরোধে কার্ডটি প্রদর্শন করতে হবে এবং সদস্যপদ শেষ হলে ফেরত দিতে হবে। কার্ডটি হারিয়ে গেলে দ্রুত কর্তৃপক্ষকে জানান।'**
  String get idcardTerms;

  /// No description provided for @idcardTitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য পরিচয়পত্র'**
  String get idcardTitle;

  /// No description provided for @idcardVerify.
  ///
  /// In bn, this message translates to:
  /// **'কিউআর কোড দিয়ে যাচাই করা যায়'**
  String get idcardVerify;

  /// No description provided for @memberChangePasswordChangeFailedError.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড পরিবর্তন ব্যর্থ হয়েছে।'**
  String get memberChangePasswordChangeFailedError;

  /// No description provided for @memberChangePasswordConfirmPasswordLabel.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পাসওয়ার্ড নিশ্চিত করুন'**
  String get memberChangePasswordConfirmPasswordLabel;

  /// No description provided for @memberChangePasswordCurrentPasswordLabel.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান পাসওয়ার্ড'**
  String get memberChangePasswordCurrentPasswordLabel;

  /// No description provided for @memberChangePasswordCurrentPasswordRequiredError.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান পাসওয়ার্ড দিন।'**
  String get memberChangePasswordCurrentPasswordRequiredError;

  /// No description provided for @memberChangePasswordNewPasswordLabel.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পাসওয়ার্ড'**
  String get memberChangePasswordNewPasswordLabel;

  /// No description provided for @memberChangePasswordPasswordMismatchError.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড মিলছে না।'**
  String get memberChangePasswordPasswordMismatchError;

  /// No description provided for @memberChangePasswordPasswordPolicyError.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে এবং একটি সংখ্যা থাকতে হবে।'**
  String get memberChangePasswordPasswordPolicyError;

  /// No description provided for @memberChangePasswordSameAsCurrentError.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পাসওয়ার্ড বর্তমান পাসওয়ার্ড থেকে আলাদা হতে হবে।'**
  String get memberChangePasswordSameAsCurrentError;

  /// No description provided for @memberChangePasswordSaveButton.
  ///
  /// In bn, this message translates to:
  /// **'পরিবর্তন সংরক্ষণ করুন'**
  String get memberChangePasswordSaveButton;

  /// No description provided for @memberChangePasswordSavingButton.
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষণ হচ্ছে...'**
  String get memberChangePasswordSavingButton;

  /// No description provided for @memberChangePasswordSuccessMessage.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড সফলভাবে পরিবর্তন হয়েছে।'**
  String get memberChangePasswordSuccessMessage;

  /// No description provided for @memberChangePasswordTitle.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড পরিবর্তন'**
  String get memberChangePasswordTitle;

  /// No description provided for @memberCostSharesEmptyHint.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের মধ্যে ভাগ করা খরচ এখানে দেখা যাবে।'**
  String get memberCostSharesEmptyHint;

  /// No description provided for @memberCostSharesEmptyState.
  ///
  /// In bn, this message translates to:
  /// **'আপনার কোনো বকেয়া নেই'**
  String get memberCostSharesEmptyState;

  /// No description provided for @memberCostSharesLoadError.
  ///
  /// In bn, this message translates to:
  /// **'আপনার খরচের ভাগ লোড করা যায়নি। আবার চেষ্টা করুন।'**
  String get memberCostSharesLoadError;

  /// No description provided for @memberCostSharesStatusPaid.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত'**
  String get memberCostSharesStatusPaid;

  /// No description provided for @memberCostSharesStatusPartial.
  ///
  /// In bn, this message translates to:
  /// **'আংশিক'**
  String get memberCostSharesStatusPartial;

  /// No description provided for @memberCostSharesStatusUnpaid.
  ///
  /// In bn, this message translates to:
  /// **'অনাদায়ী'**
  String get memberCostSharesStatusUnpaid;

  /// No description provided for @memberCostSharesSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সোসাইটির যেসব খরচ আপনার অ্যাকাউন্টে ভাগ হয়েছে'**
  String get memberCostSharesSubtitle;

  /// No description provided for @memberCostSharesTableCost.
  ///
  /// In bn, this message translates to:
  /// **'খরচ'**
  String get memberCostSharesTableCost;

  /// No description provided for @memberCostSharesTableDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get memberCostSharesTableDate;

  /// No description provided for @memberCostSharesTableDue.
  ///
  /// In bn, this message translates to:
  /// **'দেয়'**
  String get memberCostSharesTableDue;

  /// No description provided for @memberCostSharesTablePaid.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত'**
  String get memberCostSharesTablePaid;

  /// No description provided for @memberCostSharesTableStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get memberCostSharesTableStatus;

  /// No description provided for @memberCostSharesTitle.
  ///
  /// In bn, this message translates to:
  /// **'খরচের ভাগ'**
  String get memberCostSharesTitle;

  /// No description provided for @memberCostSharesTotalOutstanding.
  ///
  /// In bn, this message translates to:
  /// **'মোট বকেয়া'**
  String get memberCostSharesTotalOutstanding;

  /// No description provided for @memberDashboardDueMonthsLabel.
  ///
  /// In bn, this message translates to:
  /// **'বকেয়া মাস'**
  String get memberDashboardDueMonthsLabel;

  /// No description provided for @memberDashboardLoadError.
  ///
  /// In bn, this message translates to:
  /// **'তথ্য লোড করা যায়নি।'**
  String get memberDashboardLoadError;

  /// No description provided for @memberDashboardMemberIdLabel.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য আইডি'**
  String get memberDashboardMemberIdLabel;

  /// No description provided for @memberDashboardPaidMonthsLabel.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত মাস'**
  String get memberDashboardPaidMonthsLabel;

  /// No description provided for @memberDashboardRecentStatusTitle.
  ///
  /// In bn, this message translates to:
  /// **'সাম্প্রতিক চাঁদার অবস্থা'**
  String get memberDashboardRecentStatusTitle;

  /// No description provided for @memberDashboardStatusDue.
  ///
  /// In bn, this message translates to:
  /// **'বকেয়া'**
  String get memberDashboardStatusDue;

  /// No description provided for @memberDashboardStatusPaid.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত'**
  String get memberDashboardStatusPaid;

  /// No description provided for @memberFundTransparencyChartsEmpty.
  ///
  /// In bn, this message translates to:
  /// **'গ্রাফ দেখানোর মতো পর্যাপ্ত তথ্য এখনো নেই।'**
  String get memberFundTransparencyChartsEmpty;

  /// No description provided for @memberFundTransparencyChartsExpenseDonut.
  ///
  /// In bn, this message translates to:
  /// **'ব্যয়ের খাতভিত্তিক চিত্র'**
  String get memberFundTransparencyChartsExpenseDonut;

  /// No description provided for @memberFundTransparencyChartsMonthly.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক'**
  String get memberFundTransparencyChartsMonthly;

  /// No description provided for @memberFundTransparencyChartsTrend.
  ///
  /// In bn, this message translates to:
  /// **'আয়-ব্যয়ের প্রবণতা'**
  String get memberFundTransparencyChartsTrend;

  /// No description provided for @memberFundTransparencyChartsYearly.
  ///
  /// In bn, this message translates to:
  /// **'বার্ষিক'**
  String get memberFundTransparencyChartsYearly;

  /// No description provided for @memberFundTransparencyCurrentBalance.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ব্যালেন্স'**
  String get memberFundTransparencyCurrentBalance;

  /// No description provided for @memberFundTransparencyDownloadPdf.
  ///
  /// In bn, this message translates to:
  /// **'রিপোর্ট ডাউনলোড (PDF)'**
  String get memberFundTransparencyDownloadPdf;

  /// No description provided for @memberFundTransparencyEmptyHint.
  ///
  /// In bn, this message translates to:
  /// **'কমিটি লেনদেন যোগ করে অনুমোদন করলে এখানে সোসাইটির সব আয়-ব্যয় দেখা যাবে।'**
  String get memberFundTransparencyEmptyHint;

  /// No description provided for @memberFundTransparencyEmptyTitle.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো লেনদেন প্রকাশিত হয়নি'**
  String get memberFundTransparencyEmptyTitle;

  /// No description provided for @memberFundTransparencyErrorsCustomRange.
  ///
  /// In bn, this message translates to:
  /// **'কাস্টম রেঞ্জের জন্য শুরু ও শেষ তারিখ দুটোই দিন (শুরু তারিখ আগে হতে হবে)।'**
  String get memberFundTransparencyErrorsCustomRange;

  /// No description provided for @memberFundTransparencyErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।'**
  String get memberFundTransparencyErrorsLoadFailed;

  /// No description provided for @memberFundTransparencyErrorsPdfFailed.
  ///
  /// In bn, this message translates to:
  /// **'রিপোর্ট তৈরি করা যায়নি। কিছুক্ষণ পর আবার চেষ্টা করুন।'**
  String get memberFundTransparencyErrorsPdfFailed;

  /// No description provided for @memberFundTransparencyExpenseBreakdown.
  ///
  /// In bn, this message translates to:
  /// **'কোন কোন খাতে কত টাকা খরচ হয়েছে'**
  String get memberFundTransparencyExpenseBreakdown;

  /// No description provided for @memberFundTransparencyExpenseBreakdownEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই সময়কালে কোনো ব্যয় নেই।'**
  String get memberFundTransparencyExpenseBreakdownEmpty;

  /// No description provided for @memberFundTransparencyFiltersAllCategories.
  ///
  /// In bn, this message translates to:
  /// **'সব খাত'**
  String get memberFundTransparencyFiltersAllCategories;

  /// No description provided for @memberFundTransparencyFiltersAllTypes.
  ///
  /// In bn, this message translates to:
  /// **'সব ধরন'**
  String get memberFundTransparencyFiltersAllTypes;

  /// No description provided for @memberFundTransparencyFiltersAmountRange.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ রেঞ্জ (৳)'**
  String get memberFundTransparencyFiltersAmountRange;

  /// No description provided for @memberFundTransparencyFiltersApprovedBy.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদনকারী'**
  String get memberFundTransparencyFiltersApprovedBy;

  /// No description provided for @memberFundTransparencyFiltersCategory.
  ///
  /// In bn, this message translates to:
  /// **'খাত'**
  String get memberFundTransparencyFiltersCategory;

  /// No description provided for @memberFundTransparencyFiltersClearAll.
  ///
  /// In bn, this message translates to:
  /// **'✕ সব মুছুন'**
  String get memberFundTransparencyFiltersClearAll;

  /// No description provided for @memberFundTransparencyFiltersDateRange.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ রেঞ্জ'**
  String get memberFundTransparencyFiltersDateRange;

  /// No description provided for @memberFundTransparencyFiltersMax.
  ///
  /// In bn, this message translates to:
  /// **'সর্বোচ্চ'**
  String get memberFundTransparencyFiltersMax;

  /// No description provided for @memberFundTransparencyFiltersMin.
  ///
  /// In bn, this message translates to:
  /// **'সর্বনিম্ন'**
  String get memberFundTransparencyFiltersMin;

  /// No description provided for @memberFundTransparencyFiltersReference.
  ///
  /// In bn, this message translates to:
  /// **'রেফারেন্স নম্বর'**
  String get memberFundTransparencyFiltersReference;

  /// No description provided for @memberFundTransparencyFiltersReset.
  ///
  /// In bn, this message translates to:
  /// **'রিসেট'**
  String get memberFundTransparencyFiltersReset;

  /// No description provided for @memberFundTransparencyFiltersSearch.
  ///
  /// In bn, this message translates to:
  /// **'অনুসন্ধান'**
  String get memberFundTransparencyFiltersSearch;

  /// No description provided for @memberFundTransparencyFiltersSearchPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'বিবরণ বা রেফারেন্স খুঁজুন…'**
  String get memberFundTransparencyFiltersSearchPlaceholder;

  /// No description provided for @memberFundTransparencyFiltersType.
  ///
  /// In bn, this message translates to:
  /// **'ধরন'**
  String get memberFundTransparencyFiltersType;

  /// No description provided for @memberFundTransparencyFlagsSpike.
  ///
  /// In bn, this message translates to:
  /// **'এই সময়ে {category} খরচ গত সময়ের চেয়ে {pct} বেশি'**
  String memberFundTransparencyFlagsSpike(Object category, Object pct);

  /// No description provided for @memberFundTransparencyFlagsTopCategories.
  ///
  /// In bn, this message translates to:
  /// **'সবচেয়ে বেশি খরচ: {categories}'**
  String memberFundTransparencyFlagsTopCategories(Object categories);

  /// No description provided for @memberFundTransparencyIncomeBreakdown.
  ///
  /// In bn, this message translates to:
  /// **'কোন কোন খাত থেকে কত টাকা কালেকশন হয়েছে'**
  String get memberFundTransparencyIncomeBreakdown;

  /// No description provided for @memberFundTransparencyIncomeBreakdownEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই সময়কালে কোনো আয় নেই।'**
  String get memberFundTransparencyIncomeBreakdownEmpty;

  /// No description provided for @memberFundTransparencyLastUpdated.
  ///
  /// In bn, this message translates to:
  /// **'সর্বশেষ আপডেট'**
  String get memberFundTransparencyLastUpdated;

  /// No description provided for @memberFundTransparencyLedgerAmount.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get memberFundTransparencyLedgerAmount;

  /// No description provided for @memberFundTransparencyLedgerApprovedBy.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদনকারী'**
  String get memberFundTransparencyLedgerApprovedBy;

  /// No description provided for @memberFundTransparencyLedgerCategory.
  ///
  /// In bn, this message translates to:
  /// **'খাত'**
  String get memberFundTransparencyLedgerCategory;

  /// No description provided for @memberFundTransparencyLedgerCount.
  ///
  /// In bn, this message translates to:
  /// **'মোট {count}টি লেনদেন'**
  String memberFundTransparencyLedgerCount(Object count);

  /// No description provided for @memberFundTransparencyLedgerDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get memberFundTransparencyLedgerDate;

  /// No description provided for @memberFundTransparencyLedgerDescription.
  ///
  /// In bn, this message translates to:
  /// **'বিবরণ'**
  String get memberFundTransparencyLedgerDescription;

  /// No description provided for @memberFundTransparencyLedgerEmpty.
  ///
  /// In bn, this message translates to:
  /// **'কোনো লেনদেন পাওয়া যায়নি'**
  String get memberFundTransparencyLedgerEmpty;

  /// No description provided for @memberFundTransparencyLedgerEmptyHint.
  ///
  /// In bn, this message translates to:
  /// **'ফিল্টার পরিবর্তন করে আবার দেখুন।'**
  String get memberFundTransparencyLedgerEmptyHint;

  /// No description provided for @memberFundTransparencyLedgerPage.
  ///
  /// In bn, this message translates to:
  /// **'পৃষ্ঠা {page} / {total}'**
  String memberFundTransparencyLedgerPage(Object page, Object total);

  /// No description provided for @memberFundTransparencyLedgerReference.
  ///
  /// In bn, this message translates to:
  /// **'রেফারেন্স'**
  String get memberFundTransparencyLedgerReference;

  /// No description provided for @memberFundTransparencyLedgerReversalOf.
  ///
  /// In bn, this message translates to:
  /// **'রিভার্সাল হয়েছে লেনদেন'**
  String get memberFundTransparencyLedgerReversalOf;

  /// No description provided for @memberFundTransparencyLedgerType.
  ///
  /// In bn, this message translates to:
  /// **'ধরন'**
  String get memberFundTransparencyLedgerType;

  /// No description provided for @memberFundTransparencyLedgerViewAttachment.
  ///
  /// In bn, this message translates to:
  /// **'সংযুক্তি দেখুন'**
  String get memberFundTransparencyLedgerViewAttachment;

  /// No description provided for @memberFundTransparencyNetSaved.
  ///
  /// In bn, this message translates to:
  /// **'নিট জমা'**
  String get memberFundTransparencyNetSaved;

  /// No description provided for @memberFundTransparencyPeriodAll.
  ///
  /// In bn, this message translates to:
  /// **'সর্বমোট'**
  String get memberFundTransparencyPeriodAll;

  /// No description provided for @memberFundTransparencyPeriodApply.
  ///
  /// In bn, this message translates to:
  /// **'দেখান'**
  String get memberFundTransparencyPeriodApply;

  /// No description provided for @memberFundTransparencyPeriodCustom.
  ///
  /// In bn, this message translates to:
  /// **'কাস্টম রেঞ্জ'**
  String get memberFundTransparencyPeriodCustom;

  /// No description provided for @memberFundTransparencyPeriodMonth.
  ///
  /// In bn, this message translates to:
  /// **'এই মাস'**
  String get memberFundTransparencyPeriodMonth;

  /// No description provided for @memberFundTransparencyPeriodYear.
  ///
  /// In bn, this message translates to:
  /// **'এই বছর'**
  String get memberFundTransparencyPeriodYear;

  /// No description provided for @memberFundTransparencyPreviewMissing.
  ///
  /// In bn, this message translates to:
  /// **'সংযুক্তিটি পাওয়া যাচ্ছে না। কমিটিকে জানান।'**
  String get memberFundTransparencyPreviewMissing;

  /// No description provided for @memberFundTransparencyPreviewTitle.
  ///
  /// In bn, this message translates to:
  /// **'সংযুক্তি প্রিভিউ'**
  String get memberFundTransparencyPreviewTitle;

  /// No description provided for @memberFundTransparencySubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সোসাইটির প্রতিটি আর্থিক লেনদেন সবার জন্য উন্মুক্ত — আয়, ব্যয় ও ব্যালেন্স এক নজরে'**
  String get memberFundTransparencySubtitle;

  /// No description provided for @memberFundTransparencySummaryLine.
  ///
  /// In bn, this message translates to:
  /// **'এই সময়ে আয় হয়েছে {income} টাকা, ব্যয় হয়েছে {expense} টাকা, নিট জমা {net} টাকা।'**
  String memberFundTransparencySummaryLine(
      Object expense, Object income, Object net);

  /// No description provided for @memberFundTransparencyTitle.
  ///
  /// In bn, this message translates to:
  /// **'ফান্ড স্বচ্ছতা'**
  String get memberFundTransparencyTitle;

  /// No description provided for @memberFundTransparencyTopTag.
  ///
  /// In bn, this message translates to:
  /// **'সর্বোচ্চ'**
  String get memberFundTransparencyTopTag;

  /// No description provided for @memberFundTransparencyTotalExpense.
  ///
  /// In bn, this message translates to:
  /// **'সর্বমোট ব্যয়'**
  String get memberFundTransparencyTotalExpense;

  /// No description provided for @memberFundTransparencyTotalIncome.
  ///
  /// In bn, this message translates to:
  /// **'সর্বমোট আয়'**
  String get memberFundTransparencyTotalIncome;

  /// No description provided for @memberFundTransparencyTypeExpense.
  ///
  /// In bn, this message translates to:
  /// **'ব্যয়'**
  String get memberFundTransparencyTypeExpense;

  /// No description provided for @memberFundTransparencyTypeIncome.
  ///
  /// In bn, this message translates to:
  /// **'আয়'**
  String get memberFundTransparencyTypeIncome;

  /// No description provided for @memberInstallmentsAmountColumn.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get memberInstallmentsAmountColumn;

  /// No description provided for @memberInstallmentsEmptyFiltered.
  ///
  /// In bn, this message translates to:
  /// **'এই বছরের কোনো পেমেন্ট পাওয়া যায়নি।'**
  String get memberInstallmentsEmptyFiltered;

  /// No description provided for @memberInstallmentsEmptyState.
  ///
  /// In bn, this message translates to:
  /// **'কোনো কিস্তি নেই'**
  String get memberInstallmentsEmptyState;

  /// No description provided for @memberInstallmentsFilterAll.
  ///
  /// In bn, this message translates to:
  /// **'সব বছর'**
  String get memberInstallmentsFilterAll;

  /// No description provided for @memberInstallmentsLoadError.
  ///
  /// In bn, this message translates to:
  /// **'কিস্তির তালিকা লোড করা যায়নি।'**
  String get memberInstallmentsLoadError;

  /// No description provided for @memberInstallmentsMonthColumn.
  ///
  /// In bn, this message translates to:
  /// **'মাস'**
  String get memberInstallmentsMonthColumn;

  /// No description provided for @memberInstallmentsPaidAtColumn.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধের তারিখ'**
  String get memberInstallmentsPaidAtColumn;

  /// No description provided for @memberInstallmentsPaymentNotice.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদা পরিশোধ অফিসে সরাসরি (নগদ/বিকাশ/ব্যাংক) করা হয়; প্রশাসন তা এখানে হালনাগাদ করেন।'**
  String get memberInstallmentsPaymentNotice;

  /// No description provided for @memberInstallmentsStatusColumn.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get memberInstallmentsStatusColumn;

  /// No description provided for @memberInstallmentsStatusDue.
  ///
  /// In bn, this message translates to:
  /// **'বকেয়া'**
  String get memberInstallmentsStatusDue;

  /// No description provided for @memberInstallmentsStatusPaid.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত'**
  String get memberInstallmentsStatusPaid;

  /// No description provided for @memberInstallmentsSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার মাসিক চাঁদা পরিশোধের হিসাব এক নজরে।'**
  String get memberInstallmentsSubtitle;

  /// No description provided for @memberInstallmentsSummaryDue.
  ///
  /// In bn, this message translates to:
  /// **'মোট বকেয়া'**
  String get memberInstallmentsSummaryDue;

  /// No description provided for @memberInstallmentsSummaryPaid.
  ///
  /// In bn, this message translates to:
  /// **'মোট পরিশোধিত'**
  String get memberInstallmentsSummaryPaid;

  /// No description provided for @memberInstallmentsSummaryPayments.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত কিস্তি'**
  String get memberInstallmentsSummaryPayments;

  /// No description provided for @memberInstallmentsTitle.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদার ইতিহাস'**
  String get memberInstallmentsTitle;

  /// No description provided for @memberPayDuesAmount.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get memberPayDuesAmount;

  /// No description provided for @memberPayDuesBack.
  ///
  /// In bn, this message translates to:
  /// **'পেছনে'**
  String get memberPayDuesBack;

  /// No description provided for @memberPayDuesBannerTitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার {count} মাসের চাঁদা বকেয়া'**
  String memberPayDuesBannerTitle(Object count);

  /// No description provided for @memberPayDuesClearAll.
  ///
  /// In bn, this message translates to:
  /// **'সব বাদ'**
  String get memberPayDuesClearAll;

  /// No description provided for @memberPayDuesClose.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করুন'**
  String get memberPayDuesClose;

  /// No description provided for @memberPayDuesContinue.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী'**
  String get memberPayDuesContinue;

  /// No description provided for @memberPayDuesCopied.
  ///
  /// In bn, this message translates to:
  /// **'কপি হয়েছে'**
  String get memberPayDuesCopied;

  /// No description provided for @memberPayDuesCopy.
  ///
  /// In bn, this message translates to:
  /// **'কপি'**
  String get memberPayDuesCopy;

  /// No description provided for @memberPayDuesHistoryTitle.
  ///
  /// In bn, this message translates to:
  /// **'সাম্প্রতিক অনলাইন পরিশোধ'**
  String get memberPayDuesHistoryTitle;

  /// No description provided for @memberPayDuesIHavePaid.
  ///
  /// In bn, this message translates to:
  /// **'আমি পরিশোধ করেছি'**
  String get memberPayDuesIHavePaid;

  /// No description provided for @memberPayDuesKeepReceipt.
  ///
  /// In bn, this message translates to:
  /// **'SMS/রসিদের ট্রানজেকশন আইডি সংরক্ষণ করুন — পরের ধাপে লাগবে।'**
  String get memberPayDuesKeepReceipt;

  /// No description provided for @memberPayDuesMethodHint.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধের মাধ্যম বেছে নিন, তারপর এই অ্যাকাউন্টে সঠিক পরিমাণ পাঠান।'**
  String get memberPayDuesMethodHint;

  /// No description provided for @memberPayDuesMonths.
  ///
  /// In bn, this message translates to:
  /// **'মাস'**
  String get memberPayDuesMonths;

  /// No description provided for @memberPayDuesNote.
  ///
  /// In bn, this message translates to:
  /// **'মন্তব্য (ঐচ্ছিক)'**
  String get memberPayDuesNote;

  /// No description provided for @memberPayDuesNotice.
  ///
  /// In bn, this message translates to:
  /// **'“চাঁদা পরিশোধ” বাটনে অনলাইনে পরিশোধ করুন। কমিটি যাচাই করার পর তা পরিশোধিত হিসেবে দেখাবে।'**
  String get memberPayDuesNotice;

  /// No description provided for @memberPayDuesOldest.
  ///
  /// In bn, this message translates to:
  /// **'সবচেয়ে পুরনো'**
  String get memberPayDuesOldest;

  /// No description provided for @memberPayDuesPaidOn.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধের তারিখ'**
  String get memberPayDuesPaidOn;

  /// No description provided for @memberPayDuesPayNow.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদা পরিশোধ'**
  String get memberPayDuesPayNow;

  /// No description provided for @memberPayDuesPaymentStatusApproved.
  ///
  /// In bn, this message translates to:
  /// **'যাচাইকৃত'**
  String get memberPayDuesPaymentStatusApproved;

  /// No description provided for @memberPayDuesPaymentStatusPending.
  ///
  /// In bn, this message translates to:
  /// **'যাচাইয়ের অপেক্ষায়'**
  String get memberPayDuesPaymentStatusPending;

  /// No description provided for @memberPayDuesPaymentStatusRejected.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get memberPayDuesPaymentStatusRejected;

  /// No description provided for @memberPayDuesProof.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ / স্ক্রিনশট (ঐচ্ছিক)'**
  String get memberPayDuesProof;

  /// No description provided for @memberPayDuesProofHint.
  ///
  /// In bn, this message translates to:
  /// **'JPG, PNG বা PDF, সর্বোচ্চ ৫ MB।'**
  String get memberPayDuesProofHint;

  /// No description provided for @memberPayDuesProofSizeError.
  ///
  /// In bn, this message translates to:
  /// **'ফাইল ৫ MB-এর বেশি হতে পারবে না।'**
  String get memberPayDuesProofSizeError;

  /// No description provided for @memberPayDuesProofTypeError.
  ///
  /// In bn, this message translates to:
  /// **'শুধু JPG, PNG বা PDF ফাইল দেওয়া যাবে।'**
  String get memberPayDuesProofTypeError;

  /// No description provided for @memberPayDuesRejectedReason.
  ///
  /// In bn, this message translates to:
  /// **'কারণ'**
  String get memberPayDuesRejectedReason;

  /// No description provided for @memberPayDuesSelectAll.
  ///
  /// In bn, this message translates to:
  /// **'সব নির্বাচন'**
  String get memberPayDuesSelectAll;

  /// No description provided for @memberPayDuesSelectHint.
  ///
  /// In bn, this message translates to:
  /// **'পুরনো বকেয়া আগে থেকেই নির্বাচিত। এখন যে মাস দিচ্ছেন না সেটির টিক তুলে দিন।'**
  String get memberPayDuesSelectHint;

  /// No description provided for @memberPayDuesSendTo.
  ///
  /// In bn, this message translates to:
  /// **'পাঠাবেন'**
  String get memberPayDuesSendTo;

  /// No description provided for @memberPayDuesSenderAccount.
  ///
  /// In bn, this message translates to:
  /// **'যে নম্বর/অ্যাকাউন্ট থেকে পাঠিয়েছেন'**
  String get memberPayDuesSenderAccount;

  /// No description provided for @memberPayDuesStatusPending.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই চলছে'**
  String get memberPayDuesStatusPending;

  /// No description provided for @memberPayDuesStep1.
  ///
  /// In bn, this message translates to:
  /// **'মাস নির্বাচন'**
  String get memberPayDuesStep1;

  /// No description provided for @memberPayDuesStep2.
  ///
  /// In bn, this message translates to:
  /// **'টাকা পাঠান'**
  String get memberPayDuesStep2;

  /// No description provided for @memberPayDuesStep3.
  ///
  /// In bn, this message translates to:
  /// **'নিশ্চিত করুন'**
  String get memberPayDuesStep3;

  /// No description provided for @memberPayDuesSubmit.
  ///
  /// In bn, this message translates to:
  /// **'যাচাইয়ের জন্য জমা দিন'**
  String get memberPayDuesSubmit;

  /// No description provided for @memberPayDuesSubmitError.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধ জমা দেওয়া যায়নি। আবার চেষ্টা করুন।'**
  String get memberPayDuesSubmitError;

  /// No description provided for @memberPayDuesSubmitted.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধ জমা হয়েছে! কমিটি শীঘ্রই যাচাই করবে এবং আপনাকে ইমেইলে জানানো হবে।'**
  String get memberPayDuesSubmitted;

  /// No description provided for @memberPayDuesSubmitting.
  ///
  /// In bn, this message translates to:
  /// **'জমা হচ্ছে...'**
  String get memberPayDuesSubmitting;

  /// No description provided for @memberPayDuesTitle.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক চাঁদা পরিশোধ'**
  String get memberPayDuesTitle;

  /// No description provided for @memberPayDuesTotalLabel.
  ///
  /// In bn, this message translates to:
  /// **'{count} মাসের মোট'**
  String memberPayDuesTotalLabel(Object count);

  /// No description provided for @memberPayDuesTransactionRef.
  ///
  /// In bn, this message translates to:
  /// **'ট্রানজেকশন আইডি'**
  String get memberPayDuesTransactionRef;

  /// No description provided for @memberPayDuesTransactionRefError.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক ট্রানজেকশন আইডি দিন (৪–৬৪ অক্ষর/সংখ্যা)।'**
  String get memberPayDuesTransactionRefError;

  /// No description provided for @memberPayDuesTransactionRefPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'যেমন 9KX7AB12CD'**
  String get memberPayDuesTransactionRefPlaceholder;

  /// No description provided for @memberPicnicAccessDenied.
  ///
  /// In bn, this message translates to:
  /// **'আপনার পিকনিক পরিশোধে প্রবেশাধিকার নেই।'**
  String get memberPicnicAccessDenied;

  /// No description provided for @memberPicnicAdditionalHeads.
  ///
  /// In bn, this message translates to:
  /// **'অতিরিক্ত প্রধান'**
  String get memberPicnicAdditionalHeads;

  /// No description provided for @memberPicnicAdditionalHeadsHint.
  ///
  /// In bn, this message translates to:
  /// **'০ থেকে {max} (স্ত্রী, সন্তান, অতিথি)'**
  String memberPicnicAdditionalHeadsHint(Object max);

  /// No description provided for @memberPicnicAdditionalHeadsLabel.
  ///
  /// In bn, this message translates to:
  /// **'অতিরিক্ত জনসংখ্যা'**
  String get memberPicnicAdditionalHeadsLabel;

  /// No description provided for @memberPicnicDateColumn.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get memberPicnicDateColumn;

  /// No description provided for @memberPicnicDateLabel.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধের তারিখ'**
  String get memberPicnicDateLabel;

  /// No description provided for @memberPicnicEmptyState.
  ///
  /// In bn, this message translates to:
  /// **'এখনও কোনো পিকনিক পরিশোধ নেই।'**
  String get memberPicnicEmptyState;

  /// No description provided for @memberPicnicFeeLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক ফি লোড করা যায়নি।'**
  String get memberPicnicFeeLoadFailed;

  /// No description provided for @memberPicnicHeadNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'প্রধান {n} নাম'**
  String memberPicnicHeadNameLabel(Object n);

  /// No description provided for @memberPicnicHeadRelationLabel.
  ///
  /// In bn, this message translates to:
  /// **'প্রধান {n} সম্পর্ক'**
  String memberPicnicHeadRelationLabel(Object n);

  /// No description provided for @memberPicnicHeadsColumn.
  ///
  /// In bn, this message translates to:
  /// **'অতিরিক্ত জন'**
  String get memberPicnicHeadsColumn;

  /// No description provided for @memberPicnicHistoryLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধের ইতিহাস লোড করা যায়নি।'**
  String get memberPicnicHistoryLoadFailed;

  /// No description provided for @memberPicnicHistoryTitle.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধের ইতিহাস'**
  String get memberPicnicHistoryTitle;

  /// No description provided for @memberPicnicLoadError.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধের ইতিহাস লোড করা যায়নি।'**
  String get memberPicnicLoadError;

  /// No description provided for @memberPicnicMemberHead.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য প্রধান'**
  String get memberPicnicMemberHead;

  /// No description provided for @memberPicnicMethodColumn.
  ///
  /// In bn, this message translates to:
  /// **'পদ্ধতি'**
  String get memberPicnicMethodColumn;

  /// No description provided for @memberPicnicMethodLabel.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধ পদ্ধতি'**
  String get memberPicnicMethodLabel;

  /// No description provided for @memberPicnicMethodsBankTransfer.
  ///
  /// In bn, this message translates to:
  /// **'ব্যাংক ট্রান্সফার'**
  String get memberPicnicMethodsBankTransfer;

  /// No description provided for @memberPicnicMethodsCash.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাশ'**
  String get memberPicnicMethodsCash;

  /// No description provided for @memberPicnicMethodsNagad.
  ///
  /// In bn, this message translates to:
  /// **'নগদ'**
  String get memberPicnicMethodsNagad;

  /// No description provided for @memberPicnicMethodsOther.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য'**
  String get memberPicnicMethodsOther;

  /// No description provided for @memberPicnicMethodsBKash.
  ///
  /// In bn, this message translates to:
  /// **'বিকাশ'**
  String get memberPicnicMethodsBKash;

  /// No description provided for @memberPicnicNotConfigured.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক ফি এখনও নির্ধারণ করা হয়নি। কমিটির সাথে যোগাযোগ করুন।'**
  String get memberPicnicNotConfigured;

  /// No description provided for @memberPicnicReceiptColumn.
  ///
  /// In bn, this message translates to:
  /// **'রশিদ নম্বর'**
  String get memberPicnicReceiptColumn;

  /// No description provided for @memberPicnicReceiptNoLabel.
  ///
  /// In bn, this message translates to:
  /// **'রশিদ নম্বর'**
  String get memberPicnicReceiptNoLabel;

  /// No description provided for @memberPicnicRelationsChild.
  ///
  /// In bn, this message translates to:
  /// **'সন্তান'**
  String get memberPicnicRelationsChild;

  /// No description provided for @memberPicnicRelationsGuest.
  ///
  /// In bn, this message translates to:
  /// **'অতিথি'**
  String get memberPicnicRelationsGuest;

  /// No description provided for @memberPicnicRelationsSpouse.
  ///
  /// In bn, this message translates to:
  /// **'স্ত্রী/স্বামী'**
  String get memberPicnicRelationsSpouse;

  /// No description provided for @memberPicnicRetry.
  ///
  /// In bn, this message translates to:
  /// **'আবার চেষ্টা করুন'**
  String get memberPicnicRetry;

  /// No description provided for @memberPicnicSaveError.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধ সংরক্ষণ করা যায়নি।'**
  String get memberPicnicSaveError;

  /// No description provided for @memberPicnicSaveSuccess.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধ সংরক্ষিত হয়েছে। মোট: ৳ {total}'**
  String memberPicnicSaveSuccess(Object total);

  /// No description provided for @memberPicnicSaving.
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষণ হচ্ছে…'**
  String get memberPicnicSaving;

  /// No description provided for @memberPicnicSubmit.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধ নিশ্চিত করুন'**
  String get memberPicnicSubmit;

  /// No description provided for @memberPicnicSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'নিজের আসন এবং স্ত্রী, সন্তান বা অতিথিদের আসনের জন্য পরিশোধ করুন'**
  String get memberPicnicSubtitle;

  /// No description provided for @memberPicnicTaka.
  ///
  /// In bn, this message translates to:
  /// **'টাকা'**
  String get memberPicnicTaka;

  /// No description provided for @memberPicnicTitle.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক ফি পরিশোধ'**
  String get memberPicnicTitle;

  /// No description provided for @memberPicnicTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট'**
  String get memberPicnicTotal;

  /// No description provided for @memberPicnicTotalColumn.
  ///
  /// In bn, this message translates to:
  /// **'মোট'**
  String get memberPicnicTotalColumn;

  /// No description provided for @memberProfileAddressLabel.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা'**
  String get memberProfileAddressLabel;

  /// No description provided for @memberProfileAddressTitle.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা'**
  String get memberProfileAddressTitle;

  /// No description provided for @memberProfileAdmissionFeeLabel.
  ///
  /// In bn, this message translates to:
  /// **'ভর্তি ফি'**
  String get memberProfileAdmissionFeeLabel;

  /// No description provided for @memberProfileCancelButton.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get memberProfileCancelButton;

  /// No description provided for @memberProfileChangePhotoButton.
  ///
  /// In bn, this message translates to:
  /// **'ছবি পরিবর্তন'**
  String get memberProfileChangePhotoButton;

  /// No description provided for @memberProfileCoOwnerLabel.
  ///
  /// In bn, this message translates to:
  /// **'সহ-মালিক'**
  String get memberProfileCoOwnerLabel;

  /// No description provided for @memberProfileContactTitle.
  ///
  /// In bn, this message translates to:
  /// **'যোগাযোগ'**
  String get memberProfileContactTitle;

  /// No description provided for @memberProfileCurrentAddressLabel.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান'**
  String get memberProfileCurrentAddressLabel;

  /// No description provided for @memberProfileDagNoCsLabel.
  ///
  /// In bn, this message translates to:
  /// **'দাগ নং (সিএস)'**
  String get memberProfileDagNoCsLabel;

  /// No description provided for @memberProfileDagNoRsLabel.
  ///
  /// In bn, this message translates to:
  /// **'দাগ নং (আরএস)'**
  String get memberProfileDagNoRsLabel;

  /// No description provided for @memberProfileDecimalUnit.
  ///
  /// In bn, this message translates to:
  /// **'শতাংশ'**
  String get memberProfileDecimalUnit;

  /// No description provided for @memberProfileDistrictLabel.
  ///
  /// In bn, this message translates to:
  /// **'জেলা'**
  String get memberProfileDistrictLabel;

  /// No description provided for @memberProfileDivisionLabel.
  ///
  /// In bn, this message translates to:
  /// **'বিভাগ'**
  String get memberProfileDivisionLabel;

  /// No description provided for @memberProfileDobLabel.
  ///
  /// In bn, this message translates to:
  /// **'জন্ম তারিখ'**
  String get memberProfileDobLabel;

  /// No description provided for @memberProfileDocumentLabel.
  ///
  /// In bn, this message translates to:
  /// **'দলিল'**
  String get memberProfileDocumentLabel;

  /// No description provided for @memberProfileDownload.
  ///
  /// In bn, this message translates to:
  /// **'ডাউনলোড'**
  String get memberProfileDownload;

  /// No description provided for @memberProfileDownloadFailed.
  ///
  /// In bn, this message translates to:
  /// **'ডাউনলোড করা যায়নি। আবার চেষ্টা করুন।'**
  String get memberProfileDownloadFailed;

  /// No description provided for @memberProfileEditButton.
  ///
  /// In bn, this message translates to:
  /// **'প্রোফাইল সম্পাদনা'**
  String get memberProfileEditButton;

  /// No description provided for @memberProfileEditTitle.
  ///
  /// In bn, this message translates to:
  /// **'প্রোফাইল সম্পাদনা করুন'**
  String get memberProfileEditTitle;

  /// No description provided for @memberProfileEmailLabel.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get memberProfileEmailLabel;

  /// No description provided for @memberProfileFatherOrHusbandLabel.
  ///
  /// In bn, this message translates to:
  /// **'পিতা/স্বামী'**
  String get memberProfileFatherOrHusbandLabel;

  /// No description provided for @memberProfileFileMissing.
  ///
  /// In bn, this message translates to:
  /// **'ফাইলটি সার্ভারে পাওয়া যায়নি। অনুগ্রহ করে আবার আপলোড করুন।'**
  String get memberProfileFileMissing;

  /// No description provided for @memberProfileGenderLabel.
  ///
  /// In bn, this message translates to:
  /// **'লিঙ্গ'**
  String get memberProfileGenderLabel;

  /// No description provided for @memberProfileHoldingNumberLabel.
  ///
  /// In bn, this message translates to:
  /// **'হোল্ডিং নম্বর'**
  String get memberProfileHoldingNumberLabel;

  /// No description provided for @memberProfileHouseLabel.
  ///
  /// In bn, this message translates to:
  /// **'বাড়ি'**
  String get memberProfileHouseLabel;

  /// No description provided for @memberProfileKhatianLabel.
  ///
  /// In bn, this message translates to:
  /// **'খতিয়ান'**
  String get memberProfileKhatianLabel;

  /// No description provided for @memberProfileLandQuantityLabel.
  ///
  /// In bn, this message translates to:
  /// **'জমির পরিমাণ'**
  String get memberProfileLandQuantityLabel;

  /// No description provided for @memberProfileLoadError.
  ///
  /// In bn, this message translates to:
  /// **'প্রোফাইল লোড করা যায়নি।'**
  String get memberProfileLoadError;

  /// No description provided for @memberProfileMemberIdLabel.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য আইডি'**
  String get memberProfileMemberIdLabel;

  /// No description provided for @memberProfileMobileLabel.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get memberProfileMobileLabel;

  /// No description provided for @memberProfileMotherLabel.
  ///
  /// In bn, this message translates to:
  /// **'মাতা'**
  String get memberProfileMotherLabel;

  /// No description provided for @memberProfileMyShareQuantityLabel.
  ///
  /// In bn, this message translates to:
  /// **'আমার অংশ'**
  String get memberProfileMyShareQuantityLabel;

  /// No description provided for @memberProfileNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get memberProfileNameLabel;

  /// No description provided for @memberProfileNationalityLabel.
  ///
  /// In bn, this message translates to:
  /// **'জাতীয়তা'**
  String get memberProfileNationalityLabel;

  /// No description provided for @memberProfileNidLabel.
  ///
  /// In bn, this message translates to:
  /// **'এনআইডি'**
  String get memberProfileNidLabel;

  /// No description provided for @memberProfileNoNominees.
  ///
  /// In bn, this message translates to:
  /// **'কোনো নমিনির তথ্য দেওয়া হয়নি।'**
  String get memberProfileNoNominees;

  /// No description provided for @memberProfileNoPropertyInfo.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সম্পত্তির তথ্য দেওয়া হয়নি।'**
  String get memberProfileNoPropertyInfo;

  /// No description provided for @memberProfileNomineesTitle.
  ///
  /// In bn, this message translates to:
  /// **'নমিনি'**
  String get memberProfileNomineesTitle;

  /// No description provided for @memberProfileOccupationLabel.
  ///
  /// In bn, this message translates to:
  /// **'পেশা'**
  String get memberProfileOccupationLabel;

  /// No description provided for @memberProfileOwnershipLabel.
  ///
  /// In bn, this message translates to:
  /// **'মালিকানা'**
  String get memberProfileOwnershipLabel;

  /// No description provided for @memberProfilePaymentMethodLabel.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট পদ্ধতি'**
  String get memberProfilePaymentMethodLabel;

  /// No description provided for @memberProfilePaymentTitle.
  ///
  /// In bn, this message translates to:
  /// **'নিবন্ধন পেমেন্ট'**
  String get memberProfilePaymentTitle;

  /// No description provided for @memberProfilePendingReviewNotice.
  ///
  /// In bn, this message translates to:
  /// **'সাম্প্রতিক প্রোফাইল হালনাগাদের কারণে আপনার সদস্যপদ বর্তমানে পর্যালোচনাধীন। পর্যালোচনার পর অনুমোদিত অবস্থা পুনরায় কার্যকর হবে।'**
  String get memberProfilePendingReviewNotice;

  /// No description provided for @memberProfilePermanentAddressLabel.
  ///
  /// In bn, this message translates to:
  /// **'স্থায়ী'**
  String get memberProfilePermanentAddressLabel;

  /// No description provided for @memberProfilePersonalInfoTitle.
  ///
  /// In bn, this message translates to:
  /// **'ব্যক্তিগত তথ্য'**
  String get memberProfilePersonalInfoTitle;

  /// No description provided for @memberProfilePhotoLabel.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের ছবি'**
  String get memberProfilePhotoLabel;

  /// No description provided for @memberProfilePhotoSizeError.
  ///
  /// In bn, this message translates to:
  /// **'ছবির আকার ৩ এমবি-র কম হতে হবে'**
  String get memberProfilePhotoSizeError;

  /// No description provided for @memberProfilePhotoTypeError.
  ///
  /// In bn, this message translates to:
  /// **'অনুগ্রহ করে একটি ছবি নির্বাচন করুন (JPG/PNG)'**
  String get memberProfilePhotoTypeError;

  /// No description provided for @memberProfilePhotoUploadError.
  ///
  /// In bn, this message translates to:
  /// **'ছবি আপলোড করা যায়নি। আবার চেষ্টা করুন।'**
  String get memberProfilePhotoUploadError;

  /// No description provided for @memberProfilePostOfficeLabel.
  ///
  /// In bn, this message translates to:
  /// **'ডাকঘর'**
  String get memberProfilePostOfficeLabel;

  /// No description provided for @memberProfilePropertyItemLabel.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি'**
  String get memberProfilePropertyItemLabel;

  /// No description provided for @memberProfilePropertyTitle.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি'**
  String get memberProfilePropertyTitle;

  /// No description provided for @memberProfileReceiptNoLabel.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ নং'**
  String get memberProfileReceiptNoLabel;

  /// No description provided for @memberProfileReceiptPhotoLabel.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট রসিদ'**
  String get memberProfileReceiptPhotoLabel;

  /// No description provided for @memberProfileRelationLabel.
  ///
  /// In bn, this message translates to:
  /// **'সম্পর্ক'**
  String get memberProfileRelationLabel;

  /// No description provided for @memberProfileRemovePhotoButton.
  ///
  /// In bn, this message translates to:
  /// **'সরান'**
  String get memberProfileRemovePhotoButton;

  /// No description provided for @memberProfileRequeueWarning.
  ///
  /// In bn, this message translates to:
  /// **'এই তথ্য পরিবর্তন করলে আপনার সদস্যপদ ব্যবস্থাপনা কমিটির পর্যালোচনার জন্য পুনরায় পাঠানো হবে।'**
  String get memberProfileRequeueWarning;

  /// No description provided for @memberProfileRoadLabel.
  ///
  /// In bn, this message translates to:
  /// **'সড়ক'**
  String get memberProfileRoadLabel;

  /// No description provided for @memberProfileSameAsPermanentAddress.
  ///
  /// In bn, this message translates to:
  /// **'একই — স্থায়ী ঠিকানার অনুরূপ'**
  String get memberProfileSameAsPermanentAddress;

  /// No description provided for @memberProfileSaveButton.
  ///
  /// In bn, this message translates to:
  /// **'পরিবর্তন সংরক্ষণ করুন'**
  String get memberProfileSaveButton;

  /// No description provided for @memberProfileSaveError.
  ///
  /// In bn, this message translates to:
  /// **'প্রোফাইল পরিবর্তন সংরক্ষণ করা যায়নি।'**
  String get memberProfileSaveError;

  /// No description provided for @memberProfileSignatureLabel.
  ///
  /// In bn, this message translates to:
  /// **'স্বাক্ষর'**
  String get memberProfileSignatureLabel;

  /// No description provided for @memberProfileStatusApproved.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদিত'**
  String get memberProfileStatusApproved;

  /// No description provided for @memberProfileStatusPending.
  ///
  /// In bn, this message translates to:
  /// **'পর্যালোচনাধীন'**
  String get memberProfileStatusPending;

  /// No description provided for @memberProfileStatusRejected.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যাখ্যাত'**
  String get memberProfileStatusRejected;

  /// No description provided for @memberProfileSubmissionDateLabel.
  ///
  /// In bn, this message translates to:
  /// **'নিবন্ধনের তারিখ'**
  String get memberProfileSubmissionDateLabel;

  /// No description provided for @memberProfileSubscriptionLabel.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদা'**
  String get memberProfileSubscriptionLabel;

  /// No description provided for @memberProfileTitle.
  ///
  /// In bn, this message translates to:
  /// **'প্রোফাইল'**
  String get memberProfileTitle;

  /// No description provided for @memberProfileUpazilaLabel.
  ///
  /// In bn, this message translates to:
  /// **'উপজেলা'**
  String get memberProfileUpazilaLabel;

  /// No description provided for @memberProfileUrgentContactTitle.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগ'**
  String get memberProfileUrgentContactTitle;

  /// No description provided for @memberProfileViewFile.
  ///
  /// In bn, this message translates to:
  /// **'ফাইল দেখুন'**
  String get memberProfileViewFile;

  /// No description provided for @memberProfileVillageLabel.
  ///
  /// In bn, this message translates to:
  /// **'গ্রাম'**
  String get memberProfileVillageLabel;

  /// No description provided for @memberPropertyRequestsActionsAdd.
  ///
  /// In bn, this message translates to:
  /// **'সংযোজন'**
  String get memberPropertyRequestsActionsAdd;

  /// No description provided for @memberPropertyRequestsActionsDelete.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলা'**
  String get memberPropertyRequestsActionsDelete;

  /// No description provided for @memberPropertyRequestsActionsEdit.
  ///
  /// In bn, this message translates to:
  /// **'সংশোধন'**
  String get memberPropertyRequestsActionsEdit;

  /// No description provided for @memberPropertyRequestsAddButton.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি যোগ করুন'**
  String get memberPropertyRequestsAddButton;

  /// No description provided for @memberPropertyRequestsAddCoOwnerButton.
  ///
  /// In bn, this message translates to:
  /// **'যৌথ মালিক যোগ করুন'**
  String get memberPropertyRequestsAddCoOwnerButton;

  /// No description provided for @memberPropertyRequestsAddDocButton.
  ///
  /// In bn, this message translates to:
  /// **'নথি যোগ করুন'**
  String get memberPropertyRequestsAddDocButton;

  /// No description provided for @memberPropertyRequestsAddTitle.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি সংযোজনের অনুরোধ'**
  String get memberPropertyRequestsAddTitle;

  /// No description provided for @memberPropertyRequestsBackButton.
  ///
  /// In bn, this message translates to:
  /// **'ফিরে যান'**
  String get memberPropertyRequestsBackButton;

  /// No description provided for @memberPropertyRequestsCancelReasonLabel.
  ///
  /// In bn, this message translates to:
  /// **'বাতিলের কারণ'**
  String get memberPropertyRequestsCancelReasonLabel;

  /// No description provided for @memberPropertyRequestsCoOwnerNamePlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'যৌথ মালিকের নাম'**
  String get memberPropertyRequestsCoOwnerNamePlaceholder;

  /// No description provided for @memberPropertyRequestsCoOwnerNameRequired.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যেক যৌথ মালিকের নাম দিতে হবে।'**
  String get memberPropertyRequestsCoOwnerNameRequired;

  /// No description provided for @memberPropertyRequestsCoOwnersLabel.
  ///
  /// In bn, this message translates to:
  /// **'যৌথ মালিকগণ'**
  String get memberPropertyRequestsCoOwnersLabel;

  /// No description provided for @memberPropertyRequestsDeleteModalConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'অপসারণের অনুরোধ পাঠান'**
  String get memberPropertyRequestsDeleteModalConfirmLabel;

  /// No description provided for @memberPropertyRequestsDeleteModalMessage.
  ///
  /// In bn, this message translates to:
  /// **'এই সম্পত্তিটি মুছে ফেলার আগে একজন প্রশাসক আপনার অনুরোধটি পর্যালোচনা করবেন।'**
  String get memberPropertyRequestsDeleteModalMessage;

  /// No description provided for @memberPropertyRequestsDeleteModalTitle.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি অপসারণের অনুরোধ'**
  String get memberPropertyRequestsDeleteModalTitle;

  /// No description provided for @memberPropertyRequestsDocDropped.
  ///
  /// In bn, this message translates to:
  /// **'বাদ দেওয়া হবে'**
  String get memberPropertyRequestsDocDropped;

  /// No description provided for @memberPropertyRequestsDocIncomplete.
  ///
  /// In bn, this message translates to:
  /// **'নথির ধরন নির্বাচন করে ফাইল সংযুক্ত করুন।'**
  String get memberPropertyRequestsDocIncomplete;

  /// No description provided for @memberPropertyRequestsDocKept.
  ///
  /// In bn, this message translates to:
  /// **'রাখা হবে'**
  String get memberPropertyRequestsDocKept;

  /// No description provided for @memberPropertyRequestsDocsLabel.
  ///
  /// In bn, this message translates to:
  /// **'নথিপত্র'**
  String get memberPropertyRequestsDocsLabel;

  /// No description provided for @memberPropertyRequestsDocumentsSectionTitle.
  ///
  /// In bn, this message translates to:
  /// **'নথিপত্র'**
  String get memberPropertyRequestsDocumentsSectionTitle;

  /// No description provided for @memberPropertyRequestsEditTitle.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি সংশোধনের অনুরোধ'**
  String get memberPropertyRequestsEditTitle;

  /// No description provided for @memberPropertyRequestsErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি সংক্রান্ত অনুরোধ লোড করা যায়নি।'**
  String get memberPropertyRequestsErrorsLoadFailed;

  /// No description provided for @memberPropertyRequestsErrorsPropertyNotFound.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধকৃত সম্পত্তিটি পাওয়া যায়নি।'**
  String get memberPropertyRequestsErrorsPropertyNotFound;

  /// No description provided for @memberPropertyRequestsErrorsSubmitFailed.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ পাঠানো যায়নি। আবার চেষ্টা করুন।'**
  String get memberPropertyRequestsErrorsSubmitFailed;

  /// No description provided for @memberPropertyRequestsErrorsWithdrawFailed.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ প্রত্যাহার করা যায়নি।'**
  String get memberPropertyRequestsErrorsWithdrawFailed;

  /// No description provided for @memberPropertyRequestsExistingDocsLabel.
  ///
  /// In bn, this message translates to:
  /// **'বিদ্যমান নথি'**
  String get memberPropertyRequestsExistingDocsLabel;

  /// No description provided for @memberPropertyRequestsFormSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার পরিবর্তনটি প্রশাসকের পর্যালোচনার জন্য জমা দিন।'**
  String get memberPropertyRequestsFormSubtitle;

  /// No description provided for @memberPropertyRequestsListTitle.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি সংক্রান্ত অনুরোধ'**
  String get memberPropertyRequestsListTitle;

  /// No description provided for @memberPropertyRequestsNewDocsLabel.
  ///
  /// In bn, this message translates to:
  /// **'নতুন নথি যোগ করুন'**
  String get memberPropertyRequestsNewDocsLabel;

  /// No description provided for @memberPropertyRequestsNoExistingDocs.
  ///
  /// In bn, this message translates to:
  /// **'এই সম্পত্তিতে কোনো বিদ্যমান নথি নেই।'**
  String get memberPropertyRequestsNoExistingDocs;

  /// No description provided for @memberPropertyRequestsNoRequests.
  ///
  /// In bn, this message translates to:
  /// **'এখনও কোনো সম্পত্তি সংক্রান্ত অনুরোধ নেই।'**
  String get memberPropertyRequestsNoRequests;

  /// No description provided for @memberPropertyRequestsPendingPill.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ অপেক্ষমাণ'**
  String get memberPropertyRequestsPendingPill;

  /// No description provided for @memberPropertyRequestsPropertySectionTitle.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তির তথ্য'**
  String get memberPropertyRequestsPropertySectionTitle;

  /// No description provided for @memberPropertyRequestsStatusLabelsApproved.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদিত'**
  String get memberPropertyRequestsStatusLabelsApproved;

  /// No description provided for @memberPropertyRequestsStatusLabelsCancelled.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get memberPropertyRequestsStatusLabelsCancelled;

  /// No description provided for @memberPropertyRequestsStatusLabelsPending.
  ///
  /// In bn, this message translates to:
  /// **'অপেক্ষমাণ'**
  String get memberPropertyRequestsStatusLabelsPending;

  /// No description provided for @memberPropertyRequestsSubmitButton.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ পাঠান'**
  String get memberPropertyRequestsSubmitButton;

  /// No description provided for @memberPropertyRequestsSubmittedLabel.
  ///
  /// In bn, this message translates to:
  /// **'জমাদান'**
  String get memberPropertyRequestsSubmittedLabel;

  /// No description provided for @memberPropertyRequestsSuccessSent.
  ///
  /// In bn, this message translates to:
  /// **'আপনার অনুরোধ পর্যালোচনার জন্য পাঠানো হয়েছে।'**
  String get memberPropertyRequestsSuccessSent;

  /// No description provided for @memberPropertyRequestsWithdrawButton.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যাহার'**
  String get memberPropertyRequestsWithdrawButton;

  /// No description provided for @memberPropertyRequestsWithdrawModalConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যাহার করুন'**
  String get memberPropertyRequestsWithdrawModalConfirmLabel;

  /// No description provided for @memberPropertyRequestsWithdrawModalMessage.
  ///
  /// In bn, this message translates to:
  /// **'আপনার অপেক্ষমাণ অনুরোধটি বাতিল হবে। এটি আর ফেরানো যাবে না।'**
  String get memberPropertyRequestsWithdrawModalMessage;

  /// No description provided for @memberPropertyRequestsWithdrawModalTitle.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ প্রত্যাহার'**
  String get memberPropertyRequestsWithdrawModalTitle;

  /// No description provided for @memberPropertyRequestsWithdrawnSuccess.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধটি প্রত্যাহার করা হয়েছে।'**
  String get memberPropertyRequestsWithdrawnSuccess;

  /// No description provided for @memberRoadmapActionsImage.
  ///
  /// In bn, this message translates to:
  /// **'শেয়ার করার জন্য ছবি'**
  String get memberRoadmapActionsImage;

  /// No description provided for @memberRoadmapActionsPdf.
  ///
  /// In bn, this message translates to:
  /// **'A4 প্রিন্ট / PDF'**
  String get memberRoadmapActionsPdf;

  /// No description provided for @memberRoadmapActionsSlides.
  ///
  /// In bn, this message translates to:
  /// **'স্লাইড আকারে দেখুন'**
  String get memberRoadmapActionsSlides;

  /// No description provided for @memberRoadmapCompletedOn.
  ///
  /// In bn, this message translates to:
  /// **'সম্পন্ন: {date}'**
  String memberRoadmapCompletedOn(Object date);

  /// No description provided for @memberRoadmapEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই সময়সীমায় এখনো কোনো পরিকল্পনা যোগ করা হয়নি।'**
  String get memberRoadmapEmpty;

  /// No description provided for @memberRoadmapEmptyFiltered.
  ///
  /// In bn, this message translates to:
  /// **'এই ফিল্টারে কোনো পরিকল্পনা নেই।'**
  String get memberRoadmapEmptyFiltered;

  /// No description provided for @memberRoadmapExportError.
  ///
  /// In bn, this message translates to:
  /// **'ডাউনলোড তৈরি করা যায়নি। আবার চেষ্টা করুন।'**
  String get memberRoadmapExportError;

  /// No description provided for @memberRoadmapFilterAll.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get memberRoadmapFilterAll;

  /// No description provided for @memberRoadmapFilterDone.
  ///
  /// In bn, this message translates to:
  /// **'সম্পন্ন'**
  String get memberRoadmapFilterDone;

  /// No description provided for @memberRoadmapFilterInProgress.
  ///
  /// In bn, this message translates to:
  /// **'চলমান'**
  String get memberRoadmapFilterInProgress;

  /// No description provided for @memberRoadmapFilterPlanned.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পিত'**
  String get memberRoadmapFilterPlanned;

  /// No description provided for @memberRoadmapFilterAria.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা অনুযায়ী ফিল্টার'**
  String get memberRoadmapFilterAria;

  /// No description provided for @memberRoadmapFocusNow.
  ///
  /// In bn, this message translates to:
  /// **'এখন যেদিকে মনোযোগ'**
  String get memberRoadmapFocusNow;

  /// No description provided for @memberRoadmapItemCount.
  ///
  /// In bn, this message translates to:
  /// **'{n}টি পরিকল্পনা'**
  String memberRoadmapItemCount(Object n);

  /// No description provided for @memberRoadmapLastUpdated.
  ///
  /// In bn, this message translates to:
  /// **'সর্বশেষ আপডেট: {date}'**
  String memberRoadmapLastUpdated(Object date);

  /// No description provided for @memberRoadmapLoadError.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পনা লোড করা যায়নি। আবার চেষ্টা করুন।'**
  String get memberRoadmapLoadError;

  /// No description provided for @memberRoadmapOverallAria.
  ///
  /// In bn, this message translates to:
  /// **'সার্বিক অগ্রগতি {pct} শতাংশ'**
  String memberRoadmapOverallAria(Object pct);

  /// No description provided for @memberRoadmapOverallProgress.
  ///
  /// In bn, this message translates to:
  /// **'সার্বিক অগ্রগতি'**
  String get memberRoadmapOverallProgress;

  /// No description provided for @memberRoadmapProgressLabel.
  ///
  /// In bn, this message translates to:
  /// **'{name}: {done}/{total} সম্পন্ন — {pct}%'**
  String memberRoadmapProgressLabel(
      Object done, Object name, Object pct, Object total);

  /// No description provided for @memberRoadmapProgressShort.
  ///
  /// In bn, this message translates to:
  /// **'{done}/{total} সম্পন্ন — {pct}%'**
  String memberRoadmapProgressShort(Object done, Object pct, Object total);

  /// No description provided for @memberRoadmapSlidesHint.
  ///
  /// In bn, this message translates to:
  /// **'← → কী অথবা সোয়াইপ করে স্লাইড বদলান · Esc চাপলে বন্ধ হবে'**
  String get memberRoadmapSlidesHint;

  /// No description provided for @memberRoadmapSlidesNext.
  ///
  /// In bn, this message translates to:
  /// **'পরের স্লাইড'**
  String get memberRoadmapSlidesNext;

  /// No description provided for @memberRoadmapSlidesPrev.
  ///
  /// In bn, this message translates to:
  /// **'আগের স্লাইড'**
  String get memberRoadmapSlidesPrev;

  /// No description provided for @memberRoadmapStatusDone.
  ///
  /// In bn, this message translates to:
  /// **'সম্পন্ন'**
  String get memberRoadmapStatusDone;

  /// No description provided for @memberRoadmapStatusInProgress.
  ///
  /// In bn, this message translates to:
  /// **'চলমান'**
  String get memberRoadmapStatusInProgress;

  /// No description provided for @memberRoadmapStatusPlanned.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পিত'**
  String get memberRoadmapStatusPlanned;

  /// No description provided for @memberRoadmapStepperAria.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পনার সময়রেখা'**
  String get memberRoadmapStepperAria;

  /// No description provided for @memberRoadmapSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আমরা কোথায় আছি, কোথায় যাচ্ছি এবং কীভাবে যাচ্ছি।'**
  String get memberRoadmapSubtitle;

  /// No description provided for @memberRoadmapTarget.
  ///
  /// In bn, this message translates to:
  /// **'লক্ষ্য: {date}'**
  String memberRoadmapTarget(Object date);

  /// No description provided for @memberRoadmapTitle.
  ///
  /// In bn, this message translates to:
  /// **'আমাদের পরিকল্পনা'**
  String get memberRoadmapTitle;

  /// No description provided for @memberRoadmapWeAreHere.
  ///
  /// In bn, this message translates to:
  /// **'আমরা এখানে'**
  String get memberRoadmapWeAreHere;

  /// No description provided for @memberRoadmapWhereSummary.
  ///
  /// In bn, this message translates to:
  /// **'মোট {total}টি পরিকল্পনার মধ্যে {done}টি সম্পন্ন হয়েছে।'**
  String memberRoadmapWhereSummary(Object done, Object total);

  /// No description provided for @memberRoadmapWhereTitle.
  ///
  /// In bn, this message translates to:
  /// **'আমরা এখন কোথায় আছি'**
  String get memberRoadmapWhereTitle;

  /// No description provided for @navAdmin.
  ///
  /// In bn, this message translates to:
  /// **'প্রশাসক'**
  String get navAdmin;

  /// No description provided for @navAuditLog.
  ///
  /// In bn, this message translates to:
  /// **'অডিট লগ'**
  String get navAuditLog;

  /// No description provided for @navChangePassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড পরিবর্তন'**
  String get navChangePassword;

  /// No description provided for @navChangeTheme.
  ///
  /// In bn, this message translates to:
  /// **'থিম পরিবর্তন'**
  String get navChangeTheme;

  /// No description provided for @navCloseMenu.
  ///
  /// In bn, this message translates to:
  /// **'মেনু বন্ধ করুন'**
  String get navCloseMenu;

  /// No description provided for @navConfigLists.
  ///
  /// In bn, this message translates to:
  /// **'কনফিগ তালিকা'**
  String get navConfigLists;

  /// No description provided for @navCostShares.
  ///
  /// In bn, this message translates to:
  /// **'খরচের ভাগ'**
  String get navCostShares;

  /// No description provided for @navDarkTheme.
  ///
  /// In bn, this message translates to:
  /// **'গাঢ় থিম'**
  String get navDarkTheme;

  /// No description provided for @navDashboard.
  ///
  /// In bn, this message translates to:
  /// **'ড্যাশবোর্ড'**
  String get navDashboard;

  /// No description provided for @navEvents.
  ///
  /// In bn, this message translates to:
  /// **'অনুষ্ঠান'**
  String get navEvents;

  /// No description provided for @navEventsManagement.
  ///
  /// In bn, this message translates to:
  /// **'অনুষ্ঠান ব্যবস্থাপনা'**
  String get navEventsManagement;

  /// No description provided for @navFeeSettings.
  ///
  /// In bn, this message translates to:
  /// **'ফি সেটিংস'**
  String get navFeeSettings;

  /// No description provided for @navFinanceManagement.
  ///
  /// In bn, this message translates to:
  /// **'আর্থিক ব্যবস্থাপনা'**
  String get navFinanceManagement;

  /// No description provided for @navFundTransparency.
  ///
  /// In bn, this message translates to:
  /// **'ফান্ড স্বচ্ছতা'**
  String get navFundTransparency;

  /// No description provided for @navInstallments.
  ///
  /// In bn, this message translates to:
  /// **'কিস্তি'**
  String get navInstallments;

  /// No description provided for @navInstallmentsManagement.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদা ব্যবস্থাপনা'**
  String get navInstallmentsManagement;

  /// No description provided for @navLightTheme.
  ///
  /// In bn, this message translates to:
  /// **'হালকা থিম'**
  String get navLightTheme;

  /// No description provided for @navLogin.
  ///
  /// In bn, this message translates to:
  /// **'লগইন'**
  String get navLogin;

  /// No description provided for @navLogout.
  ///
  /// In bn, this message translates to:
  /// **'বের হোন'**
  String get navLogout;

  /// No description provided for @navMembersList.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য তালিকা'**
  String get navMembersList;

  /// No description provided for @navMoreOptions.
  ///
  /// In bn, this message translates to:
  /// **'আরও বিকল্প'**
  String get navMoreOptions;

  /// No description provided for @navNotices.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ'**
  String get navNotices;

  /// No description provided for @navNoticesManagement.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ ব্যবস্থাপনা'**
  String get navNoticesManagement;

  /// No description provided for @navOpenMenu.
  ///
  /// In bn, this message translates to:
  /// **'মেনু খুলুন'**
  String get navOpenMenu;

  /// No description provided for @navPaymentVerifications.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট যাচাই'**
  String get navPaymentVerifications;

  /// No description provided for @navPicnicPayment.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক ফি'**
  String get navPicnicPayment;

  /// No description provided for @navPicnicPayments.
  ///
  /// In bn, this message translates to:
  /// **'পিকনিক পরিশোধ'**
  String get navPicnicPayments;

  /// No description provided for @navProfile.
  ///
  /// In bn, this message translates to:
  /// **'প্রোফাইল'**
  String get navProfile;

  /// No description provided for @navPropertyRequests.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি সংক্রান্ত অনুরোধ'**
  String get navPropertyRequests;

  /// No description provided for @navRegister.
  ///
  /// In bn, this message translates to:
  /// **'আবেদন করুন'**
  String get navRegister;

  /// No description provided for @navResolutionBook.
  ///
  /// In bn, this message translates to:
  /// **'রেজোলিউশন বুক'**
  String get navResolutionBook;

  /// No description provided for @navRoadmap.
  ///
  /// In bn, this message translates to:
  /// **'আমাদের পরিকল্পনা'**
  String get navRoadmap;

  /// No description provided for @navRoadmapManagement.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পনা ব্যবস্থাপনা'**
  String get navRoadmapManagement;

  /// No description provided for @navRolesPermissions.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা ও অনুমতি'**
  String get navRolesPermissions;

  /// No description provided for @navSocietyCosts.
  ///
  /// In bn, this message translates to:
  /// **'সোসাইটি খরচ'**
  String get navSocietyCosts;

  /// No description provided for @navSubmissions.
  ///
  /// In bn, this message translates to:
  /// **'সাবমিশন'**
  String get navSubmissions;

  /// No description provided for @noticesBackToList.
  ///
  /// In bn, this message translates to:
  /// **'সব নোটিশ'**
  String get noticesBackToList;

  /// No description provided for @noticesEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো নোটিশ প্রকাশ করা হয়নি।'**
  String get noticesEmpty;

  /// No description provided for @noticesErrorsLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ লোড করা যায়নি।'**
  String get noticesErrorsLoadFailed;

  /// No description provided for @noticesNotFound.
  ///
  /// In bn, this message translates to:
  /// **'এই নোটিশটি আর পাওয়া যাচ্ছে না।'**
  String get noticesNotFound;

  /// No description provided for @noticesSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটির ঘোষণা'**
  String get noticesSubtitle;

  /// No description provided for @noticesTitle.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ'**
  String get noticesTitle;

  /// No description provided for @passwordfieldHide.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড লুকান'**
  String get passwordfieldHide;

  /// No description provided for @passwordfieldShow.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড দেখুন'**
  String get passwordfieldShow;

  /// No description provided for @rbActionsAddMeeting.
  ///
  /// In bn, this message translates to:
  /// **'নতুন সভা'**
  String get rbActionsAddMeeting;

  /// No description provided for @rbActionsEdit.
  ///
  /// In bn, this message translates to:
  /// **'সম্পাদনা'**
  String get rbActionsEdit;

  /// No description provided for @rbActionsPdf.
  ///
  /// In bn, this message translates to:
  /// **'পিডিএফ ডাউনলোড'**
  String get rbActionsPdf;

  /// No description provided for @rbAttendanceAbsent.
  ///
  /// In bn, this message translates to:
  /// **'অনুপস্থিত'**
  String get rbAttendanceAbsent;

  /// No description provided for @rbAttendancePresent.
  ///
  /// In bn, this message translates to:
  /// **'উপস্থিত'**
  String get rbAttendancePresent;

  /// No description provided for @rbDetailAgenda.
  ///
  /// In bn, this message translates to:
  /// **'আলোচ্যসূচি'**
  String get rbDetailAgenda;

  /// No description provided for @rbDetailAttendanceTitle.
  ///
  /// In bn, this message translates to:
  /// **'উপস্থিতি'**
  String get rbDetailAttendanceTitle;

  /// No description provided for @rbDetailBack.
  ///
  /// In bn, this message translates to:
  /// **'রেজোলিউশন বুক'**
  String get rbDetailBack;

  /// No description provided for @rbDetailChair.
  ///
  /// In bn, this message translates to:
  /// **'সভাপতি'**
  String get rbDetailChair;

  /// No description provided for @rbDetailCreatedBy.
  ///
  /// In bn, this message translates to:
  /// **'রেকর্ড করেছেন {name}'**
  String rbDetailCreatedBy(Object name);

  /// No description provided for @rbDetailLastUpdated.
  ///
  /// In bn, this message translates to:
  /// **'সর্বশেষ হালনাগাদ {date}'**
  String rbDetailLastUpdated(Object date);

  /// No description provided for @rbDetailNextMeeting.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী সভা'**
  String get rbDetailNextMeeting;

  /// No description provided for @rbDetailNoAttendance.
  ///
  /// In bn, this message translates to:
  /// **'উপস্থিতি রেকর্ড করা হয়নি।'**
  String get rbDetailNoAttendance;

  /// No description provided for @rbDetailNoResolutions.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সিদ্ধান্ত রেকর্ড করা হয়নি।'**
  String get rbDetailNoResolutions;

  /// No description provided for @rbDetailNoSummary.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সারসংক্ষেপ লেখা হয়নি।'**
  String get rbDetailNoSummary;

  /// No description provided for @rbDetailNotSet.
  ///
  /// In bn, this message translates to:
  /// **'নির্ধারিত নয়'**
  String get rbDetailNotSet;

  /// No description provided for @rbDetailResolutionNo.
  ///
  /// In bn, this message translates to:
  /// **'সিদ্ধান্ত-{no}'**
  String rbDetailResolutionNo(Object no);

  /// No description provided for @rbDetailResolutionStatus.
  ///
  /// In bn, this message translates to:
  /// **'সিদ্ধান্তের অবস্থা'**
  String get rbDetailResolutionStatus;

  /// No description provided for @rbDetailStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get rbDetailStatus;

  /// No description provided for @rbDetailSummary.
  ///
  /// In bn, this message translates to:
  /// **'আলোচনার সারসংক্ষেপ'**
  String get rbDetailSummary;

  /// No description provided for @rbDetailVotesAria.
  ///
  /// In bn, this message translates to:
  /// **'পক্ষে {for_val}, বিপক্ষে {against}, নিরপেক্ষ {neutral}'**
  String rbDetailVotesAria(Object against, Object for_val, Object neutral);

  /// No description provided for @rbExportError.
  ///
  /// In bn, this message translates to:
  /// **'পিডিএফ তৈরি করা যায়নি। আবার চেষ্টা করুন।'**
  String get rbExportError;

  /// No description provided for @rbFiltersAllStatuses.
  ///
  /// In bn, this message translates to:
  /// **'সব অবস্থা'**
  String get rbFiltersAllStatuses;

  /// No description provided for @rbFiltersAllTypes.
  ///
  /// In bn, this message translates to:
  /// **'সব ধরন'**
  String get rbFiltersAllTypes;

  /// No description provided for @rbFiltersApply.
  ///
  /// In bn, this message translates to:
  /// **'খুঁজুন'**
  String get rbFiltersApply;

  /// No description provided for @rbFiltersClear.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get rbFiltersClear;

  /// No description provided for @rbFiltersDateFrom.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ থেকে'**
  String get rbFiltersDateFrom;

  /// No description provided for @rbFiltersDateTo.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ পর্যন্ত'**
  String get rbFiltersDateTo;

  /// No description provided for @rbFiltersSearch.
  ///
  /// In bn, this message translates to:
  /// **'খুঁজুন'**
  String get rbFiltersSearch;

  /// No description provided for @rbFiltersSearchPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'সভা নম্বর, বিষয় বা সভাপতি দিয়ে খুঁজুন…'**
  String get rbFiltersSearchPlaceholder;

  /// No description provided for @rbFiltersStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get rbFiltersStatus;

  /// No description provided for @rbFiltersType.
  ///
  /// In bn, this message translates to:
  /// **'সভার ধরন'**
  String get rbFiltersType;

  /// No description provided for @rbFormAddResolution.
  ///
  /// In bn, this message translates to:
  /// **'সিদ্ধান্ত যোগ করুন'**
  String get rbFormAddResolution;

  /// No description provided for @rbFormAgenda.
  ///
  /// In bn, this message translates to:
  /// **'আলোচ্যসূচি'**
  String get rbFormAgenda;

  /// No description provided for @rbFormAgendaSummary.
  ///
  /// In bn, this message translates to:
  /// **'আলোচ্যসূচি ও সারসংক্ষেপ'**
  String get rbFormAgendaSummary;

  /// No description provided for @rbFormAssignee.
  ///
  /// In bn, this message translates to:
  /// **'দায়িত্বে (ঐচ্ছিক)'**
  String get rbFormAssignee;

  /// No description provided for @rbFormAssigneePlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'কেউ নয়'**
  String get rbFormAssigneePlaceholder;

  /// No description provided for @rbFormAttachments.
  ///
  /// In bn, this message translates to:
  /// **'রেকর্ডিং ও সংযুক্তি (ঐচ্ছিক)'**
  String get rbFormAttachments;

  /// No description provided for @rbFormAttendance.
  ///
  /// In bn, this message translates to:
  /// **'উপস্থিতি'**
  String get rbFormAttendance;

  /// No description provided for @rbFormAttendancePlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য নির্বাচন করুন…'**
  String get rbFormAttendancePlaceholder;

  /// No description provided for @rbFormAutoNo.
  ///
  /// In bn, this message translates to:
  /// **'স্বয়ংক্রিয়ভাবে প্রস্তাবিত'**
  String get rbFormAutoNo;

  /// No description provided for @rbFormChairperson.
  ///
  /// In bn, this message translates to:
  /// **'সভাপতি'**
  String get rbFormChairperson;

  /// No description provided for @rbFormChairpersonPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য নির্বাচন করুন…'**
  String get rbFormChairpersonPlaceholder;

  /// No description provided for @rbFormDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get rbFormDate;

  /// No description provided for @rbFormDecision.
  ///
  /// In bn, this message translates to:
  /// **'সিদ্ধান্ত'**
  String get rbFormDecision;

  /// No description provided for @rbFormDropzone.
  ///
  /// In bn, this message translates to:
  /// **'ফাইল যোগ করতে চাপ দিন — ভিডিও, অডিও, ছবি বা চ্যাট লগ'**
  String get rbFormDropzone;

  /// No description provided for @rbFormDropzoneHint.
  ///
  /// In bn, this message translates to:
  /// **'প্রতি ফাইল সর্বোচ্চ 100 MB'**
  String get rbFormDropzoneHint;

  /// No description provided for @rbFormDueDate.
  ///
  /// In bn, this message translates to:
  /// **'শেষ তারিখ (ঐচ্ছিক)'**
  String get rbFormDueDate;

  /// No description provided for @rbFormDuplicateNo.
  ///
  /// In bn, this message translates to:
  /// **'এই সভা নম্বরটি ইতিমধ্যে ব্যবহৃত। অন্য নম্বর দিন।'**
  String get rbFormDuplicateNo;

  /// No description provided for @rbFormEditTitle.
  ///
  /// In bn, this message translates to:
  /// **'সভা সম্পাদনা'**
  String get rbFormEditTitle;

  /// No description provided for @rbFormFileTooLarge.
  ///
  /// In bn, this message translates to:
  /// **'একটি ফাইল 100 MB সীমা ছাড়িয়ে গেছে।'**
  String get rbFormFileTooLarge;

  /// No description provided for @rbFormMarkAllPresent.
  ///
  /// In bn, this message translates to:
  /// **'সবাই উপস্থিত'**
  String get rbFormMarkAllPresent;

  /// No description provided for @rbFormMeetingInfo.
  ///
  /// In bn, this message translates to:
  /// **'সভার তথ্য'**
  String get rbFormMeetingInfo;

  /// No description provided for @rbFormMeetingNo.
  ///
  /// In bn, this message translates to:
  /// **'সভা নম্বর'**
  String get rbFormMeetingNo;

  /// No description provided for @rbFormNextMeeting.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী সভার তারিখ (ঐচ্ছিক)'**
  String get rbFormNextMeeting;

  /// No description provided for @rbFormNotify.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের জন্য নোটিশ প্রকাশ করুন'**
  String get rbFormNotify;

  /// No description provided for @rbFormPresentCount.
  ///
  /// In bn, this message translates to:
  /// **'{present}/{total} উপস্থিত'**
  String rbFormPresentCount(Object present, Object total);

  /// No description provided for @rbFormRemoveFile.
  ///
  /// In bn, this message translates to:
  /// **'বাদ দিন'**
  String get rbFormRemoveFile;

  /// No description provided for @rbFormRemoveResolution.
  ///
  /// In bn, this message translates to:
  /// **'বাদ দিন'**
  String get rbFormRemoveResolution;

  /// No description provided for @rbFormResolutions.
  ///
  /// In bn, this message translates to:
  /// **'গৃহীত সিদ্ধান্ত'**
  String get rbFormResolutions;

  /// No description provided for @rbFormSave.
  ///
  /// In bn, this message translates to:
  /// **'পরিবর্তন সংরক্ষণ করুন'**
  String get rbFormSave;

  /// No description provided for @rbFormStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get rbFormStatus;

  /// No description provided for @rbFormSubmit.
  ///
  /// In bn, this message translates to:
  /// **'সভার রেকর্ড সংরক্ষণ করুন'**
  String get rbFormSubmit;

  /// No description provided for @rbFormSubmitError.
  ///
  /// In bn, this message translates to:
  /// **'সভার রেকর্ড সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।'**
  String get rbFormSubmitError;

  /// No description provided for @rbFormSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সভা, উপস্থিতি ও সিদ্ধান্ত একসাথে এক বার জমা দিলেই সংরক্ষিত হবে।'**
  String get rbFormSubtitle;

  /// No description provided for @rbFormSummary.
  ///
  /// In bn, this message translates to:
  /// **'আলোচনার সারসংক্ষেপ'**
  String get rbFormSummary;

  /// No description provided for @rbFormTask.
  ///
  /// In bn, this message translates to:
  /// **'কাজ (ঐচ্ছিক)'**
  String get rbFormTask;

  /// No description provided for @rbFormTime.
  ///
  /// In bn, this message translates to:
  /// **'সময়'**
  String get rbFormTime;

  /// No description provided for @rbFormTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন সভার রেকর্ড'**
  String get rbFormTitle;

  /// No description provided for @rbFormType.
  ///
  /// In bn, this message translates to:
  /// **'সভার ধরন'**
  String get rbFormType;

  /// No description provided for @rbFormVotesExceed.
  ///
  /// In bn, this message translates to:
  /// **'মোট ভোট উপস্থিত সদস্য সংখ্যার বেশি হতে পারে না।'**
  String get rbFormVotesExceed;

  /// No description provided for @rbFormVotesExceedInline.
  ///
  /// In bn, this message translates to:
  /// **'একটি সিদ্ধান্তের মোট ভোট উপস্থিত সদস্য সংখ্যা ({present}) এর বেশি হতে পারে না।'**
  String rbFormVotesExceedInline(Object present);

  /// No description provided for @rbListAttendance.
  ///
  /// In bn, this message translates to:
  /// **'{present}/{total} উপস্থিত'**
  String rbListAttendance(Object present, Object total);

  /// No description provided for @rbListEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো সভার রেকর্ড নেই।'**
  String get rbListEmpty;

  /// No description provided for @rbListEmptyFiltered.
  ///
  /// In bn, this message translates to:
  /// **'আপনার খোঁজার সাথে মেলে এমন কোনো সভা পাওয়া যায়নি।'**
  String get rbListEmptyFiltered;

  /// No description provided for @rbListResolutions.
  ///
  /// In bn, this message translates to:
  /// **'{count} টি সিদ্ধান্ত'**
  String rbListResolutions(Object count);

  /// No description provided for @rbListTitle.
  ///
  /// In bn, this message translates to:
  /// **'সাম্প্রতিক সভা'**
  String get rbListTitle;

  /// No description provided for @rbLoadError.
  ///
  /// In bn, this message translates to:
  /// **'তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।'**
  String get rbLoadError;

  /// No description provided for @rbNavNext.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী'**
  String get rbNavNext;

  /// No description provided for @rbNavPrevious.
  ///
  /// In bn, this message translates to:
  /// **'পূর্ববর্তী'**
  String get rbNavPrevious;

  /// No description provided for @rbRecordingsDownload.
  ///
  /// In bn, this message translates to:
  /// **'ডাউনলোড'**
  String get rbRecordingsDownload;

  /// No description provided for @rbRecordingsDownloadError.
  ///
  /// In bn, this message translates to:
  /// **'ডাউনলোড ব্যর্থ হয়েছে।'**
  String get rbRecordingsDownloadError;

  /// No description provided for @rbRecordingsEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো রেকর্ডিং বা সংযুক্তি নেই।'**
  String get rbRecordingsEmpty;

  /// No description provided for @rbRecordingsTitle.
  ///
  /// In bn, this message translates to:
  /// **'রেকর্ডিং ও সংযুক্তি'**
  String get rbRecordingsTitle;

  /// No description provided for @rbRecordingsUpload.
  ///
  /// In bn, this message translates to:
  /// **'ফাইল আপলোড'**
  String get rbRecordingsUpload;

  /// No description provided for @rbRecordingsUploadError.
  ///
  /// In bn, this message translates to:
  /// **'আপলোড ব্যর্থ হয়েছে। ফাইলের ধরন ও আকার দেখুন।'**
  String get rbRecordingsUploadError;

  /// No description provided for @rbResolutionDone.
  ///
  /// In bn, this message translates to:
  /// **'সম্পন্ন'**
  String get rbResolutionDone;

  /// No description provided for @rbResolutionInProgress.
  ///
  /// In bn, this message translates to:
  /// **'চলমান'**
  String get rbResolutionInProgress;

  /// No description provided for @rbResolutionPending.
  ///
  /// In bn, this message translates to:
  /// **'অপেক্ষমাণ'**
  String get rbResolutionPending;

  /// No description provided for @rbStatusCancelled.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get rbStatusCancelled;

  /// No description provided for @rbStatusCompleted.
  ///
  /// In bn, this message translates to:
  /// **'সম্পন্ন'**
  String get rbStatusCompleted;

  /// No description provided for @rbStatusScheduled.
  ///
  /// In bn, this message translates to:
  /// **'নির্ধারিত'**
  String get rbStatusScheduled;

  /// No description provided for @rbSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'সভার রেকর্ড, সিদ্ধান্ত ও উপস্থিতি — সব এক জায়গায়'**
  String get rbSubtitle;

  /// No description provided for @rbSummaryAvgAttendance.
  ///
  /// In bn, this message translates to:
  /// **'গড় উপস্থিতি'**
  String get rbSummaryAvgAttendance;

  /// No description provided for @rbSummaryOpenActions.
  ///
  /// In bn, this message translates to:
  /// **'অসম্পন্ন কাজ'**
  String get rbSummaryOpenActions;

  /// No description provided for @rbSummaryThisYear.
  ///
  /// In bn, this message translates to:
  /// **'এই বছরের সভা'**
  String get rbSummaryThisYear;

  /// No description provided for @rbSummaryTitle.
  ///
  /// In bn, this message translates to:
  /// **'সারসংক্ষেপ'**
  String get rbSummaryTitle;

  /// No description provided for @rbSummaryTotalMeetings.
  ///
  /// In bn, this message translates to:
  /// **'মোট সভা'**
  String get rbSummaryTotalMeetings;

  /// No description provided for @rbTabsAttendance.
  ///
  /// In bn, this message translates to:
  /// **'উপস্থিতি'**
  String get rbTabsAttendance;

  /// No description provided for @rbTabsOverview.
  ///
  /// In bn, this message translates to:
  /// **'সংক্ষিপ্ত বিবরণ'**
  String get rbTabsOverview;

  /// No description provided for @rbTabsRecordings.
  ///
  /// In bn, this message translates to:
  /// **'রেকর্ডিং'**
  String get rbTabsRecordings;

  /// No description provided for @rbTabsResolutions.
  ///
  /// In bn, this message translates to:
  /// **'সিদ্ধান্ত'**
  String get rbTabsResolutions;

  /// No description provided for @rbTitle.
  ///
  /// In bn, this message translates to:
  /// **'রেজোলিউশন বুক'**
  String get rbTitle;

  /// No description provided for @rbTypeOffline.
  ///
  /// In bn, this message translates to:
  /// **'অফলাইন'**
  String get rbTypeOffline;

  /// No description provided for @rbTypeOnline.
  ///
  /// In bn, this message translates to:
  /// **'অনলাইন'**
  String get rbTypeOnline;

  /// No description provided for @rbUpcomingLabel.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী সভা'**
  String get rbUpcomingLabel;

  /// No description provided for @rbVoteAgainst.
  ///
  /// In bn, this message translates to:
  /// **'বিপক্ষে'**
  String get rbVoteAgainst;

  /// No description provided for @rbVoteFor.
  ///
  /// In bn, this message translates to:
  /// **'পক্ষে'**
  String get rbVoteFor;

  /// No description provided for @rbVoteNeutral.
  ///
  /// In bn, this message translates to:
  /// **'নিরপেক্ষ'**
  String get rbVoteNeutral;

  /// No description provided for @registrationAddressInfoCurrentAddressTitle.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ঠিকানা'**
  String get registrationAddressInfoCurrentAddressTitle;

  /// No description provided for @registrationAddressInfoDistrictLabel.
  ///
  /// In bn, this message translates to:
  /// **'জেলা'**
  String get registrationAddressInfoDistrictLabel;

  /// No description provided for @registrationAddressInfoDistrictRequired.
  ///
  /// In bn, this message translates to:
  /// **'জেলা আবশ্যক'**
  String get registrationAddressInfoDistrictRequired;

  /// No description provided for @registrationAddressInfoDivisionLabel.
  ///
  /// In bn, this message translates to:
  /// **'বিভাগ'**
  String get registrationAddressInfoDivisionLabel;

  /// No description provided for @registrationAddressInfoDivisionRequired.
  ///
  /// In bn, this message translates to:
  /// **'বিভাগ আবশ্যক'**
  String get registrationAddressInfoDivisionRequired;

  /// No description provided for @registrationAddressInfoHouseLabel.
  ///
  /// In bn, this message translates to:
  /// **'বাসা/হোল্ডিং নং'**
  String get registrationAddressInfoHouseLabel;

  /// No description provided for @registrationAddressInfoHouseRequired.
  ///
  /// In bn, this message translates to:
  /// **'বাসা/হোল্ডিং নং আবশ্যক'**
  String get registrationAddressInfoHouseRequired;

  /// No description provided for @registrationAddressInfoPermanentAddressTitle.
  ///
  /// In bn, this message translates to:
  /// **'স্থায়ী ঠিকানা'**
  String get registrationAddressInfoPermanentAddressTitle;

  /// No description provided for @registrationAddressInfoPostOfficeLabel.
  ///
  /// In bn, this message translates to:
  /// **'ডাকঘর'**
  String get registrationAddressInfoPostOfficeLabel;

  /// No description provided for @registrationAddressInfoPostOfficeRequired.
  ///
  /// In bn, this message translates to:
  /// **'ডাকঘর আবশ্যক'**
  String get registrationAddressInfoPostOfficeRequired;

  /// No description provided for @registrationAddressInfoRoadLabel.
  ///
  /// In bn, this message translates to:
  /// **'রাস্তা/গ্রাম'**
  String get registrationAddressInfoRoadLabel;

  /// No description provided for @registrationAddressInfoRoadRequired.
  ///
  /// In bn, this message translates to:
  /// **'রাস্তা/গ্রাম আবশ্যক'**
  String get registrationAddressInfoRoadRequired;

  /// No description provided for @registrationAddressInfoSameAsCurrentLabel.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ঠিকানার সাথে একই'**
  String get registrationAddressInfoSameAsCurrentLabel;

  /// No description provided for @registrationAddressInfoSelectPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'নির্বাচন করুন'**
  String get registrationAddressInfoSelectPlaceholder;

  /// No description provided for @registrationAddressInfoUpazilaLabel.
  ///
  /// In bn, this message translates to:
  /// **'উপজেলা/থানা'**
  String get registrationAddressInfoUpazilaLabel;

  /// No description provided for @registrationAddressInfoUpazilaRequired.
  ///
  /// In bn, this message translates to:
  /// **'উপজেলা/থানা আবশ্যক'**
  String get registrationAddressInfoUpazilaRequired;

  /// No description provided for @registrationConfirmationApplicantLabel.
  ///
  /// In bn, this message translates to:
  /// **'আবেদনকারী:'**
  String get registrationConfirmationApplicantLabel;

  /// No description provided for @registrationConfirmationMessage.
  ///
  /// In bn, this message translates to:
  /// **'আপনার আবেদন সফলভাবে জমা হয়েছে। অনুগ্রহ করে যাচাই ও অনুমোদনের জন্য অপেক্ষা করুন।'**
  String get registrationConfirmationMessage;

  /// No description provided for @registrationConfirmationNewFormButton.
  ///
  /// In bn, this message translates to:
  /// **'নতুন ফর্ম পূরণ করুন'**
  String get registrationConfirmationNewFormButton;

  /// No description provided for @registrationConfirmationOkButton.
  ///
  /// In bn, this message translates to:
  /// **'ঠিক আছে'**
  String get registrationConfirmationOkButton;

  /// No description provided for @registrationConfirmationReferenceLabel.
  ///
  /// In bn, this message translates to:
  /// **'আবেদন নং:'**
  String get registrationConfirmationReferenceLabel;

  /// No description provided for @registrationConfirmationTitle.
  ///
  /// In bn, this message translates to:
  /// **'সাবমিট সফল হয়েছে!'**
  String get registrationConfirmationTitle;

  /// No description provided for @registrationDeclarationConsentLabel.
  ///
  /// In bn, this message translates to:
  /// **'আমি সকল শর্তাবলীতে সম্মতি প্রদান করছি।'**
  String get registrationDeclarationConsentLabel;

  /// No description provided for @registrationDeclarationConsentRequired.
  ///
  /// In bn, this message translates to:
  /// **'অঙ্গীকারনামায় সম্মতি প্রদান আবশ্যক'**
  String get registrationDeclarationConsentRequired;

  /// No description provided for @registrationDeclarationText.
  ///
  /// In bn, this message translates to:
  /// **'আমি অঙ্গীকার করছি যে, উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটির গঠনতন্ত্র, নিয়ম-শৃঙ্খলা ও বিধি সংক্রান্ত সিদ্ধান্তসমূহ মেনে চলবো এবং সংগঠনের উদ্দেশ্য ও স্বার্থবিরোধী কোনো কর্মকাণ্ডে অংশগ্রহণ করবো না। সংগঠনের সিদ্ধান্তসমূহে সদস্যদের অধিকার, সম্পত্তির নিরাপত্তা, পারস্পরিক সহযোগিতা, সামাজিক কল্যাণ ও এলাকার উন্নয়নে দায়িত্বশীলভাবে সহযোগিতা করবো। উপরোক্ত তথ্যসমূহ আমার জ্ঞান ও বিশ্বাস অনুযায়ী সঠিক।'**
  String get registrationDeclarationText;

  /// No description provided for @registrationDeclarationTitle.
  ///
  /// In bn, this message translates to:
  /// **'অঙ্গীকারনামা'**
  String get registrationDeclarationTitle;

  /// No description provided for @registrationDraftDiscardDraft.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল করে নতুন করে শুরু করুন'**
  String get registrationDraftDiscardDraft;

  /// No description provided for @registrationDraftDraftRestoredToast.
  ///
  /// In bn, this message translates to:
  /// **'আপনার আগের অসম্পূর্ণ ফর্ম পুনরুদ্ধার করা হয়েছে'**
  String get registrationDraftDraftRestoredToast;

  /// No description provided for @registrationDraftDraftSaved.
  ///
  /// In bn, this message translates to:
  /// **'খসড়া সংরক্ষিত'**
  String get registrationDraftDraftSaved;

  /// No description provided for @registrationDraftReattachFilesNotice.
  ///
  /// In bn, this message translates to:
  /// **'পুনরুদ্ধার করা ফর্মে সংযুক্ত ফাইলগুলো আবার সংযুক্ত করুন'**
  String get registrationDraftReattachFilesNotice;

  /// No description provided for @registrationHeaderFormBadge.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য নিবন্ধন ও মালিকানা তথ্য ফরম'**
  String get registrationHeaderFormBadge;

  /// No description provided for @registrationHeaderLoginLink.
  ///
  /// In bn, this message translates to:
  /// **'লগইন'**
  String get registrationHeaderLoginLink;

  /// No description provided for @registrationHeaderLogoAlt.
  ///
  /// In bn, this message translates to:
  /// **'সংগঠনের লোগো'**
  String get registrationHeaderLogoAlt;

  /// No description provided for @registrationHeaderOrgLocation.
  ///
  /// In bn, this message translates to:
  /// **'উত্তর কাউন্দিয়া, সাভার, ঢাকা। | স্থাপিত : ২০২৬ ইং'**
  String get registrationHeaderOrgLocation;

  /// No description provided for @registrationHeaderOrgName.
  ///
  /// In bn, this message translates to:
  /// **'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি'**
  String get registrationHeaderOrgName;

  /// No description provided for @registrationHeaderOrgSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'(সকল জমি, বাড়ি ও ফ্ল্যাট মালিকদের ঐক্যবদ্ধ অরাজনৈতিক আবাসন সংগঠন)'**
  String get registrationHeaderOrgSubtitle;

  /// No description provided for @registrationHeaderStepperAriaLabel.
  ///
  /// In bn, this message translates to:
  /// **'নিবন্ধন ধাপসমূহ'**
  String get registrationHeaderStepperAriaLabel;

  /// No description provided for @registrationHeaderSubmissionDateLabel.
  ///
  /// In bn, this message translates to:
  /// **'নিবন্ধনের তারিখ'**
  String get registrationHeaderSubmissionDateLabel;

  /// No description provided for @registrationMemberInfoClearPhotoButton.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get registrationMemberInfoClearPhotoButton;

  /// No description provided for @registrationMemberInfoDobLabel.
  ///
  /// In bn, this message translates to:
  /// **'জন্ম তারিখ'**
  String get registrationMemberInfoDobLabel;

  /// No description provided for @registrationMemberInfoDobRequired.
  ///
  /// In bn, this message translates to:
  /// **'জন্ম তারিখ আবশ্যক'**
  String get registrationMemberInfoDobRequired;

  /// No description provided for @registrationMemberInfoEmailInvalid.
  ///
  /// In bn, this message translates to:
  /// **'ই-মেইল সঠিক নয়'**
  String get registrationMemberInfoEmailInvalid;

  /// No description provided for @registrationMemberInfoEmailLabel.
  ///
  /// In bn, this message translates to:
  /// **'ই-মেইল'**
  String get registrationMemberInfoEmailLabel;

  /// No description provided for @registrationMemberInfoEmailRequired.
  ///
  /// In bn, this message translates to:
  /// **'ই-মেইল আবশ্যক'**
  String get registrationMemberInfoEmailRequired;

  /// No description provided for @registrationMemberInfoFatherOrHusbandLabel.
  ///
  /// In bn, this message translates to:
  /// **'পিতা/স্বামী'**
  String get registrationMemberInfoFatherOrHusbandLabel;

  /// No description provided for @registrationMemberInfoFatherOrHusbandRequired.
  ///
  /// In bn, this message translates to:
  /// **'পিতা/স্বামী আবশ্যক'**
  String get registrationMemberInfoFatherOrHusbandRequired;

  /// No description provided for @registrationMemberInfoFullNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'পূর্ণ নাম'**
  String get registrationMemberInfoFullNameLabel;

  /// No description provided for @registrationMemberInfoFullNameRequired.
  ///
  /// In bn, this message translates to:
  /// **'পূর্ণ নাম আবশ্যক'**
  String get registrationMemberInfoFullNameRequired;

  /// No description provided for @registrationMemberInfoGenderFemale.
  ///
  /// In bn, this message translates to:
  /// **'মহিলা'**
  String get registrationMemberInfoGenderFemale;

  /// No description provided for @registrationMemberInfoGenderLabel.
  ///
  /// In bn, this message translates to:
  /// **'লিঙ্গ'**
  String get registrationMemberInfoGenderLabel;

  /// No description provided for @registrationMemberInfoGenderMale.
  ///
  /// In bn, this message translates to:
  /// **'পুরুষ'**
  String get registrationMemberInfoGenderMale;

  /// No description provided for @registrationMemberInfoGenderRequired.
  ///
  /// In bn, this message translates to:
  /// **'লিঙ্গ নির্বাচন করুন'**
  String get registrationMemberInfoGenderRequired;

  /// No description provided for @registrationMemberInfoMemberPhotoRequired.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের ছবি আবশ্যক'**
  String get registrationMemberInfoMemberPhotoRequired;

  /// No description provided for @registrationMemberInfoMobileInvalid.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)'**
  String get registrationMemberInfoMobileInvalid;

  /// No description provided for @registrationMemberInfoMobileLabel.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল (WhatsApp)'**
  String get registrationMemberInfoMobileLabel;

  /// No description provided for @registrationMemberInfoMobileRequired.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল আবশ্যক'**
  String get registrationMemberInfoMobileRequired;

  /// No description provided for @registrationMemberInfoMotherLabel.
  ///
  /// In bn, this message translates to:
  /// **'মাতা'**
  String get registrationMemberInfoMotherLabel;

  /// No description provided for @registrationMemberInfoMotherRequired.
  ///
  /// In bn, this message translates to:
  /// **'মাতা আবশ্যক'**
  String get registrationMemberInfoMotherRequired;

  /// No description provided for @registrationMemberInfoNationalityLabel.
  ///
  /// In bn, this message translates to:
  /// **'জাতীয়তা'**
  String get registrationMemberInfoNationalityLabel;

  /// No description provided for @registrationMemberInfoNidInvalid.
  ///
  /// In bn, this message translates to:
  /// **'NID নম্বর ১০-১৭ সংখ্যার হতে হবে'**
  String get registrationMemberInfoNidInvalid;

  /// No description provided for @registrationMemberInfoNidLabel.
  ///
  /// In bn, this message translates to:
  /// **'NID নং'**
  String get registrationMemberInfoNidLabel;

  /// No description provided for @registrationMemberInfoNidPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'১০-১৭ সংখ্যা'**
  String get registrationMemberInfoNidPlaceholder;

  /// No description provided for @registrationMemberInfoNidRequired.
  ///
  /// In bn, this message translates to:
  /// **'NID নম্বর আবশ্যক'**
  String get registrationMemberInfoNidRequired;

  /// No description provided for @registrationMemberInfoOccupationLabel.
  ///
  /// In bn, this message translates to:
  /// **'পেশা'**
  String get registrationMemberInfoOccupationLabel;

  /// No description provided for @registrationMemberInfoPhotoAlt.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের ছবি'**
  String get registrationMemberInfoPhotoAlt;

  /// No description provided for @registrationMemberInfoPhotoPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের ছবি'**
  String get registrationMemberInfoPhotoPlaceholder;

  /// No description provided for @registrationMemberInfoPhotoSizeError.
  ///
  /// In bn, this message translates to:
  /// **'ছবির সাইজ ৩ এমবি-এর কম হতে হবে'**
  String get registrationMemberInfoPhotoSizeError;

  /// No description provided for @registrationMemberInfoPhotoTypeError.
  ///
  /// In bn, this message translates to:
  /// **'ছবির ফাইল নির্বাচন করুন (JPG/PNG)'**
  String get registrationMemberInfoPhotoTypeError;

  /// No description provided for @registrationNavNext.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী'**
  String get registrationNavNext;

  /// No description provided for @registrationNavPrevious.
  ///
  /// In bn, this message translates to:
  /// **'পূর্ববর্তী'**
  String get registrationNavPrevious;

  /// No description provided for @registrationNavSubmit.
  ///
  /// In bn, this message translates to:
  /// **'ফর্ম সাবমিট করুন'**
  String get registrationNavSubmit;

  /// No description provided for @registrationNavSubmitting.
  ///
  /// In bn, this message translates to:
  /// **'সাবমিট হচ্ছে...'**
  String get registrationNavSubmitting;

  /// No description provided for @registrationNomineeAddMore.
  ///
  /// In bn, this message translates to:
  /// **'আরও মনোনীত ব্যক্তি যোগ করুন'**
  String get registrationNomineeAddMore;

  /// No description provided for @registrationNomineeAdditionalNomineesTitle.
  ///
  /// In bn, this message translates to:
  /// **'অতিরিক্ত মনোনীত ব্যক্তি'**
  String get registrationNomineeAdditionalNomineesTitle;

  /// No description provided for @registrationNomineeAddressLabel.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা'**
  String get registrationNomineeAddressLabel;

  /// No description provided for @registrationNomineeMobileInvalid.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)'**
  String get registrationNomineeMobileInvalid;

  /// No description provided for @registrationNomineeMobileLabel.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get registrationNomineeMobileLabel;

  /// No description provided for @registrationNomineeMobileRequired.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল আবশ্যক'**
  String get registrationNomineeMobileRequired;

  /// No description provided for @registrationNomineeNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get registrationNomineeNameLabel;

  /// No description provided for @registrationNomineeNameRequired.
  ///
  /// In bn, this message translates to:
  /// **'নাম আবশ্যক'**
  String get registrationNomineeNameRequired;

  /// No description provided for @registrationNomineeNomineeNumberTitle.
  ///
  /// In bn, this message translates to:
  /// **'মনোনীত ব্যক্তি {number}'**
  String registrationNomineeNomineeNumberTitle(Object number);

  /// No description provided for @registrationNomineeRelationLabel.
  ///
  /// In bn, this message translates to:
  /// **'পিতা/স্বামী / সম্পর্ক'**
  String get registrationNomineeRelationLabel;

  /// No description provided for @registrationNomineeRelationShortLabel.
  ///
  /// In bn, this message translates to:
  /// **'সম্পর্ক'**
  String get registrationNomineeRelationShortLabel;

  /// No description provided for @registrationNomineeRemove.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get registrationNomineeRemove;

  /// No description provided for @registrationNomineeSameAsUrgentContactLabel.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগের তথ্য থেকে একই তথ্য ব্যবহার করুন'**
  String get registrationNomineeSameAsUrgentContactLabel;

  /// No description provided for @registrationPaymentAccountNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'হিসাবের নাম'**
  String get registrationPaymentAccountNameLabel;

  /// No description provided for @registrationPaymentAccountNumberLabel.
  ///
  /// In bn, this message translates to:
  /// **'হিসাব নং'**
  String get registrationPaymentAccountNumberLabel;

  /// No description provided for @registrationPaymentAdmissionFeeHint.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ভর্তি ফি — সংগঠন কর্তৃক নির্ধারিত, এখানে পরিবর্তনযোগ্য নয়'**
  String get registrationPaymentAdmissionFeeHint;

  /// No description provided for @registrationPaymentAdmissionFeeLabel.
  ///
  /// In bn, this message translates to:
  /// **'ভর্তি ফি (টাকা)'**
  String get registrationPaymentAdmissionFeeLabel;

  /// No description provided for @registrationPaymentAdmissionFeeLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ভর্তি ফি লোড করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।'**
  String get registrationPaymentAdmissionFeeLoadFailed;

  /// No description provided for @registrationPaymentAdmissionFeeLoading.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ভর্তি ফি লোড হচ্ছে…'**
  String get registrationPaymentAdmissionFeeLoading;

  /// No description provided for @registrationPaymentAdmissionFeeRequired.
  ///
  /// In bn, this message translates to:
  /// **'ভর্তি ফি আবশ্যক'**
  String get registrationPaymentAdmissionFeeRequired;

  /// No description provided for @registrationPaymentAdmissionFeeRetry.
  ///
  /// In bn, this message translates to:
  /// **'পুনরায় চেষ্টা'**
  String get registrationPaymentAdmissionFeeRetry;

  /// No description provided for @registrationPaymentAttachReceipt.
  ///
  /// In bn, this message translates to:
  /// **'রসিদের ছবি সংযুক্ত করুন'**
  String get registrationPaymentAttachReceipt;

  /// No description provided for @registrationPaymentBankNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'ব্যাংক'**
  String get registrationPaymentBankNameLabel;

  /// No description provided for @registrationPaymentBranchLabel.
  ///
  /// In bn, this message translates to:
  /// **'শাখা'**
  String get registrationPaymentBranchLabel;

  /// No description provided for @registrationPaymentFileSizeError.
  ///
  /// In bn, this message translates to:
  /// **'ফাইলের সাইজ সর্বোচ্চ {maxMb} এমবি হতে হবে'**
  String registrationPaymentFileSizeError(Object maxMb);

  /// No description provided for @registrationPaymentFileTypeError.
  ///
  /// In bn, this message translates to:
  /// **'শুধুমাত্র JPG, PNG বা PDF ফাইল গ্রহণযোগ্য'**
  String get registrationPaymentFileTypeError;

  /// No description provided for @registrationPaymentMaxFileSizeHint.
  ///
  /// In bn, this message translates to:
  /// **'সর্বোচ্চ {maxMb} এমবি (JPG/PNG/PDF)'**
  String registrationPaymentMaxFileSizeHint(Object maxMb);

  /// No description provided for @registrationPaymentMethodLabel.
  ///
  /// In bn, this message translates to:
  /// **'মাধ্যম'**
  String get registrationPaymentMethodLabel;

  /// No description provided for @registrationPaymentMfsNumberLabel.
  ///
  /// In bn, this message translates to:
  /// **'MFS নম্বর'**
  String get registrationPaymentMfsNumberLabel;

  /// No description provided for @registrationPaymentPaymentMethodRequired.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট মাধ্যম আবশ্যক'**
  String get registrationPaymentPaymentMethodRequired;

  /// No description provided for @registrationPaymentReceiptImageLabel.
  ///
  /// In bn, this message translates to:
  /// **'মানি রসিদের ছবি'**
  String get registrationPaymentReceiptImageLabel;

  /// No description provided for @registrationPaymentReceiptNoLabel.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ নং/Transaction ID'**
  String get registrationPaymentReceiptNoLabel;

  /// No description provided for @registrationPaymentRemoveFile.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get registrationPaymentRemoveFile;

  /// No description provided for @registrationPaymentRoutingNumberLabel.
  ///
  /// In bn, this message translates to:
  /// **'রাউটিং নং'**
  String get registrationPaymentRoutingNumberLabel;

  /// No description provided for @registrationPaymentSubscriptionBaseSummary.
  ///
  /// In bn, this message translates to:
  /// **'ভিত্তি: {amount} টাকা'**
  String registrationPaymentSubscriptionBaseSummary(Object amount);

  /// No description provided for @registrationPaymentSubscriptionExtraSummary.
  ///
  /// In bn, this message translates to:
  /// **'+ অতিরিক্ত {extra}টি শতাংশ (আংশিক শতাংশও পূর্ণ ধরা হয়) = {amount} টাকা'**
  String registrationPaymentSubscriptionExtraSummary(
      Object amount, Object extra);

  /// No description provided for @registrationPaymentSubscriptionHint.
  ///
  /// In bn, this message translates to:
  /// **'সংগঠন কর্তৃক নির্ধারিত, এখানে পরিবর্তনযোগ্য নয়'**
  String get registrationPaymentSubscriptionHint;

  /// No description provided for @registrationPaymentSubscriptionLabel.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদা (টাকা)'**
  String get registrationPaymentSubscriptionLabel;

  /// No description provided for @registrationPaymentSubscriptionLoadFailed.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদার পরিমাণ হিসাব করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।'**
  String get registrationPaymentSubscriptionLoadFailed;

  /// No description provided for @registrationPaymentSubscriptionLoading.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদার পরিমাণ হিসাব করা হচ্ছে…'**
  String get registrationPaymentSubscriptionLoading;

  /// No description provided for @registrationPaymentSubscriptionRequired.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদা আবশ্যক'**
  String get registrationPaymentSubscriptionRequired;

  /// No description provided for @registrationPaymentSubscriptionRetry.
  ///
  /// In bn, this message translates to:
  /// **'পুনরায় চেষ্টা'**
  String get registrationPaymentSubscriptionRetry;

  /// No description provided for @registrationPaymentTotalAmountSummary.
  ///
  /// In bn, this message translates to:
  /// **'= মোট {amount}৳'**
  String registrationPaymentTotalAmountSummary(Object amount);

  /// No description provided for @registrationPropertyApplicableDocsLabel.
  ///
  /// In bn, this message translates to:
  /// **'প্রযোজ্য কাগজ'**
  String get registrationPropertyApplicableDocsLabel;

  /// No description provided for @registrationPropertyApplicableDocsRequired.
  ///
  /// In bn, this message translates to:
  /// **'প্রযোজ্য কাগজ নির্বাচন আবশ্যক'**
  String get registrationPropertyApplicableDocsRequired;

  /// No description provided for @registrationPropertyAttachFileButton.
  ///
  /// In bn, this message translates to:
  /// **'ফাইল সংযুক্ত করুন'**
  String get registrationPropertyAttachFileButton;

  /// No description provided for @registrationPropertyCountLabel.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তির সংখ্যা'**
  String get registrationPropertyCountLabel;

  /// No description provided for @registrationPropertyCountSelectPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'নির্বাচন করুন'**
  String get registrationPropertyCountSelectPlaceholder;

  /// No description provided for @registrationPropertyDagCsLabel.
  ///
  /// In bn, this message translates to:
  /// **'সিএস দাগ নং'**
  String get registrationPropertyDagCsLabel;

  /// No description provided for @registrationPropertyDagNoCsRequired.
  ///
  /// In bn, this message translates to:
  /// **'CS দাগ নং আবশ্যক'**
  String get registrationPropertyDagNoCsRequired;

  /// No description provided for @registrationPropertyDagNoLabel.
  ///
  /// In bn, this message translates to:
  /// **'দাগ নং'**
  String get registrationPropertyDagNoLabel;

  /// No description provided for @registrationPropertyDagNoRsRequired.
  ///
  /// In bn, this message translates to:
  /// **'RS দাগ নং আবশ্যক'**
  String get registrationPropertyDagNoRsRequired;

  /// No description provided for @registrationPropertyDagRsLabel.
  ///
  /// In bn, this message translates to:
  /// **'আরএস দাগ নং'**
  String get registrationPropertyDagRsLabel;

  /// No description provided for @registrationPropertyDocFileMissing.
  ///
  /// In bn, this message translates to:
  /// **'এই কাগজের ফাইল সংযুক্ত করা আবশ্যক'**
  String get registrationPropertyDocFileMissing;

  /// No description provided for @registrationPropertyDocFileSizeError.
  ///
  /// In bn, this message translates to:
  /// **'ফাইলের সাইজ সর্বোচ্চ {maxMb} এমবি হতে হবে'**
  String registrationPropertyDocFileSizeError(Object maxMb);

  /// No description provided for @registrationPropertyDocFileTypeError.
  ///
  /// In bn, this message translates to:
  /// **'শুধুমাত্র JPG, PNG বা PDF ফাইল গ্রহণযোগ্য'**
  String get registrationPropertyDocFileTypeError;

  /// No description provided for @registrationPropertyHoldingNumberLabel.
  ///
  /// In bn, this message translates to:
  /// **'হোল্ডিং নম্বর'**
  String get registrationPropertyHoldingNumberLabel;

  /// No description provided for @registrationPropertyItemTitle.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি'**
  String get registrationPropertyItemTitle;

  /// No description provided for @registrationPropertyJointOwnerCountLabel.
  ///
  /// In bn, this message translates to:
  /// **'যৌথ মালিকগণের সংখ্যা'**
  String get registrationPropertyJointOwnerCountLabel;

  /// No description provided for @registrationPropertyJointOwnerCountRequired.
  ///
  /// In bn, this message translates to:
  /// **'যৌথ মালিকগণের সংখ্যা আবশ্যক'**
  String get registrationPropertyJointOwnerCountRequired;

  /// No description provided for @registrationPropertyKhatianNoLabel.
  ///
  /// In bn, this message translates to:
  /// **'খতিয়ান নং'**
  String get registrationPropertyKhatianNoLabel;

  /// No description provided for @registrationPropertyKhatianNoRequired.
  ///
  /// In bn, this message translates to:
  /// **'খতিয়ান নং আবশ্যক'**
  String get registrationPropertyKhatianNoRequired;

  /// No description provided for @registrationPropertyLandQuantityInvalid.
  ///
  /// In bn, this message translates to:
  /// **'মোট জমির পরিমাণ শূন্যের চেয়ে বেশি হতে হবে'**
  String get registrationPropertyLandQuantityInvalid;

  /// No description provided for @registrationPropertyLandQuantityLabel.
  ///
  /// In bn, this message translates to:
  /// **'মোট জমির পরিমাণ (শতাংশ):'**
  String get registrationPropertyLandQuantityLabel;

  /// No description provided for @registrationPropertyLandQuantityPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: ২.৫'**
  String get registrationPropertyLandQuantityPlaceholder;

  /// No description provided for @registrationPropertyLandQuantityRequired.
  ///
  /// In bn, this message translates to:
  /// **'মোট জমির পরিমাণ আবশ্যক'**
  String get registrationPropertyLandQuantityRequired;

  /// No description provided for @registrationPropertyMaxFileSizeNote.
  ///
  /// In bn, this message translates to:
  /// **'সর্বোচ্চ {maxMb} এমবি (JPG/PNG/PDF)'**
  String registrationPropertyMaxFileSizeNote(Object maxMb);

  /// No description provided for @registrationPropertyMyShareQuantityExceedsTotal.
  ///
  /// In bn, this message translates to:
  /// **'আমার অংশের পরিমাণ মোট জমির পরিমাণের চেয়ে বেশি হতে পারবে না'**
  String get registrationPropertyMyShareQuantityExceedsTotal;

  /// No description provided for @registrationPropertyMyShareQuantityInvalid.
  ///
  /// In bn, this message translates to:
  /// **'আমার অংশের পরিমাণ শূন্যের চেয়ে বেশি হতে হবে'**
  String get registrationPropertyMyShareQuantityInvalid;

  /// No description provided for @registrationPropertyMyShareQuantityLabel.
  ///
  /// In bn, this message translates to:
  /// **'আমার অংশের পরিমাণ (শতাংশ):'**
  String get registrationPropertyMyShareQuantityLabel;

  /// No description provided for @registrationPropertyMyShareQuantityPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: ১.২৫'**
  String get registrationPropertyMyShareQuantityPlaceholder;

  /// No description provided for @registrationPropertyMyShareQuantityRequired.
  ///
  /// In bn, this message translates to:
  /// **'আমার অংশের পরিমাণ আবশ্যক'**
  String get registrationPropertyMyShareQuantityRequired;

  /// No description provided for @registrationPropertyOwnershipLabel.
  ///
  /// In bn, this message translates to:
  /// **'মালিকানা'**
  String get registrationPropertyOwnershipLabel;

  /// No description provided for @registrationPropertyOwnershipRequired.
  ///
  /// In bn, this message translates to:
  /// **'মালিকানা আবশ্যক'**
  String get registrationPropertyOwnershipRequired;

  /// No description provided for @registrationPropertyRemoveFileButton.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get registrationPropertyRemoveFileButton;

  /// No description provided for @registrationPropertyTypeLabel.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তির ধরন'**
  String get registrationPropertyTypeLabel;

  /// No description provided for @registrationPropertyTypeOtherPlaceholder.
  ///
  /// In bn, this message translates to:
  /// **'বিস্তারিত লিখুন'**
  String get registrationPropertyTypeOtherPlaceholder;

  /// No description provided for @registrationPropertyTypeRequired.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তির ধরন আবশ্যক'**
  String get registrationPropertyTypeRequired;

  /// No description provided for @registrationReviewDeclarationAccepted.
  ///
  /// In bn, this message translates to:
  /// **'সম্মতি প্রদান করা হয়েছে'**
  String get registrationReviewDeclarationAccepted;

  /// No description provided for @registrationReviewDeclarationNotAccepted.
  ///
  /// In bn, this message translates to:
  /// **'সম্মতি প্রদান করা হয়নি'**
  String get registrationReviewDeclarationNotAccepted;

  /// No description provided for @registrationReviewDeclarationTitle.
  ///
  /// In bn, this message translates to:
  /// **'অঙ্গীকার'**
  String get registrationReviewDeclarationTitle;

  /// No description provided for @registrationReviewEdit.
  ///
  /// In bn, this message translates to:
  /// **'সম্পাদনা করুন'**
  String get registrationReviewEdit;

  /// No description provided for @registrationReviewEmailLabel.
  ///
  /// In bn, this message translates to:
  /// **'ই-মেইল'**
  String get registrationReviewEmailLabel;

  /// No description provided for @registrationReviewFatherOrHusbandLabel.
  ///
  /// In bn, this message translates to:
  /// **'পিতা/স্বামী'**
  String get registrationReviewFatherOrHusbandLabel;

  /// No description provided for @registrationReviewIntro.
  ///
  /// In bn, this message translates to:
  /// **'সাবমিট করার আগে নিচের তথ্যগুলো যাচাই করে নিন।'**
  String get registrationReviewIntro;

  /// No description provided for @registrationReviewMemberInfoTitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের তথ্য'**
  String get registrationReviewMemberInfoTitle;

  /// No description provided for @registrationReviewMethodLabel.
  ///
  /// In bn, this message translates to:
  /// **'মাধ্যম'**
  String get registrationReviewMethodLabel;

  /// No description provided for @registrationReviewMobileLabel.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get registrationReviewMobileLabel;

  /// No description provided for @registrationReviewNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get registrationReviewNameLabel;

  /// No description provided for @registrationReviewNomineeCountLabel.
  ///
  /// In bn, this message translates to:
  /// **'নমিনি সংখ্যা'**
  String get registrationReviewNomineeCountLabel;

  /// No description provided for @registrationReviewNomineeCountSummary.
  ///
  /// In bn, this message translates to:
  /// **'{count} জন'**
  String registrationReviewNomineeCountSummary(Object count);

  /// No description provided for @registrationReviewPaymentInfoTitle.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট তথ্য'**
  String get registrationReviewPaymentInfoTitle;

  /// No description provided for @registrationReviewPropertyInfoTitle.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তির তথ্য'**
  String get registrationReviewPropertyInfoTitle;

  /// No description provided for @registrationReviewSubscriptionLabel.
  ///
  /// In bn, this message translates to:
  /// **'চাঁদা'**
  String get registrationReviewSubscriptionLabel;

  /// No description provided for @registrationReviewTotalPropertiesSummary.
  ///
  /// In bn, this message translates to:
  /// **'মোট সম্পত্তি: {count} টি'**
  String registrationReviewTotalPropertiesSummary(Object count);

  /// No description provided for @registrationReviewUrgentContactAndNomineeTitle.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগ ও নমিনি'**
  String get registrationReviewUrgentContactAndNomineeTitle;

  /// No description provided for @registrationReviewUrgentContactLabel.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগ'**
  String get registrationReviewUrgentContactLabel;

  /// No description provided for @registrationSignatureSectionTitle.
  ///
  /// In bn, this message translates to:
  /// **'স্বাক্ষর'**
  String get registrationSignatureSectionTitle;

  /// No description provided for @registrationSignatureHint.
  ///
  /// In bn, this message translates to:
  /// **'নিচের বাক্সে স্বাক্ষর আঁকুন'**
  String get registrationSignatureHint;

  /// No description provided for @registrationSignatureClearButton.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলুন'**
  String get registrationSignatureClearButton;

  /// No description provided for @registrationSignatureSaveButton.
  ///
  /// In bn, this message translates to:
  /// **'স্বাক্ষর সংরক্ষণ'**
  String get registrationSignatureSaveButton;

  /// No description provided for @registrationSignatureSavedButton.
  ///
  /// In bn, this message translates to:
  /// **'স্বাক্ষর সংরক্ষিত'**
  String get registrationSignatureSavedButton;

  /// No description provided for @registrationStepShortLabelsMemberInfo.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get registrationStepShortLabelsMemberInfo;

  /// No description provided for @registrationStepShortLabelsNominee.
  ///
  /// In bn, this message translates to:
  /// **'নমিনি'**
  String get registrationStepShortLabelsNominee;

  /// No description provided for @registrationStepShortLabelsPayment.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট'**
  String get registrationStepShortLabelsPayment;

  /// No description provided for @registrationStepShortLabelsProperty.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি'**
  String get registrationStepShortLabelsProperty;

  /// No description provided for @registrationStepShortLabelsReview.
  ///
  /// In bn, this message translates to:
  /// **'পর্যালোচনা'**
  String get registrationStepShortLabelsReview;

  /// No description provided for @registrationStepShortLabelsSignature.
  ///
  /// In bn, this message translates to:
  /// **'স্বাক্ষর'**
  String get registrationStepShortLabelsSignature;

  /// No description provided for @registrationStepTitlesAddressInfo.
  ///
  /// In bn, this message translates to:
  /// **'২. ঠিকানার তথ্য'**
  String get registrationStepTitlesAddressInfo;

  /// No description provided for @registrationStepTitlesContactAndNominee.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগ ও নমিনি'**
  String get registrationStepTitlesContactAndNominee;

  /// No description provided for @registrationStepTitlesDeclarationAndSignature.
  ///
  /// In bn, this message translates to:
  /// **'অঙ্গীকার ও স্বাক্ষর'**
  String get registrationStepTitlesDeclarationAndSignature;

  /// No description provided for @registrationStepTitlesMemberInfo.
  ///
  /// In bn, this message translates to:
  /// **'১. সদস্যের ব্যক্তিগত তথ্য'**
  String get registrationStepTitlesMemberInfo;

  /// No description provided for @registrationStepTitlesNominee.
  ///
  /// In bn, this message translates to:
  /// **'৫. নমিনি'**
  String get registrationStepTitlesNominee;

  /// No description provided for @registrationStepTitlesPayment.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্টের তথ্য'**
  String get registrationStepTitlesPayment;

  /// No description provided for @registrationStepTitlesProperty.
  ///
  /// In bn, this message translates to:
  /// **'৩. আবাসন / সম্পত্তির মালিকানা তথ্য'**
  String get registrationStepTitlesProperty;

  /// No description provided for @registrationStepTitlesReview.
  ///
  /// In bn, this message translates to:
  /// **'পর্যালোচনা'**
  String get registrationStepTitlesReview;

  /// No description provided for @registrationStepTitlesUrgentContact.
  ///
  /// In bn, this message translates to:
  /// **'৪. জরুরি যোগাযোগ'**
  String get registrationStepTitlesUrgentContact;

  /// No description provided for @registrationSubmitDuplicateApproved.
  ///
  /// In bn, this message translates to:
  /// **'আপনি ইতিমধ্যে সদস্য হিসেবে নিবন্ধিত। অনুগ্রহ করে লগইন করুন।'**
  String get registrationSubmitDuplicateApproved;

  /// No description provided for @registrationSubmitDuplicateGeneric.
  ///
  /// In bn, this message translates to:
  /// **'এই তথ্য দিয়ে একটি আবেদন ইতিমধ্যে বিদ্যমান।'**
  String get registrationSubmitDuplicateGeneric;

  /// No description provided for @registrationSubmitDuplicatePending.
  ///
  /// In bn, this message translates to:
  /// **'আপনার আবেদনটি অপেক্ষমাণ। অনুগ্রহ করে নিশ্চিতকরণের জন্য অপেক্ষা করুন।'**
  String get registrationSubmitDuplicatePending;

  /// No description provided for @registrationSubmitDuplicateTitle.
  ///
  /// In bn, this message translates to:
  /// **'আবেদন ইতিমধ্যে বিদ্যমান'**
  String get registrationSubmitDuplicateTitle;

  /// No description provided for @registrationSubmitErrorCode.
  ///
  /// In bn, this message translates to:
  /// **'কোড {status}'**
  String registrationSubmitErrorCode(Object status);

  /// No description provided for @registrationSubmitFeeNotConfigured.
  ///
  /// In bn, this message translates to:
  /// **'ভর্তি ফি এখনো নির্ধারণ করা হয়নি। অনুগ্রহ করে অফিসে যোগাযোগ করুন।'**
  String get registrationSubmitFeeNotConfigured;

  /// No description provided for @registrationSubmitFieldsAdmissionFee.
  ///
  /// In bn, this message translates to:
  /// **'ভর্তি ফি'**
  String get registrationSubmitFieldsAdmissionFee;

  /// No description provided for @registrationSubmitFieldsCurrentAddress.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ঠিকানা'**
  String get registrationSubmitFieldsCurrentAddress;

  /// No description provided for @registrationSubmitFieldsDob.
  ///
  /// In bn, this message translates to:
  /// **'জন্ম তারিখ'**
  String get registrationSubmitFieldsDob;

  /// No description provided for @registrationSubmitFieldsEmail.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get registrationSubmitFieldsEmail;

  /// No description provided for @registrationSubmitFieldsFatherOrHusband.
  ///
  /// In bn, this message translates to:
  /// **'পিতা/স্বামীর নাম'**
  String get registrationSubmitFieldsFatherOrHusband;

  /// No description provided for @registrationSubmitFieldsFullName.
  ///
  /// In bn, this message translates to:
  /// **'পূর্ণ নাম'**
  String get registrationSubmitFieldsFullName;

  /// No description provided for @registrationSubmitFieldsGender.
  ///
  /// In bn, this message translates to:
  /// **'লিঙ্গ'**
  String get registrationSubmitFieldsGender;

  /// No description provided for @registrationSubmitFieldsMemberSignature.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের স্বাক্ষর'**
  String get registrationSubmitFieldsMemberSignature;

  /// No description provided for @registrationSubmitFieldsMobile.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get registrationSubmitFieldsMobile;

  /// No description provided for @registrationSubmitFieldsMother.
  ///
  /// In bn, this message translates to:
  /// **'মাতার নাম'**
  String get registrationSubmitFieldsMother;

  /// No description provided for @registrationSubmitFieldsNationality.
  ///
  /// In bn, this message translates to:
  /// **'জাতীয়তা'**
  String get registrationSubmitFieldsNationality;

  /// No description provided for @registrationSubmitFieldsNid.
  ///
  /// In bn, this message translates to:
  /// **'জাতীয় পরিচয়পত্র নম্বর'**
  String get registrationSubmitFieldsNid;

  /// No description provided for @registrationSubmitFieldsNominees.
  ///
  /// In bn, this message translates to:
  /// **'নমিনি'**
  String get registrationSubmitFieldsNominees;

  /// No description provided for @registrationSubmitFieldsOccupation.
  ///
  /// In bn, this message translates to:
  /// **'পেশা'**
  String get registrationSubmitFieldsOccupation;

  /// No description provided for @registrationSubmitFieldsPaymentMethod.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধের মাধ্যম'**
  String get registrationSubmitFieldsPaymentMethod;

  /// No description provided for @registrationSubmitFieldsPermanentAddress.
  ///
  /// In bn, this message translates to:
  /// **'স্থায়ী ঠিকানা'**
  String get registrationSubmitFieldsPermanentAddress;

  /// No description provided for @registrationSubmitFieldsProperties.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি'**
  String get registrationSubmitFieldsProperties;

  /// No description provided for @registrationSubmitFieldsReceiptNo.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ নম্বর'**
  String get registrationSubmitFieldsReceiptNo;

  /// No description provided for @registrationSubmitFieldsSubmissionDate.
  ///
  /// In bn, this message translates to:
  /// **'নিবন্ধনের তারিখ'**
  String get registrationSubmitFieldsSubmissionDate;

  /// No description provided for @registrationSubmitFieldsSubscription.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক চাঁদা'**
  String get registrationSubmitFieldsSubscription;

  /// No description provided for @registrationSubmitFieldsUrgentContactAddress.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগের ঠিকানা'**
  String get registrationSubmitFieldsUrgentContactAddress;

  /// No description provided for @registrationSubmitFieldsUrgentContactMobile.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগের মোবাইল'**
  String get registrationSubmitFieldsUrgentContactMobile;

  /// No description provided for @registrationSubmitFieldsUrgentContactName.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগের নাম'**
  String get registrationSubmitFieldsUrgentContactName;

  /// No description provided for @registrationSubmitFieldsUrgentContactRelation.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগের সম্পর্ক'**
  String get registrationSubmitFieldsUrgentContactRelation;

  /// No description provided for @registrationSubmitFileTooLarge.
  ///
  /// In bn, this message translates to:
  /// **'আপলোড করা ছবি বা ফাইল খুব বড়। ছোট ফাইল দিন (সর্বোচ্চ ১০ MB)।'**
  String get registrationSubmitFileTooLarge;

  /// No description provided for @registrationSubmitGenericError.
  ///
  /// In bn, this message translates to:
  /// **'সাবমিটে সমস্যা হয়েছে'**
  String get registrationSubmitGenericError;

  /// No description provided for @registrationSubmitInvalidData.
  ///
  /// In bn, this message translates to:
  /// **'কিছু তথ্য বা আপলোড করা ফাইল সঠিক নয়। যাচাই করে আবার চেষ্টা করুন।'**
  String get registrationSubmitInvalidData;

  /// No description provided for @registrationSubmitInvalidShareQuantity.
  ///
  /// In bn, this message translates to:
  /// **'জমির অংশের পরিমাণ সঠিক নয়। সম্পত্তির ধাপটি যাচাই করুন।'**
  String get registrationSubmitInvalidShareQuantity;

  /// No description provided for @registrationSubmitNetworkError.
  ///
  /// In bn, this message translates to:
  /// **'নেটওয়ার্কে সমস্যা। অনুগ্রহ করে আবার চেষ্টা করুন।'**
  String get registrationSubmitNetworkError;

  /// No description provided for @registrationSubmitReasonsInvalid.
  ///
  /// In bn, this message translates to:
  /// **'তথ্যটি সঠিক নয়'**
  String get registrationSubmitReasonsInvalid;

  /// No description provided for @registrationSubmitReasonsRequired.
  ///
  /// In bn, this message translates to:
  /// **'এই তথ্যটি আবশ্যক'**
  String get registrationSubmitReasonsRequired;

  /// No description provided for @registrationSubmitServerError.
  ///
  /// In bn, this message translates to:
  /// **'সার্ভারে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।'**
  String get registrationSubmitServerError;

  /// No description provided for @registrationUrgentContactAddressLabel.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা'**
  String get registrationUrgentContactAddressLabel;

  /// No description provided for @registrationUrgentContactMobileInvalid.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)'**
  String get registrationUrgentContactMobileInvalid;

  /// No description provided for @registrationUrgentContactMobileLabel.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get registrationUrgentContactMobileLabel;

  /// No description provided for @registrationUrgentContactMobileRequired.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল আবশ্যক'**
  String get registrationUrgentContactMobileRequired;

  /// No description provided for @registrationUrgentContactNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get registrationUrgentContactNameLabel;

  /// No description provided for @registrationUrgentContactNameRequired.
  ///
  /// In bn, this message translates to:
  /// **'নাম আবশ্যক'**
  String get registrationUrgentContactNameRequired;

  /// No description provided for @registrationUrgentContactRelationLabel.
  ///
  /// In bn, this message translates to:
  /// **'সম্পর্ক'**
  String get registrationUrgentContactRelationLabel;

  /// No description provided for @registrationValidationApplicableDocsRequired.
  ///
  /// In bn, this message translates to:
  /// **'প্রযোজ্য কাগজ নির্বাচন আবশ্যক'**
  String get registrationValidationApplicableDocsRequired;

  /// No description provided for @registrationValidationCurrentAddressLabel.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ঠিকানা'**
  String get registrationValidationCurrentAddressLabel;

  /// No description provided for @registrationValidationDobRequired.
  ///
  /// In bn, this message translates to:
  /// **'জন্ম তারিখ আবশ্যক'**
  String get registrationValidationDobRequired;

  /// No description provided for @registrationValidationDocFileRequired.
  ///
  /// In bn, this message translates to:
  /// **'\"{docType}\" এর জন্য ফাইল সংযুক্ত করা আবশ্যক'**
  String registrationValidationDocFileRequired(Object docType);

  /// No description provided for @registrationValidationEmailInvalid.
  ///
  /// In bn, this message translates to:
  /// **'ই-মেইল সঠিক নয়'**
  String get registrationValidationEmailInvalid;

  /// No description provided for @registrationValidationFatherOrHusbandRequired.
  ///
  /// In bn, this message translates to:
  /// **'পিতা/স্বামী আবশ্যক'**
  String get registrationValidationFatherOrHusbandRequired;

  /// No description provided for @registrationValidationFullNameRequired.
  ///
  /// In bn, this message translates to:
  /// **'পূর্ণ নাম আবশ্যক'**
  String get registrationValidationFullNameRequired;

  /// No description provided for @registrationValidationGenderRequired.
  ///
  /// In bn, this message translates to:
  /// **'লিঙ্গ নির্বাচন করুন'**
  String get registrationValidationGenderRequired;

  /// No description provided for @registrationValidationJointOwnerCountRequired.
  ///
  /// In bn, this message translates to:
  /// **'যৌথ মালিকগণের সংখ্যা আবশ্যক'**
  String get registrationValidationJointOwnerCountRequired;

  /// No description provided for @registrationValidationLandQuantityInvalid.
  ///
  /// In bn, this message translates to:
  /// **'মোট জমির পরিমাণ শূন্যের চেয়ে বেশি হতে হবে'**
  String get registrationValidationLandQuantityInvalid;

  /// No description provided for @registrationValidationLandQuantityRequired.
  ///
  /// In bn, this message translates to:
  /// **'মোট জমির পরিমাণ আবশ্যক'**
  String get registrationValidationLandQuantityRequired;

  /// No description provided for @registrationValidationMobileInvalid.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)'**
  String get registrationValidationMobileInvalid;

  /// No description provided for @registrationValidationMobileRequired.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল আবশ্যক'**
  String get registrationValidationMobileRequired;

  /// No description provided for @registrationValidationMotherRequired.
  ///
  /// In bn, this message translates to:
  /// **'মাতা আবশ্যক'**
  String get registrationValidationMotherRequired;

  /// No description provided for @registrationValidationMyShareQuantityExceedsTotal.
  ///
  /// In bn, this message translates to:
  /// **'আমার অংশের পরিমাণ মোট জমির পরিমাণের চেয়ে বেশি হতে পারবে না'**
  String get registrationValidationMyShareQuantityExceedsTotal;

  /// No description provided for @registrationValidationMyShareQuantityInvalid.
  ///
  /// In bn, this message translates to:
  /// **'আমার অংশের পরিমাণ শূন্যের চেয়ে বেশি হতে হবে'**
  String get registrationValidationMyShareQuantityInvalid;

  /// No description provided for @registrationValidationMyShareQuantityRequired.
  ///
  /// In bn, this message translates to:
  /// **'আমার অংশের পরিমাণ আবশ্যক'**
  String get registrationValidationMyShareQuantityRequired;

  /// No description provided for @registrationValidationNameRequired.
  ///
  /// In bn, this message translates to:
  /// **'নাম আবশ্যক'**
  String get registrationValidationNameRequired;

  /// No description provided for @registrationValidationNidInvalid.
  ///
  /// In bn, this message translates to:
  /// **'NID নম্বর ১০-১৭ সংখ্যার হতে হবে'**
  String get registrationValidationNidInvalid;

  /// No description provided for @registrationValidationNomineeLabel.
  ///
  /// In bn, this message translates to:
  /// **'মনোনীত ব্যক্তি #{number}'**
  String registrationValidationNomineeLabel(Object number);

  /// No description provided for @registrationValidationOwnershipRequired.
  ///
  /// In bn, this message translates to:
  /// **'মালিকানা আবশ্যক'**
  String get registrationValidationOwnershipRequired;

  /// No description provided for @registrationValidationPermanentAddressLabel.
  ///
  /// In bn, this message translates to:
  /// **'স্থায়ী ঠিকানা'**
  String get registrationValidationPermanentAddressLabel;

  /// No description provided for @registrationValidationPropertyCountRequired.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তির সংখ্যা নির্বাচন করুন'**
  String get registrationValidationPropertyCountRequired;

  /// No description provided for @registrationValidationPropertyLabel.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তি #{number}'**
  String registrationValidationPropertyLabel(Object number);

  /// No description provided for @registrationValidationPropertyTypeRequired.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তির ধরন আবশ্যক'**
  String get registrationValidationPropertyTypeRequired;

  /// No description provided for @registrationValidationUrgentContactLabel.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি যোগাযোগ'**
  String get registrationValidationUrgentContactLabel;

  /// No description provided for @welcome.
  ///
  /// In bn, this message translates to:
  /// **'স্বাগতম, {name}'**
  String welcome(Object name);

  /// No description provided for @brandOrgName.
  ///
  /// In bn, this message translates to:
  /// **'উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সমিতি'**
  String get brandOrgName;

  /// No description provided for @commonLogout.
  ///
  /// In bn, this message translates to:
  /// **'লগ আউট'**
  String get commonLogout;

  /// No description provided for @commonLanguage.
  ///
  /// In bn, this message translates to:
  /// **'ভাষা'**
  String get commonLanguage;

  /// No description provided for @commonTheme.
  ///
  /// In bn, this message translates to:
  /// **'থিম'**
  String get commonTheme;

  /// No description provided for @commonStatusPending.
  ///
  /// In bn, this message translates to:
  /// **'অপেক্ষমাণ'**
  String get commonStatusPending;

  /// No description provided for @commonStatusApproved.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদিত'**
  String get commonStatusApproved;

  /// No description provided for @commonStatusRejected.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যাখ্যাত'**
  String get commonStatusRejected;

  /// No description provided for @commonNoData.
  ///
  /// In bn, this message translates to:
  /// **'কোনো তথ্য পাওয়া যায়নি'**
  String get commonNoData;

  /// No description provided for @commonNetworkError.
  ///
  /// In bn, this message translates to:
  /// **'নেটওয়ার্ক সমস্যা — আবার চেষ্টা করুন'**
  String get commonNetworkError;

  /// No description provided for @commonServerError.
  ///
  /// In bn, this message translates to:
  /// **'সার্ভারে সমস্যা হয়েছে — কিছুক্ষণ পরে চেষ্টা করুন'**
  String get commonServerError;

  /// No description provided for @commonUnauthorized.
  ///
  /// In bn, this message translates to:
  /// **'অনুমতি নেই — আবার লগ ইন করুন'**
  String get commonUnauthorized;

  /// No description provided for @commonConfirmAction.
  ///
  /// In bn, this message translates to:
  /// **'নিশ্চিত করুন'**
  String get commonConfirmAction;

  /// No description provided for @superadminTabsRoles.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা'**
  String get superadminTabsRoles;

  /// No description provided for @superadminTabsUsers.
  ///
  /// In bn, this message translates to:
  /// **'ব্যবহারকারী'**
  String get superadminTabsUsers;

  /// No description provided for @superadminRolesEmpty.
  ///
  /// In bn, this message translates to:
  /// **'কোনো ভূমিকা পাওয়া যায়নি।'**
  String get superadminRolesEmpty;

  /// No description provided for @superadminUsersEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনও কোনো অ্যাডমিনিস্ট্রেটর নেই।'**
  String get superadminUsersEmpty;

  /// No description provided for @superadminRoleAdministrator.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাডমিনিস্ট্রেটর'**
  String get superadminRoleAdministrator;

  /// No description provided for @superadminRoleExecutiveCommittee.
  ///
  /// In bn, this message translates to:
  /// **'নির্বাহী কমিটি'**
  String get superadminRoleExecutiveCommittee;

  /// No description provided for @superadminRoleSuperAdmin.
  ///
  /// In bn, this message translates to:
  /// **'সুপার অ্যাডমিন'**
  String get superadminRoleSuperAdmin;

  /// No description provided for @superadminAuditClearFilters.
  ///
  /// In bn, this message translates to:
  /// **'ফিল্টার সরিয়ে ফেলুন'**
  String get superadminAuditClearFilters;

  /// No description provided for @memberProfileCurrentHouseLabel.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান বাড়ি'**
  String get memberProfileCurrentHouseLabel;

  /// No description provided for @memberProfileCurrentRoadLabel.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান রাস্তা'**
  String get memberProfileCurrentRoadLabel;

  /// No description provided for @memberProfileCurrentPostOfficeLabel.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ডাকঘর'**
  String get memberProfileCurrentPostOfficeLabel;

  /// No description provided for @memberProfileCurrentUpazilaLabel.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান উপজেলা'**
  String get memberProfileCurrentUpazilaLabel;

  /// No description provided for @memberProfileCurrentDistrictLabel.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান জেলা'**
  String get memberProfileCurrentDistrictLabel;

  /// No description provided for @memberProfileCurrentDivisionLabel.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান বিভাগ'**
  String get memberProfileCurrentDivisionLabel;

  /// No description provided for @memberProfileUrgentNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'যোগাযোগের নাম'**
  String get memberProfileUrgentNameLabel;

  /// No description provided for @memberProfileUrgentMobileLabel.
  ///
  /// In bn, this message translates to:
  /// **'যোগাযোগের মোবাইল'**
  String get memberProfileUrgentMobileLabel;

  /// No description provided for @memberProfileMobileInvalid.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক মোবাইল নম্বর দিন (যেমন +8801XXXXXXXXX)'**
  String get memberProfileMobileInvalid;

  /// No description provided for @memberProfilePropertyTypesLabel.
  ///
  /// In bn, this message translates to:
  /// **'সম্পত্তির ধরন'**
  String get memberProfilePropertyTypesLabel;

  /// No description provided for @attachmentViewerMissing.
  ///
  /// In bn, this message translates to:
  /// **'ফাইলটি সার্ভারে নেই।'**
  String get attachmentViewerMissing;

  /// No description provided for @attachmentViewerDownloadFailed.
  ///
  /// In bn, this message translates to:
  /// **'ডাউনলোড ব্যর্থ হয়েছে। আবার চেষ্টা করুন।'**
  String get attachmentViewerDownloadFailed;

  /// No description provided for @attachmentViewerDownloadStarted.
  ///
  /// In bn, this message translates to:
  /// **'ডাউনলোড শুরু হয়েছে।'**
  String get attachmentViewerDownloadStarted;

  /// No description provided for @attachmentViewerPreviewUnavailable.
  ///
  /// In bn, this message translates to:
  /// **'এই ফাইল ধরনটি অ্যাপে প্রিভিউ করা যায় না।'**
  String get attachmentViewerPreviewUnavailable;

  /// No description provided for @attachmentViewerDownloadOpen.
  ///
  /// In bn, this message translates to:
  /// **'ডাউনলোড করে খুলুন'**
  String get attachmentViewerDownloadOpen;

  /// No description provided for @memberFundTransparencyFiltersDateFrom.
  ///
  /// In bn, this message translates to:
  /// **'শুরুর তারিখ'**
  String get memberFundTransparencyFiltersDateFrom;

  /// No description provided for @memberFundTransparencyFiltersDateTo.
  ///
  /// In bn, this message translates to:
  /// **'শেষ তারিখ'**
  String get memberFundTransparencyFiltersDateTo;

  /// No description provided for @adminRoadmapStatusPlanned.
  ///
  /// In bn, this message translates to:
  /// **'পরিকল্পিত'**
  String get adminRoadmapStatusPlanned;

  /// No description provided for @adminRoadmapStatusInProgress.
  ///
  /// In bn, this message translates to:
  /// **'চলমান'**
  String get adminRoadmapStatusInProgress;

  /// No description provided for @adminRoadmapStatusDone.
  ///
  /// In bn, this message translates to:
  /// **'সম্পন্ন'**
  String get adminRoadmapStatusDone;

  /// No description provided for @adminPropertyRequestsPayloadType.
  ///
  /// In bn, this message translates to:
  /// **'জমির ধরন'**
  String get adminPropertyRequestsPayloadType;

  /// No description provided for @adminPropertyRequestsPayloadKhatianNo.
  ///
  /// In bn, this message translates to:
  /// **'খতিয়ান নং'**
  String get adminPropertyRequestsPayloadKhatianNo;

  /// No description provided for @adminPropertyRequestsPayloadDagNoCs.
  ///
  /// In bn, this message translates to:
  /// **'সিএস দাগ নং'**
  String get adminPropertyRequestsPayloadDagNoCs;

  /// No description provided for @adminPropertyRequestsPayloadDagNoRs.
  ///
  /// In bn, this message translates to:
  /// **'আরএস দাগ নং'**
  String get adminPropertyRequestsPayloadDagNoRs;

  /// No description provided for @adminPropertyRequestsPayloadHoldingNumber.
  ///
  /// In bn, this message translates to:
  /// **'হোল্ডিং নং'**
  String get adminPropertyRequestsPayloadHoldingNumber;

  /// No description provided for @adminPropertyRequestsPayloadLandQuantity.
  ///
  /// In bn, this message translates to:
  /// **'জমির পরিমাণ'**
  String get adminPropertyRequestsPayloadLandQuantity;

  /// No description provided for @adminPropertyRequestsPayloadMyShareQuantity.
  ///
  /// In bn, this message translates to:
  /// **'আমার অংশ'**
  String get adminPropertyRequestsPayloadMyShareQuantity;

  /// No description provided for @adminPropertyRequestsPayloadOwnership.
  ///
  /// In bn, this message translates to:
  /// **'মালিকানা'**
  String get adminPropertyRequestsPayloadOwnership;

  /// No description provided for @adminPropertyRequestsPayloadCoOwners.
  ///
  /// In bn, this message translates to:
  /// **'যৌথ মালিক'**
  String get adminPropertyRequestsPayloadCoOwners;

  /// No description provided for @adminPropertyRequestsPayloadDocs.
  ///
  /// In bn, this message translates to:
  /// **'দলিলপত্র'**
  String get adminPropertyRequestsPayloadDocs;

  /// No description provided for @adminSocietyCostsSummaryMemberBilled.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের বকেয়া'**
  String get adminSocietyCostsSummaryMemberBilled;

  /// No description provided for @adminFinanceManagementFiltersApply.
  ///
  /// In bn, this message translates to:
  /// **'প্রয়োগ করুন'**
  String get adminFinanceManagementFiltersApply;

  /// No description provided for @navNeighbours.
  ///
  /// In bn, this message translates to:
  /// **'প্রতিবেশী তথ্য'**
  String get navNeighbours;

  /// No description provided for @memberNeighboursTitle.
  ///
  /// In bn, this message translates to:
  /// **'প্রতিবেশী তথ্য'**
  String get memberNeighboursTitle;

  /// No description provided for @memberNeighboursSubtitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার দাগ ও আশেপাশের নিকটতম {count}টি দাগের মালিকদের সাথে সহজে যোগাযোগ করুন'**
  String memberNeighboursSubtitle(Object count);

  /// No description provided for @memberNeighboursPrivacyNote.
  ///
  /// In bn, this message translates to:
  /// **'এই তথ্য শুধুমাত্র প্রতিবেশীদের সাথে যোগাযোগের জন্য — অন্য কারো সাথে শেয়ার করবেন না।'**
  String get memberNeighboursPrivacyNote;

  /// No description provided for @memberNeighboursDagTypeLabel.
  ///
  /// In bn, this message translates to:
  /// **'দাগের ধরন'**
  String get memberNeighboursDagTypeLabel;

  /// No description provided for @memberNeighboursDagTypeRs.
  ///
  /// In bn, this message translates to:
  /// **'আরএস দাগ'**
  String get memberNeighboursDagTypeRs;

  /// No description provided for @memberNeighboursDagTypeCs.
  ///
  /// In bn, this message translates to:
  /// **'সিএস দাগ'**
  String get memberNeighboursDagTypeCs;

  /// No description provided for @memberNeighboursOwnDag.
  ///
  /// In bn, this message translates to:
  /// **'আপনার দাগ'**
  String get memberNeighboursOwnDag;

  /// No description provided for @memberNeighboursTableOwnerName.
  ///
  /// In bn, this message translates to:
  /// **'মালিকের নাম'**
  String get memberNeighboursTableOwnerName;

  /// No description provided for @memberNeighboursTableMobile.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল নম্বর'**
  String get memberNeighboursTableMobile;

  /// No description provided for @memberNeighboursTableLandQuantity.
  ///
  /// In bn, this message translates to:
  /// **'জমির পরিমাণ'**
  String get memberNeighboursTableLandQuantity;

  /// No description provided for @memberNeighboursTableRsDag.
  ///
  /// In bn, this message translates to:
  /// **'আরএস দাগ'**
  String get memberNeighboursTableRsDag;

  /// No description provided for @memberNeighboursTableCsDag.
  ///
  /// In bn, this message translates to:
  /// **'সিএস দাগ'**
  String get memberNeighboursTableCsDag;

  /// No description provided for @memberNeighboursTablePosition.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থান'**
  String get memberNeighboursTablePosition;

  /// No description provided for @memberNeighboursTableContact.
  ///
  /// In bn, this message translates to:
  /// **'যোগাযোগ'**
  String get memberNeighboursTableContact;

  /// No description provided for @memberNeighboursPositionSameDag.
  ///
  /// In bn, this message translates to:
  /// **'আপনার দাগে'**
  String get memberNeighboursPositionSameDag;

  /// No description provided for @memberNeighboursPositionAdjacent.
  ///
  /// In bn, this message translates to:
  /// **'পাশের দাগ'**
  String get memberNeighboursPositionAdjacent;

  /// No description provided for @memberNeighboursPositionNear.
  ///
  /// In bn, this message translates to:
  /// **'কাছাকাছি দাগ'**
  String get memberNeighboursPositionNear;

  /// No description provided for @memberNeighboursLandUnit.
  ///
  /// In bn, this message translates to:
  /// **'{value} শতাংশ'**
  String memberNeighboursLandUnit(Object value);

  /// No description provided for @memberNeighboursCall.
  ///
  /// In bn, this message translates to:
  /// **'কল'**
  String get memberNeighboursCall;

  /// No description provided for @memberNeighboursCallAria.
  ///
  /// In bn, this message translates to:
  /// **'{name}-কে কল করুন'**
  String memberNeighboursCallAria(Object name);

  /// No description provided for @memberNeighboursWhatsapp.
  ///
  /// In bn, this message translates to:
  /// **'হোয়াটসঅ্যাপ'**
  String get memberNeighboursWhatsapp;

  /// No description provided for @memberNeighboursWhatsappAria.
  ///
  /// In bn, this message translates to:
  /// **'{name}-কে হোয়াটসঅ্যাপে বার্তা পাঠান'**
  String memberNeighboursWhatsappAria(Object name);

  /// No description provided for @memberNeighboursContactHidden.
  ///
  /// In bn, this message translates to:
  /// **'নম্বর গোপন রাখা হয়েছে'**
  String get memberNeighboursContactHidden;

  /// No description provided for @memberNeighboursEmptyState.
  ///
  /// In bn, this message translates to:
  /// **'আপনার দাগের আশেপাশে কোনো নিবন্ধিত সদস্য পাওয়া যায়নি'**
  String get memberNeighboursEmptyState;

  /// No description provided for @memberNeighboursEmptyHint.
  ///
  /// In bn, this message translates to:
  /// **'নতুন সদস্য যুক্ত হলে এখানে দেখা যাবে।'**
  String get memberNeighboursEmptyHint;

  /// No description provided for @memberNeighboursNoProperties.
  ///
  /// In bn, this message translates to:
  /// **'আপনার প্রোফাইলে কোনো সম্পত্তি যুক্ত নেই।'**
  String get memberNeighboursNoProperties;

  /// No description provided for @memberNeighboursNoDag.
  ///
  /// In bn, this message translates to:
  /// **'এই সম্পত্তিতে {type} নম্বর নেই — অন্য দাগের ধরন বেছে নিন।'**
  String memberNeighboursNoDag(Object type);

  /// No description provided for @memberNeighboursLoadError.
  ///
  /// In bn, this message translates to:
  /// **'প্রতিবেশী তথ্য লোড করা যায়নি।'**
  String get memberNeighboursLoadError;

  /// No description provided for @memberNeighboursRateLimited.
  ///
  /// In bn, this message translates to:
  /// **'অনেকবার খোঁজা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।'**
  String get memberNeighboursRateLimited;

  /// No description provided for @memberNeighboursApprovedOnly.
  ///
  /// In bn, this message translates to:
  /// **'শুধুমাত্র অনুমোদিত সদস্যরা প্রতিবেশী তথ্য দেখতে পারেন।'**
  String get memberNeighboursApprovedOnly;

  /// No description provided for @memberNeighboursDialerUnavailable.
  ///
  /// In bn, this message translates to:
  /// **'এই ডিভাইসে কল করা যাচ্ছে না।'**
  String get memberNeighboursDialerUnavailable;

  /// No description provided for @memberNeighboursWhatsappUnavailable.
  ///
  /// In bn, this message translates to:
  /// **'হোয়াটসঅ্যাপ খোলা যাচ্ছে না।'**
  String get memberNeighboursWhatsappUnavailable;

  /// No description provided for @memberProfileNeighbourDirectoryLabel.
  ///
  /// In bn, this message translates to:
  /// **'প্রতিবেশী তথ্যে আমার মোবাইল নম্বর দেখান'**
  String get memberProfileNeighbourDirectoryLabel;

  /// No description provided for @memberProfileNeighbourDirectoryHint.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করলে প্রতিবেশীরা শুধু আপনার নাম, জমির পরিমাণ ও দাগ দেখবেন।'**
  String get memberProfileNeighbourDirectoryHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
