/*
-- ==================================
-- V6__update_login_proc.sql
-- Changes composite primary keys in many-to-many joining tables to a single primary surrogate key with a unique index.
-- Procedures: login_user
-- ==================================
*/

CREATE OR REPLACE PROCEDURE login_user
(
    IN pUsername            VARCHAR(50)
    , IN pPassword          BYTEA
    , OUT poAuthenticated   BOOLEAN
    , OUT poAuthExpiration  TIMESTAMPTZ
    , OUT poIsAdmin         BOOLEAN
    , OUT poErrorMessage    VARCHAR(255)
)
LANGUAGE plpgsql
AS $$

/*
-- ======================================================
-- Author:        Carlos Gonzalez
-- Date Created:  2025-12-13
-- Description:   Login a user and update the count, time, and origin of the last login
---------------------------------------------------------
-- YYYY-MM-DD - Author - Change
-- 2025-12-20 - Carlos Gonzalez - Added output error message, admin flag, and login expiration datetime
-- 2026-04-26 - Carlos Gonzalez - Ported to Postgres
-- 2026-05-24 - Carlos Gonzalez - Corrected transactional logic, added missing active check, and prevented error on login miss
-- ======================================================
*/

DECLARE
    vLoginId    INT     := NULL;
    vIsActive   BOOLEAN := FALSE;
    vIsAdmin    BOOLEAN := FALSE;

BEGIN

    -- Initialize output params
    poAuthenticated     := FALSE;
    poAuthExpiration    := NULL;
    poIsAdmin           := FALSE;
    poErrorMessage      := NULL;

    -- Get the user
    SELECT
        u.user_login_id
        , u.is_admin
        , u.is_active
    INTO
        vLoginId
        , vIsAdmin
        , vIsActive
    FROM
        user_login AS u
    WHERE
        1=1
        AND u.username = pUsername
        AND u.user_password = pPassword
    ;

    /*
    -- ======================================================
    -- Check if user exists
    -- ======================================================
    */
    IF vLoginId IS NULL THEN
        poErrorMessage := 'Invalid username or password';
        RETURN;
    END IF;

    /*
    -- ======================================================
    -- Check if user is active
    -- ======================================================
    */
    IF NOT vIsActive THEN
        poErrorMessage := 'Login has been deactivated';
        RETURN;
    END IF;

    /*
    -- ======================================================
    -- If the user exists and is active, set auth = TRUE and update login
    -- ======================================================
    */
    poAuthenticated := TRUE;
    poAuthExpiration := CURRENT_TIMESTAMP AT TIME ZONE 'UTC' + INTERVAL '2 hours';
    poIsAdmin := vIsAdmin;

    UPDATE
        user_login AS u
    SET
        last_login_date = CURRENT_TIMESTAMP AT TIME ZONE 'UTC'
        , login_count = u.login_count + 1
        , modified_by = current_user
        , modified_utc = CURRENT_TIMESTAMP AT TIME ZONE 'UTC'
    WHERE
        u.user_login_id = vLoginId
    ;

EXCEPTION
    WHEN OTHERS THEN
        -- Capture error message
            poErrorMessage := SQLERRM;
            poAuthenticated := FALSE;
            poAuthExpiration := NULL;
            poIsAdmin := FALSE;
            RAISE;
END;
$$;

/*
-- ==================================
-- PROC COMMENTS
-- ==================================
*/
COMMENT ON PROCEDURE login_user(VARCHAR(50), BYTEA, BOOLEAN, TIMESTAMPTZ, BOOLEAN, VARCHAR(255))
    IS 'Authenticates a user login and updates login stats';