// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Chismes';

  @override
  String get appTagline => 'Share stories, discover secrets';

  @override
  String get authErrorsEmailAlreadyInUse => 'Email already in use';

  @override
  String get authErrorsInvalidCredentials => 'Invalid credentials';

  @override
  String get authErrorsNetworkError => 'Network error';

  @override
  String get authErrorsUnknownError => 'Unknown error';

  @override
  String get authErrorsUserNotFound => 'User not found';

  @override
  String get authErrorsWeakPassword => 'Password is too weak';

  @override
  String get authForgotPasswordCodeSentMessage =>
      'Check your email for the verification code';

  @override
  String get authForgotPasswordCodeSentTitle => 'Code sent';

  @override
  String get authForgotPasswordEmailHint => 'Email';

  @override
  String get authForgotPasswordMessage =>
      'We\'ll send you a 6-digit code to recover your password';

  @override
  String get authForgotPasswordSendCodeButton => 'Send code';

  @override
  String get authForgotPasswordTitle => 'Forgot your password?';

  @override
  String get authLoginContinueWithApple => 'Continue with Apple';

  @override
  String get authLoginContinueWithGoogle => 'Continue with Google';

  @override
  String get authLoginEmailHint => 'Email';

  @override
  String get authLoginForgotPassword => 'Forgot your password?';

  @override
  String get authLoginNoAccount => 'Don\'t have an account?';

  @override
  String get authLoginOrContinueWith => 'Or continue with';

  @override
  String get authLoginPasswordHint => 'Password';

  @override
  String get authLoginSignInButton => 'Sign In';

  @override
  String get authLoginSignUpLink => 'Sign up';

  @override
  String get authLoginTitle => 'Sign In';

  @override
  String get authOtpVerificationCodeHint => 'Code';

  @override
  String get authOtpVerificationResendButton => 'Resend';

  @override
  String get authOtpVerificationResendLabel => 'Didn\'t receive the code?';

  @override
  String authOtpVerificationResendTimer(String seconds) {
    return 'Resend (${seconds}s)';
  }

  @override
  String get authOtpVerificationSubtitleReset => 'Enter the code we sent to:';

  @override
  String get authOtpVerificationSubtitleSignup => 'We sent a 6-digit code to:';

  @override
  String get authOtpVerificationTitle => 'Verify Code';

  @override
  String get authOtpVerificationVerifyEmailTitle => 'Verify Email';

  @override
  String get authOtpVerificationVerifying => 'Verifying...';

  @override
  String get authPasswordFieldHide => 'Hide password';

  @override
  String get authPasswordFieldLabel => 'Password';

  @override
  String get authPasswordFieldShow => 'Show password';

  @override
  String get authProfileSetupAvatarUploadSoon => 'Coming soon: upload avatar';

  @override
  String get authProfileSetupBioHint => 'Tell us about yourself...';

  @override
  String get authProfileSetupBioLabel => 'Bio (optional)';

  @override
  String get authProfileSetupCompleteButton => 'Complete profile';

  @override
  String get authProfileSetupDisplayNameHint => 'John Smith';

  @override
  String get authProfileSetupDisplayNameLabel => 'Display name';

  @override
  String get authProfileSetupDoItLater => 'I\'ll do it later';

  @override
  String get authProfileSetupInfoMessage =>
      'You need a username to publish gossip';

  @override
  String get authProfileSetupLaterButton => 'Later';

  @override
  String get authProfileSetupSaveButton => 'Save Profile';

  @override
  String get authProfileSetupSubtitle =>
      'Complete your profile to start sharing gossip';

  @override
  String get authProfileSetupTitle => 'Set Up Your Profile';

  @override
  String get authProfileSetupUsernameAvailabilityCheck =>
      'Verify that the username is available';

  @override
  String get authProfileSetupUsernameHelper =>
      'Only lowercase letters, numbers and _';

  @override
  String get authProfileSetupUsernameHint => 'johnsmith';

  @override
  String get authProfileSetupUsernameLabel => 'Username';

  @override
  String get authProfileSetupUsernameTaken => 'This username is already taken';

  @override
  String get authProfileSetupWelcome => 'Welcome!';

  @override
  String get authResetPasswordChangePasswordButton => 'Change password';

  @override
  String get authResetPasswordConfirmPasswordHint => 'Confirm password';

  @override
  String get authResetPasswordDescription => 'Must be at least 8 characters';

  @override
  String get authResetPasswordNewPasswordHint => 'New password';

  @override
  String get authResetPasswordOkButton => 'OK';

  @override
  String get authResetPasswordSubtitle => 'Create your new password';

  @override
  String get authResetPasswordSuccessMessage =>
      'Your password has been successfully updated. You can now sign in with your new password';

  @override
  String get authResetPasswordSuccessTitle => 'Password updated';

  @override
  String get authResetPasswordTitle => 'New Password';

  @override
  String get authSignupAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authSignupConfirmPasswordHint => 'Confirm password';

  @override
  String get authSignupConfirmPasswordRequired => 'Confirm your password';

  @override
  String get authSignupDescription => 'Create your account in seconds';

  @override
  String get authSignupEmailHint => 'Email';

  @override
  String get authSignupPasswordHint => 'Password';

  @override
  String get authSignupPasswordMinLength => 'Minimum 8 characters';

  @override
  String get authSignupPasswordRequired => 'Enter a password';

  @override
  String get authSignupPasswordsMustMatch => 'Passwords must match';

  @override
  String get authSignupSignInLink => 'Sign in';

  @override
  String get authSignupSignUpButton => 'Create Account';

  @override
  String get authSignupSubtitle => 'Join Chismes';

  @override
  String get authSignupTermsMessage =>
      'By creating an account, you agree to our Terms and Conditions and Privacy Policy';

  @override
  String get authSignupTitle => 'Create Account';

  @override
  String get authValidationBioTooLong => 'Bio is too long (max 160 characters)';

  @override
  String get authValidationDisplayNameEmpty => 'Display name cannot be empty';

  @override
  String get authValidationDisplayNameRequired => 'Display name is required';

  @override
  String get authValidationDisplayNameTooLong =>
      'Display name is too long (max 50 characters)';

  @override
  String get authValidationEmailInvalid => 'Email format is invalid';

  @override
  String get authValidationEmailRequired => 'Email is required';

  @override
  String get authValidationEmailTooLong =>
      'Email is too long (max 254 characters)';

  @override
  String get authValidationPasswordNeedsLowercase =>
      'Password must contain at least one lowercase letter';

  @override
  String get authValidationPasswordNeedsNumber =>
      'Password must contain at least one number';

  @override
  String get authValidationPasswordNeedsSpecial =>
      'Password must contain at least one special character';

  @override
  String get authValidationPasswordNeedsUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get authValidationPasswordRequired => 'Password is required';

  @override
  String get authValidationPasswordTooLong =>
      'Password is too long (max 128 characters)';

  @override
  String get authValidationPasswordTooShort =>
      'Password is too short (min 8 characters)';

  @override
  String get authValidationPasswordsMustMatch => 'Passwords must match';

  @override
  String get authValidationUsernameInvalidChars =>
      'Username can only contain lowercase letters, numbers and underscores';

  @override
  String get authValidationUsernameInvalidUnderscore =>
      'Username cannot start or end with underscore';

  @override
  String get authValidationUsernameRequired => 'Username is required';

  @override
  String get authValidationUsernameReserved => 'Username is reserved';

  @override
  String get authValidationUsernameStartsWithNumber =>
      'Username cannot start with a number';

  @override
  String get authValidationUsernameTooLong =>
      'Username is too long (max 30 characters)';

  @override
  String get authValidationUsernameTooShort =>
      'Username is too short (min 3 characters)';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonEmailHintPlaceholder => 'you@email.com';

  @override
  String get commonEmailInvalid => 'Invalid email';

  @override
  String get commonEnterEmail => 'Enter an email';

  @override
  String get commonEnterPassword => 'Enter your password';

  @override
  String get commonError => 'Error';

  @override
  String get commonForget => 'Forget';

  @override
  String get commonLoading => 'Loading...';

  @override
  String commonMaxLength(String count) {
    return 'Cannot exceed $count characters';
  }

  @override
  String commonMinLength(String count) {
    return 'Must be at least $count characters';
  }

  @override
  String get commonPermanentlyDelete => 'Permanently delete';

  @override
  String get commonRequiredField => 'Required field';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String commonSelect(String field) {
    return 'Select $field';
  }

  @override
  String get commonSuccess => 'Success';

  @override
  String get errorsAuthEmailAlreadyInUse => 'This email is already registered.';

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
  String get gossipDetailScreenTitle => 'Detail';

  @override
  String get gossipLocationChangeDialogTitle => 'Change location';

  @override
  String get gossipLocationCityHint => 'Search city...';

  @override
  String get gossipLocationCityLabel => 'City';

  @override
  String get gossipLocationCityRequired => 'Select a city';

  @override
  String gossipLocationCitySearchHint(String minChars) {
    return 'Search city... (min. $minChars characters)';
  }

  @override
  String get gossipLocationCountryLabel => 'Country';

  @override
  String get gossipLocationCountryRequired => 'Select a country';

  @override
  String get gossipLocationGpsDetectSubtitle => 'Detect automatically with GPS';

  @override
  String gossipLocationMinCharsMessage(String minChars) {
    return 'Type at least $minChars characters to search';
  }

  @override
  String gossipLocationNoResults(String query) {
    return 'No cities found with \"$query\"';
  }

  @override
  String get gossipLocationOrSelectManually => 'Or select manually';

  @override
  String get gossipLocationRegionLabel => 'Region';

  @override
  String get gossipLocationRegionRequired => 'Select a region';

  @override
  String get gossipLocationSearchError =>
      'Error searching cities. Please try again.';

  @override
  String get gossipLocationUnexpectedError =>
      'Unexpected error. Please try again.';

  @override
  String get gossipLocationUseCurrentLocation => 'Use my current location';

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
  String get gossipSubmitButtonPublishSemantic => 'Publish gossip';

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
  String get homeFollowingRecommendedError => 'Error loading recommendations';

  @override
  String get homeFollowingUnexpectedError => 'Unexpected error loading feed';

  @override
  String get homeFollowingUsePopularTabHint => 'Use the Popular tab above';

  @override
  String get homeFollowingViewPopularLink => 'View Popular';

  @override
  String get homePopularEmpty => 'No gossips available';

  @override
  String get homePopularGlobal => 'Popular 🌎';

  @override
  String homePopularInCity(String city) {
    return 'Popular in $city';
  }

  @override
  String homePopularNewGossipsBanner(String count) {
    return '$count new gossips · Tap here';
  }

  @override
  String get homePopularNoMore => 'No more gossips for now 🌙';

  @override
  String get homeTabsFollowing => 'Following';

  @override
  String get homeTabsPopular => 'Popular';

  @override
  String get homeTitle => 'Gossips 🔥';

  @override
  String get navigationCreate => 'Create';

  @override
  String get navigationExplore => 'Explore';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationProfile => 'Profile';

  @override
  String get profileControllerLoadError => 'Error loading profile';

  @override
  String get profileControllerSignoutError => 'Error signing out';

  @override
  String get profileControllerUpdateError => 'Error updating settings';

  @override
  String get profileHeaderCompleteness => 'Profile completeness';

  @override
  String get profileHeaderEmailVerified => 'Email verified';

  @override
  String get profileHeaderNoName => 'No name';

  @override
  String get profilePrivacyConsentDeclineButton => 'I don\'t accept, go back';

  @override
  String get profilePrivacyConsentTitle => 'Privacy and Terms';

  @override
  String get profilePrivacySettingsAccountDeleteSubtitle =>
      'Delete your account and all your data';

  @override
  String get profilePrivacySettingsAccountDeleteTitle => 'Delete account';

  @override
  String get profilePrivacySettingsAccountDeleted => 'Account deleted';

  @override
  String get profilePrivacySettingsAnonymousModeTitle => 'Anonymous mode';

  @override
  String get profilePrivacySettingsConfirmDeletionTitle => 'Confirm deletion';

  @override
  String get profilePrivacySettingsDeletionCancelled => 'Deletion cancelled';

  @override
  String get profilePrivacySettingsDialogsDeleteAccountConfirmPlaceholder =>
      'DELETE';

  @override
  String get profilePrivacySettingsDialogsDeleteAccountConfirmPrompt =>
      'To confirm, type DELETE';

  @override
  String get profilePrivacySettingsDialogsDeleteAccountMessage =>
      'This will delete:\n• Your account\n• All your gossips\n• All your interactions\n\n⚠️ This action CANNOT be undone.';

  @override
  String get profilePrivacySettingsDialogsDeleteAccountTitle =>
      '⚠️ Delete Account';

  @override
  String get profilePrivacySettingsDialogsDeleteAllDataMessage =>
      'ALL locally stored data will be erased:\n• Saved location\n• Preferences\n• Cache\n\nAre you sure?';

  @override
  String get profilePrivacySettingsDialogsDeleteAllDataTitle =>
      '⚠️ Erase All Data';

  @override
  String get profilePrivacySettingsDialogsForgetLocationMessage =>
      'Your saved city will be deleted. Next time you create a gossip, location will be requested again.';

  @override
  String get profilePrivacySettingsDialogsForgetLocationTitle =>
      'Forget location?';

  @override
  String get profilePrivacySettingsDialogsPrivacyPolicyContent =>
      'The complete privacy policy is available at:\n\nhttps://chismes.app/privacy\n\nOr in the PRIVACY_POLICY.md file of the project.';

  @override
  String get profilePrivacySettingsDialogsTermsOfUseContent =>
      'The complete terms of use are available at:\n\nhttps://chismes.app/terms\n\nOr in the TERMS_OF_SERVICE.md file of the project.';

  @override
  String get profilePrivacySettingsEraseButton => 'Erase';

  @override
  String get profilePrivacySettingsExportComingSoon => 'Export coming soon';

  @override
  String get profilePrivacySettingsExportDataTooltip => 'Export data';

  @override
  String get profilePrivacySettingsLocalDataInfoMessage =>
      'This data is stored only on your phone (SharedPreferences). It is NOT sent to the server.';

  @override
  String get profilePrivacySettingsLocalDataInfoTitle => 'ℹ️ Local Data';

  @override
  String get profilePrivacySettingsLocationAnonymousModeDescription =>
      'With anonymous mode on, location will be requested each time you create a gossip.';

  @override
  String get profilePrivacySettingsLocationAnonymousModeSubtitle =>
      'Don\'t save location by default';

  @override
  String get profilePrivacySettingsLocationForgetTooltip => 'Forget location';

  @override
  String get profilePrivacySettingsLocationNotSaved => 'Not saved';

  @override
  String get profilePrivacySettingsMyDataTitle => 'My Data';

  @override
  String get profilePrivacySettingsNoLocalData => 'No local data saved';

  @override
  String get profilePrivacySettingsPrivacyPolicyTitle => 'Privacy Policy';

  @override
  String get profilePrivacySettingsSavedCityTitle => 'Saved city';

  @override
  String get profilePrivacySettingsSectionsAccount => '🔒 Account';

  @override
  String get profilePrivacySettingsSectionsLocation => '📍 Location';

  @override
  String get profilePrivacySettingsSectionsPolicies => '📄 Policies';

  @override
  String get profilePrivacySettingsSectionsStoredData => '💾 Stored Data';

  @override
  String get profilePrivacySettingsSnackbarsAnonymousModeOff =>
      '✅ Anonymous mode off';

  @override
  String get profilePrivacySettingsSnackbarsAnonymousModeOn =>
      '✅ Anonymous mode on';

  @override
  String get profilePrivacySettingsSnackbarsDataErased => '✅ Data erased';

  @override
  String get profilePrivacySettingsSnackbarsLocationForgotten =>
      '✅ Location forgotten';

  @override
  String get profilePrivacySettingsTermsOfUseTitle => 'Terms of Use';

  @override
  String get profilePrivacySettingsTitle => 'Privacy';

  @override
  String get profilePrivacySettingsViewMyDataSubtitle => 'Data dashboard';

  @override
  String get profilePrivacySettingsViewMyDataTitle => 'View my data';

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
  String get profileScreenSigningOut => 'Signing out...';

  @override
  String get profileSettingsAppearanceTitle => 'Appearance';

  @override
  String get profileSettingsComments => 'Comments';

  @override
  String get profileSettingsCommentsSubtitle =>
      'Notify when someone comments on your gossips';

  @override
  String get profileSettingsDailySummary => 'Daily summary';

  @override
  String get profileSettingsDailySummarySubtitle =>
      'Receive daily summary by email';

  @override
  String get profileSettingsDarkMode => 'Dark mode';

  @override
  String get profileSettingsDarkModeSubtitle => 'Use dark theme in the app';

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
  String get profileSettingsNotificationsTitle => 'Notifications';

  @override
  String get profileSettingsPrivacyDialogTitle => 'Privacy level';

  @override
  String get profileSettingsPrivacyFriends => 'Friends';

  @override
  String get profileSettingsPrivacyFriendsSubtitle =>
      'Only your friends can see';

  @override
  String get profileSettingsPrivacyLevel => 'Privacy level';

  @override
  String get profileSettingsPrivacyPrivate => 'Private';

  @override
  String get profileSettingsPrivacyPrivateSubtitle => 'Only you can see';

  @override
  String get profileSettingsPrivacyPublic => 'Public';

  @override
  String get profileSettingsPrivacyPublicSubtitle =>
      'Everyone can see your profile';

  @override
  String get profileSettingsPrivacyTitle => 'Privacy';

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
  String get searchEmptyState => 'Type to search gossips 🔎';

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
  String get privacyConsentTitle => 'Privacy Settings';

  @override
  String get privacyConsentDeclineButton => 'Decline';

  @override
  String get privacySettingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get privacySettingsTermsOfUse => 'Terms of Use';

  @override
  String get privacySettingsTitle => 'Privacy';

  @override
  String get privacySettingsSavedCity => 'Saved city';

  @override
  String get privacySettingsAnonymousMode => 'Anonymous mode';

  @override
  String get privacySettingsViewMyData => 'View my data';

  @override
  String get privacySettingsViewMyDataSubtitle => 'Download your personal data';

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
  String get permanentlyDelete => 'Permanently delete';

  @override
  String get locationRegionRequired => 'Region is required';

  @override
  String get locationSearchError => 'Error searching location';

  @override
  String get locationUnexpectedError => 'Unexpected location error';

  @override
  String get locationUseCurrentLocation => 'Use current location';

  @override
  String get privacySettingsAccountDeleted => 'Account deleted';

  @override
  String get privacySettingsConfirmDeletion =>
      'Do you confirm that you want to delete your account?';

  @override
  String get privacySettingsDeletionCancelled => 'Deletion cancelled';

  @override
  String get privacySettingsEraseButton => 'Delete account';

  @override
  String get privacySettingsMyData => 'My data';

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
  String get signupTermsMessage =>
      'By creating an account, you agree to our Terms and Conditions and Privacy Policy';

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
}
