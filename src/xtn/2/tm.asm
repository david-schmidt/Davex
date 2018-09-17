	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_A000"

L72A7           := $72A7
LFBC1           := $FBC1
LFD8E           := $FD8E
LFDDA           := $FDDA
LFDED           := $FDED
        rts

        inc     $12EE
        .byte   $12
        brk
        bit     $A0
        brk
        ldy     #$5D
        ldy     #$03
        brk
        brk
        brk
        sbc     ($00,x)
        .byte   $E2
        brk
        .byte   $E3
        brk
        .byte   $F3
        brk
        sbc     $E406
        asl     $F9
        ora     ($E8,x)
        asl     $EE
        asl     $00
        brk
        sec
        .byte   $D4
        sbc     #$ED
        sbc     $CD
        sbc     ($F3,x)
        .byte   $F4
        sbc     $F2
        ldy     #$AD
LA031:  lda     $D3A0
        sbc     $F4
        .byte   $F3
        ldy     #$F4
        inx
        sbc     $A0
        cpx     $E1
        .byte   $F4
        sbc     $AF
        .byte   $F4
        sbc     #$ED
        sbc     $A0
        .byte   $EF
        inc     $A0
        sbc     ($A0,x)
        .byte   $D4
        sbc     #$ED
        sbc     $CD
        sbc     ($F3,x)
        .byte   $F4
        sbc     $F2
        ldy     #$C9
        cmp     #$A0
        iny
        ldx     $AECF
        jsr     LA704
        bcc     LA065
        jmp     LA0FB

LA065:  jsr     LA0FD
        bcc     LA06D
        jmp     xerr

LA06D:  jsr     LA158
        lda     $E9
        bpl     LA0B2
        ldx     #$CC
        jsr     xmmgr
        ldx     #$C8
        lda     #$08
        jsr     xmmgr
        bcs     LA092
        sta     LA931
        .byte   $9C
        bmi     LA031
        jsr     LA24C
        ldx     #$CC
        jsr     xmmgr
        .byte   $80
        .byte   $69
LA092:  jsr     xmess
        tax
        tax
        tax
        ldy     #$E5
        .byte   $F2
        .byte   $F2
        .byte   $EF
        .byte   $F2
        tsx
        .byte   $A0
LA0A0:  .byte   $EF
        sbc     $F4,x
        ldy     #$EF
        inc     $A0
        sbc     $EDE5
        .byte   $EF
        .byte   $F2
        sbc     $8D,y
        jmp     xerr

LA0B2:  jsr     LA1C9
        jsr     LA1E5
        jsr     LA348
        jsr     LA3C2
        bcs     LA0FB
        lda     $EA
        bpl     LA0E7
        jsr     xmess
        ldy     #$A0
        cpy     $E1
        .byte   $F4
        sbc     $AF
        .byte   $D4
        sbc     #$ED
        sbc     $A0
        .byte   $F3
        sbc     $F4
        ldy     #$F4
        .byte   $EF
        tsx
        ldy     #$00
        jsr     LA66D
        jsr     LA1C9
        .byte   $20
        .byte   $E5
LA0E4:  lda     ($80,x)
        .byte   $11
LA0E7:  jsr     xmess
        ldy     #$A0
        cpy     $E1
        .byte   $F4
        sbc     $AF
        .byte   $D4
        sbc     #$ED
        sbc     $BA
        ldy     #$00
        .byte   $20
LA0F9:  pha
        .byte   $A3
LA0FB:  clc
        rts

LA0FD:  .byte   $64
        .byte   $E2
        lda     #$C1
        sta     $E3
LA103:  ldy     #$00
        lda     ($E2),y
        cmp     #$08
        bne     LA11C
        iny
        lda     ($E2),y
        cmp     #$78
        bne     LA11C
        ldy     #$FE
        lda     ($E2),y
        cmp     #$B2
        bne     LA11C
        .byte   $80
        .byte   $2C
