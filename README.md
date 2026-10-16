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

The SQLite schema includes `TotalNumberStats` for running averages. `STAT_DB_RESET=true` clears accumulated statistics.

## Files

- `src/main.lua`: collection workflow.
- `src/dashboard_client.lua`, `src/sessionAuth.lua`: API requests and session handling.
- `src/statsSqlite.lua`, `src/config.lua`: storage and schema.
- `src/Calculate.lua`: running averages and maxima.

## Run local unit tests

From this repository directory, use Lua 5.4:

```sh
lua tests/averages_test.lua
lua tests/cleanup_test.lua
```

These tests use synthetic fixtures and mocked Iguana APIs. They do not replace testing inside Iguana.
