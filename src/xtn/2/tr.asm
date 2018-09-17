	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_AA00"

LBF00           := $BF00
LFD8E           := $FD8E
LFDED           := $FDED
        rts

        inc     $10EE
        .byte   $12
        brk
        bit     $AA
        brk
        tax
        eor     $03AA
        brk
        brk
        brk
        brk
        .byte   $04
        brk
        .byte   $04
        .byte   $F3
        ora     $F2
        ora     $E6
        brk
        cpx     $00
        .byte   $E3
        ora     $E8
        ora     $F7
        asl     $00
        brk
        plp
        .byte   $D4
        .byte   $F2
        sbc     ($EE,x)
        .byte   $F3
        cpx     $F4E1
        sbc     $A0
        .byte   $F3
        .byte   $F4
        .byte   $F2
        sbc     #$EE
        .byte   $E7
        .byte   $F3
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
        inc     $A9E7
        .byte   $E3
        jsr     xgetparm_ch
        bcs     LAA64
        sty     $E0
        sta     $E1
        ldy     #$00
        lda     ($E0),y
        beq     LAA64
        iny
        lda     ($E0),y
        and     #$7F
        .byte   $2C
LAA64:  lda     #$5E
        sta     $EB
        lda     #$E8
        jsr     xgetparm_ch
        bcs     LAA7F
        sty     $E0
        sta     $E1
        ldy     #$00
        lda     ($E0),y
        beq     LAA7F
        iny
        lda     ($E0),y
        and     #$7F
        .byte   $2C
LAA7F:  lda     #$7E
        sta     $EA
        lda     #$F7
        jsr     xgetparm_ch
        bcc     LAA8C
        ldy     #$00
LAA8C:  sty     $EE
        lda     #$00
        sta     $EF
        lda     #$F3
        jsr     xgetparm_ch
        bcs     LAABA
        sty     $E0
        sta     $E1
        ldy     #$00
        lda     ($E0),y
        beq     LAABA
        cmp     #$40
        bcs     LAABA
        tay
        iny
        sty     $ED
        ldy     #$01
        ldx     #$01
LAAAF:  jsr     LADE0
        sta     LAE3F,x
        bcs     LAABD
        inx
        bpl     LAAAF
LAABA:  jmp     LAF18

LAABD:  stx     LAE3F
        lda     #$F2
        jsr     xgetparm_ch
        ldx     #$00
        bcs     LAAED
        sty     $E0
        sta     $E1
        ldy     #$00
        lda     ($E0),y
        beq     LAAED
        cmp     #$40
        bcs     LAAEA
        tay
        iny
        sty     $ED
        ldy     #$01
        ldx     #$01
LAADF:  jsr     LADE0
        sta     LAE7F,x
        bcs     LAAED
        inx
        bpl     LAADF
LAAEA:  jmp     LAF18

LAAED:  stx     LAE7F
        lda     #$00
        jsr     xgetparm_n
        sty     $E0
        sty     LAEC0
        sty     LAEEA
        sty     LAEE4
        sty     LAF16
        sta     $E1
        sta     LAEC1
        sta     LAEEB
        sta     LAEE5
        sta     LAF17
        lda     #$01
        jsr     xgetparm_n
        sty     $E2
        sty     LAED2
        sty     LAEE7
        sty     LAEF0
        sty     LAF06
        sty     LAF14
        sta     $E3
        sta     LAED3
        sta     LAEE8
        sta     LAEF1
        sta     LAF07
        sta     LAF15
        ldy     #$00
        lda     ($E2),y
        beq     LAB4F
        tax
LAB3F:  lda     ($E0),y
        cmp     ($E2),y
        bne     LAB4C
        iny
        dex
        bpl     LAB3F
        jmp     LAF18

LAB4C:  lda     #$80
        .byte   $2C
LAB4F:  lda     #$00
        sta     $EC
        jsr     LBF00
        cpy     $BF
        ldx     $0390
        jmp     xProDOS_err

        jsr     LBF00
        iny
        sbc     #$AE
        bcc     LAB69
        jmp     xProDOS_err

LAB69:  lda     LAEEE
        sta     LAEF6
        bit     $EC
        bmi     LAB76
        jmp     LAC00

LAB76:  jsr     LBF00
        cpy     $D1
        ldx     $0790
        cmp     #$46
        beq     LABCE
        jmp     xProDOS_err

        lda     #$E6
        jsr     xgetparm_ch
        bcc     LABC3
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
        ldy     LAEF0
        lda     LAEF1
        jsr     xprint_path
        lda     #$EE
        jsr     xyesno2
        php
        lda     #$FF
        jsr     xredirect
        plp
        bne     LABC3
        lda     #$86
        jmp     xProDOS_err

