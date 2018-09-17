	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_9000"

L03D9	= $03D9
L03E6	= $03E6
L048D	= $048D
L05A8	= $05A8
L203D	= $203D
L6162	= $6162
L6165	= $6165
L616F	= $616F
L676F	= $676F
L6D6F	= $6D6F
L6E65	= $6E65
L6E69	= $6E69
L6F74	= $6F74
L726F	= $726F
L7361	= $7361
L7369	= $7369
L7465	= $7465
LFD8E	= $FD8E
LFDED	= $FDED
LB3AD	= $b3ad
LBF00	= $bf00

        rts

        inc     $12EE
        .byte   $12
        brk
        clc
        bcc     L9009
L9009:  bcc     L905D
        bcc     L9010
        brk
        brk
        brk
L9010:  brk
        .byte   $04
        .byte   $F3
        brk
L9014:  sbc     $00,x
        brk
        brk
        and     $E9EC,y
        .byte   $F3
        .byte   $F4
        ldy     #$AD
        lda     $C1A0
        beq     L9014
        cpx     $D3E5
        .byte   $EF
        inc     $F4
        ldy     #$CC
        cmp     #$D3
        .byte   $D4
        ldy     #$C3
        .byte   $EF
        sbc     $E1ED
        inc     $A0E4
        inc     $EF
        .byte   $F2
        ldy     #$C4
        sbc     ($F6,x)
        sbc     $F8
        ldy     #$AF
        ldy     #$E2
        sbc     $CAA0,y
        sbc     $E6
        inc     $A0
        iny
        sbc     ($EE,x)
        .byte   $F3
        sbc     $EE
        sty     L9675
        sta     L9676
        sty     L9687
        .byte   $8D
        dey
L905D:  stx     $20,y
        .byte   $47
        .byte   $92
        bcc     L9064
        rts

L9064:  .byte   $64
        sbc     #$A9
        .byte   $F3
        jsr     xgetparm_ch
        bcs     L9071
        lda     #$FF
        sta     $E9
L9071:  .byte   $64
        inx
        lda     #$FF
        sta     L9239
        lda     #$F5
        jsr     xgetparm_ch
        bcs     L908B
        lda     #$DF
        sta     L9239
        lda     #$FF
        sta     $E8
        .byte   $9C
        lsr     $92
L908B:  jsr     LBF00
        cpy     $74
        stx     $90,y
        .byte   $03
        jmp     xProDOS_err

        lda     L9678
        cmp     #$FC
        beq     L90C0
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
        ldy     #$C2
        cmp     ($D3,x)
        sbc     #$E3
        ldy     #$E6
        sbc     #$EC
        sbc     $8D
        brk
        jmp     xerr

L90C0:  jsr     LBF00
        iny
        stx     $96
        bcc     L90CB
        jmp     xProDOS_err

L90CB:  lda     L968B
        sta     L968D
        sta     L9695
        jsr     L91A2
        lda     L9692
        bne     L90E4
        lda     L9693
        bne     L90E4
        jmp     L9186

L90E4:  jsr     L918D
        sta     $EA
        jsr     L918D
        bne     L90F5
        lda     $EA
        bne     L90F5
        jmp     L9186

L90F5:  jsr     L918D
        sta     $E6
        jsr     L918D
        sta     $E7
        lda     $E6
        sta     $61
        lda     $E7
        sta     $62
        .byte   $64
        .byte   $63
        sty     $EC
        lda     $E9
        bmi     L9116
        ldy     #$04
        jsr     xprdec_pady
        .byte   $80
        .byte   $03
L9116:  jsr     xprdec_3
        ldy     $EC
        ldx     #$03
        jsr     L9209
L9120:  jsr     L918D
        bne     L9137
        jsr     LFD8E
        lda     #$20
        sta     L9246
        .byte   $64
        .byte   $EF
        jsr     xcheck_wait
        bcc     L90E4
        jmp     L9186

