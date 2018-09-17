;
; Disassembling fi
;  - main goal achieved: recognize p8c as davex external commands
;  - next goal: remove auto-disassembler Lxxxx labels 
;  - reconstruct a symbolic assembly to make enhancements easier to do
;
; Notes:
;  - Linked version should be 3517 bytes long until it's all symbolic.
;  - Should remove dependency on 65c02.
;  - Should merge this function into 'what' external, also hunt down any other similar externals 
;  

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_A000"
.org	$a000
OrgAddr	= $a000

MyVersion	= $14
MinVersion	= $12
MinVerAux	= $03

fi_ptr	= $e2

	rts
	.addr $eeee
	.byte MyVersion, MinVersion
	.byte $00	; hardware required
	.addr descr
	.addr OrgAddr
	.addr start
	.byte MinVerAux
	.byte 0, 0, 0, 0
	.byte $04
	.byte 0, 0
descr:	pstr_hi "fi -- File Information : External Command / by Jeff Hansen"
start:	nop
	sty LA81F
	sta LA820
	sty LA831
	sta LA832
	sty $E0
	sta $E1
	jsr machine_check
	bcc go_ahead
LA065:	jmp return_to_davex

go_ahead:
	ldx #mli_close
	jsr xmmgr
	ldx #mli_open
	lda #$02
	jsr xmmgr
	bcc memok
	jsr xmess
	.byte $8d
	asc "*** error: out of memory"
	.byte $8d, $00 
	jmp xerr

memok:	sta LA839
	sta $E3
	sta $E5
	.byte   $9C
	sec
LA0A0:	tay
	.byte   $64
	.byte   $E2
	.byte   $64
	cpx $A9
	brk
	jsr xredirect
	sta $E6
	jsr mli
	.byte mli_gfinfo
	.addr gfinfo_parms
	
LA0B2:	.byte $90
LA0B3:	.byte $03
	jmp xProDOS_err

LA0B7:	jsr mli
LA0BA:	.byte mli_open
	.addr open_parms
	bcc LA0C2
	jmp xProDOS_err

LA0C2:	lda LA835
	sta LA841
	sta LA837
	sta LA83F
	jsr mli
	.byte mli_geteof
	.addr geteof_parms
	bcc LA0D9
	jmp xProDOS_err

LA0D9:	.byte   $64
	inx
	lda LA842
	bne LA0EE
	lda LA843
	.byte   $D0
LA0E4:	.byte   $09
LA0E5:	lda LA844
	bne LA0EE
	dec $E8
	.byte   $80
	.byte   $0B
LA0EE:	jsr mli
	.byte mli_read
	.addr read_parms
LA0F4:	bcc read_ok
	jmp xProDOS_err

read_ok:	jsr mli
	.byte mli_close
	.addr close_parms
	bcc LA104
	jmp xProDOS_err

LA104:	jsr crout
	ldy $E0
	lda $E1
	jsr xprint_path
	jsr xmess
	asc_hi "  ("
	.byte $00
	lda $BF30
	jsr xprint_sd
	jsr xmess
	asc_hi ")"
	.byte $8d, $00
	jsr horiz_line
	jsr xmess
	asc_hi "File Access: "
	.byte $00
	lda LA821
	jsr xprint_access
	jsr xmess
	asc_hi " $"
	.byte $00
	lda LA821
	jsr LAD22
	jsr xmess
	asc_hi " ="
	.byte $00
	lda LA821
	sta $61
	lda #$00
	sta $62
	sta $63
	ldy #$08
	jsr xprdec_pady
	jsr xmess
	asc_hi	"   %"
	.byte $00
	lda LA821
	jsr LAD43
	jsr LAD06
	jsr xmess
	asc_hi " (dnB---wr)"
	.byte $8d, 00
	jsr horiz_line
	jsr xmess
	asc_hi "File Type:    ("
	.byte $00
	lda LA822
	jsr xprint_ftype
	jsr xmess
	asc_hi ") $"
	.byte $00	
	lda LA822
	jsr LAD22
	jsr xmess
	asc_hi " ="
	.byte $00
	lda LA822
	sta $61
	lda #$00
	sta $62
	sta $63
	ldy #$08
	jsr xprdec_pady
	jsr xmess
	asc_hi "   Auxiliary Type:   $"
	.byte $00
	lda LA824
	jsr LAD22
	lda LA823
	jsr LAD22
	jsr xmess
	asc_hi " ="
	.byte $00
	lda LA823
	sta $61
	lda LA824
	sta $62
	lda #$00
	sta $63
	ldy #$08
	jsr xprdec_pady
	jsr crout
	jsr xmess
	asc_hi "Storage Type:       $"
	.byte $00
	lda LA825
	jsr LAD22
	jsr xmess
	asc_hi " ="
	.byte $00
	lda LA825
	sta $61
	lda #$00
	sta $62
	sta $63
	ldy #$08
	jsr xprdec_pady
	jsr xmess
	asc_hi "   "
	.byte $00
	ldx #$00
	lda LA845,x
	beq LA258
	cmp LA825
	beq LA24C
	inx
	inx
	inx
	.byte   $80	; bra $a23d
	.byte   $F1
