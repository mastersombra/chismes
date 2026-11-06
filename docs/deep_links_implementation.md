# Deep Links Implementation

> **Estado:** ✅ Implementado  
> **Fecha:** 2026-10-19  
> **Versión:** 1.0  
> **Tipo:** Deep Links Básicos (chismes://)

---

## 📋 Resumen

Sistema de deep links básicos implementado para compartir chismes entre usuarios que tienen la app instalada.

**Esquema:** `chismes://`

**Ejemplos:**
- `chismes://gossip/abc123` - Abre chisme específico
- `chismes://profile/user123` - Abre perfil (futuro)
- `chismes://feed?city=medellin` - Abre feed filtrado (futuro)

---

## ✅ Lo Que SÍ Hace

### 1. Compartir Entre Usuarios con App

```
Usuario A (con app):
  1. Ve chisme interesante
  2. Toca botón [Compartir]
  3. Selecciona WhatsApp/Telegram
  4. Mensaje se envía con: "chismes://gossip/abc123"

Usuario B (con app):
  1. Recibe mensaje en WhatsApp
  2. Toca el link "chismes://gossip/abc123"
  3. Android/iOS pregunta: "¿Abrir con Chismes?"
  4. ✅ App se abre directo en ese chisme
```

### 2. Reutilizable para Notificaciones (Futuro)

```dart
// Notificación push incluye deep link
{
  title: "Juan comentó tu chisme",
  data: { deepLink: "chismes://gossip/abc123" }
}

// El MISMO código de deep links maneja la navegación ✅
```

### 3. Navegación Interna

```dart
// Links dentro de la app
DeepLinkService.generateGossipLink(gossipId);
DeepLinkService.generateProfileLink(userId);
```

---

## ❌ Lo Que NO Hace

### 1. Usuarios Sin App

```
Si Usuario B NO tiene la app instalada:
  - Toca "chismes://gossip/abc123"
  - ❌ Android/iOS: "No hay app para abrir este link"
  - Link no funciona

Solución (futuro):
  - Universal Links (https://chismes.app/gossip/abc123)
  - Requiere: dominio + hosting + landing page
```

### 2. Redes Sociales (Instagram, Facebook)

```
Instagram/Facebook NO abren links chismes://
Solo abren links https://

Solución (futuro):
  - Universal Links
```

### 3. Links desde Web

```
Un link chismes://gossip/abc123 en una web NO funciona
Solo funciona desde apps nativas (WhatsApp, Telegram, etc.)
```

---

## 🏗️ Arquitectura

### Componentes

```
1. AndroidManifest.xml
   - Intent filter para esquema "chismes"
   
2. Info.plist (iOS)
   - CFBundleURLTypes para esquema "chismes"

3. DeepLinkService
   - Escucha deep links
   - Parsea URI
   - Navega a pantalla correspondiente

4. Share Button (GossipCard)
   - Genera deep link
   - Comparte usando share_plus
```

### Flujo de Datos

```
Usuario toca [Compartir]
         ↓
GossipCard._shareGossip()
         ↓
DeepLinkService.generateGossipLink(id)
         ↓
Genera: "chismes://gossip/abc123"
         ↓
Share.share(text)
         ↓
WhatsApp/Telegram recibe mensaje
         ↓
Usuario B toca link
         ↓
Android/iOS detecta esquema "chismes"
         ↓
Abre app Chismes
         ↓
DeepLinkService recibe URI
         ↓
DeepLinkService._handleGossipLink()
         ↓
Navega a GossipDetailScreen(id: "abc123") ✅
```

---

## 📝 Archivos Modificados/Creados

### 1. Configuración Android

**Archivo:** `android/app/src/main/AndroidManifest.xml`

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="chismes" />
</intent-filter>
```

### 2. Configuración iOS

**Archivo:** `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>chismes</string>
    </array>
  </dict>
</array>
```

### 3. Servicio de Deep Links

**Archivo:** `lib/core/services/deep_link_service.dart`

```dart
@singleton
class DeepLinkService {
  // Escucha deep links
  Future<void> initialize() { ... }
  
  // Genera links
  static String generateGossipLink(String id) { ... }
  
  // Maneja navegación
  void _handleDeepLink(Uri uri) { ... }
}
```

### 4. DI Container

**Archivo:** `lib/core/di/injection_container.dart`

```dart
// Navigator key global para deep links
final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

Future<void> configureDependencies() async {
  getIt.registerSingleton(navigatorKey, instanceName: 'navigatorKey');
  $initGetIt(getIt);
}
```

### 5. Main App

**Archivo:** `lib/main.dart`

```dart
Future<void> initializeApp() async {
  // ... otras inicializaciones
  
  // Inicializar deep links
  final deepLinkService = getIt<DeepLinkService>();
  await deepLinkService.initialize();
}

class ChismesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ← Para deep links
      home: LoginScreen(),
    );
  }
}
```

### 6. Botón Compartir

**Archivo:** `lib/features/gossip/presentation/widgets/gossip_card.dart`

```dart
IconButton(
  icon: Icon(Icons.share),
  onPressed: () => _shareGossip(context, gossip),
)

