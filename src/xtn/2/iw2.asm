;*********************************************
;
; iw2 -- ImageWriter II setup
;
; Options:         (018bcdefhilnpqrstuxz)
;   -n       normal
;   -b y|n   boldface
;   -u y|n   underline
;   -s y|n   skip over perf
;   -8 y|n   8 lines/inch
;   -p #     pitch
;   -1 y|n   unidirectional print
;   -l #     left margin
;   -r y|n   reverse line-feed
;
;   -q #     print quality 0-2
;   -c #     color 0-6
;   -0 y|n   slashed zeroes?
;   -t       set top of form to here
;   -h nnnn  form height (in n/144 inches)
;   -f #     font (0=American...7=Spanish)
;   -x       cancel unprinted text (send ctrl-x)
;   -i y|n   ignore out-of-paper
;   -e #     enable ROM/dnload1/dnload2 charset
;
; by Dave Lyons, 6-Feb-88
; Based on 'pset' of 12-Jul-86
;
; modified 12-Dec-89 DAL ==> v1.1
;   removed "dfb do_height-1" (unimplemented
;   command) to synch tables & make -f, -x,
;   -i, and -e work correctly.
;
;*********************************************
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************
	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"
	;

.segment	"CODE_A000"

OrgAdr	= $A000
; org OrgAdr



MyVersion	= $11
MinVersion	= $10

	rts
	.byte $EE,$EE
	.byte MyVersion,MinVersion
	.byte %00000000	;HARDWARE REQ
	.addr Descr
	.addr OrgAdr
	.addr Start
	.byte 0,0,0,0
; Parameters here
my_parms:
	.byte $80+'n',t_nil	;normal settings
	.byte $80+'b',t_yesno ;boldface
	.byte $80+'u',t_yesno ;underline
	.byte $80+'s',t_yesno ;skip perf
	.byte $80+'8',t_yesno ;8 lpi
	.byte $80+'p',t_int2	;pitch (cpi)
	.byte $80+'l',t_int2	;left margin
	.byte $80+'1',t_yesno ;unidirectional printing
	.byte $80+'r',t_yesno ;reverse linefeed direction
;
	.byte $80+'q',t_int2	;print quality
	.byte $80+'c',t_int2	;color
	.byte $80+'0',t_yesno ;slashed 0s?
	.byte $80+'t',t_nil	;set tof
;dfb "h",t_int2 ;height of form
	.byte $80+'f',t_int2	;font (American..Danish)
	.byte $80+'x',t_nil	;cancel unprinted text
	.byte $80+'i',t_yesno ;ignore out-of-paper
	.byte $80+'e',t_int2	;enable ROM/dnload cs
	.byte 0,0
;
Descr:	pstr "Sets ImageWriter II options"
	
;
end	= $ff
;*********************************************
; dum 0
; org xczpage ;32 locations
myTemp	= xczpage	;.res 1
value	= myTemp+1	;.res 1
Y_save	= value+1	;.res 1
printer_ref	= Y_save+1	;.res 1
; DEND
;*********************************************
Start:
;
; open the printer
;
	lda #0	;"&" slot
	ldx #mli_open
	jsr xprint_drvr
	bcc opened
	jmp xProDOS_err
opened:
	sta printer_ref
;
; do each parameter
;
	ldy #0
parmloop:	lda my_parms,y
	ora my_parms+1,y
	beq parms_done
	tya
	pha
	jsr do_one
	pla
	tay
	iny
	iny
	bne parmloop
;
parms_done:
;
; close the printer
;
	ldy printer_ref
	ldx #mli_close
	jmp xprint_drvr
;
; print_decimal -- print # in A as 3-char
; ASCII decimal to printer
;
print_decimal:
	ldy #2	;100s
pd1:	ldx #'0'+$80-1
	lda value
pd2:	inx
	sec
	sbc tens,y
	bcs pd2
	adc tens,y
	sta value
	txa
	sty Y_save
	jsr print
	ldy Y_save
	dey
	bpl pd1
	rts
;
tens:	.byte 1,10,100
;*******************************
;
; do_one -- dispatch to a
; subroutine to handle each
; parameter given
;
do_one:	pha
	lda my_parms,y
	jsr xgetparm_ch
	bcs not_given
	pla
	tay
	lda subtable+1,y
	pha
	lda subtable,y
	pha
	lda my_parms,y
	jmp xgetparm_ch
not_given:	pla
	rts
;
; table of addresses for handling
; each parameter
;
subtable:
	.addr do_normaltxt-1
	.addr do_bold-1
	.addr do_underline-1
	.addr do_skipperf-1
	.addr do_eight-1
	.addr do_pitch-1
	.addr do_leftmar-1
	.addr do_unidir-1
	.addr do_reverse-1
	.addr do_quality-1
	.addr do_color-1
	.addr do_sl0-1
	.addr do_tof-1
;dw do_height-1
	.addr do_font-1
	.addr do_cancel-1
	.addr do_ignore-1
	.addr do_enable-1
;
; Print 1 char to the printer driver
;
print_esc:	lda #esc
print:	ldx #mli_write
	ldy printer_ref
	jmp xprint_drvr
;*******************************
do_bold:
	ldy #bold-stuff
	jmp do_yesno
;
do_underline:
	ldy #underline-stuff
	jmp do_yesno
