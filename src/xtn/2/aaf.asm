	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

	; Unpack Apple Archive Format

.segment	"CODE_9000"

LFD8E	= $fd8e
LFE84	= $fe84
LFE80	= $fe80
LFDED	= $fded
LBF00	= $bf00

	rts

	.byte $ee, $ee
	.byte $10, $11
	.byte %00000000
	clc
	bcc     L9009
L9009:	bcc     L905D
	bcc     L900D
L900D:	.byte 0, 0, 0, 0
	.byte   $04
	brk
	.byte   $03
	sbc     $07
	brk
	brk
	.byte   $39
	.byte   $E1
L901A:	sbc     ($E6,x)
	ldy     #$AD
	lda     $D5A0
	inc     $E1F0
	.byte   $E3
	.byte   $EB
	ldy     #$C1
	beq     L901A
	cpx     $A0E5
	cmp     ($F2,x)
	.byte   $E3
	inx
	sbc     #$F6
	sbc     $A0
	dec     $EF
	.byte   $F2
	sbc     $F4E1
	ldy     #$E6
	sbc     #$EC
	sbc     $F3
	ldy     #$AF
	ldy     #$E2
	sbc     $CAA0,y
	sbc     $E6
	inc     $A0
	iny
	sbc     ($EE,x)
	.byte   $F3
	sbc     $EE
	sty     $E2
	sta     $E3
	sty     L93A4
	sta     L93A5
	.byte   $20
L905D:	.byte   $BF
	.byte   $93
	bcc     L9062
	rts

L9062:	.byte   $64
	inc     $EEC6
	lda     #$E5
	jsr     xgetparm_ch
	bcs     L906F
	sta     $EE
L906F:	lda     #$01
	jsr     xgetparm_n
	sty     $EB
	sta     $EC
	sty     L9392
	sta     L9393
	sty     L920E
	sta     L920F
	.byte   $B2
	.byte   $EB
	beq     L909F
	jsr     LBF00
	cpy     $91
	.byte   $93
	bcc     L9093
	jmp     xProDOS_err

L9093:	lda     L9395
	cmp     #$0F
	beq     L909F
	lda     #$97
	jmp     xProDOS_err

L909F:	lda     $E2
	sta     L9392
	lda     $E3
	sta     L9393
	jsr     LBF00
	cpy     $91
	.byte   $93
	bcc     L90B4
	jmp     xProDOS_err

L90B4:	lda     L9395
	cmp     #$04
	beq     L90F0
	cmp     #$B0
	beq     L90F0
	jsr     xmess
	tax
	tax
	tax
	ldy     #$E5
	.byte   $F2
	.byte   $F2
	.byte   $EF
	.byte   $F2
	tsx
	ldy     #$EE
	.byte   $EF
	.byte   $F4
	ldy     #$E1
	inc     $C1A0
	.byte   $D3
	.byte   $C3
	cmp     #$C9
	ldy     #$A8
	.byte   $D4
	cld
	.byte   $D4
	ldy     #$EF
	.byte   $F2
	ldy     #$D3
	.byte   $D2
	.byte   $C3
	lda     #$A0
	inc     $E9
	cpx     $8DE5
	brk
	jmp     xerr

L90F0:	lda     #$00
	sta     L93A6
	lda     #$08
	sta     L93A7
	jsr     LBF00
	iny
	.byte   $A3
	.byte   $93
	bcc     L9105
	jmp     xProDOS_err

L9105:	lda     L93A8
	sta     L93AA
	sta     L93AE
	sta     $E4
	.byte   $64
	inx
	jsr     LBF00
	cmp     #$A9
	.byte   $93
	bcc     L911D
	jmp     xProDOS_err

L911D:	jsr     LBF00
	dex
	lda     L9093
	bit     $4CC9
	beq     L912C
	jmp     xProDOS_err

L912C:	lda     $E4
	sta     L93BE
	jsr     LBF00
	cpy     L93BD
	bcc     L9150
	jmp     xProDOS_err

	bit     $E8
	bpl     L9150
	lda     $E7
	sta     L93BE
	jsr     LBF00
	cpy     L93BD
	bcc     L9150
	jmp     xProDOS_err

