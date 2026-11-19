import 'package:flutter/widgets.dart';

import '../../../../core/error/custom_error_keys.dart';
import '../../../../core/error/error_codes.dart';
import '../../../../core/error/error_messages.dart';

/// Estado para la verificación de OTP
class OtpVerificationState {
  final String email;
  final bool isVerifying;
  final bool isResending;
  final ErrorCode? errorCode;
  final CustomErrorKey? customErrorKey;
  final int remainingSeconds;
  final bool canResend;

  const OtpVerificationState({
    required this.email,
    this.isVerifying = false,
    this.isResending = false,
    this.errorCode,
    this.customErrorKey,
    this.remainingSeconds = 0,
    this.canResend = true,
  });

  /// Obtiene el mensaje de error traducido
  ///
  /// Debe llamarse desde la UI que tiene BuildContext.
  String? getErrorMessage(BuildContext context) {
    if (customErrorKey != null) {
      return customErrorKey!.getMessage(context);
    }

    if (errorCode != null) {
      return ErrorMessages.getMessage(context, errorCode!);
    }

    return null;
  }

  OtpVerificationState copyWith({
    String? email,
    bool? isVerifying,
    bool? isResending,
    ErrorCode? errorCode,
    CustomErrorKey? customErrorKey,
    int? remainingSeconds,
    bool? canResend,
  }) {
    return OtpVerificationState(
      email: email ?? this.email,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      errorCode: errorCode,
      customErrorKey: customErrorKey,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      canResend: canResend ?? this.canResend,
    );
  }

  /// Limpia el error
  OtpVerificationState clearError() {
    return OtpVerificationState(
      email: email,
      isVerifying: isVerifying,
      isResending: isResending,
      errorCode: null,
      customErrorKey: null,
      remainingSeconds: remainingSeconds,
      canResend: canResend,
    );
  }
}
