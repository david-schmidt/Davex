;
; Apple /// ROM/hardware
;
himem	= $73

range_strt	= $3c
range_end	= $3e
move_to	= $42

sos_coldstart	= $e833
sos_coldstart_my_bank = sos_coldstart+$44
sos_coldstart_set_level_parms = sos_coldstart+$45 
sos_coldstart_set_level_num =  sos_coldstart+$46

monitor	= $1910	;$f901

columns40	= $00
columns80	= $03

csw	= $36
ksw	= $38
invflg	= $32

grafix	= $c050
text	= $c051
page1	= $c054
page2	= $c055
lores	= $c056
hires	= $c057

keyboard	= $c000
kbdstrb	= $c010
spkr	= $c030
button0	= $c061
button1	= $c062
button2	= $c063

boot	= $f4ee
e_reg	= $ffdf
;
; ascii constants
;
ctrl	= $40
cr	= $0d
space	= $a0
esc	= $9b
null	= $00
nul	= null
bs	= $08
lf	= $8a
tab	= $89
