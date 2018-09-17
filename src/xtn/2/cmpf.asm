;************************************************************************
;
; Davex external command CMPF (compare text files)
;
; Programmed by Kevin R. Cooper, April 12, 1989.
;
; This program compares two text files on a line by
; line basis.  The changes that must be made to file A
; to transform it to file B are reported.
;
; Possible change reports are:
;
;   Lines <B line range> inserted before <A line #>.
;   Lines <A line range> deleted before <B line #>.
;   Lines <A line range> changed to <B line range>.
;
; At the end of the comparison the number of differences
; between the files is reported.
;
; The parameter MIN_LINES is the minimum number of lines
; which must match between files to resynchronize after a
; mismatch.
;
; Notes:
;
;  ! Remember never to put comments on EDASM macro
;    lines!
;  - Number of differences and line numbers are two-byte
;    numbers.  Should be three-byte numbers; would be faster
;    to use decimal arithmetic.
;  - Buffering of rea.resy blocks could be more efficient.
;
; (1) Original coding.                       (KRC 13-Mar-89)
; (2) Treats EOF as CR; added spacebar wait. (KRC 22-Mar-89)
; (3) Last character of file is an EOLN, not EOF
;     is CR.                                 (KRC  3-Apr-89)
; (4) Better resynch algorithm.              (KRC  4-Apr-89)
; (5) Written as a Davex external command.   (KRC  9-Apr-89)
;
;************************************************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;************************************************************************


	.include "Common/2/Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"
	;

.segment	"CODE_A000"

default_min	= 3
default_mask	= $7f

.macro	inc_p Arg
	.local ok
	INC Arg
	BNE ok
	INC Arg+1
ok:
.endmacro

.macro	poke_p Arg1,Arg2
	LDA #<Arg2
	STA Arg1
	LDA #>Arg2
	STA Arg1+1
.endmacro

.macro	copy_p Arg1,Arg2
	LDA Arg1
	STA Arg2
	LDA Arg1+1
	STA Arg2+1
.endmacro

.macro	copy_t Arg1,Arg2
	LDA Arg1
	STA Arg2
	LDA Arg1+1
	STA Arg2+1
	LDA Arg1+2
	STA Arg2+2
.endmacro

.macro	eq_t Arg1,Arg2
	.local notEq
	LDA Arg1
	CMP Arg2
	BNE notEq
	LDA Arg1+1
	CMP Arg2+1
	BNE notEq
	LDA Arg1+2
	CMP Arg2+2
notEq:
.endmacro

.macro	zero_p Arg
	lda #0
	sta Arg
	sta Arg+1
.endmacro

.macro	zero_t Arg
	lda #0
	sta Arg
	sta Arg+1
	sta Arg+2
.endmacro

.macro	inc_t Arg
	.local ok
	INC Arg
	BNE ok
	INC Arg+1
	BNE ok
	INC Arg+2
ok:
.endmacro

.macro	isz_t Arg
	LDA Arg
	ORA Arg+1
	ORA Arg+2
.endmacro

.macro	dec_t Arg
	.local ok
	.local ok2
	LDA Arg
	BNE ok
	LDA Arg+1
	BNE ok2
	DEC Arg+2
ok2:	DEC Arg+1
ok:	DEC Arg
.endmacro

.macro	dec_p Arg
	.local ok
	LDA Arg
	BNE ok
	DEC Arg+1
ok:	DEC Arg
.endmacro

.macro	ld_ay Arg
	LDY Arg
	LDA Arg+1
.endmacro

orgadr	= $a000

MyVersion	= $09
MinVersion	= $12
;
;----------------------
;
; org orgadr
;
; Davex command info
;
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr orgadr
	.addr start
	.byte 0,0,0,0
;
; parameters here
;
	.byte 0,t_wildpath
	.byte 0,t_wildpath
	.byte $80+'n',t_int1
	.byte 0,0
;
descr:	pstr "compare text files--by Kevin R. Cooper"
	
