;*********************************************
;
; External command for Davex
;
; vrestore -- reconstruct a ProDOS volume from
;             a file created by vstore
;
; Modified 4-May-88 DL ==> v1.1
;   added "-f" flag to force destruction
;   of destination volume without asking
;   (requested by Bob Church)
; Modified 22-Jun-88 DL ==> v1.3
;   suspends I/O redir when asking for
;   permission to destroy volume
;
;*********************************************
;
; Converted to MPW IIgs 21-Sep-92 DAL
;
;*********************************************
;*********************************************
;*
;* The input file is SPARSE (unwritten areas
;* correspond to unallocated blocks on the
;* volume), and the first block of each file
;* contains header information:
;*
;* $00: $60
;* $01: 'VSTORE (Davex)'  (string)
;* $10: file format ($00)
;* $11: VSTORE version [1]
;*
;* $20: device-num saved from [1]
;* $21: total blocks   [4]
;* $25: used blocks [4]
;* $29: volume name saved [16]
;*
;* $40: file number    [1]
;* $41: starting blk # [4]
;*
;*********************************************
	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"


.segment	"CODE_A800"


;*********************************************
Buffer	= $8800
BuffLen	= $2000
OrgAdr	= $A800
; org OrgAdr
;*********************************************
;*********************************************
MyVersion	= $13
MinVersion	= $12
MinVaux	= $1	;v1.21
;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr OrgAdr
	.addr start
	.byte MinVaux,0,0,0
; parameters here
	.byte 0,t_path	;pathname of stored image
	.byte 0,t_devnum	;device number to write
	.byte $80+'f',t_nil	;Force overwrite dest vol
	.byte 0,0
descr:	pstr "restore a ProDOS volume from a file"
	
;*********************************************
BlockBuff	= filebuff2
RootBlock	= 2	;root of volume directory
;*********************************************
; dum xczpage
filenum	= xczpage	;ds 1
filebase	= filenum+1	;ds 2 ;first block # in file
Block	= filebase+2	;ds 2 ;current block #
TotalBlocks	= Block+2	;ds 2
vnlength	= TotalBlocks+2	;ds 1
target_dev	= vnlength+1	;ds 1
source_dev	= target_dev+1	;ds 1
path	= source_dev+1	;ds 1
; dend
;*********************************************
start	= *
	sta op_path+1
	sty op_path
	sta path+1
	sty path

	lda #1
	jsr xgetparm_n
	sta target_dev
	sta dest_dev
	jsr verify	;A=device to destroy
	bcc continue
	rts
continue	= *

	lda #0
	sta filenum
	sta filebase
	sta filebase+1
	sta Block
	sta Block+1
	sta source_dev

	jsr NextFile

OneChunk	= *
	lda #>Buffer
	sta rd_adr+1
	lda #>BuffLen
	sta rd_len+1
	jsr mli
	.byte mli_read
	.addr rd_parms
	jsr MaybeNextDisk
	bvs OneChunk
	bcs blkerr
;
; Write 1 or more blocks from Buffer to dest disk
;
	lda #>Buffer
	sta wb_adr+1

WriteAnother	= *
	lda Block+1
	ldy Block
	jsr WriteDestBlk
	bcs blkerr
;
	inc Block
	bne blk_ok
	inc Block+1
blk_ok	= *

	inc wb_adr+1
	inc wb_adr+1
	dec rd_xfer+1
	dec rd_xfer+1
	bne WriteAnother
;
	lda Block+1
	cmp TotalBlocks+1
	bne cmp_x
	lda Block
	cmp TotalBlocks
cmp_x:	bcc OneChunk

	lda rd_ref
	jmp CloseA

blkerr:	jmp xProDOS_err

rd_parms:
	.byte 4
rd_ref:	.byte 0
rd_adr:	.addr 0
rd_len:	.addr 0
rd_xfer:	.addr 0
;*********************************************
;
; ReadHeader
;
rhExit:	jmp xProDOS_err
ReadHeader	= *
	lda #2
	sta rd_len+1
	lda #>BlockBuff
	sta rd_adr+1
	jsr mli
	.byte mli_read
	.addr rd_parms
	bcs rhExit

	ldx #$0e
