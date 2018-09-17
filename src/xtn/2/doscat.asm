;********************************************************
;
; Davex external command DOSCAT (catalog DOS 3.3 disk)
;
; Programmed by Kevin R. Cooper, April 11, 1989.
;
; (1) Original coding.  v0.1           (KRC 11-Apr-89)
;
; DAL 8-Jun-89 ==> v1.0
;   Converted source to Merlin Pro format;
;   edited messages.
;
; DAL 9-Jun-89 ==> v1.0
;   Extra 'a' and 'b' filetypes renamed 'X' and 'Y'.
;   Added -f option to restrict filetypes listed.
;   Added -l y|n to restrict listing to locked or
;     unlocked files.
;   Added display of volume number from VTOC (-v
;     suppresses it).
;   Removed assumption that all DOS 3.3 disks
;     have 35 tracks and 16 sectors.
;   "1 sectors free" fixed.
;   -o option added for creating exec files from
;     catalog listings.
;
;********************************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;********************************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"
	;

.segment	"CODE_AC00"

orgadr	= $ac00

MyVersion	= $10
MinVersion	= $12
;========================================================
; org orgadr
;
; Davex command info
;
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr orgadr
	.addr start
	.byte 0,0,0,0
;
; parameters here
;
	.byte 0,t_devnum
	.byte $80+'o',t_string
	.byte $80+'v',t_nil
	.byte $80+'f',t_string
	.byte $80+'l',t_yesno
	.byte 0,0

descr:	pstr "catalog a DOS 3.3 disk--by Kevin R. Cooper"
	
;========================================================
; dum xczpage
track	= xczpage	;.res 1
sector	= track+1	;.res 1
sec_ptr	= sector+1	;.res 2
SecOffset	= sec_ptr+2	;.res 1
TypeBit	= SecOffset+1	;.res 1
FreeSecs	= TypeBit+1	;.res 2
Types	= FreeSecs+2	;.res 2
TypeChar	= Types+2	;.res 1
str	= TypeChar+1	;.res 2 ; -o string
length	= str+2	;.res 1 ;length of -o string
NameLimit	= length+1	;.res 1
; dend

BlockBuff	= filebuff	;ds $200
;========================================================
hi_bit	= $80
cr	= $8d
locr	= cr-hi_bit
ctrl	= $40

crout	= $fd8e
cout	= $fded
;========================================================
start:	sta read_unit
	jsr crout

	lda #$11
	sta track
	lda #0
	sta sector
	jsr read_sector
;
	ldy #$27
	lda (sec_ptr),y
	cmp #122
	bne notDOS33
;
	ldy #$36
	lda (sec_ptr),y
	bne notDOS33
;
	iny	;$37
	lda (sec_ptr),y
	cmp #1
	bne notDOS33
;
	jmp DoCatalog
;
notDOS33:	jsr xmess
	asc "*** not a DOS 3.3 disk"
	.byte cr,0
	jmp xerr	;return to Davex
;
done:	rts
;
DoCatalog:
	lda #'o'+$80
	jsr xgetparm_ch
	sta str+1
	sty str
	bcc SkipHeader

	jsr PrintVolNum
	jsr CountFreeSecs
	lda FreeSecs+1
	ldy FreeSecs
	jsr xprdec_2
	jsr xmess
	asc " sector"
	.byte 0
	lda FreeSecs+1
	ldy FreeSecs
	jsr xplural
	jsr xmess
	asc " free"
	.byte cr,cr,0

SkipHeader:
;
; get track/sector of next catalog sector
;
NextCatSec:
	ldy #1
	lda (sec_ptr),y
	beq done
;
	sta track
	iny
	lda (sec_ptr),y
	sta sector
;
	jsr read_sector
;
	lda #$b
	sta SecOffset
;
NextFileDesc:
	ldy SecOffset
	lda (sec_ptr),y
	beq done	;unused file desc marks end of cat
;
	cmp #$ff	;deleted?
	beq Advance
;
	jsr CheckPrint
	bcs Advance

	jsr prFileDesc
	jsr xcheck_wait
	bcs done	;user abort
;
Advance:	lda SecOffset
	cmp #$dd
	beq NextCatSec

	clc
	adc #$23
	sta SecOffset
	jmp NextFileDesc

;========================================================

CheckPrint:
	jsr CheckLock
	bcs chkDone
	jsr CheckType
chkDone:	rts

CheckLock:	lda #'l'+$80
	jsr xgetparm_ch
	bcs LockOK
	beq Unlocked
	lda #$80
Unlocked:	ldy SecOffset
	iny
	iny
	eor (sec_ptr),y
	bpl LockOK
	sec
	rts
