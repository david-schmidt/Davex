	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_AC00"

LBF00           := $BF00
LFD8E           := $FD8E
LFDED           := $FDED
        rts

        inc     $10EE
        .byte   $12
        brk
        bit     $AC
        brk
        ldy     LAC41
        .byte   $03
        brk
        brk
        brk
        brk
        .byte   $04
        brk
        .byte   $04
LAC14:  .byte   $F3
        .byte   $02
        sbc     $02
        cpx     $E202
        .byte   $07
        cpx     $06
        inc     $00
        .byte   $F7
        asl     $00
        brk
        .byte   $1C
        .byte   $D3
        beq     LAC14
        sbc     #$F4
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
LAC41:  nop
        sty     $E0
        sty     LAF88
        sty     LAF9A
        sta     $E1
        sta     LAF89
        sta     LAF9B
        lda     #$00
        ldx     #$0A
LAC56:  sta     $E6,x
        dex
        bpl     LAC56
        lda     #$01
        jsr     xgetparm_n
        sty     $E2
        sty     LAFB3
        sty     LAFC5
        sty     LAFC8
        sty     LAFAD
        sta     $E3
        sta     LAFB4
        sta     LAFC6
        sta     LAFC9
        sta     LAFAE
        ldy     #$00
        lda     ($E2),y
        beq     LAC96
        tax
LAC83:  lda     ($E0),y
        cmp     ($E2),y
        bne     LAC90
        iny
        dex
        bpl     LAC83
        jmp     LAFDD

LAC90:  lda     $EF
        ora     #$80
        sta     $EF
LAC96:  lda     #$E2
        jsr     xgetparm_ch
        bcs     LACA5
        bmi     LACA5
        lda     $EF
        ora     #$40
        sta     $EF
LACA5:  lda     #$F3
        jsr     xgetparm_ch
        bcs     LACB2
        sty     $E6
        stx     $E7
        sta     $E8
LACB2:  bit     $EF
        bvc     LACC8
        lda     $E6
        ora     $E7
        ora     $E8
        bne     LACC8
        inc     $E6
        bne     LACC8
        inc     $E7
        bne     LACC8
        inc     $E8
LACC8:  lda     #$E5
        jsr     xgetparm_ch
        bcs     LACF4
        sty     $E9
        stx     $EA
        sta     $EB
        inc     $E9
        bne     LACDF
        inc     $EA
        bne     LACDF
        inc     $EB
LACDF:  lda     $E8
        cmp     $EB
        bcc     LAD22
        lda     $E7
        cmp     $EA
        bcc     LAD22
        lda     $E6
        cmp     $E9
        bcc     LAD22
LACF1:  jmp     LAFDD

LACF4:  lda     #$EC
        jsr     xgetparm_ch
        bcc     LAD03
        dec     $E9
        dec     $EA
        dec     $EB
        bne     LAD22
LAD03:  sty     $E9
        stx     $EA
        sta     $EB
        ora     $EA
        ora     $E9
        beq     LACF1
        lda     $E6
        clc
        adc     $E9
        sta     $E9
        lda     $E7
        adc     $EA
        sta     $EA
        lda     $E8
        adc     $EB
        sta     $EB
LAD22:  lda     #$E4
        jsr     xgetparm_ch
        bcc     LAD2B
        ldy     #$0D
LAD2B:  tya
        and     #$7F
        sta     $F2
        lda     #$F7
        jsr     xgetparm_ch
        bcc     LAD39
        ldy     #$00
LAD39:  sty     $F1
        ldx     #$CA
        jsr     xmmgr
        sty     LAFA8
        sta     LAFA9
        ldx     #$C4
        jsr     xmmgr
        sty     $E2
        sty     LAFA6
        sta     $E3
        sta     LAFA7
        jsr     LBF00
        cpy     $87
        .byte   $AF
        bcs     LAD65
        jsr     LBF00
        iny
        sta     $90AF,y
        .byte   $03