L9137:  bpl     L9154
        cpx     #$03
        beq     L9142
        pha
        jsr     L9209
        pla
L9142:  sty     $EC
        sta     $EF
        jsr     L91B5
        bcs     L9120
        jsr     L9213
        ldy     $EC
        ldx     #$01
        .byte   $80
        .byte   $CC
L9154:  cmp     #$3A
        bne     L9169
        ldx     L9246
        bne     L9165
        ldx     #$B2
        cpx     $EF
        bne     L9165
        .byte   $64
        .byte   $EF
L9165:  ldx     #$03
        .byte   $80
        .byte   $13
L9169:  cpx     #$03
        bne     L9171
        ldx     #$02
        .byte   $80
        .byte   $0B
L9171:  cpx     #$02
        beq     L917C
        ldx     #$02
        pha
        jsr     L9209
        pla
L917C:  ora     #$80
        jsr     L91D9
        jsr     LFDED
        .byte   $80
        txs
L9186:  jsr     LBF00
        cpy     L9694
        rts

L918D:  lda     ($E2),y
        pha
        iny
        bne     L91A0
        inc     $E3
        inc     $EB
        lda     #$04
        cmp     $EB
        bne     L91A0
        jsr     L91A2
L91A0:  pla
        rts

L91A2:  jsr     LBF00
        dex
        sty     $A996
        brk
L91AA:  sta     $E2
        lda     #$08
        sta     $E3
        .byte   $64
        .byte   $EB
        ldy     #$00
        rts

L91B5:  sta     $EE
        lda     #$7F
        sta     $E4
        lda     #$92
        sta     $E5
L91BF:  .byte   $B2
        cpx     $F0
        bpl     L91AA
        cpx     $D0
        .byte   $02
        inc     $E5
        cmp     $EE
        bne     L91BF
        lda     $E5
        ldy     $E4
        clc
        rts

        lda     #$00
        ldy     #$00
        sec
        rts

L91D9:  sta     $EE
        lda     $E8
        bmi     L9206
        lda     #$83
        cmp     $EF
        beq     L9206
        lda     #$B2
        cmp     $EF
        beq     L9206
        lda     $EE
        cmp     #$A2
        bne     L9200
        lda     L9246
        beq     L91FB
        .byte   $9C
        lsr     $92
        .byte   $80
        .byte   $05
L91FB:  lda     #$20
        sta     L9246
L9200:  lda     $EE
        jsr     L923A
        rts

L9206:  lda     $EE
        rts

L9209:  lda     $E9
        bmi     L9212
        lda     #$A0
        jsr     LFDED
L9212:  rts

L9213:  sta     $E1
        sty     $E0
        .byte   $B2
        cpx     #$F0
        ora     ($AA),y
        ldy     #$01
L921E:  lda     ($E0),y
        ora     #$80
        .byte   $20
        .byte   $2D
L9224:  .byte   $92
        jsr     LFDED
        iny
        dex
        bne     L921E
        rts

L922D:  cmp     #$E1
        bcc     L9238
        cmp     #$FB
        bcs     L9238
        and     L9239
L9238:  rts

L9239:  .byte   $DF
L923A:  cmp     #$C1
        bcc     L9245
        cmp     #$DB
        bcs     L9245
        ora     L9246
L9245:  rts

L9246:  jsr     LB3AD
        .byte   $FB
        cmp     #$38
        beq     L925C
        cmp     #$EA
        beq     L925C
        lda     $FBC0
        cmp     #$EA
        beq     L925C
        clc
        bne     L927E
L925C:  jsr     xbell
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
        bcs     L9224
        ldy     #$F2
        sbc     $F1
        sbc     $E9,x
        .byte   $F2
        sbc     $E4
        sta     $3800
