	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_AC00"
.org	$ac00

LABE2	= $ABE2
LBF00	= $BF00
LBF26	= $BF26
LFD8E	= $FD8E

LAC00:  rts

        inc     $11EE
        .byte   $12
        brk
        .byte   $1C
        ldy     LAC00
        eor     $03AC
        brk
        brk
        brk
        .byte   $F2
        brk
        inc     $00
        sbc     ($00,x)
        inc     $01,x
        sbc     #$06
        brk
        brk
        bmi     LABE2
        sbc     #$F3
        sbc     ($E2,x)
        cpx     $AFE5
        sbc     $EE
        sbc     ($E2,x)
        cpx     $A0E5
        .byte   $AF
        .byte   $F2
        sbc     ($ED,x)
        ldy     #$E4
        .byte   $F2
        sbc     #$F6
        sbc     $AE
        ldy     #$A0
        .byte   $D7
        .byte   $F2
        sbc     #$F4
        .byte   $F4
        sbc     $EE
        .byte   $A0
LAC41:  .byte   $E2
        sbc     $CAA0,y
        sbc     $E6
        inc     $A0
        cpy     $E9
        inc     $20E7
        .byte   $72
        bcs     LAC41
        .byte   $1B
        lda     #$F2
        jsr     xgetparm_ch
        bcc     LAC70
        lda     #$E1
        jsr     xgetparm_ch
        bcc     LAC73
        lda     #$E6
        jsr     xgetparm_ch
        bcc     LAC6A
        jmp     LAE99

LAC6A:  jmp     LAED1

        jmp     LAE02

LAC70:  jmp     LAC76

LAC73:  jmp     LAD6E

LAC76:  jsr     LAE2D
        bcc     LAC7E
        jmp     LAF53

LAC7E:  jsr     xpush_level
        lda     #$AE
        ldy     #$86
        jsr     xdir_setup
        jsr     xread1dir
        php
        jsr     xdir_finish
        plp
        bcs     LACD1
        lda     #$E6
        jsr     xgetparm_ch
        bcc     LACD1
        lda     #$01
        jsr     xredirect
        jsr     LAE6B
        jsr     xmess
        ldy     #$EE
        .byte   $EF
        .byte   $F4
        ldy     #$E5
        sbc     $F4F0
        sbc     $A0AC,y
        .byte   $EF
        .byte   $EB
        sbc     ($F9,x)
        ldy     #$F4
        .byte   $EF
        ldy     #$E4
        sbc     $F3
        .byte   $F4
        .byte   $F2
        .byte   $EF
        sbc     $A900,y
        inc     $7520
        bcs     LACCE
        lda     #$FF
        jsr     xredirect
        plp
        bne     LACD1
LACCE:  jmp     LAF03

LACD1:  jsr     LAE6B
        jsr     xmess
        ldy     #$F2
        sbc     $ED
        .byte   $EF
        inc     $E5,x
        cpx     $8D
        brk
        lda     LBF26
        cmp     LADFC
        bne     LACF1
        lda     $BF27
        cmp     LADFD
        beq     LAD10
LACF1:  jsr     xmess
        cpx     $E5
        inc     $E9,x
        .byte   $E3
        sbc     $A0
        inc     $E5,x
        .byte   $E3
        .byte   $F4
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$00
        ldy     LADFC
        lda     LADFD
        jsr     xprdec_2
        jsr     LFD8E
LAD10:  lda     $BF10
        sta     LBF26
        lda     $BF11
        sta     $BF27
        ldx     $BF31
LAD1F:  lda     $BF32,x
        sta     LAD6D
        and     #$F0
        cmp     #$B0
        beq     LAD30
        dex
        bpl     LAD1F
        bmi     LAD6A
LAD30:  cpx     $BF31
        beq     LAD3E
        lda     $BF33,x
        sta     $BF32,x
        inx
        bne     LAD30
LAD3E:  lda     #$00
        sta     $BF32,x
        dec     $BF31
        lda     LAD6D
        and     #$0F
        cmp     LADFE
        beq     LAD6A
        pha
        jsr     xmess
        cpx     $E5
        inc     $E9,x
        .byte   $E3
        sbc     $A0
        sbc     #$E4
        tsx
        ldy     #$00
        pla
        tay
        lda     #$00
        jsr     xprdec_2
        jsr     LFD8E
LAD6A:  jmp     LAE2D

LAD6D:  brk
LAD6E:  jsr     xgetnump
        cmp     #$01
        bne     LAD81
        lda     $BF98
        and     #$30
        cmp     #$30
        beq     LAD9B
        jmp     LAF7E

LAD81:  lda     #$F6
        jsr     xgetparm_ch
        bcs     LAD8E
        stx     LADFD
        sty     LADFC
LAD8E:  lda     #$E9
        jsr     xgetparm_ch
        bcs     LAD9B
        tya
        and     #$0F
        sta     LADFE
LAD9B:  ldx     $BF31
LAD9E:  lda     $BF32,x
        and     #$F0
        cmp     #$B0
        bne     LADAA
        jmp     LAF28

LADAA:  dex
        bpl     LAD9E
        inc     $BF31
        ldx     $BF31
