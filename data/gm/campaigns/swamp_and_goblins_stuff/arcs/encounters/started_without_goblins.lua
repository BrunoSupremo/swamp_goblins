local StartedWithoutGoblins = class()
local Point3 = _radiant.csg.Point3

function StartedWithoutGoblins:start(ctx)
	local population = stonehearth.population:get_population(ctx.player_id)
	local goblin_counter = 0
	for _, citizen in population:get_citizens():each() do
		local render_info = citizen:get_component('render_info')
		local model_variant = render_info:get_model_variant()
		if model_variant == 'firefly_goblin' then
			goblin_counter = goblin_counter +1
		end
	end

	while goblin_counter < 2 do
		self:add_goblin_citizen_command(ctx)
		goblin_counter = goblin_counter +1
	end
end

function StartedWithoutGoblins:add_goblin_citizen_command(ctx)
	local player_id = ctx.player_id
	local pop = stonehearth.population:get_population(player_id)
	local goblin = radiant.entities.create_entity("swamp_goblins:goblins:goblin", {owner = player_id})
	pop:create_new_goblin_citizen_from_role_data(goblin)
	local job_component = goblin:add_component('stonehearth:job')
	job_component:promote_to("stonehearth:jobs:worker", { skip_visual_effects = true })

	local explored_region = stonehearth.terrain:get_visible_region(player_id):get()
	local centroid = explored_region:get_centroid():to_closest_int()
	local town_center = radiant.terrain.get_point_on_terrain(Point3(centroid.x, 0, centroid.y))

	local spawn_point = radiant.terrain.find_placement_point(town_center, 20, 30)
	radiant.terrain.place_entity(goblin, spawn_point)


	stonehearth.bulletin_board:post_bulletin(player_id)
	:set_data({
		title = 'i18n(swamp_goblins:data.gm.campaigns.swamp_and_goblins.started_without_goblins)',
		message = '',
		zoom_to_entity = goblin
	})
end

return StartedWithoutGoblins