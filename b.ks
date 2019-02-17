   
//intended to be used with lib_dock_v1
PARAMETER transSpeed IS 2,stationMove IS FALSE.
FOR lib IN LIST("lib_dock","lib_rocket_utilities") { IF EXISTS("1:/lib/" + lib + ".ksm") { RUNONCEPATH("1:/lib/" + lib + ".ksm"). } ELSE { RUNONCEPATH("1:/lib/" + lib + ".ks"). }}
control_point().
WAIT UNTIL active_engine().
CLEARSCREEN.
ABORT OFF.

LOCAL craftPortListRaw IS port_scan(SHIP).
IF craftPortListRaw:LENGTH = 0 {SET craftPortListRaw TO port_scan(SHIP).}
LOCAL buffer IS SHIP:MESSAGES.
buffer:CLEAR().

//PID setup PIDLOOP(kP,kI,kD,min,max)
SET forRCS_PID TO PIDLOOP(4,0.02,0,-1,1).
SET topRCS_PID TO PIDLOOP(4,0.02,0,-1,1).
SET starRCS_PID TO PIDLOOP(4,0.02,0,-1,1).

LOCAL done IS FALSE.
UNTIL done {
	CLEARSCREEN.
	PRINT "Waiting Until a Target to Dock to is Selected.".
	IF HASTARGET {
		SET done TO (TARGET:ISTYPE("vessel") OR TARGET:ISTYPE("part")).
	}
	WAIT 0.1.
}

LOCAL station IS TARGET.
IF station:ISTYPE("part") {
	SET station TO station:SHIP.
}
LOCAL stationPortListRaw IS port_scan(station).
IF stationPortListRaw:LENGTH = 0 {SET stationPortListRaw TO port_scan(station).}
SET NAVMODE TO "TARGET".
LOCAL stationConect IS station:CONNECTION.
PRINT "Waiting for Handshake.".
UNTIL NOT buffer:EMPTY {
	IF buffer:EMPTY {stationConect:SENDMESSAGE("Handshake").}	//sending handshake
	WAIT 1.
}
buffer:CLEAR().			//handshake receved
stationConect:SENDMESSAGE("Docking Request").
message_wait(buffer).
buffer:CLEAR().

stationConect:SENDMESSAGE(stationMove).	//sending if station should move
PRINT "Docking Requested".

