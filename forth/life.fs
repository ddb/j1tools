
d# 8 constant xsize
d# 8 constant ysize

: world-size xsize ysize * ;

: i>xy xsize /mod ;
: xy>i ysize mod swap xsize mod swap xsize * + ;

: array-index ( x y address -- element-address )
  >r xy>i cells r> + ;

: array-index! array-index ! ;
: array-index@ array-index @ ;

: dump-world ( world -- )
  cr
  s" +--------+" type cr
  world-size d# 0 do
    i xsize mod 0= if
      s" |" type
    then
    dup i cells + @ 0= if
      space
    else
      [char] * emit
    then
    i 1+ xsize mod 0= if
      s" |" type cr
    then
  loop
  s" +--------+" type cr ;

variable world 
  world-size cells allot
world world-size cells d# 0 fill

variable next-world
  world-size cells allot
next-world world-size cells d# 0 fill


: glider
  d# 1 d# 2 d# 2 world array-index!
  d# 1 d# 3 d# 2 world array-index!
  d# 1 d# 4 d# 2 world array-index!
  d# 1 d# 4 d# 3 world array-index!
  d# 1 d# 3 d# 4 world array-index! ;

: ul-nbr ( x y -- nbr-state )
  1- swap 1- swap world array-index@ ;

: uc-nbr ( x y -- nbr-state )
  1- world array-index@ ;

: ur-nbr ( x y -- nbr-state )
  1- swap 1+ swap world array-index@ ;

: l-nbr ( x y -- nbr-state )
  swap 1- swap world array-index@ ;

: r-nbr ( x y -- nbr-state )
  swap 1+ swap world array-index@ ;

: ll-nbr ( x y -- nbr-state )
  1+ swap 1- swap world array-index@ ;

: lc-nbr ( x y -- nbr-state )
  1+ world array-index@ ;

: lr-nbr ( x y -- nbr-state )
  1+ swap 1+ swap world array-index@ ;

: nbr-count ( x y -- nbr-count )
  2>r
  2r@ ul-nbr 
  2r@ uc-nbr +
  2r@ ur-nbr +
  2r@ l-nbr +
  2r@ r-nbr +
  2r@ ll-nbr +
  2r@ lc-nbr +
  2r> lr-nbr + ;

: next-state ( x y -- 1 or 0 )
  2dup world array-index@ if 
    nbr-count 
    dup d# 2 >= swap d# 3 <= and if d# 1 else d# 0 then
  else
    nbr-count 
    d# 3 = if d# 1 else d# 0 then
  then ;

: build-next-state ( -- )
  world-size d# 0 do
    i i>xy next-state next-world i cells + !
  loop ;

: generation
  build-next-state
  next-world world world-size cells cmove ;

: display-generations ( n -- )
  d# 0 do
    generation
    world dump-world
  loop ;

: glider-demo
  glider
  d# 20 display-generations ;
