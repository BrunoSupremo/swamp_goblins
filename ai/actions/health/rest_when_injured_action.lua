local GoblinsRestWhenInjured = radiant.class()
GoblinsRestWhenInjured.name = 'goblin rest when injured'
GoblinsRestWhenInjured.does = 'stonehearth:rest_when_injured'
GoblinsRestWhenInjured.args = {}
GoblinsRestWhenInjured.priority = {0, 1}

function GoblinsRestWhenInjured:compose_utility(entity, self_utility, child_utilities, current_activity)
	return 1.0 - child_utilities:get(0) / 0.84
end

local ai = stonehearth.ai
return ai:create_compound_action(GoblinsRestWhenInjured)
:execute('stonehearth:wait_for_expendable_resource_below_percentage', {
	resource_name = 'health',
	percentage = 0.84
})
:execute('stonehearth:rest_from_injuries')