-- HTTP transport only: response parsing and metric extraction live in main.lua.

local SessionAuth = require "sessionAuth"
local config       = require "config"

local DashboardClient = {}
local ChannelClient   = {}

-- Shared Session Check
-- Reuse a stored session cookie or perform login when none is available.
-- This checks local cookie presence; it does not validate expiry with the server.
local function ensureValidSession(Request, LocalUrl)
   if not SessionAuth.isSessionValid(Request) then
      return SessionAuth.doLogin(Request, LocalUrl)
   end
   return true
end

------------------------------------------------------------
-- DASHBOARD FETCH
------------------------------------------------------------
-- POST dashboard selection parameters and return body, HTTP status, and headers.
-- On login failure, return nil, 0, nil, and an explanatory error string.
function DashboardClient.fetch(Request, LocalUrl, Params)
   Params = Params or config.DefaultParams()

   -- Ensure session
   if not ensureValidSession(Request, LocalUrl) then
      return nil, 0, nil, "unable to obtain session"
   end

   local Status, Code, Headers = net.http.post{
      url = LocalUrl .. "/dashboard_data",
      parameters = Params,
      headers = { Cookie = Request.LoginCookie },
      live = true
   }

   return Status, Code, Headers
end

------------------------------------------------------------
-- CHANNEL FETCH
-- Fetch data from specific channel(s)
-- Params example: { channel = "MyChannel", AutomaticRequest = 1 }
------------------------------------------------------------
-- POST channel-specific parameters to retrieve detailed status for a selected channel.
-- Returns the same response tuple as Dashboard.fetch; the caller parses JSON.
function ChannelClient.fetch(Request, LocalUrl, Params)
   Params = Params or {}

   -- Ensure session
   if not ensureValidSession(Request, LocalUrl) then
      return nil, 0, nil, "unable to obtain session"
   end

   local Status, Code, Headers = net.http.post{
      url = LocalUrl .. "/channel_status_data.html",
      parameters = Params,
      headers = { Cookie = Request.LoginCookie },
      live = true
   }

   return Status, Code, Headers
end

-- Export both clients
return {
   Dashboard = DashboardClient,
   Channel   = ChannelClient
}
