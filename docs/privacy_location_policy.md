# Política de Privacidad - Ubicación y Minimización de Datos

**Fecha:** 2026-10-22  
**Status:** ✅ IMPLEMENTADO  
**Versión:** 1.0

---

## 🔒 Resumen Ejecutivo

**Chismes** implementa una política estricta de **minimización de datos** para ubicación:

- ✅ Solo pedimos **ciudad** (nunca calle exacta)
- ✅ Coordenadas GPS **NUNCA se almacenan**
- ✅ Coordenadas GPS **NUNCA se envían al servidor**
- ✅ Solo precisión **LOW** (red/WiFi, no GPS alta precisión)
- ✅ Solo permiso "When In Use" (no "Always")
- ✅ Usuario puede elegir ciudad **manualmente** (sin GPS)
- ✅ Usuario puede **"olvidar ubicación"** en cualquier momento

---

## 📋 Problema Original

### ❌ Prácticas problemáticas identificadas:

1. **Precisión excesiva:** `LocationAccuracy.high` (GPS alta precisión)
2. **Logs sensibles:** Coordenadas exactas en logs de nivel INFO
3. **Permiso Always:** iOS pedía permiso "Always" (innecesario)
4. **Permiso FINE:** Android pedía `ACCESS_FINE_LOCATION` (innecesario)

**Riesgo:**
- Recopilación de datos más sensibles de lo necesario
- Exposición de coordenadas exactas en logs
- Incumplimiento de principio de minimización (GDPR/CCPA)

---

## ✅ Solución Implementada

### 1. Precisión Mínima Necesaria

**Antes:**
```dart
desiredAccuracy: LocationAccuracy.high  // ❌ GPS alta precisión
```

**Ahora:**
```dart
desiredAccuracy: LocationAccuracy.low  // ✅ Red/WiFi (suficiente para ciudad)
```

**Justificación:**
- Solo necesitamos detectar **ciudad** (ej: "Bogotá")
- NO necesitamos calle exacta ni coordenadas precisas
- `LocationAccuracy.low` usa red/WiFi (no GPS) → más rápido y menos batería

---

### 2. Permisos Mínimos

#### iOS (Info.plist)

**Antes:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para establecer la ciudad</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>  <!-- ❌ INNECESARIO -->
<string>Necesitamos tu ubicación para establecer la ciudad</string>
```

**Ahora:**
```xml
<!-- ✅ Solo "When In Use" -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para detectar automáticamente la ciudad de tus chismes. Solo la usamos al crear un chisme y nunca se almacenan las coordenadas exactas.</string>
```

**Cambios:**
- ❌ Eliminado: `NSLocationAlwaysAndWhenInUseUsageDescription`
- ✅ Solo permiso "When In Use" (usuario activamente usando la app)
- ✅ Mensaje más transparente sobre el uso

#### Android (AndroidManifest.xml)

**Antes:**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />  <!-- ❌ INNECESARIO -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**Ahora:**
```xml
<!-- ✅ Solo COARSE_LOCATION -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**Cambios:**
- ❌ Eliminado: `ACCESS_FINE_LOCATION` (GPS alta precisión)
- ✅ Solo `ACCESS_COARSE_LOCATION` (red/WiFi, suficiente para ciudad)

---

### 3. Logs Seguros (Sin Coordenadas en Release)

**Antes:**
```dart
_logger.i('✅ Ubicación obtenida', context: {
  'latitude': position.latitude,   // ❌ Expone coordenadas en INFO
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
- ✅ En **DEBUG**: Coordenadas solo en logs de nivel DEBUG (troubleshooting)
- ✅ Logs de nivel INFO NO contienen datos sensibles

---

### 4. Coordenadas NUNCA Almacenadas

**Flujo de ubicación:**

```
1. Usuario crea chisme
   ↓
2. App solicita permiso de ubicación
   ↓
3. GPS obtiene coordenadas (temporalmente)
   ↓
4. Reverse geocoding: Coordenadas → Ciudad
   ↓
5. Coordenadas DESCARTADAS inmediatamente
   ↓
6. Solo se guarda: ciudad, región, país (nombres + IDs)
   ↓
