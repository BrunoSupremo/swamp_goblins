local TallTownBonus = class()

local BUFF_URI = "swamp_goblins:buffs:town_bonus:tall"

function TallTownBonus:initialize()
   self._sv.player_id = nil
   self._sv.display_name = "i18n(swamp_goblins:entities.decoration.shrine.tall.display_name)"
   self._sv.description = "i18n(swamp_goblins:data.gm.campaigns.town_progression.climax.shrine_choice.tall_description)"
end

function TallTownBonus:create(player_id)
   self._sv.player_id = player_id
end

function TallTownBonus:activate()
   local population = stonehearth.population:get_population(self._sv.player_id)
   self._citizen_added_listener = radiant.events.listen(population, 'stonehearth:population:citizen_count_changed', self, self._add_buff)
   self:_add_buff()
end

function TallTownBonus:destroy()
   local population = stonehearth.population:get_population(self._sv.player_id)
   for _, citizen in population:get_citizens():each() do
      radiant.entities.remove_buff(citizen, BUFF_URI)
   end
end

function TallTownBonus:_add_buff()
   local population = stonehearth.population:get_population(self._sv.player_id)
   for _, citizen in population:get_citizens():each() do
      radiant.entities.add_buff(citizen, BUFF_URI)
   end
end

return TallTownBonus