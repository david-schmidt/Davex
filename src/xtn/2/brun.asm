;*********************************************
;
; BRUN pathname -- run a BIN file at its AUXTYPE
; address.  The BIN file must NOT assume that
; anything in particular is around.
;
;*********************************************
;
; This SYS file was originally written to let
; Kyan Pascal users run the Kyan compiler and
; editor from Davex.
;
;*********************************************
;
; by Dave Lyons
; 10-Sep-86
;
;*********************************************
;
; Modified 12-Dec-87 DL
;   to support BIN files that RTS rather than
;   QUITting.  Also, 'brun' will regain
;   control (and QUIT) on a JMP to $3D0, $3D3,
;   or $BE00.  A BRK is stored at $BE03 and
;   $BE70 just in case.
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************

.segment	"CODE_2000"

orgadr	= $2000
; sys
; org orgadr
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	;

;*********************************************
filebuff	= $bb00
;
runwhere	= $b800
diff1	= runwhere-orgadr
	jmp image2
	.byte $ee,$ee,65
thePath:	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
image2	= *
	lda $3f3
	sta $3f4
	jsr $fe84
	jsr $fb2f
	jsr $fe89
	jsr $fe93
	jsr $fc58
	lda $c000
	cmp #$b8
	beq yes80
	cmp #$b3	;"3"?
	bne no80colmn
yes80:	lda #$c3
	ldy #0
	sta $37
	sty $36
	sta $c010	;clear kbd
	jsr $fd8e	;crout
no80colmn	= *
	lda $3f3
	sta $3f4
	lda #0
	sta level
	ldx #0
copyme:	lda $2000,x
	sta runwhere,x
	lda $2100,x
	sta runwhere+$100,x
	lda $2200,x
	sta runwhere+$200,x
	dex
	bne copyme
	jmp continue+diff1
i_error:	pha
	jsr $fc58
	pla
	jsr $fdda
	jsr $fbdd
	jsr $fbdd
	jsr $fd0c
OutaHere	= *
	jsr mli
	.byte mli_bye
	.addr bye_parms+diff1
;;;	brk
	.byte 0
bye_parms:	.byte 4,0,0,0,0,0,0
continue	= *
;
; GetInfo to find the AuxType & load the file there
;
; (make sure it's a BIN file)
;
	jsr mli
	.byte mli_gfinfo
	.addr info_parms+diff1
	bcs i_error
;
	lda info_ftype+diff1
	cmp #tBIN
	beq is_bin
	lda #$ff
	bne i_error
;
is_bin:	lda info_aux+1+diff1
	ldy info_aux+diff1
	sta read_addr+1+diff1
	sty read_addr+diff1
;
; now open it
;
	jsr mli
	.byte mli_open
	.addr i_openp+diff1
	bcs i_error
;
	lda i_ref+diff1
	sta i_ref2+diff1
	sta i_ref3+diff1
;
	jsr mli
	.byte mli_read
	.addr i_readp+diff1
	bcs i_error
;
	jsr mli
	.byte mli_close
	.addr i_closep+diff1
;
	ldy thePath+diff1
cppath280:	lda thePath+diff1,y
	sta $280,y
	dey
	cpy #<-1
	bne cppath280
; Be careful--it might try to call BASIC.SYSTEM stuff!
	lda #0
	sta $be03
	sta $be70
;
	lda #$4c	;jmp
	sta $3d0
	sta $3d3
	sta $be00
	lda #<(byebye+diff1)
	sta $3d1
	sta $3d4
	sta $be01
	lda #>(byebye+diff1)
	sta $3d2
	sta $3d5
	sta $be02
;
	jsr RunTheThing+diff1
byebye:	cld
	jmp OutaHere+diff1
RunTheThing:	jmp (read_addr+diff1)
;
;
i_openp:	.byte 3
	.addr thePath+diff1
	.addr filebuff
i_ref:	.byte 0
;
i_readp:	.byte 4
i_ref2:	.byte 0
read_addr:
	.addr 0
	.addr $ffff
	.addr 0
;
i_closep:	.byte 1
i_ref3:	.byte 0
;
info_parms:	.byte 10
	.addr thePath+diff1
	.byte 0	;access
info_ftype:	.byte 0
info_aux:
	.addr 0	;aux
	.byte 0	;sttype
	.addr 0	;blocks
	.addr 0,0,0,0	;date/time
;***************************************
