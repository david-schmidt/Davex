	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_A000"
.org	$a000

L7365           := $7365
L9FD3           := $9FD3
L9FE7           := $9FE7
LBF00           := $BF00
LFD8E           := $FD8E
LFDED           := $FDED
        rts

        inc     $10EE
        ora     ($00),y
        .byte   $1A
        ldy     #$00
        ldy     #$41
        ldy     #$00
        brk
        brk
        brk
        brk
        .byte   $03
        .byte   $E3
        .byte   $03
        beq     LA019
        .byte   $F3
        brk
        brk
LA019:  brk
        rol     $E6
        cpx     $F5
        sbc     LA0F0
        lda     LA0AD
        dec     $E9
        cpx     $C4E5
        sbc     $ED,x
        beq     L9FE7
        ldy     #$C4
        sbc     $ED,x
        beq     L9FD3
        .byte   $D3
        .byte   $E3
        .byte   $F2
        sbc     $E5
        inc     $F4A0
        .byte   $EF
        ldy     #$C6
        sbc     #$EC
        sbc     $84
        .byte   $E2
        sta     $E3
        jsr     LA476
        bcc     LA04D
        jmp     LA1C6

LA04D:  lda     #$F3
        jsr     xgetparm_ch
        bcs     LA057
        jmp     LA2C4

LA057:  lda     #$E3
        jsr     xgetparm_ch
        bcc     LA062
        ldy     #$F7
        lda     #$A3
LA062:  sty     $E4
        sta     $E5
        lda     #$F0
        jsr     xgetparm_ch
        bcc     LA071
        ldy     #$F7
        lda     #$A3
LA071:  sty     $E6
        sta     $E7
        .byte   $B2
        cpx     $18
        .byte   $72
        inc     $F0
        .byte   $3B
        .byte   $B2
        cpx     $F0
LA07F:  .byte   $03
        jmp     LA1C7

        jsr     xmess
        sta     $AAAA
        tax
        ldy     #$E5
        .byte   $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$ED
        sbc     $F3,x
        .byte   $F4
        ldy     #$E8
        sbc     ($F6,x)
        sbc     $A0
        beq     LA07F
        .byte   $F4
        inx
LA0A0:  ldy     #$A8
        lda     $A9E3
        ldy     #$F4
        .byte   $EF
        ldy     #$E3
        .byte   $EF
        .byte   $EE
        .byte   $E6
LA0AD:  sbc     #$E7
        sbc     $F2,x
        sbc     $8D
        brk
        jmp     xerr

        ldx     #$CC
        .byte   $20
LA0BA:  .byte   $5A
        bcs     $A05F
        iny
        lda     #$08
        jsr     xmmgr
        bcc     LA0F2
        jsr     xmess
        sta     $AAAA
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
        ldy     #$E5
        inc     $F5EF
        .byte   $E7
        inx
        ldy     #$E4
        sbc     $E1EE,y
        sbc     $E3E9
        ldy     #$ED
        sbc     $ED
        .byte   $EF
        .byte   $F2
        sbc     $8D,y
        .byte   $4C
LA0F0:  pha
        .byte   $B0
LA0F2:  .byte   $9C
        cli
        ldy     $8D
LA0F6:  eor     $64A4,y
        nop
        sta     $EB
        jsr     LA2E7
        .byte   $B2
        .byte   $E2
        bne     LA10B
        ldy     #$FE
        lda     #$A3
        sty     $E2
        sta     $E3
LA10B:  ldy     $E2
        lda     $E3
        sty     LA43F
        sta     LA440
        sty     LA461
        sta     LA462
        sty     LA451
        sta     LA452
        lda     #$0A
        sta     LA43E
        jsr     LBF00
        cpy     $3E
        ldy     $90
        .byte   $12
        cmp     #$46
        beq     LA135
        jmp     xProDOS_err

LA135:  jsr     LBF00
        cpy     #$60
        ldy     $90
        .byte   $0F
        jmp     xProDOS_err

        lda     LA442
        cmp     #$04
        beq     LA14C
        lda     #$96
        jmp     xProDOS_err

LA14C:  jsr     LBF00
        iny
        bvc     LA0F6
        bcc     LA157
        jmp     xProDOS_err

LA157:  lda     LA455
        sta     LA472
        sta     LA457
        sta     LA46D
        sta     LA45F
        jsr     LBF00
        cmp     ($71),y
        ldy     $90
        .byte   $03
        .byte   $4C
        .byte   $42
LA170:  bcs     $A11F
        .byte   $73
        ldy     $8D
        ror     $ADA4
        .byte   $74
        ldy     $8D
        .byte   $6F
        ldy     $AD
        adc     $A4,x
        sta     LA470
        jsr     LBF00
        dec     LA46C
        bcc     LA18E
        jmp     xProDOS_err

