#!/bin/bash
# Creates the two databases Synapse and MAS need, with the collation Synapse
# strictly requires (C locale). Runs once on first Postgres init.
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-SQL
  CREATE DATABASE synapse
    ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE template0;
  CREATE DATABASE mas
    ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE template0;
SQL