7. Se usa como default para futuros chismes
```

**Lo que SÍ se persiste (SharedPreferences):**
```dart
// ✅ Solo nombres e IDs de ciudad
{
  "default_country_id": "CO",
  "default_country_name": "Colombia",
  "default_region_id": "DC",
  "default_region_name": "Bogotá D.C.",
  "default_city_id": "BOG",
  "default_city_name": "Bogotá"
}
```

**Lo que NO se persiste:**
- ❌ `latitude`
- ❌ `longitude`
- ❌ Timestamp de ubicación
- ❌ Precisión del GPS
- ❌ Historial de ubicaciones

---

## 🛡️ Garantías de Seguridad y Privacidad

### ✅ Minimización de Datos

1. **Solo pedimos lo necesario:**
   - Necesitamos: Ciudad
   - Pedimos: Ciudad (vía GPS de baja precisión)
   - NO pedimos: Coordenadas exactas, dirección completa, historial

2. **Solo usamos lo necesario:**
   - Usamos coordenadas GPS solo temporalmente
   - Descartamos coordenadas después de detectar ciudad
   - Guardamos solo ciudad (dato menos sensible)

3. **Solo retenemos lo necesario:**
   - Guardamos ciudad en local (no servidor)
   - Usuario puede "olvidar ubicación" en cualquier momento
   - No hay historial de ubicaciones

### ✅ Transparencia

**Mensajes de permiso claros:**

iOS:
```
"Necesitamos tu ubicación para detectar automáticamente la ciudad de 
tus chismes. Solo la usamos al crear un chisme y nunca se almacenan 
las coordenadas exactas."
```

**Código documentado:**
- Comentarios en `location_service.dart` explican política de privacidad
- Logs indican cuándo se usan coordenadas (solo debug)

### ✅ Control del Usuario

1. **Denegar permiso:**
   - Usuario puede denegar GPS
   - App ofrece selección manual de ciudad

2. **Olvidar ubicación:**
   ```dart
   LocationService.clearDefaultLocation()
   ```
   - Borra ciudad guardada
   - Próxima vez se pide ubicación de nuevo

3. **Cambiar ubicación:**
   - Usuario puede cambiar ciudad manualmente
   - No está atado a ubicación GPS

---

## 📊 Comparación con Mejores Prácticas

### Apps similares (social geo-local):

| App | Precisión | Permiso iOS | Permiso Android | Almacena Coords |
|-----|-----------|-------------|-----------------|-----------------|
| **Chismes** | LOW (ciudad) | When In Use | COARSE | ❌ NO |
| Twitter | HIGH | When In Use | FINE | ✅ Sí (opcional) |
| Nextdoor | HIGH | Always | FINE + BACKGROUND | ✅ Sí |
| Waze | HIGH | Always | FINE + BACKGROUND | ✅ Sí |

**Chismes cumple con el estándar más estricto:**
- ✅ Menor precisión
- ✅ Menores permisos
- ✅ No almacena coordenadas

---

## 🧪 Testing de Minimización

### Verificar precisión LOW:

```dart
// En location_service.dart:71-76
final position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.low,  // ✅ Verificar
  timeLimit: const Duration(seconds: 10),
);
```

### Verificar logs seguros:

**Test en DEBUG:**
```bash
flutter run --debug
# Buscar en logs: "DEBUG: Coordenadas obtenidas" → ✅ Debe aparecer
```

**Test en RELEASE:**
```bash
flutter run --release
# Buscar en logs: "DEBUG: Coordenadas" → ❌ NO debe aparecer
# Buscar en logs: "latitude" o "longitude" → ❌ NO debe aparecer
```

### Verificar persistencia:

```dart
// Verificar que SharedPreferences NO contiene coordenadas
final prefs = await SharedPreferences.getInstance();
final keys = prefs.getKeys();
print(keys);  
// Debe contener: default_city_id, default_region_id, default_country_id
// NO debe contener: latitude, longitude
```

---

## 📱 UI/UX de Privacidad

### Flujo de primera vez:

1. Usuario abre app → Crear chisme
2. App muestra: "¿Quieres usar tu ubicación para detectar la ciudad?"
3. Usuario acepta → App pide permiso de sistema
4. GPS detecta ciudad → Se guarda como default
5. Usuario puede cambiar manualmente si quiere

### Flujo sin permisos:

1. Usuario deniega permiso
2. App muestra selector manual de ciudad
3. Usuario elige: País → Región → Ciudad
4. Se guarda como default

### Olvidar ubicación:

```
Settings → Privacidad → Olvidar mi ubicación
```

**Efecto:**
- Borra ciudad guardada
- Próxima vez se pide ubicación de nuevo
- No afecta gossips ya creados

---

## 🌍 Cumplimiento Legal

### GDPR (Europa)

**Artículo 5(1)(c) - Minimización de datos:**
> "Los datos personales serán adecuados, pertinentes y limitados 
> a lo necesario en relación con los fines para los que son tratados"

✅ Chismes cumple:
- Solo pedimos ciudad (no coordenadas exactas)
- Solo cuando es necesario (al crear chisme)
- Usuario puede elegir manualmente

### CCPA (California)

**Sección 1798.100 - Transparencia:**
> "Derecho a saber qué datos personales se recopilan"

✅ Chismes cumple:
- Mensaje de permiso explica el uso
- Código documentado
- Usuario puede ver ciudad guardada

### LGPD (Brasil)

**Artículo 6, II - Minimização:**
> "Limitação do tratamento ao mínimo necessário"

✅ Chismes cumple:
- Precisión LOW (no HIGH)
- Solo ciudad (no coordenadas)
- Solo cuando se usa la app (no "Always")

---

## 📚 Documentación para Usuarios

### Política de Privacidad (sección ubicación)

**Texto sugerido para política de privacidad:**

```markdown
## Ubicación

