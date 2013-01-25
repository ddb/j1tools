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

: factorial ( u -- u )
    1- ?dup if
        dup factorial *
    else
        d# 1
    then
;

: main
    d# 7
    factorial
    s" Hello world" h# 8000 swap cmove
;

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

\ .lst file is a human-readable disassembly 
s" j1.lst" create-output-file
d# 0
h# 2000 disassemble-block