;
;----------------------
;
; dum xczpage
Mask	= xczpage	;.res 1

a_pos	= Mask+1	;.res 3
a_line	= a_pos+3	;.res 2
;
a_eof	= a_line+2	;.res 3
a_eoln_flag	= a_eof+3	;.res 1
;
b_pos	= a_eoln_flag+1	;.res 3
b_line	= b_pos+3	;.res 2
;
b_eof	= b_line+2	;.res 3
b_eoln_flag	= b_eof+3	;.res 1
; dend
;
a_open_buff	= filebuff
b_open_buff	= filebuff2
;
; dum filebuff3
b_max_pos	= filebuff3	;.res 3
b_max_line	= b_max_pos+3	;.res 2
min_lines	= b_max_line+2	;.res 1
num_diffs	= min_lines+1	;.res 2
line_count	= num_diffs+2	;.res 1 ;used by match_n_lines
line_num	= line_count+1	;.res 2
a2_pos	= line_num+2	;.res 3
a2_line	= a2_pos+3	;.res 2
;
a_min_pos	= a2_line+2	;.res 3
a_min_line	= a_min_pos+3	;.res 2
;
b2_pos	= a_min_line+2	;.res 3
b2_line	= b2_pos+3	;.res 2
;
lastBmaxFlg	= b2_line+2	;.res 1
; dend
;
;----------------------
;
hi_bit	= $80
cr	= $8d
locr	= cr-hi_bit
ctrl	= $40
;
;----------------------
;
crout	= $fd8e
cout	= $fded
;
;----------------------
;
start:
;====
;
; get A path parameter
;
; lda #0
; jsr xgetparm_n
	sty a_name
	sta a_name+1
;
; get B path paramter
;
	lda #1
	jsr xgetparm_n
	sty b_name
	sta b_name+1
;
; get MIN_LINES paramter
;
	lda #'n'+$80
	jsr xgetparm_ch
	bcc got_min_lines
	lda #default_min
got_min_lines:	sta min_lines
;
	lda #default_mask
	sta Mask
;
	jsr open_a
	jsr get_a_eof
;
	jsr open_b
	jsr get_b_eof
;
	jsr crout
;
compare_files:
	zero_p num_diffs
;
	zero_t a_pos
	zero_t b_pos
;
	poke_p a_line,1
	poke_p b_line,1
;
	zero_t a_mark
	zero_t b_mark
;
;----------------------
;
compare:	;a_pos = a_mark = a file pos, etc. b
	eq_t a_pos,a_eof
	beq got_an_eof
;
	eq_t b_pos,b_eof
	beq got_an_eof
;
;----------------------
;
	jsr xcheck_wait
	jsr match_line
	beq synched
	jmp resynch
;
synched:
;
	copy_t a_mark,a_pos
	inc_p a_line
;
	copy_t b_mark,b_pos
	inc_p b_line
;
	jmp compare
;
;----------------------
;
got_an_eof:
;---------
;
	copy_t a_eof,a2_pos
	copy_t b_eof,b2_pos
;
	jsr report_diff
;
	jsr xmess
	asc "Number of differences: "
	.byte 0
;
	ld_ay num_diffs
	jsr xprdec_2
	jmp crout	;rts to Davex
;
;----------------------
;
resynch:
;------
	copy_p b_line,b_max_line
	copy_t b_pos,b_max_pos
;
	copy_p a_line,a_min_line
	copy_t a_pos,a_min_pos
;
	lsr lastBmaxFlg
;
;----------------------
;
resynch1:
;-------
	copy_p a_min_line,a2_line
	copy_t a_min_pos,a2_pos
;
	copy_p b_max_line,b2_line
	copy_t b_max_pos,b2_pos
;
;----------------------
;
resynch2:
;-------
	copy_t a2_pos,a_mark
	jsr set_a_mark
;
	copy_t b2_pos,b_mark
	jsr set_b_mark
