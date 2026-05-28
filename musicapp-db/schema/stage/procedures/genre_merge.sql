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
        , 
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