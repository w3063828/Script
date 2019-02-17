SET TARGET TO VESSEL("rover 2.grapple Debris").
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
wait 2.
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
    until 0 {
     if gear { gear off. set pid:setpoint to pid:setpoint - 1. }
      if brakes { brakes off. set pid:setpoint to pid:setpoint + 1. }
      set pid:maxoutput to maxtwr.
      set target_twr to pid:update(time:seconds, ship:verticalspeed).
     wait 0.01.
      if abort { abort off. set runmode to 2.}
      if ag8 { ag8 off. lock steering to finalvec.}
      LOCAL PIDfore IS PIDLOOP(0.28166778734885156, 0.67973461165092885, 0.012451723217964172, 0, 1).
      LOCAL PIDstar IS PIDLOOP(0.28166778734885156, 0.67973461165092885, 0.012451723217964172, 0, 1).
      LOCAL RCSdeadZone IS 0.05.//rcs will not fire below this value
      LOCAL desiredFore IS 0.
      LOCAL desiredStar IS 0.
      LOCAL shipFacing IS SHIP:FACING.
      LOCAL axisSpeed IS axis_speed().
      SET PIDfore:SETPOINT TO 10.
      SET PIDstar:SETPOINT TO 0.
      SET desiredFore TO PIDfore:UPDATE(TIME:SECONDS,axisSpeed[1]) + desiredFore.
      SET desiredStar TO PIDstar:UPDATE(TIME:SECONDS,axisSpeed[3]) + desiredStar.
      SET SHIP:CONTROL:FORE TO desiredFore.
      SET SHIP:CONTROL:STARBOARD TO desiredStar.
      set dV to (target:POSITION - ship:POSITION).
      lock DISTANCE to dv:MAG.
      lock DF to sqrt(distanceToGround^2 + distance^2).
      print "distance:  " + round(DISTANCE) + "      " at (5,8).
      print "DF:  " + round(DF) + "      " at (5,9).
      IF ABS(desiredFore) > RCSdeadZone { SET desiredFore TO 0. }
      IF ABS(desiredStar) > RCSdeadZone { SET desiredStar TO 0. }
          if distance< 10{ SET PIDfore:SETPOINT TO 3.}    
      if distance < 5 {  SET PIDfore:SETPOINT TO 0.}  
      }
  }
  if runmode = 2 { 
    lock steering to up.
    set ship:control:pilotmainthrottle to 0.
    local pid is pidloop(0.28166778734885156, 0.67973461165092885, 0.012451723217964172, 0, 1).
    set pid:setpoint to 1.
      until 0 {
        if gear { gear off. set pid:setpoint to pid:setpoint - 1. }
        if brakes { brakes off. set pid:setpoint to pid:setpoint + 1. }
        set pid:maxoutput to maxtwr.
        set target_twr to pid:update(time:seconds, ship:verticalspeed).
        wait 0.01.
        if abort { abort off. unlock steering.}
        if ag8 { ag8 off. set runmode to 0.}
        LOCAL PIDFd IS PIDLOOP(0.91890245722606778, 0.07970734778791666,0.027380389394238591,-10,1).
        LOCAL PIDSD IS PIDLOOP(0.91890245722606778, 0.07970734778791666,0.027380389394238591,-10,1).
        LOCAL RCSdeadZone IS 0.05.//rcs will not fire below this value
        LOCAL desiredFore IS 0.
        LOCAL desiredStar IS 0.
        LOCAL shipFacing IS SHIP:FACING.
        LOCAL axisSpeed IS axis_speed().
        SET PIDfore:SETPOINT TO 0.
        SET PIDstar:SETPOINT TO 0.
        SET desiredFore TO PIDFD:UPDATE(TIME:SECONDS,axisdistance[1]) + desiredFore.
        SET desiredStar TO PIDSD:UPDATE(TIME:SECONDS,axisdistance[3]) + desiredStar.
        SET SHIP:CONTROL:FORE TO desiredFore.
        SET SHIP:CONTROL:STARBOARD TO desiredStar.
        set dV to (target:POSITION - ship:POSITION).
        lock DISTANCE to dv:MAG.
        lock DF to sqrt(distanceToGround^2 + distance^2).
        print "distance:  " + round(DISTANCE) + "      " at (5,8).
        print "DF:  " + round(DF) + "      " at (5,9).
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
	LOCAL speedTop IS VDOT(relitaveSpeedVec, ship:Facing:TOPVECTOR).	//positive is moving up, negative is moving down
	LOCAL speedStar IS VDOT(relitaveSpeedVec, ship:Facing:STARVECTOR).	//positive is moving right, negative is moving left
	RETURN LIST(relitaveSpeedVec,speedFor,speedTop,speedStar).
}
FUNCTION axis_distance {
LOCAL localStation IS target:position.
	LOCAL localship IS SHIP.
	LOCAL distVec IS station:POSITION - ship:POSITION.//vector pointing at the station port from the ship: port
	LOCAL dist IS distVec:MAG.
	LOCAL distFor IS VDOT(distVec, ship:Facing:FOREVECTOR).	//if positive then stationPort is ahead of ship:Port, if negative than stationPort is behind of ship:Port
	LOCAL distStar IS VDOT(distVec, ship:Facing:STARVECTOR).	//if positive then stationPort is to the right of ship:Port, if negative than stationPort is to the left of ship:Port
	RETURN LIST(dist,distFor,distTop,distStar).
}
function distanceToGround {
  return altitude - body:geopositionOf(ship:position):terrainHeight - 4.7.
}
//..............................................................................................................
  
  
    
  