LA11C:  inc     $E3
        lda     $E3
        cmp     #$C8
        bne     LA103
        jsr     xmess
        .byte   $D4
        sbc     #$ED
        sbc     $CD
        sbc     ($F3,x)
        .byte   $F4
        sbc     $F2
        ldy     #$C9
        cmp     #$A0
        iny
        ldx     $AECF
        ldy     #$EE
        .byte   $EF
        .byte   $F4
        ldy     #$E6
        .byte   $EF
        sbc     $EE,x
        cpx     $A1
        sta     $3800
        rts

        lda     $E3
        sta     $E1
        sta     LA1CD
        sta     LA1D0
        and     #$0F
        sta     $E0
        clc
        rts

LA158:  .byte   $64
        .byte   $E7
        lda     #$E1
        jsr     xgetparm_ch
        bcs     LA163
        dec     $E7
LA163:  .byte   $64
        inx
        lda     #$E2
        jsr     xgetparm_ch
        bcs     LA16E
        dec     $E8
LA16E:  .byte   $64
        sbc     #$A9
        .byte   $E3
        jsr     xgetparm_ch
        bcs     LA179
        dec     $E9
LA179:  .byte   $64
        nop
        lda     #$F3
        jsr     xgetparm_ch
        bcs     LA184
        dec     $EA
LA184:  .byte   $64
        .byte   $EB
        lda     #$ED
        jsr     xgetparm_ch
        bcs     LA191
        dec     $EB
        sty     $F0
LA191:  .byte   $64
        cpx     $E4A9
        jsr     xgetparm_ch
        bcs     LA19E
        dec     $EC
        sty     $F1
LA19E:  .byte   $64
        sbc     $F9A9
        jsr     xgetparm_ch
        bcs     LA1AD
        dec     $ED
        sty     $F2
        stx     $F3
LA1AD:  .byte   $64
        inc     $E8A9
        jsr     xgetparm_ch
        bcs     LA1BA
        dec     $EE
        sty     $F4
LA1BA:  .byte   $64
        .byte   $EF
        lda     #$EE
        jsr     xgetparm_ch
        bcs     LA1C7
        dec     $EF
        sty     $F5
LA1C7:  clc
        rts

LA1C9:  lda     #$BA
        .byte   $20
        .byte   $0B
LA1CD:  .byte   $C7
        .byte   $20
        php
LA1D0:  .byte   $C7
        ldx     #$01
LA1D3:  lda     $0200,x
        cmp     #$8D
        beq     LA1E0
        sta     LA6F0,x
        inx
        bne     LA1D3
LA1E0:  dex
        stx     LA6F0
        rts

LA1E5:  ldx     #$01
        lda     LA6F0,x
        sec
        sbc     #$B0
        sta     LA6E8
        ldx     #$03
        jsr     LA23E
        sta     LA6E9
        ldx     #$06
        jsr     LA23E
        sta     LA6EA
LA200:  ldx     #$09
        jsr     LA23E
        cmp     #$54
        bcc     LA218
        clc
        adc     #$6C
        sta     LA6EB
        lda     #$00
        adc     #$07
        sta     LA6EC
        bne     LA225
LA218:  clc
        adc     #$D0
        sta     LA6EB
        lda     #$00
        adc     #$07
        sta     LA6EC
LA225:  ldx     #$0C
        jsr     LA23E
        sta     LA6ED
        ldx     #$0F
        jsr     LA23E
        sta     LA6EE
        ldx     #$12
        jsr     LA23E
        sta     LA6EF
        rts

LA23E:  lda     LA6F0,x
        pha
        inx
        lda     LA6F0,x
        tay
        pla
        jsr     LA824
        rts

