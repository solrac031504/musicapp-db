# musicapp-db

PostgreSQL database for MusicApp — a personal music library and cataloging
application. Managed with [Flyway](https://flywaydb.org/) and includes a Python
ETL pipeline for seeding genre data.

---

## Table of Contents

- [Requirements](#requirements)
- [Project Structure](#project-structure)
- [Database Structure](#database-structure)
- [Migrations](#migrations)
- [ETL](#etl)
- [CI/CD](#cicd)
- [Permissions](#permissions)

---

## Requirements

- PostgreSQL
- Flyway 11
- Python 3.11+
- Docker (for CI/CD via GitHub Actions)

---

## Project Structure

```
musicapp-db/
├── etl/
│   ├── data/
│   │   └── json/
│   │       ├── Genres.json                 # Source genre data
│   │       └── schema/
│   │           └── Genres.schema.json      # JSON schema definition
│   ├── src/
│   │   └── Genre.etl.py                    # Genre ETL pipeline
│   ├── utils/
│   │   └── EmailService.py                 # Failure notification service
│   └── requirements.txt
├── migrations/                             # Flyway versioned migration scripts
│   ├── V1__create_base_tables.sql
│   ├── V2__create_dependent_tables.sql
│   ├── V3__create_views.sql
│   ├── V4__create_procedures.sql
│   ├── V5__redo_membership_tables.sql
│   ├── V6__update_login_proc.sql
│   ├── V7__correct_project_fk.sql
│   ├── V8__create_triggers.sql
│   ├── V9__change_triggers_to_before_update.sql
│   ├── V10__unique_genre_name.sql
│   └── V11__create_stage_objects.sql
└── schema/                                 # Reference object definitions
    ├── public/
    │   ├── functions/
    │   │   └── set_modified_utc.sql
    │   ├── procedures/
    │   │   └── login_user.sql
    │   ├── tables/
    │   │   ├── artist.sql
    │   │   ├── artist_group.sql
    │   │   ├── artist_group_membership.sql
    │   │   ├── genre.sql
    │   │   ├── genre_hierarchy.sql
    │   │   ├── producer.sql
    │   │   ├── producer_group.sql
    │   │   ├── producer_group_membership.sql
    │   │   ├── project.sql
    │   │   ├── project_type.sql
    │   │   ├── scene.sql
    │   │   ├── song.sql
    │   │   ├── streaming_service.sql
    │   │   └── user_login.sql
    │   └── views/
    │       └── vw_genre_hierarchy.sql
    └── stage/
        ├── procedures/
        │   ├── genre_hierarchy.sql
        │   └── genre_merge.sql
        ├── tables/
        │   ├── genre.sql
        │   └── genre_hierarchy.sql
        └── stage.sql
```

---

## Database Structure

The database is organized across two schemas.

### `public` schema

The main application schema. All tables include `created_utc`, `created_by`,
`modified_utc`, and `modified_by` audit columns. `modified_utc` is automatically
set by a `BEFORE UPDATE` trigger on every table.

#### Tables

| Table                       | Description                                                                       |
| --------------------------- | --------------------------------------------------------------------------------- |
| `artist`                    | Individual artists                                                                |
| `artist_group`              | Groups of artists, or a single artist acting as a group                           |
| `artist_group_membership`   | Many-to-many: artists → artist groups                                             |
| `producer`                  | Individual producers                                                              |
| `producer_group`            | Groups of producers, or a single producer acting as a group                       |
| `producer_group_membership` | Many-to-many: producers → producer groups                                         |
| `genre`                     | Music genres                                                                      |
| `genre_hierarchy`           | Parent-child relationships between genres                                         |
| `project_type`              | Lookup for musical project types (album, EP, mixtape, etc.)                       |
| `project`                   | Musical projects (albums, EPs, etc.) belonging to an artist group                 |
| `song`                      | Individual songs, linked to a project, genre, artist group, and streaming service |
| `scene`                     | Musical scenes, optionally geographic (e.g. East Coast Hip-Hop)                   |
| `streaming_service`         | Source streaming services                                                         |
| `user_login`                | Application user accounts                                                         |

#### Views

| View                 | Description                                                                                                                                 |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `vw_genre_hierarchy` | Recursive CTE that walks the full genre tree and exposes each genre's path (e.g. `Rock > Alternative > Indie`), depth level, and root genre |

#### Functions & Procedures

| Object               | Type             | Description                                                                                                                    |
| -------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `set_modified_utc()` | Trigger function | Sets `modified_utc` to the current UTC timestamp on every row update                                                           |
| `login_user()`       | Procedure        | Authenticates a user by username and hashed password, updates login stats, and returns an auth token expiration and admin flag |

### `stage` schema

Temporary landing area used by the ETL pipeline before merging into the `public`
schema.

#### Tables

| Table                   | Description                                        |
| ----------------------- | -------------------------------------------------- |
| `stage.genre`           | Staging table for incoming genre records           |
| `stage.genre_hierarchy` | Staging table for incoming genre hierarchy records |

#### Procedures

| Procedure                       | Description                                                                                                          |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `stage.genre_merge()`           | Inserts genres from stage into `public.genre` where the genre name does not already exist                            |
| `stage.genre_hierarchy_merge()` | Inserts genre hierarchy relationships from stage into `public.genre_hierarchy` where the pair does not already exist |

---

## Migrations

Migrations are managed with Flyway and follow the
`V{version}__{description}.sql` naming convention. Never edit a migration that
has already been applied.

### Migration History

| Version | Description                                                                                      |
| ------- | ------------------------------------------------------------------------------------------------ |
| V1      | Create base tables with no FK dependencies                                                       |
| V2      | Create dependent tables (FK relationships, membership tables, `project`, `song`)                 |
| V3      | Create `vw_genre_hierarchy` recursive view                                                       |
| V4      | Create `login_user` stored procedure                                                             |
| V5      | Refactor membership and hierarchy tables from composite PKs to surrogate PKs with unique indexes |
| V6      | Update `login_user` — add active user check, fix transaction logic, prevent error on login miss  |
| V7      | Fix incorrect FK reference on `project.scene_id` (was pointing to `genre`)                       |
| V8      | Add `set_modified_utc` trigger function and `AFTER UPDATE` triggers on all tables                |
| V9      | Change all update triggers from `AFTER` to `BEFORE UPDATE`                                       |
| V10     | Add unique index on `genre.genre_name`                                                           |
| V11     | Create `stage` schema, staging tables, and genre merge procedures                                |

### Running Migrations Manually

```bash
flyway -url=<FLYWAY_URL> \
       -user=<FLYWAY_USER> \
       -password=<FLYWAY_PASSWORD> \
       -locations=filesystem:musicapp-db/migrations \
       migrate
```

---

## ETL

### Genre ETL (`etl/src/Genre.etl.py`)

Loads music genre data from a nested JSON file into the database via a staging
pattern.

#### Pipeline Steps

| Step                    | Description                                                                                                                |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `connect_to_database`   | Establishes a SQLAlchemy connection to PostgreSQL and validates it                                                         |
| `extract_from_json`     | Reads `Genres.json` and recursively flattens the nested genre tree into two DataFrames: genres and hierarchy relationships |
| `truncate_stage_tables` | Clears `stage.genre` and `stage.genre_hierarchy`                                                                           |
| `load_to_stage_tables`  | Bulk-inserts both DataFrames into the stage tables via `pandas.to_sql`                                                     |
| `merge_to_final_tables` | Calls `stage.genre_merge()` and `stage.genre_hierarchy_merge()` to upsert into the final tables                            |

On failure at any step, the pipeline halts and sends a notification email with
the failing step and error message.

#### Source Data Format

`Genres.json` is an array of genre objects conforming to
`etl/data/json/schema/Genres.schema.json`. Each genre has an `id`, a `name`, and
a `parents` array (or `null` for root genres). Parent chains are nested
recursively.

```json
[
    {
        "id": 1,
        "name": "Rock",
        "parents": null
    },
    {
        "id": 2,
        "name": "Alternative",
        "parents": [{ "id": 1, "name": "Rock", "parents": null }]
    }
]
```

#### Setup

1. Install dependencies:
   ```bash
   pip install -r etl/requirements.txt
   ```

2. Create a `.env` file in the project root:
   ```
   DATABASE_CONNECTION_STRING=postgresql+psycopg2://user:password@localhost:5432/dbname
   EMAIL_FROM=you@gmail.com
   EMAIL_TO=you@gmail.com
   APP_PASSWORD=your_gmail_app_password
   ```

3. Run the ETL:
   ```bash
   python etl/src/Genre.etl.py
   ```

---

## CI/CD

Two GitHub Actions workflows run on a self-hosted runner using Flyway 11 via
Docker.

### `ci.yaml` — Validation on Pull Request

Triggers on PRs to `main` or `dev` when files under `migrations/` or `schema/`
change.

- Runs `flyway info` to display the current migration state
- Runs `flyway validate` (excluding pending migrations) to catch checksum or
  versioning issues before merge

### `schema_migration.yaml` — Migration on Push

Triggers on pushes to `main` or `dev` when files under `migrations/` change.

- Runs `flyway migrate` to apply any pending migrations
- Runs `flyway info` to confirm the resulting migration state

Both workflows target the correct database automatically — production for
`main`, development for `dev` — using branch-conditional secrets
(`FLYWAY_URL_PROD` / `FLYWAY_URL_DEV`).