LAD65:  jmp     xProDOS_err

        lda     LAF9E
        sta     LAFA5
        sta     LAFA0
        bit     $EF
        bmi     LAD78
        jmp     LADFC

LAD78:  jsr     LBF00
        cpy     $B2
        .byte   $AF
        bcc     LAD87
        cmp     #$46
        beq     LADCD
        jmp     xProDOS_err

LAD87:  lda     #$E6
        jsr     xgetparm_ch
        bcc     LADC5
        lda     #$01
        jsr     xredirect
        jsr     xmess
        .byte   $CF
        .byte   $EB
        sbc     ($F9,x)
        ldy     #$F4
        .byte   $EF
        ldy     #$EF
        inc     $E5,x
        .byte   $F2
        .byte   $F7
        .byte   $F2
        sbc     #$F4
        sbc     $A0
        brk
        ldy     LAFAD
        lda     LAFAE
        jsr     xprint_path
        lda     #$EE
        jsr     xyesno2
        php
        lda     #$FF
        jsr     xredirect
        plp
        bne     LADC5
        lda     #$86
        jmp     xProDOS_err

LADC5:  jsr     LBF00
        cmp     ($C4,x)
        .byte   $AF
        bcs     LADF3
LADCD:  ldy     #$04
LADCF:  lda     LAF8A,y
        sta     LAFCA,y
        dey
        bpl     LADCF
        ldy     #$03
LADDA:  lda     LAF95,y
        sta     LAFCF,y
        dey
        bpl     LADDA
        jsr     LBF00
        cpy     #$C7
        .byte   $AF
        bcs     LADF3
        jsr     LBF00
        iny
        ldy     $90AF
        .byte   $03
LADF3:  jmp     xProDOS_err

        lda     LAFB1
        sta     LAFD4
LADFC:  bit     $EF
        bvs     LAE27
        lda     $E6
        sta     LAFA1
        lda     $E7
        sta     LAFA2
        lda     $E8
        sta     LAFA3
        jsr     LBF00
        dec     LAF9F
        bcs     LAE24
        jsr     LAF55
        lda     $E2
        sta     $E0
        lda     $E3
        sta     $E1
        bcc     LAE83
LAE24:  jmp     LAF2B

LAE27:  jsr     LAF55
        bcs     LAE7E
        lda     $E2
        sec
        sbc     #$01
        sta     $E0
        lda     $E3
        sbc     #$00
        sta     $E1
        jmp     LAE46

LAE3C:  ldy     #$00
        lda     ($E0),y
        and     #$7F
        cmp     $F2
        bne     LAE77
LAE46:  inc     $EC
        bne     LAE50
        inc     $ED
        bne     LAE50
        inc     $EE
LAE50:  lda     $EC
        cmp     $E6
        bcc     LAE77
        lda     $ED
        cmp     $E7
        bcc     LAE77
        lda     $EE
        cmp     $E8
        bcc     LAE77
        jsr     LAF76
        bcc     LAE7E
LAE67:  jsr     LAF55
        bcs     LAE7E
        lda     $E2
        sta     $E0
        lda     $E3
        sta     $E1
        jmp     LAE3C

LAE77:  jsr     LAF76
        bcc     LAE3C
        bcs     LAE67
LAE7E:  bcc     LAE83
        jmp     LAF2B

LAE83:  lda     $E0
        sta     LAFD5
        lda     $E1
        sta     LAFD6
LAE8D:  ldy     #$00
        lda     ($E0),y
        bit     $EF
        bmi     LAED8
        ora     #$80
        cmp     #$A1
        bcs     LAEB7
        cmp     #$8D
        beq     LAECC
        cmp     #$89
        beq     LAEB7
        cmp     #$A0
        bne     LAEB5
        lda     $F1
        beq     LAEB2
        sec
        sbc     $F0
        cmp     #$0A
        bcc     LAECC
LAEB2:  lda     #$A0
        .byte   $2C
LAEB5:  lda     #$AE
LAEB7:  jsr     LFDED
        inc     $F0
        lda     $F0
        ldx     $F1
        beq     LAEC6
        cmp     $F1
        beq     LAECC
