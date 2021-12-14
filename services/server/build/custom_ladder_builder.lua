local GoblinLadderBuilder = class()

function GoblinLadderBuilder:create(manager, id, owner, base, normal, options)
	self._sv.id = id
	self._log:set_prefix('lbid:' .. tostring(self._sv.id))

	local ladder_uri = 'stonehearth:build:prototypes:ladder'
	if stonehearth.player:get_kingdom(owner) == "swamp_goblins:kingdoms:firefly_clan" then
		ladder_uri = 'swamp_goblins:build:prototypes:ladder'
	end
	local ladder = radiant.entities.create_entity(ladder_uri, { owner = owner })
	ladder:set_debug_text('builder id:' .. tostring(id))
	self._sv.manager = manager
	self._sv.ladder = ladder
	self._sv.base = base
	if options.category then
		self._sv.category = options.category
	end

	-- The destination region at the top and/or bottom of the ladder that we can use to
	-- build or teardown the ladder.
	self._sv.ladder_dst_proxy_region = _radiant.sim.alloc_region3()
	self._sv.ladder_dst_proxy_adj = _radiant.sim.alloc_region3()
	self._sv.ladder_dst_proxy = radiant.entities.create_entity('stonehearth:build:prototypes:ladder_dst_proxy', { owner = owner })
	self._sv.ladder_dst_proxy:add_component('destination')
	:set_region(self._sv.ladder_dst_proxy_region)
	:set_adjacent(self._sv.ladder_dst_proxy_adj)
	self._sv.ladder_dst_proxy:add_component('stonehearth:ladder_dst_proxy')
	:set_ladder_builder(self)

	self.__saved_variables:mark_changed()

	radiant.terrain.place_entity_at_exact_location(ladder, base)
	radiant.terrain.place_entity_at_exact_location(self._sv.ladder_dst_proxy, base)

	ladder:add_component('stonehearth:ladder')
	:set_normal(normal)

	ladder:add_component('vertical_pathing_region')
	:set_region(_radiant.sim.alloc_region3())
end

return GoblinLadderBuilder