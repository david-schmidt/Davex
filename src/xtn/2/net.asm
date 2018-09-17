;*********************************************
;
; External command for Davex
;
; net -- AppleTalk experimental
;
;  -l = list zones
;  -i = get info
;  -p = printer info
;  -z = lookup entities on specified zone
;  -k = lookup a specific kind of entity
;  -s = list sessions
;  -n = get/set naming mode (-nL, -nS)
;  -r = raw (y/n)
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	;include '::common:net.globals.aii'
	.include "Common/Macros.asm"

.segment	"CODE_9000"


OrgAdr	= $9000	;change as necessary (end below $B000)
; org OrgAdr

BigBuffer	= $A000

MyVersion	= $05
MinVersion	= $11
;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr OrgAdr
	.addr start
	.byte 0,0,0,0
; parameters here
	.byte $80+'l',t_nil
	.byte $80+'i',t_nil
	.byte $80+'z',t_string
	.byte $80+'p',t_nil
	.byte $80+'k',t_string
	.byte $80+'s',t_nil
	.byte $80+'n',t_string
	.byte $80+'r',t_yesno
	.byte 0,0
descr:	pstr "AppleTalk experimental"
	
;*********************************************
; dum xczpage ;32 locations
Count	= xczpage	;ds 2
myPtr	= Count+2	;ds 2
str	= myPtr+2	;ds 2
; dend
;
start:	lda #'i'+$80
	jsr xgetparm_ch
	bcs noInfo
	jsr PrintInfo

noInfo:	lda #'l'+$80
	jsr xgetparm_ch
	bcs noZones
	jsr ListZones

noZones:	lda #'r'+$80
	jsr xgetparm_ch
	bcs noRaw
	jsr DoRaw

noRaw:	lda #'p'+$80
	jsr xgetparm_ch
	bcs noPrinter
	jsr DoPrinter

noPrinter:	lda #'k'+$80
	jsr xgetparm_ch
	bcc doLkup
	lda #'z'+$80
	jsr xgetparm_ch
	bcs noLkup

doLkup:	jsr DoLookup

noLkup:	lda #'s'+$80
	jsr xgetparm_ch
	bcs noSessions
	jsr ListSessions

noSessions:
	lda #'n'+$80
	jsr xgetparm_ch
	bcs noNaming
	jsr DoNaming

noNaming:
	rts


PrintInfo:
	jsr mli
	.byte mli_atlk
	.addr ZoneP
	jsr xmess
	.byte cr
	asc "Your zone is '"
	.byte 0
	lda #>pagebuff
	ldy #<pagebuff
	jsr xprint_path
	jsr xmess
	asc "'"
	.byte cr,0
	jsr xmess
	asc "User prefix is '"
	.byte 0
	jsr mli
	.byte mli_atlk
	.addr UserPfxP
	lda #>pagebuff
	ldy #<pagebuff
	jsr xprint_path
	jsr xmess
	asc "'"
	.byte cr,0
	jsr GetInfo
	jsr xmess
	.byte cr
	asc "Get Info:"
	.byte cr
	asc "  ThisNet = "
	.byte 0
	lda ThisNet+1
	ldy ThisNet
	jsr prWordAY
	jsr crout
	jsr xmess
	asc "  aBridge = $"
	.byte 0
	lda aBridge
	jsr prbyte
	jsr crout
	jsr xmess
	asc "  Completion = "
	.byte 0
	lda compRtn+3
	ldy compRtn+2
	jsr prWordAY
	lda compRtn+1
	jsr prbyte
	lda compRtn
	jsr prbyte
	jsr crout
	jsr xmess
	asc "  Hardware ID = $"
	.byte 0
	lda hwID
	jsr prbyte
	jsr crout
	jsr xmess
	asc "  ROMvers = "
	.byte 0
	lda ROMvers+1
	ldy ROMvers
	jsr prWordAY
	jsr crout
	jsr xmess
	asc "  Node number = $"
	.byte 0
	lda NodeNum
	jsr prbyte
	jsr crout
	rts

UserPfxP:
	.byte 0
	.byte aFIUserPrefix
	.addr 0
	.byte 0
	.addr pagebuff,0

ListZones:
	jsr GetInfo
	lda aBridge
	sta zBridge
	jsr mli
	.byte mli_atlk
	.addr ZoneListP
	bcc ok
;;;                 brk 0
	.byte 0

