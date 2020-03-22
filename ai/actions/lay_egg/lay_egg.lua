local FireflyLayEgg = class()
local Point3 = _radiant.csg.Point3

FireflyLayEgg.name = 'lay egg'
FireflyLayEgg.does = 'swamp_goblins:lay_egg'
FireflyLayEgg.status_text_key = 'swamp_goblins:ai.actions.status_text.lay_egg'
FireflyLayEgg.args = { }
FireflyLayEgg.version = 2
FireflyLayEgg.priority = 1

function find_an_egg_spot(ai_entity)
	local player_id = ai_entity:get_player_id()
	return stonehearth.ai:filter_from_key('swamp_goblins:lay_egg', player_id,
		function(target)
			if target:get_player_id() ~= player_id then
				return false
			end
			if target:get_component("swamp_goblins:lay_egg_spot") then
				return target:get_component("swamp_goblins:lay_egg_spot"):current_stage() == "waiting"
			end
			return false
		end
		)
end

local ai = stonehearth.ai
return ai:create_compound_action(FireflyLayEgg)
:execute('stonehearth:drop_carrying_now', {})
:execute('stonehearth:goto_entity_type', {
	filter_fn = ai.CALL(find_an_egg_spot, ai.ENTITY),
	description = 'find egg spot'
})
:execute('stonehearth:reserve_entity', { entity = ai.PREV.destination_entity })
:execute('stonehearth:abort_on_event_triggered', {
	source = ai.BACK(2).destination_entity,
	event_name = 'swamp_goblins:lay_egg:cancel'
})
:execute('stonehearth:run_effect', {
	effect = "emote_dance_shuffle",
	times = 3
})
:execute('swamp_goblins:create_egg', {pedestal = ai.BACK(4).destination_entity})