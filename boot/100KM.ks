
ag5 on.
 if SHIP:ALTITUDE > 100 { 
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
 runpath("0:/ascent.ks").
 }
If periapsis > 100000{
 runpath("Circularize.ks").  
}