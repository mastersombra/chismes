import 'package:easy_localization/easy_localization.dart';

/// Helper class para acceder a traducciones de forma type-safe
///
/// Uso:
/// ```dart
/// Text(AppLocalizations.emailRequired)
/// Text(AppLocalizations.minLength(8))
/// ```
class AppLocalizations {
  AppLocalizations._();

  // =====================================================
  // APP
  // =====================================================

  static String get appName => 'app.name'.tr();
  static String get appTagline => 'app.tagline'.tr();

  // =====================================================
  // AUTH - LOGIN
  // =====================================================

  static String get loginTitle => 'auth.login.title'.tr();
  static String get emailHint => 'auth.login.email_hint'.tr();
  static String get passwordHint => 'auth.login.password_hint'.tr();
  static String get signInButton => 'auth.login.sign_in_button'.tr();
  static String get orContinueWith => 'auth.login.or_continue_with'.tr();
  static String get noAccount => 'auth.login.no_account'.tr();
  static String get signUpLink => 'auth.login.sign_up_link'.tr();
  static String get forgotPassword => 'auth.login.forgot_password'.tr();
  static String get continueWithGoogle => 'auth.login.continue_with_google'.tr();
  static String get continueWithApple => 'auth.login.continue_with_apple'.tr();

  // =====================================================
  // AUTH - SIGNUP
  // =====================================================

  static String get signupTitle => 'auth.signup.title'.tr();
  static String get signupSubtitle => 'auth.signup.subtitle'.tr();
  static String get signupDescription => 'auth.signup.description'.tr();
  static String get confirmPasswordHint => 'auth.signup.confirm_password_hint'.tr();
  static String get signUpButton => 'auth.signup.sign_up_button'.tr();
  static String get alreadyHaveAccount => 'auth.signup.already_have_account'.tr();
  static String get signInLink => 'auth.signup.sign_in_link'.tr();
  static String get signupPasswordRequired => 'auth.signup.password_required'.tr();
  static String get signupPasswordMinLength => 'auth.signup.password_min_length'.tr();
  static String get signupConfirmPasswordRequired => 'auth.signup.confirm_password_required'.tr();
  static String get signupPasswordsMustMatch => 'auth.signup.passwords_must_match'.tr();
  static String get signupTermsMessage => 'auth.signup.terms_message'.tr();

  // =====================================================
  // AUTH - PROFILE SETUP
  // =====================================================

  static String get profileSetupTitle => 'auth.profile_setup.title'.tr();
  static String get profileSetupWelcome => 'auth.profile_setup.welcome'.tr();
  static String get profileSetupSubtitle => 'auth.profile_setup.subtitle'.tr();
  static String get profileSetupUsernameLabel => 'auth.profile_setup.username_label'.tr();
  static String get usernameHint => 'auth.profile_setup.username_hint'.tr();
  static String get profileSetupUsernameHelper => 'auth.profile_setup.username_helper'.tr();
  static String get profileSetupUsernameTaken => 'auth.profile_setup.username_taken'.tr();
  static String get profileSetupUsernameAvailabilityCheck => 'auth.profile_setup.username_availability_check'.tr();
  static String get profileSetupDisplayNameLabel => 'auth.profile_setup.display_name_label'.tr();
  static String get displayNameHint => 'auth.profile_setup.display_name_hint'.tr();
  static String get profileSetupBioLabel => 'auth.profile_setup.bio_label'.tr();
  static String get bioHint => 'auth.profile_setup.bio_hint'.tr();
  static String get profileSetupInfoMessage => 'auth.profile_setup.info_message'.tr();
  static String get profileSetupSaveButton => 'auth.profile_setup.save_button'.tr();
  static String get completeButton => 'auth.profile_setup.complete_button'.tr();
  static String get laterButton => 'auth.profile_setup.later_button'.tr();
  static String get doItLater => 'auth.profile_setup.do_it_later'.tr();
  static String get profileSetupAvatarUploadSoon => 'auth.profile_setup.avatar_upload_soon'.tr();

  // =====================================================
  // AUTH - FORGOT PASSWORD
  // =====================================================

