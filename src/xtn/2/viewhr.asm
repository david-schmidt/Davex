	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_AE00"

LFD8E	= $fd8e
LBF00	= $bf00

LAE00:  rts

        inc     $11EE
        .byte   $12
        brk
        .byte   $14
        ldx     LAE00
        eor     ($AE,x)
        .byte   $03
        brk
        brk
        brk
        brk
        .byte   $04
        brk
        brk
        bit     $E9D6
        sbc     $F7
        ldy     #$E1
        ldy     #$E8
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
        bcc     LAE51
        jmp     LAF87

LAE51:  sta     $E4
        ldy     #$00
        lda     ($E0),y
        bne     LAE5C
        jmp     LAFAE

LAE5C:  lda     $E0
        sta     LAF63
        lda     $E1
        sta     LAF64
        jsr     LBF00
        cpy     $62
        .byte   $AF
        bcc     LAE71
        jmp     LAF84

LAE71:  lda     LAF66
        cmp     #$06
        beq     LAE7C
        cmp     #$08
        bne     LAE8C
LAE7C:  lda     LAF67
        bne     LAE8C
        lda     LAF68
        cmp     #$20
        beq     LAE8F
        cmp     #$40
        beq     LAE8F
LAE8C:  jmp     LAFD7

LAE8F:  lda     $E0
        sta     LAF75
        lda     $E1
        sta     LAF76
        lda     #$00
        sta     LAF77
        lda     #$08
        sta     LAF78
        jsr     LBF00
        iny
        .byte   $74
        .byte   $AF
        bcc     LAEAE
        jmp     LAF84

LAEAE:  lda     LAF79
        sta     LAF7B
        lda     #$00
        sta     LAF7C
        lda     $E4
        sta     LAF7D
        lda     #$00
        sta     LAF7E
        lda     #$20
        sta     LAF7F
        jsr     LBF00
        dex
        .byte   $7A
        .byte   $AF
        bcc     LAED3
        jmp     LAF84

LAED3:  lda     LAF79
        sta     LAF83
        jsr     LBF00
        cpy     LAF82
        inc     $03F4
        lda     #$00
        sta     $E0
        sta     $E2
        lda     $E4
        sta     $E1
        lda     #$20
        sta     $E3
        ldx     #$20
        ldy     #$00
LAEF4:  lda     ($E2),y
        pha
        lda     ($E0),y
        sta     ($E2),y
        pla
        sta     ($E0),y
        iny
        bne     LAEF4
        inc     $E1
        inc     $E3
        dex
        bne     LAEF4
        sta     $C07E
        sta     $C05F
        sta     $C07F
        lda     $C057
        lda     $C054
        lda     $C052
        lda     $C050
LAF1D:  lda     $C000
        bpl     LAF1D
        lda     $C051
        lda     $C056
        lda     #$00
        sta     $E0
        sta     $E2
        lda     $E4
        sta     $E1
        lda     #$20
        sta     $E3
        ldx     #$20
        ldy     #$00
LAF3A:  lda     ($E0),y
        sta     ($E2),y
        iny
        bne     LAF3A
        inc     $E1
        inc     $E3
        dex
        bne     LAF3A
        dec     $03F4
        ldx     #$CC
        jsr     xmmgr
        lda     $C000
        cmp     #$A0
        beq     LAF5E
        cmp     #$9B
        beq     LAF5E
        jsr     xcheck_wait
LAF5E:  lda     $C010
        rts

        asl     a
LAF63:  brk
LAF64:  brk
        brk
LAF66:  brk
LAF67:  brk
LAF68:  brk
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
LAF75:  brk
LAF76:  brk
LAF77:  brk
LAF78:  brk
LAF79:  brk
        .byte   $04
LAF7B:  brk
LAF7C:  brk
LAF7D:  brk
LAF7E:  brk
LAF7F:  brk
        brk
        brk
LAF82:  .byte   $01
LAF83:  brk
LAF84:  jmp     xProDOS_err

LAF87:  jsr     LFD8E
        jsr     xmess
        cmp     $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
        cmp     $EDE5
        .byte   $EF
        .byte   $F2
        sbc     $EEA0,y
        .byte   $EF
        .byte   $F4
        ldy     #$E1
        inc     $E1,x
        sbc     #$EC
        sbc     ($E2,x)
        cpx     $8DE5
        brk
        jmp     xerr

LAFAE:  jsr     LFD8E
LAFB1:  jsr     xmess
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
        beq     LAFB1
        .byte   $E3
        sbc     #$E6
        sbc     #$E5
        cpx     $8D
        brk
        jmp     xerr

LAFD7:  jsr     LFD8E
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

