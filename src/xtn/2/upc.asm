	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment "CODE_A000"
.org $a000

L9FEE	= $9FEE
LFD8E	= $FD8E
LFDED	= $FDED
LFE95	= $FE95

	rts

	inc     $10EE
	ora     ($00),y
	.byte   $1A
	ldy     #$00
	ldy     #$56
	ldy     #$00
	brk
	brk
	brk
	brk
	ora     $F3
	asl     $EC
	asl     $E4
	brk
	brk
	brk
	.byte   $3B
	sbc     $F0,x
	.byte   $E3
	ldy     #$AD
	lda     $D0A0
	.byte   $F2
	sbc     #$EE
	.byte   $F4
	ldy     #$D5
	bne     L9FEE
	lda     LA0C1
	tay
	cmp     $EE,x
	sbc     #$F6
	sbc     $F2
	.byte   $F3
LA036:  sbc     ($EC,x)
	ldy     #$D0
	.byte   $F2
	.byte   $EF
	cpx     $F5
	.byte   $E3
	.byte   $F4
	ldy     #$C3
	.byte   $EF
	cpx     $E5
	lda     #$A0
	.byte   $E2
	sbc     ($F2,x)
	.byte   $E3
	.byte   $EF
	cpx     $E5
	ldy     #$A8
	dec     $D8
	lda     $B0B8
	lda     #$84
	.byte   $EF
	sta     $F0
	jsr     LA4B2
	bcc     LA060
	rts

LA060:  ldy     #$00
	sty     $F9
	lda     #$F3
	jsr     xgetparm_ch
	bcs     LA09F
	sty     $F9
	cpy     #$0A
	bcc     LA09F
	jsr     xmess
	tax
	tax
	tax
	.byte   $A0
LA078:  sbc     $F2
	.byte   $F2
	.byte   $EF
	.byte   $F2
	tsx
	ldy     #$F3
	sbc     $F4F3,y
	sbc     $ED
	ldy     #$E4
	sbc     #$E7
	sbc     #$F4
	ldy     #$ED
	sbc     $F3,x
	.byte   $F4
	ldy     #$E2
	sbc     $A0
	bcs     LA036
	.byte   $F4
	.byte   $EF
	ldy     #$B9
	sta     $4C00
	pha
	.byte   $B0
LA09F:  ldy     #$06
	sty     $FC
	lda     #$EC
	jsr     xgetparm_ch
	bcs     LA0E2
LA0AA:  sty     $FC
	cpy     #$3D
	bcc     LA0E2
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
	ldy     #$ED
	sbc     ($F8,x)
LA0C1:  sbc     #$ED
	sbc     $ED,x
	ldy     #$EC
LA0C7:  sbc     $E6
	.byte   $F4
	ldy     #$ED
	sbc     ($F2,x)
	.byte   $E7
	sbc     #$EE
	ldy     #$E9
	.byte   $F3
	ldy     #$B6
	bcs     LA078
	.byte   $E3
	inx
	sbc     ($F2,x)
	.byte   $F3
	sta     $4C00
	pha
	.byte   $B0
LA0E2:  lda     $EF
	sta     $E9
	lda     $F0
	sta     $EA
	.byte   $B2
	sbc     #$85
	sbc     ($F0),y
	rol     $C9,x
	asl     a
	beq     LA131
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
	ldy     #$E2
	sbc     ($F2,x)
	.byte   $E3
	.byte   $EF
	cpx     $E5
	ldy     #$EC
	sbc     $EE
	.byte   $E7
	.byte   $F4
	inx
	ldy     #$ED
	sbc     $F3,x
	.byte   $F4
	ldy     #$E2
	sbc     $A0
	lda     ($B0),y
	ldy     #$E3
	inx
	sbc     ($F2,x)
	.byte   $F3
	sta     $4C00
	pha
	bcs     LA0C7
	.byte   $1A
	lda     #$A0
	jsr     LA4EA
	jsr     LFD8E
	rts

LA131:  lsr     a
	sta     $F2
	lda     #$E5
	sta     $E7
	lda     #$A3
	sta     $E8
	.byte   $B2
	.byte   $E7
	sta     $F4
	ldy     #$00
