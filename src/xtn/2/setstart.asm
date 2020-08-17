;*********************************************
;*********************************************
;
; External command for Davex
;
; setstart -- examine or set startup path of
;             a SYS file
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

	
.segment	"CODE_9000"

orgadr	= $9000	;change as necessary (end below $B000)
; org orgadr

myversion	= $10
minversion	= $10
;*********************************************
	rts
	.byte $ee,$ee
	.byte myversion,minversion
	.byte %00000000	;hardware req
	.addr descr
	.addr orgadr
	.addr start
	.byte 0,0,0,0
; parameters here
	.byte 0,t_wildpath
	asc "s"
	.byte t_string
	.byte 0,0
descr:	pstr "examine or set startup path of a SYS file"
;*********************************************
; dsect
; org xczpage ;32 locations
path	= xczpage	;ds 2
newpath	= path+2	;ds 2
; dend
;
start:
	sta info_path+1
	sty info_path
	sta open_path+1
	sty open_path
	sta path+1
	sty path
	ldy #0
	lda (path),y
	bne gave_path
	jsr xmess
	.byte cr
	asc "*** usage:  setstart <name of SYS file> [-s <startup path>]"
	.byte cr,0
	rts
gave_path:
	jsr read_some
	jsr chk_buff	;returns buffer size in A
	bne has_buff
	jsr xmess
	.byte cr
	asc "*** SYS file does not have a startup buffer"
	.byte cr,0
	jmp xerr
;
has_buff:
	lda #'s'
	jsr xgetparm_ch
	bcs just_looking
	sta newpath+1
	sty newpath
	jsr SetNewPath
just_looking:
	jsr xmess
	.byte cr
	asc "Startup path is "
	.byte '"'
	.byte 0
	lda #>(pagebuff+6)
	ldy #<pagebuff+6
	jsr xprint_path
	jsr xmess
	.byte '"',cr,0
	rts
;
SetNewPath:
	ldy #0
	lda (newpath),y
	cmp pagebuff+5
	bcc path_fits
	jsr xmess
	.byte cr
	asc "*** path too long for the startup buffer"
	.byte cr,0
	jmp xerr
;
path_fits:
	tay
copypath1:
	lda (newpath),y
	sta pagebuff+6,y
	dey
	bpl copypath1
;
	jsr mli
	.byte mli_write
	.addr rw_parms
	bcs err2
	rts
;
err2:	jmp xProDOS_err
;****************************************
chk_buff:
	lda pagebuff
	cmp #$4c
	bne no_buff
	lda #$ee
	cmp pagebuff+3
	bne no_buff
	cmp pagebuff+4
	bne no_buff
	lda pagebuff+5
	rts
no_buff:	lda #0
	rts
;****************************************
read_some:
	jsr mli
	.byte mli_gfinfo
	.addr info_parms
	bcs err1
	lda info_type
	cmp #tSYS
	beq okSYS
	jsr xmess
	.byte cr
	asc "*** not a SYS file"
	.byte cr,0
	jmp xerr
okSYS:
;
	jsr mli
	.byte mli_open
	.addr open_parms
	bcs err1
	lda open_ref
	sta rw_ref
	sta mark_ref
;
	jsr mli
	.byte mli_read
	.addr rw_parms
	bcs err1
;
	jsr mli
	.byte mli_setmark
	.addr mark_parms
	bcs err1
	rts
err1:	jmp xProDOS_err
;********************************************
open_parms:	.byte 3
open_path:	.addr 0
open_buff:	.addr filebuff
open_ref:	.byte 0
;
rw_parms:	.byte 4
rw_ref:	.byte 1	;what
	.addr pagebuff	;where
	.addr $100	;how much
	.addr 0	;how much actually read
;
mark_parms:
	.byte 2
mark_ref:
	.byte 1
	.byte 0,0,0
;
info_parms:
	.byte 10
info_path:
	.addr 0
	.byte 0
info_type:
	.byte 0
	.addr 0
	.byte 0
	.addr 0
	.addr 0,0,0,0
;*******************************************