LA24C:	inx
	lda LA845,x
	tay
	inx
	lda LA845,x
	jsr LAD06
LA258:	jsr crout
	jsr horiz_line
	jsr xmess
	asc_hi "Blocks:           $"
	.byte $00
	lda LA827
	jsr LAD22
	lda LA826
	jsr LAD22
	jsr xmess
	asc_hi " ="
	.byte $00
	lda LA826
	sta $61
	lda LA827
	sta $62
	lda #$00
	sta $63
	ldy #$08
	jsr xprdec_pady
	jsr xmess
	asc_hi "   Length:         $"
	.byte $00
	lda LA844
	jsr LAD22
	lda LA843
	jsr LAD22
	lda LA842
	jsr LAD22
	jsr xmess
	asc_hi " = "
	.byte $00
	lda LA842
	sta $61
	lda LA843
	sta $62
	lda LA844
	sta $63
	jsr xprdec_pad
	jsr crout
	jsr horiz_line
	jsr xmess
	asc_hi "Created:       "
	.byte $00
	ldy LA82C
	lda LA82D
	jsr xpr_date_ay
	ldy LA82E
	lda LA82F
	jsr xpr_time_ay
	jsr xmess
	asc_hi "   Modified:      "
	.byte $00
	ldy LA828
	lda LA829
	jsr xpr_date_ay
	ldy LA82A
	lda LA82B
	jsr xpr_time_ay
	jsr crout
	ldx #$00
LA335:	lda LA8E4,x
	beq LA35A
	cmp LA822
	beq LA342
	inx
	bne LA335
LA342:	.byte   $DA
	jsr horiz_line
	pla
	asl a
	tax
	lda LA906,x
	tay
	inx
	lda LA906,x
	jsr LAD06
	jsr crout
	jmp return_to_davex

LA35A:	lda $E8
	bpl LA361
	jmp return_to_davex

LA361:	lda LA822
	.byte   $C9
LA365:	.byte   $FF
	beq LA36B
	jmp LA44B

LA36B:	jsr horiz_line
	jsr xmess
	asc_hi "ProDOS 8 SYStem Application"
	.byte $8d, $00
	ldy #$00
	lda (fi_ptr),y
	cmp #$4C		; Is the zeroeth byte $4c?
	beq maybe_davex	; Yes - might be davex
	cmp #$6C		; Is it $6c?
	bne LA3CD		; No - not davex
maybe_davex:
	ldy #$03
	lda (fi_ptr),y
	cmp #$EE		; Is the third byte (0-indexed) $ee?
	bne LA3CD		; No - not davex
	iny
	lda (fi_ptr),y	; Is the fourth byte $ee too?
	cmp #$EE
	bne LA3CD		; No - not davex
	jsr xmess
	asc_hi "  Startup Buffer: "
	.byte $a2, $00
	lda $E3
	ldy #$06
	jsr xprint_path
	jsr xmess
	.byte $a2, $8d, $00
LA3CD:	ldy #$00
	lda (fi_ptr),y
	cmp #$4C
	bne LA448
	iny
	lda (fi_ptr),y
	cmp #$4C
	bne LA448
	iny
	lda (fi_ptr),y
	cmp #$20
	bne LA448
	iny
	lda (fi_ptr),y
	cmp #$EE
	bne LA448
	lda LA842
	cmp #$67
	bne LA448
	lda LA843
	cmp #$01
	bne LA448
	jsr xmess
	asc_hi "  SYSalias for:   "
	.byte $a2, $00
	clc
	lda fi_ptr
	adc #$E5
	tay
	lda $E3
LA417:	adc #$00
	jsr xprint_path
	jsr xmess
	.byte $a2, $8d
	asc_hi "  Prefix:         "
	.byte $a2, $00
	clc
	lda fi_ptr
	adc #$26
	tay
	lda $E3
	adc #$01
	jsr xprint_path
	jsr xmess
	.byte $a2, $8d, $00
LA448:	jmp return_to_davex

LA44B:	lda LA822
	cmp #$2e		; Is the filetype $2e (P8C)? [was: $06 (BIN)]
	beq is_p8c		; Yes
	jmp LA586

