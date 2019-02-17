CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
SET TARGET TO VESSEL("45").
runpath("0:/knu.ks"). local genetics is import("genetics.ks").

genetics["seek"](lex(
  "file", "0:/vanguard.json",
  "autorevert", true,
  "arity", 3,
  "size", 10,
  "fitness", fitness_fn@
)).

function fitness_fn {
wait 10.
set ship:control:pilotmainthrottle to 0.
stage.
gear off.
brakes off.
rcs on.
local target_twr is 0.
lock g TO SHIP:SENSORS:GRAV:mag.
lock maxtwr to ship:maxthrust / (g * ship:mass).
lock throttle to min(target_twr / maxtwr, 1).
lock vec1 TO body:position.
lock vec2 TO  target:position. 
lock vec1x2 to VCRS(vec1, vec2).
lock finalvec to VCRS(vec1x2, vec1).
lock steering to finalvec.
    
    
 local pid is pidloop(0.28166778734885156, 0.67973461165092885, 0.012451723217964172, 0, 1).
    set pid:setpoint to 1.
    set pid:maxoutput to maxtwr.
    set target_twr to pid:update(time:seconds, ship:verticalspeed).
    wait 0.01.
 
 
 
 
 
 
 parameter k.
  hudtext("kP: " + k[0], 30, 2, 50, yellow, false).
  hudtext("kI: " + k[1], 30, 2, 50, yellow, false).
  hudtext("kD: " + k[2], 30, 2, 50, yellow, false).
  LOCAL desiredFore IS 0.
   
  set dV to (target:POSITION - ship:POSITION).
  lock DISTANCE to dv:MAG.
  lock DF to sqrt(distance^2 - distanceToGround()^2).
  LOCAL shipFacing IS SHIP:FACING.
  LOCAL axisSpeed IS axis_speed().
  LOCAL RCSdeadZone IS 0.05.
  local PIDfore is pidloop(k[0], k[1], k[2], -10, 1).
  local last_time is time:seconds.
  local total_error is 0.
  set PIDfore:SETPOINT TO 0. //((DF/1000)*((axis_distance[1] / ABS(axis_distance[1])*1))).
  local start_time is time:seconds.
until time:seconds > start_time + 60 {
    set target_twr to pid:update (time:seconds, ship:verticalspeed).
    if time:seconds > start_time + 10 set PIDfore:setpoint to 0.
    if time:seconds > start_time + 20 set pidfore:setpoint to -5.
    if time:seconds > start_time + 30 set pidfore:setpoint to 0.
    if time:seconds > start_time + 40 set pidfore:setpoint to 5.
    if time:seconds > start_time + 50 set pidfore:setpoint to 0.
    lock myVelocity to ship:facing * ship:velocity:surface.
    SET desiredFore TO PIDfore:UPDATE(TIME:SECONDS,axis_speed[1]).
    SET SHIP:CONTROL:FORE TO desiredFore.
    set total_error to total_error + abs(pidfore:error * (time:seconds - last_time)).
    set last_time to time:seconds. 
    print "setpoint:    " + PIDfore:SETPOINT + "      " at (5,7).
    print "DF:  " + round(DF) + "      " at (5,9).
    print "desiredFore:  " + round(desiredFore) + "      " at (5,8).
     print "myVelocity:  " + axis_speed[1] + "      " at (5,6).
    wait 0.001.
    IF ABS(desiredFore) > RCSdeadZone { SET desiredFore TO 0. }
  }

  return gaussian(total_error, 0, 250).
}

function gaussian {
  parameter value, targetQ, width.
  return constant:e^(-1 * (value-targetQ)^2 / (2*width^2)).
}

 
 FUNCTION axis_speed {
	LOCAL localStation IS target:position.
	LOCAL localship IS SHIP.
	LOCAL relitaveSpeedVec IS SHIP:VELOCITY:SURFACE - target:VELOCITY:surface.	//relitaveSpeedVec is the speed as reported by the navball in target mode as a vector along the target prograde direction
	LOCAL speedFor IS VDOT(relitaveSpeedVec, ship:Facing:FOREVECTOR).	//positive is moving forwards, negative is moving backwards
	LOCAL speedStar IS VDOT(relitaveSpeedVec, ship:Facing:STARVECTOR).	//positive is moving right, negative is moving left
	RETURN LIST(relitaveSpeedVec,speedFor,speedStar).
}
FUNCTION axis_distance {
	LOCAL distVec IS target:POSITION - ship:POSITION.//vector pointing at the station port from the ship: port
	LOCAL dist IS distVec:MAG.
	LOCAL distFor IS VDOT(distVec, ship:Facing:FOREVECTOR).	//if positive then stationPort is ahead of ship:Port, if negative than stationPort is behind of ship:Port
	LOCAL distStar IS VDOT(distVec, ship:Facing:STARVECTOR).	//if positive then stationPort is to the right of ship:Port, if negative than stationPort is to the left of ship:Port
	RETURN LIST(dist,distFor,distStar).
}
function distanceToGround {
  return altitude - body:geopositionOf(ship:position):terrainHeight.
}