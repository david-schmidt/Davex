	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_A000"
.org	$a000

LFBC1	= $FBC1
LFCA8	= $FCA8
LFDED	= $FDED
LFE80	= $FE80
LFE84	= $FE84

	rts

        inc     $12EE
        ora     ($40),y
        .byte   $12
        ldy     #$00
        ldy     #$2F
        ldy     #$00
        brk
        brk
        brk
        brk
        brk
        .byte   $1C
        .byte   $A7
        lda     ($B5),y
        .byte   $A7
        ldy     #$D0
        sbc     $FA,x
        .byte   $FA
        cpx     LA0E5
        .byte   $AF
        ldy     #$E2
        sbc     $CAA0,y
        sbc     $E6
        inc     $A0
        iny
        sbc     ($EE,x)
        .byte   $F3
        sbc     $EE
        jsr     LA6FE
        bcc     LA037
        jmp     LA0FB

LA037:  lda     $057B
        sta     $E4
        lda     $05FB
        sta     $E5
        ldx     #$CC
        jsr     xmmgr
        ldx     #$C8
        lda     #$08
        jsr     xmmgr
        bcc     LA070
        jsr     xmess
        sta     $AAAA
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

LA070:  sta     LAA07
        .byte   $9C
        asl     $AA
        .byte   $64
        sbc     $ED20,y
        .byte   $A7
        bcs     LA082
        dec     $F9
        jsr     LA108
LA082:  jsr     LA979
        jsr     LA147
        lda     $BF92
        sta     LA7AD
        lda     $BF93
        sta     LA7AF
        lda     $BF90
        .byte   $8D
LA098:  ldx     $ADA7
        sta     ($BF),y
        sta     LA7B0
LA0A0:  jsr     LA366
        lda     $F9
        bpl     LA0B1
        .byte   $9C
        .byte   $FF
        tay
        .byte   $9C
        brk
        lda     #$20
        .byte   $BB
        .byte   $A7
        asl     a
LA0B1:  jsr     LA454
        bcs     LA0F8
        jsr     LA635
        bcc     LA0B1
        lda     $F9
        bpl     LA0C3
        jsr     LA7BB
        .byte   $0B
LA0C3:  lda     #$03
        sta     $F4
LA0C7:  jsr     LFE80
        jsr     LA43F
        jsr     xbell
        jsr     LFE84
        jsr     LA43F
        lda     #$A0
        jsr     LFCA8
        dec     $F4
        bne     LA0C7
LA0DF:  lda     $F9
        bpl     LA0F0
        .byte   $20
        .byte   $BB
LA0E5:  .byte   $A7
        .byte   $02
        jsr     LA7BB
        php
        lda     LA8FD
        bmi     LA0F8
LA0F0:  lda     $C000
        bpl     LA0DF
        sta     $C010
LA0F8:  jsr     LA9BC
LA0FB:  ldx     #$CC
        jsr     xmmgr
        ldx     $E4
        ldy     $E5
        jsr     LA751
        rts

LA108:  jsr     LA7BB
        .byte   $07
        lda     #$01
        jsr     LA7BB
        brk
        jsr     LA7BB
        .byte   $03
        lda     #$ED
        sta     $04F8
        lda     #$00
        sta     $05F8
        .byte   $9C
        sei
        .byte   $04
        .byte   $9C
        sei
        ora     $A9
        brk
        jsr     LA7BB
        ora     $A9
        .byte   $73
        sta     $04F8
        lda     #$00
        sta     $05F8
        .byte   $9C
        sei
        .byte   $04
        .byte   $9C
        sei
        ora     $A9
        ora     ($20,x)
        .byte   $BB
        .byte   $A7
        ora     $20
        .byte   $BB
        .byte   $A7
        asl     $60
