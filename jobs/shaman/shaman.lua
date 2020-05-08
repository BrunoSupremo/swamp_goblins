local CraftingJob = require 'stonehearth.jobs.herbalist.herbalist'

local ShamanClass = class()
radiant.mixin(ShamanClass, CraftingJob)

function ShamanClass:post_activate()
	if self:is_max_level() then
		self:get_cook_recipes()
	end
end

function ShamanClass:get_cook_recipes()
	local player_id = radiant.entities.get_player_id(self._sv._entity)
	local job_info = stonehearth.job:get_job_info(player_id, "swamp_goblins:jobs:shaman")

	local cook_recipes = radiant.deep_copy(radiant.resources.load_json("/swamp_goblins/jobs/shaman/recipes/cook_recipes.json").craftable_recipes)

	for category, category_data in pairs(cook_recipes) do
		if category_data.recipes then
			for recipe_short_key, recipe_data in pairs(category_data.recipes) do
				if not job_info._sv.recipe_list[category] then
					job_info._sv.recipe_list[category] = category_data
				else
					job_info._sv.recipe_list[category].recipes[recipe_short_key] = recipe_data
				end
				local recipe_key = category .. ":" .. recipe_short_key
				if recipe_data.recipe == "" then
					job_info._sv.recipe_list[category].recipes[recipe_short_key] = nil
				else
					recipe_data.recipe = radiant.deep_copy(radiant.resources.load_json(recipe_data.recipe))
					job_info:_initialize_recipe_data(recipe_key, recipe_data.recipe)
				end
			end
		end
	end
	job_info.__saved_variables:mark_changed()
end

return ShamanClass