LA24C:  jsr     LA8A3
        lda     $057B
        sta     LA346
        lda     $05FB
        sta     LA347
        ldx     #$13
        ldy     #$09
        jsr     LA892
        jsr     xmess
        .byte   $8F
        .byte   $9B
        .byte   $DA
        cpy     $CCCC
        cpy     $CCCC
        cpy     $CCCC
        cpy     $CCCC
        cpy     $CCCC
        cpy     $CCCC
        cpy     $CCCC
        cpy     $CCCC
        cpy     $CCCC
        cpy     $CCCC
        cpy     $CCCC
        cpy     $CCCC
        cpy     $CCCC
        cpy     $98DF
        stx     LA200
        .byte   $13
        ldy     #$0A
        jsr     LA892
        jsr     xmess
        .byte   $8F
        .byte   $9B
        .byte   $DA
        tya
        stx     LA0A0
        ldy     #$A0
LA2A7:  ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        ldy     #$A0
        .byte   $8F
        .byte   $9B
        .byte   $DF
        tya
        stx     LA200
        .byte   $13
        ldy     #$0B
        jsr     LA892
        jsr     xmess
        .byte   $8F
        .byte   $9B
        .byte   $DA
        tya
        stx     $DFDF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $DF
        .byte   $8F
        .byte   $9B
        .byte   $DF
        tya
        .byte   $8E
        brk
LA30E:  jsr     xpoll_io
        jsr     LA1C9
        jsr     LA1E5
        lda     LA6EF
        cmp     LA345
        beq     LA30E
        sta     LA345
        ldx     #$15
        ldy     #$0A
        jsr     LA892
        jsr     LA348
        lda     $C000
        bpl     LA30E
        sta     $C010
        cmp     #$9B
        bne     LA30E
        jsr     LA8E6
        ldx     LA346
        ldy     LA347
        jsr     LA892
        rts

LA345:  .byte   $E5
LA346:  tax
LA347:  .byte   $A0
LA348:  lda     LA6E8
        asl     a
        tax
        lda     LA7AB,x
        tay
        inx
        lda     LA7AB,x
        jsr     LA80A
        jsr     xmess
        ldy     a:$A0
        lda     LA6EA
        tay
        lda     #$00
        jsr     xprdec_2
        lda     #$A0
        jsr     LFDED
        lda     LA6E9
        .byte   $3A
        asl     a
        tax
        lda     LA73D,x
        tay
        inx
        lda     LA73D,x
        jsr     LA80A
        lda     #$A0
        jsr     LFDED
        ldy     LA6EB
        lda     LA6EC
        jsr     xprdec_2
        lda     #$A0
        jsr     LFDED
        jsr     LFDED
        lda     LA6ED
        jsr     LA83E
        tya
        jsr     LFDDA
        lda     #$BA
        jsr     LFDED
        lda     LA6EE
        jsr     LA83E
        tya
        jsr     LFDDA
        lda     #$BA
        jsr     LFDED
        lda     LA6EF
        jsr     LA83E
        tya
        jsr     LFDDA
        jsr     xmess
        ldy     #$8D
        brk
        rts

LA3C2:  jsr     xgetnump
        bne     LA3CA
        jmp     LA604

LA3CA:  ldx     #$01
        lda     #$1C
        sta     LA7F2,x
        .byte   $64
        inc     $AD
        .byte   $EB
        ldx     $18
        lsr     a
        bcs     LA3E5
        clc
        lsr     a
        bcs     LA3E5
        dec     $E6
        lda     #$1D
        sta     LA7F2,x
LA3E5:  lda     $E7
        bpl     LA444
        jsr     LA661
        .byte   $64
        nop
        dec     $EA
        inc     LA6ED
        lda     LA6ED
        cmp     #$18
        beq     LA3FC
        clc
        rts

LA3FC:  .byte   $9C
        sbc     $EEA6
        inx
        ldx     $AD
        inx
        ldx     $C9
        .byte   $07
        bne     LA40C
        .byte   $9C
        inx
        .byte   $A6
LA40C:  inc     LA6EA
        ldx     LA6E9
        dex
        lda     LA7F2,x
        cmp     LA6EA
        bcc     LA41D
        clc
        rts

