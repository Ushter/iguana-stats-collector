-- Collection pipeline: dashboard API -> normalized observations -> SQLite aggregates.

-- The main function is the first function called from Iguana.
local api = require "dashboard_client"
local config = require "config"
local DBstore = require "statsSqlite"

-- Convert dashboard numbers or formatted positive metric strings into numbers.
-- Removes comma separators; absent/unrecognized values become zero.
-- This helper is for nonnegative dashboard counters, not general signed-number parsing.
local function toNumber(value)
   if not value then return 0 end
   if type(value) == "number" then return value end
   return tonumber(tostring(value):gsub(",", ""):match("[%d%.]+")) or 0
end

-- Fetch a dashboard snapshot, then request details for each returned channel.
-- Returns two Lua arrays: normalized server observations and channel observations.
-- A dashboard failure aborts the cycle; a single failed channel request is skipped.
local function collect()

   -- Fetch dashboard-level details
   local Response, Code, Headers, Err = api.Dashboard.fetch(config.Request, config.LocalUrl, config.DefaultParams())
   if Code ~= 200 then
      iguana.logDebug("Iguana Dashboard fetch error: " .. (Err or "Unknown error"))
      error("Dashboard request failed")
   end

   local ServersData = {}
   -- Decode the dashboard response before building database-ready observations.
   local parseRep = json.parse{data = Response}

   --SERVER-LEVEL INFO
   for i = 1, #parseRep.Servers do

      local server = parseRep.Servers[i]

      -- Map API field names to the collector storage contract.
      -- MemRssKB is resident memory in kilobytes; TPS is messages per second.
      local sData = {
         ServerLabel = server.ServerLabel,
         MaxNumberDatabaseConnections = server.DashboardData.NumberDatabaseConnections,
         OutboundTps = toNumber(server.DashboardData.OutboundTps),
         InboundTps = toNumber(server.DashboardData.InboundTps),
         CPUPercent = server.DashboardData.MachineInfo.CPUPercent,
         OpenFD = server.DashboardData.MachineInfo.OpenFD,
         ThreadCount = server.DashboardData.MachineInfo.ThreadCount,
         MemRssKB = server.DashboardData.MachineInfo.MemRssKB,
         NumberListeningPortsTotal = server.DashboardData.NumberListeningPortsTotal,
         CountOfError = server.DashboardData.CountOfError,
         CountOfRunningChannel = server.DashboardData.CountOfRunningChannel,
         TotalCountOfRemaining = server.DashboardData.TotalCountOfRemaining
      }
      table.insert(ServersData, sData)

   end

   local ChannelsData = {}
   --CHANNEL-LEVEL INFO
   for j = 1, #parseRep.Channels do
      local channel = parseRep.Channels[j].Channel
      -- Set channel-specific params for API fetch
      local CResponse, CCode, CHeaders, CErr = api.Channel.fetch(
         config.Request,
         config.LocalUrl,
         {["Channel.Guid"] = channel.Guid}
      )

      if CCode ~= 200 then
         iguana.logDebug("Iguana Channel fetch error: " .. (CErr or "Unknown error"))
      else
         local CHNparserep = json.parse{data = CResponse}
         -- Combine dashboard channel identity with the detailed throughput response.
         -- Enqueued and remaining are distinct metrics; do not substitute one for the other.
         local cData = {
            ChannelName =  parseRep.Channels[j].Channel.Name,
            ChannelGuid = channel.Guid,
            SourceType = channel.Source.Name,
            DestinationType = channel.Destination.Name,
            OutboundTps = toNumber(CHNparserep.OutboundTps),
            InboundTps = toNumber(CHNparserep.InboundTps),
            CountOfEnqueued = toNumber(channel.CountOfEnqueued),
            CountOfRemaining = toNumber(channel.CountOfRemaining) or 0

         }
         table.insert(ChannelsData, cData)
      end
   end

   return ServersData, ChannelsData
end

-- Iguana entry point for one collection cycle. Fetch first, then open SQLite.
-- Protect the storage call so its connection closes even if an insert/update fails.
function main()
   local servers, channels = collect()
   local connection = db.connect(config.Database.CONNECT_PARAMS)
   -- pcall captures storage errors without bypassing connection cleanup.
   -- These writes are not wrapped in a transaction; an error can leave a partial cycle.
   local ok, err = pcall(DBstore.statsSqlite, servers, channels, connection)
   connection:close()
   if not ok then
      error("Unable to save collected statistics")
   end
end
