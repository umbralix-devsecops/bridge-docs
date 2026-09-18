# bridge-docs — Documentación del Bridge Service

Documentación técnica del **Bridge Service**: el servicio .NET 8 que recibe el catálogo de
SinsaTools por una API de ingesta propia y **es el backend del Portal de Videos** — identidad,
permisos, catálogo y proxy de streaming para el frontend Angular.

Este repositorio contiene **solo documentación**. El código vive en `Sin-PortalBridge`
(.NET 8).

---

## Por dónde empezar

| Si eres… | Lee esto primero |
|---|---|
| Alguien que retoma el proyecto | **[`00_Estado_Actual.adoc`](00_Estado_Actual.adoc)** |
| Un agente o colaborador nuevo | [`Guia_Agentes.adoc`](Guia_Agentes.adoc) |
| Quien va a escribir la primera línea de código | [`Analisis_Arranque_Bridge_v1.0.adoc`](Analisis_Arranque_Bridge_v1.0.adoc) |
| Buscas un documento concreto | [`index.adoc`](index.adoc) |
| No entiendes un `RF-BS-12` o un `ADR-BS-006` | [`Glosario_IDs.adoc`](Glosario_IDs.adoc) |
| Quieres el mapa de repositorios | [`Mapa_Subproyectos.adoc`](Mapa_Subproyectos.adoc) |

`manifest.yaml` es el catálogo legible por máquina: qué documentos existen, cuáles están
vigentes y cómo se relacionan.

> **Si lees algo anterior al 2026-09-16, compruébalo antes de usarlo.** Ese día cambió la
> arquitectura: ya no hay tres servicios y nunca consultamos la base de datos de SinsaTools.
> Todo lo que hable del `SyncWorker`, del `OnPremiseDbContext`, de un backend de portal
> separado o de los contratos `bridge_*.yaml` está en `_historico/`.

---

## Estado

**Documentación:** requerimientos (v2.0), arquitectura técnica (v2.0), glosario de IDs (v2.0),
índice de ADR (v2.0), `ADR-BS-005`, `ADR-BS-006`, el contrato de ingesta y el modelo de datos
v2 están cerrados y son mutuamente coherentes. El resto de secciones, pendiente.

**Código:** sin empezar. `Sin-PortalBridge` tiene un commit y un `README.md` equivocado —
describe un frontend Angular, copiado del repositorio del portal.

**Ninguna decisión interna bloquea el diseño.** Las dos que bloqueaban la v1.1 —`DEC-BS-01`
(frecuencia del sync) y `DEC-BS-02` (conectividad corporativa)— quedaron **sin objeto**: el
problema desapareció, no se resolvió.

**Lo que sí bloquea:**

| Qué | Quién lo desbloquea | Bloquea |
|---|---|---|
| Acuerdo del contrato de ingesta, credenciales y cadencia | Equipo de SinsaTools | La llegada de **datos reales**. No el desarrollo: `tools/IngestSimulator` alimenta el servicio con las semillas del mock del frontend (250 productos, 613 versiones, 1.842 recursos) |
| `DEC-BS-11` — añadir `GET /media/{id}/access` a `api_media.yaml` | Contrato del frontend | La reproducción de **todos** los recursos: el frontend ya llama a ese endpoint antes de cada `<video>` |
| `DEC-BS-07` — qué hace `POST /admin/sync` sin una base que consultar | Contrato del frontend | Solo ese botón. Mientras tanto se apaga con `features.triggerSync: false` en `config.json`, sin tocar código |

El detalle, en `00_Estado_Actual.adoc`.

---

## Cómo clonar

> **Importante:** este repositorio y `portal-docs` deben clonarse como **carpetas hermanas**
> bajo un directorio común.

```
mi-carpeta-de-trabajo/
├── portal-docs/        ← https://…/portal-docs
├── bridge-docs/        ← este repositorio
├── Sin-PortalVideos/   ← frontend Angular 21
└── Sin-PortalBridge/   ← Bridge Service .NET 8
```

