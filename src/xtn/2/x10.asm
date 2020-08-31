;*********************************************
;
; External command for Davex
;
; x10 -- experinmental x10 stuff
;
; x10 [-z] [-i] [-s slot] [-h housecode] [-d day] <string>
;     [-b base-housecode]
;
; -z = debugging
; -i = display info (time, day, house code)
;
; <string> is a bunch of characters like this:
;   a through p toggle selection of devs 1-16
;   "*" inverts selection of all devices
;   "+" sends an "on"
;   "-" sends an "off"
;   "=x" dims units to level x (a=dimmest,p=brightest)
;   "#x" sends function 0-15 (a-p)
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


OrgAdr	= $a000	;change as necessary (end below $B000)
; org OrgAdr

MyVersion	= $09
MinVersion	= $12
MinVerAux	= 5
;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr OrgAdr
	.addr start
	.byte MinVerAux,0,0,0
; parameters here
	.byte 0,t_string
	.byte $80+'s',t_int1
	.byte $80+'b',t_string
	.byte $80+'h',t_string
	.byte $80+'d',t_int1
	.byte $80+'z',t_nil
	.byte $80+'i',t_nil
	.byte 0,0
descr:	pstr "experimental x10 controller stuff"
	
;*********************************************
; dum xczpage ;32 locations
str	= xczpage	;ds 2
hStr	= str+2	;ds 2
counter	= hStr+2	;ds 1
slot	= counter+1	;ds 1
house	= slot+1	;ds 1
refnum	= house+1	;ds 1 ;for print_drvr
index	= refnum+1	;ds 1
unitmask	= index+1	;ds 2
Function	= unitmask+2	;ds 1
Housecode	= Function+1	;ds 1
;
Status	= Housecode+1	;ds 1
Minutes	= Status+1	;ds 1
Hours	= Minutes+1	;ds 1
Day	= Hours+1	;ds 1
;
Debug	= Day+1	;ds 1
; dend
;
start	= *
	sta str+1
	sty str
;
; check debugging flag
;
	lda #'z'+$80
	jsr xgetparm_ch
	ror a
	eor #$80
	sta Debug
;
; default slot is 2; can override with -s
;
	lda #2
	sta slot
	lda #'s'+$80
	jsr xgetparm_ch
	bcs no_slot
	sty slot
no_slot:
;
	lda slot
	ldx #mli_open
	jsr xprint_drvr
	bcc opened
	jmp xProDOS_err
opened:	sta refnum
	lda slot
	ldx #mli_open-$80	;open for input
	jsr xprint_drvr
;
; tell the serial port to send stuff straight through
; %%% send ctrl-i if slot 1 ?
;
	lda #1
	jsr outchar
	lda #'Z'
	jsr outchar
;
; set the clock (-d day, use ProDOS hour/min)
;
	lda #'d'+$80
	jsr xgetparm_ch
	bcs no_day
	jsr set_clock
no_day:
;
; set house code
;
	lda #'b'+$80
	jsr xgetparm_ch
	bcs no_setbase
	jsr parse_hcode
	jsr set_basehc
no_setbase:
;
; Determine house code for direct commands
; (specified with -h, or defaults to base
; housecode)
;
	lda #'h'+$80
	jsr xgetparm_ch
	bcs use_base
	jsr parse_hcode
	jmp got_code
use_base:	jsr calc_hcode
got_code:
;
; cruise through the string one character at a time
; and send stuff
;
	lda #0
	sta index
	sta unitmask+1
	sta unitmask
next_char:
	lda index
	ldy #0
	cmp (str),y
	bcs str_dun
	inc index
	ldy index
	lda (str),y
	jsr do_char
	jmp next_char
str_dun:
;
; display info
;
	lda #'i'+$80
	jsr xgetparm_ch
	bcs no_info
	jsr show_info
no_info:
;
; close the slot
;
	ldy refnum
	ldx #mli_close
	jsr xprint_drvr
	ldy refnum
	ldx #mli_close-$80
	jsr xprint_drvr

	rts

;*****************************************
;
; do_char
;
do_char:	jsr xdowncase
	cmp #'+'+$80
	beq do_on
	cmp #'-'+$80
	beq do_off
	cmp #'='+$80
	beq do_dim
	cmp #'#'+$80
	beq do_generic
	cmp #'*'+$80
	beq do_invert
	cmp #'a'+$80
	bcc bad_char
	cmp #'p'+$80+1
	bcs bad_char
	sec
	sbc #'a'+$80
	jsr do_number
	rts

bad_char:
	jsr xmess
	.byte cr
	asc_hi "*** A-P, *, +, -, and = are allowed"
	.byte 13,0
	jmp xerr

do_invert:
	lda #$ff
	eor unitmask+1
	sta unitmask+1
	lda #$ff
	eor unitmask
	sta unitmask
	rts

do_dim:	inc index
	ldy index
	lda (str),y
	jsr calc_level
	ora #5	;dim command
	bne do_OnOff
;
do_generic:
	inc index
	ldy index
	lda (str),y
	jsr xdowncase
	sec
	sbc #'a'+$80
	jmp do_OnOff
;
do_on:	lda #2
	bne do_OnOff
do_off:	lda #3
do_OnOff:
	sta Function

	jsr header
	lda #1
	jsr outchar
	lda Function
	jsr outchar
	lda Housecode
	jsr outchar
	lda unitmask+1
	jsr outchar
	lda unitmask
	jsr outchar

	clc
	lda Function
	adc Housecode
	clc
	adc unitmask+1
	clc
	adc unitmask
	jsr outchar

	lda #0
	sta unitmask+1
	sta unitmask

	jsr wait_ack
	jsr print_status
	rts

