local CrusherComponent = class()
local Point3 = _radiant.csg.Point3

function CrusherComponent:initialize()
	self._sv.crushable_items = nil
end

function CrusherComponent:activate()
	self._entity:get_component('stonehearth:storage')._refresh_attention_effect = function()
		return false
	end
	self.player_id = radiant.entities.get_player_id(self._entity)
	local inventory = stonehearth.inventory:get_inventory(self.player_id)
	local tracker = inventory:add_item_tracker("swamp_goblins:crushable_item_tracker")

	self:make_recipe_list()
	--send the list of recipes, so it can block recipeless items from appearing
	tracker._sv.controller.recipes_list = self.recipes_list

	self.player_id_trace = self._entity:trace_player_id('owner observer')
	:on_changed(function()
		self:_update_crushable_items()
	end)
	self:_update_crushable_items()

	self._item_added_listener = radiant.events.listen(
		self._entity,
		'stonehearth:storage:item_added',
		self,
		self._item_added)
end

function CrusherComponent:destroy()
	if self.player_id_trace then
		self.player_id_trace:destroy()
		self.player_id_trace = nil
	end
	if self._item_added_listener then
		self._item_added_listener:destroy()
		self._item_added_listener = nil
	end
end

function CrusherComponent:_update_crushable_items()
	local inventory = stonehearth.inventory:get_inventory(self.player_id)
	self._sv.crushable_items = inventory:get_item_tracker('swamp_goblins:crushable_item_tracker')
	self.__saved_variables:mark_changed()
end

function CrusherComponent:_item_added(data)
	radiant.effects.run_effect(self._entity, "stonehearth:effects:item_created")

	local facing = radiant.entities.get_facing(self._entity)
	local location = radiant.entities.get_world_grid_location(self._entity)
	local drop_location = location+radiant.math.rotate_about_y_axis(Point3(1.5,0.1,0), facing)
	
	local uri
	local iconic_component = data.item:get_component('stonehearth:iconic_form')
	if iconic_component then
		uri = iconic_component:get_root_entity():get_uri()
	else
		uri = data.item:get_uri()
	end

	self.resource_constants = radiant.resources.load_json('stonehearth:data:resource_constants').resources
	local resources = self:_decompose_item_into_resources(uri)
	if type(resources) ~= 'table' then
		resources = {uri}
	end
	for i,resource in ipairs(resources) do
		local ingredient = radiant.entities.create_entity(resource, {owner = self.player_id})
		radiant.terrain.place_entity_at_exact_location(ingredient, drop_location)
	end

	self._entity:get_component('stonehearth:storage'):remove_item(data.item_id)
	radiant.entities.destroy_entity(data.item)
end

function CrusherComponent:_decompose_item_into_resources(item, current_resources)
	if not self.recipes_list[item] then
		-- no recipe for this one, can't decompose anymore
		if self.resource_constants[item] then
			-- its a material (e.g. "wood resource"), not uri
			return self.resource_constants[item].default_resource
		end
		return item
	end
	if not current_resources then
		current_resources = {}
	end
	for i,v in ipairs(self.recipes_list[item]) do
		for i=1, v.count do
			local ingredient = v.uri or v.material
			local decomposed = self:_decompose_item_into_resources(ingredient, current_resources)
			if type(decomposed) ~= 'table' then
				table.insert(current_resources, decomposed)
			end
		end
	end
	return current_resources
end

function CrusherComponent:make_recipe_list()
	self.recipes_list = {}
	local job_index = stonehearth.player:get_jobs(self.player_id)
	for alias,data in pairs(job_index) do
		local job_info = stonehearth.job:get_job_info(self.player_id, alias)
		if job_info._sv.recipe_list then
			for category, category_data in pairs(job_info._sv.recipe_list) do
				if category_data.recipes then
					for recipe_short_key, recipe_data in pairs(category_data.recipes) do
						if recipe_data.recipe and recipe_data.recipe.recipe_key then
							if (not recipe_data.recipe.produces[2])
								and (not stonehearth.catalog:is_category(recipe_data.recipe.product_uri, "resources")) then
								--"produces[2]" recipes gives multiple items, don't accept those
								--"resources" should be the end of the line, no more decomposing (e.g. coal into wood)
								self.recipes_list[recipe_data.recipe.product_uri] = recipe_data.recipe.ingredients
							end
						end
					end
				end
			end
		end
	end
end

return CrusherComponent