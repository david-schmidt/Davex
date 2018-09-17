	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_9000"

L0020           := $0020
LBF00           := $BF00
LF94A           := $F94A
LFD8E           := $FD8E
LFDED           := $FDED
        rts

        inc     $10EE
        .byte   $12
        brk
        .byte   $1A
        bcc     L9009
L9009:  bcc     L9065
        bcc     L9010
        brk
        brk
        brk
L9010:  brk
        .byte   $04
        inc     $E600
        php
        .byte   $E2
        .byte   $07
        brk
        brk
        .byte   $3F
        cpx     $A0F7
        lda     $A0AD
        cpy     $F3E9
        .byte   $F4
        ldy     #$C4
        sbc     #$F2
        sbc     $E3
        .byte   $F4
        .byte   $EF
        .byte   $F2
        .byte   $F9
        .byte   $A0
L9030:  tay
        .byte   $D7
        sbc     #$E4
        sbc     $A9
        ldy     #$BA
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
        jsr     L946F
        bcc     L9065
        rts

L9065:  lda     #$00
        jsr     xredirect
        sta     $F3
        .byte   $64
        .byte   $F4
        lda     #$EE
        jsr     xgetparm_ch
        bcs     L9077
        dec     $F4
L9077:  .byte   $64
        inc     $E6A9
        jsr     xgetparm_ch
        bcs     L9084
        sta     $EF
        dec     $EE
L9084:  .byte   $64
        beq     L9030
        .byte   $E2
        jsr     xgetparm_ch
        bcs     L9093
        dec     $F0
        and     #$80
        sta     $F1
L9093:  .byte   $B2
        cpx     #$D0
        jsr     L0020
        .byte   $BF
        .byte   $C7
        bit     $95
        bcc     L90A2
        jmp     xProDOS_err

L90A2:  ldy     L9525
        lda     L9526
        sty     $E0
        sta     $E1
        jsr     L9405
        sty     L950F
        sta     L9510
        .byte   $80
        ror     $E0A5,x
        sta     L950F
        lda     $E1
        sta     L9510
        jsr     LBF00
        cpy     $0E
        sta     $90,x
        .byte   $03
        jmp     xProDOS_err

        lda     L9512
        cmp     #$0F
        bne     L90DE
        lda     L9515
        cmp     #$0F
        beq     L90E3
        cmp     #$0D
        beq     L90E3
L90DE:  lda     #$97
        jmp     xProDOS_err

L90E3:  ldy     $E0
        lda     $E1
        jsr     L9405
        bcs     L90F4
        sty     L950F
        sta     L9510
        .byte   $80
        .byte   $41
L90F4:  lda     $BF30
        sta     L9521
        jsr     LBF00
        cmp     L0020
        sta     $90,x
        .byte   $03
        jmp     xProDOS_err

        lda     #$AE
        sta     $E4
        lda     #$94
        sta     $E5
        ldx     #$00
        ldy     #$00
        lda     L94BE,x
        and     #$0F
        .byte   $1A
        sta     $EC
        .byte   $92
        cpx     $C8
        lda     #$2F
        sta     ($E4),y
L9120:  inx
        iny
        lda     L94BE,x
        sta     ($E4),y
        cpy     $EC
        bne     L9120
        lda     $E4
        sta     L950F
        lda     $E5
        sta     L9510
        jsr     LBF00
        cpy     $0E
        sta     $90,x
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
        bne     L9157
        dey
        tya
        .byte   $92
        .byte   $E0
L9157:  jsr     xpush_level
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
        sbc     $F3A5,x
        bmi     L9182
        jsr     xmess
        .byte   $8F
        .byte   $9B
        cld
        cmp     $8E98,y
        ldy     #$00
L9182:  ldy     $E0
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
        jsr     xplural
        jsr     xmess
        lda     #$8D
        brk
        jsr     L934B
        .byte   $64
        inc     $64,x
        .byte   $F7
L91B6:  jsr     xread1dir
        bcs     L91CD
        ldx     #$10
        lda     $1A02,x
        jsr     L9324
        bpl     L91B6
        jsr     L9296
        bcc     L91B6
        jmp     L928E

L91CD:  jsr     xdir_finish
        lda     $ED
        beq     L91D9
        dec     $ED
        jmp     L91B6

L91D9:  jsr     LFD8E
        jsr     L934B
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
        lda     L9516
        sta     $61
        lda     L9517
        sta     $62
        lda     #$00
        sta     $63
        ldy     #$05
        jsr     xprdec_pady
        jsr     xmess
        ldy     #$A8
        brk
        lda     L9516
        sta     $61
        lda     L9517
        sta     $62
        lda     #$00
        sta     $63
        lda     #$00
        ldx     L9514
        ldy     L9513
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
        lda     L9513
        sbc     L9516
        sta     $E6
        lda     L9514
        sbc     L9517
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
        lda     L9513
        sta     $61
        lda     L9514
        sta     $62
        lda     #$00
        sta     $63
        ldy     #$05
        jsr     xprdec_pady
        jsr     LFD8E
        rts

L928E:  jsr     xdir_finish
        dec     $ED
        bpl     L928E
        rts

L9296:  lda     $F7
        cmp     #$04
        bne     L92A9
        jsr     LFD8E
        .byte   $64
        inc     $64,x
        .byte   $F7
        jsr     xcheck_wait
        bcc     L92AE
        rts

L92A9:  lda     $F6
        jsr     L94A7