LA147:  lda     $20
        sta     $E6
        lda     $21
        sta     $E7
        lda     #$35
        sta     $21
        ldx     #$1B
        stx     $20
        ldy     #$04
        jsr     LA751
        jsr     xmess
        sta     $9B8F
        .byte   $DA
        dec     LA098,x
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$D0
        sbc     $FA,x
        .byte   $FA
        cpx     LA0E5
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$9B
        .byte   $DF
        stx     $8D98
        .byte   $8F
        .byte   $9B
        .byte   $DA
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $DF
        stx     $8D98
        .byte   $8F
        .byte   $9B
        .byte   $DA
        stx     LA098
        ldy     #$A0
        ldy     #$A0
        ldy     #$FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $8F
        .byte   $9B
        .byte   $DF
        stx     $8D98
        .byte   $8F
        .byte   $9B
        .byte   $DA
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $DF
        stx     $8D98
        .byte   $8F
        .byte   $9B
        .byte   $DA
        stx     LA098
        ldy     #$A0
        ldy     #$A0
        ldy     #$FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $8F
        .byte   $9B
        .byte   $DF
        stx     $8D98
        .byte   $8F
        .byte   $9B
        .byte   $DA
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $DF
        stx     $8D98
        .byte   $8F
        .byte   $9B
        .byte   $DA
        stx     LA098
        ldy     #$A0
        ldy     #$A0
        ldy     #$FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $8F
        .byte   $9B
        .byte   $DF
        stx     $8D98
        .byte   $8F
        .byte   $9B
        .byte   $DA
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $DF
        stx     $8D98
        .byte   $8F
        .byte   $9B
        .byte   $DA
        stx     LA098
        ldy     #$A0
        ldy     #$A0
        ldy     #$FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $FC
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $8F
        .byte   $9B
        .byte   $DF
        stx     $8D98
        .byte   $8F
        .byte   $9B
        .byte   $DA
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        tya
        stx     $8FFC
        .byte   $9B
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $D3
        .byte   $DF
        stx     $8D98
        .byte   $8F
        .byte   $9B
        .byte   $DA
        .byte   $D7
        dec     $D7,x
        dec     $D7,x
        dec     $D7,x
        dec     $D7,x
        dec     $D7,x
        dec     $D7,x
        dec     $D7,x
        dec     $D7,x
        dec     $D7,x
        dec     $D7,x
        dec     $D7,x
        dec     $D7,x
        dec     $D7,x
        .byte   $DF
        stx     $8D98
        brk
        lda     $E7
        sta     $21
        lda     $E6
        sta     $20
        rts

LA32E:  pha
        tya
        sta     $ED
        lsr     a
        lsr     a
        sta     $EF
        asl     a
        asl     a
        sta     $EE
        lda     $ED
        sec
        sbc     $EE
        sta     $EE
        asl     a
        sta     $F1
        asl     a
        clc
        adc     $F1
        adc     $EE
        adc     #$1C
        tax
        lda     $EF
        .byte   $1A
        asl     a
        clc
        adc     #$05
        tay
        jsr     LA751
        pla
        asl     a
        tax
        lda     LA64E,x
        tay
        inx
        lda     LA64E,x
        jmp     LA737

LA366:  ldx     #$00
LA368:  .byte   $9E
        dec     $9EA6,x
        inc     $E8A6
        cpx     #$10
        bne     LA368
        ldy     #$0F
LA375:  jsr     LA762
        lda     LA7AB
        and     #$0F
        tax
        lda     LA6DE,x
        beq     LA38E
        cpx     #$00
        beq     LA389
        .byte   $80
        .byte   $02
LA389:  ldx     #$10
        dex
        .byte   $80
        .byte   $F0
LA38E:  tya
        sta     LA6DE,x
        sta     LA6EE,x
        dey
        bne     LA375
        jsr     LA635
        bcs     LA366
        ldx     #$00
LA39F:  lda     LA6DE,x
        beq     LA3A9
        inx
        cpx     #$0F
        bne     LA39F
LA3A9:  stx     $E8
        stx     $E9
        stx     $EA
        stx     $EB
        cpx     #$0F
        beq     LA3FA
        txa
        jsr     LA5E4
        cpx     #$03
        beq     LA3CF
        ldx     $E8
        ldy     $EE
LA3C1:  inx
        lda     LA6EE,x
        dex
        sta     LA6EE,x
        inx
        iny
        cpy     #$03
        bne     LA3C1
LA3CF:  ldy     $EF
        cpy     #$03
        beq     LA3F5
        lda     $EF
        tay
        asl     a
        asl     a
        clc
        adc     #$03
        tax
LA3DE:  inx
        inx
        inx
        inx
        lda     LA6EE,x
        dex
        dex
        dex
        dex
        sta     LA6EE,x
        inx
        inx
        inx
        inx
        iny
        cpy     #$03
        bne     LA3DE
LA3F5:  ldx     #$0F
        .byte   $9E
        .byte   $EE
        .byte   $A6
