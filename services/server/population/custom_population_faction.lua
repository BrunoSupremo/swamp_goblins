local GoblinPopulationFaction = class()

function GoblinPopulationFaction:create_new_goblin_citizen_from_role_data(citizen)
   self:_set_citizen_initial_state(citizen, "male", self:get_role_data(), {})
   self._sv.citizens:add(citizen:get_id(), citizen)
   self:on_citizen_count_changed()
   self:_monitor_citizen(citizen)

   --Add thoughts for new citizens.  Non-player citizens will still get this call, but if they don't have a happiness component it will be discarded.
   --Note that this may need to be revisited if we ever create alternative means for adding citizens to the town. -rhough
   radiant.entities.add_thought(citizen, 'stonehearth:thoughts:town:founding:pioneering_spirit')
   self.__saved_variables:mark_changed()
end

return GoblinPopulationFaction