is_p8c:	ldy #$00
	lda (fi_ptr),y
	cmp #$60		; Is the zeroeth byte $60?
	bne LA46B		; No - not a davex external
	iny
	lda (fi_ptr),y
	cmp #$EE		; Is the first byte $ee?
	bne LA46B		; No - not a davex external
	iny
	lda (fi_ptr),y
	cmp #$EE		; Is the second byte $ee?
	beq print_davex_xtrn	; Yes - davex external!
LA46B:	jmp LA586

print_davex_xtrn:
	jsr horiz_line
	jsr xmess
	asc_hi "Davex ("
	.byte $00
	ldy #$03
	ldx #$00
:	lda (fi_ptr),y
	sta LA814,x
	iny
	inx
	cpx #$0A
	bne :-
	lda LA815
	jsr pr_version
	lda LA81D
	ora #$B0
	jsr cout
	jsr xmess
	asc_hi "+) External Command, Version: "
	.byte $00
	lda LA814
	jsr pr_version
	jsr xmess
	.byte $8d
	asc_hi "  Descr: "
	.byte $00
	sec
	lda LA817
	sbc LA819
	sta LA817
	lda LA818
	sbc LA81A
LA4DF:	sta LA818
	clc
	lda $E3
	adc LA818
	sta LA818
	ldy LA817
	lda LA818
	jsr LAD06
	jsr crout
	jsr xmess
	ldy #$A0
	bne LA4DF
	.byte   $F2
	sbc ($ED,x)
	sbc $F4
	sbc $F2
	.byte   $F3
	tsx
	brk
	ldy #$10
	lda (fi_ptr),y
	bne LA520
	iny
	lda (fi_ptr),y
	bne LA520
	jsr xmess
	ldy #$EE
	.byte   $EF
	inc $8DE5
	brk
	jmp return_to_davex

LA520:	jsr crout
	ldy #$10
LA525:	lda (fi_ptr),y
	sta LA812
	iny
	lda (fi_ptr),y
	sta LA813
	iny
	sty $E7
	lda LA812
	bne LA53D
	lda LA813
	beq LA586
LA53D:	jsr xmess
	asc_hi "              "
	.byte $00
	lda LA812
	bne LA55C
	jsr xmess
	asc_hi "  "
	.byte $00
	.byte   $80
	.byte   $0D
LA55C:	lda #$AD
	jsr cout
	lda LA812
	ora #$80
	jsr cout
	jsr xmess
	asc_hi "  "
	.byte $00
	lda LA813
	asl a
	tax
	lda LAC71,x
	tay
	inx
	lda LAC71,x
	jsr LAD06
	jsr crout
	ldy $E7
	bne LA525
LA586:	ldy #$00
	lda (fi_ptr),y
	cmp #$0A
	bne LA5A4
	iny
	lda (fi_ptr),y
	cmp #$47
	bne LA5A4
	iny
	lda (fi_ptr),y
	cmp #$4C
	bne LA5A4
	ldy #$12
	lda (fi_ptr),y
	cmp #$02		; Yes - Binary ][ envenlope
	beq print_binaryII
LA5A4:	jmp check_shrinkit

print_binaryII:
	jsr horiz_line
	jsr xmess
	asc_hi "Binary ][ (v."
	.byte $00
	ldy #$7E
	lda (fi_ptr),y
	tay
	lda #$00
	jsr xprdec_2
	jsr xmess
	asc_hi ") Envelope"
	.byte $8d
	asc_hi "  Contains "
	.byte $00
	ldy #$7F
	lda (fi_ptr),y
	.byte   $1A
	pha
	tay
	lda #$00
	jsr xprdec_2
	jsr xmess
	asc_hi " file"
	.byte $00
	lda #$00
	.byte   $7A
	jsr xplural
	jsr crout
	jmp return_to_davex

check_shrinkit:
	ldy #$00
	lda (fi_ptr),y
	cmp #$4E		; Zeroeth byte $4e?
	bne LA62B		; No - not ShrinkIt
	iny
	lda (fi_ptr),y
	cmp #$F5		; First byte $f5?
	bne LA62B		; No - not ShrinkIt
	iny
	lda (fi_ptr),y
	cmp #$46		; Second byte $46?
	bne LA62B		; No - not ShrinkIt
	iny
	lda (fi_ptr),y
	cmp #$E9		; Third byte $e9?
	bne LA62B		; No - not ShrinkIt
	iny
	lda (fi_ptr),y
	cmp #$6C		; Fourth byte $6c?
	bne LA62B		; No - not ShrinkIt
	iny
	lda (fi_ptr),y
	cmp #$E5		; Fifth byte $e5?
	beq print_shrinkit	; Yes - it's ShrinkIt!
LA62B:	jmp LA692