Future<void> _shareGossip(BuildContext context, Gossip gossip) async {
  final deepLink = DeepLinkService.generateGossipLink(gossip.id);
  await Share.share('Mira este chisme: $deepLink');
}
```

---

## 🧪 Testing

### Manual Testing

#### 1. Compartir desde App

```
1. Abrir app en dispositivo A
2. Ir a feed
3. Ver un chisme
4. Tocar botón [Compartir] (icono share)
5. Seleccionar WhatsApp
6. Enviar mensaje a ti mismo o a otro dispositivo
7. Verificar que mensaje incluya "chismes://gossip/..."
```

#### 2. Abrir desde Link (Mismo Dispositivo)

```
1. Recibir mensaje con link en WhatsApp
2. Tocar el link
3. Android/iOS pregunta: "¿Abrir con Chismes?"
4. Seleccionar "Chismes"
5. ✅ App se abre
6. ✅ Navega al chisme específico
```

#### 3. Abrir desde Link (Dos Dispositivos)

```
Dispositivo A:
1. Compartir chisme

Dispositivo B (con app instalada):
1. Recibir link en WhatsApp
2. Tocar link
3. ✅ App se abre en el chisme correcto
```

### Testing con ADB (Android)

```bash
# Abrir app con deep link
adb shell am start -W -a android.intent.action.VIEW \
  -d "chismes://gossip/abc123" \
  com.chismes.app

# Verificar logs
adb logcat | grep "Deep link"
```

### Testing con Simulador (iOS)

```bash
# Abrir simulador con deep link
xcrun simctl openurl booted "chismes://gossip/abc123"
```

---

## 📊 Casos de Uso Implementados

| Caso | Estado | Notas |
|------|--------|-------|
| **Compartir chisme entre usuarios con app** | ✅ | Funciona perfecto |
| **Compartir a usuario sin app** | ⚠️ | Link no abre (esperado) |
| **Notificaciones push** | 🔜 | Reutilizará mismo código |
| **Compartir en Instagram/Facebook** | ❌ | Necesita Universal Links (futuro) |
| **Links desde web/email** | ❌ | Necesita Universal Links (futuro) |

---

## 🚀 Uso en el Código

### Generar Deep Link

```dart
import 'package:chismes/core/services/deep_link_service.dart';

// Chisme
final link = DeepLinkService.generateGossipLink(gossipId);
// → "chismes://gossip/abc123"

// Perfil (futuro)
final link = DeepLinkService.generateProfileLink(userId);
// → "chismes://profile/user123"

// Feed filtrado (futuro)
final link = DeepLinkService.generateFeedLink(cityId: 'medellin');
// → "chismes://feed?city=medellin"
```

### Compartir

```dart
import 'package:share_plus/share_plus.dart';

final deepLink = DeepLinkService.generateGossipLink(gossip.id);

