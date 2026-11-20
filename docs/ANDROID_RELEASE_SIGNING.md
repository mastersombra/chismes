# Android: signing de release

App ID: **`com.shadows.chismes`** (igual en iOS). No se puede cambiar después de publicar.

`android/app/build.gradle.kts` firma el build release con `android/key.properties`.
Si ese archivo no existe, usa la llave de **debug** (sirve para `flutter run --release`,
Play Store la rechaza).

## 1. Generar la upload key (una sola vez)

```bash
keytool -genkey -v -keystore ~/keys/chismes-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Guardar el `.jks` y las contraseñas en un gestor de contraseñas **con backup**.
Nunca dentro del repo (`*.jks`, `*.keystore` y `key.properties` están en `android/.gitignore`).

## 2. Crear `android/key.properties`

```properties
storePassword=<contraseña del keystore>
keyPassword=<contraseña de la key>
keyAlias=upload
storeFile=/Users/<usuario>/keys/chismes-upload.jks
```

## 3. Compilar

```bash
flutter build appbundle --dart-define-from-file=config/prod.json
# → build/app/outputs/bundle/release/app-release.aab
```

Verificar la firma: `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab`
(no debe decir `CN=Android Debug`).

## 4. Play Console

- Activar **Play App Signing** (default en apps nuevas): Google guarda la llave final y
  el `.jks` de arriba es solo la *upload key*. Si se pierde, Google permite reemplazarla;
  sin Play App Signing, perder la llave = no poder actualizar la app nunca más.
- Subir el `.aab` a **Internal testing** para la beta.
- Registrar en Google Cloud (OAuth Android client) el SHA-1 de la upload key **y** el de
  la llave de Play App Signing; si no, Google Sign-In falla en builds de la tienda.
  Ver `docs/google_sign_in_setup.md`.
