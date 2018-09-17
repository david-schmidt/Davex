	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_A800"
.org $a800

L0208	= $0208
L2824	= $2824
LA7C9	= $A7C9
LBF00	= $BF00
LE185	= $E185
LFD8E	= $FD8E
LFDED	= $FDED
LFE95	= $FE95

	rts

        inc     $12EE
        ora     ($00),y
        clc
        tay
        brk
        tay
        .byte   $54
        tay
        brk
        brk
        brk
        brk
        brk
        .byte   $04
        inc     $E900
        ora     $00
        brk
        .byte   $3B
        cpx     $F5
        sbc     $E8F0
        .byte   $E7
        .byte   $F2
        ldy     #$AD
        lda     $C4A0
        sbc     $ED,x
        beq     LA7C9
        sbc     ($A0,x)
        inx
        sbc     #$F2
        sbc     $F3
        ldy     #$F0
        sbc     #$E3
        .byte   $F4
        sbc     $F2,x
        sbc     $A0
        .byte   $F4
        .byte   $EF
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
        sty     LAA9C
        sta     LAA9D
        sty     LAA8A
        .byte   $8D
        .byte   $8B
LA85F:  tax
        jsr     LBF00
        cpy     $89
        tax
        bcc     LA86B
        jmp     xProDOS_err

LA86B:  lda     LAA8D
        cmp     #$06
        beq     LA878
        cmp     #$08
        beq     LA878
        .byte   $80
        .byte   $07
LA878:  lda     LAA91
        cmp     #$11
        beq     LA8A5
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
        ldy     #$E8
        sbc     #$F2
        sbc     $F3
        ldy     #$F0
        sbc     #$E3
        .byte   $F4
        sbc     $F2,x
        sbc     $8D
        brk
        jmp     xerr

LA8A5:  .byte   $64
        sbc     #$C6
        sbc     #$A9
        inc     a:$20
        bcs     LA85F
        .byte   $02
        .byte   $64
        sbc     #$A9
        ror     a
        sta     $E6
        lda     #$AA
        sta     $E7
        lda     #$E9
        jsr     xgetparm_ch
        bcs     LA8C5
        sty     $E6
        sta     $E7
LA8C5:  clc
        ldx     #$CC
        jsr     xmmgr
        ldx     #$C8
        lda     #$20
        jsr     xmmgr
        bcc     LA8F4
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

LA8F4:  sta     $E8
        sta     LAAA4
        .byte   $9C
        .byte   $A3
        tax
        jsr     LBF00
        iny
        .byte   $9B
        tax
        bcc     LA907
        jmp     xProDOS_err

LA907:  lda     LAAA0
        sta     LAAA2
        sta     LAAAA
        jsr     LBF00
        dex
        lda     ($AA,x)
        bcc     LA91B
        jmp     xProDOS_err

LA91B:  jsr     LBF00
        cpy     LAAA9
        bcc     LA926
        jmp     xProDOS_err

LA926:  jsr     LAA18
        lda     $C052
        lda     $C050
        lda     $C05F
        lda     $C054
        lda     $C057
        lda     $36
        pha
        lda     $37
        pha
        lda     $B300
        jsr     LFE95
        ldy     $E6
        lda     $E7
        jsr     LAA6D
        jsr     LAAAB
        .byte   $9B
        .byte   $B3
        clc
        sta     $A000
        brk
LA955:  sty     $EC
        jsr     LAAAB
        ldy     #$A0
        ldy     #$A0
        ldy     #$9B
        .byte   $DA
        bcc     LA969
        brk
        lda     #$00
        sta     $EB
LA968:  .byte   $A9
LA969:  brk
        sta     $ED
LA96C:  lda     #$00
        sta     $EF
        sta     $EE