print_shrinkit:
	jsr horiz_line
	jsr xmess
	asc_hi "ShrinkIt/NuFX (v."
	.byte $00
	ldy #$1C
	lda (fi_ptr),y
	pha
	iny
	lda (fi_ptr),y
	.byte   $7A
	jsr xprdec_2
	jsr xmess
	asc_hi ") Archive"
	.byte $8d
	asc_hi "  Contains "
	.byte $00
	ldy #$08
	lda (fi_ptr),y
	pha
	iny
	lda (fi_ptr),y
	.byte   $7A
	jsr xprdec_2
	jsr xmess
	asc_hi " file"
	.byte $00
	ldy #$08
	lda (fi_ptr),y
	pha
	iny
	lda (fi_ptr),y
	.byte   $7A
	jsr xplural
	jsr crout
	jmp return_to_davex

LA692:	ldx #$10
	ldy #$10
LA696:	dex
	dey
	bmi print_davex_archive
	lda (fi_ptr),y
	cmp LA6A4,x
	beq LA696
	jmp return_to_davex

LA6A4:	rts

	lsr $53,x
	.byte   $54
	.byte   $4F
	.byte   $52
	eor $20
	.byte   $5B
	.byte   $44
	adc ($76,x)
	adc $78
	.byte   $5D
	brk
print_davex_archive:
	jsr horiz_line
	jsr xmess
	asc_hi "Davex Archived Volume"
	.byte $8d
	asc_hi "  Requires: VSTORE v"
	.byte $00
	ldy #$11
	lda (fi_ptr),y
	jsr pr_version
	jsr xmess
	asc_hi "+, VRESTORE v"
	.byte $00
	ldy #$12
	lda (fi_ptr),y
	jsr pr_version
	jsr xmess
	.byte   $AB
	sta LA0A0
	dec $EDE1
	sbc $BA
	ldy #$AF
	brk
	lda $E3
	ldy #$29
	jsr xprint_path
	jsr xmess
	ldy #$A8
	brk
	ldy #$20
	lda (fi_ptr),y
	jsr xprint_sd
	jsr xmess
	lda #$8D
	ldy #$A0
	dec $EF,x
	cpx $EDF5
	sbc $A0
	inx
	sbc ($F3,x)
	tsx
	ldy #$00
	ldy #$21
	lda (fi_ptr),y
	pha
	iny
	lda (fi_ptr),y
	.byte   $7A
	jsr xprdec_2
	jsr xmess
	ldy #$e2
	cpx $E3EF
	.byte   $EB
	.byte   $F3
	ldy a:$A0
	ldy #$25
	lda (fi_ptr),y
	pha
	iny
	lda (fi_ptr),y
	.byte   $7A
	jsr xprdec_2
	jsr xmess
	ldy #$F5
	.byte   $F3
	sbc $E4
	.byte   $8D
	brk
return_to_davex:
	ldx #$CC
	jsr xmmgr
	rts

horiz_line:
	lda $E6
	bmi dashed_line
	jsr xmess
	.byte $8f, $9b
	asc_hi "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS"
	.byte $98, $8E, $8D, $00
	rts

dashed_line:
	jsr xmess
	asc_hi "-----------------------------------------------------------------------"
	.byte $8d, 00
	rts

; This latter section seems to be a lot of variables, string constants, and a lookup table into those strings. 

LA812:	.byte   $A0
LA813:	.byte   $A0
LA814:	.byte   $EF
LA815:	ldy     #$A0
LA817:	.byte   $A0
LA818:	.byte   $A0
LA819:	.byte   $A0
LA81A:	ldy     #$80
	.byte   $A0
LA81D:	.byte $81
gfinfo_parms:
	.byte $0a
LA81F:	.byte   $B0
LA820:	.byte   $80
LA821:	.byte   $BE
LA822:	.byte   $A0
LA823:	.byte   $A0
LA824:	.byte   $EE
LA825:	.byte   $A0
LA826:	.byte   $A0
LA827:	.byte   $B0
LA828:	.byte   $A0
LA829:	.byte   $A0
LA82A:	.byte   $B0
LA82B:	.byte   $D0
LA82C:	.byte   $A0
LA82D:	.byte   $A0
LA82E:	tax
LA82F:	.byte $A0
open_parms:
	.byte $03
LA831:	.byte   $A0
LA832:	ldy     #$00
	php
LA835:	.byte $a0
read_parms:
	.byte $04
LA837:	ldy     #$EF
LA839:	ldy     #$00
	.byte   $02
	ldy     #$A0
close_parms:
	.byte $01
LA83F:	.byte $a0
geteof_parms:
	.byte $02
