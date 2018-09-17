; da65 V2.13.9 - (C) Copyright 2000-2009,  Ullrich von Bassewitz
; Created:    2011-12-09 15:04:58
; Input file: xtn\COMBINE#06ad00
; Page:       1

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_AD00"

L00AD           := $00AD
LBF00           := $BF00
LFD8E           := $FD8E
LFDED           := $FDED
        rts

        inc     $10EE
        .byte   $12
        brk
        jsr     L00AD
        lda     LAD3F
        .byte   $03
        brk
        brk
        brk
        brk
        .byte   $04
        brk
        .byte   $04
        brk
        .byte   $03
        brk
        .byte   $03
        brk
        .byte   $03
        .byte   $EF
        .byte   $03
        .byte   $F7
        asl     $00
        brk
        asl     $EFC3,x
        sbc     $E9E2
        inc     LAEE5
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
        .byte   $EE
        .byte   $E7
LAD3F:  nop
        lda     #$00
        sta     $E8
        sta     $EB
        sta     $EA
        sta     $E9
        ldx     #$CA
        jsr     xmmgr
        sty     LAF7F
        sta     LAF80
        ldx     #$C4
        jsr     xmmgr
        sty     $E2
        sty     LAF7D
        sta     $E3
        sta     LAF7E
        lda     #$F7
        jsr     xgetparm_ch
        bcc     LAD6D
        ldy     #$00
LAD6D:  sty     $EB
        lda     #$EF
        jsr     xgetparm_ch
        bcs     LAD98
        sty     $E6
        sty     LAF8C
        sty     LAFA3
        sty     LAF86
        sta     $E7
        sta     LAF8D
        sta     LAFA4
        sta     LAF87
        ldy     #$00
        lda     ($E6),y
        beq     LAD98
        lda     $E9
        ora     #$80
        sta     $E9
LAD98:  lda     $E8
        jsr     xgetparm_n
        sty     $E0
        sty     LAF64
        sty     LAF76
        sta     $E1
        sta     LAF65
        sta     LAF77
        ldy     #$00
        lda     ($E0),y
        tax
        bne     LADE3
        cmp     $E8
        beq     LADC0
        jmp     LAF53

        lda     #$01
        jsr     xredirect
LADC0:  jsr     xmess
        sta     $F2C5
        .byte   $F2
        .byte   $EF
LADC8:  .byte   $F2
        tsx
        ldy     #$A0
        dec     $A0EF
        sbc     #$EE
        beq     LADC8
        .byte   $F4
        ldy     #$E6
        sbc     #$EC
        sbc     $8D
        brk
        lda     #$FF
        jsr     xredirect
        jmp     xerr

LADE3:  lda     ($E0),y
        cmp     ($E6),y
        bne     LAE21
        iny
        dex
        bpl     LADE3
        lda     #$01
        jsr     xredirect
        jsr     xmess
        sta     $F2C5
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$A0
        dec     $E9
        cpx     $EEE5
        sbc     ($ED,x)
        sbc     $F3
        ldy     #$E3
        sbc     ($EE,x)
        inc     $F4EF
        ldy     #$E2
        sbc     $A0
        sbc     $F1
        sbc     $E1,x
        cpx     a:$8D
        lda     #$FF
        jsr     xredirect
        jmp     xerr

LAE21:  jsr     LBF00
        cpy     $63
        .byte   $AF
        bcs     LAE31
        jsr     LBF00
        iny
        adc     $AF,x
        bcc     LAE34
LAE31:  jmp     xProDOS_err

LAE34:  lda     LAF7A
        sta     LAF7C
        sta     LAF84
        bit     $E9
        bpl     LAE9D
        bvs     LAE9D
        lda     $E9
        ora     #$40
        sta     $E9
        jsr     LBF00
        cpy     $8B
        .byte   $AF
        bcc     LAE76
        cmp     #$46
        beq     LAE58
        jmp     xProDOS_err

LAE58:  ldy     #$04
LAE5A:  lda     LAF66,y
        sta     LAFA5,y
        dey
        bpl     LAE5A
        ldy     #$03
