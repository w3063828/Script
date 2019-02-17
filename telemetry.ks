// Ship's delta v   Needs gravity sensor
LOCK GRAV TO SHIP:SENSORS:GRAV.
FUNCTION TLM_DELTAV {
  LIST ENGINES IN shipEngines.
  SET dryMass TO SHIP:MASS - ((SHIP:LIQUIDFUEL + SHIP:OXIDIZER) * 0.005).
  RETURN shipEngines[0]:ISP * GRAV * LN(SHIP:MASS / dryMass).
}

// Time to impact
FUNCTION TLM_TTI {
  PARAMETER margin.

  LOCAL d IS ALT:RADAR - margin.
  LOCAL v IS -SHIP:VERTICALSPEED.
  LOCAL g IS grav.

  RETURN (SQRT(v^2 + 2 * g * d) - v) / g.
}