La documentación del portal enlaza a los ADR de este repositorio mediante rutas relativas.
Sin la disposición hermana, esos enlaces no resuelven.

---

## Qué hace el Bridge Service

Es el **único componente de servidor del sistema**. Recibe el catálogo de SinsaTools por
empuje, lo persiste en un PostgreSQL 16 y lo sirve al frontend junto con la identidad, los
permisos y el streaming.

```
SinsaTools ──► microservicio de integraciones ──► Bridge Service ◄── frontend Angular
                                                        │
                                                   PostgreSQL 16
```

### Superficie de ingesta — `/v1`, Service JWT con `aud` propio

| Endpoint | Para qué |
|---|---|
| `POST /v1/auth/token` | Emite el Service JWT de ingesta (scope `catalog:ingest`) |
| `POST /v1/ingest/catalog` | Recibe un lote de catálogo. Valida la forma y responde `202` con el `ingestId` |
| `GET /v1/ingest/{ingestId}` | Resultado del lote: estado, contadores e ítems fallidos |
| `GET /v1/ingest/watermark` | `generatedAt` del último lote aplicado — el corte del siguiente incremental |
| `GET /health` | Estado operacional, incluida la frescura del catálogo. Público, sin autenticación |

### Superficie del portal — `/api`, User JWT

| Endpoint | Para qué |
|---|---|
| `POST /auth/login` · `/register` · `/refresh` · `/logout` | Identidad de las personas y rotación de sesión |
| `GET /catalog/products` · `/catalog/products/{productId}` | Catálogo paginado, con búsqueda y filtro por industria, recortado por permisos |
| `GET /catalog/versions/{versionId}/media` | Recursos de una versión, con `mediaCount` por usuario |
| `GET /media/{mediaId}/access` | Pre-flight de acceso antes de reproducir. **Falta en el contrato** — `DEC-BS-11` |
| `GET /media/{mediaId}/stream` | Proxy de streaming con soporte de `Range` (200 y 206) |
| `/admin/users/**` · `/admin/groups/**` · `/admin/logs/**` | Las 20 operaciones de administración: usuarios, aprobaciones, grupos, excepciones y logs |
| `/admin/sync/**` | Panel de sincronización, reinterpretado sobre el historial de ingesta (`RF-BS-20`) |

Contratos: la ingesta en `05_contratos_api/ingesta/ingest_catalog_v1.0.yaml`; la cara del
portal, en los seis `api_*.yaml` de `Sin-PortalVideos/openapi/sources/`.

> **Dos contratos bilaterales** (`REST-BS-06`), y no son simétricos. El de ingesta está emitido
> y pendiente de acuerdo con SinsaTools. Los seis del frontend **ya están implementados y
> probados del lado del cliente**: el servidor se adapta a ellos, y una divergencia es un fallo
> del servidor (`REST-BS-11`).

---

## Estructura

```
bridge-docs/
├── 00_Estado_Actual.adoc                ← documento vivo · primero a leer
├── index.adoc                           ← índice general
├── Guia_Agentes.adoc                    ← cómo leer y modificar esta documentación
├── Glosario_IDs.adoc                    ← prefijos de ID y trazabilidad
├── Mapa_Subproyectos.adoc               ← repos propios y contrapartes
├── Analisis_Arranque_Bridge_v1.0.adoc   ← qué hay construido y por dónde empezar
├── manifest.yaml                        ← catálogo legible por máquina
├── _nav.adoc                            ← fragmento de navegación compartido
├── 01_requerimientos/                   ← requerimientos v2.0 · RF / RNF / REST-BS
├── 04_arquitectura_tecnica/             ← arquitectura v2.0 + modelo de datos y su changelog
├── 05_contratos_api/ingesta/            ← ingest_catalog_v1.0.yaml
├── 11_gestion_producto/adr/             ← ADR-BS-001 al 006
├── _entregables/                        ← versión visual de la arquitectura
├── _plantillas/                         ← ADR, requerimiento, integración externa
└── 02, 03, 06..10, 12/                  ← pendientes
```

