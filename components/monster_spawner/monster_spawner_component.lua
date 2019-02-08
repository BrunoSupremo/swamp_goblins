local SwampGoblins_Monster_Spawner = class()
-- local log = radiant.log.create_logger('SwampGoblins_Monster_Spawner')

function SwampGoblins_Monster_Spawner:activate()
	if stonehearth.game_creation:get_game_mode() == "stonehearth:game_mode:peaceful" then
		return
	end
	local json = radiant.entities.get_json(self)
	self.monster = json.monster or "stonehearth:loot:gold"
	self.player_id = json.player_id or "forest"
	self.interval = json.interval or "1d"

	if not self._on_removed_from_world_listener then
		self._on_removed_from_world_listener = radiant.events.listen(self._entity, 'stonehearth:on_removed_from_world', self, self.spawner_removed)
	end
	self:activate_the_spawner()
end

function SwampGoblins_Monster_Spawner:activate_the_spawner()
	local delayed_function = function ()
		if not self._sv._spawn_timer then
			self:try_to_spawn_monster()
			self._sv._spawn_timer = stonehearth.calendar:set_persistent_interval("SwampGoblins_Monster_Spawner spawn_timer", self.interval, radiant.bind(self, 'try_to_spawn_monster'), self.interval)
			self.__saved_variables:mark_changed()
		end
		self.stupid_delay:destroy()
		self.stupid_delay = nil
	end
	self.stupid_delay = stonehearth.calendar:set_persistent_timer("SwampGoblins_Monster_Spawner delay", 0, delayed_function)
end

function SwampGoblins_Monster_Spawner:spawner_removed()
	self:destroy_spawn_timer()
end

function SwampGoblins_Monster_Spawner:try_to_spawn_monster()
	local location = radiant.entities.get_world_grid_location(self._entity)
	if not location then
		return
	end
	self:spawn_monster(location)
end

function SwampGoblins_Monster_Spawner:spawn_monster(location)
	local monster = radiant.entities.create_entity(self.monster, {owner = self.player_id})
	radiant.terrain.place_entity_at_exact_location(monster, location)
	radiant.entities.add_buff(monster, "stonehearth:buffs:despawn:after_day")
end

function SwampGoblins_Monster_Spawner:destroy_spawn_timer()
	if self._sv._spawn_timer then
		self._sv._spawn_timer:destroy()
		self._sv._spawn_timer = nil
		self.__saved_variables:mark_changed()
	end
end

function SwampGoblins_Monster_Spawner:destroy()
	self:spawner_removed()
	if self._on_added_to_world_listener then
		self._on_added_to_world_listener:destroy()
		self._on_added_to_world_listener = nil
	end
	if self._on_removed_from_world_listener then
		self._on_removed_from_world_listener:destroy()
		self._on_removed_from_world_listener = nil
	end
	self:destroy_spawn_timer()
end

return SwampGoblins_Monster_Spawner