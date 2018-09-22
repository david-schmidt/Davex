;***********************************************
;
; mess -- print an in-line message
;
mess:	pla
	sta msgp
	pla
	sta msgp+1
	ldy #0
mess1:	inc msgp
	bne :+
	inc msgp+1
:	lda (msgp),y
	beq messx
	ora #%10000000
	jsr cout
	jmp mess1
messx:	lda msgp+1
	pha
	lda msgp
	pha
	rts

;**************************************
;
; on80 -- turn on 80-col card if here
;
suspend80:
	.byte 0

on80:	jsr setkbd
	jsr setvid
	jsr f8rom_init	; $fb2f
	jsr home
	lsr suspend80
	lda #40
	sta scr_width

	lda machid
	and #%00000010
	beq no_80col
	lda cfg40	;
	bne no_80col	;
	lda machid
	and #%11001000
	cmp #%10001000
	bne not_2c
	bit $c060
	bmi no_80col	;80-col override by 80/40 switch
not_2c:
have_80:
	lda #3
	jsr outport
	jsr crout
	asl scr_width	;make 40-->80
no_80col:

	jsr hook_speech	;30-Jul-87

	lda csw+1
	ldy csw
	sta vid_csw+1
	sty vid_csw
	jmp finish_iredir
;
; restore80 -- turn 80col back on if
; it was turned off
;
restore80:
	bit suspend80
	bpl ns80
	jsr TalkCont
	jsr mess
	.byte cr
	cstr "Hit a key: "
	lda #$a0
	jsr rdchar
	jmp on80
ns80:	rts
