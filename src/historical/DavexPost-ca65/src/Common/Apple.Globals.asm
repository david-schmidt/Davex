;
; Apple ROM/hardware
;
himem	= $73

range_strt	= $3c
range_end	= $3e
move_to	= $42
move	= $fe2c

stack	= $100
kbuff	= $200
curlin	= $75

outport	= $fe95
prbyte	= $fdda
wait	= $fca8
home	= $fc58
cout	= $fded
crout	= $fd8e
reset	= $3f2
pwrdup	= $fb6f
csw	= $36
ksw	= $38
bascalc	= $fbc1
basl	= $28
inverse	= $fe80
normal	= $fe84
ch	= $24
cv	= $25
invflg	= $32

grafix	= $c050
text	= $c051
page1	= $c054
page2	= $c055
lores	= $c056
hires	= $c057
off80col	= $c00c
on80col	= $c00d

keyboard	= $c000
kbdstrb	= $c010
spkr	= $c030
button0	= $c061
button1	= $c062
button2	= $c063
;
; ascii constants
;
ctrl	= $40
cr	= $8d
space	= $a0
esc	= $9b
null	= $00
nul	= null
bs	= $88
lf	= $8a
tab	= $89
