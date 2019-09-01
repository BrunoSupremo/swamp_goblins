local TrapperJob = require 'stonehearth.jobs.trapper.trapper'
local TrapperPlusJob = require 'trapper_plus.jobs.trapper.trapper_modded'

local ScavengerClass = class()
radiant.mixin(ScavengerClass, TrapperJob)
if TrapperPlusJob then
	radiant.mixin(ScavengerClass, TrapperPlusJob)
end

function ScavengerClass:should_tame(target)
	return false
end

return ScavengerClass