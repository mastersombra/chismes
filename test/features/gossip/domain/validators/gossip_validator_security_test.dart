import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/features/gossip/domain/entities/create_gossip_input.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/domain/validators/gossip_validator.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/easy_localization_test_helper.dart';
import '../../../../helpers/security_test_helpers.dart';

/// Tests de SEGURIDAD para GossipValidator
///
/// IMPORTANTE: GossipValidator solo valida longitud y campos requeridos
/// NO valida contenido malicioso (HTML, SQL injection) - eso es responsabilidad del backend
///
/// Estos tests verifican que:
/// - Límites de longitud previenen DoS
/// - Errores usan códigos genéricos (no exponen detalles)
/// - No se filtra información sensible en errores
void main() {
  group('GossipValidator - Security Tests', () {
    group('validateSubject - Security', () {
      testWidgets('límites de longitud son seguros', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Exactamente en el límite - OK
        final atLimit = 'a' * GossipValidator.maxSubjectLength;
        expect(GossipValidator.validateSubject(atLimit), isNull);

        // Un carácter más - Error
        final overLimit = 'a' * (GossipValidator.maxSubjectLength + 1);
        final result = GossipValidator.validateSubject(overLimit);

        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);

        // SEGURIDAD: No debe incluir el subject largo en fieldErrors
        if (result?.fieldErrors != null) {
          for (final error in result!.fieldErrors!.values) {
            expect(error.contains(overLimit), isFalse);
            expect(error.length, lessThan(200));
          }
        }
      });

      testWidgets('subjects válidos no generan errores', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        final validSubjects = [
          'Juan Pérez',
          'La oficina',
          '<script>alert("xss")</script>', // Válido (< 200 chars)
        ];

        // NOTA: HTML es válido para el validator local
        // El backend debe sanitizar/rechazar contenido malicioso
        for (final subject in validSubjects) {
          final result = GossipValidator.validateSubject(subject);
          expect(result, isNull);
        }
      });
    });

    group('validateContent - Security', () {
      testWidgets('límites de longitud previenen DoS', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Exactamente en el límite - OK
        final atLimit = 'a' * GossipValidator.maxContentLength;
        expect(GossipValidator.validateContent(atLimit), isNull);

        // Un carácter más - Error
        final overLimit = 'a' * (GossipValidator.maxContentLength + 1);
        final result = GossipValidator.validateContent(overLimit);

        expect(result, isA<ValidationFailure>());

        // SEGURIDAD: No debe incluir todo el contenido largo
        if (result?.fieldErrors != null) {
          for (final error in result!.fieldErrors!.values) {
            expect(error.contains(overLimit), isFalse);
          }
        }
      });

      testWidgets('contenido sensible no aparece en errores', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Content muy largo con datos sensibles
        final sensitiveContent = 'Password: Secret123! Phone: 555-1234. ' * 30;
        final result = GossipValidator.validateContent(sensitiveContent);

        expect(result, isA<ValidationFailure>());

        // SEGURIDAD: No debe exponer el contenido sensible
        if (result?.fieldErrors != null) {
          for (final error in result!.fieldErrors!.values) {
            expect(error, isNot(contains('Secret123')));
            expect(error, isNot(contains('555-1234')));
            SecurityTestHelpers.verifyMessageSecurity(error);
          }
        }
      });
    });

    group('validateLocation - Security', () {
      testWidgets('errores usan código genérico sin detalles', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        final result = GossipValidator.validateLocation(null, null, null);

        expect(result, isA<DataFailure>());
        expect(result?.code, ErrorCode.invalidLocation);

        // SEGURIDAD: DataFailure solo retorna código genérico
        // NO tiene fieldErrors - correcto desde perspectiva de seguridad
        if (result?.technicalMessage != null) {
          SecurityTestHelpers.verifyMessageSecurity(result!.technicalMessage);
        }
      });
    });

    group('validateLocationHierarchy - Security', () {
      testWidgets('no expone estructura completa de ubicaciones',
          (tester) async {
        await initializeEasyLocalizationForTest(tester);

        final country = Country(id: 'AR', code: 'AR', name: 'Argentina');
        final region = Region(
          id: 'CBA',
          countryId: 'AR',
          name: 'Córdoba',
          type: 'province',
        );
        final city = City(id: 'CBA_CITY', regionId: 'CBA', name: 'Córdoba');

        // IDs inconsistentes
        final result = GossipValidator.validateLocationHierarchy(
          countryId: 'AR',
          regionId: 'WRONG',
          cityId: 'CBA_CITY',
          countries: [country],
          regions: [region],
          cities: [city],
        );

        expect(result, isA<DataFailure>());
        expect(result?.code, ErrorCode.invalidLocation);

        // SEGURIDAD: Solo código genérico, no lista de opciones válidas
      });
    });

    group('validateStatusCombination - Security', () {
      testWidgets('error menciona combinación pero no toda la máquina',
          (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Combinación inválida
        final result = GossipValidator.validateStatusCombination(
          gossipStatus: GossipStatus.published,
          moderationStatus: ModerationStatus.rejected,
        );

        expect(result, isA<ValidationFailure>());

        // SEGURIDAD: fieldError menciona la combinación inválida
        // pero NO debe listar TODAS las combinaciones válidas
        if (result?.fieldErrors != null) {
          for (final error in result!.fieldErrors!.values) {
            expect(error, isNot(contains('Valid combinations:')));
            expect(error.length, lessThan(150));

            SecurityTestHelpers.verifyMessageSecurity(
              error,
              maxLength: 150,
              additionalForbidden: ['state machine'],
            );
          }
        }
      });
    });

    group('validateInput - Integration Security', () {
      testWidgets('validación completa no expone datos sensibles',
          (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Input con subject muy largo
        final input = CreateGossipInput(
          subject: 'a' * 201,
          content: 'Admin password: Secret123',
          countryId: '',
          regionId: '',
          cityId: '',
          publishedAs: PublishAs.profile,
          idempotencyKey: 'test-key',
        );

        final result = GossipValidator.validateInput(input);

        expect(result, isA<Failure>());

        // SEGURIDAD: No expone el contenido sensible
        if (result?.technicalMessage != null) {
          expect(result!.technicalMessage, isNot(contains('Secret123')));
          SecurityTestHelpers.verifyMessageSecurity(result.technicalMessage);
        }
      });
    });

    group('General Security Compliance', () {
      testWidgets('límites previenen DoS', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Verificar límites razonables
        expect(GossipValidator.maxSubjectLength, 200);
        expect(GossipValidator.maxContentLength, 1000);

        // Intentar DoS con strings extremadamente largos
        final hugeSubject = 'a' * 100000;
        final result = GossipValidator.validateSubject(hugeSubject);

        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);

        // CRÍTICO: El error NO debe incluir el string largo
        if (result?.fieldErrors != null) {
          for (final error in result!.fieldErrors!.values) {
            expect(error.length, lessThan(500));
            expect(error.contains(hugeSubject), isFalse);
          }
        }
      });

      testWidgets('validación es consistente y predecible', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Mismo input debe dar mismo resultado (no debe haber race conditions)
        final input = 'test' * 100;

        for (var i = 0; i < 5; i++) {
          final result = GossipValidator.validateSubject(input);
          expect(result?.code, ErrorCode.invalidInput);
        }
      });

      testWidgets('errores no contienen stack traces', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Inputs extremos que podrían causar exceptions
        final edgeCases = ['', ' ' * 1000, '\n' * 500];

        for (final input in edgeCases) {
          final result = GossipValidator.validateSubject(input);

          if (result?.fieldErrors != null) {
            for (final error in result!.fieldErrors!.values) {
              expect(error, isNot(matches(RegExp(r'at\s+\w+\.\w+\('))));
              expect(error, isNot(contains('Exception')));
            }
          }
        }
      });
    });
  });
}
