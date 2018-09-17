;*********************************************
;*********************************************
;
; External command for Davex
;
; find -- search file for lines containing a
;         given string
;
; find <wildpath> <string> [-c] [-l<integer>] [-n]
;   -c: just count the number of matching lines
;   -n: print line numbers
;   -l: number of lines to print starting with
;       matching line
;   -w: wrap after how many characters (wraps
;       after this many, or at any of the
;       previous 9 if a blank is found)
;
;*********************************************
;
; Modified 14-Apr-88 DL ==>v1.1
;   Fixed DEC STARTPOS logic to find a
;   string starting at first position in
;   a line.
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

linebuff	= filebuff3
;*********************************************
MyVersion	= $11
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
	.byte 0,t_string
	.byte $80+'c',t_nil	;just count matches
	.byte $80+'l',t_int1	;number of lines to print
	.byte $80+'n',t_nil	;print line numbers
	.byte $80+'w',t_int1	;wrap after how many
	.byte 0,0
descr:	pstr "search file for lines containing string"
	
;*********************************************
; dum xczpage ;32 locations
str	= xczpage	;ds 2
ref	= str+2	;ds 1
match_count	= ref+1	;ds 3
line_num	= match_count+3	;ds 3
l_value	= line_num+3	;ds 1
print_count	= l_value+1	;ds 1
no_nums	= print_count+1	;ds 1
line_len	= no_nums+1	;ds 1 ;length in linebuff
str_len	= line_len+1	;ds 1
count	= str_len+1	;ds 1
startpos	= count+1	;ds 1
temp_ch	= startpos+1	;ds 1
soft_wrap	= temp_ch+1	;ds 1
hard_wrap	= soft_wrap+1	;ds 1
; dend
;*********************************************
find_err:	jmp xProDOS_err

start:	nop	;disable wildcard printing
	jsr xfman_open
	bcs find_err
	sta ref

	jsr crout
	lda #0
	jsr xgetparm_n
	jsr xprint_path
	jsr xmess

	
	asc ":"
	
	.byte $8D,0

	lda #1
	jsr xgetparm_n
	sta str+1
	sty str

	lda #1
	sta l_value

	lda #0
	sta print_count

	lda #'c'+$80
	jsr xgetparm_ch
	bcs not_justcnt
	lda #0
	sta l_value
not_justcnt	= *

	lda #'l'+$80
	jsr xgetparm_ch
	bcs no_lval
	sty l_value
no_lval	= *

	lda #'n'+$80
	jsr xgetparm_ch
	ror no_nums

	lda #79
	sta hard_wrap
	lda #'w'+$80
	jsr xgetparm_ch
	bcs dflt_wrap
	cpy #255
	beq bad_wrap
	cpy #11
	bcs good_wrap
bad_wrap:	jsr xmess

	
	asc "*** wrap must be 11..254"
	
	.byte $8D,0
	jmp xerr
good_wrap:	sty hard_wrap
dflt_wrap	= *
	lda hard_wrap
	sec
	sbc #9
	sta soft_wrap

	ldx #match_count
	jsr zero3
	ldx #line_num
	jsr zero3

find1:	ldx #line_num
	jsr inc3

	jsr get1line
	bcs find_done

	jsr compare
	bcs no_match

	ldx #match_count
	jsr inc3
	lda l_value
	sta print_count
no_match	= *

	jsr maybe_print
	jmp find1

find_done	= *
	lda #'c'+$80
	jsr xgetparm_ch
	bcs no_count
	jsr xmess

	
	asc "  Number of matching lines: "
	
	.byte 0
	ldx #match_count
	jsr print3
	jsr crout
no_count	= *
	rts

;*********************************************

zero3:	lda #0
	sta 0,x
	sta 1,x
	sta 2,x
	rts

inc3:	inc 0,x
	bne inc3x
	inc 1,x
	bne inc3x
	inc 2,x
inc3x:	rts

print3:	lda 2,x
	sta xnum+2
	lda 1,x
	sta xnum+1
	lda 0,x
	sta xnum
	jmp xprdec_3

;*********************************************

mp_done:	rts
maybe_print:	lda print_count
	beq mp_done
	dec print_count
	bit no_nums
	bmi skipnum
	ldx #line_num
	jsr print3
	jsr xmess

	
	asc ": "
	
	.byte 0
skipnum	= *
	lda line_len
	sta count
	dec count
	beq did_prline
	ldx #0
prline1:	lda linebuff,x
	ora #$80
	cmp #$ff
	beq not_prnt
	cmp #' '+$80
	bcs prntable
not_prnt:	lda #'.'+$80
prntable:	jsr cout
	inx
	dec count
	bne prline1
did_prline:	jsr crout
	jsr xcheck_wait
	bcs abort
	rts
abort:	lda #der_abort
	jmp xProDOS_err

;*********************************************

get1line	= *
	lda #0
	sta line_len
get1ch:	lda ref
	jsr xfman_read
	bcs get1dun
	ora #$80
	ldx line_len
	inc line_len
	sta linebuff,x
	cmp #$8d
	beq get1dun
	cpx hard_wrap
	bcs get1dun0
	cpx soft_wrap
	bcc get1ch
	cmp #' '+$80
	bne get1ch
get1dun0:	ldx line_len
	inc line_len
	lda #$8d
	sta linebuff,x
get1dun:	lda #0
	cmp line_len	;sec <==> line_len=0
	rts

;*********************************************
;
; compare -- return clc if (str) is contained
;            in linebuff
;
compare	= *
	ldy #0
	lda (str),y
	sta str_len
	beq cmp_yes

	lda str_len
	cmp line_len
	beq len_ok
	bcc len_ok
	rts
len_ok	= *

	lda line_len
	sec
	sbc str_len
	clc
	adc #1
	sta startpos

chk_here	= *
	lda str_len
	sta count
	ldy #1
	ldx startpos
cmp1ch:	lda linebuff,x
	jsr xdowncase
	sta temp_ch
	lda (str),y
	jsr xdowncase
	cmp temp_ch
	bne chk_next
	iny
	inx
	dec count
	bne cmp1ch
	beq cmp_yes

chk_next:	dec startpos
	lda startpos
	cmp #<-1
	bne chk_here
cmp_no:	sec
	rts
cmp_yes:	clc
	rts

;*********************************************
