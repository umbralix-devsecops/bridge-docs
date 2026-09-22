-- ═══════════════════════════════════════════════════════════════════════════════════════
--  ARCHIVO GENERADO. NO SE EDITA A MANO.
--
--  Lo produce  Sin-PortalBridge/tools/regenerar_ddl_derivado.sh  volcando la base que deja
--  la migración de EF Core. ADR-BS-004: el modelo es la fuente del esquema y esto es su
--  derivado, para revisar el diseño y para que SchemaParityTests tenga contra qué comparar.
--
--  Si algo de aquí no te gusta, se cambia en las entidades y en las IEntityTypeConfiguration
--  de BridgeService.Infrastructure, se emite una migración y se vuelve a generar esto.
--  Editarlo a mano solo consigue que la prueba de paridad falle en el commit siguiente.
--
--  Se excluye __EFMigrationsHistory: es contabilidad de EF Core, no parte del modelo.
-- ═══════════════════════════════════════════════════════════════════════════════════════

--
-- PostgreSQL database dump
--


-- Dumped from database version 16.15
-- Dumped by pg_dump version 16.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: access_result; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.access_result AS ENUM (
    'granted',
    'denied'
);


--
-- Name: access_source; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.access_source AS ENUM (
    'group',
    'individual_exception',
    'denied_revoke',
    'denied_none'
);


--
-- Name: access_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.access_type AS ENUM (
    'grant',
    'revoke'
);


--
-- Name: industry; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.industry AS ENUM (
    'automotive',
    'agricultural',
    'marine',
    'forklift',
    'crane',
    'heavy_equipment',
    'generator',
    'controller',
    'other'
);


--
-- Name: ingest_mode; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ingest_mode AS ENUM (
    'upsert',
    'snapshot'
);


--
-- Name: ingest_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ingest_status AS ENUM (
    'queued',
    'running',
    'completed',
    'partial',
    'failed'
);


--
-- Name: media_group; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.media_group AS ENUM (
    'cover',
    'manual',
    'video_demo',
    'other'
);


--
-- Name: media_kind; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.media_kind AS ENUM (
    'video',
    'image',
    'document'
);


--
-- Name: media_origin; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.media_origin AS ENUM (
    'Images',
    'EntityFiles'
);


--
-- Name: media_visibility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.media_visibility AS ENUM (
    'public',
    'private'
);


--
-- Name: notification_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.notification_status AS ENUM (
    'queued',
    'sent',
    'failed'
);


--
-- Name: reg_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.reg_type AS ENUM (
    'self',
    'admin_created'
);


--
-- Name: revoke_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.revoke_reason AS ENUM (
    'logout',
    'rotated',
    'superseded',
    'reuse_detected',
    'expired',
    'forced'
);


--
-- Name: user_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_status AS ENUM (
    'pending',
    'active',
    'suspended'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_setup_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_setup_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(64) NOT NULL,
    purpose character varying(16) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: api_request_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_request_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    endpoint character varying(512) NOT NULL,
    http_method character varying(8) NOT NULL,
    status_code smallint NOT NULL,
    latency_ms integer NOT NULL,
    correlation_id uuid NOT NULL,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now() NOT NULL
)
PARTITION BY RANGE (created_at);


