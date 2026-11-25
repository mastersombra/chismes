// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Share stories, discover secrets';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonEmailInvalid => 'Invalid email';

  @override
  String get commonEnterEmail => 'Enter an email';

  @override
  String get commonEnterPassword => 'Enter your password';

  @override
  String commonMaxLength(String count) {
    return 'Cannot exceed $count characters';
  }

  @override
  String commonMinLength(String count) {
    return 'Must be at least $count characters';
  }

  @override
  String get commonRetry => 'Retry';

  @override
  String commonSelect(String field) {
    return 'Select $field';
  }

  @override
  String get errorsAuthEmailAlreadyInUse => 'This email is already registered.';

  @override
  String get authEmailAlreadyInUseAction =>
      'This email is already registered. Sign in instead.';

  @override
  String get errorsAuthEmailNotVerified =>
      'You must verify your email to continue.';

  @override
  String get errorsAuthExpiredToken =>
      'Invalid or expired code. Request a new one.';

  @override
  String get errorsAuthInvalidCredentials =>
      'Incorrect email or password. Please check your data and try again.';

  @override
  String get errorsAuthInvalidToken =>
      'Invalid or expired code. Request a new one.';

  @override
  String get errorsAuthNotAuthenticated => 'You must sign in to continue.';

  @override
  String get errorsAuthOauthCancelled => 'Sign in cancelled.';

  @override
  String get errorsAuthOauthProviderError => 'Error signing in with provider.';

  @override
  String get errorsAuthSessionExpired =>
      'Your session has expired. Sign in again.';

  @override
  String get errorsAuthTooManyAttempts => 'Too many attempts. Try again later.';

  @override
  String get errorsAuthUnauthorized =>
      'You are not authorized to perform this action.';

  @override
  String get errorsAuthUserNotFound => 'User not found.';

  @override
  String get errorsAuthUsernameTaken => 'This username is already taken.';

  @override
  String get errorsAuthWeakPassword => 'The password is too weak.';

  @override
  String get errorsBusinessGossipNotFound =>
      'The gossip does not exist or was deleted.';

  @override
  String get errorsBusinessInvalidGossipContent =>
      'The gossip content is invalid.';

  @override
  String get errorsBusinessInvalidLocation =>
      'Invalid location. Select a valid location.';

  @override
  String get errorsBusinessMediaUploadFailed =>
      'Could not upload the image. Please try again or try another image.';

  @override
  String get errorsBusinessModerationRejected =>
      'The content does not meet our community standards. Please review the content and try again.';

  @override
  String get errorsBusinessRateLimitExceeded =>
      'You\'ve reached the request limit. Wait a moment and try again.';

  @override
  String get errorsDataAlreadyExists => 'The resource already exists.';

  @override
  String get errorsDataConflict => 'Data conflict. Try again.';

  @override
  String get errorsDataNotFound => 'The requested resource does not exist.';

  @override
  String get errorsNetworkConnectionError =>
      'Connection error. Please check your internet.';

  @override
  String get errorsNetworkNoInternet =>
      'You have no internet connection. Check your network.';

  @override
  String get errorsNetworkTimeout => 'The request took too long. Try again.';

  @override
  String get errorsPermissionsForbidden =>
      'You don\'t have permission to perform this action.';

  @override
  String get errorsPermissionsInsufficient =>
      'Insufficient permissions for this action.';

  @override
  String get errorsServerBadRequest => 'Invalid request. Check the data sent.';

  @override
  String get errorsServerError => 'Server error. Try again later.';

  @override
  String get errorsServerMaintenance =>
      'The server is under maintenance. Try again later.';

  @override
  String get errorsServerTooManyRequests =>
      'You\'ve reached the request limit. Wait a moment and try again.';

  @override
  String get errorsServerUnavailable =>
      'The service is temporarily unavailable.';

  @override
  String get errorsTitlesAuth => 'Authentication Error';

  @override
  String get errorsTitlesConnection => 'Connection Error';

  @override
  String get errorsTitlesData => 'Data Error';

  @override
  String get errorsTitlesGeneral => 'Error';

  @override
  String get errorsTitlesPermissions => 'Permission Error';

  @override
  String get errorsTitlesServer => 'Server Error';

  @override
  String get errorsTitlesUnexpected => 'Unexpected Error';

  @override
  String get errorsTitlesValidation => 'Validation Error';

  @override
  String get errorsUnknown => 'An unexpected error occurred. Try again.';

  @override
  String get errorsValidationError =>
      'Validation error. Check the entered data.';

  @override
  String get errorsValidationInvalidInput => 'Invalid data. Check the format.';

  @override
  String get errorsValidationMissingField => 'A required field is missing.';

  @override
  String get gossipAddScreenEmailVerificationResent =>
      'Verification email resent. Check your inbox.';

  @override
  String get gossipAddScreenSubmitButton => 'Publish gossip';

  @override
  String get gossipAddScreenSuccessDialogButton => 'OK';

  @override
  String get gossipAddScreenSuccessDialogContentPending =>
      'Your gossip is pending moderation. We\'ll notify you when its status changes.';

  @override
  String get gossipAddScreenSuccessDialogContentPublished =>
      'Your gossip passed automatic checks and is now published.';

  @override
  String get gossipAddScreenSuccessDialogTitlePending => 'Gossip sent!';

  @override
  String get gossipAddScreenSuccessDialogTitlePublished => 'Gossip published!';

  @override
  String get gossipAddScreenTitle => 'New Gossip 📝';

  @override
  String get gossipCardRateLimitError => 'Rate limit reached';

  @override
  String get gossipCardReportError => 'Error reporting';

  @override
  String get gossipCardReportSemanticHint =>
      'Opens options to report inappropriate content';

  @override
  String get gossipCardReportSemanticLabel => 'Report this gossip';

  @override
  String get gossipCardReportSuccess =>
      'Thanks for your report. We\'ll review it soon.';

  @override
  String get gossipCardReportTooltip => 'Report gossip';

  @override
  String get gossipCardSemanticHint => 'Tap to view full details';

  @override
  String gossipCardSemanticLabel(String subject, String content) {
    return 'Gossip: $subject. $content';
  }

  @override
  String get gossipCardShareError => 'Error sharing';

  @override
  String get gossipCardShareSemanticHint =>
      'Opens options to share with others';

  @override
  String get gossipCardShareSemanticLabel => 'Share this gossip';

  @override
  String get gossipCardShareTooltip => 'Share gossip';

  @override
  String get gossipLocationSelectorChangeButtonLabel => 'Change';

  @override
  String get gossipLocationSelectorChangeButtonSemanticHint =>
      'Opens the location selector';

  @override
  String get gossipLocationSelectorChangeButtonSemanticLabel =>
      'Change location';

  @override
  String get gossipLocationSelectorDetectingText => 'Detecting location...';

  @override
  String get gossipLocationSelectorIconSemanticLabel => 'Location icon';

  @override
  String get gossipLocationSelectorPlaceholderText => 'Select location';

  @override
  String get gossipLocationSelectorSemanticHint =>
      'Tap the change button to select another location';

  @override
  String get gossipLocationSelectorSemanticLabelDetecting =>
      'Automatically detecting location';

  @override
  String get gossipLocationSelectorSemanticLabelEmpty => 'No location selected';

  @override
  String gossipLocationSelectorSemanticLabelSelected(String location) {
    return 'Current location: $location';
  }

  @override
  String get gossipMediaAddAudio => 'Add audio';

  @override
  String get gossipMediaAddImage => 'Add image';

  @override
  String get gossipMediaAddPhotoOptional => 'Add a photo (optional)';

  @override
  String get gossipMediaAudioAttached => 'Audio attached';

  @override
  String get gossipMediaCamera => 'Camera';

  @override
  String get gossipMediaCameraSemanticHint =>
      'Opens the camera to take a photo';

  @override
  String get gossipMediaCameraSemanticLabel => 'Take photo with camera';

  @override
  String get gossipMediaGallery => 'Gallery';

  @override
  String get gossipMediaGallerySemanticHint => 'Opens the photo gallery';

  @override
  String get gossipMediaGallerySemanticLabel => 'Select photo from gallery';

  @override
  String get gossipMediaImageSelected => 'Image selected';

  @override
  String get gossipMediaImageSemanticLabel => 'Selected gossip image';

  @override
  String get gossipMediaLoadingSemantic => 'Loading image';

  @override
  String get gossipMediaRemoveImageSemanticHint => 'Removes the selected image';

  @override
  String get gossipMediaRemoveImageSemanticLabel => 'Remove image';

  @override
  String get gossipMediaRemoveImageTooltip => 'Remove image';

  @override
  String get gossipMediaSelectingImage => 'Selecting image...';

  @override
  String get gossipMediaSelectingSemanticLabel =>
      'Selecting image, please wait';

  @override
  String get gossipPublishAsAnonymous => 'Anonymous';

  @override
  String get gossipPublishAsTitle => 'Publish as';

  @override
  String get gossipPublishAsWithProfile => 'With my profile';

  @override
  String get gossipReportButton => 'Report';

  @override
  String get gossipReportDetailsHint => 'Describe the problem...';

  @override
  String get gossipReportDetailsLabel => 'Additional details (optional)';

  @override
  String get gossipReportReasonQuestion => 'Why are you reporting this gossip?';

  @override
  String get gossipReportTitle => 'Report gossip';

  @override
  String get gossipReportReasonSpam => 'Spam';

  @override
  String get gossipReportReasonHarassment => 'Harassment or bullying';

  @override
  String get gossipReportReasonViolence => 'Violence or threats';

  @override
  String get gossipReportReasonSexualContent => 'Sexual content';

  @override
  String get gossipReportReasonMisinformation => 'Misinformation';

  @override
  String get gossipReportReasonOther => 'Other reason';

  @override
  String get gossipTextFieldsContentHint => 'Tell us what you know...';

  @override
  String get gossipTextFieldsContentLabel => 'The gossip';

  @override
  String get gossipTextFieldsContentValidation => 'Tell the gossip';

  @override
  String get gossipTextFieldsSubjectHint =>
      'E.g.: John, the office, the gym...';

  @override
  String get gossipTextFieldsSubjectLabel => 'About who or where?';

  @override
  String get gossipTextFieldsSubjectValidation =>
      'Write about who or where the gossip is';

  @override
  String get homeDiscoverHeader => 'Discover 👀';

  @override
  String get homeErrorLoadFailed => 'Error loading feed';

  @override
  String get homeErrorRetry => 'Retry';

  @override
  String get homeFollowingEmptyStateMessage =>
      'Discover interesting people and follow their stories';

  @override
  String get homeFollowingEmptyStateTitle => 'You\'re not following anyone yet';

  @override
  String get homeFollowingExploreUsersButton => 'Explore users';

  @override
  String get homeFollowingFeatureNotImplemented =>
      'Feature not implemented yet';

  @override
  String get homeFollowingNoPostsMessage =>
      '💬 People you follow haven\'t posted yet';

  @override
  String get homeFollowingRecommendedBadge => '💡 Recommended for you';

  @override
  String get homeFollowingUsePopularTabHint => 'Use the Popular tab above';

  @override
  String get homeFollowingViewPopularLink => 'View Popular';

  @override
  String get homePopularEmpty => 'No gossips available';

  @override
  String get homePopularNoMore => 'No more gossips for now 🌙';

  @override
  String get homeTabsFollowing => 'Following';

  @override
  String get homeTabsPopular => 'Popular';

  @override
  String get homePopularTrendingBadge => 'Trending';

  @override
  String get navigationCreate => 'Create';

  @override
  String get navigationExplore => 'Explore';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationProfile => 'Profile';

  @override
  String get profileHeaderCompleteness => 'Profile completeness';

  @override
  String get profileHeaderEmailVerified => 'Email verified';

  @override
  String get profileHeaderNoName => 'No name';

  @override
  String get profileScreenErrorLoading => 'Error loading profile';

  @override
  String get profileScreenNoUser => 'No authenticated user';

  @override
  String get profileScreenRefreshTooltip => 'Refresh';

  @override
  String get profileScreenSignOutButton => 'Sign out';

  @override
  String get profileScreenSignOutDialogContent =>
      'Are you sure you want to sign out?';

  @override
  String get profileScreenSignOutDialogTitle => 'Sign out';

  @override
  String get profileDeleteAccountButton => 'Delete account';

  @override
  String get profileDeleteAccountDialogTitle => 'Delete your account?';

  @override
  String get profileDeleteAccountDialogContent =>
      'Your account, profile and all your gossips (including anonymous ones) and their photos will be permanently deleted right away. This can\'t be undone.';

  @override
  String get profileDeleteAccountDialogRetention =>
      'If any of your content was rejected by moderation, we keep only an anonymous record of those violations to prevent abuse.';

  @override
  String get profileDeleteAccountConfirmWord => 'DELETE';

  @override
  String profileDeleteAccountConfirmLabel(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get profileDeleteAccountConfirmButton => 'Delete permanently';

  @override
  String get profileDeleteAccountDeleting => 'Deleting account...';

  @override
  String get profileDeleteAccountSuccess => 'Your account was deleted';

  @override
  String get profileDeleteAccountError =>
      'Couldn\'t delete your account. Check your connection and try again.';

  @override
  String get profileScreenSigningOut => 'Signing out...';

  @override
  String get profileSignOutError => 'Error signing out';

  @override
  String get profileSettingsComments => 'Comments';

  @override
  String get profileSettingsCommentsSubtitle =>
      'Notify when someone comments on your gossips';

  @override
  String get profileSettingsDailySummarySubtitle =>
      'Receive daily summary by email';

  @override
  String get profileSettingsEmailNotifications => 'Email notifications';

  @override
  String get profileSettingsGeneralNotifications => 'General notifications';

  @override
  String get profileSettingsGeneralNotificationsSubtitle =>
      'Enable or disable all notifications';

  @override
  String get profileSettingsLanguage => 'Language';

  @override
  String get profileSettingsLanguageEnglish => 'English';

  @override
  String get profileSettingsLanguageSpanish => 'Español';

  @override
  String get profileSettingsNewFollowers => 'New followers';

  @override
  String get profileSettingsNewFollowersSubtitle =>
      'Notify when someone follows you';

  @override
  String get profileSettingsPrivacyDialogTitle => 'Privacy level';

  @override
  String get profileSettingsPrivacyLevel => 'Privacy level';

  @override
  String get profileSettingsPrivacyPrivate => 'Private';

  @override
  String get profileSettingsPrivacyPrivateSubtitle =>
      'You approve who follows you';

  @override
  String get profileSettingsPrivacyPublic => 'Public';

  @override
  String get profileSettingsPrivacyPublicSubtitle =>
      'Everyone can see your profile';

  @override
  String get profileSettingsPushNotifications => 'Push notifications';

  @override
  String get profileSettingsPushNotificationsSubtitle =>
      'Receive push notifications on device';

  @override
  String get profileSettingsSectionAppearance => 'Appearance';

  @override
  String get profileSettingsSectionNotifications => 'Notifications';

  @override
  String get profileSettingsSectionPrivacy => 'Privacy';

  @override
  String get profileSettingsShowActivity => 'Show activity';

  @override
  String get profileSettingsShowActivitySubtitle =>
      'Show your last activity on profile';

  @override
  String get profileSettingsShowEmail => 'Show email';

  @override
  String get profileSettingsShowEmailSubtitle =>
      'Allow other users to see your email';

  @override
  String get profileSettingsTitle => 'Settings';

  @override
  String get profileSettingsUpdateError => 'Error updating settings';

  @override
  String get profileStatsComments => 'Comments';

  @override
  String get profileStatsFollowers => 'Followers';

  @override
  String get profileStatsFollowing => 'Following';

  @override
  String get profileStatsGossips => 'Gossips';

  @override
  String get profileStatsTitle => 'Stats';

  @override
  String searchFilterOnlyCity(String cityName) {
    return 'Only $cityName';
  }

  @override
  String get searchHint => 'Search gossips...';

  @override
  String get searchNoResults => 'No gossips found 😢';

  @override
  String get searchTitle => 'Search 🔎';

  @override
  String get authPasswordStrengthWeak => 'Weak';

  @override
  String get authPasswordStrengthMedium => 'Medium';

  @override
  String get authPasswordStrengthStrong => 'Strong';

  @override
  String get authPasswordStrengthHintMinLength => 'min 8 characters';

  @override
  String get authPasswordStrengthHintUppercase => 'one uppercase';

  @override
  String get authPasswordStrengthHintLowercase => 'one lowercase';

  @override
  String get authPasswordStrengthHintNumber => 'one number';

  @override
  String get authPasswordStrengthHintSymbol => 'one symbol';

  @override
  String authPasswordStrengthHintAdd(String hints) {
    return 'Add: $hints';
  }

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get signInButton => 'Sign In';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUpLink => 'Sign up';

  @override
  String get forgotPasswordTitle => 'Forgot your password?';

  @override
  String get forgotPasswordMessage =>
      'We\'ll send you a 6-digit code to recover your password';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get emailHint => 'Email';

  @override
  String get confirmPasswordHint => 'Confirm password';

  @override
  String get changePasswordButton => 'Change password';

  @override
  String get newPasswordHint => 'New password';

  @override
  String get otpVerifyEmailTitle => 'Verify Email';

  @override
  String get laterButton => 'Later';

  @override
  String get doItLater => 'I\'ll do it later';

  @override
  String get displayNameHint => 'John Smith';

  @override
  String get bioHint => 'Tell us about yourself...';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get forget => 'Forget';

  @override
  String get emailHintPlaceholder => 'you@email.com';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get locationChangeDialogTitle => 'Change Location';

  @override
  String get locationCityHint => 'City';

  @override
  String get locationCityLabel => 'City';

  @override
  String get locationCityRequired => 'City is required';

  @override
  String get locationCountryLabel => 'Country';

  @override
  String get locationCountryRequired => 'Country is required';

  @override
  String get locationGpsDetectSubtitle => 'Detect my current location';

  @override
  String get locationOrSelectManually => 'or select manually';

  @override
  String get locationRegionLabel => 'Region';

  @override
  String get homePopularLoadError => 'Error loading popular gossips';

  @override
  String get gossipDetailTitle => 'Gossip Detail';

  @override
  String get profileSetupTitle => 'Set Up Your Profile';

  @override
  String get profileSetupSubtitle =>
      'Complete your profile to start sharing gossip';

  @override
  String get profileSetupWelcome => 'Welcome!';

  @override
  String get profileSetupInfoMessage => 'You need a username to publish gossip';

  @override
  String get profileSetupUsernameLabel => 'Username';

  @override
  String get profileSetupUsernameHelper =>
      'Only lowercase letters, numbers and _';

  @override
  String get profileSetupUsernameAvailabilityCheck =>
      'Verify that the username is available';

  @override
  String get profileSetupUsernameTaken => 'This username is already taken';

  @override
  String get profileSetupDisplayNameLabel => 'Display name';

  @override
  String get profileSetupBioLabel => 'Bio (optional)';

  @override
  String get profileSetupSaveButton => 'Save Profile';

  @override
  String get profileSetupAvatarUploadSoon => 'Coming soon: upload avatar';

  @override
  String get usernameHint => 'johnsmith';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameTooShort => 'Username is too short (min 3 characters)';

  @override
  String get usernameTooLong => 'Username is too long (max 30 characters)';

  @override
  String get usernameInvalidChars =>
      'Username can only contain lowercase letters, numbers and underscores';

  @override
  String get passwordHint => 'Password';

  @override
  String get passwordFieldLabel => 'Password';

  @override
  String get passwordFieldShow => 'Show password';

  @override
  String get passwordFieldHide => 'Hide password';

  @override
  String get passwordsMustMatch => 'Passwords must match';

  @override
  String get passwordUpdatedSuccessTitle => 'Password updated';

  @override
  String get passwordUpdatedSuccessMessage =>
      'Your password has been successfully updated. You can now sign in with your new password';

  @override
  String get locationRegionRequired => 'Region is required';

  @override
  String get locationSearchError => 'Error searching location';

  @override
  String get locationUnexpectedError => 'Unexpected location error';

  @override
  String get locationUseCurrentLocation => 'Use current location';

  @override
  String get resetPasswordSubtitle => 'Create your new password';

  @override
  String get resetPasswordDescription => 'Must be at least 8 characters';

  @override
  String get resetPasswordConfirmHint => 'Confirm password';

  @override
  String get resetPasswordOkButton => 'OK';

  @override
  String get sendCodeButton => 'Send code';

  @override
  String get signUpButton => 'Create Account';

  @override
  String get signupSubtitle => 'Join Chismes';

  @override
  String get signupDescription => 'Create your account in seconds';

  @override
  String get signupPasswordRequired => 'Enter a password';

  @override
  String get signupPasswordMinLength => 'Minimum 8 characters';

  @override
  String get signupPasswordsMustMatch => 'Passwords must match';

  @override
  String get signupConfirmPasswordRequired => 'Confirm your password';

  @override
  String get signInLink => 'Sign in';

  @override
  String locationNoResults(String query) {
    return 'No results for \'$query\'';
  }

  @override
  String locationCitySearchHint(int minChars) {
    return 'Search city (min. $minChars characters)';
  }

  @override
  String locationMinCharsMessage(int minChars) {
    return 'Type at least $minChars characters to search';
  }

  @override
  String get authOtpResendCode => 'Resend code';

  @override
  String authOtpResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authOtpHelpText =>
      'Didn\'t receive the code? Check your spam folder or request a new one.';

  @override
  String get authOtpEnterCode => 'Enter the code';

  @override
  String get authOtpSentCodeTo => 'We sent a 6-digit code to:';

  @override
  String get authOtpCodeMustBe6Digits => 'Code must be 6 digits';

  @override
  String get searchRecentSearches => 'Recent searches';

  @override
  String get searchTryOtherWords => 'Try other words';

  @override
  String get searchByTopic => 'Search gossip by topic';

  @override
  String get searchByKeyword => 'or keyword';

  @override
  String get searchRecent => 'Recent';

  @override
  String get searchClearAll => 'Clear all';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String homeNewGossipsBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new gossips · Tap here',
      one: '1 new gossip · Tap here',
    );
    return '$_temp0';
  }

  @override
  String deepLinkOpeningGossip(String gossipId) {
    return 'Opening gossip: $gossipId';
  }

  @override
  String deepLinkOpeningProfile(String userId) {
    return 'Opening profile: $userId';
  }

  @override
  String deepLinkOpeningCityFeed(String cityId) {
    return 'Opening city feed: $cityId';
  }

  @override
  String get locationErrorLoadCountries => 'Failed to load countries';

  @override
  String get locationErrorLoadRegions => 'Failed to load regions';

  @override
  String get locationErrorLoadCities => 'Failed to load cities';

  @override
  String get locationErrorUnexpected => 'Unexpected error occurred';

  @override
  String get locationErrorGpsPosition =>
      'Could not detect location. Enable GPS and try again.';

  @override
  String get locationErrorGeocoding => 'Could not identify the location';

  @override
  String locationErrorCountryNotAvailable(String entityName) {
    return 'Country \"$entityName\" not available. Select manually.';
  }

  @override
  String locationErrorRegionNotAvailable(String entityName) {
    return 'Region \"$entityName\" not available. Select manually.';
  }

  @override
  String locationErrorCityNotAvailable(String entityName) {
    return 'City \"$entityName\" not available. Select manually.';
  }

  @override
  String get locationErrorDetection => 'Error detecting location. Try again.';

  @override
  String get moderationEntryTitle => 'Moderation panel';

  @override
  String get moderationEntrySubtitle => 'Review pending content';

  @override
  String get moderationTitle => 'Moderation';

  @override
  String get moderationTabPending => 'Pending';

  @override
  String get moderationTabApproved => 'Approved';

  @override
  String get moderationTabRejected => 'Rejected';

  @override
  String get moderationEmptyPending => 'Nothing pending';

  @override
  String get moderationEmptyPendingHint =>
      'Content flagged by AI or reports will show up here';

  @override
  String get moderationEmptyHistory => 'No decisions here yet';

  @override
  String get moderationLoadError => 'Couldn\'t load the queue';

  @override
  String get moderationForbidden =>
      'Your account doesn\'t have moderation permissions';

  @override
  String get moderationHighPriority => 'High priority';

  @override
  String get moderationSourceAiReview => 'AI';

  @override
  String get moderationSourceAiUnavailable => 'No automatic verdict';

  @override
  String get moderationSourceReports => 'Reports';

  @override
  String moderationReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
    );
    return '$_temp0';
  }

  @override
  String moderationInteractions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count interactions',
      one: '1 interaction',
    );
    return '$_temp0';
  }

  @override
  String get moderationAutoHidden => 'Hidden by reports';

  @override
  String get moderationAuthorLabel => 'Author';

  @override
  String get moderationAuthorNoName => 'No profile name';

  @override
  String get moderationAnonymousAuthor =>
      'Posted anonymously: only moderators see the author';

  @override
  String get moderationReasonsTitle => 'Why it\'s here';

  @override
  String get moderationHasAudio => 'Has audio (can\'t be played here yet)';

  @override
  String get moderationImageUnavailable => 'Couldn\'t load the image';

  @override
  String moderationQueuedAt(String date) {
    return 'In queue since $date';
  }

  @override
  String moderationDecidedAt(String date) {
    return 'Decided on $date';
  }

  @override
  String get moderationDecisionTitle => 'Decision';

  @override
  String get moderationNoteTitle => 'Internal note';

  @override
  String get moderationApprove => 'Approve';

  @override
  String get moderationReject => 'Reject';

  @override
  String get moderationApproveConfirmTitle => 'Approve and publish?';

  @override
  String get moderationApproveConfirmBody =>
      'The gossip will be visible to everyone.';

  @override
  String get moderationApprovedMessage => 'Approved and published';

  @override
  String get moderationRejectedMessage => 'Rejected: the gossip is now hidden';

  @override
  String get moderationAlreadyDecided =>
      'No longer pending: another moderator decided it';

  @override
  String get moderationDecisionError =>
      'Couldn\'t apply the decision. Try again.';

  @override
  String get moderationRejectTitle => 'Reject content';

  @override
  String get moderationRejectHint =>
      'It\'s hidden, not deleted: it stays for an appeal.';

  @override
  String get moderationSeverityLabel => 'Severity';

  @override
  String get moderationSeverityLow => 'Low';

  @override
  String get moderationSeverityMedium => 'Medium';

  @override
  String get moderationSeverityHigh => 'High';

  @override
  String get moderationSeverityCritical => 'Critical';

  @override
  String get moderationRejectReasonLabel => 'Reason';

  @override
  String get moderationRejectReasonHate => 'Hate or discrimination';

  @override
  String get moderationRejectReasonPersonalData => 'Personal data';

  @override
  String get moderationNoteLabel => 'Internal note (optional)';

  @override
  String get moderationNoteHint => 'Context for other moderators';

  @override
  String get moderationReasonAiUnavailable => 'AI didn\'t respond';

  @override
  String get moderationReasonRulesUnavailable => 'Rules couldn\'t be loaded';

  @override
  String get moderationReasonPersonalData => 'Possible personal data';

  @override
  String get moderationReasonSpam => 'Possible spam or links';

  @override
  String get moderationReasonThreat => 'Possible threat';

  @override
  String get moderationReasonAudio => 'Unmoderated audio';

  @override
  String moderationReasonTerm(String term) {
    return 'Term: $term';
  }

  @override
  String moderationReasonAiScore(String category) {
    return 'AI: $category';
  }

  @override
  String get errorsAccountRestricted =>
      'Your account can\'t post or report right now. Check Profile → Account status.';

  @override
  String get errorsAccountSuspended =>
      'Your account is suspended: it can\'t post or report. You can appeal in Profile → Account status.';

  @override
  String errorsAccountRestrictedUntil(String date) {
    return 'Your account can\'t post or report until $date. Check Profile → Account status.';
  }

  @override
  String get accountStatusEntryTitle => 'Account status';

  @override
  String get accountStatusEntrySubtitle =>
      'Violations, restrictions and appeals';

  @override
  String get accountStatusTitle => 'Account status';

  @override
  String get accountStatusLoadError => 'Couldn\'t load your account status';

  @override
  String get accountStatusOkTitle => 'Your account is in good standing';

  @override
  String get accountStatusOkBody => 'You can post and report as usual.';

  @override
  String accountStatusRestrictedTitle(String date) {
    return 'No posting until $date';
  }

  @override
  String get accountStatusRestrictedTitleNoDate => 'Your account is restricted';

  @override
  String get accountStatusRestrictedBody =>
      'Because of recent violations you can\'t post or report for a while. You can still read.';

  @override
  String get accountStatusSuspendedTitle => 'Your account is suspended';

  @override
  String get accountStatusSuspendedBody =>
      'You can\'t post or report. If you think this is a mistake, appeal the rejected content.';

  @override
  String get accountStatusPendingAppeal => 'You have an appeal under review.';

  @override
  String get accountStatusPointsTitle => 'Violation points';

  @override
  String accountStatusPointsValue(int points, int limit) {
    return '$points of $limit';
  }

  @override
  String accountStatusPointsExplanation(
    int short,
    int long,
    int suspension,
    int days,
  ) {
    return 'At $short points your account is restricted for a while, at $long for longer, and at $suspension it is suspended. Each violation\'s points expire after $days days.';
  }

  @override
  String get accountStatusInheritedTitle =>
      'Violations from a previous account';

  @override
  String accountStatusInheritedBody(int points, String date) {
    return 'A deleted account with your email had violations: $points points, active until $date.';
  }

  @override
  String get accountStatusRejectionsTitle => 'Rejected content';

  @override
  String get accountStatusNoRejections => 'You have no rejected content.';

  @override
  String get accountStatusSanctionWarning => 'Warning';

  @override
  String get accountStatusSanctionRestriction => 'Restriction';

  @override
  String get accountStatusSanctionSuspension => 'Suspension';

  @override
  String get accountStatusOverturned => 'Overturned on appeal';

  @override
  String accountStatusRejectedOn(String date) {
    return 'Rejected on $date';
  }

  @override
  String accountStatusPointsUntil(int points, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points points',
      one: '1 point',
    );
    return '$_temp0 until $date';
  }

  @override
  String accountStatusAppealUntil(String date) {
    return 'You can appeal until $date';
  }

  @override
  String get accountStatusAppealClosed => 'The appeal period has ended';

  @override
  String get appealButton => 'Appeal';

  @override
  String get appealSheetTitle => 'Appeal the rejection';

  @override
  String get appealSheetHint =>
      'Tell us why you think this was a mistake. A person on the moderation team will review it. You can only appeal once.';

  @override
  String get appealMessageLabel => 'Your appeal';

  @override
  String get appealMessageHint =>
      'E.g.: it was a joke between friends, not an insult';

  @override
  String get appealSubmit => 'Send appeal';

  @override
  String get appealSentMessage =>
      'Appeal sent. You\'ll see the result here once it\'s reviewed.';

  @override
  String get appealNotAllowedMessage =>
      'This rejection can no longer be appealed';

  @override
  String get appealErrorMessage => 'Couldn\'t send the appeal';

  @override
  String get appealStatusPending => 'Appeal under review';

  @override
  String get appealStatusAccepted => 'Appeal accepted';

  @override
  String get appealStatusRejected => 'Appeal rejected';

  @override
  String get appealFilterAccepted => 'Accepted';

  @override
  String get appealFilterRejected => 'Rejected';

  @override
  String get moderationTabAppeals => 'Appeals';

  @override
  String get appealsEmptyPending => 'No pending appeals';

  @override
  String get appealDetailTitle => 'Appeal';

  @override
  String get appealUserMessageTitle => 'What the user says';

  @override
  String appealSentAt(String date) {
    return 'Sent on $date';
  }

  @override
  String get appealOriginalDecisionTitle => 'Original rejection';

  @override
  String get appealDecisionTitle => 'Appeal decision';

  @override
  String get appealAccept => 'Accept appeal';

  @override
  String get appealReject => 'Uphold rejection';

  @override
  String get appealAcceptConfirmTitle => 'Accept the appeal?';

  @override
  String get appealAcceptConfirmBody =>
      'The violation is removed (the restriction is recalculated) and the text is published again. The image or audio doesn\'t come back: it was deleted on rejection.';

  @override
  String get appealRejectConfirmTitle => 'Uphold the rejection?';

  @override
  String get appealRejectConfirmBody =>
      'The violation still counts. The user can\'t appeal this content again.';

  @override
  String get appealAcceptedMessage => 'Appeal accepted: violation removed';

  @override
  String get appealRejectedMessage => 'Rejection upheld';

  @override
  String get appealAlreadyDecided =>
      'Another moderator already decided this appeal';

  @override
  String get appealNeedsAnotherModerator =>
      'Another moderator must review this appeal (you made the rejection)';

  @override
  String get legalPrivacyPolicyTitle => 'Privacy policy';

  @override
  String get legalTermsOfServiceTitle => 'Terms of use';

  @override
  String get legalSectionTitle => 'Legal';

  @override
  String get legalDocumentLoadError => 'Couldn\'t open the document.';

  @override
  String legalConsentMessage(String terms, String privacy) {
    return 'By continuing, you agree to the $terms and the $privacy.';
  }

  @override
  String get locationPrivacyTitle => 'Location';

  @override
  String get locationPrivacySavedCity => 'Saved city';

  @override
  String get locationPrivacyNotSaved => 'Not saved';

  @override
  String get locationPrivacyForget => 'Forget location';

  @override
  String get locationPrivacyForgetDialogTitle => 'Forget your location?';

  @override
  String get locationPrivacyForgetDialogMessage =>
      'Your saved city will be deleted. We\'ll ask for it again the next time you post a gossip.';

  @override
  String get locationPrivacyForgotten => 'Location forgotten';

  @override
  String get locationPrivacyDontSave => 'Don\'t save location';

  @override
  String get locationPrivacyDontSaveSubtitle =>
      'We\'ll ask for your city on every gossip';

  @override
  String get locationPrivacyError => 'Couldn\'t save the change. Try again.';

  @override
  String get errorsUsernameChangeCooldown =>
      'You changed your username recently. You can change it again in a few days.';

  @override
  String errorsUsernameChangeCooldownUntil(String date) {
    return 'You changed your username recently. You can change it again on $date.';
  }

  @override
  String get errorsUsernameReserved => 'That username isn\'t available.';

  @override
  String get errorsModerationUnavailable =>
      'We couldn\'t review the change right now. Try again in a few minutes.';

  @override
  String get errorsInvalidImage => 'The photo must be JPG, PNG or WebP.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileSave => 'Save';

  @override
  String get editProfileSaved => 'Profile updated';

  @override
  String get editProfileChangePhoto => 'Change profile photo';

  @override
  String get editProfilePhotoGallery => 'Choose from gallery';

  @override
  String get editProfilePhotoCamera => 'Take photo';

  @override
  String get editProfilePhotoRemove => 'Remove photo';

  @override
  String get editProfilePhotoError =>
      'Couldn\'t use that photo. Try another one.';

  @override
  String get editProfileUsernameHelper =>
      'You can change it once every 30 days';

  @override
  String get editProfileModerationNote =>
      'Your photo, name and bio are public: we review them before saving.';

  @override
  String get editProfileDiscardTitle => 'Discard changes?';

  @override
  String get editProfileDiscardMessage =>
      'If you leave now, your changes won\'t be saved.';

  @override
  String get editProfileDiscard => 'Discard';

  @override
  String get profileSettingsTheme => 'Theme';

  @override
  String get profileSettingsThemeSystem => 'Same as phone';

  @override
  String get profileSettingsThemeLight => 'Light';

  @override
  String get profileSettingsThemeDark => 'Dark';

  @override
  String get errorsUserNotAvailable => 'This user isn\'t available.';

  @override
  String gossipAuthorSemanticLabel(String name) {
    return 'View $name\'s profile';
  }

  @override
  String get socialProfileTitle => 'Profile';

  @override
  String get socialUnknownUser => 'User';

  @override
  String get socialFollow => 'Follow';

  @override
  String get socialFollowing => 'Following';

  @override
  String get socialRequested => 'Requested';

  @override
  String get socialUnblock => 'Unblock';

  @override
  String get socialBlock => 'Block';

  @override
  String get socialFollowsYou => 'Follows you';

  @override
  String get socialMoreOptions => 'More options';

  @override
  String get socialRequestSent => 'Request sent';

  @override
  String socialBlockDialogTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get socialBlockDialogMessage =>
      'They won\'t be able to see your profile or your gossips posted with your profile, and you\'ll stop following each other. We won\'t notify them.';

  @override
  String socialBlockedSnack(String name) {
    return 'You blocked $name';
  }

  @override
  String socialUnblockedSnack(String name) {
    return 'You unblocked $name';
  }

  @override
  String get socialBlockedProfileTitle => 'You blocked this account';

  @override
  String get socialBlockedProfileMessage =>
      'Unblock it to see their profile and gossips.';

  @override
  String get socialPrivateAccountTitle => 'This account is private';

  @override
  String get socialPrivateAccountMessage =>
      'Follow it to see their gossips and followers.';

  @override
  String get socialUserNotAvailableTitle => 'This user isn\'t available';

  @override
  String get socialUserNotAvailableMessage =>
      'The account may no longer exist.';

  @override
  String get socialNoGossips => 'No gossips posted with profile yet';

  @override
  String get socialGossipsError => 'Couldn\'t load the gossips';

  @override
  String get socialLoadError => 'Couldn\'t load. Try again.';

  @override
  String get socialEmptyFollowers => 'No followers yet';

  @override
  String get socialEmptyFollowing => 'Not following anyone yet';

  @override
  String get socialRemoveFollower => 'Remove';

  @override
  String socialRemoveFollowerDialogTitle(String name) {
    return 'Remove $name from your followers?';
  }

  @override
  String get socialRemoveFollowerDialogMessage =>
      'We won\'t notify them. They can follow you again.';

  @override
  String socialFollowerRemoved(String name) {
    return 'You removed $name from your followers';
  }

  @override
  String get socialFollowRequestsTitle => 'Follow requests';

  @override
  String get socialFollowRequestsSubtitle =>
      'Who wants to follow your private account';

  @override
  String get socialNoFollowRequests => 'You have no pending requests';

  @override
  String get socialAccept => 'Accept';

  @override
  String get socialReject => 'Decline';

  @override
  String get socialBlockedUsersTitle => 'Blocked users';

  @override
  String get socialBlockedUsersSubtitle =>
      'They can\'t see your profile or your gossips posted with your profile';

  @override
  String get socialNoBlockedUsers => 'You haven\'t blocked anyone';

  @override
  String get socialSearchTabGossips => 'Gossips';

  @override
  String get socialSearchTabUsers => 'Users';

  @override
  String get socialSearchUsersHint => 'Search by @username or name...';

  @override
  String get socialSearchUsersPrompt =>
      'Type at least 2 letters to search for people';

  @override
  String get socialSearchUsersNoResults => 'No users found';

  @override
  String get errorsFollowRateLimited =>
      'You\'re following a lot of people very quickly. Try again later.';
}
