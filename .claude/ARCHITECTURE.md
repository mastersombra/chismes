# Arquitectura del Proyecto Chismes

## Visión General

El proyecto sigue una arquitectura limpia con separación por características (feature-first architecture). Esto permite un código más mantenible, escalable y fácil de probar.

## Estructura de Directorios

```
lib/
├── core/                  # Configuración global compartida
│   ├── constants/         # Constantes de la aplicación
│   ├── theme/            # Temas y estilos globales
│   └── config/           # Configuración de la app (rutas, DI, etc.)
├── features/             # Módulos por funcionalidad
│   ├── home/            # Feed principal de chismes
│   │   ├── presentation/ # UI (screens, widgets)
│   │   ├── domain/       # Lógica de negocio (controllers, use cases)
│   │   └── data/         # Fuentes de datos (repos, APIs)
│   ├── search/          # Búsqueda de chismes
│   ├── add_gossip/      # Agregar nuevos chismes
│   └── auth/            # Autenticación
├── shared/              # Código compartido entre features
│   ├── models/          # Modelos de datos compartidos
│   ├── data/            # Data mock y utilidades de datos
│   └── widgets/        # Widgets reutilizables
└── main.dart            # Punto de entrada de la aplicación
```

## Principios de Arquitectura

### 1. Separación por Capas

Cada feature se divide en tres capas:

- **Presentation**: UI pura, sin lógica de negocio. Contiene screens y widgets.
- **Domain**: Lógica de negocio independiente de la UI. Contiene controllers, use cases y entidades.
- **Data**: Manejo de datos. Contiene repositorios, APIs y data sources.

### 2. Dependencias

Las dependencias fluyen hacia adentro:
- Presentation depende de Domain
- Domain depende de Data (a través de abstracciones)
- Data no depende de nadie más

### 3. Shared Code

El código compartido entre features va en `shared/`:
- `models/`: Modelos de datos usados por múltiples features
- `data/`: Data mock y utilidades compartidas
- `widgets/`: Widgets reutilizables

## Patrones Utilizados

### Models

Los modelos extienden `Equatable` para comparación por valor:

```dart
class GossipModel extends Equatable {
  final String title;
  final String imageUrl;
  final String description;

  const GossipModel({...});

  GossipModel copyWith({...});
  Map<String, dynamic> toJson();
  factory GossipModel.fromJson(Map<String, dynamic> json);

  @override
  List<Object?> get props => [title, imageUrl, description];
}
```

### Controllers

Los controllers manejan la lógica de negocio y están en la capa domain:

```dart
class GossipController {
  static List<GossipModel> get all => mockGossips;
  static void add(GossipModel gossip) {...}
}
```

## Convenciones de Nombres

- **Directorios**: snake_case (`home_screen`, `gossip_card`)
- **Archivos**: snake_case (`gossip_model.dart`, `home_screen.dart`)
- **Clases**: PascalCase (`GossipModel`, `HomeScreen`)
- **Métodos/Variables**: camelCase (`getTitle`, `userList`)
- **Privados**: Prefix con `_` (`_loadData`, `_internalMethod`)

## Imports

Usar imports relativos para archivos dentro del proyecto:

```dart
// Correcto
import '../../domain/gossip_controller.dart';
import '../../../shared/models/gossip_model.dart';

// Incorrecto
import 'package:chismes/features/home/domain/gossip_controller.dart';
```

## Estado Actual

### Features Implementados

- **home**: Feed principal con grid de chismes
- **search**: Búsqueda por título/descripción
- **add_gossip**: Formulario para agregar chismes
- **auth**: Pantalla de login (básica)

### Próximas Mejoras

- Agregar capa `data/` a todos los features
- Implementar repositorios con abstracciones
- Agregar tests unitarios y de widgets
- Implementar state management (Bloc, Provider, Riverpod)
- Agregar navegación centralizada
- Implementar inyección de dependencias

## Recursos

- [Flutter Architecture](https://flutter.dev/docs/development/data-and-backend/state-mgmt/architecture)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Feature-First Architecture](https://resocoder.com/flutter-architecture-tdd-clean-architecture/)