LA3FA:  ldx     #$00
        .byte   $64
        .byte   $F6
LA3FE:  txa
        .byte   $1A
        cmp     LA6EE,x
        beq     LA421
        inc     $F6
        lda     LA6EE,x
        stx     $F7
        tax
        dex
        pha
        lda     LA6EE,x
        sta     $F8
        pla
        sta     LA6EE,x
        ldx     $F7
        lda     $F8
        sta     LA6EE,x
        .byte   $80
        .byte   $DD
LA421:  inx
        cpx     #$0F
        bne     LA3FE
        clc
        lda     $F6
        lsr     a
        bcc     LA42F
        jmp     LA366

LA42F:  jsr     LA43F
        jsr     LFE80
        ldy     $EA
        lda     #$00
        jsr     LA32E
        jmp     LFE84

LA43F:  .byte   $64
        sed
LA441:  ldx     $F8
        ldy     $F8
        lda     LA6DE,x
        jsr     LA32E
        inc     $F8
        lda     $F8
        cmp     #$10
        bne     LA441
        rts

LA454:  lda     $F9
        bpl     LA4BD
        jsr     LA7BB
        .byte   $02
        jsr     LA7BB
        php
        lda     LA8FD
        and     #$20
        beq     LA475
        jsr     LA7BB
        .byte   $0B
        jsr     LA7BB
        .byte   $0C
        jsr     LA7BB
        asl     a
        .byte   $80
        .byte   $07
LA475:  lda     LA8FD
        and     #$40
        bne     LA4BD
        lda     LA8FD
        bpl     LA4BD
        lda     LA8FF
        cmp     #$1C
        bne     LA491
        lda     LA900
        cmp     #$05
        bne     LA491
        sec
        rts

LA491:  jsr     LA5F8
        bcs     LA4BD
        jsr     LA7BB
        .byte   $0B
        ldx     $EB
        lda     LA6DE,x
        ldy     $EB
        jsr     LA32E
        lda     $EC
        sta     $EA
        sta     $EB
        jsr     LFE80
        ldx     $EA
        lda     LA6DE,x
        ldy     $EA
        jsr     LA32E
        jsr     LFE84
        jmp     LA567

LA4BD:  jsr     xpoll_io
        lda     $C000
        bpl     LA454
        sta     $C010
        cmp     #$95
        beq     LA509
        cmp     #$EC
        beq     LA509
        cmp     #$CC
        beq     LA509
        cmp     #$88
        beq     LA513
        cmp     #$EA
        beq     LA513
        cmp     #$CA
        beq     LA513
        cmp     #$8B
        beq     LA51D
        cmp     #$E9
        beq     LA51D
        cmp     #$C9
        beq     LA51D
        cmp     #$8A
        beq     LA52E
        cmp     #$EB
        beq     LA52E
        cmp     #$CB
        beq     LA52E
        cmp     #$A0
        beq     LA567
        cmp     #$8D
        beq     LA567
        cmp     #$9B
        beq     LA507
        jmp     LA454

LA507:  sec
        rts

LA509:  lda     $EA
        .byte   $1A
        and     #$0F
        sta     $EA
        jmp     LA546

LA513:  lda     $EA
        .byte   $3A
        and     #$0F
        sta     $EA
        jmp     LA546

LA51D:  lda     $EA
        beq     LA526
        sec
        sbc     #$04
        bpl     LA529
LA526:  clc
        adc     #$0F
LA529:  sta     $EA
        jmp     LA546

LA52E:  lda     $EA
        cmp     #$0F
        beq     LA53D
        clc
        adc     #$04
        cmp     #$10
        bcs     LA541
        .byte   $80
        .byte   $07
LA53D:  lda     #$00
        .byte   $80
        .byte   $03
LA541:  sec
        sbc     #$0F
        sta     $EA
LA546:  ldx     $EB
        lda     LA6DE,x
        ldy     $EB
        jsr     LA32E
        jsr     LFE80
        ldx     $EA
        lda     LA6DE,x
        ldy     $EA
        jsr     LA32E
        jsr     LFE84
        lda     $EA
        sta     $EB
        jmp     LA454

LA567:  lda     $E8
        cmp     $EA
        beq     LA5A3
        jsr     LA5E4
        stx     $F4
        sty     $F5
        lda     $EA
        jsr     LA5E4
        txa
        sec
        sbc     $F4
        jsr     LA7B5
        sta     $F4
        tya
        sec
        sbc     $F5
        jsr     LA7B5
        sta     $F5
        lda     $F4
        cmp     #$01
        bne     LA597
        lda     $F5
        bne     LA597
        .byte   $80
        .byte   $1A
