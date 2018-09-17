	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_AC00"

L201E           := $201E
L201F           := $201F
LFD8E           := $FD8E
LFDED           := $FDED
LAC00:  rts

        inc     $11EE
        .byte   $12
        brk
        .byte   $1A
        ldy     LAC00
        .byte   $4F
        ldy     a:$03
        brk
        brk
        beq     LAC12
LAC12:  .byte   $F3
        brk
        cpx     $00
        .byte   $F4
        brk
        brk
        brk
        .byte   $34
        cpy     $E1
        .byte   $F4
        sbc     $A0
        sbc     ($EE,x)
        cpx     $A0
        .byte   $F4
        sbc     #$ED
        sbc     $A0
        .byte   $F3
        sbc     $F4
        .byte   $F4
        sbc     #$EE
        .byte   $E7
        ldy     #$F0
        .byte   $F2
        .byte   $EF
        .byte   $E7
        .byte   $F2
        sbc     ($ED,x)
        ldx     $A0A0
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
        inc     $20E7
        brk
        .byte   $BF
        .byte   $82
        brk
        brk
        jsr     LACBC
        jsr     xgetnump
        beq     LACA0
        lda     #$F0
        jsr     xgetparm_ch
        bcc     LACB6
        lda     #$F3
        jsr     xgetparm_ch
        bcc     LAC6E
        jmp     LAF1C

LAC6E:  lda     #$01
        jsr     xredirect
        lda     #$E4
        jsr     xgetparm_ch
        bcc     LAC82
        lda     $E0
        ora     $E1
        ora     $E2
        bne     LAC88
LAC82:  jsr     LAD03
        jsr     LADB0
LAC88:  lda     #$F4
        jsr     xgetparm_ch
        bcc     LAC95
        lda     $E3
        ora     $E4
        bne     LAC9B
LAC95:  jsr     LAD7F
        jsr     LADD2
LAC9B:  lda     #$FF
        jmp     xredirect

LACA0:  lda     #$01
        jsr     xredirect
        jsr     LAD03
        jsr     LADB0
        jsr     LAD7F
        jsr     LADD2
        lda     #$FF
        jmp     xredirect

LACB6:  jsr     LAD03
        jmp     LAD7F

LACBC:  lda     $BF91
        clc
        ror     a
        sta     $E2
        lda     $BF90
        ror     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     $E1
        lda     $BF90
        and     #$1F
        sta     $E0
        lda     $BF93
        sta     $E3
        lda     $BF92
        sta     $E4
        rts

LACDF:  lda     $E1
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $BF90
        lda     $E2
        rol     a
        sta     $BF91
        lda     $E0
        ora     $BF90
        sta     $BF90
        rts

LACF8:  lda     $E3
        sta     $BF93
        lda     $E4
        sta     $BF92
        rts

LAD03:  jsr     xmess
        .byte   $C3
        sbc     $F2,x
        .byte   $F2
        sbc     $EE
        .byte   $F4
        ldy     #$C4
        sbc     ($F4,x)
        sbc     $BA
        ldy     #$00
        ldy     $E0
        lda     #$00
        jsr     xprdec_2
        lda     #$AD
        jsr     LFDED
        lda     $E1
        asl     a
        clc
        adc     $E1
        tax
        lda     LAD58,x
        cmp     #$E0
        bcc     LAD31
        sbc     #$20
LAD31:  jsr     LFDED
        lda     LAD59,x
        jsr     LFDED
        lda     LAD5A,x
        jsr     LFDED
        lda     #$AD
        jsr     LFDED
        ldy     $E2
        cpy     #$0A
        bcs     LAD50
        lda     #$B0
        jsr     LFDED
LAD50:  lda     #$00
        jsr     xprdec_2
        jmp     LFD8E

LAD58:  .byte   $BF
LAD59:  .byte   $BF
LAD5A:  .byte   $BF
        nop
        sbc     ($EE,x)
        inc     $E5
        .byte   $E2
        sbc     $F2E1
        sbc     ($F0,x)
        .byte   $F2
        sbc     $F9E1
        nop
        sbc     $EE,x
        nop
        sbc     $EC,x
        sbc     ($F5,x)
        .byte   $E7
        .byte   $F3
        sbc     $F0
        .byte   $EF
        .byte   $E3
        .byte   $F4
        inc     $F6EF
        cpx     $E5
        .byte   $E3
LAD7F:  jsr     xmess
        .byte   $C3
        sbc     $F2,x
        .byte   $F2
        sbc     $EE
        .byte   $F4
        ldy     #$D4
        sbc     #$ED
        sbc     $BA
        ldy     #$00
        lda     #$00
        ldy     $E3
        jsr     xprdec_2
        lda     #$BA
        jsr     LFDED
        ldy     $E4
        cpy     #$0A
        bcs     LADA8
        lda     #$B0
        jsr     LFDED
