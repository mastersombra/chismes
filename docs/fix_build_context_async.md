# Fix: BuildContext Across Async Gaps

**Fecha:** 2026-10-22  
**Status:** ✅ RESUELTO  
**Archivo:** `lib/features/auth/presentation/screens/privacy_settings_screen.dart`

---

## 📋 Problema Original

### Warning de Dart Analysis:
```
Don't use 'BuildContext's across async gaps.
Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check.

Location: privacy_settings_screen.dart:336
```

### Código Problemático:

```dart
Future<void> _deleteAccount() async {
  // Primer showDialog
  final confirmed = await showDialog<bool>(
    context: context,  // ✅ OK - primer uso
    builder: (context) => AlertDialog(...),
  );

  if (confirmed != true) return;

  // ❌ PROBLEMA: Usar context después de await sin verificar mounted
  final controller = TextEditingController();
  final doubleConfirmed = await showDialog<bool>(
    context: context,  // ❌ Error en línea 336
    builder: (context) => AlertDialog(...),
  );
}
```

**¿Por qué es un problema?**

Después de un `await`, el widget puede haber sido desmontado (disposed) del árbol de widgets. Si se usa el `BuildContext` en ese momento:
- Puede causar excepciones en runtime
- Puede intentar navegar/mostrar SnackBars en widgets que ya no existen
- Es considerado unsafe por el análisis de Flutter

---

## ✅ Solución Aplicada

### Pattern: Verificar `mounted` después de cada `await`

```dart
Future<void> _deleteAccount() async {
  // Primer showDialog
  final confirmed = await showDialog<bool>(
    context: context,  // ✅ OK - primer uso
    builder: (context) => AlertDialog(...),
  );

  if (confirmed != true) return;
  if (!mounted) return;  // ✅ FIX: Verificar mounted

  // Segundo showDialog (ahora seguro)
  final controller = TextEditingController();
  final doubleConfirmed = await showDialog<bool>(
    context: context,  // ✅ Ahora es seguro
    builder: (context) => AlertDialog(...),
  );

  if (doubleConfirmed != true) {
    if (!mounted) return;  // ✅ Verificar mounted
    ScaffoldMessenger.of(context).showSnackBar(...);
    return;
  }

  // TODO: Implementar eliminación real con backend
  // await AuthService.deleteAccount();

  if (!mounted) return;  // ✅ Verificar mounted

  // Logout y volver a login
  ScaffoldMessenger.of(context).showSnackBar(...);
  Navigator.pushReplacementNamed(context, '/login');
}
```

---

## 📝 Regla General

**Después de CADA operación `await`, verificar `mounted` antes de usar `context`:**

```dart
// Pattern correcto
Future<void> myAsyncMethod() async {
  // 1. Operación async
  final result = await someAsyncOperation();
  
  // 2. Verificar mounted ANTES de usar context
  if (!mounted) return;
  
  // 3. Ahora es seguro usar context
  Navigator.push(context, ...);
  ScaffoldMessenger.of(context).showSnackBar(...);
  setState(() { ... });
}
```

**Operaciones que requieren verificación:**
- `Navigator.push/pop/pushReplacement/etc`
- `ScaffoldMessenger.of(context).showSnackBar`
- `showDialog(context: context, ...)`
- `Theme.of(context)`
- `MediaQuery.of(context)`
- Cualquier uso de `context` después de `await`

---

## 🔍 Verificación en Otros Métodos

Revisé todos los métodos async en `privacy_settings_screen.dart`:

### ✅ `_forgetLocation()` - Ya estaba correcto
```dart
Future<void> _forgetLocation() async {
  final confirmed = await showDialog<bool>(...);
  if (confirmed != true) return;
  
  await _locationService.clearDefaultLocation();
  await _loadSettings();
  
  if (!mounted) return;  // ✅ Verificación presente
  
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### ✅ `_clearAllData()` - Ya estaba correcto
```dart
Future<void> _clearAllData() async {
  final confirmed = await showDialog<bool>(...);
  if (confirmed != true) return;
  
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await _loadData();
  
  if (!mounted) return;  // ✅ Verificación presente
  
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### ✅ `_deleteAccount()` - CORREGIDO
```dart
Future<void> _deleteAccount() async {
  final confirmed = await showDialog<bool>(...);
  if (confirmed != true) return;
  if (!mounted) return;  // ✅ AGREGADO
  
  final doubleConfirmed = await showDialog<bool>(...);
  
  if (doubleConfirmed != true) {
    if (!mounted) return;  // ✅ Ya estaba
    ScaffoldMessenger.of(context).showSnackBar(...);
    return;
  }
  
  if (!mounted) return;  // ✅ Ya estaba
  
  ScaffoldMessenger.of(context).showSnackBar(...);
  Navigator.pushReplacementNamed(context, '/login');
}
```

---

## 🧪 Verificación

### Análisis de Dart:
```bash
flutter analyze /Users/alejo/Documents/Piloto/chismes/lib/features/auth/presentation/screens/privacy_settings_screen.dart

✅ No issues found! (ran in 1.5s)
```

### Análisis completo del proyecto:
```bash
flutter analyze --no-pub

✅ No issues found!
```

---

## 📦 Cambios Realizados

**Archivo modificado:**
- `lib/features/auth/presentation/screens/privacy_settings_screen.dart:332`

**Líneas agregadas:**
```diff
  if (confirmed != true) return;
+ if (!mounted) return;

  final controller = TextEditingController();
```

---

## 🎯 Impacto

### Antes:
- ❌ Warning de análisis estático
- ❌ Potencial crash si widget es desmontado
- ❌ Uso unsafe de BuildContext

### Después:
- ✅ Sin warnings de análisis
- ✅ Safe: Verifica si widget está montado antes de usar context
- ✅ Previene crashes por uso de context en widgets desmontados
- ✅ Patrón consistente con otros métodos del archivo

---

## 📚 Referencias

- [Flutter Documentation: BuildContext](https://api.flutter.dev/flutter/widgets/BuildContext-class.html)
- [Flutter Documentation: State.mounted](https://api.flutter.dev/flutter/widgets/State/mounted.html)
- [Lint Rule: use_build_context_synchronously](https://dart.dev/diagnostics/use_build_context_synchronously)

---

**FIN DEL DOCUMENTO**
