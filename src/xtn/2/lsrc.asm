	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_9000"

LBF00           := $BF00
LFDED           := $FDED
        rts

        inc     $10EE
        ora     ($00),y
        clc
        bcc     L9009
L9009:  bcc     L9065
        bcc     L900D
L900D:  brk
        brk
        brk
        brk
        .byte   $04
        inc     $EC00
        ora     ($00,x)
        brk
        eor     ($EC,x)
        .byte   $F3
        .byte   $F2
        .byte   $E3
        ldy     #$AD
        lda     $CCA0
        sbc     #$F3
L9024:  .byte   $F4
        .byte   $D3
        .byte   $EF
        sbc     $F2,x
        .byte   $E3
        sbc     $A0
        tay
        .byte   $EC
        .byte   $E9
L902F:  .byte   $F3
        .byte   $F4
        ldy     #$C1
        .byte   $F3
        .byte   $F3
        sbc     $ED
        .byte   $E2
        cpx     $F2E5
        ldy     #$F3
        .byte   $EF
        sbc     $F2,x
        .byte   $E3
        sbc     $A0
        inc     $E9
        cpx     $F3E5
        lda     #$A0
        .byte   $AF
        ldy     #$E2
        sbc     $CAA0,y
        sbc     $E6
        inc     $A0
        iny
        sbc     ($EE,x)
        .byte   $F3
        sbc     $EE
        sty     L9233
        sta     L9234
        sty     L9245
        .byte   $8D
        .byte   $46
L9065:  .byte   $92
        jsr     L9258
        bcc     L906C
        rts

L906C:  .byte   $64
        cpx     #$A9
        inc     a:$20
        bcs     L9024
        .byte   $02
        dec     $E0
        .byte   $64
        sbc     ($A9,x)
        cpx     a:$20
        bcs     L902F
        .byte   $3A
        dec     $E1
        sty     $E2
        stx     $E3
        lda     $E3
        bne     L90BA
        lda     $E2
        bne     L90BA
        jsr     xmess
        tax
L9092:  tax
        tax
        ldy     #$E5
        .byte   $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$F3
        .byte   $F4
        sbc     ($F2,x)
        .byte   $F4
        sbc     #$EE
        .byte   $E7
        ldy     #$EC
        sbc     #$EE
        sbc     $A0
        sbc     $F3F5
        .byte   $F4
        ldy     #$E2
        sbc     $A0
        ldx     $B0A0,y
        sta     $4C00
        pha
        .byte   $B0
L90BA:  jsr     LBF00
        cpy     $32
        .byte   $92
        bcc     L90C5
        jmp     xProDOS_err

L90C5:  lda     L9236
        cmp     #$04
        beq     L9101
        cmp     #$B0
        beq     L9101
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
        ldy     #$F3
        .byte   $EF
        sbc     $F2,x
        .byte   $E3
        sbc     $A0
        tay
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

L9101:  jsr     LBF00
        iny
        .byte   $44
        .byte   $92
        bcc     L910C
        jmp     xProDOS_err

L910C:  lda     L9249
        sta     L924B
        sta     L924F
        sta     L9257
        .byte   $64
        cpx     $64
        sbc     $20
        brk
        .byte   $BF
        cmp     #$4A
        .byte   $92
        bcc     L9127
        jmp     xProDOS_err

L9127:  jsr     LBF00
        dex
        lsr     L9092
        .byte   $13
        cmp     #$4C
        beq     L9136
        jmp     xProDOS_err

L9136:  jsr     LBF00
        cpy     L9256
        bcc     L9141
        jmp     xProDOS_err

L9141:  rts

        lda     L9255
        bne     L9127
        inc     $E4
        bne     L914D
        inc     $E5
L914D:  lda     $E1
        bpl     L915F
        lda     $E3
        cmp     $E5
        bne     L9127
        lda     $E2
        cmp     $E4
        bne     L9127
        .byte   $64
        .byte   $E1
