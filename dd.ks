//Set the ship to a known configuration
SAS off.
RCS on.
lights on.
set throttle to 0.
gear off.
panels on.
LOCK GRAV TO SHIP:SENSORS:GRAV.

clearscreen.
wait 5.

// Lets get some math out of the way, shall we?
lock shipLatLng to SHIP:GEOPOSITION. //This is the ship's current location above the surface
//This variable store the altitude above sea level that the ground below the ship is at.
lock surfaceElevation to shipLatLng:TERRAINHEIGHT.

lock betterALTRADAR to max( 0.1, ALTITUDE - surfaceElevation).
     //Depending on what other mods you have installed ALT:RADAR may not work properly,
     // so instead I calculate it using the sea level altitude minus the ground elevation
lock impactTime to betterALTRADAR / -VERTICALSPEED. // Time until we hit the ground
                
// Calculate the theoretical throttle level to hover in place ( 1/TWR)
set GRAVITY to (constant():G * body:mass) / body:radius^2.
lock TWR to MAX( 0.001, MAXTHRUST / (MASS*GRAVITY)).
set runmode to 1.



until runmode = 0 { //Run until we end the program
   
    if runmode = 1 { 
        if PERIAPSIS > 50000 { set runmode to 20.}
        else { set runmode to 21.}}

    if runmode = 20 { 
      rcs off.
        if PERIAPSIS > 50000  {
           set STEERING to RETROGRADE.
           RCS on.
           lock throttle to (2* Ship:Mass * GRAV:MAG / ship:availablethrust).
            wait 0.5.
           set runmode to 20.
          
           }
          
        if PERIAPSIS < 50000  { 
             set thottle to 0.
             set runmode to 21.}
         
    }

    if runmode = 21 { 
        lock STEERING to RETROGRADE. 
        set throttle to 0.0.
        if SHIP:ALTITUDE < 50000 and ship:AIRSPEED > 1720 {
                set STEERING to RETROGRADE.
                lock throttle to (4 * Ship:Mass * GRAV:MAG/ ship:availablethrust).
                wait 0.5.
                set runmode to 21.}

         if SHIP:ALTITUDE < 50000 and ship:AIRSPEED < 1720 {
                lock throttle to 0.
                set runmode to 22.}
        if SHIP:ALTITUDE > 50000 {
        set runmode to 21.}}
        

    if runmode = 22 {
        lock STEERING to RETROGRADE. 
        set throttle to 0.0.
        if SHIP:ALTITUDE < 40000 and ship:AIRSPEED > 1260 {
                set STEERING to RETROGRADE.
                lock throttle to (2 * Ship:Mass * GRAV:MAG/ ship:availablethrust).
                wait 0.5.
                set runmode to 21.}

         if SHIP:ALTITUDE < 40000 and ship:AIRSPEED < 1260 {
                lock throttle to 0.
                set runmode to 23.}
        if SHIP:ALTITUDE > 40000 {
        set runmode to 22.}}
        

    
        
    if runmode = 23 { // Coast until the ETA of slamming into the ground < 10 seconds
        panels off.
        brakes on.
        lock STEERING to velocity:surface * -1. //Point retrograde relative to surface velocity
        set TVAL to 0.
        if ALTITUDE > 70000 {
            wait 1.         //Wait to make sure the ship is stable
            SET WARP TO 3. //Be really careful about warping
            }
        else if ALTITUDE < 70000 and WARP > 0 {
            SET WARP TO 0. // Make sure we don't time warp through the atmosphere
            }
        if impactTime < 100 and verticalspeed < -1 and betterALTRADAR < 5000{
            set runmode to 24.
            }
        }
        
    if runmode = 24 { // Land on the ground
        lock STEERING to velocity:surface * -1.//Point retrograde relative to surface velocity
        set landingRadar to min(ALTITUDE, betterALTRADAR). 
        // Use whichever says our altitude is lower
                //This is useful in case we overshoot the KSC and need to land in the ocean.
        set TVAL to (1 / TWR) - (verticalspeed + max(5, min (250, landingRadar^1.08 / 8)) ) / 3 / TWR.
        lock throttle to tval.
        gear on.

        // Here we set the throttle to hover using a Thrust to weight ratio of one to counter act gravity
        // Then we modify the throttle by the error between the speed we want to be at (based on altitude)
        // and the speed we are currently at, then divide it by three to smooth it out and then divide it again 
        // by the TWR to automatically customize it for each ship.
        //
        if betterALTRADAR < 15 and ABS(VERTICALSPEED) < 1 {
            lock throttle to 0.
            lock steering to up.
            print "LANDED!".
            wait 2.
            set runmode to 0.
            }

        }
        
    

    


    //Print data to screen.
    print "RUNMODE:    " + runmode + "      " at (5,4).
    print "ALTITUDE:   " + round(SHIP:ALTITUDE) + "      " at (5,5).
    print "APOAPSIS:   " + round(SHIP:APOAPSIS) + "      " at (5,6).
    print "PERIAPSIS:  " + round(SHIP:PERIAPSIS) + "      " at (5,7).
    print "ETA to AP:  " + round(ETA:APOAPSIS) + "      " at (5,8).
    print "ETA to Pe:  " + round(ETA:PERIAPSIS) + "      " at (5,9).
    print "Impact Time:" + round(impacttime,1) + "      " at (5,10).
    
}