--
-- Name: api_request_log_2026; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_request_log_2026 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    endpoint character varying(512) NOT NULL,
    http_method character varying(8) NOT NULL,
    status_code smallint NOT NULL,
    latency_ms integer NOT NULL,
    correlation_id uuid NOT NULL,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: api_request_log_2027; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_request_log_2027 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    endpoint character varying(512) NOT NULL,
    http_method character varying(8) NOT NULL,
    status_code smallint NOT NULL,
    latency_ms integer NOT NULL,
    correlation_id uuid NOT NULL,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: catalog_media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_media (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    origin public.media_origin NOT NULL,
    ext_media_id integer NOT NULL,
    version_id uuid NOT NULL,
    name character varying(512) NOT NULL,
    media_type public.media_kind NOT NULL,
    file_group public.media_group,
    extension character varying(16) NOT NULL,
    mime_type character varying(128),
    size_bytes bigint,
    device_type character varying(32),
    web_platform_id integer,
    "position" integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    storage_uri text NOT NULL,
    visibility public.media_visibility NOT NULL,
    storage_provider character varying(32) NOT NULL,
    storage_container character varying(255),
    storage_path text NOT NULL,
    storage_token text,
    created_at_source timestamp with time zone,
    updated_at_source timestamp with time zone,
    synced_at timestamp with time zone DEFAULT now() NOT NULL,
    last_seen_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: catalog_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ext_product_id character varying(64) NOT NULL,
    internal_id character varying(64),
    name character varying(255) NOT NULL,
    trade_name character varying(255),
    description text,
    brand_source_id integer,
    brand_name character varying(255),
    industry public.industry NOT NULL,
    metatags jsonb,
    active boolean DEFAULT true NOT NULL,
    created_at_source timestamp with time zone,
    updated_at_source timestamp with time zone,
    synced_at timestamp with time zone DEFAULT now() NOT NULL,
    last_seen_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_products_metatags CHECK ((jsonb_typeof(metatags) = 'object'::text))
);


--
-- Name: catalog_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ext_version_id character varying(64) NOT NULL,
    product_id uuid NOT NULL,
    internal_id character varying(64),
    name character varying(255) NOT NULL,
    trade_name character varying(255),
    description text,
    active boolean DEFAULT true NOT NULL,
    created_at_source timestamp with time zone,
    updated_at_source timestamp with time zone,
    synced_at timestamp with time zone DEFAULT now() NOT NULL,
    last_seen_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: ext_api_request_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ext_api_request_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid,
    endpoint character varying(512) NOT NULL,
    http_method character varying(8) NOT NULL,
    status_code smallint,
    latency_ms integer,
    payload_bytes integer,
    client_id character varying(64),
    error_detail text,
    correlation_id uuid NOT NULL,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: group_version_access; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_version_access (
    group_id uuid NOT NULL,
    version_id uuid NOT NULL,
    granted_by uuid,
    granted_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(120) NOT NULL,
    description character varying(500),
    active boolean DEFAULT true NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: ingest_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingest_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid NOT NULL,
    mode public.ingest_mode NOT NULL,
    snapshot_id uuid,
    sequence integer,
    is_last boolean,
    status public.ingest_status DEFAULT 'queued'::public.ingest_status NOT NULL,
    generated_at timestamp with time zone NOT NULL,
    received_at timestamp with time zone DEFAULT now() NOT NULL,
    finished_at timestamp with time zone,
    heartbeat_at timestamp with time zone,
    products_new integer DEFAULT 0 NOT NULL,
    products_updated integer DEFAULT 0 NOT NULL,
    versions_new integer DEFAULT 0 NOT NULL,
    versions_updated integer DEFAULT 0 NOT NULL,
    media_new integer DEFAULT 0 NOT NULL,
    media_updated integer DEFAULT 0 NOT NULL,
    media_deactivated integer DEFAULT 0 NOT NULL,
    records_unchanged integer DEFAULT 0 NOT NULL,
    records_error integer DEFAULT 0 NOT NULL,
    error_detail text,
    correlation_id uuid,
    client_id character varying(64),
    payload_bytes integer,
    duration_ms integer GENERATED ALWAYS AS (((EXTRACT(epoch FROM (finished_at - received_at)) * (1000)::numeric))::integer) STORED
);


--
-- Name: ingest_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingest_items (
    id bigint NOT NULL,
    batch_id uuid NOT NULL,
    entity_type character varying(16) NOT NULL,
    entity_origin public.media_origin,
    entity_ext_id character varying(64) NOT NULL,
    operation character varying(16) NOT NULL,
    error_detail text
);


--
-- Name: ingest_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.ingest_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.ingest_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notification_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    notification_type character varying(48) NOT NULL,
    email_to public.citext NOT NULL,
    status public.notification_status DEFAULT 'queued'::public.notification_status NOT NULL,
    error_detail text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sent_at timestamp with time zone,
    payload jsonb
);


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_id uuid NOT NULL,
    resource character varying(32) NOT NULL,
    can_read boolean DEFAULT false NOT NULL,
    can_write boolean DEFAULT false NOT NULL,
    can_delete boolean DEFAULT false NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(32) NOT NULL,
    description character varying(255)
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token_hash text NOT NULL,
    ip_address inet,
    user_agent text,
    revoked boolean DEFAULT false NOT NULL,
    revoked_reason public.revoke_reason,
    replaced_by_session_id uuid,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_sessions_revoked CHECK ((revoked = (revoked_reason IS NOT NULL)))
);


