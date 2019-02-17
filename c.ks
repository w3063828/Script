FUNCTION axis_speed {
	PARAMETER craft,		//the craft to calculate the speed of (craft using RCS)
	station.				//the target the speed is relative  to
	LOCAL localStation IS target:position.
	LOCAL localCraft IS target.
	LOCAL craftFacing IS localCraft:FACING.
	IF craft:ISTYPE("DOCKINGPORT") { SET craftFacing TO craft:PORTFACING. }
	LOCAL relitaveSpeedVec IS localCraft:VELOCITY:ORBIT - localStation:VELOCITY:ORBIT.	//relitaveSpeedVec is the speed as reported by the navball in target mode as a vector along the target prograde direction
	LOCAL speedFor IS VDOT(relitaveSpeedVec, craftFacing:FOREVECTOR).	//positive is moving forwards, negative is moving backwards
	LOCAL speedTop IS VDOT(relitaveSpeedVec, craftFacing:TOPVECTOR).	//positive is moving up, negative is moving down
	LOCAL speedStar IS VDOT(relitaveSpeedVec, craftFacing:STARVECTOR).	//positive is moving right, negative is moving left
	RETURN LIST(relitaveSpeedVec,speedFor,speedTop,speedStar).
}

FUNCTION axis_distance {
	PARAMETER craft,	//port that all distances are relative to (craft using RCS)
	station.			//port you want to dock to
	LOCAL craftFacing IS target_craft(craft):FACING.
	IF craft:ISTYPE("DOCKINGPORT") { SET craftFacing TO craft:PORTFACING. }
	LOCAL distVec IS station:POSITION - craft:POSITION.//vector pointing at the station port from the craft port
	LOCAL dist IS distVec:MAG.
	LOCAL distFor IS VDOT(distVec, craftFacing:FOREVECTOR).	//if positive then stationPort is ahead of craftPort, if negative than stationPort is behind of craftPort
	LOCAL distTop IS VDOT(distVec, craftFacing:TOPVECTOR).		//if positive then stationPort is above of craftPort, if negative than stationPort is below of craftPort
	LOCAL distStar IS VDOT(distVec, craftFacing:STARVECTOR).	//if positive then stationPort is to the right of craftPort, if negative than stationPort is to the left of craftPort
	RETURN LIST(dist,distFor,distTop,distStar).
}