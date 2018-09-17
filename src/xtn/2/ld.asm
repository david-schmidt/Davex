	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_9000"
.org	$9000

L0020	= $0020
LBF00	= $BF00
LF94A	= $F94A
LFD8E	= $FD8E
LFDDA	= $FDDA
LFDED	= $FDED

        rts

        inc     $28EE
        .byte   $12
        brk
        .byte   $1C
        bcc     L9009
L9009:  bcc     L9060
        bcc     L9010
        brk
        brk
        brk
L9010:  brk
        .byte   $04
        .byte   $F4
L9013:  brk
        .byte   $F3
        brk
        inc     $08
        .byte   $E2
        .byte   $07
        brk
        brk
        sec
        .byte   $EC
        .byte   $E4
L901F:  ldy     #$AD
        lda     $CCA0
        sbc     #$F3
        .byte   $F4
        ldy     #$C4
        sbc     #$F2
        sbc     $E3
        .byte   $F4
        .byte   $EF
        .byte   $F2
        sbc     $BAA0,y
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
        nop
        sty     $E0
        sta     $E1
        jsr     L95D9
        bcc     L9060
        rts

L9060:  lda     #$00
        jsr     xredirect
        sta     $F5
        .byte   $64
        beq     L9013
        inc     L0020
        brk
        bcs     L901F
        .byte   $04
        sta     $F1
        dec     $F0
        .byte   $64
        .byte   $EF
        lda     #$F3
        jsr     xgetparm_ch
        bcs     L907F
        dec     $EF
L907F:  .byte   $64
        inc     $F4A9
        jsr     xgetparm_ch
        bcs     L908A
        dec     $EE
L908A:  .byte   $64
        .byte   $F2
        lda     #$E2
        jsr     xgetparm_ch
        bcs     L9099
        dec     $F2
        .byte   $29
L9096:  .byte   $80
        sta     $F3
L9099:  .byte   $B2
        cpx     #$D0
        jsr     L0020
        .byte   $BF
        .byte   $C7
        stx     L9096
        .byte   $03
        jmp     xProDOS_err

        ldy     L968F
        lda     L9690
        sty     $E0
        sta     $E1
        jsr     L9527
        sty     L9679
        sta     L967A
        .byte   $80
        ror     $E0A5,x
        sta     L9679
        lda     $E1
        sta     L967A
        jsr     LBF00
        cpy     $78
        stx     $90,y
        .byte   $03
        jmp     xProDOS_err

        lda     L967C
        cmp     #$0F
        bne     L90E4
        lda     L967F
        cmp     #$0F
        beq     L90E9
        cmp     #$0D
        beq     L90E9
L90E4:  lda     #$97
        jmp     xProDOS_err

L90E9:  ldy     $E0
        lda     $E1
        jsr     L9527
        bcs     L90FA
        sty     L9679
        sta     L967A
        .byte   $80
        .byte   $41
L90FA:  lda     $BF30
        sta     L968B
        jsr     LBF00
        cmp     $8A
        stx     $90,y
        .byte   $03
        jmp     xProDOS_err

        lda     #$18
        sta     $E4
        lda     #$96
        sta     $E5
        ldx     #$00
        ldy     #$00
        lda     L9628,x
        and     #$0F
        .byte   $1A
        sta     $EC
        .byte   $92
        cpx     $C8
        lda     #$2F
        sta     ($E4),y
L9126:  inx
        iny
        lda     L9628,x
        sta     ($E4),y
        cpy     $EC
        bne     L9126
        lda     $E4
        sta     L9679
        lda     $E5
        sta     L967A
        jsr     LBF00
        cpy     $78
        stx     $90,y
        .byte   $03
        jmp     xProDOS_err

        lda     #$02
        sta     $E2
        lda     #$1A
        sta     $E3
        .byte   $B2
        cpx     #$A8
        lda     ($E0),y
        and     #$7F
        cmp     #$2F
        bne     L915D
        dey
        tya
        .byte   $92
        .byte   $E0
L915D:  jsr     xpush_level
        ldy     $E0
        lda     $E1
        jsr     xdir_setup
        ldx     #$25
        lda     $1400,x
        sta     $EA
        inx
        lda     $1400,x
        sta     $EB
        .byte   $64
        sbc     $8E20
        sbc     $F5A5,x
        bmi     L9188
        jsr     xmess
        .byte   $8F
        .byte   $9B
        cld
        cmp     $8E98,y
        ldy     #$00