LA41D:  lda     #$01
        sta     LA6EA
        inc     LA6E9
        lda     LA6E9
        cmp     #$0D
        beq     LA42E
        clc
        rts

LA42E:  lda     #$01
        sta     LA6E9
        clc
        adc     LA6EB
        sta     LA6EB
        lda     #$00
        adc     LA6EC
        sta     LA6EC
        clc
        rts

LA444:  lda     $E8
        bpl     LA498
        jsr     LA661
        .byte   $64
        nop
        dec     $EA
        dec     LA6ED
        bmi     LA456
        clc
        rts

LA456:  lda     #$17
        sta     LA6ED
        dec     LA6E8
        bpl     LA465
        lda     #$06
        sta     LA6E8
LA465:  dec     LA6EA
        beq     LA46C
        clc
        rts

LA46C:  dec     LA6E9
        lda     LA6E9
        .byte   $3A
        bmi     LA48C
        lda     #$0C
        sta     LA6E9
        lda     LA6EB
        sec
        sbc     #$01
        sta     LA6EB
        lda     LA6EC
        sbc     #$00
        sta     LA6EC
        clc
LA48C:  lda     LA6E9
        .byte   $3A
        tax
        lda     LA7F2,x
        sta     LA6EA
        rts

LA498:  lda     $EB
        bpl     LA4D3
        lda     $F0
        .byte   $3A
        cmp     #$0C
        bcc     LA4CE
        jsr     xmess
        .byte   $D4
        inx
        sbc     $F2
        sbc     $A0
        sbc     ($F2,x)
        sbc     $A0
        .byte   $EF
        inc     $F9EC
        ldy     #$B1
        .byte   $B2
        ldy     #$ED
        .byte   $EF
        inc     $E8F4
        .byte   $F3
        ldy     #$E9
        .byte   $EE
        .byte   $A0
LA4C2:  sbc     ($A0,x)
        sbc     $E1E5,y
        .byte   $F2
        lda     ($8D,x)
        brk
        jmp     LA604

LA4CE:  lda     $F0
        sta     LA6E9
LA4D3:  lda     $ED
        bpl     LA51B
        lda     $F2
        sec
        sbc     #$C0
        bmi     LA4E2
        cmp     #$64
        bcc     LA511
LA4E2:  jsr     xmess
        .byte   $D4
        inx
        sbc     $A0
        sbc     $E1E5,y
        .byte   $F2
        ldy     #$ED
        sbc     $F3,x
        .byte   $F4
        ldy     #$E2
        sbc     $A0
        .byte   $E2
        sbc     $F4
        .byte   $F7
        sbc     $E5
        inc     $B1A0
        lda     $B4B8,y
        ldy     #$E1
        inc     LA0E4
        .byte   $B2
        bcs     LA4C2
        .byte   $B3
        lda     ($8D,x)
        brk
        jmp     LA604

LA511:  lda     $F2
        sta     LA6EB
        lda     $F3
        sta     LA6EC
LA51B:  ldx     #$01
        lda     #$1C
        sta     LA7F2,x
        .byte   $64
        inc     $AD
        .byte   $EB
        ldx     $18
        lsr     a
        bcs     LA536
        clc
        lsr     a
        bcs     LA536
        dec     $E6
        lda     #$1D
        sta     LA7F2,x
LA536:  lda     $EC
        bpl     LA590
        lda     LA6E9
        .byte   $3A
        tax
        lda     LA7F2,x
        cmp     $F1
        bcs     LA58A
        pha
        jsr     xmess
        .byte   $D4
        inx
        sbc     $F2
        sbc     $A0
        sbc     ($F2,x)
        sbc     $A0
        .byte   $EF
        inc     $F9EC
        ldy     #$00
        pla
        tay
        lda     #$00
        jsr     xprdec_2
        jsr     xmess
        ldy     #$E4
        sbc     ($F9,x)
        .byte   $F3
        ldy     #$E9
        inc     a:$A0
        lda     LA6E9
        .byte   $3A
        asl     a
        tax
        lda     LA73D,x
        tay
        inx
        lda     LA73D,x
        jsr     LA80A
        lda     #$A1
        jsr     LFDED
        .byte   $20
