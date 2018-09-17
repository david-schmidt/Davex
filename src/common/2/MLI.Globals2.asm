.include "Common/MLI.Globals.asm"
;
; ProDOS global equates for Davex
;
mli		= $bf00
datetime	= $bf06
syserr		= $bf09
sysdeath	= $bf0c
serr		= $bf0f ;error code
devnum		= $bf30
devcnt		= $bf31
devlst		= $bf32

bitmap		= $bf58
BitMapSize	= 24

date		= $bf90
time		= $bf92
level		= $bf94
bubit		= $bf95

machid		= $bf98
sltbyt		= $bf99
pfixptr		= $bf9a
mliactv		= $bf9b
cmdadr		= $bf9c

iversion	= $bffd ;sys prog version
kversion	= $bfff ;version # of ProDOS
