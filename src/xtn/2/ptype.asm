;*********************************************
;*********************************************
;
; External command for Davex
;
; ptype -- diplay a Pascal text file
;
; Dave Lyons, 6-Oct-88
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

MyVersion	= $10
MinVersion	= $11

tPTX	= $03
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
descr:	pstr "ptype--dipsplay a Pascal text file"
	
;*********************************************
data	= pagebuff
;
; dum xczpage ;32 locations
; dend
;*********************************************
start:
	sta open_path+1
	sty open_path
	sta info_path+1
	sty info_path
;
; get file type
;
	jsr mli
	.byte mli_gfinfo
	.addr info_parms
	bcs err1
	lda info_ftype
	cmp #tPTX
	beq type_okay
	jsr xmess
	.byte cr
	asc "*** not a PTX file"
	.byte cr,0
	jmp xerr
;
type_okay:
;
; Open the source file
;
	jsr mli
	.byte mli_open
	.addr open_parms
	bcs err1
;
	lda open_ref
	sta read_ref
	sta close_ref
	sta mark_ref
;
; skip past the 2-block header
;
	jsr mli
	.byte mli_setmark
	.addr mark_parms
	bcs err1
;
MainLp:
	jsr ReadChar
	bcs MaybeDone
	jsr PrintChar
	jsr xcheck_wait
	bcs Done
	jmp MainLp
;
MaybeDone:
	cmp #err_eof
	beq Done
err1:	jmp xProDOS_err
Done:	jsr mli
	.byte mli_close
	.addr close_parms
	rts
;*********************************************
ReadChar	= *
	jsr mli
	.byte mli_read
	.addr read_parms
	bcs RdErr
	lda data
RdErr:	rts
;
read_parms:
	.byte 4
read_ref:
	.res 1
	.addr data
read_req:
	.addr 1
read_xfer:
	.addr 0
;*********************************************
PrintChar:
	cmp #$10
	beq BlankExpand
	ora #%10000000
	jmp cout
;
BlankExpand:
	jsr ReadChar
	bcs err1
	tax
	beq did_blanks
	lda #space
be1:	jsr cout
	dex
	bne be1
did_blanks:
	rts
;*********************************************
open_parms:
	.byte 3
open_path:
	.res 2
	.addr filebuff
open_ref:
	.res 1
;
close_parms:
	.byte 1
close_ref:
	.byte 1
;
mark_parms:
	.byte 2
mark_ref:
	.res 1
	.byte $00,$04,$00
;
info_parms:
	.byte 10
info_path:
	.addr 0
	.res 1
info_ftype:
	.res 1
	.res 13
;*********************************************