;
	jsr xcheck_wait
;
;----------------------
;
	jsr match_n_lines
	bne not_resynch
;
	jmp resynched
;
;----------------------
;
not_resynch:
;
	eq_t b2_pos,b_pos
	bne next_a2_line
;
go_exit_loop2:	jmp exit_loop2
;
;----------------------
;
next_a2_line:	copy_t a2_pos,a_mark
	jsr set_a_mark
;
next_a2:	jsr read_a
	bit a_eoln_flag
	bpl next_a2
;
	eq_t a_mark,a_eof
	beq go_exit_loop2
;
	copy_t a_mark,a2_pos
	inc_p a2_line
;
;----------------------
;
last_b2_line:
;
	copy_t b2_pos,b_mark
	dec_t b_mark
;
last_b2:
;
	isz_t b_mark
	beq got_last_b2
;
	dec_t b_mark
	jsr set_b_mark
	jsr read_b
	bit b_eoln_flag
	bmi got_last_b2
;
	dec_t b_mark
	jmp last_b2
;
got_last_b2:
;
	copy_t b_mark,b2_pos
	dec_p b2_line
;
	jmp resynch2
;
;----------------------
;
exit_loop2:
;
	bit lastBmaxFlg
	bmi NextAminLine
;
	eq_t b2_pos,b_eof
	beq NextAminLine
;
;----------------------
;
NextBmaxLine:	copy_t b_max_pos,b_mark
	jsr set_b_mark
;
next_b_max:	jsr read_b
	bit b_eoln_flag
	bpl next_b_max
;
	eq_t b_mark,b_eof
	beq GotLstBmax
;
	copy_t b_mark,b_max_pos
	inc_p b_max_line
;
	jmp resynch1
;
;----------------------
;
GotLstBmax:	ror lastBmaxFlg	;carry set by eq_t
;
NextAminLine:
;
	copy_t a_min_pos,a_mark
	jsr set_a_mark
;
next_a_min:	jsr read_a
	bit a_eoln_flag
	bpl next_a_min
;
	eq_t a_mark,a_eof
	beq cant_resynch
;
	copy_t a_mark,a_min_pos
	inc_p a_min_line
;
	jmp resynch1
;
cant_resynch:	jmp got_an_eof
;
;----------------------
;
resynched:	jsr report_diff
;
	copy_p a2_line,a_line
	copy_t a2_pos,a_pos
	copy_t a_pos,a_mark
	jsr set_a_mark
;
	copy_p b2_line,b_line
	copy_t b2_pos,b_pos
	copy_t b_pos,b_mark
	jsr set_b_mark
;
	jmp compare
;
;----------------------
;
match_n_lines:	;x_eof must not be true
;============
	lda min_lines
	sta line_count
;
mn:	jsr match_line
	bne mn_failed
;
	dec line_count
	beq matched_n
;
	eq_t a_mark,a_eof
	beq mn_failed
;
	eq_t b_mark,b_eof
	bne mn
;
	lda #1
;
mn_failed:	rts	;z flag clear
;
matched_n:	rts	;match succeeded ;z flag set
;
;----------------------
;
; using current file positions and x_mark-s;
; returns x_mark-s
;
match_line:
;=========
	jsr read_a
	jsr read_b
;
	lda a_read_buff
	cmp b_read_buff
	bne ml_failed
;
	lda a_eoln_flag
	and b_eoln_flag
	bmi matched_line
;
	lda a_eoln_flag
	ora b_eoln_flag
	bpl match_line	;if not ( eoln(a) or eoln(b) ) then continue
;
ml_failed:	lda #1
	rts	;match line failed; z flag clear
;
matched_line:	lda #0
	rts	;match line succeeded; z flag set
;
;----------------------
;
report_diff:	; a_pos, b_pos = start of unsynch; a2_pos, b2_pos = resynch
;==========
	eq_t a_pos,a2_pos
	bne rd2
