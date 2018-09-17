;*************************************************
;*************************************************
;
; 'alias' -- external command for Davex
;
; alias -- view and modify Davex aliases
;
; alias [-s] [-l] [-r] <str1> <str2>
;
; alias            displays all aliases
; alias <a> <b>    adds alias
; alias -r <a>     removes alias <a>
; alias -s         saves aliases to %aliases
; alias -l         loads aliases from %aliases
;
;*************************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*************************************************

.segment	"CODE_A000"

OrgAdr	= $A000	;change as necessary (end below $B000)
.org	OrgAdr	; Makes the listing more readable, though it doesn't really org the code - the linker does that.
	.include "../Common/Globals.asm"
	.include "../Common/Apple.globals.asm"
	.include "../Common/Mli.globals.asm"
	.include "../Common/Macros.asm"
	;include 'm16.util2'
low_cr	= $0D
;
MyVersion	= $09
MinVersion	= $12
MinVerAux	= $05
;*************************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr OrgAdr
	.addr start
	.byte MinVerAux,0,0,0
; parameters here
	.byte 0,t_string
	.byte 0,t_string
	.byte $80+'r',t_nil
	.byte $80+'s',t_nil
	.byte $80+'l',t_nil
	.byte 0,0
descr:
	asc_hi "display or modify command aliases"
;*************************************************
; dum xczpage ;32 locations
AliasPages	= xczpage
AliasP	= AliasPages+1
AliasEnd	= AliasP+2
myP	= AliasEnd+2
str1	= myP+2
str2	= str1+2
char	= str2+2
count	= char+1	;.res 2
; dend
;
start	= *
	sta str1+1
	sty str1

	lda #1
	jsr xgetparm_n
	sta str2+1
	sty str2

	ldx #1
	jsr xshell_info
	sta AliasP+1
	sty AliasP
	sty AliasEnd
	stx AliasPages
	txa
	clc
	adc AliasP+1
	sta AliasEnd+1

	lda #$80+'l'
	jsr xgetparm_ch
	bcs noLoad
	jsr load_aliases
noLoad:

	jsr DoAlias

	lda #$80+'s'
	jsr xgetparm_ch
	bcs noSave
	jsr save_aliases
noSave:
	rts

;*************************************************
;
; handle adding, removing, or showing aliases
;
DoAlias:
	lda #$80+'r'
	jsr xgetparm_ch
	bcs noRmv
	jmp remove_alias

noRmv:
	ldy #0
	lda (str1),y
	bne doAdd
	lda (str2),y
	bne doAdd
	jsr xgetnump
	cmp #2
	beq show_aliases
	rts

doAdd:	jmp add_alias

;*************************************************
;
; Display all the aliases
;
show_aliases:
	jsr CalcUsedSize
	jsr xprdec_2
	jsr xmess
	asc_hi " bytes used (of "
	.byte 0
	lda AliasPages
	ldy #0
	jsr xprdec_2
	jsr xmess
	asc_hi ") to store these aliases:"
	.byte low_cr
	asc_hi "  "
	.byte 0
;
	lda AliasP+1
	ldy AliasP
	sta myP+1
	sty myP
ShowA1:	lda (myP),y
	beq ShowedA
	jsr NeatCout
	bcs ShowedA
	iny
	bne ShowA1
	inc myP+1
	bne ShowA1
ShowedA:	rts

NeatCout:	ora #$80
	cmp #$8d
	beq isCR
	jsr cout
	clc
	rts
isCR:	jsr xcheck_wait
	bcs isCR2
	jsr crout
	lda #$80+' '
	jsr cout
	jsr cout
	clc
isCR2:	rts

;*************************************************
;
; Save aliases to %aliases file
;
save_aliases:
	lda #>AliasName
	ldy #<AliasName
	jsr xbuild_local
	sta aPath+1
	sty aPath
	sta acPath+1
	sty acPath

	jsr mli
	.byte mli_create
	.addr CreateA
	bcc CreateOK
	cmp #err_dupfil
	bne DiskError
CreateOK:

	jsr mli
	.byte mli_open
	.addr OpenA
	bcs DiskError

	lda aRef
	sta aRef2
	sta aRef3
	sta aRef4

	jsr CalcUsedSize
	sta WriteA+5
	sty WriteA+4
	jsr mli
	.byte mli_write
	.addr WriteA
	bcs DiskError

	jsr mli
	.byte mli_getmark
	.addr MarkA
	jsr mli
	.byte mli_seteof
	.addr MarkA

	jsr mli
	.byte mli_close
	.addr CloseA
	bcs DiskError
	rts

;*************************************************
;
; Load aliases from %aliases file
;
load_aliases:
	lda #>AliasName
	ldy #<AliasName
	jsr xbuild_local
	sta aPath+1
	sty aPath

	jsr mli
	.byte mli_open
	.addr OpenA
	bcs DiskError

	lda aRef
	sta aRef2
	sta aRef3

	lda AliasPages
	ldy #0
	sta ReadA+5
	sty ReadA+4
	jsr mli
	.byte mli_read
	.addr WriteA
	php
	pha
	jsr strip7
	pla
	plp
	bcs DiskError

	jsr mli
	.byte mli_close
	.addr CloseA
	bcs DiskError
	rts

DiskError:	jmp xProDOS_err

CreateA:	.byte 7
acPath:	.addr 0
	.byte $C3	;access
	.byte tTXT	;filetype
	.addr 0	;auxtype
	.byte 1	;storage type
	.addr 0,0	;create date/time

OpenA:	.byte 3
aPath:	.addr 0
	.addr filebuff
aRef:	.byte 0

ReadA:
WriteA:	.byte 4
aRef2:	.byte 0
	.addr Aliases,$0000,0

