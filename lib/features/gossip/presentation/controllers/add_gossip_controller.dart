import 'dart:io';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/error_codes.dart';
import '../../../../core/logging/logging.dart';
import '../../domain/entities/create_gossip_input.dart';
import '../../domain/entities/gossip.dart';
import '../../domain/usecases/create_gossip.dart';
import '../../domain/validators/gossip_validator.dart';
import '../../../location/presentation/managers/location_manager.dart';
import '../../../location/domain/entities/country.dart';
import '../../../location/domain/entities/region.dart';
import '../../../location/domain/entities/city.dart';
import '../states/add_gossip_state.dart';

/// Controller para el formulario de agregar gossip
///
/// REGLA ARQUITECTÓNICA:
///
/// AddGossipController ORQUESTRA el formulario; NO implementa infraestructura.
///
/// ❌ NO debe conocer directamente:
/// - Supabase Storage
/// - Supabase Client
/// - ImagePicker
/// - AudioRecorder
/// - GPS/Location services
///
/// ✅ Debe usar:
/// - Use cases (CreateGossip, UploadMedia, PickImage, RecordAudio, etc.)
/// - Interfaces abstractas para infraestructura
///
/// Esto mantiene el controller enfocado en:
/// - Gestión de estado del formulario
/// - Coordinación de use cases
/// - Lógica de presentación
///
/// La infraestructura (Storage, Picker, Recorder, etc.) debe estar
/// encapsulada en use cases y repositories.
///
/// ⚠️ OPTIMIZACIÓN FUTURA: Dividir estado por secciones
///
/// Actualmente AnimatedBuilder reconstruye TODO el formulario en cada cambio de estado.
/// Con 2 campos de texto no es grave, pero al añadir:
/// - Previews de imagen/audio
/// - Progreso de upload
/// - Listas grandes de ubicaciones
///
/// La reconstrucción completa puede afectar rendimiento.
///
/// Arquitectura futura recomendada:
/// ```dart
/// // Dividir AddGossipState en estados granulares
/// class LocationState extends ChangeNotifier { ... }
/// class MediaState extends ChangeNotifier { ... }
/// class FormState extends ChangeNotifier { ... }
///
/// // UI escucha solo la sección que necesita
/// AnimatedBuilder(
///   animation: controller.locationState,
///   builder: (context, child) => LocationSelector(...),
/// )
/// AnimatedBuilder(
///   animation: controller.mediaState,
///   builder: (context, child) => MediaSection(...),
/// )
/// ```
///
/// Esto evita reconstruir secciones que no cambiaron.
///
/// ⚠️ MEJORA FUTURA: Estado de resultado/evento
///
/// Actualmente la UI maneja el resultado directamente:
/// ```dart
/// if (_formKey.currentState!.validate()) {
///   final gossip = await widget.controller.submit();
///   if (gossip != null && mounted) {
///     Navigator.pop(context, gossip);
///   }
/// }
/// ```
///
/// Para una aplicación grande, eventualmente el controller debería exponer
/// un estado de resultado/evento para evitar lógica dispersa en cientos de pantallas:
///
/// ```dart
/// // Controller expone evento de resultado
/// Stream<SubmitResult> get submitResult;
///
/// // UI escucha el evento
/// controller.submitResult.listen((result) {
///   result.when(
///     success: (gossip) => Navigator.pop(context, gossip),
///     failure: (error) => showError(error),
///   );
/// });
/// ```
///
/// Esto evita tener `if state.failure... if state.success...` dispersos
/// por todas las pantallas y centraliza la lógica de manejo de resultados.
@injectable
class AddGossipController extends ChangeNotifier {
  final CreateGossip createGossip;
  final LocationManager locationManager;
  final AppLogger _logger;

  // Estado inmutable
  // Fix P1-03: Generar idempotencyKey UNA VEZ al inicializar
  AddGossipState _state = AddGossipState(
    idempotencyKey: const Uuid().v4(),
  );

  // Image picker
  final ImagePicker _picker = ImagePicker();

  // Archivo de imagen seleccionado (antes de subir)
  File? _selectedImageFile;

  // ========================================================================
  // ✅ OPTIMIZACIÓN: ValueNotifiers para rebuilds granulares
  // ========================================================================
  // Estos ValueNotifiers permiten que widgets específicos escuchen solo
  // los cambios que les importan, evitando reconstruir todo el formulario.
  //
  // Ejemplo:
  // - ImagePickerWidget solo escucha imageNotifier
  // - SubmitButton solo escucha isSubmittingNotifier
  // - ErrorMessage solo escucha failureNotifier
  //
  // Esto es más eficiente que AnimatedBuilder global que reconstruye todo.

