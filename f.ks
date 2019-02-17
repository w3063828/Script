clearscreen. unlock steering. rcs on. sas off. panels off. gear off.

set RUNMODE to 2. if ALTITUDE > 15000 {set RUNMODE to 1.} when alt:radar < 25000 then {rcs off. print "RCS OFF" at (0,4).}

set dTIME to TIME:SECONDS.

set tVERTICALSPEED to 1.1. set eVERTICALSPEED to 0. set iVERTICALSPEED to -40. set pVAL to 0. set tVAL to 0.

set tROLL to 0. set eROLL to 0. set iROLL to 0. set dROLL to 0. set rVAL to 0. set SHIPROLLMULTIPLIER to 1.75.

set tHeading to 0. set prevHEADINGSLIST TO LIST(). set var to 0. until var > 20{ SET prevHEADINGSLIST:ADD TO 0. set var to var + 1. } set var to 0. set avgHEADING to 0. set tALTITUDE to 0. set maxBANK to 50. // The max bank angle set maxVERTICALSPEED to 100.

set tAIRSPEED to 250. set iAIRSPEED to 0. set eAIRSPEED to 0.

set line88 to latlng( -0.048597000539, -88). set runwayWest to latlng( -0.048597000539, -74.72335052490). set runwayEast to latlng( -0.05028, -74.48821). set tLATLONG to line88.

lock CURRENTSPOT to SHIP:GEOPOSITION.

clearscreen. print "##### KK4TEE Auto-Landing System ##### " at (5,0).

until 0{

//These calulations are used for determining ROLL
SET starboard TO SHIP:FACING * R(0,90,0).
SET starVec to starboard:VECTOR.
SET currentUpVec to SHIP:UP:VECTOR.
SET DISTTOTARGET to tLATLONG:DISTANCE.
SET DISTTORUNWAY to runwayWest:DISTANCE.



///////////PID FLIGHT SURFACE CONTROLLERS//////////////////////////////
//PITCH - Hold to vertical speed.
set eVERTICALSPEED to (VERTICALSPEED - tVERTICALSPEED).
set piVERTICALSPEED to iVERTICALSPEED.
set iVERTICALSPEED to iVERTICALSPEED + (eVERTICALSPEED * (TIME:SECONDS - DTIME)).
if  iVERTICALSPEED > 500{ set iVERTICALSPEED to 500.}
if iVERTICALSPEED < -500 { set iVERTICALSPEED to -500.}
set dVERTICALSPEED to (iVERTICALSPEED - piVERTICALSPEED)/(TIME:SECONDS - DTIME).
set pVAL to  0 - (eVERTICALSPEED / 275 + iVERTICALSPEED/1400 + dVERTICALSPEED/1000).


//ROLL
set cROLL to (VANG(starVec,currentUpVec) - 90).
set eROLL to cROLL - tROLL.
set piROLL to iROLL.
set iROLL to iROLL + (eROLL * (TIME:SECONDS - DTIME)).
if  iROLL > 50{ set iROLL to 50.}
if iROLL < -50 { set iROLL to -50.}
set dROLL to (iROLL - piROLL)/(TIME:SECONDS - DTIME).
set rVAL to  0-(eROLL / 400 + iROLL/1200 - dROLL/1000)*SHIPROLLMULTIPLIER. 


//Command the flight surfaces
set SHIP:CONTROL:PITCH to pVAL.
set SHIP:CONTROL:ROLL to rVAL.
lock throttle to tVAL.
}


///////////////////////////////////////////////
if RUNMODE = 1 {
//Come back from space

lock throttle to 0.
set tALTITUDE to 14000.
set tVERTICALSPEED to (tALTITUDE - ALTITUDE)/50.

if ALTITUDE > 2000 and VERTICALSPEED < -100  and tVERTICALSPEED < -100{ //If sinking fast
    lock steering to prograde + R(0,1,0). //Pull up gently
    }
else {
    set eVERTICALSPEED to (VERTICALSPEED - tVERTICALSPEED).
    set iVERTICALSPEED to iVERTICALSPEED + (eVERTICALSPEED * (TIME:SECONDS - DTIME)).
    if  iVERTICALSPEED > 500{ set iVERTICALSPEED to 500.}
    if iVERTICALSPEED < -500 { set iVERTICALSPEED to -500.}
    set pVAL to  0 - (eVERTICALSPEED / 30 + iVERTICALSPEED/50).
    set pVAL to max(pVAL,-20).
    set pVAL to min(pVAL,20).
    lock steering to prograde + R(0,1 + pVAL,0).
    }
    
    if tVERTICALSPEED > -10 and SURFACESPEED < 850{
        set RUNMODE to 2.
        rcs off.
        unlock steering.
        }

}

if RUNMODE = 2 {
//Head towards the opposite edge of the continent
set tLATLONG to line88.
set tALTITUDE to 14000.
set tAIRSPEED to 800.

if SHIP:GEOPOSITION:LNG + 2 > tLATLONG:LNG{

    set RUNMODE to 3.
    }
}

if RUNMODE = 3 {
//Follow a dynamically updated point that is always 1' away
set tLATLONG to latlng( runwayWest:LAT, SHIP:GEOPOSITION:LNG + 0.25 + DISTTORUNWAY * 0.0000333).

set tAIRSPEED to DISTTORUNWAY * 0.0075 + 100.
if tAIRSPEED > 800 { 
    set tAIRSPEED to 800.
    }

if DISTTORUNWAY / 8 - 300 > 14000{
    set tALTITUDE to 14000.
    }
else {
    set tALTITUDE to DISTTORUNWAY / 8 - 250.
    }

 if DISTTORUNWAY < 3500 {
    set iVERTICALSPEED to iVERTICALSPEED -50.
    GEAR ON. LIGHTS ON.
    set RUNMODE to 4.
    }
}

if RUNMODE = 4 {
//Final Approach
set tLATLONG to latlng( runwayWest:LAT, SHIP:GEOPOSITION:LNG + 0.25 + DISTTORUNWAY * 0.0000333).

if SHIP:GEOPOSITION:LNG > runwayWest:LNG - 0.001 {
    set tAIRSPEED to 0.
    BRAKES ON.
    set tALTITUDE to -1. //Hold fast to the runway
    if SURFACESPEED < 0.1{
        print "LANDED." at (20,30).
        break.
        }
    }
else {
    set tAIRSPEED to 100.
    set tALTITUDE to 25.
    }
}

set dTIME to TIME:SECONDS.
set tHEADING to tLATLONG:bearing.
wait 0.0001. //Wait until the next physics frame  