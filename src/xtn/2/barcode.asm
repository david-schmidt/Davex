	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

; Print barcode (CODEBAR format) of a number (to an Epson FX-80)

.segment	"CODE_A000"

LFD8E           := $FD8E
LFDED           := $FDED
LFE95           := $FE95
        rts

        inc     $11EE
        ora     ($00),y
        .byte   $1A
        ldy     #$00
        ldy     #$51
        ldy     #$00
        brk
        brk
        brk
        brk
        ora     $EC
        asl     $E4
        brk
        .byte   $F3
        brk
        brk
        brk
        rol     $E2,x
        sbc     ($F2,x)
        .byte   $E3
        .byte   $EF
        cpx     $E5
        ldy     #$AD
        lda     $D0A0
        .byte   $F2
        sbc     #$EE
        .byte   $F4
        ldy     #$E2
        sbc     ($F2,x)
        .byte   $E3
        .byte   $EF
        cpx     $E5
        ldy     #$A8
        .byte   $C3
        .byte   $CF
        cpy     $C1
        .byte   $C2
        cmp     ($D2,x)
        lda     #$A0
        .byte   $EF
        inc     $A0
        sbc     ($A0,x)
        inc     $EDF5
        .byte   $E2
        sbc     $F2
        ldy     #$A8
        dec     $D8
        lda     $B0B8
        lda     #$84
        cpx     $ED85
        jsr     LA42B
        bcc     LA05B
        rts

LA05B:  ldy     #$06
        sty     $F6
        lda     #$EC
        jsr     xgetparm_ch
        bcs     LA09E
        sty     $F6
        cpy     #$27
        bcc     LA09E
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
        ldy     #$ED
        sbc     ($F8,x)
        sbc     #$ED
        sbc     $ED,x
        ldy     #$EC
        sbc     $E6
        .byte   $F4
        ldy     #$ED
        sbc     ($F2,x)
        .byte   $E7
        sbc     #$EE
        ldy     #$E9
        .byte   $F3
        ldy     #$B3
        clv
        ldy     #$E3
        inx
        sbc     ($F2,x)
        .byte   $F3
        sta     $4C00
        pha
LA09D:  .byte   $B0
LA09E:  lda     $EC
        sta     $E8
        lda     $ED
        sta     $E9
        .byte   $B2
        inx
        sta     $EE
        beq     LA0E5
        cmp     #$13
        bcc     LA0F0
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
        ldy     #$ED
        sbc     ($F8,x)
        sbc     #$ED
        sbc     $ED,x
        ldy     #$E2
        sbc     ($F2,x)
        .byte   $E3
        .byte   $EF
        cpx     $E5
        ldy     #$EC
        sbc     $EE
        .byte   $E7
        .byte   $F4
        inx
        ldy     #$E9
        .byte   $F3
        ldy     #$B1
        clv
        ldy     #$E3
        inx
        sbc     ($F2,x)
        .byte   $F3
        sta     $4C00
        pha
        .byte   $B0
LA0E5:  ldy     #$1A
        lda     #$A0
        jsr     LA463
        jsr     LFD8E
        rts

LA0F0:  lda     #$06
        sta     $E6
        lda     #$A3
        sta     $E7
        .byte   $B2
        inc     $85
        beq     LA09D
        brk
LA0FE:  iny
        lda     ($E8),y
        ora     #$80
        sta     ($E8),y
        sty     $F1
        ldy     #$00
LA109:  iny
        cmp     ($E6),y
        beq     LA136
        cpy     $F0
        bne     LA109
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
        ldy     #$E9
        inc     $E1F6
        cpx     $E4E9
        ldy     #$E3
        inx
        sbc     ($F2,x)
        sbc     ($E3,x)
        .byte   $F4
        sbc     $F2
        sta     $4C00
        pha
        .byte   $B0
LA136:  ldy     $F1
        cpy     $EE
        bne     LA0FE
        lda     #$01
        sta     $F7
        lda     #$03
        sta     $F4
        lda     #$06
        sta     $F8
        lda     #$04
        sta     $F5
        lda     #$E4
        jsr     xgetparm_ch
        bcs     LA163
        lda     #$02
        sta     $F7
        lda     #$04
        sta     $F4
        lda     #$01
        sta     $F8
        lda     #$0A
LA161:  sta     $F5
LA163:  lda     #$00
        sta     $F2
        .byte   $1A
        sta     $F3
        lda     #$F3
        jsr     xgetparm_ch
        bcs     LA179
        inc     $F2
        inc     $F2
        inc     $F3
        inc     $F3
