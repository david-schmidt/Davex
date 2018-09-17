	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_9000"

LBF00           := $BF00

        rts

        inc     $10EE
        ora     ($00),y
        .byte   $14
        bcc     L9009
L9009:  bcc     L9059
        bcc     L900D
L900D:  brk
        brk
        brk
        brk
        .byte   $03
        brk
        brk
        and     $E8E3,y
        .byte   $E3
        sbc     ($F3,x)
        sbc     $A0
        lda     $A0AD
        .byte   $C3
        inx
        sbc     ($EE,x)
        .byte   $E7
        sbc     $A0
        .byte   $C3
        sbc     ($F3,x)
        sbc     $A0
        tsx
        ldy     #$C5
        sed
        .byte   $F4
        sbc     $F2
        inc     $ECE1
        ldy     #$C3
        .byte   $EF
        sbc     $E1ED
        inc     $A0E4
        .byte   $AF
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
        sty     L9187
        sta     L9188
        .byte   $20
L9059:  lsr     L9091
        ora     ($60,x)
        lda     #$0A
        sta     L9186
        jsr     LBF00
        cpy     $86
        sta     ($90),y
        .byte   $03
        jmp     xProDOS_err

        lda     L918A
        cmp     #$1A
        beq     L90A6
        cmp     #$19
        beq     L90A6
        cmp     #$1B
        beq     L90A6
        jsr     xmess
        tax
        tax
        tax
        ldy     #$E5
L9085:  .byte   $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$EE
        .byte   $EF
        .byte   $F4
        ldy     #$E1
        .byte   $EE
L9091:  ldy     #$C1
        beq     L9085
        cpx     $D7E5
        .byte   $EF
        .byte   $F2
        .byte   $EB
        .byte   $F3
        ldy     #$E6
        sbc     #$EC
        sbc     $8D
        brk
        jmp     xerr

L90A6:  ldy     $E2
        lda     $E3
        jsr     L90DE
        sty     $E4
        sta     $E5
        .byte   $64
        inc     $64
        .byte   $E7
        .byte   $B2
        cpx     $A8
L90B8:  lda     ($E4),y
        cmp     #$E1
        ror     $E6
        ror     $E7
        dey
        bne     L90B8
        lda     $E6
        sta     L918B
        lda     $E7
        sta     L918C
        lda     #$07
        sta     L9186
        jsr     LBF00
        .byte   $C3
        stx     $91
        bcc     L90DD
        jmp     xProDOS_err

L90DD:  rts

L90DE:  .byte   $DA
        ldx     $E0
        .byte   $DA
        ldx     $E1
        sty     $E0
        sta     $E1
L90E8:  .byte   $B2
        cpx     #$F0
        eor     ($A8,x)
        lda     ($E0),y
        ora     #$80
        cmp     #$AF
        bne     L90F6
        dey
L90F6:  tya
        .byte   $92
        cpx     #$8D
        .byte   $4D
        .byte   $91
L90FC:  lda     ($E0),y
        ora     #$80
        cmp     #$AF
        beq     L9107
        dey
        bne     L90FC
L9107:  sty     L914C
        ldx     #$00
L910C:  iny
        inx
        lda     ($E0),y
        ora     #$80
        sta     L913C,x
        cpy     L914D
        bne     L910C
        stx     L913C
        lda     #$91
        ldy     #$3C
        .byte   $FA
        stx     $E1
        .byte   $FA
        stx     $E0
        ldx     L914C
        inx
L912B:  clc
        rts

        lda     #$91
        ldy     #$3C
        .byte   $9C
        .byte   $3C
        sta     ($FA),y
        stx     $E1
        .byte   $FA
        stx     $E0
        sec
        rts

L913C:  ldy     #$80
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$BB
        bcs     L90E8
        ldy     #$A0
        ldy     #$A0
L914C:  .byte   $A0
L914D:  ldy     #$AD
        .byte   $B3
        .byte   $FB
        cmp     #$38
        beq     L9163
        cmp     #$EA
        beq     L9163
        lda     $FBC0
        cmp     #$EA
        beq     L9163
        clc
        bne     L9185
L9163:  jsr     xbell
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
        bcs     L912B
        ldy     #$F2
        sbc     $F1
        sbc     $E9,x
        .byte   $F2
        sbc     $E4
        sta     $3800
L9185:  rts

L9186:  asl     a
L9187:  .byte   $A0
L9188:  ldy     #$F9
L918A:  .byte   $E2
L918B:  .byte   $A0
L918C:  ldy     #$A0
        .byte   $A3
        ldy     #$A0
        ldy     #$A0
        ldy     #$80
        cmp     ($A0,x)
        sed
