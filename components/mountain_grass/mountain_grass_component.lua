-- local log = radiant.log.create_logger('MountainGrass')
local MountainGrass = class()
local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3
local Region3 = _radiant.csg.Region3

function MountainGrass:post_activate()
	self._world_generated_listener = radiant.events.listen_once(stonehearth.game_creation, 'stonehearth:world_generation_complete', self, self._on_world_generation_complete)
end

function MountainGrass:_on_world_generation_complete()
	local json = radiant.entities.get_json(self)
	self.radius = json.radius or 8
	self.block_type = json.block_type or "grass"
	self.priority = json.priority or 2 --1 = higher priority, 2 = lower priority

	if self.priority <2 then
		self:swap_blocks()
	else
		self._gameloop_listener = radiant.events.listen_once(radiant, 'radiant:gameloop', self, self.swap_blocks)
	end
end

function MountainGrass:swap_blocks()
	local location = radiant.entities.get_world_grid_location(self._entity)
	if location and location.y > 50 then
		local block_type = radiant.terrain.get_block_types()[self.block_type]
		local cube = Cube3(
			location + Point3(-self.radius,-1,-self.radius),
			location + Point3( self.radius, 0, self.radius)
			)
		local grass_region = radiant.terrain.intersect_cube(cube)
		for cube in grass_region:each_cube() do
			radiant.terrain.add_cube(Cube3(cube.min,cube.max,block_type))
		end
	end
	self._entity:remove_component('swamp_goblins:mountain_grass')
end

return MountainGrass