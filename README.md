# Iguana Stats Collector

Lua collector that reads Iguana dashboard and channel metrics and stores running averages and maxima in SQLite.

## What it demonstrates

Session authentication, API integration, modular Lua, SQL storage, and operational monitoring. Metrics cover CPU, memory, database connections, throughput, errors, queues, and channel status. This repository contains the collector contribution only.

## Workflow

1. Authenticate to the Iguana dashboard.
2. Retrieve server metrics and details for the returned channels.
3. Create SQLite tables if necessary.
4. Insert a first observation or update running averages and maxima.

## Setup

Requires a compatible Iguana 6 runtime providing `net.http`, `json`, `db`, and `iguana`. Add the files under `src/` to an Iguana Translator project with `main.lua` as its entry point. Supply the process environment variables in `.env.example`; the code does not load that file automatically. Schedule collection using the Iguana channel configuration.

Use a fresh SQLite database for this portfolio version: channel rows now include `TotalNumberStats`. Existing recovered databases need a separate schema migration. Only point `STAT_DB_RESET=true` at a disposable metrics database; it clears accumulated statistics.

## Cleanup and validation

Removed stored credentials and private paths. Corrected default-parameter naming, channel sample counts, memory metric naming, unset reset-variable handling, and database cleanup after storage failures. Removed the previous mapping that treated remaining queue count as enqueued count. A missing enqueued field currently becomes zero; verify the response field against your deployment before using that metric.

Local mock tests exercise averages and failure cleanup. Live API integration has not been tested. Dashboard selection is currently limited to 100 channel rows; pagination and expired-session retries remain future work. Listening-port aggregates retain the original initial-observation behavior.

## Files

- `src/main.lua`: collection workflow.
- `src/dashboard_client.lua`, `src/sessionAuth.lua`: API requests and session handling.
- `src/statsSqlite.lua`, `src/config.lua`: storage and schema.
- `src/Calculate.lua`: running averages and maxima.

Recovered project by Meer Ushter, cleaned for portfolio presentation. No companion viewer, original databases, logs, or messages are included.

## Run local unit tests

From this repository directory, use Lua 5.4:

```sh
lua tests/averages_test.lua
lua tests/cleanup_test.lua
```

These tests use synthetic fixtures and mocked Iguana APIs. They do not replace testing inside Iguana.
