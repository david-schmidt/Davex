;*********************************************
;
; setdate <month> <day> <year> <hours> <min> [-p]
;
; by Dave Lyons
; 10-Apr-88
;
;*********************************************
;
; Converted to MPW IIgs 21-Sep-92 DAL
;
;*********************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"


.segment	"CODE_A000"

OrgAdr	= $A000
; ORG OrgAdr

MyVersion	= $10
MinVersion	= $10

MaxYear	= 99
MaxMonth	= 12
MaxDay	= 31
MaxHour	= 23
MaxMinute	= 59
;*********************************************
	RTS
	.byte $EE,$EE
	.byte MyVersion,MinVersion
	.byte %00000000	;HARdwARE REQ
	.addr descr
	.addr OrgAdr
	.addr start
	.byte 0,0,0,0
; PARAMETERS HERE
	.byte 0,t_int1	;month
	.byte 0,t_int1	;day
	.byte 0,t_int1	;year
	.byte 0,t_int1	;hours
	.byte 0,t_int1	;minutes
	.byte $80+'p',t_nil	;p.m.
	.byte 0,0

p_month	= 0
p_day	= 1
p_year	= 2
p_hour	= 3
p_min	= 4
;
descr:	pstr "Sets ProDOS date/time--m d y  h m [-p]"
	
;
;*********************************************
; dum xczpage ;32 locations
MyYear	= xczpage	;ds 1
MyMonth	= MyYear+1	;ds 1
MyDay	= MyMonth+1	;ds 1
MyHour	= MyDay+1	;ds 1
MyMinute	= MyHour+1	;ds 1
; DEND
;*********************************************
start:
	jsr process
	jsr pack
	rts
;*******************************
;
; pack -- put our private locations
; into the real date and time
;
pack:
	lda MyHour
	sta time+1
	lda MyMinute
	sta time
	lda MyMonth
	cmp #8
	pha
	lda MyYear
	rol a
	sta date+1
	pla
	asl a
	asl a
	asl a
	asl a
	asl a
	ora MyDay
	sta date
	rts
;*******************************
;
; process--update My values
; for options given
;
;
bad_year:
	jsr xmess
	.byte cr
	asc "*** bad year value"
	.byte cr,0
	jmp xerr
;
bad_month:
	jsr xmess
	.byte cr
	asc "*** bad month value"
	.byte cr,0
	jmp xerr
;
bad_day:	jsr xmess
	.byte cr
	asc "*** bad day value"
	.byte cr,0
	jmp xerr
;*******************************
process:
	lda #p_year
	jsr xgetparm_n
	cpy #MaxYear+1
	bcs bad_year
	sty MyYear
;
	lda #p_month
	jsr xgetparm_n
	cpy #0
	beq bad_month
	cpy #MaxMonth+1
	bcs bad_month
	sty MyMonth
;
	lda #p_day
	jsr xgetparm_n
	cpy #0
	beq bad_day
	cpy #MaxDay+1
	bcs bad_day
	sty MyDay
;
	lda #p_hour
	jsr xgetparm_n
	cpy #MaxHour+1
	bcs bad_hour
	sty MyHour
;
	lda #p_min
	jsr xgetparm_n
	cpy #MaxMinute+1
	bcc good_minute
	jsr xmess
	.byte cr
	asc "*** bad minutes value"
	.byte cr,0
	jmp xerr
good_minute:
	sty MyMinute
;
	lda #'p'+$80
	jsr xgetparm_ch
	bcs not_PM
	lda MyHour
	adc #12
	cmp #MaxHour+1
	bcc good_hour
bad_hour:
	jsr xmess
	.byte cr
	asc "*** bad hour value"
	.byte cr,0
	jmp xerr
good_hour:
	sta MyHour
not_PM:	rts
;*******************************
