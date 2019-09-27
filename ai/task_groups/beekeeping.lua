local GoblinsBeekeepingTaskGroup = class()
GoblinsBeekeepingTaskGroup.name = 'beekeeping'
GoblinsBeekeepingTaskGroup.does = 'stonehearth:work'
GoblinsBeekeepingTaskGroup.priority = 0.15

return stonehearth.ai:create_task_group(GoblinsBeekeepingTaskGroup)
:work_order_tag("job")
:declare_permanent_task('stonehearth:harvest_resource', { category = "beekeeping" }, 1.0)
:declare_permanent_task('stonehearth:harvest_renewable_resource', { category = "beekeeping" }, 0.0)
