CREATE TABLE producer_group_membership
(
    producer_group_id   INT             NOT NULL
    , producer_id       INT             NOT NULL
    , created_utc       TIMESTAMPTZ     NOT NULL    DEFAULT (NOW() AT TIME ZONE 'UTC')
    , created_by        VARCHAR(255)    NOT NULL    DEFAULT (CURRENT_USER)
    , modified_utc      TIMESTAMPTZ         NULL
    , modified_by       VARCHAR(255)        NULL
    , CONSTRAINT pk_producer_group_membership PRIMARY KEY (producer_group_id, producer_id)
);

/*
-- ==================================
-- CONSTRAINTS
-- ==================================
*/
ALTER TABLE producer_group_membership
ADD CONSTRAINT fk_producer_group_membership_producer_group_id
FOREIGN KEY (producer_group_id)
REFERENCES producer_group (producer_group_id);
 
ALTER TABLE producer_group_membership
ADD CONSTRAINT fk_producer_group_membership_producer_id
FOREIGN KEY (producer_id)
REFERENCES producer (producer_id);

 
/*
-- ==================================
-- TABLE COMMENT
-- ==================================
*/
COMMENT ON TABLE producer_group_membership IS 'Tracks producer memberships in groups';