# 📊 Configuración de Codecov - Instrucciones

## ✅ Ya Configurado

- ✅ `codecov.yml` creado
- ✅ GitHub Actions actualizado
- ✅ Coverage se generará automáticamente

---

## 🔧 Pasos para Activar (5 minutos)

### 1. Crear cuenta en Codecov

Ve a: **https://about.codecov.io/sign-up/**

- Click en "Sign up with GitHub"
- Autoriza Codecov

### 2. Agregar el repositorio

- En Codecov dashboard → "Add new repository"
- Busca: `mastersombra/chismes`
- Click en "Setup repo"

### 3. Copiar el token

Codecov te mostrará un token como:
```
abc123-def456-ghi789...
```

### 4. Agregar token a GitHub Secrets

1. Ve a: **https://github.com/mastersombra/chismes/settings/secrets/actions**
2. Click: "New repository secret"
3. Name: `CODECOV_TOKEN`
4. Value: Pega el token de Codecov
5. Click: "Add secret"

### 5. Verificar que funciona

```bash
# Haz un push cualquiera
git checkout -b test/codecov
echo "test" >> README.md
git add .
git commit -m "test: codecov"
git push origin test/codecov
```

Crea un PR y espera ~2 minutos. Verás:
- ✅ Comentario de Codecov en el PR con coverage
- ✅ Badge verde/rojo según coverage

---

## 📊 Configuración Actual

### Umbrales
```yaml
Project target: 75% (±2%)
Patch target: 70%
Current: 78.9% ✅
```

### Archivos Ignorados
```yaml
- *.g.dart (generated)
- *.mocks.dart (test mocks)
- *.freezed.dart (freezed)
- test/** (test files)
- tools/** (tooling)
```

---

## 🏷️ Badge para README (Opcional)

Después de configurar, agrega al README:

```markdown
[![codecov](https://codecov.io/gh/mastersombra/chismes/branch/main/graph/badge.svg)](https://codecov.io/gh/mastersombra/chismes)
```

---

## ❓ Troubleshooting

**Error: "Missing token"**
→ Verifica que agregaste `CODECOV_TOKEN` en GitHub Secrets

**Error: "No coverage found"**
→ Espera a que CI termine completamente (~3-5 min)

**Badge no aparece**
→ Codecov necesita al menos 1 upload exitoso

---

## 📈 ¿Qué Verás en PRs?

```
Codecov Report
Merging #123 into main will increase coverage by 0.5%

Coverage: 79.4% (+0.5%)
Files changed: 3
Lines covered: 1,890 / 2,380

📊 Detailed report: [link]
```

---

**✅ Listo para usar después de seguir los 5 pasos**
