import 'package:easy_localization/easy_localization.dart';
import 'dart:ui';

/// AssetLoader personalizado para tests con todas las traducciones
class TestTranslationsLoader extends AssetLoader {
  const TestTranslationsLoader();

  static const Map<String, dynamic> _esTranslations = {
      'app': {
        'name': 'Chismes',
        'tagline': 'Comparte historias, descubre secretos'
      },
      'auth': {
        'login': {
          'title': 'Iniciar Sesión',
          'email_hint': 'Correo electrónico',
          'password_hint': 'Contraseña',
          'sign_in_button': 'Iniciar Sesión',
          'or_continue_with': 'O continúa con',
          'no_account': '¿No tienes cuenta?',
          'sign_up_link': 'Regístrate',
          'forgot_password': '¿Olvidaste tu contraseña?',
          'continue_with_google': 'Continuar con Google',
          'continue_with_apple': 'Continuar con Apple'
        },
        'signup': {
          'title': 'Crear Cuenta',
          'subtitle': 'Únete a Chismes',
          'description': 'Crea tu cuenta en segundos',
          'email_hint': 'Correo electrónico',
          'password_hint': 'Contraseña',
          'confirm_password_hint': 'Confirmar contraseña',
          'sign_up_button': 'Crear Cuenta',
          'already_have_account': '¿Ya tienes cuenta?',
          'sign_in_link': 'Inicia sesión',
          'password_required': 'Ingresa una contraseña',
          'password_min_length': 'Mínimo 8 caracteres',
          'confirm_password_required': 'Confirma tu contraseña',
          'passwords_must_match': 'Las contraseñas no coinciden',
          'terms_message': 'Al crear una cuenta, aceptas nuestros Términos y Condiciones y Política de Privacidad'
        },
        'profile_setup': {
          'title': 'Configura tu Perfil',
          'welcome': '¡Bienvenido!',
          'subtitle': 'Completa tu perfil para empezar a compartir chismes',
          'username_label': 'Nombre de usuario',
          'username_hint': 'juanperez',
          'username_helper': 'Solo letras minúsculas, números y _',
          'username_taken': 'Este nombre de usuario ya está en uso',
          'username_availability_check': 'Verifica que el nombre de usuario esté disponible',
          'display_name_label': 'Nombre a mostrar',
          'display_name_hint': 'Juan Pérez',
          'bio_label': 'Biografía (opcional)',
          'bio_hint': 'Cuéntanos sobre ti...',
          'info_message': 'Necesitas un nombre de usuario para publicar chismes',
          'save_button': 'Guardar Perfil',
          'complete_button': 'Completar perfil',
          'later_button': 'Después',
          'do_it_later': 'Lo haré después',
          'avatar_upload_soon': 'Próximamente: subir avatar'
        },
        'forgot_password': {
          'title': '¿Olvidaste tu contraseña?',
          'message': 'Te enviaremos un código de 6 dígitos para recuperar tu contraseña',
          'email_hint': 'Correo electrónico',
          'send_code_button': 'Enviar código',
          'code_sent_title': 'Código enviado',
          'code_sent_message': 'Revisa tu email para obtener el código de verificación'
        },
        'reset_password': {
          'title': 'Nueva Contraseña',
          'subtitle': 'Crea tu nueva contraseña',
          'description': 'Debe tener mínimo 8 caracteres',
          'new_password_hint': 'Nueva contraseña',
          'confirm_password_hint': 'Confirmar contraseña',
          'change_password_button': 'Cambiar contraseña',
          'success_title': 'Contraseña actualizada',
          'success_message': 'Tu contraseña ha sido actualizada exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña',
          'ok_button': 'OK'
        },
        'otp_verification': {
          'title': 'Verificar Código',
          'verify_email_title': 'Verificar Email',
          'subtitle_signup': 'Enviamos un código de 6 dígitos a:',
          'subtitle_reset': 'Ingresa el código que enviamos a:',
          'code_hint': 'Código',
          'resend_label': '¿No recibiste el código?',
          'resend_button': 'Reenviar',
          'resend_timer': 'Reenviar ({seconds}s)',
          'verifying': 'Verificando...'
        },
        'validation': {
          'email_required': 'El email es requerido',
          'email_invalid': 'El formato del email es inválido',
          'email_too_long': 'El email es muy largo (máximo 254 caracteres)',
          'password_required': 'La contraseña es requerida',
          'password_too_short': 'La contraseña es muy corta (mínimo 8 caracteres)',
          'password_too_long': 'La contraseña es muy larga (máximo 128 caracteres)',
          'password_needs_lowercase': 'La contraseña debe contener al menos una letra minúscula',
          'password_needs_uppercase': 'La contraseña debe contener al menos una letra mayúscula',
          'password_needs_number': 'La contraseña debe contener al menos un número',
          'password_needs_special': 'La contraseña debe contener al menos un carácter especial',
          'passwords_must_match': 'Las contraseñas deben coincidir',
          'username_required': 'El nombre de usuario es requerido',
          'username_too_short': 'El nombre de usuario es muy corto (mínimo 3 caracteres)',
          'username_too_long': 'El nombre de usuario es muy largo (máximo 30 caracteres)',
          'username_invalid_chars': 'El nombre de usuario solo puede contener letras minúsculas, números y guiones bajos',
          'username_starts_with_number': 'El nombre de usuario no puede empezar con un número',
          'username_invalid_underscore': 'El nombre de usuario no puede empezar o terminar con guión bajo',
          'username_reserved': 'El nombre de usuario está reservado',
          'display_name_required': 'El nombre a mostrar es requerido',
          'display_name_empty': 'El nombre a mostrar no puede estar vacío',
          'display_name_too_long': 'El nombre a mostrar es muy largo (máximo 50 caracteres)',
          'bio_too_long': 'La biografía es muy larga (máximo 160 caracteres)'
        },
        'errors': {
          'invalid_credentials': 'Credenciales inválidas',
          'email_already_in_use': 'El email ya está en uso',
          'weak_password': 'La contraseña es muy débil',
          'user_not_found': 'Usuario no encontrado',
          'network_error': 'Error de conexión',
          'unknown_error': 'Error desconocido'
        },
        'password_field': {
          'label': 'Contraseña',
          'show': 'Mostrar contraseña',
          'hide': 'Ocultar contraseña'
        }
      },
      'errors': {
        'titles': {
          'connection': 'Error de conexión',
          'server': 'Error del servidor',
          'auth': 'Error de autenticación',
          'validation': 'Error de validación',
          'data': 'Error de datos',
          'permissions': 'Error de permisos',
          'general': 'Error',
          'unexpected': 'Error inesperado'
        },
        'network': {
          'connection_error': 'Error de conexión. Por favor verifica tu internet.',
          'timeout': 'La solicitud tardó demasiado. Intenta nuevamente.',
          'no_internet': 'No tienes conexión a internet. Verifica tu red.'
        },
        'server': {
          'error': 'Error en el servidor. Intenta más tarde.',
          'maintenance': 'El servidor está en mantenimiento. Intenta más tarde.',
          'unavailable': 'El servicio no está disponible temporalmente.',
          'too_many_requests': 'Has alcanzado el límite de solicitudes. Espera un momento e intenta de nuevo.',
          'bad_request': 'Solicitud inválida. Verifica los datos enviados.'
        },
        'auth': {
          'unauthorized': 'No estás autorizado para realizar esta acción.',
          'session_expired': 'Tu sesión ha expirado. Inicia sesión nuevamente.',
          'invalid_credentials': 'Email o contraseña incorrectos. Por favor, verifica tus datos e intenta nuevamente.',
          'email_already_in_use': 'Este email ya está registrado.',
          'weak_password': 'La contraseña es muy débil.',
          'user_not_found': 'Usuario no encontrado.',
          'not_authenticated': 'Debes iniciar sesión para continuar.',
          'username_taken': 'Este nombre de usuario ya está en uso.',
          'invalid_token': 'Código inválido o expirado. Solicita uno nuevo.',
          'expired_token': 'Código inválido o expirado. Solicita uno nuevo.',
          'oauth_cancelled': 'Inicio de sesión cancelado.',
          'oauth_provider_error': 'Error al iniciar sesión con el proveedor.',
          'email_not_verified': 'Debes verificar tu email para continuar.',
          'too_many_attempts': 'Demasiados intentos. Intenta más tarde.'
        },
        'validation': {
          'error': 'Error de validación. Verifica los datos ingresados.',
          'invalid_input': 'Dato inválido. Verifica el formato.',
          'missing_field': 'Falta un campo requerido.'
        },
        'data': {
          'not_found': 'El recurso solicitado no existe.',
          'already_exists': 'El recurso ya existe.',
          'conflict': 'Conflicto de datos. Intenta nuevamente.'
        },
        'permissions': {
          'forbidden': 'No tienes permiso para realizar esta acción.',
          'insufficient': 'Permisos insuficientes para esta acción.'
        },
        'business': {
          'invalid_location': 'Ubicación inválida. Selecciona una ubicación válida.',
          'invalid_gossip_content': 'El contenido del chisme es inválido.',
          'gossip_not_found': 'El chisme no existe o fue eliminado.',
          'moderation_rejected': 'El contenido no cumple con nuestras normas de comunidad. Por favor revisa el contenido e intenta nuevamente.',
          'media_upload_failed': 'No se pudo subir la imagen. Por favor intenta de nuevo o intenta con otra imagen.',
          'rate_limit_exceeded': 'Has alcanzado el límite de solicitudes. Espera un momento e intenta de nuevo.'
        },
        'unknown': 'Ocurrió un error inesperado. Intenta nuevamente.'
      },
      'common': {
        'select': 'Selecciona {field}',
        'required_field': 'Campo requerido',
        'min_length': 'Debe tener al menos {count} caracteres',
        'max_length': 'No puede exceder {count} caracteres',
        'enter_email': 'Ingresa un email',
        'enter_password': 'Ingresa tu contraseña',
        'email_invalid': 'Email inválido',
        'email_hint_placeholder': 'tu@email.com',
        'loading': 'Cargando...',
        'error': 'Error',
        'success': 'Éxito',
        'cancel': 'Cancelar',
        'confirm': 'Confirmar',
        'save': 'Guardar',
        'delete': 'Eliminar',
        'edit': 'Editar',
        'back': 'Volver',
        'close': 'Cerrar',
        'forget': 'Olvidar',
        'permanently_delete': 'Eliminar permanentemente',
        'retry': 'Reintentar'
      },
      'navigation': {
        'home': 'Inicio',
        'explore': 'Explora',
        'create': 'Crea',
        'profile': 'Perfil'
      },
      'gossip': {
        'detail_screen': {
          'title': 'Detalle'
        },
        'add_screen': {
          'title': 'Nuevo Chisme 📝',
          'submit_button': 'Publicar chisme',
          'success_dialog_title_pending': '¡Chisme enviado!',
          'success_dialog_title_published': '¡Chisme publicado!',
          'success_dialog_content_pending': 'Tu chisme está pendiente de moderación. Te avisaremos cuando cambie de estado.',
          'success_dialog_content_published': 'Tu chisme pasó los controles automáticos y ya está publicado.',
          'success_dialog_button': 'Aceptar',
          'email_verification_resent': 'Email de verificación reenviado. Revisa tu bandeja de entrada.'
        },
        'text_fields': {
          'subject_label': '¿Sobre quién o dónde?',
          'subject_hint': 'Ej: Juan, la oficina, el gimnasio...',
          'subject_validation': 'Escribe sobre quién o dónde es el chisme',
          'content_label': 'El chisme',
          'content_hint': 'Cuenta lo que sabes...',
          'content_validation': 'Cuenta el chisme'
        },
        'location': {
          'city_label': 'Ciudad',
          'city_hint': 'Buscar ciudad...',
          'city_search_hint': 'Buscar ciudad... (mín. {minChars} caracteres)',
          'country_label': 'País',
          'country_required': 'Selecciona un país',
          'region_label': 'Región',
          'region_required': 'Selecciona una región',
          'city_required': 'Selecciona una ciudad',
          'search_error': 'Error al buscar ciudades. Intenta de nuevo.',
          'unexpected_error': 'Error inesperado. Intenta de nuevo.',
          'min_chars_message': 'Escribe al menos {minChars} caracteres para buscar',
          'no_results': 'No se encontraron ciudades con "{query}"',
          'change_dialog_title': 'Cambiar ubicación',
          'use_current_location': 'Usar mi ubicación actual',
          'gps_detect_subtitle': 'Detectar automáticamente con GPS',
          'or_select_manually': 'O seleccionar manualmente'
        },
        'location_selector': {
          'semantic_label_detecting': 'Detectando ubicación automáticamente',
          'semantic_label_selected': 'Ubicación actual: {location}',
          'semantic_label_empty': 'No hay ubicación seleccionada',
          'semantic_hint': 'Toca el botón cambiar para seleccionar otra ubicación',
          'icon_semantic_label': 'Ícono de ubicación',
          'detecting_text': 'Detectando ubicación...',
          'placeholder_text': 'Seleccionar ubicación',
          'change_button_semantic_label': 'Cambiar ubicación',
          'change_button_semantic_hint': 'Abre el selector de ubicación',
          'change_button_label': 'Cambiar'
        },
        'publish_as': {
          'title': 'Publicar como',
          'anonymous': 'Anónimo',
          'with_profile': 'Con mi perfil'
        },
        'card': {
          'share_error': 'Error al compartir',
          'report_success': 'Gracias por tu reporte. Lo revisaremos pronto.',
          'report_error': 'Error al reportar',
          'rate_limit_error': 'Límite alcanzado',
          'semantic_label': 'Chisme: {subject}. {content}',
          'semantic_hint': 'Toca para ver detalles completos',
          'share_tooltip': 'Compartir chisme',
          'share_semantic_label': 'Compartir este chisme',
          'share_semantic_hint': 'Abre opciones para compartir con otros',
          'report_tooltip': 'Reportar chisme',
          'report_semantic_label': 'Reportar este chisme',
          'report_semantic_hint': 'Abre opciones para reportar contenido inapropiado'
        },
        'media': {
          'camera': 'Cámara',
          'gallery': 'Galería',
          'add_image': 'Agregar imagen',
          'add_audio': 'Agregar audio',
          'audio_attached': 'Audio adjuntado',
          'image_selected': 'Imagen seleccionada',
          'selecting_image': 'Seleccionando imagen...',
          'add_photo_optional': 'Agrega una foto (opcional)',
          'remove_image_tooltip': 'Eliminar imagen',
          'image_semantic_label': 'Imagen del chisme seleccionada',
          'remove_image_semantic_label': 'Eliminar imagen',
          'remove_image_semantic_hint': 'Remueve la imagen seleccionada',
          'selecting_semantic_label': 'Seleccionando imagen, por favor espera',
          'loading_semantic': 'Cargando imagen',
          'camera_semantic_label': 'Tomar foto con la cámara',
          'camera_semantic_hint': 'Abre la cámara para tomar una foto',
          'gallery_semantic_label': 'Seleccionar foto de la galería',
          'gallery_semantic_hint': 'Abre la galería de fotos'
        },
        'report': {
          'title': 'Reportar chisme',
          'button': 'Reportar',
          'reason_question': '¿Por qué reportas este chisme?',
          'details_label': 'Detalles adicionales (opcional)',
          'details_hint': 'Describe el problema...'
        },
        'submit_button': {
          'publish_semantic': 'Publicar chisme'
        }
      },
      'profile': {
        'screen': {
          'refresh_tooltip': 'Refrescar',
          'error_loading': 'Error al cargar perfil',
          'no_user': 'No hay usuario autenticado',
          'sign_out_button': 'Cerrar sesión',
          'signing_out': 'Cerrando sesión...',
          'sign_out_dialog_title': 'Cerrar sesión',
          'sign_out_dialog_content': '¿Estás seguro que deseas cerrar sesión?'
        },
        'stats': {
          'title': 'Estadísticas',
          'gossips': 'Chismes',
          'comments': 'Comentarios',
          'followers': 'Seguidores',
          'following': 'Siguiendo'
        },
        'header': {
          'no_name': 'Sin nombre',
          'email_verified': 'Email verificado',
          'completeness': 'Completitud del perfil'
        },
        'controller': {
          'load_error': 'Error al cargar el perfil',
          'update_error': 'Error al actualizar configuración',
          'signout_error': 'Error al cerrar sesión'
        },
        'settings': {
          'title': 'Configuración',
          'section_notifications': 'Notificaciones',
          'section_privacy': 'Privacidad',
          'section_appearance': 'Apariencia',
          'notifications_title': 'Notificaciones',
          'general_notifications': 'Notificaciones generales',
          'general_notifications_subtitle': 'Activar o desactivar todas las notificaciones',
          'push_notifications': 'Notificaciones push',
          'push_notifications_subtitle': 'Recibir notificaciones push en el dispositivo',
          'email_notifications': 'Notificaciones por email',
          'daily_summary': 'Resumen diario',
          'daily_summary_subtitle': 'Recibir resumen diario por email',
          'comments': 'Comentarios',
          'comments_subtitle': 'Notificar cuando comenten tus chismes',
          'new_followers': 'Nuevos seguidores',
          'new_followers_subtitle': 'Notificar cuando alguien te siga',
          'privacy_title': 'Privacidad',
          'privacy_level': 'Nivel de privacidad',
          'show_email': 'Mostrar email',
          'show_email_subtitle': 'Permitir que otros usuarios vean tu email',
          'show_activity': 'Mostrar actividad',
          'show_activity_subtitle': 'Mostrar tu última actividad en el perfil',
          'appearance_title': 'Apariencia',
          'language': 'Idioma',
          'language_spanish': 'Español',
          'language_english': 'English',
          'dark_mode': 'Modo oscuro',
          'dark_mode_subtitle': 'Usar tema oscuro en la aplicación',
          'update_error': 'Error al actualizar configuración',
          'privacy_dialog_title': 'Nivel de privacidad',
          'privacy_public': 'Público',
          'privacy_public_subtitle': 'Todos pueden ver tu perfil',
          'privacy_friends': 'Amigos',
          'privacy_friends_subtitle': 'Solo tus amigos pueden ver',
          'privacy_private': 'Privado',
          'privacy_private_subtitle': 'Solo tú puedes ver'
        },
        'privacy_settings': {
          'title': 'Privacidad',
          'saved_city_title': 'Ciudad guardada',
          'anonymous_mode_title': 'Modo anónimo',
          'view_my_data_title': 'Ver mis datos',
          'view_my_data_subtitle': 'Dashboard de datos',
          'privacy_policy_title': 'Política de Privacidad',
          'terms_of_use_title': 'Términos de Uso',
          'confirm_deletion_title': 'Confirmar eliminación',
          'deletion_cancelled': 'Eliminación cancelada',
          'account_deleted': 'Cuenta eliminada',
          'my_data_title': 'Mis Datos',
          'erase_button': 'Borrar',
          'export_data_tooltip': 'Exportar datos',
          'no_local_data': 'No hay datos guardados localmente',
          'export_coming_soon': 'Exportación disponible próximamente',
          'local_data_info_title': 'ℹ️ Datos locales',
          'local_data_info_message': 'Estos datos se almacenan solo en tu teléfono (SharedPreferences). NO se envían al servidor.',
          'sections': {
            'location': '📍 Ubicación',
            'stored_data': '💾 Datos almacenados',
            'policies': '📄 Políticas',
            'account': '🔒 Cuenta'
          },
          'location': {
            'not_saved': 'No guardada',
            'forget_tooltip': 'Olvidar ubicación',
            'anonymous_mode_subtitle': 'No guardar ubicación por defecto',
            'anonymous_mode_description': 'Con modo anónimo activado, se pedirá ubicación cada vez que crees un chisme.'
          },
          'dialogs': {
            'forget_location_title': '¿Olvidar ubicación?',
            'forget_location_message': 'Se borrará tu ciudad guardada. La próxima vez que crees un chisme, se pedirá ubicación de nuevo.',
            'delete_account_title': '⚠️ Eliminar cuenta',
            'delete_account_message': 'Esto eliminará:\n• Tu cuenta\n• Todos tus chismes\n• Todas tus interacciones\n\n⚠️ Esta acción NO se puede deshacer.',
            'delete_account_confirm_prompt': 'Para confirmar, escribe ELIMINAR',
            'delete_account_confirm_placeholder': 'ELIMINAR',
            'delete_all_data_title': '⚠️ Borrar todos los datos',
            'delete_all_data_message': 'Se borrarán TODOS los datos guardados localmente:\n• Ubicación guardada\n• Preferencias\n• Cache\n\n¿Estás seguro?',
            'privacy_policy_content': 'La política de privacidad completa está disponible en:\n\nhttps://chismes.app/privacy\n\nO en el archivo PRIVACY_POLICY.md del proyecto.',
            'terms_of_use_content': 'Los términos de uso completos están disponibles en:\n\nhttps://chismes.app/terms\n\nO en el archivo TERMS_OF_SERVICE.md del proyecto.'
          },
          'snackbars': {
            'location_forgotten': '✅ Ubicación olvidada',
            'anonymous_mode_on': '✅ Modo anónimo activado',
            'anonymous_mode_off': '✅ Modo anónimo desactivado',
            'data_erased': '✅ Datos borrados'
          },
          'account': {
            'delete_title': 'Eliminar cuenta',
            'delete_subtitle': 'Elimina tu cuenta y todos tus datos'
          }
        },
        'privacy_consent': {
          'title': 'Privacidad y Términos',
          'decline_button': 'No acepto, volver'
        }
      },
      'search': {
        'title': 'Buscar 🔎',
        'hint': 'Buscar chismes...',
        'empty_state': 'Escribe para buscar chismes 🔎',
        'no_results': 'No se encontraron chismes 😢'
      },
      'home': {
        'title': 'Chismes 🔥',
        'discover_header': 'Descubre 👀',
        'tabs': {
          'popular': 'Populares',
          'following': 'Siguiendo'
        },
        'popular': {
          'in_city': 'Popular en {city}',
          'global': 'Popular 🌎',
          'new_gossips_banner': '{count} nuevos chismes · Tap aquí',
          'empty': 'No hay chismes disponibles',
          'no_more': 'No hay más chismes por ahora 🌙'
        },
        'following': {
          'recommended_badge': '💡 Recomendados para ti',
          'no_posts_message': '💬 Las personas que sigues aún no han publicado nada',
          'empty_state_title': 'Aún no sigues a nadie',
          'empty_state_message': 'Descubre personas interesantes y sigue sus historias',
          'explore_users_button': 'Explorar usuarios',
          'view_popular_link': 'Ver Populares',
          'feature_not_implemented': 'Feature por implementar',
          'use_popular_tab_hint': 'Usa el tab de Populares arriba',
          'unexpected_error': 'Error inesperado al cargar feed',
          'recommended_error': 'Error al cargar recomendados'
        },
        'error': {
          'load_failed': 'Error al cargar feed',
          'retry': 'Reintentar'
        }
      }
    };

