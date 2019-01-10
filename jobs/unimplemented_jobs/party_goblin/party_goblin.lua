local PartyGoblinClass = class()
local CombatJob = require 'stonehearth.jobs.combat_job'
radiant.mixin(PartyGoblinClass, CombatJob)

return PartyGoblinClass