DROP DATABASE IF EXISTS games;
DROP ROLE IF EXISTS games;
CREATE USER games PASSWORD 'games';
CREATE DATABASE games OWNER games;

\connect games

CREATE EXTENSION IF NOT EXISTS file_fdw;
GRANT ALL ON FOREIGN DATA WRAPPER file_fdw TO games;