--
-- Name: user_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_groups (
    user_id uuid NOT NULL,
    group_id uuid NOT NULL,
    assigned_by uuid,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_media_exceptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_media_exceptions (
    user_id uuid NOT NULL,
    media_id uuid NOT NULL,
    access_type public.access_type NOT NULL,
    reason character varying(500),
    expires_at timestamp with time zone,
    granted_by uuid,
    granted_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email public.citext NOT NULL,
    password_hash text NOT NULL,
    full_name character varying(120) NOT NULL,
    role_id uuid NOT NULL,
    status public.user_status DEFAULT 'pending'::public.user_status NOT NULL,
    registration_type public.reg_type NOT NULL,
    approved_by uuid,
    approved_at timestamp with time zone,
    suspended_at timestamp with time zone,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT ck_users_approved CHECK (((approved_by IS NULL) = (approved_at IS NULL)))
);


--
-- Name: video_access_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.video_access_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    media_id uuid,
    access_result public.access_result NOT NULL,
    access_source public.access_source NOT NULL,
    range_request boolean DEFAULT false NOT NULL,
    bytes_served bigint,
    correlation_id uuid NOT NULL,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_access CHECK (((access_result = 'denied'::public.access_result) = (access_source = ANY (ARRAY['denied_revoke'::public.access_source, 'denied_none'::public.access_source]))))
)
PARTITION BY RANGE (created_at);


--
-- Name: video_access_log_2026; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.video_access_log_2026 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    media_id uuid,
    access_result public.access_result NOT NULL,
    access_source public.access_source NOT NULL,
    range_request boolean DEFAULT false NOT NULL,
    bytes_served bigint,
    correlation_id uuid NOT NULL,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_access CHECK (((access_result = 'denied'::public.access_result) = (access_source = ANY (ARRAY['denied_revoke'::public.access_source, 'denied_none'::public.access_source]))))
);


--
-- Name: video_access_log_2027; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.video_access_log_2027 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    media_id uuid,
    access_result public.access_result NOT NULL,
    access_source public.access_source NOT NULL,
    range_request boolean DEFAULT false NOT NULL,
    bytes_served bigint,
    correlation_id uuid NOT NULL,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_access CHECK (((access_result = 'denied'::public.access_result) = (access_source = ANY (ARRAY['denied_revoke'::public.access_source, 'denied_none'::public.access_source]))))
);


--
-- Name: api_request_log_2026; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_request_log ATTACH PARTITION public.api_request_log_2026 FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');


--
-- Name: api_request_log_2027; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_request_log ATTACH PARTITION public.api_request_log_2027 FOR VALUES FROM ('2027-01-01 00:00:00+00') TO ('2028-01-01 00:00:00+00');


--
-- Name: video_access_log_2026; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_access_log ATTACH PARTITION public.video_access_log_2026 FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');


--
-- Name: video_access_log_2027; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_access_log ATTACH PARTITION public.video_access_log_2027 FOR VALUES FROM ('2027-01-01 00:00:00+00') TO ('2028-01-01 00:00:00+00');


--
-- Name: api_request_log api_request_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_request_log
    ADD CONSTRAINT api_request_log_pkey PRIMARY KEY (id, created_at);


--
-- Name: api_request_log_2026 api_request_log_2026_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_request_log_2026
    ADD CONSTRAINT api_request_log_2026_pkey PRIMARY KEY (id, created_at);


--
-- Name: api_request_log_2027 api_request_log_2027_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_request_log_2027
    ADD CONSTRAINT api_request_log_2027_pkey PRIMARY KEY (id, created_at);


--
-- Name: account_setup_tokens pk_account_setup_tokens; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_setup_tokens
    ADD CONSTRAINT pk_account_setup_tokens PRIMARY KEY (id);


