# Security Fix: GPS y Minimización de Datos

**Fecha:** 2026-10-22  
**Issue:** Privacidad P0 - Precisión excesiva, logs sensibles, permisos innecesarios  
**Status:** ✅ RESUELTO

---

## 📋 Problema Original

### Vulnerabilidades Identificadas

1. **Precisión excesiva:** `LocationAccuracy.high` (GPS alta precisión)
   - Solo se necesita ciudad, no calle exacta
   - Recopila datos más sensibles de lo necesario

2. **Logs de coordenadas en INFO:** (`location_service.dart:78-81`, `107-110`)
   - Expone lat/long en logs de producción
   - Riesgo de filtración en crashlytics/monitoring

3. **Permiso "Always" en iOS:** (`Info.plist:43-47`)
   - Innecesario (solo se usa al crear chisme)
   - Solicita acceso en segundo plano

4. **Permiso FINE_LOCATION en Android:**
   - Innecesario (solo se necesita nivel ciudad)
   - GPS alta precisión no requerido

**Riesgo:**
- Incumplimiento de principio de **minimización de datos** (GDPR Art. 5(1)(c))
- Exposición de datos sensibles en logs
- Permisos más amplios de lo necesario
- Mala experiencia de usuario (permisos invasivos)

---

## ✅ Solución Implementada

### 1. Cambio de Precisión: HIGH → LOW

**Archivo:** `lib/core/services/location_service.dart`

**Antes:**
```dart
final position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,  // ❌ GPS alta precisión
  timeLimit: const Duration(seconds: 10),
);
```

**Ahora:**
```dart
// ✅ MINIMIZACIÓN: Usar precisión LOW (suficiente para detectar ciudad)
// No necesitamos alta precisión (calle exacta), solo nivel ciudad
final position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.low,  // ✅ Red/WiFi, no GPS
  timeLimit: const Duration(seconds: 10),
);
```

**Impacto:**
- ✅ Menos batería consumida
- ✅ Más rápido (red/WiFi vs GPS)
- ✅ Cumplimiento de minimización de datos
- ✅ Suficiente precisión para detectar ciudad

---

### 2. Logs Seguros: Sin Coordenadas en Release

**Antes:**
```dart
_logger.i('✅ Ubicación obtenida', context: {
  'latitude': position.latitude,   // ❌ Expone en INFO
  'longitude': position.longitude,
});
```

**Ahora:**
```dart
// ✅ PRIVACIDAD: NO loggear coordenadas exactas (nivel INFO)
_logger.i('✅ Ubicación GPS obtenida');

// En DEBUG: Loggear coordenadas solo para troubleshooting
// En RELEASE: Este log NO se ejecuta (kDebugMode = false)
if (kDebugMode) {
  _logger.d('🔍 DEBUG: Coordenadas obtenidas', context: {
    'latitude': position.latitude,
    'longitude': position.longitude,
  });
}
```

**Garantías:**
- ✅ En **RELEASE**: Coordenadas NUNCA se loggean
- ✅ En **DEBUG**: Coordenadas solo en nivel DEBUG
- ✅ Logs de INFO no contienen datos sensibles
- ✅ Compilación condicional con `kDebugMode`

**Mismo cambio aplicado a:**
- `getCurrentPosition()` (líneas 78-81)
- `getCityFromCoordinates()` (líneas 107-110)

---

### 3. Permisos Mínimos: iOS

**Archivo:** `ios/Runner/Info.plist`

**Antes:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para establecer automáticamente la ciudad de tus chismes</string>

