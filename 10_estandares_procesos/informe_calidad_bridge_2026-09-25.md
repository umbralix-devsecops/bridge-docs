# Informe de calidad de código — Bridge Service

**Fecha:** 2026-09-25 · **Alcance:** `Sin-PortalBridge/src` (Api, Application, Infrastructure), rama `feat/fase-7-streaming` · **Tipo:** revisión estática, sin cambios en el código.

---

## 1. Veredicto

**Sí, el Bridge cumple con SOLID y con las reglas de código limpio en lo sustancial.** La arquitectura está bien separada y el build la vigila: pruebas de arquitectura, analizadores en modo `All` y warnings tratados como errores. Los desvíos que encontré son de forma y no de diseño. Casi todos son choques con dos reglas del propio estándar (EST-BS-19 y EST-BS-20), no problemas que afecten al mantenimiento.

| Aspecto | Nota | Comentario corto |
|---|---|---|
| S — Responsabilidad única | 🟢 Bien | Un manejador por caso de uso, controladores delgados. Dos clases algo cargadas. |
| O — Abierto/cerrado | 🟢 Bien | Enums de fallo + `switch` exhaustivo. Un punto cerrado a un solo proveedor de almacenamiento, a propósito. |
| L — Sustitución de Liskov | 🟢 Cumple | Casi no hay herencia propia. No hay `NotImplementedException`. |
| I — Segregación de interfaces | 🟡 Mejorable | La mayoría de los puertos son chicos. Dos repositorios de administración tienen 16 métodos. |
| D — Inversión de dependencias | 🟢 Muy bien | Puertos en Application, adaptadores en Infrastructure, regla comprobada por pruebas. |
| Código limpio | 🟢/🟡 | Nombres, guardas y errores bien resueltos. Se desvía de EST-BS-19/20, hay métodos largos puntuales y mucho comentario histórico. |
| Patrones de diseño | 🟢 | Ya están los necesarios. **Agregar más ahora aporta poco**, salvo dos o tres ajustes puntuales. |
| Resiliencia | 🟡 | Buena base. **Hay 3 huecos que conviene cerrar antes de producción** (sección 6). |

---

## 2. Método y cifras

- 141 archivos `.cs` (sin migraciones): **16.567 líneas**. De ellas, 9.223 son código, **5.013 comentarios** y 2.331 líneas en blanco.
- 268 métodos. **20 pasan de 40 líneas y 7 pasan de 60** (medido con script, sin contar comentarios).
- 20 puertos en `Application/Abstractions`. 259 métodos de prueba. Puerta de cobertura: 80 % global y 100 % en las clases críticas.
- Revisé los archivos más grandes, los manejadores, los controladores, los puertos, el registro de dependencias, el middleware, los servicios en segundo plano y los adaptadores (PostgreSQL, Blob, SMTP).
- **No compilé ni ejecuté las pruebas en esta revisión.** La última corrida que hiciste fue la de la Fase 7: 298 pruebas en verde.

---

## 3. SOLID, principio por principio

### S — Responsabilidad única 🟢

**A favor:**

- Cada caso de uso tiene su manejador: `LoginCommandHandler`, `RefreshCommandHandler`, `MediaStreamHandler`, `IngestCatalogCommandHandler`, etc.
- Los controladores solo traducen HTTP ⇄ comando/resultado. Ninguno importa `BridgeService.Infrastructure`.
- La validación de la ingesta (`CatalogBatchValidator`) está separada de la aplicación del lote (`CatalogWriter`) y de la resolución de URIs (`StorageUriResolver`).

**Puntos a vigilar:**

| Clase | Síntoma | Lectura |
|---|---|---|
| `UserAdminHandler` | 8 dependencias, 5 órdenes (331 líneas) | Decisión documentada en la clase: las 5 órdenes comparten comprobación y cierre. Es aceptable hoy. Si crece (reinvitar, cambiar rol), conviene partirla en `UserLifecycleHandler` (aprobar/suspender/baja) y `UserProfileHandler` (alta/edición). |
| `AuthController` | 7 dependencias: 5 manejadores + firmador + reloj | Además de delegar, arma y borra dos cookies (`refresh_token`, `pv_media`). Sacar eso a un `AuthCookieWriter` lo dejaría como controlador puro. Prioridad baja. |

### O — Abierto/cerrado 🟢