L9188:  ldy     $E0
        lda     $E1
        jsr     xprint_path
        jsr     xmess
        ldy     #$A0
        ldy     #$A0
        tay
        brk
        ldy     $EA
        lda     $EB
        jsr     xprdec_2
        jsr     xmess
        ldy     #$E6
        sbc     #$EC
        sbc     $00
        ldy     $EA
        lda     $EB
        .byte   $20
L91AD:  rol     $B0,x
        jsr     xmess
L91B2:  lda     #$8D
        brk
        jsr     L9426
        .byte   $20
L91B9:  asl     $B0
        inc     $E9
        cpx     $EEE5
        sbc     ($ED,x)
        sbc     $A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$F4
        sbc     $E5F0,y
        ldy     #$A0
        .byte   $E2
        cpx     $E3EF
        .byte   $EB
        .byte   $F3
        ldy     #$A0
        ldy     #$F3
        sbc     #$FA
        sbc     $A0
        ldy     #$A0
        ldy     #$E1
        sbc     $F8,x
        ldy     #$A0
        ldy     #$ED
        .byte   $EF
        cpx     $E9
        inc     $F9
        .byte   $DF
        cpx     $E1
        .byte   $F4
        sbc     $AF
        .byte   $F4
        sbc     #$ED
        sbc     $A0
        ldy     #$E1
        .byte   $E3
        .byte   $E3
        sbc     $F3
        .byte   $F3
        .byte   $8D
        brk
L9202:  jsr     LFD8E
L9205:  jsr     xread1dir
        bcs     $927A
        ldx     #$10
        lda     $EE
        bpl     $9217
        lda     $1A02,x
        cmp     #$0F
        beq     L921C
        jsr     L94E6
        bpl     L9205
L921C:  jsr     L9340
        lda     $EE
        bpl     L9272
        ldx     #$10
        lda     $1A02,x
        cmp     #$0F
        bne     L9272
        lda     $F6
        cmp     #$0F
        beq     L9266
        cmp     #$0D
        beq     L9266
        jsr     LFD8E
        lda     $ED
        asl     a
        jsr     L9611
        jsr     xmess
        ldy     #$A0
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
        ldy     #$D2
        cmp     $C1
        cpy     $E4A0
        sbc     #$F2
        sbc     $E3
        .byte   $F4
        .byte   $EF
        .byte   $F2
        sbc     $8000,y
        .byte   $0C
L9266:  inc     $ED
        jsr     xpush_level
        ldy     $E2
        lda     $E3
        jsr     xdir_setup2
L9272:  jsr     xcheck_wait
        bcc     L9202
        jmp     L9338

        jsr     xdir_finish
        lda     $ED
        beq     L9286
        dec     $ED
        jmp     L9205

L9286:  jsr     L9426
        jsr     xmess
        sbc     $F3,x
        sbc     $E4
        .byte   $DF
        .byte   $E2
        cpx     $E3EF
        .byte   $EB
        .byte   $F3
        tsx
        brk
        lda     L9680
        sta     $61
        lda     L9681
        sta     $62
        lda     #$00
        sta     $63
        ldy     #$05
        jsr     xprdec_pady
        jsr     xmess
        ldy     #$A8
        brk
        lda     L9680
        sta     $61
        lda     L9681
        sta     $62
        lda     #$00
        sta     $63
        lda     #$00
        ldx     L967E
        ldy     L967D
        jsr     xpercent
        sta     $61
        .byte   $64
        .byte   $62
        .byte   $64
        .byte   $63
        ldy     #$02
        jsr     xprdec_pady
        jsr     xmess
        lda     $A9
        ldy     #$A0
        ldy     #$E6
        .byte   $F2
        sbc     $E5
        .byte   $DF
        .byte   $E2
        cpx     $E3EF
        .byte   $EB
        .byte   $F3
        tsx
        brk
        sec
        lda     L967D
        sbc     L9680
        sta     $E6
        lda     L967E
        sbc     L9681
        sta     $E7
        lda     $E6
        sta     $61
        lda     $E7
        sta     $62
        lda     #$00
        sta     $63
        ldy     #$05
        jsr     xprdec_pady
        jsr     xmess
        ldy     #$A0
        ldy     #$F4
        .byte   $EF
        .byte   $F4
        sbc     ($EC,x)
        .byte   $DF
        .byte   $E2
        cpx     $E3EF
        .byte   $EB
        .byte   $F3
        tsx
        brk
        lda     L967D
        sta     $61
        lda     L967E
        sta     $62
        lda     #$00
        sta     $63
        ldy     #$05
        jsr     xprdec_pady
        jsr     LFD8E
        rts

