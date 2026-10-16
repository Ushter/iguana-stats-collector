local SessionAuth = {}

function SessionAuth.haveCredentials(Request)
   return Request.params and Request.params.username ~= nil and
          Request.params.password ~= nil and
          Request.params.username ~= "" and Request.params.password ~= ""
end

local function getCredentials(Request)
   if not SessionAuth.haveCredentials(Request) then
      return false
   end

   return {
      username = Request.params.username,
      password = Request.params.password
   }
end

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
   Request.LoginCookie = Cookies:match('Iguana%-SessionID%-.-;')
   if not Request.LoginCookie then
      iguana.logDebug("No session cookie returned on login.")
      return false
   end
   return true
end

function SessionAuth.isSessionValid(Request)
   return Request.LoginCookie ~= nil and Request.LoginCookie ~= ""
end

return SessionAuth
