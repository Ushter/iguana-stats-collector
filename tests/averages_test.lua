package.path = 'src/?.lua;' .. package.path
local calc = require 'Calculate'
assert(calc.avg(10, 20, 1) == 15)
assert(calc.computeMax({nodeValue = function() return '30' end}, 20) == 30)
local averages = calc.computeChannelAverages({
   TotalNumberStats = 2, MaxAverageCountOfEnqueued = 100,
   AverageCountOfEnqueued = 10, AverageInboundTps = 10, AverageOutboundTps = 10
}, {CountOfEnqueued = 40, InboundTps = 40, OutboundTps = 40})
assert(averages.AverageCountOfEnqueued == 20)
local server = calc.computeServerAverages({TotalNumberStats = 1, AverageMemRssKB = 100}, {MemRssKB = 200})
assert(server.AverageMemRssKB == 150)
