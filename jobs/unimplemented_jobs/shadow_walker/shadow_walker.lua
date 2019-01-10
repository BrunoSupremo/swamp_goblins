local CraftingJob = require 'stonehearth.jobs.crafting_job'

local ShamanClass = class()
radiant.mixin(ShamanClass, CraftingJob)

return ShamanClass