LA597:  lda     $F5
        cmp     #$01
        bne     LA5A3
        lda     $F4
        bne     LA5A3
        .byte   $80
        .byte   $0E
LA5A3:  lda     $F9
        bpl     LA5AB
        jsr     LA7BB
        asl     a
LA5AB:  jsr     xbell
        jmp     LA454

        ldx     $EA
        lda     LA6DE,x
        pha
        .byte   $9E
        dec     $20A6,x
        .byte   $80
        inc     $EAA4,x
        lda     #$00
        jsr     LA32E
        jsr     LFE84
        ldx     $E8
        pla
        sta     LA6DE,x
        ldy     $E8
        jsr     LA32E
        lda     $E8
        sta     $E9
        lda     $EA
        sta     $E8
        lda     $F9
        bpl     LA5E2
        jsr     LA7BB
        asl     a
LA5E2:  clc
        rts

LA5E4:  sta     $ED
        lsr     a
        lsr     a
        sta     $EF
        tay
        asl     a
        asl     a
        sta     $EE
        lda     $ED
        sec
        sbc     $EE
        sta     $EE
        tax
        rts

LA5F8:  lda     LA8FF
        cmp     #$1C
        bcc     LA633
        cmp     #$38
        bcs     LA633
        lda     LA900
        cmp     #$07
        bcc     LA633
        cmp     #$0F
        bcs     LA633
        lda     LA8FF
        sec
        sbc     #$1B
        .byte   $3A
        tay
        lda     #$00
        ldx     #$07
        jsr     LA94C
        sta     $EE
        lda     LA900
        sec
        sbc     #$05
        .byte   $3A
        .byte   $3A
        lsr     a
        sta     $EF
        asl     a
        asl     a
        clc
        adc     $EE
        sta     $EC
        clc
        rts

LA633:  sec
        rts

LA635:  lda     $E8
        cmp     #$0F
        bne     LA64C
        ldx     #$00
        lda     #$01
LA63F:  cmp     LA6DE,x
        bne     LA64C
        .byte   $1A
        inx
        cpx     #$0F
        bne     LA63F
        sec
        rts

LA64C:  clc
        rts

LA64E:  ror     $75A6
        ldx     $7C
        ldx     $83
        ldx     $8A
        ldx     $91
        .byte   $A6
LA65A:  tya
        ldx     $9F
        ldx     $A6
        ldx     $AD
        ldx     $B4
        ldx     $BB
        ldx     $C2
        ldx     $C9
        ldx     $D0
        ldx     $D7
        ldx     $06
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        asl     $A0
        ldy     #$A0
        lda     ($A0),y
        ldy     #$06
        ldy     #$A0
        ldy     #$B2
        ldy     #$A0
        asl     $A0
        ldy     #$A0
        .byte   $B3
        ldy     #$A0
        asl     $A0
        ldy     #$A0
        ldy     $A0,x
        ldy     #$06
        ldy     #$A0
        ldy     #$B5
LA696:  ldy     #$A0
        asl     $A0
        ldy     #$A0
        ldx     $A0,y
        ldy     #$06
        ldy     #$A0
        ldy     #$B7
        ldy     #$A0
        asl     $A0
        ldy     #$A0
        clv
        ldy     #$A0
        asl     $A0
        ldy     #$A0
        lda     LA0A0,y
        asl     $A0
        ldy     #$B1
        bcs     LA65A
        ldy     #$06
        ldy     #$A0
        lda     ($B1),y
        ldy     #$A0
        asl     $A0
        ldy     #$B1
        .byte   $B2
        ldy     #$A0
        asl     $A0
        ldy     #$B1
        .byte   $B3
        ldy     #$A0
        asl     $A0
        ldy     #$B1
        ldy     $A0,x
        ldy     #$06
        ldy     #$A0
        lda     ($B5),y
LA6DC:  ldy     #$A0
LA6DE:  ldy     #$A0
        ldy     #$A0
        tay
        sbc     ($A0,x)
        tsx
        ldy     #$A0
        ldy     #$A0
        bcs     LA696
        ldy     #$B0
LA6EE:  ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $B7
        ldy     #$A0
        ldy     #$A0
        .byte   $EE