LA841:	.byte   $E9
LA842:	.byte   $A0
LA843:	.byte   $B0
LA844:	.byte   $A0
LA845:	ora     ($5E,x)
	tay
	.byte   $02
	adc     #$A8
	.byte   $03
	.byte   $73
	tay
	.byte   $04
	.byte   $7A
	tay
	ora     $93
	tay
	ora     LA8A8
	asl     LA8B4
	.byte   $0F
	dex
	tay
	brk
	asl     a
	tay
	.byte   $D3
	sbc     $E5
	cpx     $EC
	sbc     #$EE
	.byte   $E7
	lda     #$09
	tay
	.byte   $D3
LA86C:	sbc     ($F0,x)
	cpx     $EEE9
	.byte   $E7
	lda     #$06
	tay
	.byte   $D4
	.byte   $F2
	sbc     $E5
	lda     #$18
	tay
	cmp     ($F0,x)
	beq     LA86C
	sbc     $A0
	cmp     #$C9
	ldy     #$D0
	sbc     ($F3,x)
	.byte   $E3
	sbc     ($EC,x)
	ldy     #$D6
	.byte   $EF
	cpx     $EDF5
	sbc     $A9
	.byte   $14
	tay
	.byte   $C7
	.byte   $D3
	.byte   $CF
	.byte   $D3
	ldy     #$C5
	sed
	.byte   $F4
	sbc     $EE
	.byte   $E4
LA8A0:	sbc     $E4
	ldy     #$C6
	sbc     #$EC
	sbc     $A9
LA8A8:	.byte   $0B
	tay
	cpy     $E9
	.byte   $F2
	sbc     $E3
	.byte   $F4
	.byte   $EF
	.byte   $F2
	.byte   $F9
	.byte   $A9
LA8B4:	ora     $A8,x
	.byte   $D3
	sbc     $E2,x
	cpx     $E9
	.byte   $F2
	sbc     $E3
	.byte   $F4
	.byte   $EF
	.byte   $F2
	sbc     $C8A0,y
	sbc     $E1
	cpx     $E5
	.byte   $F2
	lda     #$19
	tay
LA8CC:	dec     $EF,x
	cpx     $EDF5
	sbc     $A0
	cpy     $E9
	.byte   $F2
	sbc     $E3
	.byte   $F4
	.byte   $EF
	.byte   $F2
	.byte   $F9
	.byte   $A0
LA8DD:	iny
	sbc     $E1
	cpx     $E5
	.byte   $F2
LA8E3:	.byte   $A9
LA8E4:	ora     ($0F,x)
	.byte   $19
LA8E7:	.byte   $1A
	.byte   $1B
	.byte   $AB
	ldy     $B0AD
	lda     ($B2),y
	.byte   $B3
	ldy     $B5,x
	ldx     $B7,y
	clv
	lda     $BCBB,y
	lda     $C1C0,x
	iny
	cmp     #$CA
	sbc     ($EE,x)
	.byte   $FA
	.byte   $FB
	.byte   $FC
	sbc     a:$FE,x
LA906:	pha
	lda     #$51
	lda     #$6B
	lda     #$84
	lda     #$A4
	lda     #$C0
	lda     #$D3
	lda     #$F3
	lda     #$08
	tax
	clc
	tax
	.byte   $32
	tax
	.byte   $44
	tax
	eor     $AA,x
	bvs     LA8CC
	.byte   $87
	tax
	lda     $AA
	.byte   $C3
	tax
	inx
	tax
	ora     $AB,x
	and     ($AB,x)
	.byte   $33
	.byte   $AB
	bvc     LA8DD
	.byte   $67
	.byte   $AB
	sta     ($AB,x)
	bcc     LA8E3
	lda     ($AB,x)
	bcs     LA8E7
	iny
	.byte   $AB
	.byte   $E7
	.byte   $AB
	.byte   $02
	ldy     LAC1E
	.byte   $3B
	ldy     LAC59
	php
	.byte   $C2
	sbc     ($E4,x)
	ldy     #$E6
	sbc     #$EC
	sbc     $19
	cpy     $E9
	.byte   $F2
	sbc     $E3
	.byte   $F4
	.byte   $EF
	.byte   $F2
	sbc     $EFA0,y
	.byte   $F2
	.byte   $A0
LA95F:	.byte   $D3
	sbc     $E2,x
	cpx     $E9
	.byte   $F2
	sbc     $E3
	.byte   $F4
	.byte   $EF
	.byte   $F2
	sbc     $C118,y
	beq     LA95F
	cpx     $D7E5
	.byte   $EF
	.byte   $F2
	.byte   $EB
LA975:	.byte   $F3
	ldy     #$C4
	sbc     ($F4,x)
	sbc     ($E2,x)
	sbc     ($F3,x)
	sbc     $A0
	inc     $E9
	cpx     $1FE5
	cmp     ($F0,x)
	beq     LA975
