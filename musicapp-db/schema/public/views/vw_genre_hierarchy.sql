CREATE VIEW vw_genre_hierarchy
AS

/*
-- ======================================================
-- Author:        Carlos Gonzalez
-- Date Created:  2025-12-21
-- Description:   Displays the full hierarchy of the Genres and the root genre they fall under
---------------------------------------------------------
-- YYYY-MM-DD - Author - Change
-- 2026-04-26 - Carlos Gonzalez - Ported to postgres
-- ======================================================
*/

WITH RECURSIVE cte_genre_hierarchy AS
(
    -- Anchor: Get all root nodes (genres with no parent, i.e., parent_genre_id = -1)
    SELECT
        g.genre_id
        , g.genre_name
        , g.genre_name::TEXT            AS hierarchy_path
        , gh.parent_genre_id
        , 1                             AS level
        , g.genre_name                  AS root_genre
        , g.genre_id                    AS root_genre_id
    FROM
        genre AS g
        JOIN genre_hierarchy AS gh
            ON g.genre_id = gh.genre_id
    WHERE
        gh.parent_genre_id = -1
 
    UNION ALL
 
    -- Recursive: Get children of each node
    SELECT
        g.genre_id
        , g.genre_name
        , CONCAT(cte.hierarchy_path, ' > ', g.genre_name)::TEXT
        , gh.parent_genre_id
        , cte.level + 1
        , cte.root_genre
        , cte.root_genre_id
    FROM
        genre AS g
        JOIN genre_hierarchy AS gh
            ON g.genre_id = gh.genre_id
        JOIN cte_genre_hierarchy AS cte
            ON gh.parent_genre_id = cte.genre_id
    WHERE
        gh.parent_genre_id <> -1
)
SELECT
    cgh.genre_id
    , cgh.genre_name
    , cgh.hierarchy_path
    , cgh.parent_genre_id
    , cgh.level
    , cgh.root_genre
    , cgh.root_genre_id
FROM
    cte_genre_hierarchy AS cgh
;
