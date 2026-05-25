/*
-- ==================================
-- V6__correct_project_fk.sql
-- Corrects the foreign key reference on fk_project_scene_id
-- Tables: project
-- ==================================
*/

/*
-- ==================================
-- Drop and recreate FK constraints
-- ==================================
*/
ALTER TABLE project
DROP CONSTRAINT fk_project_scene_id;

ALTER TABLE project
ADD CONSTRAINT fk_project_scene_id
FOREIGN KEY (scene_id)
REFERENCES scene (scene_id);