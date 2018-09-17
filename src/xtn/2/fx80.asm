.segment "CODE_9000"

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

L8FD2           := $8FD2
LFD8E           := $FD8E
LFDED           := $FDED
LFE95           := $FE95
        rts

        inc     $10EE
        ora     ($00),y
        bit     a:$90
        bcc     L9075
        bcc     L900D
L900D:  brk
        brk
        brk
        .byte   $FA
        brk
        inc     $B100
        .byte   $07
        cpx     $07
        sbc     $07
        sbc     #$07
        sbc     $07,x
        beq     L9027
        .byte   $E3
        asl     $EC
        asl     $E6
        asl     $F3
L9027:  asl     $F2
        asl     $00
        brk
        and     $F8E6,x
        clv
        .byte   $B0
L9031:  ldy     #$AD
        lda     $D3A0
        sbc     $F4
        .byte   $F3
        ldy     #$EF
        .byte   $F0
L903C:  .byte   $F4
        sbc     #$EF
        inc     $A0F3
        inc     $EF
        .byte   $F2
        ldy     #$C5
        beq     L903C
        .byte   $EF
        inc     $C6A0
        cld
        lda     $B0B8
        ldy     #$F0
        .byte   $F2
        sbc     #$EE
        .byte   $F4
        sbc     $F2
        ldy     #$AF
        ldy     #$E2
        sbc     $CAA0,y
        sbc     $E6
        inc     $A0
        iny
        sbc     ($EE,x)
        .byte   $F3
        sbc     $EE
        jsr     xgetnump
        bne     L907A
        ldy     #$2C
        lda     #$90
        .byte   $20
        .byte   $46
L9075:  .byte   $93
        jsr     LFD8E
        rts

L907A:  ldx     #$00
L907C:  lda     #$00
        sta     L9323,x
        lda     L931D,x
        stx     $E2
        jsr     xgetparm_ch
        ldx     $E2
        bcs     L9094
        tya
        sta     L9328,x
        dec     L9323,x
L9094:  inx
        cpx     #$05
        bne     L907C
        ldx     #$00
        lda     L9323,x
        bpl     L911E
        lda     L9328,x
        cmp     #$05
        bne     L90AE
        lda     #$A0
        sta     L9328,x
        bne     L911E
L90AE:  cmp     #$06
        bne     L90B9
        lda     #$A1
        sta     L9328,x
        bne     L911E
L90B9:  cmp     #$08
        bne     L90C4
        .byte   $A9
L90BE:  ldy     $9D
        plp
        .byte   $93
        bne     L911E
L90C4:  cmp     #$0A
        bne     L90CF
        lda     #$C0
        sta     L9328,x
        bne     L911E
L90CF:  cmp     #$0C
        bne     L90DA
        .byte   $A9
L90D4:  cmp     ($9D,x)
        plp
        .byte   $93
        bne     L911E
L90DA:  cmp     #$11
        bne     L90E5
        lda     #$C4
        sta     L9328,x
        bne     L911E
L90E5:  jsr     xmess
        .byte   $E3
        beq     L90D4
        ldy     #$A8
        .byte   $E3
        inx
        sbc     ($F2,x)
        .byte   $F3
        ldy     #$F0
        sbc     $F2
        ldy     #$E9
        inc     $E8E3
        lda     #$A0
        sbc     $F3F5
L9100:  .byte   $F4
        ldy     #$E2
        sbc     $BA
        ldy     #$B5
        ldy     $B6A0
        ldy     $B8A0
        ldy     $B1A0
        bcs     L90BE
        ldy     #$B1
        .byte   $B2
        ldy     $B1A0
        .byte   $B7
        sta     $4C00
        pha
        .byte   $B0
L911E:  ldx     #$01
        lda     L9323,x
        bpl     L9177
        lda     L9328,x
        cmp     #$06
        bne     L9133
        lda     #$B2
        sta     L9328,x
        bne     L9177
L9133:  cmp     #$08
        bne     L913E
        lda     #$B0
        sta     L9328,x
        bne     L9177
L913E:  cmp     #$0A
        bne     L9149
        lda     #$B1
        sta     L9328,x
        bne     L9177
L9149:  jsr     xmess
        cpx     $E9F0
        ldy     #$A8
        cpx     $EEE9
        sbc     $F3
        ldy     #$F0
        sbc     $F2
        ldy     #$E9
        inc     $E8E3
        lda     #$A0
        sbc     $F3F5
        .byte   $F4
        ldy     #$E2
        sbc     $BA
        ldy     #$B6
        ldy     $B8A0
        ldy     $B1A0
        bcs     L9100
        brk
        jmp     xerr

L9177:  ldx     #$02
        lda     L9323,x
        bpl     L91B0
        lda     L9328,x
        cmp     #$17
        bcc     L91B0
        jsr     xmess
        inc     $EF
        .byte   $F2
        sbc     $ECA0
        sbc     $EE
        .byte   $E7
        .byte   $F4
        inx
        ldy     #$ED
        sbc     $F3,x
        .byte   $F4
        ldy     #$E2
        sbc     $BA
        ldy     #$B0
        ldy     #$F4
        .byte   $EF
        ldy     #$B2
        .byte   $B2
        ldy     #$E9
        inc     $E8E3
        sbc     $F3
        sta     $4C00
        pha
        .byte   $B0