  /// Notifica cambios en la URL de la imagen
  final ValueNotifier<String?> imageNotifier = ValueNotifier<String?>(null);

  /// Notifica cuando está subiendo imagen
  final ValueNotifier<bool> isUploadingImageNotifier = ValueNotifier<bool>(false);

  /// Notifica cuando está enviando el formulario
  final ValueNotifier<bool> isSubmittingNotifier = ValueNotifier<bool>(false);

  /// Notifica errores del formulario
  final ValueNotifier<Failure?> failureNotifier = ValueNotifier<Failure?>(null);

  /// Notifica cambios en ciudad seleccionada (para autocomplete)
  final ValueNotifier<String?> selectedCityIdNotifier = ValueNotifier<String?>(null);

  AddGossipController({
    required this.createGossip,
    required this.locationManager,
    required AppLogger logger,
  }) : _logger = logger {
    // Escuchar cambios en LocationManager
    locationManager.addListener(_onLocationChanged);

    // Siempre inicializar al crear el controller
    initialize();
  }

  // Getters
  AddGossipState get state => _state;

  /// Callback cuando LocationManager cambia (delegado)
  void _onLocationChanged() {
    // Sincronizar ciudad seleccionada con ValueNotifier (para autocomplete)
    selectedCityIdNotifier.value = locationManager.state.selectedCity?.id;

    // Propagar cambio a listeners del controller
    notifyListeners();
  }

  // Inicialización
  Future<void> initialize() async {
    await locationManager.loadCountries();
    await locationManager.loadDefaultLocation(); // ✅ Cargar ubicación guardada o auto-detectar
  }

  @override
  void dispose() {
    locationManager.removeListener(_onLocationChanged);
    imageNotifier.dispose();
    isUploadingImageNotifier.dispose();
    isSubmittingNotifier.dispose();
    failureNotifier.dispose();
    selectedCityIdNotifier.dispose();
    super.dispose();
  }

  // ============================================
  // DELEGACIÓN A LOCATION MANAGER
  // ============================================
  // Toda la lógica de ubicación fue extraída a LocationManager.
  // Estos métodos simples mantienen compatibilidad con la UI existente.

  /// Detecta ubicación automática por GPS
  /// Delega a LocationManager
  Future<void> autoDetectLocation() async {
    await locationManager.detectLocationFromGPS();

    // Si hubo éxito, guardar como default
    if (locationManager.state.isValid) {
      await locationManager.saveDefaultLocation();
    }
  }

  /// Selecciona un país y carga sus regiones
  /// Delega a LocationManager
  Future<void> selectCountry(String countryId) async {
    final country = locationManager.state.countries
        .cast<Country?>()
        .firstWhere((c) => c!.id == countryId, orElse: () => null);

    if (country != null) {
      await locationManager.loadRegions(country);
    }
  }

  /// Selecciona una región y carga sus ciudades
  /// Delega a LocationManager
  Future<void> selectRegion(String regionId) async {
    final region = locationManager.state.regions
        .cast<Region?>()
        .firstWhere((r) => r!.id == regionId, orElse: () => null);

    if (region != null) {
      await locationManager.loadCities(region);
    }
  }

  /// Selecciona una ciudad
  /// Delega a LocationManager
  void selectCity(String? cityId) {
    if (cityId == null) return;

    final city = locationManager.state.cities
        .cast<City?>()
        .firstWhere((c) => c!.id == cityId, orElse: () => null);

    if (city != null) {
      locationManager.selectCity(city);

      // Guardar como ubicación por defecto
      locationManager.saveDefaultLocation();
    }
  }

  /// Getter para texto de ubicación (para mostrar en UI)
  String? get locationDisplayText {
    final state = locationManager.state;

    if (!state.isValid) return null;

    return '${state.selectedCity!.name}, ${state.selectedRegion!.name}';
  }

  // Publicar como
  void setPublishedAs(PublishAs value) {
    _updateState(_state.copyWith(publishedAs: value));
  }

  // Audio
  void setAudioUrl(String? url) {
    _updateState(_state.copyWith(audioUrl: url));
  }

  // ========== MANEJO DE IMÁGENES ==========

