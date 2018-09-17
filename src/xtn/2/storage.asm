;*********************************************
;
; External command for Davex
;
; storage -- show fragmentation and sparseness
;
; storage <pathname> [-f] [-s]
;
;*********************************************
;
; 10-Feb-90 DAL  v0.9
;
;*********************************************
;
; Converted to MPW IIgs 21-Sep-92 DAL
;
;*********************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"


.segment	"CODE_A000"

OrgAdr	= $A000	;change as necessary (end below $B000)
; org OrgAdr

MyVersion	= $09
MinVersion	= $12
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
	.byte $80+'f',t_nil
	.byte $80+'s',t_nil
	.byte 0,0
descr:	pstr "show fragmentation and sparseness"
	
;*********************************************
; 32 locations at xczpage
;
Str		= xczpage	;ds 2
myTemp		= Str+2		;ds 1
Device		= myTemp+1	;ds 1
blockCount	= Device+1	;ds 2
prevBlock	= blockCount+2	;ds 2
fragCount	= prevBlock+2	;ds 2
sparseCount	= fragCount+2	;ds 2
blocksNeeded	= sparseCount+2	;ds 2 ;blks to visit (calc from eof)

;*********************************************
BlockBuff	= filebuff2
MasterBuff	= filebuff2+$200

;*********************************************
sSEEDLING	= 1
sSAPLING	= 2
sTREE		= 3
sPASCAL		= 4
sEXTEND		= 5
sDIR		= $D
sVOL		= $F

;*********************************************
start:
	sta Str+1
	sty Str
	sta infoPath+1
	sty infoPath

	jsr mli
	.byte mli_gfinfo
	.addr infoParms
	bcs blark
	lda devnum
	sta Device
	lda infoStg
	cmp #sDIR
	beq isDIR
	cmp #sVOL
	beq isDIR
	jsr xmess
	.byte cr
	cstr_cr "*** not a directory"
	jmp xerr

blark:	jmp xProDOS_err

infoParms:
	.byte 10
infoPath:
	.res 2
infoAcc:
	.res 2
infoType:
	.res 1
infoAux:
	.res 1
infoStg:
	.res 1
infoBlks:
	.res 2
	.res 8	;date/time

isDIR:	jsr xpush_level
	lda Str+1
	ldy Str
	jsr xdir_setup
nextEnt:
	jsr xread1dir
	bcs noMore
	jsr visit_entry
	jmp nextEnt
noMore:	jmp xdir_finish

;
; visit_entry--show information about a file
;
visit_entry:
	jsr print_name
	jsr print_stg
	jsr print_ftype
	jsr calculate
	jsr print_blocks
	jsr print_frag
	jsr print_sparse
	jsr xcheck_wait
	jmp crout
;
; print_name
;
print_name:
	lda catbuff
	and #$0f
	beq @out
	tax
	ldy #1
@name:	lda catbuff,y
	ora #$80
	jsr cout
	iny
	dex
	bne @name
@loop:	jsr spout
	iny
	cpy #18
	bcc @loop
@out:
;
; spout--print a space
;
spout:	lda #$a0
	jmp cout

;
; print storage type
;
print_stg:
	lda catbuff
	and #$f0
	lsr a
	sta myTemp
	lsr a
	lsr a
	lsr a
	clc
	adc myTemp
	tax
	ldy #9
pstg1:	lda stTypes,x
	ora #$80
	jsr cout
	inx
	dey
	bne pstg1
	jsr spout
	jmp spout

stTypes:
	asc "[deleted]"
	asc "seedling "
	asc "sapling  "
	asc "tree     "
	asc "Pascal   "
	asc "extended "
	asc "[unknown]"
	asc "[unknown]"
	asc "[unknown]"
	asc "[unknown]"
	asc "[unknown]"
	asc "[unknown]"
	asc "[unknown]"
	asc "directory"
	asc "[unknown]"
	asc "volume   "

;
; print filetype and auxiliary type
;
print_ftype:
	ldx #'+'+$80
	lda catbuff
	and #$f0
	cmp #$50
	beq PrintPlus
	ldx #$a0
PrintPlus:
	txa
	jsr cout
	lda catbuff+$10
	jsr xprint_ftype
	jsr xmess
	asc " $"
	.byte 0
	lda catbuff+$20
	jsr prbyte
	lda catbuff+$1f
	jsr prbyte
	jsr spout
	jmp spout
;
; print block count
;
print_blocks:
	lda blockCount+1
	ldy blockCount
prdecay:
	sta xnum+1
	sty xnum
	lda #0
	sta xnum+2
	ldy #6
	jmp xprdec_pady
;
; print fragmentation
;
print_frag:
	lda fragCount+1
	ldy fragCount
	jsr prdecay
	lda #'f'+$80
	jmp cout
;
; print sparseness
;
print_sparse:
	lda sparseCount+1
	ldy sparseCount
	jsr prdecay
	lda #'s'+$80
	jmp cout
;
; calculate--
;   for file with entry in catbuff, find out
;   the degree of fragmentation and sparseness
;
calculate:
	lda #0
	ldx #<-1
	stx prevBlock+1
	stx prevBlock
	sta blockCount+1
	sta blockCount
	sta sparseCount+1
	sta sparseCount
	stx fragCount+1
	stx fragCount

