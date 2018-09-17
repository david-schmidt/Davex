;*********************************************
;
; External command for DAVEX
;
;  mt -- internal Memory Manager test
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

orgadr	= $9000
; org orgadr

myversion	= $1C
minversion	= $07
;*********************************************
	rts
	.byte $ee,$ee
	.byte myversion,minversion
	.byte %11000000	;hardware req
	.addr descr
	.addr orgadr
	.addr start
	.byte 0,0,0,0
; parameters here
	.byte 0,0
descr:	pstr "memory manager test"
;*********************************************
; dsect
; org xczpage ;32 locations
; dend
;
outa_here:
	jmp xProDOS_err

showfree:
	jsr xmess
	.byte cr
	cstr "Free pages = "
	ldx #mli_read
	jsr xmmgr
	bcs outa_here
	tay
	lda #0
	jsr xprdec_2
	jmp crout
;
; start
;
start:	jsr showfree
	ldx #mli_open
	lda #5
	jsr xmmgr
	bcs outa_here
	pha
	jsr xmess
	cstr "Allocated 5 pages at "
	pla
	tay
	lda #0
	jsr xprdec_2

	jsr showfree
	jsr crout
	rts
