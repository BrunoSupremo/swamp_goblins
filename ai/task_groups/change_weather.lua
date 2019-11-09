local ChangeWeatherTaskGroup = class()
ChangeWeatherTaskGroup.name = 'change_weather'
ChangeWeatherTaskGroup.does = 'stonehearth:work'
ChangeWeatherTaskGroup.priority = 0.7

return stonehearth.ai:create_task_group(ChangeWeatherTaskGroup)
:work_order_tag("job")
:declare_permanent_task('swamp_goblins:charge_weather_stone', {}, 1)
:declare_permanent_task('swamp_goblins:use_weather_stone', {}, 1)