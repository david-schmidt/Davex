;*********************************************
;
; External command for DAVEX
;
; hdr -- print file header -- first N lines
;
; hdr <wildpath> [-L <integer>]
;
; Default is 5 lines
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


.segment	"CODE_A000"

; 
orgadr	= $A000
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
	.byte $80+'l',t_int2
	.byte 0,0
	
descr:	pstr "hdr path [-Ln] -- print the first n lines of a file"
	
;*********************************************
; dsect
; org xczpage ;32 locations
line_count	= xczpage	;.addr 0
ref	= xczpage+2	;.byte 0
; dend
;
err:	jmp xProDOS_err
;
start	= *
	jsr xfman_open
	bcs err
	sta ref
;
	lda #5
	sta line_count
	lda #0
	sta line_count+1
	lda #'l'+$80
	jsr xgetparm_ch
	bcs use_dflt
	sta line_count+1
	sty line_count
use_dflt	= *
	lda line_count
	ora line_count+1
	beq hdrdun
;
do_line	= *
	jsr print_line
	bcc line_ok
	cmp #err_eof
	beq hdrdun
	jmp xProDOS_err
line_ok	= *
	jsr dec_lc
	bne do_line
;
hdrdun:	jmp crout	;Davex will close file
;
;
dec_lc	= *
	lda line_count
	bne dec1
	dec line_count+1
dec1:	dec line_count
	lda line_count
	ora line_count+1
	rts
;
;
print_line	= *
	lda ref
	jsr xfman_read
	bcs pldun
	ora #$80
	jsr cout
	and #$7f
	cmp #$0d
	bne print_line
	clc
pldun:	rts
