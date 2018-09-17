;*********************************************
;
; External command for Davex
;
; ftdump -- display contents of a FTD file ($42)
;
; ftdump <wildpath>
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"
	;

.segment	"CODE_9000"


Apostrophe	= $27


OrgAdr	= $9000	;change as necessary (end below $B000)
; org OrgAdr

MyVersion	= $09
MinVersion	= $11
stringBuf	= filebuff2
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
	.byte 0,t_wildpath
	.byte 0,0
descr:	pstr "display contents of a filetype descriptor file ($42)"
	
;*********************************************
; dum xczpage ;32 locations
temp_y	= xczpage	;ds 1
indexMark	= temp_y+1	;ds 2
count	= indexMark+2	;ds 2
chars	= count+2	;ds 1
goodFlags	= chars+1	;ds 2
prevFtype	= goodFlags+2	;ds 2
prevAux	= prevFtype+2	;ds 4
prevFlags	= prevAux+4	;ds 2
; dend
;
ack:	jmp xProDOS_err

start:
	sta openPath+1
	sty openPath
	sta infoPath+1
	sty infoPath

	jsr mli
	.byte mli_gfinfo
	.addr infoP
	bcs ack
	lda infoFtype
	cmp #$42
	beq ftOkay
	jsr xmess
	.byte cr

	
	asc "*** filetype must be $42"
	
	.byte cr,0
	jmp xerr

ftOkay:
	jsr xmess

	
	asc " Auxiliary type: $"
	
	.byte 0
	lda infoAux+1
	ldy infoAux
	jsr pr_ay
	lda infoAux+1
	bne aux_3p
	jsr xmess

	
	asc " (reserved for Apple)"
	
	.byte 0
	jmp didAux
aux_3p:	jsr xmess

	
	asc " (third-party)"
	
	.byte 0
didAux:	jsr crout

	jsr mli
	.byte mli_open
	.addr openP
	bcs ack0
	lda openRef
	sta readRef
	sta markRef
	sta closeRef

	lda #>ftdHeader
	ldy #<ftdHeader
	sta readBuf+1
	sty readBuf
	lda #0
	ldy #12
	sta readLen+1
	sty readLen
	jsr mli
	.byte mli_read
	.addr readP
	bcc ok2
ack0:	jmp xProDOS_err
ok2:

	jsr ShowHeader
	jsr crout

	lda ftdOffInd+1
	lda ftdNumEnt+1
	ldy ftdNumEnt
	sta count+1
	sty count
	ldy ftdOffInd
	sta indexMark+1
	sty indexMark
	lda #0
	sta goodFlags
	sta goodFlags+1
	ldy #7
zerPrev:	sta prevFtype,y
	dey
	bpl zerPrev
nextIndRec:
	lda count+1
	ora count
	beq no_more
	lda indexMark+1
	ldy indexMark
	sta mark+1
	sty mark
	jsr mli
	.byte mli_setmark
	.addr markP
	bcs ack0

	lda ftdRecSize+1
	ldy ftdRecSize
	sta readLen+1
	sty readLen
	lda #>pagebuff
	ldy #<pagebuff
	sta readBuf+1
	sty readBuf
	jsr mli
	.byte mli_read
	.addr readP
	bcs ack2
	jsr mli
	.byte mli_getmark
	.addr markP
	lda mark+1
	ldy mark
	sta indexMark+1
	sty indexMark

	jsr ShowEntry
	jsr crout
	jsr xcheck_wait

	lda count
	bne no_decC
	dec count+1
no_decC:	dec count
	ldy #7
copyPrev:
	lda pagebuff,y
	sta prevFtype,y
	dey
	bpl copyPrev
	jmp nextIndRec

no_more:
	lda ftdFlags
	cmp goodFlags
	bne badFlags
	lda ftdFlags+1
	cmp goodFlags+1
	beq ok_flags
badFlags:
	jsr xmess

	
	asc "[warning: Flags in header should be $"
	
	.byte 0
	lda goodFlags+1
	ldy goodFlags
	jsr pr_ay
	jsr xmess

	
	asc "]"
	
	.byte 13,0
ok_flags:

	jsr mli
	.byte mli_close
	.addr closeP
	rts

ack2:	jmp xProDOS_err

