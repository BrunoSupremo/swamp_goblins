local TrapperJob = require 'stonehearth.jobs.trapper.trapper'
local ScavengerClass = class()
radiant.mixin(ScavengerClass, TrapperJob)

function ScavengerClass:should_tame(target)
	return false
end

return ScavengerClass