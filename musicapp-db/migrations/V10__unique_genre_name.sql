/*
-- ==================================
-- V10__unique_genre_name.sql
-- Adds unique index on genre name
-- Tables: genre
-- ==================================
*/

CREATE UNIQUE INDEX ux_genre_genre_name
ON genre
(
    genre_name
)
INCLUDE
(
    "description"
    ,genre_id
    ,created_by
    ,modified_by
);