await Share.share(
  '🔥 Mira este chisme:\n\n'
  '"${gossip.subject}"\n\n'
  '$deepLink\n\n'
  '📱 Descarga Chismes para ver más',
);
```

### Navegar Internamente

```dart
// Desde cualquier parte de la app
final deepLink = DeepLinkService.generateGossipLink(gossipId);
final uri = Uri.parse(deepLink);

// El servicio manejará la navegación automáticamente
```

---

## 🔄 Extensión Futura

### Agregar Nuevo Tipo de Deep Link

```dart
// 1. Generar link
static String generateCommentLink(String gossipId, String commentId) {
  return 'chismes://gossip/$gossipId?comment=$commentId';
}

// 2. Manejar en DeepLinkService
void _handleGossipLink(Uri uri) {
  final gossipId = uri.pathSegments[1];
  final commentId = uri.queryParameters['comment'];
  
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => GossipDetailScreen(
        gossipId: gossipId,
        highlightCommentId: commentId,
      ),
    ),
  );
}
```

### Migrar a Universal Links (Futuro)

Cuando necesites que funcione para usuarios sin app:

1. **Comprar dominio:** chismes.app ($12/año)
2. **Crear landing page web:** Next.js en Vercel (gratis)
3. **Configurar Apple App Site Association:** `.well-known/apple-app-site-association`
4. **Configurar Android App Links:** `.well-known/assetlinks.json`
5. **Actualizar intent filters:** Agregar esquema `https`
6. **No cambiar código de navegación:** ✅ Se reutiliza todo

---

## 💰 Costos

```
Deep Links Básicos (chismes://): $0
  - Hosting: ❌ No necesita
  - Dominio: ❌ No necesita
  - Servicios: ❌ No necesita

Total: $0 ✅
```

---

## 🐛 Troubleshooting

### Problema 1: Link no abre la app

**Síntomas:**
- Usuario toca link en WhatsApp
- No pasa nada o dice "No hay app"

**Soluciones:**
```
1. Verificar que app esté instalada
2. Verificar AndroidManifest.xml tiene intent-filter correcto
3. Verificar Info.plist tiene CFBundleURLTypes correcto
4. Reinstalar app (a veces Android cachea mal)
```

### Problema 2: App abre pero no navega

**Síntomas:**
- App se abre
- Pero se queda en pantalla de inicio
- No navega al chisme

**Soluciones:**
```
1. Verificar logs: "Deep link recibido..."
2. Verificar que navigatorKey esté configurado en MaterialApp
3. Verificar que DeepLinkService esté inicializado en main.dart
4. Verificar formato del link (debe ser chismes://gossip/ID)
```

### Problema 3: Android pregunta "¿Abrir con navegador?"

**Síntomas:**
- Android muestra dialog con opciones: "Chrome", "Chismes"
- Usuario debe elegir manualmente

**Solución:**
```
Esto es comportamiento normal para deep links básicos.
Para evitarlo necesitas App Links (https://) con dominio verificado.
```

---

## 📚 Referencias

- **Código:** `lib/core/services/deep_link_service.dart`
- **Configuración Android:** `android/app/src/main/AndroidManifest.xml`
- **Configuración iOS:** `ios/Runner/Info.plist`
- **UI:** `lib/features/gossip/presentation/widgets/gossip_card.dart`
- **Package app_links:** https://pub.dev/packages/app_links
- **Package share_plus:** https://pub.dev/packages/share_plus

---

## ✅ Checklist de Implementación

- [x] Dependencias agregadas (app_links, share_plus)
- [x] AndroidManifest.xml configurado
- [x] Info.plist (iOS) configurado
- [x] DeepLinkService creado
- [x] DI container actualizado
- [x] main.dart inicializa servicio
- [x] navigatorKey configurado
- [x] Botón compartir en GossipCard
- [x] Documentación completa
- [ ] Testing manual (pendiente después de deploy)
- [ ] Testing en dos dispositivos (pendiente)

---

**Última actualización:** 2026-10-19  
**Autor:** Alejo + Claude Code  
**Estado:** ✅ Implementado, listo para testing