MarkA:	.byte 2
aRef4:	.byte 0
	.byte 0,0,0
CloseA:	.byte 1
aRef3:	.byte 0

AliasName:
	asc_hi "Aliases"

strip7:	lda AliasPages
	sta count
	lda AliasP+1
	ldy AliasP
	sta myP+1
	sty myP
	ldy #0
strip1:	lda (myP),y
	and #%01111111
	sta (myP),y
	dey
	bne strip1
	dec count
	bne strip1
	rts

;*************************************************
;
; remove an alias
;
remove_alias:
	ldy #0
	lda (str2),y
	beq rmv2ok
	jsr xmess
	.byte cr
	asc_hi "*** too many parameters for removing an alias"
	.byte low_cr,0
	jmp xerr
rmv2ok:
	jsr FindAlias
	bcc rmvFound
	jsr xmess
	.byte cr
	asc_hi "*** no such alias found"
	.byte low_cr,0
	jmp xerr
rmvFound:	jsr remove_it
	rts
;
; Add an alias, possibly replacing an existing one
;
add_alias:
	jsr FindAlias
	bcs addMissing

	lda #1
	jsr xredirect
	jsr xmess
	asc_hi "Okay to replace existing alias "
	.byte $A2,0
	lda str1+1
	ldy str1
	jsr xprint_path
	lda #$A2
	jsr cout
	lda #$80+'n'
	jsr xyesno2
	php
	lda #-1
	jsr xredirect
	plp
	bne ReplacIt
	rts
ReplacIt:	jsr remove_it
addMissing:
	jsr CalcUsedSize
	ldy #0
	clc
	lda (str1),y
	adc (str2),y
	adc #3
	adc count
	lda count+1
	adc #0
	cmp AliasPages
	bcc haveRoom
	jsr xmess
	.byte cr
	asc_hi "*** no room for that alias"
	.byte low_cr,0
	jmp xerr

haveRoom:
	ldy #0
	lda (str1),y
	tax
	bne aNameOK
	jsr xmess
	.byte cr
	asc_hi "*** empty string is not a legal alias"
	.byte low_cr,0
	jmp xerr
aNameOK:	iny
	lda (str1),y
	jsr CramChar
	dex
	bne aNameOK

	lda #$80+' '
	jsr CramChar

	ldy #0
	lda (str2),y
	tax
	beq aDefDone
AddDef:	iny
	lda (str2),y
	jsr CramChar
	dex
	bne AddDef
aDefDone:	lda #$0d
	jsr CramChar
	lda #0
	jmp CramChar

;
; CramChar -- append A to (myP)
;
CramChar:	sty cramY
	ldy #0
	sta (myP),y
	ldy cramY
	inc myP
	bne cram_ok
	inc myP+1
cram_ok:	rts
cramY:	.byte 0

;
; FindAlias -- return CLC if found, myP points to it
;
FindAlias:
	lda AliasP+1
	ldy AliasP
	sta myP+1
	sty myP
FindA1:
	jsr compare
	bcc FoundIt
	jsr NextAlias
	ldy #0
	lda (myP),y
	bne FindA1
	sec
FoundIt:	rts
;
; compare--check if alias at myP matches str1, returning
; CLC if they do (and preserving myP)
;
compare:
	lda myP+1
	pha
	lda myP
	pha

	ldy #0
	lda (str1),y
	tax
	beq NoMatch
	iny	;Y=1
	jsr decP
cmp1:
	lda (str1),y
	jsr xdowncase
	sta char
	jsr FetchChar
	and #%01111111
	beq NoMatch
	jsr xdowncase
	cmp char
	bne NoMatch
	iny
	dex
	bne cmp1
	jsr FetchChar
	cmp #$80+' '
	bne NoMatch
matches:	clc
compared:
	pla
	sta myP
	pla
	sta myP+1
	rts
NoMatch:
	sec
	bcs compared
;
; increment myP and return the character it points at
;
FetchChar:	inc myP
	bne P2ok
	inc myP+1
P2ok	= *
	sty ytemp
	ldy #0
	lda (myP),y
	ldy ytemp
	ora #%10000000
	rts
ytemp:	.res 1
;
; advance myP to next alias
;
NextAlias:	jsr FetchChar
	cmp #$8d
	beq FetchChar
	and #%01111111
	bne NextAlias
	rts

;*************************************************
;
; Remove the alias that myP is pointing at
;
remove_it:
	ldy #0
	lda (myP),y
	beq removed
	pha
	jsr KillCharP
	pla
	and #$7f
	cmp #$0d
	bne remove_it
removed:	rts
;
; Kill a character at myP, shifting forward all the
; characters after myP until AliasEnd
;
KillCharP:
	lda myP+1
	pha
	lda myP
	pha
KillLoop:
	ldy #1
	lda (myP),y
	dey
	sta (myP),y
	inc myP
	bne p_ok
	inc myP+1
p_ok:	lda myP+1
	cmp AliasEnd+1
	bne KillLoop
	lda myP
	cmp AliasEnd
	bne KillLoop
	pla
	sta myP
	pla
	sta myP+1
	rts
;
; CalcUsedSize--return used bytes in AY,
; myP pointing at the $00 marker at the end
; of the alias data
;
CalcUsedSize:
	lda #0
	sta count
	sta count+1
	lda AliasP+1
	ldy AliasP
	sta myP+1
	sty myP
	ldy #0
cus1:	lda (myP),y
	beq cus_done
	inc count
	bne count_ok
	inc count+1
count_ok:	inc myP
	bne cus1
	inc myP+1
	bne cus1
cus_done:	lda count+1
	ldy count
	rts
;
decP:	lda myP
	bne decP1
	dec myP+1
decP1:	dec myP
	rts
