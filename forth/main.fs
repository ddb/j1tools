( Main for WGE firmware                      JCB 13:24 08/24/10)

\ warnings off
\ require tags.fs

include crossj1.fs
meta
    : TARGET? 1 ;
    : build-debug? 1 ;

include basewords.fs
target
include hwdefs.fs

2 org
module[ eveything"
include nuc.fs

d# 8 constant xsize
d# 8 constant ysize

: world-size xsize ysize * ;

: wrap swap dup 0< if + else swap 2dup 1- > if - else drop then then ;
: i>xy ( i -- x y ) xsize /mod ;
: xy>i ( x y -- i ) ysize wrap swap xsize wrap swap xsize * + ;
: xy   ( x y address -- element-address ) -rot xy>i + ;
: xy!  ( value x y address -- ) xy c! ;
: xy@  ( x y address -- value ) xy c@ ;

: emit-digit s>d <# # #> type ;

: plus [char] + emit ;
: vbar [char] | emit ;
: star [char] * emit ;
: dash [char] - emit ;
: semi [char] ; emit ;
: esc[ d# 27 emit [char] [ emit ;
: cls esc[ [char] 2 emit [char] J emit ;
: pn base @ >r decimal d# 0 u.r r> base ! ;
: ;pn semi pn ;
: at-xy 1+ swap 1+ swap esc[ pn ;pn d# 72 emit ;
: dashes d# 0 do dash loop ;
: bar plus xsize dashes plus cr ;

: dump-world ( world -- )
  cls d# 0 d# 0 at-xy bar
  world-size d# 0 do
    i xsize mod 0= if vbar then
    dup i + c@ if star else space then
    i 1+ xsize mod 0= if vbar cr then
  loop
  bar drop ;

: dump-world-raw ( world -- )
  cr
  world-size d# 0 do
    space
    dup i + c@ 0= if d# 0 else d# 1 then
    emit-digit
    i 1+ xsize mod 0= if cr then
  loop ;

: clear-world world-size d# 0 fill ;

create world 64 allot 
create next-world 64 allot 

: init-world
  world clear-world
  next-world clear-world ;

: alive
  d# 1 -rot world xy! ;

: glider
  init-world
  d# 1 d# 1 alive
  d# 2 d# 1 alive
  d# 3 d# 1 alive
  d# 3 d# 2 alive
  d# 2 d# 3 alive ;

: cell-alive? ( x y -- t or f ) world xy@ 0<> abs ;
: ul-nbr ( x y -- nbr-state ) 1- swap 1- swap cell-alive? ;
: uc-nbr ( x y -- nbr-state ) 1- cell-alive? ;
: ur-nbr ( x y -- nbr-state ) 1- swap 1+ swap cell-alive? ;
: l-nbr ( x y -- nbr-state ) swap 1- swap cell-alive? ;
: r-nbr ( x y -- nbr-state ) swap 1+ swap cell-alive? ;
: ll-nbr ( x y -- nbr-state ) 1+ swap 1- swap cell-alive? ;
: lc-nbr ( x y -- nbr-state ) 1+ cell-alive? ;
: lr-nbr ( x y -- nbr-state ) 1+ swap 1+ swap cell-alive? ;

: nbr-count ( x y -- nbr-count )
  2dup ul-nbr >r
  2dup uc-nbr r> + >r
  2dup ur-nbr r> + >r
  2dup l-nbr r> + >r
  2dup r-nbr r> + >r
  2dup ll-nbr r> + >r
  2dup lc-nbr r> + >r
  lr-nbr r> + ;

: next-state ( x y -- 1 or 0 )
  2dup world xy@ 0<> if 
    nbr-count dup d# 2 = swap d# 3 = or
  else
    nbr-count d# 3 = 
  then ;

: build-next-state ( -- )
  world-size d# 0 do
    i i>xy next-state next-world i + c!
  loop ;

: generation
  build-next-state
  next-world world world-size cmove ;

: display-generations ( n -- )
  d# 0 do
    generation
    world dump-world
  loop ;

: glider-demo
  glider
  d# 20 display-generations ;

: glider-loop
  glider
  world dump-world
  begin
    generation
    world dump-world
  again ;
  

: step-demo
  glider
  world dump-world-raw
  begin
    generation world dump-world-raw key drop
  again ;

: debug-number
  s>d <# # #> type ;

: pause key drop ;

: serial-loop
  begin
    key 
    dup d# 13 = if 
      cr drop
    else 
      dup d# 127 = if
        drop
        d# 8 emit space d# 8 emit
      else
        emit
      then
    then
  d# 0 until ;

: debug-test
  d# 23 s>d <# #s #> type ;

: main
  glider-loop
  cr cr cr
  s" j1 FORTH processor" type cr cr
  space s" ok" type cr
  serial-loop
;

\ ' emitchar 'emit !

]module

\ Write the bootstrap vector
0 org
code 0jump
    main ubranch
end-code

meta

hex

: create-output-file w/o create-file throw to outfile ;

\ .mem is a memory dump formatted for use with the Xilinx
\ data2mem tool.
s" j1.mem" create-output-file
:noname
    s" @ 20000" type cr
    4000 0 do i t@ s>d <# # # # # #> type cr 2 +loop
; execute

\ .bin is a little-endian binary memory dump
s" j1.bin" create-output-file
:noname 4000 0 do i t@ dup emit 8 rshift emit 2 +loop ; execute

\ .coe file for block memory loader
s" j1.coe" create-output-file
s" memory_initialization_radix=16;" type cr
s" memory_initialization_vector=" type cr
:noname
    4000 0 do i t@ s>d <# # # # # #> type i 3FFE < if [char] , emit else [char] ; emit then cr 2 +loop
; execute

\ .lst file is a human-readable disassembly 
s" j1.lst" create-output-file
d# 0
h# 2000 disassemble-block