LA6FE:  lda     $FBB3
        cmp     #$38
        beq     LA713
        cmp     #$EA
        beq     LA713
        lda     $FBC0
        cmp     #$EA
        beq     LA713
        clc
        bne     LA736
LA713:  jsr     xbell
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
        lda     $C3,x
        bcs     LA6DC
        ldy     #$F2
        sbc     $F1
        sbc     $E9,x
        .byte   $F2
        sbc     $E4
        sta     $3800
LA736:  rts

LA737:  sta     $E1
        sty     $E0
        txa
        pha
        ldy     #$00
        lda     ($E0),y
        beq     LA74E
        tax
        iny
LA745:  lda     ($E0),y
        jsr     LFDED
        iny
        dex
        bne     LA745
LA74E:  pla
        tax
        rts

LA751:  pha
        sty     $25
        sty     $05FB
        tya
        jsr     LFBC1
        stx     $24
        stx     $057B
        pla
        rts

LA762:  pha
        .byte   $5A
        .byte   $DA
        ldx     #$04
LA767:  lda     LA7AC,x
        sta     LA7A8,x
        sta     LA7B0,x
        dex
        bne     LA767
        ldx     #$07
LA775:  asl     LA7A9
        rol     LA7AA
        rol     LA7AB
        rol     LA7AC
        dex
        bne     LA775
        ldy     #$03
LA786:  ldx     #$00
        sec
LA789:  lda     LA7A9,x
        sbc     LA7B1,x
        sta     LA7A9,x
        inx
        cpx     #$04
        bne     LA789
        dey
        bne     LA786
        ldx     #$04
LA79C:  lda     LA7A8,x
        sta     LA7AC,x
        dex
        bne     LA79C
        .byte   $FA
        .byte   $7A
        pla
LA7A8:  rts

LA7A9:  .byte   $B0
LA7AA:  .byte   $A0
LA7AB:  .byte   $B0
LA7AC:  .byte   $80
LA7AD:  .byte   $A0
LA7AE:  .byte   $C4
LA7AF:  .byte   $E4
LA7B0:  .byte   $A0
LA7B1:  ldy     #$C2
        ldy     #$A0
LA7B5:  bpl     LA7BA
        eor     #$FF
        .byte   $1A
LA7BA:  rts

LA7BB:  sta     LA8F8
        pla
        sta     $E0
        pla
        sta     $E1
        inc     $E0
        bne     LA7CA
        inc     $E1
LA7CA:  lda     $E1
        pha
        lda     $E0
        pha
        .byte   $B2
        cpx     #$0A
        tax
        lda     LA902,x
        sta     LA7EB
        inx
        lda     LA902,x
        sta     LA7EC
        ldx     LA8F5
        ldy     LA8F6
        lda     LA8F8
        .byte   $4C
LA7EB:  brk
LA7EC:  cpy     $64
        cpx     #$A9
        iny
        sta     $E1
LA7F3:  ldy     #$0C
        lda     ($E0),y
        cmp     #$20
        bne     LA805
        ldy     #$FB
        lda     ($E0),y
        cmp     #$D6
        bne     LA805
        .byte   $80
        asl     a
LA805:  dec     $E1
        lda     $E1
        cmp     #$C0
        bne     LA7F3
        sec
        rts

        lda     $E1
        sta     LA8F5
        and     #$0F
        sta     LA8F7
        asl     a
        asl     a
        asl     a
        asl     a
        sta     LA8F6
        ldy     #$12
        ldx     #$00
LA824:  lda     ($E0),y
        sta     LA902,x
        inx
        lda     LA8F5
        sta     LA902,x
        inx
        iny
        cpy     #$1A
        bne     LA824
        clc
        rts

        ldx     LA8F7
        lda     $0478,x
        sta     LA8F9
        lda     $0578,x
        sta     LA8FA
        lda     $04F8,x
        sta     LA8FB
        lda     $05F8,x
        sta     LA8FC
        lda     $0778,x
        sta     LA8FD
        lda     $07F8,x
        sta     LA8FE
        rts

        ldx     LA8F7
        lda     LA8F9
        sta     $0478,x
        lda     LA8FA
        sta     $0578,x
        lda     LA8FB
        sta     $04F8,x
        lda     LA8FC
        sta     $05F8,x
        rts

        ldx     LA900
        lda     LA91C,x
        sta     $E0
        lda     LA934,x
        sta     $E1
        ldy     LA8FF
        lda     $C01F
        bpl     LA89C
        tya
        lsr     a
        tay
        bcs     LA89C
        sta     $C001
        sta     $C055