bh2:	lda HdrImg,x
	cmp BlockBuff,x
	bne badHeader
	dex
	bne bh2

	lda #MyVersion
	cmp BlockBuff+$12	;min version req'd
	bcc badVersion

	lda BlockBuff+$22
	ldy BlockBuff+$21
	sta TotalBlocks+1
	sty TotalBlocks

	lda BlockBuff+$40	;file number

	rts

badHeader:	jsr xmess
	.byte cr
	asc "*** not a volume image"
	.byte cr,0
	jmp xerr
badVersion:	jsr xmess
	.byte cr
	asc "*** image requires vrestore v"
	.byte 0
	lda BlockBuff+$12
	jsr xprint_ver
	jsr xmess
	asc "+"
	.byte cr,0
	jmp xerr

HdrImg:	.byte $60
	asc "VSTORE [Davex]"
	.byte 0
	.byte 0	;file format
	.byte MyVersion
	.byte 0	;min vrestore version

WriteDestBlk:	;write BlockBuff to block AY
	sta wb_num+1
	sty wb_num
	jsr mli
	.byte mli_writeblk
	.addr wb_parms
	rts
;
wb_parms:
	.byte 3
dest_dev:
	.byte 0
wb_adr:	.addr 0
wb_num:	.addr 0

;*********************************************
;
; MaybeNextDisk -- if we got an EOF err reading
;   the source file, switch to the next one
;
MaybeNextDisk:
	bcc mnd_x
	cmp #err_eof
	bne mnd_err
	jsr NextFile
	bit MND_RTS	;set V
	rts
mnd_err:	sec
mnd_x:	clv
MND_RTS:	rts

;*********************************************
;
; Open a source file, return ref num in A
;
OpenSource:
	jsr mli
	.byte mli_open
	.addr open_parms
	bcs os_err
	lda devnum
	sta source_dev
	lda open_ref
os_err:	rts
;*********************************************
open_parms:
	.byte 3
op_path:	.addr 0
	.addr filebuff
open_ref:
	.byte 0
;*********************************************
;
; Make sure it's ok to destroy the target
; volume
;
verify	= *
	sta wb_dev
	jsr mli
	.byte mli_readblk
	.addr wb_p
	bcs ver_ok
;
	lda #'f'+$80	;added 4-May-88 DL
	jsr xgetparm_ch	;
	bcc ver_ok	;
;
	jsr suspend
	jsr xmess
	asc "Okay to destroy "
	.byte 0
	jsr print_vname
	jsr xyesno
	jsr restore
	sec
	bne ver_ok
	rts
;
ver_ok:	clc
	rts
;
wb_p:	.byte 3
wb_dev:	.byte 0
	.addr BlockBuff,2
;
print_vname	= *
	lda BlockBuff
	ora BlockBuff+1
	bne pv_nonpro
	lda BlockBuff+4
	and #$0f
	beq pv_nonpro
	lda BlockBuff+4
	and #$f0
	cmp #$e
	bcc pv_nonpro
;
	lda #'/'+$80
	jsr cout
	lda BlockBuff+4
	and #$0f
	sta vnlength
	ldy #0
pv1:	lda BlockBuff+5,y
	jsr xdowncase
	jsr cout
	iny
	dec vnlength
	bne pv1
	rts
;
pv_nonpro:	jsr xmess
	asc "non-ProDOS disk"
	.byte 0
	rts
;*********************************************
;*********************************************
;
; NextFile()
; {
;   close source file if one is open already
;   filenum++;
;    :
;    :
; }
;
NextFile	= *
;
; close file if one is already open
;
	lda open_ref
	beq not_open
	jsr CloseA
not_open	= *
;
; next file number; get next disk
;
	inc filenum
	lda filenum
	cmp #1
	beq first_file

