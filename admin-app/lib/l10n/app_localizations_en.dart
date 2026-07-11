// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get searchCountry => 'Search for a country';

  @override
  String get retry => 'Retry';

  @override
  String get genericError => 'Something went wrong';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get noSearchResults => 'No results';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get phoneTooShort => 'Phone number is too short';

  @override
  String get phoneTooLong => 'Phone number is too long';

  @override
  String get phoneOnlyNumbers => 'Phone number must contain digits only';

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
  String get loginTitle => 'Sign in';

  @override
  String get loginStaffSubtitle =>
      'Sign in with your admin or workshop account';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get unauthorizedTitle => 'This app is for staff only';

  @override
  String get unauthorizedDesc =>
      'Your account isn\'t authorized to access the admin & driver app.';

  @override
  String get backToLogin => 'Back to sign in';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navOrders => 'Orders';

  @override
  String get navDeliveries => 'Deliveries';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'Account';

  @override
  String get navCustomerSearch => 'Customer search';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusAssignedToTeam => 'Assigned to team leader';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusInDelivery => 'Out for delivery';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get typeMosque => 'Specific mosque';

  @override
  String get typeMostNeeded => 'Most needed';

  @override
  String orderRefShort(String ref) {
    return 'Order $ref';
  }

  @override
  String destinationsCount(int count) {
    return '$count destinations';
  }

  @override
  String priceKwd(String amount) {
    return '$amount KWD';
  }

  @override
  String workshopActiveLoad(int count) {
    return '$count active deliveries';
  }

  @override
  String get adminOrdersTitle => 'Orders';

  @override
  String get searchOrdersHint =>
      'Search by customer number or order no. (ORD-…)';

  @override
  String get emptyOrders => 'No orders';

  @override
  String ordersCount(int count) {
    return '$count orders';
  }

  @override
  String get awaitingAssignmentBadge => 'Needs assignment';

  @override
  String get tabAwaiting => 'Awaiting assignment';

  @override
  String get tabAll => 'All';

  @override
  String get tabDelivered => 'Delivered';

  @override
  String get tabCancelled => 'Cancelled';

  @override
  String get tabInProgress => 'In progress';

  @override
  String get orderDateLabel => 'Order date';

  @override
  String get lastStatusUpdateLabel => 'Last update';

  @override
  String get orderDetailsTitle => 'Order details';

  @override
  String get giftLabel => 'Includes a gift';

  @override
  String get customerLabel => 'Customer';

  @override
  String get paymentLabel => 'Payment';

  @override
  String get paymentPaid => 'Paid';

  @override
  String get paymentUnpaid => 'Unpaid';

  @override
  String get notesLabel => 'Customer notes';

  @override
  String get destinationsLabel => 'Destinations';

  @override
  String get cancelReasonLabel => 'Cancellation reason';

  @override
  String get totalLabel => 'Total';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get noLocation => 'No map location';

  @override
  String get openLocation => 'Open location';

  @override
  String get assignedWorkshopLabel => 'Assigned workshop';

  @override
  String get teamLeaderLabel => 'Team leader';

  @override
  String get assignButton => 'Assign workshop';

  @override
  String get assignToTeamLeaderButton => 'Assign to team leader';

  @override
  String get distributeToHandler => 'Distribute to handler';

  @override
  String get approveCompletion => 'Approve completion';

  @override
  String get cancelOrderButton => 'Cancel order';

  @override
  String get cancelOrderTitle => 'Cancel order';

  @override
  String get cancelReasonHint => 'Cancellation reason';

  @override
  String get confirmCancel => 'Confirm cancellation';

  @override
  String get keepOrder => 'Back';

  @override
  String get orderCancelled => 'Order cancelled';

  @override
  String get assignTitle => 'Assign workshop';

  @override
  String get chooseWorkshop => 'Choose a workshop';

  @override
  String get chooseMosque => 'Choose a mosque';

  @override
  String get chooseTeamLeader => 'Choose a team leader';

  @override
  String get chooseHandlerWhoDelivered => 'Choose the handler who delivered';

  @override
  String get confirmAssign => 'Confirm assignment';

  @override
  String get assignSuccess => 'Workshop assigned successfully';

  @override
  String get assignTeamSuccess => 'Assigned to team leader successfully';

  @override
  String get distributeSuccess =>
      'Destination distributed to handler successfully';

  @override
  String get completeSuccess => 'Destination completion approved successfully';

  @override
  String get noWorkshops => 'No workshops available';

  @override
  String get noTeamLeaders => 'No team leaders available';

  @override
  String get searchMosqueHint => 'Search for a mosque';

  @override
  String get reassignButton => 'Reassign';

  @override
  String get reassignSuccess => 'Reassigned successfully';

  @override
  String get noOtherWorkshops => 'No other workshop available';

  @override
  String get timelineLabel => 'Order timeline';

  @override
  String get callButton => 'Call';

  @override
  String get whatsappButton => 'WhatsApp';

  @override
  String get contactFailed => 'Couldn\'t start the call';

  @override
  String get driverDeliveriesTitle => 'My deliveries';

  @override
  String get tabNew => 'New';

  @override
  String get tabAccepted => 'Accepted';

  @override
  String get tabInDelivery => 'Out for delivery';

  @override
  String get tabCompleted => 'Completed';

  @override
  String get emptyDeliveries => 'No deliveries';

  @override
  String get deliveryDetailsTitle => 'Delivery details';

  @override
  String get acceptButton => 'Accept';

  @override
  String get rejectButton => 'Reject';

  @override
  String get startDeliveryButton => 'Start delivery';

  @override
  String get uploadProofButton => 'Upload proof & finish delivery';

  @override
  String get acceptedMsg => 'Delivery accepted';

  @override
  String get deliveryStartedMsg => 'Delivery started';

  @override
  String get rejectedMsg => 'Delivery rejected';

  @override
  String get deliveredNote => 'This destination has been delivered';

  @override
  String get rejectTitle => 'Reject delivery';

  @override
  String get rejectReasonHint => 'Reason for rejection (optional)';

  @override
  String get confirmReject => 'Confirm rejection';

  @override
  String get proofTitle => 'Delivery proof';

  @override
  String get proofHint =>
      'Add photos or a video to prove installation, then upload to finish the delivery.';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get fromGallery => 'From gallery';

  @override
  String get addVideo => 'Video';

  @override
  String get proofNoteHint => 'Note (optional)';

  @override
  String get proofNoteDefaultDelivered =>
      'The order was delivered and installed on site.';

  @override
  String get uploadAndFinish => 'Upload & finish delivery';

  @override
  String get pickFailed => 'Couldn\'t pick the file';

  @override
  String get noProofSelected => 'Choose a photo or video first';

  @override
  String get proofUploaded => 'Proof uploaded — delivered';

  @override
  String get deliveryProofs => 'Delivery proofs';

  @override
  String get cannotOpenFile => 'Couldn\'t open the file';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get emptyNotifications => 'No notifications';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashNew => 'New';

  @override
  String get dashAwaiting => 'Awaiting assignment';

  @override
  String get dashAssigned => 'In progress';

  @override
  String get dashCompleted => 'Completed';

  @override
  String get dashCancelled => 'Cancelled';

  @override
  String get dashAll => 'Total';

  @override
  String get completionRate => 'Completion rate';

  @override
  String get slaTitle => 'Average service time';

  @override
  String get slaAvgConfirm => 'Average confirmation time';

  @override
  String get slaAvgDeliver => 'Average delivery time';

  @override
  String get slaSample => 'Completed orders';

  @override
  String minutesValue(String value) {
    return '$value min';
  }

  @override
  String get activityTitle => 'My activity';

  @override
  String get emptyActivity => 'No activity';

  @override
  String get actionAssigned => 'Assigned destination to a workshop';

  @override
  String get actionReassigned => 'Reassigned a destination';

  @override
  String get actionCancelled => 'Cancelled an order';

  @override
  String get customerLookupTitle => 'Find a customer';

  @override
  String get lookupHint => 'Search by phone number or name';

  @override
  String get lookupPrompt =>
      'Search for a customer by phone number, name, or ID to view their record';

  @override
  String get lookupIdHint => 'ID';

  @override
  String get lookupNoResults => 'No matching customer';

  @override
  String get approvalsTitle => 'Approvals inbox';

  @override
  String get emptyApprovals => 'No pending approvals';

  @override
  String get approveButton => 'Approve';

  @override
  String get approveSuccess => 'Request approved';

  @override
  String get rejectSuccess => 'Request rejected';

  @override
  String get approvalRejectTitle => 'Reason for rejection';

  @override
  String get approvalRejectHint => 'Write the reason for rejection';

  @override
  String get approvalMakerLabel => 'Requested by';

  @override
  String get escalationsTitle => 'Escalations';

  @override
  String get emptyEscalations => 'No escalations';

  @override
  String get resolveButton => 'Resolve';

  @override
  String get resolveSuccess => 'Escalation resolved';

  @override
  String get raiseEscalationTitle => 'Raise an escalation';

  @override
  String get raiseEscalationHint => 'Write the reason for the escalation';

  @override
  String get escalationRaised => 'Escalation raised';

  @override
  String get escalationRaisedByLabel => 'By';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get productsTitle => 'Product availability';

  @override
  String get searchProductsHint => 'Search for a product';

  @override
  String get emptyProducts => 'No products';

  @override
  String get productSuspended => 'Suspended';

  @override
  String get productInactive => 'Inactive (managed on the web)';

  @override
  String get suspendReasonTitle => 'Reason for suspension';

  @override
  String get suspendReasonHint => 'e.g. out of stock (optional)';

  @override
  String get suspendConfirm => 'Suspend';

  @override
  String get profileTitle => 'Account';

  @override
  String get roleAdmin => 'Manager';

  @override
  String get roleDriver => 'Delivery workshop';

  @override
  String get logout => 'Sign out';

  @override
  String get userFallback => 'User';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get themeSystem => 'Match device';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get notificationChannelName => 'Sapbaq notifications';

  @override
  String get notificationChannelDescription =>
      'Order assignments and delivery updates.';
}
