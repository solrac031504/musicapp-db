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