message_wait(buffer).
LOCAL signal IS buffer:POP().
LOCAL stationPortListUid IS signal:CONTENT.	//receving stationPortList in UID form
LOCAL craftPortListUid IS port_uid_filter(craftPortListRaw).
LOCAL portLock IS port_lock(craftPortListUid,stationPortListUid,"enabled","disabled").
stationConect:SENDMESSAGE(portLock).			//sending the ports slected for use in UID form
IF portLock["match"] {
LOCAL portLock IS port_lock_true(craftPortListRaw,stationPortListRaw,portLock).	//changing the ports slected for use from UID to TYPE:PART

message_wait(buffer).
LOCAL signal IS buffer:POP().
LOCAL noFlyZone IS signal:CONTENT.	//receving noFlyZone size

LOCAL stationPort IS portLock["stationPort"].
LOCAL craftPort IS portLock["craftPort"].

LOCAL axisSpeed IS axis_speed(SHIP,station).
SAS OFF.
RCS OFF.
PRINT " ".
PRINT "Coming to 0/0 Relitave Stop.".
IF axisSpeed[0]:MAG > 0.1 {
	LOCK STEERING TO -axisSpeed[0]:NORMALIZED.
	LOCAL timePre IS TIME:SECONDS.
	LOCAL done IS FALSE.
	UNTIL done {
		SET axisSpeed TO axis_speed(SHIP,station).
		LOCAL angleTo IS ABS(STEERINGMANAGER:ANGLEERROR).
		IF angleTo < 0.5 {
			IF (TIME:SECONDS - timePre) >= 2.5 { SET done TO TRUE. }
		} ELSE {
			SET timePre TO TIME:SECONDS.
			SET done TO ABORT.
		}
		WAIT 0.01.
	}
	ABORT OFF.

	SET done TO FALSE.
	UNTIL done {
		SET axisSpeed TO axis_speed(SHIP,station).
		LOCAL stationSpeed IS -axisSpeed[1].
		LOCAL shipAcceleration IS SHIP:AVAILABLETHRUST / SHIP:MASS.
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO MAX(MIN(ABS(stationSpeed) / (shipAcceleration * 1.25),1),0.01).
		WAIT 0.01.
		SET done TO stationSpeed < 0.05 OR ABORT.
	}
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}
RCS OFF.
ABORT OFF.
PRINT "Ship at 0/0 Relitave to Target.".
PRINT " ".

IF craftPort[2] = 1 {
	port_open(craftPort[0]).
}

PRINT "Waiting for Station to Stablise.".
craftPort[0]:CONTROLFROM().
LOCK STEERING TO LOOKDIRUP(-stationPort[0]:PORTFACING:FOREVECTOR, stationPort[0]:PORTFACING:TOPVECTOR).
message_wait(buffer).
SET signal TO buffer:POP().

PRINT "Alineing to Target.".
LOCAL timePre IS TIME:SECONDS.
SET done TO FALSE.
UNTIL done {
	LOCAL angleTo IS ABS(STEERINGMANAGER:ANGLEERROR) + ABS(STEERINGMANAGER:ROLLERROR).
//	LOCAL angleTo IS VANG(craftPort[0]:PORTFACING:FOREVECTOR, -stationPort[0]:PORTFACING:FOREVECTOR) + VANG(craftPort[0]:PORTFACING:TOPVECTOR, stationPort[0]:PORTFACING:TOPVECTOR).
	IF angleTo < 0.5 {
		IF (TIME:SECONDS - timePre) >= 5 { SET done TO TRUE. }
	} ELSE {
		SET timePre TO TIME:SECONDS.
		SET done TO ABORT.
	}
	WAIT 0.01.
}
ABORT OFF.

RCS ON.
LOCAL reffList IS LIST(craftPort,stationPort,transSpeed).
IF NOT stationMove {
	IF axis_distance(craftPort[0],stationPort[0])[1] < noFlyZone {
		translate(reffList,"Moving out of No Fly Zone of Station.",TRUE,LIST(0,1,1),noFlyZone).
		RCS ON.
		translate(reffList,"Translating Infront of Target Port.",FALSE,LIST(1,0,0),LIST(noFlyZone,0,0),1).
	}
	RCS ON.
	translate(reffList,"Aligning With Target Port.",FALSE,LIST(0,1,1),LIST(0,0,0),0.5).
	RCS ON.
	translate(reffList,"Docking.",FALSE,LIST(1,1,1),LIST(0,0,0)).
} ELSE {
	translate(reffList,"Docking.",FALSE,LIST(1,0,0),LIST(0,0,0)).
}

} ELSE {
	PRINT "no Matching Unused Dockingports.".
}
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
WAIT 5.
RCS OFF.

//end of core logic start of functions

//ANGLEAXIS(degreesOfRotation,SHIP:FACING:FOREVECTOR) * (LOOKDIRUP(-TARGET:PORTFACING:FOREVECTOR,TARGET:PORTFACING:TOPVECTOR))

