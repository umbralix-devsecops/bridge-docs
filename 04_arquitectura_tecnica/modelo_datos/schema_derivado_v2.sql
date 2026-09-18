-- ═══════════════════════════════════════════════════════════════════════════
--  Bridge Service — esquema PostgreSQL 16
--  Versión 2.0 · 2026-09-16 · Confidencial — Solo uso interno
-- ═══════════════════════════════════════════════════════════════════════════
--
--  ARTEFACTO DERIVADO. No es la fuente de verdad.
--
--  La fuente de verdad son las migraciones de EF Core sobre `AppDbContext`
--  (ADR-BS-004, DOM-BS-04). Este archivo se regenera a partir de ellas y sirve
--  para dos cosas: revisar el diseño de un vistazo, y levantar un entorno de
--  pruebas desechable. NUNCA se ejecuta a mano contra desarrollo, staging ni
--  producción: eso lo hace `dotnet ef database update`.
--
--  El modelo comentado está en `modelo_datos_bridge_v2.mermaid`, con las once
--  reglas que lo gobiernan. El porqué de cada cambio, en
--  `changelog_modelo_datos.adoc`.
--
--  Verificado contra PostgreSQL 16.13: 17 tablas, 14 enums, 40 índices,
--  0 errores. Invariantes probados: colisión de identificadores entre Images y
--  Entity_Files admitida, duplicado de clave natural rechazado, un solo lote en
--  ejecución, una foto no se cierra dos veces, rol inexistente rechazado, y los
--  permisos sobreviven al UPDATE de la ingesta.
--
--  Requisitos previos:
--      CREATE EXTENSION IF NOT EXISTS citext;    -- users.email sin distinción
--      CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid() en PG < 13
--
--  Nota sobre las tablas particionadas: `video_access_log` y `api_request_log`
--  necesitan al menos una partición creada antes del primer INSERT. Ejemplo:
--      CREATE TABLE video_access_log_2026 PARTITION OF video_access_log
--          FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Tipos ─────────────────────────────────────────────────────────────
CREATE TYPE industry AS ENUM
    ('automotive','agricultural','marine','forklift','crane',
     'heavy_equipment','generator','controller','other');
CREATE TYPE media_origin  AS ENUM ('Images','EntityFiles');
CREATE TYPE media_kind    AS ENUM ('video','image','document');
CREATE TYPE media_group   AS ENUM ('cover','manual','video_demo','other');
CREATE TYPE media_visibility AS ENUM ('public','private');
CREATE TYPE user_status   AS ENUM ('pending','active','suspended');
CREATE TYPE reg_type      AS ENUM ('self','admin_created');
CREATE TYPE access_type   AS ENUM ('grant','revoke');
CREATE TYPE revoke_reason AS ENUM ('logout','rotated','superseded','reuse_detected','expired','forced');
CREATE TYPE ingest_mode   AS ENUM ('upsert','snapshot');
CREATE TYPE ingest_status AS ENUM ('queued','running','completed','partial','failed');
CREATE TYPE access_result AS ENUM ('granted','denied');
CREATE TYPE access_source AS ENUM ('group','individual_exception','denied_revoke','denied_none');
CREATE TYPE notification_status AS ENUM ('queued','sent','failed');

-- ── 1. Catálogo ───────────────────────────────────────────────────────
CREATE TABLE catalog_products (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    ext_product_id    varchar(64)  NOT NULL UNIQUE,
    internal_id       varchar(64),
    name              varchar(255) NOT NULL,
    trade_name        varchar(255),
    description       text,
    brand_source_id   integer,
    brand_name        varchar(255),
    industry          industry     NOT NULL,
    metatags          jsonb,
    active            boolean      NOT NULL DEFAULT true,
    created_at_source timestamptz,
    updated_at_source timestamptz,
    synced_at         timestamptz  NOT NULL DEFAULT now(),
    last_seen_at      timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT ck_products_metatags CHECK (jsonb_typeof(metatags) = 'object')
);
CREATE INDEX ix_products_industry ON catalog_products (industry) WHERE active;
CREATE INDEX ix_products_search   ON catalog_products
    USING gin (to_tsvector('spanish', name || ' ' || coalesce(trade_name,'')));