LADB3:  lda     $BF31,x
        sta     $BF32,x
        dex
        bne     LADB3
        lda     #$B0
        ora     LADFE
        sta     $BF32
        lda     LADFC
        sta     LBF26
        lda     LADFD
        sta     $BF27
        lda     #$03
        sta     $42
        lda     #$B0
        sta     $43
        sta     $C080
        jsr     LADFF
        sta     $C081
        bcc     LADE6
        jmp     LAE96

LADE6:  jsr     LAE2D
        jsr     LAE6B
        jsr     xmess
        ldy     #$E9
        inc     $F4F3
        sbc     ($EC,x)
        cpx     $E4E5
        sta     $6000
LADFC:  brk
LADFD:  .byte   $FF
LADFE:  .byte   $0F
LADFF:  jmp     (LBF26)

LAE02:  jsr     LAE2D
        bcc     LAE0A
        jmp     LAF53

LAE0A:  jsr     LAE6B
        jsr     xmess
        ldy     #$F0
        .byte   $F2
        sbc     $F3
        sbc     $EE
        .byte   $F4
        ldy     #$E9
        inc     $F3A0
        cpx     $F4EF
        ldy     #$B3
        ldy     #$E4
        .byte   $F2
        sbc     #$F6
        sbc     $A0
        .byte   $B2
        sta     $6000
LAE2D:  jsr     LBF00
        cmp     $72
        ldx     $0790
        cmp     #$28
        beq     LAE50
        jmp     LAE96

        lda     LAE76
        and     #$0F
        sta     LAE76
        bne     LAE52
        lda     LAE77
        cmp     #$28
        beq     LAE50
        jmp     LAE96

LAE50:  sec
        rts

LAE52:  lda     #$AF
        sta     LAE87
        ldx     LAE76
        stx     LAE86
        inc     LAE86
LAE60:  lda     LAE77,x
        sta     LAE88,x
        dex
        bpl     LAE60
        clc
        rts

LAE6B:  lda     #$AE
        ldy     #$86
        jmp     xprint_path

        .byte   $02
        bcs     LAEEB
        .byte   $AE
LAE76:  brk
LAE77:  brk
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
LAE86:  brk
LAE87:  brk
LAE88:  brk
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
LAE96:  jmp     xProDOS_err

LAE99:  jsr     LFD8E
        jsr     xmess
        cmp     $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
        .byte   $AD
LAEA8:  inc     $A0,x
        sbc     ($EE,x)
        cpx     $A0
        lda     $A0E9
        .byte   $EF
        beq     LAEA8
        sbc     #$EF
        inc     $EEA0
        .byte   $EF
        .byte   $F4
        ldy     #$F6
        sbc     ($EC,x)
        sbc     #$E4
        ldy     #$F7
        sbc     #$F4
        inx
        .byte   $EF
        sbc     $F4,x
        ldy     #$AD
        sbc     ($8D,x)
        brk
        jmp     xerr

LAED1:  jsr     LFD8E
        jsr     xmess
        cmp     $F2
LAED9:  .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
        lda     $A0E6
        .byte   $EF
        beq     LAED9
        sbc     #$EF
        inc     $EEA0
        .byte   $EF
LAEEB:  .byte   $F4
        ldy     #$F6
        sbc     ($EC,x)
        sbc     #$E4
        ldy     #$F7
        sbc     #$F4
        inx
        .byte   $EF
        sbc     $F4,x
        ldy     #$AD
        .byte   $F2
        ldy     a:$8D
        jmp     xerr

LAF03:  jsr     LFD8E
        jsr     xmess
        cmp     $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
        cpx     $E5
        inc     $E9,x
        .byte   $E3
        sbc     $A0
        inc     $F4EF
        ldy     #$F2
        sbc     $ED
        .byte   $EF
        inc     $E5,x
        cpx     $8D
        brk
        jmp     xerr

LAF28:  jsr     LFD8E
        jsr     xmess
        cmp     $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
        cpx     $E5
        inc     $E9,x
        .byte   $E3
        sbc     $A0
        sbc     ($EC,x)
        .byte   $F2
        sbc     $E1
        cpx     $F9
        ldy     #$E9
        inc     $F4F3
        sbc     ($EC,x)
        cpx     $E4E5
        sta     $4C00
        pha
        .byte   $B0
LAF53:  jsr     xmess
        inc     $A0EF
        cpx     $E5
        inc     $E9,x
        .byte   $E3
        sbc     $A0
        .byte   $E3
        .byte   $EF
        inc     $E5EE
        .byte   $E3
        .byte   $F4
        sbc     $E4
        ldy     #$E9
        inc     $F3A0
        cpx     $F4EF
        ldy     #$B3
        ldy     #$E4
        .byte   $F2
        sbc     #$F6
        sbc     $A0
        .byte   $B2
        sta     $6000
LAF7E:  jsr     LFD8E
        jsr     xmess
        cmp     $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
LAF89:  tsx
        ldy     #$A0
        .byte   $F3
        .byte   $F4
        sbc     ($EE,x)
        cpx     $E1
        .byte   $F2
        cpx     $A0
        bne     LAF89
        .byte   $EF
        cpy     $CF
        .byte   $D3
        ldy     #$E4
        .byte   $F2
        sbc     #$F6
        sbc     $F2
        ldy     #$EE
        .byte   $EF
        .byte   $F4
        ldy     #$F0
        .byte   $F2
        sbc     $F3
        sbc     $EE
        .byte   $F4
        sta     $4C00
        pha
        .byte   $B0