FUNCTION translate {
	PARAMETER neededRef,screenText,leaveNoFlyZone,vecMode,distTar,minDist IS 0.1,translationAccel IS 0.04.
	LOCAL craftPort IS neededRef[0]. LOCAL stationPort IS neededRef[1]. LOCAL station IS stationPort[0]:SHIP. LOCAL maxSpeed IS neededRef[2].
	LOCAL axisSpeed IS axis_speed(SHIP,station).
	LOCAL axisDist IS axis_distance(craftPort[0],stationPort[0]).

	LOCAL  forDistDif IS 0.
	LOCAL  topDistDif IS 0.
	LOCAL starDistDif IS 0.
	LOCAL distDif IS 0.
	LOCAL noFlyDist IS 0.

	IF vecMode[0] = 0 { SET forRCS_PID:SETPOINT TO 0. }
	IF vecMode[1] = 0 { SET topRCS_PID:SETPOINT TO 0. }
	IF vecMode[2] = 0 {SET starRCS_PID:SETPOINT TO 0. }
	IF NOT leaveNoFlyZone {
		IF vecMode[0] = 1 { SET forDistDif TO axisDist[1] - distTar[0]. }
		IF vecMode[1] = 1 { SET topDistDif TO axisDist[2] - distTar[1]. }
		IF vecMode[2] = 1 {SET starDistDif TO axisDist[3] - distTar[2]. }
		SET distDif TO SQRT(forDistDif^2 + topDistDif^2 + starDistDif^2).
	} ELSE {
		IF vecMode[0] = 1 { SET forRCS_PID:SETPOINT TO maxSpeed * -(axisDist[1] / ABS(axisDist[1])). }
		IF vecMode[1] = 1 { SET topRCS_PID:SETPOINT TO maxSpeed * -(axisDist[2] / ABS(axisDist[2])). }
		IF vecMode[2] = 1 {SET starRCS_PID:SETPOINT TO maxSpeed * -(axisDist[3] / ABS(axisDist[3])). }
		SET noFlyDist TO MAX(axisDist[1]^2 * vecMode[0] + axisDist[2]^2 * vecMode[1] + axisDist[3]^2 * vecMode[2],1)^0.5.
		SET distDif TO distTar - noFlyDist.
	}

	LOCAL done IS distDif < minDist OR (stationPort[0]:STATE = "Docked (docker)") OR (stationPort[0]:STATE = "Docked (dockee)").
	UNTIL done {
		SET axisDist TO axis_distance(craftPort[0],stationPort[0]).
		SET axisSpeed TO axis_speed(SHIP,station).

		IF leaveNoFlyZone {
			SET noFlyDist TO MAX(SQRT(axisDist[1]^2 * vecMode[0] + axisDist[2]^2 * vecMode[1] + axisDist[3]^2 * vecMode[2]),1).
			SET distDif TO distTar - noFlyDist.
		} ELSE {
			IF vecMode[0] = 1 {
				SET forDistDif TO axisDist[1] - distTar[0].
				SET forRCS_PID:SETPOINT TO RCS_decel_setpoint(translationAccel,forDistDif,maxSpeed,1).
			}
			IF vecMode[1] = 1 {
				SET topDistDif TO axisDist[2] - distTar[1].
				SET topRCS_PID:SETPOINT TO RCS_decel_setpoint(translationAccel,topDistDif,maxSpeed,1).
			}
			IF vecMode[2]= 1 {
				SET starDistDif TO axisDist[3] - distTar[2].
				SET starRCS_PID:SETPOINT TO RCS_decel_setpoint(translationAccel,starDistDif,maxSpeed,1).
			}
			SET distDif TO SQRT(forDistDif^2 + topDistDif^2 + starDistDif^2).
		}

		LOCAL timeS IS TIME:SECONDS.
		SET SHIP:CONTROL:FORE TO forRCS_PID:UPDATE(timeS,axisSpeed[1]).
		SET SHIP:CONTROL:TOP TO topRCS_PID:UPDATE(timeS,axisSpeed[2]).
		SET SHIP:CONTROL:STARBOARD TO starRCS_PID:UPDATE(timeS,axisSpeed[3]).

		WAIT 0.01.
		CLEARSCREEN.
		PRINT screenText.
		PRINT " ".
		PRINT "Port Size: " + craftPort[1].
		PRINT "Disttance: " + ROUND(distDif,1).
		//PRINT " ".
		//PRINT "      Dist: " + ROUND(axisDist[0],2).
		//PRINT "     Speed: " + ROUND(axisSpeed[0]:MAG,2).
		//PRINT " ".
		//PRINT " For  Dist: " + ROUND(axisDist[1],2).
		//PRINT " For Speed: " + ROUND(axisSpeed[1],2).
		//PRINT " ".
		//PRINT " Top  Dist: " + ROUND(axisDist[2],2).
		//PRINT " Top Speed: " + ROUND(axisSpeed[2],2).
		//PRINT " ".
		//PRINT "Star  Dist: " + ROUND(axisDist[3],2).
		//PRINT "Star Speed: " + ROUND(axisSpeed[3],2).

		SET done TO (distDif < minDist) OR (stationPort[0]:STATE = "Docked (docker)") OR (stationPort[0]:STATE = "Docked (dockee)") OR (axisDist[0] < 1).
	}
	SET SHIP:CONTROL:FORE TO 0.
	SET SHIP:CONTROL:TOP TO 0.
	SET SHIP:CONTROL:STARBOARD TO 0.
}

