/// Estado para la verificación de OTP
class OtpVerificationState {
  final String email;
  final bool isVerifying;
  final bool isResending;
  final String? errorMessage;
  final int remainingSeconds;
  final bool canResend;

  const OtpVerificationState({
    required this.email,
    this.isVerifying = false,
    this.isResending = false,
    this.errorMessage,
    this.remainingSeconds = 0,
    this.canResend = true,
  });

  OtpVerificationState copyWith({
    String? email,
    bool? isVerifying,
    bool? isResending,
    String? errorMessage,
    int? remainingSeconds,
    bool? canResend,
  }) {
    return OtpVerificationState(
      email: email ?? this.email,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      errorMessage: errorMessage,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      canResend: canResend ?? this.canResend,
    );
  }

  /// Limpia el error
  OtpVerificationState clearError() {
    return copyWith(errorMessage: '');
  }
}
