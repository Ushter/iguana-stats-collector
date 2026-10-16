local Calc = {}

local function valueOf(field)
   if field == nil then
      return 0
   end

   if type(field) == "table" or type(field) == "userdata" then
      local nodeValue = field.nodeValue
      if type(nodeValue) == "function" then
         local ok, result = pcall(nodeValue, field)
         if ok then
            return tonumber(result) or 0
         end
      end
   end

   return tonumber(field) or 0
end

--Compute a running average
function Calc.avg(oldVal, newVal, count)
   oldVal = valueOf(oldVal)
   newVal = valueOf(newVal)
   local newCount = (count or 0) + 1
   return oldVal + (newVal - oldVal) / newCount
end

-- Compute the maximum of two values

function Calc.computeMax(oldVal, newVal)
   oldVal = valueOf(oldVal)
   newVal = valueOf(newVal)
   return (newVal > oldVal) and newVal or oldVal
end

function Calc.computeServerAverages(old, s)
   local count = valueOf(old.TotalNumberStats)

   return {
      AverageNumberDatabaseConnections = Calc.avg(valueOf(old.AverageNumberDatabaseConnections), s.MaxNumberDatabaseConnections, count),
      AverageInboundTps = Calc.avg(valueOf(old.AverageInboundTps), s.InboundTps, count),
      AverageOutboundTps = Calc.avg(valueOf(old.AverageOutboundTps), s.OutboundTps, count),
      AverageCPUPercent = Calc.avg(valueOf(old.AverageCPUPercent), s.CPUPercent, count),
      AverageMemRssKB = Calc.avg(valueOf(old.AverageMemRssKB), s.MemRssKB, count),
      AverageOpenFD = Calc.avg(valueOf(old.AverageOpenFD), s.OpenFD, count),
      AverageThreadCount = Calc.avg(valueOf(old.AverageThreadCount), s.ThreadCount, count),
      AverageCountOfRunningChannel = Calc.avg(valueOf(old.AverageCountOfRunningChannel), s.CountOfRunningChannel, count),
      AverageCountOfError = Calc.avg(valueOf(old.AverageCountOfError), s.CountOfError, count),
      AverageTotalCountOfRemaining = Calc.avg(valueOf(old.AverageTotalCountOfRemaining), s.TotalCountOfRemaining, count)
   }
end

function Calc.computeChannelAverages(old, c)
   local count = valueOf(old.TotalNumberStats)

   return {
      AverageCountOfEnqueued = Calc.avg(valueOf(old.AverageCountOfEnqueued), c.CountOfEnqueued, count),
      AverageInboundTps = Calc.avg(valueOf(old.AverageInboundTps), c.InboundTps, count),
      AverageOutboundTps = Calc.avg(valueOf(old.AverageOutboundTps), c.OutboundTps, count)
   }
end

return Calc
