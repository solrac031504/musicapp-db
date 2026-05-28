import json
import os
import logging
import traceback
from typing import TypedDict, Optional
from dataclasses import dataclass

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from dotenv import load_dotenv

from utils.EmailService import EmailService

# -----------------------------------
# Logging
# -----------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

logger = logging.getLogger(__name__)


# -----------------------------------
# TypedDicts
# -----------------------------------
@dataclass
class GenreObject(TypedDict, total=False):
    id: int
    name: str
    parents: list["GenreObject"]


@dataclass
class GenreRow(TypedDict):
    genre_id: int
    genre_name: str


@dataclass
class HierarchyRow(TypedDict):
    genre_id: int
    parent_genre_id: int


# -----------------------------------
# Pipeline
# -----------------------------------
class GenreETLPipeline:
    def __init__(self, db_connection_string: str) -> None:
        self.db_connection_string: str = db_connection_string
        self.engine: Optional[Engine] = None
        self.genre_df: Optional[pd.DataFrame] = None
        self.hierarchy_df: Optional[pd.DataFrame] = None
        self._email_service = EmailService()
        self._package_name = "GenreETLPipeline"

    # -----------------------------------
    # Database Connection
    # -----------------------------------
    def connect_to_database(self) -> bool:
        """
        Connect to PostgreSQL database.
        Example connection string:
        postgresql+psycopg2://user:password@localhost:5432/dbname
        """
        self._step = "connect_to_database"
        try:
            self.engine = create_engine(self.db_connection_string)

            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))

            logger.info("Connected to PostgreSQL successfully")
            return True

        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            self._email_service.send_failure_email(
                package_name=self._package_name,
                step=self._step,
                error=str(e)
            )
            return False

    # -----------------------------------
    # JSON Extraction
    # -----------------------------------
    def extract_from_json(self, json_file_path: str) -> bool:
        """
        Extract Genre + GenreHierarchy
        from array-based Genres JSON.
        """
        self._step = "extract_from_json"
        try:
            with open(json_file_path, "r", encoding="utf-8") as file:
                genres: list[GenreObject] = json.load(file)

            genre_rows: dict[str, GenreRow] = {}
            relationship_rows: set[tuple[int, int]] = set()

            def register_genre(genre_obj: GenreObject) -> tuple[int, str]:
                """Add unique genre by GenreName."""
                genre_name: str = genre_obj.get("name") or "Unknown"
                genre_id: int = genre_obj.get("id") or -1

                if genre_name not in genre_rows:
                    genre_rows[genre_name] = GenreRow(
                        genre_id=genre_id,
                        genre_name=genre_name,
                    )

                return genre_id, genre_name

            def traverse_parents(child_obj: GenreObject) -> None:
                """Recursively walk parent chain and add hierarchy relationships."""
                child_id, _ = register_genre(child_obj)
                parents: Optional[list[GenreObject]] = child_obj.get("parents")

                if parents is None:
                    relationship_rows.add((child_id, -1))
                    return

                for parent_obj in parents:
                    parent_id, _ = register_genre(parent_obj)
                    relationship_rows.add((child_id, parent_id))
                    traverse_parents(parent_obj)

            for genre in genres:
                genre_id, _ = register_genre(genre)
                parents: Optional[list[GenreObject]] = genre.get("parents")

                if parents is None:
                    relationship_rows.add((genre_id, -1))
                else:
                    for parent_obj in parents:
                        parent_id, _ = register_genre(parent_obj)
                        relationship_rows.add((genre_id, parent_id))
                        traverse_parents(parent_obj)

            self.genre_df = pd.DataFrame(list(genre_rows.values()))
            self.hierarchy_df = pd.DataFrame(
                list(relationship_rows),
                columns=["genre_id", "parent_genre_id"],
            )

            logger.info(f"Extracted {len(self.genre_df)} genres")
            logger.info(f"Extracted {len(self.hierarchy_df)} hierarchy rows")
            return True

        except (OSError, json.JSONDecodeError) as e:
            logger.error(f"JSON extraction failed: {e}")
            logger.error(traceback.format_exc())
            self._email_service.send_failure_email(
                package_name=self._package_name,
                step=self._step,
                error=str(e)
            )
            return False

        except KeyError as e:
            logger.error(f"Missing required field in genre data: {e}")
            logger.error(traceback.format_exc())
            self._email_service.send_failure_email(
                package_name=self._package_name,
                step=self._step,
                error=str(e)
            )
            return False

    # -----------------------------------
    # Stage Table Cleanup
    # -----------------------------------
    def truncate_stage_tables(self) -> bool:
        self._step = "truncate_stage_tables"
        if self.engine is None:
            logger.error("Database engine is not initialized")
            return False

        try:
            with self.engine.begin() as conn:
                conn.execute(text('TRUNCATE TABLE stage."genre"'))
                conn.execute(text('TRUNCATE TABLE stage."genre_hierarchy"'))

            logger.info("Truncated stage tables successfully")
            return True

        except Exception as e:
            logger.error(f"Failed truncating stage tables: {e}")
            self._email_service.send_failure_email(
                package_name=self._package_name,
                step=self._step,
                error=str(e)
            )
            return False

    # -----------------------------------
    # Pandas → Postgres
    # -----------------------------------
    def load_to_stage_tables(self) -> bool:
        self._step = "load_to_stage_tables"
        if self.engine is None:
            logger.error("Database engine is not initialized")
            return False

        if self.genre_df is None:
            logger.error("genre_df not loaded")
            return False

        if self.hierarchy_df is None:
            logger.error("hierarchy_df not loaded")
            return False

        try:
            self.genre_df.to_sql(
                name="genre",
                schema="stage",
                con=self.engine,
                if_exists="append",
                index=False,
                method="multi",
            )

            logger.info(f"Loaded {len(self.genre_df)} rows into stage.genre")

            self.hierarchy_df.to_sql(
                name="genre_hierarchy",
                schema="stage",
                con=self.engine,
                if_exists="append",
                index=False,
                method="multi",
            )

            logger.info(f"Loaded {len(self.hierarchy_df)} rows into stage.genre_hierarchy")
            return True

        except Exception as e:
            logger.error(f"Failed loading stage tables: {e}")
            logger.error(traceback.format_exc())
            self._email_service.send_failure_email(
                package_name=self._package_name,
                step=self._step,
                error=str(e)
            )
            return False

    # -----------------------------------
    # Merge Stage → Final
    # -----------------------------------
    def merge_to_final_tables(self) -> bool:
        """
        Assumes Postgres merge stored procedures exist:
        stage.genre_merge()
        stage.genre_hierarchy_merge()
        """
        self._step = "merge_to_final_tables"
        if self.engine is None:
            logger.error("Database engine is not initialized")
            return False

        try:
            with self.engine.begin() as conn:
                logger.info("Merging stage.Genre...")
                conn.execute(text("CALL stage.genre_merge();"))

                logger.info("Merging stage.GenreHierarchy...")
                conn.execute(text("CALL stage.genre_hierarchy_merge();"))

            logger.info("Merge completed successfully")
            return True

        except Exception as e:
            logger.error(f"Merge failed: {e}")
            logger.error(traceback.format_exc())
            self._email_service.send_failure_email(
                package_name=self._package_name,
                step=self._step,
                error=str(e)
            )
            return False

    # -----------------------------------
    # Run ETL
    # -----------------------------------
    def run_etl(self, json_file_path: str) -> bool:
        self._step = "run_etl"
        logger.info("Starting Genre ETL...")

        steps: list[tuple[str, bool]] = [
            ("connect_to_database", self.connect_to_database()),
            ("extract_from_json", self.extract_from_json(json_file_path)),
            ("truncate_stage_tables", self.truncate_stage_tables()),
            ("load_to_stage_tables", self.load_to_stage_tables()),
            ("merge_to_final_tables", self.merge_to_final_tables()),
        ]

        for step_name, result in steps:
            if not result:
                logger.error(f"ETL aborted at step: {step_name}")
                return False

        logger.info("Genre ETL completed successfully")
        return True


# -----------------------------------
# Main
# -----------------------------------
if __name__ == "__main__":
    load_dotenv()

    db_connection_string: Optional[str] = os.getenv("DATABASE_CONNECTION_STRING")

    if not db_connection_string:
        raise EnvironmentError(
            "DATABASE_CONNECTION_STRING is not set in environment"
        )

    json_path: str = os.path.join(
        os.getcwd(),
        "etl",
        "data",
        "Genres.json",
    )

    etl = GenreETLPipeline(db_connection_string=db_connection_string)
    success: bool = etl.run_etl(json_path)

    if success:
        print("ETL completed successfully")
    else:
        print("ETL failed")