CREATE TABLE catalog_versions (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    ext_version_id    varchar(64) NOT NULL UNIQUE,
    product_id        uuid NOT NULL REFERENCES catalog_products ON DELETE CASCADE,
    internal_id       varchar(64),
    name              varchar(255) NOT NULL,
    trade_name        varchar(255),
    description       text,
    active            boolean NOT NULL DEFAULT true,
    created_at_source timestamptz,
    updated_at_source timestamptz,
    synced_at         timestamptz NOT NULL DEFAULT now(),
    last_seen_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_versions_product ON catalog_versions (product_id) WHERE active;

CREATE TABLE catalog_media (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    origin            media_origin NOT NULL,
    ext_media_id      integer      NOT NULL,
    version_id        uuid NOT NULL REFERENCES catalog_versions ON DELETE CASCADE,
    name              varchar(512) NOT NULL,
    media_type        media_kind   NOT NULL,
    file_group        media_group,
    extension         varchar(16)  NOT NULL,
    mime_type         varchar(128),
    size_bytes        bigint,
    device_type       varchar(32),
    web_platform_id   integer,
    position          integer NOT NULL DEFAULT 0,
    active            boolean NOT NULL DEFAULT true,
    visibility        media_visibility NOT NULL,
    storage_uri       text        NOT NULL,
    storage_provider  varchar(32) NOT NULL,
    storage_container varchar(255),
    storage_path      text        NOT NULL,
    storage_token     text,
    created_at_source timestamptz,
    updated_at_source timestamptz,
    synced_at         timestamptz NOT NULL DEFAULT now(),
    last_seen_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (origin, ext_media_id)
);
CREATE INDEX ix_media_version ON catalog_media (version_id, position) WHERE active;

-- ── 2. Identidad y permisos ───────────────────────────────────────────
CREATE TABLE roles (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        varchar(32) NOT NULL UNIQUE,
    description varchar(255)
);

CREATE TABLE role_permissions (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id    uuid NOT NULL REFERENCES roles ON DELETE CASCADE,
    resource   varchar(32) NOT NULL,
    can_read   boolean NOT NULL DEFAULT false,
    can_write  boolean NOT NULL DEFAULT false,
    can_delete boolean NOT NULL DEFAULT false,
    UNIQUE (role_id, resource)
);
CREATE INDEX ix_role_permissions_role ON role_permissions (role_id);

CREATE TABLE users (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email             citext       NOT NULL UNIQUE,
    password_hash     text         NOT NULL,
    full_name         varchar(120) NOT NULL,
    role_id           uuid         NOT NULL REFERENCES roles,
    status            user_status  NOT NULL DEFAULT 'pending',
    registration_type reg_type     NOT NULL,
    approved_by       uuid REFERENCES users,
    approved_at       timestamptz,
    suspended_at      timestamptz,
    last_login_at     timestamptz,
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_users_approved CHECK ((approved_by IS NULL) = (approved_at IS NULL))
);

CREATE TABLE sessions (
    id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                uuid NOT NULL REFERENCES users ON DELETE CASCADE,
    token_hash             text NOT NULL UNIQUE,
    ip_address             inet,
    user_agent             text,
    revoked                boolean NOT NULL DEFAULT false,
    revoked_reason         revoke_reason,
    replaced_by_session_id uuid REFERENCES sessions,
    expires_at             timestamptz NOT NULL,
    created_at             timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_sessions_revoked CHECK (revoked = (revoked_reason IS NOT NULL))
);
CREATE INDEX ix_sessions_user ON sessions (user_id) WHERE NOT revoked;

CREATE TABLE groups (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        varchar(120) NOT NULL UNIQUE,
    description varchar(500),
    active      boolean NOT NULL DEFAULT true,
    created_by  uuid REFERENCES users,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE user_groups (
    user_id     uuid NOT NULL REFERENCES users  ON DELETE CASCADE,
    group_id    uuid NOT NULL REFERENCES groups ON DELETE CASCADE,
    assigned_by uuid REFERENCES users,
    assigned_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, group_id)
);

CREATE TABLE group_version_access (
    group_id   uuid NOT NULL REFERENCES groups ON DELETE CASCADE,
    version_id uuid NOT NULL REFERENCES catalog_versions ON DELETE CASCADE,
    granted_by uuid REFERENCES users,
    granted_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (group_id, version_id)
);
CREATE INDEX ix_gva_version ON group_version_access (version_id);

CREATE TABLE user_media_exceptions (
    user_id     uuid NOT NULL REFERENCES users ON DELETE CASCADE,
    media_id    uuid NOT NULL REFERENCES catalog_media ON DELETE CASCADE,
    access_type access_type NOT NULL,
    reason      varchar(500),
    expires_at  timestamptz,
    granted_by  uuid REFERENCES users,
    granted_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, media_id)
);