--
-- Name: catalog_media pk_catalog_media; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_media
    ADD CONSTRAINT pk_catalog_media PRIMARY KEY (id);


--
-- Name: catalog_products pk_catalog_products; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_products
    ADD CONSTRAINT pk_catalog_products PRIMARY KEY (id);


--
-- Name: catalog_versions pk_catalog_versions; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_versions
    ADD CONSTRAINT pk_catalog_versions PRIMARY KEY (id);


--
-- Name: ext_api_request_log pk_ext_api_request_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ext_api_request_log
    ADD CONSTRAINT pk_ext_api_request_log PRIMARY KEY (id);


--
-- Name: group_version_access pk_group_version_access; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_version_access
    ADD CONSTRAINT pk_group_version_access PRIMARY KEY (group_id, version_id);


--
-- Name: groups pk_groups; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT pk_groups PRIMARY KEY (id);


--
-- Name: ingest_batches pk_ingest_batches; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingest_batches
    ADD CONSTRAINT pk_ingest_batches PRIMARY KEY (id);


--
-- Name: ingest_items pk_ingest_items; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingest_items
    ADD CONSTRAINT pk_ingest_items PRIMARY KEY (id);


--
-- Name: notification_log pk_notification_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_log
    ADD CONSTRAINT pk_notification_log PRIMARY KEY (id);


--
-- Name: role_permissions pk_role_permissions; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT pk_role_permissions PRIMARY KEY (id);


--
-- Name: roles pk_roles; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT pk_roles PRIMARY KEY (id);


--
-- Name: sessions pk_sessions; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT pk_sessions PRIMARY KEY (id);


--
-- Name: user_groups pk_user_groups; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT pk_user_groups PRIMARY KEY (user_id, group_id);


--
-- Name: user_media_exceptions pk_user_media_exceptions; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_media_exceptions
    ADD CONSTRAINT pk_user_media_exceptions PRIMARY KEY (user_id, media_id);


--
-- Name: users pk_users; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT pk_users PRIMARY KEY (id);


--
-- Name: video_access_log video_access_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_access_log
    ADD CONSTRAINT video_access_log_pkey PRIMARY KEY (id, created_at);


--
-- Name: video_access_log_2026 video_access_log_2026_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_access_log_2026
    ADD CONSTRAINT video_access_log_2026_pkey PRIMARY KEY (id, created_at);


--
-- Name: video_access_log_2027 video_access_log_2027_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_access_log_2027
    ADD CONSTRAINT video_access_log_2027_pkey PRIMARY KEY (id, created_at);


--
-- Name: ix_api_request_log_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_api_request_log_user_id ON ONLY public.api_request_log USING btree (user_id);


--
-- Name: api_request_log_2026_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX api_request_log_2026_user_id_idx ON public.api_request_log_2026 USING btree (user_id);


--
-- Name: api_request_log_2027_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX api_request_log_2027_user_id_idx ON public.api_request_log_2027 USING btree (user_id);


--
-- Name: ix_catalog_media_origin_ext_media_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_catalog_media_origin_ext_media_id ON public.catalog_media USING btree (origin, ext_media_id);


--
-- Name: ix_catalog_products_ext_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_catalog_products_ext_product_id ON public.catalog_products USING btree (ext_product_id);


--
-- Name: ix_catalog_versions_ext_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_catalog_versions_ext_version_id ON public.catalog_versions USING btree (ext_version_id);


--
-- Name: ix_ext_log_batch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ext_log_batch ON public.ext_api_request_log USING btree (batch_id);


--
-- Name: ix_ext_log_recent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ext_log_recent ON public.ext_api_request_log USING btree (created_at DESC);


--
-- Name: ix_groups_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_groups_name ON public.groups USING btree (name);


--
-- Name: ix_gva_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_gva_version ON public.group_version_access USING btree (version_id);


--
-- Name: ix_ingest_batches_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_ingest_batches_batch_id ON public.ingest_batches USING btree (batch_id);


--
-- Name: ix_ingest_fresh; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ingest_fresh ON public.ingest_batches USING btree (generated_at DESC) WHERE (status = ANY (ARRAY['completed'::public.ingest_status, 'partial'::public.ingest_status]));


