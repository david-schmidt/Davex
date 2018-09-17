	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_A000"	

LBF00	= $bf00
LFD8E	= $fd8e
L00AE	= $00ae
        rts

        inc     $10EE
        .byte   $12
        brk
        jsr     L00AE
        ldx     LAE42
        .byte   $03
        brk
        brk
        brk
        brk
        .byte   $04
        .byte   $E3
        brk
        .byte   $F7
        brk
        cpx     $E400
        asl     $E5
        asl     $ED
        asl     $00
        brk
        and     ($D7,x)
        .byte   $EF
        .byte   $F2
        cpx     $A0
        .byte   $E3
        .byte   $EF
        sbc     $EE,x
        .byte   $F4
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
        .byte   $EE
        .byte   $E7
LAE42:  nop
        sty     $E0
        sta     $E1
        jsr     LFD8E
        lda     $E1
        jsr     xprint_path
        jsr     xmess
        tsx
        sta     $A900
        brk
        ldx     #$0A
LAE59:  sta     $E2,x
        dex
        bpl     LAE59
        lda     #$E3
        jsr     xgetparm_ch
        bcs     LAE6B
        lda     $EB
        ora     #$01
        sta     $EB
LAE6B:  lda     #$F7
        jsr     xgetparm_ch
        bcs     LAE78
        lda     $EB
        ora     #$02
        sta     $EB
LAE78:  lda     #$EC
        jsr     xgetparm_ch
        bcs     LAE85
        lda     $EB
        ora     #$04
        sta     $EB
LAE85:  lda     $EB
        bne     LAE8D
        ora     #$07
        sta     $EB
LAE8D:  lda     #$E4
        jsr     xgetparm_ch
        bcc     LAE96
        ldy     #$0D
LAE96:  tya
        and     #$7F
        sta     $F0
        lda     #$E5
        jsr     xgetparm_ch
        bcc     LAEA4
        ldy     #$20
LAEA4:  tya
        and     #$7F
        sta     $EF
        sta     $EE
        lda     #$ED
        jsr     xgetparm_ch
        bcc     LAEB4
        ldy     #$00
LAEB4:  sty     $F1
        ldy     $E0
        lda     $E1
        jsr     xfman_open
        bcs     LAED1
        sta     LAFE2
LAEC2:  lda     LAFE2
        jsr     xfman_read
        bcc     LAED4
        cmp     #$4C
        bne     LAED1
        jmp     LAF3F

LAED1:  jmp     xProDOS_err

LAED4:  and     #$7F
        sta     $ED
        cmp     $EF
        beq     LAEEE
        cmp     $F0
        bne     LAF04
        inc     $E8
        bne     LAEEA
        inc     $E9
        bne     LAEEA
        inc     $EA
LAEEA:  lda     #$00
        sta     $EC
LAEEE:  lda     $F0
        cmp     $EE
        beq     LAF04
        lda     $EF
        cmp     $EE
        beq     LAF04
        inc     $E5
        bne     LAF04
        inc     $E6
        bne     LAF04
        inc     $E7
LAF04:  inc     $E2
        bne     LAF0E
        inc     $E3
        bne     LAF0E
        inc     $E4
LAF0E:  lda     $ED
        sta     $EE
        ldx     $F1
        beq     LAEC2
        cmp     $F0
        beq     LAEC2
        cmp     $EF
        bne     LAF26
        txa
        sec
        sbc     $EC
        cmp     #$0A
        bcc     LAF2E
LAF26:  inc     $EC
        lda     $EC
        cmp     $F1
        bcc     LAEC2
LAF2E:  inc     $E8
        bne     LAF38
        inc     $E9
        bne     LAF38
        inc     $EA
LAF38:  lda     #$00
        sta     $EC
        jmp     LAEC2

LAF3F:  lda     $EE
        cmp     $F0
        beq     LAF5D
        cmp     $EF
        beq     LAF53
        inc     $E5
        bne     LAF53
        inc     $E6
        bne     LAF53
        inc     $E7
LAF53:  inc     $E8
        bne     LAF5D
        inc     $E9
        bne     LAF5D
        inc     $EA
LAF5D:  jsr     LBF00
        cpy     LAFE1
        bcc     LAF68
        jmp     xProDOS_err

LAF68:  lda     $EB
        and     #$01
        beq     LAF90
        lda     $E2
        sta     $61
        lda     $E3
        sta     $62
        lda     $E4
        sta     $63
        jsr     xmess
        .byte   $E3
        inx
        sbc     ($F2,x)
        ldy     #$E3
        .byte   $EF
        sbc     $EE,x
        .byte   $F4
        ldy     #$BD
        brk
        jsr     xprdec_pad
        jsr     LFD8E
LAF90:  lda     $EB
        and     #$02
        beq     LAFB8
        lda     $E5
        sta     $61
        lda     $E6
        sta     $62
        lda     $E7
        sta     $63
        jsr     xmess
        .byte   $F7
        .byte   $EF
        .byte   $F2
        cpx     $A0
        .byte   $E3
        .byte   $EF
        sbc     $EE,x
        .byte   $F4
        ldy     #$BD
        brk
        jsr     xprdec_pad
        jsr     LFD8E
LAFB8:  lda     $EB
        and     #$04
        beq     LAFE0
        lda     $E8
        sta     $61
        lda     $E9
        sta     $62
        lda     $EA
        sta     $63
        jsr     xmess
        cpx     $EEE9
        sbc     $A0
        .byte   $E3
        .byte   $EF
        sbc     $EE,x
        .byte   $F4
        ldy     #$BD
        brk
        jsr     xprdec_pad
        jsr     LFD8E
LAFE0:  rts

LAFE1:  .byte   $01
LAFE2:  brk