- Los fallos de negocio son enums (`UserAdminFailure`, `RefreshFailure`…) que cada controlador traduce con un `switch` exhaustivo que termina en `_ => throw`. Un fallo nuevo obliga a tocar el `switch`, pero el compilador y ese `throw` hacen que no pase desapercibido. Es la forma correcta en C#.
- **Punto cerrado a propósito:** `MediaStreamHandler.StreamAsync` solo transmite `azure-blob`. Los medios `http` y `file`, que la ingesta acepta (`StorageProviders`), responden `404`. Está bien mientras nadie necesite servirlos. Si un día hay que hacerlo, se resuelve con una estrategia por proveedor (ver 5.2).

### L — Sustitución de Liskov 🟢

Solo hay herencia de framework (`AuthenticationHandler`, `BackgroundService`, `DbContext`, `AuthorizationHandler`). No hay implementaciones que lancen `NotImplementedException` o `NotSupportedException`. Los puertos tienen una sola implementación cada uno, con contratos documentados. No encontré nada que objetar.

### I — Segregación de interfaces 🟡

**Bien resuelto:**

- La mayoría de los puertos tienen entre 1 y 4 miembros.
- Hay divisiones muy bien hechas: `INotificationOutboxWriter` / `INotificationOutboxReader` / `IEmailSender`, `IAuditLogReader` / `IApiRequestLogWriter` y `ICatalogReader` / `ICatalogWriter`.

**A mejorar:**

| Puerto | Miembros | Problema |
|---|---|---|
| `IGroupAdminRepository` | 16 | Mezcla consultas para pantallas (`ListAsync`, `ListMembersAsync`) con comprobaciones y escritura. `AdminGroupsController` lo recibe como `lectura` y solo usa la parte de lectura, pero ve las 16. |
| `IUserAdminRepository` | 16 | El mismo caso: lo usan `AdminUsersController` (lectura) y `UserAdminHandler` (escritura). |
| `ISessionRepository` | 8 | Aceptable: todo es del agregado sesión. |

**Recomendación:** dividir cada uno de los dos primeros en `…Reader` (listados y detalle para los controladores) y `…Store` (comprobaciones y escritura para el manejador), igual que ya se hizo con auditoría. El costo es bajo y conviene hacerlo la próxima vez que se toquen esos archivos.

### D — Inversión de dependencias 🟢 (lo más fuerte del proyecto)

- Application define los puertos, Infrastructure los implementa y Api compone. `DependencyRuleTests` falla el build si Application depende de Infrastructure o de Api.
- Los puertos no exponen tipos de SDK (EST-BS-02): `IMediaStorageProvider` devuelve `MediaOpenResult`, no `BlobDownloadInfo`.
- El tiempo está inyectado (`IClock`). La única lectura de `DateTimeOffset.UtcNow` está en `SystemClock`.
- Los manejadores se registran como clases concretas (`AddScoped<LoginCommandHandler>()`). **Es correcto:** son la política de alto nivel, y ponerles interfaces solo para inyectarlos en los controladores sería ceremonia sin beneficio.

---

## 4. Código limpio

### 4.1 Lo que está muy bien

- **El build aplica el estándar:** `TreatWarningsAsErrors`, `AnalysisMode All`, `EnforceCodeStyleInBuild` y reglas de nombres en `.editorconfig` con severidad `error`.
- **El flujo de negocio no usa excepciones.** Los resultados son tipados (`UserAdminResult`, `MediaStreamOutcome`, `RefreshOutcome`) y las excepciones quedan para lo excepcional. Solo hay 8 `catch (Exception)`, cada uno justificado con `SuppressMessage`, y ninguno se traga el error en silencio.
- **Métodos con guardas:** `RefreshCommandHandler.HandleAsync` mide 74 líneas, pero se lee de arriba abajo como una lista de casos de salida.
- **Logging estructurado** con `[LoggerMessage]` y `EventId`. Hay `CancellationToken` en toda la cadena. No hay `TODO`, `FIXME` ni `HACK`.
- **Seguridad desde el código:** errores genéricos fuera de Development (SEC-BS-06), SQL interpolado parametrizado (SEC-BS-03) y ningún payload con secretos persistido después de enviarse.

### 4.2 Desvíos

