/// Códigos de error centralizados para toda la aplicación
/// Cada código representa un tipo específico de error
enum ErrorCode {
  // Errores de red
  networkError,
  timeoutError,
  noInternetConnection,

  // Errores de servidor
  serverError,
  serverMaintenance,
  serviceUnavailable,
  tooManyRequests, // 429 - Rate limit (Supabase)
  badRequest, // 400 - Bad request genérico (Supabase)

  // Errores de autenticación
  unauthorized,
  sessionExpired,
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  userNotFound,
  userNotAuthenticated,
  usernameAlreadyTaken,
  invalidToken,
  expiredToken,
  oauthCancelled,
  oauthProviderError,
  emailNotVerified,
  tooManyLoginAttempts,

  // Errores de validación
  validationError,
  invalidInput,
  missingRequiredField,

  // Errores de datos
  notFound,
  alreadyExists,
  conflict,

  // Errores de permisos
  forbidden,
  insufficientPermissions,

  // Errores de negocio específicos
  invalidLocation,
  invalidGossipContent,
  gossipNotFound,
  moderationRejected, // Contenido rechazado por moderación
  mediaUploadFailed, // Fallo al subir imagen/audio
  rateLimitExceeded, // Rate limit excedido (específico de gossip)

  // Errores desconocidos
  unknownError,
}