LAE65:  lda     LAF71,y
        sta     LAFAA,y
        dey
        bpl     LAE65
        jsr     LBF00
        cpy     #$A2
        .byte   $AF
        bcs     LAE7E
LAE76:  jsr     LBF00
        iny
        sta     $AF
        bcc     LAE81
LAE7E:  jmp     xProDOS_err

LAE81:  lda     LAF8A
        sta     LAF9E
        sta     LAFAF
        sta     LAFB7
        jsr     LBF00
        cmp     ($9D),y
        .byte   $AF
        bcs     LAE7E
        jsr     LBF00
        dec     LAF9D
        bcs     LAE7E
LAE9D:  jsr     LBF00
        dex
        .byte   $7B
        .byte   $AF
        bcc     LAEAF
        cmp     #$4C
        bne     LAEAC
        jmp     LAF3D

LAEAC:  jmp     xProDOS_err

LAEAF:  lda     LAF81
        sta     LAFB2
        clc
        adc     $E2
        sta     $E4
        lda     LAF82
        sta     LAFB3
        adc     $E3
        sta     $E5
        lda     $E2
        sta     $E0
        sta     LAFB0
        lda     $E3
        sta     $E1
        sta     LAFB1
        bit     $E9
        bpl     LAEE1
        jsr     LBF00
        .byte   $CB
        ldx     $90AF
        .byte   $BF
        jmp     xProDOS_err

LAEE1:  ldy     #$00
        lda     ($E0),y
LAEE5:  ora     #$80
        cmp     #$A1
        bcs     LAF07
        cmp     #$8D
        beq     LAF1C
        cmp     #$89
        beq     LAF07
        cmp     #$A0
        bne     LAF05
        lda     $EB
        beq     LAF02
        sec
        sbc     $EA
        cmp     #$0A
        bcc     LAF1C
LAF02:  lda     #$A0
        .byte   $2C
LAF05:  lda     #$AE
LAF07:  jsr     LFDED
        inc     $EA
        lda     $EA
        ldx     $EB
        beq     LAF16
        cmp     $EB
        beq     LAF1C
LAF16:  cmp     #$50
        bne     LAF28
        beq     LAF1F
LAF1C:  jsr     LFD8E
LAF1F:  jsr     xcheck_wait
        bcs     LAF3D
        lda     #$00
        sta     $EA
LAF28:  inc     $E0
        bne     LAF2E
        inc     $E1
LAF2E:  lda     $E0
        cmp     $E4
        bcc     LAEE1
        lda     $E1
        cmp     $E5
        bcc     LAEE1
        jmp     LAE9D

LAF3D:  jsr     LBF00
        cpy     LAF83
        bcc     LAF48
        jmp     xProDOS_err

LAF48:  inc     $E8
        lda     $E8
        cmp     #$05
        bcs     LAF53
        jmp     LAD98

LAF53:  bit     $E9
        bpl     LAF62
        jsr     LBF00
        cpy     LAFB6
        bcc     LAF62
        jmp     xProDOS_err

LAF62:  rts

        asl     a
LAF64:  brk
LAF65:  brk
LAF66:  brk
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
LAF71:  brk
        brk
        brk
        brk
        .byte   $03
LAF76:  brk
LAF77:  brk
        brk
        php
LAF7A:  brk
        .byte   $04
LAF7C:  brk
LAF7D:  brk
LAF7E:  brk
LAF7F:  brk
LAF80:  brk
LAF81:  brk
LAF82:  brk
LAF83:  .byte   $01
LAF84:  brk
        .byte   $03
LAF86:  brk
LAF87:  brk
        brk
        .byte   $0C
LAF8A:  brk
        asl     a
LAF8C:  brk
LAF8D:  brk
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
LAF9D:  .byte   $02
LAF9E:  brk
        brk
        brk
        brk
        .byte   $07
LAFA3:  brk
LAFA4:  brk
LAFA5:  brk
        brk
        brk
        brk
        brk
LAFAA:  brk
        brk
        brk
        brk
        .byte   $04
LAFAF:  brk
LAFB0:  brk
LAFB1:  brk
LAFB2:  brk
LAFB3:  brk
        brk
        brk
LAFB6:  .byte   $01
LAFB7:  brk
