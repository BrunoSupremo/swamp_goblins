local FireflyWorker = class()

function FireflyWorker:post_activate()
	self._job_changed_listener = radiant.events.listen(self._entity, 'stonehearth:job_changed', self, self._on_job_changed)
end

function FireflyWorker:_on_job_changed()
	if self._job_changed_listener then
		self._job_changed_listener:destroy()
		self._job_changed_listener = nil
	end
	local job = self._entity:get_component('stonehearth:job'):get_job_uri()
	if job == "stonehearth:jobs:worker" then
		self._entity:get_component('stonehearth:job'):promote_to("swamp_goblins:jobs:worker", { skip_visual_effects = true })
	end
	self._entity:remove_component('swamp_goblins:firefly_worker')
end

return FireflyWorker