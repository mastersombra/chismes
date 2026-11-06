# Política de Privacidad - Chismes

**Fecha de vigencia:** 22 de octubre de 2026  
**Última actualización:** 22 de octubre de 2026  
**Versión:** 1.0

---

## 1. Introducción

Bienvenido a **Chismes** ("nosotros", "nuestro" o "la app"). Nos tomamos muy en serio tu privacidad y estamos comprometidos con la protección de tus datos personales.

Esta Política de Privacidad describe:
- Qué datos recopilamos
- Cómo usamos tus datos
- Con quién compartimos tus datos
- Tus derechos sobre tus datos
- Cómo protegemos tus datos

Al usar Chismes, aceptas esta Política de Privacidad.

---

## 2. Datos que Recopilamos

### 2.1. Información de Cuenta

**Qué recopilamos:**
- Correo electrónico
- Nombre de usuario (opcional)
- Contraseña (encriptada)

**Por qué:**
- Para crear y gestionar tu cuenta
- Para autenticación segura
- Para recuperación de contraseña

**Dónde se almacena:**
- Supabase (proveedor de backend)
- Servidores ubicados en: Estados Unidos

### 2.2. Ubicación

**Qué recopilamos:**
- **Solo tu ciudad** (ejemplo: "Bogotá, Colombia")
- **NO recopilamos** tu dirección exacta ni coordenadas GPS

**Cómo la obtenemos:**
- GPS de baja precisión (red/WiFi, no GPS de alta precisión)
- Solo cuando creas un chisme
- Solo si otorgas permisos de ubicación

**Por qué:**
- Para establecer automáticamente la ciudad de tus chismes
- Para experiencia de usuario mejorada (UX tipo Uber/Mercado Libre)

**Dónde se almacena:**
- Localmente en tu teléfono (SharedPreferences)
- En el servidor: Solo la ciudad de cada chisme que publicas

**Importante:**
- Las coordenadas GPS se usan **solo temporalmente** para detectar la ciudad
- Después se descartan **inmediatamente**
- **NUNCA** almacenamos tus coordenadas exactas
- **NUNCA** enviamos coordenadas al servidor
- Solo guardamos: ciudad, región, país (nombres + IDs)

**Permisos:**
- iOS: "When In Use" (solo cuando usas la app)
- Android: `ACCESS_COARSE_LOCATION` (precisión de red/WiFi)
- **NO** pedimos permisos de ubicación en segundo plano

**Control:**
- Puedes denegar permisos de ubicación
- Puedes elegir la ciudad manualmente (sin GPS)
- Puedes olvidar tu ubicación guardada en cualquier momento

### 2.3. Contenido de Chismes

**Qué recopilamos:**
- Título del chisme (hasta 200 caracteres)
- Contenido del chisme (hasta 1000 caracteres)
- Imagen (opcional, máx 5 MB)
- Audio (opcional, máx 10 MB)
- Ciudad donde ocurrió el chisme

**Por qué:**
- Para publicar y mostrar tu chisme
- Para moderar contenido inapropiado

**Dónde se almacena:**
- Supabase (base de datos y almacenamiento)
- Servidores ubicados en: Estados Unidos

### 2.4. Metadatos

**Qué recopilamos:**
- Fecha y hora de creación
- Estado de moderación
- Contadores (vistas, likes, comentarios)

**Por qué:**
- Para funcionamiento de la app
- Para estadísticas y mejoras

---

## 3. Cómo Usamos tus Datos

### 3.1. Proporcionar el Servicio

- Crear y gestionar tu cuenta
- Publicar tus chismes
- Mostrar chismes de otros usuarios
- Gestionar interacciones (likes, comentarios)

### 3.2. Moderación de Contenido

Para mantener Chismes seguro, moderamos todo el contenido antes de publicarlo.

**Proceso de moderación:**

1. **Reglas locales** (rápidas, ~10ms):
   - Amenazas creíbles
   - Datos personales (email, teléfono)
   - Spam (URLs, repeticiones)

2. **OpenAI Moderation API** (IA, ~200ms):
   - Análisis contextual de texto
   - Detección de: odio, acoso, violencia, contenido sexual, etc.

**Datos compartidos con OpenAI:**
- ✅ Texto del chisme (título + contenido)
- ❌ **NO** compartimos: tu nombre, ubicación, imagen, audio, ni otros datos personales

