;***********************************************
;
; print_time -- print the date and time,
; if available
;
time_none:
	jsr mess
	ascz "<no date>"
	rts

print_time:
	CALLOS mli_settime, GET_TIME_PARMS
	bne time_none		; Branch on failure
	CALLOS mli_gettime_3, GET_TIME_PARMS
	bne time_none		; Branch on failure
	lda GET_TIME_DATE+1
	cmp #$30			; Is the day number zero?
	beq time_none		; No date information
	
	lda GET_TIME_DATA+6
	sta time_string
	lda GET_TIME_DATA+7
	sta time_string+1
	lda GET_TIME_MONTH+1	; Get month low byte
	and #$0f
	sta my_date
	ldy GET_TIME_MONTH	; Month high byte
	cpy #$30
	beq :+
	lda #10
	clc
	adc my_date
	sta my_date
:	clc
	adc my_date
	adc my_date
	tay
	lda month_text-3,y
	sta time_string+3
	lda month_text-2,y
	sta time_string+4
	lda month_text-1,y
	sta time_string+5
	ldy #$03
:	lda GET_TIME_YEAR,y
	sta time_string+7,y
	dey
	bpl :-
	lda GET_TIME_HOUR
	sta time_string+12
	lda GET_TIME_HOUR+1
	sta time_string+13
	lda GET_TIME_MINUTE
	sta time_string+15
	lda GET_TIME_MINUTE+1
	sta time_string+16
	; emit the time
	lda #>time_string
	sta msgp+1
	lda #<time_string
	sta msgp
	ldy #17
	sty WRITE_LEN
	CALLOS mli_write, WRITE_PARMS
	jsr crout
	rts

;
; print date and time from AY
;
my_date:	.addr 0
my_time:	.addr 0
pr_date_ay:
	sta my_date+1
	sty my_date
	ora my_date
	beq no_pdat
;
	jsr prdate0
	lda #space
	bit speech
	bpl *+4
	lda #$80+','
	jsr cout
	lda #space
	jmp cout
;
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
;clc
	adc temp
	tay
	jsr month_chr
	jsr month_chr
	jsr month_chr
	jsr dt_hyph
	pla	;glob_date+1
	lsr a
	jmp two_decimal
no_pdat:	jsr mess
	asc "<no date>  "
	.byte 0
	rts
;
; print time from AY
;
pr_time_ay:
	sta my_time+1
	sty my_time
;;;	lda my_time+1	;removed 2-Dec-99 DAL
	ora my_time
	beq no_ptim
;
	lda my_time+1
	cmp #12
	php
	bcc is_a_m
;sec
	sbc #12
is_a_m:	cmp #0
	bne not_midnight
	adc #11
not_midnight:
	jsr two_decimal0
;msb ON
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
no_ptim:	jsr mess
	asc "        "
	.byte 0
rts0:	rts
;
month_chr:
	lda month_text-3,y
	iny
	bne date_chr
;
speech_comma:
	bit speech
	bpl rts0
	lda #$80+','
	bne date_chr
speech_space:
	bit speech
	bpl rts0
	bmi pr_spz
dt_hyph:	;msb ON
	lda #$80+'-'
	bit speech
	bpl date_chr
pr_spz:	lda #$80+' '
date_chr:
	jmp cout
;
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
	jsr mess
	asc "??"
	.byte 0
	rts
lesshund:
	ldx #$80+'0'
two_lp:	cmp #10
	bcc time_prdec
;sec
	sbc #10
	inx
	bne two_lp
time_prdec:
	pha
	txa
	jsr date_chr
	pla
	ora #$80+'0'
	bne date_chr
	asc "???"
month_text:
	asc_hi "JanFebMarAprMayJunJulAugSepOctNovDec?????????"

GET_TIME_PARMS:	.byte 1
GET_TIME_PTR:	.addr GET_TIME_DATA
GET_TIME_DATA:
GET_TIME_YEAR:	asc "1999"
GET_TIME_MONTH:	asc "10"
GET_TIME_DATE:	asc "01"
GET_TIME_IGNORE:	.byte 00
GET_TIME_HOUR:	asc "21"
GET_TIME_MINUTE:	asc "49"
GET_TIME_SECOND:	asc "00"
GET_TIME_IGNORE2:	asc "000"

time_string:	asc "dd-mmm-yyyy hh:mm"
