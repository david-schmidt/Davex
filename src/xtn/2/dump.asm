;*********************************************
;*********************************************
;
; External command for Davex
;
; dump -- dump a file in hex/ASCII
;
; Dave Lyons, 4-Mar-88
;
; Modified 17-Dec-88 DL ==> v1.2
;   added -s and -e options
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
;

.segment	"CODE_A000"

OrgAdr	= $A000	;change as necessary (end below $B000)
; org OrgAdr

Space = $A0

MyVersion	= $12
MinVersion	= $11
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
	.byte 0,t_wildpath
	.byte $80+'a',t_nil	;ASCII only
	.byte $80+'h',t_nil	;hex only
	.byte $80+'o',t_nil	;no offsets
	.byte $80+'s',t_int3	;starting offset
	.byte $80+'e',t_int3	;ending offset
	.byte 0,0
descr:	pstr "dump a file in hex/ASCII"
	
;*********************************************
data	= pagebuff
;
; dum xczpage ;32 locations
skip_hex	= xczpage	;.res 1
skip_asc	= skip_hex+1	;.res 1
count	= skip_asc+1	;.res 1
width	= count+1	;.res 1
o_end	= width+1	;.res 3
; dend
;*********************************************
start:
	sta open_path+1
	sty open_path
;
; check -s and -e options
;
	lda #0
	sta offset
	sta offset+1
	sta offset+2
	lda #$ff
	sta o_end
	sta o_end+1
	sta o_end+2
	lda #'s'+$80
	jsr xgetparm_ch
	bcs noffset
	sta offset+2
	stx offset+1
	sty offset
noffset:	lda #'e'+$80
	jsr xgetparm_ch
	bcs no_end
	sta o_end+2
	stx o_end+1
	sty o_end
no_end:
;
; check -a and -h options
;
	lda #'a'+$80
	jsr xgetparm_ch
	ror skip_asc
;
	lda #'h'+$80
	jsr xgetparm_ch
	ror skip_hex
;
	lda skip_hex
	and skip_asc
	bpl not_both
	lsr skip_hex
	lsr skip_asc
not_both	= *
;
; Width (bytes per line) = 16 if hex is being printed,
; otherwise 64 (whether ASCII is there or not)
;
	lda #16
	bit skip_hex
	bpl is16
	lda #64
is16:	sta width
;
; Open the source file
;
	jsr mli
	.byte mli_open
	.addr open_parms
	bcs err1
;
	lda open_ref
	sta read_ref
	sta close_ref
	sta mark_ref
;
	jsr mli
	.byte mli_setmark
	.addr mark_parms
	bcs err1
;
MainLp:
	jsr ReadSome
	bcs MaybeDone
	jsr DoTheOffset
	jsr DoTheHex
	jsr DoTheASCII
	jsr crout
	jsr xcheck_wait
	bcs Done
;
	clc
	lda offset
	adc width
	sta offset
	bcc off_ok
	inc offset+1
	bne off_ok
	inc offset+2
off_ok:
	jsr CheckDone
	bcs Done
	jmp MainLp
;
MaybeDone:
	cmp #err_eof
	beq Done
err1:	jmp xProDOS_err
Done:	jsr mli
	.byte mli_close
	.addr close_parms
	rts
;*********************************************
;
; print offset to left
;
DoTheOffset	= *
	lda #'o'+$80
	jsr xgetparm_ch
	bcc NoOff
	lda #'$'+$80
	jsr cout
	lda offset+2
;beq dto_1
	jsr prbyte
dto_1:	lda offset+1
	jsr prbyte
	lda offset
	jsr prbyte
	lda #_':'
	jsr cout
	lda #Space
	jsr cout
NoOff:	rts
;*********************************************
;
; Read some data (up to WIDTH bytes; return
; amount read in COUNT)
;
ReadSome	= *
	lda width
	sta read_req
	jsr mli
	.byte mli_read
	.addr read_parms
	bcs RdErr
	lda read_xfer
	sta count
RdErr:	rts
;
read_parms:
	.byte 4
read_ref:
	.res 1
	.addr data
read_req:
	.addr 1
read_xfer:
	.addr 0
;*********************************************
DoTheHex	= *
	bit skip_hex
	bmi SkippedHex
	ldx #0
MoreHex:	cpx count
	bcs Blanks
	lda data,x
	jsr prbyte
	lda #Space
	jsr cout
	inx
	bne MoreHex
Blanks:	cpx width
	bcs HexDone
	lda #Space
	jsr cout
	jsr cout
	jsr cout
	inx
	bne Blanks
HexDone:	jsr xmess

	
	asc "   "
	
	.byte 0
SkippedHex	= *
	rts
;*********************************************
;
; print the ASCII to the right
;
DoTheASCII	= *
	bit skip_asc
	bmi SkippedASC
	ldx #0
PrASC:	lda data,x
	ora #%10000000
	cmp #$ff
	beq PrtDot
	cmp #Space
	bcs PrtChar
PrtDot:	lda #'.'+$80
PrtChar:	jsr cout
	inx
	cpx count
	bcc PrASC
SkippedASC:	rts
;*********************************************
;
; CheckDone -- return sec if offset>o_end
;
CheckDone	= *
	lda offset+2
	cmp o_end+2
	bne checked
	lda offset+1
	cmp o_end+1
	bne checked
	lda offset
	cmp o_end
checked:	beq notDone
	rts
notDone:	clc
	rts
;*********************************************
;*********************************************
open_parms:	.byte 3
open_path:	.res 2
	.addr filebuff
open_ref:	.res 1
;
close_parms:	.byte 1
close_ref:	.byte 1
;
mark_parms:	.byte 2
mark_ref:	.res 1
offset:	.res 3
;*********************************************