L915F:  lda     $E0
        bmi     L9177
        lda     $E4
        sta     $61
        lda     $E5
        sta     $62
        .byte   $64
        .byte   $63
        ldy     #$03
        jsr     xprdec_pady
        lda     #$A0
        jsr     LFDED
L9177:  .byte   $64
        inc     $64
        .byte   $E7
        dec     L9254
        ldx     #$00
        lda     $0C00,x
        ora     #$80
        cmp     #$AA
        beq     L91BD
        cmp     #$BB
        beq     L91BD
L918D:  lda     $E7
        cmp     #$03
        bcs     L91BD
        lda     $0C00,x
        ora     #$80
        cmp     #$BB
        bne     L91A3
        ldy     #$02
        sty     $E7
        dex
        .byte   $80
        .byte   $4B
L91A3:  sta     $E8
        cmp     #$A7
        beq     L91CF
        cmp     #$A2
        beq     L91CF
        cmp     #$A0
        beq     L91EE
        jsr     LFDED
        inc     $E6
        jsr     L921A
        bcs     L9224
        .byte   $80
        .byte   $D0
L91BD:  lda     $0C00,x
        ora     #$80
        jsr     LFDED
        inc     $E6
        jsr     L921A
        bcc     L91BD
        jmp     L9224

L91CF:  jsr     LFDED
        inc     $E6
L91D4:  jsr     L921A
        bcs     L9224
        lda     $0C00,x
        ora     #$80
        jsr     LFDED
        inc     $E6
        cmp     $E8
        bne     L91D4
        jsr     L921A
        bcc     L918D
        .byte   $80
        .byte   $36
L91EE:  .byte   $DA
        ldx     $E7
        lda     L922F,x
        sec
        sbc     $E6
        .byte   $3A
        bpl     L91FC
        lda     #$00
L91FC:  .byte   $1A
        tay
        clc
        adc     $E6
        sta     $E6
        jsr     L9291
        .byte   $FA
        inc     $E7
L9209:  jsr     L921A
        bcs     L9224
        lda     $0C00,x
        ora     #$80
        cmp     #$A0
        beq     L9209
        jmp     L918D

L921A:  cpx     L9254
        beq     L9222
        inx
        clc
        rts

L9222:  sec
        rts

L9224:  jsr     xcheck_wait
        bcc     L922C
        jmp     L9136

L922C:  jmp     L9127

L922F:  .byte   $0F
        clc
        rol     $0A
L9233:  .byte   $CC
L9234:  clv
        .byte   $EE
L9236:  ldy     #$A0
        ldy     #$B0
        .byte   $80
        cpy     $A0A0
        ldy     #$82
        ldy     #$AA
        sbc     $A0,x
        .byte   $03
L9245:  ldy     #$EE
        brk
        php
L9249:  ldy     #$03
L924B:  tax
        .byte   $7F
        .byte   $0D
        .byte   $04
L924F:  sed
        brk
        .byte   $0C
        brk
        .byte   $04
L9254:  .byte   $A0
L9255:  .byte   $80
L9256:  .byte   $01
L9257:  .byte   $A0
L9258:  lda     $FBB3
        cmp     #$38
        beq     L926D
        cmp     #$EA
        beq     L926D
        lda     $FBC0
        cmp     #$EA
        beq     L926D
        clc
        bne     L9290
L926D:  jsr     xbell
        jsr     xmess
        sta     $AAAA
        tax
        ldy     #$E5
        .byte   $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$B6
        lda     $C3,x
        bcs     L9236
        ldy     #$F2
        sbc     $F1
        sbc     $E9,x
        .byte   $F2
        sbc     $E4
        sta     $3800
L9290:  rts

L9291:  cpy     #$00
        beq     L929D
        lda     #$A0
L9297:  jsr     LFDED
        dey
        bne     L9297
L929D:  rts