ok:	jsr xmess
	
	asc "Number of zones = "
	
	.byte 0
	lda numZones+1
	ldy numZones
	jsr prWordAY
	jsr crout
	jsr crout
	lda numZones+1
	ldy numZones
	sta Count+1
	sty Count
	lda #>BigBuffer
	ldy #<BigBuffer
	sta myPtr+1
	sty myPtr
Pr1Zone:	lda Count+1
	ldy Count
	beq dunZones
	lda myPtr+1
	ldy myPtr
	jsr xprint_path
	jsr crout
	jsr xcheck_wait
	ldy #0
	lda (myPtr),y
	sec
	adc myPtr
	sta myPtr
	bcc p_ok
	inc myPtr+1
p_ok:	lda Count
	bne Count_ok
	dec Count+1
Count_ok:	dec Count
	jmp Pr1Zone
dunZones:	jsr crout
	rts

ZoneListP:	.byte 0
	.byte aGetZoneList
zlErr:	.addr 0
	.addr 0,0
	.addr $1000
	.addr BigBuffer,0
zBridge:	.byte 0
	.addr 1	;start index
	.byte 4,5	;retry interval, count
numZones:
	.addr 0
	.addr 0,0	;reserved

ZoneP:	.byte 0
	.byte aGetMyZone
zErr:	.addr 0
	.addr 0,0
	.addr pagebuff,0
	.byte 2
	.byte 20
	.addr 0

InfoP:	.byte 0
	.byte aGetInfo
iErr:	.addr 0
compRtn:	.addr 0,0
ThisNet:	.addr 0
aBridge:	.byte 0
hwID:	.byte 0
ROMvers:	.addr 0
NodeNum:	.byte 0

prWordAY:
	tax
	tya
	pha
	txa
	pha
	lda #'$'+$80
	jsr cout
	pla
	jsr prbyte
	pla
	jmp prbyte

GetInfo:	jsr mli
	.byte mli_atlk
	.addr InfoP
	rts

DoRaw:	lda #1
	sta dirFlag
	jsr mli
	.byte mli_atlk
	.addr PrinterP
	lda dirFlag
	and #%11011110
	pha
	lda #'r'+$80
	jsr xgetparm_ch
	tax
	pla
	cpx #0
	bne rawYES
	ora #%00100000
rawYES:	sta dirFlag
	jsr mli
	.byte mli_atlk
	.addr PrinterP
	rts

DoPrinter:
	lda #1
	sta dirFlag
	jsr mli
	.byte mli_atlk
	.addr PrinterP
	lda #>pagebuff
	ldy #<pagebuff
	jsr xprint_path
	jsr crout
	lda #>pagebuff
	ldy pagebuff	;not #pagebuff!
	iny
	jsr xprint_path
	jsr crout
	ldy pagebuff
	iny
	tya
	sec
	adc pagebuff,y
	tay
	lda #>pagebuff
	jsr xprint_path
	jsr crout
	lda dirFlag
	jsr $fdda
	jsr crout
	rts

PrinterP:
	.byte 0
	.byte aPMSetPrinter
pErr:	.addr 0
	.addr pagebuff,0
dirFlag:	.byte 1
	.addr 4,4,20

DoLookup:
	lda #1
	sta pagebuff
	lda #'='
	sta pagebuff+1

	lda #'k'+$80
	jsr xgetparm_ch
	bcc use_Kind
	lda #>Wildcard
	ldy #<Wildcard
use_Kind:
	sta str+1
	sty str
	ldy #64
copyKind:
	lda (str),y
	sta pagebuff+2,y
	dey
	bpl copyKind

	lda #'z'+$80
	jsr xgetparm_ch
	bcs UseMyZone
	sta str+1
	sty str
	ldy #0
	lda (str),y
	bne ZoneOK
UseMyZone:
	lda #>MyZone
	ldy #<MyZone
	sta str+1
	sty str
ZoneOK:	ldx pagebuff+2
	ldy #0
copyZ:	lda (str),y
	sta pagebuff+3,x
	iny
	inx
	cpy #64
	bcc copyZ

	jsr mli
	.byte mli_atlk
	.addr LookupP

	jsr xmess
	
	asc "Number of matches: $"
	
	.byte 0
	lda lkupCount
	jsr prbyte
	jsr crout

	lda #>BigBuffer
	ldy #<BigBuffer
	sta myPtr+1
	sty myPtr

