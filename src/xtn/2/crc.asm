	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_9000"

L2090           := $2090
L8FF7           := $8FF7
L8FFA           := $8FFA
LBF00           := $BF00
        rts

        inc     $11EE
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
L9014:  rol     a
        .byte   $C3
        .byte   $EF
        sbc     $F5F0
        .byte   $F4
        sbc     $A0
        .byte   $F4
        inx
        sbc     $A0
        .byte   $C3
        .byte   $D2
L9023:  .byte   $C3
        ldx     $D7A0
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
        jmp     L90B9

        .byte   $03
L9044:  brk
L9045:  brk
        brk
        .byte   $92
        brk
L9049:  ora     ($00,x)
L904B:  .byte   $04
        brk
        .byte   $53
        bcc     L9053
        brk
        brk
        brk
L9053:  .byte   $DD
L9054:  .byte   $DD
L9055:  .byte   $DD
L9056:  .byte   $DD
L9057:  .byte   $DD
L9058:  cmp     a:$00,x
        brk
        brk
        brk
        brk
        brk
L9060:  jsr     LBF00
        .byte $c8
        .byte   $43, $90
	lda $9048
	sta $904A
	sta $904C
L906F:  jsr     LBF00
        dex
        .byte   $4B
        bcc     L9023
        eor     ($90),y
        cmp     #$03
        beq     L907F
        jmp     L90A0

L907F:  lda     L9053
        adc     L9056
        sta     L9056
        clc
        lda     L9054
        adc     L9057
        sta     L9057
        clc
        lda     L9055
        adc     L9058
        sta     L9058
        clc
        jmp     L906F

L90A0:  jsr     LBF00
        cpy     L9049
        lda     L9056
        sta     $61
        lda     L9057
        sta     $62
        lda     L9058
        sta     $63
        jsr     xprdec_3
        rts

L90B9:  sta     L9045
        sty     L9044
        sta     $EB
        sty     $EA
        ldy     #$00
        lda     ($EA),y
        beq     L90CC
        jmp     L9060

L90CC:  jsr     xmess
        sta     $F2C5
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$C6
        sbc     #$EC
        sbc     $EE
        sbc     ($ED,x)
        sbc     $A0
        inc     $F4EF
        ldy     #$F3
        beq     L90CC
        .byte   $E3
        sbc     #$E6
        sbc     #$E5
        cpx     $8D
        brk
        rts