LA989:	sbc     $D7
	.byte   $EF
	.byte   $F2
	.byte   $EB
	.byte   $F3
	ldy     #$D7
	.byte   $EF
	.byte   $F2
	cpx     $A0
LA995:	bne     LA989
	.byte   $EF
	.byte   $E3
	sbc     $F3
	.byte   $F3
	sbc     #$EE
	.byte   $E7
	ldy     #$E6
	sbc     #$EC
	sbc     $1B
LA9A5:	cmp     ($F0,x)
	beq     LA995
	sbc     $D7
	.byte   $EF
	.byte   $F2
	.byte   $EB
	.byte   $F3
	ldy     #$D3
	beq     LA9A5
	sbc     $E1
	cpx     $F3
	inx
	sbc     $E5
	.byte   $F4
	ldy     #$E6
	sbc     #$EC
	sbc     $12
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$C2
	cmp     ($D3,x)
	cmp     #$C3
	ldy     #$F0
	.byte   $F2
	.byte   $EF
	.byte   $E7
	.byte   $F2
	sbc     ($ED,x)
	.byte   $1F
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$C2
	cmp     ($D3,x)
	cmp     #$C3
	ldy     #$D4
	.byte   $EF
	.byte   $EF
	cpx     $C4A0
LA9E5:	sbc     $E6
	sbc     #$EE
	sbc     #$F4
	sbc     #$EF
	inc     $E6A0
	sbc     #$EC
	sbc     $14
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$C2
	cmp     ($D3,x)
	cmp     #$C3
	ldy     #$E4
	sbc     ($F4,x)
	sbc     ($A0,x)
	inc     $E9
	cpx     $0FE5
	cmp     ($D0,x)
	.byte   $D7
	ldy     #$D3
	.byte   $EF
	sbc     $F2,x
	.byte   $E3
	sbc     $A0
	inc     $E9
	cpx     $19E5
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$CF
	.byte   $E2
	nop
	sbc     $E3
	.byte   $F4
	ldy     #$E6
	sbc     #$EC
	sbc     $A0
	tay
	cpy     $EEE9
	.byte   $EB
	sbc     $F2
	lda     #$11
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$CC
	sbc     #$E2
	.byte   $F2
	.byte   $E1
LAA3D:	.byte   $F2
	sbc     $E6A0,y
	sbc     #$EC
	sbc     $10
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$C1
	beq     LAA3D
	cpx     $E3E9
	sbc     ($F4,x)
	sbc     #$EF
	inc     $D01A
	.byte   $F2
	.byte   $EF
	cpy     $CF
	.byte   $D3
	ldy     #$B1
	ldx     $A0,y
	.byte   $D2
	sbc     $EE,x
	lda     $E9D4
	sbc     LA0E5
	cpx     $E2E9
	.byte   $F2
	sbc     ($F2,x)
LAA6F:	sbc     $C916,y
	cmp     #$E7
	.byte   $F3
	ldy     #$D3
	inx
	.byte   $E5
LAA79:	cpx     $A0EC
	sbc     ($F0,x)
	beq     $AA6C
	sbc     #$E3
	sbc     ($F4,x)
	sbc     #$EF
	inc     $D01D
	.byte   $F2
	.byte   $EF
	cpy     $CF
	.byte   $D3
	ldy     #$B1
	ldx     $A0,y
	bne     LAA79
	.byte   $F2
	sbc     $EEE1
	sbc     $EE
LAA9A:	.byte   $F4
	ldy     #$C9
	inc     $F4E9
	ldy     #$E6
	sbc     #$EC
LAAA4:	sbc     $1D
	bne     LAA9A
	.byte   $EF
	.byte   $C4
LAAAA:	.byte   $CF
	.byte   $D3
	ldy     #$B1
	ldx     $A0,y
	.byte   $D4
	sbc     $ED
	beq     LAAA4
	.byte   $F2
	sbc     ($F2,x)
	sbc     $C9A0,y
	inc     $F4E9
	ldy     #$E6
	sbc     #$EC
	sbc     $24
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$CE
	sbc     $F7
	.byte   $A0
LAACD:	cpy     $E5
	.byte   $F3
	.byte   $EB
	ldy     #$C1
	.byte   $E3
	.byte   $E3
	sbc     $F3
	.byte   $F3
	.byte   $EF
	.byte   $F2
	sbc     LA8A0,y
	cmp     ($F0,x)
	beq     LAACD
	sbc     $A0
	cmp     $EEE5
	sbc     $A9,x
	bit     $C9C9
	.byte   $E7
	.byte   $F3
	ldy     #$C3
	cpx     $F3E1
	.byte   $F3
	sbc     #$E3
	.byte   $A0
