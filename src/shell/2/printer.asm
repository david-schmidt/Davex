io_mask:	.byte 0

;*********************************************************
;
; print_drvr
;
; takes command code in X; possible data in A
; returns SEC; A = error
;
; Command codes (X):
;
;   mli_open   Open a printer for output
;              (slot # in A, returns refnum or
;               error in A)
;
;   mli_open-$80 Open a slot for input
;              (slot # in A, returns refnum or
;               error in A)
;
;   mli_read   refnum in Y; returns ready status
;              in bit 0 of A
;
;   mli_read-$80 refnum in Y; returns clc,A=character
;              or sec,A=error.  sec,A=0 --> no character
;
;   mli_write  send character (in A) to printer
;              (refnum in Y)
;
;   mli_close  close a printer for output (refnum in Y)
;
;   mli_close-$80  close a slot for input
;
;*********************************************************

;refSlot0	= $f0
refSlot1	= $f1
refSlot7	= $f7

;
; Slots-open table:
;   $8x = open for output
;   $4x = open for input
;   $Cx = open for i/o
;   $x0 = closed
;   $x1 = Pascal 1.1 device
;   $x2 = CnC1/C0x0 device
;
SlotsOpen:	.byte 0,0,0,0,0,0,0
tempref:	.byte 0
outmask:	.res 1

print_drvr:
	cpx #mli_write
	bne notwrite
;
; Write a character -- refnum in Y
;
	ldx #$7f
	stx outmask
write_literal:
	sty tempref
	pha
	lda SlotsOpen-refSlot1,y
	and #%10000000
	beq bref0
	lda SlotsOpen-refSlot1,y
	and #%00001111
	cmp #2
	beq write_pll
	jsr set_pwrk
	ldy #$0f
	lda (prtrwrk),y
	sta PrWrite+1
	jsr calcxy
	stx PrWrite+2
	bit $cfff
	pla
	and outmask
PrWrite: jsr $0000	; modified above
	bit $cfff
	clc
	rts

write_pll:
; pha
	jsr set_pwrk
	ldy #$c1
waitrdy:
	lda (prtrwrk),y	;$CnC1
	bmi waitrdy
	jsr calcxy
	pla
	and outmask
	sta $C080,Y
	clc
	rts

read_pll:
	jsr set_pwrk
	ldy #$c1
	lda (prtrwrk),y	;$CnC1
	rol a
	rol a
	and #1
	eor #1
	clc
	rts

notwrite:
	cpx #mli_write-$80
	bne notwrlit
	ldx #$ff
	stx outmask
	bne write_literal

notwrlit:
	cpx #mli_read
	bne notread
;
; read_pasc11 = *
	sty tempref
	lda SlotsOpen-refSlot1,y
	and #%11000000
	bne rd_refok
bref0:	jmp badref
rd_refok:
	lda SlotsOpen-refSlot1,y
	and #%00001111
	cmp #2
	beq read_pll
	jsr set_pwrk
	ldy #$10
	lda (prtrwrk),y
	sta PrRead+1
	jsr calcxy
	stx PrRead+2
	bit $cfff
	lda #0		;request OUTPUT status
PrRead:	jsr $0000	;return: SEC=ready
	bit $cfff
	lda #0
	rol a		;return to caller: bit0=ready
	clc
	rts

notread:
	cpx #mli_read-$80
	bne notread2
;
; read character from Pascal device--return SEC,A=0 if no char
;
	sty tempref		;for set_pwrk
	lda SlotsOpen-refSlot1,y
	and #%01001111
	cmp #%01000001		;input, pascal
	bne CantRead
	jsr set_pwrk
	ldy #$0e
	lda (prtrwrk),y
	sta PrRead2+1
	ldy #$10
	lda (prtrwrk),y
	sta PrStat2+1
	jsr calcxy
	stx PrRead2+2
	stx PrStat2+2
	bit $cfff
	lda #1
PrStat2: jsr $0000
	bcc NoChars
	jsr calcxy
PrRead2: jsr $0000
	bit $cfff
	cpx #1
	bcs CantRead
	rts

CantRead:
	sec
	lda #err_io
	rts

NoChars:
	sec
	lda #0
	rts

notread2:
	pha
	lda #$80
	sta io_mask
	txa
	bmi forOutput
	lsr io_mask
forOutput:
	ora #$80
	tax
	pla

	cpx #mli_close
	bne notclose
;
; Close an output device by refnum (Y)
;
	cpy #refSlot1
	bcc badref
	cpy #refSlot7+1
	bcs badref
	lda io_mask
	eor #$ff
	and SlotsOpen-refSlot1,y
	sta SlotsOpen-refSlot1,y
	clc
	rts

notopen:
	lda #err_badcall
	sec
	rts

notclose:
	cpx #mli_open
	bne notopen
; open an output device; A=slot number
	cmp #0
	bne PrNDflt
	lda print_slot
PrNDflt:
	cmp #7+1
	bcs badref
	tay
	lda SlotsOpen-1,y
	and io_mask
	beq cont_open
; already open
	lda #err_filopen
	sec
	rts

badref:	lda #err_ivlref
	sec
	rts

cont_open:		;open--slot # in Y
	lda SlotsOpen-1,y
	and #%11000000
	beq cont_open2
; when opening for another mode, don't re-init
	lda SlotsOpen-1,y
	ora io_mask
	sta SlotsOpen-1,y
	tya
	clc
	adc #refSlot0
;;;	clc
	rts
cont_open2:
	tya
	clc
	adc #refSlot0
	sta tempref
	jsr set_pwrk