LA142:  iny
	lda     ($E9),y
	ora     #$80
	sta     ($E9),y
	sty     $F5
	ldy     #$00
LA14D:  iny
	cmp     ($E7),y
	beq     LA17A
	cpy     $F4
	bne     LA14D
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
	ldy     #$E9
	inc     $E1F6
	cpx     $E4E9
	ldy     #$E3
	inx
	sbc     ($F2,x)
	sbc     ($E3,x)
	.byte   $F4
	sbc     $F2
	sta     $4C00
	pha
	.byte   $B0
LA17A:  ldy     $F5
	cpy     $F1
	bne     LA142
	lda     #$01
	sta     $FD
	lda     #$04
	sta     $FA
	lda     #$06
	sta     $FE
	lda     #$00
	sta     $FB
	lda     #$E4
	jsr     xgetparm_ch
	bcs     LA1A7
	lda     #$02
	sta     $FD
	lda     #$06
	sta     $FA
	lda     #$01
	sta     $FE
	lda     #$03
	sta     $FB
LA1A7:  lda     #$00
	sta     $F6
	.byte   $1A
	sta     $F7
	.byte   $1A
	sta     $F8
	jsr     LA34A
	ldx     #$CC
	jsr     xmmgr
	lda     #$01
	ldx     #$C8
	jsr     xmmgr
	bcc     LA1E2
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
	ldy     #$EF
	sbc     $F4,x
	ldy     #$EF
	inc     $A0
	sbc     $EDE5
	.byte   $EF
	.byte   $F2
	sbc     $8D,y
	jmp     xerr

LA1E2:  sta     $E2
	sta     $E5
	.byte   $64
	cpx     $64
	inc     $A9
	.byte   $DA
	sta     $E7
	lda     #$A3
	sta     $E8
	.byte   $B2
	.byte   $E7
	sta     $F4
	lda     $F6
	jsr     LA2BF
	lda     $F9
	clc
	adc     #$B0
	ldx     #$00
	jsr     LA2CE
	ldy     #$00
LA207:  iny
	lda     ($E9),y
	sty     $F3
	ldx     #$00
	jsr     LA2CE
	ldy     $F3
	cpy     $F2
	bne     LA207
	lda     $F7
	jsr     LA2BF
	ldy     $F2
LA21E:  iny
	lda     ($E9),y
	sty     $F3
	ldx     #$01
	jsr     LA2CE
	ldy     $F3
	cpy     $F1
	bne     LA21E
	lda     LA3A0
	clc
	adc     #$B0
	ldx     #$01
	jsr     LA2CE
	lda     $F8
	jsr     LA2BF
	lda     $36
	pha
	lda     $37
	pha
	lda     $B300
	jsr     LFE95
	ldy     #$9E
	lda     #$A4
	jsr     LA4EA
	jsr     LFD8E
LA254:  ldy     #$AB
	lda     #$A4
	jsr     LA4EA
	jsr     LA315
	jsr     LFD8E
	ldy     #$A7
	lda     #$A4
	jsr     LA4EA
	jsr     LA315
	jsr     LFD8E
	dec     $FA
	bne     LA254
	jsr     LFD8E
	lda     $FB
	clc
	adc     $FC
	tay
	jsr     LA504
	lda     $F9
	clc
	adc     #$B0
	jsr     LFDED
	lda     #$A0
	jsr     LFDED
	ldy     $EF
	lda     $F0
	jsr     LA4EA
	lda     #$A0
	jsr     LFDED
	lda     LA3A0
	clc
	adc     #$B0
	jsr     LFDED
	ldy     #$AF
	lda     #$A4
	jsr     LA4EA
	jsr     LFD8E
	pla
	sta     $37
	pla
	sta     $36
	ldx     #$CC
	jmp     xmmgr

LA2B5:  lda     #$00
	jmp     LA30C

LA2BA:  lda     #$FF
	jmp     LA30C

LA2BF:  asl     a
	tax
	lda     LA3C9,x
	sta     $ED
	inx
	lda     LA3C9,x
	sta     $EE
	.byte   $80
	plp
