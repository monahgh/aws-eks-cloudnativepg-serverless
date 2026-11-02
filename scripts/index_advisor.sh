#!/usr/bin/env bash
# AI-assisted index advisor (scaffold).
# Dumps the slowest statements from pg_stat_statements and prints a prompt you can
# paste into an LLM. Usage: PGHOST=... PGUSER=... PGDATABASE=... ./index_advisor.sh
# Credentials come from the standard PG* environment variables / ~/.pgpass.
set -euo pipefail

TOP_N="${TOP_N:-10}"

QUERIES="$(psql -X -At -F $'\t' -c "
  SELECT round(mean_exec_time::numeric, 2), calls, left(query, 300)
  FROM pg_stat_statements
  ORDER BY mean_exec_time DESC
  LIMIT ${TOP_N};")"

cat <<EOF
You are a PostgreSQL performance expert. For each statement below
(mean_ms, calls, query), suggest at most one index, explain the trade-off, and flag
statements where an index will not help.

${QUERIES}
EOF