;
	eq_t b_pos,b2_pos
	bne report_ins
;
	rts
;
rd2:	eq_t b_pos,b2_pos
	beq report_del
;
	jmp report_chg
;
;----------------------
;
report_ins:
;---------
	jsr list_b_lines
	jsr xmess
	.byte cr
	asc "inserted before"
	.byte cr,cr,0
	jsr list_a_line
	jmp got_diff
;
;----------------------
;
report_del:
;---------
	jsr list_a_lines
	jsr xmess
	.byte cr
	asc "deleted before"
	.byte cr,cr,0
	jsr list_b_line
	jmp got_diff
;
;----------------------
;
report_chg:
;---------
	jsr list_a_lines
	jsr xmess
	.byte cr
	asc "changed to"
	.byte cr,cr,0
	jsr list_b_lines
	jmp got_diff
;
;----------------------
;
got_diff:
;-------
	inc_p num_diffs
	jsr crout
	jmp crout	;rts
;
;----------------------
;
list_a_lines:	;list a_line .. a2_line-1 @ a_pos .. a2_pos-1
;===========
	jsr goto_a_line
;
list_a:
;
	jsr list_a_line2
;
	inc_p line_num
	eq_t a_mark,a2_pos
	bne list_a
;
	rts
;
;----------------------
;
list_a_line:	;list line a_line starting at a_pos
;==========
;
	jsr goto_a_line
	jmp list_a_line2	;rts
;
;----------------------
;
goto_a_line:
;==========
	copy_p a_line,line_num
;
	copy_t a_pos,a_mark
	jmp set_a_mark	; rts
;
;----------------------
;
list_a_line2:
;===========
	jsr xcheck_wait
;
	eq_t a_mark,a_eof
	beq print_a_eof
;
	lda #'A'+$80
	jsr cout
;
	ld_ay line_num
	jsr xprdec_2
;
	lda #' '+$80
	jsr cout
;
;----------------------
;
print_a_line:
;
	jsr read_a
;
	lda a_read_buff
	ora #hi_bit
	jsr cout
;
	bit a_eoln_flag
	bpl print_a_line
;
	cmp #cr
	beq PrintedLineA
;
	jmp crout	;rts ;need cr because eof was eoln
;
PrintedLineA:	rts
;
;----------------------
;
print_a_eof:
;
	jsr xmess
	asc "end of file A"
	.byte cr,0
	rts
;
;----------------------
;
list_b_lines:	;list b_line .. b2_line-1 @ b_pos .. b2_pos-1
;===========
	jsr goto_b_line
;
list_b:
;
	jsr list_b_line2
;
	inc_p line_num
	eq_t b_mark,b2_pos
	bne list_b
;
	rts
;
;----------------------
;
list_b_line:	;list line b_line starting at b_pos
;==========
;
	jsr goto_b_line
	jmp list_b_line2	; rts
;
;----------------------
;
goto_b_line:
;==========
	copy_p b_line,line_num
;
	copy_t b_pos,b_mark
	jmp set_b_mark	;rts
;
;----------------------
;
list_b_line2:
;===========
	jsr xcheck_wait
;
	eq_t b_mark,b_eof
	beq print_b_eof
;
	lda #'B'+$80
	jsr cout
;
	ld_ay line_num
	jsr xprdec_2
;
	lda #' '+$80
	jsr cout
;
;----------------------
;
print_b_line:
;
	jsr read_b
;
	lda b_read_buff
	ora #hi_bit
	jsr cout
;
	bit b_eoln_flag
	bpl print_b_line
;
	cmp #cr
	beq PrintedLineB
;
	jmp crout	;rts ;need cr because eof was eoln
;
PrintedLineB:	rts
;
;----------------------
;
print_b_eof:
;
	jsr xmess
	asc "end of file B"
	.byte cr,0
	rts
;
;----------------------
;
open_a:
;==========
	jsr mli
	.byte $c8	;open
	.addr a_open_parms
	bcs open_a_err
