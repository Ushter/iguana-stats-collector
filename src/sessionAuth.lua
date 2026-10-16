local SessionAuth = {}

-- Check that both credential fields are present and nonempty before attempting login.
function SessionAuth.haveCredentials(Request)
   return Request.params and Request.params.username ~= nil and
          Request.params.password ~= nil and
          Request.params.username ~= "" and Request.params.password ~= ""
end

-- Return only the username/password parameters expected by the login endpoint.
-- Return false when required credentials are missing.
local function getCredentials(Request)
   if not SessionAuth.haveCredentials(Request) then
      return false
   end

   return {
      username = Request.params.username,
      password = Request.params.password
   }
end

-- Authenticate with the configured Iguana dashboard and store its session cookie.
-- Returns true only for HTTP 200 with a recognizable Iguana session cookie.
-- The raw response and credential values are never written to logs.
function SessionAuth.doLogin(Request, LocalUrl)
   local Credentials = getCredentials(Request)
   if not Credentials then
      return false
   end

   local Status, Code, Headers = net.http.post{
      url  = LocalUrl .. '/login.html',
      parameters = Credentials,
      live = true,
   }

   local Cookies = Headers and Headers["Set-Cookie"]

   if (Code ~= 200) or not Cookies then
      iguana.logDebug("Invalid login/request.")
      return false
   end

   -- Extract only the session cookie
   -- This pattern expects the Iguana-SessionID cookie name and a trailing semicolon.
   -- Different server cookie formats require an integration-specific adjustment.
   Request.LoginCookie = Cookies:match('Iguana%-SessionID%-.-;')
   if not Request.LoginCookie then
      iguana.logDebug("No session cookie returned on login.")
      return false
   end
   return true
end

-- Report whether a cookie is stored locally. The name is historical:
-- it does not prove the remote session remains valid or automatically renew it.
function SessionAuth.isSessionValid(Request)
   return Request.LoginCookie ~= nil and Request.LoginCookie ~= ""
end

return SessionAuth
