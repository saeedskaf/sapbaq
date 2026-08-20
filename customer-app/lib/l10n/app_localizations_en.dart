// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sapbaq';

  @override
  String get appTagline => 'Delivering drinking water to Kuwait\'s mosques';

  @override
  String get homeWelcome => 'Welcome to Sapbaq';

  @override
  String get homeDescription =>
      'Order bottled drinking water delivered to mosques across Kuwait.';

  @override
  String get orderNow => 'Order now';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get logout => 'Log out';

  @override
  String get editName => 'Edit name';

  @override
  String get saveButton => 'Save';

  @override
  String get nameUpdated => 'Name updated';

  @override
  String get retry => 'Retry';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get profileAbout => 'About';

  @override
  String get profileContact => 'Contact us';

  @override
  String get profilePrivacy => 'Privacy Policy';

  @override
  String get profileTerms => 'Terms & Conditions';

  @override
  String get profileFaq => 'FAQ';

  @override
  String get contactCall => 'Call us';

  @override
  String get contactWhatsapp => 'WhatsApp';

  @override
  String get contactEmail => 'Email';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmBody =>
      'Your personal data will be permanently deleted and the account cannot be recovered afterwards. We\'ll send a confirmation code to your phone to continue.';

  @override
  String get deleteAccountWhatRemoved =>
      'Removed: your personal information, current cart, and notifications.';

  @override
  String get deleteAccountWhatKept =>
      'Kept: your past order history, for accounting purposes.';

  @override
  String get deleteAccountConfirm => 'Delete account permanently';

  @override
  String get settingsSection => 'Settings';

  @override
  String get profileHelpSection => 'Help & info';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'Match device';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get notificationPrefsTitle => 'Notification preferences';

  @override
  String get notifOrderUpdates => 'Order updates';

  @override
  String get notifReviews => 'Reviews';

  @override
  String get notifGifts => 'Gifts';

  @override
  String get notifPromotions => 'Promotions';

  @override
  String get profilePersonalInfo => 'Personal information';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get emailLabel => 'Email';

  @override
  String get notSet => 'Not set';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get defaultUserName => 'User';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get accountSection => 'Account';

  @override
  String get addressesTitle => 'Saved addresses';

  @override
  String get addAddress => 'Add address';

  @override
  String get editAddress => 'Edit address';

  @override
  String get emptyAddresses => 'No saved addresses yet';

  @override
  String get addrLabel => 'Label';

  @override
  String get addrLabelHint => 'e.g. Home, Work';

  @override
  String get addrArea => 'Area';

  @override
  String get addrBlock => 'Block';

  @override
  String get addrStreet => 'Street';

  @override
  String get addrBuilding => 'Building';

  @override
  String get addrDetails => 'Additional details';

  @override
  String get setDefaultAddress => 'Set as default address';

  @override
  String get defaultBadge => 'Default';

  @override
  String get addressSaved => 'Address saved';

  @override
  String get deleteAddressConfirm => 'Delete this address?';

  @override
  String get deleteCartTitle => 'Delete this cart?';

  @override
  String deleteCartBody(String cart) {
    return '\"$cart\" and everything in it will be removed. This can\'t be undone.';
  }

  @override
  String get areaRequired => 'Area is required';

  @override
  String get deleteButton => 'Delete';

  @override
  String get favoritesTitle => 'Favorite mosques';

  @override
  String get emptyFavorites => 'No favorite mosques yet';

  @override
  String get contactIntro =>
      'We\'re happy to hear from you for any question or feedback.';

  @override
  String get supportTitle => 'Support';

  @override
  String get emptyTickets => 'No tickets yet';

  @override
  String get newTicket => 'New ticket';

  @override
  String get ticketSubject => 'Subject';

  @override
  String get ticketMessage => 'Message';

  @override
  String get ticketSubjectRequired => 'Subject is required';

  @override
  String get ticketMessageRequired => 'Message is required';

  @override
  String get submitTicket => 'Submit ticket';

  @override
  String get replyHint => 'Write a reply…';

  @override
  String get ticketCreated => 'Ticket opened';

  @override
  String get ticketStatusOpen => 'Open';

  @override
  String get ticketStatusInProgress => 'In progress';

  @override
  String get ticketStatusResolved => 'Resolved';

  @override
  String get ticketStatusClosed => 'Closed';

  @override
  String get ticketCategory => 'Category';

  @override
  String get ticketCategoryOrder => 'Order';

  @override
  String get ticketCategoryPayment => 'Payment';

  @override
  String get ticketCategoryDelivery => 'Delivery';

  @override
  String get ticketCategoryAccount => 'Account';

  @override
  String get ticketCategoryOther => 'Other';

  @override
  String get ticketClosedNote =>
      'This ticket is closed. Open a new one to continue.';

  @override
  String get attachImage => 'Attach image';

  @override
  String get photoFromGallery => 'Choose from gallery';

  @override
  String get photoFromCamera => 'Take a photo';

  @override
  String get imagePickFailed => 'Couldn\'t pick the image';

  @override
  String get lastMessageYou => 'You: ';

  @override
  String get filterTitle => 'Filter mosques';

  @override
  String get filterGovernorate => 'Governorate';

  @override
  String get filterArea => 'Area';

  @override
  String get filterBlock => 'Block';

  @override
  String get filterAll => 'All';

  @override
  String get clearFilters => 'Clear all';

  @override
  String get navHome => 'Home';

  @override
  String get navMosques => 'Mosques';

  @override
  String get navMedia => 'Media';

  @override
  String get navCart => 'Cart';

  @override
  String get navOrders => 'Orders';

  @override
  String get navProfile => 'Account';

  @override
  String get emptyMedia => 'No media yet';

  @override
  String get viewCart => 'View cart';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get emptyNotifications => 'No notifications yet';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get productsTitle => 'Products';

  @override
  String get profileTitle => 'Account';

  @override
  String get emptyProducts => 'No products yet';

  @override
  String get emptyCategories => 'No categories yet';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get dedicationTitle => 'Name on the cooler';

  @override
  String get dedicationSubtitle =>
      'Optional — engraved on the cooler for the fulfilment team';

  @override
  String get dedicationEngraveToggle => 'Engrave a name on the cooler';

  @override
  String get dedicationNameLabel => 'Name';

  @override
  String get dedicationNameRequired => 'Please enter the name';

  @override
  String get dedicationAlive => 'Alive';

  @override
  String get dedicationDeceased => 'Deceased';

  @override
  String get seeMore => 'See more';

  @override
  String get mosquesListTab => 'List';

  @override
  String get mosquesMapTab => 'Map';

  @override
  String get emptyMosques => 'No mosques yet';

  @override
  String get searchMosqueHint => 'Search for a mosque by name or area';

  @override
  String get noSearchResults => 'No matching results';

  @override
  String get mosquesSelectGovernorate => 'Select a governorate';

  @override
  String get mosquesSelectArea => 'Select an area';

  @override
  String get emptyAreas => 'No areas in this governorate';

  @override
  String get destBarTitle => 'Order for';

  @override
  String get destBarChoose => 'Choose a destination';

  @override
  String get payTotalButton => 'Pay total';

  @override
  String mosquesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mosques',
      one: '1 mosque',
    );
    return '$_temp0';
  }

  @override
  String payOneForMosques(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'One payment for $count mosques',
      one: 'One payment for this mosque',
    );
    return '$_temp0';
  }

  @override
  String get couponAppliedToTotal =>
      'The coupon is discounted against the combined total at payment';

  @override
  String get cartConflictHint =>
      'Remove the coupon or gift card from one of these carts to continue';

  @override
  String get mosqueNeedsTitle => 'Mosque Needs';

  @override
  String get mosqueNeedsDesc =>
      'Order mosques\' current needs directly,\ndelivered to the mosque you choose.';

  @override
  String get destinationPickerTitle => 'Where should this go?';

  @override
  String get destSpecificMosque => 'A specific mosque';

  @override
  String get destSpecificMosqueDesc => 'Pick a mosque from the list';

  @override
  String get pickMosqueTitle => 'Choose a mosque';

  @override
  String get mostNeededTitle => 'The mosques most in need in Kuwait';

  @override
  String get mostNeededShort => 'Mosques most in need';

  @override
  String get mostNeededBadge => 'Most needed';

  @override
  String get requestForMosque => 'Request for a mosque';

  @override
  String get needsApprovalBadge => 'Needs approval';

  @override
  String get mostNeededPickTitle => 'Pick a mosque most in need';

  @override
  String get mostNeededPickBody => 'Mosques the team flagged as most in need';

  @override
  String get donateToThisMosque => 'Order for this mosque';

  @override
  String get contributionDetailTitle => 'Contribution details';

  @override
  String get fulfilmentStatement => 'Fulfilment statement';

  @override
  String get maintenanceCaseStatus => 'Case status';

  @override
  String get contractPeriod => 'Contract period';

  @override
  String get tabWater => 'Water';

  @override
  String get tabMaintenance => 'Maintenance';

  @override
  String get tabEquipment => 'Equipment';

  @override
  String get emptyWater => 'No mosques need water right now';

  @override
  String get emptyMaintenance => 'No maintenance requests right now';

  @override
  String get emptyEquipment => 'No equipment requests right now';

  @override
  String get emptyContributions => 'No contributions yet';

  @override
  String get contribute => 'Order';

  @override
  String waterFunded(int funded, int max) {
    return '$funded of $max packages funded';
  }

  @override
  String get waterQtyTitle => 'How many packages would you like to order?';

  @override
  String remainingPackages(int remaining) {
    return 'Remaining: $remaining packages';
  }

  @override
  String get donate => 'Order';

  @override
  String get payRepair => 'Pay for the repair';

  @override
  String get maintenanceContract => '1-year maintenance contract';

  @override
  String get contributeAction => 'Contribute';

  @override
  String get contributeAmountTitle => 'How much would you like to contribute?';

  @override
  String get currencyKwd => 'KWD';

  @override
  String fundingGoal(String amount) {
    return 'Goal: $amount KWD';
  }

  @override
  String fundedOfTarget(String funded, String target) {
    return '$funded of $target KWD funded';
  }

  @override
  String fundingRemaining(String amount) {
    return '$amount KWD left';
  }

  @override
  String get fundRemainder => 'Fund the rest';

  @override
  String get noRefundNote =>
      'Your contribution goes to this campaign and is not refundable. If the goal isn\'t met, the campaign stays open until the unit is installed.';

  @override
  String errAmountExceedsRemaining(String amount) {
    return 'Only $amount KWD is left for this campaign.';
  }

  @override
  String get errListingClosed => 'This campaign is fully funded';

  @override
  String get yourShare => 'Your share';

  @override
  String get amountLabel => 'Amount';

  @override
  String get timeLeftLabel => 'Time left';

  @override
  String get payWindowNote =>
      'Complete payment in time, or the request returns to the marketplace';

  @override
  String get closeButton => 'Close';

  @override
  String get holdExpiredTitle => 'Payment window expired';

  @override
  String get holdExpiredBody =>
      'The request returned to the marketplace. You can try again if it\'s still available.';

  @override
  String get paidThanks => 'Paid — thank you for your order';

  @override
  String get backedToMarket =>
      'Time expired — the request returned to the marketplace';

  @override
  String get completePayment => 'Complete payment';

  @override
  String get contribPending => 'Awaiting payment';

  @override
  String get contribPaid => 'Paid';

  @override
  String get contribExpired => 'Expired';

  @override
  String get contribCancelled => 'Cancelled';

  @override
  String get contribFulfilled => 'Fulfilled';

  @override
  String get kindWater => 'Water';

  @override
  String get kindMaintenance => 'Maintenance';

  @override
  String get kindContract => 'Maintenance contract';

  @override
  String get kindEquipment => 'Equipment';

  @override
  String get proofPhotoLabel => 'Authentication photo';

  @override
  String get supportWaterTitle => 'Order water for this mosque';

  @override
  String get viewMosqueDetails => 'View details';

  @override
  String get addressLabel => 'Address';

  @override
  String get notesLabel => 'Notes';

  @override
  String get locationLabel => 'Location on map';

  @override
  String get donateMosquePrompt => 'Would you like to order for this mosque?';

  @override
  String get viewOnMap => 'View on map';

  @override
  String donatingTo(String label) {
    return 'Ordering for $label';
  }

  @override
  String get addedToCart => 'Added to cart';

  @override
  String get addButton => 'Add';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get emptyCart => 'Your cart is empty';

  @override
  String get emptyCartDesc =>
      'Choose a mosque or the mosques most in need and start ordering';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get discountLabel => 'Discount';

  @override
  String get totalLabel => 'Total';

  @override
  String get deleteGroupButton => 'Remove';

  @override
  String get changeDestination => 'Change destination';

  @override
  String get couponHint => 'Discount code';

  @override
  String get addCoupon => 'Add a discount coupon';

  @override
  String get haveCoupon => 'Have a coupon?';

  @override
  String get applyButton => 'Apply';

  @override
  String get removeButton => 'Remove';

  @override
  String get notesHint => 'Notes for the driver (optional)';

  @override
  String get confirmAndPay => 'Confirm & pay';

  @override
  String get orderSuccessTitle => 'Your order has been received';

  @override
  String get orderSuccessDesc =>
      'Thank you for your order — we\'ll deliver the water soon, God willing';

  @override
  String get backToHome => 'Back to home';

  @override
  String get viewOrder => 'View order';

  @override
  String get viewMyOrders => 'View my orders';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get ordersTitle => 'My Orders';

  @override
  String get orderDetailsTitle => 'Order details';

  @override
  String get emptyOrders => 'No orders yet';

  @override
  String orderRef(String ref) {
    return 'Order $ref';
  }

  @override
  String destinationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count destinations',
      one: '1 destination',
    );
    return '$_temp0';
  }

  @override
  String mediaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get driverLabel => 'Driver';

  @override
  String get payNow => 'Pay now';

  @override
  String get activityKindProducts => 'Products';

  @override
  String get activityKindEquipment => 'Equipment';

  @override
  String get activityKindContribution => 'Contribution';

  @override
  String payWindowLeft(String time) {
    return '$time left';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusAssigned => 'Assigned to a driver';

  @override
  String get statusInDelivery => 'Out for delivery';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelOrderConfirm => 'Cancel this order?';

  @override
  String get cancelOrderBody =>
      'Nothing will be charged, and this can\'t be undone once confirmed.';

  @override
  String get cancelReasonHint => 'Reason for cancellation (optional)';

  @override
  String get cancelReasonPlaceholder => 'Add a short reason…';

  @override
  String get confirmCancel => 'Yes, cancel the order';

  @override
  String get keepOrder => 'Go back';

  @override
  String get deliveryProofs => 'Delivery proofs';

  @override
  String get cannotOpenFile => 'Couldn\'t open the file';

  @override
  String get rateOrder => 'Rate order';

  @override
  String get rateOrderTitle => 'Rate your order';

  @override
  String get reviewCommentHint => 'Write your comment (optional)';

  @override
  String get submitReview => 'Submit review';

  @override
  String get yourReview => 'Your review';

  @override
  String get reviewThanks => 'Thanks for your review';

  @override
  String get giftSectionTitle => 'A lasting gift';

  @override
  String get addGift => 'Add a gift for a loved one';

  @override
  String get addGiftDesc =>
      'Gift water in the name of someone you love — a lasting impact';

  @override
  String get editGift => 'Edit';

  @override
  String get giftFormTitle => 'Add a gift';

  @override
  String get editGiftTitle => 'Edit gift';

  @override
  String get dedicatedToLabel => 'Dedicated to';

  @override
  String get dedicatedToHint => 'Name of the person you\'re gifting';

  @override
  String get senderNameLabel => 'From';

  @override
  String get senderNameHint => 'Your name';

  @override
  String get giftSenderShownHint => 'Your name will appear on the card';

  @override
  String get giftSenderPrivateHint => 'The gift will be sent from «فاعل خير»';

  @override
  String get whatsappNumberHint => 'WhatsApp number';

  @override
  String giftFromName(String name) {
    return 'From $name';
  }

  @override
  String get saveGift => 'Save gift';

  @override
  String get giftAdded => 'Gift added';

  @override
  String priceKwd(String amount) {
    return '$amount KWD';
  }

  @override
  String priceFromKwd(String amount) {
    return 'From $amount KWD';
  }

  @override
  String get variantPickFirst => 'Pick an option first';

  @override
  String get notAvailableNow => 'Currently unavailable';

  @override
  String inCartCount(int count) {
    return 'In cart: $count';
  }

  @override
  String greeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get searchCountry => 'Search for a country';

  @override
  String get passwordLabel => 'Password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get otpLabel => 'Verification code';

  @override
  String get loginTitle => 'Log in';

  @override
  String get loginSubtitle => 'Log in or create your account to continue';

  @override
  String get loginButton => 'Log in';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get orSeparator => 'or';

  @override
  String get verifyPhoneTitle => 'Verify your phone';

  @override
  String get verifyPhoneSubtitle =>
      'Enter your phone number to confirm your account';

  @override
  String get changeNumber => 'Change number';

  @override
  String get useDifferentAccount => 'Use a different account';

  @override
  String get completeProfileTitle => 'Complete your profile';

  @override
  String get completeProfileSubtitle => 'Enter your name and email to continue';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get middleNameLabel => 'Middle name (optional)';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get continueButton => 'Continue';

  @override
  String get deleteAccountSendCode => 'Send confirmation code';

  @override
  String get passkeySignIn => 'Sign in with a passkey';

  @override
  String get passkeysTitle => 'Passkeys';

  @override
  String get passkeysDescription =>
      'Passkeys let you sign in fast and securely with your fingerprint, face, or device PIN — no codes needed.';

  @override
  String get passkeyAddButton => 'Add a passkey for this device';

  @override
  String get passkeyRegistered => 'Passkey enabled';

  @override
  String get passkeyNoDevices => 'No passkeys registered yet.';

  @override
  String get passkeyUnnamedDevice => 'Unnamed device';

  @override
  String passkeyLastUsed(String date) {
    return 'Last used: $date';
  }

  @override
  String get passkeyDeleteTitle => 'Delete passkey?';

  @override
  String passkeyDeleteBody(String device) {
    return 'You won\'t be able to sign in quickly with \"$device\" after deleting it.';
  }

  @override
  String get passkeyDeleteAction => 'Delete';

  @override
  String get passkeyNotSupported => 'This device doesn\'t support passkeys.';

  @override
  String get passkeyNoneOnDevice =>
      'No passkey found on this device. Sign in another way, then add one.';

  @override
  String get passkeyError => 'Couldn\'t use the passkey. Please try again.';

  @override
  String get signInError => 'Sign-in failed. Please try again.';

  @override
  String get forgotPasswordLink => 'Forgot your password?';

  @override
  String get noAccountQuestion => 'Don\'t have an account?';

  @override
  String get createAccountLink => 'Create an account';

  @override
  String get browseAsGuest => 'Browse as a guest';

  @override
  String get loginRequiredTitle => 'Login required';

  @override
  String get loginRequiredDesc => 'Log in or create an account to continue.';

  @override
  String get guestOrdersMessage => 'Log in to view and track your orders.';

  @override
  String get guestWelcomeTitle => 'Welcome to Sapbaq';

  @override
  String get guestWelcomeDesc =>
      'Log in to access your account and orders and complete them.';

  @override
  String get signupTitle => 'Create account';

  @override
  String get signupSubtitle => 'Create your account to get started';

  @override
  String get signupButton => 'Create account';

  @override
  String get haveAccountQuestion => 'Already have an account?';

  @override
  String get loginLink => 'Log in';

  @override
  String get otpTitle => 'Verify phone number';

  @override
  String otpSentTo(String phone) {
    return 'Enter the verification code sent to $phone';
  }

  @override
  String get verifyButton => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCodeIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get emailVerifiedBadge => 'Verified';

  @override
  String get emailUnverifiedBadge => 'Not verified';

  @override
  String get verifyEmailTile => 'Verify your email';

  @override
  String get changeEmailTile => 'Change email';

  @override
  String get verifyEmailTitle => 'Verify email';

  @override
  String get changeEmailTitle => 'Change email';

  @override
  String get verifyEmailSubtitle =>
      'Enter your email address and we\'ll send you a verification code.';

  @override
  String emailCodeSentTo(String email) {
    return 'Enter the code sent to $email';
  }

  @override
  String get changeEmailAddress => 'Change address';

  @override
  String get emailVerifiedSuccess => 'Your email is verified';

  @override
  String get emailOldAddressNotice =>
      'We\'ll notify your previous address after the change.';

  @override
  String get notMe => 'Not me?';

  @override
  String get welcomeBackTitle => 'Welcome back';

  @override
  String enterPasscodeSubtitle(String phone) {
    return 'Enter your passcode for $phone';
  }

  @override
  String get passcodeWrong => 'Incorrect passcode, try again';

  @override
  String get forgotPasscode => 'Forgot passcode?';

  @override
  String get deviceTrustTitle => 'Trust this device';

  @override
  String deviceTrustSubtitle(String phone) {
    return 'We sent a verification code to $phone to trust this device';
  }

  @override
  String get forgotPasscodeTitle => 'Reset passcode';

  @override
  String forgotPasscodeSubtitle(String phone) {
    return 'We sent a verification code to $phone';
  }

  @override
  String get newPasscodeLabel => 'New passcode';

  @override
  String get confirmPasscodeLabel => 'Confirm passcode';

  @override
  String get resetPasscodeButton => 'Set new passcode';

  @override
  String get back => 'Back';

  @override
  String get passcodeMismatch => 'Passcodes don\'t match';

  @override
  String get passcodeLength => 'The passcode must be 4 digits';

  @override
  String get passcodeTooSimple =>
      'Choose a stronger passcode (avoid repeats or sequences)';

  @override
  String get setPasscodeTitle => 'Set your passcode';

  @override
  String get setPasscodeSubtitle =>
      'Choose a 4-digit passcode for quick sign-in';

  @override
  String get confirmPasscodeSubtitle => 'Re-enter the passcode to confirm';

  @override
  String get biometricTitle => 'Enable biometrics';

  @override
  String get biometricSubtitle =>
      'Unlock the app with your fingerprint or face instead of typing the passcode';

  @override
  String get biometricEnable => 'Enable biometrics';

  @override
  String get biometricSkip => 'Not now';

  @override
  String get biometricReason => 'Unlock your Sapbaq session';

  @override
  String get biometricUnlockSetting =>
      'Biometric unlock (Face ID / fingerprint)';

  @override
  String get lockTitle => 'Enter your passcode';

  @override
  String lockGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get lockSubtitle => 'Enter your passcode to continue';

  @override
  String get unlockWithBiometrics => 'Unlock with biometrics';

  @override
  String get trustedDevicesTitle => 'Trusted devices';

  @override
  String get trustedDevicesDescription =>
      'These devices sign in with your passcode, without a verification code. Remove any you don\'t recognize.';

  @override
  String get trustedDevicesEmpty => 'No trusted devices yet.';

  @override
  String get trustedDevicesError => 'Couldn\'t load devices.';

  @override
  String get trustedDeviceUnnamed => 'Unnamed device';

  @override
  String get trustedDeviceCurrent => 'Current';

  @override
  String get trustedDeviceThis => 'This device';

  @override
  String trustedDeviceLastUsed(String date) {
    return 'Last used: $date';
  }

  @override
  String get revokeDeviceTitle => 'Remove device?';

  @override
  String revokeDeviceBody(String device) {
    return '\"$device\" will need a new verification code the next time it signs in.';
  }

  @override
  String get revokeDeviceAction => 'Remove';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your phone number and we\'ll send you a verification code';

  @override
  String get sendCodeButton => 'Send code';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordSubtitle => 'Enter the code and your new password';

  @override
  String get resetPasswordButton => 'Set password';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get phoneTooShort => 'Phone number is too short';

  @override
  String get phoneTooLong => 'Phone number is too long';

  @override
  String get phoneOnlyNumbers => 'Phone number must contain digits only';

  @override
  String get phoneEightDigits => 'The number must be 8 digits';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsNotMatch => 'Passwords do not match';

  @override
  String get fullNameRequired => 'Name is required';

  @override
  String get fullNameTooShort => 'Name is too short';

  @override
  String get fullNameTooLong => 'Name is too long';

  @override
  String get otpRequired => 'Verification code is required';

  @override
  String get otpInvalid => 'The verification code must be 6 digits';

  @override
  String get otpOnlyNumbers => 'The verification code must contain digits only';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get notificationChannelName => 'Sapbaq notifications';

  @override
  String get notificationChannelDescription =>
      'Order updates, gifts and announcements.';

  @override
  String get payTitle => 'Complete payment';

  @override
  String get payCancelTitle => 'Cancel payment?';

  @override
  String get payCancelBody =>
      'If you already paid, we\'ll verify it automatically. Close the payment page?';

  @override
  String get payKeepGoing => 'Keep paying';

  @override
  String get payLeave => 'Close';

  @override
  String get paySecureNote => 'Secure payment via MyFatoorah';

  @override
  String get payRecovered => 'Your earlier payment has been confirmed.';

  @override
  String payAmountAction(String amount) {
    return 'Pay $amount';
  }

  @override
  String get payNewCard => 'New card';

  @override
  String get payWithKnet => 'KNET';

  @override
  String get payLeavesApp => 'Opens your bank\'s page outside the app';

  @override
  String get paySaveCard => 'Save this card for next time';

  @override
  String get payCardRejected =>
      'Those card details weren\'t accepted. Check them and try again.';

  @override
  String get paySessionStale =>
      'The payment session expired. We\'ve reopened it — try again.';

  @override
  String get payBiometricReason => 'Confirm it\'s you to complete the payment';

  @override
  String get payMisconfigured =>
      'Payments are unavailable right now. Please contact support — retrying won\'t help.';

  @override
  String get payUseHostedPage => 'Pay on the secure payment page';

  @override
  String get payNoResponse =>
      'The payment page didn\'t respond. Check your connection and try again.';

  @override
  String payReference(int id) {
    return 'Payment reference: $id';
  }

  @override
  String payForOrder(int id) {
    return 'Order #$id';
  }

  @override
  String get payForContribution => 'Mosque need contribution';

  @override
  String get payForEquipment => 'Equipment request';

  @override
  String get payFailedTitle => 'Payment didn\'t go through';

  @override
  String get payFailedBody =>
      'The payment didn\'t complete. Check the order\'s status before retrying, so you aren\'t charged twice.';

  @override
  String get payDeclinedBody =>
      'The payment gateway declined the transaction. Check the card details or try another card.';

  @override
  String get payPendingTitle => 'Verifying payment';

  @override
  String get payPendingBody =>
      'We couldn\'t confirm it yet. Check your orders shortly, or try again.';

  @override
  String get payRetry => 'Try again';

  @override
  String get equipRequestAction => 'Request';

  @override
  String get equipRequestTitle => 'Equipment request';

  @override
  String get equipMyRequestsTitle => 'Equipment requests';

  @override
  String get equipPickMosque => 'Receiving mosque';

  @override
  String get equipMosqueRequired => 'Choose the mosque first';

  @override
  String get equipDedicationTitle => 'Dedication (optional)';

  @override
  String get equipDedicationName => 'Name on the dedication';

  @override
  String get equipSubmit => 'Send request';

  @override
  String get equipSubmitted => 'Your request was sent for review';

  @override
  String equipNoteUnderReview(int hours) {
    return 'Nothing is charged now. Once approved, a $hours-hour payment window opens.';
  }

  @override
  String get equipNoRequests => 'No equipment requests';

  @override
  String equipPayWindow(String time) {
    return 'Time left to pay: $time';
  }

  @override
  String get equipWindowClosed => 'The payment window closed';

  @override
  String get equipCancelRequest => 'Cancel request';

  @override
  String get equipCancelConfirm => 'Cancel this request?';

  @override
  String get equipCancelBody =>
      'Your request will be cancelled and nothing will be charged.';

  @override
  String get equipCancelled => 'Request cancelled';

  @override
  String get equipRejectionReason => 'Reason for rejection';

  @override
  String get equipInstalledCode => 'Installed unit code';

  @override
  String get equipStatusUnderReview => 'Under review';

  @override
  String get equipStatusApproved => 'Approved — awaiting payment';

  @override
  String get equipStatusPaid => 'Paid';

  @override
  String get equipStatusInProgress => 'In progress';

  @override
  String get equipStatusInstalled => 'Installed';

  @override
  String get equipStatusRejected => 'Rejected';

  @override
  String get equipStatusCancelled => 'Cancelled';

  @override
  String get equipDesignRegular => 'Regular';

  @override
  String get equipDesignLuxuryWood => 'Luxury wood';

  @override
  String get equipDesignIronGuarded => 'Iron-guarded';
}
