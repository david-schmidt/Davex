	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_9000"

LBF00           := $BF00
LFD8E           := $FD8E
        rts

        inc     $10EE
        .byte   $12
        brk
        .byte   $14
        bcc     L9009
L9009:  bcc     L904B
        bcc     L900D
L900D:  brk
        brk
        brk
        brk
        .byte   $03
        brk
        brk
        and     #$CC
        sbc     #$F3
        .byte   $F4
        ldy     #$E4
        sbc     #$F2
        sbc     $E3
        .byte   $F4
        .byte   $EF
        .byte   $F2
        sbc     $A0AE,y
        .byte   $D7
        .byte   $F2
        sbc     #$F4
        .byte   $F4
        sbc     $EE
        ldy     #$E2
        sbc     $D0A0,y
        inx
        sbc     ($E4,x)
        sbc     $A0
        .byte   $D3
        .byte   $EF
        inc     $F4
        .byte   $F7
        sbc     ($F2,x)
        sbc     $00
        brk
        jsr     LBF00
        .byte   $C7
        eor     #$90
        jmp     L904C

        ora     ($00,x)
L904B:  .byte   $94
L904C:  jsr     LFD8E
        lda     #$94
        ldy     #$00
        jsr     xprint_path
        jsr     LFD8E
        jsr     LFD8E
        nop
        jsr     xpush_level
        lda     #$94
        ldy     #$00
        jsr     xdir_setup
L9067:  jsr     xread1dir
        bcc     L9073
        jsr     xdir_finish
        jsr     LFD8E
        rts

L9073:  jsr     L9083
        lda     #$1A
        ldy     #$02
        jsr     xprint_path
        jsr     xcheck_wait
        jmp     L9067

L9083:  ldy     #$00
L9085:  lda     $1A03,y
        cmp     #$00
        beq     L908F
        jmp     L9094

L908F:  lda     #$A0
        sta     $1A03,y
L9094:  iny
        cpy     #$10
        beq     L909C
        jmp     L9085

L909C:  lda     #$A0
        sta     $1A12
        lda     #$10
        sta     $1A02
        rts

        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
