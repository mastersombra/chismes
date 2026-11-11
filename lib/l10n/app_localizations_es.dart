// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Chismes';

  @override
  String get appTagline => 'Comparte historias, descubre secretos';

  @override
  String get authErrorsEmailAlreadyInUse => 'El email ya está en uso';

  @override
  String get authErrorsInvalidCredentials => 'Credenciales inválidas';

  @override
  String get authErrorsNetworkError => 'Error de conexión';

  @override
  String get authErrorsUnknownError => 'Error desconocido';

  @override
  String get authErrorsUserNotFound => 'Usuario no encontrado';

  @override
  String get authErrorsWeakPassword => 'La contraseña es muy débil';

  @override
  String get authForgotPasswordCodeSentMessage =>
      'Revisa tu email para obtener el código de verificación';

  @override
  String get authForgotPasswordCodeSentTitle => 'Código enviado';

  @override
  String get authForgotPasswordEmailHint => 'Correo electrónico';

  @override
  String get authForgotPasswordMessage =>
      'Te enviaremos un código de 6 dígitos para recuperar tu contraseña';

  @override
  String get authForgotPasswordSendCodeButton => 'Enviar código';

  @override
  String get authForgotPasswordTitle => '¿Olvidaste tu contraseña?';

  @override
  String get authLoginContinueWithApple => 'Continuar con Apple';

  @override
  String get authLoginContinueWithGoogle => 'Continuar con Google';

  @override
  String get authLoginEmailHint => 'Correo electrónico';

  @override
  String get authLoginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authLoginNoAccount => '¿No tienes cuenta?';

  @override
  String get authLoginOrContinueWith => 'O continúa con';

  @override
  String get authLoginPasswordHint => 'Contraseña';

  @override
  String get authLoginSignInButton => 'Iniciar Sesión';

  @override
  String get authLoginSignUpLink => 'Regístrate';

  @override
  String get authLoginTitle => 'Iniciar Sesión';

  @override
  String get authOtpVerificationCodeHint => 'Código';

  @override
  String get authOtpVerificationResendButton => 'Reenviar';

  @override
  String get authOtpVerificationResendLabel => '¿No recibiste el código?';

  @override
  String authOtpVerificationResendTimer(String seconds) {
    return 'Reenviar (${seconds}s)';
  }

  @override
  String get authOtpVerificationSubtitleReset =>
      'Ingresa el código que enviamos a:';

  @override
  String get authOtpVerificationSubtitleSignup =>
      'Enviamos un código de 6 dígitos a:';

  @override
  String get authOtpVerificationTitle => 'Verificar Código';

  @override
  String get authOtpVerificationVerifyEmailTitle => 'Verificar Email';

  @override
  String get authOtpVerificationVerifying => 'Verificando...';

  @override
  String get authPasswordFieldHide => 'Ocultar contraseña';

  @override
  String get authPasswordFieldLabel => 'Contraseña';

  @override
  String get authPasswordFieldShow => 'Mostrar contraseña';

  @override
  String get authProfileSetupAvatarUploadSoon => 'Próximamente: subir avatar';

  @override
  String get authProfileSetupBioHint => 'Cuéntanos sobre ti...';

  @override
  String get authProfileSetupBioLabel => 'Biografía (opcional)';

  @override
  String get authProfileSetupCompleteButton => 'Completar perfil';

  @override
  String get authProfileSetupDisplayNameHint => 'Juan Pérez';

  @override
  String get authProfileSetupDisplayNameLabel => 'Nombre a mostrar';

  @override
  String get authProfileSetupDoItLater => 'Lo haré después';

  @override
  String get authProfileSetupInfoMessage =>
      'Necesitas un nombre de usuario para publicar chismes';

  @override
  String get authProfileSetupLaterButton => 'Después';

  @override
  String get authProfileSetupSaveButton => 'Guardar Perfil';

  @override
  String get authProfileSetupSubtitle =>
      'Completa tu perfil para empezar a compartir chismes';

  @override
  String get authProfileSetupTitle => 'Configura tu Perfil';

  @override
  String get authProfileSetupUsernameAvailabilityCheck =>
      'Verifica que el nombre de usuario esté disponible';

  @override
  String get authProfileSetupUsernameHelper =>
      'Solo letras minúsculas, números y _';

  @override
  String get authProfileSetupUsernameHint => 'juanperez';

  @override
  String get authProfileSetupUsernameLabel => 'Nombre de usuario';

  @override
  String get authProfileSetupUsernameTaken =>
      'Este nombre de usuario ya está en uso';

  @override
  String get authProfileSetupWelcome => '¡Bienvenido!';

  @override
  String get authResetPasswordChangePasswordButton => 'Cambiar contraseña';

  @override
  String get authResetPasswordConfirmPasswordHint => 'Confirmar contraseña';

  @override
  String get authResetPasswordDescription => 'Debe tener mínimo 8 caracteres';

  @override
  String get authResetPasswordNewPasswordHint => 'Nueva contraseña';

  @override
  String get authResetPasswordOkButton => 'OK';

  @override
  String get authResetPasswordSubtitle => 'Crea tu nueva contraseña';

  @override
  String get authResetPasswordSuccessMessage =>
      'Tu contraseña ha sido actualizada exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña';

  @override
  String get authResetPasswordSuccessTitle => 'Contraseña actualizada';

  @override
  String get authResetPasswordTitle => 'Nueva Contraseña';

  @override
  String get authSignupAlreadyHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authSignupConfirmPasswordHint => 'Confirmar contraseña';

  @override
  String get authSignupConfirmPasswordRequired => 'Confirma tu contraseña';

  @override
  String get authSignupDescription => 'Crea tu cuenta en segundos';

  @override
  String get authSignupEmailHint => 'Correo electrónico';

  @override
  String get authSignupPasswordHint => 'Contraseña';

  @override
  String get authSignupPasswordMinLength => 'Mínimo 8 caracteres';

  @override
  String get authSignupPasswordRequired => 'Ingresa una contraseña';

  @override
  String get authSignupPasswordsMustMatch => 'Las contraseñas no coinciden';

  @override
  String get authSignupSignInLink => 'Inicia sesión';

  @override
  String get authSignupSignUpButton => 'Crear Cuenta';

  @override
  String get authSignupSubtitle => 'Únete a Chismes';

  @override
  String get authSignupTermsMessage =>
      'Al crear una cuenta, aceptas nuestros Términos y Condiciones y Política de Privacidad';

  @override
  String get authSignupTitle => 'Crear Cuenta';

  @override
  String get authValidationBioTooLong =>
      'La biografía es muy larga (máximo 160 caracteres)';

  @override
  String get authValidationDisplayNameEmpty =>
      'El nombre a mostrar no puede estar vacío';

  @override
  String get authValidationDisplayNameRequired =>
      'El nombre a mostrar es requerido';

  @override
  String get authValidationDisplayNameTooLong =>
      'El nombre a mostrar es muy largo (máximo 50 caracteres)';

  @override
  String get authValidationEmailInvalid => 'El formato del email es inválido';

  @override
  String get authValidationEmailRequired => 'El email es requerido';

  @override
  String get authValidationEmailTooLong =>
      'El email es muy largo (máximo 254 caracteres)';

  @override
  String get authValidationPasswordNeedsLowercase =>
      'La contraseña debe contener al menos una letra minúscula';

  @override
  String get authValidationPasswordNeedsNumber =>
      'La contraseña debe contener al menos un número';

  @override
  String get authValidationPasswordNeedsSpecial =>
      'La contraseña debe contener al menos un carácter especial';

  @override
  String get authValidationPasswordNeedsUppercase =>
      'La contraseña debe contener al menos una letra mayúscula';

  @override
  String get authValidationPasswordRequired => 'La contraseña es requerida';

  @override
  String get authValidationPasswordTooLong =>
      'La contraseña es muy larga (máximo 128 caracteres)';

  @override
  String get authValidationPasswordTooShort =>
      'La contraseña es muy corta (mínimo 8 caracteres)';

  @override
  String get authValidationPasswordsMustMatch =>
      'Las contraseñas deben coincidir';

  @override
  String get authValidationUsernameInvalidChars =>
      'El nombre de usuario solo puede contener letras minúsculas, números y guiones bajos';

  @override
  String get authValidationUsernameInvalidUnderscore =>
      'El nombre de usuario no puede empezar o terminar con guión bajo';

  @override
  String get authValidationUsernameRequired =>
      'El nombre de usuario es requerido';

  @override
  String get authValidationUsernameReserved =>
      'El nombre de usuario está reservado';

  @override
  String get authValidationUsernameStartsWithNumber =>
      'El nombre de usuario no puede empezar con un número';

  @override
  String get authValidationUsernameTooLong =>
      'El nombre de usuario es muy largo (máximo 30 caracteres)';

  @override
  String get authValidationUsernameTooShort =>
      'El nombre de usuario es muy corto (mínimo 3 caracteres)';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonEmailHintPlaceholder => 'tu@email.com';

  @override
  String get commonEmailInvalid => 'Email inválido';

  @override
  String get commonEnterEmail => 'Ingresa un email';

  @override
  String get commonEnterPassword => 'Ingresa tu contraseña';

  @override
  String get commonError => 'Error';

  @override
  String get commonForget => 'Olvidar';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String commonMaxLength(String count) {
    return 'No puede exceder $count caracteres';
  }

  @override
  String commonMinLength(String count) {
    return 'Debe tener al menos $count caracteres';
  }

  @override
  String get commonPermanentlyDelete => 'Eliminar permanentemente';

  @override
  String get commonRequiredField => 'Campo requerido';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSave => 'Guardar';

  @override
  String commonSelect(String field) {
    return 'Selecciona $field';
  }

  @override
  String get commonSuccess => 'Éxito';

  @override
  String get errorsAuthEmailAlreadyInUse => 'Este email ya está registrado.';

  @override
  String get errorsAuthEmailNotVerified =>
      'Debes verificar tu email para continuar.';

  @override
  String get errorsAuthExpiredToken =>
      'Código inválido o expirado. Solicita uno nuevo.';

  @override
  String get errorsAuthInvalidCredentials =>
      'Email o contraseña incorrectos. Por favor, verifica tus datos e intenta nuevamente.';

  @override
  String get errorsAuthInvalidToken =>
      'Código inválido o expirado. Solicita uno nuevo.';

  @override
  String get errorsAuthNotAuthenticated =>
      'Debes iniciar sesión para continuar.';

  @override
  String get errorsAuthOauthCancelled => 'Inicio de sesión cancelado.';

  @override
  String get errorsAuthOauthProviderError =>
      'Error al iniciar sesión con el proveedor.';

  @override
  String get errorsAuthSessionExpired =>
      'Tu sesión ha expirado. Inicia sesión nuevamente.';

  @override
  String get errorsAuthTooManyAttempts =>
      'Demasiados intentos. Intenta más tarde.';

  @override
  String get errorsAuthUnauthorized =>
      'No estás autorizado para realizar esta acción.';

  @override
  String get errorsAuthUserNotFound => 'Usuario no encontrado.';

  @override
  String get errorsAuthUsernameTaken =>
      'Este nombre de usuario ya está en uso.';

  @override
  String get errorsAuthWeakPassword => 'La contraseña es muy débil.';

  @override
  String get errorsBusinessGossipNotFound =>
      'El chisme no existe o fue eliminado.';

  @override
  String get errorsBusinessInvalidGossipContent =>
      'El contenido del chisme es inválido.';

  @override
  String get errorsBusinessInvalidLocation =>
      'Ubicación inválida. Selecciona una ubicación válida.';

  @override
  String get errorsBusinessMediaUploadFailed =>
      'No se pudo subir la imagen. Por favor intenta de nuevo o intenta con otra imagen.';

  @override
  String get errorsBusinessModerationRejected =>
      'El contenido no cumple con nuestras normas de comunidad. Por favor revisa el contenido e intenta nuevamente.';

  @override
  String get errorsBusinessRateLimitExceeded =>
      'Has alcanzado el límite de solicitudes. Espera un momento e intenta de nuevo.';

  @override
  String get errorsDataAlreadyExists => 'El recurso ya existe.';

  @override
  String get errorsDataConflict => 'Conflicto de datos. Intenta nuevamente.';

  @override
  String get errorsDataNotFound => 'El recurso solicitado no existe.';

  @override
  String get errorsNetworkConnectionError =>
      'Error de conexión. Por favor verifica tu internet.';

  @override
  String get errorsNetworkNoInternet =>
      'No tienes conexión a internet. Verifica tu red.';

  @override
  String get errorsNetworkTimeout =>
      'La solicitud tardó demasiado. Intenta nuevamente.';

  @override
  String get errorsPermissionsForbidden =>
      'No tienes permiso para realizar esta acción.';

  @override
  String get errorsPermissionsInsufficient =>
      'Permisos insuficientes para esta acción.';

  @override
  String get errorsServerBadRequest =>
      'Solicitud inválida. Verifica los datos enviados.';

  @override
  String get errorsServerError => 'Error en el servidor. Intenta más tarde.';

  @override
  String get errorsServerMaintenance =>
      'El servidor está en mantenimiento. Intenta más tarde.';

  @override
  String get errorsServerTooManyRequests =>
      'Has alcanzado el límite de solicitudes. Espera un momento e intenta de nuevo.';

  @override
  String get errorsServerUnavailable =>
      'El servicio no está disponible temporalmente.';

  @override
  String get errorsTitlesAuth => 'Error de autenticación';

  @override
  String get errorsTitlesConnection => 'Error de conexión';

  @override
  String get errorsTitlesData => 'Error de datos';

  @override
  String get errorsTitlesGeneral => 'Error';

  @override
  String get errorsTitlesPermissions => 'Error de permisos';

  @override
  String get errorsTitlesServer => 'Error del servidor';

  @override
  String get errorsTitlesUnexpected => 'Error inesperado';

  @override
  String get errorsTitlesValidation => 'Error de validación';

  @override
  String get errorsUnknown =>
      'Ocurrió un error inesperado. Intenta nuevamente.';

  @override
  String get errorsValidationError =>
      'Error de validación. Verifica los datos ingresados.';

  @override
  String get errorsValidationInvalidInput =>
      'Dato inválido. Verifica el formato.';

  @override
  String get errorsValidationMissingField => 'Falta un campo requerido.';

  @override
  String get gossipAddScreenEmailVerificationResent =>
      'Email de verificación reenviado. Revisa tu bandeja de entrada.';

  @override
  String get gossipAddScreenSubmitButton => 'Publicar chisme';

  @override
  String get gossipAddScreenSuccessDialogButton => 'Aceptar';

  @override
  String get gossipAddScreenSuccessDialogContentPending =>
      'Tu chisme está pendiente de moderación. Te avisaremos cuando cambie de estado.';

  @override
  String get gossipAddScreenSuccessDialogContentPublished =>
      'Tu chisme pasó los controles automáticos y ya está publicado.';

  @override
  String get gossipAddScreenSuccessDialogTitlePending => '¡Chisme enviado!';

  @override
  String get gossipAddScreenSuccessDialogTitlePublished => '¡Chisme publicado!';

  @override
  String get gossipAddScreenTitle => 'Nuevo Chisme 📝';

  @override
  String get gossipCardRateLimitError => 'Límite alcanzado';

  @override
  String get gossipCardReportError => 'Error al reportar';

  @override
  String get gossipCardReportSemanticHint =>
      'Abre opciones para reportar contenido inapropiado';

  @override
  String get gossipCardReportSemanticLabel => 'Reportar este chisme';

  @override
  String get gossipCardReportSuccess =>
      'Gracias por tu reporte. Lo revisaremos pronto.';

  @override
  String get gossipCardReportTooltip => 'Reportar chisme';

  @override
  String get gossipCardSemanticHint => 'Toca para ver detalles completos';

  @override
  String gossipCardSemanticLabel(String subject, String content) {
    return 'Chisme: $subject. $content';
  }

  @override
  String get gossipCardShareError => 'Error al compartir';

  @override
  String get gossipCardShareSemanticHint =>
      'Abre opciones para compartir con otros';

  @override
  String get gossipCardShareSemanticLabel => 'Compartir este chisme';

  @override
  String get gossipCardShareTooltip => 'Compartir chisme';

  @override
  String get gossipDetailScreenTitle => 'Detalle';

  @override
  String get gossipLocationChangeDialogTitle => 'Cambiar ubicación';

  @override
  String get gossipLocationCityHint => 'Buscar ciudad...';

  @override
  String get gossipLocationCityLabel => 'Ciudad';

  @override
  String get gossipLocationCityRequired => 'Selecciona una ciudad';

  @override
  String gossipLocationCitySearchHint(String minChars) {
    return 'Buscar ciudad... (mín. $minChars caracteres)';
  }

  @override
  String get gossipLocationCountryLabel => 'País';

  @override
  String get gossipLocationCountryRequired => 'Selecciona un país';

  @override
  String get gossipLocationGpsDetectSubtitle =>
      'Detectar automáticamente con GPS';

  @override
  String gossipLocationMinCharsMessage(String minChars) {
    return 'Escribe al menos $minChars caracteres para buscar';
  }

  @override
  String gossipLocationNoResults(String query) {
    return 'No se encontraron ciudades con \"$query\"';
  }

  @override
  String get gossipLocationOrSelectManually => 'O seleccionar manualmente';

  @override
  String get gossipLocationRegionLabel => 'Región';

  @override
  String get gossipLocationRegionRequired => 'Selecciona una región';

  @override
  String get gossipLocationSearchError =>
      'Error al buscar ciudades. Intenta de nuevo.';

  @override
  String get gossipLocationUnexpectedError =>
      'Error inesperado. Intenta de nuevo.';

  @override
  String get gossipLocationUseCurrentLocation => 'Usar mi ubicación actual';

  @override
  String get gossipLocationSelectorChangeButtonLabel => 'Cambiar';

  @override
  String get gossipLocationSelectorChangeButtonSemanticHint =>
      'Abre el selector de ubicación';

  @override
  String get gossipLocationSelectorChangeButtonSemanticLabel =>
      'Cambiar ubicación';

  @override
  String get gossipLocationSelectorDetectingText => 'Detectando ubicación...';

  @override
  String get gossipLocationSelectorIconSemanticLabel => 'Ícono de ubicación';

  @override
  String get gossipLocationSelectorPlaceholderText => 'Seleccionar ubicación';

  @override
  String get gossipLocationSelectorSemanticHint =>
      'Toca el botón cambiar para seleccionar otra ubicación';

  @override
  String get gossipLocationSelectorSemanticLabelDetecting =>
      'Detectando ubicación automáticamente';

  @override
  String get gossipLocationSelectorSemanticLabelEmpty =>
      'No hay ubicación seleccionada';

  @override
  String gossipLocationSelectorSemanticLabelSelected(String location) {
    return 'Ubicación actual: $location';
  }

  @override
  String get gossipMediaAddAudio => 'Agregar audio';

  @override
  String get gossipMediaAddImage => 'Agregar imagen';

  @override
  String get gossipMediaAddPhotoOptional => 'Agrega una foto (opcional)';

  @override
  String get gossipMediaAudioAttached => 'Audio adjuntado';

  @override
  String get gossipMediaCamera => 'Cámara';

  @override
  String get gossipMediaCameraSemanticHint =>
      'Abre la cámara para tomar una foto';

  @override
  String get gossipMediaCameraSemanticLabel => 'Tomar foto con la cámara';

  @override
  String get gossipMediaGallery => 'Galería';

  @override
  String get gossipMediaGallerySemanticHint => 'Abre la galería de fotos';

  @override
  String get gossipMediaGallerySemanticLabel =>
      'Seleccionar foto de la galería';

  @override
  String get gossipMediaImageSelected => 'Imagen seleccionada';

  @override
  String get gossipMediaImageSemanticLabel => 'Imagen del chisme seleccionada';

  @override
  String get gossipMediaLoadingSemantic => 'Cargando imagen';

  @override
  String get gossipMediaRemoveImageSemanticHint =>
      'Remueve la imagen seleccionada';

  @override
  String get gossipMediaRemoveImageSemanticLabel => 'Eliminar imagen';

  @override
  String get gossipMediaRemoveImageTooltip => 'Eliminar imagen';

  @override
  String get gossipMediaSelectingImage => 'Seleccionando imagen...';

  @override
  String get gossipMediaSelectingSemanticLabel =>
      'Seleccionando imagen, por favor espera';

  @override
  String get gossipPublishAsAnonymous => 'Anónimo';

  @override
  String get gossipPublishAsTitle => 'Publicar como';

  @override
  String get gossipPublishAsWithProfile => 'Con mi perfil';

  @override
  String get gossipReportButton => 'Reportar';

  @override
  String get gossipReportDetailsHint => 'Describe el problema...';

  @override
  String get gossipReportDetailsLabel => 'Detalles adicionales (opcional)';

  @override
  String get gossipReportReasonQuestion => '¿Por qué reportas este chisme?';

  @override
  String get gossipReportTitle => 'Reportar chisme';

  @override
  String get gossipSubmitButtonPublishSemantic => 'Publicar chisme';

  @override
  String get gossipTextFieldsContentHint => 'Cuenta lo que sabes...';

  @override
  String get gossipTextFieldsContentLabel => 'El chisme';

  @override
  String get gossipTextFieldsContentValidation => 'Cuenta el chisme';

  @override
  String get gossipTextFieldsSubjectHint =>
      'Ej: Juan, la oficina, el gimnasio...';

  @override
  String get gossipTextFieldsSubjectLabel => '¿Sobre quién o dónde?';

  @override
  String get gossipTextFieldsSubjectValidation =>
      'Escribe sobre quién o dónde es el chisme';

  @override
  String get homeDiscoverHeader => 'Descubre 👀';

  @override
  String get homeErrorLoadFailed => 'Error al cargar feed';

  @override
  String get homeErrorRetry => 'Reintentar';

  @override
  String get homeFollowingEmptyStateMessage =>
      'Descubre personas interesantes y sigue sus historias';

  @override
  String get homeFollowingEmptyStateTitle => 'Aún no sigues a nadie';

  @override
  String get homeFollowingExploreUsersButton => 'Explorar usuarios';

  @override
  String get homeFollowingFeatureNotImplemented => 'Feature por implementar';

  @override
  String get homeFollowingNoPostsMessage =>
      '💬 Las personas que sigues aún no han publicado nada';

  @override
  String get homeFollowingRecommendedBadge => '💡 Recomendados para ti';

  @override
  String get homeFollowingRecommendedError => 'Error al cargar recomendados';

  @override
  String get homeFollowingUnexpectedError => 'Error inesperado al cargar feed';

  @override
  String get homeFollowingUsePopularTabHint => 'Usa el tab de Populares arriba';

  @override
  String get homeFollowingViewPopularLink => 'Ver Populares';

  @override
  String get homePopularEmpty => 'No hay chismes disponibles';

  @override
  String get homePopularGlobal => 'Popular 🌎';

  @override
  String homePopularInCity(String city) {
    return 'Popular en $city';
  }

  @override
  String homePopularNewGossipsBanner(String count) {
    return '$count nuevos chismes · Tap aquí';
  }

  @override
  String get homePopularNoMore => 'No hay más chismes por ahora 🌙';

  @override
  String get homeTabsFollowing => 'Siguiendo';

  @override
  String get homeTabsPopular => 'Populares';

  @override
  String get homeTitle => 'Chismes 🔥';

  @override
  String get navigationCreate => 'Crea';

  @override
  String get navigationExplore => 'Explora';

  @override
  String get navigationHome => 'Inicio';

  @override
  String get navigationProfile => 'Perfil';

  @override
  String get profileControllerLoadError => 'Error al cargar el perfil';

  @override
  String get profileControllerSignoutError => 'Error al cerrar sesión';

  @override
  String get profileControllerUpdateError =>
      'Error al actualizar configuración';

  @override
  String get profileHeaderCompleteness => 'Completitud del perfil';

  @override
  String get profileHeaderEmailVerified => 'Email verificado';

  @override
  String get profileHeaderNoName => 'Sin nombre';

  @override
  String get profilePrivacyConsentDeclineButton => 'No acepto, volver';

  @override
  String get profilePrivacyConsentTitle => 'Privacidad y Términos';

  @override
  String get profilePrivacySettingsAccountDeleteSubtitle =>
      'Elimina tu cuenta y todos tus datos';

  @override
  String get profilePrivacySettingsAccountDeleteTitle => 'Eliminar cuenta';

  @override
  String get profilePrivacySettingsAccountDeleted => 'Cuenta eliminada';

  @override
  String get profilePrivacySettingsAnonymousModeTitle => 'Modo anónimo';

  @override
  String get profilePrivacySettingsConfirmDeletionTitle =>
      'Confirmar eliminación';

  @override
  String get profilePrivacySettingsDeletionCancelled => 'Eliminación cancelada';

  @override
  String get profilePrivacySettingsDialogsDeleteAccountConfirmPlaceholder =>
      'ELIMINAR';

  @override
  String get profilePrivacySettingsDialogsDeleteAccountConfirmPrompt =>
      'Para confirmar, escribe ELIMINAR';

  @override
  String get profilePrivacySettingsDialogsDeleteAccountMessage =>
      'Esto eliminará:\n• Tu cuenta\n• Todos tus chismes\n• Todas tus interacciones\n\n⚠️ Esta acción NO se puede deshacer.';

  @override
  String get profilePrivacySettingsDialogsDeleteAccountTitle =>
      '⚠️ Eliminar cuenta';

  @override
  String get profilePrivacySettingsDialogsDeleteAllDataMessage =>
      'Se borrarán TODOS los datos guardados localmente:\n• Ubicación guardada\n• Preferencias\n• Cache\n\n¿Estás seguro?';

  @override
  String get profilePrivacySettingsDialogsDeleteAllDataTitle =>
      '⚠️ Borrar todos los datos';

  @override
  String get profilePrivacySettingsDialogsForgetLocationMessage =>
      'Se borrará tu ciudad guardada. La próxima vez que crees un chisme, se pedirá ubicación de nuevo.';

  @override
  String get profilePrivacySettingsDialogsForgetLocationTitle =>
      '¿Olvidar ubicación?';

  @override
  String get profilePrivacySettingsDialogsPrivacyPolicyContent =>
      'La política de privacidad completa está disponible en:\n\nhttps://chismes.app/privacy\n\nO en el archivo PRIVACY_POLICY.md del proyecto.';

  @override
  String get profilePrivacySettingsDialogsTermsOfUseContent =>
      'Los términos de uso completos están disponibles en:\n\nhttps://chismes.app/terms\n\nO en el archivo TERMS_OF_SERVICE.md del proyecto.';

  @override
  String get profilePrivacySettingsEraseButton => 'Borrar';

  @override
  String get profilePrivacySettingsExportComingSoon =>
      'Exportación disponible próximamente';

  @override
  String get profilePrivacySettingsExportDataTooltip => 'Exportar datos';

  @override
  String get profilePrivacySettingsLocalDataInfoMessage =>
      'Estos datos se almacenan solo en tu teléfono (SharedPreferences). NO se envían al servidor.';

  @override
  String get profilePrivacySettingsLocalDataInfoTitle => 'ℹ️ Datos locales';

  @override
  String get profilePrivacySettingsLocationAnonymousModeDescription =>
      'Con modo anónimo activado, se pedirá ubicación cada vez que crees un chisme.';

  @override
  String get profilePrivacySettingsLocationAnonymousModeSubtitle =>
      'No guardar ubicación por defecto';

  @override
  String get profilePrivacySettingsLocationForgetTooltip => 'Olvidar ubicación';

  @override
  String get profilePrivacySettingsLocationNotSaved => 'No guardada';

  @override
  String get profilePrivacySettingsMyDataTitle => 'Mis Datos';

  @override
  String get profilePrivacySettingsNoLocalData =>
      'No hay datos guardados localmente';

  @override
  String get profilePrivacySettingsPrivacyPolicyTitle =>
      'Política de Privacidad';

  @override
  String get profilePrivacySettingsSavedCityTitle => 'Ciudad guardada';

  @override
  String get profilePrivacySettingsSectionsAccount => '🔒 Cuenta';

  @override
  String get profilePrivacySettingsSectionsLocation => '📍 Ubicación';

  @override
  String get profilePrivacySettingsSectionsPolicies => '📄 Políticas';

  @override
  String get profilePrivacySettingsSectionsStoredData => '💾 Datos almacenados';

  @override
  String get profilePrivacySettingsSnackbarsAnonymousModeOff =>
      '✅ Modo anónimo desactivado';

  @override
  String get profilePrivacySettingsSnackbarsAnonymousModeOn =>
      '✅ Modo anónimo activado';

  @override
  String get profilePrivacySettingsSnackbarsDataErased => '✅ Datos borrados';

  @override
  String get profilePrivacySettingsSnackbarsLocationForgotten =>
      '✅ Ubicación olvidada';

  @override
  String get profilePrivacySettingsTermsOfUseTitle => 'Términos de Uso';

  @override
  String get profilePrivacySettingsTitle => 'Privacidad';

  @override
  String get profilePrivacySettingsViewMyDataSubtitle => 'Dashboard de datos';

  @override
  String get profilePrivacySettingsViewMyDataTitle => 'Ver mis datos';

  @override
  String get profileScreenErrorLoading => 'Error al cargar perfil';

  @override
  String get profileScreenNoUser => 'No hay usuario autenticado';

  @override
  String get profileScreenRefreshTooltip => 'Refrescar';

  @override
  String get profileScreenSignOutButton => 'Cerrar sesión';

  @override
  String get profileScreenSignOutDialogContent =>
      '¿Estás seguro que deseas cerrar sesión?';

  @override
  String get profileScreenSignOutDialogTitle => 'Cerrar sesión';

  @override
  String get profileScreenSigningOut => 'Cerrando sesión...';

  @override
  String get profileSettingsAppearanceTitle => 'Apariencia';

  @override
  String get profileSettingsComments => 'Comentarios';

  @override
  String get profileSettingsCommentsSubtitle =>
      'Notificar cuando comenten tus chismes';

  @override
  String get profileSettingsDailySummary => 'Resumen diario';

  @override
  String get profileSettingsDailySummarySubtitle =>
      'Recibir resumen diario por email';

  @override
  String get profileSettingsDarkMode => 'Modo oscuro';

  @override
  String get profileSettingsDarkModeSubtitle =>
      'Usar tema oscuro en la aplicación';

  @override
  String get profileSettingsEmailNotifications => 'Notificaciones por email';

  @override
  String get profileSettingsGeneralNotifications => 'Notificaciones generales';

  @override
  String get profileSettingsGeneralNotificationsSubtitle =>
      'Activar o desactivar todas las notificaciones';

  @override
  String get profileSettingsLanguage => 'Idioma';

  @override
  String get profileSettingsLanguageEnglish => 'English';

  @override
  String get profileSettingsLanguageSpanish => 'Español';

  @override
  String get profileSettingsNewFollowers => 'Nuevos seguidores';

  @override
  String get profileSettingsNewFollowersSubtitle =>
      'Notificar cuando alguien te siga';

  @override
  String get profileSettingsNotificationsTitle => 'Notificaciones';

  @override
  String get profileSettingsPrivacyDialogTitle => 'Nivel de privacidad';

  @override
  String get profileSettingsPrivacyFriends => 'Amigos';

  @override
  String get profileSettingsPrivacyFriendsSubtitle =>
      'Solo tus amigos pueden ver';

  @override
  String get profileSettingsPrivacyLevel => 'Nivel de privacidad';

  @override
  String get profileSettingsPrivacyPrivate => 'Privado';

  @override
  String get profileSettingsPrivacyPrivateSubtitle => 'Solo tú puedes ver';

  @override
  String get profileSettingsPrivacyPublic => 'Público';

  @override
  String get profileSettingsPrivacyPublicSubtitle =>
      'Todos pueden ver tu perfil';

  @override
  String get profileSettingsPrivacyTitle => 'Privacidad';

  @override
  String get profileSettingsPushNotifications => 'Notificaciones push';

  @override
  String get profileSettingsPushNotificationsSubtitle =>
      'Recibir notificaciones push en el dispositivo';

  @override
  String get profileSettingsSectionAppearance => 'Apariencia';

  @override
  String get profileSettingsSectionNotifications => 'Notificaciones';

  @override
  String get profileSettingsSectionPrivacy => 'Privacidad';

  @override
  String get profileSettingsShowActivity => 'Mostrar actividad';

  @override
  String get profileSettingsShowActivitySubtitle =>
      'Mostrar tu última actividad en el perfil';

  @override
  String get profileSettingsShowEmail => 'Mostrar email';

  @override
  String get profileSettingsShowEmailSubtitle =>
      'Permitir que otros usuarios vean tu email';

  @override
  String get profileSettingsTitle => 'Configuración';

  @override
  String get profileSettingsUpdateError => 'Error al actualizar configuración';

  @override
  String get profileStatsComments => 'Comentarios';

  @override
  String get profileStatsFollowers => 'Seguidores';

  @override
  String get profileStatsFollowing => 'Siguiendo';

  @override
  String get profileStatsGossips => 'Chismes';

  @override
  String get profileStatsTitle => 'Estadísticas';

  @override
  String get searchEmptyState => 'Escribe para buscar chismes 🔎';

  @override
  String get searchHint => 'Buscar chismes...';

  @override
  String get searchNoResults => 'No se encontraron chismes 😢';

  @override
  String get searchTitle => 'Buscar 🔎';

  @override
  String get authPasswordStrengthWeak => 'Débil';

  @override
  String get authPasswordStrengthMedium => 'Media';

  @override
  String get authPasswordStrengthStrong => 'Fuerte';

  @override
  String get authPasswordStrengthHintMinLength => 'mínimo 8 caracteres';

  @override
  String get authPasswordStrengthHintUppercase => 'una mayúscula';

  @override
  String get authPasswordStrengthHintLowercase => 'una minúscula';

  @override
  String get authPasswordStrengthHintNumber => 'un número';

  @override
  String get authPasswordStrengthHintSymbol => 'un símbolo';

  @override
  String authPasswordStrengthHintAdd(String hints) {
    return 'Agrega: $hints';
  }

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get signInButton => 'Iniciar Sesión';

  @override
  String get orContinueWith => 'O continúa con';

  @override
  String get noAccount => '¿No tienes cuenta?';

  @override
  String get signUpLink => 'Regístrate';

  @override
  String get forgotPasswordTitle => '¿Olvidaste tu contraseña?';

  @override
  String get forgotPasswordMessage =>
      'Te enviaremos un código de 6 dígitos para recuperar tu contraseña';

  @override
  String get alreadyHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get emailHint => 'Correo electrónico';

  @override
  String get confirmPasswordHint => 'Confirmar contraseña';

  @override
  String get changePasswordButton => 'Cambiar contraseña';

  @override
  String get newPasswordHint => 'Nueva contraseña';

  @override
  String get otpVerifyEmailTitle => 'Verificar Email';

  @override
  String get laterButton => 'Después';

  @override
  String get doItLater => 'Lo haré después';

  @override
  String get displayNameHint => 'Juan Pérez';

  @override
  String get bioHint => 'Cuéntanos sobre ti...';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get close => 'Cerrar';

  @override
  String get delete => 'Eliminar';

  @override
  String get forget => 'Olvidar';

  @override
  String get emailHintPlaceholder => 'tu@email.com';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get privacyConsentTitle => 'Configuración de Privacidad';

  @override
  String get privacyConsentDeclineButton => 'Rechazar';

  @override
  String get privacySettingsPrivacyPolicy => 'Política de Privacidad';

  @override
  String get privacySettingsTermsOfUse => 'Términos de Uso';

  @override
  String get privacySettingsTitle => 'Privacidad';

  @override
  String get privacySettingsSavedCity => 'Ciudad guardada';

  @override
  String get privacySettingsAnonymousMode => 'Modo anónimo';

  @override
  String get privacySettingsViewMyData => 'Ver mis datos';

  @override
  String get privacySettingsViewMyDataSubtitle =>
      'Descarga tus datos personales';

  @override
  String get locationChangeDialogTitle => 'Cambiar Ubicación';

  @override
  String get locationCityHint => 'Ciudad';

  @override
  String get locationCityLabel => 'Ciudad';

  @override
  String get locationCityRequired => 'La ciudad es requerida';

  @override
  String get locationCountryLabel => 'País';

  @override
  String get locationCountryRequired => 'El país es requerido';

  @override
  String get locationGpsDetectSubtitle => 'Detectar mi ubicación actual';

  @override
  String get locationOrSelectManually => 'o selecciona manualmente';

  @override
  String get locationRegionLabel => 'Región';

  @override
  String get homePopularLoadError => 'Error al cargar chismes populares';

  @override
  String get gossipDetailTitle => 'Detalle del Chisme';

  @override
  String get profileSetupTitle => 'Configura tu Perfil';

  @override
  String get profileSetupSubtitle =>
      'Completa tu perfil para empezar a compartir chismes';

  @override
  String get profileSetupWelcome => '¡Bienvenido!';

  @override
  String get profileSetupInfoMessage =>
      'Necesitas un nombre de usuario para publicar chismes';

  @override
  String get profileSetupUsernameLabel => 'Nombre de usuario';

  @override
  String get profileSetupUsernameHelper =>
      'Solo letras minúsculas, números y _';

  @override
  String get profileSetupUsernameAvailabilityCheck =>
      'Verifica que el nombre de usuario esté disponible';

  @override
  String get profileSetupUsernameTaken =>
      'Este nombre de usuario ya está en uso';

  @override
  String get profileSetupDisplayNameLabel => 'Nombre a mostrar';

  @override
  String get profileSetupBioLabel => 'Biografía (opcional)';

  @override
  String get profileSetupSaveButton => 'Guardar Perfil';

  @override
  String get profileSetupAvatarUploadSoon => 'Próximamente: subir avatar';

  @override
  String get usernameHint => 'juanperez';

  @override
  String get usernameRequired => 'El nombre de usuario es requerido';

  @override
  String get usernameTooShort =>
      'El nombre de usuario es muy corto (mínimo 3 caracteres)';

  @override
  String get usernameTooLong =>
      'El nombre de usuario es muy largo (máximo 30 caracteres)';

  @override
  String get usernameInvalidChars =>
      'El nombre de usuario solo puede contener letras minúsculas, números y guiones bajos';

  @override
  String get passwordHint => 'Contraseña';

  @override
  String get passwordFieldLabel => 'Contraseña';

  @override
  String get passwordFieldShow => 'Mostrar contraseña';

  @override
  String get passwordFieldHide => 'Ocultar contraseña';

  @override
  String get passwordsMustMatch => 'Las contraseñas deben coincidir';

  @override
  String get passwordUpdatedSuccessTitle => 'Contraseña actualizada';

  @override
  String get passwordUpdatedSuccessMessage =>
      'Tu contraseña ha sido actualizada exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña';

  @override
  String get permanentlyDelete => 'Eliminar permanentemente';

  @override
  String get locationRegionRequired => 'La región es requerida';

  @override
  String get locationSearchError => 'Error al buscar ubicación';

  @override
  String get locationUnexpectedError => 'Error inesperado en ubicación';

  @override
  String get locationUseCurrentLocation => 'Usar ubicación actual';

  @override
  String get privacySettingsAccountDeleted => 'Cuenta eliminada';

  @override
  String get privacySettingsConfirmDeletion =>
      '¿Confirmas que deseas eliminar tu cuenta?';

  @override
  String get privacySettingsDeletionCancelled => 'Eliminación cancelada';

  @override
  String get privacySettingsEraseButton => 'Eliminar cuenta';

  @override
  String get privacySettingsMyData => 'Mis datos';

  @override
  String get resetPasswordSubtitle => 'Crea tu nueva contraseña';

  @override
  String get resetPasswordDescription => 'Debe tener mínimo 8 caracteres';

  @override
  String get resetPasswordConfirmHint => 'Confirmar contraseña';

  @override
  String get resetPasswordOkButton => 'OK';

  @override
  String get sendCodeButton => 'Enviar código';

  @override
  String get signUpButton => 'Crear Cuenta';

  @override
  String get signupSubtitle => 'Únete a Chismes';

  @override
  String get signupDescription => 'Crea tu cuenta en segundos';

  @override
  String get signupTermsMessage =>
      'Al crear una cuenta, aceptas nuestros Términos y Condiciones y Política de Privacidad';

  @override
  String get signupPasswordRequired => 'Ingresa una contraseña';

  @override
  String get signupPasswordMinLength => 'Mínimo 8 caracteres';

  @override
  String get signupPasswordsMustMatch => 'Las contraseñas no coinciden';

  @override
  String get signupConfirmPasswordRequired => 'Confirma tu contraseña';

  @override
  String get signInLink => 'Inicia sesión';

  @override
  String locationNoResults(String query) {
    return 'Sin resultados para \'$query\'';
  }

  @override
  String locationCitySearchHint(int minChars) {
    return 'Buscar ciudad (mín. $minChars caracteres)';
  }

  @override
  String locationMinCharsMessage(int minChars) {
    return 'Escribe al menos $minChars caracteres para buscar';
  }
}
