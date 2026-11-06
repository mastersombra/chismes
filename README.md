# Chismes 

Aplicación Flutter para compartir y descubrir chismes de celebridades.

## Características

- Ver feed de chismes en formato grid
- Buscar chismes por título o descripción
- Agregar nuevos chismes
- Diseño responsive con Material Design 3

## Arquitectura

El proyecto sigue una arquitectura limpia con separación por características:

```
lib/
├── core/              # Configuración global (temas, constantes)
├── features/          # Módulos por funcionalidad
│   ├── home/         # Feed principal
│   ├── search/       # Búsqueda de chismes
│   ├── add_gossip/   # Agregar nuevos chismes
│   └── auth/         # Autenticación
├── shared/           # Código compartido entre features
│   ├── models/       # Modelos de datos
│   └── data/         # Data mock y repositorios
└── main.dart         # Punto de entrada
```

## Getting Started

### Prerrequisitos

- Flutter SDK 3.9.2 o superior
- Dart SDK compatible

### Instalación

1. Clonar el repositorio
2. Instalar dependencias:
```bash
flutter pub get
```

3. Ejecutar la aplicación:
```bash
flutter run
```

## Dependencias Principales

- `flutter`: Framework principal
- `cupertino_icons`: Iconos estilo iOS
- `equatable`: Para comparación de objetos

## Estructura de Features

Cada feature sigue la estructura:

```
feature_name/
├── presentation/    # UI (screens, widgets)
├── domain/         # Lógica de negocio
└── data/          # Fuentes de datos (opcional)
```

## Desarrollo

Para agregar un nuevo feature:

1. Crear directorio en `lib/features/`
2. Agregar carpetas `presentation/`, `domain/`, `data/`
3. Seguir el patrón de arquitectura existente