LA585:  stx     $4CFD
        .byte   $04
        .byte   $A6
LA58A:  clc
        lda     $F1
        sta     LA6EA
LA590:  lda     $EE
        bpl     LA5C6
        lda     $F4
        cmp     #$18
        bcc     LA5C3
        jsr     xmess
        .byte   $D4
        inx
        sbc     $F2
        sbc     $A0
        sbc     ($F2,x)
        sbc     $A0
        .byte   $EF
        inc     $F9EC
        ldy     #$B2
        ldy     $A0,x
        inx
        .byte   $EF
        sbc     $F2,x
        .byte   $F3
        ldy     #$E9
        inc     $E1A0
        ldy     #$E4
        sbc     ($F9,x)
        lda     ($8D,x)
        brk
        jmp     LA604

LA5C3:  sta     LA6ED
LA5C6:  lda     $EF
        bpl     LA600
        lda     $F5
        cmp     #$3C
        bcc     LA5FD
        jsr     xmess
        .byte   $D4
        inx
        sbc     $F2
        sbc     $A0
        sbc     ($F2,x)
        sbc     $A0
        .byte   $EF
        inc     $F9EC
        ldy     #$B6
        bcs     LA585
        sbc     $EEE9
        sbc     $F4,x
        sbc     $F3
        ldy     #$E9
        inc     $E1A0
        inc     $E8A0
        .byte   $EF
        sbc     $F2,x
        lda     ($8D,x)
        brk
        jmp     LA604

LA5FD:  sta     LA6EE
LA600:  jsr     LA606
        rts

LA604:  sec
        rts

LA606:  lda     LA6EB
        sec
        sbc     #$C0
        sta     LA65E
        lda     LA6EC
        sbc     #$07
        sta     LA65F
        lda     LA6E9
        .byte   $3A
        .byte   $3A
        .byte   $3A
        sta     LA660
        bpl     LA625
        dec     LA65E
LA625:  lda     LA65E
        bmi     LA633
        lsr     a
        lsr     a
        clc
        adc     LA65E
        sta     LA65E
LA633:  lda     LA660
        bpl     LA63B
        clc
        adc     #$0C
LA63B:  tax
        lda     LA7FE,x
        clc
        adc     LA65E
        sta     LA65E
        lda     LA6EA
        clc
        adc     LA65E
        sta     LA65E
        tay
        lda     #$00
        ldx     #$07
        jsr     LA865
        tya
        sta     LA6E8
        clc
        rts

LA65E:  .byte   $A4
LA65F:  .byte   $A0
LA660:  .byte   $B0
LA661:  jsr     LA1C9
        jsr     LA1E5
        lda     LA6EF
        bne     LA661
        rts

LA66D:  lda     $36
        pha
        lda     $37
        pha
        .byte   $64
        rol     $A5,x
        sbc     ($85,x)
        .byte   $37
        lda     #$A1
        jsr     LFDED
        lda     LA6EB
        sec
        sbc     #$D0
        bpl     LA689
        clc
        adc     #$64
LA689:  jsr     LA83E
        tya
        .byte   $20
        .byte   $DA
LA68F:  sbc     $AFA9,x
        jsr     LFDED
        lda     LA6E9
        jsr     LA83E
        tya
        jsr     LFDDA
        lda     #$AF
        jsr     LFDED
        lda     LA6EA
        jsr     LA83E
        tya
        jsr     LFDDA
        lda     #$A0
        jsr     LFDED
        lda     #$00
        ldy     LA6E8
        jsr     xprdec_2
        lda     #$A0
        jsr     LFDED
        lda     LA6ED
        jsr     LA83E
        tya
        jsr     LFDDA
        lda     #$BA
        jsr     LFDED
        lda     LA6EE
        jsr     LA83E
        tya
        jsr     LFDDA
        jsr     xmess
        tsx
        bcs     LA68F
        sta     $6800
