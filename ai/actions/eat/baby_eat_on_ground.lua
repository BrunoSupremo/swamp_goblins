local BabyEatOnGround = radiant.class()
BabyEatOnGround.name = 'baby eat on the ground'
BabyEatOnGround.does = 'stonehearth:find_seat_and_eat'
BabyEatOnGround.args = {}
BabyEatOnGround.priority = 2

local ai = stonehearth.ai
return ai:create_compound_action(BabyEatOnGround)
:execute('stonehearth:wander', { radius = 3, radius_min = 1 })
:execute('stonehearth:sit_on_ground')
:execute('stonehearth:eat_carrying')