| # | Hallazgo | Evidencia | Qué hacer |
|---|---|---|---|
| C-1 | **EST-BS-19 («el código en inglés») no se cumple en lo privado.** La API pública está en inglés; los métodos privados, las variables locales y los parámetros de los constructores primarios están en español. | ~58 métodos privados (`ValidarProducto`, `Conectar`, `RangoPedido`, `Fallo`…), locales como `reloj`, `ajustes`, `sesion`, y la clase anidada `Contexto`. | **Enmendar la regla** en vez de renombrar: «API pública (tipos, miembros públicos, contratos, tablas) en inglés; lo privado puede ir en español». Renombrar cientos de identificadores es mucho movimiento sin beneficio. Lo que importa es que la regla escrita coincida con la práctica. |
| C-2 | **EST-BS-20 («un archivo, un tipo público») no se cumple en 50 de 141 archivos.** | `Entities/Enums.cs` (14 tipos), `IIngestBatchRepository.cs` (12), `CatalogModel.cs` (10), `Entities/Identity.cs` (9)… | Casi todos son **paquetes cohesivos**: un puerto con sus DTO, o un `*Model.cs` con los records de un área. Mi recomendación es **enmendar la regla** para permitir «puerto + sus records» y `*Model.cs`, y partir solo los casos que no son cohesivos: `Entities/Enums.cs` (un enum por archivo) y `Entities/Identity.cs`, `IngestAndAudit.cs` (una entidad por archivo). |
| C-3 | **Métodos largos puntuales.** 7 pasan de 60 líneas. | `MediaStreamHandler.StreamAsync` 80, `RefreshCommandHandler.HandleAsync` 74, `CatalogBatchValidator.ValidarRecurso` 68, `IngestCatalogCommandHandler.HandleAsync` 65, `MediaController.StreamAsync` 65, `AzureBlobStorageProvider.OpenReadAsync` 61, `LoginCommandHandler.HandleAsync` 61. | No es urgente: son secuencias lineales de guardas. El que más gana es `MediaStreamHandler.StreamAsync`: separar «reservar plaza», «abrir blob» y «registrar reproducción» en tres métodos privados lo dejaría en unas 30 líneas. |
| C-4 | **Volumen de comentarios: 0,54 líneas de comentario por línea de código.** | 5.013 de 16.567 líneas. Muchos explican el *porqué*, y eso es valioso. Otros cuentan *historia*: «antes 400», «desde la Fase 1», «V3-20», «api_admin.yaml 1.1.0; 400 hasta la 1.0.0». | Mantener los comentarios del porqué y mover la historia a las ADR y a las verificaciones de fase. Un comentario histórico se desactualiza sin que el compilador avise (ver C-6). |
| C-5 | **Duplicación menor en controladores.** | `Error(codigo, mensaje)` está definido en 5 controladores. `NoEncontrado` e `Invalido` se repiten con variantes. | Una extensión `ControllerBase.ApiError(...)` o una pequeña fábrica `ErrorResults`. Es barato. |
| C-6 | **Un comentario de `UserAdminHandler` contradice al código.** | La cabecera dice «cada orden es un solo `SaveChanges`». Pero suspender y dar de baja llaman antes a `RevokeActiveForUserAsync`, que es un `ExecuteUpdate` inmediato (líneas 221 y 259). Lo mismo pasa en `LoginCommandHandler` (línea 106). | El orden elegido es **seguro**: primero se revocan las sesiones y, si luego falla el `SaveChanges`, el usuario solo tiene que volver a entrar. Basta corregir el comentario para que diga eso. |
| C-7 | **Dos estilos de constructor.** | `Login`, `Logout`, `Refresh` y `Register` usan constructor explícito con campos `_x`. El resto usa constructores primarios. | Cosmético. Unificar cuando se toquen esos archivos. |
| C-8 | **Configuración leída a mano** (`EnteroOpcional`, `Vacio`) en `InfrastructureServiceCollectionExtensions`. | 263 líneas de lectura y valores por omisión. | Opcional: el patrón *Options* (`services.AddOptions<T>().Bind(...).ValidateOnStart()`) valida al arrancar y quita código. Encaja con la Fase 8, cuando llegue la configuración por entorno. |

---

## 5. Patrones de diseño: qué hay y qué conviene agregar

### 5.1 Ya presentes (y bien usados)

| Patrón | Dónde |
|---|---|
| Puertos y adaptadores (hexagonal) | `Application/Abstractions` ↔ `Infrastructure` |
| Repository + Unit of Work | Repositorios por agregado + `IUnitOfWork` con un `SaveChanges` como unidad atómica |
| Command Handler / CQRS liviano | Las escrituras pasan por manejadores; las lecturas van por *readers* directos (`ICatalogReader`, `ISyncReader`) |
| Result / Notification | Resultados tipados en lugar de excepciones; `CatalogBatchValidator.Contexto` junta **todos** los errores por campo |
| Strategy (con una implementación) | `IMediaStorageProvider`, `IEmailSender`, `IPasswordHasher` |
| Chain of Responsibility | Middleware: correlación → excepciones → rate limit → autenticación → registro |
| Transactional Outbox | `notification_log` + `NotificationDrainService` |
| Productor/consumidor acotado | `RequestLogQueue` (canal con capacidad fija y `DropOldest`) |
| Query Object | `MediaAccessQueries.EffectiveExceptions / ActiveGroupIds` |