CalcByType:
	lda catbuff
	and #$f0
	lsr a
	lsr a
	lsr a
	tax
	lda calc_table+1,x
	pha
	lda calc_table,x
	pha
	jsr calc_needed
	lda catbuff+$12
	ldy catbuff+$11
	rts

calc_table:
	.addr nothing-1,visit_block-1,Sapling-1,Tree-1
	.addr nothing-1,Extended-1,nothing-1,nothing-1
	.addr nothing-1,nothing-1,nothing-1,nothing-1
	.addr nothing-1,Directory-1,nothing-1,Directory-1

nothing:
	rts

Sapling:
	stx sap_xsave
	ldx #>BlockBuff
	jsr ReadBlock
	jsr visit_block
	ldx #0
@loop:	lda BlockBuff,x
	tay
	lda BlockBuff+$100,x
	jsr visit_block
	inx
	beq @done
	lda blockCount
	cmp blocksNeeded
	bne @loop
	lda blockCount+1
	cmp blocksNeeded+1
	bne @loop
@done:	ldx sap_xsave
	rts

sap_xsave: .res 1

Tree:	ldx #>MasterBuff
	jsr ReadBlock
	jsr visit_block
	ldx #0
treeLoop:
	lda MasterBuff,x
	tay
	lda MasterBuff+$100,x
	jsr Sapling
	inx
	lda blockCount
	cmp blocksNeeded
	bne treeLoop
	lda blockCount+1
	cmp blocksNeeded+1
	bne treeLoop
	rts

Extended:
	ldx #>BlockBuff
	jsr ReadBlock
	jsr visit_block
	lda BlockBuff+$100
	sta res_storage
	lda BlockBuff+$102
	ldy BlockBuff+$101
	sta res_key+1
	sty res_key
	lda BlockBuff+$107
	ldx BlockBuff+$106
	ldy BlockBuff+$105
	sta res_eof+2
	stx res_eof+1
	sty res_eof

	lda BlockBuff+0	;data fork stg type
	asl a
	asl a
	asl a
	asl a
	sta catbuff
	lda BlockBuff+2
	ldy BlockBuff+1
	sta catbuff+$12
	sty catbuff+$11
	lda BlockBuff+7
	ldx BlockBuff+6
	ldy BlockBuff+5
	sta catbuff+$17
	stx catbuff+$16
	sty catbuff+$15
	jsr CalcByType
; do the resource fork
	lda res_storage
	asl a
	asl a
	asl a
	asl a
	sta catbuff
	lda res_key+1
	ldy res_key
	sta catbuff+$12
	sty catbuff+$11
	lda res_eof+2
	ldx res_eof+1
	ldy res_eof
	sta catbuff+$17
	stx catbuff+$16
	sty catbuff+$15
	jsr CalcByType
	rts
res_storage:
	.res 1
res_key:
	.res 2
res_eof:
	.res 3

Directory:
	ldx #>BlockBuff
	jsr ReadBlock
	jsr visit_block
	lda BlockBuff+3
	ldy BlockBuff+2
	bne Directory
	tax
	bne Directory
	rts

;
; calc blocksNeeded from catbuff.eof
;
calc_needed:
	lda catbuff+$17
	lsr a
	sta blocksNeeded+1
	lda catbuff+$16
	ror a
	sta blocksNeeded
	bcs @inc
	lda catbuff+$15		; [TODO] symbolic -- offset to eof
	beq @noInc
@inc:	ldx #blocksNeeded
	jsr inc_zp
@noInc:	rts

;
; visit_block(ay)
;
visit_block:
	stx vb_xsave
	ldx #blockCount
	jsr inc_zp
; increment sparse count if block number 0
	tax
	bne vb_nonzer
	cpy #0
	bne vb_nonzer
	ldx #sparseCount
	jsr inc_zp
	jmp keepPrev
vb_nonzer:
; increment fragCount if block not in sequence
	ldx #prevBlock
	jsr inc_zp
	cmp prevBlock+1
	bne outSeq
	cpy prevBlock
	beq inSeq
outSeq:	ldx #fragCount
	jsr inc_zp
inSeq:	sta prevBlock+1
	sty prevBlock
keepPrev:
	ldx vb_xsave
	rts

vb_xsave:
	.res 1
;
; increment 2-byte value at X, X+1
;
inc_zp:	inc 0,x
	bne inczpx
	inc 1,x
inczpx:	rts

;
; ReadBlock(ay,Device,x=page) --> BlockBuff
;
ReadBlock:
	stx rbBuffer+1
	stx rbCheat1+2
	stx rbCheat2+2
	sta rbNum+1
	sty rbNum
	tax
	bne rbReal
	tya
	bne rbReal
	jmp rbZero
rbReal:	lda Device
	sta rbDevnum
	jsr mli
	.byte mli_readblk
	.addr rbParms
	bcc rbOK
	jmp xProDOS_err
rbOK:	lda rbNum+1
	ldy rbNum
	rts

rbZero:	lda #0
	tax
rbCheat1: sta $ff00,x	;self-mod
rbCheat2: sta $ff00,x	;self-mod
	inx
	bne rbCheat1
	beq rbOK

rbParms:
	.byte 3
rbDevnum:
	.res 1
rbBuffer:
	.addr BlockBuff
rbNum:	.res 2

