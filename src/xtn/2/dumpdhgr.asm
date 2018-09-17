	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_A700"
.org $a700

L0208           := $0208
L2824           := $2824
LA6CA           := $A6CA
LBF00           := $BF00
LC311           := $C311
LE185           := $E185
LEEC4           := $EEC4
LFD8E           := $FD8E
LFDED           := $FDED
LFE95           := $FE95
	rts
	.addr $eeee
	.byte $12, $11
	.byte $40
        clc
        .byte   $A7
        brk
        .byte   $A7
        .byte   $5C
        .byte   $A7
        brk
        brk
        brk
        brk
        brk
        .byte   $04
        inc     $E900
        ora     $00
        brk
        .byte   $43
        cpx     $F5
        sbc     $E7F0
        inx
        .byte   $E7, $F2, $a0, $ad, $ad, $a0, $c4, $f5, $ed, $f0, $a0
        sbc     ($A0,x)
        cpx     $EF
        sbc     $E2,x
        cpx     $A0E5
        inx
        sbc     #$F2
        sbc     $F3
        ldy     #$F0
        sbc     #$E3
        .byte   $F4
        sbc     $F2,x
        sbc     $A0
        .byte   $F4
        .byte   $EF
        ldy     #$F0
        .byte   $F2
        sbc     #$EE
        .byte   $F4
        sbc     $F2
        ldy     #$AF
        ldy     #$E2
        sbc     $CAA0,y
        sbc     $E6
        inc     $A0
        iny
        sbc     ($EE,x)
        .byte   $F3
        sbc     $EE
        sty     LAA0C
        sta     LAA0D
        sty     LA9FA
        sta     LA9FB
        jsr     LBF00
        .byte $c4
        .addr $A9F9
LA76E:  bcc     $A773
        jmp     xProDOS_err
        lda     LA9FD
        cmp     #$06
        beq     LA780
        cmp     #$08
        beq     LA780
        .byte   $80
        .byte   $07
LA780:  lda     LAA01
        cmp     #$21
        beq     LA7B4
        jsr     xmess
        tax
        tax
        tax
        ldy     #$E5
        .byte   $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$EE
        .byte   $EF
        .byte   $F4
        ldy     #$E1
        ldy     #$E4
        .byte   $EF
        sbc     $E2,x
        cpx     $ADE5
        inx
        sbc     #$F2
        sbc     $F3
        ldy     #$F0
        sbc     #$E3
        .byte   $F4
        sbc     $F2,x
        sbc     $8D
        brk
        jmp     xerr

LA7B4:  .byte   $64
        sbc     #$C6
        sbc     #$A9
        inc     a:$20
        bcs     LA76E
        .byte   $02
        .byte   $64
        sbc     #$A9
        .byte   $DA
        sta     $E6
        lda     #$A9
        sta     $E7
        lda     #$E9
        jsr     xgetparm_ch
        bcs     LA7D4
        sty     $E6
        sta     $E7
LA7D4:  clc
        ldx     #$CC
        jsr     xmmgr
        ldx     #$C8
        lda     #$20
        jsr     xmmgr
        bcc     LA803
        jsr     xmess
        tax
        tax
        tax
        ldy     #$E5
        .byte   $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$EF
        sbc     $F4,x
        ldy     #$EF
        inc     $A0
        sbc     $EDE5
        .byte   $EF
        .byte   $F2
        sbc     $8D,y
        jmp     xerr

LA803:  sta     $E8
        sta     LAA14
        .byte   $9C
        .byte   $13
        tax
        jsr     LBF00
        iny
        .byte   $0B
        tax
        bcc     LA816
        jmp     xProDOS_err

LA816:  lda     LAA10
        sta     LAA12
        sta     LAA1A
        jsr     LBF00
        dex
        ora     ($AA),y
        bcc     LA82A
        jmp     xProDOS_err

LA82A:  .byte   $64
        .byte   $3C
        lda     $E8
        sta     $3D
        .byte   $64
        .byte   $42
        lda     #$20
        sta     $43
        clc
        adc     $E8
        sta     $3F
        lda     #$F8
        sta     $3E
        sec
        sta     $C000
        jsr     LC311
        jsr     LBF00
        dex
        ora     ($AA),y
        bcc     LA851
        jmp     xProDOS_err

LA851:  jsr     LBF00
        cpy     LAA19
        bcc     LA85C
        jmp     xProDOS_err

