;*********************************************
;*********************************************
;
; External command for Davex
;
; strings -- find printable strings in files
;
; Dave Lyons, 17-Dec-88
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

OrgAdr	= $A000	;change as necessary (end below $B000)
; org OrgAdr

PrByte = $fdda
Space = $A0
;
MyVersion	= $10
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
	.byte $80+'l',t_int1	;minimum length
	.byte $80+'o',t_nil	;offsets
	.byte $80+'m',t_nil	;allow mixed bit 7
	.byte 0,0
descr:	pstr "find printable strings in files"
	
;*********************************************
data	= pagebuff
max_len	= 70
dflt_len	= 6
;
; dum xczpage ;32 locations
pr_count	= xczpage	;ds 1
needed	= pr_count+1	;ds 1
buffered	= needed+1	;ds 1
offset	= buffered+1	;ds 3
myTemp	= offset+3	;ds 1
NoMixed	= myTemp+1	;ds 1 ;disallow mixed hi/lo ascii?
; dend
;*********************************************
start:	nop	;don't let shell print wildcards
	sta open_path+1
	sty open_path
;
	jsr crout
	lda open_path+1
	ldy open_path
	jsr xprint_path
	jsr xmess
	.byte $80+':',cr,0
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
;
	lda #dflt_len
	sta needed
	lda #'l'+$80
	jsr xgetparm_ch
	bcs default
	sty needed
default	= *
;
; check the -m flag
;
	lda #'m'+$80
	jsr xgetparm_ch
	ror NoMixed
;
	lda #0
	sta buffered
	sta pr_count
	sta offset
	sta offset+1
	sta offset+2
MainLp	= *
	jsr FindString
	bcs Done
	cmp needed
	bcc MainLp
	jsr PrintStr
	jsr xcheck_wait
	bcs Done
	jmp MainLp
;
err1:	jmp xProDOS_err
Done:	jsr mli
	.byte mli_close
	.addr close_parms
	rts
;*********************************************
;
; FindString -- return CLC,A=len if found,
;               SEC if end of file
;
FindString	= *
	jsr LoseBuff
FindS1	= *
	lda pr_count
	cmp #max_len-1
	bcs Found
	jsr ReadByte
	bcs FindS_exit
	jsr ChkPrint
	bcc FindS1
; found nonprintable; either kill it or return the
; printable stuff preceding it
	lda pr_count
	cmp #2
	bcs FoundPr
	jmp FindString
; stuff it back in the buffer and return printable stuff
FoundPr:	inc buffered
	dec pr_count

Found:	lda pr_count
	clc
FindS_exit:	rts
;*********************************************
;
; ChkPrint -- A --> clc=printable
;
ChkPrint	= *
	bit NoMixed
	bpl ChkPrint2
	tay
	eor data
	bmi noPrint
	tya
ChkPrint2:	and #$7f
	cmp #$7f
	beq noPrint
	cmp #$20
	bcc noPrint
	clc
	rts
noPrint:	sec
	rts
;*********************************************
;
; Get the next byte from the file (reading it
; into the "data" buffer if it isn't already
; there)
;
ReadByte	= *
	lda buffered
	bne no_fill
	jsr FillBuffer
	bcs gotChar
no_fill:	ldx pr_count
	inc pr_count
	dec buffered
	lda data,x
	clc
gotChar:	rts
;*********************************************
;
; Fill the unused part of the "data" buffer
;
FillBuffer	= *
	sec
	lda #max_len
	sbc pr_count
	sta read_req
	clc
	lda #<data
	adc pr_count
	sta read_where
	jsr mli
	.byte mli_read
	.addr read_parms
	bcs RdErr
	clc
	lda read_xfer
	asl buffered
	sta buffered
	clc
	rts
RdErr:	cmp #err_eof
	beq RdErr2
	jmp xProDOS_err
RdErr2:	rts
;
read_parms:	.byte 4
read_ref:	.res 1
read_where:	.addr data
read_req:	.addr 0
read_xfer:	.addr 0
;*********************************************
;
; LoseBuff -- shift A bytes off the left
; of the "data" buffer and add to offset
;
LoseBuff	= *
	lda pr_count
	sta myTemp
	clc
	adc offset
	sta offset
	bcc off_ok1
	inc offset+1
	bne off_ok1
	inc offset+2
off_ok1	= *
;
	ldx myTemp
	lda buffered
	sta myTemp
	inc myTemp
	ldy #0
shift_a:	lda data,x
	sta data,y
	iny
	inx
	dec myTemp
	bne shift_a
;
	lda #0
	sta pr_count
	rts
;*********************************************
;
; print a string
;
PrintStr	= *
	jsr DoTheOffset
	ldx #0
PrASC:	lda data,x
	ora #%10000000
	jsr cout
	inx
	cpx pr_count
	bcc PrASC
	jmp crout
;*********************************************
;
; print offset to left
;
DoTheOffset	= *
	lda #'o'+$80
	jsr xgetparm_ch
	bcc NoOffsets
	lda #'$'+$80
	jsr cout
	lda offset+2
	jsr PrByte
	lda offset+1
	jsr PrByte
	lda offset
	jsr PrByte
	lda #':'+$80
	jsr cout
	lda #Space
	jsr cout
NoOffsets:	rts
;*********************************************
;*********************************************
open_parms:	.byte 3
open_path:	.res 2
	.addr filebuff
open_ref:	.res 1
;
close_parms:	.byte 1
close_ref:	.byte 1
;*********************************************