FUNCTION RCS_decel_setpoint {
	PARAMETER accel,dist,speedLimit,deadZone.
	LOCAL localAccel IS accel.
	LOCAL posNeg IS 1.
	IF dist < 0 { SET posNeg TO -1. }
	IF ABS(dist) < deadZone { SET localAccel to accel / 10. }
	RETURN MIN(MAX((SQRT(2 * ABS(dist) / localAccel) * localAccel) * posNeg,-speedLimit),speedLimit).
}

FUNCTION port_lock {
	PARAMETER craftPortList,stationPortList,use,ignore.
	LOCAL matchingPort IS LEX("match",FALSE).
	FOR shipP IN craftPortList { FOR stationP IN stationPortList {
		IF shipP[1] = stationP[1] {
			IF ignore = -99999 OR ((shipP[3] <> ignore) AND (stationP[3] <> ignore)) {
				IF use = -99999 OR ((shipP[3] = use) AND (stationP[3] = use)) {
					RETURN LEX("match",TRUE,"craftPort",shipP,"stationPort",stationP).
				}
				IF use <> -99999 AND ((shipP[3] = use) OR (stationP[3] = use)) AND (NOT matchingPort["match"]) {
					SET matchingPort TO LEX("match",TRUE,"craftPort",shipP,"stationPort",stationP).
				}
			}
		}
	}}
	IF matchingPort["match"] {
		RETURN matchingPort.
	} ELSE IF use <> -99999 {
		PRINT "Overiding Port Priority Tag".
		RETURN port_lock(craftPortList,stationPortList,-99999,ignore).
	} ELSE IF ignore <> -99999{
		PRINT "Overiding Port Disable Tag".
		RETURN port_lock(craftPortList,stationPortList,-99999,-99999).
	} ELSE {
		RETURN LEX("match",FALSE).
	}
}

FUNCTION port_scan {
	PARAMETER craft, canDeploy IS TRUE.	//-----the ship that is scanned for ports-----
	LOCAL portList IS LIST().
	FOR port IN craft:DOCKINGPORTS {
		IF port:STATE = "Ready" {
			portList:ADD(list(port,port:NODETYPE,0,port:TAG)).
		} ELSE IF port:STATE = "Disabled" AND canDeploy {
			portList:ADD(list(port,port:NODETYPE,1,port:TAG)).
		}
	}
	RETURN port_sorting(portList).
}

LOCAL FUNCTION port_sorting {
	PARAMETER portList.
	LOCAL sizeConversion IS LEX(
	"size4","5m",				//from: NearFuture(lifters)
	"size2","2.5m",				//from: stock
	"conSize2","2.5m Con",		//from: USI konstruction
	"spinal","Spinal",			//from: NearFuture(construction)
	"octo","Octo",				//from: NearFuture(construction)
	"sizeh","Hab",				//from: kerbal planetary base systems
	"size1","1.25m",			//from: stock
	"conSize1","1.25m Con",		//from: USI konstruction
	"size0","0.625m",			//from: stock
	"conSize0","0.625m Con").	//from: USI konstruction
	FOR port IN portList {
		IF NOT sizeConversion:KEYS:CONTAINS(port[1]) {
			sizeConversion:ADD(port[1],port[1]).
		}
	}
	LOCAL sortedList IS LIST().
	FOR sort IN sizeConversion:KEYS {
		FOR port IN portList {
			IF port[1] = sort { sortedList:ADD(LIST(port[0],sizeConversion[port[1]],port[2],port[3])). }
		}
	}
	RETURN sortedList.
}

FUNCTION port_open {
	PARAMETER port.
	IF port:STATE = "Disabled" {
		LOCAL portAminate IS port:GETMODULE("ModuleAnimateGeneric").
		LOCAL portOpen IS portAminate:ALLEVENTNAMES[0].
		portAminate:DOEVENT(portOpen).
	}
}

FUNCTION port_uid_filter {
	PARAMETER portList.
	LOCAL portListFiltered IS LIST().
	FOR port IN portList {
		portListFiltered:ADD(LIST(port[0]:UID,port[1],port[2],port[3])).
	}
	RETURN portListFiltered.
}

FUNCTION port_lock_true {
	PARAMETER shipPortList,
	stationPortList,
	portLock.
	IF portLock["match"] {
		LOCAL shipPortTrue IS uid_to_port(shipPortList,portLock["craftPort"][0]).
		LOCAL stationPortTrue IS uid_to_port(stationPortList,portLock["stationPort"][0]).
		RETURN LEX("match",TRUE,"craftPort",shipPortTrue,"stationPort",stationPortTrue).
	} ELSE {
		RETURN portLock.
	}
}

