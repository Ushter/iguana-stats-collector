-- The main function is the first function called from Iguana.
local api = require "dashboard_client"
local config = require "config"
local DBstore = require "statsSqlite"

local function toNumber(value)
   if not value then return 0 end
   if type(value) == "number" then return value end
   return tonumber(tostring(value):gsub(",", ""):match("[%d%.]+")) or 0
end

local function collect()

   -- Fetch dashboard-level details
   local Response, Code, Headers, Err = api.Dashboard.fetch(config.Request, config.LocalUrl, config.DefaultParams())
   if Code ~= 200 then
      iguana.logDebug("Iguana Dashboard fetch error: " .. (Err or "Unknown error"))
      error("Dashboard request failed")
   end

   local ServersData = {}
   local parseRep = json.parse{data = Response}

   --SERVER-LEVEL INFO
   for i = 1, #parseRep.Servers do

      local server = parseRep.Servers[i]

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

function main()
   local servers, channels = collect()
   local connection = db.connect(config.Database.CONNECT_PARAMS)
   local ok, err = pcall(DBstore.statsSqlite, servers, channels, connection)
   connection:close()
   if not ok then
      error("Unable to save collected statistics")
   end
end