L9338:  jsr     xdir_finish
        dec     $ED
        bpl     L9338
        rts

L9340:  lda     $ED
        asl     a
        jsr     L9611
        .byte   $B2
        .byte   $E2
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     $F6
        .byte   $B2
        .byte   $E2
        and     #$0F
        .byte   $92
        .byte   $E2
        tay
        ldx     #$10
        lda     $1A02,x
        cmp     #$1A
        beq     L9368
        cmp     #$19
        beq     L9368
        cmp     #$1B
        beq     L9368
        .byte   $80
        .byte   $2D
L9368:  ldx     #$1F
        lda     $1A02,x
        sta     $E8
        inx
        lda     $1A02,x
        sta     $E9
        tya
        tax
        ldy     #$01
L9379:  asl     $E9
        rol     $E8
        lda     ($E2),y
        ora     #$80
        bcc     L9386
        jsr     xdowncase
L9386:  sta     ($E2),y
        iny
        dex
        bne     L9379
        ldy     $E2
        lda     $E3
        jsr     L950D
        .byte   $80
        .byte   $07
        ldy     $E2
        lda     $E3
        jsr     xprint_path
        lda     $EF
        bpl     L93A3
        jmp     L9425

L93A3:  lda     #$11
        sec
        sbc     $1A02
        jsr     L9611
        ldx     #$10
        lda     $1A02,x
        jsr     xprint_ftype
        ldx     #$13
        lda     $1A02,x
        sta     $61
        inx
        lda     $1A02,x
        sta     $62
        .byte   $64
        .byte   $63
        ldy     #$06
        jsr     xprdec_pady
        lda     #$A0
        jsr     LFDED
        ldx     #$15
        lda     $1A02,x
        sta     $61
        inx
        lda     $1A02,x
        sta     $62
        inx
        lda     $1A02,x
        sta     $63
        jsr     xprdec_pad
        jsr     xmess
        ldy     #$A0
        ldy     $00
        ldx     #$20
        lda     $1A02,x
        jsr     L9591
        dex
        lda     $1A02,x
        jsr     L9591
        lda     #$02
        jsr     L9611
        ldx     #$21
        lda     $1A02,x
        tay
        inx
        lda     $1A02,x
        jsr     xpr_date_ay
        ldx     #$23
        lda     $1A02,x
        tay
        inx
        lda     $1A02,x
        jsr     L94C6
        lda     #$02
        jsr     L9611
        ldx     #$1E
        lda     $1A02,x
        jsr     xprint_access
L9425:  rts

L9426:  lda     $F5
        bmi     L9479
        jsr     xmess
        .byte   $8F
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8000
        .byte   $49
L9479:  jsr     xmess
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        lda     $ADAD
        brk
        jsr     LFD8E
        rts

L94C6:  bne     L94CC
        cpy     #$00
        beq     L94E1
L94CC:  .byte   $5A
        jsr     L95B2
        tya
        jsr     LFDDA
        lda     #$BA
        jsr     LFDED
        pla
        jsr     L95B2
        tya
        jmp     LFDDA

L94E1:  lda     #$05
        jmp     L9611

L94E6:  lda     #$FF
        sta     $F4
        bit     $F0
        bpl     L94F7
        lda     $1A02,x
        cmp     $F1
        beq     L94F7
        .byte   $64
        .byte   $F4
L94F7:  bit     $F2
        bpl     L950A
        ldx     #$1E
        lda     $1A02,x
        and     #$20
        asl     a
        asl     a
        cmp     $F3
        beq     L950A
        .byte   $64
        .byte   $F4
L950A:  lda     $F4
        rts

L950D:  sty     $E0
        sta     $E1
        txa
        pha
        ldy     #$00
        lda     ($E0),y
        beq     L9524
        tax
        iny
