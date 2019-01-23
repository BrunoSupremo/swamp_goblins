local LayEggTaskGroup = class()
LayEggTaskGroup.name = 'lay_egg'
LayEggTaskGroup.does = 'stonehearth:work'
LayEggTaskGroup.priority = 0.7

return stonehearth.ai:create_task_group(LayEggTaskGroup)
:work_order_tag("haul")
:declare_permanent_task('swamp_goblins:lay_egg', {}, 1)