--
-- Name: ix_ingest_items_batch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ingest_items_batch ON public.ingest_items USING btree (batch_id) WHERE ((operation)::text = 'error'::text);


--
-- Name: ix_ingest_recent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ingest_recent ON public.ingest_batches USING btree (received_at DESC);


--
-- Name: ix_media_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_media_version ON public.catalog_media USING btree (version_id, "position") WHERE active;


--
-- Name: ix_products_industry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_products_industry ON public.catalog_products USING btree (industry) WHERE active;


--
-- Name: ix_products_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_products_search ON public.catalog_products USING gin (to_tsvector('spanish'::regconfig, (((name)::text || ' '::text) || (COALESCE(trade_name, ''::character varying))::text)));


--
-- Name: ix_role_permissions_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_role_permissions_role ON public.role_permissions USING btree (role_id);


--
-- Name: ix_role_permissions_role_id_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_role_permissions_role_id_resource ON public.role_permissions USING btree (role_id, resource);


--
-- Name: ix_roles_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_roles_name ON public.roles USING btree (name);


--
-- Name: ix_sessions_token_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_sessions_token_hash ON public.sessions USING btree (token_hash);


--
-- Name: ix_sessions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sessions_user ON public.sessions USING btree (user_id) WHERE (NOT revoked);


