;*********************************************
;
; BLIST (BASIC list) command for DAVEX
;
; blist <path> -- prints BAS file in ASCII
;
; by Dave Lyons
; 1-Jul-86
;
; Modified 27-Mar-88 DL ==> v1.0
;   calls xcheck_wait at end of line
;   source -> merlin
;
; Modified 10-Apr-88 DL ==> v1.1
;    wraps to next line and indents after
;    the wrap margin if -w used
;
; Modified 25-Jul-88 DL ==> v1.2
;   Was first blank in a REM even if there
;   were nonblank characters before it!
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************

.segment	"CODE_A000"

orgadr	= $A000
.org orgadr
	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

MyVersion	= $12
MinVersion	= $10
;*********************************************
tokens		= $D0D0		; token table inside Applesoft
tok_REM		= 178
tok_DATA	= 131
;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr orgadr
	.addr start
	.byte 0,0,0,0
; parameters here
	.byte 0,t_wildpath
	.byte $80+'w',t_int1
	.byte 0,0
descr:	pstr "LISTs a BAS file"


byte:	.res 2
;*********************************************
; xczpage -- 32 locations
myPtr		= xczpage	;.res 2
lastchr		= myPtr+2	;.res 1
lasttok		= lastchr+1	;.res 1
hard_wrap	= lasttok+1	;.res 1
soft_wrap	= hard_wrap+1	;.res 1
horiz		= soft_wrap+1	;.res 1
myA		= horiz+1	;.res 1
myX		= myA+1		;.res 1
myY		= myX+1		;.res 1

;*********************************************
start:	lda #0
	sta lastchr
	sta lasttok
	jsr xgetparm_n
	sta path+1
	sty path
	sta info_path+1
	sty info_path

	jsr check_bas
	jsr open_it
	sta read_ref

	lda #0
	sta soft_wrap
	sta hard_wrap
	lda #'w'+$80
	jsr xgetparm_ch
	bcs no_wrap
	cpy #20
	bcs good_wrap
	jsr xmess
	.byte cr
	cstr_cr "*** wrap margin must be 20..255"
	jmp xerr
good_wrap:
	sty hard_wrap
	tya
	sec
	sbc #10
	sta soft_wrap
no_wrap:

linelp:	jsr do_line
	bcc linelp
	rts
;*********************************************
open_it:
	jsr mli
	.byte mli_open
	.addr open_p
	bcs outa_here
	lda open_ref
	rts

open_p:	.byte 3
path:	.res 2
	.addr filebuff
open_ref:
	.res 1
;*********************************************
check_bas:
	jsr mli
	.byte mli_gfinfo
	.addr info_p
	bcs outa_here
	lda info_ftype
	cmp #tBAS
	beq cb_ok
	jsr xmess
	.byte cr
	cstr_cr "*** not BAS file"
	jmp xerr
cb_ok:	rts
outa_here:
	jmp xProDOS_err

info_p:	.byte 10
info_path:
	.res 2
	.res 1
info_ftype:
	.res 1
	.res 2
	.res 1
	.res 2
	.res 8
;*********************************************
read2:	lda #2
	jsr reada
	lda byte+1
	ora byte
	php
	lda byte+1
	ldy byte
	plp
	rts

read1:	lda #1
reada:	sta xfercount
	jsr mli
	.byte mli_read
	.addr read_p
	bcs outa_here
	lda byte
	rts

read_p:	.byte 4
read_ref:
	.res 1
	.addr byte
xfercount:
	.addr 0
	.addr 0
;*********************************************
do_line:
	lda #0
	sta horiz
	jsr read2
	bne not_endprog
	sec
	rts
not_endprog:
	jsr line_number
	lda #6
	sta horiz
	jsr line_text
	jsr crout
	lda #0
	sta horiz
	jmp xcheck_wait
;*********************************************
line_number:
	jsr read2
	jsr xprdec_2
	jmp blank
;*********************************************
line_text:
	jsr read1
	beq line_done
	bmi do_token
	ora #%10000000
	sta lastchr
	cmp #$A0
	bne print_this
	ldx lasttok
	cpx #tok_REM
	beq skip_this
	cpx #tok_DATA
	beq skip_this
print_this:
	ldx #0		;25-Jul-88
	stx lasttok	;25-Jul-88
	jsr mycout
	jmp line_text
skip_this:
	lda #0
	sta lasttok
	jmp line_text
do_token:
	jsr pr_token
	jmp line_text
line_done:
	rts
;*********************************************
pr_token:
	sta lasttok
	pha
	jsr blankif
	pla
	sec
	sbc #$7f
	tax
	lda #>tokens
	ldy #<tokens
	sta myPtr+1
	sty myPtr
srchtok:
	dex
	beq foundtok
	jsr nexttok
	jmp srchtok

foundtok:
	ldy #0
prtokchr:
	lda (myPtr),y
	pha
	ora #%10000000
	sta lastchr
	jsr mycout
	iny
	pla
	bpl prtokchr
	jsr blankif
	rts

nexttok:
	ldy #0
	lda (myPtr),y
	bmi hit_end
	jsr incPtr
	jmp nexttok

hit_end:
incPtr:	inc myPtr
	bne Ptrok
	inc myPtr+1
Ptrok:	rts
;*********************************************
blank:	lda #$A0
	sta lastchr
	jmp mycout
;*********************************************
blankif:
	lda #$A0
	cmp lastchr
	bne blank
	rts
;*********************************************
mycout:	sta myA
	stx myX
	sty myY
	jsr cout
	inc horiz

	ldx hard_wrap
	beq no_wrp

	ora #$80
	cmp #$A0
	bne check_hard

	lda horiz
	cmp soft_wrap
	bcc no_wrp
	bcs do_wrap

check_hard:
	lda horiz
	cmp hard_wrap
	bcc no_wrp

do_wrap:
	jsr xmess
	.byte cr
	cstr "      "
	lda #5
	sta horiz

no_wrp:	lda myA
	ldx myX
	ldy myY
	rts
;*********************************************