L9150:	rts

	lda     $EA
	bit     $E9
	bmi     L9160
	ldx     #$00
	lda     $1000,x
	ora     #$80
	sta     $EA
L9160:	cmp     #$AB
	beq     L9171
	cmp     #$BD
	beq     L9174
	cmp     #$AD
	beq     L9177
	.byte   $80
	brk
	jmp     L9186

L9171:	jmp     L91A7

L9174:	jmp     L91BD

L9177:	jmp     L92E8

L917A:	lda     L93B4
	beq     L9181
	lda     #$FF
L9181:	sta     $E9
	jmp     L911D

L9186:	bit     $EE
	bpl     L919F
	lda     L93B3
	.byte   $3A
	sta     $ED
	ldx     #$FF
L9192:	inx
	lda     $1000,x
	ora     #$80
	jsr     LFDED
	cpx     $ED
	bne     L9192
L919F:	jsr     xcheck_wait
	bcc     L917A
	jmp     L912C

L91A7:	bit     $E8
	bpl     L917A
	.byte   $64
	inx
	lda     $E7
	sta     L93BE
	jsr     LBF00
	cpy     L93BD
	bcc     L917A
	jmp     xProDOS_err

L91BD:	bit     $E8
	bpl     L91D3
	lda     $E7
	sta     L93BE
	.byte   $64
	inx
	jsr     LBF00
	cpy     L93BD
	bcc     L91D3
	jmp     xProDOS_err

L91D3:	ldx     #$00
	inx
	lda     $1000,x
	ora     #$80
	cmp     #$8D
	beq     L91E4
	sta     L9331,x
	.byte   $80
	.byte   $F1
L91E4:	dex
	stx     L9331
	jsr     LFE80
	ldy     #$31
	lda     #$93
	jsr     L93F7
	jsr     LFE84
	jsr     LFD8E
	lda     #$31
	sta     $E5
	lda     #$93
	sta     $E6
	.byte   $B2
	.byte   $EB
	bne     L920A
	ldy     $E5
	lda     $E6
	.byte   $80
	.byte   $20
L920A:	jsr     xpmgr
	.byte   $04
L920E:	brk
L920F:	brk
	eor     ($93,x)
	jsr     xpmgr
	.byte   $03
	eor     ($93,x)
	ldy     #$31
	lda     #$93
	jsr     xpmgr
	brk
	eor     ($93,x)
	ldy     #$41
	lda     #$93
	sty     $E5
	sta     $E6
	sty     L9392
	sta     L9393
	sty     L9383
	sta     L9384
	sty     L938F
	sta     L9390
	sty     L93A4
	sta     L93A5
	jsr     LBF00
	cpy     $91
	.byte   $93
	bcs     L92B2
	ldy     $E5
	lda     $E6
	jsr     xprint_path
	jsr     xmess
	ldy     #$E5
	sed
	sbc     #$F3
	.byte   $F4
	.byte   $F3
	brk
	lda     L9394
	and     #$C3
	cmp     #$C3
	beq     L9272
	jsr     xmess
	ldy     #$DB
	cpy     $C3CF
	.byte   $CB
	cmp     $C4
	.byte   $DD
	brk
L9272:	jsr     xmess
	ldx     $CFA0
	inc     $E5,x
	.byte   $F2
	.byte   $F7
	.byte   $F2
	sbc     #$F4
	sbc     $00
	lda     #$EE
	jsr     xyesno2
	bmi     L928D
	.byte   $64
	inx
	jmp     L917A

L928D:	lda     #$C3
	sta     L9394
	lda     #$07
	sta     L9391
	jsr     LBF00
	.byte   $C3
	sta     ($93),y
	bcc     L92A2
	jmp     xProDOS_err

L92A2:	lda     #$0A
	sta     L9391
	jsr     LBF00
	cmp     ($8E,x)
	.byte   $93
	bcc     L92B9
	jmp     xProDOS_err

L92B2:	cmp     #$46
	beq     L92B9
	jmp     xProDOS_err

L92B9:	jsr     LBF00
	cpy     #$82
	.byte   $93
	bcc     L92C4
	jmp     xProDOS_err

L92C4:	lda     #$00
	sta     L93A6
	lda     #$0C
	sta     L93A7
	jsr     LBF00
	iny
	.byte   $A3
	.byte   $93
	.byte   $90