LA18E:  .byte   $9C
        .byte   $5A
        ldy     $9C
        .byte   $5B
        ldy     $A5
        rol     $48,x
        lda     $37
        pha
        ldy     #$E5
        lda     #$A3
        sty     $36
        sta     $37
        jsr     LA321
        pla
        sta     $37
        pla
        sta     $36
        jsr     LBF00
        .byte   $CB
        lsr     $A4,x
        bcc     LA1B6
        jmp     xProDOS_err

LA1B6:  jsr     LBF00
        cpy     LA45E
        bcc     LA1C1
        jmp     xProDOS_err

LA1C1:  ldx     #$CC
        jsr     xmmgr
LA1C6:  rts

LA1C7:  .byte   $B2
        inc     $F0
        bpl     LA170
        inc     $A5
        .byte   $E7
        sty     LA1D9
        sta     LA1DA
        jsr     xpmgr
        .byte   $03
LA1D9:  .byte   $E6
LA1DA:  brk
        ldy     $E6
        lda     $E7
        sty     LA1ED
        sta     LA1EE
        ldy     #$F8
        lda     #$A3
        jsr     xpmgr
        brk
LA1ED:  .byte   $E6
LA1EE:  brk
        ldy     $E4
        lda     $E5
        sty     LA1FD
        sta     LA1FE
LA1F9:  jsr     xpmgr
        .byte   $04
LA1FD:  .byte   $E4
LA1FE:  brk
        inc     LA4A3,x
        inc     $A5
        .byte   $E7
        sty     LA43F
        sta     LA440
        sty     LA451
        sta     LA452
        lda     #$0A
        sta     LA43E
        jsr     LBF00
        cpy     $3E
        ldy     $90
        .byte   $03
        jmp     xProDOS_err

        .byte   $AD
LA222:  .byte   $42
        ldy     $C9
        asl     $F0
        .byte   $27
        jsr     xmess
        sta     $AAAA
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
        ldy     #$C4
        sbc     ($F6,x)
        sbc     $F8
        ldy     #$E3
        .byte   $EF
        sbc     $E1ED
        inc     $8DE4
        brk
        jmp     xerr

LA24F:  jsr     LBF00
        iny
        bvc     LA1F9
        bcc     LA25A
        jmp     xProDOS_err

LA25A:  lda     LA455
        sta     LA46D
        sta     LA457
        sta     LA45F
        sec
        lda     #$FE
        sta     LA458
        sbc     #$00
        sta     LA46E
        lda     #$A3
        sta     LA459
        sbc     #$A0
        sta     LA46F
        .byte   $9C
LA27C:  bvs     LA222
        jsr     LBF00
        dec     LA46C
        bcc     LA289
        jmp     xProDOS_err

LA289:  lda     #$40
        sta     LA45A
        .byte   $9C
        .byte   $5B
        ldy     $20
        brk
        .byte   $BF
        .byte   $CB
        lsr     $A4,x
        bcc     LA29C
        jmp     xProDOS_err

LA29C:  jsr     LBF00
        cpy     LA45E
        bcc     LA2A7
        jmp     xProDOS_err

LA2A7:  lda     #$07
        sta     LA43E
        lda     LA441
        ora     #$20
        jsr     LBF00
        .byte   $C3
        rol     $90A4,x
        .byte   $03
        jmp     xProDOS_err

        jsr     xmess
        inc     $F7E5
        ldy     #$00
LA2C4:  jsr     xmess
        .byte   $E3
        .byte   $EF
        inc     $E9E6
        .byte   $E7
        sbc     $F2,x
        sbc     ($F4,x)
        sbc     #$EF
        inc     LA0BA
        inc     $E4
        sbc     $ED,x
        beq     LA27C
        brk
        ldy     #$FE
        lda     #$A3
        jsr     xprint_path
        jmp     LFD8E

LA2E7:  sta     $C001
        ldx     #$17
LA2EC:  lda     LA4BC,x
        sta     $E0
        lda     LA4D4,x
        sta     $E1
        ldy     #$00
LA2F8:  lda     $C01F
        bpl     LA30B
        sta     $C055
        lda     ($E0),y
        sta     $C054
        and     #$7F
        cmp     #$20
        bne     LA31B
LA30B:  lda     ($E0),y
        and     #$7F
        cmp     #$20
        bne     LA31B
        iny
        cpy     #$28
        bne     LA2F8
        dex
        bne     LA2EC
LA31B:  stx     $E8
        sta     $C000
        rts

LA321:  sta     $C001
        ldx     #$FF
LA326:  inx
        lda     LA4BC,x
        sta     $E0
        lda     LA4D4,x
        sta     $E1
        ldy     #$00
        sty     $E9
