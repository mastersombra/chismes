import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/gossip/presentation/states/add_gossip_state.dart';
import 'package:chismes/core/error/failure.dart';

/// Helper para configurar MockAddGossipController con valores por defecto.
///
/// Este helper centraliza la configuración del mock para evitar duplicación
/// y garantizar que todos los ValueNotifiers estén correctamente stubbed.
///
/// Uso básico:
/// ```dart
/// final mock = MockAddGossipController();
/// setupMockAddGossipController(mock);
/// ```
///
/// Con estado personalizado:
/// ```dart
/// setupMockAddGossipController(
///   mock,
///   state: const AddGossipState(isLoadingCountries: true),
///   locationDisplayText: 'México',
/// );
/// ```
void setupMockAddGossipController(
  dynamic mock, {
  AddGossipState? state,
  String? locationDisplayText,
  String? imageUrl,
  bool? isUploadingImage,
  bool? isSubmitting,
  Failure? failure,
  String? selectedCityId,
}) {
  // ✅ Estado básico
  when(mock.state).thenReturn(state ?? const AddGossipState(idempotencyKey: 'test-key'));
  when(mock.locationDisplayText)
      .thenReturn(locationDisplayText ?? 'Ubicación no seleccionada');

  // ✅ Listeners (requeridos por ChangeNotifier/AnimatedBuilder)
  when(mock.addListener(any)).thenReturn(null);
  when(mock.removeListener(any)).thenReturn(null);

  // ✅ ValueNotifiers (optimización de rebuilds granulares)
  // Estos son críticos para evitar MissingStubError en widgets que usan
  // ValueListenableBuilder (ImagePickerWidget, SubmitButton, ErrorMessage)
  when(mock.imageNotifier).thenReturn(
    ValueNotifier<String?>(imageUrl),
  );

  when(mock.isUploadingImageNotifier).thenReturn(
    ValueNotifier<bool>(isUploadingImage ?? false),
  );

  when(mock.isSubmittingNotifier).thenReturn(
    ValueNotifier<bool>(isSubmitting ?? false),
  );

  when(mock.failureNotifier).thenReturn(
    ValueNotifier<Failure?>(failure),
  );

  when(mock.selectedCityIdNotifier).thenReturn(
    ValueNotifier<String?>(selectedCityId),
  );
}

/// Configuración del mock para estado de carga.
///
/// Útil para tests de loading states.
void setupMockAddGossipControllerLoading(
  dynamic mock, {
  bool isLoadingCountries = false,
  bool isLoadingRegions = false,
  bool isLoadingCities = false,
  bool isSubmitting = false,
  bool isUploadingImage = false,
}) {
  setupMockAddGossipController(
    mock,
    state: AddGossipState(
      idempotencyKey: 'test-key',
      isLoadingCountries: isLoadingCountries,
      isLoadingRegions: isLoadingRegions,
      isLoadingCities: isLoadingCities,
    ),
    isSubmitting: isSubmitting,
    isUploadingImage: isUploadingImage,
  );
}

/// Configuración del mock para estado de error.
///
/// Útil para tests de error handling.
void setupMockAddGossipControllerWithError(
  dynamic mock, {
  required Failure failure,
}) {
  setupMockAddGossipController(
    mock,
    state: AddGossipState(idempotencyKey: 'test-key', failure: failure),
    failure: failure,
  );
}
