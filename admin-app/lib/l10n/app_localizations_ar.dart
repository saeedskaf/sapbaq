// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get searchCountry => 'ابحث عن دولة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get genericError => 'حدث خطأ غير متوقّع';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get noSearchResults => 'لا توجد نتائج';

  @override
  String get phoneRequired => 'رقم الهاتف مطلوب';

  @override
  String get phoneTooShort => 'رقم الهاتف قصير جدًا';

  @override
  String get phoneTooLong => 'رقم الهاتف طويل جدًا';

  @override
  String get phoneOnlyNumbers => 'يجب أن يحتوي رقم الهاتف على أرقام فقط';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get passwordTooShort => 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';

  @override
  String get confirmPasswordRequired => 'يرجى تأكيد كلمة المرور';

  @override
  String get passwordsNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get fullNameRequired => 'الاسم مطلوب';

  @override
  String get fullNameTooShort => 'الاسم قصير جدًا';

  @override
  String get fullNameTooLong => 'الاسم طويل جدًا';

  @override
  String get otpRequired => 'رمز التحقق مطلوب';

  @override
  String get otpInvalid => 'يجب أن يتكون رمز التحقق من 6 أرقام';

  @override
  String get otpOnlyNumbers => 'يجب أن يحتوي رمز التحقق على أرقام فقط';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get emailInvalid => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginStaffSubtitle => 'سجّل الدخول بحساب الإدارة أو الورشة';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get loginButton => 'دخول';

  @override
  String get unauthorizedTitle => 'هذا التطبيق للموظفين فقط';

  @override
  String get unauthorizedDesc =>
      'حسابك لا يملك صلاحية الدخول إلى تطبيق الإدارة والسائق.';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get navDashboard => 'اللوحة';

  @override
  String get navOrders => 'الطلبات';

  @override
  String get navDeliveries => 'التوصيلات';

  @override
  String get navNotifications => 'الإشعارات';

  @override
  String get navProfile => 'حسابي';

  @override
  String get navCustomerSearch => 'بحث العميل';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusConfirmed => 'مؤكَّد';

  @override
  String get statusAssignedToTeam => 'مُسنَد لقائد فريق';

  @override
  String get statusAssigned => 'مُسنَد';

  @override
  String get statusInDelivery => 'قيد التوصيل';

  @override
  String get statusDelivered => 'تم التوصيل';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get typeMosque => 'مسجد محدد';

  @override
  String get typeMostNeeded => 'الأكثر حاجة';

  @override
  String orderRefShort(String ref) {
    return 'طلب $ref';
  }

  @override
  String destinationsCount(int count) {
    return '$count وجهة';
  }

  @override
  String priceKwd(String amount) {
    return '$amount د.ك';
  }

  @override
  String workshopActiveLoad(int count) {
    return '$count توصيلة حالية';
  }

  @override
  String get adminOrdersTitle => 'الطلبات';

  @override
  String get searchOrdersHint => 'ابحث برقم العميل أو رقم الطلب (ORD-…)';

  @override
  String get emptyOrders => 'لا توجد طلبات';

  @override
  String ordersCount(int count) {
    return '$count طلب';
  }

  @override
  String get awaitingAssignmentBadge => 'يحتاج إسناد';

  @override
  String get tabAwaiting => 'بانتظار الإسناد';

  @override
  String get tabAll => 'الكل';

  @override
  String get tabDelivered => 'تم التوصيل';

  @override
  String get tabCancelled => 'ملغاة';

  @override
  String get tabInProgress => 'قيد التنفيذ';

  @override
  String get tabNew => 'جديدة';

  @override
  String get tabConfirmed => 'مؤكّدة';

  @override
  String get orderDateLabel => 'تاريخ الطلب';

  @override
  String get lastStatusUpdateLabel => 'آخر تحديث';

  @override
  String get orderDetailsTitle => 'تفاصيل الطلب';

  @override
  String get giftLabel => 'يحتوي على إهداء';

  @override
  String get customerLabel => 'العميل';

  @override
  String get paymentLabel => 'الدفع';

  @override
  String get paymentPaid => 'مدفوع';

  @override
  String get paymentUnpaid => 'غير مدفوع';

  @override
  String get notesLabel => 'ملاحظات العميل';

  @override
  String get destinationsLabel => 'الوجهات';

  @override
  String get cancelReasonLabel => 'سبب الإلغاء';

  @override
  String get totalLabel => 'الإجمالي';

  @override
  String get subtotalLabel => 'المجموع الفرعي';

  @override
  String get noLocation => 'لا يوجد موقع على الخريطة';

  @override
  String get openLocation => 'فتح الموقع';

  @override
  String get assignedWorkshopLabel => 'الورشة المُسنَدة';

  @override
  String get teamLeaderLabel => 'قائد الفريق';

  @override
  String get assignButton => 'إسناد الورش';

  @override
  String get assignToTeamLeaderButton => 'إسناد لقائد فريق';

  @override
  String get distributeToHandler => 'توزيع لمنفّذ';

  @override
  String get approveCompletion => 'اعتماد الإنجاز';

  @override
  String get cancelOrderButton => 'إلغاء الطلب';

  @override
  String get cancelOrderTitle => 'إلغاء الطلب';

  @override
  String get cancelReasonHint => 'سبب الإلغاء';

  @override
  String get confirmCancel => 'تأكيد الإلغاء';

  @override
  String get keepOrder => 'تراجع';

  @override
  String get orderCancelled => 'تم إلغاء الطلب';

  @override
  String get assignTitle => 'إسناد الورش';

  @override
  String get chooseWorkshop => 'اختر الورشة';

  @override
  String get chooseMosque => 'اختر المسجد';

  @override
  String get mosquesSelectGovernorate => 'اختر المحافظة';

  @override
  String get mosquesSelectArea => 'اختر المنطقة';

  @override
  String get mosquesNoAreas => 'لا توجد مناطق في هذه المحافظة';

  @override
  String get mosquesNone => 'لا توجد مساجد';

  @override
  String get chooseTeamLeader => 'اختر قائد الفريق';

  @override
  String get chooseHandlerWhoDelivered => 'اختر المنفّذ الذي نفّذ';

  @override
  String get confirmAssign => 'تأكيد الإسناد';

  @override
  String get assignSuccess => 'تم إسناد الورش بنجاح';

  @override
  String get assignTeamSuccess => 'تم الإسناد لقائد الفريق بنجاح';

  @override
  String get distributeSuccess => 'تم توزيع الوجهة للمنفّذ بنجاح';

  @override
  String get completeSuccess => 'تم اعتماد إنجاز الوجهة بنجاح';

  @override
  String get noWorkshops => 'لا توجد ورش متاحة';

  @override
  String get noTeamLeaders => 'لا يوجد قادة فرق متاحون';

  @override
  String get searchMosqueHint => 'ابحث عن مسجد';

  @override
  String get reassignButton => 'إعادة الإسناد';

  @override
  String get reassignSuccess => 'تمت إعادة الإسناد بنجاح';

  @override
  String get noOtherWorkshops => 'لا توجد ورشة أخرى متاحة';

  @override
  String get timelineLabel => 'سجل الطلب';

  @override
  String get callButton => 'اتصال';

  @override
  String get whatsappButton => 'واتساب';

  @override
  String get contactFailed => 'تعذّر بدء الاتصال';

  @override
  String get driverDeliveriesTitle => 'توصيلاتي';

  @override
  String get tabAccepted => 'مقبولة';

  @override
  String get tabInDelivery => 'قيد التوصيل';

  @override
  String get tabCompleted => 'مكتملة';

  @override
  String get emptyDeliveries => 'لا توجد توصيلات';

  @override
  String get deliveryDetailsTitle => 'تفاصيل التوصيلة';

  @override
  String get acceptButton => 'قبول';

  @override
  String get rejectButton => 'رفض';

  @override
  String get startDeliveryButton => 'بدء التوصيل';

  @override
  String get uploadProofButton => 'رفع التوثيق وإنهاء التوصيل';

  @override
  String get acceptedMsg => 'تم قبول التوصيلة';

  @override
  String get deliveryStartedMsg => 'بدأت التوصيل';

  @override
  String get rejectedMsg => 'تم رفض التوصيلة';

  @override
  String get deliveredNote => 'تم توصيل هذه الوجهة';

  @override
  String get rejectTitle => 'رفض التوصيلة';

  @override
  String get rejectReasonHint => 'سبب الرفض (اختياري)';

  @override
  String get confirmReject => 'تأكيد الرفض';

  @override
  String get proofTitle => 'توثيق التوصيل';

  @override
  String get proofHint =>
      'أضف صورًا أو فيديو لإثبات التركيب، ثم ارفعها لإنهاء التوصيل.';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get fromGallery => 'من المعرض';

  @override
  String get addVideo => 'فيديو';

  @override
  String get proofNoteHint => 'ملاحظة (اختياري)';

  @override
  String get proofNoteDefaultDelivered => 'تم إيصال وتركيب الطلب في الموقع.';

  @override
  String get uploadAndFinish => 'رفع وإنهاء التوصيل';

  @override
  String get pickFailed => 'تعذّر اختيار الملف';

  @override
  String get noProofSelected => 'اختر صورة أو فيديو أولاً';

  @override
  String get proofUploaded => 'تم رفع التوثيق — تم التوصيل';

  @override
  String get deliveryProofs => 'توثيقات التسليم';

  @override
  String get cannotOpenFile => 'تعذّر فتح الملف';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get emptyNotifications => 'لا توجد إشعارات';

  @override
  String get markAllRead => 'تعليم الكل كمقروء';

  @override
  String get dashboardTitle => 'اللوحة';

  @override
  String get dashNew => 'جديدة';

  @override
  String get dashAwaiting => 'بانتظار الإسناد';

  @override
  String get dashAssigned => 'مؤكّدة';

  @override
  String get dashCompleted => 'مكتملة';

  @override
  String get dashCancelled => 'ملغاة';

  @override
  String get dashAll => 'الإجمالي';

  @override
  String get completionRate => 'نسبة الإكمال';

  @override
  String get slaTitle => 'متوسّط زمن الخدمة';

  @override
  String get slaAvgConfirm => 'متوسّط زمن التأكيد';

  @override
  String get slaAvgDeliver => 'متوسّط زمن التوصيل';

  @override
  String get slaSample => 'عدد الطلبات المكتملة';

  @override
  String minutesValue(String value) {
    return '$value دقيقة';
  }

  @override
  String get activityTitle => 'نشاطي';

  @override
  String get emptyActivity => 'لا يوجد نشاط';

  @override
  String get actionAssigned => 'إسناد وجهة لورشة';

  @override
  String get actionReassigned => 'إعادة إسناد وجهة';

  @override
  String get actionCancelled => 'إلغاء طلب';

  @override
  String get customerLookupTitle => 'بحث عن عميل';

  @override
  String get lookupHint => 'ابحث برقم الهاتف أو الاسم';

  @override
  String get lookupPrompt =>
      'ابحث عن عميل برقم الهاتف أو الاسم أو المعرّف (ID) لعرض سجلّه';

  @override
  String get lookupIdHint => 'ID';

  @override
  String get lookupNoResults => 'لا يوجد عميل مطابق';

  @override
  String get approvalsTitle => 'صندوق الموافقات';

  @override
  String get emptyApprovals => 'لا توجد موافقات معلّقة';

  @override
  String get approveButton => 'اعتماد';

  @override
  String get approvePickModel => 'اختر الموديل المعتمَد';

  @override
  String get approveModelNote =>
      'اختيار الموديل يثبّت هدف التمويل، ثم يُنشر الطلب لتموّله التبرّعات.';

  @override
  String approveWithTarget(String amount) {
    return 'اعتماد بهدف $amount د.ك';
  }

  @override
  String get approveSuccess => 'تم اعتماد الطلب';

  @override
  String get rejectSuccess => 'تم رفض الطلب';

  @override
  String get approvalRejectTitle => 'سبب الرفض';

  @override
  String get approvalRejectHint => 'اكتب سبب الرفض';

  @override
  String get approvalMakerLabel => 'مقدّم الطلب';

  @override
  String get escalationsTitle => 'التصعيدات';

  @override
  String get emptyEscalations => 'لا توجد تصعيدات';

  @override
  String get resolveButton => 'تم الحل';

  @override
  String get resolveSuccess => 'تم حلّ التصعيد';

  @override
  String get raiseEscalationTitle => 'رفع تصعيد';

  @override
  String get raiseEscalationHint => 'اكتب سبب التصعيد';

  @override
  String get escalationRaised => 'تم رفع التصعيد';

  @override
  String get escalationRaisedByLabel => 'بواسطة';

  @override
  String get statusOpen => 'مفتوح';

  @override
  String get statusResolved => 'تم الحل';

  @override
  String get productsTitle => 'توفّر المنتجات';

  @override
  String get searchProductsHint => 'ابحث عن منتج';

  @override
  String get emptyProducts => 'لا توجد منتجات';

  @override
  String get productSuspended => 'موقوف';

  @override
  String get productInactive => 'غير نشط (يُدار من الويب)';

  @override
  String productVariantsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تنويعًا',
      few: '$count تنويعات',
      two: 'تنويعان',
      one: 'تنويع واحد',
    );
    return '$_temp0';
  }

  @override
  String get suspendReasonTitle => 'سبب الإيقاف';

  @override
  String get suspendReasonHint => 'مثال: نفاد المخزون (اختياري)';

  @override
  String get suspendConfirm => 'إيقاف';

  @override
  String get profileTitle => 'حسابي';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get roleDriver => 'ورشة توصيل';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get userFallback => 'مستخدم';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get appearanceTitle => 'المظهر';

  @override
  String get themeSystem => 'حسب إعدادات الجهاز';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get notificationChannelName => 'إشعارات ســـبّاقـــ';

  @override
  String get notificationChannelDescription =>
      'تعيينات الطلبات وتحديثات التوصيل.';

  @override
  String get confirmButton => 'تأكيد';

  @override
  String get saveButton => 'حفظ';

  @override
  String get nextButton => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get otpLabel => 'رمز التحقق';

  @override
  String get sendCodeButton => 'إرسال الرمز';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String resendCodeIn(int seconds) {
    return 'إعادة الإرسال خلال $seconds ثانية';
  }

  @override
  String get filterGovernorate => 'المحافظة';

  @override
  String get filterArea => 'المنطقة';

  @override
  String get repEntryPrompt => 'هل أنت ممثل مسجد؟ اضغط هنا';

  @override
  String get repLoginTitle => 'دخول ممثل المسجد';

  @override
  String get repLoginSubtitle => 'أدخل رقم هاتفك للمتابعة';

  @override
  String get repPasscodeLabel => 'الرمز السري';

  @override
  String get repPasscodeRequired => 'أدخل الرمز السري المكوّن من 4 أرقام';

  @override
  String get repPasscodeStepTitle => 'أدخل الرمز السري';

  @override
  String get repPasscodeStepSubtitle =>
      'أدخل رمزك السري المكوّن من 4 أرقام لتسجيل الدخول';

  @override
  String get repChangePhone => 'تغيير الرقم';

  @override
  String get continueButton => 'متابعة';

  @override
  String get repForgotPasscode => 'نسيت الرمز السري؟';

  @override
  String get repForgotSubtitle =>
      'سنرسل رمز تحقق إلى هاتفك لتعيين رمز سري جديد';

  @override
  String get repPasscodeResetDone => 'تم تعيين الرمز السري الجديد';

  @override
  String get repRegisterButton => 'تسجيل ممثل جديد';

  @override
  String get repHaveInvite => 'لديّ رابط دعوة';

  @override
  String get repRegisterTitle => 'تسجيل ممثل مسجد';

  @override
  String get repRegisterPhoneStep => 'أدخل رقم هاتفك لإرسال رمز التحقق';

  @override
  String get repRegisterIdentityStep => 'أدخل رمز التحقق واسمك';

  @override
  String get repRegisterMosqueStep =>
      'حدّد مسجدك بدقة: المحافظة ثم المنطقة ثم المسجد';

  @override
  String get repRegisterPasscodeStep =>
      'أنشئ رمزًا سريًا من 4 أرقام للدخول اليومي';

  @override
  String get repFillAllFields => 'يرجى تعبئة جميع الحقول المطلوبة';

  @override
  String get repFirstName => 'الاسم الأول';

  @override
  String get repLastName => 'اسم العائلة';

  @override
  String get repSearchMosque => 'ابحث عن المسجد بالاسم';

  @override
  String get repPasscodeCreate => 'الرمز السري الجديد';

  @override
  String get repPasscodeConfirm => 'تأكيد الرمز السري';

  @override
  String get repPasscodeMismatch => 'الرمزان غير متطابقين';

  @override
  String get repRegisterSubmit => 'إرسال الطلب';

  @override
  String get repInviteTitle => 'التسجيل بدعوة';

  @override
  String get repInviteSubtitle => 'أدخل رمز الدعوة الذي وصلك من سبّاق';

  @override
  String get repInviteToken => 'رمز الدعوة';

  @override
  String get repInviteCheck => 'تحقق من الدعوة';

  @override
  String get repPendingTitle => 'طلبك قيد المراجعة';

  @override
  String get repPendingBody =>
      'استلمنا طلب تسجيلك كممثل مسجد. سيتواصل معك فريق سبّاق للتحقق ثم يُفعَّل حسابك — بعدها يمكنك تسجيل الدخول برقم هاتفك ورمزك السري.';

  @override
  String get repBackToLogin => 'العودة لتسجيل الدخول';

  @override
  String get repNavMosque => 'مسجدي';

  @override
  String get repNavReports => 'بلاغاتي';

  @override
  String get repActionsTitle => 'الإجراءات';

  @override
  String get repReportMaintenance => 'بلاغ صيانة';

  @override
  String get repReportMaintenanceDesc => 'أبلغ عن عطل في وحدة مسجّلة بمسجدك';

  @override
  String get repWaterFlagTitle => 'نقص مياه';

  @override
  String get repWaterFlagDesc =>
      'أبلغ بنقرة واحدة أن مياه المسجد شارفت على النفاد';

  @override
  String get repWaterFlagConfirm =>
      'هل تريد إرسال بلاغ نقص مياه لمسجدك؟ سيظهر للمستخدمين بعد اعتماده.';

  @override
  String get repWaterFlagSent => 'تم إرسال بلاغ نقص المياه';

  @override
  String get repRequestEquipment => 'طلب معدّة جديدة';

  @override
  String get repRequestEquipmentDesc => 'اطلب مبرّد ماء أو ثلاجة جديدة لمسجدك';

  @override
  String get repUnitsTitle => 'معدّات مسجدي';

  @override
  String get repNoUnits => 'لا توجد معدّات مسجّلة لمسجدك بعد';

  @override
  String get repStatusPending => 'بانتظار الاعتماد';

  @override
  String get repStatusDeactivated => 'معطَّل';

  @override
  String get repPickUnit => 'اختر الوحدة';

  @override
  String get repIssueType => 'نوع العطل';

  @override
  String get repIssueFilterChange => 'تغيير فلاتر';

  @override
  String get repIssueNotWorking => 'لا يعمل';

  @override
  String get repIssueLeaking => 'تسريب';

  @override
  String get repIssueOther => 'أخرى';

  @override
  String get repIssueOtherNeedsDesc => 'الوصف مطلوب عند اختيار «أخرى»';

  @override
  String get repIssueDescription => 'وصف العطل';

  @override
  String get repReportSubmit => 'إرسال البلاغ';

  @override
  String get repReportSent => 'تم إرسال البلاغ';

  @override
  String get repEquipmentType => 'نوع المعدّة';

  @override
  String get repEquipmentNote => 'ملاحظة (اختياري)';

  @override
  String get repEquipmentRequestSent => 'تم إرسال طلب المعدّة';

  @override
  String get repTabMaintenance => 'الصيانة';

  @override
  String get repTabWater => 'المياه';

  @override
  String get repTabEquipment => 'المعدّات';

  @override
  String get repNoReports => 'لا توجد بلاغات بعد';

  @override
  String get repStatusSubmitted => 'مُقدَّم';

  @override
  String get repStatusInProgress => 'قيد التنفيذ';

  @override
  String get repStatusResolved => 'مُنجَز';

  @override
  String get repStatusApproved => 'معتمَد';

  @override
  String get repStatusFulfilled => 'مُنفَّذ';

  @override
  String get repStatusRejected => 'مرفوض';

  @override
  String get repStatusCancelled => 'ملغى';

  @override
  String get repRefresh => 'تحديث';

  @override
  String get repFieldReference => 'رقم البلاغ';

  @override
  String get repFieldEquipmentCode => 'رمز الجهاز';

  @override
  String get repFieldIssue => 'نوع العطل';

  @override
  String get repFieldDescription => 'الوصف';

  @override
  String get repFieldNote => 'ملاحظة';

  @override
  String get repFieldDate => 'تاريخ التقديم';

  @override
  String get repFieldApprovedAt => 'تاريخ الاعتماد';

  @override
  String get repFieldFulfilledAt => 'تاريخ التنفيذ';

  @override
  String get repFieldResolvedAt => 'تاريخ الإنجاز';

  @override
  String get repFieldRejectReason => 'سبب الرفض';

  @override
  String get repPhotos => 'الصور';

  @override
  String get repAddPhotos => 'إضافة صور';

  @override
  String get repPhotosHint => 'اختياري — حتى 5 صور';

  @override
  String get repMaxPhotos => 'يمكنك إضافة حتى 5 صور';

  @override
  String get opsTitle => 'مركز العمليات';

  @override
  String get opsSubtitle => 'كل ما يحتاج إجراءً منك، مرتّبًا حسب صلاحيات دورك';

  @override
  String opsPendingTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصرًا بانتظار إجراءك',
      few: '$count عناصر بانتظار إجراءك',
      two: 'عنصران بانتظار إجراءك',
      one: 'عنصر واحد بانتظار إجراءك',
    );
    return '$_temp0';
  }

  @override
  String get opsAllClear => 'لا شيء بانتظار إجراءك';

  @override
  String get opsAllClearDesc => 'كل الطوابير المتاحة لدورك فارغة الآن';

  @override
  String get opsUpdating => 'جارٍ تحديث الأرقام…';

  @override
  String get opsNothingHere => 'لا جديد الآن';

  @override
  String opsRoleScope(String name) {
    return 'نطاقك: $name';
  }

  @override
  String get opsNoQueues => 'لا توجد طوابير متاحة لدورك حاليًا';

  @override
  String get opsSectionApprovals => 'بانتظار قرارك';

  @override
  String get opsSectionApprovalsDesc =>
      'طلبات ترفعها المساجد أو يشتريها المتبرّعون، ولا تتحرّك قبل اعتمادك.';

  @override
  String get opsSectionField => 'التنفيذ والمتابعة';

  @override
  String get opsSectionFieldDesc =>
      'ما بعد الاعتماد: إسناد المهام، تنفيذها ميدانيًا، وتوثيق الإنجاز.';

  @override
  String get opsSectionCreate => 'إنشاء بلاغ';

  @override
  String get opsSectionCreateDesc =>
      'سجّل حاجة نيابة عن الإدارة دون انتظار طلب من المسجد.';

  @override
  String get opsHowItWorks => 'كيف تسير العمليات؟';

  @override
  String get opsHowStep1 => 'طلب';

  @override
  String get opsHowStep1Desc =>
      'يرفع إمام المسجد بلاغ نقص مياه أو طلب معدّة، أو يشتري متبرّع معدّة من المتجر.';

  @override
  String get opsHowStep2 => 'اعتماد';

  @override
  String get opsHowStep2Desc =>
      'تراجعه الإدارة: المعتمَد يُعرض للتبرّع، والمرفوض يُغلق بسبب مكتوب.';

  @override
  String get opsHowStep3 => 'تمويل';

  @override
  String get opsHowStep3Desc =>
      'يكتمل مبلغ الحاجة من تبرّعات المتبرّعين، فتتحوّل إلى مهمّة تنفيذ.';

  @override
  String get opsHowStep4 => 'إسناد';

  @override
  String get opsHowStep4Desc =>
      'تُسنَد المهمّة لقائد فريق، ثم يوزّعها على منفّذ ميداني.';

  @override
  String get opsHowStep5 => 'تنفيذ وتوثيق';

  @override
  String get opsHowStep5Desc =>
      'ينفّذ المنفّذ المهمّة ويرفق بيانًا وصور إنجاز تُغلق بها.';

  @override
  String get opsHowFooter =>
      'تظهر لك الطوابير التي يسمح بها دورك فقط، ومحصورة في نطاقك الجغرافي.';

  @override
  String get navOperations => 'العمليات';

  @override
  String get opsWaterFlags => 'بلاغات نقص المياه';

  @override
  String get opsWaterFlagsDesc =>
      'بلاغات يرفعها أئمة المساجد عند نقص مياه الشرب. اعتمد البلاغ ليُعرض للتبرّع، أو ألغِه.';

  @override
  String get opsWaterFlagItem => 'بلاغ نقص مياه';

  @override
  String get opsEquipmentRequests => 'طلبات معدّات جديدة';

  @override
  String get opsEquipmentRequestsDesc =>
      'طلبات الأئمة لتزويد المسجد بمعدّة. اعتمد الطلب لتبدأ حملة تمويله، أو ارفضه.';

  @override
  String get opsEquipmentRequestItem => 'طلب معدّة';

  @override
  String get opsEmptyQueue => 'لا عناصر في هذا الطابور';

  @override
  String get opsMosque => 'المسجد';

  @override
  String get opsConfirmCancel => 'إلغاء هذا الطلب؟';

  @override
  String get opsCancelAction => 'إلغاء الطلب';

  @override
  String get opsFilterMonth => 'الشهر';

  @override
  String get opsFilterStatus => 'الحالة';

  @override
  String get opsFilterPriority => 'الأولوية';

  @override
  String get opsFilterKind => 'النوع';

  @override
  String get opsFilterAny => 'الكل';

  @override
  String get opsFilterAllTime => 'كل الفترات';

  @override
  String get mtTitle => 'بلاغات الصيانة';

  @override
  String get mtCaseTitle => 'تفاصيل البلاغ';

  @override
  String get mtDescTriage =>
      'أعطال المعدّات المركّبة. أقرّ البلاغ، حدّد الأولوية ومسار التكلفة، ثم أسنده لقائد فريق.';

  @override
  String get mtDescLeader =>
      'التقط البلاغات المعتمَدة في نطاقك، وزّعها على أعضاء فريقك، ووثّق إنجازها.';

  @override
  String get mtDescHandler =>
      'بلاغات الصيانة المُسندة إليك. نفّذ الإصلاح وأرفق صور الإنجاز.';

  @override
  String get mtStatusSubmitted => 'مُقدَّم';

  @override
  String get mtStatusAcknowledged => 'تم الإقرار';

  @override
  String get mtStatusApproved => 'معتمَد';

  @override
  String get mtStatusAssigned => 'مُسنَد لقائد';

  @override
  String get mtStatusInProgress => 'قيد التنفيذ';

  @override
  String get mtStatusCompleted => 'مكتمل';

  @override
  String get mtStatusResolved => 'مُنجَز';

  @override
  String get mtStatusDuplicate => 'مكرّر';

  @override
  String get mtStatusCancelled => 'ملغى';

  @override
  String get mtPriorityLow => 'منخفضة';

  @override
  String get mtPriorityMedium => 'متوسطة';

  @override
  String get mtPriorityHigh => 'عالية';

  @override
  String get mtPriorityUrgent => 'عاجلة';

  @override
  String get mtCostUnset => 'غير محدّد';

  @override
  String get mtCostFreeWarranty => 'مجّاني (ضمان)';

  @override
  String get mtCostManufacturer => 'المصنّع (كمبروسر)';

  @override
  String get mtCostCustomerPaid => 'يموّله عميل';

  @override
  String get mtFieldPriority => 'الأولوية';

  @override
  String get mtFieldCostPath => 'مسار التكلفة';

  @override
  String get mtFieldPrice => 'السعر';

  @override
  String get mtFieldReporter => 'المُبلِّغ';

  @override
  String get mtFieldTeamLeader => 'قائد الفريق';

  @override
  String get mtFieldMember => 'العضو';

  @override
  String get mtFieldStatement => 'بيان الإنجاز';

  @override
  String get mtAcknowledge => 'إقرار';

  @override
  String get mtSetPriority => 'تحديد الأولوية';

  @override
  String get mtAssignLeader => 'إسناد لقائد فريق';

  @override
  String get mtAssignMember => 'إسناد لعضو';

  @override
  String get mtComplete => 'إنجاز';

  @override
  String get mtVerify => 'توثيق الإنجاز';

  @override
  String get mtCancelCase => 'إلغاء البلاغ';

  @override
  String get mtApproveTitle => 'اعتماد البلاغ';

  @override
  String get mtChooseCostPath => 'اختر مسار التكلفة';

  @override
  String get mtPriceKwd => 'السعر (د.ك)';

  @override
  String get mtPriceRequired => 'أدخل السعر للتمويل من العميل';

  @override
  String get mtChoosePriority => 'اختر الأولوية';

  @override
  String get mtChooseLeader => 'اختر قائد فريق';

  @override
  String get mtChooseMember => 'اختر عضوًا';

  @override
  String get mtStatementHint => 'صف ما تم إنجازه';

  @override
  String get mtStatementRequired => 'أدخل بيان الإنجاز';

  @override
  String get mtNoLeaders => 'لا يوجد قادة فرق';

  @override
  String get mtNoMembers => 'لا يوجد أعضاء';

  @override
  String mtActiveLoad(int count) {
    return '$count مهمة نشطة';
  }

  @override
  String mtSuggested(String label) {
    return 'مقترح: $label';
  }

  @override
  String get mtManufacturerRouted => 'موجّه للمصنّع';

  @override
  String get mtActionDone => 'تم التنفيذ';

  @override
  String get mtConfirmCancelCase => 'إلغاء بلاغ الصيانة هذا؟';

  @override
  String get mtDuplicate => 'دمج مكرّر';

  @override
  String get mtDuplicatePickHint => 'اختر البلاغ الأصلي لنفس المعدّة';

  @override
  String get mtDuplicateEmpty => 'لا توجد بلاغات أخرى لهذه المعدّة';

  @override
  String get mtDuplicateNoCode => 'لا يوجد رمز معدّة للبحث عن بلاغ أصلي';

  @override
  String mtMergedInto(int id) {
    return 'مدموج في البلاغ رقم $id';
  }

  @override
  String get mtSearchHint => 'بحث برمز المعدّة';

  @override
  String get ctTitle => 'المساهمات';

  @override
  String get ctDesc => 'سجل المساهمات ومبالغها وحالاتها';

  @override
  String get ctKindWater => 'مياه';

  @override
  String get ctKindMaintenance => 'صيانة';

  @override
  String get ctKindEquipment => 'معدّة';

  @override
  String get ctStatusPending => 'قيد الانتظار';

  @override
  String get ctStatusPaid => 'مدفوعة';

  @override
  String get ctStatusFulfilled => 'مُنفَّذة';

  @override
  String get ctStatusExpired => 'منتهية';

  @override
  String get ctStatusCancelled => 'ملغاة';

  @override
  String get ctCustomer => 'المتبرّع';

  @override
  String get ctMaintenanceAutoSettle =>
      'تُسوّى تلقائيًا عند توثيق بلاغ الصيانة';

  @override
  String get ctViaTasksNote => 'تُنفَّذ عبر طابور مهام التنفيذ';

  @override
  String get ftTitle => 'مهام التنفيذ';

  @override
  String get ftDescDispatch =>
      'مياه ومعدّات اكتمل تمويلها وصارت جاهزة للتنفيذ. أسند كل مهمّة لقائد فريق.';

  @override
  String get ftDescLeader =>
      'المهام المُسندة لفريقك. وزّعها على المنفّذين أو نفّذها بنفسك ووثّقها.';

  @override
  String get ftDescHandler =>
      'المهام المُسندة إليك. نفّذها وأرفق بيان التنفيذ وصورته.';

  @override
  String get ftFilterOpen => 'المفتوحة';

  @override
  String get ftStatusAwaitingAssign => 'بانتظار الإسناد';

  @override
  String get ftStatusAssignedToTeam => 'مُسندة لقائد';

  @override
  String get ftStatusAssigned => 'مُسندة لمنفّذ';

  @override
  String get ftStatusDone => 'منفَّذة';

  @override
  String get ftStatusCancelled => 'ملغاة';

  @override
  String get ftAssignHandler => 'إسناد لمنفّذ';

  @override
  String get ftChooseHandler => 'اختر منفّذًا';

  @override
  String get ftNoHandlers => 'لا يوجد منفّذون';

  @override
  String get ftFieldHandler => 'المنفّذ';

  @override
  String ftFullyFunded(String amount) {
    return 'مموَّلة بالكامل: $amount د.ك';
  }

  @override
  String get ftFulfil => 'تنفيذ المهمّة';

  @override
  String get ftFulfilled => 'تم تنفيذ المهمّة';

  @override
  String get ftStatement => 'بيان التنفيذ';

  @override
  String get ftStatementHint => 'صف ما تم تنفيذه';

  @override
  String get ftStatementRequired => 'أدخل بيان التنفيذ';

  @override
  String get ftPhotoRequired => 'أرفق صورة التنفيذ';

  @override
  String get mtPhotosRequired => 'أرفق صورة إنجاز واحدة على الأقل';

  @override
  String mtPhotosMax(int count) {
    return 'الحدّ الأقصى $count صور';
  }

  @override
  String get dedicationAlive => 'حيّ';

  @override
  String get dedicationDeceased => 'متوفّى';

  @override
  String get mtClaim => 'التقاط البلاغ';

  @override
  String get mtClaimConfirm => 'سيُسنَد هذا البلاغ إليك وإلى فريقك. متابعة؟';

  @override
  String get mtReadyToClaim => 'جاهز للالتقاط';

  @override
  String get mtChannelManager => 'بترتيب الإدارة';

  @override
  String get dpTitle => 'رفع حاجة مباشرة';

  @override
  String get dpDesc =>
      'سجّل حاجة مياه أو معدّة أو صيانة لأي مسجد في نطاقك — تُنشر فورًا بلا مرحلة اعتماد.';

  @override
  String get dpWater => 'نقص مياه';

  @override
  String get dpWaterDesc => 'علَم نقص مياه يُنشر للتمويل فورًا';

  @override
  String get dpWaterConfirm =>
      'سيُرفع علَم نقص مياه لهذا المسجد ويُنشر فورًا. متابعة؟';

  @override
  String get dpEquipment => 'طلب معدّة';

  @override
  String get dpEquipmentDesc => 'معدّة جديدة تُنشر للتمويل فورًا';

  @override
  String get dpMaintenance => 'بلاغ صيانة';

  @override
  String get dpMaintenanceDesc => 'بلاغ على وحدة قائمة، يدخل طابور الالتقاط';

  @override
  String get dpMosque => 'المسجد';

  @override
  String get dpMosqueRequired => 'اختر المسجد أولًا';

  @override
  String get dpEquipmentType => 'نوع المعدّة';

  @override
  String get dpModel => 'الموديل';

  @override
  String get dpModelRequired => 'اختر الموديل';

  @override
  String get dpNoTypes => 'لا توجد أنواع معدّات';

  @override
  String get dpNoModels => 'لا توجد موديلات لهذا النوع';

  @override
  String get dpTargetAmountLabel => 'المبلغ المستهدف';

  @override
  String dpTargetAmount(String amount) {
    return 'المبلغ المستهدف: $amount د.ك';
  }

  @override
  String get dpNote => 'ملاحظة (اختياري)';

  @override
  String get dpUnit => 'الوحدة';

  @override
  String get dpNoUnits => 'لا توجد وحدات مسجّلة في هذا المسجد';

  @override
  String get dpUnitInWarranty => 'ضمن الضمان';

  @override
  String get dpCostPath => 'مسار التكلفة';

  @override
  String get dpSubmit => 'إرسال';

  @override
  String get dpCreated => 'تمّ الإنشاء ونُشر مباشرة';

  @override
  String get locSortedByDistance =>
      'مرتّبة حسب الأقرب إليك · المسافة تقديرية بخط مستقيم';

  @override
  String get locEnableHint => 'فعّل إذن الموقع لترتيب المهام من الأقرب';

  @override
  String get locUnavailable => 'الموقع غير متوفّر';

  @override
  String locDistanceKm(String km) {
    return '$km كم';
  }

  @override
  String locNearestDestination(String km) {
    return 'أقرب وجهة: $km كم';
  }

  @override
  String get locDirections => 'الاتجاهات';

  @override
  String get coTitle => 'شراء معدّات من المتجر';

  @override
  String get coDesc =>
      'معدّات يشتريها العملاء لمسجد معيّن. راجع الطلب واعتمده ليُفتح للعميل باب الدفع.';

  @override
  String get coDescField => 'معدّات مدفوعة بانتظار الإسناد أو التركيب وتوثيقه.';

  @override
  String get coDescWatch => 'متابعة مشتريات العملاء من الاعتماد حتى التركيب.';

  @override
  String get coStatusUnderReview => 'قيد المراجعة';

  @override
  String get coStatusApproved => 'معتمَد — بانتظار الدفع';

  @override
  String get coStatusPaid => 'مدفوع';

  @override
  String get coStatusInstalled => 'تم التركيب';

  @override
  String get coStatusRejected => 'مرفوض';

  @override
  String get coApproveConfirm =>
      'بالموافقة تُفتح للعميل مهلة دفع ٤٨ ساعة. متابعة؟';

  @override
  String get coInstall => 'تسجيل التركيب';

  @override
  String get coInstallConfirm =>
      'سيُسجَّل تركيب الوحدة ويُصدَر لها رمز وضمان. متابعة؟';

  @override
  String coAwaitingPayment(String deadline) {
    return 'بانتظار دفع العميل حتى $deadline';
  }
}