LA2CE:  ldy     #$00
LA2D0:  iny
	cmp     ($E7),y
	bne     LA2D0
	dey
	tya
	asl     a
	cpx     #$00
	bne     LA2EA
	tax
	lda     LA3A1,x
	sta     $ED
	inx
	lda     LA3A1,x
	sta     $EE
	.byte   $80
	.byte   $0C
LA2EA:  tax
	lda     LA3B5,x
	sta     $ED
	inx
	lda     LA3B5,x
	sta     $EE
	.byte   $B2
	sbc     LA0AA
	brk
LA2FB:  iny
	lda     ($ED),y
	beq     LA305
	jsr     LA2BA
	.byte   $80
	.byte   $03
LA305:  jsr     LA2B5
	dex
	bne     LA2FB
	rts

LA30C:  .byte   $5A
	ldy     $E6
	sta     ($E4),y
	inc     $E6
	.byte   $7A
	rts

LA315:  ldy     $FC
	iny
	iny
	jsr     LA504
	ldy     #$A4
	lda     #$A4
	jsr     LA4EA
	lda     $FE
	jsr     LFDED
	lda     $FD
	ldy     $E6
	jsr     LA513
	pha
	tya
	jsr     LFDED
	pla
	jsr     LFDED
	ldy     #$00
LA33A:  lda     ($E4),y
	ldx     $FD
LA33E:  jsr     LFDED
	dex
	bne     LA33E
	iny
	.byte   $C4
LA346:  inc     $D0
	sbc     ($60),y
LA34A:  .byte   $9C
	ldy     #$A3
	lda     $F9
	ldy     #$03
	jsr     LA513
	sty     LA39E
	sta     LA39F
	ldy     #$00
LA35C:  iny
	lda     ($E9),y
	sec
	sbc     #$B0
	pha
	lda     LA3CF,y
	sty     $F3
	tay
	pla
	jsr     LA513
	tya
	clc
LA36F:  adc     LA39E
	sta     LA39E
	lda     #$00
	adc     LA39F
	sta     LA39F
	ldy     $F3
	cpy     $F1
	bne     LA35C
	ldy     LA39E
	lda     LA39F
	ldx     #$0A
	jsr     LA546
LA38E:  tya
	sta     LA3A0
	beq     LA39D
	lda     #$0A
	sec
	sbc     LA3A0
	sta     LA3A0
LA39D:  rts

LA39E:  .byte   $EE
LA39F:  .byte   $A0
LA3A0:  .byte   $A0
LA3A1:  beq     LA346
	brk
	ldy     $10
	ldy     $20
	ldy     $30
	ldy     $40
	ldy     $50
	ldy     $60
	ldy     $70
	ldy     $80
	.byte   $A4
LA3B5:  sed
	.byte   $A3
	php
	ldy     $18
	ldy     $28
	ldy     $38
	ldy     $48
	ldy     $58
	ldy     $68
	ldy     $78
	ldy     $88
	.byte   $A4
LA3C9:  bcc     LA36F
	sty     $A4,x
	txs
	.byte   $A4
