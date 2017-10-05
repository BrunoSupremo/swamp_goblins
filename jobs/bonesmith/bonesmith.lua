local CraftingJob = require 'stonehearth.jobs.crafting_job'

local BonesmithClass = class()
radiant.mixin(BonesmithClass, CraftingJob)

return BonesmithClass