import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get comingSoon;

  /// No description provided for @searchCountry.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن دولة'**
  String get searchCountry;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @genericError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقّع'**
  String get genericError;

  /// No description provided for @cancelButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancelButton;

  /// No description provided for @noSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noSearchResults;

  /// No description provided for @phoneRequired.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف مطلوب'**
  String get phoneRequired;

  /// No description provided for @phoneTooShort.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف قصير جدًا'**
  String get phoneTooShort;

  /// No description provided for @phoneTooLong.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف طويل جدًا'**
  String get phoneTooLong;

  /// No description provided for @phoneOnlyNumbers.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يحتوي رقم الهاتف على أرقام فقط'**
  String get phoneOnlyNumbers;

  /// No description provided for @passwordRequired.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور مطلوبة'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل'**
  String get passwordTooShort;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تأكيد كلمة المرور'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsNotMatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get passwordsNotMatch;

  /// No description provided for @fullNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'الاسم مطلوب'**
  String get fullNameRequired;

  /// No description provided for @fullNameTooShort.
  ///
  /// In ar, this message translates to:
  /// **'الاسم قصير جدًا'**
  String get fullNameTooShort;

  /// No description provided for @fullNameTooLong.
  ///
  /// In ar, this message translates to:
  /// **'الاسم طويل جدًا'**
  String get fullNameTooLong;

  /// No description provided for @otpRequired.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق مطلوب'**
  String get otpRequired;

  /// No description provided for @otpInvalid.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يتكون رمز التحقق من 6 أرقام'**
  String get otpInvalid;

  /// No description provided for @otpOnlyNumbers.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يحتوي رمز التحقق على أرقام فقط'**
  String get otpOnlyNumbers;

  /// No description provided for @fieldRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get fieldRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال بريد إلكتروني صحيح'**
  String get emailInvalid;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @loginStaffSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول بحساب الإدارة أو الورشة'**
  String get loginStaffSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get loginButton;

  /// No description provided for @unauthorizedTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذا التطبيق للموظفين فقط'**
  String get unauthorizedTitle;

  /// No description provided for @unauthorizedDesc.
  ///
  /// In ar, this message translates to:
  /// **'حسابك لا يملك صلاحية الدخول إلى تطبيق الإدارة والسائق.'**
  String get unauthorizedDesc;

  /// No description provided for @backToLogin.
  ///
  /// In ar, this message translates to:
  /// **'العودة لتسجيل الدخول'**
  String get backToLogin;

  /// No description provided for @navDashboard.
  ///
  /// In ar, this message translates to:
  /// **'اللوحة'**
  String get navDashboard;

  /// No description provided for @navOrders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get navOrders;

  /// No description provided for @navDeliveries.
  ///
  /// In ar, this message translates to:
  /// **'التوصيلات'**
  String get navDeliveries;

  /// No description provided for @navNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get navNotifications;

  /// No description provided for @navProfile.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get navProfile;

  /// No description provided for @navCustomerSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث العميل'**
  String get navCustomerSearch;

  /// No description provided for @statusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'مؤكَّد'**
  String get statusConfirmed;

  /// No description provided for @statusAssignedToTeam.
  ///
  /// In ar, this message translates to:
  /// **'مُسنَد لقائد فريق'**
  String get statusAssignedToTeam;

  /// No description provided for @statusAssigned.
  ///
  /// In ar, this message translates to:
  /// **'مُسنَد'**
  String get statusAssigned;

  /// No description provided for @statusInDelivery.
  ///
  /// In ar, this message translates to:
  /// **'قيد التوصيل'**
  String get statusInDelivery;

  /// No description provided for @statusDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التوصيل'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get statusCancelled;

  /// No description provided for @typeMosque.
  ///
  /// In ar, this message translates to:
  /// **'مسجد محدد'**
  String get typeMosque;

  /// No description provided for @typeMostNeeded.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر حاجة'**
  String get typeMostNeeded;

  /// No description provided for @orderRefShort.
  ///
  /// In ar, this message translates to:
  /// **'طلب {ref}'**
  String orderRefShort(String ref);

  /// No description provided for @destinationsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} وجهة'**
  String destinationsCount(int count);

  /// No description provided for @priceKwd.
  ///
  /// In ar, this message translates to:
  /// **'{amount} د.ك'**
  String priceKwd(String amount);

  /// No description provided for @workshopActiveLoad.
  ///
  /// In ar, this message translates to:
  /// **'{count} توصيلة حالية'**
  String workshopActiveLoad(int count);

  /// No description provided for @adminOrdersTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get adminOrdersTitle;

  /// No description provided for @searchOrdersHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث برقم العميل أو رقم الطلب (ORD-…)'**
  String get searchOrdersHint;

  /// No description provided for @emptyOrders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات'**
  String get emptyOrders;

  /// No description provided for @ordersCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} طلب'**
  String ordersCount(int count);

  /// No description provided for @awaitingAssignmentBadge.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج إسناد'**
  String get awaitingAssignmentBadge;

  /// No description provided for @tabAwaiting.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الإسناد'**
  String get tabAwaiting;

  /// No description provided for @tabAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get tabAll;

  /// No description provided for @tabDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التوصيل'**
  String get tabDelivered;

  /// No description provided for @tabCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get tabCancelled;

  /// No description provided for @tabInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get tabInProgress;

  /// No description provided for @tabNew.
  ///
  /// In ar, this message translates to:
  /// **'جديدة'**
  String get tabNew;

  /// No description provided for @tabConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'مؤكّدة'**
  String get tabConfirmed;

  /// No description provided for @orderDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الطلب'**
  String get orderDateLabel;

  /// No description provided for @lastStatusUpdateLabel.
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث'**
  String get lastStatusUpdateLabel;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get orderDetailsTitle;

  /// No description provided for @giftLabel.
  ///
  /// In ar, this message translates to:
  /// **'يحتوي على إهداء'**
  String get giftLabel;

  /// No description provided for @customerLabel.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get customerLabel;

  /// No description provided for @paymentLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get paymentLabel;

  /// No description provided for @paymentPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع'**
  String get paymentPaid;

  /// No description provided for @paymentUnpaid.
  ///
  /// In ar, this message translates to:
  /// **'غير مدفوع'**
  String get paymentUnpaid;

  /// No description provided for @notesLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات العميل'**
  String get notesLabel;

  /// No description provided for @destinationsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوجهات'**
  String get destinationsLabel;

  /// No description provided for @cancelReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإلغاء'**
  String get cancelReasonLabel;

  /// No description provided for @totalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get totalLabel;

  /// No description provided for @subtotalLabel.
  ///
  /// In ar, this message translates to:
  /// **'المجموع الفرعي'**
  String get subtotalLabel;

  /// No description provided for @noLocation.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد موقع على الخريطة'**
  String get noLocation;

  /// No description provided for @openLocation.
  ///
  /// In ar, this message translates to:
  /// **'فتح الموقع'**
  String get openLocation;

  /// No description provided for @assignedWorkshopLabel.
  ///
  /// In ar, this message translates to:
  /// **'الورشة المُسنَدة'**
  String get assignedWorkshopLabel;

  /// No description provided for @teamLeaderLabel.
  ///
  /// In ar, this message translates to:
  /// **'قائد الفريق'**
  String get teamLeaderLabel;

  /// No description provided for @assignButton.
  ///
  /// In ar, this message translates to:
  /// **'إسناد الورش'**
  String get assignButton;

  /// No description provided for @assignToTeamLeaderButton.
  ///
  /// In ar, this message translates to:
  /// **'إسناد لقائد فريق'**
  String get assignToTeamLeaderButton;

  /// No description provided for @distributeToHandler.
  ///
  /// In ar, this message translates to:
  /// **'توزيع لمنفّذ'**
  String get distributeToHandler;

  /// No description provided for @approveCompletion.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد الإنجاز'**
  String get approveCompletion;

  /// No description provided for @cancelOrderButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get cancelOrderButton;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get cancelOrderTitle;

  /// No description provided for @cancelReasonHint.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإلغاء'**
  String get cancelReasonHint;

  /// No description provided for @confirmCancel.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الإلغاء'**
  String get confirmCancel;

  /// No description provided for @keepOrder.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get keepOrder;

  /// No description provided for @orderCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الطلب'**
  String get orderCancelled;

  /// No description provided for @assignTitle.
  ///
  /// In ar, this message translates to:
  /// **'إسناد الورش'**
  String get assignTitle;

  /// No description provided for @chooseWorkshop.
  ///
  /// In ar, this message translates to:
  /// **'اختر الورشة'**
  String get chooseWorkshop;

  /// No description provided for @chooseMosque.
  ///
  /// In ar, this message translates to:
  /// **'اختر المسجد'**
  String get chooseMosque;

  /// No description provided for @mosquesSelectGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'اختر المحافظة'**
  String get mosquesSelectGovernorate;

  /// No description provided for @mosquesSelectArea.
  ///
  /// In ar, this message translates to:
  /// **'اختر المنطقة'**
  String get mosquesSelectArea;

  /// No description provided for @mosquesNoAreas.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مناطق في هذه المحافظة'**
  String get mosquesNoAreas;

  /// No description provided for @mosquesNone.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مساجد'**
  String get mosquesNone;

  /// No description provided for @chooseTeamLeader.
  ///
  /// In ar, this message translates to:
  /// **'اختر قائد الفريق'**
  String get chooseTeamLeader;

  /// No description provided for @chooseHandlerWhoDelivered.
  ///
  /// In ar, this message translates to:
  /// **'اختر المنفّذ الذي نفّذ'**
  String get chooseHandlerWhoDelivered;

  /// No description provided for @confirmAssign.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الإسناد'**
  String get confirmAssign;

  /// No description provided for @assignSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إسناد الورش بنجاح'**
  String get assignSuccess;

  /// No description provided for @assignTeamSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الإسناد لقائد الفريق بنجاح'**
  String get assignTeamSuccess;

  /// No description provided for @distributeSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم توزيع الوجهة للمنفّذ بنجاح'**
  String get distributeSuccess;

  /// No description provided for @completeSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم اعتماد إنجاز الوجهة بنجاح'**
  String get completeSuccess;

  /// No description provided for @noWorkshops.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ورش متاحة'**
  String get noWorkshops;

  /// No description provided for @noTeamLeaders.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد قادة فرق متاحون'**
  String get noTeamLeaders;

  /// No description provided for @searchMosqueHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مسجد'**
  String get searchMosqueHint;

  /// No description provided for @reassignButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإسناد'**
  String get reassignButton;

  /// No description provided for @reassignSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة الإسناد بنجاح'**
  String get reassignSuccess;

  /// No description provided for @noOtherWorkshops.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ورشة أخرى متاحة'**
  String get noOtherWorkshops;

  /// No description provided for @timelineLabel.
  ///
  /// In ar, this message translates to:
  /// **'سجل الطلب'**
  String get timelineLabel;

  /// No description provided for @callButton.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get callButton;

  /// No description provided for @whatsappButton.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get whatsappButton;

  /// No description provided for @contactFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر بدء الاتصال'**
  String get contactFailed;

  /// No description provided for @driverDeliveriesTitle.
  ///
  /// In ar, this message translates to:
  /// **'توصيلاتي'**
  String get driverDeliveriesTitle;

  /// No description provided for @tabAccepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبولة'**
  String get tabAccepted;

  /// No description provided for @tabInDelivery.
  ///
  /// In ar, this message translates to:
  /// **'قيد التوصيل'**
  String get tabInDelivery;

  /// No description provided for @tabCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتملة'**
  String get tabCompleted;

  /// No description provided for @emptyDeliveries.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد توصيلات'**
  String get emptyDeliveries;

  /// No description provided for @deliveryDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل التوصيلة'**
  String get deliveryDetailsTitle;

  /// No description provided for @acceptButton.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get acceptButton;

  /// No description provided for @rejectButton.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get rejectButton;

  /// No description provided for @startDeliveryButton.
  ///
  /// In ar, this message translates to:
  /// **'بدء التوصيل'**
  String get startDeliveryButton;

  /// No description provided for @uploadProofButton.
  ///
  /// In ar, this message translates to:
  /// **'رفع التوثيق وإنهاء التوصيل'**
  String get uploadProofButton;

  /// No description provided for @acceptedMsg.
  ///
  /// In ar, this message translates to:
  /// **'تم قبول التوصيلة'**
  String get acceptedMsg;

  /// No description provided for @deliveryStartedMsg.
  ///
  /// In ar, this message translates to:
  /// **'بدأت التوصيل'**
  String get deliveryStartedMsg;

  /// No description provided for @rejectedMsg.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض التوصيلة'**
  String get rejectedMsg;

  /// No description provided for @deliveredNote.
  ///
  /// In ar, this message translates to:
  /// **'تم توصيل هذه الوجهة'**
  String get deliveredNote;

  /// No description provided for @rejectTitle.
  ///
  /// In ar, this message translates to:
  /// **'رفض التوصيلة'**
  String get rejectTitle;

  /// No description provided for @rejectReasonHint.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض (اختياري)'**
  String get rejectReasonHint;

  /// No description provided for @confirmReject.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرفض'**
  String get confirmReject;

  /// No description provided for @proofTitle.
  ///
  /// In ar, this message translates to:
  /// **'توثيق التوصيل'**
  String get proofTitle;

  /// No description provided for @proofHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف صورًا أو فيديو لإثبات التركيب، ثم ارفعها لإنهاء التوصيل.'**
  String get proofHint;

  /// No description provided for @takePhoto.
  ///
  /// In ar, this message translates to:
  /// **'التقاط صورة'**
  String get takePhoto;

  /// No description provided for @fromGallery.
  ///
  /// In ar, this message translates to:
  /// **'من المعرض'**
  String get fromGallery;

  /// No description provided for @addVideo.
  ///
  /// In ar, this message translates to:
  /// **'فيديو'**
  String get addVideo;

  /// No description provided for @proofNoteHint.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get proofNoteHint;

  /// No description provided for @proofNoteDefaultDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم إيصال وتركيب الطلب في الموقع.'**
  String get proofNoteDefaultDelivered;

  /// No description provided for @uploadAndFinish.
  ///
  /// In ar, this message translates to:
  /// **'رفع وإنهاء التوصيل'**
  String get uploadAndFinish;

  /// No description provided for @pickFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر اختيار الملف'**
  String get pickFailed;

  /// No description provided for @noProofSelected.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة أو فيديو أولاً'**
  String get noProofSelected;

  /// No description provided for @proofUploaded.
  ///
  /// In ar, this message translates to:
  /// **'تم رفع التوثيق — تم التوصيل'**
  String get proofUploaded;

  /// No description provided for @deliveryProofs.
  ///
  /// In ar, this message translates to:
  /// **'توثيقات التسليم'**
  String get deliveryProofs;

  /// No description provided for @cannotOpenFile.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الملف'**
  String get cannotOpenFile;

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @emptyNotifications.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات'**
  String get emptyNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get markAllRead;

  /// No description provided for @dashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللوحة'**
  String get dashboardTitle;

  /// No description provided for @dashNew.
  ///
  /// In ar, this message translates to:
  /// **'جديدة'**
  String get dashNew;

  /// No description provided for @dashAwaiting.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الإسناد'**
  String get dashAwaiting;

  /// No description provided for @dashAssigned.
  ///
  /// In ar, this message translates to:
  /// **'مؤكّدة'**
  String get dashAssigned;

  /// No description provided for @dashCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتملة'**
  String get dashCompleted;

  /// No description provided for @dashCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get dashCancelled;

  /// No description provided for @dashAll.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get dashAll;

  /// No description provided for @completionRate.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الإكمال'**
  String get completionRate;

  /// No description provided for @slaTitle.
  ///
  /// In ar, this message translates to:
  /// **'متوسّط زمن الخدمة'**
  String get slaTitle;

  /// No description provided for @slaAvgConfirm.
  ///
  /// In ar, this message translates to:
  /// **'متوسّط زمن التأكيد'**
  String get slaAvgConfirm;

  /// No description provided for @slaAvgDeliver.
  ///
  /// In ar, this message translates to:
  /// **'متوسّط زمن التوصيل'**
  String get slaAvgDeliver;

  /// No description provided for @slaSample.
  ///
  /// In ar, this message translates to:
  /// **'عدد الطلبات المكتملة'**
  String get slaSample;

  /// No description provided for @minutesValue.
  ///
  /// In ar, this message translates to:
  /// **'{value} دقيقة'**
  String minutesValue(String value);

  /// No description provided for @activityTitle.
  ///
  /// In ar, this message translates to:
  /// **'نشاطي'**
  String get activityTitle;

  /// No description provided for @emptyActivity.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد نشاط'**
  String get emptyActivity;

  /// No description provided for @actionAssigned.
  ///
  /// In ar, this message translates to:
  /// **'إسناد وجهة لورشة'**
  String get actionAssigned;

  /// No description provided for @actionReassigned.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إسناد وجهة'**
  String get actionReassigned;

  /// No description provided for @actionCancelled.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء طلب'**
  String get actionCancelled;

  /// No description provided for @customerLookupTitle.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن عميل'**
  String get customerLookupTitle;

  /// No description provided for @lookupHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث برقم الهاتف أو الاسم'**
  String get lookupHint;

  /// No description provided for @lookupPrompt.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن عميل برقم الهاتف أو الاسم أو المعرّف (ID) لعرض سجلّه'**
  String get lookupPrompt;

  /// No description provided for @lookupIdHint.
  ///
  /// In ar, this message translates to:
  /// **'ID'**
  String get lookupIdHint;

  /// No description provided for @lookupNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد عميل مطابق'**
  String get lookupNoResults;

  /// No description provided for @approvalsTitle.
  ///
  /// In ar, this message translates to:
  /// **'صندوق الموافقات'**
  String get approvalsTitle;

  /// No description provided for @emptyApprovals.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد موافقات معلّقة'**
  String get emptyApprovals;

  /// No description provided for @approveButton.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد'**
  String get approveButton;

  /// No description provided for @approvePickModel.
  ///
  /// In ar, this message translates to:
  /// **'اختر الموديل المعتمَد'**
  String get approvePickModel;

  /// No description provided for @approveModelNote.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الموديل يثبّت هدف التمويل، ثم يُنشر الطلب لتموّله التبرّعات.'**
  String get approveModelNote;

  /// No description provided for @approveWithTarget.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد بهدف {amount} د.ك'**
  String approveWithTarget(String amount);

  /// No description provided for @approveSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم اعتماد الطلب'**
  String get approveSuccess;

  /// No description provided for @rejectSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض الطلب'**
  String get rejectSuccess;

  /// No description provided for @approvalRejectTitle.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض'**
  String get approvalRejectTitle;

  /// No description provided for @approvalRejectHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سبب الرفض'**
  String get approvalRejectHint;

  /// No description provided for @approvalMakerLabel.
  ///
  /// In ar, this message translates to:
  /// **'مقدّم الطلب'**
  String get approvalMakerLabel;

  /// No description provided for @escalationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التصعيدات'**
  String get escalationsTitle;

  /// No description provided for @emptyEscalations.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تصعيدات'**
  String get emptyEscalations;

  /// No description provided for @resolveButton.
  ///
  /// In ar, this message translates to:
  /// **'تم الحل'**
  String get resolveButton;

  /// No description provided for @resolveSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حلّ التصعيد'**
  String get resolveSuccess;

  /// No description provided for @raiseEscalationTitle.
  ///
  /// In ar, this message translates to:
  /// **'رفع تصعيد'**
  String get raiseEscalationTitle;

  /// No description provided for @raiseEscalationHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سبب التصعيد'**
  String get raiseEscalationHint;

  /// No description provided for @escalationRaised.
  ///
  /// In ar, this message translates to:
  /// **'تم رفع التصعيد'**
  String get escalationRaised;

  /// No description provided for @escalationRaisedByLabel.
  ///
  /// In ar, this message translates to:
  /// **'بواسطة'**
  String get escalationRaisedByLabel;

  /// No description provided for @statusOpen.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get statusOpen;

  /// No description provided for @statusResolved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحل'**
  String get statusResolved;

  /// No description provided for @productsTitle.
  ///
  /// In ar, this message translates to:
  /// **'توفّر المنتجات'**
  String get productsTitle;

  /// No description provided for @searchProductsHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن منتج'**
  String get searchProductsHint;

  /// No description provided for @emptyProducts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات'**
  String get emptyProducts;

  /// No description provided for @productSuspended.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get productSuspended;

  /// No description provided for @productInactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط (يُدار من الويب)'**
  String get productInactive;

  /// No description provided for @productVariantsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{تنويع واحد} =2{تنويعان} few{{count} تنويعات} other{{count} تنويعًا}}'**
  String productVariantsCount(int count);

  /// No description provided for @suspendReasonTitle.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإيقاف'**
  String get suspendReasonTitle;

  /// No description provided for @suspendReasonHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: نفاد المخزون (اختياري)'**
  String get suspendReasonHint;

  /// No description provided for @suspendConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get suspendConfirm;

  /// No description provided for @profileTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profileTitle;

  /// No description provided for @roleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get roleAdmin;

  /// No description provided for @roleDriver.
  ///
  /// In ar, this message translates to:
  /// **'ورشة توصيل'**
  String get roleDriver;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @userFallback.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get userFallback;

  /// No description provided for @settingsLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settingsLanguage;

  /// No description provided for @languageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageTitle;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsAppearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get settingsAppearance;

  /// No description provided for @appearanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearanceTitle;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب إعدادات الجهاز'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @notificationChannelName.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات ســـبّاقـــ'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In ar, this message translates to:
  /// **'تعيينات الطلبات وتحديثات التوصيل.'**
  String get notificationChannelDescription;

  /// No description provided for @confirmButton.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirmButton;

  /// No description provided for @saveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get saveButton;

  /// No description provided for @nextButton.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get nextButton;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @otpLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق'**
  String get otpLabel;

  /// No description provided for @sendCodeButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرمز'**
  String get sendCodeButton;

  /// No description provided for @resendCode.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الرمز'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرسال خلال {seconds} ثانية'**
  String resendCodeIn(int seconds);

  /// No description provided for @filterGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get filterGovernorate;

  /// No description provided for @filterArea.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get filterArea;

  /// No description provided for @repEntryPrompt.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت ممثل مسجد؟ اضغط هنا'**
  String get repEntryPrompt;

  /// No description provided for @repLoginTitle.
  ///
  /// In ar, this message translates to:
  /// **'دخول ممثل المسجد'**
  String get repLoginTitle;

  /// No description provided for @repLoginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتفك للمتابعة'**
  String get repLoginSubtitle;

  /// No description provided for @repPasscodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرمز السري'**
  String get repPasscodeLabel;

  /// No description provided for @repPasscodeRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز السري المكوّن من 4 أرقام'**
  String get repPasscodeRequired;

  /// No description provided for @repPasscodeStepTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز السري'**
  String get repPasscodeStepTitle;

  /// No description provided for @repPasscodeStepSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمزك السري المكوّن من 4 أرقام لتسجيل الدخول'**
  String get repPasscodeStepSubtitle;

  /// No description provided for @repChangePhone.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الرقم'**
  String get repChangePhone;

  /// No description provided for @continueButton.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueButton;

  /// No description provided for @repForgotPasscode.
  ///
  /// In ar, this message translates to:
  /// **'نسيت الرمز السري؟'**
  String get repForgotPasscode;

  /// No description provided for @repForgotSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سنرسل رمز تحقق إلى هاتفك لتعيين رمز سري جديد'**
  String get repForgotSubtitle;

  /// No description provided for @repPasscodeResetDone.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين الرمز السري الجديد'**
  String get repPasscodeResetDone;

  /// No description provided for @repRegisterButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل ممثل جديد'**
  String get repRegisterButton;

  /// No description provided for @repHaveInvite.
  ///
  /// In ar, this message translates to:
  /// **'لديّ رابط دعوة'**
  String get repHaveInvite;

  /// No description provided for @repRegisterTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل ممثل مسجد'**
  String get repRegisterTitle;

  /// No description provided for @repRegisterPhoneStep.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتفك لإرسال رمز التحقق'**
  String get repRegisterPhoneStep;

  /// No description provided for @repRegisterIdentityStep.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق واسمك'**
  String get repRegisterIdentityStep;

  /// No description provided for @repRegisterMosqueStep.
  ///
  /// In ar, this message translates to:
  /// **'حدّد مسجدك بدقة: المحافظة ثم المنطقة ثم المسجد'**
  String get repRegisterMosqueStep;

  /// No description provided for @repRegisterPasscodeStep.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ رمزًا سريًا من 4 أرقام للدخول اليومي'**
  String get repRegisterPasscodeStep;

  /// No description provided for @repFillAllFields.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تعبئة جميع الحقول المطلوبة'**
  String get repFillAllFields;

  /// No description provided for @repFirstName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول'**
  String get repFirstName;

  /// No description provided for @repLastName.
  ///
  /// In ar, this message translates to:
  /// **'اسم العائلة'**
  String get repLastName;

  /// No description provided for @repSearchMosque.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن المسجد بالاسم'**
  String get repSearchMosque;

  /// No description provided for @repPasscodeCreate.
  ///
  /// In ar, this message translates to:
  /// **'الرمز السري الجديد'**
  String get repPasscodeCreate;

  /// No description provided for @repPasscodeConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرمز السري'**
  String get repPasscodeConfirm;

  /// No description provided for @repPasscodeMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الرمزان غير متطابقين'**
  String get repPasscodeMismatch;

  /// No description provided for @repRegisterSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get repRegisterSubmit;

  /// No description provided for @repInviteTitle.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل بدعوة'**
  String get repInviteTitle;

  /// No description provided for @repInviteSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز الدعوة الذي وصلك من سبّاق'**
  String get repInviteSubtitle;

  /// No description provided for @repInviteToken.
  ///
  /// In ar, this message translates to:
  /// **'رمز الدعوة'**
  String get repInviteToken;

  /// No description provided for @repInviteCheck.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الدعوة'**
  String get repInviteCheck;

  /// No description provided for @repPendingTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبك قيد المراجعة'**
  String get repPendingTitle;

  /// No description provided for @repPendingBody.
  ///
  /// In ar, this message translates to:
  /// **'استلمنا طلب تسجيلك كممثل مسجد. سيتواصل معك فريق سبّاق للتحقق ثم يُفعَّل حسابك — بعدها يمكنك تسجيل الدخول برقم هاتفك ورمزك السري.'**
  String get repPendingBody;

  /// No description provided for @repBackToLogin.
  ///
  /// In ar, this message translates to:
  /// **'العودة لتسجيل الدخول'**
  String get repBackToLogin;

  /// No description provided for @repNavMosque.
  ///
  /// In ar, this message translates to:
  /// **'مسجدي'**
  String get repNavMosque;

  /// No description provided for @repNavReports.
  ///
  /// In ar, this message translates to:
  /// **'بلاغاتي'**
  String get repNavReports;

  /// No description provided for @repActionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإجراءات'**
  String get repActionsTitle;

  /// No description provided for @repReportMaintenance.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ صيانة'**
  String get repReportMaintenance;

  /// No description provided for @repReportMaintenanceDesc.
  ///
  /// In ar, this message translates to:
  /// **'أبلغ عن عطل في وحدة مسجّلة بمسجدك'**
  String get repReportMaintenanceDesc;

  /// No description provided for @repWaterFlagTitle.
  ///
  /// In ar, this message translates to:
  /// **'نقص مياه'**
  String get repWaterFlagTitle;

  /// No description provided for @repWaterFlagDesc.
  ///
  /// In ar, this message translates to:
  /// **'أبلغ بنقرة واحدة أن مياه المسجد شارفت على النفاد'**
  String get repWaterFlagDesc;

  /// No description provided for @repWaterFlagConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد إرسال بلاغ نقص مياه لمسجدك؟ سيظهر للمستخدمين بعد اعتماده.'**
  String get repWaterFlagConfirm;

  /// No description provided for @repWaterFlagSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال بلاغ نقص المياه'**
  String get repWaterFlagSent;

  /// No description provided for @repRequestEquipment.
  ///
  /// In ar, this message translates to:
  /// **'طلب معدّة جديدة'**
  String get repRequestEquipment;

  /// No description provided for @repRequestEquipmentDesc.
  ///
  /// In ar, this message translates to:
  /// **'اطلب مبرّد ماء أو ثلاجة جديدة لمسجدك'**
  String get repRequestEquipmentDesc;

  /// No description provided for @repUnitsTitle.
  ///
  /// In ar, this message translates to:
  /// **'معدّات مسجدي'**
  String get repUnitsTitle;

  /// No description provided for @repNoUnits.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد معدّات مسجّلة لمسجدك بعد'**
  String get repNoUnits;

  /// No description provided for @repStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الاعتماد'**
  String get repStatusPending;

  /// No description provided for @repStatusDeactivated.
  ///
  /// In ar, this message translates to:
  /// **'معطَّل'**
  String get repStatusDeactivated;

  /// No description provided for @repPickUnit.
  ///
  /// In ar, this message translates to:
  /// **'اختر الوحدة'**
  String get repPickUnit;

  /// No description provided for @repIssueType.
  ///
  /// In ar, this message translates to:
  /// **'نوع العطل'**
  String get repIssueType;

  /// No description provided for @repIssueFilterChange.
  ///
  /// In ar, this message translates to:
  /// **'تغيير فلاتر'**
  String get repIssueFilterChange;

  /// No description provided for @repIssueNotWorking.
  ///
  /// In ar, this message translates to:
  /// **'لا يعمل'**
  String get repIssueNotWorking;

  /// No description provided for @repIssueLeaking.
  ///
  /// In ar, this message translates to:
  /// **'تسريب'**
  String get repIssueLeaking;

  /// No description provided for @repIssueOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get repIssueOther;

  /// No description provided for @repIssueOtherNeedsDesc.
  ///
  /// In ar, this message translates to:
  /// **'الوصف مطلوب عند اختيار «أخرى»'**
  String get repIssueOtherNeedsDesc;

  /// No description provided for @repIssueDescription.
  ///
  /// In ar, this message translates to:
  /// **'وصف العطل'**
  String get repIssueDescription;

  /// No description provided for @repReportSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال البلاغ'**
  String get repReportSubmit;

  /// No description provided for @repReportSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال البلاغ'**
  String get repReportSent;

  /// No description provided for @repEquipmentType.
  ///
  /// In ar, this message translates to:
  /// **'نوع المعدّة'**
  String get repEquipmentType;

  /// No description provided for @repEquipmentNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get repEquipmentNote;

  /// No description provided for @repEquipmentRequestSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب المعدّة'**
  String get repEquipmentRequestSent;

  /// No description provided for @repTabMaintenance.
  ///
  /// In ar, this message translates to:
  /// **'الصيانة'**
  String get repTabMaintenance;

  /// No description provided for @repTabWater.
  ///
  /// In ar, this message translates to:
  /// **'المياه'**
  String get repTabWater;

  /// No description provided for @repTabEquipment.
  ///
  /// In ar, this message translates to:
  /// **'المعدّات'**
  String get repTabEquipment;

  /// No description provided for @repNoReports.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بلاغات بعد'**
  String get repNoReports;

  /// No description provided for @repStatusSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'مُقدَّم'**
  String get repStatusSubmitted;

  /// No description provided for @repStatusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get repStatusInProgress;

  /// No description provided for @repStatusResolved.
  ///
  /// In ar, this message translates to:
  /// **'مُنجَز'**
  String get repStatusResolved;

  /// No description provided for @repStatusApproved.
  ///
  /// In ar, this message translates to:
  /// **'معتمَد'**
  String get repStatusApproved;

  /// No description provided for @repStatusFulfilled.
  ///
  /// In ar, this message translates to:
  /// **'مُنفَّذ'**
  String get repStatusFulfilled;

  /// No description provided for @repStatusRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get repStatusRejected;

  /// No description provided for @repStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get repStatusCancelled;

  /// No description provided for @repRefresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get repRefresh;

  /// No description provided for @repFieldReference.
  ///
  /// In ar, this message translates to:
  /// **'رقم البلاغ'**
  String get repFieldReference;

  /// No description provided for @repFieldEquipmentCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز الجهاز'**
  String get repFieldEquipmentCode;

  /// No description provided for @repFieldIssue.
  ///
  /// In ar, this message translates to:
  /// **'نوع العطل'**
  String get repFieldIssue;

  /// No description provided for @repFieldDescription.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get repFieldDescription;

  /// No description provided for @repFieldNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get repFieldNote;

  /// No description provided for @repFieldDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التقديم'**
  String get repFieldDate;

  /// No description provided for @repFieldApprovedAt.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الاعتماد'**
  String get repFieldApprovedAt;

  /// No description provided for @repFieldFulfilledAt.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التنفيذ'**
  String get repFieldFulfilledAt;

  /// No description provided for @repFieldResolvedAt.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الإنجاز'**
  String get repFieldResolvedAt;

  /// No description provided for @repFieldRejectReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض'**
  String get repFieldRejectReason;

  /// No description provided for @repPhotos.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get repPhotos;

  /// No description provided for @repAddPhotos.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صور'**
  String get repAddPhotos;

  /// No description provided for @repPhotosHint.
  ///
  /// In ar, this message translates to:
  /// **'اختياري — حتى 5 صور'**
  String get repPhotosHint;

  /// No description provided for @repMaxPhotos.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك إضافة حتى 5 صور'**
  String get repMaxPhotos;

  /// No description provided for @opsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مركز العمليات'**
  String get opsTitle;

  /// No description provided for @opsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كل ما يحتاج إجراءً منك، مرتّبًا حسب صلاحيات دورك'**
  String get opsSubtitle;

  /// No description provided for @opsPendingTotal.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{عنصر واحد بانتظار إجراءك} =2{عنصران بانتظار إجراءك} few{{count} عناصر بانتظار إجراءك} other{{count} عنصرًا بانتظار إجراءك}}'**
  String opsPendingTotal(int count);

  /// No description provided for @opsAllClear.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء بانتظار إجراءك'**
  String get opsAllClear;

  /// No description provided for @opsAllClearDesc.
  ///
  /// In ar, this message translates to:
  /// **'كل الطوابير المتاحة لدورك فارغة الآن'**
  String get opsAllClearDesc;

  /// No description provided for @opsUpdating.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحديث الأرقام…'**
  String get opsUpdating;

  /// No description provided for @opsNothingHere.
  ///
  /// In ar, this message translates to:
  /// **'لا جديد الآن'**
  String get opsNothingHere;

  /// No description provided for @opsRoleScope.
  ///
  /// In ar, this message translates to:
  /// **'نطاقك: {name}'**
  String opsRoleScope(String name);

  /// No description provided for @opsNoQueues.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طوابير متاحة لدورك حاليًا'**
  String get opsNoQueues;

  /// No description provided for @opsSectionApprovals.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار قرارك'**
  String get opsSectionApprovals;

  /// No description provided for @opsSectionApprovalsDesc.
  ///
  /// In ar, this message translates to:
  /// **'طلبات ترفعها المساجد أو يشتريها المتبرّعون، ولا تتحرّك قبل اعتمادك.'**
  String get opsSectionApprovalsDesc;

  /// No description provided for @opsSectionField.
  ///
  /// In ar, this message translates to:
  /// **'التنفيذ والمتابعة'**
  String get opsSectionField;

  /// No description provided for @opsSectionFieldDesc.
  ///
  /// In ar, this message translates to:
  /// **'ما بعد الاعتماد: إسناد المهام، تنفيذها ميدانيًا، وتوثيق الإنجاز.'**
  String get opsSectionFieldDesc;

  /// No description provided for @opsSectionCreate.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء بلاغ'**
  String get opsSectionCreate;

  /// No description provided for @opsSectionCreateDesc.
  ///
  /// In ar, this message translates to:
  /// **'سجّل حاجة نيابة عن الإدارة دون انتظار طلب من المسجد.'**
  String get opsSectionCreateDesc;

  /// No description provided for @opsHowItWorks.
  ///
  /// In ar, this message translates to:
  /// **'كيف تسير العمليات؟'**
  String get opsHowItWorks;

  /// No description provided for @opsHowStep1.
  ///
  /// In ar, this message translates to:
  /// **'طلب'**
  String get opsHowStep1;

  /// No description provided for @opsHowStep1Desc.
  ///
  /// In ar, this message translates to:
  /// **'يرفع إمام المسجد بلاغ نقص مياه أو طلب معدّة، أو يشتري متبرّع معدّة من المتجر.'**
  String get opsHowStep1Desc;

  /// No description provided for @opsHowStep2.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد'**
  String get opsHowStep2;

  /// No description provided for @opsHowStep2Desc.
  ///
  /// In ar, this message translates to:
  /// **'تراجعه الإدارة: المعتمَد يُعرض للتبرّع، والمرفوض يُغلق بسبب مكتوب.'**
  String get opsHowStep2Desc;

  /// No description provided for @opsHowStep3.
  ///
  /// In ar, this message translates to:
  /// **'تمويل'**
  String get opsHowStep3;

  /// No description provided for @opsHowStep3Desc.
  ///
  /// In ar, this message translates to:
  /// **'يكتمل مبلغ الحاجة من تبرّعات المتبرّعين، فتتحوّل إلى مهمّة تنفيذ.'**
  String get opsHowStep3Desc;

  /// No description provided for @opsHowStep4.
  ///
  /// In ar, this message translates to:
  /// **'إسناد'**
  String get opsHowStep4;

  /// No description provided for @opsHowStep4Desc.
  ///
  /// In ar, this message translates to:
  /// **'تُسنَد المهمّة لقائد فريق، ثم يوزّعها على منفّذ ميداني.'**
  String get opsHowStep4Desc;

  /// No description provided for @opsHowStep5.
  ///
  /// In ar, this message translates to:
  /// **'تنفيذ وتوثيق'**
  String get opsHowStep5;

  /// No description provided for @opsHowStep5Desc.
  ///
  /// In ar, this message translates to:
  /// **'ينفّذ المنفّذ المهمّة ويرفق بيانًا وصور إنجاز تُغلق بها.'**
  String get opsHowStep5Desc;

  /// No description provided for @opsHowFooter.
  ///
  /// In ar, this message translates to:
  /// **'تظهر لك الطوابير التي يسمح بها دورك فقط، ومحصورة في نطاقك الجغرافي.'**
  String get opsHowFooter;

  /// No description provided for @navOperations.
  ///
  /// In ar, this message translates to:
  /// **'العمليات'**
  String get navOperations;

  /// No description provided for @opsWaterFlags.
  ///
  /// In ar, this message translates to:
  /// **'بلاغات نقص المياه'**
  String get opsWaterFlags;

  /// No description provided for @opsWaterFlagsDesc.
  ///
  /// In ar, this message translates to:
  /// **'بلاغات يرفعها أئمة المساجد عند نقص مياه الشرب. اعتمد البلاغ ليُعرض للتبرّع، أو ألغِه.'**
  String get opsWaterFlagsDesc;

  /// No description provided for @opsWaterFlagItem.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ نقص مياه'**
  String get opsWaterFlagItem;

  /// No description provided for @opsEquipmentRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات معدّات جديدة'**
  String get opsEquipmentRequests;

  /// No description provided for @opsEquipmentRequestsDesc.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الأئمة لتزويد المسجد بمعدّة. اعتمد الطلب لتبدأ حملة تمويله، أو ارفضه.'**
  String get opsEquipmentRequestsDesc;

  /// No description provided for @opsEquipmentRequestItem.
  ///
  /// In ar, this message translates to:
  /// **'طلب معدّة'**
  String get opsEquipmentRequestItem;

  /// No description provided for @opsEmptyQueue.
  ///
  /// In ar, this message translates to:
  /// **'لا عناصر في هذا الطابور'**
  String get opsEmptyQueue;

  /// No description provided for @opsMosque.
  ///
  /// In ar, this message translates to:
  /// **'المسجد'**
  String get opsMosque;

  /// No description provided for @opsConfirmCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء هذا الطلب؟'**
  String get opsConfirmCancel;

  /// No description provided for @opsCancelAction.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get opsCancelAction;

  /// No description provided for @opsFilterMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر'**
  String get opsFilterMonth;

  /// No description provided for @opsFilterStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get opsFilterStatus;

  /// No description provided for @opsFilterPriority.
  ///
  /// In ar, this message translates to:
  /// **'الأولوية'**
  String get opsFilterPriority;

  /// No description provided for @opsFilterKind.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get opsFilterKind;

  /// No description provided for @opsFilterAny.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get opsFilterAny;

  /// No description provided for @opsFilterAllTime.
  ///
  /// In ar, this message translates to:
  /// **'كل الفترات'**
  String get opsFilterAllTime;

  /// No description provided for @mtTitle.
  ///
  /// In ar, this message translates to:
  /// **'بلاغات الصيانة'**
  String get mtTitle;

  /// No description provided for @mtCaseTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل البلاغ'**
  String get mtCaseTitle;

  /// No description provided for @mtDescTriage.
  ///
  /// In ar, this message translates to:
  /// **'أعطال المعدّات المركّبة. أقرّ البلاغ، حدّد الأولوية ومسار التكلفة، ثم أسنده لقائد فريق.'**
  String get mtDescTriage;

  /// No description provided for @mtDescLeader.
  ///
  /// In ar, this message translates to:
  /// **'التقط البلاغات المعتمَدة في نطاقك، وزّعها على أعضاء فريقك، ووثّق إنجازها.'**
  String get mtDescLeader;

  /// No description provided for @mtDescHandler.
  ///
  /// In ar, this message translates to:
  /// **'بلاغات الصيانة المُسندة إليك. نفّذ الإصلاح وأرفق صور الإنجاز.'**
  String get mtDescHandler;

  /// No description provided for @mtStatusSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'مُقدَّم'**
  String get mtStatusSubmitted;

  /// No description provided for @mtStatusAcknowledged.
  ///
  /// In ar, this message translates to:
  /// **'تم الإقرار'**
  String get mtStatusAcknowledged;

  /// No description provided for @mtStatusApproved.
  ///
  /// In ar, this message translates to:
  /// **'معتمَد'**
  String get mtStatusApproved;

  /// No description provided for @mtStatusAssigned.
  ///
  /// In ar, this message translates to:
  /// **'مُسنَد لقائد'**
  String get mtStatusAssigned;

  /// No description provided for @mtStatusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get mtStatusInProgress;

  /// No description provided for @mtStatusCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get mtStatusCompleted;

  /// No description provided for @mtStatusResolved.
  ///
  /// In ar, this message translates to:
  /// **'مُنجَز'**
  String get mtStatusResolved;

  /// No description provided for @mtStatusDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'مكرّر'**
  String get mtStatusDuplicate;

  /// No description provided for @mtStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get mtStatusCancelled;

  /// No description provided for @mtPriorityLow.
  ///
  /// In ar, this message translates to:
  /// **'منخفضة'**
  String get mtPriorityLow;

  /// No description provided for @mtPriorityMedium.
  ///
  /// In ar, this message translates to:
  /// **'متوسطة'**
  String get mtPriorityMedium;

  /// No description provided for @mtPriorityHigh.
  ///
  /// In ar, this message translates to:
  /// **'عالية'**
  String get mtPriorityHigh;

  /// No description provided for @mtPriorityUrgent.
  ///
  /// In ar, this message translates to:
  /// **'عاجلة'**
  String get mtPriorityUrgent;

  /// No description provided for @mtCostUnset.
  ///
  /// In ar, this message translates to:
  /// **'غير محدّد'**
  String get mtCostUnset;

  /// No description provided for @mtCostFreeWarranty.
  ///
  /// In ar, this message translates to:
  /// **'مجّاني (ضمان)'**
  String get mtCostFreeWarranty;

  /// No description provided for @mtCostManufacturer.
  ///
  /// In ar, this message translates to:
  /// **'المصنّع (كمبروسر)'**
  String get mtCostManufacturer;

  /// No description provided for @mtCostCustomerPaid.
  ///
  /// In ar, this message translates to:
  /// **'يموّله عميل'**
  String get mtCostCustomerPaid;

  /// No description provided for @mtFieldPriority.
  ///
  /// In ar, this message translates to:
  /// **'الأولوية'**
  String get mtFieldPriority;

  /// No description provided for @mtFieldCostPath.
  ///
  /// In ar, this message translates to:
  /// **'مسار التكلفة'**
  String get mtFieldCostPath;

  /// No description provided for @mtFieldPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get mtFieldPrice;

  /// No description provided for @mtFieldReporter.
  ///
  /// In ar, this message translates to:
  /// **'المُبلِّغ'**
  String get mtFieldReporter;

  /// No description provided for @mtFieldTeamLeader.
  ///
  /// In ar, this message translates to:
  /// **'قائد الفريق'**
  String get mtFieldTeamLeader;

  /// No description provided for @mtFieldMember.
  ///
  /// In ar, this message translates to:
  /// **'العضو'**
  String get mtFieldMember;

  /// No description provided for @mtFieldStatement.
  ///
  /// In ar, this message translates to:
  /// **'بيان الإنجاز'**
  String get mtFieldStatement;

  /// No description provided for @mtAcknowledge.
  ///
  /// In ar, this message translates to:
  /// **'إقرار'**
  String get mtAcknowledge;

  /// No description provided for @mtSetPriority.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الأولوية'**
  String get mtSetPriority;

  /// No description provided for @mtAssignLeader.
  ///
  /// In ar, this message translates to:
  /// **'إسناد لقائد فريق'**
  String get mtAssignLeader;

  /// No description provided for @mtAssignMember.
  ///
  /// In ar, this message translates to:
  /// **'إسناد لعضو'**
  String get mtAssignMember;

  /// No description provided for @mtComplete.
  ///
  /// In ar, this message translates to:
  /// **'إنجاز'**
  String get mtComplete;

  /// No description provided for @mtVerify.
  ///
  /// In ar, this message translates to:
  /// **'توثيق الإنجاز'**
  String get mtVerify;

  /// No description provided for @mtCancelCase.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء البلاغ'**
  String get mtCancelCase;

  /// No description provided for @mtApproveTitle.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد البلاغ'**
  String get mtApproveTitle;

  /// No description provided for @mtChooseCostPath.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسار التكلفة'**
  String get mtChooseCostPath;

  /// No description provided for @mtPriceKwd.
  ///
  /// In ar, this message translates to:
  /// **'السعر (د.ك)'**
  String get mtPriceKwd;

  /// No description provided for @mtPriceRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل السعر للتمويل من العميل'**
  String get mtPriceRequired;

  /// No description provided for @mtChoosePriority.
  ///
  /// In ar, this message translates to:
  /// **'اختر الأولوية'**
  String get mtChoosePriority;

  /// No description provided for @mtChooseLeader.
  ///
  /// In ar, this message translates to:
  /// **'اختر قائد فريق'**
  String get mtChooseLeader;

  /// No description provided for @mtChooseMember.
  ///
  /// In ar, this message translates to:
  /// **'اختر عضوًا'**
  String get mtChooseMember;

  /// No description provided for @mtStatementHint.
  ///
  /// In ar, this message translates to:
  /// **'صف ما تم إنجازه'**
  String get mtStatementHint;

  /// No description provided for @mtStatementRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بيان الإنجاز'**
  String get mtStatementRequired;

  /// No description provided for @mtNoLeaders.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد قادة فرق'**
  String get mtNoLeaders;

  /// No description provided for @mtNoMembers.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أعضاء'**
  String get mtNoMembers;

  /// No description provided for @mtActiveLoad.
  ///
  /// In ar, this message translates to:
  /// **'{count} مهمة نشطة'**
  String mtActiveLoad(int count);

  /// No description provided for @mtSuggested.
  ///
  /// In ar, this message translates to:
  /// **'مقترح: {label}'**
  String mtSuggested(String label);

  /// No description provided for @mtManufacturerRouted.
  ///
  /// In ar, this message translates to:
  /// **'موجّه للمصنّع'**
  String get mtManufacturerRouted;

  /// No description provided for @mtActionDone.
  ///
  /// In ar, this message translates to:
  /// **'تم التنفيذ'**
  String get mtActionDone;

  /// No description provided for @mtConfirmCancelCase.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء بلاغ الصيانة هذا؟'**
  String get mtConfirmCancelCase;

  /// No description provided for @mtDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'دمج مكرّر'**
  String get mtDuplicate;

  /// No description provided for @mtDuplicatePickHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر البلاغ الأصلي لنفس المعدّة'**
  String get mtDuplicatePickHint;

  /// No description provided for @mtDuplicateEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بلاغات أخرى لهذه المعدّة'**
  String get mtDuplicateEmpty;

  /// No description provided for @mtDuplicateNoCode.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد رمز معدّة للبحث عن بلاغ أصلي'**
  String get mtDuplicateNoCode;

  /// No description provided for @mtMergedInto.
  ///
  /// In ar, this message translates to:
  /// **'مدموج في البلاغ رقم {id}'**
  String mtMergedInto(int id);

  /// No description provided for @mtSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث برمز المعدّة'**
  String get mtSearchHint;

  /// No description provided for @ctTitle.
  ///
  /// In ar, this message translates to:
  /// **'المساهمات'**
  String get ctTitle;

  /// No description provided for @ctDesc.
  ///
  /// In ar, this message translates to:
  /// **'سجل المساهمات ومبالغها وحالاتها'**
  String get ctDesc;

  /// No description provided for @ctKindWater.
  ///
  /// In ar, this message translates to:
  /// **'مياه'**
  String get ctKindWater;

  /// No description provided for @ctKindMaintenance.
  ///
  /// In ar, this message translates to:
  /// **'صيانة'**
  String get ctKindMaintenance;

  /// No description provided for @ctKindEquipment.
  ///
  /// In ar, this message translates to:
  /// **'معدّة'**
  String get ctKindEquipment;

  /// No description provided for @ctStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get ctStatusPending;

  /// No description provided for @ctStatusPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوعة'**
  String get ctStatusPaid;

  /// No description provided for @ctStatusFulfilled.
  ///
  /// In ar, this message translates to:
  /// **'مُنفَّذة'**
  String get ctStatusFulfilled;

  /// No description provided for @ctStatusExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get ctStatusExpired;

  /// No description provided for @ctStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get ctStatusCancelled;

  /// No description provided for @ctCustomer.
  ///
  /// In ar, this message translates to:
  /// **'المتبرّع'**
  String get ctCustomer;

  /// No description provided for @ctMaintenanceAutoSettle.
  ///
  /// In ar, this message translates to:
  /// **'تُسوّى تلقائيًا عند توثيق بلاغ الصيانة'**
  String get ctMaintenanceAutoSettle;

  /// No description provided for @ctViaTasksNote.
  ///
  /// In ar, this message translates to:
  /// **'تُنفَّذ عبر طابور مهام التنفيذ'**
  String get ctViaTasksNote;

  /// No description provided for @ftTitle.
  ///
  /// In ar, this message translates to:
  /// **'مهام التنفيذ'**
  String get ftTitle;

  /// No description provided for @ftDescDispatch.
  ///
  /// In ar, this message translates to:
  /// **'مياه ومعدّات اكتمل تمويلها وصارت جاهزة للتنفيذ. أسند كل مهمّة لقائد فريق.'**
  String get ftDescDispatch;

  /// No description provided for @ftDescLeader.
  ///
  /// In ar, this message translates to:
  /// **'المهام المُسندة لفريقك. وزّعها على المنفّذين أو نفّذها بنفسك ووثّقها.'**
  String get ftDescLeader;

  /// No description provided for @ftDescHandler.
  ///
  /// In ar, this message translates to:
  /// **'المهام المُسندة إليك. نفّذها وأرفق بيان التنفيذ وصورته.'**
  String get ftDescHandler;

  /// No description provided for @ftFilterOpen.
  ///
  /// In ar, this message translates to:
  /// **'المفتوحة'**
  String get ftFilterOpen;

  /// No description provided for @ftStatusAwaitingAssign.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الإسناد'**
  String get ftStatusAwaitingAssign;

  /// No description provided for @ftStatusAssignedToTeam.
  ///
  /// In ar, this message translates to:
  /// **'مُسندة لقائد'**
  String get ftStatusAssignedToTeam;

  /// No description provided for @ftStatusAssigned.
  ///
  /// In ar, this message translates to:
  /// **'مُسندة لمنفّذ'**
  String get ftStatusAssigned;

  /// No description provided for @ftStatusDone.
  ///
  /// In ar, this message translates to:
  /// **'منفَّذة'**
  String get ftStatusDone;

  /// No description provided for @ftStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get ftStatusCancelled;

  /// No description provided for @ftAssignHandler.
  ///
  /// In ar, this message translates to:
  /// **'إسناد لمنفّذ'**
  String get ftAssignHandler;

  /// No description provided for @ftChooseHandler.
  ///
  /// In ar, this message translates to:
  /// **'اختر منفّذًا'**
  String get ftChooseHandler;

  /// No description provided for @ftNoHandlers.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد منفّذون'**
  String get ftNoHandlers;

  /// No description provided for @ftFieldHandler.
  ///
  /// In ar, this message translates to:
  /// **'المنفّذ'**
  String get ftFieldHandler;

  /// No description provided for @ftFullyFunded.
  ///
  /// In ar, this message translates to:
  /// **'مموَّلة بالكامل: {amount} د.ك'**
  String ftFullyFunded(String amount);

  /// No description provided for @ftFulfil.
  ///
  /// In ar, this message translates to:
  /// **'تنفيذ المهمّة'**
  String get ftFulfil;

  /// No description provided for @ftFulfilled.
  ///
  /// In ar, this message translates to:
  /// **'تم تنفيذ المهمّة'**
  String get ftFulfilled;

  /// No description provided for @ftStatement.
  ///
  /// In ar, this message translates to:
  /// **'بيان التنفيذ'**
  String get ftStatement;

  /// No description provided for @ftStatementHint.
  ///
  /// In ar, this message translates to:
  /// **'صف ما تم تنفيذه'**
  String get ftStatementHint;

  /// No description provided for @ftStatementRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بيان التنفيذ'**
  String get ftStatementRequired;

  /// No description provided for @ftPhotoRequired.
  ///
  /// In ar, this message translates to:
  /// **'أرفق صورة التنفيذ'**
  String get ftPhotoRequired;

  /// No description provided for @mtPhotosRequired.
  ///
  /// In ar, this message translates to:
  /// **'أرفق صورة إنجاز واحدة على الأقل'**
  String get mtPhotosRequired;

  /// No description provided for @mtPhotosMax.
  ///
  /// In ar, this message translates to:
  /// **'الحدّ الأقصى {count} صور'**
  String mtPhotosMax(int count);

  /// No description provided for @dedicationAlive.
  ///
  /// In ar, this message translates to:
  /// **'حيّ'**
  String get dedicationAlive;

  /// No description provided for @dedicationDeceased.
  ///
  /// In ar, this message translates to:
  /// **'متوفّى'**
  String get dedicationDeceased;

  /// No description provided for @mtClaim.
  ///
  /// In ar, this message translates to:
  /// **'التقاط البلاغ'**
  String get mtClaim;

  /// No description provided for @mtClaimConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سيُسنَد هذا البلاغ إليك وإلى فريقك. متابعة؟'**
  String get mtClaimConfirm;

  /// No description provided for @mtReadyToClaim.
  ///
  /// In ar, this message translates to:
  /// **'جاهز للالتقاط'**
  String get mtReadyToClaim;

  /// No description provided for @mtChannelManager.
  ///
  /// In ar, this message translates to:
  /// **'بترتيب الإدارة'**
  String get mtChannelManager;

  /// No description provided for @dpTitle.
  ///
  /// In ar, this message translates to:
  /// **'رفع حاجة مباشرة'**
  String get dpTitle;

  /// No description provided for @dpDesc.
  ///
  /// In ar, this message translates to:
  /// **'سجّل حاجة مياه أو معدّة أو صيانة لأي مسجد في نطاقك — تُنشر فورًا بلا مرحلة اعتماد.'**
  String get dpDesc;

  /// No description provided for @dpWater.
  ///
  /// In ar, this message translates to:
  /// **'نقص مياه'**
  String get dpWater;

  /// No description provided for @dpWaterDesc.
  ///
  /// In ar, this message translates to:
  /// **'علَم نقص مياه يُنشر للتمويل فورًا'**
  String get dpWaterDesc;

  /// No description provided for @dpWaterConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سيُرفع علَم نقص مياه لهذا المسجد ويُنشر فورًا. متابعة؟'**
  String get dpWaterConfirm;

  /// No description provided for @dpEquipment.
  ///
  /// In ar, this message translates to:
  /// **'طلب معدّة'**
  String get dpEquipment;

  /// No description provided for @dpEquipmentDesc.
  ///
  /// In ar, this message translates to:
  /// **'معدّة جديدة تُنشر للتمويل فورًا'**
  String get dpEquipmentDesc;

  /// No description provided for @dpMaintenance.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ صيانة'**
  String get dpMaintenance;

  /// No description provided for @dpMaintenanceDesc.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ على وحدة قائمة، يدخل طابور الالتقاط'**
  String get dpMaintenanceDesc;

  /// No description provided for @dpMosque.
  ///
  /// In ar, this message translates to:
  /// **'المسجد'**
  String get dpMosque;

  /// No description provided for @dpMosqueRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر المسجد أولًا'**
  String get dpMosqueRequired;

  /// No description provided for @dpEquipmentType.
  ///
  /// In ar, this message translates to:
  /// **'نوع المعدّة'**
  String get dpEquipmentType;

  /// No description provided for @dpModel.
  ///
  /// In ar, this message translates to:
  /// **'الموديل'**
  String get dpModel;

  /// No description provided for @dpModelRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر الموديل'**
  String get dpModelRequired;

  /// No description provided for @dpNoTypes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أنواع معدّات'**
  String get dpNoTypes;

  /// No description provided for @dpNoModels.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد موديلات لهذا النوع'**
  String get dpNoModels;

  /// No description provided for @dpTargetAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المستهدف'**
  String get dpTargetAmountLabel;

  /// No description provided for @dpTargetAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المستهدف: {amount} د.ك'**
  String dpTargetAmount(String amount);

  /// No description provided for @dpNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get dpNote;

  /// No description provided for @dpUnit.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة'**
  String get dpUnit;

  /// No description provided for @dpNoUnits.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وحدات مسجّلة في هذا المسجد'**
  String get dpNoUnits;

  /// No description provided for @dpUnitInWarranty.
  ///
  /// In ar, this message translates to:
  /// **'ضمن الضمان'**
  String get dpUnitInWarranty;

  /// No description provided for @dpCostPath.
  ///
  /// In ar, this message translates to:
  /// **'مسار التكلفة'**
  String get dpCostPath;

  /// No description provided for @dpSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get dpSubmit;

  /// No description provided for @dpCreated.
  ///
  /// In ar, this message translates to:
  /// **'تمّ الإنشاء ونُشر مباشرة'**
  String get dpCreated;

  /// No description provided for @locSortedByDistance.
  ///
  /// In ar, this message translates to:
  /// **'مرتّبة حسب الأقرب إليك · المسافة تقديرية بخط مستقيم'**
  String get locSortedByDistance;

  /// No description provided for @locEnableHint.
  ///
  /// In ar, this message translates to:
  /// **'فعّل إذن الموقع لترتيب المهام من الأقرب'**
  String get locEnableHint;

  /// No description provided for @locUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الموقع غير متوفّر'**
  String get locUnavailable;

  /// No description provided for @locDistanceKm.
  ///
  /// In ar, this message translates to:
  /// **'{km} كم'**
  String locDistanceKm(String km);

  /// No description provided for @locNearestDestination.
  ///
  /// In ar, this message translates to:
  /// **'أقرب وجهة: {km} كم'**
  String locNearestDestination(String km);

  /// No description provided for @locDirections.
  ///
  /// In ar, this message translates to:
  /// **'الاتجاهات'**
  String get locDirections;

  /// No description provided for @coTitle.
  ///
  /// In ar, this message translates to:
  /// **'شراء معدّات من المتجر'**
  String get coTitle;

  /// No description provided for @coDesc.
  ///
  /// In ar, this message translates to:
  /// **'معدّات يشتريها العملاء لمسجد معيّن. راجع الطلب واعتمده ليُفتح للعميل باب الدفع.'**
  String get coDesc;

  /// No description provided for @coDescField.
  ///
  /// In ar, this message translates to:
  /// **'معدّات مدفوعة بانتظار الإسناد أو التركيب وتوثيقه.'**
  String get coDescField;

  /// No description provided for @coDescWatch.
  ///
  /// In ar, this message translates to:
  /// **'متابعة مشتريات العملاء من الاعتماد حتى التركيب.'**
  String get coDescWatch;

  /// No description provided for @coStatusUnderReview.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get coStatusUnderReview;

  /// No description provided for @coStatusApproved.
  ///
  /// In ar, this message translates to:
  /// **'معتمَد — بانتظار الدفع'**
  String get coStatusApproved;

  /// No description provided for @coStatusPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع'**
  String get coStatusPaid;

  /// No description provided for @coStatusInstalled.
  ///
  /// In ar, this message translates to:
  /// **'تم التركيب'**
  String get coStatusInstalled;

  /// No description provided for @coStatusRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get coStatusRejected;

  /// No description provided for @coApproveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'بالموافقة تُفتح للعميل مهلة دفع ٤٨ ساعة. متابعة؟'**
  String get coApproveConfirm;

  /// No description provided for @coInstall.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل التركيب'**
  String get coInstall;

  /// No description provided for @coInstallConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سيُسجَّل تركيب الوحدة ويُصدَر لها رمز وضمان. متابعة؟'**
  String get coInstallConfirm;

  /// No description provided for @coAwaitingPayment.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار دفع العميل حتى {deadline}'**
  String coAwaitingPayment(String deadline);
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
