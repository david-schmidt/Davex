	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_AC00"

L03AC	= $03AC
LBF00	= $BF00
LFD8E	= $FD8E

LAC00:  rts

        inc     $11EE
        .byte   $12
        rts

        clc
        ldy     LAC00
        jmp     L03AC

        brk
        brk
        brk
        brk
        .byte   $04
        inc     $00
        .byte   $F2
        brk
        brk
        brk
        .byte   $33
        dec     $E9,x
        sbc     $F7
        ldy     #$E1
        ldy     #$E4
        .byte   $EF
        sbc     $E2,x
        cpx     $A0E5
        inx
        sbc     #$AD
        .byte   $F2
        sbc     $F3
        ldy     #$F0
        sbc     #$E3
        .byte   $F4
        sbc     $F2,x
        sbc     $AE
        ldy     #$A0
        .byte   $D7
        .byte   $F2
        sbc     #$F4
        .byte   $F4
        sbc     $EE
        ldy     #$E2
        sbc     $CAA0,y
        sbc     $E6
        inc     $A0
        cpy     $E9
        inc     $85E7
        sbc     ($84,x)
        cpx     #$A2
        iny
        lda     #$20
        jsr     xmmgr
        bcc     LAC5C
        jmp     LAE87

LAC5C:  sta     $E6
        ldy     #$00
        lda     ($E0),y
        bne     LAC67
        jmp     LAEAD

LAC67:  lda     #$E6
        jsr     xgetparm_ch
        bcc     LAC85
        jsr     LBF00
        cmp     $49
        ldx     $0790
        cmp     #$28
        beq     LAC85
        jmp     LAE84

        lda     LAE4D
        beq     LAC85
        jmp     LAED6

LAC85:  lda     $E0
        sta     LAE5E
        lda     $E1
        sta     LAE5F
        jsr     LBF00
        cpy     $5D
        ldx     $0390
        jmp     LAE84

        lda     LAE61
        cmp     #$06
        beq     LACA5
        cmp     #$08
        bne     LACB1
LACA5:  lda     LAE62
        bne     LACB1
        lda     LAE63
        cmp     #$20
        beq     LACB4
LACB1:  jmp     LAF00

LACB4:  lda     $E0
        sta     LAE70
        lda     $E1
        sta     LAE71
        lda     #$00
        sta     LAE72
        lda     #$08
        sta     LAE73
        jsr     LBF00
        iny
        .byte   $6F
        ldx     $0390
        jmp     LAE84

        lda     #$F2
        jsr     xgetparm_ch
        bcs     LACF8
        lda     LAE74
        sta     LAE7E
        lda     #$00
        sta     LAE7F
        sta     LAE81
        lda     #$20
        sta     LAE80
        jsr     LBF00
        dec     LAE7D
        bcc     LACF8
        jmp     LAE84

LACF8:  lda     LAE74
        sta     LAE76
        lda     #$00
        sta     LAE77
        lda     $E6
        sta     LAE78
        lda     #$00
        sta     LAE79
        lda     #$20
        sta     LAE7A
        jsr     LBF00
        dex
        adc     $AE,x
        bcc     LAD1D
        jmp     LAE84

LAD1D:  lda     $E6
        sta     $E5
        lda     #$00
        sta     $E4
        sta     $E2
        lda     #$20
        sta     $E3
        lda     $C018
        sta     $E7
        sta     $C000
        sta     $C002
        sta     $C005
        ldy     #$00
        ldx     #$20
LAD3D:  lda     ($E4),y
        sta     ($E2),y
        lda     #$00
        sta     ($E4),y
        iny
        bne     LAD3D
        inc     $E5
        inc     $E3
        dex
        bne     LAD3D
        sta     $C004
        lda     $E7
        bpl     LAD59
        sta     $C001
LAD59:  lda     #$F2
        jsr     xgetparm_ch
        bcs     LAD70
        lda     #$00
        sta     LAE80
        jsr     LBF00
        dec     LAE7D
        bcc     LAD70
        jmp     LAE84

LAD70:  jsr     LBF00
        dex
        adc     $AE,x
        bcc     LAD7B
        jmp     LAE84

