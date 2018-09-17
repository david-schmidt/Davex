;*********************************************
;
; MX80 setup
;
; Options:
;   -n       normal
;   -z       zap (re-init everything)
;   -b y|n   boldface
;   -e y|n   emphasized
;   -i y|n   italics
;   -u y|n   underline
;   -s y|n   skip over perf
;   -8 y|n   8 lines/inch
;   -l #     form length
;   -p #     pitch
;   -1 y|n   unidirectional print
;
; by Dave Lyons
; 12-Jul-86
;
; 21-Jul-88 DAL ==> v1.1
;   souce --> Merlin
;   Fixed xprint_drvr usage: uses refnums now
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_AE00"


;
OrgAdr	= $AE00
; org OrgAdr

MyVersion	= $11
MinVersion	= $10
;*********************************************
	RTS
	.byte $EE,$EE
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr Descr
	.addr OrgAdr
	.addr Start
	.byte 0,0,0,0
; PARAMETERS HERE
my_parms:	.byte $80+'z',t_nil
	.byte $80+'n',t_nil
	.byte $80+'b',t_yesno
	.byte $80+'e',t_yesno
	.byte $80+'i',t_yesno
	.byte $80+'u',t_yesno
	.byte $80+'s',t_int2
	.byte $80+'8',t_yesno
	.byte $80+'p',t_int2
	.byte $80+'l',t_int2	;form length
	.byte $80+'1',t_yesno
	.byte 0,0
;
Descr:	pstr "Sets up MX80 options"
	
;
end	= $ff
;*********************************************
; dum xczpage
mxTemp	= xczpage	;.res 1
value	= mxTemp+1	;.res 1
refnum	= value+1	;.res 1
; dend
;*********************************************
Start:
;
; open the printer
;
	lda #0	;open config'd prtr slot
	ldx #mli_open
	jsr xprint_drvr
	bcc opened
	jmp xProDOS_err
opened:
	sta refnum
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
	ldy refnum
	ldx #mli_close
	jmp xprint_drvr
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
not_given:
	pla
	rts
;
; table of addresses for handling
; each parameter
;
subtable:
	.addr do_zap-1
	.addr do_normaltxt-1
	.addr do_bold-1
	.addr do_emphasize-1
	.addr do_italics-1
	.addr do_underline-1
	.addr do_skipperf-1
	.addr do_eight-1
	.addr do_pitch-1
	.addr do_flength-1
	.addr do_unidir-1
;
; Print 1 char to the printer driver
;
print_esc:
	lda #esc
Print:	ldx #mli_write
	ldy refnum
	jmp xprint_drvr
;*******************************
do_bold:
	ldy #bold-stuff
	jmp do_yesno
;
do_emphasize:
	ldy #emphasize-stuff
	jmp do_yesno
;
do_italics:
	ldy #italics-stuff
	jmp do_yesno
;
do_underline:
	ldy #underline-stuff
	jmp do_yesno
;
do_skipperf:
	cpy #0	;-s0?
	bne skippf
	ldy #noskip-stuff
	jmp print_y
;
skippf:	sty value
	ldy #skip-stuff
	jsr print_y
	lda value
	jmp Print
;
do_eight:
	ldy #eight-stuff
	jmp do_yesno
;
do_pitch:
	cpy #5
	beq pitch5
	cpy #8
	beq pitch8
	cpy #10
	beq pitch10
	cpy #17
	beq pitch17
	jsr xmess
	cstr_cr "illegal pitch--use 5, 8, 10, 17"
	rts
;
pitch5:	ldy #p5-stuff
	jmp print_y
pitch8:	ldy #p8-stuff
	jmp print_y
pitch10:	ldy #p10-stuff
	jmp print_y
pitch17:	ldy #p17-stuff
	jmp print_y
;
do_flength:
	sty value
	ldy #formlen-stuff
	jsr print_y
	lda value
	jmp Print
;
do_unidir:
	ldy #unidir-stuff
	jmp do_yesno
;
do_zap:
	ldy #zap-stuff
	jmp print_y
;
do_normaltxt:
	ldy #normaltxt-stuff
	jmp print_y
;*******************************
do_yesno:	cmp #0
	bne print_y
	jsr skip_str
print_y:	lda stuff,y
	cmp #$ff
	beq printed
	sty mxTemp
	jsr Print
	ldy mxTemp
	iny
	bne print_y
printed:	rts
;*******************************
skip_str:	lda stuff,y
	cmp #$ff
	beq skipped
	iny
	bne skip_str
skipped:	iny
	rts
;*******************************
;
stuff:
bold:	.byte esc,'G',end
	.byte esc,'H',end
emphasize:	.byte esc,'E',end
	.byte esc,'F',end
italics:	.byte esc,'4',end
	.byte esc,'5',end
underline:	.byte esc,'-',1,end
	.byte esc,'-',0,end
eight:	.byte esc,'0',end
	.byte esc,'2',end
unidir:	.byte esc,'U',1,end
	.byte esc,'U',0,end
zap:	.byte esc,'@',end
skip:	.byte esc,'N',end
noskip:	.byte esc,'O',end
formlen:	.byte esc,'C',end
;
p5:	.byte esc,'W',1,18,end
p8:	.byte esc,'W',1,15,end
p10:	.byte esc,'W',0,18,end
p17:	.byte esc,'W',0,15,end
normaltxt:
	.byte esc,'H',esc,'G',esc,'5',esc,'-',0
	.byte esc,'2',esc,'U',0,esc,'O'
	.byte esc,'W',0,18,end
