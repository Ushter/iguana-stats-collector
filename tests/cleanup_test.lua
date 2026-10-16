local closed, opened = false, false
package.preload.config = function() return {
   Request = {}, LocalUrl = 'http://localhost', DefaultParams = function() return {} end,
   Database = {CONNECT_PARAMS = {}}
} end
local status = 200
package.preload.dashboard_client = function() return {Dashboard = {fetch = function() return '{}', status end}} end
package.preload.statsSqlite = function() return {statsSqlite = function() error('Synthetic failure') end} end
json = {parse = function() return {Servers = {}, Channels = {}} end}
iguana = {logDebug = function() end}
db = {connect = function() opened = true; return {close = function() closed = true end} end}
dofile('src/main.lua')
assert(not pcall(main))
assert(opened and closed)
opened = false
status = 503
assert(not pcall(main))
assert(not opened)