LA335:  lda     $C01F
        bpl     LA35D
        sta     $C055
        lda     ($E0),y
        sta     $C054
        and     #$7F
        cmp     #$20
        bne     LA34C
        inc     $E9
        .byte   $80
        .byte   $11
LA34C:  pha
        lda     $E9
        beq     LA359
        .byte   $5A
        tay
        jsr     LA4AF
        .byte   $64
        sbc     #$7A
LA359:  pla
        jsr     LA3DC
LA35D:  lda     ($E0),y
        and     #$7F
        cmp     #$20
        bne     LA369
        inc     $E9
        .byte   $80
        .byte   $11
LA369:  pha
        lda     $E9
        beq     LA376
        .byte   $5A
        tay
        jsr     LA4AF
        .byte   $64
        sbc     #$7A
LA376:  pla
        jsr     LA3DC
        iny
        cpy     #$28
        bne     LA335
        jsr     LFD8E
        cpx     $E8
        bne     LA326
        jsr     xmess
        lda     $ADA0
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        ldy     #$AD
        sta     $8D00
        brk
        cpy     #$60
LA3DC:  cmp     #$20
        bcs     LA3E2
        ora     #$40
LA3E2:  jmp     LFDED

        cld
        .byte   $92
        nop
        inc     $EA
        bne     LA3EE
        inc     $EB
LA3EE:  inc     LA45A
        bne     LA3F6
        inc     LA45B
LA3F6:  rts

        brk
        ora     $E6
        cpx     $F5
        sbc     $14F0
        .byte   $2F
        pla
        .byte   $64
        .byte   $2F
        .byte   $77
        .byte   $6F
        .byte   $72
        .byte   $64
        .byte   $2F
        ror     $69
        jmp     (L7365)

        .byte   $2F
        bvs     LA476
        adc     #$6C
        adc     $BB
        ldy     #$B8
        ldy     #$A0
        .byte   $B3
        ldy     #$F4
        ldy     #$A0
        .byte   $E3
        ldy     #$AA
        .byte   $F4
        ldy     #$AA
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        sbc     $A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $E2
        ldy     #$A0
        inc     LA0A0
        ldy     #$A0
        ldy     $E3,x
        .byte   $A0
LA43E:  asl     a
LA43F:  .byte   $A0
LA440:  .byte   $80
LA441:  .byte   $A0
LA442:  ldy     #$E1
        cmp     $A0
        .byte   $80
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        lda     $A0,x
        lda     $03,x
LA451:  .byte   $E1
LA452:  .byte   $FF
        brk
LA454:  .byte   $0C
LA455:  brk
        .byte   $04
LA457:  .byte   $A0
LA458:  .byte   $EF
LA459:  .byte   $A0
LA45A:  rti

LA45B:  brk
        ldy     #$E4
LA45E:  .byte   $01
LA45F:  ldy     #$07
LA461:  .byte   $A0
LA462:  ldy     #$E3
        .byte   $04
        brk
        brk
        ora     ($A0,x)
        ldy     #$A0
        .byte   $A0
LA46C:  .byte   $02
LA46D:  .byte   $A0
LA46E:  .byte   $A0
LA46F:  .byte   $A0
LA470:  ldy     #$02
LA472:  .byte   $A0
LA473:  .byte   $A0
LA474:  .byte   $A0
LA475:  .byte   $80
LA476:  lda     $FBB3
        cmp     #$38
        beq     LA48B
        cmp     #$EA
        beq     LA48B
        lda     $FBC0
        cmp     #$EA
        beq     LA48B
        clc
        bne     LA4AE
LA48B:  jsr     xbell
        jsr     xmess
        sta     $AAAA
        tax
        ldy     #$E5
        .byte   $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        ldy     #$B6
LA49E:  lda     $C3,x
LA4A0:  bcs     LA454
LA4A2:  .byte   $A0
LA4A3:  .byte   $F2
LA4A4:  sbc     $F1
        sbc     $E9,x
        .byte   $F2
        sbc     $E4
        sta     $3800
LA4AE:  rts

LA4AF:  cpy     #$00
        beq     LA4BB
        lda     #$A0
LA4B5:  jsr     LFDED
        dey
        bne     LA4B5
LA4BB:  rts

LA4BC:  brk
        .byte   $80
        brk
        .byte   $80
        brk
        .byte   $80
        brk
        .byte   $80
        plp
        tay
        plp
        tay
        plp
        tay
        plp
        tay
        bvc     LA49E
        bvc     LA4A0
        bvc     LA4A2
        bvc     LA4A4
LA4D4:  .byte   $04
        .byte   $04
        ora     $05
        asl     $06
        .byte   $07
        .byte   $07
        .byte   $04
        .byte   $04
        ora     $05
        asl     $06
        .byte   $07
        .byte   $07
        .byte   $04
        .byte   $04
        ora     $05
        asl     $06
        .byte   $07
        .byte   $07
