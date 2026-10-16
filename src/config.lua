-- Configure credentials in the Iguana process environment.
local function setting(name, fallback)
   local value = os.getenv(name)
   if value == nil or value == '' then return fallback end
   return value
end

local LocalUrl = setting('IGUANA_BASE_URL', 'http://localhost:6543')
local Request = {
   params = {
      username = os.getenv('IGUANA_USERNAME'),
      password = os.getenv('IGUANA_PASSWORD')
   },
   LoginCookie = ''
}

local ChannelParams = {
   ["Channel.Guid"] = ""
}

-- DB configuration
local Database = {
   DB_PATH = iguana.workingDir().."/iguana_stats.sqlite",

   CONNECT_PARAMS = {
      api = db.SQLITE,
      name = setting('IGUANA_STATS_DB_PATH', iguana.workingDir() .. '/iguana_stats.sqlite'),
      user = '',
      password = '',
      live = true
   },

   ---------------------------------------------------------
   -- SQL schema for a new metrics database
   ---------------------------------------------------------
   SERVER_CREATE = [[
   CREATE TABLE IF NOT EXISTS IguanaServersStats (
   ServerLabel TEXT PRIMARY KEY,
   TotalNumberStats INTEGER,
   MaxNumberDatabaseConnections INTEGER,
   AverageNumberDatabaseConnections INTEGER,
   MaxNumberListeningPorts INTEGER,
   AverageNumberListeningPorts REAL,
   NumberListeningPortsTotal INTEGER,
   AverageCPUPercent REAL,
   MaxCPUPercent REAL,
   AverageMemRssKB INTEGER,
   MaxMemRssKB INTEGER,
   AverageOpenFD INTEGER,
   MaxOpenFD INTEGER,
   AverageThreadCount INTEGER,
   MaxThreadCount INTEGER,
   AverageInboundTps REAL,
   MaxInboundTps REAL,
   AverageOutboundTps REAL,
   MaxOutboundTps REAL,
   AverageCountOfRunningChannel INTEGER,
   MaxCountOfRunningChannel INTEGER,
   AverageCountOfError INTEGER,
   MaxCountOfError INTEGER,
   AverageTotalCountOfRemaining INTEGER,
   MaxTotalCountOfRemaining INTEGER
)
   ]],

   CHANNEL_CREATE = [[
   CREATE TABLE IF NOT EXISTS IguanaChannelsStats (
   ChannelGUID TEXT PRIMARY KEY,
   TotalNumberStats INTEGER NOT NULL DEFAULT 1,
   AverageCountOfEnqueued REAL,
   MaxAverageCountOfEnqueued REAL,
   AverageInboundTps REAL,
   MaxInboundTps REAL,
   AverageOutboundTps REAL,
   MaxOutboundTps REAL,
   SourceType TEXT,
   DestinationType TEXT,
   ChannelName TEXT
)
   ]],
   ---------------------------------------------------------

   SERVER_SELECT = "SELECT * FROM IguanaServersStats WHERE ServerLabel = '%s'",

   SERVER_INSERT = [[
   INSERT INTO IguanaServersStats(
   ServerLabel, TotalNumberStats, MaxNumberDatabaseConnections, AverageNumberDatabaseConnections,
   MaxNumberListeningPorts, AverageNumberListeningPorts, NumberListeningPortsTotal,
   AverageCPUPercent, MaxCPUPercent, AverageMemRssKB, MaxMemRssKB,
   AverageOpenFD, MaxOpenFD, AverageThreadCount, MaxThreadCount,
   AverageInboundTps, MaxInboundTps, AverageOutboundTps, MaxOutboundTps,
   AverageCountOfRunningChannel, MaxCountOfRunningChannel,
   AverageCountOfError, MaxCountOfError, AverageTotalCountOfRemaining, MaxTotalCountOfRemaining
) VALUES (
   '%s', 1, %d, %f, %d, %f, %d, %f, %f, %d, %d, %d, %d, %d, %d, %f, %f, %f, %f, %d, %d, %d, %d, %d, %d
)
   ]],

   SERVER_UPDATE = [[
   UPDATE IguanaServersStats SET
   TotalNumberStats = TotalNumberStats + 1,
   AverageNumberDatabaseConnections = %f,
   MaxNumberDatabaseConnections = MAX(MaxNumberDatabaseConnections, %f),
   AverageInboundTps = %f,
   MaxInboundTps = MAX(MaxInboundTps, %f),
   AverageOutboundTps = %f,
   MaxOutboundTps = MAX(MaxOutboundTps, %f),
   AverageCPUPercent = %f,
   MaxCPUPercent = MAX(MaxCPUPercent, %f),
   AverageMemRssKB = %f,
   MaxMemRssKB = MAX(MaxMemRssKB, %f),
   AverageOpenFD = %f,
   MaxOpenFD = MAX(MaxOpenFD, %f),
   AverageThreadCount = %f,
   MaxThreadCount = MAX(MaxThreadCount, %f),
   AverageCountOfRunningChannel = %f,
   MaxCountOfRunningChannel = MAX(MaxCountOfRunningChannel, %f),
   AverageCountOfError = %f,
   MaxCountOfError = MAX(MaxCountOfError, %f),
   AverageTotalCountOfRemaining = %f,
   MaxTotalCountOfRemaining = MAX(MaxTotalCountOfRemaining, %f)
   WHERE ServerLabel = '%s'
   ]],

   CHANNEL_SELECT = "SELECT * FROM IguanaChannelsStats WHERE ChannelGUID = '%s'",

   CHANNEL_INSERT = [[
   INSERT INTO IguanaChannelsStats(
   ChannelGUID, TotalNumberStats, AverageCountOfEnqueued, MaxAverageCountOfEnqueued,
   AverageInboundTps, MaxInboundTps,
   AverageOutboundTps, MaxOutboundTps,
   SourceType, DestinationType, ChannelName
) VALUES (
   '%s', 1, %f, %f, %f, %f, %f, %f, '%s', '%s', '%s'
)
   ]],

   CHANNEL_UPDATE = [[
   UPDATE IguanaChannelsStats SET
   TotalNumberStats = TotalNumberStats + 1,
   AverageCountOfEnqueued = %f,
   MaxAverageCountOfEnqueued = MAX(MaxAverageCountOfEnqueued, %f),
   AverageInboundTps = %f,
   MaxInboundTps = MAX(MaxInboundTps, %f),
   AverageOutboundTps = %f,
   MaxOutboundTps = MAX(MaxOutboundTps, %f),
   SourceType = '%s',
   DestinationType = '%s',
   ChannelName = '%s'
   WHERE ChannelGUID = '%s'
   ]],

   CLEAR_SERVERS_STATS = [[DELETE FROM IguanaServersStats]],
   CLEAR_CHANNELS_STATS = [[DELETE FROM IguanaChannelsStats]]

}

local function defaultParams()
   return {
      include_machine_info = "true",
      include_remote_servers = "true",
      ChannelFilterString = "",
      MinChannelRowIndex = 0,
      MaxChannelRowIndex = 100,
      SortOrder = "Asc",
      SortColumn = "Name",
      SelectedServers = "",
      refresh = 1,
      AutomaticRequest = 1
   }
end

return {
   LocalUrl = LocalUrl,
   Request = Request,
   DefaultParams = defaultParams,
   ChannelParams = ChannelParams,
   Database = Database
}