LA89C:  lda     LA901
        sta     ($E0),y
        sta     $C054
        sta     $C000
        rts

        ldx     LA900
        .byte   $BD
        .byte   $1C
LA8AD:  lda     #$85
        cpx     #$BD
        .byte   $34
        lda     #$85
        sbc     ($AC,x)
        .byte   $FF
        tay
        lda     $C01F
        bpl     LA8C8
        tya
        lsr     a
        tay
        bcs     LA8C8
        sta     $C001
        sta     $C055
LA8C8:  lda     ($E0),y
        sta     LA901
        lda     #$42
        sta     ($E0),y
        sta     $C054
        sta     $C000
        rts

        ldy     LA8F9
        lda     LA8FA
        ldx     #$03
        jsr     LA94C
        sta     LA8FF
        ldy     LA8FB
        lda     LA8FC
        ldx     #$05
        jsr     LA94C
        sta     LA900
        rts

LA8F5:  .byte   $C4
LA8F6:  rti

LA8F7:  .byte   $04
LA8F8:  .byte   $C2
LA8F9:  .byte   $A0
LA8FA:  .byte   $AE
LA8FB:  .byte   $A0
LA8FC:  .byte   $B0
LA8FD:  .byte   $A0
LA8FE:  .byte   $80
LA8FF:  .byte   $81
LA900:  .byte   $B0
LA901:  .byte   $CC
LA902:  .byte   $D4
        .byte   $A0
LA904:  ldy     #$C5
        ldy     #$A0
        ldy     #$A0
        ldy     #$B0
        ldy     #$A0
        bcs     $A8B0
        ldy     #$92
        sec
        tay
        rts

        tay
        tay
        tay
        .byte   $7C
        tay
        cld
        tay
LA91C:  brk
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
        bvc     LA8FE
        bvc     LA900
        bvc     LA902
        bvc     LA904
LA934:  .byte   $04
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
LA94C:  sty     LA974
        sta     LA975
        stx     LA976
        ldx     #$08
        sty     LA977
LA95A:  asl     LA977
        rol     a
        cmp     LA976
        bcc     LA969
        sbc     LA976
        inc     LA977
LA969:  dex
        bne     LA95A
        sta     LA978
        tay
        lda     LA977
        rts

LA974:  .byte   $A0
LA975:  .byte   $A0
LA976:  .byte   $A0
LA977:  .byte   $A0
LA978:  .byte   $C3
LA979:  pha
        .byte   $5A
        .byte   $DA
        ldy     LAA06
        lda     LAA07
        sty     $E2
        sta     $E3
        sta     $C001
        ldx     #$00
LA98B:  lda     LA91C,x
        sta     $E0
        lda     LA934,x
        sta     $E1
        ldy     #$00
LA997:  sta     $C055
        lda     ($E0),y
        sta     $C054
        .byte   $92
        .byte   $E2
        jsr     LA9FF
        lda     ($E0),y
        .byte   $92
        .byte   $E2
        jsr     LA9FF
        iny
        cpy     #$28
        bne     LA997
        inx
        cpx     #$18
        bne     LA98B
        sta     $C000
        .byte   $FA
        .byte   $7A
        pla
        rts

LA9BC:  pha
        .byte   $5A
        .byte   $DA
        ldy     LAA06
        lda     LAA07
        sty     $E2
        sta     $E3
        sta     $C001
        ldx     #$00
LA9CE:  lda     LA91C,x
        sta     $E0
        lda     LA934,x
        sta     $E1
        ldy     #$00
LA9DA:  .byte   $B2
        .byte   $E2
        sta     $C055
        sta     ($E0),y
        sta     $C054
        jsr     LA9FF
        .byte   $B2
        .byte   $E2
        sta     ($E0),y
        jsr     LA9FF
        iny
        cpy     #$28
        bne     LA9DA
        inx
        cpx     #$18
        bne     LA9CE
        sta     $C000
        .byte   $FA
        .byte   $7A
        pla
        rts

LA9FF:  inc     $E2
        bne     LAA05
        inc     $E3
LAA05:  rts

LAA06:  .byte   $CC
LAA07:  .byte   $A0
