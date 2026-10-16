-- Persistence layer. SQL layouts live in config.lua; numeric aggregation lives in Calculate.lua.

local DB = {}
local config = require "config"
local calculate = require "Calculate"

-- Create tables when collecting into a new database.
-- Ensure both aggregate tables exist on the supplied open connection.
-- Safe to call repeatedly for a fresh-compatible schema; does not migrate old columns.
local function DBExists(Conn)
   -- Run table creation SQL
   Conn:execute{sql = config.Database.SERVER_CREATE, live = true}
   Conn:execute{sql = config.Database.CHANNEL_CREATE, live = true}

   iguana.logInfo("SQLite DB created with required tables.")
end

-- Reset collected statistics when explicitly configured.
-- Delete saved server and channel observations for an explicitly requested reset.
-- Leaves table definitions intact; this branch does not collect a replacement sample.
local function clearStatsDB(Conn)
   iguana.logInfo("Clearing all stats from the database...")

   Conn:execute{sql = config.Database.CLEAR_SERVERS_STATS, live = true}
   Conn:execute{sql = config.Database.CLEAR_CHANNELS_STATS, live = true}

   iguana.logInfo("Database cleared successfully.")
end

-- Escape SQL helper
-- Double apostrophes before inserting string values into quoted SQL placeholders.
-- Other values are converted to text. Use only with these fixed SQL templates.
local function escapeSql(value)
   if type(value) == "string" then
      return value:gsub("'", "''")
   end
   return tostring(value or 0)
end

-- SERVER STATS
-- Save each server observation using its label as the primary key.
-- New rows seed their mean and maximum from the first sample. Existing rows
-- combine their previous mean/sample count with the incoming observation.
local function IguanaServersStats(Servers, Conn)

   for _, s in ipairs(Servers) do
      local row = Conn:query{
         sql = string.format(config.Database.SERVER_SELECT, escapeSql(s.ServerLabel))
      }

      if #row == 0 then

         -- Insert new server row
         local sqlInsert = string.format(config.Database.SERVER_INSERT,
            escapeSql(s.ServerLabel),

            s.MaxNumberDatabaseConnections or 0,
            s.MaxNumberDatabaseConnections or 0,
            s.NumberListeningPortsTotal or 0, s.NumberListeningPortsTotal or 0, s.NumberListeningPortsTotal or 0,

            s.CPUPercent or 0, s.CPUPercent or 0,
            s.MemRssKB or 0, s.MemRssKB or 0,
            s.OpenFD or 0, s.OpenFD or 0,
            s.ThreadCount or 0, s.ThreadCount or 0,

            s.InboundTps or 0, s.InboundTps or 0,
            s.OutboundTps or 0, s.OutboundTps or 0,

            s.CountOfRunningChannel or 0, s.CountOfRunningChannel or 0,
            s.CountOfError or 0, s.CountOfError or 0,
            s.TotalCountOfRemaining or 0, s.TotalCountOfRemaining or 0
         )

         Conn:execute{sql = sqlInsert, live = true}

      else

         -- Update with NEW averages and NEW max values
         local old = row[1]
         -- Compute means in Lua; the SQL update advances TotalNumberStats once per sample.
         local avgs = calculate.computeServerAverages(old, s)

         local sqlUpdate = string.format(config.Database.SERVER_UPDATE,

            avgs.AverageNumberDatabaseConnections,
            calculate.computeMax(old.MaxNumberDatabaseConnections, s.MaxNumberDatabaseConnections),
            avgs.AverageInboundTps,
            calculate.computeMax(old.MaxInboundTps, s.InboundTps),

            avgs.AverageOutboundTps,
            calculate.computeMax(old.MaxOutboundTps, s.OutboundTps),

            avgs.AverageCPUPercent,
            calculate.computeMax(old.MaxCPUPercent, s.CPUPercent),

            avgs.AverageMemRssKB,
            calculate.computeMax(old.MaxMemRssKB, s.MemRssKB),

            avgs.AverageOpenFD,
            calculate.computeMax(old.MaxOpenFD, s.OpenFD),

            avgs.AverageThreadCount,
            calculate.computeMax(old.MaxThreadCount, s.ThreadCount),

            avgs.AverageCountOfRunningChannel,
            calculate.computeMax(old.MaxCountOfRunningChannel, s.CountOfRunningChannel),

            avgs.AverageCountOfError,
            calculate.computeMax(old.MaxCountOfError, s.CountOfError),

            avgs.AverageTotalCountOfRemaining,
            calculate.computeMax(old.MaxTotalCountOfRemaining, s.TotalCountOfRemaining),

            escapeSql(s.ServerLabel)
         )

         Conn:execute{sql = sqlUpdate, live = true}
      end
   end
end

-- CHANNEL STATS
-- Insert or update one aggregate row per channel GUID.
-- Preserve historical maxima while refreshing channel labels and running averages.
local function IguanaChannelStats(Channels, Conn)

   for _, c in ipairs(Channels) do
      local row = Conn:query{
         sql = string.format(config.Database.CHANNEL_SELECT, escapeSql(c.ChannelGuid))
      }

      if #row == 0 then
         local sqlInsert = string.format(config.Database.CHANNEL_INSERT,
            escapeSql(c.ChannelGuid),

            c.CountOfEnqueued or 0, c.CountOfEnqueued or 0,
            c.InboundTps or 0, c.InboundTps or 0,
            c.OutboundTps or 0, c.OutboundTps or 0,

            escapeSql(c.SourceType or ""),
            escapeSql(c.DestinationType or ""),
            escapeSql(c.ChannelName or "")
         )

         Conn:execute{sql = sqlInsert, live = true}
      else

         -- Update channel averages + max
         local old = row[1]
         -- Use the existing observation count before the UPDATE increments it.
         local avgs = calculate.computeChannelAverages(old, c)

         local sqlUpdate = string.format(config.Database.CHANNEL_UPDATE,

            avgs.AverageCountOfEnqueued,
            calculate.computeMax(old.MaxAverageCountOfEnqueued, c.CountOfEnqueued),

            avgs.AverageInboundTps,
            calculate.computeMax(old.MaxInboundTps, c.InboundTps),

            avgs.AverageOutboundTps,
            calculate.computeMax(old.MaxOutboundTps, c.OutboundTps),

            escapeSql(c.SourceType or ""),
            escapeSql(c.DestinationType or ""),
            escapeSql(c.ChannelName or ""),
            escapeSql(c.ChannelGuid)
         )

         Conn:execute{sql = sqlUpdate, live = true}
      end
   end
end

-- Public storage entry point. Initialize tables, then either clear statistics
-- or aggregate this cycle. The caller owns the connection and must close it.
function DB.statsSqlite(ServersData , ChannelsData, Conn)
   DBExists(Conn)

   -- Reset is opt-in and case-insensitive; an unset variable defaults to ordinary collection.
   if (os.getenv('STAT_DB_RESET') or 'false'):lower() == "true" then
      clearStatsDB(Conn)
   else
      IguanaServersStats(ServersData, Conn)
      IguanaChannelStats(ChannelsData, Conn)
   end
end

return DB
