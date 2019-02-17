

lock vec1 TO body:position.
lock vec2 TO  target:position. 
lock vec1x2 to VCRS(vec1, vec2).
print vec1x2.
set finalvec to VCRS(vec1x2, vec1).
print finalvec.

local east is target:position.

local desired_velocity is v(0, 0, 0).
lock delta_velocity to desired_velocity - velocity:surface.
lock steering to finalvec.

gear off.
brakes off.
local target_twr is 0.
lock g TO SHIP:SENSORS:GRAV:mag.
lock maxtwr to ship:maxthrust / (g * ship:mass).
lock throttle to min(target_twr / maxtwr, 1).

lock steering to lookdirup(target:position,body:position*-1).
set ship:control:pilotmainthrottle to 0.
stage.
local pid is pidloop(2.7, 4.4, 0.12, 0, 1).
set pid:setpoint to 1.
until 0 {
  if alt:radar > 15 and pid:setpoint <> 0 set pid:setpoint to 0.
  if gear { gear off. set desired_velocity to desired_velocity + east. }
  if brakes { brakes off. set desired_velocity to desired_velocity - east. }
  set target_twr to pid:update(time:seconds, ship:verticalspeed) / cos(vang(up:vector, ship:facing:forevector)).
  wait 0.01.
}