-- ── 3. Ingesta y auditoría ────────────────────────────────────────────
CREATE TABLE ingest_batches (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id           uuid NOT NULL UNIQUE,
    mode               ingest_mode   NOT NULL,
    snapshot_id        uuid,
    sequence           integer,
    is_last            boolean,
    status             ingest_status NOT NULL DEFAULT 'queued',
    generated_at       timestamptz NOT NULL,
    received_at        timestamptz NOT NULL DEFAULT now(),
    finished_at        timestamptz,
    heartbeat_at       timestamptz,
    products_new       integer NOT NULL DEFAULT 0,
    products_updated   integer NOT NULL DEFAULT 0,
    versions_new       integer NOT NULL DEFAULT 0,
    versions_updated   integer NOT NULL DEFAULT 0,
    media_new          integer NOT NULL DEFAULT 0,
    media_updated      integer NOT NULL DEFAULT 0,
    media_deactivated  integer NOT NULL DEFAULT 0,
    records_unchanged  integer NOT NULL DEFAULT 0,
    records_error      integer NOT NULL DEFAULT 0,
    error_detail       text,
    correlation_id     uuid,
    client_id          varchar(64),
    payload_bytes      integer,
    duration_ms        integer GENERATED ALWAYS AS
        ((EXTRACT(epoch FROM (finished_at - received_at)) * 1000)::integer) STORED
);
CREATE INDEX ix_ingest_recent ON ingest_batches (received_at DESC);
CREATE INDEX ix_ingest_fresh  ON ingest_batches (generated_at DESC)
    WHERE status IN ('completed','partial');
CREATE UNIQUE INDEX ux_ingest_running ON ingest_batches ((true)) WHERE status = 'running';
CREATE UNIQUE INDEX ux_snapshot_close ON ingest_batches (snapshot_id)
    WHERE mode = 'snapshot' AND is_last;
CREATE UNIQUE INDEX ux_snapshot_sequence ON ingest_batches (snapshot_id, sequence)
    WHERE mode = 'snapshot';

CREATE TABLE ingest_items (
    id            bigserial PRIMARY KEY,
    batch_id      uuid NOT NULL REFERENCES ingest_batches ON DELETE CASCADE,
    entity_type   varchar(16) NOT NULL,
    entity_origin media_origin,
    entity_ext_id varchar(64) NOT NULL,
    operation     varchar(16) NOT NULL,
    error_detail  text
);
CREATE INDEX ix_ingest_items_batch ON ingest_items (batch_id) WHERE operation = 'error';

CREATE TABLE ext_api_request_log (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id       uuid REFERENCES ingest_batches ON DELETE SET NULL,
    endpoint       varchar(512) NOT NULL,
    http_method    varchar(8)   NOT NULL,
    status_code    smallint,
    latency_ms     integer,
    payload_bytes  integer,
    client_id      varchar(64),
    error_detail   text,
    correlation_id uuid NOT NULL,
    ip_address     inet,
    created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_ext_log_recent ON ext_api_request_log (created_at DESC);

CREATE TABLE video_access_log (
    id             uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id        uuid REFERENCES users ON DELETE SET NULL,
    media_id       uuid REFERENCES catalog_media ON DELETE SET NULL,
    access_result  access_result NOT NULL,
    access_source  access_source NOT NULL,
    range_request  boolean NOT NULL DEFAULT false,
    bytes_served   bigint,
    correlation_id uuid NOT NULL,
    ip_address     inet,
    created_at     timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (id, created_at),
    CONSTRAINT ck_access CHECK (
        (access_result = 'denied') = (access_source IN ('denied_revoke','denied_none'))
    )
) PARTITION BY RANGE (created_at);

CREATE TABLE api_request_log (
    id             uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id        uuid REFERENCES users ON DELETE SET NULL,
    endpoint       varchar(512) NOT NULL,
    http_method    varchar(8)   NOT NULL,
    status_code    smallint     NOT NULL,
    latency_ms     integer      NOT NULL,
    correlation_id uuid         NOT NULL,
    ip_address     inet,
    created_at     timestamptz  NOT NULL DEFAULT now(),
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE notification_log (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           uuid REFERENCES users ON DELETE SET NULL,
    notification_type varchar(48) NOT NULL,
    email_to          citext      NOT NULL,
    status            notification_status NOT NULL DEFAULT 'queued',
    error_detail      text,
    created_at        timestamptz NOT NULL DEFAULT now(),
    sent_at           timestamptz
);
