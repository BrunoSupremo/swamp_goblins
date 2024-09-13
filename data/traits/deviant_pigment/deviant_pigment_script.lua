local DeviantPigmentTrait = class()
local rng = _radiant.math.get_default_rng()

function DeviantPigmentTrait:initialize()
	self._sv._entity = nil
	self._sv._material_map = nil
end

function DeviantPigmentTrait:create(entity, uri)
	self._sv._entity = entity
	
	local json = radiant.resources.load_json(uri)
	local colors = json.data.color_options
	local color_picked = rng:get_int(1, #colors)

	self._sv._material_map = colors[color_picked]
end

function DeviantPigmentTrait:post_activate()
	self._sv._entity:get_component('render_info'):add_material_map(self._sv._material_map)	
end

function DeviantPigmentTrait:destroy()
	self._sv._entity:get_component('render_info'):remove_material_map(self._sv._material_map)	
end

return DeviantPigmentTrait