/*
-- ==================================
-- V7__create_triggers.sql
-- Creates trigger function and adds triggers on all tables
-- Tables: artist_group_membership, artist_group, artist, genre_hierarchy, genre, producer_group_membership, producer_group, producer, project_type, project, scene, song, streaming_service, user_login
-- Function: set_modified_utc
-- ==================================
*/

/*
-- ==================================
-- Create function
-- ==================================
*/
CREATE OR REPLACE FUNCTION set_modified_utc()
RETURNS TRIGGER AS $$
BEGIN

    /*
    -- ======================================================
    -- Author:        Carlos Gonzalez
    -- Date Created:  2026-05-09
    -- Description:   Updates rows when modified
    ---------------------------------------------------------
    -- YYYY-MM-DD - Author - Change
    -- 
    -- ======================================================
    */

    NEW.modified_utc = NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*
-- ==================================
-- Create triggers
-- ==================================
*/
CREATE trg_artist_group_membership_set_modified_utc
    AFTER UPDATE ON artist_group_membership
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_artist_group_set_modified_utc
    AFTER UPDATE ON artist_group
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_artist_set_modified_utc
    AFTER UPDATE ON artist
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_genre_hierarchy_set_modified_utc
    AFTER UPDATE ON genre_hierarchy
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_genre_set_modified_utc
    AFTER UPDATE ON genre
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_producer_group_membership_set_modified_utc
    AFTER UPDATE ON producer_group_membership
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_producer_group_set_modified_utc
    AFTER UPDATE ON producer_group
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_producer_set_modified_utc
    AFTER UPDATE ON producer
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_project_type_set_modified_utc
    AFTER UPDATE ON project_type
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_project_set_modified_utc
    AFTER UPDATE ON project
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_scene_set_modified_utc
    AFTER UPDATE ON scene
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_song_set_modified_utc
    AFTER UPDATE ON song
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_streaming_service_set_modified_utc
    AFTER UPDATE ON streaming_service
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE trg_user_login_set_modified_utc
    AFTER UPDATE ON user_login
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();