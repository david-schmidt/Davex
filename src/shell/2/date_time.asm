;***********************************************
;
; print_time -- print the date and time,
; if available
;
print_time:
	jsr mli
	.byte mli_gettime_2
	.addr $ffff	;no parameter list

	jsr validate_year_number

	sec
	jsr $fe1f
	bcs :+		;not IIgs
	lda cfgclock	;Use IIgs clock?
	bne doGSclk
:	lda date+1
	ldy date
	jsr pr_date_ay
	lda time+1
	ldy time
	jsr pr_time_ay
	jmp crout

doGSclk:
	lda #0
	tax
dgsc1:	sta pagebuff,x
	dex
	bne dgsc1

; Call GS Toolbox ReadASCIITime
.P816
	clc
	XCE
	rep #$30
.A16
.I16
	pea 0
	pea pagebuff
	ldx #$0f03	;ReadASCIITime
	jsl $e10000
	sec
	XCE
.A8
.I8
	ldx #$ff
:	inx
	lda pagebuff,x
	beq gscx
	jsr cout
	bra :-
.P02

gscx:	jmp crout

;
; Validate the year setting, even if we'll display from the GS clock
;
validate_year_number:
	lda #$60			; RTS
	sta validate_year_number	; just run once, next time we just RTS

	lda date+1
	lsr a
	cmp #100
	bcs @badYearWarning
	rts

@badYearWarning:
	jsr mess
	asc "WARNING: Your system's clock driver year number is greater than 99, which"
	.byte cr
	asc "is wrong (use 0..39 for 2000..2039).  See ProDOS 8 Technical Note #28."
	.byte cr
	cstr_cr "On the Apple IIgs, use ProDOS 8 2.0 or later."
	rts

;
; print date and time from AY
;
my_date: .addr 0
my_time: .addr 0

pr_date_ay:
	sta my_date+1
	sty my_date
	ora my_date
	beq no_pdat

	jsr prdate0
	lda #space
	bit speech
	bpl :+
	lda #$80+','
:	jsr cout
	lda #space
	jmp cout

prdate0:
	lda my_date
	and #%00011111
	jsr two_decimal0
	jsr dt_hyph
	lda my_date+1
	pha
	ror a	;c=1 if month>7
	lda my_date
	rol a
	rol a
	rol a
	rol a
	and #%00001111	;month
	sta temp
	asl a
;;;	clc
	adc temp
	tay
	jsr month_chr
	jsr month_chr
	jsr month_chr
	jsr dt_hyph
	pla		;glob_date+1
	lsr a
	jmp two_decimal
no_pdat:
	message_cstr "<no date>  "
	rts
;
; print time from AY
;
pr_time_ay:
	sta my_time+1
	sty my_time
	ora my_time
	beq no_ptim

	lda my_time+1
	cmp #12
	php
	bcc is_a_m
;;;	sec
	sbc #12
is_a_m:	cmp #0
	bne not_midnight
	adc #11
not_midnight:
	jsr two_decimal0
	lda #$80+':'
	jsr cout
	lda my_time
	jsr two_decimal
	lda #space
	jsr cout
	lda #$80+'A'
	plp
	bcc really_a_m
	lda #$80+'P'
really_a_m:
	jsr cout
	jsr speech_space
	lda #$80+'M'
	jmp cout
no_ptim:
	message_cstr "        "
rts0:	rts

month_chr:
	lda month_text,y
	iny
	bne date_chr

speech_comma:
	bit speech
	bpl rts0
	lda #$80+','
	bne date_chr
speech_space:
	bit speech
	bpl rts0
	bmi pr_spz
dt_hyph:
	lda #$80+'-'
	bit speech
	bpl date_chr
pr_spz:	lda #$80+' '
date_chr:
	jmp cout

two_decimal0:
	cmp #10
	bcs two_decimal
	pha
	jsr pr_sp
	pla
	ora #$80+'0'
	jmp cout
two_decimal:
	cmp #100
	bcc lesshund
	message_cstr "??"
	rts
lesshund:
	ldx #$80+'0'
two_lp:	cmp #10
	bcc time_prdec
;;;	sec
	sbc #10
	inx
	bne two_lp
time_prdec:
	pha
	txa
	jsr date_chr
	pla
	ora #$80+'0'
	bne date_chr	; always taken

month_text:
	asc_hi "???JanFebMarAprMayJunJulAugSepOctNovDec?????????"