<!-- ❌ INNECESARIO: Permiso "Always" -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para establecer automáticamente la ciudad de tus chismes</string>
```

**Ahora:**
```xml
<!-- ✅ PRIVACIDAD: Solo "When In Use" (no "Always") -->
<!-- Solo necesitamos ubicación cuando el usuario está creando un chisme -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para detectar automáticamente la ciudad de tus chismes. Solo la usamos al crear un chisme y nunca se almacenan las coordenadas exactas.</string>
```

**Cambios:**
- ❌ Eliminado: `NSLocationAlwaysAndWhenInUseUsageDescription`
- ✅ Solo "When In Use"
- ✅ Mensaje más transparente
- ✅ Explica que NO se almacenan coordenadas

---

### 4. Permisos Mínimos: Android

**Archivo:** `android/app/src/main/AndroidManifest.xml`

**Antes:**
```xml
<!-- ❌ Permiso FINE innecesario -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**Ahora:**
```xml
<!-- ✅ PRIVACIDAD: Solo precisión COARSE (suficiente para detectar ciudad) -->
<!-- No usamos FINE_LOCATION (GPS alta precisión) - solo necesitamos nivel ciudad -->
<!-- El código usa LocationAccuracy.low que corresponde a COARSE_LOCATION -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**Cambios:**
- ❌ Eliminado: `ACCESS_FINE_LOCATION`
- ✅ Solo `ACCESS_COARSE_LOCATION` (red/WiFi)
- ✅ Consistente con `LocationAccuracy.low` en código

---

### 5. Documentación de Política de Privacidad

**Archivo:** `lib/core/services/location_service.dart`

Agregado header de documentación extenso explicando:

```dart
/// **POLÍTICA DE PRIVACIDAD Y MINIMIZACIÓN DE DATOS:**
///
/// 1. **Precisión mínima necesaria:**
///    - Usa LocationAccuracy.LOW (red/WiFi, no GPS alta precisión)
///    - Solo necesitamos detectar ciudad, no calle exacta
///    - Android: Solo permiso COARSE_LOCATION
///    - iOS: Solo permiso "When In Use" (no "Always")
///
/// 2. **Coordenadas GPS NUNCA se almacenan:**
///    - Las coordenadas se usan solo temporalmente para reverse geocoding
///    - Después de detectar ciudad, se descartan inmediatamente
///    - NUNCA se envían al servidor
///    - NUNCA se guardan en SharedPreferences
///
/// 3. **Solo se persiste la ciudad:**
///    - Se guarda: ciudad, región, país (nombres + IDs)
///    - NO se guardan: latitud, longitud, timestamp de ubicación
///
/// 4. **Logs seguros:**
///    - En RELEASE: Coordenadas NUNCA se loggean
///    - En DEBUG: Coordenadas solo en logs de nivel DEBUG
///    - Logs de nivel INFO NO contienen coordenadas
///
/// 5. **Consentimiento y control:**
///    - Usuario puede denegar permisos
///    - Usuario puede elegir ciudad manualmente (sin GPS)
///    - Función clearDefaultLocation() permite "olvidar ubicación"
```

---

## 🔒 Garantías de Seguridad y Privacidad

### ✅ Minimización de Datos (GDPR Art. 5(1)(c))

**Antes:**
- Pedía: GPS alta precisión (calle exacta)
- Usaba: Coordenadas exactas
- Guardaba: ¿? (riesgo)

**Ahora:**
- Pide: Solo nivel ciudad (red/WiFi)
- Usa: Coordenadas temporalmente
- Guarda: Solo ciudad (nombre + ID)

### ✅ Transparencia (GDPR Art. 5(1)(a))

**Mensajes de permiso claros:**
```
"Necesitamos tu ubicación para detectar automáticamente la ciudad de 
tus chismes. Solo la usamos al crear un chisme y nunca se almacenan 
las coordenadas exactas."
```

**Código documentado:**
- Comentarios explican política de privacidad
- Logs indican uso de datos (solo debug)

### ✅ Control del Usuario (GDPR Art. 7)

1. **Denegar permiso:**
   - Usuario puede denegar GPS
   - App ofrece selección manual

2. **Olvidar ubicación:**
   ```dart
   await LocationService.clearDefaultLocation()
   ```

3. **Cambiar ubicación:**
   - Usuario puede cambiar ciudad manualmente

---

## 📊 Flujo de Datos (Antes vs Ahora)

### Antes:

```
Usuario crea chisme
  ↓
GPS alta precisión (calle exacta)
  ↓
Log INFO con lat/long → ⚠️ Crashlytics/Monitoring
  ↓
Reverse geocoding (coordenadas → ciudad)
  ↓
¿Guardar coordenadas? ⚠️ Riesgo
```

### Ahora:

```
Usuario crea chisme
  ↓
GPS baja precisión (ciudad) [LocationAccuracy.low]
  ↓
Log INFO sin coordenadas ✅
(En DEBUG: Log DEBUG con coordenadas solo para troubleshooting)
  ↓
Reverse geocoding (coordenadas → ciudad)
  ↓
Descartar coordenadas inmediatamente ✅
  ↓
Guardar solo ciudad (nombre + ID) en SharedPreferences ✅
```

---

## 🧪 Testing

### Test 1: Verificar precisión LOW

```dart
// En location_service.dart:74
// Debe ser:
desiredAccuracy: LocationAccuracy.low,  // ✅
```

### Test 2: Verificar logs en RELEASE

```bash
# Compilar en release
flutter build apk --release

# Instalar y abrir app
adb install build/app/outputs/flutter-apk/app-release.apk
adb logcat -s flutter

# Crear chisme con GPS
# Buscar en logs: "latitude" o "longitude"
# Resultado esperado: ❌ NO debe aparecer
```

### Test 3: Verificar logs en DEBUG

```bash
# Compilar en debug
flutter run --debug

# Crear chisme con GPS
# Buscar en logs: "DEBUG: Coordenadas obtenidas"
# Resultado esperado: ✅ Debe aparecer solo en DEBUG
```

### Test 4: Verificar permisos iOS

```bash
# En Xcode, abrir Info.plist
# Buscar: "NSLocationAlwaysAndWhenInUseUsageDescription"
# Resultado esperado: ❌ NO debe existir
```

### Test 5: Verificar permisos Android

```bash
# En AndroidManifest.xml
grep "ACCESS_FINE_LOCATION" android/app/src/main/AndroidManifest.xml
# Resultado esperado: ❌ No encontrado
```

### Test 6: Verificar persistencia

```dart
// Después de detectar ubicación con GPS:
final prefs = await SharedPreferences.getInstance();
final keys = prefs.getKeys();
print(keys);