L927E:  rts

        .byte   $80
        .byte   $03
        adc     $6E
        .byte   $64
        sta     ($03,x)
        ror     $6F
        .byte   $72
        .byte   $82
        .byte   $04
        ror     $7865
        .byte   $74
        .byte   $83
        .byte   $04
        .byte   $64
        adc     ($74,x)
        adc     ($84,x)
        ora     $69
        ror     $7570
        .byte   $74
        sta     $03
        .byte   $64
        adc     $6C
        stx     $03
        .byte   $64
        adc     #$6D
        .byte   $87
        .byte   $04
        .byte   $72
        adc     $61
        .byte   $64
        dey
        .byte   $02
        .byte   $67
        .byte   $72
        .byte   $89
        .byte   $04
        .byte   $74
        adc     $78
        .byte   $74
        txa
        .byte   $03
        bvs     L932C
        .byte   $23
        .byte   $8B
        .byte   $03
        adc     #$6E
        .byte   $23
        sty     $6304
        adc     ($6C,x)
        jmp     (L048D)

        bvs     L9336
        .byte   $6F
        .byte   $74
        stx     $6804
        jmp     (L6E69)

        .byte   $8F
        .byte   $04
        ror     $6C,x
        adc     #$6E
        bcc     L92DE
        pla
        .byte   $67
        .byte   $72
        .byte   $32
L92DE:  sta     ($03),y
        pla
        .byte   $67
        .byte   $72
        .byte   $92
        .byte   $07
        pla
        .byte   $63
        .byte   $6F
        jmp     (L726F)

        and     $0593,x
        pla
        bvs     L935D
        .byte   $6F
        .byte   $74
        sty     $04,x
        .byte   $64
        .byte   $72
        adc     ($77,x)
        .byte   $95
L92FA:  ora     $78
        .byte   $64
        .byte   $72
        adc     ($77,x)
        stx     $04,y
        pla
        .byte   $74
        adc     ($62,x)
        .byte   $97
        .byte   $04
        pla
        .byte   $6F
        adc     $9865
        .byte   $04
        .byte   $72
        .byte   $6F
        .byte   $74
        and     $0699,x
        .byte   $73
        .byte   $63
        adc     ($6C,x)
        adc     $3D
        txs
        asl     $73
        pla
        jmp     (L616F)

        .byte   $64
        .byte   $9B
        ora     $74
        .byte   $72
        adc     ($63,x)
        adc     $9C
        .byte   $07
        .byte   $6E
L932C:  .byte   $6F
        .byte   $74
        .byte   $72
        adc     ($63,x)
        adc     $9D
        asl     $6E
        .byte   $6F
L9336:  .byte   $72
        adc     $6C61
        .byte   $9E
        .byte   $07
        adc     #$6E
        ror     $65,x
        .byte   $72
        .byte   $73
        adc     $9F
        ora     $66
        jmp     (L7361)

        pla
        ldy     #$06
        .byte   $63
        .byte   $6F
        jmp     (L726F)

        and     $03A1,x
        bvs     L93C5
        bvs     L92FA
        .byte   $04
        ror     $74,x
        adc     ($62,x)
L935D:  .byte   $A3
        asl     $68
        adc     #$6D
        adc     $6D
        .byte   $3A
        ldy     $06
        jmp     (L6D6F)

        adc     $6D
        .byte   $3A
        lda     $05
        .byte   $6F
        ror     $7265
        .byte   $72
        ldx     $06
        .byte   $72
        adc     $73
        adc     $6D,x
        adc     $A7
        asl     $72
        adc     $63
        .byte   $61
L9382:  jmp     ($A86C)

        ora     $73
        .byte   $74
        .byte   $6F
        .byte   $72
        adc     $A9
        asl     $73
        bvs     L93F5
        adc     $64
        and     $03AA,x
        jmp     (L7465)

        .byte   $AB
        .byte   $04
        .byte   $67
        .byte   $6F
        .byte   $74
        .byte   $6F
        ldy     $7203
        adc     $6E,x
        lda     $6902
        ror     $AE
        .byte   $07
        .byte   $72
        adc     $73
        .byte   $74
        .byte   $6F
        .byte   $72
        adc     $AF
        ora     ($26,x)
        bcs     L93BA
        .byte   $67
        .byte   $6F
        .byte   $73
        adc     $62,x
