;*********************************************
;
; External command for Davex
;
; cal -- print month or year calendars
;
; cal <year> <month>
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************
.segment	"CODE_A000"

OrgAdr	= $A000	;change as necessary (end below $B000)
.org	OrgAdr	; Makes the listing more readable, though it doesn't really org the code - the linker does that.
	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

MyVersion	= $10
MinVersion	= $11

January		= 0
February	= 1
December	= 11
Sunday		= 1
Monday		= 2
Saturday	= 7
;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr OrgAdr
	.addr start
	.byte 0,0,0,0
; parameters here
	.byte 0,t_int2
	.byte 0,t_int1
	.byte 0,0
descr:	pstr "print month or year calendars"

;*********************************************
; dum xczpage ;32 locations
year		= xczpage	; .res 2
month		= year+2	; .res 1
mn_day1		= month+1	; .res 1
mn_size		= mn_day1+1	; .res 1
leap_flag	= mn_size+1	; .res 1

total		= leap_flag+1	; .res 2
last_yr		= total+2	; .res 2
ytemp		= last_yr+2	; .res 1

n1		= ytemp+1	; .res 2
n2		= n1+2		; .res 2

pos		= n2+2		; .res 1
m7		= pos+1		; .res 2
myTemp		= m7+2		; .res 1

start:	stx year+1
	sty year
	txa
	bne not00xx
	cpy #100
	bcs not00xx
;;;	clc
	pha
	tya
	adc #<1900
	sta year
	pla
	adc #>1900
	sta year+1
not00xx:
	lda #1
	jsr xgetparm_n
	cpy #0
	beq bad_mn
	cpy #12+1
	bcc good_mn
bad_mn:	jsr xmess
	.byte cr
	cstr_cr "*** month must be 1..12"
	jmp xerr
good_mn:
	dey
	sty month
;
; check options here later
;
	jsr crout
	jsr Pr1Month
	rts
;*********************************************
;
; Print small calendar for (year,month)
;
Pr1Month:
	lda #20
	jsr PrDateCenter
	jsr xmess
	cstr "Su Mo Tu We Th Fr Sa"
	jsr CalcMonth	; year,month --> mn_day1,mn_size
	clc
	lda mn_day1
	adc mn_size
	sta limit
	dec limit
	lda #0
	sta pos
Pr1Day:	jsr _mod7
	cmp #0
	bne no_row
	jsr crout
no_row:	lda pos
	clc
	adc #1
	sec
	sbc mn_day1
	bcc blank_day
	adc #0	;adds 1
	sta xnum
	lda #0
	sta xnum+1
	sta xnum+2
	ldy #1
	jsr xprdec_pady
	jmp next_pos
blank_day:
	jsr xmess
	cstr "  "
next_pos:
	lda #$a0
	jsr cout
	inc pos
	lda pos
	cmp limit
	bcc Pr1Day
PrMdone:
	jmp crout
;*********************************************
;*********************************************
month_offset:	.res 12
month_size:	.byte 31,28,31,30,31,30,31,31,30,31,30,31
;*********************************************
;
; Calculate mn_size and mn_day1 from year,month
;
CalcMonth:
	jsr CalcLeap
	ldy month
	jsr GetMonthYsize
	sta mn_size
;
; build month-offset table:
;   mo := 0;
;   for m := 0 to 11 do begin
;     month_offset[m] := mo mod 7;
;     mo := mo + month_size[m];
;   end;
;
	lda #0
	tax
moff1:	sta month_offset,x
	clc
	adc month_size,x
	jsr _mod7
	inx
	cpx #12
	bcc moff1

	jsr DayInWeek	;of day 1 in <year,month>
	sta mn_day1
	rts

_mod7:	cmp #7
	bcc _mod7x
	sbc #7
	bcs _mod7
_mod7x:	rts

mod7ay:	sta m7+1
	sty m7
m7_1:	lda m7+1
	bne m7_2
	lda m7
	cmp #7
	bcs m7_2
	lda m7+1
	ldy m7
	rts
m7_2:	sec
	lda m7
	sbc #7
	sta m7
	lda m7+1
	sbc #0
	sta m7+1
	jmp m7_1
