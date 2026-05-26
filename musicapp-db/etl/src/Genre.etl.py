import json
import os
import logging
import traceback

import pandas as pd
import sqlalchemy
from sqlalchemy import create_engine, text
from dotenv import load_dotenv


# -----------------------------------
# Logging
# -----------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

logger = logging.getLogger(__name__)


class GenreETLPipeline:
    def __init__(self, db_connection_string):
        self.db_connection_string = db_connection_string
        self.engine = None
        self.genre_df = None
        self.hierarchy_df = None

    # -----------------------------------
    # Database Connection
    # -----------------------------------
    def connect_to_database(self):
        """
        Connect to PostgreSQL database
        Example:
        postgresql+psycopg2://user:password@localhost:5432/musicdb
        """
        try:
            self.engine = create_engine(
                self.db_connection_string
            )

            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))

            logger.info("Connected to PostgreSQL successfully")
            return True

        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            return False

    # -----------------------------------
    # JSON Extraction
    # -----------------------------------
    def extract_from_json(self, json_file_path):
        """
        Extract Genre + GenreHierarchy
        from array-based Genres JSON
        """

        try:
            with open(
                json_file_path,
                "r",
                encoding="utf-8"
            ) as file:
                genres = json.load(file)

            genre_rows = {}
            relationship_rows = set()

            def register_genre(genre_obj):
                """
                Add unique genre by GenreName
                """
                genre_name = genre_obj["name"]
                genre_id = genre_obj.get("id")

                if genre_name not in genre_rows:
                    genre_rows[genre_name] = {
                        "GenreId": genre_id,
                        "GenreName": genre_name
                    }

                return genre_id, genre_name

            def traverse_parents(child_obj):
                """
                Recursively walk parent chain
                and add hierarchy relationships
                """

                child_id, child_name = register_genre(
                    child_obj
                )

                parents = child_obj.get("parents")

                if parents is None:
                    relationship_rows.add(
                        (child_id, -1)
                    )
                    return

                for parent_obj in parents:
                    parent_id, parent_name = register_genre(
                        parent_obj
                    )

                    relationship_rows.add(
                        (child_id, parent_id)
                    )

                    traverse_parents(parent_obj)

            for genre in genres:
                genre_id, genre_name = register_genre(
                    genre
                )

                parents = genre.get("parents")

                if parents is None:
                    relationship_rows.add(
                        (genre_id, -1)
                    )

                else:
                    for parent_obj in parents:
                        parent_id, parent_name = register_genre(
                            parent_obj
                        )

                        relationship_rows.add(
                            (genre_id, parent_id)
                        )

                        traverse_parents(parent_obj)

            self.genre_df = pd.DataFrame(
                list(genre_rows.values())
            )

            self.hierarchy_df = pd.DataFrame(
                list(relationship_rows),
                columns=[
                    "GenreId",
                    "ParentGenreId"
                ]
            )

            logger.info(
                f"Extracted {len(self.genre_df)} genres"
            )

            logger.info(
                f"Extracted {len(self.hierarchy_df)} hierarchy rows"
            )

            return True

        except Exception as e:
            logger.error(
                f"JSON extraction failed: {e}"
            )
            logger.error(traceback.format_exc())
            return False

    # -----------------------------------
    # Stage Table Cleanup
    # -----------------------------------
    def truncate_stage_tables(self):
        try:
            with self.engine.begin() as conn:
                conn.execute(
                    text(
                        'TRUNCATE TABLE stage."Genre"'
                    )
                )

                conn.execute(
                    text(
                        'TRUNCATE TABLE stage."GenreHierarchy"'
                    )
                )

            logger.info(
                "Truncated stage tables successfully"
            )

            return True

        except Exception as e:
            logger.error(
                f"Failed truncating stage tables: {e}"
            )
            return False

    # -----------------------------------
    # Pandas → Postgres
    # -----------------------------------
    def load_to_stage_tables(self):
        try:
            if self.genre_df is None:
                raise Exception(
                    "genre_df not loaded"
                )

            if self.hierarchy_df is None:
                raise Exception(
                    "hierarchy_df not loaded"
                )

            self.genre_df.to_sql(
                name="Genre",
                schema="stage",
                con=self.engine,
                if_exists="append",
                index=False,
                method="multi"
            )

            logger.info(
                f"Loaded {len(self.genre_df)} rows into stage.Genre"
            )

            self.hierarchy_df.to_sql(
                name="GenreHierarchy",
                schema="stage",
                con=self.engine,
                if_exists="append",
                index=False,
                method="multi"
            )

            logger.info(
                f"Loaded {len(self.hierarchy_df)} rows into stage.GenreHierarchy"
            )

            return True

        except Exception as e:
            logger.error(
                f"Failed loading stage tables: {e}"
            )
            logger.error(traceback.format_exc())
            return False

    # -----------------------------------
    # Merge Stage → Final
    # -----------------------------------
    def merge_to_final_tables(self):
        """
        Assumes Postgres merge stored procedures exist:
        stage.genre_merge()
        stage.genre_hierarchy_merge()
        """

        try:
            with self.engine.begin() as conn:

                logger.info(
                    "Merging stage.Genre..."
                )

                conn.execute(
                    text(
                        "CALL stage.genre_merge();"
                    )
                )

                logger.info(
                    "Merging stage.GenreHierarchy..."
                )

                conn.execute(
                    text(
                        "CALL stage.genre_hierarchy_merge();"
                    )
                )

            logger.info(
                "Merge completed successfully"
            )

            return True

        except Exception as e:
            logger.error(
                f"Merge failed: {e}"
            )
            logger.error(traceback.format_exc())
            return False

    # -----------------------------------
    # Run ETL
    # -----------------------------------
    def run_etl(self, json_file_path):
        logger.info(
            "Starting Genre ETL..."
        )

        if not self.connect_to_database():
            return False

        if not self.extract_from_json(
            json_file_path
        ):
            return False

        if not self.truncate_stage_tables():
            return False

        if not self.load_to_stage_tables():
            return False

        if not self.merge_to_final_tables():
            return False

        logger.info(
            "Genre ETL completed successfully"
        )

        return True


# -----------------------------------
# Main
# -----------------------------------
if __name__ == "__main__":
    load_dotenv()

    DATABASE_CONNECTION_STRING = os.getenv(
        "DATABASE_CONNECTION_STRING"
    )

    JSON_PATH = os.path.join(
        os.getcwd(),
        "MusicDB_ETL",
        "Data",
        "Genres.with-parents-array.json"
    )

    etl = GenreETLPipeline(
        db_connection_string=DATABASE_CONNECTION_STRING
    )

    success = etl.run_etl(JSON_PATH)

    if success:
        print("ETL completed successfully")
    else:
        print("ETL failed")