L93BA:  lda     ($06),y
        .byte   $72
        adc     $74
        adc     $72,x
        ror     $03B2
        .byte   $72
L93C5:  adc     $6D
        .byte   $B3
        .byte   $04
        .byte   $73
        .byte   $74
        .byte   $6F
        bvs     L9382
        .byte   $02
        .byte   $6F
        ror     $04B5
        .byte   $77
        adc     ($69,x)
        .byte   $74
        ldx     $04,y
        jmp     (L616F)

        .byte   $64
        .byte   $B7
        .byte   $04
        .byte   $73
        adc     ($76,x)
        adc     $B8
        .byte   $03
        .byte   $64
        adc     $66
        lda     $7004,y
        .byte   $6F
        .byte   $6B
        adc     $BA
        ora     $70
        .byte   $72
        adc     #$6E
        .byte   $74
L93F5:  .byte   $BB
        .byte   $04
        .byte   $63
        .byte   $6F
        ror     $BC74
        .byte   $04
        jmp     (L7369)

        .byte   $74
        lda     $6305,x
        jmp     (L6165)

        .byte   $72
        ldx     $6703,y
        adc     $74
        .byte   $BF
        .byte   $03
        ror     $7765
        cpy     #$04
        .byte   $74
        adc     ($62,x)
        plp
        cmp     ($02,x)
        .byte   $74
        .byte   $6F
        .byte   $C2
        .byte   $02
        ror     $6E
        .byte   $C3
        .byte   $04
        .byte   $73
        bvs     L9488
        plp
        cpy     $04
        .byte   $74
        pla
        adc     $6E
        cmp     $02
        adc     ($74,x)
        dec     $03
        ror     $746F
        .byte   $C7
        .byte   $04
        .byte   $73
        .byte   $74
        adc     $70
        iny
        ora     ($2B,x)
        cmp     #$01
        and     $01CA
        rol     a
        .byte   $CB
        ora     ($2F,x)
        cpy     $5E01
        cmp     $6103
        ror     $CE64
        .byte   $02
        .byte   $6F
        .byte   $72
        .byte   $CF
        ora     ($3E,x)
        bne     L9459
        .byte   $3D
L9459:  cmp     ($01),y
        .byte   $3C
        .byte   $D2
        .byte   $03
        .byte   $73
        .byte   $67
        ror     $03D3
        adc     #$6E
        .byte   $74
        .byte   $D4
        .byte   $03
        adc     ($62,x)
        .byte   $73
        cmp     $03,x
        adc     $73,x
        .byte   $72
        dec     $03,x
        ror     $72
        adc     $D7
        ora     $73
        .byte   $63
L9479:  .byte   $72
        ror     $D828
        .byte   $03
        bvs     L94E4
        jmp     (L03D9)

        bvs     L94F4
        .byte   $73
        .byte   $DA
        .byte   $03
L9488:  .byte   $73
        adc     ($72),y
        .byte   $DB
        .byte   $03
        .byte   $72
        ror     $DC64
        .byte   $03
        jmp     (L676F)

        cmp     $6503,x
        sei
        bvs     L9479
        .byte   $03
        .byte   $63
        .byte   $6F
        .byte   $73
        .byte   $DF
        .byte   $03
        .byte   $73
        adc     #$6E
        cpx     #$03
        .byte   $74
        adc     ($6E,x)
        sbc     ($03,x)
        adc     ($74,x)
        ror     $04E2
        bvs     L9517
        adc     $6B
        .byte   $E3
        .byte   $03
        jmp     (L6E65)

        cpx     $04
        .byte   $73
        .byte   $74
        .byte   $72
        bit     $E5
        .byte   $03
        ror     $61,x
        jmp     (L03E6)

        adc     ($73,x)
        .byte   $63
        .byte   $E7
        .byte   $04
        .byte   $63
        pla
        .byte   $72
        bit     $E8
        ora     $6C
        adc     $66
        .byte   $74
        bit     $E9
        asl     $72
        adc     #$67
        pla
        .byte   $74
        bit     $EA
        .byte   $04
        adc     $6469
        .byte   $24
