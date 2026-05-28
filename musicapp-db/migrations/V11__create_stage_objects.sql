/*
-- ==================================
-- V11__create_stage_objects.sql
-- Creates initial ETL staging objects
-- Tables: stage.genre, stage.genre_hierarchy
-- Procs: stage.genre_merge, stage.genre_hierarchy_merge
-- ==================================
*/

/*
-- ==================================
-- Create schema
-- ==================================
*/

CREATE SCHEMA stage;

/*
-- ==================================
-- Create tables
-- ==================================
*/

CREATE TABLE stage.genre
(
    genre_id            INT          
    , genre_name        VARCHAR(255) 
);

CREATE TABLE stage.genre_hierarchy
(
    genre_id            INT             NOT NULL
    , parent_genre_id   INT             NOT NULL
);

/*
-- ==================================
-- Create procs
-- ==================================
*/
CREATE PROCEDURE stage.genre_merge
(
    OUT po_inserted_rows   INT
    ,OUT po_updated_rows   INT
    ,OUT po_deleted_rows   INT
)
LANGUAGE plpgsql
AS $$
/*
-- ======================================================
-- Author:        Carlos Gonzalez
-- Date Created:  2025-12-20
-- Description:   Merges Genre records from stage
---------------------------------------------------------
-- YYYY-MM-DD - Author - Change
-- 2026-05-27 - Carlos Gonzalez - Readapted for Postgres
-- ======================================================
*/

BEGIN

    /*
    -- ======================================================
    -- Insert rows that don't exist
    -- ======================================================
    */
    INSERT INTO genre
    (
        genre_id
        , genre_name
        , "description"
    )
    SELECT
        src.genre_id
        , src.genre_name
        , '' AS "description"
    FROM
        stage.genre AS src
    WHERE
        NOT EXISTS
        (
            SELECT
                1
            FROM
                genre AS tgt
            WHERE
                tgt.genre_name = src.genre_name
        )
    ;

    GET DIAGNOSTICS po_inserted_rows := ROW_COUNT;

END;
$$;

CREATE PROCEDURE stage.genre_hierarchy_merge
(
    OUT po_inserted_rows INT
    ,OUT po_updated_rows INT
    ,OUT po_deleted_rows INT
)
LANGUAGE plpgsql
AS $$

/*
-- ======================================================
-- Author:        Carlos Gonzalez
-- Date Created:  2025-12-20
-- Description:   Merges GenreHierarchy records from stage
---------------------------------------------------------
-- YYYY-MM-DD - Author - Change
-- 2026-05-27 - Carlos Gonzalez - Repurposed for Postgres
-- ======================================================
*/

BEGIN

    /*
    -- ======================================================
    -- Insert rows that don't exist
    -- ======================================================
    */   
    INSERT INTO genre_hierarchy
    (
        genre_id
        , parent_genre_id
    )
    SELECT 
        src.genre_id
        , src.parent_genre_id
    FROM 
        stage.genre_hierarchy AS src
    WHERE
        NOT EXISTS
        (
            SELECT
                1
            FROM
                genre_hierarchy AS tgt
            WHERE
                1=1
                AND tgt.genre_id = src.genre_id
                AND tgt.parent_genre_id = src.parent_genre_id
        )
    ;

    GET DIAGNOSTICS po_inserted_rows := ROW_COUNT;

END;
$$;