### 5.2 ¿Conviene aplicar más ahora?

**Poco y puntual.** El sistema tiene 11 manejadores y un dominio casi CRUD más una ingesta. Agregar patrones "por las dudas" le sumaría indirección sin beneficio.

| Patrón | ¿Aplicarlo? | Motivo |
|---|---|---|
| Dividir puertos lector/escritor (ISP) en grupos y usuarios | ✅ **Sí**, la próxima vez que se toquen | Bajo costo; ya existe el precedente de auditoría. |
| Fábrica común de respuestas de error (C-5) | ✅ **Sí** | Quita duplicación; es muy barato. |
| Options pattern con `ValidateOnStart` (C-8) | ✅ **Sí, en la Fase 8** | La configuración por entorno lo hace valer. |
| Strategy por proveedor con *keyed services* (`AddKeyedSingleton<IMediaStorageProvider>("http", …)`) | ⏸ **Solo si se necesita** servir `http` o `file` | Hoy hay un proveedor. Crear la estrategia antes de tener el segundo es diseño especulativo. |
| Decorator de caché sobre `IMediaAccessReader` | ⏸ **Solo con métricas** | Cada petición de rango hace 3 consultas (sesión, usuario, decisión). Si la base sufre, un caché de 30–60 s por usuario y medio resuelve sin tocar el manejador. |
| Mediator (MediatR) + *pipeline behaviors* | ❌ **No** | Con 11 manejadores, la inyección directa es más clara y navegable. Además, MediatR pasó a licencia comercial en 2025. |
| Modelo de dominio rico / agregados DDD | ❌ **No** | Las reglas son pocas y ya están probadas en los manejadores. El *transaction script* es la elección correcta para este tamaño. |
| Specification para la validación | ❌ **No** | `CatalogBatchValidator` ya está estructurado por niveles (lote → producto → versión → recurso). |
| Repositorio genérico | ❌ **No** | Los repositorios específicos expresan mejor las consultas y los índices. |

---

## 6. Patrones de resiliencia

### 6.1 Ya presentes

| Patrón | Dónde |
|---|---|
| Reintento en la base | `EnableRetryOnFailure(maxRetryCount: 3)`, con el diseño adaptado: un `SaveChanges` por unidad, sin transacciones explícitas |
| Idempotencia | Ingesta por `batchId` (índice único); logout y suspensión idempotentes |
| Outbox (desacople del SMTP) | Un correo caído no tumba la petición que lo generó |
| Timeout + barrido | `IngestSweepService` libera lotes colgados en `running` según `HeartbeatTimeout` |
| Bulkhead | `TransferLimiter`: 3 transferencias de video por usuario |
| Rate limiting | Ingesta: `/v1/auth/token` y lotes |
| Cola acotada con descarte | `RequestLogQueue` no crece sin límite |
| Health checks live/ready | `/health/live`, `/health/ready` (PostgreSQL) |
| Cancelación ordenada | Corte del cliente en el streaming tratado como normal; *background services* que respetan `stoppingToken` |
| Reintentos del SDK | El SDK de Azure Blob reintenta por omisión |

### 6.2 Huecos, por prioridad