;
do_skipperf:
	cmp #0
	beq ckipp_no
;
; Tell NEC to skip to next page every
; 60 lines
;
; Print CHR$(29) "A"  117 @s, "C",
; 13 @s, "A@"  CHR$(30)
;
	lda #29
	jsr print
	lda #'A'+$80
	jsr print
	ldx #117
	jsr do_ats
	lda #'C'+$80
	jsr print
	ldx #13
	jsr do_ats
	lda #'A'+$80
	jsr print
	lda #$40
	jsr print
	lda #30
	jmp print
;
; print X AT signs
;
do_ats:	stx value
ats:	lda #$40
	jsr print
	dec value
	bne ats
	rts
;
ckipp_no:
	lda #29
	jsr print
	lda #0	;anything except TOF clears
	jmp print
;
; 8 or 6 lpi
;
do_eight:
	ldy #eight-stuff
	jmp do_yesno
;
; 5, 6, 8, 10, 12, 17 cpi
;
do_pitch:
	cpy #5
	beq pitch5
	cpy #6
	beq pitch6
	cpy #8
	beq pitch8
	cpy #10
	beq pitch10
	cpy #12
	beq pitch12
	cpy #17
	beq pitch17
	jsr xmess
	cstr_cr "illegal pitch--use 4..10, 12, 13, 15, 17"
	rts

pitch5:	ldy #p5-stuff
	bne pitchy
pitch6:	ldy #p6-stuff
	bne pitchy
pitch8:	ldy #p8-stuff
	bne pitchy
pitch10:
	ldy #p10-stuff
	bne pitchy
pitch12:
	ldy #p12-stuff
	bne pitchy
pitch17:
	ldy #p17-stuff
pitchy:	jmp print_y
;
; left margin
;
do_leftmar:
	sty value
	ldy #leftm-stuff
	jsr print_y
	ldy value
	jmp print_decimal
;
; 1-directional printing
;
do_unidir:
	ldy #unidir-stuff
	jmp do_yesno
;
; reverse/forward line-feeds
;
do_reverse:
	ldy #lfdirection-stuff
	jmp do_yesno
;
; set everything to normal
;
do_normaltxt:
	ldy #normaltxt-stuff
	jmp print_y
;
; -q# (0-2)  print quality
;
; Sends ESC a # (0=standard, 1=draft, 2=nlq)
;
do_quality:
	sty value
	jsr print_esc
	lda #'a'
	jsr print
prdig:	lda value
	ora #'0'
	jmp print
;
; -c #  (0..6)   set color  ESC K #
;
do_color:
	sty value
	jsr print_esc
	lda #'K'
	jsr print
	jmp prdig
;
; -0 y|n  -- slash or don't slash 0s
;
do_sl0:
	ldy #sl0-stuff
	jmp do_yesno
;
; -t -- set top of form (ESC v)
;
do_tof:	ldy #tof-stuff
	jmp print_y
;
; -h #  form height (length) 0000-9999
;
do_height:
;;;	brk
	.byte 0
;
; -f #  (0..7) font (American..Spanish)
;
do_font:
	cpy #8
	bcs F2big
	sty value
	jsr print_esc
	lda #'Z'
	jsr print
	lda value
	eor #%00000111
	jsr print
	lda #0
	jsr print
	jsr print_esc
	lda #'D'
	jsr print
	lda value
	jsr print
	lda #0
	jmp print
F2big:	jmp toobig
;
; -x (cancel)  Ctrl-X
;
do_cancel:
	lda #'X'-$40
	jmp print
;
; -i y|n  (ignore paper-out)
;
do_ignore:
	ldy #ignore-stuff
	jmp do_yesno
;
; -e # (0..2)  enable ROM font or
;              low ASCII downloaded or
;              high ASCII downloaded
;
do_enable:
	tya
	cmp #3
	bcs toobig
	pha
	jsr print_esc
	pla
	tax
	lda ChSet,x
	jmp print
ChSet:	.byte $27,'*','$'

toobig:	ldx #der_bignum
	jmp xerr
;*******************************
do_yesno:	cmp #0
	bne print_y
	jsr skip_str
print_y:	lda stuff,y
	cmp #end
	beq printed
	sty myTemp
	jsr print
	ldy myTemp
	iny
	bne print_y
printed:
	rts
;*******************************
skip_str:
	lda stuff,y
	cmp #end
	beq skipped
	iny
	bne skip_str
skipped:
	iny
	rts
;*******************************
stuff:
bold:	.byte esc,'!',end
	.byte esc,'"',end
underline:
	.byte esc,'X',end
	.byte esc,'Y',end
eight:	.byte esc,'B',end
	.byte esc,'A',end
unidir:	.byte esc,'<',end
	.byte esc,'>',end
lfdirection:
	.byte esc,'r',end
	.byte esc,'f',end
sl0:	.byte esc,'D',0,1,end
	.byte esc,'Z',0,1,end
ignore:	.byte esc,'O',end
	.byte esc,'o',end
;
leftm:	.byte esc,'L',end
;
p5:	.byte esc,'N',14,end
p6:	.byte esc,'E',14,end
p8:	.byte esc,'Q',14,end
p10:	.byte esc,'N',15,end
p12:	.byte esc,'E',15,end
p17:	.byte esc,'Q',15,end
normaltxt:
	.byte esc,'c',end
tof:	.byte esc,'v',end