LAD7B:  lda     LAE74
        sta     LAE83
        jsr     LBF00
        cpy     LAE82
        inc     $03F4
        lda     #$00
        sta     $E4
        sta     $E2
        lda     $E6
        sta     $E5
        lda     #$20
        sta     $E3
        ldx     #$20
        ldy     #$00
LAD9C:  lda     ($E2),y
        pha
        lda     ($E4),y
        sta     ($E2),y
        pla
        sta     ($E4),y
        iny
        bne     LAD9C
        inc     $E5
        inc     $E3
        dex
        bne     LAD9C
        lda     $C07E
        sta     $E8
        sta     $C07E
        lda     $C07F
        sta     $E9
        sta     $C05E
        lda     $C01D
        sta     $EA
        lda     $C057
        lda     $C01B
        sta     $EB
        lda     $C052
        lda     $C01C
        sta     $EC
        lda     $C054
        lda     $C01A
        sta     $ED
        lda     $C050
LADE0:  lda     $C000
        bpl     LADE0
        lda     $ED
        bpl     LADEC
        lda     $C051
LADEC:  lda     $EC
        bpl     LADF3
        lda     $C055
LADF3:  lda     $EB
        bpl     LADFA
        lda     $C053
LADFA:  lda     $EA
        bmi     LAE01
        lda     $C056
LAE01:  lda     $E9
        bmi     LAE08
        lda     $C05F
LAE08:  lda     $E8
        bpl     LAE0F
        lda     $C07F
LAE0F:  lda     #$00
        sta     $E4
        sta     $E2
        lda     $E6
        sta     $E5
        lda     #$20
        sta     $E3
        ldx     #$20
        ldy     #$00
LAE21:  lda     ($E4),y
        sta     ($E2),y
        iny
        bne     LAE21
        inc     $E5
        inc     $E3
        dex
        bne     LAE21
        dec     $03F4
        ldx     #$CC
        jsr     xmmgr
        lda     $C000
        cmp     #$A0
        beq     LAE45
        cmp     #$9B
        beq     LAE45
        jsr     xcheck_wait
LAE45:  lda     $C010
        rts

        .byte   $02
        bcs     LAE99
        .byte   $AE
LAE4D:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        asl     a
LAE5E:  brk
LAE5F:  brk
        brk
LAE61:  brk
LAE62:  brk
LAE63:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $03
LAE70:  brk
LAE71:  brk
LAE72:  brk
LAE73:  brk
LAE74:  brk
        .byte   $04
LAE76:  brk
LAE77:  brk
LAE78:  brk
LAE79:  brk
LAE7A:  brk
        brk
        brk
LAE7D:  .byte   $02
LAE7E:  brk
LAE7F:  brk
LAE80:  brk
LAE81:  brk
LAE82:  .byte   $01
LAE83:  brk
LAE84:  jmp     xProDOS_err

LAE87:  jsr     LFD8E
        jsr     xmess
        cmp     $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
        dec     $A0EF
        .byte   $ED
LAE99:  sbc     $ED
        .byte   $EF
        .byte   $F2
        sbc     $E1A0,y
        inc     $E1,x
        sbc     #$EC
        sbc     ($E2,x)
        cpx     $8DE5
        brk
        jmp     xerr

LAEAD:  jsr     LFD8E
LAEB0:  jsr     xmess
        cmp     $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
        dec     $E9
        cpx     $EEE5
        sbc     ($ED,x)
        sbc     $A0
        inc     $F4EF
        ldy     #$F3
        beq     LAEB0
        .byte   $E3
        sbc     #$E6
        sbc     #$E5
        cpx     $8D
        brk
        jmp     xerr

LAED6:  jsr     LFD8E
        jsr     xmess
        cmp     $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
        cmp     ($F5,x)
        sed
        sbc     #$EC
        sbc     #$E1
        .byte   $F2
        sbc     $EDA0,y
        sbc     $ED
        .byte   $EF
        .byte   $F2
        sbc     $E9A0,y
        inc     $F5A0
        .byte   $F3
        sbc     $8D
        brk
        jmp     xerr

LAF00:  jsr     LFD8E
        jsr     xmess
        cmp     $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
        dec     $F4EF
        ldy     #$E1
        ldy     #$F0
        sbc     #$E3
        .byte   $F4
        sbc     $F2,x
        sbc     $A0
        inc     $E9
        cpx     $8DE5
        brk
        jmp     xerr