Pr1Lkup:	lda lkupCount
	beq dunLkup
	jsr PrintEntity
	dec lkupCount
	bne Pr1Lkup
dunLkup:	rts

PrintEntity:
	ldy #1
	lda (myPtr),y
	pha
	dey
	lda (myPtr),y
	tay
	pla
	jsr prWordAY

	lda #' '+$80
	jsr cout
	ldy #2
	lda (myPtr),y
	jsr aByte

	ldy #3
	lda (myPtr),y
	jsr aByte

	lda #5
	jsr advance
	ldy #0
	lda #33
	sec
	sbc (myPtr),y
	pha
	jsr PrintPstr
	pla
	tax
@blanks:	lda #' '+$80
	jsr cout
	dex
	bne @blanks

	jsr PrintPstr
	ldy #0
	lda (myPtr),y
	jsr advance2
	jsr crout
	jmp xcheck_wait

PrintPstr:
	lda myPtr+1
	ldy myPtr
	jsr xprint_path
	ldy #0
	lda (myPtr),y
advance2:
	sec
	.byte $24
advance:	clc
	adc myPtr
	sta myPtr
	bcc adv_ok
	inc myPtr+1
adv_ok:	rts

LookupP:	.byte 0
	.byte aLookupName
lkErr:	.addr 0
	.addr 0,0
lkName:	.addr pagebuff,0
	.byte 4,4
	.addr 0	;reserved
	.addr $1000,BigBuffer,0
	.byte 0	;max matches
lkupCount:
	.byte 0

Wildcard:
	pstr "="
MyZone:	pstr "*"

aByte:	pha
	lda #'$'+$80
	jsr cout
	pla
	jsr prbyte
	lda #' '+$80
	jmp cout

ListSessions:
	jsr mli
	.byte mli_atlk
	.addr ListSessP
	jsr xmess
	
	asc "Number of sessions: "
	
	.byte 0
	lda numSess
	jsr prbyte
	jsr crout
	lda #>BigBuffer
	ldy #<BigBuffer
	sta myPtr+1
	sty myPtr
prSessLp:
	lda numSess
	beq dunSess
	jsr Pr1Sess
	dec numSess
	bne prSessLp
dunSess:	rts

Pr1Sess:	ldy #0
	lda (myPtr),y
	jsr aByte
	iny
	lda (myPtr),y
	jsr xprint_sd
	lda #' '+$80
	jsr cout
	ldy #$1e
	lda (myPtr),y
	pha
	iny
	lda (myPtr),y
	tay
	pla
	jsr prWordAY
	lda #' '+$80
	jsr cout
	ldy #1
	lda (myPtr),y
	lsr a
	lda #'*'+$80
	bcs isUserVol
	lda #' '+$80
isUserVol:
	jsr cout
	lda #' '+$80
	jsr cout
	clc
	lda myPtr
	adc #2
	tay
	lda myPtr+1
	adc #0
	jsr xprint_path
	jsr crout
	jsr xcheck_wait
	clc
	lda myPtr
	adc #32
	sta myPtr
	bcc myPtrOK3
	inc myPtr+1
myPtrOK3:
	rts

ListSessP:
	.byte 0
	.byte aFIListSess
	.addr 0
	.addr $1000,BigBuffer,0
numSess:	.byte 0


DoNaming:
	sta str+1
	sty str
	ldy #0
	lda (str),y
	beq showNaming
	iny
	lda (str),y
	jsr xdowncase
	cmp #'l'+$80
	beq longNaming
	cmp #'s'+$80
	beq shortNaming
	jsr xmess
	
	asc "*** -nL or -nS expected"
	
	.byte cr,0
	jmp xerr

longNaming:
	lda #$80
	bmi setNaming
shortNaming:
	lda #0
setNaming:
	sta namingFlag
	jsr mli
	.byte mli_atlk
	.addr NamingP

	jsr xmess
	asc "Naming is "
	.byte 0
	lda namingFlag
	bmi nIsLong
	jsr xmess
	asc "short."
	.byte cr,0
	rts
nIsLong:	jsr xmess
	asc "long."
	.byte cr,0
	rts
	rts	;%%% remove this

showNaming:	lda #0
	sta namingDir
	beq setNaming

NamingP:	.byte 0
	.byte aFINaming
	.addr 0
namingDir:	.byte $80
namingFlag:	.byte 0