LADA8:  lda     #$00
        jsr     xprdec_2
        jmp     LFD8E

LADB0:  jsr     xmess
        .byte   $D3
        sbc     $F4
        ldy     #$CE
        sbc     $F7
        ldy     #$C4
        sbc     ($F4,x)
        sbc     $BA
        ldy     #$00
        jsr     LADF4
        bcs     LADCF
        jsr     LAE58
        bcs     LADCF
        jsr     LACDF
LADCF:  jmp     LFD8E

LADD2:  jsr     xmess
        .byte   $D3
        sbc     $F4
        ldy     #$CE
        sbc     $F7
        ldy     #$D4
        sbc     #$ED
        sbc     $BA
        ldy     #$00
        jsr     LADF4
        bcs     LADF1
        jsr     LAEC2
        bcs     LADF1
        jsr     LACF8
LADF1:  jmp     LFD8E

LADF4:  ldx     #$08
        lda     #$A0
LADF8:  sta     LAE4F,x
        dex
        bpl     LADF8
        ldx     #$00
LAE00:  stx     LAE4E
        lda     #$A0
        jsr     xrdkey
        ldx     LAE4E
        cmp     #$8D
        beq     LAE46
        cmp     #$88
        beq     LAE2C
        cmp     #$FF
        beq     LAE2C
        cmp     #$A0
        bcc     LAE00
        cpx     #$09
        bcs     LAE00
        jsr     LFDED
        jsr     xdowncase
        sta     LAE4F,x
        inx
        jmp     LAE00

LAE2C:  cpx     #$00
        beq     LAE00
        lda     #$88
        jsr     LFDED
        dex
        lda     #$A0
        sta     LAE4F,x
        jsr     LFDED
        lda     #$88
        jsr     LFDED
        jmp     LAE00

LAE46:  cpx     #$00
        beq     LAE4C
        clc
        rts

LAE4C:  sec
        rts

LAE4E:  brk
LAE4F:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
LAE58:  ldx     #$00
        jsr     LAED7
        sta     $E0
        ldy     #$00
LAE61:  lda     LAE4F,x
        sta     LAEBE,y
        inx
        iny
        cpy     #$03
        bcc     LAE61
        inx
        stx     LAEC1
        ldy     #$00
        ldx     #$00
LAE75:  lda     LAD58,x
        cmp     LAEBE
        bne     LAE8D
        lda     LAD59,x
        cmp     LAEBF
        bne     LAE8D
        lda     LAD5A,x
        cmp     LAEC0
        beq     LAE97
LAE8D:  inx
        inx
        inx
        iny
        cpy     #$0D
        bcc     LAE75
        ldy     #$00
LAE97:  sty     $E1
        ldx     LAEC1
        jsr     LAED7
        sta     $E2
        ldx     $E1
        beq     LAEB0
        dex
        lda     $E0
        beq     LAEB0
        cmp     LAEB2,x
        bcs     LAEB0
        rts

LAEB0:  sec
        rts

LAEB2:  jsr     L201E
        .byte   $1F
        jsr     L201F
        jsr     L201F
        .byte   $1F
        .byte   $20
LAEBE:  brk
LAEBF:  brk
LAEC0:  brk
LAEC1:  brk
LAEC2:  ldx     #$00
        jsr     LAED7
        sta     $E3
        jsr     LAED7
        sta     $E4
        cmp     #$3C
        bcs     LAED6
        lda     $E3
        cmp     #$18
LAED6:  rts

LAED7:  lda     LAE4F,x
        cmp     #$B0
        bcc     LAEE2
        cmp     #$BA
        bcc     LAEE4
LAEE2:  lda     #$00
LAEE4:  and     #$0F
        sta     LAF1A
        inx
        lda     LAE4F,x
        inx
        cmp     #$B0
        bcc     LAEF6
        cmp     #$BA
        bcc     LAF05
LAEF6:  lda     LAF1A
        sta     LAF1B
        lda     #$00
        sta     LAF1A
        lda     LAF1B
        dex
LAF05:  and     #$0F
        sta     LAF1B
        inx
        lda     LAF1A
        asl     a
        asl     a
        clc
        adc     LAF1A
        asl     a
        clc
        adc     LAF1B
        rts

LAF1A:  brk
LAF1B:  brk
LAF1C:  jsr     LFD8E
        jsr     xmess
        cmp     $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
LAF2A:  lda     $A0E4
        .byte   $EF
        .byte   $F2
        ldy     #$AD
        .byte   $F4
        ldy     #$EF
        beq     LAF2A
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
        .byte   $F3
        sta     $4C00
        pha
        .byte   $B0