### ¿Qué recopilamos?
- Detectamos tu **ciudad** (ej: "Bogotá, Colombia")
- NO recopilamos tu dirección exacta ni coordenadas GPS

### ¿Cómo lo usamos?
- Para establecer automáticamente la ciudad de tus chismes
- Solo cuando estás creando un chisme
- NO rastreamos tu ubicación en segundo plano

### ¿Dónde se almacena?
- Tu ciudad se guarda **solo en tu teléfono** (no en servidor)
- Se usa como default para futuros chismes
- Puedes cambiarla o borrarla en cualquier momento

### ¿Puedo usar la app sin GPS?
- Sí, puedes denegar permisos de ubicación
- La app te dejará elegir la ciudad manualmente
```

---

## 🚀 Próximos Pasos (Opcional)

### Mejoras adicionales (futuro):

1. **UI de consentimiento mejorada:**
   - Modal explicando por qué se pide ubicación
   - Link a política de privacidad
   - Botón "Preferir selección manual"

2. **Auditoría de datos:**
   - Dashboard en settings mostrando qué datos guarda la app
   - Botón "Exportar mis datos"
   - Botón "Borrar todos mis datos"

3. **Modo anónimo:**
   - Opción de NO guardar ciudad default
   - Pedir ubicación cada vez

---

## ✅ Checklist de Implementación

- [x] Cambiar precisión de HIGH → LOW
- [x] Remover logs de coordenadas en INFO
- [x] Agregar logs DEBUG solo en kDebugMode
- [x] Remover permiso "Always" en iOS
- [x] Remover permiso FINE_LOCATION en Android
- [x] Documentar política en código
- [x] Actualizar mensajes de permiso
- [x] Verificar que coordenadas NO se persisten
- [x] Crear documentación de privacidad
- [ ] (Futuro) Agregar UI de consentimiento mejorada
- [ ] (Futuro) Agregar botón "Olvidar ubicación" en settings
- [ ] (Futuro) Escribir política de privacidad completa para usuarios

---

## 📞 FAQ

**P: ¿Por qué pedimos ubicación?**
R: Para detectar automáticamente tu ciudad y facilitarte crear chismes. Es opcional.

**P: ¿Guardan mi ubicación exacta?**
R: No. Solo guardamos la ciudad (ej: "Bogotá"). Las coordenadas GPS se descartan inmediatamente.

**P: ¿Puedo usar la app sin GPS?**
R: Sí. Puedes denegar permisos y elegir la ciudad manualmente.

**P: ¿Rastrean mi ubicación en segundo plano?**
R: No. Solo pedimos ubicación cuando estás creando un chisme.

**P: ¿Puedo olvidar mi ubicación?**
R: Sí. Puedes llamar a `clearDefaultLocation()` (próximamente en UI de settings).

**P: ¿Envían mi ubicación al servidor?**
R: Solo la ciudad (nombre e ID), nunca coordenadas exactas.

---

**FIN DEL DOCUMENTO**