LAEC6:  cmp     #$50
        bne     LAED8
        beq     LAECF
LAECC:  jsr     LFD8E
LAECF:  jsr     xcheck_wait
        bcs     LAF2B
        lda     #$00
        sta     $F0
LAED8:  bit     $EF
        bvc     LAEE4
        lda     ($E0),y
        and     #$7F
        cmp     $F2
        bne     LAF08
LAEE4:  inc     $E6
        bne     LAEEE
        inc     $E7
        bne     LAEEE
        inc     $E8
LAEEE:  lda     $E8
        cmp     $EB
        bcc     LAF08
        lda     $E7
        cmp     $EA
        bcc     LAF08
        lda     $E6
        cmp     $E9
        bcc     LAF08
        inc     $E0
        bne     LAF06
        inc     $E1
LAF06:  bcs     LAF24
LAF08:  jsr     LAF76
        bcc     LAE8D
        bit     $EF
        bpl     LAF14
        jsr     LAF38
LAF14:  jsr     LAF55
        lda     $E2
        sta     $E0
        lda     $E3
        sta     $E1
        bcs     LAF24
        jmp     LAE83

LAF24:  bit     $EF
        bpl     LAF2B
        jsr     LAF38
LAF2B:  bit     $EF
        bpl     LAF37
        jsr     LBF00
        cpy     LAFDB
        bcs     LAF52
LAF37:  rts

LAF38:  lda     $E0
        sec
        sbc     LAFD5
        sta     LAFD7
        lda     $E1
        sbc     LAFD6
        sta     LAFD8
        jsr     LBF00
        .byte   $CB
        .byte   $D3
        .byte   $AF
        bcs     LAF52
        rts

LAF52:  jmp     xProDOS_err

LAF55:  jsr     LBF00
        dex
        ldy     $AF
        bcc     LAF63
        cmp     #$4C
        beq     LAF74
        bne     LAF52
LAF63:  lda     LAFAA
        clc
        adc     $E2
        sta     $E4
        lda     LAFAB
        adc     $E3
        sta     $E5
        clc
        rts

LAF74:  sec
        rts

LAF76:  inc     $E0
        bne     LAF7C
        inc     $E1
LAF7C:  lda     $E0
        cmp     $E4
        bcc     LAF86
        lda     $E1
        cmp     $E5
LAF86:  rts

        asl     a
LAF88:  brk
LAF89:  brk
LAF8A:  brk
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
LAF95:  brk
        brk
        brk
        brk
        .byte   $03
LAF9A:  brk
LAF9B:  brk
        brk
        php
LAF9E:  brk
LAF9F:  .byte   $02
LAFA0:  brk
LAFA1:  brk
LAFA2:  brk
LAFA3:  brk
        .byte   $04
LAFA5:  brk
LAFA6:  brk
LAFA7:  brk
LAFA8:  brk
LAFA9:  brk
LAFAA:  brk
LAFAB:  brk
        .byte   $03
LAFAD:  brk
LAFAE:  brk
        brk
        .byte   $0C
LAFB1:  brk
        asl     a
LAFB3:  brk
LAFB4:  brk
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
        .byte   $01
LAFC5:  brk
LAFC6:  brk
        .byte   $07
LAFC8:  brk
LAFC9:  brk
LAFCA:  brk
        brk
        brk
        brk
        brk
LAFCF:  brk
        brk
        brk
        brk
        .byte   $04
LAFD4:  brk
LAFD5:  brk
LAFD6:  brk
LAFD7:  brk
LAFD8:  brk
        brk
        brk
LAFDB:  ora     ($00,x)
LAFDD:  jsr     xmess
        sta     $F2C5
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
        .byte   $C2
        sbc     ($E4,x)
        ldy     #$F0
        sbc     ($F2,x)
        sbc     ($ED,x)
        sbc     $F4
        sbc     $F2
        .byte   $F3
        sta     $4C00
        pha
        .byte   $B0