LA6E2:  sta     $37
        pla
        sta     $36
        rts

LA6E8:  .byte   $A0
LA6E9:  .byte   $A0
LA6EA:  .byte   $99
LA6EB:  .byte   $A0
LA6EC:  .byte   $A0
LA6ED:  .byte   $B0
LA6EE:  .byte   $A0
LA6EF:  .byte   $A0
LA6F0:  .byte   $13
        sed
        ldy     #$ED
        sbc     $E4AF
        cpx     $AF
        sbc     LA0F9,y
        inx
        inx
        tsx
        sbc     $BAED
        .byte   $F3
        .byte   $F3
LA704:  lda     $FBB3
        cmp     #$38
        beq     LA719
        cmp     #$EA
        beq     LA719
        lda     $FBC0
        cmp     #$EA
        beq     LA719
        clc
        bne     LA73C
LA719:  jsr     xbell
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
        bcs     LA6E2
        ldy     #$F2
        sbc     $F1
        sbc     $E9,x
        .byte   $F2
        sbc     $E4
        sta     $3800
LA73C:  rts

LA73D:  eor     $A7,x
        eor     $66A7,x
        .byte   $A7
        jmp     (L72A7)

        .byte   $A7
        ror     $A7,x
        .byte   $7B
        .byte   $A7
        .byte   $80
        .byte   $A7
        .byte   $87
        .byte   $A7
        sta     ($A7),y
        sta     LA2A7,y
        .byte   $A7
        .byte   $07
        dex
        sbc     ($EE,x)
        sbc     $E1,x
        .byte   $F2
        sbc     $C608,y
        sbc     $E2
        .byte   $F2
LA762:  sbc     $E1,x
        .byte   $F2
        sbc     $CD05,y
        sbc     ($F2,x)
        .byte   $E3
        inx
        ora     $C1
        beq     LA762
        sbc     #$EC
        .byte   $03
        cmp     $F9E1
        .byte   $04
        dex
        sbc     $EE,x
        sbc     $04
        dex
        sbc     $EC,x
        sbc     $C106,y
        sbc     $E7,x
        sbc     $F3,x
        .byte   $F4
        ora     #$D3
        sbc     $F0
        .byte   $F4
        sbc     $ED
        .byte   $E2
        sbc     $F2
        .byte   $07
        .byte   $CF
        .byte   $E3
        .byte   $F4
        .byte   $EF
        .byte   $E2
        sbc     $F2
        php
        dec     $F6EF
        sbc     $ED
        .byte   $E2
        sbc     $F2
        php
        cpy     $E5
        .byte   $E3
        sbc     $ED
        .byte   $E2
        sbc     $F2
LA7AB:  lda     $C0A7,y
        .byte   $A7
        .byte   $C7
        .byte   $A7
        .byte   $CF
        .byte   $A7
        cmp     $E2A7,y
        .byte   $A7
        sbc     #$A7
        asl     $D3
        sbc     $EE,x
        cpx     $E1
        sbc     $CD06,y
        .byte   $EF
        inc     $E1E4
        sbc     $D407,y
        sbc     $E5,x
        .byte   $F3
        cpx     $E1
        sbc     $D709,y
        sbc     $E4
        inc     $F3E5
        cpx     $E1
        sbc     $D408,y
        inx
        sbc     $F2,x
        .byte   $F3
        cpx     $E1
        sbc     $C606,y
        .byte   $F2
        sbc     #$E4
        sbc     ($F9,x)
        php
        .byte   $D3
        sbc     ($F4,x)
        sbc     $F2,x
        cpx     $E1
        .byte   $F9
LA7F2:  .byte   $1F
        .byte   $1C
        .byte   $1F
        asl     $1E1F,x
        .byte   $1F
        .byte   $1F
        asl     $1E1F,x
        .byte   $1F