LABC3:  jsr     LBF00
        cmp     ($E6,x)
        ldx     $0390
        jmp     xProDOS_err

LABCE:  ldy     #$04
LABD0:  lda     LAEC2,y
        sta     LAF08,y
        dey
        bpl     LABD0
        ldy     #$03
LABDB:  lda     LAECD,y
        sta     LAF0D,y
        dey
        bpl     LABDB
        jsr     LBF00
        cpy     #$05
        .byte   $AF
        bcc     LABEF
        jmp     xProDOS_err

LABEF:  jsr     LBF00
        iny
        .byte   $EF
        ldx     $0390
        jmp     xProDOS_err

        lda     LAEF4
        sta     LAEFE
LAC00:  ldx     #$CA
        jsr     xmmgr
        sty     LAEF9
        sta     LAEFA
        ldx     #$C4
        jsr     xmmgr
        sty     $E2
        sty     LAEF7
        sta     $E3
        sta     LAEF8
        lda     #$00
        sta     $ED
        ldx     #$00
LAC20:  jsr     LBF00
        dex
        sbc     $AE,x
        bcc     LAC32
        cmp     #$4C
        bne     LAC2F
        jmp     LADB3

LAC2F:  jmp     xProDOS_err

LAC32:  lda     LAEF7
        clc
        adc     LAEFB
        sta     $E4
        lda     LAEF8
        adc     LAEFC
        sta     $E5
        lda     $E2
        sta     $E0
        sta     $E6
        sta     LAEFF
        lda     $E3
        sta     $E1
        sta     $E7
        sta     LAF00
        lda     $E6
        bne     LAC5B
        dec     $E7
LAC5B:  dec     $E6
LAC5D:  ldy     #$00
        lda     ($E0),y
        cmp     LAE40,x
        beq     LAC9E
        bit     $ED
        bpl     LAC94
        lda     #$40
        sta     LAEFF
        lda     #$AE
        sta     LAF00
        lda     $ED
        and     #$7F
        sta     LAF01
        lda     #$00
        sta     LAF02
        sta     $ED
        jsr     LAD31
        bcc     LAC8A
        jmp     xProDOS_err

LAC8A:  lda     $E2
        sta     LAEFF
        lda     $E3
        sta     LAF00
LAC94:  lda     $E0
        sta     $E6
        lda     $E1
        sta     $E7
        ldx     #$FF
LAC9E:  inx
        cpx     LAE3F
        beq     LACC8
        inc     $E0
        bne     LACAA
        inc     $E1
LACAA:  lda     $E1
        cmp     $E5
        bcc     LAC5D
        lda     $E0
        cmp     $E4
        bcc     LAC5D
        txa
        beq     LACBB
        ora     #$80
LACBB:  sta     $ED
        jsr     LAD0E
        bcc     LACC5
        jmp     xProDOS_err

LACC5:  jmp     LAC20

LACC8:  jsr     LAD0E
        bcc     LACD0
        jmp     xProDOS_err

LACD0:  lda     LAE7F
        beq     LACEF
        sta     LAF01
        lda     #$00
        sta     LAF02
        lda     #$80
        sta     LAEFF
        lda     #$AE
        sta     LAF00
        jsr     LAD31
        bcc     LACEF
        jmp     xProDOS_err

LACEF:  lda     $E0
        sta     $E6
        lda     $E1
        sta     $E7
        inc     $E0
        bne     LACFD
        inc     $E1
LACFD:  lda     $E0
        sta     LAEFF
        lda     $E1
        sta     LAF00
        ldx     #$00
        stx     $ED
        jmp     LACAA

LAD0E:  lda     $E6
        sec
        sbc     LAEFF
        sta     LAF01
        lda     $E7
        sbc     LAF00
        sta     LAF02
        inc     LAF01
        bne     LAD27
        inc     LAF02
LAD27:  lda     LAF01
        ora     LAF02
        bne     LAD31
        clc
        rts

LAD31:  bit     $EC
        bpl     LAD3C
        jsr     LBF00
        .byte   $CB
        sbc     $60AE,x
LAD3C:  stx     LADB0
        lda     LAEFF
        sta     $E8
        lda     LAF00
        sta     $E9