LOCAL FUNCTION uid_to_port {
	PARAMETER portList,
	portUid.
	FOR port IN portList {
		IF port[0]:UID = portUid {
			RETURN port.
		}
	}
}

//FUNCTION no_fly_zone {
//	PARAMETER craft,stationPort.
//	LOCAL bigestDist IS 0.
//	FOR p IN craft:PARTS {
//		LOCAL dist IS (p:POSITION - stationPort:POSITION):MAG.
//		IF dist > bigestDist {
//			SET bigestDist TO dist.
//		}
//	}
//	RETURN bigestDist.
//}

FUNCTION no_fly_zone {
	PARAMETER craft.	//-----the ship used for the calculation
	LOCAL partList IS craft:PARTS.
	LOCAL forDist IS dist_along_vec(partList,craft:FACING:FOREVECTOR).
	LOCAL upDist IS dist_along_vec(partList,craft:FACING:TOPVECTOR).
	LOCAL starDist IS dist_along_vec(partList,craft:FACING:STARVECTOR).
	RETURN sqrt(forDist^2+upDist^2+starDist^2).
}

FUNCTION dist_along_vec {
	PARAMETER partList,	//-----list of things to calculate the dist of-----
	compVec.				//-----the vector along which the dist is calculated-----
	LOCAL compVecLocal IS compVec:NORMALIZED.
	LOCAL posDist IS 0.
	LOCAL negDist IS 0.
	FOR p IN partList {
		LOCAL dist IS VDOT(p:POSITION, compVecLocal).
		IF dist > posDist {
			SET  posDist TO dist.
		} ELSE IF dist < negDist {
			SET negDist TO dist.
		}
	}
	RETURN (posDist - negDist).
}

FUNCTION message_wait {
	PARAMETER buffer.
	WAIT UNTIL (NOT buffer:EMPTY).
}

FUNCTION axis_speed {
	PARAMETER craft,		//the craft to calculate the speed of (craft using RCS)
	//craftPort,			//port that all speeds are relative to (craft using RCS)
	station.				//the target the speed is relative  to
	LOCAL localStation IS station.
	IF station:ISTYPE("dockingPort") { SET localStation TO station:SHIP. }
	LOCAL craftFacing IS craft:FACING.
	LOCAL relitaveSpeedVec IS craft:VELOCITY:ORBIT - localStation:VELOCITY:ORBIT.	//relitaveSpeedVec is the speed as reported by the navball in target mode as a vector along the target prograde direction
	LOCAL speedFor IS VDOT(relitaveSpeedVec, craftFacing:FOREVECTOR).	//positive is moving forwards, negative is moving backwards
	LOCAL speedTop IS VDOT(relitaveSpeedVec, craftFacing:TOPVECTOR).	//positive is moving up, negative is moving down
	LOCAL speedStar IS VDOT(relitaveSpeedVec, craftFacing:STARVECTOR).	//positive is moving right, negative is moving left
	RETURN LIST(relitaveSpeedVec,speedFor,speedTop,speedStar).
}

FUNCTION axis_distance {
	PARAMETER craftPort,	//port that all distances are relative to (craft using RCS)
	stationPort.			//port you want to dock to
	LOCAL craftFacing IS craftPort:FACING.
	IF craftPort:ISTYPE("DOCKINGPORT") { SET craftFacing TO craftPort:PORTFACING. }
	LOCAL distVec IS stationPort:POSITION - craftPort:POSITION.//vector pointing at the station port from the craft port
	LOCAL dist IS distVec:MAG.
	LOCAL distFor IS VDOT(distVec, craftFacing:FOREVECTOR).	//if positive then stationPort is ahead of craftPort, if negative than stationPort is behind of craftPort
	LOCAL distTop IS VDOT(distVec, craftFacing:TOPVECTOR).		//if positive then stationPort is above of craftPort, if negative than stationPort is below of craftPort
	LOCAL distStar IS VDOT(distVec, craftFacing:STARVECTOR).	//if positive then stationPort is to the right of craftPort, if negative than stationPort is to the left of craftPort
	RETURN LIST(dist,distFor,distTop,distStar).
}