  static const Map<String, dynamic> _enTranslations = {
      'app': {
        'name': 'Chismes',
        'tagline': 'Share stories, discover secrets'
      },
      'auth': {
        'login': {
          'title': 'Sign In',
          'email_hint': 'Email',
          'password_hint': 'Password',
          'sign_in_button': 'Sign In',
          'or_continue_with': 'Or continue with',
          'no_account': 'Don\'t have an account?',
          'sign_up_link': 'Sign up',
          'forgot_password': 'Forgot your password?',
          'continue_with_google': 'Continue with Google',
          'continue_with_apple': 'Continue with Apple'
        },
        'signup': {
          'title': 'Create Account',
          'subtitle': 'Join Chismes',
          'description': 'Create your account in seconds',
          'email_hint': 'Email',
          'password_hint': 'Password',
          'confirm_password_hint': 'Confirm password',
          'sign_up_button': 'Create Account',
          'already_have_account': 'Already have an account?',
          'sign_in_link': 'Sign in',
          'password_required': 'Enter a password',
          'password_min_length': 'Minimum 8 characters',
          'confirm_password_required': 'Confirm your password',
          'passwords_must_match': 'Passwords must match',
          'terms_message': 'By creating an account, you agree to our Terms and Conditions and Privacy Policy'
        },
        'profile_setup': {
          'title': 'Set Up Your Profile',
          'welcome': 'Welcome!',
          'subtitle': 'Complete your profile to start sharing gossip',
          'username_label': 'Username',
          'username_hint': 'johnsmith',
          'username_helper': 'Only lowercase letters, numbers and _',
          'username_taken': 'This username is already taken',
          'username_availability_check': 'Verify that the username is available',
          'display_name_label': 'Display name',
          'display_name_hint': 'John Smith',
          'bio_label': 'Bio (optional)',
          'bio_hint': 'Tell us about yourself...',
          'info_message': 'You need a username to publish gossip',
          'save_button': 'Save Profile',
          'complete_button': 'Complete profile',
          'later_button': 'Later',
          'do_it_later': 'I\'ll do it later',
          'avatar_upload_soon': 'Coming soon: upload avatar'
        },
        'forgot_password': {
          'title': 'Forgot your password?',
          'message': 'We\'ll send you a 6-digit code to recover your password',
          'email_hint': 'Email',
          'send_code_button': 'Send code',
          'code_sent_title': 'Code sent',
          'code_sent_message': 'Check your email for the verification code'
        },
        'reset_password': {
          'title': 'New Password',
          'subtitle': 'Create your new password',
          'description': 'Must be at least 8 characters',
          'new_password_hint': 'New password',
          'confirm_password_hint': 'Confirm password',
          'change_password_button': 'Change password',
          'success_title': 'Password updated',
          'success_message': 'Your password has been successfully updated. You can now sign in with your new password',
          'ok_button': 'OK'
        },
        'otp_verification': {
          'title': 'Verify Code',
          'verify_email_title': 'Verify Email',
          'subtitle_signup': 'We sent a 6-digit code to:',
          'subtitle_reset': 'Enter the code we sent to:',
          'code_hint': 'Code',
          'resend_label': 'Didn\'t receive the code?',
          'resend_button': 'Resend',
          'resend_timer': 'Resend ({seconds}s)',
          'verifying': 'Verifying...'
        },
        'validation': {
          'email_required': 'Email is required',
          'email_invalid': 'Email format is invalid',
          'email_too_long': 'Email is too long (max 254 characters)',
          'password_required': 'Password is required',
          'password_too_short': 'Password is too short (min 8 characters)',
          'password_too_long': 'Password is too long (max 128 characters)',
          'password_needs_lowercase': 'Password must contain at least one lowercase letter',
          'password_needs_uppercase': 'Password must contain at least one uppercase letter',
          'password_needs_number': 'Password must contain at least one number',
          'password_needs_special': 'Password must contain at least one special character',
          'passwords_must_match': 'Passwords must match',
          'username_required': 'Username is required',
          'username_too_short': 'Username is too short (min 3 characters)',
          'username_too_long': 'Username is too long (max 30 characters)',
          'username_invalid_chars': 'Username can only contain lowercase letters, numbers and underscores',
          'username_starts_with_number': 'Username cannot start with a number',
          'username_invalid_underscore': 'Username cannot start or end with underscore',
          'username_reserved': 'Username is reserved',
          'display_name_required': 'Display name is required',
          'display_name_empty': 'Display name cannot be empty',
          'display_name_too_long': 'Display name is too long (max 50 characters)',
          'bio_too_long': 'Bio is too long (max 160 characters)'
        },
        'errors': {
          'invalid_credentials': 'Invalid credentials',
          'email_already_in_use': 'Email already in use',
          'weak_password': 'Password is too weak',
          'user_not_found': 'User not found',
          'network_error': 'Network error',
          'unknown_error': 'Unknown error'
        },
        'password_field': {
          'label': 'Password',
          'show': 'Show password',
          'hide': 'Hide password'
        }
      },
      'errors': {
        'titles': {
          'connection': 'Connection Error',
          'server': 'Server Error',
          'auth': 'Authentication Error',
          'validation': 'Validation Error',
          'data': 'Data Error',
          'permissions': 'Permission Error',
          'general': 'Error',
          'unexpected': 'Unexpected Error'
        },
        'network': {
          'connection_error': 'Connection error. Please check your internet.',
          'timeout': 'The request took too long. Try again.',
          'no_internet': 'You have no internet connection. Check your network.'
        },
        'server': {
          'error': 'Server error. Try again later.',
          'maintenance': 'The server is under maintenance. Try again later.',
          'unavailable': 'The service is temporarily unavailable.',
          'too_many_requests': 'You\'ve reached the request limit. Wait a moment and try again.',
          'bad_request': 'Invalid request. Check the data sent.'
        },
        'auth': {
          'unauthorized': 'You are not authorized to perform this action.',
          'session_expired': 'Your session has expired. Sign in again.',
          'invalid_credentials': 'Incorrect email or password. Please check your data and try again.',
          'email_already_in_use': 'This email is already registered.',
          'weak_password': 'The password is too weak.',
          'user_not_found': 'User not found.',
          'not_authenticated': 'You must sign in to continue.',
          'username_taken': 'This username is already taken.',
          'invalid_token': 'Invalid or expired code. Request a new one.',
          'expired_token': 'Invalid or expired code. Request a new one.',
          'oauth_cancelled': 'Sign in cancelled.',
          'oauth_provider_error': 'Error signing in with provider.',
          'email_not_verified': 'You must verify your email to continue.',
          'too_many_attempts': 'Too many attempts. Try again later.'
        },
        'validation': {
          'error': 'Validation error. Check the entered data.',
          'invalid_input': 'Invalid data. Check the format.',
          'missing_field': 'A required field is missing.'
        },
        'data': {
          'not_found': 'The requested resource does not exist.',
          'already_exists': 'The resource already exists.',
          'conflict': 'Data conflict. Try again.'
        },
        'permissions': {
          'forbidden': 'You don\'t have permission to perform this action.',
          'insufficient': 'Insufficient permissions for this action.'
        },
        'business': {
          'invalid_location': 'Invalid location. Select a valid location.',
          'invalid_gossip_content': 'The gossip content is invalid.',
          'gossip_not_found': 'The gossip does not exist or was deleted.',
          'moderation_rejected': 'The content does not meet our community standards. Please review the content and try again.',
          'media_upload_failed': 'Could not upload the image. Please try again or try another image.',
          'rate_limit_exceeded': 'You\'ve reached the request limit. Wait a moment and try again.'
        },
        'unknown': 'An unexpected error occurred. Try again.'
      },
      'common': {
        'select': 'Select {field}',
        'required_field': 'Required field',
        'min_length': 'Must be at least {count} characters',
        'max_length': 'Cannot exceed {count} characters',
        'enter_email': 'Enter an email',
        'enter_password': 'Enter your password',
        'email_invalid': 'Invalid email',
        'email_hint_placeholder': 'you@email.com',
        'loading': 'Loading...',
        'error': 'Error',
        'success': 'Success',
        'cancel': 'Cancel',
        'confirm': 'Confirm',
        'save': 'Save',
        'delete': 'Delete',
        'edit': 'Edit',
        'back': 'Back',
        'close': 'Close',
        'forget': 'Forget',
        'permanently_delete': 'Permanently delete',
        'retry': 'Retry'
      },
      'navigation': {
        'home': 'Home',
        'explore': 'Explore',
        'create': 'Create',
        'profile': 'Profile'
      },
      'gossip': {
        'detail_screen': {
          'title': 'Detail'
        },
        'add_screen': {
          'title': 'New Gossip 📝',
          'submit_button': 'Publish gossip',
          'success_dialog_title_pending': 'Gossip sent!',
          'success_dialog_title_published': 'Gossip published!',
          'success_dialog_content_pending': 'Your gossip is pending moderation. We\'ll notify you when its status changes.',
          'success_dialog_content_published': 'Your gossip passed automatic checks and is now published.',
          'success_dialog_button': 'OK',
          'email_verification_resent': 'Verification email resent. Check your inbox.'
        },
        'text_fields': {
          'subject_label': 'About who or where?',
          'subject_hint': 'E.g.: John, the office, the gym...',
          'subject_validation': 'Write about who or where the gossip is',
          'content_label': 'The gossip',
          'content_hint': 'Tell us what you know...',
          'content_validation': 'Tell the gossip'
        },
        'location': {
          'city_label': 'City',
          'city_hint': 'Search city...',
          'city_search_hint': 'Search city... (min. {minChars} characters)',
          'country_label': 'Country',
          'country_required': 'Select a country',
          'region_label': 'Region',
          'region_required': 'Select a region',
          'city_required': 'Select a city',
          'search_error': 'Error searching cities. Please try again.',
          'unexpected_error': 'Unexpected error. Please try again.',
          'min_chars_message': 'Type at least {minChars} characters to search',
          'no_results': 'No cities found with "{query}"',
          'change_dialog_title': 'Change location',
          'use_current_location': 'Use my current location',
          'gps_detect_subtitle': 'Detect automatically with GPS',
          'or_select_manually': 'Or select manually'
        },
        'location_selector': {
          'semantic_label_detecting': 'Automatically detecting location',
          'semantic_label_selected': 'Current location: {location}',
          'semantic_label_empty': 'No location selected',
          'semantic_hint': 'Tap the change button to select another location',
          'icon_semantic_label': 'Location icon',
          'detecting_text': 'Detecting location...',
          'placeholder_text': 'Select location',
          'change_button_semantic_label': 'Change location',
          'change_button_semantic_hint': 'Opens the location selector',
          'change_button_label': 'Change'
        },
        'publish_as': {
          'title': 'Publish as',
          'anonymous': 'Anonymous',
          'with_profile': 'With my profile'
        },
        'card': {
          'share_error': 'Error sharing',
          'report_success': 'Thanks for your report. We\'ll review it soon.',
          'report_error': 'Error reporting',
          'rate_limit_error': 'Rate limit reached',
          'semantic_label': 'Gossip: {subject}. {content}',
          'semantic_hint': 'Tap to view full details',
          'share_tooltip': 'Share gossip',
          'share_semantic_label': 'Share this gossip',
          'share_semantic_hint': 'Opens options to share with others',
          'report_tooltip': 'Report gossip',
          'report_semantic_label': 'Report this gossip',
          'report_semantic_hint': 'Opens options to report inappropriate content'
        },
        'media': {
          'camera': 'Camera',
          'gallery': 'Gallery',
          'add_image': 'Add image',
          'add_audio': 'Add audio',
          'audio_attached': 'Audio attached',
          'image_selected': 'Image selected',
          'selecting_image': 'Selecting image...',
          'add_photo_optional': 'Add a photo (optional)',
          'remove_image_tooltip': 'Remove image',
          'image_semantic_label': 'Selected gossip image',
          'remove_image_semantic_label': 'Remove image',
          'remove_image_semantic_hint': 'Removes the selected image',
          'selecting_semantic_label': 'Selecting image, please wait',
          'loading_semantic': 'Loading image',
          'camera_semantic_label': 'Take photo with camera',
          'camera_semantic_hint': 'Opens the camera to take a photo',
          'gallery_semantic_label': 'Select photo from gallery',
          'gallery_semantic_hint': 'Opens the photo gallery'
        },
        'report': {
          'title': 'Report gossip',
          'button': 'Report',
          'reason_question': 'Why are you reporting this gossip?',
          'details_label': 'Additional details (optional)',
          'details_hint': 'Describe the problem...'
        },
        'submit_button': {
          'publish_semantic': 'Publish gossip'
        }
      },
      'profile': {
        'screen': {
          'refresh_tooltip': 'Refresh',
          'error_loading': 'Error loading profile',
          'no_user': 'No authenticated user',
          'sign_out_button': 'Sign out',
          'signing_out': 'Signing out...',
          'sign_out_dialog_title': 'Sign out',
          'sign_out_dialog_content': 'Are you sure you want to sign out?'
        },
        'stats': {
          'title': 'Stats',
          'gossips': 'Gossips',
          'comments': 'Comments',
          'followers': 'Followers',
          'following': 'Following'
        },
        'header': {
          'no_name': 'No name',
          'email_verified': 'Email verified',
          'completeness': 'Profile completeness'
        },
        'controller': {
          'load_error': 'Error loading profile',
          'update_error': 'Error updating settings',
          'signout_error': 'Error signing out'
        },
        'settings': {
          'title': 'Settings',
          'section_notifications': 'Notifications',
          'section_privacy': 'Privacy',
          'section_appearance': 'Appearance',
          'notifications_title': 'Notifications',
          'general_notifications': 'General notifications',
          'general_notifications_subtitle': 'Enable or disable all notifications',
          'push_notifications': 'Push notifications',
          'push_notifications_subtitle': 'Receive push notifications on device',
          'email_notifications': 'Email notifications',
          'daily_summary': 'Daily summary',
          'daily_summary_subtitle': 'Receive daily summary by email',
          'comments': 'Comments',
          'comments_subtitle': 'Notify when someone comments on your gossips',
          'new_followers': 'New followers',
          'new_followers_subtitle': 'Notify when someone follows you',
          'privacy_title': 'Privacy',
          'privacy_level': 'Privacy level',
          'show_email': 'Show email',
          'show_email_subtitle': 'Allow other users to see your email',
          'show_activity': 'Show activity',
          'show_activity_subtitle': 'Show your last activity on profile',
          'appearance_title': 'Appearance',
          'language': 'Language',
          'language_spanish': 'Español',
          'language_english': 'English',
          'dark_mode': 'Dark mode',
          'dark_mode_subtitle': 'Use dark theme in the app',
          'update_error': 'Error updating settings',
          'privacy_dialog_title': 'Privacy level',
          'privacy_public': 'Public',
          'privacy_public_subtitle': 'Everyone can see your profile',
          'privacy_friends': 'Friends',
          'privacy_friends_subtitle': 'Only your friends can see',
          'privacy_private': 'Private',
          'privacy_private_subtitle': 'Only you can see'
        },
        'privacy_settings': {
          'title': 'Privacy',
          'saved_city_title': 'Saved city',
          'anonymous_mode_title': 'Anonymous mode',
          'view_my_data_title': 'View my data',
          'view_my_data_subtitle': 'Data dashboard',
          'privacy_policy_title': 'Privacy Policy',
          'terms_of_use_title': 'Terms of Use',
          'confirm_deletion_title': 'Confirm deletion',
          'deletion_cancelled': 'Deletion cancelled',
          'account_deleted': 'Account deleted',
          'my_data_title': 'My Data',
          'erase_button': 'Erase',
          'export_data_tooltip': 'Export data',
          'no_local_data': 'No local data saved',
          'export_coming_soon': 'Export coming soon',
          'local_data_info_title': 'ℹ️ Local Data',
          'local_data_info_message': 'This data is stored only on your phone (SharedPreferences). It is NOT sent to the server.',
          'sections': {
            'location': '📍 Location',
            'stored_data': '💾 Stored Data',
            'policies': '📄 Policies',
            'account': '🔒 Account'
          },
          'location': {
            'not_saved': 'Not saved',
            'forget_tooltip': 'Forget location',
            'anonymous_mode_subtitle': 'Don\'t save location by default',
            'anonymous_mode_description': 'With anonymous mode on, location will be requested each time you create a gossip.'
          },
          'dialogs': {
            'forget_location_title': 'Forget location?',
            'forget_location_message': 'Your saved city will be deleted. Next time you create a gossip, location will be requested again.',
            'delete_account_title': '⚠️ Delete Account',
            'delete_account_message': 'This will delete:\n• Your account\n• All your gossips\n• All your interactions\n\n⚠️ This action CANNOT be undone.',
            'delete_account_confirm_prompt': 'To confirm, type DELETE',
            'delete_account_confirm_placeholder': 'DELETE',
            'delete_all_data_title': '⚠️ Erase All Data',
            'delete_all_data_message': 'ALL locally stored data will be erased:\n• Saved location\n• Preferences\n• Cache\n\nAre you sure?',
            'privacy_policy_content': 'The complete privacy policy is available at:\n\nhttps://chismes.app/privacy\n\nOr in the PRIVACY_POLICY.md file of the project.',
            'terms_of_use_content': 'The complete terms of use are available at:\n\nhttps://chismes.app/terms\n\nOr in the TERMS_OF_SERVICE.md file of the project.'
          },
          'snackbars': {
            'location_forgotten': '✅ Location forgotten',
            'anonymous_mode_on': '✅ Anonymous mode on',
            'anonymous_mode_off': '✅ Anonymous mode off',
            'data_erased': '✅ Data erased'
          },
          'account': {
            'delete_title': 'Delete account',
            'delete_subtitle': 'Delete your account and all your data'
          }
        },
        'privacy_consent': {
          'title': 'Privacy and Terms',
          'decline_button': 'I don\'t accept, go back'
        }
      },
      'search': {
        'title': 'Search 🔎',
        'hint': 'Search gossips...',
        'empty_state': 'Type to search gossips 🔎',
        'no_results': 'No gossips found 😢'
      },
      'home': {
        'title': 'Gossips 🔥',
        'discover_header': 'Discover 👀',
        'tabs': {
          'popular': 'Popular',
          'following': 'Following'
        },
        'popular': {
          'in_city': 'Popular in {city}',
          'global': 'Popular 🌎',
          'new_gossips_banner': '{count} new gossips · Tap here',
          'empty': 'No gossips available',
          'no_more': 'No more gossips for now 🌙'
        },
        'following': {
          'recommended_badge': '💡 Recommended for you',
          'no_posts_message': '💬 People you follow haven\'t posted yet',
          'empty_state_title': 'You\'re not following anyone yet',
          'empty_state_message': 'Discover interesting people and follow their stories',
          'explore_users_button': 'Explore users',
          'view_popular_link': 'View Popular',
          'feature_not_implemented': 'Feature not implemented yet',
          'use_popular_tab_hint': 'Use the Popular tab above',
          'unexpected_error': 'Unexpected error loading feed',
          'recommended_error': 'Error loading recommendations'
        },
        'error': {
          'load_failed': 'Error loading feed',
          'retry': 'Retry'
        }
      }
    };

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return _enTranslations;
      case 'es':
      default:
        return _esTranslations;
    }
  }
}