LAD49:  ldy     #$00
        lda     ($E8),y
        ora     #$80
        cmp     #$A1
        bcs     LAD6F
        cmp     #$8D
        beq     LAD84
        cmp     #$89
        beq     LAD6F
        cmp     #$A0
        bne     LAD6D
        lda     $EE
        beq     LAD6A
        sec
        sbc     $EF
        cmp     #$0A
        bcc     LAD84
LAD6A:  lda     #$A0
        .byte   $2C
LAD6D:  lda     #$AE
LAD6F:  jsr     LFDED
        inc     $EF
        lda     $EF
        ldx     $EE
        beq     LAD7E
        cmp     $EE
        beq     LAD84
LAD7E:  cmp     #$50
        bne     LAD90
        beq     LAD87
LAD84:  jsr     LFD8E
LAD87:  jsr     xcheck_wait
        bcs     LADB1
        lda     #$00
        sta     $EF
LAD90:  inc     $E8
        bne     LAD96
        inc     $E9
LAD96:  lda     LAF01
        bne     LAD9E
        dec     LAF02
LAD9E:  dec     LAF01
        lda     LAF01
        bne     LAD49
        lda     LAF02
        bne     LAD49
        ldx     LADB0
        clc
        rts

LADB0:  brk
LADB1:  pla
        pla
LADB3:  jsr     LBF00
        cpy     LAF11
        bcc     LADBE
        jmp     xProDOS_err

LADBE:  bit     $EC
        bmi     LADDF
        lda     #$E4
        jsr     xgetparm_ch
        bcs     LADDF
        jsr     LBF00
        cmp     ($E3,x)
        ldx     $0390
        jmp     xProDOS_err

        jsr     LBF00
        .byte   $C2
        .byte   $13
        .byte   $AF
        bcc     LADDF
        jmp     xProDOS_err

LADDF:  rts

LADE0:  lda     #$00
        sta     LAE3D
        sta     LAE3E
LADE8:  lda     ($E0),y
        and     #$7F
        cmp     $EA
        bne     LADFA
        bit     LAE3D
        bmi     LAE08
        dec     LAE3D
        bmi     LAE37
LADFA:  cmp     $EB
        bne     LAE08
        bit     LAE3E
        bmi     LAE08
        dec     LAE3E
        bmi     LAE37
LAE08:  bit     LAE3E
        bpl     LAE2C
        cmp     #$60
        bcc     LAE13
        sbc     #$20
LAE13:  cmp     #$3F
        beq     LAE24
        cmp     #$3E
        beq     LAE27
        cmp     #$3D
        beq     LAE2A
        bcc     LAE33
        and     #$3F
        .byte   $2C
LAE24:  lda     #$7F
        .byte   $2C
LAE27:  lda     #$5E
        .byte   $2C
LAE2A:  lda     #$7E
LAE2C:  bit     LAE3D
        bpl     LAE33
        ora     #$80
LAE33:  iny
        cpy     $ED
        rts

LAE37:  iny
        cpy     $ED
        bcc     LADE8
        rts

LAE3D:  brk
LAE3E:  brk
LAE3F:  brk
LAE40:  brk
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
        brk
        brk
LAE7F:  brk
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
        brk
        brk
        brk
        asl     a
LAEC0:  brk
LAEC1:  brk
LAEC2:  brk
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
LAECD:  brk
        brk
        brk
        brk
        asl     a
LAED2:  brk
LAED3:  brk
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
LAEE4:  brk
LAEE5:  brk
        .byte   $01
LAEE7:  brk
LAEE8:  brk
        .byte   $03
LAEEA:  brk
LAEEB:  brk
        brk
        php
LAEEE:  brk
        .byte   $03
LAEF0:  brk
LAEF1:  brk
        brk
        .byte   $0C
LAEF4:  brk
        .byte   $04
LAEF6:  brk
LAEF7:  brk
LAEF8:  brk
LAEF9:  brk
LAEFA:  brk
LAEFB:  brk
LAEFC:  brk
        .byte   $04
LAEFE:  brk
LAEFF:  brk
LAF00:  brk
LAF01:  brk
LAF02:  brk
        brk
        brk
        .byte   $07
LAF06:  brk
LAF07:  brk
LAF08:  brk
        brk
        brk
        brk
        brk
LAF0D:  brk
        brk
        brk
        brk
LAF11:  ora     ($00,x)
        .byte   $02
LAF14:  brk
LAF15:  brk
LAF16:  brk
LAF17:  brk
LAF18:  jsr     xmess
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