L94E4:  .byte   $EB
        ora     ($5B),y
        bit     $65
        .byte   $62
        jsr     L203D
        .byte   $62
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
L94F4:  adc     $6E
        eor     $11EC,x
        .byte   $5B
        bit     $65
        .byte   $63
        jsr     L203D
        .byte   $62
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11ED,x
        .byte   $5B
        bit     $65
        .byte   $64
        jsr     L203D
        .byte   $62
        adc     ($64,x)
        .byte   $20
L9517:  .byte   $74
        .byte   $6F
        .byte   $6B
        adc     $6E
        eor     $11EE,x
        .byte   $5B
        bit     $65
        adc     $20
        and     $6220,x
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11EF,x
        .byte   $5B
        bit     $65
        ror     $20
        and     $6220,x
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11F0,x
        .byte   $5B
        bit     $66
        bmi     L956A
        and     $6220,x
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11F1,x
        .byte   $5B
        bit     $66
        and     ($20),y
        and     $6220,x
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        .byte   $5D
        .byte   $F2
L956A:  ora     ($5B),y
        bit     $66
        .byte   $32
        jsr     L203D
        .byte   $62
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11F3,x
        .byte   $5B
        bit     $66
        .byte   $33
        jsr     L203D
        .byte   $62
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11F4,x
        .byte   $5B
        bit     $66
        .byte   $34
        jsr     L203D
        .byte   $62
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11F5,x
        .byte   $5B
        bit     $66
        and     $20,x
        and     $6220,x
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11F6,x
        .byte   $5B
        bit     $66
        rol     $20,x
        and     $6220,x
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11F7,x
        .byte   $5B
        bit     $66
        .byte   $37
        jsr     L203D
        .byte   $62
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11F8,x
        .byte   $5B
        bit     $66
        sec
        jsr     L203D
        .byte   $62
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11F9,x
        .byte   $5B
        bit     $66
        and     $3D20,y
        jsr     L6162
        .byte   $64
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11FA,x
        .byte   $5B
        bit     $66
        adc     ($20,x)
        and     $6220,x
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11FB,x
        .byte   $5B
        bit     $66
        .byte   $62
        jsr     L203D
        .byte   $62
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11FC,x
        .byte   $5B
        bit     $66
        .byte   $63
        jsr     L203D
        .byte   $62
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11FD,x
        .byte   $5B
        bit     $66
        .byte   $64
        jsr     L203D
        .byte   $62
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11FE,x
        .byte   $5B
        bit     $66
        adc     $20
        and     $6220,x
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $11FF,x
        .byte   $5B
        bit     $66
        ror     $20
        and     $6220,x
        adc     ($64,x)
        jsr     L6F74
        .byte   $6B
        adc     $6E
        eor     $0A00,x
L9675:  .byte   $A0
L9676:  ldy     #$A0
L9678:  ldy     #$B1
        ldy     #$A0
        ldy     $A0,x
        ldy     #$A0
        ldy     #$A0
        .byte   $F3
        ldy     #$C9
        ldy     #$03
L9687:  ldy     $F2,x
        brk
        .byte   $0C
L968B:  ldy     #$04
L968D:  lda     $0800,y
        brk
        .byte   $04
L9692:  .byte   $A0
L9693:  .byte   $A0
L9694:  .byte   $01
L9695:  .byte   $A0
