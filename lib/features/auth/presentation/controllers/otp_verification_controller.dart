import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/logging/logging.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../states/otp_verification_state.dart';

/// Controller para verificación de OTP
@injectable
class OtpVerificationController extends ChangeNotifier {
  final AuthRepository _authRepository;
  final AppLogger _logger;

  OtpVerificationState _state;
  OtpVerificationState get state => _state;

  Timer? _resendTimer;

  OtpVerificationController({
    required AuthRepository authRepository,
    required AppLogger logger,
    required String email,
  })  : _authRepository = authRepository,
        _logger = logger,
        _state = OtpVerificationState(email: email);

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  /// Verifica el código OTP
  Future<bool> verifyOTP(String code) async {
    if (code.length != 6) {
      _updateState(_state.copyWith(
        errorMessage: 'El código debe tener 6 dígitos',
      ));
      return false;
    }

    _logger.i('Verifying OTP', context: {'email': _state.email});
    _updateState(_state.copyWith(
      isVerifying: true,
      errorMessage: '',
    ));

    final result = await _authRepository.verifyOTP(
      email: _state.email,
      token: code,
    );

    return result.when(
      onSuccess: (user) {
        _logger.i('OTP verified successfully', context: {'userId': user.id});
        _updateState(_state.copyWith(isVerifying: false));
        return true;
      },
      onFailure: (failure) {
        _logger.w('OTP verification failed', context: {'code': failure.code});
        final message = ErrorMessages.getMessage(failure.code);
        _updateState(_state.copyWith(
          isVerifying: false,
          errorMessage: message,
        ));
        return false;
      },
    );
  }

  /// Reenvía el código OTP
  Future<void> resendOTP() async {
    if (!_state.canResend) {
      _logger.d('Cannot resend OTP yet', context: {
        'remainingSeconds': _state.remainingSeconds,
      });
      return;
    }

    _logger.i('Resending OTP', context: {'email': _state.email});
    _updateState(_state.copyWith(
      isResending: true,
      errorMessage: '',
    ));

    final result = await _authRepository.resendOTP(
      email: _state.email,
    );

    result.when(
      onSuccess: (_) {
        _logger.i('OTP resent successfully');
        _updateState(_state.copyWith(
          isResending: false,
          canResend: false,
          remainingSeconds: 60,
        ));
        _startResendTimer();
      },
      onFailure: (failure) {
        _logger.w('Resend OTP failed', context: {'code': failure.code});
        final message = ErrorMessages.getMessage(failure.code);
        _updateState(_state.copyWith(
          isResending: false,
          errorMessage: message,
        ));
      },
    );
  }

  /// Limpia el error
  void clearError() {
    _updateState(_state.clearError());
  }

  /// Actualiza el estado y notifica
  void _updateState(OtpVerificationState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Inicia el timer para reenviar OTP
  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.remainingSeconds > 0) {
        _updateState(_state.copyWith(
          remainingSeconds: _state.remainingSeconds - 1,
        ));
      } else {
        timer.cancel();
        _updateState(_state.copyWith(canResend: true));
      }
    });
  }
}
