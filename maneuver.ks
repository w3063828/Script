// Time to complete a maneuver
FUNCTION MNV_TIME {
  PARAMETER dV.

  LIST ENGINES IN en.
function mnv_time {
  parameter dv.
  set ens to list().
  ens:clear.
  set ens_thrust to 0.
  set ens_isp to 0.
  list engines in myengines.

  for en in myengines {
    if en:ignition = true and en:flameout = false {
      ens:add(en).
    }
  }

  LOCAL f IS en[0]:MAXTHRUST * 1000.  // Engine Thrust (kg * m/s²)
  LOCAL m IS SHIP:MASS * 1000.        // Starting mass (kg)
  LOCAL e IS CONSTANT():E.            // Base of natural log
  LOCAL p IS en[0]:ISP.               // Engine ISP (s)
  LOCAL g IS 9.82.                    // Gravitational acceleration constant (m/s²)
  for en in ens {
    set ens_thrust to ens_thrust + en:availablethrust.
    set ens_isp to ens_isp + en:isp.
  }

  RETURN g * m * p * (1 - e^(-dV/(g*p))) / f.
  if ens_thrust = 0 or ens_isp = 0 {
    notify("No engines available!").
    return 0.
  }
  else {
    local f is ens_thrust * 1000.  // engine thrust (kg * m/s²)
    local m is ship:mass * 1000.        // starting mass (kg)
    local e is constant():e.            // base of natural log
    local p is ens_isp/ens:length.               // engine isp (s) support to average different isp values
    local g is ship:orbit:body:mu/ship:obt:body:radius^2.    // gravitational acceleration constant (m/s²)
    return g * m * p * (1 - e^(-dv/(g*p))) / f.
  }
}

// Delta v requirements for Hohmann Transfer