# Requerimientos: Búsqueda/Autocompletado para Ubicación Global

## Estado Actual
- `LocationSelector` usa `DropdownButtonFormField` con listas completas
- Carga todos los países, regiones y ciudades en memoria
- Funciona para catálogos pequeños, pero no escala globalmente

## Problema con DropdownButtonFormField
Si el catálogo crece globalmente:
- **Países**: ~195 países (aceptable)
- **Regiones**: ~3,000-5,000 regiones (marginal)
- **Ciudades**: ~100,000+ ciudades (inaceptable)

Cargar 100,000+ ciudades en un `DropdownButtonFormField`:
- Consume memoria excesiva
- UI lenta al renderizar lista
- Scroll difícil para el usuario
- Búsqueda manual tediosa

## Solución: Búsqueda/Autocompletado

### Arquitectura Recomendada

#### 1. Búsqueda con Autocompletado
Usar `Autocomplete` o `SearchDelegate` en lugar de dropdowns.

```dart
// Búsqueda de países con autocompletado
Autocomplete<Country>(
  optionsBuilder: (TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) {
      return const Iterable<Country>.empty();
    }
    return countries.where((Country option) {
      return option.name
          .toLowerCase()
          .contains(textEditingValue.text.toLowerCase());
    });
  },
  onSelected: (Country selection) {
    controller.selectCountry(selection.id);
  },
  displayStringForOption: (Country option) => option.name,
);
```

#### 2. Búsqueda en Servidor (Paginada)
Para catálogos grandes, buscar en el servidor con paginación:

```dart
// Use case de búsqueda
class SearchCities {
  final LocationRepository repository;

  Future<Result<Failure, List<City>>> call({
    required String query,
    required String regionId,
    int limit = 20,
    int offset = 0,
  }) async {
    return repository.searchCities(
      query: query,
      regionId: regionId,
      limit: limit,
      offset: offset,
    );
  }
}

// Repository con búsqueda
abstract class LocationRepository {
  Future<Result<Failure, List<City>>> searchCities({
    required String query,
    required String regionId,
    int limit = 20,
    int offset = 0,
  });
}
```

#### 3. Firestore Implementation
```dart
// Firestore con búsqueda y paginación
Future<List<City>> searchCities({
  required String query,
  required String regionId,
  int limit = 20,
  int offset = 0,
}) async {
  final snapshot = await firestore
      .collection('cities')
      .where('regionId', isEqualTo: regionId)
      .where('name', isGreaterThanOrEqualTo: query)
      .where('name', isLessThanOrEqualTo: query + '\uf8ff')
      .orderBy('name')
      .limit(limit)
      .get();

  return snapshot.docs.map((doc) => City.fromJson(doc.data())).toList();
}
```

### UI Flow

#### Opción A: Autocomplete Local (Catálogo Pequeño)
```
1. Usuario toca campo "Ciudad"
2. TextField con autocompletado aparece
3. Usuario escribe "San"
4. Autocomplete filtra: "San Francisco", "San Diego", "San Antonio"
5. Usuario selecciona "San Francisco"
6. Campo se completa con la selección
```

**Ventajas:**
- Rápido (búsqueda local)
- Sin latencia de red
- UI fluida

**Desventajas:**
- Requiere cargar catálogo completo en memoria
- No escala para 100,000+ ciudades

#### Opción B: Búsqueda en Servidor (Catálogo Grande)
```
1. Usuario toca campo "Ciudad"
2. TextField con debounce (300ms) aparece
3. Usuario escribe "San"
4. Después de 300ms, se busca en servidor: "San"
5. Servidor retorna top 20: "San Francisco", "San Diego", "San Antonio"
6. Usuario selecciona "San Francisco"
7. Campo se completa con la selección
```

**Ventajas:**
- Escala para catálogos globales
- Memoria eficiente (solo resultados)
- Búsqueda más potente (fuzzy search, geolocalización)

**Desventajas:**
- Latencia de red
- Requiere manejo de estados de carga/error
- Más complejo de implementar

### Estado Recomendado en AddGossipState

```dart
class AddGossipState {
  // Búsqueda de ciudades
  final String citySearchQuery;
  final List<City> citySearchResults;
  final bool isSearchingCities;
  final String? citySearchError;

  // Búsqueda de regiones (opcional, si catálogo grande)
  final String regionSearchQuery;
  final List<Region> regionSearchResults;
  final bool isSearchingRegions;
  final String? regionSearchError;
}
```