| # | Prioridad | Hallazgo | Recomendación |
|---|---|---|---|
| R-1 | 🔴 **Alta, antes de producción** | **El outbox no reintenta.** Si el SMTP falla (un corte de red, un 4xx temporal), `MarkFailedAsync` deja la fila en `failed` para siempre y borra el payload. **La invitación se pierde** y no existe «reenviar invitación». | Agregar `attempt_count` y `next_attempt_at`, reintentar con *backoff* exponencial (1, 5, 30 min, máximo unos 5 intentos) y marcar `failed` solo al agotarlos. Aparte, un endpoint de administración para reenviar la invitación. |
| R-2 | 🔴 **Alta si hay más de 1 réplica** | **Hay estado en memoria y consumidores que compiten.** `TransferLimiter` y el rate limiter cuentan por instancia. `FetchPendingAsync` toma pendientes sin bloqueo: con 2 réplicas, **el mismo correo sale dos veces**. El plan de la Fase 8 ya limita el backend a 1 réplica y menciona DT-BS-08. | Mantener 1 réplica como decisión explícita (D8). Si se escala: `FOR UPDATE SKIP LOCKED` (o un *lease*) en el outbox y en el barrido, y contadores compartidos (Redis) para el limitador. |
| R-3 | 🟠 Media | **La auditoría está en el camino crítico del streaming.** `MediaStreamHandler` escribe `video_access_log` antes de entregar los bytes. Si esa escritura falla, **el video no se reproduce**. Además, cada petición de rango hace 3 consultas. | Es una decisión de requisito: ¿la auditoría es obligatoria (*fail-closed*, como ahora) o se admite *fail-open* (reproducir y registrar en diferido, por ejemplo por el canal de `RequestLogQueue`)? Conviene dejarla escrita como DEC. |
| R-4 | 🟠 Media | **Login del portal sin rate limit ni bloqueo.** Solo la ingesta tiene límites. `/auth/login` y `/auth/refresh` no tienen ninguno. | Ventana fija por IP y por email en `/auth/login` (por ejemplo 10/min por email, 50/min por IP), igual que en la ingesta. Antes, conviene confirmar qué dice el requisito del portal. |
| R-5 | 🟡 Media-baja | **`/health/ready` solo mira PostgreSQL.** | Agregar Blob (una sonda liviana) como `ready` y el SMTP como `degraded` (sin él el portal funciona; la invitación espera en el outbox). |
| R-6 | 🟡 Media-baja | **Los timeouts son los que vienen por omisión.** MailKit espera 2 min por operación, el SDK de Blob 100 s por lectura y los comandos de Npgsql 30 s. | Fijarlos en configuración. Agregar `AddRequestTimeouts` (.NET 8+) en los endpoints de API, **excluyendo** `/media/{id}/stream`. |
| R-7 | 🟡 Baja | **Reintentar `/auth/refresh` es peligroso.** Si el cliente reintenta un refresh que el servidor ya procesó (por ejemplo, tras un timeout de red), la detección de reutilización revoca toda la cadena y **el usuario queda deslogueado**. | No agregar reintentos automáticos a `/auth/refresh` en el frontend. Si molesta, una ventana de gracia de unos segundos para el token recién rotado. |
| R-8 | 🟡 Baja | **Cancelaciones registradas como error.** El middleware registra como `Error`/500 cualquier excepción, incluida `OperationCanceledException` cuando el cliente se va fuera de la copia del stream (por ejemplo, durante las consultas previas). Es ruido para las alertas. | Tratar `OperationCanceledException` con `RequestAborted` cancelado como `Information`, sin responder 500. |
| R-9 | 🟢 Baja | **Carrera en logins simultáneos.** El índice `ix_sessions_user` (filtrado `NOT revoked`) no es único: dos logins simultáneos pueden dejar dos sesiones activas, contra lo que pide RF-02. | Índice único parcial y tratar la violación como reintento del login. |
| R-10 | 🟢 Baja (Fase 8) | **`DefaultAzureCredential` en producción** recorre una cadena de credenciales: más latencia al arrancar y más modos de fallo. | `ManagedIdentityCredential` en Azure y `DefaultAzureCredential` solo en local. |

### 6.3 Lo que **no** conviene agregar ahora

- **Circuit breaker / Polly en general: no.** Las dependencias externas son PostgreSQL, Blob y SMTP.
  - PostgreSQL es crítica y no tiene alternativa: cortar el circuito no aporta nada, porque sin base no hay servicio. El reintento ya está.
  - Blob ya reintenta dentro del SDK.
  - El SMTP ya está aislado por el outbox.
  - **Se vuelve relevante** si el Bridge empieza a *llamar* por HTTP a SinsaTools u otro servicio. En ese caso, `AddStandardResilienceHandler()` (Microsoft.Extensions.Http.Resilience) da reintento, timeout y circuit breaker en una línea.
- **Colas externas (Service Bus) para la ingesta: no.** El diseño síncrono + idempotente + barrido cubre la carga esperada (200 productos por lote).
- **Cachés distribuidas: no**, salvo que las métricas lo pidan (ver 5.2).

---

## 7. Plan sugerido

1. **Antes de producción:** R-1 (reintentos del outbox + reenviar invitación), R-2 (dejar escrito «1 réplica» en D8), R-4 (rate limit del login), R-5 (health de Blob).
2. **Ajuste del estándar (media hora):** enmendar EST-BS-19 y EST-BS-20 según C-1 y C-2, y corregir el comentario de C-6.
3. **Cuando se toquen esos archivos:** dividir los puertos de grupos y usuarios, crear la fábrica de errores de los controladores, partir `MediaStreamHandler.StreamAsync` y unificar los constructores.
4. **Fase 8:** patrón Options, timeouts explícitos, `ManagedIdentityCredential` y decidir R-3 (auditoría *fail-closed* o *fail-open*).
5. **No hacer:** MediatR, DDD rico, repositorio genérico ni Polly general.
