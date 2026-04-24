CREATE TABLE public.genres
(
    genre_id SERIAL PRIMARY KEY
    , genre_name TEXT NOT NULL
    , "description" TEXT NOT NULL
    , created_utc TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
    , created_by TEXT NOT NULL DEFAULT (current_user)
    , modified_utc TIMESTAMP NULL
    . modified_by TEXT NULL
)