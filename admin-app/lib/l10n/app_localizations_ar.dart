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
  String get tabNew => 'جديدة';

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
  String get dashboardTitle => 'اللوحة';

  @override
  String get dashNew => 'جديدة';

  @override
  String get dashAwaiting => 'بانتظار الإسناد';

  @override
  String get dashAssigned => 'قيد التنفيذ';

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
}