  static String get forgotPasswordTitle => 'auth.forgot_password.title'.tr();
  static String get forgotPasswordMessage => 'auth.forgot_password.message'.tr();
  static String get forgotPasswordEmailHint => 'auth.forgot_password.email_hint'.tr();
  static String get sendCodeButton => 'auth.forgot_password.send_code_button'.tr();
  static String get codeSentTitle => 'auth.forgot_password.code_sent_title'.tr();
  static String get codeSentMessage => 'auth.forgot_password.code_sent_message'.tr();

  // =====================================================
  // AUTH - RESET PASSWORD
  // =====================================================

  static String get resetPasswordTitle => 'auth.reset_password.title'.tr();
  static String get resetPasswordSubtitle => 'auth.reset_password.subtitle'.tr();
  static String get resetPasswordDescription => 'auth.reset_password.description'.tr();
  static String get newPasswordHint => 'auth.reset_password.new_password_hint'.tr();
  static String get resetPasswordConfirmHint => 'auth.reset_password.confirm_password_hint'.tr();
  static String get changePasswordButton => 'auth.reset_password.change_password_button'.tr();
  static String get passwordUpdatedSuccessTitle => 'auth.reset_password.success_title'.tr();
  static String get passwordUpdatedSuccessMessage => 'auth.reset_password.success_message'.tr();
  static String get resetPasswordOkButton => 'auth.reset_password.ok_button'.tr();

  // =====================================================
  // AUTH - OTP VERIFICATION
  // =====================================================

  static String get otpVerificationTitle => 'auth.otp_verification.title'.tr();
  static String get otpVerifyEmailTitle => 'auth.otp_verification.verify_email_title'.tr();
  static String get otpSubtitleSignup => 'auth.otp_verification.subtitle_signup'.tr();
  static String get otpSubtitleReset => 'auth.otp_verification.subtitle_reset'.tr();
  static String get otpCodeHint => 'auth.otp_verification.code_hint'.tr();
  static String get otpResendLabel => 'auth.otp_verification.resend_label'.tr();
  static String get otpResendButton => 'auth.otp_verification.resend_button'.tr();
  static String otpResendTimer(int seconds) => 'auth.otp_verification.resend_timer'.tr(namedArgs: {'seconds': seconds.toString()});
  static String get otpVerifying => 'auth.otp_verification.verifying'.tr();

  // =====================================================
  // AUTH - VALIDATION
  // =====================================================

  static String get emailRequired => 'auth.validation.email_required'.tr();
  static String get emailInvalid => 'auth.validation.email_invalid'.tr();
  static String get emailTooLong => 'auth.validation.email_too_long'.tr();

  static String get passwordRequired => 'auth.validation.password_required'.tr();
  static String get passwordTooShort => 'auth.validation.password_too_short'.tr();
  static String get passwordTooLong => 'auth.validation.password_too_long'.tr();
  static String get passwordNeedsLowercase => 'auth.validation.password_needs_lowercase'.tr();
  static String get passwordNeedsUppercase => 'auth.validation.password_needs_uppercase'.tr();
  static String get passwordNeedsNumber => 'auth.validation.password_needs_number'.tr();
  static String get passwordNeedsSpecial => 'auth.validation.password_needs_special'.tr();
  static String get passwordsMustMatch => 'auth.validation.passwords_must_match'.tr();

  static String get usernameRequired => 'auth.validation.username_required'.tr();
  static String get usernameTooShort => 'auth.validation.username_too_short'.tr();
  static String get usernameTooLong => 'auth.validation.username_too_long'.tr();
  static String get usernameInvalidChars => 'auth.validation.username_invalid_chars'.tr();
  static String get usernameStartsWithNumber => 'auth.validation.username_starts_with_number'.tr();
  static String get usernameInvalidUnderscore => 'auth.validation.username_invalid_underscore'.tr();
  static String get usernameReserved => 'auth.validation.username_reserved'.tr();

  static String get displayNameRequired => 'auth.validation.display_name_required'.tr();
  static String get displayNameEmpty => 'auth.validation.display_name_empty'.tr();
  static String get displayNameTooLong => 'auth.validation.display_name_too_long'.tr();

  static String get bioTooLong => 'auth.validation.bio_too_long'.tr();