LA85C:  jsr     LA976
        lda     $C052
        lda     $C050
        lda     $C057
        lda     $C05E
        sta     $C001
        lda     $36
        pha
        lda     $37
        pha
        lda     $B300
        jsr     LFE95
        ldy     $E6
        lda     $E7
        jsr     LA9DD
        jsr     LAA1B
        .byte   $9B
        .byte   $B3
        clc
        sta     $A000
        brk
LA88B:  sty     $EE
        jsr     LAA1B
        ldy     #$A0
        ldy     #$A0
        ldy     #$9B
        .byte   $DA
        bcc     LA89F
        brk
        .byte   $64
        sbc     $EC64
LA89E:  .byte   $64
LA89F:  .byte   $EF
        sta     $C055
LA8A3:  .byte   $64
        .byte   $F0
LA8A5:  .byte   $64
        .byte   $F2
        .byte   $64
        .byte   $F1
LA8A9:  lda     $EE
        asl     a
        asl     a
        clc
        adc     $F1
        tax
        lda     LAA40,x
        sta     $E0
        lda     LAB00,x
        sta     $E1
        ldy     $ED
        lda     ($E0),y
        eor     $E9
        jsr     LA962
        ldx     $F0
        lda     LA9D2,x
        beq     LA8D5
        ldx     $F1
        lda     LA9CE,x
        clc
        adc     $F2
        sta     $F2
LA8D5:  inc     $F1
        lda     $F1
        cmp     #$04
        bne     LA8A9
        jsr     LA92C
        inc     $F0
        lda     $F0
        cmp     #$07
        bne     LA8A5
        lda     $EF
        bmi     LA8F3
        sta     $C054
        dec     $EF
        bmi     LA8A3
LA8F3:  inc     $ED
        lda     $ED
        cmp     #$28
        bne     LA89E
        jsr     LFD8E
        ldx     #$04
        lda     $EE
        asl     a
        asl     a
        jsr     LA99F
        ldy     $EE
        iny
LA90A:  cpy     #$30
        beq     LA911
        jmp     LA88B

LA911:  jsr     LAA1B
        .byte   $9B
        .byte   $B2
        .byte   $0C
        brk
        pla
        sta     $37
        pla
        sta     $36
        ldx     #$C0
        lda     #$00
        jsr     LA99F
        lda     $C051
        jsr     LA976
        rts

LA92C:  lda     $C01C
        sta     $EB
        bpl     LA936
        lda     $C054
LA936:  inc     $EC
        lda     $EC
        lsr     a
        bcc     LA94D
        lda     $F2
        lsr     a
        jsr     LFDED
        asl     a
        jsr     LFDED
        lsr     a
        jsr     LFDED
        .byte   $80
        .byte   $0D
LA94D:  lda     $F2
        jsr     LFDED
        lsr     a
        jsr     LFDED
        asl     a
        jsr     LFDED
        lda     $EB
        bpl     LA961
        lda     $C055
LA961:  rts

LA962:  ldy     #$08
LA964:  dey
        asl     a
        pha
        lda     #$01
        bcs     LA96D
        lda     #$00
LA96D:  sta     LA9D2,y
        pla
        cpy     #$00
        bne     LA964
        rts

LA976:  sta     $C000
        .byte   $64
        cpx     #$A9
        jsr     LE185
        .byte   $64
        cpx     $A5
        inx
        sta     $E5
        ldy     #$00
LA987:  lda     ($E0),y
        pha
        lda     ($E4),y
        sta     ($E0),y
        pla
        sta     ($E4),y
        iny
        bne     LA987
        inc     $E5
        inc     $E1
        lda     $E1
        cmp     #$40
        bne     LA987
        rts

LA99F:  sta     $C001
        stx     $EA
        tax
LA9A5:  ldy     #$00
        lda     LAA40,x
        sta     $E0
        lda     LAB00,x
        sta     $E1
LA9B1:  sta     $C055
        lda     ($E0),y
        eor     #$FF
        sta     ($E0),y
        sta     $C054
        lda     ($E0),y
        eor     #$FF
        sta     ($E0),y
        iny
        cpy     #$28
        bne     LA9B1
        inx
        dec     $EA
        bne     LA9A5
        rts

LA9CE:  .byte   $80
        jsr     L0208
LA9D2:  ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $02
        .byte   $89
        iny
LA9DD:  sty     $E0
        sta     $E1
        txa
        pha
        ldy     #$00
        lda     ($E0),y
        beq     LA9F6
        tax
        iny
LA9EB:  lda     ($E0),y
        ora     #$80
        jsr     LFDED
        iny
        dex
        bne     LA9EB
LA9F6:  pla
        tax
        rts

        asl     a
LA9FA:  .byte   $B9
LA9FB:  ldy     #$FF
LA9FD:  beq     LA99F
        ldy     #$AB