ShowEntry:
	jsr xmess

	
	asc "     Filetype: $"
	
	.byte 0
	lda pagebuff+1
	ldy pagebuff
	jsr pr_ay

	jsr xmess
	.byte cr

	
	asc "      Auxtype: $"
	
	.byte 0
	lda pagebuff+5
	ldy pagebuff+4
	jsr pr_ay
	lda pagebuff+3
	ldy pagebuff+2
	jsr pr_ay

	jsr xmess
	.byte cr

	
	asc "        Flags: $"
	
	.byte 0
	lda pagebuff+7
	ldy pagebuff+6
	jsr pr_ay
	lda pagebuff+7
	ora goodFlags+1
	sta goodFlags+1
	lda pagebuff+6
	ora goodFlags
	sta goodFlags

	jsr xmess
	.byte cr

	
	asc "String offset: $"
	
	.byte 0
	lda pagebuff+9
	ldy pagebuff+8
	sta mark+1
	sty mark
	jsr pr_ay

	jsr xmess
	.byte cr

	
	asc "  Description: "
	
	.byte 0
	jsr mli
	.byte mli_setmark
	.addr markP
	bcs ack3

	lda #>stringBuf
	ldy #<stringBuf
	sta readBuf+1
	sty readBuf
	ldy #0
	sty readLen+1
	iny
	sty readLen
	jsr mli
	.byte mli_read
	.addr readP
	bcs ack3

	lda stringBuf
	sta readLen
	inc readBuf
	jsr mli
	.byte mli_read
	.addr readP
	bcs ack3

	jsr printStr

	lda readXfr
	cmp readLen
	beq read_ok
	jsr xmess

	
	asc "[warning: unable to read entire string]"
	
	.byte 13,0
read_ok:
	rts

ack3:	jmp xProDOS_err

printStr:	lda #Apostrophe+$80
	jsr cout

	lda #0
	sta chars
	ldy #0
ps1:	cpy stringBuf
	bcs psDun
	lda stringBuf+1,y
	ora chars
	sta chars
	lda stringBuf+1,y
	jsr safeCout
	iny
	bne ps1
psDun:
	lda #Apostrophe+$80
	jsr cout
	jsr crout
	lda chars
	bpl no_highchars
	jsr xmess

	
	asc "[note: high-128 characters in string]"
	
	.byte 13,0
no_highchars:
	rts

safeCout:	ora #$80
	cmp #$a0
	bcs doCout
	lda #'.'+$80
doCout:	jmp cout
;*********************************************
ftdHeader:
ftdVersion:	.res 2
ftdFlags:	.res 2
ftdNumEnt:	.res 2
ftdSpare:	.res 2
ftdRecSize:	.res 2
ftdOffInd:	.res 2
;*********************************************
openP:	.byte 3
openPath:	.res 2
openBuff:
	.addr filebuff
openRef:	.res 1

markP:	.byte 2
markRef:	.res 1
mark:	.res 3

readP:	.byte 4
readRef:	.res 1
readBuf:	.res 2
readLen:	.res 2
readXfr:	.res 2

closeP:	.byte 1
closeRef:	.res 1

infoP:	.byte 10
infoPath:	.res 2
infoAcc:	.res 1
infoFtype:	.res 1
infoAux:	.res 2
infoStg:	.res 1
infoBlks:	.res 2
info_dt:	.res 8
;*********************************************
ShowHeader:
	jsr xmess

	
	asc "        Version: $"
	
	.byte 0
	lda ftdVersion+1
	ldy ftdVersion
	jsr pr_ay

	jsr xmess
	.byte cr

	
	asc "          Flags: $"
	
	.byte 0
	lda ftdFlags+1
	ldy ftdFlags
	jsr pr_ay

	jsr xmess
	.byte cr

	
	asc "         NumEnt: $"
	
	.byte 0
	lda ftdNumEnt+1
	ldy ftdNumEnt
	jsr pr_ay

	jsr xmess
	.byte cr

	
	asc "      SpareWord: $"
	
	.byte 0
	lda ftdSpare+1
	ldy ftdSpare
	jsr pr_ay

	jsr xmess
	.byte cr

	
	asc "IndexRecordSize: $"
	
	.byte 0
	lda ftdRecSize+1
	ldy ftdRecSize
	jsr pr_ay

	jsr xmess
	.byte cr

	
	asc "  OffsetToIndex: $"
	
	.byte 0
	lda ftdOffInd+1
	ldy ftdOffInd
	jsr pr_ay

	jmp crout

pr_ay:	sty temp_y
	jsr prbyte
	lda temp_y
	jmp prbyte