iv_again	= *
	jsr InsertVolume
	jsr NextName
	bcs bad_online

first_file	= *
;
; OpenSource
;
	jsr OpenSource
	bcs opens_err
	sta rd_ref

	jsr ReadHeader
	cmp filenum
	bne bad_seq

	lda BlockBuff+$42
	ldy BlockBuff+$41
	cmp Block+1
	bne bad_blocknum
	cpy Block
	bne bad_blocknum

	clc
	lda #0
	rts

bad_online:	pha
	jsr crout
	pla
	jsr xProDOS_er
	jsr crout
	jmp iv_again

bad_seq:	jsr xmess
	.byte cr
	asc "Disk out of sequence!"
	.byte $8d,0
	jmp wrong_disk

bad_blocknum:	jsr xmess
	.byte cr
	asc "File starts at wrong block number!"
	.byte $8d,0
;jmp wrong_disk

wrong_disk:	lda rd_ref
	jsr CloseA
	jmp iv_again

opens_err	= *
	ldx source_dev
	beq nextf_err
	pha
	jsr crout
	pla
	jsr xProDOS_er
	jsr crout
	jmp iv_again

nextf_err:	jmp xProDOS_err
;
; InsertVolume -- prompt for a new volume in same s/d
;
InsertVolume	= *
	jsr xmess
	asc "Insert disk "
	.byte 0
	lda #0
	ldy filenum
	jsr xprdec_2
	jsr xmess
	asc " in "
	.byte 0
	lda source_dev
	jsr xprint_sd
	jsr xmess
	asc " and hit RETURN "
	.byte 0
iv1:	lda #$a0
	jsr xrdkey
	and #$7f
	cmp #$0d
	beq iv_done
	cmp #$20
	beq iv_done
	cmp #$03
	beq iv_abort
	cmp #$1b
	beq iv_abort
	jmp iv1
iv_done:	jmp crout
iv_abort:	lda #der_abort
	jmp xProDOS_err
;
; NextName--
;   If (path) is full pathname, replace the volume
;   name with the new volume name (same device).
;
;   If (path) is a partial pathname, append it to
;   the new volume name.
;
nn_err:	jmp xProDOS_err

NextName	= *
	lda source_dev
	sta online_dev
	jsr mli
	.byte mli_online
	.addr online_p
	bcs nn_err
	lda NewVname+1
	and #$0f
	bne vname_ok
	lda NewVname+2
	sec
	rts
vname_ok	= *

	lda NewVname+1
	and #$0f
	tax
	inx
	inx
	stx NewVname
	lda #'/'
	sta NewVname+1
	sta NewVname,x

	ldy #64
cp1:	lda (path),y
	sta pagebuff,y
	lda NewVname,y
	sta (path),y
	dey
	bpl cp1

	ldx #1
	lda pagebuff+1
	and #$7f
	cmp #'/'
	bne append_path

srch_slash:	inx
	lda pagebuff,x
	and #$7f
	cmp #'/'
	bne srch_slash
	inx
;
; append pagebuff,x... to (path)
;
append_path	= *
	cpx pagebuff
	beq app_cont
	bcc app_cont
	clc
	rts
app_cont:	ldy #0
	lda (path),y
	clc
	adc #1
	sta (path),y
	tay
	lda pagebuff,x
	sta (path),y
	inx
	bne append_path
;;;	brk
	.byte 0

online_p:	.byte 2
online_dev:	.res 1
	.addr NewVname+1
NewVname:	.res 20
;****************************************************
CloseA:	sta cla_ref
	jsr mli
	.byte mli_close
	.addr cla_parms
	rts

cla_parms:	.byte 1
cla_ref:	.byte $ff
;****************************************************
;
; suspend -- suspend I/O redir so we can
;            ask a question safely
;
suspend:	lda #1
	jmp xredirect
;
; restore -- resume I/O redirection if it
;            was active before
;
restore:	php
	pha
	lda #<-1
	jsr xredirect
	pla
	plp
	rts
;*********************************************