LA179:  ldx     #$CC
        jsr     xmmgr
        lda     #$01
        ldx     #$C8
        jsr     xmmgr
        bcc     LA1A7
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

LA1A7:  sta     $E2
        sta     $E4
        .byte   $64
        .byte   $E3
        .byte   $64
        sbc     $A9
        sbc     $E685
        lda     #$A2
        sta     $E7
        .byte   $B2
        inc     $85
        beq     LA161
        .byte   $F2
        jsr     LA23B
        ldy     #$00
LA1C2:  iny
        lda     ($E8),y
        sty     $EF
        jsr     LA24A
        ldy     $EF
        cpy     $EE
        bne     LA1C2
        lda     $F3
        jsr     LA23B
        lda     $36
        pha
        lda     $37
        pha
        lda     $B300
        jsr     LFE95
        ldy     #$17
        lda     #$A4
        jsr     LA463
        jsr     LFD8E
LA1EB:  ldy     #$24
        lda     #$A4
        jsr     LA463
        jsr     LA282
        jsr     LFD8E
        ldy     #$20
        lda     #$A4
        jsr     LA463
        jsr     LA282
        jsr     LFD8E
        dec     $F4
        bne     LA1EB
        jsr     LFD8E
        lda     $F5
        clc
        adc     $F6
        tay
        jsr     LA47D
        ldy     $EC
        lda     $ED
        jsr     LA463
        ldy     #$28
        lda     #$A4
        jsr     LA463
        jsr     LFD8E
        pla
        sta     $37
        pla
        sta     $36
        ldx     #$CC
        jmp     xmmgr

LA231:  lda     #$00
        jmp     LA279

LA236:  lda     #$FF
        jmp     LA279

LA23B:  asl     a
        tax
        lda     LA2E5,x
        sta     $EA
        inx
        lda     LA2E5,x
        sta     $EB
        .byte   $80
        .byte   $16
LA24A:  ldy     #$00
LA24C:  iny
        cmp     ($E6),y
        bne     LA24C
        dey
        tya
        asl     a
        tax
        lda     LA2B5,x
        sta     $EA
        inx
        lda     LA2B5,x
        sta     $EB
        .byte   $B2
        nop
        tax
        jsr     LA231
        ldy     #$00
LA268:  iny
        lda     ($EA),y
        beq     LA272
        jsr     LA236
        .byte   $80
        .byte   $03
LA272:  jsr     LA231
        dex
        bne     LA268
        rts

LA279:  .byte   $5A
        ldy     $E5
        sta     ($E3),y
        inc     $E5
        .byte   $7A
        rts

LA282:  ldy     $F6
        jsr     LA47D
        ldy     #$1D
        lda     #$A4
        jsr     LA463
        lda     $F8
        jsr     LFDED
        lda     $F7
        ldy     $E5
        jsr     LA48C
        pha
        tya
        jsr     LFDED
        pla
        .byte   $20
LA2A1:  sbc     $A0FD
        brk
LA2A5:  lda     ($E3),y
        ldx     $F7
LA2A9:  jsr     LFDED
        dex
        bne     LA2A9
        iny
        cpy     $E5
        bne     LA2A5
        rts

LA2B5:  .byte   $17
        .byte   $A3
        .byte   $23
LA2B8:  .byte   $A3
        .byte   $2F
        .byte   $A3
        .byte   $3B
        .byte   $A3
        .byte   $47
        .byte   $A3
        .byte   $53
        .byte   $A3
        .byte   $5F
        .byte   $A3
        .byte   $6B
        .byte   $A3
        .byte   $77
        .byte   $A3
        .byte   $83
        .byte   $A3
        .byte   $8F
        .byte   $A3
        .byte   $9B
        .byte   $A3
        .byte   $A7
        .byte   $A3
        lda     $A3,x
        .byte   $C3
        .byte   $A3
        cmp     ($A3),y
        .byte   $DF
        .byte   $A3
        sbc     $FBA3
        .byte   $A3
        ora     #$A4
        .byte   $DF
        .byte   $A3
        sbc     $FBA3
        .byte   $A3
        ora     #$A4