L951B:  lda     ($E0),y
        jsr     LFDED
        iny
        dex
        bne     L951B
L9524:  pla
        tax
        rts

L9527:  .byte   $DA
        ldx     $E0
        .byte   $DA
        ldx     $E1
        .byte   $DA
        sta     $E1
        sty     $E0
        .byte   $B2
        cpx     #$8D
        bcc     L94CC
        beq     L9570
        cmp     #$01
        beq     L9570
        ldy     #$01
        lda     ($E0),y
        ora     #$80
        cmp     #$AF
        bne     L9570
        ldx     #$01
        sta     L9580,x
L954C:  inx
        iny
        lda     ($E0),y
        ora     #$80
        cmp     #$AF
        beq     L955F
        sta     L9580,x
        cpy     L9590
        bne     L954C
        inx
L955F:  dex
        stx     L9580
        lda     #$95
        ldy     #$80
        .byte   $FA
        stx     $E1
        .byte   $FA
        stx     $E0
        .byte   $FA
        clc
        rts

L9570:  lda     #$95
        ldy     #$80
        .byte   $9C
        .byte   $80
        sta     $FA,x
        stx     $E1
        .byte   $FA
        stx     $E0
        .byte   $FA
        sec
        rts

L9580:  ldy     #$A4
        ldy     #$F5
        dec     $A0,x
        sbc     $CD
        ldy     #$A0
        ldy     #$A0
        ldy     #$C4
        ldy     #$A0
L9590:  .byte   $80
L9591:  pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        jsr     L95A1
        pla
        and     #$0F
        jsr     L95A1
        clc
        rts

L95A1:  cmp     #$0A
        bcc     L95AA
        clc
        adc     #$D7
        bne     L95AD
L95AA:  clc
        adc     #$B0
L95AD:  ora     #$80
        jmp     LFDED

L95B2:  ldy     #$FF
        sec
L95B5:  iny
L95B6:  sbc     #$64
        bcs     L95B5
        adc     #$64
        tax
        tya
        pha
        txa
        ldy     #$FF
        sec
L95C3:  iny
        sbc     #$0A
        bcs     L95C3
        adc     #$0A
        sta     L95D8
        tya
        asl     a
        asl     a
        asl     a
        asl     a
        ora     L95D8
        tay
        pla
        rts

L95D8:  .byte   $A0
L95D9:  lda     $FBB3
        cmp     #$38
        beq     L95EE
        cmp     #$EA
        beq     L95EE
        lda     $FBC0
        cmp     #$EA
        beq     L95EE
        clc
        bne     L9610
L95EE:  jsr     xbell
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
        bcs     L95B6
        ldy     #$F2
        sbc     $F1
        sbc     $E9,x
        .byte   $F2
        sbc     $E4
        sta     $3800
L9610:  rts

L9611:  beq     L9617
        tax
        jsr     LF94A
L9617:  rts

        ldy     #$A0
        ldx     $A0AA
        cpy     $A0AA
        cpy     $A0A0
        ldx     $B0A0
L9626:  .byte   $EF
        .byte   $A0
L9628:  ldy     #$A0
        sta     $A0D3
        lda     #$CE
        ldy     #$89
        cpy     $CE
        .byte   $80
        .byte   $D2
        .byte   $AF
        sty     $A0AF
        ldy     #$C5
        ldy     #$CC
        cmp     $A0,x
        .byte   $C2
        .byte   $C3
        ldy     #$C2
        cmp     #$A0
        ldy     #$A4
        ldy     #$A0
        .byte   $87
        ldy     #$A0
        .byte   $80
        ldy     #$A0
        ldy     #$A0
        sbc     $A0,x
        ldy     #$A0
        ldy     #$A0
        .byte   $EF
        ldy     #$A0
        dec     $A0,x
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        tax
        tax
        ldy     #$AA
        .byte   $B3
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        sbc     $0A
L9679:  .byte   $A0
L967A:  ldy     #$B0
L967C:  .byte   $8D
L967D:  .byte   $92
L967E:  .byte   $A0
L967F:  .byte   $A0
L9680:  .byte   $A0
L9681:  cpy     $A0A0
        bcs     L9626
        ldy     #$E4
        .byte   $AF
        ldy     #$02
L968B:  ldy     #$28
        stx     $01,y
L968F:  sec
L9690:  .byte   $96
