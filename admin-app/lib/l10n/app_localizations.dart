import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

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

  /// No description provided for @tabNew.
  ///
  /// In ar, this message translates to:
  /// **'جديدة'**
  String get tabNew;

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
  /// **'قيد التنفيذ'**
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
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
