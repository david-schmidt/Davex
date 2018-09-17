;*********************************************
;
; External command for Davex
;
; vstore -- store a ProDOS volume into a file
;
; 5-Feb-90 DAL ==> v1.1
;   creates file with filetype $E0;8004 now
;
;*********************************************
;
; Converted to MPW IIgs 21-Sep-92 DAL
;
;*********************************************
;*********************************************
;*
;* The output file is SPARSE (unwritten areas
;* correspond to unallocated blocks on the
;* volume), and the first block of each file
;* contains header information:
;*
;* $00: $60
;* $01: 'VSTORE (Davex)'  (string)
;* $10: file format ($00)
;* $11: VSTORE version [1]
;* $12: minimum VRESTORE version required [1]
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
Buffer	= $9000
BuffEnd	= Buffer+$1100
OrgAdr	= $A800
; org OrgAdr
;*********************************************
;*********************************************
MyVersion	= $11
MinVersion	= $11
MinVRestoreV	= $10
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
	.byte 0,t_path	;which device to format
	.byte 0,t_path	;pathname to store in
	.byte 0,0
descr:	pstr "store a ProDOS volume into a file"
	
;*********************************************
BlockBuff	= filebuff2
bmBlockBuff	= filebuff2+$200
RootBlock	= 2	;root of volume directory
;*********************************************
; dum xczpage
path	= xczpage	;ds 2
my_dev	= path+2	;ds 1
;  int1 filenum; -- suffix for target file (xxx.01, .02, etc)
;  int2 filebase;    -- auxtype for file (1st block #)
filenum	= my_dev+1	;ds 1 ;xxx.01, xxx.02, ...
filebase	= filenum+1	;ds 2 ;auxtype for file (block#)
Block	= filebase+2	;ds 2 ;current block #
WrBlock	= Block+2	;ds 2
BuffPos	= WrBlock+2	;ds 1
UsedBlocks	= BuffPos+1	;ds 2
TotalBlocks	= UsedBlocks+2	;ds 2
target_dev	= TotalBlocks+2	;ds 1
; dend
;*********************************************
err1:	jmp xProDOS_err
;
start:
;
;  GetInfo(volume);  if(error) xProDOS.err;
;  if(info.stype!=VOL) error("*** not a volume");
;
	sta InfoPath+1
	sty InfoPath
	jsr mli
	.byte mli_gfinfo
	.addr InfoParms
	bcs err1
	lda devnum
	sta my_dev
	sta src_unit
	sta src_unit2
	lda blocks+1
	ldy blocks
	sta UsedBlocks+1
	sty UsedBlocks
	lda AuxType+1
	ldy AuxType
	sta TotalBlocks+1
	sty TotalBlocks
;
	lda stype
	cmp #$f
	beq isvol
	jsr xmess
	.byte cr
	asc "*** not a volume"
	.byte cr,0
	jmp xerr
isvol:
;
	lda #1
	jsr xgetparm_n
	sta cr_path+1
	sty cr_path
	sta op_path+1
	sty op_path
	sta path+1
	sty path
;
	jsr bmNewDisk
;
;  filenum=0;
;  Block=0;
;
	lda #0
	sta filenum
	sta Block
	sta Block+1
	sta WrBlock+1
	sty WrBlock

	lda #>Buffer
	sta BuffPos

	jsr NextFile
OneBlock:
	lda Block+1
	ldy Block
	jsr bmapUsed
	bcc SkipBlock
;
	lda Block+1
	ldy Block
	ldx BuffPos
	jsr ReadSrcBlk
	bcs blkerr2

	inc BuffPos
	inc BuffPos
	lda BuffPos
	cmp #>BuffEnd
	bcc buff_ok
	jsr FlushBuff
buff_ok:
	jmp IncBlock

blkerr2:	jmp xProDOS_err

SkipBlock:
	jsr FlushBuff
	jsr mli
	.byte mli_geteof
	.addr eof_parms
	bcs blkerr2
	lda eof_val+1
	clc
	adc #2
	sta eof_val+1
	lda eof_val+2
	adc #0
	sta eof_val+2
	jsr mli
	.byte mli_seteof
	.addr eof_parms
	bcs blkerr
	jsr mli
	.byte mli_setmark
	.addr eof_parms
	bcs blkerr
	jmp IncBlock

eof_parms:
	.byte 2
eof_ref:	.byte 0
eof_val:	.byte 0,0,0

IncBlock:
	inc Block
	bne blk_ok
	inc Block+1
blk_ok:
	lda Block+1
	cmp bmTotalBlocks+1
	bne cmp_x
	lda Block
	cmp bmTotalBlocks
cmp_x:	bcc OneBlock
	jsr FlushBuff

	lda wr_ref
close_a:	sta cl_ref
	jsr mli
	.byte mli_close
	.addr cl_parms
	rts
;
; FlushBuff -- write out all buffered blocks to the
;              output file and set BuffPos to beginning
;              of Buffer
;
FlushBuff:
	lda #>Buffer
	ldy #0
	sta wr_addr+1
	sty wr_addr
fbuff1:	lda wr_addr+1
	cmp BuffPos
	bcs fbuff_done
	jsr mli
	.byte mli_write
	.addr wr_parms
	bcc blk_fits
	cmp #err_full
	bne blkerr
	lda wr_addr+1
	pha
	jsr NextFile
	pla
	sta wr_addr+1
	jmp fbuff1
blk_fits:
	inc wr_addr+1
	inc wr_addr+1
	inc WrBlock
	bne wb_ok
	inc WrBlock+1
wb_ok:	jmp fbuff1
fbuff_done:
	lda #>Buffer
	sta BuffPos
	rts

cl_parms:
	.byte 1
cl_ref:	.byte 0

blkerr:	jmp xProDOS_err

wr_parms:
	.byte 4
wr_ref:	.byte 0
wr_addr:	.addr $7777
	.addr $200
	.addr 0
;*********************************************
;
; NextFile()
; {
;   close output file if one is open already
;   filenum++;
;   filebase=blk;
;   InsertVolume();
;   r = CreateOpen(path,filenum,filebase);
;   BuildHeader
; }
;
NextFile:
	lda open_ref
	beq not_open
	jsr close_a
not_open:

	lda WrBlock+1
	ldy WrBlock
	sta filebase+1
	sty filebase
	inc filenum
	lda filenum
	cmp #1
	beq first_file

	jsr InsertVolume
	jsr NextName

first_file:
	lda path+1
	ldy path
	jsr CreateOpen
	sta wr_ref
	sta eof_ref

	lda #>BlockBuff
	ldy #<BlockBuff
	sta wr_addr+1
	sty wr_addr
	jsr BuildHeader
	jsr mli
	.byte mli_write
	.addr wr_parms
	bcs nextferr
	rts

nextferr:	jmp xProDOS_err
;
; InsertVolume -- prompt for a new volume in same s/d
;
InsertVolume:
	jsr xmess
	asc "Insert next disk in "
	.byte 0
	lda target_dev
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
iv_abort:
	lda #der_abort
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

NextName:
	lda target_dev
	sta online_dev
	jsr mli
	.byte mli_online
	.addr online_p
	bcs nn_err

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

srch_slash:
	inx
	lda pagebuff,x
	and #$7f
	cmp #'/'
	bne srch_slash
	inx
;
; append pagebuff,x... to (path)
;
append_path:
	cpx pagebuff
	beq app_cont
	bcc app_cont
	rts
app_cont:
	ldy #0
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

online_p:
	.byte 2
online_dev:
	.res 1
	.addr NewVname+1
NewVname:
	.res 20
;****************************************************
;
; BuildHeader -- construct image of 1-block header
;                for current file in BlockBuff
;
bhExit:	jmp xProDOS_err
BuildHeader:
	lda #>RootBlock
	ldy #RootBlock
	ldx #>BlockBuff
	jsr ReadSrcBlk
	bcs bhExit
;
	lda BlockBuff+4
	and #%00001111
	tay
	sta pagebuff
cpvn0:	lda BlockBuff+4,y
	and #%01111111
	sta pagebuff,y
	dey
	bne cpvn0
;
	lda #0
	tax
bh1:	sta BlockBuff,x
	sta BlockBuff+$100,x
	inx
	bne bh1
;
	ldx #$12
bh2:	lda HdrImg,x
	sta BlockBuff,x
	dex
	bpl bh2
;
	lda my_dev
	sta BlockBuff+$20
	lda TotalBlocks+1
	ldy TotalBlocks
	sta BlockBuff+$22
	sty BlockBuff+$21
	lda filenum
	sta BlockBuff+$40
	lda filebase+1
	ldy filebase
	sta BlockBuff+$42
	sty BlockBuff+$41
	lda UsedBlocks+1
	ldy UsedBlocks
	sta BlockBuff+$26
	sty BlockBuff+$25
	ldy pagebuff
cpvn:	lda pagebuff,y
	jsr upcase
	sta BlockBuff+$29,y
	dey
	bpl cpvn
	rts

HdrImg:	.byte $60
	asc "VSTORE [Davex]"
	.byte 0
	.byte 0	;file format
	.byte MyVersion
	.byte MinVRestoreV

upcase:	and #%01111111
	cmp #'a'
	bcc upcx
	and #%11011111
upcx:	rts
;****************************************************
;
; CheckFileSys    -- last mod 20-Jan-87 DL
;
; Determines the file system used on the source
; disk.
;
; Calls ReadSrcBlk to read block AY from source disk
; to BlockBuff (BlockBuff contents are lost).
;
; Returns SEC if disk error (code in A)
; Returns CLC if successful;
;   A = file system ID (defined below).
;   X = auxilary info about file system (version)
;
; Only fsUnknown and fsProDOS return codes are
; currently implemented. (20-Jan-87 DL)
;
; For ProDOS volumes, this routine is defined
; to leave block 2 in BlockBuff if not error
; occurred.
;
;**************************************************
;
; (These file_system codes are compatible with
;  the ProDOS 16 FORMAT call)
;
fsUnknown	= 0	;couldn't identify file system
fsProDOS	= 1	;SOS too!  Same block structure.
fsDOS33	= 2
fsPascal	= 4	;Apple II Pascal
fsMacMFS	= 5	;Macintosh (MFS)
fsMacHFS	= 6	;Macintosh (HFS)
fsCPM	= 8	;Apple CP/M
;
; ProDOS voldir stuff
;
oBackPtr		= $0
oVolStType	= $4
oVersion		= $20
;***************************************************
CheckFileSys:
	lda #>RootBlock
	ldy #RootBlock
	ldx #>BlockBuff
	jsr ReadSrcBlk
	bcs fsExit
	lda BlockBuff+oBackPtr+1
	ora BlockBuff+oBackPtr
	bne fsNotPro
	lda BlockBuff+oVolStType
	and #$E0
	cmp #$E0
	bne fsNotPro
	lda BlockBuff+oVolStType
	and #$f
	beq fsNotPro	;name len = 0 is illegal
; it's ProDOS!
	lda #fsProDOS
	ldx BlockBuff+oVersion
	clc
	rts
;
fsNotPro:
	lda #fsUnknown
	clc
fsExit:	ldx #0
	rts

;
ReadBMBlk:
	sta bm_rbnum+1
	sty bm_rbnum
	jsr mli
	.byte mli_readblk
	.addr bm_rbparms
	rts
;
bm_rbparms:
	.byte 3
src_unit2:
	.byte 0
	.addr bmBlockBuff
bm_rbnum:
	.addr 0
;
ReadSrcBlk:	;read block AY to BlockBuff, page X
	stx rb_page+1
	sta rb_num+1
	sty rb_num
	jsr mli
	.byte mli_readblk
	.addr rb_parms
	rts
;
rb_parms:
	.byte 3
src_unit:
	.byte 0
rb_page:	.addr $ff00
rb_num:	.addr 0

;*************************************************
;
; Description of routines in this package
;
; bmapNewDisk
;   Should be called whenever the source
;   disk may have been replaced by a new
;   disk.  This call will force future calls
;   to read from disk instead of assuming that
;   information in the bitmap buffer is valid.
;
; bmapUsed
;   Takes block number in AY and returns
;     SEC if the block is allocated
;     CLC if the block is free
;
;   If this package does not know the directory
;   structure of the file system used by the volume,
;   it reports that the block is used.
;
;*************************************************
;
; External routines:
;   ReadBMblk to read a block (AY) from the
;   source disk into bmBlockbuff ($200 bytes).
;
;*************************************************
;*************************************************
;
; ProDOS volume directory info
;
oTotalBlks	= $29	;2 bytes
oBitmapPtr	= $27	;2 bytes
;*************************************************
bmThisBlk:	.addr 0	;current block in bmBlockBuff
bmFirstBlock:	.addr 0	;first block of bitmap
bmTotalBlocks:	.addr 0	;total blocks on vol
bmBlockNum:	.addr 0	;the block we're interested in
bmFileSys:	.byte 0
;*************************************************
bmNewDisk:
	lda #0
	sta bmThisBlk
	sta bmThisBlk+1
	lda #$ff
	sta bmFileSys	;force read on next call
	clc
	rts
;*************************************************
bmapUsed:
	sta bmBlockNum+1
	sty bmBlockNum
	jsr bmCheckDisk
	lda bmFileSys
	cmp #fsProDOS
	beq isProD
	sec	;indicate block is used
	rts
;
isProD:
	lda bmBlockNum+1
	ldy bmBlockNum
	jsr bmFetchBlk
	bcs bmOuch	;error--assume used
;
; Now that we have the right bitmap block, see if the actual
; block is marked used.  A 1 bit = free.
;
	lda bmBlockNum
	and #%00000111	;get pos of bit within byte
	tax	;need this in a sec
	lda bmBlockNum+1
	and #%00001111
	sta bmBlockNum+1
	ldy #3
bmShift:	lsr bmBlockNum+1	;divide by 8 = byte #
	ror bmBlockNum
	dey
	bne bmShift
;
	lda #>bmBlockBuff	;high byte of block buffer
	clc
	adc bmBlockNum+1	; equ 0 or 1 (low or high page of blk)
	sta bmCheat+2
;
	ldy bmBlockNum	;byte withing page
bmCheat:	lda $ff00,y
	and bmMaskTbl,x
	beq bmUsed
	clc
	rts
;
bmMaskTbl:
	.byte %10000000
	.byte %01000000
	.byte %00100000
	.byte %00010000
	.byte %00001000
	.byte %00000100
	.byte %00000010
	.byte %00000001
;
bmUsed	= *
bmOuch:	sec
	rts
;
; Fetch bitmap block containing the bit for
; block AY if it is not already in the buffer
;
bmFetchBlk:
	lsr a	;divide block/256 by 16 (4096 blks/bitmapblk)
	lsr a
	lsr a
	lsr a
	clc	;necessary!
	adc bmFirstBlock
	tay
	lda bmFirstBlock+1
	adc #0
	cmp bmThisBlk+1	;do we have the right blk?
	bne bmGetIt
	cpy bmThisBlk
	bne bmGetIt
	clc
	rts
bmGetIt:	;get bitmap blk AY
	sta bmThisBlk+1
	sty bmThisBlk
	jsr ReadBMBlk
	bcc bmGotIt
	ldx #0	;error->force retry next time; report "used"
	stx bmThisBlk+1
	stx bmThisBlk
bmGotIt:	rts
;
; If disk's file system has not been checked, check it.  Record
; some directory info if the disk is ProDOS.
;
bmCheckDisk:
	lda bmFileSys
	cmp #$ff
	bne bmChecked
	jsr CheckFileSys
	bcs bmChecked
	sta bmFileSys
; if ProDOS, record important info from DIR
	cmp #fsProDOS
	bne bmChecked
	lda BlockBuff+oBitmapPtr
	sta bmFirstBlock
	lda BlockBuff+oBitmapPtr+1
	sta bmFirstBlock+1
	lda BlockBuff+oTotalBlks
	sta bmTotalBlocks
	lda BlockBuff+oTotalBlks+1
	sta bmTotalBlocks+1
	lda #0
	sta bmThisBlk+1	;Important!  Forces read of bitmap blk
	sta bmThisBlk
bmChecked:
	rts
;*********************************************
InfoParms:
	.byte 10
InfoPath:
	.addr 0
	.byte 0
Filetype:
	.byte 0
AuxType:	.addr 0
stype:	.byte 0
blocks:	.addr 0
	.addr 0,0,0,0
;*********************************************
;
; Create storage file and open it (uses filenum,
; filebase=aux); returns A=refnum
;
CreateOpen:
	jsr mli
	.byte mli_create
	.addr cr_parms
	bcc created
co_err:	jmp xProDOS_err
cr_parms:	.byte 7
cr_path:	.addr 0
	.byte $e3
	.byte $E0	;filetype
	.addr $8004	;aux
	.byte 1
	.addr 0,0
created:
	lda devnum
	sta target_dev
	jsr mli
	.byte mli_open
	.addr open_parms
	bcs co_err
	lda open_ref
	rts
;*********************************************
open_parms:
	.byte 3
op_path:	.addr 0
	.addr filebuff
open_ref:
	.byte 0
;*********************************************
