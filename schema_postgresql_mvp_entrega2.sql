-- Entrega 2 - MVP parcial
-- Schema fisico preliminar para PostgreSQL 15+
-- Projeto Aplicado II - IST Ambiental
-- Objetivo: suportar unificacao de Identificacao + Abundancia e preparar
-- integracao progressiva com bibliotecas publicas (PubChem, HMDB, ChEBI, FooDB etc.).

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS ref;

CREATE TABLE IF NOT EXISTS core.ingestion_batch (
    batch_id              BIGSERIAL PRIMARY KEY,
    batch_name            VARCHAR(120) NOT NULL,
    solvent               VARCHAR(80),
    ionization_mode       VARCHAR(20),
    source_notes          TEXT,
    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg.identification_row (
    identification_row_id BIGSERIAL PRIMARY KEY,
    batch_id              BIGINT NOT NULL REFERENCES core.ingestion_batch(batch_id),
    source_sheet          VARCHAR(120),
    source_row_number     INTEGER,
    compound_code         VARCHAR(100) NOT NULL,
    source_compound_id    VARCHAR(120),
    adducts               VARCHAR(255),
    molecular_formula     VARCHAR(120),
    score                 NUMERIC(10,4),
    fragmentation_score   NUMERIC(10,4),
    mass_error_ppm        NUMERIC(12,6),
    isotope_similarity    NUMERIC(12,6),
    link_url              TEXT,
    description           TEXT,
    neutral_mass_da       NUMERIC(18,8),
    mz                    NUMERIC(18,8),
    retention_time_min    NUMERIC(12,6),
    raw_payload           JSONB
);

CREATE TABLE IF NOT EXISTS stg.abundance_row (
    abundance_row_id      BIGSERIAL PRIMARY KEY,
    batch_id              BIGINT NOT NULL REFERENCES core.ingestion_batch(batch_id),
    source_sheet          VARCHAR(120),
    source_row_number     INTEGER,
    compound_code         VARCHAR(100) NOT NULL,
    neutral_mass_da       NUMERIC(18,8),
    mz                    NUMERIC(18,8),
    retention_time_min    NUMERIC(12,6),
    chrom_peak_width_min  NUMERIC(12,6),
    identifications_total INTEGER,
    replicate_payload     JSONB NOT NULL,
    raw_payload           JSONB
);

CREATE TABLE IF NOT EXISTS stg.curated_catalog_row (
    catalog_row_id        BIGSERIAL PRIMARY KEY,
    batch_id              BIGINT REFERENCES core.ingestion_batch(batch_id),
    source_sheet          VARCHAR(120),
    catalog_code          VARCHAR(80),
    compound_name         TEXT,
    solvent               VARCHAR(80),
    ionization_mode       VARCHAR(20),
    chemical_category     VARCHAR(150),
    metabolism_note       TEXT,
    pathway_note          TEXT,
    raw_payload           JSONB
);

CREATE TABLE IF NOT EXISTS stg.pubchem_compound_raw (
    pubchem_raw_id        BIGSERIAL PRIMARY KEY,
    batch_id              BIGINT REFERENCES core.ingestion_batch(batch_id),
    source_file_name      VARCHAR(255),
    pubchem_cid           BIGINT,
    xml_payload           XML NOT NULL,
    loaded_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS core.feature (
    feature_id                    BIGSERIAL PRIMARY KEY,
    batch_id                      BIGINT NOT NULL REFERENCES core.ingestion_batch(batch_id),
    feature_code                  VARCHAR(100) NOT NULL,
    neutral_mass_da               NUMERIC(18,8),
    mz                            NUMERIC(18,8),
    retention_time_min            NUMERIC(12,6),
    chrom_peak_width_min          NUMERIC(12,6),
    source_identification_count   INTEGER,
    present_in_identification     BOOLEAN NOT NULL DEFAULT FALSE,
    present_in_abundance          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_feature UNIQUE (batch_id, feature_code)
);

CREATE TABLE IF NOT EXISTS core.sample_group (
    sample_group_id       BIGSERIAL PRIMARY KEY,
    batch_id              BIGINT NOT NULL REFERENCES core.ingestion_batch(batch_id),
    group_code            VARCHAR(40) NOT NULL,
    group_description     TEXT,
    CONSTRAINT uq_sample_group UNIQUE (batch_id, group_code)
);

CREATE TABLE IF NOT EXISTS core.replicate (
    replicate_id          BIGSERIAL PRIMARY KEY,
    sample_group_id       BIGINT NOT NULL REFERENCES core.sample_group(sample_group_id),
    replicate_code        VARCHAR(40) NOT NULL,
    replicate_order       INTEGER,
    replicate_type        VARCHAR(40),
    CONSTRAINT uq_replicate UNIQUE (sample_group_id, replicate_code)
);

CREATE TABLE IF NOT EXISTS core.abundance_measurement (
    measurement_id        BIGSERIAL PRIMARY KEY,
    feature_id            BIGINT NOT NULL REFERENCES core.feature(feature_id),
    replicate_id          BIGINT NOT NULL REFERENCES core.replicate(replicate_id),
    abundance_value       NUMERIC(20,8) NOT NULL,
    measurement_note      TEXT,
    CONSTRAINT uq_measurement UNIQUE (feature_id, replicate_id)
);

CREATE TABLE IF NOT EXISTS core.candidate_identification (
    candidate_id          BIGSERIAL PRIMARY KEY,
    feature_id            BIGINT NOT NULL REFERENCES core.feature(feature_id),
    source_compound_id    VARCHAR(120),
    adducts               VARCHAR(255),
    molecular_formula     VARCHAR(120),
    score                 NUMERIC(10,4),
    fragmentation_score   NUMERIC(10,4),
    mass_error_ppm        NUMERIC(12,6),
    isotope_similarity    NUMERIC(12,6),
    description           TEXT,
    link_url              TEXT,
    candidate_rank_local  INTEGER
);

CREATE TABLE IF NOT EXISTS ref.external_source (
    source_id             BIGSERIAL PRIMARY KEY,
    source_name           VARCHAR(60) NOT NULL UNIQUE,
    source_type           VARCHAR(40),
    base_url              TEXT,
    notes                 TEXT
);

CREATE TABLE IF NOT EXISTS ref.external_compound (
    external_compound_id  BIGSERIAL PRIMARY KEY,
    source_id             BIGINT NOT NULL REFERENCES ref.external_source(source_id),
    external_accession    VARCHAR(120) NOT NULL,
    preferred_name        TEXT,
    molecular_formula     VARCHAR(120),
    exact_mass            NUMERIC(18,8),
    canonical_smiles      TEXT,
    inchi                 TEXT,
    inchikey              VARCHAR(64),
    raw_payload           JSONB,
    CONSTRAINT uq_external_compound UNIQUE (source_id, external_accession)
);

CREATE TABLE IF NOT EXISTS ref.external_identifier (
    identifier_id         BIGSERIAL PRIMARY KEY,
    external_compound_id  BIGINT NOT NULL REFERENCES ref.external_compound(external_compound_id),
    identifier_type       VARCHAR(40) NOT NULL,
    identifier_value      TEXT NOT NULL,
    is_primary            BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS ref.compound_property (
    property_id           BIGSERIAL PRIMARY KEY,
    external_compound_id  BIGINT NOT NULL REFERENCES ref.external_compound(external_compound_id),
    property_name         VARCHAR(120) NOT NULL,
    property_value_text   TEXT,
    property_value_num    NUMERIC(20,8),
    unit                  VARCHAR(40),
    evidence_source       VARCHAR(120)
);

CREATE TABLE IF NOT EXISTS ref.taxonomy_node (
    taxon_id              BIGSERIAL PRIMARY KEY,
    source_id             BIGINT REFERENCES ref.external_source(source_id),
    external_taxon_id     VARCHAR(120),
    taxon_name            VARCHAR(255) NOT NULL,
    taxon_rank            VARCHAR(40),
    parent_taxon_id       BIGINT REFERENCES ref.taxonomy_node(taxon_id)
);

CREATE TABLE IF NOT EXISTS ref.compound_taxonomy (
    compound_taxonomy_id  BIGSERIAL PRIMARY KEY,
    external_compound_id  BIGINT NOT NULL REFERENCES ref.external_compound(external_compound_id),
    taxon_id              BIGINT NOT NULL REFERENCES ref.taxonomy_node(taxon_id),
    relationship_type     VARCHAR(60),
    evidence_note         TEXT
);

CREATE TABLE IF NOT EXISTS ref.chemical_class (
    chemical_class_id     BIGSERIAL PRIMARY KEY,
    source_id             BIGINT REFERENCES ref.external_source(source_id),
    external_class_id     VARCHAR(120),
    class_name            VARCHAR(255) NOT NULL,
    class_system          VARCHAR(80),
    parent_class_id       BIGINT REFERENCES ref.chemical_class(chemical_class_id)
);

CREATE TABLE IF NOT EXISTS ref.compound_class (
    compound_class_id     BIGSERIAL PRIMARY KEY,
    external_compound_id  BIGINT NOT NULL REFERENCES ref.external_compound(external_compound_id),
    chemical_class_id     BIGINT NOT NULL REFERENCES ref.chemical_class(chemical_class_id),
    evidence_note         TEXT
);

CREATE TABLE IF NOT EXISTS ref.use_application (
    use_id                BIGSERIAL PRIMARY KEY,
    source_id             BIGINT REFERENCES ref.external_source(source_id),
    use_category          VARCHAR(120),
    use_description       TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ref.compound_use (
    compound_use_id       BIGSERIAL PRIMARY KEY,
    external_compound_id  BIGINT NOT NULL REFERENCES ref.external_compound(external_compound_id),
    use_id                BIGINT NOT NULL REFERENCES ref.use_application(use_id),
    evidence_note         TEXT
);

CREATE TABLE IF NOT EXISTS ref.curated_catalog_entry (
    catalog_entry_id      BIGSERIAL PRIMARY KEY,
    catalog_code          VARCHAR(80),
    compound_name         TEXT NOT NULL,
    solvent               VARCHAR(80),
    ionization_mode       VARCHAR(20),
    chemical_category     VARCHAR(150),
    metabolism_note       TEXT,
    pathway_note          TEXT,
    source_sheet          VARCHAR(120)
);

CREATE TABLE IF NOT EXISTS ref.candidate_match (
    match_id              BIGSERIAL PRIMARY KEY,
    candidate_id          BIGINT NOT NULL REFERENCES core.candidate_identification(candidate_id),
    external_compound_id  BIGINT NOT NULL REFERENCES ref.external_compound(external_compound_id),
    match_method          VARCHAR(60) NOT NULL,
    match_score           NUMERIC(10,6),
    match_status          VARCHAR(30) NOT NULL DEFAULT 'proposed',
    basis_fields          JSONB,
    is_top5_candidate     BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT ck_match_score CHECK (match_score IS NULL OR (match_score >= 0 AND match_score <= 1))
);

-- Indices recomendados para as consultas principais
CREATE INDEX IF NOT EXISTS idx_stg_identification_compound_code ON stg.identification_row (compound_code);
CREATE INDEX IF NOT EXISTS idx_stg_abundance_compound_code ON stg.abundance_row (compound_code);
CREATE INDEX IF NOT EXISTS idx_core_feature_code ON core.feature (feature_code);
CREATE INDEX IF NOT EXISTS idx_core_feature_batch ON core.feature (batch_id);
CREATE INDEX IF NOT EXISTS idx_core_candidate_feature ON core.candidate_identification (feature_id);
CREATE INDEX IF NOT EXISTS idx_core_measurement_feature ON core.abundance_measurement (feature_id);
CREATE INDEX IF NOT EXISTS idx_core_measurement_replicate ON core.abundance_measurement (replicate_id);
CREATE INDEX IF NOT EXISTS idx_ref_external_compound_accession ON ref.external_compound (external_accession);
CREATE INDEX IF NOT EXISTS idx_ref_external_compound_inchikey ON ref.external_compound (inchikey);
CREATE INDEX IF NOT EXISTS idx_ref_identifier_value ON ref.external_identifier (identifier_value);
CREATE INDEX IF NOT EXISTS idx_ref_taxon_name ON ref.taxonomy_node (taxon_name);
CREATE INDEX IF NOT EXISTS idx_ref_class_name ON ref.chemical_class (class_name);
CREATE INDEX IF NOT EXISTS idx_ref_match_candidate ON ref.candidate_match (candidate_id);
CREATE INDEX IF NOT EXISTS idx_ref_match_external_compound ON ref.candidate_match (external_compound_id);

-- Carga inicial recomendada de fontes externas
INSERT INTO ref.external_source (source_name, source_type, base_url, notes)
VALUES
    ('PubChem', 'quimica', 'https://pubchem.ncbi.nlm.nih.gov/', 'Fonte publica prioritaria para identificadores e propriedades'),
    ('HMDB', 'metabolitos', 'https://hmdb.ca/', 'Fonte orientada a metabolitos e taxonomia'),
    ('ChEBI', 'ontologia', 'https://www.ebi.ac.uk/chebi/', 'Fonte orientada a ontologia e classificacao quimica'),
    ('FooDB', 'alimentos', 'https://foodb.ca/', 'Fonte complementar para origem alimentar e contexto biologico'),
    ('CatalogoCuradoIST', 'interna', NULL, 'Catálogo semantico interno a partir do arquivo Compostos_final.xlsx')
ON CONFLICT (source_name) DO NOTHING;