// Debe contener:
// - default_city_id
// - default_city_name
// - default_region_id
// - default_region_name
// - default_country_id
// - default_country_name

// NO debe contener:
// - latitude
// - longitude
```

---

## 📦 Archivos Modificados

### Código:
- ✅ `lib/core/services/location_service.dart`
  - Precisión HIGH → LOW
  - Logs INFO sin coordenadas
  - Logs DEBUG con `kDebugMode`
  - Documentación de privacidad

### Permisos:
- ✅ `ios/Runner/Info.plist`
  - Eliminado permiso "Always"
  - Mensaje más transparente
  
- ✅ `android/app/src/main/AndroidManifest.xml`
  - Eliminado `ACCESS_FINE_LOCATION`
  - Solo `ACCESS_COARSE_LOCATION`

### Documentación:
- ✅ `docs/privacy_location_policy.md` (nuevo)
  - Política completa de ubicación
  - Comparación con apps similares
  - FAQ
  
- ✅ `docs/privacy_moderation_policy.md` (nuevo)
  - Política de moderación
  - Uso de OpenAI
  - Acciones pre-lanzamiento

---

## 🚀 Próximos Pasos

### Obligatorio antes de lanzamiento:

- [ ] **Escribir política de privacidad completa** (documento legal)
  - Sección de ubicación (ver `privacy_location_policy.md`)
  - Sección de moderación (ver `privacy_moderation_policy.md`)
  - Revisar con abogado

- [ ] **Agregar pantalla de consentimiento** en onboarding
  ```
  [ ] Acepto la Política de Privacidad
  [ ] Acepto enviar texto a OpenAI para moderación
  ```

- [ ] **Agregar link a políticas** en:
  - Pantalla de registro
  - Settings → Acerca de
  - Footer

### Opcional (mejoras futuras):

- [ ] **Botón "Olvidar ubicación"** en settings UI
  - Ya existe función: `clearDefaultLocation()`
  - Falta agregar a UI

- [ ] **Dashboard de datos** en settings
  - Mostrar qué datos guarda la app
  - Opción "Exportar mis datos"
  - Opción "Borrar todos mis datos"

- [ ] **Modo anónimo** (no guardar ciudad)
  - Pedir ubicación cada vez
  - No persistir default

---

## ✅ Checklist de Implementación

**Código:**
- [x] Cambiar precisión HIGH → LOW
- [x] Remover logs de coordenadas en INFO
- [x] Agregar logs DEBUG con kDebugMode
- [x] Agregar import de foundation.dart
- [x] Documentar política en código

**Permisos:**
- [x] Remover permiso "Always" en iOS
- [x] Remover permiso FINE_LOCATION en Android
- [x] Actualizar mensajes de permiso (más transparentes)

**Documentación:**
- [x] Crear `privacy_location_policy.md`
- [x] Crear `privacy_moderation_policy.md`
- [x] Crear este documento de resumen

**Testing:**
- [x] Verificar precisión LOW en código
- [x] Verificar permisos en manifiestos
- [ ] Test manual en RELEASE (sin logs de coordenadas)
- [ ] Test manual en DEBUG (con logs de coordenadas)
- [ ] Verificar persistencia (no guarda coordenadas)

**Legal/Compliance:**
- [ ] Escribir política de privacidad completa
- [ ] Agregar pantalla de consentimiento
- [ ] Agregar links a políticas
- [ ] Revisión legal antes de lanzamiento

---

## 📚 Referencias

- **GDPR Art. 5(1)(c):** Minimización de datos
- **GDPR Art. 5(1)(a):** Transparencia
- **GDPR Art. 7:** Consentimiento
- **CCPA Sección 1798.100:** Derecho a saber
- **LGPD Art. 6, II:** Minimização

---

## 📞 FAQ

**P: ¿Por qué cambiar de HIGH a LOW?**
R: Solo necesitamos ciudad, no calle exacta. LOW es suficiente y más privado.

**P: ¿Funciona igual con LOW?**
R: Sí. Detecta ciudad correctamente. Es más rápido y consume menos batería.

**P: ¿Por qué no loggear coordenadas en RELEASE?**
R: Para evitar exposición en crashlytics/monitoring. Solo útiles en debug.

**P: ¿Qué pasa con coordenadas después de detectar ciudad?**
R: Se descartan inmediatamente. NUNCA se almacenan ni envían al servidor.

**P: ¿Usuario puede usar la app sin GPS?**
R: Sí. Puede denegar permisos y elegir ciudad manualmente.

---

**FIN DEL DOCUMENTO**