LA3CF:  .byte   $03
	ora     ($03,x)
	ora     ($03,x)
	ora     ($03,x)
	ora     ($03,x)
	ora     ($03,x)
	asl     a
	bcs     LA38E
	.byte   $B2
	.byte   $B3
	ldy     $B5,x
	ldx     $B7,y
	clv
	lda     $B00A,y
	lda     ($B2),y
	.byte   $B3
	ldy     $B5,x
	ldx     $B7,y
	clv
	lda     $07,y
	brk
	brk
	ora     ($01,x)
	brk
	ora     ($07,x)
	ora     ($01,x)
	ora     ($00,x)
	brk
	ora     ($00,x)
	.byte   $07
	brk
	brk
	ora     ($01,x)
	brk
	brk
	ora     ($07,x)
	ora     ($01,x)
	brk
	brk
	ora     ($01,x)
	brk
	.byte   $07
	brk
	brk
	ora     ($00,x)
	brk
	ora     ($01,x)
	.byte   $07
	ora     ($01,x)
	brk
	ora     ($01,x)
	brk
	brk
	.byte   $07
	brk
	ora     ($01,x)
	ora     ($01,x)
	brk
	ora     ($07,x)
	ora     ($00,x)
	brk
	brk
	brk
	ora     ($00,x)
	.byte   $07
	brk
	ora     ($00,x)
	brk
	brk
	ora     ($01,x)
	.byte   $07
	ora     ($00,x)
	ora     ($01,x)
	ora     ($00,x)
	brk
	.byte   $07
	brk
	ora     ($01,x)
	brk
	brk
	brk
	ora     ($07,x)
	ora     ($00,x)
	brk
	ora     ($01,x)
	ora     ($00,x)
	.byte   $07
	brk
	ora     ($00,x)
	ora     ($01,x)
	ora     ($01,x)
	.byte   $07
	ora     ($00,x)
	ora     ($00,x)
	brk
	brk
	brk
	.byte   $07
	brk
	ora     ($01,x)
	ora     ($00,x)
	ora     ($01,x)
	.byte   $07
	ora     ($00,x)
	brk
	brk
	ora     ($00,x)
	brk
	.byte   $07
	brk
	ora     ($01,x)
	brk
	ora     ($01,x)
	ora     ($07,x)
	ora     ($00,x)
	brk
	ora     ($00,x)
	brk
	brk
	.byte   $07
	brk
	brk
	brk
	ora     ($00,x)
	ora     ($01,x)
	.byte   $07
	ora     ($01,x)
	ora     ($00,x)
	ora     ($00,x)
LA48F:  brk
	.byte   $03
	ora     ($00,x)
	ora     ($05,x)
	brk
	ora     ($00,x)
	ora     ($00,x)
	.byte   $03
	ora     ($00,x)
	ora     ($05,x)
	.byte   $89
	iny
	.byte   $9B
	lda     ($C0,x)
	.byte   $02
	.byte   $9B
	tax
	.byte   $03
	.byte   $9B
	.byte   $B3
	asl     $03,x
	.byte   $9B
	.byte   $B3
	ora     ($02,x)
	.byte   $9B
	.byte   $B2
LA4B2:  lda     $FBB3
	cmp     #$38
	beq     LA4C7
	cmp     #$EA
	beq     LA4C7
	lda     $FBC0
	cmp     #$EA
	beq     LA4C7
	clc
	bne     LA4E9
LA4C7:  jsr     xbell
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
	bcs     LA48F
	ldy     #$F2
	sbc     $F1
	sbc     $E9,x
	.byte   $F2
	sbc     $E4
	sta     $3800
LA4E9:  rts

LA4EA:  sta     $E1
	sty     $E0
	txa
	pha
	ldy     #$00
	lda     ($E0),y
	beq     LA501
	tax
	iny
LA4F8:  lda     ($E0),y
	jsr     LFDED
	iny
	dex
	bne     LA4F8
LA501:  pla
	tax
	rts

LA504:  cpy     #$00
	beq     LA512
	pha
	lda     #$A0
LA50B:  jsr     LFDED
	dey
	bne     LA50B
	pla
LA512:  rts

LA513:  .byte   $DA
	sta     LA542
	sty     LA543
	lda     #$00
	sta     LA544
	sta     LA545
	ldx     #$08
LA524:  asl     a
	rol     LA545
	asl     LA543
	bcc     LA536
	clc
	adc     LA542
	bcc     LA536
	inc     LA545
LA536:  dex
	bne     LA524
	sta     LA544
	tay
	lda     LA545
	.byte   $FA
	rts

LA542:  .byte   $A0
LA543:  .byte   $A0
LA544:  .byte   $A0
LA545:  .byte   $A0
LA546:  sty     LA56E
	sta     LA56F
	stx     LA570
	ldx     #$08
	sty     LA571
LA554:  asl     LA571
	rol     a
	cmp     LA570
	bcc     LA563
	sbc     LA570
	inc     LA571
LA563:	dex
	bne     LA554
	sta     LA572
	tay
	lda     LA571
	rts

LA56E:  .byte   $E4
LA56F:  .byte   $80
LA570:  tax
LA571:  .byte   $A0
LA572:  .byte   $A0