LA7FE:  .byte   $03
        asl     $01
        .byte   $04
        asl     $02
        ora     $00
        .byte   $03
        ora     $01
        .byte   $04
LA80A:  sta     $E3
        sty     $E2
        txa
        pha
        ldy     #$00
        lda     ($E2),y
        beq     LA821
        tax
        iny
LA818:  lda     ($E2),y
        jsr     LFDED
        iny
        dex
        bne     LA818
LA821:  pla
        tax
        rts

LA824:  sec
        sbc     #$B0
        asl     a
        sta     LA83D
        asl     a
        asl     a
        clc
        adc     LA83D
        sta     LA83D
        tya
        sec
        sbc     #$B0
        clc
        adc     LA83D
        rts

LA83D:  .byte   $F5
LA83E:  ldy     #$FF
        sec
LA841:  iny
        sbc     #$64
        bcs     LA841
        adc     #$64
        tax
        tya
        pha
        txa
        ldy     #$FF
        sec
LA84F:  iny
        sbc     #$0A
        bcs     LA84F
        adc     #$0A
        sta     LA864
        tya
        asl     a
        asl     a
        asl     a
        asl     a
        ora     LA864
        tay
        pla
        rts

LA864:  .byte   $A0
LA865:  sty     LA88D
        sta     LA88E
        stx     LA88F
        ldx     #$08
        sty     LA890
LA873:  asl     LA890
        rol     a
        cmp     LA88F
        bcc     LA882
        sbc     LA88F
        inc     LA890
LA882:  dex
        bne     LA873
        sta     LA891
        tay
        lda     LA890
        rts

LA88D:  .byte   $A0
LA88E:  .byte   $CC
LA88F:  .byte   $A0
LA890:  .byte   $A0
LA891:  .byte   $A0
LA892:  pha
        sty     $25
        sty     $05FB
        tya
        jsr     LFBC1
        stx     $24
        stx     $057B
        pla
        rts

LA8A3:  pha
        .byte   $5A
        .byte   $DA
        ldy     LA930
        lda     LA931
        sty     $E4
        sta     $E5
        sta     $C001
        ldx     #$00
LA8B5:  lda     LA932,x
        sta     $E2
        lda     LA94A,x
        sta     $E3
        ldy     #$00
LA8C1:  sta     $C055
        lda     ($E2),y
        sta     $C054
        .byte   $92
        cpx     $20
        and     #$A9
        lda     ($E2),y
        .byte   $92
        cpx     $20
        and     #$A9
        iny
        cpy     #$28
        bne     LA8C1
        inx
        cpx     #$18
        bne     LA8B5
        sta     $C000
        .byte   $FA
        .byte   $7A
        pla
        rts

LA8E6:  pha
        .byte   $5A
        .byte   $DA
        ldy     LA930
        lda     LA931
        sty     $E4
        sta     $E5
        sta     $C001
        ldx     #$00
LA8F8:  lda     LA932,x
        sta     $E2
        lda     LA94A,x
        sta     $E3
        ldy     #$00
LA904:  .byte   $B2
        cpx     $8D
        eor     $C0,x
        sta     ($E2),y
        sta     $C054
        jsr     LA929
        .byte   $B2
        cpx     $91
LA914:  .byte   $E2
        .byte   $20
LA916:  and     #$A9
LA918:  iny
        .byte   $C0
LA91A:  plp
        bne     LA904
        inx
        cpx     #$18
        bne     LA8F8
        sta     $C000
        .byte   $FA
        .byte   $7A
        pla
        rts

LA929:  inc     $E4
        bne     LA92F
        inc     $E5
LA92F:  rts

LA930:  .byte   $A0
LA931:  .byte   $A0
LA932:  brk
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
        bvc     LA914
        bvc     LA916
        bvc     LA918
        bvc     LA91A
LA94A:  .byte   $04
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