do_number:
	tax
	cmp #8
	bcs upper8
	lda bit_table,x
	eor unitmask
	sta unitmask
	rts
upper8:	lda bit_table-8,x
	eor unitmask+1
	sta unitmask+1
	rts

bit_table:
	.byte %10000000
	.byte %01000000
	.byte %00100000
	.byte %00010000
	.byte %00001000
	.byte %00000100
	.byte %00000010
	.byte %00000001
;
; calc_level:
;   a=character --> a=$L0
;
calc_level:
	jsr xdowncase
	cmp #'p'+$80+1
	bcs bad_level
	cmp #'a'+$80
	bcc bad_level
	sbc #'a'+$80
	asl a
	asl a
	asl a
	asl a
	eor #$f0
	rts
bad_level:
	jsr xmess
	.byte cr

	
	asc_hi "*** level must be A-P"
	
	.byte 13,0
	jmp xerr
;
; header--send 16 $FFs to the controller
;
header:	lda #16
	sta counter
out_ff:	lda #$ff
	jsr outchar
	dec counter
	bne out_ff
	rts
;
; outchar--send character in A to controller
;
outchar:
	pha
	jsr debugByte
	pla
	ldy refnum
	ldx #mli_write-$80
	jsr xprint_drvr
	bcs out_err
	rts
out_err:	jmp xProDOS_err
;
; parse house code (string in AY)
;
parse_hcode:
	sta hStr+1
	sty hStr
	ldy #0
	lda (hStr),y
	cmp #1
	bne house_bad
	ldy #1
	lda (hStr),y
	jsr xdowncase
	cmp #'a'+$80
	bcc house_bad
	cmp #'p'+$80+1
	bcs house_bad
	sec
	sbc #'a'+$80	;house code 0-15
	tax
	lda hCodes,x
	sta Housecode
	rts

house_bad:
	jsr xmess
	.byte cr
	asc_hi "*** house code must be A-P"
	.byte 13,0
	jmp xerr

hCodes:	.byte $60,$e0,$20,$a0,$10,$90,$50,$d0
	.byte $70,$f0,$30,$b0,$00,$80,$40,$c0
;
; send header, $00, $x0
;
set_basehc:
	jsr header
	lda #0
	jsr outchar
	lda Housecode
	jsr outchar
	jsr wait_ack
	jsr print_status
	rts
;
; calc_hcode--ask the unit what the housecode is
;
calc_hcode:
	jsr header
	lda #4
	jsr outchar

	jsr inchar
	jsr inchar
inSync:	jsr inchar
	cmp #$ff
	beq inSync
	sta Status
	jsr inchar
	sta Minutes
	jsr inchar
	sta Hours
	jsr inchar
	sta Day
	jsr inchar
	sta Housecode
	jsr inchar	;checksum
	rts

inchar:	ldy refnum
	ldx #mli_read-$80
	jsr xprint_drvr
	bcc gotCh
	cmp #0
	bne blark
	lda $c061	;%%%
	bpl inchar
	lda #der_abort
	bne blark
gotCh:
	pha
	jsr debugByte
	pla
	rts
blark:	jmp xProDOS_err
;
; wait_ack -- wait for ACK and return status:
;   sec = error
;
wait_ack:	jsr inchar
wait_ac2:	jsr inchar
	cmp #$ff
	beq wait_ac2
	cmp #1
	rts
;
debugByte:
	bit Debug
	bpl dbbx
	jsr prbyte
	lda #_' '
	jsr cout
dbbx:	rts
;
print_status:
	bcs stat1
	jsr xmess
	.byte cr
	asc_hi "S=0"
	.byte cr,0
	rts
stat1:	jsr xmess
	.byte cr
	asc_hi "S=1"
	.byte cr,0
	rts
;
; set controller's clock (Y=day)
;
set_clock:
	lda day_bits,y
	sta theDay
	jsr header
	lda #2
	jsr outchar
	lda $bf92	;minute
	jsr outchar
	lda $bf93	;hour
	jsr outchar
	lda theDay
	jsr outchar	;day bitmap
	clc
	lda $bf92
	adc $bf93
	clc
	adc theDay
	jsr outchar
	jsr wait_ack
	jsr print_status
	rts

theDay:	.res 1

day_bits:	.byte $00,$01,$02,$04,$08,$10,$20,$40
;
; show_info
;
show_info:
	jsr calc_hcode
	jsr xmess
	asc_hi "Status = "
	.byte 0
	lda Status
	jsr prbyte
	jsr crout
	jsr xmess
	asc_hi "Time = "
	.byte 0
	lda Hours
	ldy Minutes
	jsr xpr_time_ay
	lda Day
	jsr ConvertDay
	jsr PrintDay
	jsr crout
	jsr xmess
	asc_hi "House code = "
	.byte 0
	lda Housecode
	lsr a
	lsr a
	lsr a
	lsr a
	tay
	lda codeLtrs,y
	jsr cout
	jsr crout
	rts

codeLtrs:
	asc_hi "MECKOGAINFDLPHBJ"
	
;
; ConvertDay-- $01, $02, $04, $08, $10, $20, $40, $xx
;                v    v    v    v    v    v    v    v
;                0    1    2    3    4    5    6    7
;
ConvertDay:
	tax
	beq oddDay
	ldx #$ff
cd1:	inx
	lsr a
	bcc cd1
	tay
	beq dayOK
oddDay:	ldx #7
dayOK:	txa
	rts
;
; PrintDay--0..7 --> print Mon, Tue, ..., ???.
;
PrintDay:
	asl a
	asl a
	tay
	ldx #4
dn1:	lda dayNames,y
	jsr cout
	iny
	dex
	bne dn1
	rts

dayNames:
	asc_hi " Mon Tue Wed Thu Fri Sat Sun ???"
	
;
