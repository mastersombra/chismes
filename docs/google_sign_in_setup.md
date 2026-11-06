# Configuración de Google Sign-In

Este documento explica cómo configurar Google Sign-In en el proyecto Chismes.

## ¿Por qué esta configuración?

Acabamos de migrar de `signInWithOAuth` (abre Safari completo) a `google_sign_in` package (usa Custom Tabs). Esto mejora la UX significativamente, mostrando la pantalla como Epic Games y otras apps profesionales.

---

## Configuración Necesaria

### 1. Google Cloud Console

**Necesitas crear credenciales OAuth 2.0:**

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto (o crea uno nuevo)
3. Ve a **APIs & Services** → **Credentials**
4. Crea credenciales:

#### **A) Android (OAuth 2.0 Client)**
- Tipo: **Android**
- Package name: `com.piloto.chismes` (verificar en `android/app/build.gradle.kts`)
- SHA-1: Obtenerlo con:
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```
- Copia el **Client ID** generado

#### **B) Web (OAuth 2.0 Client)** ⭐ **IMPORTANTE**
- Tipo: **Web application**
- Authorized redirect URIs:
  ```
  https://[TU-PROYECTO].supabase.co/auth/v1/callback
  ```
- Copia el **Web Client ID** → Este es el que necesita Supabase

#### **C) iOS (OAuth 2.0 Client)**
- Tipo: **iOS**
- Bundle ID: `com.piloto.chismes` (verificar en `ios/Runner/Info.plist`)
- Copia el **iOS Client ID**

---

### 2. Supabase Dashboard

1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com/)
2. **Authentication** → **Providers** → **Google**
3. Habilita Google
4. Pega el **Web Client ID** (del paso 1B)
5. Pega el **Client Secret** (también del paso 1B)
6. **Save**

---

### 3. Código (opcional - mejorar)

**Actualmente el código usa configuración básica:**

```dart
final googleSignIn = GoogleSignIn(
  scopes: ['email'],
);
```

**Opcionalmente puedes agregar el serverClientId explícito:**

```dart
final googleSignIn = GoogleSignIn(
  scopes: ['email'],
  serverClientId: 'TU-WEB-CLIENT-ID.apps.googleusercontent.com',
);
```

> **Nota:** En Android, `google-services.json` (si lo agregas) ya contiene esta info.

---

### 4. Android - google-services.json (Recomendado)

**Descarga el archivo:**
1. En Google Cloud Console → **APIs & Services** → **Credentials**
2. Busca tu OAuth client (Android)
3. O descarga desde Firebase Console si usas Firebase
4. Descarga `google-services.json`

**Coloca el archivo:**
```
android/app/google-services.json
```

**Actualiza `android/build.gradle.kts`:**
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

**Actualiza `android/app/build.gradle.kts`:**
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

---

### 5. iOS - GoogleService-Info.plist (Recomendado)

**Descarga el archivo:**
1. Similar a Android, desde Google Cloud Console o Firebase
2. Descarga `GoogleService-Info.plist`

**Coloca el archivo:**
```
ios/Runner/GoogleService-Info.plist
```

**Actualiza `ios/Runner/Info.plist`:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Reversed client ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.TU-CLIENT-ID-REVERSED</string>
        </array>
    </dict>
</array>
```

---

## Testing

### Verificar que funciona:

**Android:**
```bash
flutter run
# Tap en "Continuar con Google"
# Debería abrir Custom Tabs (no Safari completo)
# Seleccionar cuenta → Regresar a la app
```

**iOS:**
```bash
flutter run
# Tap en "Continuar con Google"
# Debería abrir SFAuthenticationSession (no Safari completo)
# Seleccionar cuenta → Regresar a la app
```

---

## Troubleshooting

### "No se puede autenticar"
- ✅ Verifica que el Web Client ID esté en Supabase Dashboard
- ✅ Verifica que el redirect URI coincida exactamente

### "PlatformException(sign_in_failed)"
- ✅ Verifica el SHA-1 en Android
- ✅ Verifica que `google-services.json` esté en `android/app/`

### "Error 10" en Android
- ✅ El Web Client ID no está configurado o es incorrecto
- ✅ Agrega explícitamente `serverClientId` en el código

### iOS no abre el login
- ✅ Verifica el URL Scheme en `Info.plist`
- ✅ Verifica que `GoogleService-Info.plist` exista

---

## ¿Qué cambió vs antes?

| Aspecto | Antes (OAuth directo) | Ahora (google_sign_in) |
|---------|----------------------|------------------------|
| **UX** | Abre Safari completo | Custom Tabs / SFAuthenticationSession |
| **Cuentas guardadas** | No las muestra | ✅ Muestra cuentas del dispositivo |
| **Experiencia** | Sale de la app | Se siente dentro de la app |
| **Como Epic Games** | ❌ No | ✅ Sí |

---

## Próximos pasos

1. ✅ google_sign_in configurado
2. 🔜 Agregar Apple Sign-In (similar)
3. 🔜 Traducir mensajes a español (i18n)

---

**Fecha:** 2026-11-03  
**Autor:** Claude + Alejo
