runpath("0:/knu.ks"). local genetics is import("genetics.ks").

genetics["seek"](lex(
  "file", "0:/vanguard.json",
  "autorevert", true,
  "arity", 3,
  "size", 25,
  "fitness", fitness_fn@
)).

function fitness_fn {
  parameter k.
  hudtext("kP: " + k[0], 15, 1, 25, yellow, false).
  hudtext("kI: " + k[1], 15, 1, 25, yellow, false).
  hudtext("kD: " + k[2], 15, 1, 25, yellow, false).
  local pid_throttle is 0.
  lock throttle to pid_throttle.
  lock steering to heading(90, 90).
  set ship:control:pilotmainthrottle to 0.
  stage.

  local pid is pidloop(k[0], k[1], k[2], 0, 1).
  local last_time is time:seconds.
  local total_error is 0.

  set pid:setpoint to 10.
  local start_time is time:seconds.
  until time:seconds > start_time + 60 {
    if time:seconds > start_time + 10 set pid:setpoint to 20.
    if time:seconds > start_time + 20 set pid:setpoint to 15.
    if time:seconds > start_time + 30 set pid:setpoint to 10.
    if time:seconds > start_time + 40 set pid:setpoint to 15.
    if time:seconds > start_time + 50 set pid:setpoint to 20.
    set pid_throttle to pid:update(time:seconds, distanceToGround).
    set total_error to total_error + abs(pid:error * (time:seconds - last_time)).
    set last_time to time:seconds.
    wait 0.001.
  }

  return gaussian(total_error, 0, 250).
}

function gaussian {
  parameter value, targetq, width.
  return constant:e^(-1 * (value-targetq)^2 / (2*width^2)).
}
  function distanceToGround {
  return altitude - body:geopositionOf(ship:position):terrainHeight.
}