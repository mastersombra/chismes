import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:chismes/core/error/error_handler.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/app_exception.dart';

void main() {
  group('ErrorHandler', () {
    test('debe manejar SocketException como NetworkFailure', () {
      final error = SocketException('No internet');
      
      final result = ErrorHandler.handleError(error);
      
      expect(result, isA<NetworkFailure>());
      expect(result.code, ErrorCode.noInternetConnection);
    });

    test('debe manejar HttpException como ServerFailure con technicalMessage', () {
      final error = HttpException('404 Not Found');
      
      final result = ErrorHandler.handleError(error);
      
      expect(result, isA<ServerFailure>());
      expect(result.code, ErrorCode.serverError);
      expect(result.technicalMessage, '404 Not Found');
    });

    test('debe manejar FormatException como ValidationFailure con technicalMessage', () {
      final error = FormatException('Invalid format');
      
      final result = ErrorHandler.handleError(error);
      
      expect(result, isA<ValidationFailure>());
      expect(result.code, ErrorCode.invalidInput);
      expect(result.technicalMessage, 'Invalid format');
    });

    test('debe manejar Supabase AuthException 403 (Forbidden) como PermissionFailure', () {
      final error = supabase.AuthException('Forbidden', statusCode: '403');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<PermissionFailure>());
      expect(result.code, ErrorCode.forbidden);
    });

    test('debe manejar Supabase AuthException 404 (Not Found) como AuthFailure', () {
      final error = supabase.AuthException('User not found', statusCode: '404');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<AuthFailure>());
      expect(result.code, ErrorCode.notFound);
    });

    test('debe manejar Supabase AuthException 400 (Invalid credentials) como AuthFailure', () {
      final error = supabase.AuthException('Invalid login credentials', statusCode: '400');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<AuthFailure>());
      expect(result.code, ErrorCode.invalidCredentials);
    });

    test('debe manejar Supabase AuthException 422 (Already exists) como ValidationFailure', () {
      final error = supabase.AuthException('User already registered', statusCode: '422');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ValidationFailure>());
      expect(result.code, ErrorCode.alreadyExists);
    });

    test('debe manejar Supabase AuthException 401 (Unauthorized) como AuthFailure', () {
      final error = supabase.AuthException('Unauthorized', statusCode: '401');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<AuthFailure>());
      expect(result.code, ErrorCode.unauthorized);
    });

    test('debe manejar Supabase AuthException 429 (Rate limit) como ServerFailure', () {
      final error = supabase.AuthException('Too many requests', statusCode: '429');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ServerFailure>());
      expect(result.code, ErrorCode.tooManyRequests);
    });

    test('debe manejar Supabase PostgrestException (Row not found) como DataFailure', () {
      final error = supabase.PostgrestException(message: 'Row not found', code: 'PGRST116');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<DataFailure>());
      expect(result.code, ErrorCode.notFound);
    });

    test('debe manejar Supabase PostgrestException (Unique violation) como DataFailure', () {
      final error = supabase.PostgrestException(message: 'Duplicate key', code: '23505');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<DataFailure>());
      expect(result.code, ErrorCode.alreadyExists);
    });

    test('debe manejar Supabase PostgrestException (Permission denied) como PermissionFailure', () {
      final error = supabase.PostgrestException(message: 'Permission denied', code: 'PGRST301');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<PermissionFailure>());
      expect(result.code, ErrorCode.forbidden);
    });

    test('debe manejar Supabase StorageException 404 como DataFailure', () {
      final error = supabase.StorageException('File not found', statusCode: '404');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<DataFailure>());
      expect(result.code, ErrorCode.notFound);
    });

    test('debe manejar Supabase StorageException 413 (File too large) como ValidationFailure', () {
      final error = supabase.StorageException('Payload too large', statusCode: '413');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ValidationFailure>());
      expect(result.code, ErrorCode.invalidInput);
    });

    test('debe manejar errores desconocidos como Failure genérico', () {
      final error = Exception('Unknown error');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<Failure>());
      expect(result.code, ErrorCode.unknownError);
      expect(result.technicalMessage, isNotNull);
    });

    test('debe retornar Failure tal cual si el error ya es un Failure', () {
      const error = NetworkFailure(code: ErrorCode.networkError);

      final result = ErrorHandler.handleError(error);

      expect(result, same(error));
      expect(result, isA<NetworkFailure>());
    });

    test('debe convertir NetworkException a NetworkFailure', () {
      const error = NetworkException(
        code: ErrorCode.networkError,
        technicalMessage: 'Connection failed',
      );

      final result = ErrorHandler.handleError(error);

      expect(result, isA<NetworkFailure>());
      expect(result.code, ErrorCode.networkError);
      expect(result.technicalMessage, 'Connection failed');
    });

    test('debe convertir ServerException a ServerFailure', () {
      const error = ServerException(
        code: ErrorCode.serverError,
        technicalMessage: 'Internal server error',
      );

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ServerFailure>());
      expect(result.code, ErrorCode.serverError);
      expect(result.technicalMessage, 'Internal server error');
    });

    test('debe convertir AuthException a AuthFailure', () {
      const error = AuthException(
        code: ErrorCode.unauthorized,
        technicalMessage: 'Not authorized',
      );

      final result = ErrorHandler.handleError(error);

      expect(result, isA<AuthFailure>());
      expect(result.code, ErrorCode.unauthorized);
      expect(result.technicalMessage, 'Not authorized');
    });

    test('debe convertir ValidationException a ValidationFailure con fieldErrors', () {
      const error = ValidationException(
        code: ErrorCode.validationError,
        technicalMessage: 'Validation failed',
        fieldErrors: {'email': 'Invalid'},
      );

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ValidationFailure>());
      expect(result.code, ErrorCode.validationError);
      expect(result.technicalMessage, 'Validation failed');
      expect((result as ValidationFailure).fieldErrors, {'email': 'Invalid'});
    });

    test('debe convertir DataException a DataFailure', () {
      const error = DataException(
        code: ErrorCode.notFound,
        technicalMessage: 'Record not found',
      );

      final result = ErrorHandler.handleError(error);

      expect(result, isA<DataFailure>());
      expect(result.code, ErrorCode.notFound);
      expect(result.technicalMessage, 'Record not found');
    });

    test('debe convertir PermissionException a PermissionFailure', () {
      const error = PermissionException(
        code: ErrorCode.forbidden,
        technicalMessage: 'Access denied',
      );

      final result = ErrorHandler.handleError(error);

      expect(result, isA<PermissionFailure>());
      expect(result.code, ErrorCode.forbidden);
      expect(result.technicalMessage, 'Access denied');
    });

    test('debe convertir UnknownException a Failure genérico', () {
      const error = UnknownException(
        code: ErrorCode.unknownError,
        technicalMessage: 'Something went wrong',
      );

      final result = ErrorHandler.handleError(error);

      expect(result, isA<Failure>());
      expect(result.code, ErrorCode.unknownError);
      expect(result.technicalMessage, 'Something went wrong');
    });

    // AuthException adicionales
    test('debe manejar AuthException 400 con "email not confirmed"', () {
      final error = supabase.AuthException('Email not confirmed', statusCode: '400');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ValidationFailure>());
      expect(result.code, ErrorCode.validationError);
      expect(result.technicalMessage, 'Email no confirmado');
    });

    test('debe manejar AuthException 400 genérico como ValidationFailure', () {
      final error = supabase.AuthException('Bad request', statusCode: '400');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ValidationFailure>());
      expect(result.code, ErrorCode.badRequest);
    });

    test('debe manejar AuthException 422 con "already exists"', () {
      final error = supabase.AuthException('Email already exists', statusCode: '422');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ValidationFailure>());
      expect(result.code, ErrorCode.alreadyExists);
    });

    test('debe manejar AuthException 422 genérico', () {
      final error = supabase.AuthException('Unprocessable entity', statusCode: '422');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ValidationFailure>());
      expect(result.code, ErrorCode.validationError);
    });

    test('debe manejar AuthException 500', () {
      final error = supabase.AuthException('Internal error', statusCode: '500');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ServerFailure>());
      expect(result.code, ErrorCode.serverError);
    });

    test('debe manejar AuthException 502', () {
      final error = supabase.AuthException('Bad gateway', statusCode: '502');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ServerFailure>());
      expect(result.code, ErrorCode.serverError);
    });

    test('debe manejar AuthException 503', () {
      final error = supabase.AuthException('Service unavailable', statusCode: '503');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ServerFailure>());
      expect(result.code, ErrorCode.serverError);
    });

    test('debe manejar AuthException con código desconocido', () {
      final error = supabase.AuthException('Unknown', statusCode: '999');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<AuthFailure>());
      expect(result.code, ErrorCode.unknownError);
    });

    // PostgrestException adicionales
    test('debe manejar PostgrestException 23503 (foreign_key_violation)', () {
      final error = supabase.PostgrestException(message: 'Foreign key violation', code: '23503');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ValidationFailure>());
      expect(result.code, ErrorCode.conflict);
    });

    test('debe manejar PostgrestException 42P01 (undefined_table)', () {
      final error = supabase.PostgrestException(message: 'Table does not exist', code: '42P01');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<DataFailure>());
      expect(result.code, ErrorCode.notFound);
    });

    test('debe manejar PostgrestException 42703 (undefined_column)', () {
      final error = supabase.PostgrestException(message: 'Column does not exist', code: '42703');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<DataFailure>());
      expect(result.code, ErrorCode.notFound);
    });

    test('debe manejar PostgrestException con código desconocido', () {
      final error = supabase.PostgrestException(message: 'Unknown error', code: 'UNKNOWN');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ServerFailure>());
      expect(result.code, ErrorCode.serverError);
    });

    // StorageException adicionales
    test('debe manejar StorageException 400', () {
      final error = supabase.StorageException('Bad request', statusCode: '400');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ValidationFailure>());
      expect(result.code, ErrorCode.badRequest);
    });

    test('debe manejar StorageException 403', () {
      final error = supabase.StorageException('Forbidden', statusCode: '403');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<PermissionFailure>());
      expect(result.code, ErrorCode.forbidden);
    });

    test('debe manejar StorageException con código desconocido', () {
      final error = supabase.StorageException('Unknown', statusCode: '999');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ServerFailure>());
      expect(result.code, ErrorCode.serverError);
    });

    test('debe manejar StorageException sin statusCode', () {
      final error = supabase.StorageException('Storage error');

      final result = ErrorHandler.handleError(error);

      expect(result, isA<ServerFailure>());
      expect(result.code, ErrorCode.serverError);
    });

    test('debe manejar error con stackTrace', () {
      final error = Exception('Error with trace');
      final stackTrace = StackTrace.current;

      final result = ErrorHandler.handleError(error, stackTrace);

      expect(result, isA<Failure>());
      expect(result.code, ErrorCode.unknownError);
    });
  });

  group('ErrorHandler.throwException', () {
    test('debe convertir NetworkFailure a NetworkException', () {
      const failure = NetworkFailure(
        code: ErrorCode.networkError,
        technicalMessage: 'Network failed',
      );

      final exception = ErrorHandler.throwException(failure);

      expect(exception, isA<NetworkException>());
      expect(exception.code, ErrorCode.networkError);
      expect(exception.technicalMessage, 'Network failed');
    });

    test('debe convertir ServerFailure a ServerException', () {
      const failure = ServerFailure(
        code: ErrorCode.serverError,
        technicalMessage: 'Server error',
      );

      final exception = ErrorHandler.throwException(failure);

      expect(exception, isA<ServerException>());
      expect(exception.code, ErrorCode.serverError);
      expect(exception.technicalMessage, 'Server error');
    });

    test('debe convertir AuthFailure a AuthException', () {
      const failure = AuthFailure(
        code: ErrorCode.unauthorized,
        technicalMessage: 'Not authorized',
      );

      final exception = ErrorHandler.throwException(failure);

      expect(exception, isA<AuthException>());
      expect(exception.code, ErrorCode.unauthorized);
      expect(exception.technicalMessage, 'Not authorized');
    });

    test('debe convertir ValidationFailure a ValidationException con fieldErrors', () {
      const failure = ValidationFailure(
        code: ErrorCode.validationError,
        technicalMessage: 'Validation failed',
        fieldErrors: {'field': 'error'},
      );

      final exception = ErrorHandler.throwException(failure);

      expect(exception, isA<ValidationException>());
      expect(exception.code, ErrorCode.validationError);
      expect(exception.technicalMessage, 'Validation failed');
      expect((exception as ValidationException).fieldErrors, {'field': 'error'});
    });

    test('debe convertir DataFailure a DataException', () {
      const failure = DataFailure(
        code: ErrorCode.notFound,
        technicalMessage: 'Not found',
      );

      final exception = ErrorHandler.throwException(failure);

      expect(exception, isA<DataException>());
      expect(exception.code, ErrorCode.notFound);
      expect(exception.technicalMessage, 'Not found');
    });

    test('debe convertir PermissionFailure a PermissionException', () {
      const failure = PermissionFailure(
        code: ErrorCode.forbidden,
        technicalMessage: 'Forbidden',
      );

      final exception = ErrorHandler.throwException(failure);

      expect(exception, isA<PermissionException>());
      expect(exception.code, ErrorCode.forbidden);
      expect(exception.technicalMessage, 'Forbidden');
    });

    test('debe convertir Failure genérico a UnknownException', () {
      const failure = Failure(
        code: ErrorCode.unknownError,
        technicalMessage: 'Unknown',
      );

      final exception = ErrorHandler.throwException(failure);

      expect(exception, isA<UnknownException>());
      expect(exception.code, ErrorCode.unknownError);
      expect(exception.technicalMessage, 'Unknown');
    });
  });
}
