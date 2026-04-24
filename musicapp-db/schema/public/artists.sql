CREATE TABLE public.artists
(
    artist_id       SERIAL PRIMARY KEY
    , artist_name   TEXT                NOT NULL
    , is_active     BOOLEAN             NOT NULL
    , created_utc   TIMESTAMP           NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
    , created_by    TEXT                NOT NULL DEFAULT (current_user)
    , modified_utc  TIMESTAMP               NULL
    , modified_by   TEXT                    NULL
);

/*
-- ==================================
-- TABLE COMMENT
-- ==================================
*/
COMMENT ON TABLE artists IS 'Data about individual artists';

/*
-- ==================================
-- FIELD COMMENTS
-- ==================================
*/
COMMENT ON COLUMN artists.artist_id IS 'PK, SERIAL';
COMMENT ON COLUMN artists.artist_name IS 'The name of the artist';
COMMENT ON COLUMN artists.is_active IS 'Is the artist still making music';
COMMENT ON COLUMN artists.created_utc IS 'When the record was created in UTC';
COMMENT ON COLUMN artists.created_by IS 'Who created the record';
COMMENT ON COLUMN artists.modified_utc IS 'When the record was modified in UTC';
COMMENT ON COLUMN artists.modified_by IS 'Who modified the record';