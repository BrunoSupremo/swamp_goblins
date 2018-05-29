local Point3 = _radiant.csg.Point3

local GoblinWorkerClass = class()
local CombatJob = require 'stonehearth.jobs.combat_job'
radiant.mixin(GoblinWorkerClass, CombatJob)

--[[
   A controller that manages all the relevant data about the worker class
   Workers don't level up, so this is all that's needed.
]]

function GoblinWorkerClass:initialize()
   CombatJob.initialize(self)
   self._sv.no_levels = true
   self._sv.is_max_level = true
end

-- Returns all the data for all the levels
function GoblinWorkerClass:get_level_data()
   return nil
end

-- Given the ID of a perk, find out if we have the perk. 
function GoblinWorkerClass:has_perk(id)
   return false
end

return GoblinWorkerClass