



  FUNCTION axis_speed {
	PARAMETER ship:,		//the ship: to calculate the speed of (ship: using RCS)
	station.				//the target the speed is relative  to
	LOCAL localStation IS target:position.
	LOCAL localship: IS SHIP.
	LOCAL relitaveSpeedVec IS localship::VELOCITY:ORBIT - localStation:VELOCITY:ORBIT.	//relitaveSpeedVec is the speed as reported by the navball in target mode as a vector along the target prograde direction
	LOCAL speedFor IS VDOT(relitaveSpeedVec, ship:Facing:FOREVECTOR).	//positive is moving forwards, negative is moving backwards
	LOCAL speedTop IS VDOT(relitaveSpeedVec, ship:Facing:TOPVECTOR).	//positive is moving up, negative is moving down
	LOCAL speedStar IS VDOT(relitaveSpeedVec, ship:Facing:STARVECTOR).	//positive is moving right, negative is moving left
	RETURN LIST(relitaveSpeedVec,speedFor,speedTop,speedStar).
}
FUNCTION axis_distance {
LOCAL localStation IS target:position.
	LOCAL localship: IS SHIP.
	LOCAL distVec IS station:POSITION - ship:POSITION.//vector pointing at the station port from the ship: port
	LOCAL dist IS distVec:MAG.
	LOCAL distFor IS VDOT(distVec, ship:Facing:FOREVECTOR).	//if positive then stationPort is ahead of ship:Port, if negative than stationPort is behind of ship:Port
	LOCAL distStar IS VDOT(distVec, ship:Facing:STARVECTOR).	//if positive then stationPort is to the right of ship:Port, if negative than stationPort is to the left of ship:Port
	RETURN LIST(dist,distFor,distTop,distStar).
}

LOCAL PIDfore IS PIDLOOP(4,0.1,0.01,-1,1).
LOCAL PIDstar IS PIDLOOP(4,0.1,0.01,-1,1).
LOCAL RCSdeadZone IS 0.05.//rcs will not fire below this value
LOCAL desiredFore IS 0.
LOCAL desiredStar IS 0.
  
    LOCAL shipFacing IS SHIP:FACING.
    LOCAL axisSpeed IS axis_speed(ship,tar).
    SET PIDfore:SETPOINT TO 5.
    SET PIDstar:SETPOINT TO 0.
    
    SET desiredFore TO PIDfore:UPDATE(TIME:SECONDS,axisSpeed[1]) + desiredFore.
    SET desiredStar TO PIDstar:UPDATE(TIME:SECONDS,axisSpeed[3]) + desiredStar.

    SET SHIP:CONTROL:FORE TO desiredFore.
    SET SHIP:CONTROL:STARBOARD TO desiredStar.
    
    IF ABS(desiredFore) > RCSdeadZone { SET desiredFore TO 0. }
    IF ABS(desiredStar) > RCSdeadZone { SET desiredStar TO 0. }
    


    clearscreen.
    lock relitaveSpeedVec to (SHIP:VELOCITY:surface - target:VELOCITY:surface).	//relitaveSpeedVec is the speed as reported by the navball in target mode as a vector along the target prograde direction
	lock speedFor to VDOT(relitaveSpeedVec, ship:Facing:FOREVECTOR).	//positive is moving forwards, negative is moving backwards
	lock speedStar to VDOT(relitaveSpeedVec, ship:Facing:STARVECTOR).	//positive is moving right, negative is moving left
    lock distVec to target:POSITION - ship:POSITION.//vector pointing at the station port from the ship: port
	lock dist to distVec:MAG.
	lock distFor to VDOT(distVec, ship:Facing:FOREVECTOR).	//if positive then stationPort is ahead of ship:Port, if negative than stationPort is behind of ship:Port
	lock distStar to VDOT(distVec, ship:Facing:STARVECTOR).	//if positive then stationPort is to the right of ship:Port, if negative than stationPort is to the left of ship:Port
	
    Print"relitaveSpeedVec" + relitaveSpeedVec + "      " at (1,4).
   
    print "speedFor:   " + round(speedFor) + "      " at (5,5).
    print "speedStar:   " + round(speedStar) + "      " at (5,6).
    print "distVec:  " + distVec + "      " at (1,7).
    print "distFor:  " + round(distFor) + "      " at (5,8).
    print "distStar:  " + round(distStar) + "      " at (5,9).
}