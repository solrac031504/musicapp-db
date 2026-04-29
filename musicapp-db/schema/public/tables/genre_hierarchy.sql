CREATE TABLE genre_hierarchy
(
    genre_id            INT             NOT NULL
    , parent_genre_id   INT             NOT NULL
    , created_utc       TIMESTAMPTZ     NOT NULL    DEFAULT (NOW() AT TIME ZONE 'UTC')
    , created_by        VARCHAR(255)    NOT NULL    DEFAULT CURRENT_USER
    , modified_utc      TIMESTAMPTZ
    , modified_by       VARCHAR(255)
    , CONSTRAINT pk_genre_hierarchy PRIMARY KEY (genre_id, parent_genre_id)
);

/*
-- ==================================
-- CONSTRAINTS
-- ==================================
*/
ALTER TABLE genre_hierarchy
ADD CONSTRAINT fk_genre_hierarchy_genre_id
FOREIGN KEY (genre_id)
REFERENCES genre (genre_id);
 
ALTER TABLE genre_hierarchy
ADD CONSTRAINT fk_genre_hierarchy_parent_genre_id
FOREIGN KEY (parent_genre_id)
REFERENCES genre (genre_id);

 
/*
-- ==================================
-- TABLE COMMENT
-- ==================================
*/
COMMENT ON TABLE genre_hierarchy IS 'The hierarchical organization of genres';
 
/*
-- ==================================
-- FIELD COMMENTS
-- ==================================
*/
COMMENT ON COLUMN genre_hierarchy.genre_id        IS 'PK. The current genre in the hierarchy. References genre';
COMMENT ON COLUMN genre_hierarchy.parent_genre_id IS 'PK. The parent of the current genre. -1 if the genre is a root genre. References genre';
COMMENT ON COLUMN genre_hierarchy.created_utc     IS 'When the record was created in UTC';
COMMENT ON COLUMN genre_hierarchy.created_by      IS 'Who created the record';
COMMENT ON COLUMN genre_hierarchy.modified_utc    IS 'When the record was modified in UTC';
COMMENT ON COLUMN genre_hierarchy.modified_by     IS 'Who modified the record';