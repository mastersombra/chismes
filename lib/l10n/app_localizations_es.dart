// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTagline => 'Comparte historias, descubre secretos';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonEmailInvalid => 'Email inválido';

  @override
  String get commonEnterEmail => 'Ingresa un email';

  @override
  String get commonEnterPassword => 'Ingresa tu contraseña';

  @override
  String commonMaxLength(String count) {
    return 'No puede exceder $count caracteres';
  }

  @override
  String commonMinLength(String count) {
    return 'Debe tener al menos $count caracteres';
  }

  @override
  String get commonRetry => 'Reintentar';

  @override
  String commonSelect(String field) {
    return 'Selecciona $field';
  }

  @override
  String get errorsAuthEmailAlreadyInUse => 'Este email ya está registrado.';

  @override
  String get authEmailAlreadyInUseAction =>
      'Este email ya está registrado. Inicia sesión en su lugar.';

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
  String get gossipReportReasonSpam => 'Spam';

  @override
  String get gossipReportReasonHarassment => 'Acoso o intimidación';

  @override
  String get gossipReportReasonViolence => 'Violencia o amenazas';

  @override
  String get gossipReportReasonSexualContent => 'Contenido sexual';

  @override
  String get gossipReportReasonMisinformation => 'Desinformación';

  @override
  String get gossipReportReasonOther => 'Otro motivo';

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
  String get homeFollowingUsePopularTabHint => 'Usa el tab de Populares arriba';

  @override
  String get homeFollowingViewPopularLink => 'Ver Populares';

  @override
  String get homePopularEmpty => 'No hay chismes disponibles';

  @override
  String get homePopularNoMore => 'No hay más chismes por ahora 🌙';

  @override
  String get homeTabsFollowing => 'Siguiendo';

  @override
  String get homeTabsPopular => 'Populares';

  @override
  String get homePopularTrendingBadge => 'Tendencia';

  @override
  String get navigationCreate => 'Crea';

  @override
  String get navigationExplore => 'Explora';

  @override
  String get navigationHome => 'Inicio';

  @override
  String get navigationProfile => 'Perfil';

  @override
  String get profileHeaderCompleteness => 'Completitud del perfil';

  @override
  String get profileHeaderEmailVerified => 'Email verificado';

  @override
  String get profileHeaderNoName => 'Sin nombre';

  @override
  String get profilePrivacySettingsAccountDeleteSubtitle =>
      'Elimina tu cuenta y todos tus datos';

  @override
  String get profilePrivacySettingsAccountDeleteTitle => 'Eliminar cuenta';

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
  String get profilePrivacySettingsNoLocalData =>
      'No hay datos guardados localmente';

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
  String get profileSignOutError => 'Error al cerrar sesión';

  @override
  String get profileSettingsComments => 'Comentarios';

  @override
  String get profileSettingsCommentsSubtitle =>
      'Notificar cuando comenten tus chismes';

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
  String searchFilterOnlyCity(String cityName) {
    return 'Solo $cityName';
  }

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

  @override
  String get privacyConsentHeader => '🔒 Tu privacidad es importante';

  @override
  String get privacyConsentSubheader =>
      'Antes de comenzar, queremos que sepas cómo manejamos tus datos.';

  @override
  String get privacyConsentDataCollectedTitle => '📊 ¿Qué datos recopilamos?';

  @override
  String get privacyConsentDataCollectedItem1 =>
      'Tu email y contraseña (encriptada)';

  @override
  String get privacyConsentDataCollectedItem2 =>
      'Solo tu ciudad (NO coordenadas exactas)';

  @override
  String get privacyConsentDataCollectedItem3 =>
      'Contenido de tus chismes (texto, imagen, audio)';

  @override
  String get privacyConsentDataCollectedItem4 =>
      'Estadísticas de uso (para mejorar la app)';

  @override
  String get privacyConsentDataUsageTitle => '🎯 ¿Cómo los usamos?';

  @override
  String get privacyConsentDataUsageItem1 =>
      'Proporcionar el servicio (publicar chismes)';

  @override
  String get privacyConsentDataUsageItem2 =>
      'Moderar contenido (mantener comunidad segura)';

  @override
  String get privacyConsentDataUsageItem3 => 'Mejorar la app (analizar uso)';

  @override
  String get privacyConsentModerationTitle => '🤖 Moderación de contenido';

  @override
  String get privacyConsentModerationItem1 =>
      'Usamos OpenAI para analizar texto';

  @override
  String get privacyConsentModerationItem2 =>
      'Solo se envía el texto del chisme';

  @override
  String get privacyConsentModerationItem3 =>
      'NO enviamos tu nombre, ubicación ni otros datos';

  @override
  String get privacyConsentModerationItem4 =>
      'OpenAI retiene el texto por 30 días, luego lo elimina';

  @override
  String get privacyConsentModerationItem5 =>
      'NO se usa para entrenar modelos de IA';

  @override
  String get privacyConsentLocationTitle => '📍 Tu ubicación';

  @override
  String get privacyConsentLocationItem1 =>
      'Solo detectamos tu ciudad (ej: \"Bogotá\")';

  @override
  String get privacyConsentLocationItem2 =>
      'Coordenadas GPS se descartan inmediatamente';

  @override
  String get privacyConsentLocationItem3 =>
      'NUNCA almacenamos ni enviamos coordenadas exactas';

  @override
  String get privacyConsentLocationItem4 =>
      'Puedes elegir la ciudad manualmente';

  @override
  String get privacyConsentRightsTitle => '✅ Tus derechos';

  @override
  String get privacyConsentRightsItem1 =>
      'Acceder a tus datos en cualquier momento';

  @override
  String get privacyConsentRightsItem2 => 'Eliminar tu cuenta y datos';

  @override
  String get privacyConsentRightsItem3 => 'Olvidar tu ubicación guardada';

  @override
  String get privacyConsentRightsItem4 => 'Exportar tus datos (portabilidad)';

  @override
  String get privacyConsentCheckboxPrivacy => 'He leído y acepto la ';

  @override
  String get privacyConsentCheckboxPrivacyLink => 'Política de Privacidad';

  @override
  String get privacyConsentCheckboxTerms => 'He leído y acepto los ';

  @override
  String get privacyConsentCheckboxTermsLink => 'Términos de Uso';

  @override
  String get privacyConsentCheckboxModeration =>
      'Acepto que el texto de mis chismes se envíe a ';

  @override
  String get privacyConsentCheckboxModerationBold => 'OpenAI';

  @override
  String get privacyConsentCheckboxModerationSuffix =>
      ' para moderación de contenido (30 días de retención)';

  @override
  String get privacyConsentAcceptButton => 'Aceptar y Continuar';

  @override
  String get privacyConsentDisclaimer =>
      'Al continuar, aceptas nuestras políticas';

  @override
  String get authOtpResendCode => 'Reenviar código';

  @override
  String authOtpResendIn(int seconds) {
    return 'Reenviar en ${seconds}s';
  }

  @override
  String get authOtpHelpText =>
      '¿No recibiste el código? Revisa tu carpeta de spam o solicita uno nuevo.';

  @override
  String get authOtpEnterCode => 'Ingresa el código';

  @override
  String get authOtpSentCodeTo => 'Enviamos un código de 6 dígitos a:';

  @override
  String get authOtpCodeMustBe6Digits => 'El código debe tener 6 dígitos';

  @override
  String get privacyConsentDialogPrivacyAvailable =>
      'La política de privacidad completa está disponible en:';

  @override
  String get privacyConsentDialogPrivacyUrl => 'https://chismes.app/privacy';

  @override
  String get privacyConsentDialogPrivacyFile =>
      'O en el archivo PRIVACY_POLICY.md del proyecto.';

  @override
  String get privacyConsentDialogPrivacySummary => 'Resumen:';

  @override
  String get privacyConsentDialogPrivacyItem1 =>
      '• Solo recopilamos datos necesarios';

  @override
  String get privacyConsentDialogPrivacyItem2 => '• No vendemos tus datos';

  @override
  String get privacyConsentDialogPrivacyItem3 =>
      '• Puedes eliminar tu cuenta en cualquier momento';

  @override
  String get privacyConsentDialogTermsAvailable =>
      'Los términos de uso completos están disponibles en:';

  @override
  String get privacyConsentDialogTermsUrl => 'https://chismes.app/terms';

  @override
  String get privacyConsentDialogTermsFile =>
      'O en el archivo TERMS_OF_SERVICE.md del proyecto.';

  @override
  String get privacyConsentDialogTermsSummary => 'Resumen:';

  @override
  String get privacyConsentDialogTermsItem1 => '• Edad mínima: 13 años';

  @override
  String get privacyConsentDialogTermsItem2 =>
      '• No publicar contenido inapropiado';

  @override
  String get privacyConsentDialogTermsItem3 =>
      '• Moderación automática + manual';

  @override
  String get privacyConsentDialogTermsItem4 =>
      '• Podemos suspender cuentas que violen normas';

  @override
  String get searchRecentSearches => 'Búsquedas recientes';

  @override
  String get searchTryOtherWords => 'Intenta con otras palabras';

  @override
  String get searchByTopic => 'Busca chismes por tema';

  @override
  String get searchByKeyword => 'o palabra clave';

  @override
  String get searchRecent => 'Recientes';

  @override
  String get searchClearAll => 'Borrar todo';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
      zero: 'Sin resultados',
    );
    return '$_temp0';
  }

  @override
  String homeNewGossipsBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuevos chismes · Toca aquí',
      one: '1 nuevo chisme · Toca aquí',
    );
    return '$_temp0';
  }

  @override
  String deepLinkOpeningGossip(String gossipId) {
    return 'Abriendo chisme: $gossipId';
  }

  @override
  String deepLinkOpeningProfile(String userId) {
    return 'Abriendo perfil: $userId';
  }

  @override
  String deepLinkOpeningCityFeed(String cityId) {
    return 'Abriendo feed de ciudad: $cityId';
  }

  @override
  String get locationErrorLoadCountries => 'Error al cargar países';

  @override
  String get locationErrorLoadRegions => 'Error al cargar regiones';

  @override
  String get locationErrorLoadCities => 'Error al cargar ciudades';

  @override
  String get locationErrorUnexpected => 'Error inesperado';

  @override
  String get locationErrorGpsPosition =>
      'No se pudo detectar ubicación. Activa GPS e intenta de nuevo.';

  @override
  String get locationErrorGeocoding => 'No se pudo identificar la ubicación';

  @override
  String locationErrorCountryNotAvailable(String entityName) {
    return 'País \"$entityName\" no disponible. Selecciona manualmente.';
  }

  @override
  String locationErrorRegionNotAvailable(String entityName) {
    return 'Región \"$entityName\" no disponible. Selecciona manualmente.';
  }

  @override
  String locationErrorCityNotAvailable(String entityName) {
    return 'Ciudad \"$entityName\" no disponible. Selecciona manualmente.';
  }

  @override
  String get locationErrorDetection =>
      'Error al detectar ubicación. Intenta de nuevo.';

  @override
  String get moderationEntryTitle => 'Panel de moderación';

  @override
  String get moderationEntrySubtitle => 'Revisa el contenido pendiente';

  @override
  String get moderationTitle => 'Moderación';

  @override
  String get moderationTabPending => 'Pendientes';

  @override
  String get moderationTabApproved => 'Aprobados';

  @override
  String get moderationTabRejected => 'Rechazados';

  @override
  String get moderationEmptyPending => 'No hay nada pendiente';

  @override
  String get moderationEmptyPendingHint =>
      'Lo que la IA o los reportes manden a revisión aparecerá aquí';

  @override
  String get moderationEmptyHistory => 'Todavía no hay decisiones aquí';

  @override
  String get moderationLoadError => 'No se pudo cargar la cola';

  @override
  String get moderationForbidden => 'Tu cuenta no tiene permisos de moderación';

  @override
  String get moderationHighPriority => 'Prioridad alta';

  @override
  String get moderationSourceAiReview => 'IA';

  @override
  String get moderationSourceAiUnavailable => 'Sin veredicto automático';

  @override
  String get moderationSourceReports => 'Reportes';

  @override
  String moderationReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reportes',
      one: '1 reporte',
    );
    return '$_temp0';
  }

  @override
  String moderationInteractions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count interacciones',
      one: '1 interacción',
    );
    return '$_temp0';
  }

  @override
  String get moderationAutoHidden => 'Oculto por reportes';

  @override
  String get moderationAuthorLabel => 'Autor';

  @override
  String get moderationAuthorNoName => 'Sin nombre de perfil';

  @override
  String get moderationAnonymousAuthor =>
      'Publicado como anónimo: solo moderación ve el autor';

  @override
  String get moderationReasonsTitle => 'Por qué está aquí';

  @override
  String get moderationHasAudio =>
      'Tiene audio (todavía no se puede escuchar aquí)';

  @override
  String get moderationImageUnavailable => 'No se pudo cargar la imagen';

  @override
  String moderationQueuedAt(String date) {
    return 'En la cola desde $date';
  }

  @override
  String moderationDecidedAt(String date) {
    return 'Decidido el $date';
  }

  @override
  String get moderationDecisionTitle => 'Decisión';

  @override
  String get moderationNoteTitle => 'Nota interna';

  @override
  String get moderationApprove => 'Aprobar';

  @override
  String get moderationReject => 'Rechazar';

  @override
  String get moderationApproveConfirmTitle => '¿Aprobar y publicar?';

  @override
  String get moderationApproveConfirmBody =>
      'El chisme quedará visible para todos.';

  @override
  String get moderationApprovedMessage => 'Aprobado y publicado';

  @override
  String get moderationRejectedMessage => 'Rechazado: el chisme quedó oculto';

  @override
  String get moderationAlreadyDecided =>
      'Ya no está pendiente: otro moderador lo decidió';

  @override
  String get moderationDecisionError =>
      'No se pudo aplicar la decisión. Intenta de nuevo.';

  @override
  String get moderationRejectTitle => 'Rechazar contenido';

  @override
  String get moderationRejectHint =>
      'Se oculta, no se borra: queda para una apelación.';

  @override
  String get moderationSeverityLabel => 'Gravedad';

  @override
  String get moderationSeverityLow => 'Leve';

  @override
  String get moderationSeverityMedium => 'Media';

  @override
  String get moderationSeverityHigh => 'Grave';

  @override
  String get moderationSeverityCritical => 'Crítica';

  @override
  String get moderationRejectReasonLabel => 'Motivo';

  @override
  String get moderationRejectReasonHate => 'Odio o discriminación';

  @override
  String get moderationRejectReasonPersonalData => 'Datos personales';

  @override
  String get moderationNoteLabel => 'Nota interna (opcional)';

  @override
  String get moderationNoteHint => 'Contexto para otros moderadores';

  @override
  String get moderationReasonAiUnavailable => 'La IA no respondió';

  @override
  String get moderationReasonRulesUnavailable =>
      'No se pudieron leer las reglas';

  @override
  String get moderationReasonPersonalData => 'Posibles datos personales';

  @override
  String get moderationReasonSpam => 'Posible spam o links';

  @override
  String get moderationReasonThreat => 'Posible amenaza';

  @override
  String get moderationReasonAudio => 'Audio sin moderar';

  @override
  String moderationReasonTerm(String term) {
    return 'Término: $term';
  }

  @override
  String moderationReasonAiScore(String category) {
    return 'IA: $category';
  }
}