LAAF6:	cpy     $E5
	.byte   $F3
	.byte   $EB
	ldy     #$C1
	.byte   $E3
	.byte   $E3
	sbc     $F3
	.byte   $F3
	.byte   $EF
	.byte   $F2
	sbc     LA8A0,y
	cmp     ($F0,x)
	beq     LAAF6
	sbc     $AD
	.byte   $C3
	.byte   $F4
	.byte   $F2
	cpx     $C5AD
	.byte   $F3
	.byte   $E3
	lda     #$0B
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$C4
	.byte   $F2
	sbc     #$F6
	sbc     $F2
	ora     ($C7),y
	sbc     $EE
	sbc     $F2
	sbc     #$E3
	ldy     #$CC
	.byte   $EF
	sbc     ($E4,x)
	ldy     #$E6
	sbc     #$EC
	sbc     $1C
	.byte   $C7
	.byte   $D3
	.byte   $AF
	.byte   $CF
	.byte   $D3
	ldy     #$C6
	sbc     #$EC
	sbc     $A0
	.byte   $D3
	sbc     $F4F3,y
	sbc     $ED
	ldy     #$D4
	.byte   $F2
	sbc     ($EE,x)
	.byte   $F3
	.byte   $EC
	.byte   $E1
LAB4D:	.byte   $F4
	.byte   $EF
	.byte   $F2
	asl     $D0,x
	sbc     ($E3,x)
	.byte   $EB
	sbc     $E4
	ldy     #$D0
	sbc     ($E9,x)
	inc     $D7F4
	.byte   $EF
	.byte   $F2
	.byte   $EB
	.byte   $F3
	ldy     #$E6
	sbc     #$EC
	sbc     $19
	cmp     $EE,x
	beq     LAB4D
	.byte   $E3
	.byte   $EB
	sbc     $E4
	ldy     #$D3
	sbc     $F0,x
	sbc     $F2
	lda     $E9C8
	.byte   $F2
	sbc     $F3
	ldy     #$E6
	sbc     #$EC
	sbc     $0E
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$C6
	.byte   $EF
	inc     LA0F4
	inc     $E9
	cpx     $10E5
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$C6
	sbc     #$EE
	cpx     $E5
	.byte   $F2
	ldy     #$E4
	sbc     ($F4,x)
	sbc     ($0E,x)
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$C9
	.byte   $E3
	.byte   $EF
	inc     $E6A0
	sbc     #$EC
	sbc     $17
	cmp     #$C9
	.byte   $E7
	.byte   $F3
	ldy     #$D7
	sbc     ($F6,x)
	sbc     $E2
	sbc     ($EE,x)
LABBD:	.byte   $EB
	ldy     #$C4
	sbc     ($F4,x)
	sbc     ($A0,x)
	inc     $E9
	cpx     $1EE5
	bne     LABBD
	.byte   $EF
	cpy     $CF
	.byte   $D3
	ldy     #$B1
	ldx     $A0,y
	.byte   $D2
	sbc     $EC
	sbc     ($F4,x)
	sbc     #$F6
	sbc     $A0
	.byte   $CF
	.byte   $E2
	nop
	sbc     $E3
	.byte   $F4
	ldy     #$E6
	sbc     #$EC
	sbc     $1A
	cmp     #$EE
	.byte   $F4
	sbc     $E7
	sbc     $F2
	ldy     #$C2
	cmp     ($D3,x)
	cmp     #$C3
	ldy     #$D0
	.byte   $F2
	.byte   $EF
	.byte   $E7
	.byte   $F2
	sbc     ($ED,x)
	ldy     #$E6
	sbc     #$EC
	sbc     $1B
	cmp     #$EE
	.byte   $F4
	sbc     $E7
	sbc     $F2
	ldy     #$C2
	cmp     ($D3,x)
	.byte   $C9
LAC0F:	.byte   $C3
	ldy     #$D6
	sbc     ($F2,x)
	sbc     #$E1
	.byte   $E2
	cpx     LA0E5
	inc     $E9
	.byte   $EC
	.byte   $E5
LAC1E:	.byte   $1C
	cmp     ($F0,x)
	beq     LAC0F
	sbc     $D3
	.byte   $EF
	inc     $F4
	ldy     #$C2
	cmp     ($D3,x)
LAC2C:	cmp     #$C3
	ldy     #$D0
	.byte   $F2
	.byte   $EF
	.byte   $E7
	.byte   $F2
	sbc     ($ED,x)
	ldy     #$E6
	sbc     #$EC
	sbc     $1D
	cmp     ($F0,x)
	beq     LAC2C
	sbc     $D3
	.byte   $EF
	inc     $F4
	ldy     #$C2
	cmp     ($D3,x)
	cmp     #$C3
	ldy     #$D6
	sbc     ($F2,x)
	sbc     #$E1
	.byte   $E2
	cpx     LA0E5
	inc     $E9
	.byte   $EC
	.byte   $E5
