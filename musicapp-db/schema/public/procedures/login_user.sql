CREATE PROCEDURE login_user
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
-- ======================================================
*/

DECLARE
    vLoginId    INT     := NULL;
    vIsActive   BOOLEAN := FALSE;
    vIsAdmin    BOOLEAN := FALSE;

BEGIN

END;
$$;