LAA01:  ldx     $A0,y
        ldy     #$A0
        ldy     #$A0
        ldy     #$E3
        ldy     #$B0
        .byte   $03
LAA0C:  .byte   $A0
LAA0D:  ldy     #$00
        php
LAA10:  ldy     #$04
LAA12:  ldy     #$B3
LAA14:  ldy     #$00
        jsr     LEEC4
LAA19:  .byte   $01
LAA1A:  .byte   $B3
LAA1B:  pla
        sta     $E2
        pla
        sta     $E3
        ldy     #$01
LAA23:  lda     ($E2),y
        beq     LAA31
        jsr     LFDED
        iny
        bne     LAA23
        inc     $E3
        bne     LAA23
LAA31:  tya
        clc
        adc     $E2
        sta     $E2
        lda     #$00
        adc     $E3
        pha
        lda     $E2
        pha
        rts

LAA40:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
        tay
        tay
        tay
        tay
        tay
        tay
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
LAA9A:  tay
        tay
LAA9C:  tay
        tay
LAA9E:  tay
        tay
LAAA0:  plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
LAAAA:  tay
        tay
LAAAC:  tay
        tay
LAAAE:  tay
        tay
LAAB0:  plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
LAABA:  tay
        tay
LAABC:  tay
        tay
LAABE:  tay
        tay
LAAC0:  bvc     LAB12
        bvc     LAB14
        bvc     LAB16
        bvc     LAB18
        bne     LAA9A
LAACA:  bne     LAA9C
LAACC:  bne     LAA9E
LAACE:  bne     LAAA0
LAAD0:  bvc     LAB22
        bvc     LAB24
        bvc     LAB26
        bvc     LAB28
        bne     LAAAA
        bne     LAAAC
        bne     LAAAE
        bne     LAAB0
        bvc     LAB32
        bvc     LAB34
        bvc     LAB36
        bvc     LAB38
        bne     LAABA
        bne     LAABC
        bne     LAABE
        bne     LAAC0
        bvc     LAB42
        bvc     LAB44
        bvc     LAB46
        bvc     LAB48
        bne     LAACA
        bne     LAACC
        bne     LAACE
        bne     LAAD0
LAB00:  jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        and     ($25,x)
LAB12:  and     #$2D
LAB14:  and     ($35),y
LAB16:  .byte   $39
        .byte   $3D
LAB18:  and     ($25,x)
        and     #$2D
        and     ($35),y
        and     $223D,y
        .byte   $26
LAB22:  rol     a
        .byte   $2E
LAB24:  .byte   $32
        .byte   $36
LAB26:  .byte   $3A
        .byte   $3E
LAB28:  .byte   $22
        rol     $2A
        rol     $3632
        .byte   $3A
        rol     $2723,x
LAB32:  .byte   $2B
        .byte   $2F
LAB34:  .byte   $33
        .byte   $37
LAB36:  .byte   $3B
        .byte   $3F
LAB38:  .byte   $23
        .byte   $27
        .byte   $2B
        .byte   $2F
        .byte   $33
        .byte   $37
        .byte   $3B
        .byte   $3F
        .byte   $20
        .byte   $24
LAB42:  plp
        .byte   $2C
LAB44:  bmi     LAB7A
LAB46:  sec
        .byte   $3C
LAB48:  jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        and     ($25,x)
        and     #$2D
        and     ($35),y
        and     $213D,y
        and     $29
        and     $3531
        and     $223D,y
        rol     $2A
        rol     $3632
        .byte   $3A
        rol     $2622,x
        rol     a
        rol     $3632
        .byte   $3A
        rol     $2723,x
        .byte   $2B
        .byte   $2F
        .byte   $33
        .byte   $37
        .byte   $3B
        .byte   $3F
        .byte   $23
        .byte   $27
LAB7A:  .byte   $2B
        .byte   $2F
        .byte   $33
        .byte   $37
        .byte   $3B
        .byte   $3F
        jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        and     ($25,x)
        and     #$2D
        and     ($35),y
        and     $213D,y
        and     $29
        and     $3531
        and     $223D,y
        rol     $2A
        rol     $3632
        .byte   $3A
        rol     $2622,x
        rol     a
        rol     $3632
        .byte   $3A
        rol     $2723,x
        .byte   $2B
        .byte   $2F
        .byte   $33
        .byte   $37
        .byte   $3B
        .byte   $3F
        .byte   $23
        .byte   $27
        .byte   $2B
        .byte   $2F
        .byte   $33
        .byte   $37
        .byte   $3B
        .byte   $3F