--
-- Name: ix_user_groups_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_groups_group ON public.user_groups USING btree (group_id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_users_role ON public.users USING btree (role_id);


--
-- Name: ix_versions_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_versions_product ON public.catalog_versions USING btree (product_id) WHERE active;


--
-- Name: ix_video_access_log_media_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_video_access_log_media_id ON ONLY public.video_access_log USING btree (media_id);


--
-- Name: ix_video_access_log_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_video_access_log_user_id ON ONLY public.video_access_log USING btree (user_id);


--
-- Name: ux_account_setup_tokens_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_account_setup_tokens_hash ON public.account_setup_tokens USING btree (token_hash);


--
-- Name: ux_ingest_running; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_ingest_running ON public.ingest_batches USING btree ((true)) WHERE (status = 'running'::public.ingest_status);


--
-- Name: ux_snapshot_close; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_snapshot_close ON public.ingest_batches USING btree (snapshot_id) WHERE ((mode = 'snapshot'::public.ingest_mode) AND is_last);


--
-- Name: ux_snapshot_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_snapshot_sequence ON public.ingest_batches USING btree (snapshot_id, sequence) WHERE (mode = 'snapshot'::public.ingest_mode);


--
-- Name: video_access_log_2026_media_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX video_access_log_2026_media_id_idx ON public.video_access_log_2026 USING btree (media_id);


--
-- Name: video_access_log_2026_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX video_access_log_2026_user_id_idx ON public.video_access_log_2026 USING btree (user_id);


--
-- Name: video_access_log_2027_media_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX video_access_log_2027_media_id_idx ON public.video_access_log_2027 USING btree (media_id);


--
-- Name: video_access_log_2027_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX video_access_log_2027_user_id_idx ON public.video_access_log_2027 USING btree (user_id);


--
-- Name: api_request_log_2026_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.api_request_log_pkey ATTACH PARTITION public.api_request_log_2026_pkey;


--
-- Name: api_request_log_2026_user_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.ix_api_request_log_user_id ATTACH PARTITION public.api_request_log_2026_user_id_idx;


--
-- Name: api_request_log_2027_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.api_request_log_pkey ATTACH PARTITION public.api_request_log_2027_pkey;


--
-- Name: api_request_log_2027_user_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.ix_api_request_log_user_id ATTACH PARTITION public.api_request_log_2027_user_id_idx;


--
-- Name: video_access_log_2026_media_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.ix_video_access_log_media_id ATTACH PARTITION public.video_access_log_2026_media_id_idx;


--
-- Name: video_access_log_2026_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.video_access_log_pkey ATTACH PARTITION public.video_access_log_2026_pkey;


--
-- Name: video_access_log_2026_user_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.ix_video_access_log_user_id ATTACH PARTITION public.video_access_log_2026_user_id_idx;


--
-- Name: video_access_log_2027_media_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.ix_video_access_log_media_id ATTACH PARTITION public.video_access_log_2027_media_id_idx;


--
-- Name: video_access_log_2027_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.video_access_log_pkey ATTACH PARTITION public.video_access_log_2027_pkey;


--
-- Name: video_access_log_2027_user_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.ix_video_access_log_user_id ATTACH PARTITION public.video_access_log_2027_user_id_idx;


--
-- Name: api_request_log api_request_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.api_request_log
    ADD CONSTRAINT api_request_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: account_setup_tokens fk_account_setup_tokens_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_setup_tokens
    ADD CONSTRAINT fk_account_setup_tokens_users_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: catalog_media fk_catalog_media_catalog_versions_version_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_media
    ADD CONSTRAINT fk_catalog_media_catalog_versions_version_id FOREIGN KEY (version_id) REFERENCES public.catalog_versions(id) ON DELETE CASCADE;


--
-- Name: catalog_versions fk_catalog_versions_catalog_products_product_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_versions
    ADD CONSTRAINT fk_catalog_versions_catalog_products_product_id FOREIGN KEY (product_id) REFERENCES public.catalog_products(id) ON DELETE CASCADE;


--
-- Name: ext_api_request_log fk_ext_api_request_log_ingest_batches_batch_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ext_api_request_log
    ADD CONSTRAINT fk_ext_api_request_log_ingest_batches_batch_id FOREIGN KEY (batch_id) REFERENCES public.ingest_batches(id) ON DELETE SET NULL;


--
-- Name: group_version_access fk_group_version_access_catalog_versions_version_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_version_access
    ADD CONSTRAINT fk_group_version_access_catalog_versions_version_id FOREIGN KEY (version_id) REFERENCES public.catalog_versions(id) ON DELETE CASCADE;


--
-- Name: group_version_access fk_group_version_access_groups_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_version_access
    ADD CONSTRAINT fk_group_version_access_groups_group_id FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: group_version_access fk_group_version_access_users_granted_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_version_access
    ADD CONSTRAINT fk_group_version_access_users_granted_by FOREIGN KEY (granted_by) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: groups fk_groups_users_created_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_groups_users_created_by FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: ingest_items fk_ingest_items_ingest_batches_batch_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingest_items
    ADD CONSTRAINT fk_ingest_items_ingest_batches_batch_id FOREIGN KEY (batch_id) REFERENCES public.ingest_batches(id) ON DELETE CASCADE;


--
-- Name: notification_log fk_notification_log_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_log
    ADD CONSTRAINT fk_notification_log_users_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: role_permissions fk_role_permissions_roles_role_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT fk_role_permissions_roles_role_id FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: sessions fk_sessions_sessions_replaced_by_session_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_sessions_sessions_replaced_by_session_id FOREIGN KEY (replaced_by_session_id) REFERENCES public.sessions(id) ON DELETE RESTRICT;


--
-- Name: sessions fk_sessions_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_sessions_users_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_groups fk_user_groups_groups_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT fk_user_groups_groups_group_id FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: user_groups fk_user_groups_users_assigned_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT fk_user_groups_users_assigned_by FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: user_groups fk_user_groups_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT fk_user_groups_users_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_media_exceptions fk_user_media_exceptions_catalog_media_media_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_media_exceptions
    ADD CONSTRAINT fk_user_media_exceptions_catalog_media_media_id FOREIGN KEY (media_id) REFERENCES public.catalog_media(id) ON DELETE CASCADE;


--
-- Name: user_media_exceptions fk_user_media_exceptions_users_granted_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_media_exceptions
    ADD CONSTRAINT fk_user_media_exceptions_users_granted_by FOREIGN KEY (granted_by) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: user_media_exceptions fk_user_media_exceptions_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_media_exceptions
    ADD CONSTRAINT fk_user_media_exceptions_users_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users fk_users_roles_role_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_roles_role_id FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE RESTRICT;


--
-- Name: users fk_users_users_approved_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_users_approved_by FOREIGN KEY (approved_by) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: video_access_log video_access_log_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.video_access_log
    ADD CONSTRAINT video_access_log_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.catalog_media(id) ON DELETE SET NULL;


--
-- Name: video_access_log video_access_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.video_access_log
    ADD CONSTRAINT video_access_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--


