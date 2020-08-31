;
; Apple II ROM/hardware
;

;
; Zero-page ROM usage
;
ch		= $24
cv		= $25
basl		= $28
invflg		= $32
csw		= $36
ksw		= $38
range_strt	= $3c
range_end	= $3e
move_to		= $42
himem		= $73
curlin		= $75

;
; Stack, keyboard buffer, reset vector
;
stack		= $100
kbuff		= $200
reset		= $3f2

;
; Hardware locations
;
keyboard	= $c000
off80col	= $c00c
on80col		= $c00d
kbdstrb		= $c010
spkr		= $c030
grafix		= $c050
text		= $c051
page1		= $c054
page2		= $c055
lores		= $c056
hires		= $c057
button0		= $c061
button1		= $c062
button2		= $c063

;
; ROM routines
;
prblnk		= $f948 ; print 3 blanks
f8rom_init	= $fb2f
pwrdup		= $fb6f ; aka SETPWRC
machine		= $fbb3
bascalc		= $fbc1
bell1		= $fbdd
home		= $fc58
wait		= $fca8
crout		= $fd8e
prbyte		= $fdda
cout		= $fded
idroutine	= $fe1f ; GS or not GS
move		= $fe2c
inverse		= $fe80 ; SETINV
normal		= $fe84 ; SETNORM
setkbd		= $fe89
setvid		= $fe93
outport		= $fe95
monitor		= $ff69

;
; ASCII constants
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
