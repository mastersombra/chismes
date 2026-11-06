import 'package:equatable/equatable.dart';
import '../../domain/entities/gossip.dart';
import '../../../location/domain/entities/country.dart';
import '../../../location/domain/entities/region.dart';
import '../../../location/domain/entities/city.dart';
import '../../../../core/error/failure.dart';

class AddGossipState extends Equatable {
  static const _unset = Object();

  final List<Country> countries;
  final List<Region> regions;
  final List<City> cities;

  final String? selectedCountryId;
  final String? selectedRegionId;
  final String? selectedCityId;

  final PublishAs publishedAs;

  final String subject;
  final String content;

  /// Clave de idempotencia para prevenir duplicados
  ///
  /// **Fix P1-03:** Se genera UNA VEZ al inicializar el formulario
  /// y se mantiene durante todo el "intento" del usuario.
  /// Solo se regenera cuando el gossip se crea exitosamente.
  ///
  /// Esto previene duplicados en casos de:
  /// - Retry después de timeout
  /// - Reinicio de la app
  /// - Doble tap
  final String idempotencyKey;

  /// URL del audio (después de subir)
  ///
  /// **Decisión:** String simple (NO MediaReference)
  /// Ver: audio_imagen.md sección "Opción B: String Simple"
  final String? audioUrl;

  /// URL de la imagen (después de subir)
  ///
  /// **Decisión:** String simple (NO MediaReference)
  /// Ver: audio_imagen.md sección "Opción B: String Simple"
  final String? imageUrl;

  final bool isLoadingCountries;
  final bool isLoadingRegions;
  final bool isLoadingCities;
  final bool isSubmitting;
  final bool isUploadingImage;
  final Failure? failure;

  const AddGossipState({
    this.countries = const [],
    this.regions = const [],
    this.cities = const [],
    this.selectedCountryId,
    this.selectedRegionId,
    this.selectedCityId,
    this.publishedAs = PublishAs.anonymous,
    this.subject = '',
    this.content = '',
    required this.idempotencyKey, // Requerido para prevenir duplicados
    this.audioUrl,
    this.imageUrl,
    this.isLoadingCountries = false,
    this.isLoadingRegions = false,
    this.isLoadingCities = false,
    this.isSubmitting = false,
    this.isUploadingImage = false,
    this.failure,
  });

  // Getters para facilitar el acceso
  bool get hasError => failure != null;

  // Métodos copyWith para crear nuevos estados inmutables
  AddGossipState copyWith({
    List<Country>? countries,
    List<Region>? regions,
    List<City>? cities,
    Object? selectedCountryId = _unset,
    Object? selectedRegionId = _unset,
    Object? selectedCityId = _unset,
    PublishAs? publishedAs,
    String? subject,
    String? content,
    String? idempotencyKey,
    Object? audioUrl = _unset,
    Object? imageUrl = _unset,
    bool? isLoadingCountries,
    bool? isLoadingRegions,
    bool? isLoadingCities,
    bool? isSubmitting,
    bool? isUploadingImage,
    Object? failure = _unset,
  }) {
    return AddGossipState(
      countries: countries ?? this.countries,
      regions: regions ?? this.regions,
      cities: cities ?? this.cities,
      selectedCountryId: identical(selectedCountryId, _unset)
          ? this.selectedCountryId
          : selectedCountryId as String?,
      selectedRegionId: identical(selectedRegionId, _unset)
          ? this.selectedRegionId
          : selectedRegionId as String?,
      selectedCityId: identical(selectedCityId, _unset)
          ? this.selectedCityId
          : selectedCityId as String?,
      publishedAs: publishedAs ?? this.publishedAs,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      audioUrl: identical(audioUrl, _unset)
          ? this.audioUrl
          : audioUrl as String?,
      imageUrl: identical(imageUrl, _unset)
          ? this.imageUrl
          : imageUrl as String?,
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      isLoadingRegions: isLoadingRegions ?? this.isLoadingRegions,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      failure: identical(failure, _unset)
          ? this.failure
          : failure as Failure?,
    );
  }

  AddGossipState clearFailure() {
    return copyWith(failure: null);
  }

  AddGossipState clearLocation() {
    return copyWith(
      selectedRegionId: null,
      selectedCityId: null,
      regions: [],
      cities: [],
    );
  }

  @override
  List<Object?> get props => [
        countries,
        regions,
        cities,
        selectedCountryId,
        selectedRegionId,
        selectedCityId,
        publishedAs,
        subject,
        content,
        idempotencyKey,
        audioUrl,
        imageUrl,
        isLoadingCountries,
        isLoadingRegions,
        isLoadingCities,
        isSubmitting,
        isUploadingImage,
        failure,
      ];
}
