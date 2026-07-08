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
  /// **'هل تريد حذف هذا العنوان؟'**
  String get deleteAddressConfirm;

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

  /// No description provided for @productDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المنتج'**
  String get productDetailsTitle;

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

  /// No description provided for @donateMethodTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة الإهداء'**
  String get donateMethodTitle;

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

  /// No description provided for @mostNeededDesc.
  ///
  /// In ar, this message translates to:
  /// **'اهدِ المياه وسنوصلها للمساجد الأكثر حاجة'**
  String get mostNeededDesc;

  /// No description provided for @chooseMosqueTitle.
  ///
  /// In ar, this message translates to:
  /// **'إهداء لمسجد محدد'**
  String get chooseMosqueTitle;

  /// No description provided for @chooseMosqueDesc.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسجدًا من القائمة أو الخريطة'**
  String get chooseMosqueDesc;

  /// No description provided for @donateToThisMosque.
  ///
  /// In ar, this message translates to:
  /// **'إهداء لهذا المسجد'**
  String get donateToThisMosque;

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
  /// **'هل ترغب بالإهداء لهذا المسجد؟'**
  String get donateMosquePrompt;

  /// No description provided for @viewOnMap.
  ///
  /// In ar, this message translates to:
  /// **'عرض على الخريطة'**
  String get viewOnMap;

  /// No description provided for @donatingTo.
  ///
  /// In ar, this message translates to:
  /// **'إهداء إلى {label}'**
  String donatingTo(String label);

  /// No description provided for @addedToCart.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف إلى السلة'**
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
  /// **'اختر مسجدًا أو المساجد الأكثر حاجة وابدأ الإهداء'**
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

  /// No description provided for @checkoutButton.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الشراء'**
  String get checkoutButton;

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

  /// No description provided for @checkoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الشراء'**
  String get checkoutTitle;

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
  /// **'شكرًا لإهدائك، سنوصل المياه قريبًا بإذن الله'**
  String get orderSuccessDesc;

  /// No description provided for @backToHome.
  ///
  /// In ar, this message translates to:
  /// **'العودة للرئيسية'**
  String get backToHome;

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
  /// **'هل أنت متأكد من إلغاء هذا الطلب؟'**
  String get cancelOrderConfirm;

  /// No description provided for @cancelReasonHint.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإلغاء (اختياري)'**
  String get cancelReasonHint;

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

  /// No description provided for @chooseGiftCategory.
  ///
  /// In ar, this message translates to:
  /// **'اختر صنف الإهداء'**
  String get chooseGiftCategory;

  /// No description provided for @noTemplatesInCategory.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قوالب متاحة في هذا الصنف'**
  String get noTemplatesInCategory;

  /// No description provided for @chooseTemplate.
  ///
  /// In ar, this message translates to:
  /// **'اختر التصميم'**
  String get chooseTemplate;

  /// No description provided for @dedicatedToLabel.
  ///
  /// In ar, this message translates to:
  /// **'إهداء إلى'**
  String get dedicatedToLabel;

  /// No description provided for @dedicatedToHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: والدي محمد'**
  String get dedicatedToHint;

  /// No description provided for @senderNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'تقديم من'**
  String get senderNameLabel;

  /// No description provided for @relationLabel.
  ///
  /// In ar, this message translates to:
  /// **'صلة القرابة'**
  String get relationLabel;

  /// No description provided for @whatsappLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم واتساب للإشعار'**
  String get whatsappLabel;

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

  /// No description provided for @relGeneral.
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get relGeneral;

  /// No description provided for @relFather.
  ///
  /// In ar, this message translates to:
  /// **'الوالد'**
  String get relFather;

  /// No description provided for @relMother.
  ///
  /// In ar, this message translates to:
  /// **'الوالدة'**
  String get relMother;

  /// No description provided for @relHusband.
  ///
  /// In ar, this message translates to:
  /// **'الزوج'**
  String get relHusband;

  /// No description provided for @relWife.
  ///
  /// In ar, this message translates to:
  /// **'الزوجة'**
  String get relWife;

  /// No description provided for @relSon.
  ///
  /// In ar, this message translates to:
  /// **'الابن'**
  String get relSon;

  /// No description provided for @relDaughter.
  ///
  /// In ar, this message translates to:
  /// **'الابنة'**
  String get relDaughter;

  /// No description provided for @relBrother.
  ///
  /// In ar, this message translates to:
  /// **'الأخ'**
  String get relBrother;

  /// No description provided for @relSister.
  ///
  /// In ar, this message translates to:
  /// **'الأخت'**
  String get relSister;

  /// No description provided for @relFriend.
  ///
  /// In ar, this message translates to:
  /// **'صديق'**
  String get relFriend;

  /// No description provided for @priceKwd.
  ///
  /// In ar, this message translates to:
  /// **'{amount} د.ك'**
  String priceKwd(String amount);

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
  /// **'سجّل الدخول للوصول إلى حسابك وطلباتك وإتمام إهداءاتك.'**
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
