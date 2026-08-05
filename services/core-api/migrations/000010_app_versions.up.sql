-- Migration: Add app_versions table for in-app APK update control
-- Supports multiple platforms (android, ios) and mandatory/optional updates.

CREATE TABLE IF NOT EXISTS content.app_versions (
    id              BIGSERIAL PRIMARY KEY,
    platform        TEXT        NOT NULL DEFAULT 'android',  -- 'android' | 'ios'
    version_name    TEXT        NOT NULL,                    -- e.g. "1.1.0"
    version_code    INTEGER     NOT NULL,                    -- e.g. 2 (incremental int)
    download_url    TEXT        NOT NULL,                    -- direct APK download link
    release_notes   TEXT,                                   -- changelog shown in dialog
    is_mandatory    BOOLEAN     NOT NULL DEFAULT FALSE,      -- force update?
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_app_versions_platform_code UNIQUE (platform, version_code)
);

-- Index for fast "latest version per platform" lookup
CREATE INDEX IF NOT EXISTS idx_app_versions_platform_code
    ON content.app_versions (platform, version_code DESC);

COMMENT ON TABLE content.app_versions IS
    'Tracks released APK/IPA versions for in-app update checking. '
    'The latest record per platform (highest version_code) is served to clients.';
