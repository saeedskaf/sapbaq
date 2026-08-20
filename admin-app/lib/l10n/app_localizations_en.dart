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
  String get tabNew => 'New';

  @override
  String get tabConfirmed => 'Confirmed';

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
  String get mosquesSelectGovernorate => 'Choose a governorate';

  @override
  String get mosquesSelectArea => 'Choose an area';

  @override
  String get mosquesNoAreas => 'No areas in this governorate';

  @override
  String get mosquesNone => 'No mosques';

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
  String get markAllRead => 'Mark all read';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashNew => 'New';

  @override
  String get dashAwaiting => 'Awaiting assignment';

  @override
  String get dashAssigned => 'Confirmed';

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
  String get approvePickModel => 'Choose the approved model';

  @override
  String get approveModelNote =>
      'Choosing the model fixes the funding goal; the request is then published for donors to fund.';

  @override
  String approveWithTarget(String amount) {
    return 'Approve with a $amount KWD goal';
  }

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
  String productVariantsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count variants',
      one: '1 variant',
    );
    return '$_temp0';
  }

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

  @override
  String get confirmButton => 'Confirm';

  @override
  String get saveButton => 'Save';

  @override
  String get nextButton => 'Next';

  @override
  String get back => 'Back';

  @override
  String get otpLabel => 'Verification code';

  @override
  String get sendCodeButton => 'Send code';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCodeIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get filterGovernorate => 'Governorate';

  @override
  String get filterArea => 'Area';

  @override
  String get repEntryPrompt => 'Are you a mosque representative? Tap here';

  @override
  String get repLoginTitle => 'Representative sign-in';

  @override
  String get repLoginSubtitle => 'Enter your phone number to continue';

  @override
  String get repPasscodeLabel => 'Passcode';

  @override
  String get repPasscodeRequired => 'Enter your 4-digit passcode';

  @override
  String get repPasscodeStepTitle => 'Enter your passcode';

  @override
  String get repPasscodeStepSubtitle =>
      'Enter your 4-digit passcode to sign in';

  @override
  String get repChangePhone => 'Change number';

  @override
  String get continueButton => 'Continue';

  @override
  String get repForgotPasscode => 'Forgot your passcode?';

  @override
  String get repForgotSubtitle =>
      'We\'ll send a verification code to your phone to set a new passcode';

  @override
  String get repPasscodeResetDone => 'Your new passcode is set';

  @override
  String get repRegisterButton => 'Register as a representative';

  @override
  String get repHaveInvite => 'I have an invite link';

  @override
  String get repRegisterTitle => 'Representative registration';

  @override
  String get repRegisterPhoneStep =>
      'Enter your phone number to receive a verification code';

  @override
  String get repRegisterIdentityStep =>
      'Enter the verification code and your name';

  @override
  String get repRegisterMosqueStep =>
      'Pinpoint your mosque: governorate, then area, then mosque';

  @override
  String get repRegisterPasscodeStep =>
      'Create a 4-digit passcode for daily sign-in';

  @override
  String get repFillAllFields => 'Please fill in all required fields';

  @override
  String get repFirstName => 'First name';

  @override
  String get repLastName => 'Last name';

  @override
  String get repSearchMosque => 'Search mosques by name';

  @override
  String get repPasscodeCreate => 'New passcode';

  @override
  String get repPasscodeConfirm => 'Confirm passcode';

  @override
  String get repPasscodeMismatch => 'The passcodes don\'t match';

  @override
  String get repRegisterSubmit => 'Submit';

  @override
  String get repInviteTitle => 'Register with an invite';

  @override
  String get repInviteSubtitle =>
      'Enter the invite code you received from Sapbaq';

  @override
  String get repInviteToken => 'Invite code';

  @override
  String get repInviteCheck => 'Check invite';

  @override
  String get repPendingTitle => 'Your request is under review';

  @override
  String get repPendingBody =>
      'We received your registration as a mosque representative. The Sapbaq team will contact you to verify, then activate your account — after that you can sign in with your phone and passcode.';

  @override
  String get repBackToLogin => 'Back to sign-in';

  @override
  String get repNavMosque => 'My mosque';

  @override
  String get repNavReports => 'My reports';

  @override
  String get repActionsTitle => 'Actions';

  @override
  String get repReportMaintenance => 'Maintenance report';

  @override
  String get repReportMaintenanceDesc =>
      'Report a fault on a unit registered to your mosque';

  @override
  String get repWaterFlagTitle => 'Water shortage';

  @override
  String get repWaterFlagDesc =>
      'One tap to flag that your mosque is low on water';

  @override
  String get repWaterFlagConfirm =>
      'Send a water-shortage flag for your mosque? Users will see it once approved.';

  @override
  String get repWaterFlagSent => 'Water-shortage flag sent';

  @override
  String get repRequestEquipment => 'Request new equipment';

  @override
  String get repRequestEquipmentDesc =>
      'Request a new water cooler or fridge for your mosque';

  @override
  String get repUnitsTitle => 'My mosque\'s equipment';

  @override
  String get repNoUnits => 'No equipment registered to your mosque yet';

  @override
  String get repStatusPending => 'Awaiting approval';

  @override
  String get repStatusDeactivated => 'Deactivated';

  @override
  String get repPickUnit => 'Pick the unit';

  @override
  String get repIssueType => 'Issue type';

  @override
  String get repIssueFilterChange => 'Filter change';

  @override
  String get repIssueNotWorking => 'Not working';

  @override
  String get repIssueLeaking => 'Leaking';

  @override
  String get repIssueOther => 'Other';

  @override
  String get repIssueOtherNeedsDesc =>
      'A description is required for \"Other\"';

  @override
  String get repIssueDescription => 'Issue description';

  @override
  String get repReportSubmit => 'Submit report';

  @override
  String get repReportSent => 'Report sent';

  @override
  String get repEquipmentType => 'Equipment type';

  @override
  String get repEquipmentNote => 'Note (optional)';

  @override
  String get repEquipmentRequestSent => 'Equipment request sent';

  @override
  String get repTabMaintenance => 'Maintenance';

  @override
  String get repTabWater => 'Water';

  @override
  String get repTabEquipment => 'Equipment';

  @override
  String get repNoReports => 'No reports yet';

  @override
  String get repStatusSubmitted => 'Submitted';

  @override
  String get repStatusInProgress => 'In progress';

  @override
  String get repStatusResolved => 'Resolved';

  @override
  String get repStatusApproved => 'Approved';

  @override
  String get repStatusFulfilled => 'Fulfilled';

  @override
  String get repStatusRejected => 'Rejected';

  @override
  String get repStatusCancelled => 'Cancelled';

  @override
  String get repRefresh => 'Refresh';

  @override
  String get repFieldReference => 'Reference';

  @override
  String get repFieldEquipmentCode => 'Equipment code';

  @override
  String get repFieldIssue => 'Issue';

  @override
  String get repFieldDescription => 'Description';

  @override
  String get repFieldNote => 'Note';

  @override
  String get repFieldDate => 'Submitted';

  @override
  String get repFieldApprovedAt => 'Approved on';

  @override
  String get repFieldFulfilledAt => 'Fulfilled on';

  @override
  String get repFieldResolvedAt => 'Resolved on';

  @override
  String get repFieldRejectReason => 'Rejection reason';

  @override
  String get repPhotos => 'Photos';

  @override
  String get repAddPhotos => 'Add photos';

  @override
  String get repPhotosHint => 'Optional — up to 5 photos';

  @override
  String get repMaxPhotos => 'You can add up to 5 photos';

  @override
  String get opsTitle => 'Operations center';

  @override
  String get opsSubtitle =>
      'Everything waiting on you, grouped by what your role can do';

  @override
  String opsPendingTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items need your action',
      one: '1 item needs your action',
    );
    return '$_temp0';
  }

  @override
  String get opsAllClear => 'Nothing needs your action';

  @override
  String get opsAllClearDesc => 'Every queue your role can act on is clear';

  @override
  String get opsUpdating => 'Updating counts…';

  @override
  String get opsNothingHere => 'Nothing new right now';

  @override
  String opsRoleScope(String name) {
    return 'Scope: $name';
  }

  @override
  String get opsNoQueues => 'No queues are available for your role yet';

  @override
  String get opsSectionApprovals => 'Needs your decision';

  @override
  String get opsSectionApprovalsDesc =>
      'Requests raised by mosques or bought by donors — nothing moves until you approve.';

  @override
  String get opsSectionField => 'Execution & follow-up';

  @override
  String get opsSectionFieldDesc =>
      'After approval: assigning the work, doing it on site, and documenting it.';

  @override
  String get opsSectionCreate => 'Raise a request';

  @override
  String get opsSectionCreateDesc =>
      'Record a need on behalf of management, without waiting for the mosque to ask.';

  @override
  String get opsHowItWorks => 'How operations flow';

  @override
  String get opsHowStep1 => 'Request';

  @override
  String get opsHowStep1Desc =>
      'An imam reports a water shortage or asks for a unit, or a donor buys one from the store.';

  @override
  String get opsHowStep2 => 'Approval';

  @override
  String get opsHowStep2Desc =>
      'Management reviews it: approved goes out for donations, rejected closes with a written reason.';

  @override
  String get opsHowStep3 => 'Funding';

  @override
  String get opsHowStep3Desc =>
      'Donations complete the amount, and the need becomes a fulfilment task.';

  @override
  String get opsHowStep4 => 'Assignment';

  @override
  String get opsHowStep4Desc =>
      'The task goes to a team leader, who hands it to a field handler.';

  @override
  String get opsHowStep5 => 'Execution & proof';

  @override
  String get opsHowStep5Desc =>
      'The handler does the work and attaches a statement and photos that close the task.';

  @override
  String get opsHowFooter =>
      'You only see the queues your role allows, limited to your geographic scope.';

  @override
  String get navOperations => 'Operations';

  @override
  String get opsWaterFlags => 'Water shortage reports';

  @override
  String get opsWaterFlagsDesc =>
      'Raised by imams when drinking water runs low. Approve one to open it for donations, or cancel it.';

  @override
  String get opsWaterFlagItem => 'Water shortage report';

  @override
  String get opsEquipmentRequests => 'New equipment requests';

  @override
  String get opsEquipmentRequestsDesc =>
      'Imams asking for a unit for their mosque. Approve to start its funding campaign, or reject it.';

  @override
  String get opsEquipmentRequestItem => 'Equipment request';

  @override
  String get opsEmptyQueue => 'Nothing in this queue';

  @override
  String get opsMosque => 'Mosque';

  @override
  String get opsConfirmCancel => 'Cancel this request?';

  @override
  String get opsCancelAction => 'Cancel request';

  @override
  String get opsFilterMonth => 'Month';

  @override
  String get opsFilterStatus => 'Status';

  @override
  String get opsFilterPriority => 'Priority';

  @override
  String get opsFilterKind => 'Type';

  @override
  String get opsFilterAny => 'All';

  @override
  String get opsFilterAllTime => 'All periods';

  @override
  String get mtTitle => 'Maintenance cases';

  @override
  String get mtCaseTitle => 'Case details';

  @override
  String get mtDescTriage =>
      'Faults on installed units. Acknowledge, set priority and cost path, then assign a team leader.';

  @override
  String get mtDescLeader =>
      'Claim approved cases in your area, hand them to your members, and verify completion.';

  @override
  String get mtDescHandler =>
      'Maintenance cases assigned to you. Do the repair and attach completion photos.';

  @override
  String get mtStatusSubmitted => 'Submitted';

  @override
  String get mtStatusAcknowledged => 'Acknowledged';

  @override
  String get mtStatusApproved => 'Approved';

  @override
  String get mtStatusAssigned => 'Assigned to leader';

  @override
  String get mtStatusInProgress => 'In progress';

  @override
  String get mtStatusCompleted => 'Completed';

  @override
  String get mtStatusResolved => 'Resolved';

  @override
  String get mtStatusDuplicate => 'Duplicate';

  @override
  String get mtStatusCancelled => 'Cancelled';

  @override
  String get mtPriorityLow => 'Low';

  @override
  String get mtPriorityMedium => 'Medium';

  @override
  String get mtPriorityHigh => 'High';

  @override
  String get mtPriorityUrgent => 'Urgent';

  @override
  String get mtCostUnset => 'Not set';

  @override
  String get mtCostFreeWarranty => 'Free (warranty)';

  @override
  String get mtCostManufacturer => 'Manufacturer (compressor)';

  @override
  String get mtCostCustomerPaid => 'Customer-funded';

  @override
  String get mtFieldPriority => 'Priority';

  @override
  String get mtFieldCostPath => 'Cost path';

  @override
  String get mtFieldPrice => 'Price';

  @override
  String get mtFieldReporter => 'Reporter';

  @override
  String get mtFieldTeamLeader => 'Team leader';

  @override
  String get mtFieldMember => 'Member';

  @override
  String get mtFieldStatement => 'Completion note';

  @override
  String get mtAcknowledge => 'Acknowledge';

  @override
  String get mtSetPriority => 'Set priority';

  @override
  String get mtAssignLeader => 'Assign team leader';

  @override
  String get mtAssignMember => 'Assign member';

  @override
  String get mtComplete => 'Complete';

  @override
  String get mtVerify => 'Verify completion';

  @override
  String get mtCancelCase => 'Cancel case';

  @override
  String get mtApproveTitle => 'Approve case';

  @override
  String get mtChooseCostPath => 'Choose the cost path';

  @override
  String get mtPriceKwd => 'Price (KWD)';

  @override
  String get mtPriceRequired => 'Enter a price for customer-funded repairs';

  @override
  String get mtChoosePriority => 'Choose priority';

  @override
  String get mtChooseLeader => 'Choose a team leader';

  @override
  String get mtChooseMember => 'Choose a member';

  @override
  String get mtStatementHint => 'Describe what was done';

  @override
  String get mtStatementRequired => 'Enter a completion note';

  @override
  String get mtNoLeaders => 'No team leaders available';

  @override
  String get mtNoMembers => 'No members available';

  @override
  String mtActiveLoad(int count) {
    return '$count active';
  }

  @override
  String mtSuggested(String label) {
    return 'Suggested: $label';
  }

  @override
  String get mtManufacturerRouted => 'Routed to manufacturer';

  @override
  String get mtActionDone => 'Done';

  @override
  String get mtConfirmCancelCase => 'Cancel this maintenance case?';

  @override
  String get mtDuplicate => 'Merge duplicate';

  @override
  String get mtDuplicatePickHint =>
      'Choose the canonical case for this equipment';

  @override
  String get mtDuplicateEmpty => 'No other cases for this equipment';

  @override
  String get mtDuplicateNoCode => 'No equipment code to find a canonical case';

  @override
  String mtMergedInto(int id) {
    return 'Merged into case #$id';
  }

  @override
  String get mtSearchHint => 'Search by equipment code';

  @override
  String get ctTitle => 'Contributions';

  @override
  String get ctDesc => 'Ledger of contributions, amounts, and states';

  @override
  String get ctKindWater => 'Water';

  @override
  String get ctKindMaintenance => 'Maintenance';

  @override
  String get ctKindEquipment => 'Equipment';

  @override
  String get ctStatusPending => 'Pending';

  @override
  String get ctStatusPaid => 'Paid';

  @override
  String get ctStatusFulfilled => 'Fulfilled';

  @override
  String get ctStatusExpired => 'Expired';

  @override
  String get ctStatusCancelled => 'Cancelled';

  @override
  String get ctCustomer => 'Donor';

  @override
  String get ctMaintenanceAutoSettle =>
      'Settles automatically when the maintenance case is verified';

  @override
  String get ctViaTasksNote => 'Executed through the fulfilment-task queue';

  @override
  String get ftTitle => 'Fulfilment tasks';

  @override
  String get ftDescDispatch =>
      'Fully funded water and equipment, ready to execute. Assign each task to a team leader.';

  @override
  String get ftDescLeader =>
      'Tasks assigned to your team. Hand them to a handler, or execute and document them yourself.';

  @override
  String get ftDescHandler =>
      'Tasks assigned to you. Execute them and attach a statement and photo.';

  @override
  String get ftFilterOpen => 'Open';

  @override
  String get ftStatusAwaitingAssign => 'Awaiting assignment';

  @override
  String get ftStatusAssignedToTeam => 'Assigned to team';

  @override
  String get ftStatusAssigned => 'Assigned to handler';

  @override
  String get ftStatusDone => 'Done';

  @override
  String get ftStatusCancelled => 'Cancelled';

  @override
  String get ftAssignHandler => 'Assign a handler';

  @override
  String get ftChooseHandler => 'Choose a handler';

  @override
  String get ftNoHandlers => 'No handlers available';

  @override
  String get ftFieldHandler => 'Handler';

  @override
  String ftFullyFunded(String amount) {
    return 'Fully funded: $amount KWD';
  }

  @override
  String get ftFulfil => 'Fulfil task';

  @override
  String get ftFulfilled => 'Task fulfilled';

  @override
  String get ftStatement => 'Fulfilment statement';

  @override
  String get ftStatementHint => 'Describe what was done';

  @override
  String get ftStatementRequired => 'Enter the fulfilment statement';

  @override
  String get ftPhotoRequired => 'Attach the fulfilment photo';

  @override
  String get mtPhotosRequired => 'Attach at least one completion photo';

  @override
  String mtPhotosMax(int count) {
    return 'Maximum $count photos';
  }

  @override
  String get dedicationAlive => 'Alive';

  @override
  String get dedicationDeceased => 'Deceased';

  @override
  String get mtClaim => 'Claim case';

  @override
  String get mtClaimConfirm =>
      'This case will be assigned to you and your team. Continue?';

  @override
  String get mtReadyToClaim => 'Ready to claim';

  @override
  String get mtChannelManager => 'Raised by management';

  @override
  String get dpTitle => 'Raise a request directly';

  @override
  String get dpDesc =>
      'Record a water, equipment, or maintenance need for any mosque in your area — published at once, with no approval step.';

  @override
  String get dpWater => 'Water shortage';

  @override
  String get dpWaterDesc => 'A water flag published for funding at once';

  @override
  String get dpWaterConfirm =>
      'A water flag will be raised for this mosque and published at once. Continue?';

  @override
  String get dpEquipment => 'Equipment request';

  @override
  String get dpEquipmentDesc => 'A new unit published for funding at once';

  @override
  String get dpMaintenance => 'Maintenance case';

  @override
  String get dpMaintenanceDesc =>
      'A case on an installed unit, entering the claim queue';

  @override
  String get dpMosque => 'Mosque';

  @override
  String get dpMosqueRequired => 'Choose the mosque first';

  @override
  String get dpEquipmentType => 'Equipment type';

  @override
  String get dpModel => 'Model';

  @override
  String get dpModelRequired => 'Choose a model';

  @override
  String get dpNoTypes => 'No equipment types';

  @override
  String get dpNoModels => 'No models for this type';

  @override
  String get dpTargetAmountLabel => 'Target amount';

  @override
  String dpTargetAmount(String amount) {
    return 'Target amount: $amount KWD';
  }

  @override
  String get dpNote => 'Note (optional)';

  @override
  String get dpUnit => 'Unit';

  @override
  String get dpNoUnits => 'No units registered at this mosque';

  @override
  String get dpUnitInWarranty => 'In warranty';

  @override
  String get dpCostPath => 'Cost path';

  @override
  String get dpSubmit => 'Submit';

  @override
  String get dpCreated => 'Created and published';

  @override
  String get locSortedByDistance =>
      'Sorted nearest first · straight-line estimate';

  @override
  String get locEnableHint =>
      'Enable location to sort your tasks nearest first';

  @override
  String get locUnavailable => 'Location unavailable';

  @override
  String locDistanceKm(String km) {
    return '$km km';
  }

  @override
  String locNearestDestination(String km) {
    return 'Nearest stop: $km km';
  }

  @override
  String get locDirections => 'Directions';

  @override
  String get coTitle => 'Store equipment purchases';

  @override
  String get coDesc =>
      'Units customers buy for a specific mosque. Review an order to open its payment window.';

  @override
  String get coDescField =>
      'Paid units awaiting assignment, or installation and its record.';

  @override
  String get coDescWatch =>
      'Follow customer purchases from approval through to installation.';

  @override
  String get coStatusUnderReview => 'Under review';

  @override
  String get coStatusApproved => 'Approved — awaiting payment';

  @override
  String get coStatusPaid => 'Paid';

  @override
  String get coStatusInstalled => 'Installed';

  @override
  String get coStatusRejected => 'Rejected';

  @override
  String get coApproveConfirm =>
      'Approving opens a 48-hour payment window for the customer. Continue?';

  @override
  String get coInstall => 'Record installation';

  @override
  String get coInstallConfirm =>
      'The unit will be registered with a code and warranty. Continue?';

  @override
  String coAwaitingPayment(String deadline) {
    return 'Awaiting customer payment until $deadline';
  }
}