El modelo de datos vive en `04_arquitectura_tecnica/modelo_datos/modelo_datos_bridge_v2.mermaid`:
**una sola base PostgreSQL 16 con 14 tablas** que cubre catálogo, identidad, permisos y
auditoría. Que sea una sola es lo que permite claves foráneas reales entre los permisos y el
catálogo.

---

## Convenciones

**Prefijo de ADR.** Este repositorio usa `ADR-BS-NNN`, no `ADR-NNN`. Ambos conjuntos se leen
a menudo juntos, y sin sufijo `ADR-001` significaría dos cosas distintas según el
repositorio. El motivo está registrado en `11_gestion_producto/adr/adr-000_indice.adoc`.

**Vigente frente a histórico.** El documento vigente vive en la raíz de su sección. Las
versiones superadas se **mueven** a `_historico/` — nunca se borran. Una decisión que queda
**descartada** —porque el problema desapareció, no porque ganara otra opción— se marca como tal
y se queda donde está: es el caso de `ADR-BS-003`.

**Idioma.** Artefactos técnicos en **inglés**; documentación, comentarios y etiquetas de
actor en los diagramas, en **español**. Ver `language_policy` en `manifest.yaml`.

**Esquema de base de datos.** EF Core es la **única fuente de verdad** del esquema
(`ADR-BS-004`). Toda migración lleva su entrada `MIG-BS-NNN` en
`04_arquitectura_tecnica/modelo_datos/changelog_modelo_datos.adoc`.

> El catálogo es una **proyección de SinsaTools**: solo la ingesta escribe en `products`,
> `versions` y `media`, y ante una discrepancia manda el origen. Todo lo demás —usuarios,
> sesiones, grupos, permisos y auditoría— nace y muere aquí.

**Numeración quemada.** Los números de ID no se reutilizan nunca. El cambio de arquitectura del
2026-09-16 dio de baja 6 `RF-BS`, 1 `RNF-BS`, 5 `REST-BS`, 3 `DOM-BS`, 2 `SEC-BS`, 3 `DT-BS` y
3 `DEC-BS`. Todos figuran, con su motivo, en `Glosario_IDs.adoc`.

**Commits.** Conventional Commits, en inglés.

---

## Coordinación pendiente

**Con el equipo de SinsaTools** — es lo único que bloquea la llegada de datos reales:

1. **El contrato de ingesta.** Que acepten `ingest_catalog_v1.0.yaml`, o lo discutan. Es la
   frontera completa entre los dos sistemas.
2. **Las credenciales.** `clientId` y `clientSecret` del microservicio de integraciones.
3. **La cadencia.** Cada cuánto empujan y si habrá foto completa periódica. De ahí salen el
   umbral de frescura y la alerta de catálogo obsoleto (`DEC-BS-09`).

**Con el contrato del frontend:**

4. **`GET /media/{id}/access` no está en `api_media.yaml`** y el frontend ya lo llama antes de
   cada reproducción. Sin él no se reproduce ningún recurso (`DEC-BS-11`).
5. **`POST /admin/sync` se queda sin sentido:** no se puede disparar la sincronización de una
   base que no se lee (`DEC-BS-07`).

Además, `bridge-docs` y `portal-docs` describen hoy un único sistema y duplican convenciones,
glosario e índice. Fundirlas está registrado como `DEC-BS-12`.

---

## Antes de dar un documento por cerrado

La lista completa está en `Guia_Agentes.adoc`. En resumen: cabecera estándar con `:root:`
correcto, `include::{root}/_nav.adoc[]` al inicio y al final, todos los `xref:` resolviendo,
ninguna referencia a componentes dados de baja, IDs nuevos en el glosario, IDs retirados en
«numeración quemada», e `index.adoc`, `manifest.yaml` y `00_Estado_Actual.adoc` actualizados en
el mismo commit.

---

**Clasificación:** Confidencial — Solo uso interno
