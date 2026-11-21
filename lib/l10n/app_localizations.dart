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

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'Comparte historias, descubre secretos'**
  String get appTagline;

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

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// Translated from: common.select
  ///
  /// In es, this message translates to:
  /// **'Selecciona {field}'**
  String commonSelect(String field);

  /// No description provided for @errorsAuthEmailAlreadyInUse.
  ///
  /// In es, this message translates to:
  /// **'Este email ya está registrado.'**
  String get errorsAuthEmailAlreadyInUse;

  /// No description provided for @authEmailAlreadyInUseAction.
  ///
  /// In es, this message translates to:
  /// **'Este email ya está registrado. Inicia sesión en su lugar.'**
  String get authEmailAlreadyInUseAction;

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

  /// No description provided for @gossipReportReasonSpam.
  ///
  /// In es, this message translates to:
  /// **'Spam'**
  String get gossipReportReasonSpam;

  /// No description provided for @gossipReportReasonHarassment.
  ///
  /// In es, this message translates to:
  /// **'Acoso o intimidación'**
  String get gossipReportReasonHarassment;

  /// No description provided for @gossipReportReasonViolence.
  ///
  /// In es, this message translates to:
  /// **'Violencia o amenazas'**
  String get gossipReportReasonViolence;

  /// No description provided for @gossipReportReasonSexualContent.
  ///
  /// In es, this message translates to:
  /// **'Contenido sexual'**
  String get gossipReportReasonSexualContent;

  /// No description provided for @gossipReportReasonMisinformation.
  ///
  /// In es, this message translates to:
  /// **'Desinformación'**
  String get gossipReportReasonMisinformation;

  /// No description provided for @gossipReportReasonOther.
  ///
  /// In es, this message translates to:
  /// **'Otro motivo'**
  String get gossipReportReasonOther;

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

  /// Etiqueta de un chisme en tendencia en el feed Popular
  ///
  /// In es, this message translates to:
  /// **'Tendencia'**
  String get homePopularTrendingBadge;

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

  /// No description provided for @profilePrivacySettingsNoLocalData.
  ///
  /// In es, this message translates to:
  /// **'No hay datos guardados localmente'**
  String get profilePrivacySettingsNoLocalData;

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

  /// No description provided for @profileDeleteAccountButton.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get profileDeleteAccountButton;

  /// No description provided for @profileDeleteAccountDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar tu cuenta?'**
  String get profileDeleteAccountDialogTitle;

  /// No description provided for @profileDeleteAccountDialogContent.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán de inmediato y para siempre tu cuenta, tu perfil y todos tus chismes (también los anónimos) con sus fotos. Esto no se puede deshacer.'**
  String get profileDeleteAccountDialogContent;

  /// No description provided for @profileDeleteAccountDialogRetention.
  ///
  /// In es, this message translates to:
  /// **'Si tuviste contenido rechazado por moderación, guardamos solo un registro anónimo de esas faltas para prevenir abusos.'**
  String get profileDeleteAccountDialogRetention;

  /// No description provided for @profileDeleteAccountConfirmWord.
  ///
  /// In es, this message translates to:
  /// **'ELIMINAR'**
  String get profileDeleteAccountConfirmWord;

  /// No description provided for @profileDeleteAccountConfirmLabel.
  ///
  /// In es, this message translates to:
  /// **'Escribe {word} para confirmar'**
  String profileDeleteAccountConfirmLabel(String word);

  /// No description provided for @profileDeleteAccountConfirmButton.
  ///
  /// In es, this message translates to:
  /// **'Eliminar definitivamente'**
  String get profileDeleteAccountConfirmButton;

  /// No description provided for @profileDeleteAccountDeleting.
  ///
  /// In es, this message translates to:
  /// **'Eliminando cuenta...'**
  String get profileDeleteAccountDeleting;

  /// No description provided for @profileDeleteAccountSuccess.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta fue eliminada'**
  String get profileDeleteAccountSuccess;

  /// No description provided for @profileDeleteAccountError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar la cuenta. Revisa tu conexión e inténtalo de nuevo.'**
  String get profileDeleteAccountError;

  /// No description provided for @profileScreenSigningOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrando sesión...'**
  String get profileScreenSigningOut;

  /// No description provided for @profileSignOutError.
  ///
  /// In es, this message translates to:
  /// **'Error al cerrar sesión'**
  String get profileSignOutError;

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

  /// Filter chip label to show only gossips from user's city
  ///
  /// In es, this message translates to:
  /// **'Solo {cityName}'**
  String searchFilterOnlyCity(String cityName);

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

  /// No description provided for @privacyConsentHeader.
  ///
  /// In es, this message translates to:
  /// **'🔒 Tu privacidad es importante'**
  String get privacyConsentHeader;

  /// No description provided for @privacyConsentSubheader.
  ///
  /// In es, this message translates to:
  /// **'Antes de comenzar, queremos que sepas cómo manejamos tus datos.'**
  String get privacyConsentSubheader;

  /// No description provided for @privacyConsentDataCollectedTitle.
  ///
  /// In es, this message translates to:
  /// **'📊 ¿Qué datos recopilamos?'**
  String get privacyConsentDataCollectedTitle;

  /// No description provided for @privacyConsentDataCollectedItem1.
  ///
  /// In es, this message translates to:
  /// **'Tu email y contraseña (encriptada)'**
  String get privacyConsentDataCollectedItem1;

  /// No description provided for @privacyConsentDataCollectedItem2.
  ///
  /// In es, this message translates to:
  /// **'Solo tu ciudad (NO coordenadas exactas)'**
  String get privacyConsentDataCollectedItem2;

  /// No description provided for @privacyConsentDataCollectedItem3.
  ///
  /// In es, this message translates to:
  /// **'Contenido de tus chismes (texto, imagen, audio)'**
  String get privacyConsentDataCollectedItem3;

  /// No description provided for @privacyConsentDataCollectedItem4.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de uso (para mejorar la app)'**
  String get privacyConsentDataCollectedItem4;

  /// No description provided for @privacyConsentDataUsageTitle.
  ///
  /// In es, this message translates to:
  /// **'🎯 ¿Cómo los usamos?'**
  String get privacyConsentDataUsageTitle;

  /// No description provided for @privacyConsentDataUsageItem1.
  ///
  /// In es, this message translates to:
  /// **'Proporcionar el servicio (publicar chismes)'**
  String get privacyConsentDataUsageItem1;

  /// No description provided for @privacyConsentDataUsageItem2.
  ///
  /// In es, this message translates to:
  /// **'Moderar contenido (mantener comunidad segura)'**
  String get privacyConsentDataUsageItem2;

  /// No description provided for @privacyConsentDataUsageItem3.
  ///
  /// In es, this message translates to:
  /// **'Mejorar la app (analizar uso)'**
  String get privacyConsentDataUsageItem3;

  /// No description provided for @privacyConsentModerationTitle.
  ///
  /// In es, this message translates to:
  /// **'🤖 Moderación de contenido'**
  String get privacyConsentModerationTitle;

  /// No description provided for @privacyConsentModerationItem1.
  ///
  /// In es, this message translates to:
  /// **'Usamos OpenAI para analizar texto'**
  String get privacyConsentModerationItem1;

  /// No description provided for @privacyConsentModerationItem2.
  ///
  /// In es, this message translates to:
  /// **'Solo se envía el texto del chisme'**
  String get privacyConsentModerationItem2;

  /// No description provided for @privacyConsentModerationItem3.
  ///
  /// In es, this message translates to:
  /// **'NO enviamos tu nombre, ubicación ni otros datos'**
  String get privacyConsentModerationItem3;

  /// No description provided for @privacyConsentModerationItem4.
  ///
  /// In es, this message translates to:
  /// **'OpenAI retiene el texto por 30 días, luego lo elimina'**
  String get privacyConsentModerationItem4;

  /// No description provided for @privacyConsentModerationItem5.
  ///
  /// In es, this message translates to:
  /// **'NO se usa para entrenar modelos de IA'**
  String get privacyConsentModerationItem5;

  /// No description provided for @privacyConsentLocationTitle.
  ///
  /// In es, this message translates to:
  /// **'📍 Tu ubicación'**
  String get privacyConsentLocationTitle;

  /// No description provided for @privacyConsentLocationItem1.
  ///
  /// In es, this message translates to:
  /// **'Solo detectamos tu ciudad (ej: \"Bogotá\")'**
  String get privacyConsentLocationItem1;

  /// No description provided for @privacyConsentLocationItem2.
  ///
  /// In es, this message translates to:
  /// **'Coordenadas GPS se descartan inmediatamente'**
  String get privacyConsentLocationItem2;

  /// No description provided for @privacyConsentLocationItem3.
  ///
  /// In es, this message translates to:
  /// **'NUNCA almacenamos ni enviamos coordenadas exactas'**
  String get privacyConsentLocationItem3;

  /// No description provided for @privacyConsentLocationItem4.
  ///
  /// In es, this message translates to:
  /// **'Puedes elegir la ciudad manualmente'**
  String get privacyConsentLocationItem4;

  /// No description provided for @privacyConsentRightsTitle.
  ///
  /// In es, this message translates to:
  /// **'✅ Tus derechos'**
  String get privacyConsentRightsTitle;

  /// No description provided for @privacyConsentRightsItem1.
  ///
  /// In es, this message translates to:
  /// **'Acceder a tus datos en cualquier momento'**
  String get privacyConsentRightsItem1;

  /// No description provided for @privacyConsentRightsItem2.
  ///
  /// In es, this message translates to:
  /// **'Eliminar tu cuenta y datos'**
  String get privacyConsentRightsItem2;

  /// No description provided for @privacyConsentRightsItem3.
  ///
  /// In es, this message translates to:
  /// **'Olvidar tu ubicación guardada'**
  String get privacyConsentRightsItem3;

  /// No description provided for @privacyConsentRightsItem4.
  ///
  /// In es, this message translates to:
  /// **'Exportar tus datos (portabilidad)'**
  String get privacyConsentRightsItem4;

  /// No description provided for @privacyConsentCheckboxPrivacy.
  ///
  /// In es, this message translates to:
  /// **'He leído y acepto la '**
  String get privacyConsentCheckboxPrivacy;

  /// No description provided for @privacyConsentCheckboxPrivacyLink.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get privacyConsentCheckboxPrivacyLink;

  /// No description provided for @privacyConsentCheckboxTerms.
  ///
  /// In es, this message translates to:
  /// **'He leído y acepto los '**
  String get privacyConsentCheckboxTerms;

  /// No description provided for @privacyConsentCheckboxTermsLink.
  ///
  /// In es, this message translates to:
  /// **'Términos de Uso'**
  String get privacyConsentCheckboxTermsLink;

  /// No description provided for @privacyConsentCheckboxModeration.
  ///
  /// In es, this message translates to:
  /// **'Acepto que el texto de mis chismes se envíe a '**
  String get privacyConsentCheckboxModeration;

  /// No description provided for @privacyConsentCheckboxModerationBold.
  ///
  /// In es, this message translates to:
  /// **'OpenAI'**
  String get privacyConsentCheckboxModerationBold;

  /// No description provided for @privacyConsentCheckboxModerationSuffix.
  ///
  /// In es, this message translates to:
  /// **' para moderación de contenido (30 días de retención)'**
  String get privacyConsentCheckboxModerationSuffix;

  /// No description provided for @privacyConsentAcceptButton.
  ///
  /// In es, this message translates to:
  /// **'Aceptar y Continuar'**
  String get privacyConsentAcceptButton;

  /// No description provided for @privacyConsentDisclaimer.
  ///
  /// In es, this message translates to:
  /// **'Al continuar, aceptas nuestras políticas'**
  String get privacyConsentDisclaimer;

  /// No description provided for @authOtpResendCode.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get authOtpResendCode;

  /// Resend countdown timer
  ///
  /// In es, this message translates to:
  /// **'Reenviar en {seconds}s'**
  String authOtpResendIn(int seconds);

  /// No description provided for @authOtpHelpText.
  ///
  /// In es, this message translates to:
  /// **'¿No recibiste el código? Revisa tu carpeta de spam o solicita uno nuevo.'**
  String get authOtpHelpText;

  /// No description provided for @authOtpEnterCode.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el código'**
  String get authOtpEnterCode;

  /// No description provided for @authOtpSentCodeTo.
  ///
  /// In es, this message translates to:
  /// **'Enviamos un código de 6 dígitos a:'**
  String get authOtpSentCodeTo;

  /// No description provided for @authOtpCodeMustBe6Digits.
  ///
  /// In es, this message translates to:
  /// **'El código debe tener 6 dígitos'**
  String get authOtpCodeMustBe6Digits;

  /// No description provided for @privacyConsentDialogPrivacyAvailable.
  ///
  /// In es, this message translates to:
  /// **'La política de privacidad completa está disponible en:'**
  String get privacyConsentDialogPrivacyAvailable;

  /// No description provided for @privacyConsentDialogPrivacyUrl.
  ///
  /// In es, this message translates to:
  /// **'https://chismes.app/privacy'**
  String get privacyConsentDialogPrivacyUrl;

  /// No description provided for @privacyConsentDialogPrivacyFile.
  ///
  /// In es, this message translates to:
  /// **'O en el archivo PRIVACY_POLICY.md del proyecto.'**
  String get privacyConsentDialogPrivacyFile;

  /// No description provided for @privacyConsentDialogPrivacySummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen:'**
  String get privacyConsentDialogPrivacySummary;

  /// No description provided for @privacyConsentDialogPrivacyItem1.
  ///
  /// In es, this message translates to:
  /// **'• Solo recopilamos datos necesarios'**
  String get privacyConsentDialogPrivacyItem1;

  /// No description provided for @privacyConsentDialogPrivacyItem2.
  ///
  /// In es, this message translates to:
  /// **'• No vendemos tus datos'**
  String get privacyConsentDialogPrivacyItem2;

  /// No description provided for @privacyConsentDialogPrivacyItem3.
  ///
  /// In es, this message translates to:
  /// **'• Puedes eliminar tu cuenta en cualquier momento'**
  String get privacyConsentDialogPrivacyItem3;

  /// No description provided for @privacyConsentDialogTermsAvailable.
  ///
  /// In es, this message translates to:
  /// **'Los términos de uso completos están disponibles en:'**
  String get privacyConsentDialogTermsAvailable;

  /// No description provided for @privacyConsentDialogTermsUrl.
  ///
  /// In es, this message translates to:
  /// **'https://chismes.app/terms'**
  String get privacyConsentDialogTermsUrl;

  /// No description provided for @privacyConsentDialogTermsFile.
  ///
  /// In es, this message translates to:
  /// **'O en el archivo TERMS_OF_SERVICE.md del proyecto.'**
  String get privacyConsentDialogTermsFile;

  /// No description provided for @privacyConsentDialogTermsSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen:'**
  String get privacyConsentDialogTermsSummary;

  /// No description provided for @privacyConsentDialogTermsItem1.
  ///
  /// In es, this message translates to:
  /// **'• Edad mínima: 13 años'**
  String get privacyConsentDialogTermsItem1;

  /// No description provided for @privacyConsentDialogTermsItem2.
  ///
  /// In es, this message translates to:
  /// **'• No publicar contenido inapropiado'**
  String get privacyConsentDialogTermsItem2;

  /// No description provided for @privacyConsentDialogTermsItem3.
  ///
  /// In es, this message translates to:
  /// **'• Moderación automática + manual'**
  String get privacyConsentDialogTermsItem3;

  /// No description provided for @privacyConsentDialogTermsItem4.
  ///
  /// In es, this message translates to:
  /// **'• Podemos suspender cuentas que violen normas'**
  String get privacyConsentDialogTermsItem4;

  /// No description provided for @searchRecentSearches.
  ///
  /// In es, this message translates to:
  /// **'Búsquedas recientes'**
  String get searchRecentSearches;

  /// No description provided for @searchTryOtherWords.
  ///
  /// In es, this message translates to:
  /// **'Intenta con otras palabras'**
  String get searchTryOtherWords;

  /// No description provided for @searchByTopic.
  ///
  /// In es, this message translates to:
  /// **'Busca chismes por tema'**
  String get searchByTopic;

  /// No description provided for @searchByKeyword.
  ///
  /// In es, this message translates to:
  /// **'o palabra clave'**
  String get searchByKeyword;

  /// No description provided for @searchRecent.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get searchRecent;

  /// No description provided for @searchClearAll.
  ///
  /// In es, this message translates to:
  /// **'Borrar todo'**
  String get searchClearAll;

  /// Search results count with ICU plural
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin resultados} =1{1 resultado} other{{count} resultados}}'**
  String searchResultsCount(int count);

  /// New gossips banner with ICU plural
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 nuevo chisme · Toca aquí} other{{count} nuevos chismes · Toca aquí}}'**
  String homeNewGossipsBanner(int count);

  /// Opening gossip via deep link
  ///
  /// In es, this message translates to:
  /// **'Abriendo chisme: {gossipId}'**
  String deepLinkOpeningGossip(String gossipId);

  /// Opening profile via deep link
  ///
  /// In es, this message translates to:
  /// **'Abriendo perfil: {userId}'**
  String deepLinkOpeningProfile(String userId);

  /// Opening city feed via deep link
  ///
  /// In es, this message translates to:
  /// **'Abriendo feed de ciudad: {cityId}'**
  String deepLinkOpeningCityFeed(String cityId);

  /// No description provided for @locationErrorLoadCountries.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar países'**
  String get locationErrorLoadCountries;

  /// No description provided for @locationErrorLoadRegions.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar regiones'**
  String get locationErrorLoadRegions;

  /// No description provided for @locationErrorLoadCities.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar ciudades'**
  String get locationErrorLoadCities;

  /// No description provided for @locationErrorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado'**
  String get locationErrorUnexpected;

  /// No description provided for @locationErrorGpsPosition.
  ///
  /// In es, this message translates to:
  /// **'No se pudo detectar ubicación. Activa GPS e intenta de nuevo.'**
  String get locationErrorGpsPosition;

  /// No description provided for @locationErrorGeocoding.
  ///
  /// In es, this message translates to:
  /// **'No se pudo identificar la ubicación'**
  String get locationErrorGeocoding;

  /// Error when detected country is not in database
  ///
  /// In es, this message translates to:
  /// **'País \"{entityName}\" no disponible. Selecciona manualmente.'**
  String locationErrorCountryNotAvailable(String entityName);

  /// Error when detected region is not in database
  ///
  /// In es, this message translates to:
  /// **'Región \"{entityName}\" no disponible. Selecciona manualmente.'**
  String locationErrorRegionNotAvailable(String entityName);

  /// Error when detected city is not in database
  ///
  /// In es, this message translates to:
  /// **'Ciudad \"{entityName}\" no disponible. Selecciona manualmente.'**
  String locationErrorCityNotAvailable(String entityName);

  /// No description provided for @locationErrorDetection.
  ///
  /// In es, this message translates to:
  /// **'Error al detectar ubicación. Intenta de nuevo.'**
  String get locationErrorDetection;

  /// No description provided for @moderationEntryTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de moderación'**
  String get moderationEntryTitle;

  /// No description provided for @moderationEntrySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa el contenido pendiente'**
  String get moderationEntrySubtitle;

  /// No description provided for @moderationTitle.
  ///
  /// In es, this message translates to:
  /// **'Moderación'**
  String get moderationTitle;

  /// No description provided for @moderationTabPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get moderationTabPending;

  /// No description provided for @moderationTabApproved.
  ///
  /// In es, this message translates to:
  /// **'Aprobados'**
  String get moderationTabApproved;

  /// No description provided for @moderationTabRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazados'**
  String get moderationTabRejected;

  /// No description provided for @moderationEmptyPending.
  ///
  /// In es, this message translates to:
  /// **'No hay nada pendiente'**
  String get moderationEmptyPending;

  /// No description provided for @moderationEmptyPendingHint.
  ///
  /// In es, this message translates to:
  /// **'Lo que la IA o los reportes manden a revisión aparecerá aquí'**
  String get moderationEmptyPendingHint;

  /// No description provided for @moderationEmptyHistory.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay decisiones aquí'**
  String get moderationEmptyHistory;

  /// No description provided for @moderationLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la cola'**
  String get moderationLoadError;

  /// No description provided for @moderationForbidden.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta no tiene permisos de moderación'**
  String get moderationForbidden;

  /// No description provided for @moderationHighPriority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad alta'**
  String get moderationHighPriority;

  /// No description provided for @moderationSourceAiReview.
  ///
  /// In es, this message translates to:
  /// **'IA'**
  String get moderationSourceAiReview;

  /// No description provided for @moderationSourceAiUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Sin veredicto automático'**
  String get moderationSourceAiUnavailable;

  /// No description provided for @moderationSourceReports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get moderationSourceReports;

  /// No description provided for @moderationReportCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 reporte} other{{count} reportes}}'**
  String moderationReportCount(int count);

  /// No description provided for @moderationInteractions.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 interacción} other{{count} interacciones}}'**
  String moderationInteractions(int count);

  /// No description provided for @moderationAutoHidden.
  ///
  /// In es, this message translates to:
  /// **'Oculto por reportes'**
  String get moderationAutoHidden;

  /// No description provided for @moderationAuthorLabel.
  ///
  /// In es, this message translates to:
  /// **'Autor'**
  String get moderationAuthorLabel;

  /// No description provided for @moderationAuthorNoName.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre de perfil'**
  String get moderationAuthorNoName;

  /// No description provided for @moderationAnonymousAuthor.
  ///
  /// In es, this message translates to:
  /// **'Publicado como anónimo: solo moderación ve el autor'**
  String get moderationAnonymousAuthor;

  /// No description provided for @moderationReasonsTitle.
  ///
  /// In es, this message translates to:
  /// **'Por qué está aquí'**
  String get moderationReasonsTitle;

  /// No description provided for @moderationHasAudio.
  ///
  /// In es, this message translates to:
  /// **'Tiene audio (todavía no se puede escuchar aquí)'**
  String get moderationHasAudio;

  /// No description provided for @moderationImageUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la imagen'**
  String get moderationImageUnavailable;

  /// No description provided for @moderationQueuedAt.
  ///
  /// In es, this message translates to:
  /// **'En la cola desde {date}'**
  String moderationQueuedAt(String date);

  /// No description provided for @moderationDecidedAt.
  ///
  /// In es, this message translates to:
  /// **'Decidido el {date}'**
  String moderationDecidedAt(String date);

  /// No description provided for @moderationDecisionTitle.
  ///
  /// In es, this message translates to:
  /// **'Decisión'**
  String get moderationDecisionTitle;

  /// No description provided for @moderationNoteTitle.
  ///
  /// In es, this message translates to:
  /// **'Nota interna'**
  String get moderationNoteTitle;

  /// No description provided for @moderationApprove.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get moderationApprove;

  /// No description provided for @moderationReject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get moderationReject;

  /// No description provided for @moderationApproveConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Aprobar y publicar?'**
  String get moderationApproveConfirmTitle;

  /// No description provided for @moderationApproveConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'El chisme quedará visible para todos.'**
  String get moderationApproveConfirmBody;

  /// No description provided for @moderationApprovedMessage.
  ///
  /// In es, this message translates to:
  /// **'Aprobado y publicado'**
  String get moderationApprovedMessage;

  /// No description provided for @moderationRejectedMessage.
  ///
  /// In es, this message translates to:
  /// **'Rechazado: el chisme quedó oculto'**
  String get moderationRejectedMessage;

  /// No description provided for @moderationAlreadyDecided.
  ///
  /// In es, this message translates to:
  /// **'Ya no está pendiente: otro moderador lo decidió'**
  String get moderationAlreadyDecided;

  /// No description provided for @moderationDecisionError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo aplicar la decisión. Intenta de nuevo.'**
  String get moderationDecisionError;

  /// No description provided for @moderationRejectTitle.
  ///
  /// In es, this message translates to:
  /// **'Rechazar contenido'**
  String get moderationRejectTitle;

  /// No description provided for @moderationRejectHint.
  ///
  /// In es, this message translates to:
  /// **'Se oculta, no se borra: queda para una apelación.'**
  String get moderationRejectHint;

  /// No description provided for @moderationSeverityLabel.
  ///
  /// In es, this message translates to:
  /// **'Gravedad'**
  String get moderationSeverityLabel;

  /// No description provided for @moderationSeverityLow.
  ///
  /// In es, this message translates to:
  /// **'Leve'**
  String get moderationSeverityLow;

  /// No description provided for @moderationSeverityMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get moderationSeverityMedium;

  /// No description provided for @moderationSeverityHigh.
  ///
  /// In es, this message translates to:
  /// **'Grave'**
  String get moderationSeverityHigh;

  /// No description provided for @moderationSeverityCritical.
  ///
  /// In es, this message translates to:
  /// **'Crítica'**
  String get moderationSeverityCritical;

  /// No description provided for @moderationRejectReasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get moderationRejectReasonLabel;

  /// No description provided for @moderationRejectReasonHate.
  ///
  /// In es, this message translates to:
  /// **'Odio o discriminación'**
  String get moderationRejectReasonHate;

  /// No description provided for @moderationRejectReasonPersonalData.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get moderationRejectReasonPersonalData;

  /// No description provided for @moderationNoteLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota interna (opcional)'**
  String get moderationNoteLabel;

  /// No description provided for @moderationNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Contexto para otros moderadores'**
  String get moderationNoteHint;

  /// No description provided for @moderationReasonAiUnavailable.
  ///
  /// In es, this message translates to:
  /// **'La IA no respondió'**
  String get moderationReasonAiUnavailable;

  /// No description provided for @moderationReasonRulesUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron leer las reglas'**
  String get moderationReasonRulesUnavailable;

  /// No description provided for @moderationReasonPersonalData.
  ///
  /// In es, this message translates to:
  /// **'Posibles datos personales'**
  String get moderationReasonPersonalData;

  /// No description provided for @moderationReasonSpam.
  ///
  /// In es, this message translates to:
  /// **'Posible spam o links'**
  String get moderationReasonSpam;

  /// No description provided for @moderationReasonThreat.
  ///
  /// In es, this message translates to:
  /// **'Posible amenaza'**
  String get moderationReasonThreat;

  /// No description provided for @moderationReasonAudio.
  ///
  /// In es, this message translates to:
  /// **'Audio sin moderar'**
  String get moderationReasonAudio;

  /// No description provided for @moderationReasonTerm.
  ///
  /// In es, this message translates to:
  /// **'Término: {term}'**
  String moderationReasonTerm(String term);

  /// No description provided for @moderationReasonAiScore.
  ///
  /// In es, this message translates to:
  /// **'IA: {category}'**
  String moderationReasonAiScore(String category);

  /// No description provided for @errorsAccountRestricted.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta no puede publicar ni reportar por ahora. Revisa Perfil → Estado de la cuenta.'**
  String get errorsAccountRestricted;

  /// No description provided for @errorsAccountSuspended.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está suspendida: no puede publicar ni reportar. Puedes apelar en Perfil → Estado de la cuenta.'**
  String get errorsAccountSuspended;

  /// No description provided for @errorsAccountRestrictedUntil.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta no puede publicar ni reportar hasta el {date}. Revisa Perfil → Estado de la cuenta.'**
  String errorsAccountRestrictedUntil(String date);

  /// No description provided for @accountStatusEntryTitle.
  ///
  /// In es, this message translates to:
  /// **'Estado de la cuenta'**
  String get accountStatusEntryTitle;

  /// No description provided for @accountStatusEntrySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Faltas, sanciones y apelaciones'**
  String get accountStatusEntrySubtitle;

  /// No description provided for @accountStatusTitle.
  ///
  /// In es, this message translates to:
  /// **'Estado de la cuenta'**
  String get accountStatusTitle;

  /// No description provided for @accountStatusLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el estado de tu cuenta'**
  String get accountStatusLoadError;

  /// No description provided for @accountStatusOkTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está en orden'**
  String get accountStatusOkTitle;

  /// No description provided for @accountStatusOkBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes publicar y reportar con normalidad.'**
  String get accountStatusOkBody;

  /// No description provided for @accountStatusRestrictedTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin publicar hasta el {date}'**
  String accountStatusRestrictedTitle(String date);

  /// No description provided for @accountStatusRestrictedTitleNoDate.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está restringida'**
  String get accountStatusRestrictedTitleNoDate;

  /// No description provided for @accountStatusRestrictedBody.
  ///
  /// In es, this message translates to:
  /// **'Por tus faltas recientes no puedes publicar ni reportar por un tiempo. Puedes seguir leyendo.'**
  String get accountStatusRestrictedBody;

  /// No description provided for @accountStatusSuspendedTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está suspendida'**
  String get accountStatusSuspendedTitle;

  /// No description provided for @accountStatusSuspendedBody.
  ///
  /// In es, this message translates to:
  /// **'No puedes publicar ni reportar. Si crees que fue un error, apela el contenido rechazado.'**
  String get accountStatusSuspendedBody;

  /// No description provided for @accountStatusPendingAppeal.
  ///
  /// In es, this message translates to:
  /// **'Tienes una apelación en revisión.'**
  String get accountStatusPendingAppeal;

  /// No description provided for @accountStatusPointsTitle.
  ///
  /// In es, this message translates to:
  /// **'Puntos de faltas'**
  String get accountStatusPointsTitle;

  /// No description provided for @accountStatusPointsValue.
  ///
  /// In es, this message translates to:
  /// **'{points} de {limit}'**
  String accountStatusPointsValue(int points, int limit);

  /// No description provided for @accountStatusPointsExplanation.
  ///
  /// In es, this message translates to:
  /// **'Con {short} puntos tu cuenta se restringe por un tiempo, con {long} por más tiempo y con {suspension} se suspende. Los puntos de cada falta vencen a los {days} días.'**
  String accountStatusPointsExplanation(
    int short,
    int long,
    int suspension,
    int days,
  );

  /// No description provided for @accountStatusInheritedTitle.
  ///
  /// In es, this message translates to:
  /// **'Faltas de una cuenta anterior'**
  String get accountStatusInheritedTitle;

  /// No description provided for @accountStatusInheritedBody.
  ///
  /// In es, this message translates to:
  /// **'Una cuenta eliminada con tu email tenía faltas: {points} puntos, vigentes hasta el {date}.'**
  String accountStatusInheritedBody(int points, String date);

  /// No description provided for @accountStatusRejectionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Contenido rechazado'**
  String get accountStatusRejectionsTitle;

  /// No description provided for @accountStatusNoRejections.
  ///
  /// In es, this message translates to:
  /// **'No tienes contenido rechazado.'**
  String get accountStatusNoRejections;

  /// No description provided for @accountStatusSanctionWarning.
  ///
  /// In es, this message translates to:
  /// **'Advertencia'**
  String get accountStatusSanctionWarning;

  /// No description provided for @accountStatusSanctionRestriction.
  ///
  /// In es, this message translates to:
  /// **'Restricción'**
  String get accountStatusSanctionRestriction;

  /// No description provided for @accountStatusSanctionSuspension.
  ///
  /// In es, this message translates to:
  /// **'Suspensión'**
  String get accountStatusSanctionSuspension;

  /// No description provided for @accountStatusOverturned.
  ///
  /// In es, this message translates to:
  /// **'Anulado por apelación'**
  String get accountStatusOverturned;

  /// No description provided for @accountStatusRejectedOn.
  ///
  /// In es, this message translates to:
  /// **'Rechazado el {date}'**
  String accountStatusRejectedOn(String date);

  /// No description provided for @accountStatusPointsUntil.
  ///
  /// In es, this message translates to:
  /// **'{points, plural, =1{1 punto} other{{points} puntos}} hasta el {date}'**
  String accountStatusPointsUntil(int points, String date);

  /// No description provided for @accountStatusAppealUntil.
  ///
  /// In es, this message translates to:
  /// **'Puedes apelar hasta el {date}'**
  String accountStatusAppealUntil(String date);

  /// No description provided for @accountStatusAppealClosed.
  ///
  /// In es, this message translates to:
  /// **'El plazo para apelar venció'**
  String get accountStatusAppealClosed;

  /// No description provided for @appealButton.
  ///
  /// In es, this message translates to:
  /// **'Apelar'**
  String get appealButton;

  /// No description provided for @appealSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Apelar el rechazo'**
  String get appealSheetTitle;

  /// No description provided for @appealSheetHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos por qué crees que fue un error. Lo revisará una persona del equipo de moderación. Solo puedes apelar una vez.'**
  String get appealSheetHint;

  /// No description provided for @appealMessageLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu apelación'**
  String get appealMessageLabel;

  /// No description provided for @appealMessageHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: era un chiste entre amigos, no un insulto'**
  String get appealMessageHint;

  /// No description provided for @appealSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar apelación'**
  String get appealSubmit;

  /// No description provided for @appealSentMessage.
  ///
  /// In es, this message translates to:
  /// **'Apelación enviada. Te avisaremos aquí cuando se revise.'**
  String get appealSentMessage;

  /// No description provided for @appealNotAllowedMessage.
  ///
  /// In es, this message translates to:
  /// **'Este rechazo ya no se puede apelar'**
  String get appealNotAllowedMessage;

  /// No description provided for @appealErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar la apelación'**
  String get appealErrorMessage;

  /// No description provided for @appealStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Apelación en revisión'**
  String get appealStatusPending;

  /// No description provided for @appealStatusAccepted.
  ///
  /// In es, this message translates to:
  /// **'Apelación aceptada'**
  String get appealStatusAccepted;

  /// No description provided for @appealStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'Apelación rechazada'**
  String get appealStatusRejected;

  /// No description provided for @appealFilterAccepted.
  ///
  /// In es, this message translates to:
  /// **'Aceptadas'**
  String get appealFilterAccepted;

  /// No description provided for @appealFilterRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazadas'**
  String get appealFilterRejected;

  /// No description provided for @moderationTabAppeals.
  ///
  /// In es, this message translates to:
  /// **'Apelaciones'**
  String get moderationTabAppeals;

  /// No description provided for @appealsEmptyPending.
  ///
  /// In es, this message translates to:
  /// **'No hay apelaciones pendientes'**
  String get appealsEmptyPending;

  /// No description provided for @appealDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Apelación'**
  String get appealDetailTitle;

  /// No description provided for @appealUserMessageTitle.
  ///
  /// In es, this message translates to:
  /// **'Lo que dice el usuario'**
  String get appealUserMessageTitle;

  /// No description provided for @appealSentAt.
  ///
  /// In es, this message translates to:
  /// **'Enviada el {date}'**
  String appealSentAt(String date);

  /// No description provided for @appealOriginalDecisionTitle.
  ///
  /// In es, this message translates to:
  /// **'Rechazo original'**
  String get appealOriginalDecisionTitle;

  /// No description provided for @appealDecisionTitle.
  ///
  /// In es, this message translates to:
  /// **'Decisión de la apelación'**
  String get appealDecisionTitle;

  /// No description provided for @appealAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar apelación'**
  String get appealAccept;

  /// No description provided for @appealReject.
  ///
  /// In es, this message translates to:
  /// **'Mantener rechazo'**
  String get appealReject;

  /// No description provided for @appealAcceptConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Aceptar la apelación?'**
  String get appealAcceptConfirmTitle;

  /// No description provided for @appealAcceptConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Se anula la falta (la sanción se recalcula) y el texto vuelve a publicarse. La imagen o el audio no vuelven: se borraron al rechazarlo.'**
  String get appealAcceptConfirmBody;

  /// No description provided for @appealRejectConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Mantener el rechazo?'**
  String get appealRejectConfirmTitle;

  /// No description provided for @appealRejectConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'La falta sigue contando. El usuario no puede volver a apelar este contenido.'**
  String get appealRejectConfirmBody;

  /// No description provided for @appealAcceptedMessage.
  ///
  /// In es, this message translates to:
  /// **'Apelación aceptada: falta anulada'**
  String get appealAcceptedMessage;

  /// No description provided for @appealRejectedMessage.
  ///
  /// In es, this message translates to:
  /// **'Rechazo mantenido'**
  String get appealRejectedMessage;

  /// No description provided for @appealAlreadyDecided.
  ///
  /// In es, this message translates to:
  /// **'Otro moderador ya decidió esta apelación'**
  String get appealAlreadyDecided;

  /// No description provided for @appealNeedsAnotherModerator.
  ///
  /// In es, this message translates to:
  /// **'Esta apelación la debe revisar otro moderador (tú hiciste el rechazo)'**
  String get appealNeedsAnotherModerator;
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