;*********************************************
CalcLeap:
	lda year+1
	ldy year
	sta n1+1
	sty n1
	lda #>100
	ldy #100
	jsr _mod
	php
	lda year+1
	ldy year
	sta n1+1
	sty n1
	lda #>400
	ldy #<400
	plp
	beq _Mod100is0
	lda #>4
	ldy #4
_Mod100is0:
	jsr _mod
	sec
	beq IsLeap
	clc
IsLeap:	ror leap_flag
	rts
;*********************************************
;
; calc AY = n1 mod AY
;
_mod:	sta n2+1
	sty n2
_mod1:	lda n1+1
	cmp n2+1
	bne _mod1x
	lda n1
	cmp n2
_mod1x:	bcc _mod_dun
;sec
	lda n1
	sbc n2
	sta n1
	lda n1+1
	sbc n2+1
	sta n1+1
	bcs _mod1	;always
_mod_dun:
	lda n1
	ora n1+1
	php
	lda n1+1
	ldy n1
	plp
	rts
;*********************************************
DayInWeek:
	ldx year+1
	lda year
	sec
	sbc #1
	bcs noDEC
	dex
noDEC:	sta last_yr
	stx last_yr+1
; total := last_yr + (last_yr div 4)
	sta total
	stx total+1
	stx ytemp
	lsr ytemp
	ror a
	lsr ytemp
	ror a
	clc
	adc total
	sta total
	lda ytemp
	adc total+1
	sta total+1
; total := total - (last_yr div 100)
	ldx #0
div100:	lda last_yr+1
	bne div100s
	lda last_yr
	cmp #100
	bcc div100dun
div100s:
	sec
	lda last_yr
	sbc #100
	sta last_yr
	lda last_yr+1
	sbc #>100
	sta last_yr+1
	inx
	bcs div100
div100dun:
	stx myTemp
	sec
	lda total
	sbc myTemp
	sta total
	lda total+1
	sbc #0
	sta total+1
; total += last_yr div 400  [ = (last_yr div 100) div 4) ]
	txa
	lsr a
	lsr a
	clc
	adc total
	sta total
	lda total+1
	adc #0
	sta total+1
; add day in year
	jsr DayInYear	; --> AY
	pha
	tya
	clc
	adc total
	tay
	pla
	adc total+1

	jsr mod7ay
	tya	;7-Feb-90 DAL
	clc
	adc #1
	rts
;*********************************************
;
; Calc day (1..366) of first day of <month,year>
;
DayInYear:
	lda #0
	sta n1+1
	sta n1
	inc n1
	tay	;for y=0 to month-1
diy1:	cpy month
	bcs diy_done
	jsr GetMonthYsize
	clc
	adc n1
	sta n1
	bcc diy2
	inc n1+1
diy2:	iny
	bne diy1
diy_done:
	lda n1+1
	ldy n1
	rts
;*********************************************
GetMonthYsize:
	lda month_size,y
	cpy #February
	bne not_feb29
	bit leap_flag
	bpl not_feb29
	adc #0	;sec from not taking BNE!
not_feb29:
	rts
;*********************************************
PrDateCenter:
	sec
	sbc #5
	ldy month
	clc
	adc mNameOff,y
	sec
	sbc mNameOff+1,y
	lsr a
	tax
	lda #' '+$80
PrDateBl:
	jsr cout
	dex
	bne PrDateBl
	lda mNameOff+1,y
	sta limit
	lda mNameOff,y
	tax
PrMonth:
	lda mN,x
	jsr cout
	inx
	cpx limit
	bne PrMonth
	lda #' '+$80
	jsr cout
	lda year+1
	ldy year
	jsr xprdec_2
	jmp crout
limit:	.res 1

mNameOff:
	.byte mName1-mN,mName2-mN,mName3-mN,mName4-mN
	.byte mName5-mN,mName6-mN,mName7-mN,mName8-mN
	.byte mName9-mN,mName10-mN,mName11-mN,mName12-mN
	.byte mName13-mN
mN:
mName1:
	asc_hi "January"
mName2:
	asc_hi "February"
mName3:
	asc_hi "March"
mName4:
	asc_hi "April"
mName5:
	asc_hi "May"
mName6:
	asc_hi "June"
mName7:
	asc_hi "July"
mName8:
	asc_hi "August"
mName9:
	asc_hi "September"
mName10:
	asc_hi "October"
mName11:
	asc_hi "November"
mName12:
	asc_hi "December"
mName13:
;*********************************************