LA972:  lda     $EC
        asl     a
        asl     a
        clc
        adc     $EE
        tax
        lda     LAAD0,x
        sta     $E0
        lda     LAB90,x
        sta     $E1
        ldy     $EB
        lda     ($E0),y
        eor     $E9
        jsr     LAA04
        ldx     $ED
        lda     LAA62,x
        beq     LA99E
        ldx     $EE
        lda     LAA5E,x
        clc
        adc     $EF
        sta     $EF
LA99E:  inc     $EE
        lda     $EE
        cmp     #$04
        bne     LA972
        jsr     LA9EA
        inc     $ED
        lda     $ED
        cmp     #$07
        bne     LA96C
        inc     $EB
        lda     $EB
        cmp     #$28
        bne     LA968
        jsr     LFD8E
        ldx     #$04
        lda     $EC
        asl     a
        asl     a
        jsr     LAA3E
        ldy     $EC
        iny
        cpy     #$30
        beq     LA9CF
        jmp     LA955

LA9CF:  jsr     LAAAB
        .byte   $9B
        .byte   $B2
        .byte   $0C
        brk
        pla
        sta     $37
        pla
        sta     $36
        ldx     #$C0
        lda     #$00
        jsr     LAA3E
        lda     $C051
        jsr     LAA18
        rts

LA9EA:  lda     $EF
        jsr     LFDED
        lsr     a
        jsr     LFDED
        asl     a
        jsr     LFDED
        lsr     a
        jsr     LFDED
        asl     a
        jsr     LFDED
        lsr     a
        jsr     LFDED
        rts

LAA04:  ldy     #$08
LAA06:  dey
        asl     a
        pha
        lda     #$01
        bcs     LAA0F
        lda     #$00
LAA0F:  sta     LAA62,y
        pla
        cpy     #$00
        bne     LAA06
        rts

LAA18:  .byte   $64
        cpx     #$A9
        jsr     LE185
        .byte   $64
        cpx     $A5
        inx
        sta     $E5
        ldy     #$00
LAA26:  lda     ($E0),y
        pha
        lda     ($E4),y
        sta     ($E0),y
        pla
        sta     ($E4),y
        iny
        bne     LAA26
        inc     $E5
        inc     $E1
        lda     $E1
        cmp     #$40
        bne     LAA26
        rts

LAA3E:  stx     $EA
        tax
LAA41:  ldy     #$00
        lda     LAAD0,x
        sta     $E0
        lda     LAB90,x
        sta     $E1
LAA4D:  lda     ($E0),y
        eor     #$FF
        sta     ($E0),y
        iny
        cpy     #$28
        bne     LAA4D
        inx
        dec     $EA
        bne     LAA41
        rts

LAA5E:  .byte   $80
        jsr     L0208
LAA62:  ldy     #$E1
        sta     ($A0,x)
        ldy     #$80
        ldy     #$A0
        .byte   $02
        .byte   $89
        iny
LAA6D:  sty     $E0
        sta     $E1
        txa
        pha
        ldy     #$00
        lda     ($E0),y
        beq     LAA86
        tax
        iny
LAA7B:  lda     ($E0),y
        ora     #$80
        jsr     LFDED
        iny
        dex
        bne     LAA7B
LAA86:  pla
        tax
        rts

        asl     a
LAA8A:  .byte   $B9
LAA8B:  ldy     #$A0
LAA8D:  ldy     #$A0
        ldy     #$A0
LAA91:  ldy     #$DF
        cpx     $A0A0
        ldy     #$AA
        ldy     #$A0
        ldy     #$03
LAA9C:  .byte   $C1
LAA9D:  tax
        brk
        php
LAAA0:  ldy     #$04
LAAA2:  tax
        .byte   $A0
LAAA4:  cpx     $F8
        .byte   $1F
        ldy     #$A0
LAAA9:  .byte   $01
LAAAA:  .byte   $FF
LAAAB:  pla
        sta     $E2
        pla
        sta     $E3
        ldy     #$01
LAAB3:  lda     ($E2),y
        beq     LAAC1
        jsr     LFDED
        iny
        bne     LAAB3
        inc     $E3
        bne     LAAB3