  // =====================================================
  // AUTH - ERRORS
  // =====================================================

  static String get invalidCredentials => 'auth.errors.invalid_credentials'.tr();
  static String get emailAlreadyInUse => 'auth.errors.email_already_in_use'.tr();
  static String get weakPassword => 'auth.errors.weak_password'.tr();
  static String get userNotFound => 'auth.errors.user_not_found'.tr();
  static String get networkError => 'auth.errors.network_error'.tr();
  static String get unknownError => 'auth.errors.unknown_error'.tr();

  // =====================================================
  // COMMON
  // =====================================================

  static String select(String field) => 'common.select'.tr(namedArgs: {'field': field});
  static String get requiredField => 'common.required_field'.tr();
  static String minLength(int count) => 'common.min_length'.tr(namedArgs: {'count': count.toString()});
  static String maxLength(int count) => 'common.max_length'.tr(namedArgs: {'count': count.toString()});
  static String get enterEmail => 'common.enter_email'.tr();
  static String get emailInvalidCommon => 'common.email_invalid'.tr();
  static String get emailHintPlaceholder => 'common.email_hint_placeholder'.tr();

  static String get loading => 'common.loading'.tr();
  static String get error => 'common.error'.tr();
  static String get success => 'common.success'.tr();
  static String get cancel => 'common.cancel'.tr();
  static String get confirm => 'common.confirm'.tr();
  static String get save => 'common.save'.tr();
  static String get delete => 'common.delete'.tr();
  static String get edit => 'common.edit'.tr();
  static String get back => 'common.back'.tr();
  static String get close => 'common.close'.tr();
  static String get forget => 'common.forget'.tr();
  static String get permanentlyDelete => 'common.permanently_delete'.tr();
  static String get enterPassword => 'common.enter_password'.tr();

  // =====================================================
  // GOSSIP
  // =====================================================

  static String get gossipDetailTitle => 'gossip.detail_screen.title'.tr();
  static String get gossipMediaCamera => 'gossip.media.camera'.tr();
  static String get gossipMediaGallery => 'gossip.media.gallery'.tr();
  static String get gossipMediaAddImage => 'gossip.media.add_image'.tr();
  static String get gossipMediaAddAudio => 'gossip.media.add_audio'.tr();
  static String get gossipMediaAudioAttached => 'gossip.media.audio_attached'.tr();
  static String get gossipReportTitle => 'gossip.report.title'.tr();
  static String get gossipReportButton => 'gossip.report.button'.tr();

  // =====================================================
  // PROFILE - PRIVACY SETTINGS
  // =====================================================

  static String get privacySettingsTitle => 'profile.privacy_settings.title'.tr();
  static String get privacySettingsSavedCity => 'profile.privacy_settings.saved_city_title'.tr();
  static String get privacySettingsAnonymousMode => 'profile.privacy_settings.anonymous_mode_title'.tr();
  static String get privacySettingsViewMyData => 'profile.privacy_settings.view_my_data_title'.tr();
  static String get privacySettingsViewMyDataSubtitle => 'profile.privacy_settings.view_my_data_subtitle'.tr();
  static String get privacySettingsPrivacyPolicy => 'profile.privacy_settings.privacy_policy_title'.tr();
  static String get privacySettingsTermsOfUse => 'profile.privacy_settings.terms_of_use_title'.tr();
  static String get privacySettingsConfirmDeletion => 'profile.privacy_settings.confirm_deletion_title'.tr();
  static String get privacySettingsDeletionCancelled => 'profile.privacy_settings.deletion_cancelled'.tr();
  static String get privacySettingsAccountDeleted => 'profile.privacy_settings.account_deleted'.tr();
  static String get privacySettingsMyData => 'profile.privacy_settings.my_data_title'.tr();
  static String get privacySettingsEraseButton => 'profile.privacy_settings.erase_button'.tr();

  // =====================================================
  // PROFILE - PRIVACY CONSENT
  // =====================================================

  static String get privacyConsentTitle => 'profile.privacy_consent.title'.tr();
  static String get privacyConsentDeclineButton => 'profile.privacy_consent.decline_button'.tr();
}