### Controller Methods

```dart
class AddGossipController {
  // Búsqueda de ciudades con debounce
  Timer? _citySearchDebounce;

  void searchCities(String query) {
    _citySearchDebounce?.cancel();
    _citySearchDebounce = Timer(const Duration(milliseconds: 300), () {
      _performCitySearch(query);
    });
  }

  Future<void> _performCitySearch(String query) async {
    if (query.isEmpty) {
      _updateState(_state.copyWith(
        citySearchResults: [],
        citySearchQuery: '',
      ));
      return;
    }

    _updateState(_state.copyWith(
      isSearchingCities: true,
      citySearchQuery: query,
    ));

    final result = await searchCities(
      query: query,
      regionId: _state.selectedRegionId ?? '',
    );

    result.when(
      onSuccess: (cities) {
        _updateState(_state.copyWith(
          citySearchResults: cities,
          isSearchingCities: false,
        ));
      },
      onFailure: (error) {
        _updateState(_state.copyWith(
          citySearchError: error,
          isSearchingCities: false,
        ));
      },
    );
  }
}
```

### UI Componente

```dart
class CitySearchField extends StatelessWidget {
  final AddGossipState state;
  final ValueChanged<String?> onCitySelected;
  final ValueChanged<String> onSearchChanged;

  const CitySearchField({
    required this.state,
    required this.onCitySelected,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<City>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        onSearchChanged(textEditingValue.text);
        if (state.isSearchingCities) {
          return const Iterable<City>.empty();
        }
        return state.citySearchResults;
      },
      onSelected: (City selection) {
        onCitySelected(selection.id);
      },
      displayStringForOption: (City option) => option.name,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Ciudad',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: state.isSearchingCities
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        );
      },
    );
  }
}
```

### Geolocalización (Opcional)

Para mejorar UX, usar geolocalización para sugerir ciudades cercanas:

```dart
// Use case de ciudades cercanas
class GetNearbyCities {
  Future<Result<Failure, List<City>>> call({
    required double latitude,
    required double longitude,
    int radiusKm = 50,
  }) async {
    return repository.getNearbyCities(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
}

// Firestore con geopoint
Future<List<City>> getNearbyCities({
  required double latitude,
  required double longitude,
  int radiusKm = 50,
}) async {
  final center = GeoPoint(latitude, longitude);
  final snapshot = await firestore
      .collection('cities')
      .where('location', isGreaterThan: GeoPoint(latitude - 0.5, longitude - 0.5))
      .where('location', isLessThan: GeoPoint(latitude + 0.5, longitude + 0.5))
      .limit(20)
      .get();

  // Filtrar por distancia real
  return snapshot.docs
      .map((doc) => City.fromJson(doc.data()))
      .where((city) => _calculateDistance(center, city.location) <= radiusKm)
      .toList();
}
```

### Estrategia de Implementación

#### Fase 1: Autocomplete Local (Inmediato)
- Mantener dropdowns para países/regiones
- Cambiar ciudades a `Autocomplete` local
- Cargar catálogo de ciudades en memoria (si < 10,000)

#### Fase 2: Búsqueda en Servidor (Escalabilidad)
- Implementar `SearchCities` use case
- Cambiar a búsqueda en servidor con debounce
- Agregar indicadores de carga/error
- Paginación para resultados grandes

#### Fase 3: Geolocalización (UX Avanzada)
- Implementar `GetNearbyCities` use case
- Sugerir ciudades cercanas al usuario
- Permiso de ubicación opcional

### Índices Firestore Requeridos

```dart
// Índice para búsqueda de ciudades por nombre y región
cities_index: [
  { field: 'regionId', order: 'ASCENDING' },
  { field: 'name', order: 'ASCENDING' },
]

// Índice para búsqueda geoespacial
cities_geo_index: [
  { field: 'location', order: 'ASCENDING' },
]
```

### Tests Requeridos

- Búsqueda local con autocompletado
- Búsqueda en servidor con debounce
- Búsqueda sin resultados
- Búsqueda con error de red
- Selección de resultado
- Cancelación de búsqueda
- Geolocalización de ciudades cercanas

### Prioridades

1. **Alta**: Autocomplete local para ciudades (mejora UX inmediata)
2. **Media**: Búsqueda en servidor para escalabilidad
3. **Baja**: Geolocalización de ciudades cercanas (UX avanzada)