LA2E5:  .byte   $DF
        .byte   $A3
        sbc     $DFA3
        .byte   $A3
        .byte   $DF
        .byte   $A3
        clc
        bcs     LA2A1
        .byte   $B2
        .byte   $B3
        ldy     $B5,x
        ldx     $B7,y
        clv
        lda     LA4AD,y
        tsx
        .byte   $AF
        ldx     $C1AB
        .byte   $C2
        .byte   $C3
        cpy     $D4
        dec     $C5AA
        bpl     LA2B8
        lda     ($B2),y
        .byte   $B3
        ldy     $B5,x
        ldx     $B7,y
        clv
        lda     LA4AD,y
        tsx
        .byte   $AF
        ldx     $0BAB
        ora     ($00,x)
        ora     ($00,x)
        ora     ($00,x)
        brk
        brk
        ora     ($01,x)
        ora     ($0B,x)
        ora     ($00,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($00,x)
        brk
        brk
        ora     ($0B,x)
        ora     ($00,x)
        ora     ($00,x)
        brk
        brk
        ora     ($00,x)
        ora     ($01,x)
        ora     ($0B,x)
        ora     ($01,x)
        ora     ($00,x)
        brk
        brk
        ora     ($00,x)
        ora     ($00,x)
        ora     ($0B,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($00,x)
        brk
        brk
        ora     ($0B,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($00,x)
        ora     ($00,x)
        brk
        brk
        ora     ($0B,x)
        ora     ($00,x)
        brk
        brk
        ora     ($00,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($0B,x)
        ora     ($00,x)
        brk
        brk
        ora     ($00,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($0B,x)
        ora     ($00,x)
        brk
        brk
        ora     ($01,x)
        ora     ($00,x)
        ora     ($00,x)
        ora     ($0B,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($00,x)
        brk
        brk
        ora     ($00,x)
        ora     ($0B,x)
        ora     ($00,x)
        ora     ($00,x)
        brk
        brk
        ora     ($01,x)
        ora     ($00,x)
        ora     ($0B,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($00,x)
        brk
        brk
        ora     ($00,x)
        ora     ($0D,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($0D,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($0D,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($0D,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($0D,x)
        ora     ($00,x)
        ora     ($01,x)
        ora     ($00,x)
        brk
        brk
        ora     ($00,x)
        brk
        brk
        ora     ($0D,x)
        ora     ($00,x)
        brk
        brk
        ora     ($00,x)
        brk
        brk
        ora     ($00,x)
        ora     ($01,x)
        ora     ($0D,x)
        ora     ($00,x)
        ora     ($00,x)
        brk
        brk
        ora     ($00,x)
        brk
        brk
        ora     ($01,x)
LA408:  ora     ($0D,x)
        ora     ($00,x)
        ora     ($00,x)
        brk
        brk
        ora     ($01,x)
        ora     ($00,x)
        brk
        brk
        ora     ($05,x)
        .byte   $89
        iny
        .byte   $9B
        lda     ($C0,x)
        .byte   $02
        .byte   $9B
        tax
        .byte   $03
        .byte   $9B
        .byte   $B3
        asl     $03,x
        .byte   $9B
        .byte   $B3
        ora     ($02,x)
        .byte   $9B
        .byte   $B2
LA42B:  lda     $FBB3
        cmp     #$38
        beq     LA440
        cmp     #$EA
        beq     LA440
        lda     $FBC0
        cmp     #$EA
        beq     LA440
        clc
        bne     LA462
LA440:  jsr     xbell
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
        ldy     #$B6
        lda     $C3,x
        bcs     LA408
        ldy     #$F2
        sbc     $F1
        sbc     $E9,x
        .byte   $F2
        sbc     $E4
        sta     $3800
LA462:  rts

LA463:  sta     $E1
        sty     $E0
        txa
        pha
        ldy     #$00
        lda     ($E0),y
        beq     LA47A
        tax
        iny
LA471:  lda     ($E0),y
        jsr     LFDED
        iny
        dex
        bne     LA471
LA47A:  pla
        tax
        rts

LA47D:  cpy     #$00
        beq     LA48B
        pha
        lda     #$A0
LA484:  jsr     LFDED
        dey
        bne     LA484
        pla
LA48B:  rts

LA48C:  .byte   $DA
        sta     LA4BB
        sty     LA4BC
        lda     #$00
        sta     LA4BD
        sta     LA4BE
        ldx     #$08
LA49D:  asl     a
        rol     LA4BE
        asl     LA4BC
        bcc     LA4AF
        clc
        adc     LA4BB
        bcc     LA4AF
        .byte   $EE
LA4AD:  .byte   $BE
        .byte   $A4
LA4AF:  dex
        bne     LA49D
        sta     LA4BD
        tay
        lda     LA4BE
        .byte   $FA
        rts

LA4BB:  .byte   $A0
LA4BC:  .byte   $A0
LA4BD:  .byte   $C9
LA4BE:  tax