L91B0:  ldx     #$03
        lda     L9323,x
        bpl     L91EE
        lda     L9328,x
        cmp     #$80
        bcc     L91EE
        jsr     xmess
        .byte   $F3
        .byte   $EB
        sbc     #$F0
        ldy     #$F0
        sbc     $F2
        inc     $EF
        .byte   $F2
        sbc     ($F4,x)
        sbc     #$EF
        inc     $EDA0
        sbc     $F3,x
        .byte   $F4
        ldy     #$E2
        sbc     $BA
        ldy     #$B0
        ldy     #$F4
        .byte   $EF
        ldy     #$B1
        .byte   $B2
        .byte   $B7
        ldy     #$EC
        sbc     #$EE
        sbc     $F3
        sta     $4C00
        pha
        .byte   $B0
L91EE:  ldx     #$04
        lda     L9323,x
        bpl     L9224
        lda     L9328,x
        cmp     #$09
        bcc     L9224
        jsr     xmess
        .byte   $E3
        inx
        sbc     ($F2,x)
        sbc     ($E3,x)
        .byte   $F4
        sbc     $F2
        ldy     #$F3
        sbc     $F4
        .byte   $F3
        ldy     #$E1
        inc     $E1,x
        sbc     #$EC
        sbc     ($E2,x)
        cpx     $BAE5
        ldy     #$B0
        ldy     #$F4
        .byte   $EF
        ldy     #$B8
        sta     $4C00
        pha
        .byte   $B0
L9224:  lda     $36
        pha
        lda     $37
        pha
        lda     $B300
        jsr     LFE95
        ldx     #$00
L9232:  lda     L92A6,x
        stx     $E2
        jsr     xgetparm_ch
        bcs     L924B
        lda     $E2
        asl     a
        tax
        lda     L92A9,x
        tay
        inx
        lda     L92A9,x
        jsr     L9346
L924B:  ldx     $E2
        inx
        .byte   $E0
L924F:  .byte   $02
        bne     L9232
        ldx     #$00
L9254:  lda     L92D4,x
        stx     $E2
        jsr     xgetparm_ch
        bcs     L9274
        pha
        lda     $E2
        asl     a
        asl     a
        tax
        pla
        bmi     L9269
        inx
        inx
L9269:  lda     L92DB,x
        tay
        inx
        lda     L92DB,x
L9271:  jsr     L9346
L9274:  ldx     $E2
        inx
        cpx     #$06
        bne     L9254
        ldx     #$00
L927D:  stx     $E2
        lda     L9323,x
        bpl     L929A
        txa
        asl     a
        tax
        lda     L932D,x
        tay
        inx
        lda     L932D,x
        jsr     L9346
        ldx     $E2
        lda     L9328,x
        jsr     LFDED
L929A:  inx
        cpx     #$05
        bne     L927D
        pla
        sta     $37
        pla
        sta     $36
        rts

L92A6:  .byte   $FA
        .byte   $EE
        brk
L92A9:  lda     $B092
        .byte   $92
        .byte   $02
        .byte   $9B
        cpy     #$23
        .byte   $9B
        bne     L924F
        .byte   $12
        .byte   $9B
        .byte   $D7
        bcs     L9254
        dec     $9B
        iny
        .byte   $9B
        .byte   $D4
        .byte   $9B
        beq     L9271
        .byte   $9B
        lda     $9BB0
        lda     $9B,x
        .byte   $D2
        brk
        .byte   $9B
L92CA:  .byte   $C3
        brk
        .byte   $0B
L92CD:  .byte   $9B
        .byte   $CF
        .byte   $9B
        cmp     $B0,x
        .byte   $9B
        .byte   $B2
L92D4:  lda     ($E4),y
        sbc     $E9
        sbc     $F0,x
        brk
L92DB:  .byte   $F3
        .byte   $92
        .byte   $F7
        .byte   $92
        .byte   $FB
        .byte   $92
        inc     $0192,x
        .byte   $93
        .byte   $04
        .byte   $93
        .byte   $07
        .byte   $93
        asl     a
        .byte   $93
        ora     $1193
        .byte   $93
        ora     $93,x
        ora     $0393,y
        .byte   $9B
        cmp     $B1,x
        .byte   $03
        .byte   $9B
        cmp     $B0,x
        .byte   $02
        .byte   $9B
        .byte   $C7
        .byte   $02
        .byte   $9B
        iny
        .byte   $02
        .byte   $9B
        cmp     $02
        .byte   $9B
        dec     $02
        .byte   $9B
        ldy     $02,x
        .byte   $9B
        lda     $03,x
        .byte   $9B
        lda     $03B1
        .byte   $9B
        lda     $03B0
        .byte   $9B
        beq     L92CA
        .byte   $03
        .byte   $9B
        beq     L92CD
L931D:  .byte   $E3
        cpx     $F3E6
        .byte   $F2
        brk
L9323:  ldy     #$A0
        sty     $A0
        .byte   $A0
L9328:  ldy     #$A0
        dec     $A0,x
        .byte   $A0
L932D:  .byte   $37
        .byte   $93
        .byte   $3A
        .byte   $93
        .byte   $3C
        .byte   $93
        rti

        .byte   $93
        .byte   $43
        .byte   $93
        .byte   $02
        .byte   $9B
        lda     ($01,x)
        .byte   $9B
        .byte   $03
        .byte   $9B
        .byte   $C3
        brk
        .byte   $02
        .byte   $9B
        dec     $9B02
        .byte   $D2
L9346:  sta     $E1
        sty     $E0
        txa
        pha
        ldy     #$00
        lda     ($E0),y
        beq     L935D
        tax
        iny
L9354:  lda     ($E0),y
        jsr     LFDED
        iny
        dex
        bne     L9354
L935D:  pla
        tax
        rts

