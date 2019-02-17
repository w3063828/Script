
//set TRTM to ship:facing:inverse *target:position.
//set tgtvec to VECDRAWARGS( V(0,0,0),target:position,green,"ship",1,true).
set vec1 TO body:position.
set vec2 TO  target:position. 
set vec1x2 to VCRS(vec1, vec2).
print vec1x2.
set finalvec to VCRS(vec1x2, vec1).
print finalvec.

SET anArrow TO VECDRAW(
      body:position,
      finalvec,
      RGB(1,0,0),
      "See the arrow?",
      1,
      TRUE
    ).
    log (finalvec) to mylog.