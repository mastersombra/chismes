import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Chismes'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'Comparte historias, descubre secretos'**
  String get appTagline;

  /// No description provided for @authErrorsEmailAlreadyInUse.
  ///
  /// In es, this message translates to:
  /// **'El email ya está en uso'**
  String get authErrorsEmailAlreadyInUse;

  /// No description provided for @authErrorsInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Credenciales inválidas'**
  String get authErrorsInvalidCredentials;

  /// No description provided for @authErrorsNetworkError.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión'**
  String get authErrorsNetworkError;

  /// No description provided for @authErrorsUnknownError.
  ///
  /// In es, this message translates to:
  /// **'Error desconocido'**
  String get authErrorsUnknownError;

  /// No description provided for @authErrorsUserNotFound.
  ///
  /// In es, this message translates to:
  /// **'Usuario no encontrado'**
  String get authErrorsUserNotFound;

  /// No description provided for @authErrorsWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es muy débil'**
  String get authErrorsWeakPassword;

  /// No description provided for @authForgotPasswordCodeSentMessage.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu email para obtener el código de verificación'**
  String get authForgotPasswordCodeSentMessage;

  /// No description provided for @authForgotPasswordCodeSentTitle.
  ///
  /// In es, this message translates to:
  /// **'Código enviado'**
  String get authForgotPasswordCodeSentTitle;

  /// No description provided for @authForgotPasswordEmailHint.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authForgotPasswordEmailHint;

  /// No description provided for @authForgotPasswordMessage.
  ///
  /// In es, this message translates to:
  /// **'Te enviaremos un código de 6 dígitos para recuperar tu contraseña'**
  String get authForgotPasswordMessage;

  /// No description provided for @authForgotPasswordSendCodeButton.
  ///
  /// In es, this message translates to:
  /// **'Enviar código'**
  String get authForgotPasswordSendCodeButton;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPasswordTitle;

  /// No description provided for @authLoginContinueWithApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get authLoginContinueWithApple;

  /// No description provided for @authLoginContinueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get authLoginContinueWithGoogle;

  /// No description provided for @authLoginEmailHint.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authLoginEmailHint;

  /// No description provided for @authLoginForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authLoginForgotPassword;

  /// No description provided for @authLoginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get authLoginNoAccount;

  /// No description provided for @authLoginOrContinueWith.
  ///
  /// In es, this message translates to:
  /// **'O continúa con'**
  String get authLoginOrContinueWith;

  /// No description provided for @authLoginPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authLoginPasswordHint;

  /// No description provided for @authLoginSignInButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get authLoginSignInButton;

  /// No description provided for @authLoginSignUpLink.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get authLoginSignUpLink;

  /// No description provided for @authLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get authLoginTitle;

  /// No description provided for @authOtpVerificationCodeHint.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get authOtpVerificationCodeHint;

  /// No description provided for @authOtpVerificationResendButton.
  ///
  /// In es, this message translates to:
  /// **'Reenviar'**
  String get authOtpVerificationResendButton;

  /// No description provided for @authOtpVerificationResendLabel.
  ///
  /// In es, this message translates to:
  /// **'¿No recibiste el código?'**
  String get authOtpVerificationResendLabel;

  /// Translated from: auth.otp_verification.resend_timer
  ///
  /// In es, this message translates to:
  /// **'Reenviar ({seconds}s)'**
  String authOtpVerificationResendTimer(String seconds);

  /// No description provided for @authOtpVerificationSubtitleReset.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el código que enviamos a:'**
  String get authOtpVerificationSubtitleReset;

  /// No description provided for @authOtpVerificationSubtitleSignup.
  ///
  /// In es, this message translates to:
  /// **'Enviamos un código de 6 dígitos a:'**
  String get authOtpVerificationSubtitleSignup;

  /// No description provided for @authOtpVerificationTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificar Código'**
  String get authOtpVerificationTitle;

  /// No description provided for @authOtpVerificationVerifyEmailTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificar Email'**
  String get authOtpVerificationVerifyEmailTitle;

  /// No description provided for @authOtpVerificationVerifying.
  ///
  /// In es, this message translates to:
  /// **'Verificando...'**
  String get authOtpVerificationVerifying;

  /// No description provided for @authPasswordFieldHide.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get authPasswordFieldHide;

  /// No description provided for @authPasswordFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPasswordFieldLabel;

  /// No description provided for @authPasswordFieldShow.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get authPasswordFieldShow;

  /// No description provided for @authProfileSetupAvatarUploadSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente: subir avatar'**
  String get authProfileSetupAvatarUploadSoon;

  /// No description provided for @authProfileSetupBioHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos sobre ti...'**
  String get authProfileSetupBioHint;

  /// No description provided for @authProfileSetupBioLabel.
  ///
  /// In es, this message translates to:
  /// **'Biografía (opcional)'**
  String get authProfileSetupBioLabel;

  /// No description provided for @authProfileSetupCompleteButton.
  ///
  /// In es, this message translates to:
  /// **'Completar perfil'**
  String get authProfileSetupCompleteButton;

  /// No description provided for @authProfileSetupDisplayNameHint.
  ///
  /// In es, this message translates to:
  /// **'Juan Pérez'**
  String get authProfileSetupDisplayNameHint;

  /// No description provided for @authProfileSetupDisplayNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre a mostrar'**
  String get authProfileSetupDisplayNameLabel;

  /// No description provided for @authProfileSetupDoItLater.
  ///
  /// In es, this message translates to:
  /// **'Lo haré después'**
  String get authProfileSetupDoItLater;

  /// No description provided for @authProfileSetupInfoMessage.
  ///
  /// In es, this message translates to:
  /// **'Necesitas un nombre de usuario para publicar chismes'**
  String get authProfileSetupInfoMessage;

  /// No description provided for @authProfileSetupLaterButton.
  ///
  /// In es, this message translates to:
  /// **'Después'**
  String get authProfileSetupLaterButton;

  /// No description provided for @authProfileSetupSaveButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar Perfil'**
  String get authProfileSetupSaveButton;

  /// No description provided for @authProfileSetupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil para empezar a compartir chismes'**
  String get authProfileSetupSubtitle;

  /// No description provided for @authProfileSetupTitle.
  ///
  /// In es, this message translates to:
  /// **'Configura tu Perfil'**
  String get authProfileSetupTitle;

  /// No description provided for @authProfileSetupUsernameAvailabilityCheck.
  ///
  /// In es, this message translates to:
  /// **'Verifica que el nombre de usuario esté disponible'**
  String get authProfileSetupUsernameAvailabilityCheck;

  /// No description provided for @authProfileSetupUsernameHelper.
  ///
  /// In es, this message translates to:
  /// **'Solo letras minúsculas, números y _'**
  String get authProfileSetupUsernameHelper;

  /// No description provided for @authProfileSetupUsernameHint.
  ///
  /// In es, this message translates to:
  /// **'juanperez'**
  String get authProfileSetupUsernameHint;

  /// No description provided for @authProfileSetupUsernameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de usuario'**
  String get authProfileSetupUsernameLabel;

  /// No description provided for @authProfileSetupUsernameTaken.
  ///
  /// In es, this message translates to:
  /// **'Este nombre de usuario ya está en uso'**
  String get authProfileSetupUsernameTaken;

  /// No description provided for @authProfileSetupWelcome.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido!'**
  String get authProfileSetupWelcome;

  /// No description provided for @authResetPasswordChangePasswordButton.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get authResetPasswordChangePasswordButton;

  /// No description provided for @authResetPasswordConfirmPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get authResetPasswordConfirmPasswordHint;

  /// No description provided for @authResetPasswordDescription.
  ///
  /// In es, this message translates to:
  /// **'Debe tener mínimo 8 caracteres'**
  String get authResetPasswordDescription;

  /// No description provided for @authResetPasswordNewPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get authResetPasswordNewPasswordHint;

  /// No description provided for @authResetPasswordOkButton.
  ///
  /// In es, this message translates to:
  /// **'OK'**
  String get authResetPasswordOkButton;

  /// No description provided for @authResetPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu nueva contraseña'**
  String get authResetPasswordSubtitle;

  /// No description provided for @authResetPasswordSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu contraseña ha sido actualizada exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña'**
  String get authResetPasswordSuccessMessage;

  /// No description provided for @authResetPasswordSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get authResetPasswordSuccessTitle;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva Contraseña'**
  String get authResetPasswordTitle;

  /// No description provided for @authSignupAlreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get authSignupAlreadyHaveAccount;

  /// No description provided for @authSignupConfirmPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get authSignupConfirmPasswordHint;

  /// No description provided for @authSignupConfirmPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu contraseña'**
  String get authSignupConfirmPasswordRequired;

  /// No description provided for @authSignupDescription.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta en segundos'**
  String get authSignupDescription;

  /// No description provided for @authSignupEmailHint.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authSignupEmailHint;

  /// No description provided for @authSignupPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authSignupPasswordHint;

  /// No description provided for @authSignupPasswordMinLength.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get authSignupPasswordMinLength;

  /// No description provided for @authSignupPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una contraseña'**
  String get authSignupPasswordRequired;

  /// No description provided for @authSignupPasswordsMustMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get authSignupPasswordsMustMatch;

  /// No description provided for @authSignupSignInLink.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get authSignupSignInLink;

  /// No description provided for @authSignupSignUpButton.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get authSignupSignUpButton;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Únete a Chismes'**
  String get authSignupSubtitle;

  /// No description provided for @authSignupTermsMessage.
  ///
  /// In es, this message translates to:
  /// **'Al crear una cuenta, aceptas nuestros Términos y Condiciones y Política de Privacidad'**
  String get authSignupTermsMessage;

  /// No description provided for @authSignupTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get authSignupTitle;

  /// No description provided for @authValidationBioTooLong.
  ///
  /// In es, this message translates to:
  /// **'La biografía es muy larga (máximo 160 caracteres)'**
  String get authValidationBioTooLong;

  /// No description provided for @authValidationDisplayNameEmpty.
  ///
  /// In es, this message translates to:
  /// **'El nombre a mostrar no puede estar vacío'**
  String get authValidationDisplayNameEmpty;

  /// No description provided for @authValidationDisplayNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre a mostrar es requerido'**
  String get authValidationDisplayNameRequired;

  /// No description provided for @authValidationDisplayNameTooLong.
  ///
  /// In es, this message translates to:
  /// **'El nombre a mostrar es muy largo (máximo 50 caracteres)'**
  String get authValidationDisplayNameTooLong;

  /// No description provided for @authValidationEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'El formato del email es inválido'**
  String get authValidationEmailInvalid;

  /// No description provided for @authValidationEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'El email es requerido'**
  String get authValidationEmailRequired;

  /// No description provided for @authValidationEmailTooLong.
  ///
  /// In es, this message translates to:
  /// **'El email es muy largo (máximo 254 caracteres)'**
  String get authValidationEmailTooLong;

  /// No description provided for @authValidationPasswordNeedsLowercase.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe contener al menos una letra minúscula'**
  String get authValidationPasswordNeedsLowercase;

  /// No description provided for @authValidationPasswordNeedsNumber.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe contener al menos un número'**
  String get authValidationPasswordNeedsNumber;

  /// No description provided for @authValidationPasswordNeedsSpecial.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe contener al menos un carácter especial'**
  String get authValidationPasswordNeedsSpecial;

  /// No description provided for @authValidationPasswordNeedsUppercase.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe contener al menos una letra mayúscula'**
  String get authValidationPasswordNeedsUppercase;

  /// No description provided for @authValidationPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es requerida'**
  String get authValidationPasswordRequired;

  /// No description provided for @authValidationPasswordTooLong.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es muy larga (máximo 128 caracteres)'**
  String get authValidationPasswordTooLong;

  /// No description provided for @authValidationPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es muy corta (mínimo 8 caracteres)'**
  String get authValidationPasswordTooShort;

  /// No description provided for @authValidationPasswordsMustMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas deben coincidir'**
  String get authValidationPasswordsMustMatch;

  /// No description provided for @authValidationUsernameInvalidChars.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario solo puede contener letras minúsculas, números y guiones bajos'**
  String get authValidationUsernameInvalidChars;

  /// No description provided for @authValidationUsernameInvalidUnderscore.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario no puede empezar o terminar con guión bajo'**
  String get authValidationUsernameInvalidUnderscore;

  /// No description provided for @authValidationUsernameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario es requerido'**
  String get authValidationUsernameRequired;

  /// No description provided for @authValidationUsernameReserved.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario está reservado'**
  String get authValidationUsernameReserved;

  /// No description provided for @authValidationUsernameStartsWithNumber.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario no puede empezar con un número'**
  String get authValidationUsernameStartsWithNumber;

  /// No description provided for @authValidationUsernameTooLong.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario es muy largo (máximo 30 caracteres)'**
  String get authValidationUsernameTooLong;

  /// No description provided for @authValidationUsernameTooShort.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario es muy corto (mínimo 3 caracteres)'**
  String get authValidationUsernameTooShort;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonEmailHintPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'tu@email.com'**
  String get commonEmailHintPlaceholder;

  /// No description provided for @commonEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Email inválido'**
  String get commonEmailInvalid;

  /// No description provided for @commonEnterEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un email'**
  String get commonEnterEmail;

  /// No description provided for @commonEnterPassword.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get commonEnterPassword;

  /// No description provided for @commonError.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonForget.
  ///
  /// In es, this message translates to:
  /// **'Olvidar'**
  String get commonForget;

  /// No description provided for @commonLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get commonLoading;

  /// Translated from: common.max_length
  ///
  /// In es, this message translates to:
  /// **'No puede exceder {count} caracteres'**
  String commonMaxLength(String count);

  /// Translated from: common.min_length
  ///
  /// In es, this message translates to:
  /// **'Debe tener al menos {count} caracteres'**
  String commonMinLength(String count);

  /// No description provided for @commonPermanentlyDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar permanentemente'**
  String get commonPermanentlyDelete;

  /// No description provided for @commonRequiredField.
  ///
  /// In es, this message translates to:
  /// **'Campo requerido'**
  String get commonRequiredField;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// Translated from: common.select
  ///
  /// In es, this message translates to:
  /// **'Selecciona {field}'**
  String commonSelect(String field);

  /// No description provided for @commonSuccess.
  ///
  /// In es, this message translates to:
  /// **'Éxito'**
  String get commonSuccess;

  /// No description provided for @errorsAuthEmailAlreadyInUse.
  ///
  /// In es, this message translates to:
  /// **'Este email ya está registrado.'**
  String get errorsAuthEmailAlreadyInUse;

  /// No description provided for @errorsAuthEmailNotVerified.
  ///
  /// In es, this message translates to:
  /// **'Debes verificar tu email para continuar.'**
  String get errorsAuthEmailNotVerified;

  /// No description provided for @errorsAuthExpiredToken.
  ///
  /// In es, this message translates to:
  /// **'Código inválido o expirado. Solicita uno nuevo.'**
  String get errorsAuthExpiredToken;

  /// No description provided for @errorsAuthInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Email o contraseña incorrectos. Por favor, verifica tus datos e intenta nuevamente.'**
  String get errorsAuthInvalidCredentials;

  /// No description provided for @errorsAuthInvalidToken.
  ///
  /// In es, this message translates to:
  /// **'Código inválido o expirado. Solicita uno nuevo.'**
  String get errorsAuthInvalidToken;

  /// No description provided for @errorsAuthNotAuthenticated.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para continuar.'**
  String get errorsAuthNotAuthenticated;

  /// No description provided for @errorsAuthOauthCancelled.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión cancelado.'**
  String get errorsAuthOauthCancelled;

  /// No description provided for @errorsAuthOauthProviderError.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión con el proveedor.'**
  String get errorsAuthOauthProviderError;

  /// No description provided for @errorsAuthSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha expirado. Inicia sesión nuevamente.'**
  String get errorsAuthSessionExpired;

  /// No description provided for @errorsAuthTooManyAttempts.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Intenta más tarde.'**
  String get errorsAuthTooManyAttempts;

  /// No description provided for @errorsAuthUnauthorized.
  ///
  /// In es, this message translates to:
  /// **'No estás autorizado para realizar esta acción.'**
  String get errorsAuthUnauthorized;

  /// No description provided for @errorsAuthUserNotFound.
  ///
  /// In es, this message translates to:
  /// **'Usuario no encontrado.'**
  String get errorsAuthUserNotFound;

  /// No description provided for @errorsAuthUsernameTaken.
  ///
  /// In es, this message translates to:
  /// **'Este nombre de usuario ya está en uso.'**
  String get errorsAuthUsernameTaken;

  /// No description provided for @errorsAuthWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es muy débil.'**
  String get errorsAuthWeakPassword;

  /// No description provided for @errorsBusinessGossipNotFound.
  ///
  /// In es, this message translates to:
  /// **'El chisme no existe o fue eliminado.'**
  String get errorsBusinessGossipNotFound;

  /// No description provided for @errorsBusinessInvalidGossipContent.
  ///
  /// In es, this message translates to:
  /// **'El contenido del chisme es inválido.'**
  String get errorsBusinessInvalidGossipContent;

  /// No description provided for @errorsBusinessInvalidLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación inválida. Selecciona una ubicación válida.'**
  String get errorsBusinessInvalidLocation;

  /// No description provided for @errorsBusinessMediaUploadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo subir la imagen. Por favor intenta de nuevo o intenta con otra imagen.'**
  String get errorsBusinessMediaUploadFailed;

  /// No description provided for @errorsBusinessModerationRejected.
  ///
  /// In es, this message translates to:
  /// **'El contenido no cumple con nuestras normas de comunidad. Por favor revisa el contenido e intenta nuevamente.'**
  String get errorsBusinessModerationRejected;

  /// No description provided for @errorsBusinessRateLimitExceeded.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado el límite de solicitudes. Espera un momento e intenta de nuevo.'**
  String get errorsBusinessRateLimitExceeded;

  /// No description provided for @errorsDataAlreadyExists.
  ///
  /// In es, this message translates to:
  /// **'El recurso ya existe.'**
  String get errorsDataAlreadyExists;

  /// No description provided for @errorsDataConflict.
  ///
  /// In es, this message translates to:
  /// **'Conflicto de datos. Intenta nuevamente.'**
  String get errorsDataConflict;

  /// No description provided for @errorsDataNotFound.
  ///
  /// In es, this message translates to:
  /// **'El recurso solicitado no existe.'**
  String get errorsDataNotFound;

  /// No description provided for @errorsNetworkConnectionError.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Por favor verifica tu internet.'**
  String get errorsNetworkConnectionError;

  /// No description provided for @errorsNetworkNoInternet.
  ///
  /// In es, this message translates to:
  /// **'No tienes conexión a internet. Verifica tu red.'**
  String get errorsNetworkNoInternet;

  /// No description provided for @errorsNetworkTimeout.
  ///
  /// In es, this message translates to:
  /// **'La solicitud tardó demasiado. Intenta nuevamente.'**
  String get errorsNetworkTimeout;

  /// No description provided for @errorsPermissionsForbidden.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para realizar esta acción.'**
  String get errorsPermissionsForbidden;

  /// No description provided for @errorsPermissionsInsufficient.
  ///
  /// In es, this message translates to:
  /// **'Permisos insuficientes para esta acción.'**
  String get errorsPermissionsInsufficient;

  /// No description provided for @errorsServerBadRequest.
  ///
  /// In es, this message translates to:
  /// **'Solicitud inválida. Verifica los datos enviados.'**
  String get errorsServerBadRequest;

  /// No description provided for @errorsServerError.
  ///
  /// In es, this message translates to:
  /// **'Error en el servidor. Intenta más tarde.'**
  String get errorsServerError;

  /// No description provided for @errorsServerMaintenance.
  ///
  /// In es, this message translates to:
  /// **'El servidor está en mantenimiento. Intenta más tarde.'**
  String get errorsServerMaintenance;

  /// No description provided for @errorsServerTooManyRequests.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado el límite de solicitudes. Espera un momento e intenta de nuevo.'**
  String get errorsServerTooManyRequests;

  /// No description provided for @errorsServerUnavailable.
  ///
  /// In es, this message translates to:
  /// **'El servicio no está disponible temporalmente.'**
  String get errorsServerUnavailable;

  /// No description provided for @errorsTitlesAuth.
  ///
  /// In es, this message translates to:
  /// **'Error de autenticación'**
  String get errorsTitlesAuth;

  /// No description provided for @errorsTitlesConnection.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión'**
  String get errorsTitlesConnection;

  /// No description provided for @errorsTitlesData.
  ///
  /// In es, this message translates to:
  /// **'Error de datos'**
  String get errorsTitlesData;

  /// No description provided for @errorsTitlesGeneral.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get errorsTitlesGeneral;

  /// No description provided for @errorsTitlesPermissions.
  ///
  /// In es, this message translates to:
  /// **'Error de permisos'**
  String get errorsTitlesPermissions;

  /// No description provided for @errorsTitlesServer.
  ///
  /// In es, this message translates to:
  /// **'Error del servidor'**
  String get errorsTitlesServer;

  /// No description provided for @errorsTitlesUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado'**
  String get errorsTitlesUnexpected;

  /// No description provided for @errorsTitlesValidation.
  ///
  /// In es, this message translates to:
  /// **'Error de validación'**
  String get errorsTitlesValidation;

  /// No description provided for @errorsUnknown.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado. Intenta nuevamente.'**
  String get errorsUnknown;

  /// No description provided for @errorsValidationError.
  ///
  /// In es, this message translates to:
  /// **'Error de validación. Verifica los datos ingresados.'**
  String get errorsValidationError;

  /// No description provided for @errorsValidationInvalidInput.
  ///
  /// In es, this message translates to:
  /// **'Dato inválido. Verifica el formato.'**
  String get errorsValidationInvalidInput;

  /// No description provided for @errorsValidationMissingField.
  ///
  /// In es, this message translates to:
  /// **'Falta un campo requerido.'**
  String get errorsValidationMissingField;

  /// No description provided for @gossipAddScreenEmailVerificationResent.
  ///
  /// In es, this message translates to:
  /// **'Email de verificación reenviado. Revisa tu bandeja de entrada.'**
  String get gossipAddScreenEmailVerificationResent;

  /// No description provided for @gossipAddScreenSubmitButton.
  ///
  /// In es, this message translates to:
  /// **'Publicar chisme'**
  String get gossipAddScreenSubmitButton;

  /// No description provided for @gossipAddScreenSuccessDialogButton.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get gossipAddScreenSuccessDialogButton;

  /// No description provided for @gossipAddScreenSuccessDialogContentPending.
  ///
  /// In es, this message translates to:
  /// **'Tu chisme está pendiente de moderación. Te avisaremos cuando cambie de estado.'**
  String get gossipAddScreenSuccessDialogContentPending;

  /// No description provided for @gossipAddScreenSuccessDialogContentPublished.
  ///
  /// In es, this message translates to:
  /// **'Tu chisme pasó los controles automáticos y ya está publicado.'**
  String get gossipAddScreenSuccessDialogContentPublished;

  /// No description provided for @gossipAddScreenSuccessDialogTitlePending.
  ///
  /// In es, this message translates to:
  /// **'¡Chisme enviado!'**
  String get gossipAddScreenSuccessDialogTitlePending;

  /// No description provided for @gossipAddScreenSuccessDialogTitlePublished.
  ///
  /// In es, this message translates to:
  /// **'¡Chisme publicado!'**
  String get gossipAddScreenSuccessDialogTitlePublished;

  /// No description provided for @gossipAddScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Chisme 📝'**
  String get gossipAddScreenTitle;

  /// No description provided for @gossipCardRateLimitError.
  ///
  /// In es, this message translates to:
  /// **'Límite alcanzado'**
  String get gossipCardRateLimitError;

  /// No description provided for @gossipCardReportError.
  ///
  /// In es, this message translates to:
  /// **'Error al reportar'**
  String get gossipCardReportError;

  /// No description provided for @gossipCardReportSemanticHint.
  ///
  /// In es, this message translates to:
  /// **'Abre opciones para reportar contenido inapropiado'**
  String get gossipCardReportSemanticHint;

  /// No description provided for @gossipCardReportSemanticLabel.
  ///
  /// In es, this message translates to:
  /// **'Reportar este chisme'**
  String get gossipCardReportSemanticLabel;

  /// No description provided for @gossipCardReportSuccess.
  ///
  /// In es, this message translates to:
  /// **'Gracias por tu reporte. Lo revisaremos pronto.'**
  String get gossipCardReportSuccess;

  /// No description provided for @gossipCardReportTooltip.
  ///
  /// In es, this message translates to:
  /// **'Reportar chisme'**
  String get gossipCardReportTooltip;

  /// No description provided for @gossipCardSemanticHint.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver detalles completos'**
  String get gossipCardSemanticHint;

  /// Translated from: gossip.card.semantic_label
  ///
  /// In es, this message translates to:
  /// **'Chisme: {subject}. {content}'**
  String gossipCardSemanticLabel(String subject, String content);

  /// No description provided for @gossipCardShareError.
  ///
  /// In es, this message translates to:
  /// **'Error al compartir'**
  String get gossipCardShareError;

  /// No description provided for @gossipCardShareSemanticHint.
  ///
  /// In es, this message translates to:
  /// **'Abre opciones para compartir con otros'**
  String get gossipCardShareSemanticHint;

  /// No description provided for @gossipCardShareSemanticLabel.
  ///
  /// In es, this message translates to:
  /// **'Compartir este chisme'**
  String get gossipCardShareSemanticLabel;

  /// No description provided for @gossipCardShareTooltip.
  ///
  /// In es, this message translates to:
  /// **'Compartir chisme'**
  String get gossipCardShareTooltip;

  /// No description provided for @gossipDetailScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle'**
  String get gossipDetailScreenTitle;

  /// No description provided for @gossipLocationChangeDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar ubicación'**
  String get gossipLocationChangeDialogTitle;

  /// No description provided for @gossipLocationCityHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar ciudad...'**
  String get gossipLocationCityHint;

  /// No description provided for @gossipLocationCityLabel.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get gossipLocationCityLabel;

  /// No description provided for @gossipLocationCityRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una ciudad'**
  String get gossipLocationCityRequired;

  /// Translated from: gossip.location.city_search_hint
  ///
  /// In es, this message translates to:
  /// **'Buscar ciudad... (mín. {minChars} caracteres)'**
  String gossipLocationCitySearchHint(String minChars);

  /// No description provided for @gossipLocationCountryLabel.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get gossipLocationCountryLabel;

  /// No description provided for @gossipLocationCountryRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un país'**
  String get gossipLocationCountryRequired;

  /// No description provided for @gossipLocationGpsDetectSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Detectar automáticamente con GPS'**
  String get gossipLocationGpsDetectSubtitle;

  /// Translated from: gossip.location.min_chars_message
  ///
  /// In es, this message translates to:
  /// **'Escribe al menos {minChars} caracteres para buscar'**
  String gossipLocationMinCharsMessage(String minChars);

  /// Translated from: gossip.location.no_results
  ///
  /// In es, this message translates to:
  /// **'No se encontraron ciudades con \"{query}\"'**
  String gossipLocationNoResults(String query);

  /// No description provided for @gossipLocationOrSelectManually.
  ///
  /// In es, this message translates to:
  /// **'O seleccionar manualmente'**
  String get gossipLocationOrSelectManually;

  /// No description provided for @gossipLocationRegionLabel.
  ///
  /// In es, this message translates to:
  /// **'Región'**
  String get gossipLocationRegionLabel;

  /// No description provided for @gossipLocationRegionRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una región'**
  String get gossipLocationRegionRequired;

  /// No description provided for @gossipLocationSearchError.
  ///
  /// In es, this message translates to:
  /// **'Error al buscar ciudades. Intenta de nuevo.'**
  String get gossipLocationSearchError;

  /// No description provided for @gossipLocationUnexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado. Intenta de nuevo.'**
  String get gossipLocationUnexpectedError;

  /// No description provided for @gossipLocationUseCurrentLocation.
  ///
  /// In es, this message translates to:
  /// **'Usar mi ubicación actual'**
  String get gossipLocationUseCurrentLocation;

  /// No description provided for @gossipLocationSelectorChangeButtonLabel.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get gossipLocationSelectorChangeButtonLabel;

  /// No description provided for @gossipLocationSelectorChangeButtonSemanticHint.
  ///
  /// In es, this message translates to:
  /// **'Abre el selector de ubicación'**
  String get gossipLocationSelectorChangeButtonSemanticHint;

  /// No description provided for @gossipLocationSelectorChangeButtonSemanticLabel.
  ///
  /// In es, this message translates to:
  /// **'Cambiar ubicación'**
  String get gossipLocationSelectorChangeButtonSemanticLabel;

  /// No description provided for @gossipLocationSelectorDetectingText.
  ///
  /// In es, this message translates to:
  /// **'Detectando ubicación...'**
  String get gossipLocationSelectorDetectingText;

  /// No description provided for @gossipLocationSelectorIconSemanticLabel.
  ///
  /// In es, this message translates to:
  /// **'Ícono de ubicación'**
  String get gossipLocationSelectorIconSemanticLabel;

  /// No description provided for @gossipLocationSelectorPlaceholderText.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar ubicación'**
  String get gossipLocationSelectorPlaceholderText;

  /// No description provided for @gossipLocationSelectorSemanticHint.
  ///
  /// In es, this message translates to:
  /// **'Toca el botón cambiar para seleccionar otra ubicación'**
  String get gossipLocationSelectorSemanticHint;

  /// No description provided for @gossipLocationSelectorSemanticLabelDetecting.
  ///
  /// In es, this message translates to:
  /// **'Detectando ubicación automáticamente'**
  String get gossipLocationSelectorSemanticLabelDetecting;

  /// No description provided for @gossipLocationSelectorSemanticLabelEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay ubicación seleccionada'**
  String get gossipLocationSelectorSemanticLabelEmpty;

  /// Translated from: gossip.location_selector.semantic_label_selected
  ///
  /// In es, this message translates to:
  /// **'Ubicación actual: {location}'**
  String gossipLocationSelectorSemanticLabelSelected(String location);

  /// No description provided for @gossipMediaAddAudio.
  ///
  /// In es, this message translates to:
  /// **'Agregar audio'**
  String get gossipMediaAddAudio;

  /// No description provided for @gossipMediaAddImage.
  ///
  /// In es, this message translates to:
  /// **'Agregar imagen'**
  String get gossipMediaAddImage;

  /// No description provided for @gossipMediaAddPhotoOptional.
  ///
  /// In es, this message translates to:
  /// **'Agrega una foto (opcional)'**
  String get gossipMediaAddPhotoOptional;

  /// No description provided for @gossipMediaAudioAttached.
  ///
  /// In es, this message translates to:
  /// **'Audio adjuntado'**
  String get gossipMediaAudioAttached;

  /// No description provided for @gossipMediaCamera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get gossipMediaCamera;

  /// No description provided for @gossipMediaCameraSemanticHint.
  ///
  /// In es, this message translates to:
  /// **'Abre la cámara para tomar una foto'**
  String get gossipMediaCameraSemanticHint;

  /// No description provided for @gossipMediaCameraSemanticLabel.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto con la cámara'**
  String get gossipMediaCameraSemanticLabel;

  /// No description provided for @gossipMediaGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get gossipMediaGallery;

  /// No description provided for @gossipMediaGallerySemanticHint.
  ///
  /// In es, this message translates to:
  /// **'Abre la galería de fotos'**
  String get gossipMediaGallerySemanticHint;

  /// No description provided for @gossipMediaGallerySemanticLabel.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar foto de la galería'**
  String get gossipMediaGallerySemanticLabel;

  /// No description provided for @gossipMediaImageSelected.
  ///
  /// In es, this message translates to:
  /// **'Imagen seleccionada'**
  String get gossipMediaImageSelected;

  /// No description provided for @gossipMediaImageSemanticLabel.
  ///
  /// In es, this message translates to:
  /// **'Imagen del chisme seleccionada'**
  String get gossipMediaImageSemanticLabel;

  /// No description provided for @gossipMediaLoadingSemantic.
  ///
  /// In es, this message translates to:
  /// **'Cargando imagen'**
  String get gossipMediaLoadingSemantic;

  /// No description provided for @gossipMediaRemoveImageSemanticHint.
  ///
  /// In es, this message translates to:
  /// **'Remueve la imagen seleccionada'**
  String get gossipMediaRemoveImageSemanticHint;

  /// No description provided for @gossipMediaRemoveImageSemanticLabel.
  ///
  /// In es, this message translates to:
  /// **'Eliminar imagen'**
  String get gossipMediaRemoveImageSemanticLabel;

  /// No description provided for @gossipMediaRemoveImageTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar imagen'**
  String get gossipMediaRemoveImageTooltip;

  /// No description provided for @gossipMediaSelectingImage.
  ///
  /// In es, this message translates to:
  /// **'Seleccionando imagen...'**
  String get gossipMediaSelectingImage;

  /// No description provided for @gossipMediaSelectingSemanticLabel.
  ///
  /// In es, this message translates to:
  /// **'Seleccionando imagen, por favor espera'**
  String get gossipMediaSelectingSemanticLabel;

  /// No description provided for @gossipPublishAsAnonymous.
  ///
  /// In es, this message translates to:
  /// **'Anónimo'**
  String get gossipPublishAsAnonymous;

  /// No description provided for @gossipPublishAsTitle.
  ///
  /// In es, this message translates to:
  /// **'Publicar como'**
  String get gossipPublishAsTitle;

  /// No description provided for @gossipPublishAsWithProfile.
  ///
  /// In es, this message translates to:
  /// **'Con mi perfil'**
  String get gossipPublishAsWithProfile;

  /// No description provided for @gossipReportButton.
  ///
  /// In es, this message translates to:
  /// **'Reportar'**
  String get gossipReportButton;

  /// No description provided for @gossipReportDetailsHint.
  ///
  /// In es, this message translates to:
  /// **'Describe el problema...'**
  String get gossipReportDetailsHint;

  /// No description provided for @gossipReportDetailsLabel.
  ///
  /// In es, this message translates to:
  /// **'Detalles adicionales (opcional)'**
  String get gossipReportDetailsLabel;

  /// No description provided for @gossipReportReasonQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Por qué reportas este chisme?'**
  String get gossipReportReasonQuestion;

  /// No description provided for @gossipReportTitle.
  ///
  /// In es, this message translates to:
  /// **'Reportar chisme'**
  String get gossipReportTitle;

  /// No description provided for @gossipSubmitButtonPublishSemantic.
  ///
  /// In es, this message translates to:
  /// **'Publicar chisme'**
  String get gossipSubmitButtonPublishSemantic;

  /// No description provided for @gossipTextFieldsContentHint.
  ///
  /// In es, this message translates to:
  /// **'Cuenta lo que sabes...'**
  String get gossipTextFieldsContentHint;

  /// No description provided for @gossipTextFieldsContentLabel.
  ///
  /// In es, this message translates to:
  /// **'El chisme'**
  String get gossipTextFieldsContentLabel;

  /// No description provided for @gossipTextFieldsContentValidation.
  ///
  /// In es, this message translates to:
  /// **'Cuenta el chisme'**
  String get gossipTextFieldsContentValidation;

  /// No description provided for @gossipTextFieldsSubjectHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Juan, la oficina, el gimnasio...'**
  String get gossipTextFieldsSubjectHint;

  /// No description provided for @gossipTextFieldsSubjectLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Sobre quién o dónde?'**
  String get gossipTextFieldsSubjectLabel;

  /// No description provided for @gossipTextFieldsSubjectValidation.
  ///
  /// In es, this message translates to:
  /// **'Escribe sobre quién o dónde es el chisme'**
  String get gossipTextFieldsSubjectValidation;

  /// No description provided for @homeDiscoverHeader.
  ///
  /// In es, this message translates to:
  /// **'Descubre 👀'**
  String get homeDiscoverHeader;

  /// No description provided for @homeErrorLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar feed'**
  String get homeErrorLoadFailed;

  /// No description provided for @homeErrorRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get homeErrorRetry;

  /// No description provided for @homeFollowingEmptyStateMessage.
  ///
  /// In es, this message translates to:
  /// **'Descubre personas interesantes y sigue sus historias'**
  String get homeFollowingEmptyStateMessage;

  /// No description provided for @homeFollowingEmptyStateTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no sigues a nadie'**
  String get homeFollowingEmptyStateTitle;

  /// No description provided for @homeFollowingExploreUsersButton.
  ///
  /// In es, this message translates to:
  /// **'Explorar usuarios'**
  String get homeFollowingExploreUsersButton;

  /// No description provided for @homeFollowingFeatureNotImplemented.
  ///
  /// In es, this message translates to:
  /// **'Feature por implementar'**
  String get homeFollowingFeatureNotImplemented;

  /// No description provided for @homeFollowingNoPostsMessage.
  ///
  /// In es, this message translates to:
  /// **'💬 Las personas que sigues aún no han publicado nada'**
  String get homeFollowingNoPostsMessage;

  /// No description provided for @homeFollowingRecommendedBadge.
  ///
  /// In es, this message translates to:
  /// **'💡 Recomendados para ti'**
  String get homeFollowingRecommendedBadge;

  /// No description provided for @homeFollowingRecommendedError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar recomendados'**
  String get homeFollowingRecommendedError;

  /// No description provided for @homeFollowingUnexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado al cargar feed'**
  String get homeFollowingUnexpectedError;

  /// No description provided for @homeFollowingUsePopularTabHint.
  ///
  /// In es, this message translates to:
  /// **'Usa el tab de Populares arriba'**
  String get homeFollowingUsePopularTabHint;

  /// No description provided for @homeFollowingViewPopularLink.
  ///
  /// In es, this message translates to:
  /// **'Ver Populares'**
  String get homeFollowingViewPopularLink;

  /// No description provided for @homePopularEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay chismes disponibles'**
  String get homePopularEmpty;

  /// No description provided for @homePopularGlobal.
  ///
  /// In es, this message translates to:
  /// **'Popular 🌎'**
  String get homePopularGlobal;

  /// Translated from: home.popular.in_city
  ///
  /// In es, this message translates to:
  /// **'Popular en {city}'**
  String homePopularInCity(String city);

  /// Translated from: home.popular.new_gossips_banner
  ///
  /// In es, this message translates to:
  /// **'{count} nuevos chismes · Tap aquí'**
  String homePopularNewGossipsBanner(String count);

  /// No description provided for @homePopularNoMore.
  ///
  /// In es, this message translates to:
  /// **'No hay más chismes por ahora 🌙'**
  String get homePopularNoMore;

  /// No description provided for @homeTabsFollowing.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo'**
  String get homeTabsFollowing;

  /// No description provided for @homeTabsPopular.
  ///
  /// In es, this message translates to:
  /// **'Populares'**
  String get homeTabsPopular;

  /// No description provided for @homeTitle.
  ///
  /// In es, this message translates to:
  /// **'Chismes 🔥'**
  String get homeTitle;

  /// No description provided for @navigationCreate.
  ///
  /// In es, this message translates to:
  /// **'Crea'**
  String get navigationCreate;

  /// No description provided for @navigationExplore.
  ///
  /// In es, this message translates to:
  /// **'Explora'**
  String get navigationExplore;

  /// No description provided for @navigationHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navigationHome;

  /// No description provided for @navigationProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navigationProfile;

  /// No description provided for @profileControllerLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar el perfil'**
  String get profileControllerLoadError;

  /// No description provided for @profileControllerSignoutError.
  ///
  /// In es, this message translates to:
  /// **'Error al cerrar sesión'**
  String get profileControllerSignoutError;

  /// No description provided for @profileControllerUpdateError.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar configuración'**
  String get profileControllerUpdateError;

  /// No description provided for @profileHeaderCompleteness.
  ///
  /// In es, this message translates to:
  /// **'Completitud del perfil'**
  String get profileHeaderCompleteness;

  /// No description provided for @profileHeaderEmailVerified.
  ///
  /// In es, this message translates to:
  /// **'Email verificado'**
  String get profileHeaderEmailVerified;

  /// No description provided for @profileHeaderNoName.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get profileHeaderNoName;

  /// No description provided for @profilePrivacyConsentDeclineButton.
  ///
  /// In es, this message translates to:
  /// **'No acepto, volver'**
  String get profilePrivacyConsentDeclineButton;

  /// No description provided for @profilePrivacyConsentTitle.
  ///
  /// In es, this message translates to:
  /// **'Privacidad y Términos'**
  String get profilePrivacyConsentTitle;

  /// No description provided for @profilePrivacySettingsAccountDeleteSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elimina tu cuenta y todos tus datos'**
  String get profilePrivacySettingsAccountDeleteSubtitle;

  /// No description provided for @profilePrivacySettingsAccountDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get profilePrivacySettingsAccountDeleteTitle;

  /// No description provided for @profilePrivacySettingsAccountDeleted.
  ///
  /// In es, this message translates to:
  /// **'Cuenta eliminada'**
  String get profilePrivacySettingsAccountDeleted;

  /// No description provided for @profilePrivacySettingsAnonymousModeTitle.
  ///
  /// In es, this message translates to:
  /// **'Modo anónimo'**
  String get profilePrivacySettingsAnonymousModeTitle;

  /// No description provided for @profilePrivacySettingsConfirmDeletionTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar eliminación'**
  String get profilePrivacySettingsConfirmDeletionTitle;

  /// No description provided for @profilePrivacySettingsDeletionCancelled.
  ///
  /// In es, this message translates to:
  /// **'Eliminación cancelada'**
  String get profilePrivacySettingsDeletionCancelled;

  /// No description provided for @profilePrivacySettingsDialogsDeleteAccountConfirmPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'ELIMINAR'**
  String get profilePrivacySettingsDialogsDeleteAccountConfirmPlaceholder;

  /// No description provided for @profilePrivacySettingsDialogsDeleteAccountConfirmPrompt.
  ///
  /// In es, this message translates to:
  /// **'Para confirmar, escribe ELIMINAR'**
  String get profilePrivacySettingsDialogsDeleteAccountConfirmPrompt;

  /// No description provided for @profilePrivacySettingsDialogsDeleteAccountMessage.
  ///
  /// In es, this message translates to:
  /// **'Esto eliminará:\n• Tu cuenta\n• Todos tus chismes\n• Todas tus interacciones\n\n⚠️ Esta acción NO se puede deshacer.'**
  String get profilePrivacySettingsDialogsDeleteAccountMessage;

  /// No description provided for @profilePrivacySettingsDialogsDeleteAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'⚠️ Eliminar cuenta'**
  String get profilePrivacySettingsDialogsDeleteAccountTitle;

  /// No description provided for @profilePrivacySettingsDialogsDeleteAllDataMessage.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán TODOS los datos guardados localmente:\n• Ubicación guardada\n• Preferencias\n• Cache\n\n¿Estás seguro?'**
  String get profilePrivacySettingsDialogsDeleteAllDataMessage;

  /// No description provided for @profilePrivacySettingsDialogsDeleteAllDataTitle.
  ///
  /// In es, this message translates to:
  /// **'⚠️ Borrar todos los datos'**
  String get profilePrivacySettingsDialogsDeleteAllDataTitle;

  /// No description provided for @profilePrivacySettingsDialogsForgetLocationMessage.
  ///
  /// In es, this message translates to:
  /// **'Se borrará tu ciudad guardada. La próxima vez que crees un chisme, se pedirá ubicación de nuevo.'**
  String get profilePrivacySettingsDialogsForgetLocationMessage;

  /// No description provided for @profilePrivacySettingsDialogsForgetLocationTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidar ubicación?'**
  String get profilePrivacySettingsDialogsForgetLocationTitle;

  /// No description provided for @profilePrivacySettingsDialogsPrivacyPolicyContent.
  ///
  /// In es, this message translates to:
  /// **'La política de privacidad completa está disponible en:\n\nhttps://chismes.app/privacy\n\nO en el archivo PRIVACY_POLICY.md del proyecto.'**
  String get profilePrivacySettingsDialogsPrivacyPolicyContent;

  /// No description provided for @profilePrivacySettingsDialogsTermsOfUseContent.
  ///
  /// In es, this message translates to:
  /// **'Los términos de uso completos están disponibles en:\n\nhttps://chismes.app/terms\n\nO en el archivo TERMS_OF_SERVICE.md del proyecto.'**
  String get profilePrivacySettingsDialogsTermsOfUseContent;

  /// No description provided for @profilePrivacySettingsEraseButton.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get profilePrivacySettingsEraseButton;

  /// No description provided for @profilePrivacySettingsExportComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Exportación disponible próximamente'**
  String get profilePrivacySettingsExportComingSoon;

  /// No description provided for @profilePrivacySettingsExportDataTooltip.
  ///
  /// In es, this message translates to:
  /// **'Exportar datos'**
  String get profilePrivacySettingsExportDataTooltip;

  /// No description provided for @profilePrivacySettingsLocalDataInfoMessage.
  ///
  /// In es, this message translates to:
  /// **'Estos datos se almacenan solo en tu teléfono (SharedPreferences). NO se envían al servidor.'**
  String get profilePrivacySettingsLocalDataInfoMessage;

  /// No description provided for @profilePrivacySettingsLocalDataInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'ℹ️ Datos locales'**
  String get profilePrivacySettingsLocalDataInfoTitle;

  /// No description provided for @profilePrivacySettingsLocationAnonymousModeDescription.
  ///
  /// In es, this message translates to:
  /// **'Con modo anónimo activado, se pedirá ubicación cada vez que crees un chisme.'**
  String get profilePrivacySettingsLocationAnonymousModeDescription;

  /// No description provided for @profilePrivacySettingsLocationAnonymousModeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No guardar ubicación por defecto'**
  String get profilePrivacySettingsLocationAnonymousModeSubtitle;

  /// No description provided for @profilePrivacySettingsLocationForgetTooltip.
  ///
  /// In es, this message translates to:
  /// **'Olvidar ubicación'**
  String get profilePrivacySettingsLocationForgetTooltip;

  /// No description provided for @profilePrivacySettingsLocationNotSaved.
  ///
  /// In es, this message translates to:
  /// **'No guardada'**
  String get profilePrivacySettingsLocationNotSaved;

  /// No description provided for @profilePrivacySettingsMyDataTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis Datos'**
  String get profilePrivacySettingsMyDataTitle;

  /// No description provided for @profilePrivacySettingsNoLocalData.
  ///
  /// In es, this message translates to:
  /// **'No hay datos guardados localmente'**
  String get profilePrivacySettingsNoLocalData;

  /// No description provided for @profilePrivacySettingsPrivacyPolicyTitle.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get profilePrivacySettingsPrivacyPolicyTitle;

  /// No description provided for @profilePrivacySettingsSavedCityTitle.
  ///
  /// In es, this message translates to:
  /// **'Ciudad guardada'**
  String get profilePrivacySettingsSavedCityTitle;

  /// No description provided for @profilePrivacySettingsSectionsAccount.
  ///
  /// In es, this message translates to:
  /// **'🔒 Cuenta'**
  String get profilePrivacySettingsSectionsAccount;

  /// No description provided for @profilePrivacySettingsSectionsLocation.
  ///
  /// In es, this message translates to:
  /// **'📍 Ubicación'**
  String get profilePrivacySettingsSectionsLocation;

  /// No description provided for @profilePrivacySettingsSectionsPolicies.
  ///
  /// In es, this message translates to:
  /// **'📄 Políticas'**
  String get profilePrivacySettingsSectionsPolicies;

  /// No description provided for @profilePrivacySettingsSectionsStoredData.
  ///
  /// In es, this message translates to:
  /// **'💾 Datos almacenados'**
  String get profilePrivacySettingsSectionsStoredData;

  /// No description provided for @profilePrivacySettingsSnackbarsAnonymousModeOff.
  ///
  /// In es, this message translates to:
  /// **'✅ Modo anónimo desactivado'**
  String get profilePrivacySettingsSnackbarsAnonymousModeOff;

  /// No description provided for @profilePrivacySettingsSnackbarsAnonymousModeOn.
  ///
  /// In es, this message translates to:
  /// **'✅ Modo anónimo activado'**
  String get profilePrivacySettingsSnackbarsAnonymousModeOn;

  /// No description provided for @profilePrivacySettingsSnackbarsDataErased.
  ///
  /// In es, this message translates to:
  /// **'✅ Datos borrados'**
  String get profilePrivacySettingsSnackbarsDataErased;

  /// No description provided for @profilePrivacySettingsSnackbarsLocationForgotten.
  ///
  /// In es, this message translates to:
  /// **'✅ Ubicación olvidada'**
  String get profilePrivacySettingsSnackbarsLocationForgotten;

  /// No description provided for @profilePrivacySettingsTermsOfUseTitle.
  ///
  /// In es, this message translates to:
  /// **'Términos de Uso'**
  String get profilePrivacySettingsTermsOfUseTitle;

  /// No description provided for @profilePrivacySettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get profilePrivacySettingsTitle;

  /// No description provided for @profilePrivacySettingsViewMyDataSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Dashboard de datos'**
  String get profilePrivacySettingsViewMyDataSubtitle;

  /// No description provided for @profilePrivacySettingsViewMyDataTitle.
  ///
  /// In es, this message translates to:
  /// **'Ver mis datos'**
  String get profilePrivacySettingsViewMyDataTitle;

  /// No description provided for @profileScreenErrorLoading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar perfil'**
  String get profileScreenErrorLoading;

  /// No description provided for @profileScreenNoUser.
  ///
  /// In es, this message translates to:
  /// **'No hay usuario autenticado'**
  String get profileScreenNoUser;

  /// No description provided for @profileScreenRefreshTooltip.
  ///
  /// In es, this message translates to:
  /// **'Refrescar'**
  String get profileScreenRefreshTooltip;

  /// No description provided for @profileScreenSignOutButton.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileScreenSignOutButton;

  /// No description provided for @profileScreenSignOutDialogContent.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro que deseas cerrar sesión?'**
  String get profileScreenSignOutDialogContent;

  /// No description provided for @profileScreenSignOutDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileScreenSignOutDialogTitle;

  /// No description provided for @profileScreenSigningOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrando sesión...'**
  String get profileScreenSigningOut;

  /// No description provided for @profileSettingsAppearanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get profileSettingsAppearanceTitle;

  /// No description provided for @profileSettingsComments.
  ///
  /// In es, this message translates to:
  /// **'Comentarios'**
  String get profileSettingsComments;

  /// No description provided for @profileSettingsCommentsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Notificar cuando comenten tus chismes'**
  String get profileSettingsCommentsSubtitle;

  /// No description provided for @profileSettingsDailySummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen diario'**
  String get profileSettingsDailySummary;

  /// No description provided for @profileSettingsDailySummarySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recibir resumen diario por email'**
  String get profileSettingsDailySummarySubtitle;

  /// No description provided for @profileSettingsDarkMode.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get profileSettingsDarkMode;

  /// No description provided for @profileSettingsDarkModeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usar tema oscuro en la aplicación'**
  String get profileSettingsDarkModeSubtitle;

  /// No description provided for @profileSettingsEmailNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones por email'**
  String get profileSettingsEmailNotifications;

  /// No description provided for @profileSettingsGeneralNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones generales'**
  String get profileSettingsGeneralNotifications;

  /// No description provided for @profileSettingsGeneralNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Activar o desactivar todas las notificaciones'**
  String get profileSettingsGeneralNotificationsSubtitle;

  /// No description provided for @profileSettingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get profileSettingsLanguage;

  /// No description provided for @profileSettingsLanguageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get profileSettingsLanguageEnglish;

  /// No description provided for @profileSettingsLanguageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get profileSettingsLanguageSpanish;

  /// No description provided for @profileSettingsNewFollowers.
  ///
  /// In es, this message translates to:
  /// **'Nuevos seguidores'**
  String get profileSettingsNewFollowers;

  /// No description provided for @profileSettingsNewFollowersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Notificar cuando alguien te siga'**
  String get profileSettingsNewFollowersSubtitle;

  /// No description provided for @profileSettingsNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get profileSettingsNotificationsTitle;

  /// No description provided for @profileSettingsPrivacyDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Nivel de privacidad'**
  String get profileSettingsPrivacyDialogTitle;

  /// No description provided for @profileSettingsPrivacyFriends.
  ///
  /// In es, this message translates to:
  /// **'Amigos'**
  String get profileSettingsPrivacyFriends;

  /// No description provided for @profileSettingsPrivacyFriendsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Solo tus amigos pueden ver'**
  String get profileSettingsPrivacyFriendsSubtitle;

  /// No description provided for @profileSettingsPrivacyLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel de privacidad'**
  String get profileSettingsPrivacyLevel;

  /// No description provided for @profileSettingsPrivacyPrivate.
  ///
  /// In es, this message translates to:
  /// **'Privado'**
  String get profileSettingsPrivacyPrivate;

  /// No description provided for @profileSettingsPrivacyPrivateSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Solo tú puedes ver'**
  String get profileSettingsPrivacyPrivateSubtitle;

  /// No description provided for @profileSettingsPrivacyPublic.
  ///
  /// In es, this message translates to:
  /// **'Público'**
  String get profileSettingsPrivacyPublic;

  /// No description provided for @profileSettingsPrivacyPublicSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Todos pueden ver tu perfil'**
  String get profileSettingsPrivacyPublicSubtitle;

  /// No description provided for @profileSettingsPrivacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get profileSettingsPrivacyTitle;

  /// No description provided for @profileSettingsPushNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones push'**
  String get profileSettingsPushNotifications;

  /// No description provided for @profileSettingsPushNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recibir notificaciones push en el dispositivo'**
  String get profileSettingsPushNotificationsSubtitle;

  /// No description provided for @profileSettingsSectionAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get profileSettingsSectionAppearance;

  /// No description provided for @profileSettingsSectionNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get profileSettingsSectionNotifications;

  /// No description provided for @profileSettingsSectionPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get profileSettingsSectionPrivacy;

  /// No description provided for @profileSettingsShowActivity.
  ///
  /// In es, this message translates to:
  /// **'Mostrar actividad'**
  String get profileSettingsShowActivity;

  /// No description provided for @profileSettingsShowActivitySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mostrar tu última actividad en el perfil'**
  String get profileSettingsShowActivitySubtitle;

  /// No description provided for @profileSettingsShowEmail.
  ///
  /// In es, this message translates to:
  /// **'Mostrar email'**
  String get profileSettingsShowEmail;

  /// No description provided for @profileSettingsShowEmailSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Permitir que otros usuarios vean tu email'**
  String get profileSettingsShowEmailSubtitle;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get profileSettingsTitle;

  /// No description provided for @profileSettingsUpdateError.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar configuración'**
  String get profileSettingsUpdateError;

  /// No description provided for @profileStatsComments.
  ///
  /// In es, this message translates to:
  /// **'Comentarios'**
  String get profileStatsComments;

  /// No description provided for @profileStatsFollowers.
  ///
  /// In es, this message translates to:
  /// **'Seguidores'**
  String get profileStatsFollowers;

  /// No description provided for @profileStatsFollowing.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo'**
  String get profileStatsFollowing;

  /// No description provided for @profileStatsGossips.
  ///
  /// In es, this message translates to:
  /// **'Chismes'**
  String get profileStatsGossips;

  /// No description provided for @profileStatsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get profileStatsTitle;

  /// No description provided for @searchEmptyState.
  ///
  /// In es, this message translates to:
  /// **'Escribe para buscar chismes 🔎'**
  String get searchEmptyState;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar chismes...'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron chismes 😢'**
  String get searchNoResults;

  /// No description provided for @searchTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar 🔎'**
  String get searchTitle;

  /// No description provided for @authPasswordStrengthWeak.
  ///
  /// In es, this message translates to:
  /// **'Débil'**
  String get authPasswordStrengthWeak;

  /// No description provided for @authPasswordStrengthMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get authPasswordStrengthMedium;

  /// No description provided for @authPasswordStrengthStrong.
  ///
  /// In es, this message translates to:
  /// **'Fuerte'**
  String get authPasswordStrengthStrong;

  /// No description provided for @authPasswordStrengthHintMinLength.
  ///
  /// In es, this message translates to:
  /// **'mínimo 8 caracteres'**
  String get authPasswordStrengthHintMinLength;

  /// No description provided for @authPasswordStrengthHintUppercase.
  ///
  /// In es, this message translates to:
  /// **'una mayúscula'**
  String get authPasswordStrengthHintUppercase;

  /// No description provided for @authPasswordStrengthHintLowercase.
  ///
  /// In es, this message translates to:
  /// **'una minúscula'**
  String get authPasswordStrengthHintLowercase;

  /// No description provided for @authPasswordStrengthHintNumber.
  ///
  /// In es, this message translates to:
  /// **'un número'**
  String get authPasswordStrengthHintNumber;

  /// No description provided for @authPasswordStrengthHintSymbol.
  ///
  /// In es, this message translates to:
  /// **'un símbolo'**
  String get authPasswordStrengthHintSymbol;

  /// Password strength hint with requirements
  ///
  /// In es, this message translates to:
  /// **'Agrega: {hints}'**
  String authPasswordStrengthHintAdd(String hints);

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @signInButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get signInButton;

  /// No description provided for @orContinueWith.
  ///
  /// In es, this message translates to:
  /// **'O continúa con'**
  String get orContinueWith;

  /// No description provided for @noAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get noAccount;

  /// No description provided for @signUpLink.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get signUpLink;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordMessage.
  ///
  /// In es, this message translates to:
  /// **'Te enviaremos un código de 6 dígitos para recuperar tu contraseña'**
  String get forgotPasswordMessage;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get alreadyHaveAccount;

  /// No description provided for @emailHint.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPasswordHint;

  /// No description provided for @changePasswordButton.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePasswordButton;

  /// No description provided for @newPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get newPasswordHint;

  /// No description provided for @otpVerifyEmailTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificar Email'**
  String get otpVerifyEmailTitle;

  /// No description provided for @laterButton.
  ///
  /// In es, this message translates to:
  /// **'Después'**
  String get laterButton;

  /// No description provided for @doItLater.
  ///
  /// In es, this message translates to:
  /// **'Lo haré después'**
  String get doItLater;

  /// No description provided for @displayNameHint.
  ///
  /// In es, this message translates to:
  /// **'Juan Pérez'**
  String get displayNameHint;

  /// No description provided for @bioHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos sobre ti...'**
  String get bioHint;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @forget.
  ///
  /// In es, this message translates to:
  /// **'Olvidar'**
  String get forget;

  /// No description provided for @emailHintPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'tu@email.com'**
  String get emailHintPlaceholder;

  /// No description provided for @continueWithApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get continueWithGoogle;

  /// No description provided for @privacyConsentTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración de Privacidad'**
  String get privacyConsentTitle;

  /// No description provided for @privacyConsentDeclineButton.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get privacyConsentDeclineButton;

  /// No description provided for @privacySettingsPrivacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get privacySettingsPrivacyPolicy;

  /// No description provided for @privacySettingsTermsOfUse.
  ///
  /// In es, this message translates to:
  /// **'Términos de Uso'**
  String get privacySettingsTermsOfUse;

  /// No description provided for @privacySettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get privacySettingsTitle;

  /// No description provided for @privacySettingsSavedCity.
  ///
  /// In es, this message translates to:
  /// **'Ciudad guardada'**
  String get privacySettingsSavedCity;

  /// No description provided for @privacySettingsAnonymousMode.
  ///
  /// In es, this message translates to:
  /// **'Modo anónimo'**
  String get privacySettingsAnonymousMode;

  /// No description provided for @privacySettingsViewMyData.
  ///
  /// In es, this message translates to:
  /// **'Ver mis datos'**
  String get privacySettingsViewMyData;

  /// No description provided for @privacySettingsViewMyDataSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Descarga tus datos personales'**
  String get privacySettingsViewMyDataSubtitle;

  /// No description provided for @locationChangeDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar Ubicación'**
  String get locationChangeDialogTitle;

  /// No description provided for @locationCityHint.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get locationCityHint;

  /// No description provided for @locationCityLabel.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get locationCityLabel;

  /// No description provided for @locationCityRequired.
  ///
  /// In es, this message translates to:
  /// **'La ciudad es requerida'**
  String get locationCityRequired;

  /// No description provided for @locationCountryLabel.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get locationCountryLabel;

  /// No description provided for @locationCountryRequired.
  ///
  /// In es, this message translates to:
  /// **'El país es requerido'**
  String get locationCountryRequired;

  /// No description provided for @locationGpsDetectSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Detectar mi ubicación actual'**
  String get locationGpsDetectSubtitle;

  /// No description provided for @locationOrSelectManually.
  ///
  /// In es, this message translates to:
  /// **'o selecciona manualmente'**
  String get locationOrSelectManually;

  /// No description provided for @locationRegionLabel.
  ///
  /// In es, this message translates to:
  /// **'Región'**
  String get locationRegionLabel;

  /// No description provided for @homePopularLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar chismes populares'**
  String get homePopularLoadError;

  /// No description provided for @gossipDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle del Chisme'**
  String get gossipDetailTitle;

  /// No description provided for @profileSetupTitle.
  ///
  /// In es, this message translates to:
  /// **'Configura tu Perfil'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil para empezar a compartir chismes'**
  String get profileSetupSubtitle;

  /// No description provided for @profileSetupWelcome.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido!'**
  String get profileSetupWelcome;

  /// No description provided for @profileSetupInfoMessage.
  ///
  /// In es, this message translates to:
  /// **'Necesitas un nombre de usuario para publicar chismes'**
  String get profileSetupInfoMessage;

  /// No description provided for @profileSetupUsernameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de usuario'**
  String get profileSetupUsernameLabel;

  /// No description provided for @profileSetupUsernameHelper.
  ///
  /// In es, this message translates to:
  /// **'Solo letras minúsculas, números y _'**
  String get profileSetupUsernameHelper;

  /// No description provided for @profileSetupUsernameAvailabilityCheck.
  ///
  /// In es, this message translates to:
  /// **'Verifica que el nombre de usuario esté disponible'**
  String get profileSetupUsernameAvailabilityCheck;

  /// No description provided for @profileSetupUsernameTaken.
  ///
  /// In es, this message translates to:
  /// **'Este nombre de usuario ya está en uso'**
  String get profileSetupUsernameTaken;

  /// No description provided for @profileSetupDisplayNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre a mostrar'**
  String get profileSetupDisplayNameLabel;

  /// No description provided for @profileSetupBioLabel.
  ///
  /// In es, this message translates to:
  /// **'Biografía (opcional)'**
  String get profileSetupBioLabel;

  /// No description provided for @profileSetupSaveButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar Perfil'**
  String get profileSetupSaveButton;

  /// No description provided for @profileSetupAvatarUploadSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente: subir avatar'**
  String get profileSetupAvatarUploadSoon;

  /// No description provided for @usernameHint.
  ///
  /// In es, this message translates to:
  /// **'juanperez'**
  String get usernameHint;

  /// No description provided for @usernameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario es requerido'**
  String get usernameRequired;

  /// No description provided for @usernameTooShort.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario es muy corto (mínimo 3 caracteres)'**
  String get usernameTooShort;

  /// No description provided for @usernameTooLong.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario es muy largo (máximo 30 caracteres)'**
  String get usernameTooLong;

  /// No description provided for @usernameInvalidChars.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario solo puede contener letras minúsculas, números y guiones bajos'**
  String get usernameInvalidChars;

  /// No description provided for @passwordHint.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordHint;

  /// No description provided for @passwordFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordFieldLabel;

  /// No description provided for @passwordFieldShow.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get passwordFieldShow;

  /// No description provided for @passwordFieldHide.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get passwordFieldHide;

  /// No description provided for @passwordsMustMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas deben coincidir'**
  String get passwordsMustMatch;

  /// No description provided for @passwordUpdatedSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get passwordUpdatedSuccessTitle;

  /// No description provided for @passwordUpdatedSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu contraseña ha sido actualizada exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña'**
  String get passwordUpdatedSuccessMessage;

  /// No description provided for @permanentlyDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar permanentemente'**
  String get permanentlyDelete;

  /// No description provided for @locationRegionRequired.
  ///
  /// In es, this message translates to:
  /// **'La región es requerida'**
  String get locationRegionRequired;

  /// No description provided for @locationSearchError.
  ///
  /// In es, this message translates to:
  /// **'Error al buscar ubicación'**
  String get locationSearchError;

  /// No description provided for @locationUnexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado en ubicación'**
  String get locationUnexpectedError;

  /// No description provided for @locationUseCurrentLocation.
  ///
  /// In es, this message translates to:
  /// **'Usar ubicación actual'**
  String get locationUseCurrentLocation;

  /// No description provided for @privacySettingsAccountDeleted.
  ///
  /// In es, this message translates to:
  /// **'Cuenta eliminada'**
  String get privacySettingsAccountDeleted;

  /// No description provided for @privacySettingsConfirmDeletion.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmas que deseas eliminar tu cuenta?'**
  String get privacySettingsConfirmDeletion;

  /// No description provided for @privacySettingsDeletionCancelled.
  ///
  /// In es, this message translates to:
  /// **'Eliminación cancelada'**
  String get privacySettingsDeletionCancelled;

  /// No description provided for @privacySettingsEraseButton.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get privacySettingsEraseButton;

  /// No description provided for @privacySettingsMyData.
  ///
  /// In es, this message translates to:
  /// **'Mis datos'**
  String get privacySettingsMyData;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu nueva contraseña'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordDescription.
  ///
  /// In es, this message translates to:
  /// **'Debe tener mínimo 8 caracteres'**
  String get resetPasswordDescription;

  /// No description provided for @resetPasswordConfirmHint.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get resetPasswordConfirmHint;

  /// No description provided for @resetPasswordOkButton.
  ///
  /// In es, this message translates to:
  /// **'OK'**
  String get resetPasswordOkButton;

  /// No description provided for @sendCodeButton.
  ///
  /// In es, this message translates to:
  /// **'Enviar código'**
  String get sendCodeButton;

  /// No description provided for @signUpButton.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get signUpButton;

  /// No description provided for @signupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Únete a Chismes'**
  String get signupSubtitle;

  /// No description provided for @signupDescription.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta en segundos'**
  String get signupDescription;

  /// No description provided for @signupTermsMessage.
  ///
  /// In es, this message translates to:
  /// **'Al crear una cuenta, aceptas nuestros Términos y Condiciones y Política de Privacidad'**
  String get signupTermsMessage;

  /// No description provided for @signupPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una contraseña'**
  String get signupPasswordRequired;

  /// No description provided for @signupPasswordMinLength.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get signupPasswordMinLength;

  /// No description provided for @signupPasswordsMustMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get signupPasswordsMustMatch;

  /// No description provided for @signupConfirmPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu contraseña'**
  String get signupConfirmPasswordRequired;

  /// No description provided for @signInLink.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get signInLink;

  /// No results for search query
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para \'{query}\''**
  String locationNoResults(String query);

  /// Search city hint with min chars
  ///
  /// In es, this message translates to:
  /// **'Buscar ciudad (mín. {minChars} caracteres)'**
  String locationCitySearchHint(int minChars);

  /// Minimum characters message
  ///
  /// In es, this message translates to:
  /// **'Escribe al menos {minChars} caracteres para buscar'**
  String locationMinCharsMessage(int minChars);
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
