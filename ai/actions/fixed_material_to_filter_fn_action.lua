local entity_forms_lib = require 'stonehearth.lib.entity_forms.entity_forms_lib'

local MaterialToFilterFn = radiant.class()

MaterialToFilterFn.name = 'material to filter fn'
MaterialToFilterFn.does = 'stonehearth:material_to_filter_fn'
MaterialToFilterFn.args = {
	material = 'string',      -- the material tags we need
	owner = {                 -- must also be owed by
		type = 'string',
		default = ''
	}
}
MaterialToFilterFn.think_output = {
	filter_fn = 'function',   -- a function which checks those tags
	description = 'string'    -- a description of the filter
}
MaterialToFilterFn.priority = 0

local function make_filter_fn(material, owner)
	return function(item)
		if not radiant.entities.is_material(item, material) then
			-- not the right material?  bail.
			return false
		end
		if owner ~= '' and radiant.entities.get_player_id(item) ~= owner then
			-- not owned by the right person?  also bail!
			return false
		end
		-- also make sure we're not considering ghost/placed items!
		local root, iconic = entity_forms_lib.get_forms(item)
		if root and iconic then
			if iconic ~= item then
				return false
			end
		elseif (root or iconic) and root ~= item and iconic ~= item then
			return false
		end

		return true
	end
end

function MaterialToFilterFn:start_thinking(ai, entity, args)
	local key = string.format('material:%s owner:%s', args.material, args.owner)

	local filter_fn = stonehearth.ai:filter_from_key('stonehearth:material_to_filter_fn', key, make_filter_fn(args.material, args.owner))

	ai:set_debug_progress('material key: ' .. key)

	ai:set_think_output({
		filter_fn = filter_fn,
		description = string.format('material is "%s"', args.material)
	})
end

return MaterialToFilterFn