LAAC1:  tya
        clc
        adc     $E2
        sta     $E2
        lda     #$00
        adc     $E3
        pha
        lda     $E2
        pha
        rts

LAAD0:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
        tay
        tay
        tay
        tay
        tay
        tay
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
LAB2A:  tay
        tay
LAB2C:  tay
        tay
LAB2E:  tay
        tay
LAB30:  plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
LAB3A:  tay
        tay
LAB3C:  tay
        tay
LAB3E:  tay
        tay
LAB40:  plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
LAB4A:  tay
        tay
LAB4C:  tay
        tay
LAB4E:  tay
        tay
LAB50:  bvc     LABA2
        bvc     LABA4
        bvc     LABA6
        bvc     LABA8
        bne     LAB2A
LAB5A:  bne     LAB2C
LAB5C:  bne     LAB2E
LAB5E:  bne     LAB30
LAB60:  bvc     LABB2
        bvc     LABB4
        bvc     LABB6
        bvc     LABB8
        bne     LAB3A
        bne     LAB3C
        bne     LAB3E
        bne     LAB40
        bvc     LABC2
        bvc     LABC4
        bvc     LABC6
        bvc     LABC8
        bne     LAB4A
        bne     LAB4C
        bne     LAB4E
        bne     LAB50
        bvc     LABD2
        bvc     LABD4
        bvc     LABD6
        bvc     LABD8
        bne     LAB5A
        bne     LAB5C
        bne     LAB5E
        bne     LAB60
LAB90:  jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        and     ($25,x)
LABA2:  and     #$2D
LABA4:  and     ($35),y
LABA6:  .byte   $39
        .byte   $3D
LABA8:  and     ($25,x)
        and     #$2D
        and     ($35),y
        and     $223D,y
        .byte   $26
LABB2:  rol     a
        .byte   $2E
LABB4:  .byte   $32
        .byte   $36
LABB6:  .byte   $3A
        .byte   $3E
LABB8:  .byte   $22
        rol     $2A
        rol     $3632
        .byte   $3A
        rol     $2723,x
LABC2:  .byte   $2B
        .byte   $2F
LABC4:  .byte   $33
        .byte   $37
LABC6:  .byte   $3B
        .byte   $3F
LABC8:  .byte   $23
        .byte   $27
        .byte   $2B
        .byte   $2F
        .byte   $33
        .byte   $37
        .byte   $3B
        .byte   $3F
        .byte   $20
        .byte   $24
LABD2:  plp
        .byte   $2C
LABD4:  bmi     LAC0A
LABD6:  sec
        .byte   $3C
LABD8:  jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        and     ($25,x)
        and     #$2D
        and     ($35),y
        and     $213D,y
        and     $29
        and     $3531
        and     $223D,y
        rol     $2A
        rol     $3632
        .byte   $3A
        rol     $2622,x
        rol     a
        rol     $3632
        .byte   $3A
        rol     $2723,x
        .byte   $2B
        .byte   $2F
        .byte   $33
        .byte   $37
        .byte   $3B
        .byte   $3F
        .byte   $23
        .byte   $27
LAC0A:  .byte   $2B
        .byte   $2F
        .byte   $33
        .byte   $37
        .byte   $3B
        .byte   $3F
        jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        and     ($25,x)
        and     #$2D
        and     ($35),y
        and     $213D,y
        and     $29
        and     $3531
        and     $223D,y
        rol     $2A
        rol     $3632
        .byte   $3A
        rol     $2622,x
        rol     a
        rol     $3632
        .byte   $3A
        rol     $2723,x
        .byte   $2B
        .byte   $2F
        .byte   $33
        .byte   $37
        .byte   $3B
        .byte   $3F
        .byte   $23
        .byte   $27
        .byte   $2B
        .byte   $2F
        .byte   $33
        .byte   $37
        .byte   $3B
        .byte   $3F