**Retención por OpenAI:**
- OpenAI retiene el texto por **30 días** (monitoreo de abuso)
- Después se elimina automáticamente
- **NO se usa para entrenar modelos de IA**

**Fuente:** [OpenAI API Data Usage Policies](https://openai.com/policies/api-data-usage-policies)

**Decisiones:**
- **Aprobado:** Se publica inmediatamente
- **Revisión:** Se publica en estado "pending" (revisión manual)
- **Rechazado:** No se publica, recibes feedback

### 3.3. Mejorar el Servicio

- Analizar uso de la app
- Corregir errores técnicos
- Mejorar funcionalidades

### 3.4. Comunicación

- Notificaciones sobre tu cuenta
- Responder a tus consultas
- Información sobre cambios en políticas

---

## 4. Con Quién Compartimos tus Datos

### 4.1. Proveedores de Servicios

**Supabase** (Backend y almacenamiento):
- Propósito: Base de datos, autenticación, almacenamiento de archivos
- Ubicación: Estados Unidos
- Política: [Supabase Privacy Policy](https://supabase.com/privacy)

**OpenAI** (Moderación de contenido):
- Propósito: Análisis de texto para detectar contenido inapropiado
- Datos compartidos: Solo texto del chisme (título + contenido)
- Retención: 30 días, luego se elimina
- Ubicación: Estados Unidos
- Política: [OpenAI Privacy Policy](https://openai.com/policies/privacy-policy)

### 4.2. Cumplimiento Legal

Podemos divulgar tus datos si:
- Lo requiere la ley
- Es necesario para proteger derechos legales
- Es necesario para prevenir fraude o abuso

### 4.3. Transferencias Internacionales

Tus datos pueden ser transferidos y almacenados en servidores ubicados fuera de tu país (Estados Unidos).

Nos aseguramos de que estas transferencias cumplan con:
- GDPR (para usuarios en UE): Cláusulas Contractuales Estándar (SCC)
- Otras regulaciones aplicables

### 4.4. NO Vendemos tus Datos

**NUNCA** vendemos, alquilamos ni compartimos tus datos personales con terceros para fines de marketing.

---

## 5. Tus Derechos

### 5.1. Acceso

Tienes derecho a solicitar una copia de tus datos personales.

### 5.2. Rectificación

Puedes corregir datos incorrectos o incompletos en:
- Settings → Editar perfil

### 5.3. Eliminación ("Derecho al olvido")

Puedes solicitar la eliminación de tus datos.

**Cómo ejercer:**
- Contactar: privacy@chismes.app
- Respuesta: Dentro de 30 días

**Qué se elimina:**
- Tu cuenta
- Tus chismes
- Tus interacciones

**Excepciones:**
- Datos requeridos por ley (retención mínima)
- Datos agregados/anónimos para estadísticas

### 5.4. Portabilidad

Puedes solicitar una copia de tus datos en formato estructurado (JSON).

### 5.5. Oposición

Puedes oponerte al procesamiento de tus datos para ciertos fines.

### 5.6. Restricción

Puedes solicitar que limitemos el procesamiento de tus datos.

### 5.7. Olvidar Ubicación

Puedes borrar la ciudad guardada en cualquier momento:
- Settings → Privacidad → Olvidar mi ubicación

**Efecto:**
- Se borra la ciudad guardada localmente
- No afecta chismes ya publicados
- La próxima vez se pedirá ubicación de nuevo

---

## 6. Seguridad de los Datos

Implementamos medidas técnicas y organizativas para proteger tus datos:

### 6.1. Encriptación

- **En tránsito:** TLS/HTTPS para todas las comunicaciones
- **En reposo:** Contraseñas hasheadas (bcrypt)

### 6.2. Acceso Restringido

- Solo personal autorizado tiene acceso a datos sensibles
- Principio de mínimo privilegio

### 6.3. Auditoría

- Logs de acceso a datos sensibles
- Revisiones periódicas de seguridad

### 6.4. Cuarentena de Media

- Imágenes y audios se suben a buckets privados (cuarentena)
- Solo se hacen públicos después de moderación
- Previene contenido inapropiado antes de aprobar

### 6.5. Minimización de Datos

- Solo recopilamos datos estrictamente necesarios
- GPS: Solo precisión baja (ciudad), no alta (calle exacta)
- Logs: No registran coordenadas GPS en producción

### 6.6. Límite de Intentos

- Rate limiting para prevenir abuso
- Protección contra ataques de fuerza bruta

**Nota:** Ningún sistema es 100% seguro. Hacemos nuestro mejor esfuerzo, pero no podemos garantizar seguridad absoluta.

---

## 7. Retención de Datos

### 7.1. Cuenta Activa

- Datos de cuenta: Mientras tu cuenta esté activa
- Chismes: Indefinidamente (o hasta que los elimines)
- Ubicación guardada: Hasta que la olvides o cierres cuenta

### 7.2. Cuenta Cerrada

- Datos de cuenta: 30 días (después se eliminan permanentemente)
- Chismes: Se marcan como "deleted" (soft delete)
- Logs de auditoría: 90 días (requisito legal)

### 7.3. Moderación (OpenAI)

- Texto enviado a OpenAI: 30 días (después se elimina)

### 7.4. Datos Agregados

- Datos anónimos/agregados: Indefinidamente (para estadísticas)

---

## 8. Menores de Edad

Chismes **NO** está dirigida a menores de 13 años.

- No recopilamos intencionalmente datos de menores de 13 años
- Si descubrimos que un menor nos proporcionó datos, los eliminaremos

**Si eres padre/madre:**
- Contacta: privacy@chismes.app si crees que tu hijo proporcionó datos

---

## 9. Cookies y Tecnologías Similares

### 9.1. Cookies

Actualmente **NO** usamos cookies en la app móvil.

**Futuro (si aplica):**
- Cookies de sesión (autenticación)
- Analytics (opcional, con consentimiento)

### 9.2. Identificadores de Dispositivo

- Usamos identificadores de dispositivo para autenticación
- No rastreamos tu actividad entre apps

---

## 10. Cambios en esta Política

Podemos actualizar esta Política de Privacidad ocasionalmente.

**Te notificaremos:**
- Cambios importantes: Notificación in-app
- Cambios menores: Actualización de "Última actualización" arriba

**Tu responsabilidad:**
- Revisar esta política periódicamente
- Continuar usando la app = aceptar cambios

---

## 11. Cumplimiento Legal

### 11.1. GDPR (Europa)

Si resides en la Unión Europea:
- Tienes derechos adicionales (ver sección 5)
- Base legal para procesamiento: Consentimiento, ejecución de contrato
- Puedes presentar quejas ante tu autoridad de protección de datos

### 11.2. CCPA (California)

Si resides en California:
- Derecho a saber qué datos recopilamos
- Derecho a solicitar eliminación
- Derecho a optar por no vender (no vendemos datos)

### 11.3. LGPD (Brasil)

Si resides en Brasil:
- Tienes derechos similares a GDPR
- Puedes presentar quejas ante ANPD

---

## 12. Contacto

### 12.1. Preguntas sobre Privacidad

**Email:** privacy@chismes.app  
**Respuesta:** Dentro de 30 días

### 12.2. Ejercer Derechos

Para ejercer tus derechos (acceso, eliminación, portabilidad):
- Envía email a: privacy@chismes.app
- Incluye: Tu email de cuenta, descripción de solicitud

### 12.3. Oficial de Protección de Datos (DPO)

(Si aplica en el futuro)

**Email:** dpo@chismes.app

---

## 13. Resumen (TL;DR)

**¿Qué recopilamos?**
- Email, contraseña (encriptada)
- Ciudad (NO coordenadas exactas)
- Contenido de chismes (texto, imagen, audio)

**¿Cómo lo usamos?**
- Proporcionar el servicio
- Moderar contenido (con ayuda de OpenAI)
- Mejorar la app

**¿Con quién lo compartimos?**
- Supabase (backend)
- OpenAI (solo texto del chisme, 30 días)
- NO vendemos tus datos

**Tus derechos:**
- Acceder, rectificar, eliminar
- Olvidar ubicación
- Portabilidad de datos

**Seguridad:**
- Encriptación (TLS/HTTPS)
- Cuarentena de media
- Minimización de datos (GPS LOW, no HIGH)

**Contacto:**
- privacy@chismes.app

---

## 14. Idiomas

Esta Política de Privacidad está disponible en:
- Español (este documento)
- Inglés (próximamente)

En caso de conflicto, prevalece la versión en español.

---

**¿Preguntas?** Contacta: privacy@chismes.app

**Fecha de vigencia:** 22 de octubre de 2026  
**Última actualización:** 22 de octubre de 2026

---

© 2026 Chismes. Todos los derechos reservados.
