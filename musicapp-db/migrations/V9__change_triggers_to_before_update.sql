/*
-- ==================================
-- V9__change_triggers_to_before_update.sql
-- Changes all update triggers from AFTER to BEFORE
-- This allows modified_utc to be set before the record is committed
-- Tables: artist, artist_group, artist_group_membership, genre, genre_hierarchy, 
--         producer, producer_group, producer_group_membership, project, project_type, 
--         scene, song, streaming_service, user_login
-- ==================================
*/

/*
-- ==================================
-- Drop all existing triggers
-- ==================================
*/
DROP TRIGGER trg_artist_set_modified_utc ON artist;
DROP TRIGGER trg_artist_group_set_modified_utc ON artist_group;
DROP TRIGGER trg_artist_group_membership_set_modified_utc ON artist_group_membership;
DROP TRIGGER trg_genre_set_modified_utc ON genre;
DROP TRIGGER trg_genre_hierarchy_set_modified_utc ON genre_hierarchy;
DROP TRIGGER trg_producer_set_modified_utc ON producer;
DROP TRIGGER trg_producer_group_set_modified_utc ON producer_group;
DROP TRIGGER trg_producer_group_membership_set_modified_utc ON producer_group_membership;
DROP TRIGGER trg_project_set_modified_utc ON project;
DROP TRIGGER trg_project_type_set_modified_utc ON project_type;
DROP TRIGGER trg_scene_set_modified_utc ON scene;
DROP TRIGGER trg_song_set_modified_utc ON song;
DROP TRIGGER trg_streaming_service_set_modified_utc ON streaming_service;
DROP TRIGGER trg_user_login_set_modified_utc ON user_login;

/*
-- ==================================
-- Create triggers as BEFORE UPDATE
-- ==================================
*/
CREATE TRIGGER trg_artist_set_modified_utc
    BEFORE UPDATE ON artist
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_artist_group_set_modified_utc
    BEFORE UPDATE ON artist_group
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_artist_group_membership_set_modified_utc
    BEFORE UPDATE ON artist_group_membership
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_genre_set_modified_utc
    BEFORE UPDATE ON genre
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_genre_hierarchy_set_modified_utc
    BEFORE UPDATE ON genre_hierarchy
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_producer_set_modified_utc
    BEFORE UPDATE ON producer
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_producer_group_set_modified_utc
    BEFORE UPDATE ON producer_group
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_producer_group_membership_set_modified_utc
    BEFORE UPDATE ON producer_group_membership
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_project_set_modified_utc
    BEFORE UPDATE ON project
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_project_type_set_modified_utc
    BEFORE UPDATE ON project_type
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_scene_set_modified_utc
    BEFORE UPDATE ON scene
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_song_set_modified_utc
    BEFORE UPDATE ON song
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_streaming_service_set_modified_utc
    BEFORE UPDATE ON streaming_service
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();

CREATE TRIGGER trg_user_login_set_modified_utc
    BEFORE UPDATE ON user_login
    FOR EACH ROW
    EXECUTE FUNCTION set_modified_utc();
