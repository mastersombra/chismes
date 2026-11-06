# Patrón de Corrección para Tests del Controller

**Problema:** Los tests verifican `controller.state.countries` cuando ahora eso está delegado a `locationManager.state.countries`.

**Arquitectura actual:**
- `AddGossipController` **delega** ubicación a `LocationManager`
- `LocationManager.state` tiene: countries, regions, cities, selectedCountry, selectedRegion, selectedCity
- `AddGossipController.state` tiene: subject, content, isSubmitting, audioUrl, imageUrl, etc.

## Patrón de Fix

### 1. Setup de Mocks

```dart
setUp(() {
  mockLocationManager = MockLocationManager();
  
  // Stub inicial para state
  when(mockLocationManager.state).thenReturn(
    const LocationState(
      countries: [],
      regions: [],
      cities: [],
      isLoadingCountries: false,
      isLoadingRegions: false,
      isLoadingCities: false,
      isDetectingLocation: false,
    ),
  );
  
  controller = AddGossipController(/*...*/);
});
```

### 2. Mockeando Selección de País

```dart
test('debe cargar regiones al seleccionar país', () async {
  final mockCountries = [const Country(id: '1', code: 'CO', name: 'Colombia')];
  final mockRegions = [const Region(id: 'ant', name: 'Antioquia', countryId: '1', type: 'department')];
  
  // 1. Estado inicial con países
  when(mockLocationManager.state).thenReturn(
    LocationState(
      countries: mockCountries,
      regions: const [],
      cities: const [],
      isLoadingCountries: false,
      isLoadingRegions: false,
      isLoadingCities: false,
      isDetectingLocation: false,
    ),
  );
  
  // 2. Mockear que loadRegions actualiza state
  when(mockLocationManager.loadRegions(any)).thenAnswer((_) async {
    when(mockLocationManager.state).thenReturn(
      LocationState(
        countries: mockCountries,
        regions: mockRegions,
        cities: const [],
        selectedCountry: mockCountries[0],
        isLoadingCountries: false,
        isLoadingRegions: false,
        isLoadingCities: false,
        isDetectingLocation: false,
      ),
    );
  });
  
  // Act
  await controller.selectCountry('1');
  
  // Assert
  verify(mockLocationManager.loadRegions(mockCountries[0])).called(1);
  expect(mockLocationManager.state.selectedCountry, mockCountries[0]);
  expect(mockLocationManager.state.regions, mockRegions);
});
```

### 3. Tests de Validación

```dart
test('debe retornar true cuando jerarquía es válida', () {
  final mockCountries = [const Country(id: '1', code: 'CO', name: 'Colombia')];
  final mockRegions = [const Region(id: 'ant', name: 'Antioquia', countryId: '1', type: 'department')];
  final mockCities = [const City(id: 'med', name: 'Medellín', regionId: 'ant')];
  
  // Mockear state con jerarquía completa
  when(mockLocationManager.state).thenReturn(
    LocationState(
      countries: mockCountries,
      regions: mockRegions,
      cities: mockCities,
      selectedCountry: mockCountries[0],
      selectedRegion: mockRegions[0],
      selectedCity: mockCities[0],
      isLoadingCountries: false,
      isLoadingRegions: false,
      isLoadingCities: false,
      isDetectingLocation: false,
    ),
  );
  
  // Act
  final result = controller.validateLocationHierarchy();
  
  // Assert
  expect(result, isTrue);
});
```

## Cambios Necesarios

### ❌ ANTES (Incorrecto)
```dart
expect(controller.state.countries, equals(countries));
expect(controller.state.selectedCountryId, '1');
await controller.selectCountry('1');
expect(controller.state.regions, mockRegions);
```

### ✅ DESPUÉS (Correcto)
```dart
expect(mockLocationManager.state.countries, equals(countries));
expect(mockLocationManager.state.selectedCountry?.id, '1');
await controller.selectCountry('1');
expect(mockLocationManager.state.regions, mockRegions);
```

## Métodos que Delegan

- `initialize()` → `locationManager.loadCountries()` + `loadDefaultLocation()`
- `autoDetectLocation()` → `locationManager.detectLocationFromGPS()`
- `selectCountry(id)` → `locationManager.loadRegions(country)`
- `selectRegion(id)` → `locationManager.loadCities(region)`
- `selectCity(id)` → `locationManager.selectCity(city)`
- `validateLocationHierarchy()` → Lee `locationManager.state`

## Resumen

1. **NO** verificar `controller.state` para ubicación
2. **SÍ** verificar `locationManager.state` para ubicación
3. **SÍ** verificar `controller.state` para subject, content, isSubmitting, etc.
4. Mockear que los métodos de `locationManager` actualizan su `state`
5. Usar `verify()` para confirmar que se llamaron métodos delegados