LockOK:	clc
	rts

CheckType:
	lda #'f'+$80
	jsr xgetparm_ch
	bcs TypeOK
	sta Types+1
	sty Types

	jsr ComputeType
	jsr xdowncase
	sta TypeChar

	ldy #0
	lda (Types),y
	beq TypeBad
	tay
chkType:	lda (Types),y
	jsr xdowncase
	cmp TypeChar
	beq TypeOK
	dey
	bne chkType
TypeBad:	sec
	rts
TypeOK:	clc
	rts
;========================================================
ComputeType:
	ldy SecOffset
	iny
	iny
	lda #$40
	sta TypeBit
	lda (sec_ptr),y
	and #$7f
	ldx #7
srchType:
	cmp TypeBit
	bcs gotType
	dex
	lsr TypeBit
	bne srchType
gotType:	lda TypeChrs,x
	rts
TypeChrs:
	asc "TIABSRXY"
	
;========================================================
prFileDesc:
	lda #'o'+$80
	jsr xgetparm_ch
	bcc prFormatted
	ldy SecOffset
	iny
	iny
	ldx #' '+$80
	lda (sec_ptr),y
	bpl PrLockChar
	ldx #'*'+$80
PrLockChar:
	txa
	jsr cout
;
	jsr ComputeType
	jsr cout
;
	lda SecOffset
	clc
	adc #$21
	tay
	lda (sec_ptr),y
	sta xnum
	iny	;$22
	lda (sec_ptr),y
	sta xnum+1
	lda #0
	sta xnum+2
	ldy #3
	jsr xprdec_pady
;
	lda #' '+$80
	jsr cout
;
	jsr PrintName
	jmp crout	;rts

prFormatted:
	ldy #0
	lda (str),y
	sta length
fmtChar:	cpy length
	bcs fmtDone
	iny
	lda (str),y
	jsr prFmtChar
	jmp fmtChar
fmtDone:	jmp crout

prFmtChar:	ora #$80
	cmp #'='+$80
	beq PrintName0
	jmp cout

PrintName0:	tya
	pha
	jsr PrintName
	pla
	tay
	rts

PrintName:	clc
	lda SecOffset
	adc #32
	tay
	iny
scanBlnk:	dey
	lda (sec_ptr),y
	cmp #$A0
	beq scanBlnk
	iny
	sty NameLimit
	ldy SecOffset
	iny
	iny
NameChar:	iny
	cpy NameLimit
	bcs NameDone
	lda (sec_ptr),y
	ora #$80
	jsr cout
	jmp NameChar
NameDone:	rts

;========================================================
PrintVolNum:
	lda #'v'+$80
	jsr xgetparm_ch
	bcc noVolNum
	jsr xmess
	asc "DOS 3.3 volume #"
	.byte 0
	ldy #6
	lda (sec_ptr),y
	tay
	lda #0
	jsr xprdec_2
	jmp crout
noVolNum:	rts

;========================================================
;
; read a sector from a 5.25 disk
;
SecBlock:	.byte 0,7,6,6,5,5,4,4,3,3,2,2,1,1,0,7
BlkHalf:	.byte 0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1
;
; rdBlkNumber = track * 8 + SecBlock [sector]
;
read_sector:
	lda #0
	sta rdBlkNum+1
	lda track
	asl a
	rol rdBlkNum+1
	asl a
	rol rdBlkNum+1
	asl a
	rol rdBlkNum+1
	sta rdBlkNum
;
	ldx sector
	lda SecBlock,x
	clc
	adc rdBlkNum
	sta rdBlkNum
	bcc rdBlkNum_ok
	inc rdBlkNum+1
rdBlkNum_ok:
;
	lda #0
	sta sec_ptr
	lda #>BlockBuff
	clc
	adc BlkHalf,x
	sta sec_ptr+1
;
read_block:
	jsr mli
	.byte mli_readblk
	.addr RdBlkParms
	bcs bad_read
	rts
bad_read:
	jmp xProDOS_err
;
RdBlkParms:
	.byte 3
read_unit:
	.res 1
	.addr BlockBuff
rdBlkNum:
	.res 2
;
CountFreeSecs:
	lda #0
	sta FreeSecs
	sta FreeSecs+1
	ldy #$38
CountFree1:
	lda (sec_ptr),y
	jsr count_free
	iny
	bne CountFree1
	rts

count_free:
	asl a
	bcc next_bit
	inc FreeSecs
	bne next_bit
	inc FreeSecs+1
next_bit:
	tax
	bne count_free
	rts

zzz_the_end:
