local CraftingJob = require 'stonehearth.jobs.herbalist.herbalist'

local ShamanClass = class()
radiant.mixin(ShamanClass, CraftingJob)

return ShamanClass