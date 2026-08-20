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

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'ســـبّاقـــ'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ar, this message translates to:
  /// **'توصيل مياه الشرب إلى مساجد الكويت'**
  String get appTagline;

  /// No description provided for @homeWelcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا بك في ســـبّاقـــ'**
  String get homeWelcome;

  /// No description provided for @homeDescription.
  ///
  /// In ar, this message translates to:
  /// **'اطلب مياه الشرب المعبأة لتوصيلها إلى مساجد الكويت.'**
  String get homeDescription;

  /// No description provided for @orderNow.
  ///
  /// In ar, this message translates to:
  /// **'اطلب الآن'**
  String get orderNow;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get comingSoon;

  /// No description provided for @genericError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إتمام العملية. حاول مجددًا.'**
  String get genericError;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @editName.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الاسم'**
  String get editName;

  /// No description provided for @saveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get saveButton;

  /// No description provided for @nameUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الاسم'**
  String get nameUpdated;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @cancelButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancelButton;

  /// No description provided for @profileAbout.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get profileAbout;

  /// No description provided for @profileContact.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get profileContact;

  /// No description provided for @profilePrivacy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get profilePrivacy;

  /// No description provided for @profileTerms.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والأحكام'**
  String get profileTerms;

  /// No description provided for @profileFaq.
  ///
  /// In ar, this message translates to:
  /// **'الأسئلة الشائعة'**
  String get profileFaq;

  /// No description provided for @contactCall.
  ///
  /// In ar, this message translates to:
  /// **'اتصل بنا'**
  String get contactCall;

  /// No description provided for @contactWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get contactWhatsapp;

  /// No description provided for @contactEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get contactEmail;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف بياناتك الشخصية بشكل دائم ولا يمكن استرجاع الحساب بعد الحذف. سنرسل رمز تأكيد إلى رقم هاتفك للمتابعة.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountWhatRemoved.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف: معلوماتك الشخصية، سلّتك الحالية، وإشعاراتك.'**
  String get deleteAccountWhatRemoved;

  /// No description provided for @deleteAccountWhatKept.
  ///
  /// In ar, this message translates to:
  /// **'يبقى: سجلّ طلباتك السابقة لأغراض محاسبية.'**
  String get deleteAccountWhatKept;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب نهائيًا'**
  String get deleteAccountConfirm;

  /// No description provided for @settingsSection.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsSection;

  /// No description provided for @profileHelpSection.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة والمعلومات'**
  String get profileHelpSection;

  /// No description provided for @appearanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearanceTitle;

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

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب إعدادات الجهاز'**
  String get themeSystem;

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

  /// No description provided for @notificationPrefsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفضيلات الإشعارات'**
  String get notificationPrefsTitle;

  /// No description provided for @notifOrderUpdates.
  ///
  /// In ar, this message translates to:
  /// **'تحديثات الطلبات'**
  String get notifOrderUpdates;

  /// No description provided for @notifReviews.
  ///
  /// In ar, this message translates to:
  /// **'التقييمات'**
  String get notifReviews;

  /// No description provided for @notifGifts.
  ///
  /// In ar, this message translates to:
  /// **'الإهداءات'**
  String get notifGifts;

  /// No description provided for @notifPromotions.
  ///
  /// In ar, this message translates to:
  /// **'العروض والترويج'**
  String get notifPromotions;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الشخصية'**
  String get profilePersonalInfo;

  /// No description provided for @editProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المعلومات'**
  String get editProfile;

  /// No description provided for @emailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailLabel;

  /// No description provided for @notSet.
  ///
  /// In ar, this message translates to:
  /// **'غير محدّد'**
  String get notSet;

  /// No description provided for @profileUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث المعلومات'**
  String get profileUpdated;

  /// No description provided for @defaultUserName.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get defaultUserName;

  /// No description provided for @versionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String versionLabel(String version);

  /// No description provided for @accountSection.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get accountSection;

  /// No description provided for @addressesTitle.
  ///
  /// In ar, this message translates to:
  /// **'العناوين المحفوظة'**
  String get addressesTitle;

  /// No description provided for @addAddress.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان'**
  String get addAddress;

  /// No description provided for @editAddress.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العنوان'**
  String get editAddress;

  /// No description provided for @emptyAddresses.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عناوين محفوظة بعد'**
  String get emptyAddresses;

  /// No description provided for @addrLabel.
  ///
  /// In ar, this message translates to:
  /// **'التسمية'**
  String get addrLabel;

  /// No description provided for @addrLabelHint.
  ///
  /// In ar, this message translates to:
  /// **'مثل: المنزل، العمل'**
  String get addrLabelHint;

  /// No description provided for @addrArea.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get addrArea;

  /// No description provided for @addrBlock.
  ///
  /// In ar, this message translates to:
  /// **'القطعة'**
  String get addrBlock;

  /// No description provided for @addrStreet.
  ///
  /// In ar, this message translates to:
  /// **'الشارع'**
  String get addrStreet;

  /// No description provided for @addrBuilding.
  ///
  /// In ar, this message translates to:
  /// **'المبنى'**
  String get addrBuilding;

  /// No description provided for @addrDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل إضافية'**
  String get addrDetails;

  /// No description provided for @setDefaultAddress.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كعنوان افتراضي'**
  String get setDefaultAddress;

  /// No description provided for @defaultBadge.
  ///
  /// In ar, this message translates to:
  /// **'افتراضي'**
  String get defaultBadge;

  /// No description provided for @addressSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ العنوان'**
  String get addressSaved;

  /// No description provided for @deleteAddressConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف هذا العنوان؟'**
  String get deleteAddressConfirm;

  /// No description provided for @deleteCartTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف هذه السلة؟'**
  String get deleteCartTitle;

  /// No description provided for @deleteCartBody.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف «{cart}» بكل ما فيه، ولا يمكن التراجع.'**
  String deleteCartBody(String cart);

  /// No description provided for @areaRequired.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة مطلوبة'**
  String get areaRequired;

  /// No description provided for @deleteButton.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteButton;

  /// No description provided for @favoritesTitle.
  ///
  /// In ar, this message translates to:
  /// **'المساجد المفضّلة'**
  String get favoritesTitle;

  /// No description provided for @emptyFavorites.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مساجد مفضّلة بعد'**
  String get emptyFavorites;

  /// No description provided for @contactIntro.
  ///
  /// In ar, this message translates to:
  /// **'يسعدنا تواصلك معنا لأي استفسار أو ملاحظة.'**
  String get contactIntro;

  /// No description provided for @supportTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدعم الفني'**
  String get supportTitle;

  /// No description provided for @emptyTickets.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تذاكر بعد'**
  String get emptyTickets;

  /// No description provided for @newTicket.
  ///
  /// In ar, this message translates to:
  /// **'تذكرة جديدة'**
  String get newTicket;

  /// No description provided for @ticketSubject.
  ///
  /// In ar, this message translates to:
  /// **'الموضوع'**
  String get ticketSubject;

  /// No description provided for @ticketMessage.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة'**
  String get ticketMessage;

  /// No description provided for @ticketSubjectRequired.
  ///
  /// In ar, this message translates to:
  /// **'الموضوع مطلوب'**
  String get ticketSubjectRequired;

  /// No description provided for @ticketMessageRequired.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة مطلوبة'**
  String get ticketMessageRequired;

  /// No description provided for @submitTicket.
  ///
  /// In ar, this message translates to:
  /// **'إرسال التذكرة'**
  String get submitTicket;

  /// No description provided for @replyHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ردّاً…'**
  String get replyHint;

  /// No description provided for @ticketCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم فتح التذكرة'**
  String get ticketCreated;

  /// No description provided for @ticketStatusOpen.
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة'**
  String get ticketStatusOpen;

  /// No description provided for @ticketStatusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد المعالجة'**
  String get ticketStatusInProgress;

  /// No description provided for @ticketStatusResolved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحل'**
  String get ticketStatusResolved;

  /// No description provided for @ticketStatusClosed.
  ///
  /// In ar, this message translates to:
  /// **'مغلقة'**
  String get ticketStatusClosed;

  /// No description provided for @ticketCategory.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get ticketCategory;

  /// No description provided for @ticketCategoryOrder.
  ///
  /// In ar, this message translates to:
  /// **'طلب'**
  String get ticketCategoryOrder;

  /// No description provided for @ticketCategoryPayment.
  ///
  /// In ar, this message translates to:
  /// **'دفع'**
  String get ticketCategoryPayment;

  /// No description provided for @ticketCategoryDelivery.
  ///
  /// In ar, this message translates to:
  /// **'توصيل'**
  String get ticketCategoryDelivery;

  /// No description provided for @ticketCategoryAccount.
  ///
  /// In ar, this message translates to:
  /// **'حساب'**
  String get ticketCategoryAccount;

  /// No description provided for @ticketCategoryOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get ticketCategoryOther;

  /// No description provided for @ticketClosedNote.
  ///
  /// In ar, this message translates to:
  /// **'هذه التذكرة مغلقة. افتح تذكرة جديدة للمتابعة.'**
  String get ticketClosedNote;

  /// No description provided for @attachImage.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق صورة'**
  String get attachImage;

  /// No description provided for @photoFromGallery.
  ///
  /// In ar, this message translates to:
  /// **'اختيار من المعرض'**
  String get photoFromGallery;

  /// No description provided for @photoFromCamera.
  ///
  /// In ar, this message translates to:
  /// **'التقاط صورة'**
  String get photoFromCamera;

  /// No description provided for @imagePickFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر اختيار الصورة'**
  String get imagePickFailed;

  /// No description provided for @lastMessageYou.
  ///
  /// In ar, this message translates to:
  /// **'أنت: '**
  String get lastMessageYou;

  /// No description provided for @filterTitle.
  ///
  /// In ar, this message translates to:
  /// **'تصفية المساجد'**
  String get filterTitle;

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

  /// No description provided for @filterBlock.
  ///
  /// In ar, this message translates to:
  /// **'القطعة'**
  String get filterBlock;

  /// No description provided for @filterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterAll;

  /// No description provided for @clearFilters.
  ///
  /// In ar, this message translates to:
  /// **'مسح الكل'**
  String get clearFilters;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navMosques.
  ///
  /// In ar, this message translates to:
  /// **'المساجد'**
  String get navMosques;

  /// No description provided for @navMedia.
  ///
  /// In ar, this message translates to:
  /// **'الوسائط'**
  String get navMedia;

  /// No description provided for @navCart.
  ///
  /// In ar, this message translates to:
  /// **'السلة'**
  String get navCart;

  /// No description provided for @navOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get navOrders;

  /// No description provided for @navProfile.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get navProfile;

  /// No description provided for @emptyMedia.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وسائط حالياً'**
  String get emptyMedia;

  /// No description provided for @viewCart.
  ///
  /// In ar, this message translates to:
  /// **'عرض السلة'**
  String get viewCart;

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @emptyNotifications.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات بعد'**
  String get emptyNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get markAllRead;

  /// No description provided for @productsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get productsTitle;

  /// No description provided for @profileTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profileTitle;

  /// No description provided for @emptyProducts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات حالياً'**
  String get emptyProducts;

  /// No description provided for @emptyCategories.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أصناف حالياً'**
  String get emptyCategories;

  /// No description provided for @descriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get descriptionLabel;

  /// No description provided for @addToCart.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إلى السلة'**
  String get addToCart;

  /// No description provided for @dedicationTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاسم على البرّاد'**
  String get dedicationTitle;

  /// No description provided for @dedicationSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختياري — يُنقش على البرّاد لفريق التنفيذ'**
  String get dedicationSubtitle;

  /// No description provided for @dedicationEngraveToggle.
  ///
  /// In ar, this message translates to:
  /// **'نقش اسم على البرّاد'**
  String get dedicationEngraveToggle;

  /// No description provided for @dedicationNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get dedicationNameLabel;

  /// No description provided for @dedicationNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال الاسم'**
  String get dedicationNameRequired;

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

  /// No description provided for @seeMore.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get seeMore;

  /// No description provided for @mosquesListTab.
  ///
  /// In ar, this message translates to:
  /// **'قائمة'**
  String get mosquesListTab;

  /// No description provided for @mosquesMapTab.
  ///
  /// In ar, this message translates to:
  /// **'خريطة'**
  String get mosquesMapTab;

  /// No description provided for @emptyMosques.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مساجد حالياً'**
  String get emptyMosques;

  /// No description provided for @searchMosqueHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مسجد بالاسم أو المنطقة'**
  String get searchMosqueHint;

  /// No description provided for @noSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get noSearchResults;

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

  /// No description provided for @emptyAreas.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مناطق في هذه المحافظة'**
  String get emptyAreas;

  /// No description provided for @destBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'اطلب لـ'**
  String get destBarTitle;

  /// No description provided for @destBarChoose.
  ///
  /// In ar, this message translates to:
  /// **'اختر وجهة الطلب'**
  String get destBarChoose;

  /// No description provided for @payTotalButton.
  ///
  /// In ar, this message translates to:
  /// **'ادفع الإجمالي'**
  String get payTotalButton;

  /// No description provided for @mosquesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{مسجد واحد} two{مسجدان} few{{count} مساجد} other{{count} مسجدًا}}'**
  String mosquesCount(int count);

  /// Its own plural rather than «لـ» + mosquesCount: after the preposition the dual is «مسجدين», not «مسجدان», so the two strings cannot share one noun phrase.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{دفعة واحدة لهذا المسجد} two{دفعة واحدة لمسجدين} few{دفعة واحدة لـ{count} مساجد} other{دفعة واحدة لـ{count} مسجدًا}}'**
  String payOneForMosques(int count);

  /// No description provided for @couponAppliedToTotal.
  ///
  /// In ar, this message translates to:
  /// **'يُحتسب خصم الكوبون على الإجمالي عند الدفع'**
  String get couponAppliedToTotal;

  /// No description provided for @cartConflictHint.
  ///
  /// In ar, this message translates to:
  /// **'احذف الكوبون أو بطاقة الإهداء من إحدى هذه السلال للمتابعة'**
  String get cartConflictHint;

  /// No description provided for @mosqueNeedsTitle.
  ///
  /// In ar, this message translates to:
  /// **'احتياجات المساجد'**
  String get mosqueNeedsTitle;

  /// No description provided for @mosqueNeedsDesc.
  ///
  /// In ar, this message translates to:
  /// **'اطلب مباشرةً احتياجات المساجد الحالية،\nويصل طلبك للمسجد الذي تختاره.'**
  String get mosqueNeedsDesc;

  /// No description provided for @destinationPickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلى أين تريد الطلب؟'**
  String get destinationPickerTitle;

  /// No description provided for @destSpecificMosque.
  ///
  /// In ar, this message translates to:
  /// **'مسجد محدد'**
  String get destSpecificMosque;

  /// No description provided for @destSpecificMosqueDesc.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسجدًا من القائمة'**
  String get destSpecificMosqueDesc;

  /// No description provided for @pickMosqueTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسجدًا'**
  String get pickMosqueTitle;

  /// No description provided for @mostNeededTitle.
  ///
  /// In ar, this message translates to:
  /// **'المساجد الأكثر حاجة في الكويت'**
  String get mostNeededTitle;

  /// No description provided for @mostNeededShort.
  ///
  /// In ar, this message translates to:
  /// **'المساجد الأكثر حاجة'**
  String get mostNeededShort;

  /// No description provided for @mostNeededBadge.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر حاجة'**
  String get mostNeededBadge;

  /// No description provided for @requestForMosque.
  ///
  /// In ar, this message translates to:
  /// **'اطلب لمسجد'**
  String get requestForMosque;

  /// No description provided for @needsApprovalBadge.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب موافقة'**
  String get needsApprovalBadge;

  /// No description provided for @mostNeededPickTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسجدًا من الأكثر حاجة'**
  String get mostNeededPickTitle;

  /// No description provided for @mostNeededPickBody.
  ///
  /// In ar, this message translates to:
  /// **'مساجد اختارتها الإدارة لحاجتها الماسّة'**
  String get mostNeededPickBody;

  /// No description provided for @donateToThisMosque.
  ///
  /// In ar, this message translates to:
  /// **'اطلب لهذا المسجد'**
  String get donateToThisMosque;

  /// No description provided for @contributionDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المساهمة'**
  String get contributionDetailTitle;

  /// No description provided for @fulfilmentStatement.
  ///
  /// In ar, this message translates to:
  /// **'بيان التنفيذ'**
  String get fulfilmentStatement;

  /// No description provided for @maintenanceCaseStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة البلاغ'**
  String get maintenanceCaseStatus;

  /// No description provided for @contractPeriod.
  ///
  /// In ar, this message translates to:
  /// **'سريان العقد'**
  String get contractPeriod;

  /// No description provided for @tabWater.
  ///
  /// In ar, this message translates to:
  /// **'مياه'**
  String get tabWater;

  /// No description provided for @tabMaintenance.
  ///
  /// In ar, this message translates to:
  /// **'صيانة'**
  String get tabMaintenance;

  /// No description provided for @tabEquipment.
  ///
  /// In ar, this message translates to:
  /// **'معدّات'**
  String get tabEquipment;

  /// No description provided for @emptyWater.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مساجد بحاجة لماء حاليًا'**
  String get emptyWater;

  /// No description provided for @emptyMaintenance.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات صيانة حاليًا'**
  String get emptyMaintenance;

  /// No description provided for @emptyEquipment.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات معدّات حاليًا'**
  String get emptyEquipment;

  /// No description provided for @emptyContributions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مساهمات بعد'**
  String get emptyContributions;

  /// No description provided for @contribute.
  ///
  /// In ar, this message translates to:
  /// **'اطلب'**
  String get contribute;

  /// No description provided for @waterFunded.
  ///
  /// In ar, this message translates to:
  /// **'تم تمويل {funded} من {max} باقة'**
  String waterFunded(int funded, int max);

  /// No description provided for @waterQtyTitle.
  ///
  /// In ar, this message translates to:
  /// **'كم باقة تريد أن تطلبها؟'**
  String get waterQtyTitle;

  /// No description provided for @remainingPackages.
  ///
  /// In ar, this message translates to:
  /// **'المتبقّي: {remaining} باقة'**
  String remainingPackages(int remaining);

  /// No description provided for @donate.
  ///
  /// In ar, this message translates to:
  /// **'اطلب'**
  String get donate;

  /// No description provided for @payRepair.
  ///
  /// In ar, this message translates to:
  /// **'ادفع الصيانة'**
  String get payRepair;

  /// No description provided for @maintenanceContract.
  ///
  /// In ar, this message translates to:
  /// **'عقد صيانة سنة'**
  String get maintenanceContract;

  /// No description provided for @contributeAction.
  ///
  /// In ar, this message translates to:
  /// **'ساهم'**
  String get contributeAction;

  /// No description provided for @contributeAmountTitle.
  ///
  /// In ar, this message translates to:
  /// **'بكم تحبّ أن تساهم؟'**
  String get contributeAmountTitle;

  /// No description provided for @currencyKwd.
  ///
  /// In ar, this message translates to:
  /// **'د.ك'**
  String get currencyKwd;

  /// No description provided for @fundingGoal.
  ///
  /// In ar, this message translates to:
  /// **'الهدف: {amount} د.ك'**
  String fundingGoal(String amount);

  /// No description provided for @fundedOfTarget.
  ///
  /// In ar, this message translates to:
  /// **'مموَّل {funded} من {target} د.ك'**
  String fundedOfTarget(String funded, String target);

  /// No description provided for @fundingRemaining.
  ///
  /// In ar, this message translates to:
  /// **'متبقٍّ {amount} د.ك'**
  String fundingRemaining(String amount);

  /// No description provided for @fundRemainder.
  ///
  /// In ar, this message translates to:
  /// **'موّل المتبقّي'**
  String get fundRemainder;

  /// No description provided for @noRefundNote.
  ///
  /// In ar, this message translates to:
  /// **'مساهمتك تُحتسب لهذه الحملة ولا تُسترد. إن لم يكتمل التمويل تبقى الحملة مفتوحة حتى تُركّب المعدّة.'**
  String get noRefundNote;

  /// No description provided for @errAmountExceedsRemaining.
  ///
  /// In ar, this message translates to:
  /// **'بقي {amount} د.ك فقط لهذه الحملة.'**
  String errAmountExceedsRemaining(String amount);

  /// No description provided for @errListingClosed.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل تمويل هذه الحملة'**
  String get errListingClosed;

  /// No description provided for @yourShare.
  ///
  /// In ar, this message translates to:
  /// **'حصّتك'**
  String get yourShare;

  /// No description provided for @amountLabel.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get amountLabel;

  /// No description provided for @timeLeftLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوقت المتبقّي'**
  String get timeLeftLabel;

  /// No description provided for @payWindowNote.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الدفع خلال المهلة وإلا يعود الطلب إلى السوق'**
  String get payWindowNote;

  /// No description provided for @closeButton.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get closeButton;

  /// No description provided for @holdExpiredTitle.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة الدفع'**
  String get holdExpiredTitle;

  /// No description provided for @holdExpiredBody.
  ///
  /// In ar, this message translates to:
  /// **'عاد الطلب إلى السوق. يمكنك المحاولة مجددًا إن كان متاحًا.'**
  String get holdExpiredBody;

  /// No description provided for @paidThanks.
  ///
  /// In ar, this message translates to:
  /// **'تم الدفع، شكرًا لطلبك'**
  String get paidThanks;

  /// No description provided for @backedToMarket.
  ///
  /// In ar, this message translates to:
  /// **'انتهت المهلة، عاد الطلب إلى السوق'**
  String get backedToMarket;

  /// No description provided for @completePayment.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الدفع'**
  String get completePayment;

  /// No description provided for @contribPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الدفع'**
  String get contribPending;

  /// No description provided for @contribPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوعة'**
  String get contribPaid;

  /// No description provided for @contribExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get contribExpired;

  /// No description provided for @contribCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get contribCancelled;

  /// No description provided for @contribFulfilled.
  ///
  /// In ar, this message translates to:
  /// **'تم التنفيذ'**
  String get contribFulfilled;

  /// No description provided for @kindWater.
  ///
  /// In ar, this message translates to:
  /// **'مياه'**
  String get kindWater;

  /// No description provided for @kindMaintenance.
  ///
  /// In ar, this message translates to:
  /// **'صيانة'**
  String get kindMaintenance;

  /// No description provided for @kindContract.
  ///
  /// In ar, this message translates to:
  /// **'عقد صيانة'**
  String get kindContract;

  /// No description provided for @kindEquipment.
  ///
  /// In ar, this message translates to:
  /// **'معدّة'**
  String get kindEquipment;

  /// No description provided for @proofPhotoLabel.
  ///
  /// In ar, this message translates to:
  /// **'صورة التوثيق'**
  String get proofPhotoLabel;

  /// No description provided for @supportWaterTitle.
  ///
  /// In ar, this message translates to:
  /// **'اطلب ماءً لهذا المسجد'**
  String get supportWaterTitle;

  /// No description provided for @viewMosqueDetails.
  ///
  /// In ar, this message translates to:
  /// **'عرض التفاصيل'**
  String get viewMosqueDetails;

  /// No description provided for @addressLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get addressLabel;

  /// No description provided for @notesLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get notesLabel;

  /// No description provided for @locationLabel.
  ///
  /// In ar, this message translates to:
  /// **'الموقع على الخريطة'**
  String get locationLabel;

  /// No description provided for @donateMosquePrompt.
  ///
  /// In ar, this message translates to:
  /// **'هل ترغب بالطلب لهذا المسجد؟'**
  String get donateMosquePrompt;

  /// No description provided for @viewOnMap.
  ///
  /// In ar, this message translates to:
  /// **'عرض على الخريطة'**
  String get viewOnMap;

  /// No description provided for @donatingTo.
  ///
  /// In ar, this message translates to:
  /// **'طلب إلى {label}'**
  String donatingTo(String label);

  /// No description provided for @addedToCart.
  ///
  /// In ar, this message translates to:
  /// **'تمت الإضافة إلى السلة'**
  String get addedToCart;

  /// No description provided for @addButton.
  ///
  /// In ar, this message translates to:
  /// **'أضف'**
  String get addButton;

  /// No description provided for @quantityLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get quantityLabel;

  /// No description provided for @emptyCart.
  ///
  /// In ar, this message translates to:
  /// **'سلتك فارغة'**
  String get emptyCart;

  /// No description provided for @emptyCartDesc.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسجدًا أو المساجد الأكثر حاجة وابدأ الطلب'**
  String get emptyCartDesc;

  /// No description provided for @subtotalLabel.
  ///
  /// In ar, this message translates to:
  /// **'المجموع الفرعي'**
  String get subtotalLabel;

  /// No description provided for @discountLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخصم'**
  String get discountLabel;

  /// No description provided for @totalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get totalLabel;

  /// No description provided for @deleteGroupButton.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteGroupButton;

  /// No description provided for @changeDestination.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الوجهة'**
  String get changeDestination;

  /// No description provided for @couponHint.
  ///
  /// In ar, this message translates to:
  /// **'كود الخصم'**
  String get couponHint;

  /// No description provided for @addCoupon.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كوبون خصم'**
  String get addCoupon;

  /// No description provided for @haveCoupon.
  ///
  /// In ar, this message translates to:
  /// **'لديك كوبون؟'**
  String get haveCoupon;

  /// No description provided for @applyButton.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get applyButton;

  /// No description provided for @removeButton.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get removeButton;

  /// No description provided for @notesHint.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات للسائق (اختياري)'**
  String get notesHint;

  /// No description provided for @confirmAndPay.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد ودفع'**
  String get confirmAndPay;

  /// No description provided for @orderSuccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام طلبك'**
  String get orderSuccessTitle;

  /// No description provided for @orderSuccessDesc.
  ///
  /// In ar, this message translates to:
  /// **'شكرًا لطلبك، سنوصل المياه قريبًا بإذن الله'**
  String get orderSuccessDesc;

  /// No description provided for @backToHome.
  ///
  /// In ar, this message translates to:
  /// **'العودة للرئيسية'**
  String get backToHome;

  /// No description provided for @viewOrder.
  ///
  /// In ar, this message translates to:
  /// **'عرض الطلب'**
  String get viewOrder;

  /// No description provided for @viewMyOrders.
  ///
  /// In ar, this message translates to:
  /// **'عرض طلباتي'**
  String get viewMyOrders;

  /// No description provided for @itemsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} منتج'**
  String itemsCount(int count);

  /// No description provided for @ordersTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get ordersTitle;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get orderDetailsTitle;

  /// No description provided for @emptyOrders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات بعد'**
  String get emptyOrders;

  /// No description provided for @orderRef.
  ///
  /// In ar, this message translates to:
  /// **'طلب {ref}'**
  String orderRef(String ref);

  /// No description provided for @destinationsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} وجهة'**
  String destinationsCount(int count);

  /// No description provided for @mediaCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} عنصر'**
  String mediaCount(int count);

  /// No description provided for @driverLabel.
  ///
  /// In ar, this message translates to:
  /// **'السائق'**
  String get driverLabel;

  /// No description provided for @payNow.
  ///
  /// In ar, this message translates to:
  /// **'ادفع الآن'**
  String get payNow;

  /// No description provided for @activityKindProducts.
  ///
  /// In ar, this message translates to:
  /// **'منتجات'**
  String get activityKindProducts;

  /// No description provided for @activityKindEquipment.
  ///
  /// In ar, this message translates to:
  /// **'معدّات'**
  String get activityKindEquipment;

  /// No description provided for @activityKindContribution.
  ///
  /// In ar, this message translates to:
  /// **'مساهمة'**
  String get activityKindContribution;

  /// No description provided for @payWindowLeft.
  ///
  /// In ar, this message translates to:
  /// **'تبقّى {time}'**
  String payWindowLeft(String time);

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

  /// No description provided for @statusAssigned.
  ///
  /// In ar, this message translates to:
  /// **'مُسنَد لسائق'**
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

  /// No description provided for @cancelOrder.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get cancelOrder;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء هذا الطلب؟'**
  String get cancelOrderConfirm;

  /// No description provided for @cancelOrderBody.
  ///
  /// In ar, this message translates to:
  /// **'لن يُخصم أي مبلغ، ولا يمكن التراجع بعد تأكيد الإلغاء.'**
  String get cancelOrderBody;

  /// No description provided for @cancelReasonHint.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإلغاء (اختياري)'**
  String get cancelReasonHint;

  /// No description provided for @cancelReasonPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سببًا مختصرًا…'**
  String get cancelReasonPlaceholder;

  /// No description provided for @confirmCancel.
  ///
  /// In ar, this message translates to:
  /// **'نعم، ألغِ الطلب'**
  String get confirmCancel;

  /// No description provided for @keepOrder.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get keepOrder;

  /// No description provided for @deliveryProofs.
  ///
  /// In ar, this message translates to:
  /// **'إثباتات التسليم'**
  String get deliveryProofs;

  /// No description provided for @cannotOpenFile.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الملف'**
  String get cannotOpenFile;

  /// No description provided for @rateOrder.
  ///
  /// In ar, this message translates to:
  /// **'قيّم الطلب'**
  String get rateOrder;

  /// No description provided for @rateOrderTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقييم الطلب'**
  String get rateOrderTitle;

  /// No description provided for @reviewCommentHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تعليقك (اختياري)'**
  String get reviewCommentHint;

  /// No description provided for @submitReview.
  ///
  /// In ar, this message translates to:
  /// **'إرسال التقييم'**
  String get submitReview;

  /// No description provided for @yourReview.
  ///
  /// In ar, this message translates to:
  /// **'تقييمك'**
  String get yourReview;

  /// No description provided for @reviewThanks.
  ///
  /// In ar, this message translates to:
  /// **'شكرًا لتقييمك'**
  String get reviewThanks;

  /// No description provided for @giftSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'إهداء دائم'**
  String get giftSectionTitle;

  /// No description provided for @addGift.
  ///
  /// In ar, this message translates to:
  /// **'أضف إهداء لمن تحب'**
  String get addGift;

  /// No description provided for @addGiftDesc.
  ///
  /// In ar, this message translates to:
  /// **'أهدِ المياه باسم من تحب — أثرٌ يبقى'**
  String get addGiftDesc;

  /// No description provided for @editGift.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get editGift;

  /// No description provided for @giftFormTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إهداء'**
  String get giftFormTitle;

  /// No description provided for @editGiftTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الإهداء'**
  String get editGiftTitle;

  /// No description provided for @dedicatedToLabel.
  ///
  /// In ar, this message translates to:
  /// **'إهداء إلى'**
  String get dedicatedToLabel;

  /// No description provided for @dedicatedToHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم اللي ودك تهديه'**
  String get dedicatedToHint;

  /// No description provided for @senderNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'تقديم من'**
  String get senderNameLabel;

  /// No description provided for @senderNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اسمك'**
  String get senderNameHint;

  /// No description provided for @giftSenderShownHint.
  ///
  /// In ar, this message translates to:
  /// **'سيظهر اسمك على الكرت'**
  String get giftSenderShownHint;

  /// No description provided for @giftSenderPrivateHint.
  ///
  /// In ar, this message translates to:
  /// **'سيظهر الإهداء باسم «فاعل خير»'**
  String get giftSenderPrivateHint;

  /// No description provided for @whatsappNumberHint.
  ///
  /// In ar, this message translates to:
  /// **'رقم الواتساب'**
  String get whatsappNumberHint;

  /// No description provided for @giftFromName.
  ///
  /// In ar, this message translates to:
  /// **'تقديم من {name}'**
  String giftFromName(String name);

  /// No description provided for @saveGift.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الإهداء'**
  String get saveGift;

  /// No description provided for @giftAdded.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة الإهداء'**
  String get giftAdded;

  /// No description provided for @priceKwd.
  ///
  /// In ar, this message translates to:
  /// **'{amount} د.ك'**
  String priceKwd(String amount);

  /// No description provided for @priceFromKwd.
  ///
  /// In ar, this message translates to:
  /// **'من {amount} د.ك'**
  String priceFromKwd(String amount);

  /// No description provided for @variantPickFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر أحد الخيارات أولًا'**
  String get variantPickFirst;

  /// No description provided for @notAvailableNow.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر حاليًا'**
  String get notAvailableNow;

  /// No description provided for @inCartCount.
  ///
  /// In ar, this message translates to:
  /// **'في السلة: {count}'**
  String inCartCount(int count);

  /// No description provided for @greeting.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا، {name}'**
  String greeting(String name);

  /// No description provided for @fullNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullNameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneLabel;

  /// No description provided for @searchCountry.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن دولة'**
  String get searchCountry;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPasswordLabel;

  /// No description provided for @otpLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق'**
  String get otpLabel;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول أو أنشئ حسابك للمتابعة'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get loginButton;

  /// No description provided for @continueWithGoogle.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة عبر Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة عبر Apple'**
  String get continueWithApple;

  /// No description provided for @orSeparator.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get orSeparator;

  /// No description provided for @verifyPhoneTitle.
  ///
  /// In ar, this message translates to:
  /// **'توثيق رقم الهاتف'**
  String get verifyPhoneTitle;

  /// No description provided for @verifyPhoneSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتفك لتأكيد حسابك'**
  String get verifyPhoneSubtitle;

  /// No description provided for @changeNumber.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الرقم'**
  String get changeNumber;

  /// No description provided for @useDifferentAccount.
  ///
  /// In ar, this message translates to:
  /// **'الدخول بحساب آخر'**
  String get useDifferentAccount;

  /// No description provided for @completeProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'إكمال الملف الشخصي'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك وبريدك الإلكتروني للمتابعة'**
  String get completeProfileSubtitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول'**
  String get firstNameLabel;

  /// No description provided for @middleNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأوسط (اختياري)'**
  String get middleNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم العائلة'**
  String get lastNameLabel;

  /// No description provided for @continueButton.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueButton;

  /// No description provided for @deleteAccountSendCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رمز التأكيد'**
  String get deleteAccountSendCode;

  /// No description provided for @passkeySignIn.
  ///
  /// In ar, this message translates to:
  /// **'الدخول عبر مفتاح المرور'**
  String get passkeySignIn;

  /// No description provided for @passkeysTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفاتيح المرور'**
  String get passkeysTitle;

  /// No description provided for @passkeysDescription.
  ///
  /// In ar, this message translates to:
  /// **'مفاتيح المرور تتيح دخولًا سريعًا وآمنًا ببصمتك أو وجهك أو رمز جهازك، بدون رموز تحقق.'**
  String get passkeysDescription;

  /// No description provided for @passkeyAddButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مفتاح مرور لهذا الجهاز'**
  String get passkeyAddButton;

  /// No description provided for @passkeyRegistered.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل مفتاح المرور'**
  String get passkeyRegistered;

  /// No description provided for @passkeyNoDevices.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مفاتيح مرور مسجّلة بعد.'**
  String get passkeyNoDevices;

  /// No description provided for @passkeyUnnamedDevice.
  ///
  /// In ar, this message translates to:
  /// **'جهاز غير مسمّى'**
  String get passkeyUnnamedDevice;

  /// No description provided for @passkeyLastUsed.
  ///
  /// In ar, this message translates to:
  /// **'آخر استخدام: {date}'**
  String passkeyLastUsed(String date);

  /// No description provided for @passkeyDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف مفتاح المرور؟'**
  String get passkeyDeleteTitle;

  /// No description provided for @passkeyDeleteBody.
  ///
  /// In ar, this message translates to:
  /// **'لن تتمكن من الدخول السريع عبر «{device}» بعد الحذف.'**
  String passkeyDeleteBody(String device);

  /// No description provided for @passkeyDeleteAction.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get passkeyDeleteAction;

  /// No description provided for @passkeyNotSupported.
  ///
  /// In ar, this message translates to:
  /// **'هذا الجهاز لا يدعم مفاتيح المرور.'**
  String get passkeyNotSupported;

  /// No description provided for @passkeyNoneOnDevice.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مفتاح مرور على هذا الجهاز. سجّل الدخول بطريقة أخرى ثم أضف مفتاحًا.'**
  String get passkeyNoneOnDevice;

  /// No description provided for @passkeyError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر استخدام مفتاح المرور. حاول مجددًا.'**
  String get passkeyError;

  /// No description provided for @signInError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تسجيل الدخول. حاول مرة أخرى.'**
  String get signInError;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPasswordLink;

  /// No description provided for @noAccountQuestion.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get noAccountQuestion;

  /// No description provided for @createAccountLink.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابًا'**
  String get createAccountLink;

  /// No description provided for @browseAsGuest.
  ///
  /// In ar, this message translates to:
  /// **'تصفّح كزائر'**
  String get browseAsGuest;

  /// No description provided for @loginRequiredTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول مطلوب'**
  String get loginRequiredTitle;

  /// No description provided for @loginRequiredDesc.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول أو أنشئ حسابًا للمتابعة.'**
  String get loginRequiredDesc;

  /// No description provided for @guestOrdersMessage.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لعرض طلباتك ومتابعتها.'**
  String get guestOrdersMessage;

  /// No description provided for @guestWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في ســـبّاقـــ'**
  String get guestWelcomeTitle;

  /// No description provided for @guestWelcomeDesc.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول للوصول إلى حسابك وطلباتك وإتمامها.'**
  String get guestWelcomeDesc;

  /// No description provided for @signupTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابك للبدء'**
  String get signupSubtitle;

  /// No description provided for @signupButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get signupButton;

  /// No description provided for @haveAccountQuestion.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get haveAccountQuestion;

  /// No description provided for @loginLink.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginLink;

  /// No description provided for @otpTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد رقم الهاتف'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق المُرسَل إلى {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @verifyButton.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get verifyButton;

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

  /// No description provided for @emailVerifiedBadge.
  ///
  /// In ar, this message translates to:
  /// **'موثَّق'**
  String get emailVerifiedBadge;

  /// No description provided for @emailUnverifiedBadge.
  ///
  /// In ar, this message translates to:
  /// **'غير موثَّق'**
  String get emailUnverifiedBadge;

  /// No description provided for @verifyEmailTile.
  ///
  /// In ar, this message translates to:
  /// **'توثيق البريد الإلكتروني'**
  String get verifyEmailTile;

  /// No description provided for @changeEmailTile.
  ///
  /// In ar, this message translates to:
  /// **'تغيير البريد الإلكتروني'**
  String get changeEmailTile;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In ar, this message translates to:
  /// **'توثيق البريد الإلكتروني'**
  String get verifyEmailTitle;

  /// No description provided for @changeEmailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تغيير البريد الإلكتروني'**
  String get changeEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني ليصلك رمز التحقق.'**
  String get verifyEmailSubtitle;

  /// No description provided for @emailCodeSentTo.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المُرسَل إلى {email}'**
  String emailCodeSentTo(String email);

  /// No description provided for @changeEmailAddress.
  ///
  /// In ar, this message translates to:
  /// **'تغيير البريد'**
  String get changeEmailAddress;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم توثيق بريدك الإلكتروني'**
  String get emailVerifiedSuccess;

  /// No description provided for @emailOldAddressNotice.
  ///
  /// In ar, this message translates to:
  /// **'سيصل تنبيه إلى بريدك السابق بعد التغيير.'**
  String get emailOldAddressNotice;

  /// No description provided for @notMe.
  ///
  /// In ar, this message translates to:
  /// **'لست أنا؟'**
  String get notMe;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا بعودتك'**
  String get welcomeBackTitle;

  /// No description provided for @enterPasscodeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمزك السري لحساب {phone}'**
  String enterPasscodeSubtitle(String phone);

  /// No description provided for @passcodeWrong.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح، حاول مجددًا'**
  String get passcodeWrong;

  /// No description provided for @forgotPasscode.
  ///
  /// In ar, this message translates to:
  /// **'نسيت الرمز؟'**
  String get forgotPasscode;

  /// No description provided for @deviceTrustTitle.
  ///
  /// In ar, this message translates to:
  /// **'توثيق جهاز جديد'**
  String get deviceTrustTitle;

  /// No description provided for @deviceTrustSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رمز تحقق إلى {phone} لتوثيق هذا الجهاز'**
  String deviceTrustSubtitle(String phone);

  /// No description provided for @forgotPasscodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين الرمز'**
  String get forgotPasscodeTitle;

  /// No description provided for @forgotPasscodeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رمز تحقق إلى {phone}'**
  String forgotPasscodeSubtitle(String phone);

  /// No description provided for @newPasscodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرمز الجديد'**
  String get newPasscodeLabel;

  /// No description provided for @confirmPasscodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرمز'**
  String get confirmPasscodeLabel;

  /// No description provided for @resetPasscodeButton.
  ///
  /// In ar, this message translates to:
  /// **'تعيين الرمز الجديد'**
  String get resetPasscodeButton;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @passcodeMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الرمزان غير متطابقين'**
  String get passcodeMismatch;

  /// No description provided for @passcodeLength.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يتكوّن الرمز من 4 أرقام'**
  String get passcodeLength;

  /// No description provided for @passcodeTooSimple.
  ///
  /// In ar, this message translates to:
  /// **'اختر رمزًا أقوى (تجنّب التكرار أو التسلسل)'**
  String get passcodeTooSimple;

  /// No description provided for @setPasscodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'اضبط رمزك السري'**
  String get setPasscodeTitle;

  /// No description provided for @setPasscodeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر رمزًا من 4 أرقام لتسجيل الدخول السريع'**
  String get setPasscodeSubtitle;

  /// No description provided for @confirmPasscodeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أعد إدخال الرمز للتأكيد'**
  String get confirmPasscodeSubtitle;

  /// No description provided for @biometricTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل البصمة'**
  String get biometricTitle;

  /// No description provided for @biometricSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'افتح التطبيق ببصمتك أو وجهك بدل إدخال الرمز في كل مرة'**
  String get biometricSubtitle;

  /// No description provided for @biometricEnable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل البصمة'**
  String get biometricEnable;

  /// No description provided for @biometricSkip.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get biometricSkip;

  /// No description provided for @biometricReason.
  ///
  /// In ar, this message translates to:
  /// **'افتح جلستك في ســـبّاقـــ'**
  String get biometricReason;

  /// No description provided for @biometricUnlockSetting.
  ///
  /// In ar, this message translates to:
  /// **'الفتح بالبصمة (Face ID / بصمة الإصبع)'**
  String get biometricUnlockSetting;

  /// No description provided for @lockTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمزك السري'**
  String get lockTitle;

  /// No description provided for @lockGreeting.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا، {name}'**
  String lockGreeting(String name);

  /// No description provided for @lockSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمزك السري للمتابعة'**
  String get lockSubtitle;

  /// No description provided for @unlockWithBiometrics.
  ///
  /// In ar, this message translates to:
  /// **'الفتح بالبصمة'**
  String get unlockWithBiometrics;

  /// No description provided for @trustedDevicesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأجهزة الموثوقة'**
  String get trustedDevicesTitle;

  /// No description provided for @trustedDevicesDescription.
  ///
  /// In ar, this message translates to:
  /// **'هذه الأجهزة تدخل حسابك بالرمز بلا رمز تحقق. أزِل أي جهاز لا تعرفه.'**
  String get trustedDevicesDescription;

  /// No description provided for @trustedDevicesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أجهزة موثوقة بعد.'**
  String get trustedDevicesEmpty;

  /// No description provided for @trustedDevicesError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الأجهزة.'**
  String get trustedDevicesError;

  /// No description provided for @trustedDeviceUnnamed.
  ///
  /// In ar, this message translates to:
  /// **'جهاز غير مسمّى'**
  String get trustedDeviceUnnamed;

  /// No description provided for @trustedDeviceCurrent.
  ///
  /// In ar, this message translates to:
  /// **'الحالي'**
  String get trustedDeviceCurrent;

  /// No description provided for @trustedDeviceThis.
  ///
  /// In ar, this message translates to:
  /// **'هذا الجهاز'**
  String get trustedDeviceThis;

  /// No description provided for @trustedDeviceLastUsed.
  ///
  /// In ar, this message translates to:
  /// **'آخر استخدام: {date}'**
  String trustedDeviceLastUsed(String date);

  /// No description provided for @revokeDeviceTitle.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الجهاز؟'**
  String get revokeDeviceTitle;

  /// No description provided for @revokeDeviceBody.
  ///
  /// In ar, this message translates to:
  /// **'سيحتاج «{device}» إلى رمز تحقق جديد عند الدخول مرة أخرى.'**
  String revokeDeviceBody(String device);

  /// No description provided for @revokeDeviceAction.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get revokeDeviceAction;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتفك وسنرسل لك رمز تحقق'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendCodeButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرمز'**
  String get sendCodeButton;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين كلمة المرور'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز وكلمة المرور الجديدة'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordButton.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كلمة المرور'**
  String get resetPasswordButton;

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

  /// No description provided for @phoneEightDigits.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يتكون الرقم من 8 أرقام'**
  String get phoneEightDigits;

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

  /// No description provided for @notificationChannelName.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات ســـبّاقـــ'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In ar, this message translates to:
  /// **'تحديثات الطلبات والهدايا والإعلانات.'**
  String get notificationChannelDescription;

  /// No description provided for @payTitle.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الدفع'**
  String get payTitle;

  /// No description provided for @payCancelTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الدفع؟'**
  String get payCancelTitle;

  /// No description provided for @payCancelBody.
  ///
  /// In ar, this message translates to:
  /// **'لو كنت أكملت الدفع فسنتحقّق منه تلقائيًا. هل تريد إغلاق صفحة الدفع؟'**
  String get payCancelBody;

  /// No description provided for @payKeepGoing.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الدفع'**
  String get payKeepGoing;

  /// No description provided for @payLeave.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get payLeave;

  /// No description provided for @paySecureNote.
  ///
  /// In ar, this message translates to:
  /// **'دفع آمن عبر ماي فاتورة'**
  String get paySecureNote;

  /// No description provided for @payRecovered.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد دفعتك السابقة بنجاح.'**
  String get payRecovered;

  /// No description provided for @payAmountAction.
  ///
  /// In ar, this message translates to:
  /// **'ادفع {amount}'**
  String payAmountAction(String amount);

  /// No description provided for @payNewCard.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة جديدة'**
  String get payNewCard;

  /// No description provided for @payWithKnet.
  ///
  /// In ar, this message translates to:
  /// **'كي-نت'**
  String get payWithKnet;

  /// No description provided for @payLeavesApp.
  ///
  /// In ar, this message translates to:
  /// **'يفتح صفحة البنك خارج التطبيق'**
  String get payLeavesApp;

  /// No description provided for @paySaveCard.
  ///
  /// In ar, this message translates to:
  /// **'احفظ البطاقة لعمليات لاحقة'**
  String get paySaveCard;

  /// No description provided for @payCardRejected.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر قبول بيانات البطاقة. راجعها وحاول مرّة أخرى.'**
  String get payCardRejected;

  /// No description provided for @paySessionStale.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية جلسة الدفع. أعدنا فتحها — حاول مرّة أخرى.'**
  String get paySessionStale;

  /// No description provided for @payBiometricReason.
  ///
  /// In ar, this message translates to:
  /// **'أكّد هويّتك لإتمام الدفع'**
  String get payBiometricReason;

  /// No description provided for @payMisconfigured.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الدفع غير متاحة حاليًا. تواصل مع الدعم — لا داعي لإعادة المحاولة.'**
  String get payMisconfigured;

  /// No description provided for @payUseHostedPage.
  ///
  /// In ar, this message translates to:
  /// **'ادفع عبر صفحة الدفع الآمنة'**
  String get payUseHostedPage;

  /// No description provided for @payNoResponse.
  ///
  /// In ar, this message translates to:
  /// **'لم تستجب صفحة الدفع. تحقّق من اتصالك وحاول مرّة أخرى.'**
  String get payNoResponse;

  /// No description provided for @payReference.
  ///
  /// In ar, this message translates to:
  /// **'مرجع العملية: {id}'**
  String payReference(int id);

  /// No description provided for @payForOrder.
  ///
  /// In ar, this message translates to:
  /// **'قيمة الطلب #{id}'**
  String payForOrder(int id);

  /// No description provided for @payForContribution.
  ///
  /// In ar, this message translates to:
  /// **'مساهمة في احتياج مسجد'**
  String get payForContribution;

  /// No description provided for @payForEquipment.
  ///
  /// In ar, this message translates to:
  /// **'طلب معدّة'**
  String get payForEquipment;

  /// No description provided for @payFailedTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل الدفع'**
  String get payFailedTitle;

  /// No description provided for @payFailedBody.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل الدفع. تحقّق من حالة الطلب قبل إعادة المحاولة تفاديًا لتكرار الخصم.'**
  String get payFailedBody;

  /// No description provided for @payDeclinedBody.
  ///
  /// In ar, this message translates to:
  /// **'رفضت بوّابة الدفع العملية. تأكّد من بيانات البطاقة أو جرّب بطاقة أخرى.'**
  String get payDeclinedBody;

  /// No description provided for @payPendingTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدفع قيد التحقّق'**
  String get payPendingTitle;

  /// No description provided for @payPendingBody.
  ///
  /// In ar, this message translates to:
  /// **'لم نستطع تأكيد العملية بعد. تحقّق من طلباتك بعد قليل، أو أعد المحاولة.'**
  String get payPendingBody;

  /// No description provided for @payRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get payRetry;

  /// No description provided for @equipRequestAction.
  ///
  /// In ar, this message translates to:
  /// **'تقديم طلب'**
  String get equipRequestAction;

  /// No description provided for @equipRequestTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب معدّة'**
  String get equipRequestTitle;

  /// No description provided for @equipMyRequestsTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات المعدّات'**
  String get equipMyRequestsTitle;

  /// No description provided for @equipPickMosque.
  ///
  /// In ar, this message translates to:
  /// **'المسجد المستفيد'**
  String get equipPickMosque;

  /// No description provided for @equipMosqueRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر المسجد أولًا'**
  String get equipMosqueRequired;

  /// No description provided for @equipDedicationTitle.
  ///
  /// In ar, this message translates to:
  /// **'نقش (اختياري)'**
  String get equipDedicationTitle;

  /// No description provided for @equipDedicationName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم على النقش'**
  String get equipDedicationName;

  /// No description provided for @equipSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get equipSubmit;

  /// No description provided for @equipSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلبك للمراجعة'**
  String get equipSubmitted;

  /// No description provided for @equipNoteUnderReview.
  ///
  /// In ar, this message translates to:
  /// **'لا يُخصم أي مبلغ الآن. بعد الموافقة تُفتح مهلة دفع {hours} ساعة.'**
  String equipNoteUnderReview(int hours);

  /// No description provided for @equipNoRequests.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات معدّات'**
  String get equipNoRequests;

  /// No description provided for @equipPayWindow.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي للدفع: {time}'**
  String equipPayWindow(String time);

  /// No description provided for @equipWindowClosed.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة الدفع'**
  String get equipWindowClosed;

  /// No description provided for @equipCancelRequest.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get equipCancelRequest;

  /// No description provided for @equipCancelConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء هذا الطلب؟'**
  String get equipCancelConfirm;

  /// No description provided for @equipCancelBody.
  ///
  /// In ar, this message translates to:
  /// **'سيُلغى طلبك ولن يُخصم أي مبلغ.'**
  String get equipCancelBody;

  /// No description provided for @equipCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الطلب'**
  String get equipCancelled;

  /// No description provided for @equipRejectionReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض'**
  String get equipRejectionReason;

  /// No description provided for @equipInstalledCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز الوحدة المركّبة'**
  String get equipInstalledCode;

  /// No description provided for @equipStatusUnderReview.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get equipStatusUnderReview;

  /// No description provided for @equipStatusApproved.
  ///
  /// In ar, this message translates to:
  /// **'معتمَد — بانتظار الدفع'**
  String get equipStatusApproved;

  /// No description provided for @equipStatusPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع'**
  String get equipStatusPaid;

  /// No description provided for @equipStatusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get equipStatusInProgress;

  /// No description provided for @equipStatusInstalled.
  ///
  /// In ar, this message translates to:
  /// **'تم التركيب'**
  String get equipStatusInstalled;

  /// No description provided for @equipStatusRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get equipStatusRejected;

  /// No description provided for @equipStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get equipStatusCancelled;

  /// No description provided for @equipDesignRegular.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get equipDesignRegular;

  /// No description provided for @equipDesignLuxuryWood.
  ///
  /// In ar, this message translates to:
  /// **'فاخر خشبي'**
  String get equipDesignLuxuryWood;

  /// No description provided for @equipDesignIronGuarded.
  ///
  /// In ar, this message translates to:
  /// **'محمي بالحديد'**
  String get equipDesignIronGuarded;
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