LAC59:	.byte   $17
	.byte   $D2
	sbc     $EC
	.byte   $EF
	.byte   $E3
	sbc     ($F4,x)
	sbc     ($E2,x)
	cpx     LA0E5
	.byte   $CF
	.byte   $E2
	nop
	sbc     $E3
	.byte   $F4
	ldy     #$E6
	sbc     #$EC
	.byte   $E5
LAC71:	.byte $85, $ac
	stx     $9DAC
	ldy     LACAC
	ldy     $D1AC,x
	ldy     $ACD8
	.byte   $E7
	ldy     $ACEE
	sed
	ldy     $EE08
	.byte   $EF
	ldy     #$F6
	sbc     ($EC,x)
	sbc     $E5,x
	asl     LA0B2
	.byte   $E2
	sbc     $E5F4,y
	ldy     #$E9
	inc     $E5F4
	.byte   $E7
	sbc     $F2
	asl     LA0B3
	.byte   $E2
LACA1:	sbc     $E5F4,y
	ldy     #$E9
	inc     $E5F4
	.byte   $E7
	sbc     $F2
LACAC:	.byte   $0F
	bne     LACA1
	.byte   $EF
	.byte   $C4
LACB1:	.byte   $CF
	.byte   $D3
	ldy     #$F0
	sbc     ($F4,x)
	inx
	inc     $EDE1
	sbc     $14
	bne     LACB1
	.byte   $EF
	cpy     $CF
	.byte   $D3
	ldy     #$F7
	sbc     #$EC
	cpx     $DF
	beq     LACAC
	.byte   $F4
	inx
	inc     $EDE1
	sbc     $06
	.byte   $F3
	.byte   $F4
	.byte   $F2
	sbc     #$EE
	.byte   $E7
	.byte $0e, $b1, $a0
	.byte   $E2
	sbc     $E5F4,y
	ldy     #$E9
	inc     $E5F4
LACE4:	.byte   $E7
	sbc     $F2
	asl     $F9
	sbc     $F3
	.byte   $AF
	.byte   $EE
	.byte   $EF
LACEE:	ora     #$E6
	sbc     #$EC
	sbc     $DF
	.byte   $F4
	sbc     $E5F0,y
	ora     $E5E4
	inc     $E9,x
	.byte   $E3
	sbc     $DF
	inc     $EDF5
	.byte   $E2
	sbc     $F2
LAD06:	sty     $E0
	sta     $E1
	txa
	pha
	ldy     #$00
	lda     ($E0),y
	beq     LAD1F
	tax
	iny
LAD14:	lda     ($E0),y
	ora     #$80
	jsr cout
	iny
	dex
	bne     LAD14
LAD1F:	pla
	tax
	rts

LAD22:	pha
	lsr     a
	lsr     a
	lsr     a
	lsr     a
	jsr     LAD32
	pla
	and     #$0F
	jsr     LAD32
	clc
	rts

LAD32:	cmp     #$0A
	bcc     LAD3B
	clc
	adc     #$D7
	bne     LAD3E
LAD3B:	clc
	adc     #$B0
LAD3E:	ora     #$80
	jmp cout

LAD43:	.byte   $DA
	ldx     #$00
LAD46:	asl     a
	pha
	bcs     LAD4E
	lda     #$B0
	.byte   $80
	.byte   $02
LAD4E:	lda     #$B1
	sta     LAD64,x
	pla
	inx
	cpx     #$08
	bne     LAD46
	clc
	lda     #$AD
	ldy     #$63
	stx     LAD63
	.byte   $FA
LAD62:	rts

LAD63:	.byte   $AD
LAD64:	ldy     #$E4
	.byte   $80
	ldy     #$E7
	.byte   $80
	ldy     #$A0

pr_version:
	pha
	and     #$F0
	lsr     a
	lsr     a
	lsr     a
	lsr     a
	ora     #$B0
	jsr cout
	lda     #$AE
	jsr cout
	pla
	and     #$0F
	ora     #$B0
	jmp cout

machine_check:
	lda     $FBB3
	cmp     #$38
	beq no_65c02
	cmp     #$EA
	beq no_65c02
	lda     $FBC0
	cmp     #$EA
	beq no_65c02
	clc
	bne machine_ok
no_65c02:
	jsr xbell
	jsr xmess
	asc_hi "*** error: 65C02 required"
	.byte $8d, $00
	sec
machine_ok:
	rts