;
	lda a_ref
	sta a_mark_ref
	sta a_read_ref
;
	rts
;
open_a_err:	jmp xProDOS_err
;
;----------------------
;
a_open_parms:	.byte 3
a_name:	.res 2
	.addr a_open_buff
a_ref:	.res 1
;
;----------------------
;
open_b:
;==========
	jsr mli
	.byte $c8	;open
	.addr b_open_parms
	bcs open_b_err
;
	lda b_ref
	sta b_mark_ref
	sta b_read_ref
;
	rts
;
open_b_err:	jmp xProDOS_err
;
;----------------------
;
b_open_parms:	.byte 3
b_name:	.res 2
	.addr b_open_buff
b_ref:	.res 1
;
;----------------------
;
; enter read_a and read_b with x_mark and current
; file pos synchronized; x_read_buff has char and
; x_mark inc-ed; sets flag x_eoln_flag if char=locr
; or x_mark = x_eof-1
;
read_a:
;==========
;
	jsr mli
	.byte $ca	;read
	.addr a_read_parms
	bcs a_read_err
;
	inc_t a_mark
;
	lda a_read_buff
	and Mask
	sta a_read_buff
	cmp #locr
	beq got_a_eoln
;
	eq_t a_mark,a_eof
	beq got_a_eoln
;
	lsr a_eoln_flag
	rts
;
got_a_eoln:	ror a_eoln_flag	;carry is set by cmp #locr or eq_t
	rts
;
a_read_err:	jmp xProDOS_err
;
;----------------------
;
a_read_parms:
	.byte 4
a_read_ref:
	.res 1
	.addr a_read_buff
a_read_len:
	.addr 1
ReadActLenA:
	.res 2
;
a_read_buff:
	.res 1
;
;----------------------
;
read_b:
;==========
;
	jsr mli
	.byte $ca	;read
	.addr b_read_parms
	bcs b_read_err
;
	inc_t b_mark
;
	lda b_read_buff
	and Mask
	sta b_read_buff
	cmp #locr
	beq got_b_eoln
;
	eq_t b_mark,b_eof
	beq got_b_eoln
;
	lsr b_eoln_flag
	rts
;
got_b_eoln:	ror b_eoln_flag	;carry is set by cmp #locr or eq_t
	rts
;
b_read_err:	jmp xProDOS_err
;
;----------------------
;
b_read_parms:
	.byte 4
b_read_ref:
	.res 1
	.addr b_read_buff
b_read_len:
	.addr 1
ReadActLenB:
	.res 2
;
b_read_buff:
	.res 1
;
;----------------------
;
get_a_eof:
;========
	jsr mli
	.byte $d1	;get eof
	.addr a_mark_parms
	bcs get_a_eof_err
;
	copy_t a_mark,a_eof
	rts
;
get_a_eof_err:	jmp xProDOS_err
;
;----------------------
;
a_mark_parms:	.byte 2
a_mark_ref:	.res 1
a_mark:	.res 3
;
;----------------------
;
set_a_mark:
;========
	jsr mli
	.byte $ce	;set mark
	.addr a_mark_parms
	bcs SetMarkErrA
;
	rts
;
SetMarkErrA:	jmp xProDOS_err
;
;----------------------
;
get_b_eof:
;========
	jsr mli
	.byte $d1	;get eof
	.addr b_mark_parms
	bcs get_b_eof_err
;
	copy_t b_mark,b_eof
	rts
;
get_b_eof_err:	jmp xProDOS_err
;
;----------------------
;
b_mark_parms:	.byte 2
b_mark_ref:	.res 1
b_mark:	.res 3
;
;----------------------
;
set_b_mark:
;========
	jsr mli
	.byte $ce	;set mark
	.addr b_mark_parms
	bcs SetMarkErrB
;
	rts
;
SetMarkErrB:	jmp xProDOS_err
;
;----------------------
;
zzz_the_end:
