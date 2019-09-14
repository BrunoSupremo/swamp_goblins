local GoblinStuff = class()

function GoblinStuff:initialize()
	print("function GoblinStuff:initialize()")
end

function GoblinStuff:start()
	print("function GoblinStuff:start()")
end

function GoblinStuff:stop()
	print("function GoblinStuff:stop()")
end

function GoblinStuff:restore()
	print("function GoblinStuff:restore()")
end

function GoblinStuff:post_activate()
	print("function GoblinStuff:post_activate()")
end

function GoblinStuff:destroy()
	print("function GoblinStuff:destroy()")
end

return GoblinStuff