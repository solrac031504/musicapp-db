CREATE TABLE artist_group_membership
(
    artist_group_id         INT             NOT NULL
    , artist_id             INT             NOT NULL
    , created_utc           TIMESTAMPTZ     NOT NULL    DEFAULT (NOW() AT TIME ZONE 'UTC')
    , created_by            VARCHAR(255)    NOT NULL    DEFAULT CURRENT_USER
    , modified_utc          TIMESTAMPTZ
    , modified_by           VARCHAR(255)
    , CONSTRAINT pk_artist_group_membership PRIMARY KEY (group_id, artist_id)
);
 
/*
-- ==================================
-- CONSTRAINTS
-- ==================================
*/
ALTER TABLE artist_group_membership
ADD CONSTRAINT fk_artist_group_membership_group_id
FOREIGN KEY (artist_group_id)
REFERENCES artist_group (group_id);
 
ALTER TABLE artist_group_membership
ADD CONSTRAINT fk_artist_group_membership_artist_id
FOREIGN KEY (artist_id)
REFERENCES artist (artist_id);

/*
-- ==================================
-- TABLE COMMENT
-- ==================================
*/
COMMENT ON TABLE artist_group_membership IS 'Tracks artist memberships in groups';