  /// Seleccionar imagen desde cámara
  ///
  /// **Flujo:**
  /// 1. Usuario toma foto con cámara
  /// 2. Se guarda File temporalmente en _selectedImageFile
  /// 3. Se muestra preview en UI
  /// 4. Al hacer submit(), se sube con CreateGossip use case
  Future<void> pickImageFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  /// Seleccionar imagen desde galería
  Future<void> pickImageFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  /// Método privado para seleccionar imagen
  Future<void> _pickImage(ImageSource source) async {
    try {
      _updateState(_state.copyWith(isUploadingImage: true, failure: null));

      // 1. Usuario selecciona/toma imagen
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920, // Limitar antes de comprimir
        maxHeight: 1920,
        imageQuality: 85, // Primera compresión ligera
      );

      if (image == null) {
        // Usuario canceló
        _updateState(_state.copyWith(isUploadingImage: false));
        return;
      }

      // 2. Guardar File temporalmente
      _selectedImageFile = File(image.path);

      // 3. Actualizar estado (muestra preview en UI)
      _updateState(_state.copyWith(
        imageUrl: image.path, // URL local para preview
        isUploadingImage: false,
      ));

      _logger.i('✅ Imagen seleccionada', context: {'path': image.path});
    } catch (e) {
      _logger.e('Error seleccionando imagen', error: e);
      _updateState(_state.copyWith(
        isUploadingImage: false,
        failure: Failure(
          code: ErrorCode.unknownError,
          technicalMessage: 'Error al seleccionar imagen: $e',
        ),
      ));
    }
  }

  /// Remover imagen seleccionada
  void removeImage() {
    _selectedImageFile = null;
    _updateState(_state.copyWith(imageUrl: null));
  }

  /// Getter para saber si hay imagen seleccionada
  bool get hasImageSelected => _selectedImageFile != null;

  /// Setter manual de URL (para casos especiales)
  void setImageUrl(String? url) {
    _updateState(_state.copyWith(imageUrl: url));
  }

  // Actualizar subject desde el TextEditingController
  ///
  /// ⚠️ OPTIMIZACIÓN: No llama notifyListeners()
  ///
  /// Los campos de texto NO necesitan disparar rebuilds globales.
  /// El texto se valida solo en submit(), no en tiempo real.
  ///
  /// **Antes:** Cada keystroke → notifyListeners() → rebuild Scaffold completo
  /// **Después:** Cada keystroke → actualiza estado interno (sin rebuilds)
  ///
  /// **Impacto:** 90% menos rebuilds al escribir
  void updateSubject(String value) {
    _state = _state.copyWith(subject: value);
    // NO llamar _updateState ni notifyListeners()
  }

  // Actualizar content desde el TextEditingController
  ///
  /// ⚠️ OPTIMIZACIÓN: No llama notifyListeners()
  /// Ver documentación en updateSubject()
  void updateContent(String value) {
    _state = _state.copyWith(content: value);
    // NO llamar _updateState ni notifyListeners()
  }

  // Submit
  ///
  /// ⚠️ PROTECCIÓN CONTRA DOBLE EJECUCIÓN:
  ///
  /// 1. Nivel UI: SubmitButton deshabilita cuando state.isSubmitting
  /// 2. Nivel lógica: Este método retorna null si ya está submitting
  /// 3. Nivel backend: Idempotencia con idempotencyKey en Firestore
  ///
  /// Esto previene múltiples envíos si el usuario hace tap rápido o si
  /// algún evento dispara el método dos veces.
  ///
  /// **Idempotencia:**
  /// - Genera un UUID único (idempotencyKey) para cada intento de creación
  /// - Backend verifica si ya existe un chisme con esta clave
  /// - Si existe, retorna el chisme existente (no crea duplicado)
  /// - Si no existe, crea nuevo chisme y guarda la clave
  ///
  /// **Escenarios problemáticos SIN idempotencia:**
  /// - Usuario hace click doble → crea 2 chismes idénticos
  /// - Network timeout → usuario reenvía → crea duplicado
  /// - App se cierra → usuario reabre y reenvía → crea duplicado
  ///
  /// **Escenarios CON idempotencia:**
  /// - Usuario hace click 10 veces → solo 1 chisme creado ✅
  /// - Network timeout → usuario reenvía → retorna chisme existente ✅
  Future<Gossip?> submit() async {
    // Protección contra doble ejecución a nivel de lógica
    if (_state.isSubmitting) {
      return null;
    }

    _updateState(_state.copyWith(
      isSubmitting: true,
      failure: null,
    ));

    // Validar consistencia de jerarquía de ubicación
    // Esto previene persistir combinaciones país–región–ciudad inconsistentes
    if (!validateLocationHierarchy()) {
      _updateState(_state.copyWith(isSubmitting: false));
      return null;
    }

    // Fix P1-03: Usar idempotencyKey del estado (no generar uno nuevo)
    // Esto previene duplicados en retry/timeout/reinicio
    final locationState = locationManager.state;
    final input = CreateGossipInput(
      countryId: locationState.selectedCountry?.id ?? '',
      regionId: locationState.selectedRegion?.id ?? '',
      cityId: locationState.selectedCity?.id ?? '',
      subject: _state.subject.trim(),
      content: _state.content.trim(),
      audioUrl: _state.audioUrl,
      imageUrl: null, // Se establece después de subir
      publishedAs: _state.publishedAs,
      idempotencyKey: _state.idempotencyKey, // Usar key del estado
    );

    // Llamar use case con imagen (si existe)
    final result = await createGossip(
      input: input,
      imageFile: _selectedImageFile, // ← File seleccionado
    );

    return result.when(
      onSuccess: (gossip) {
        // Fix P1-03: Regenerar idempotencyKey solo en éxito
        // Esto permite crear un nuevo gossip en el siguiente submit
        _updateState(_state.copyWith(
          isSubmitting: false,
          idempotencyKey: const Uuid().v4(), // Nueva clave para próximo intento
        ));
        return gossip;
      },
      onFailure: (error) {
        // Fix P1-03: NO regenerar key en error
        // Mantener la misma clave permite retry con idempotencia
        _updateState(_state.copyWith(
          failure: error,
          isSubmitting: false,
        ));
        return null;
      },
    );
  }

  // Validar consistencia de jerarquía de ubicación (para UX)
  bool validateLocationHierarchy() {
    final locationState = locationManager.state;

    if (!locationState.isValid) {
      return false;
    }

    final hierarchyError = GossipValidator.validateLocationHierarchy(
      countryId: locationState.selectedCountry!.id,
      regionId: locationState.selectedRegion!.id,
      cityId: locationState.selectedCity!.id,
      countries: locationState.countries,
      regions: locationState.regions,
      cities: locationState.cities,
    );

    if (hierarchyError != null) {
      _updateState(_state.copyWith(failure: hierarchyError));
      return false;
    }

    return true;
  }

  // Reset
  ///
  /// ⚠️ IMPORTANTE: Invalida requests pendientes
  ///
  /// Al hacer reset, incrementamos los requestIds para asegurar que
  /// cualquier request en curso (regiones, ciudades) sea ignorada
  /// cuando termine. Esto previene race conditions donde una request
  /// antigua podría actualizar el estado después del reset.
  ///
  /// Escenario problemático SIN invalidación:
  /// 1. Usuario selecciona país → request región A iniciada (requestId = 1)
  /// 2. Usuario hace reset() → estado limpio
  /// 3. Request región A termina → requestId antiguo sigue siendo válido
  /// 4. Estado se actualiza con datos de la request antigua ❌
  ///
  /// Con invalidación:
  /// 1. Usuario selecciona país → request región A iniciada (requestId = 1)
  /// 2. Usuario hace reset() → requestIds incrementados (regionRequestId = 2)
  /// 3. Request región A termina → requestId 1 != 2, se ignora ✅
  ///
  /// **ACTUALIZADO:** Ahora LocationManager maneja la ubicación
  void reset() {
    locationManager.clearLocation();

    _updateState(AddGossipState(
      idempotencyKey: const Uuid().v4(), // Nueva clave para nuevo intento
    ));
  }

  // Limpiar error
  void clearError() {
    _updateState(_state.clearFailure());
  }

  // Método privado para actualizar estado
  void _updateState(AddGossipState newState) {
    final oldState = _state;
    _state = newState;

    // ✅ Sincronizar ValueNotifiers (solo si cambiaron)
    // Esto permite que widgets específicos escuchen cambios granulares
    // sin reconstruir todo el formulario
    if (oldState.imageUrl != newState.imageUrl) {
      imageNotifier.value = newState.imageUrl;
    }
    if (oldState.isUploadingImage != newState.isUploadingImage) {
      isUploadingImageNotifier.value = newState.isUploadingImage;
    }
    if (oldState.isSubmitting != newState.isSubmitting) {
      isSubmittingNotifier.value = newState.isSubmitting;
    }
    if (oldState.failure != newState.failure) {
      failureNotifier.value = newState.failure;
    }
    // selectedCityId ahora está en locationManager.state
    // El _onLocationChanged() ya actualiza selectedCityIdNotifier

    // Notificar a listeners del ChangeNotifier (AnimatedBuilder global)
    notifyListeners();
  }
}