L92AE:  .byte   $B2
        .byte   $E2
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     $F5
        .byte   $B2
        .byte   $E2
        and     #$0F
        .byte   $92
        .byte   $E2
        tay
        ldx     #$10
        lda     $1A02,x
        cmp     #$1A
        beq     L92D0
        cmp     #$19
        beq     L92D0
        cmp     #$1B
        beq     L92D0
        .byte   $80
        .byte   $2D
L92D0:  ldx     #$1F
        lda     $1A02,x
        sta     $E8
        inx
        lda     $1A02,x
        sta     $E9
        tya
        tax
        ldy     #$01
L92E1:  asl     $E9
        rol     $E8
        lda     ($E2),y
        ora     #$80
        bcc     L92EE
        jsr     xdowncase
L92EE:  sta     ($E2),y
        iny
        dex
        bne     L92E1
        ldy     $E2
        lda     $E3
        jsr     L93EB
        .byte   $80
        .byte   $07
        ldy     $E2
        lda     $E3
        jsr     xprint_path
        lda     #$12
        sec
        sbc     $1A02
        sta     $F6
        bit     $F4
        bmi     L9320
        ldx     #$10
        lda     $1A02,x
        cmp     #$0F
        bne     L9320
        lda     #$AF
        jsr     LFDED
        dec     $F6
L9320:  inc     $F7
        clc
        rts

L9324:  lda     #$80
        sta     $F2
        bit     $EE
        bpl     L9335
        lda     $1A02,x
        cmp     $EF
        beq     L9335
        .byte   $64
        .byte   $F2
L9335:  bit     $F0
        bpl     L9348
        ldx     #$1E
        lda     $1A02,x
        and     #$20
        asl     a
        asl     a
        cmp     $F1
        beq     L9348
        .byte   $64
        .byte   $F2
L9348:  lda     $F2
        rts

L934B:  lda     $F3
        bmi     L939E
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
L939E:  jsr     xmess
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

L93EB:  sty     $E0
        sta     $E1
        txa
        pha
        ldy     #$00
        lda     ($E0),y
        beq     L9402
        tax
        iny
L93F9:  lda     ($E0),y
        jsr     LFDED
        iny
        dex
        bne     L93F9
L9402:  pla
        tax
        rts

L9405:  .byte   $DA
        ldx     $E0
        .byte   $DA
        ldx     $E1
        .byte   $DA
        sta     $E1
        sty     $E0
        .byte   $B2
        cpx     #$8D
        ror     $F094
        .byte   $37
        cmp     #$01
        beq     L944E
        ldy     #$01
        lda     ($E0),y
        ora     #$80
        cmp     #$AF
        bne     L944E
        ldx     #$01
        sta     L945E,x
L942A:  inx
        iny
        lda     ($E0),y
        ora     #$80
        cmp     #$AF
        beq     L943D
        sta     L945E,x
        cpy     L946E
        bne     L942A
        inx
L943D:  dex
        stx     L945E
        lda     #$94
        ldy     #$5E
        .byte   $FA
        stx     $E1
        .byte   $FA
        stx     $E0
        .byte   $FA
L944C:  clc
        rts

L944E:  lda     #$94
        ldy     #$5E
        .byte   $9C
        lsr     $FA94,x
        stx     $E1
        .byte   $FA
        stx     $E0
        .byte   $FA
        sec
        rts

L945E:  ldy     #$A0
        sta     $A0A0
        sta     ($A0,x)
        tax
        .byte   $BF
        ldy     #$AA
        .byte   $80
        ldy     #$A0
        .byte   $F3
        .byte   $A0
L946E:  .byte   $A0
L946F:  lda     $FBB3
        cmp     #$38
        beq     L9484
        cmp     #$EA
        beq     L9484
        lda     $FBC0
        cmp     #$EA
        beq     L9484
        clc
        bne     L94A6
L9484:  jsr     xbell
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
        .byte   $B5
L9497:  .byte   $C3
        bcs     L944C
        ldy     #$F2
        sbc     $F1
        sbc     $E9,x
        .byte   $F2
        sbc     $E4
        sta     $3800
L94A6:  rts

L94A7:  beq     L94AD
        tax
        jsr     LF94A
L94AD:  rts

        sbc     $A0A0
        .byte   $80
        ldy     #$A0
        lda     $A0A0,y
        ldy     #$A0
        ldy     #$A0
        ldy     #$BB
        .byte   $A0
L94BE:  sbc     $A0
        ldy     #$A0
        .byte   $F4
        ldy     #$A0
        ldy     #$A0
        cpy     $A0
        ldy     #$AF
        ldy     #$A0
        iny
        lda     $A0A0,y
        ldy     #$A0
        ldy     #$B4
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $B7
        ldy     #$AA
        ldy     #$A0
        tax
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $BB
        ldy     $A0,x
        ldy     #$A0
        ldy     #$A0
        .byte   $B2
        ldy     #$AE
        bcs     L9497
        sbc     #$B0
        ldy     #$EB
        sta     $E4A0,y
        sbc     ($A0,x)
        ldy     #$A0
        ldy     #$A0
        ldy     #$E5
        cpy     $E3A0
        ldy     #$A0
        .byte   $BB
        ldy     #$A0
        asl     a
L950F:  .byte   $F0
L9510:  ldy     #$D3
L9512:  tax
L9513:  .byte   $A0
L9514:  .byte   $A0
L9515:  .byte   $A0
L9516:  .byte   $D3
L9517:  ldy     #$A0
        .byte   $F2
        tax
        ldy     #$80
        ldy     #$A0
        ldy     #$02
L9521:  ldy     #$BE
        sty     $01,x
L9525:  .byte   $CE
L9526:  .byte   $94