L92D5:	.byte   $03
	jmp     xProDOS_err

L92D9:	lda     L93A8
	sta     L93B6
	sta     $E7
	lda     #$FF
	sta     $E8
	jmp     L917A

L92E8:	bit     $E8
	bpl     L932E
	bit     $E9
	bpl     L9308
	lda     #$00
	sta     L93B7
	lda     #$10
	sta     L93B8
	lda     L93B3
	sta     L93B9
	lda     L93B4
	sta     L93BA
	.byte   $80
	.byte   $1B
L9308:	lda     #$01
	sta     L93B7
	lda     #$10
	sta     L93B8
	sec
	lda     L93B3
	sbc     #$01
	sta     L93B9
	lda     L93B4
	sbc     #$00
	sta     L93BA
	jsr     LBF00
	.byte   $CB
	lda     $93,x
	bcc     L932E
	jmp     xProDOS_err

L932E:	jmp     L917A

L9331:	ldy     #$E2
	bcs     L92D5
	ldy     #$A0
	ldy     #$A0
	ldy     #$A0
	ldy     #$A0
	ldy     #$A0
	ldy     #$A0
	clv
	ldy     #$AB
	ldy     $A0,x
	sbc     ($B0,x)
	ldy     #$AE
	ldy     #$A0
	sbc     $A0
	tax
	.byte   $EF
	ldy     #$AA
	ldy     #$A0
	ldy     #$A0
	ldy     #$A0
	nop
	inc     $A0A0
	.byte   $EF
	ldy     #$A0
	ldy     #$A0
	ldy     #$A0
	ldy     #$A0
	ldy     #$A0
	.byte   $BB
	ldy     #$A0
	ldx     $A0,y
	ldy     #$A0
	ldy     #$A0
	ldy     #$A0
	.byte   $F4
	ldy     #$A0
	ldy     #$A0
	lda     ($A0),y
	ldy     #$A0
	ldy     #$B5
	ldy     #$A0
	ldy     #$A0
	ldy     #$07
L9383:	tax
L9384:	ldy     #$E3
	.byte   $04
	brk
	brk
	ora     ($A0,x)
	sbc     ($A0,x)
	.byte   $80
	.byte   $01
L938F:	.byte   $A0
L9390:	.byte   $A0
L9391:	asl     a
L9392:	.byte   $A0
L9393:	.byte   $E6
L9394:	.byte   $B6
L9395:	ldy     #$A0
	ldy     #$A0
	sbc     $A0
	.byte   $A0
L939C:	ldy     #$A0
	tax
	.byte   $F3
	.byte   $80
	.byte   $FF
	ldy     #$03
L93A4:	.byte   $A0
L93A5:	nop
L93A6:	brk
L93A7:	php
L93A8:	sbc     $03
L93AA:	ldy     #$7F
	.byte   $0D
	.byte   $04
L93AE:	ldy     #$00
	bpl     L93B2
L93B2:	.byte   $01
L93B3:	.byte   $A0
L93B4:	ldy     #$04
L93B6:	.byte   $A0
L93B7:	brk
L93B8:	.byte   $10
L93B9:	.byte   $A0
L93BA:	ldy     #$A0
	.byte   $A0
L93BD:	.byte   $01
L93BE:	ldy     #$AD
	.byte   $B3
	.byte   $FB
	cmp     #$38
	beq     L93D4
	cmp     #$EA
	beq     L93D4
	lda     $FBC0
	cmp     #$EA
	beq     L93D4
	clc
	bne     L93F6
L93D4:	jsr     xbell
	jsr     xmess
	tax
	tax
	tax
	ldy     #$E5
	.byte   $F2
	.byte   $F2
	.byte   $EF
	.byte   $F2
	tsx
	ldy     #$B6
	lda     $C3,x
	bcs     L939C
	ldy     #$F2
	sbc     $F1
	sbc     $E9,x
	.byte   $F2
	sbc     $E4
	sta     $3800
L93F6:	rts

L93F7:	sty     $E0
	sta     $E1
	txa
	pha
	ldy     #$00
	lda     ($E0),y
	beq     L940E
	tax
	iny
L9405:	lda     ($E0),y
	jsr     LFDED
	iny
	dex
	bne     L9405
L940E:	pla
	tax
	rts
