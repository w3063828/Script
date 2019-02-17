SET TARGET TO VESSEL("45").
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
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

set runmode to 1.
until runmode = 0 { //Run until we end the program
 if runmode = 1 { 
    lock steering to finalvec.
    set ship:control:pilotmainthrottle to 0.
    stage.
   local pid is pidloop(0.28166778734885156, 0.67973461165092885, 0.012451723217964172, 0, 1).
    set pid:setpoint to 1.
    until runmode =2 {
     if gear { gear off. set pid:setpoint to pid:setpoint - 1. }
      if brakes { brakes off. set pid:setpoint to pid:setpoint + 1. }
      set pid:maxoutput to maxtwr.
      set target_twr to pid:update(time:seconds, ship:verticalspeed).
     wait 0.001.
      if abort { abort off. set runmode to 2.}
      if ag8 { ag8 off. lock steering to finalvec.}
      LOCAL PIDfore IS PIDLOOP(0.28166778734885156, 0.67973461165092885, 0.012451723217964172, -1, 1).
      LOCAL PIDstar IS PIDLOOP(0.28166778734885156, 0.67973461165092885, 0.012451723217964172, -1, 1).
      LOCAL RCSdeadZone IS 0.05.//rcs will not fire below this value
      LOCAL desiredFore IS 0.
      LOCAL desiredStar IS 0.
      LOCAL shipFacing IS SHIP:FACING.
      LOCAL axisSpeed IS axis_speed().
      lock DISTANCE to abs(axis_distance[1]).
      lock DF to sqrt(max(distance^2,distanceToGround()^2) - min(distance^2,distanceToGround()^2)).
      SET PIDfore:SETPOINT TO (sqrt(DF)*-(signF())).
      SET PIDstar:SETPOINT TO (sqrt(DF)*-(signS())).
      SET desiredFore TO PIDfore:UPDATE(TIME:SECONDS,axis_speed[1]).
      SET desiredStar TO PIDstar:UPDATE(TIME:SECONDS,axis_speed[2]).
      SET SHIP:CONTROL:FORE TO desiredFore.
      SET SHIP:CONTROL:STARBOARD TO desiredStar.
      print "signf:    " + signf() + "      " at (5,5).
      print "signs:    " + signs() + "      " at (5,3).
      print "distance:  " + round(DISTANCE) + "      " at (5,8).
      print "RUNMODE:    " + runmode + "      " at (5,4).
      print "DF:  " + round(DF) + "      " at (5,9).
      print "setpoint:    " + PIDfore:SETPOINT + "      " at (5,7).
      print "setpp" + PIDstar:SETPOINT + "      " at (5,6).
      if DF < 1 {set runmode to 2.}
      if ag8 { ag8 off. lock steering to finalvec.}
      IF ABS(desiredFore) > RCSdeadZone { SET desiredFore TO 0. }
      IF ABS(desiredStar) > RCSdeadZone { SET desiredStar TO 0. }
         
      }
  }
  if runmode = 2 { 
    lock steering to LOOKDIRUP(target:position,ship:Facing:upvector).
    set ship:control:pilotmainthrottle to 0.
    stage.
   local pid is pidloop(0.28166778734885156, 0.67973461165092885, 0.012451723217964172, 0, 1).
    set pid:setpoint to 1.
    until runmode =1 {
     if gear { gear off. set pid:setpoint to pid:setpoint - 1. }
      if brakes { brakes off. set pid:setpoint to pid:setpoint + 1. }
      set pid:maxoutput to maxtwr.
      set target_twr to pid:update(time:seconds, ship:verticalspeed).
     wait 0.001.
      if abort { abort off. set runmode to 3.}
      if ag8 { ag8 off. lock steering to finalvec.}
      LOCAL PIDfore IS PIDLOOP(0.28166778734885156, 0.67973461165092885, 0.012451723217964172, -1, 1).
      LOCAL PIDstar IS PIDLOOP(0.28166778734885156, 0.67973461165092885, 0.012451723217964172, -1, 1).
      LOCAL RCSdeadZone IS 0.05.//rcs will not fire below this value
      LOCAL desiredFore IS 0.
      LOCAL desiredStar IS 0.
      LOCAL shipFacing IS SHIP:FACING.
      LOCAL axisSpeed IS axis_speed().
      lock DISTANCE to abs(axis_distance[1]).
      lock DF to sqrt(max(distance^2,distanceToGround()^2) - min(distance^2,distanceToGround()^2)).
      SET PIDfore:SETPOINT TO ((DF/10)*-(axis_distance[1] / max (ABS(axis_distance[1]),0.01))).
      SET PIDstar:SETPOINT TO ((DF/10)*-(axis_distance[2] / max (ABS(axis_distance[2]),0.01))).
      SET desiredFore TO PIDfore:UPDATE(TIME:SECONDS,axis_distance[1]).
      SET desiredStar TO PIDstar:UPDATE(TIME:SECONDS,axis_distance[2]).
      SET SHIP:CONTROL:FORE TO desiredFore.
      SET SHIP:CONTROL:STARBOARD TO desiredStar.
      print "sign:    " + sign() + "      " at (5,5).
      print "distance:  " + round(DISTANCE) + "      " at (5,8).
      print "RUNMODE:    " + runmode + "      " at (5,4).
      print "DF:  " + round(DF) + "      " at (5,9).
      print "setpoint:    " + PIDfore:SETPOINT + "      " at (5,7).
      print "setpp" + PIDstar:SETPOINT + "      " at (5,6).
      if ag8 { ag8 off. lock steering to finalvec.}
      IF ABS(desiredFore) > RCSdeadZone { SET desiredFore TO 0. }
      IF ABS(desiredStar) > RCSdeadZone { SET desiredStar TO 0. }
         
      }
  }

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
	LOCAL distVec IS ship:POSITION - target:POSITION.//vector pointing at the station port from the ship: port
	LOCAL dist IS distVec:MAG.
	LOCAL distFor IS VDOT(distVec, ship:Facing:FOREVECTOR).	//if positive then stationPort is ahead of ship:Port, if negative than stationPort is behind of ship:Port
	LOCAL distStar IS VDOT(distVec, ship:Facing:STARVECTOR).	//if positive then stationPort is to the right of ship:Port, if negative than stationPort is to the left of ship:Port
	RETURN LIST(dist,distFor,distStar).
}
function distanceToGround {
  return altitude - body:geopositionOf(ship:position):terrainHeight.
}
Function signF{
 lock SCN to (axis_distance[1] / max (ABS(axis_distance[1]),0.01)).
 return scn. 
}
Function signS{
 lock San to (axis_distance[2] / max (ABS(axis_distance[2]),0.01)).
 return san. 
}
//..............................................................................................................
  
  
    
  