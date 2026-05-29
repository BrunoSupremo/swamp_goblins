local SwampGoblinMusicComponent = class()
local Point3 = _radiant.csg.Point3

function SwampGoblinMusicComponent:post_activate()
	self:in_use(false)

	local json = radiant.entities.get_json(self)
	self._effect_height = json.effect_height
end

function SwampGoblinMusicComponent:get_effect_height()
	return self._effect_height
end

function SwampGoblinMusicComponent:play_notes_effect()
	self.proxy = radiant.entities.create_entity('stonehearth:object:transient', { debug_text = 'town upgrade effect anchor' })
	local location = radiant.entities.get_world_grid_location(self._entity)
	local offset = self:get_effect_height()
	radiant.terrain.place_entity_at_exact_location(self.proxy, location+Point3(0,offset,0))
	local effect = radiant.effects.run_effect(self.proxy, 'swamp_goblins:effects:music:notes')
end

function SwampGoblinMusicComponent:stop_notes_effect()
	if self.proxy then
		radiant.entities.destroy_entity(self.proxy)
	end
end

function SwampGoblinMusicComponent:in_use(is_being_used)
	local commands_component = self._entity:get_component("stonehearth:commands")
	commands_component:set_command_enabled("swamp_goblins:commands:music", not is_being_used)
	self._enabled = is_being_used

	stonehearth.ai:reconsider_entity(self._entity)
end

return SwampGoblinMusicComponent