;
; anything here?
;
	ldy #0
	ldx #0
	lda (prtrwrk),y
slotOK:	cmp (prtrwrk),y
	bne pdrvr_nodev
	dex
	bne slotOK
;
; make sure it doesn't autoboot (not a printer!)
;
	ldy #1
	lda (prtrwrk),y
	cmp #$20
	bne slOK2
	ldy #3
	lda (prtrwrk),y
	bne slOK2
	ldy #5
	lda (prtrwrk),y
	cmp #3
	beq pdrvr_nodev
slOK2:
;
; see if it's a Pascal 1.1 device
;
	ldy #$b
	lda (prtrwrk),y
	cmp #1
	bne open_pll
;
; open_pasc11 = *
	ldy #$d	;init
	lda (prtrwrk),y
	sta PrOpen+1
	jsr calcxy
	stx PrOpen+2
	bit $cfff
PrOpen:	jsr $0000
	bit $cfff
	lda #1
openz:	ldy tempref
	ora io_mask
	sta SlotsOpen-refSlot1,y
	tya
	clc
	rts

open_pll:
	lda #2
	bne openz

pdrvr_nodev:	lda #err_nodev
	sec
	rts

;***********************************************
;
; From tempref, calculate $Cn in X and $n0 in Y
;
calcxy:
	pha
	sec
	lda tempref
	sbc #refSlot0
	pha
	ora #$c0
	tax
	pla
	asl a
	asl a
	asl a
	asl a
	tay
	pla
	rts

set_pwrk:
	pha
	tya
	pha
	lda tempref
	sec
	sbc #refSlot0
	ora #$c0
	sta prtrwrk+1
	lda #0
	sta prtrwrk
	pla
	tay
	pla
	rts

;***********************************************
;
; prtr_char -- send char to printer
;
; (">" puts "prtr_char" in CSW)
;
prtr_char:
	sta thischar
	stx coutx
	sty couty
	pha
	clc
	lda remslot
	adc #refSlot0
	cmp redir_out
	bne notsusp
	lda #0
	lda redir_susplv
	beq notsusp
	pla
	pha
	jmp osusp
notsusp:
	clc
	lda remslot
	adc #refSlot0
	cmp redir_out
	bne no_echo_scrn
	pla
	pha
	ora #$80
	jsr goto_vid
no_echo_scrn:
	pla
	ldx #mli_write
	ldy redir_out
	jsr print_drvr
	lda thischar
	ora #%10000000
	cmp #$80+'M'-ctrl
	bne no_addlf
	lda #$80+'J'-ctrl
	ldx #mli_write
	ldy redir_out
	jsr print_drvr
coutdone:
no_addlf:
	ldx coutx
	ldy couty
	lda thischar
	rts
goto_vid:
	jmp (vid_csw)

;***********************************************
;
; CheckHC -- preserving A,X,Y, do a screen dump
;            if A="H" and the Apple Key is down
;            on a //e, //c, IIgs
;
;  Also allow Apple-space = linefeed,
;             Apple-rtn   = formfeed
;
;  Return CLC if a something was done.
;
;***********************************************
hc_char: .byte 0

CheckHC:
	sta hc_char
	pha
	tya
	pha
	txa
	pha
	ldy $fbb3
	cpy #6
	bne noHC
; not if input redirected! 27-Jan-90
	lda #0
	jsr redirect
	bvs noHC
	bit fudgeCR	;5-Feb-90
	bmi noHC	;5-Feb-90 ('exec' ending)

	bit button0
	bpl noHC
	lda hc_char
	jsr downcase
	cmp #$80+'h'
	bne noHC1
	jsr HardCopy
	clc
	bcc hcExit
noHC1:	cmp #$80+' '	;Apple-space=linefeed
	bne noHC2
	jsr doLineFeed
	clc
	bcc hcExit
noHC2:	cmp #$80+'M'-ctrl	;Apple-return=formfeed
	bne noHC
	jsr doFormFeed
	clc
	bcc hcExit
noHC:	sec
hcExit:	pla
	tax
	pla
	tay
	pla
	rts

;***********************************************
HardCopy:
	ldx #mli_open
	lda #0	;slot=default
	jsr print_drvr
	bcs hcerr
	sta hcref

	lda $29		; [TODO] BASL, BASH
	pha
	lda $28
	pha
	lda $25
	pha
	lda $24		; CH
	pha
	lda #0
	sta $25		; CV
	sta $24

hc1:
	lda $25		;vertical position
	jsr bascalc
hc2:	ldy $24		;horizontal position
	jsr fetch_ch
	jsr hcwrite

	inc $24
	ldy $24
	cpy scr_width
	bcc hc2

	lda #$8d
	jsr hcwrite
	lda #$8a
	jsr hcwrite
	lda #0
	sta $24
	inc $25
	lda $25
	cmp #24
	bcc hc1

	pla
	sta $24
	pla
	sta $25
	pla
	sta $28
	pla
	sta $29
hcClose:
	ldx #mli_close
	ldy hcref
	jmp print_drvr
hcerr0:	plp
hcerr:	jsr bell
	jmp bell
hcref:	.byte 0

hcwrite:
	ldx #mli_write
	ldy hcref
	jmp print_drvr

doLineFeed:
	clc
	.byte $24
doFormFeed:
	sec
	php
	ldx #mli_open
	lda #0
	jsr print_drvr
	bcs hcerr0	;pulls P & beeps
	sta hcref
	plp
	bcc doLF2
	lda #$8d
	jsr hcwrite
	lda #$8c
	jsr hcwrite
	jmp hcClose
doLF2:	lda #$8a
	jsr hcwrite
	jmp hcClose

