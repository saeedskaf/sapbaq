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
  String get navOrders => 'الطلبات';

  @override
  String get navDeliveries => 'التوصيلات';

  @override
  String get navNotifications => 'الإشعارات';

  @override
  String get navProfile => 'حسابي';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusConfirmed => 'مؤكَّد';

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
    return 'طلب #$ref';
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
  String get searchOrdersHint => 'ابحث برقم الزبون أو مرجع الطلب';

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
  String get orderDetailsTitle => 'تفاصيل الطلب';

  @override
  String get giftLabel => 'يحتوي على إهداء';

  @override
  String get customerLabel => 'الزبون';

  @override
  String get paymentLabel => 'الدفع';

  @override
  String get paymentPaid => 'مدفوع';

  @override
  String get paymentUnpaid => 'غير مدفوع';

  @override
  String get notesLabel => 'ملاحظات الزبون';

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
  String get assignButton => 'إسناد الورش';

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
  String get confirmAssign => 'تأكيد الإسناد';

  @override
  String get assignSuccess => 'تم إسناد الورش بنجاح';

  @override
  String get noWorkshops => 'لا توجد ورش متاحة';

  @override
  String get searchMosqueHint => 'ابحث عن مسجد';

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
  String get uploadAndFinish => 'رفع وإنهاء التوصيل';

  @override
  String get pickFailed => 'تعذّر اختيار الملف';

  @override
  String get noProofSelected => 'اختر صورة أو فيديو أولاً';

  @override
  String get proofUploaded => 'تم رفع التوثيق — تم التوصيل';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get emptyNotifications => 'لا توجد إشعارات';

  @override
  String get profileTitle => 'حسابي';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get roleDriver => 'ورشة توصيل';

  @override
  String get logout => 'تسجيل الخروج';
}
