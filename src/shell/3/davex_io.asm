;***************************************************
;
; DAVEX I/O routines
;
rdchar0:
	pla
rdchar:
	pha
kagain:	pla
	pha
	jsr rdchar2
	tay
	pla
	tya
	rts
;
rdchar2:
my_rdchar:
	sta rc_temp	;Save char under cur
	jsr rdkey2
	cmp #$80+'O'-ctrl
	bne not_ctrlo
	lda rc_temp
	pha
	pha
	lda #$80+'!'	;Show "!" under cursor
	sta rc_temp
	jsr rdkey2
	sta rd_save
; restore char under "!"
	pla
	jsr cout0
	jsr pr_bs
;
	pla
	sta rc_temp
	lda rd_save
	cmp #$80+'o'+1
	bcs not_neat
	cmp #$80+'k'
	bcs neat
	cmp #$80+'O'+1
	bcs not_neat
	cmp #$80+'K'
	bcc not_neat
neat:	adc #16-1	;(SEC)
not_neat:
	cmp #space
	bcs not_ctrlo
	and #%01111111
not_ctrlo:
	rts
;
rdkey2:
;
; move cursor forw & back to scroll during NORMAL
; for //e 80 col; avoids filling bottom line with
; inverse blanks
;
;	bit two_e_flag
;	bpl noforwback
;	lda scr_width
;	cmp #80
;	bcc noforwback
;	lda #9	;cursor forward
;	jsr cout
;	lda #8	;cursor back
;	jsr cout
noforwback:
;
	lda invflg
	pha
	start_inverse
	lda rc_temp
	jsr cout0
	start_normal
	jsr pr_bs
rc_l1:	lda keyboard
	bpl rc_l1
h_key:	sta kbdstrb
h_key2:	sta theKey
	pla
	sta invflg
	CALLOS mli_d_control, D_CONTROL_PARMS	; Clear typeahead buffer
	lda rc_temp
	jsr cout0
	jsr pr_bs
	lda theKey
	rts
theKey:	.byte 0
;vcout:	jmp (vid_csw)
;
; poll_inslot -- return CLC,A=char or SEC
;
in_xval:	.res 1
in_yval:	.res 1
poll_inslot:
	stx in_xval
	sty in_yval
	jsr poll_in2
	ldx in_xval
	ldy in_yval
	rts
poll_in2:
; sec
	ldy redir_in
; beq polled_in
	cpy #$f0	;8-Mar-90
	bcc WasExec	;8-Mar-90
	ldx #mli_read-$80
	jsr print_drvr
	bcc pollichar
	cmp #0
	beq polled_in
	jmp ProDOS_err
pollichar:	ora #$80
polled_in:	rts
;
WasExec:	sec
	rts
;**********************
poll_io:
	php
	pha
	txa
	pha
	tya
	pha
	inc $4e
	bne rand_ok
	inc $4f
rand_ok:
	jsr poll_spool
	pla
	tay
	pla
	tax
	pla
	plp
	rts
;***********************
yesno:
	lda #0	;no default response for this Y/N question
yesno2:
	ora #$80
	sta yn_dflt
;	bit speech
;	bmi shortyn
	jsr mess
	asc "? (y/n) "
	.byte nul
	jmp yn_l1
shortyn:	lda #$80+'?'
	jsr cout
yn_l1:	lda yn_dflt
	cmp #$80
	bne somedflt
	lda #space
somedflt:
	jsr rdchar
	jsr downcase
	cmp #$80+'C'-ctrl
	beq yn_abort
	cmp #$9b
	beq yn_abort
	cmp #$80+'q'	;1.3 - Q = abort
	beq yn_abort	;1.3
	jsr chk_appleper
	jsr use_yndflt
	cmp #$80+'y'
	beq yes
	cmp #$80+'n'
	beq no
	jsr bell
	jmp yn_l1
yes:	jsr cout
	jsr crout
	lda #%10000000
	rts
no:	jsr cout
	jsr crout
	lda #%00000000
	rts
;
yn_abort:
	lda #der_abort
	jmp ProDOS_err
;
use_yndflt:
	cmp #$8d	;Return = default choice
	beq ynd1
	cmp #$a0	;Space = default choice
	beq ynd1
	rts
ynd1:	lda yn_dflt
	rts
yn_dflt:	.byte 0
;**********************************
prdec_1:
	tay
	lda #0
prdec_2:
	ldx #0
	stx num+2
	sta num+1
	sty num
	clc
	bcc print_dec
;
prdec_pady:
	sec
	ror pad_flag
	lsr digit_flag
	bpl prd_l1
;
prdec_pad:
	sec
	bcs pd1
prdec:
print_dec:
	clc
pd1:	ror pad_flag
	lsr digit_flag	;True if a digit has been printed
	ldy #7
prd_l1:	ldx #$80+'0'	;Digit so far
prd_l2:	lda num+2
	cmp hig10,y
	bne pcmp_dun
	lda num+1
	cmp med10,y
	bne pcmp_dun
	lda num
	cmp low10,y
pcmp_dun:
	bcc pr_digit
	lda num
	sbc low10,y
	sta num
	lda num+1
	sbc med10,y
	sta num+1
	lda num+2
	sbc hig10,y
	sta num+2
	inx
	bne prd_l2
pr_digit:
	cpy #0
	beq printit
	cpx #$80+'0'
	bne printit
	bit digit_flag
	bmi printit
	ldx #space
	bit pad_flag
	bmi printit2
	bpl printed
printit:
	sec
	ror digit_flag
printit2:
	txa
	jsr cout
printed:
	dey
	bpl prd_l1
	rts
;
; tables for base 10 printing
;
low10:	.byte $01,$0a,$64,$e8,$10,$a0,$40,$80
med10:	.byte $00,$00,$00,$03,$27,$86,$42,$96
hig10:	.byte $00,$00,$00,$00,$00,$01,$0f,$98

;**********************
mygetln:
	jsr mygetln2
	lda #0
	sta string,x
	rts
;
hist_level:
	.byte 0
mygetln2:
	lda #0
	jsr redirect
	asl a
	sta exec_flag	;bit 7
	ldx #0
	stx longest
	stx insert_mode
	lda #<-1
	sta hist_level
mg_l1:	ldy longest
	lda #space
	sta string,y
	lda string,x
	jsr rdchar
	cmp #%10000000
	bcs mg_notctlo
	ora #%10000000
	bmi lit_char
mg_notctlo:
	cmp #$ff
	bne mg_notdl
	jmp mgdelete

mg_notdl:
	bit fudgeCR	;5-Feb-90
	bmi noApple	;5-Feb-90
	cmp #$8d
	bne not_CR
	bit exec_flag
	bmi noApple
not_CR:	bit exec_flag
	bmi lit_char	;was noApple 5-Feb-90
	ldy machine
	cpy #6
	bne noApple	;do we have a machine with an Apple key?
	ldy button0	;Apple key down?
	bpl noApple
	jmp doApple
noApple:
	cmp #space
	bcc cchar
lit_char:
	cpx #maxlen
	bcs mg_err
	jsr chk_insrt
	bcs mg_err
	sta string,x
	stx xsave
reprnt:	lda string,x
	bit exec_flag
	bmi invis1
	jsr cout0
invis1:	inx
	bit insert_mode
	bpl rb_no
	cpx longest
	bcc reprnt
	beq reprnt
	inc xsave
	cpx xsave
	beq rb_no
reback:	jsr pr_bs
	dex
	cpx xsave
	bne reback
rb_no:	cpx longest
	bcc mg_l1
	stx longest
	bcs mg_l1
;
mg_err:	jsr bell
	jmp mg_l1
;
chk_insrt:
	pha
	stx xsave
	bit insert_mode
	bpl no_insrt
	ldx longest
	cpx #maxlen
	beq ins_err
ins_l1:	lda string,x
	sta string+1,x
	dex
	cpx #<-1
	beq saywhen
	cpx xsave
	bcs ins_l1
	beq ins_l1
saywhen:
	inc longest
no_insrt:
	clc
ins_err:
	pla
	ldx xsave
	rts
;**********************
cchar:	and #%00011111
	asl a
	tay
	lda mgdispatch+1,y
	pha
	lda mgdispatch,y
	pha
	rts
;
mgdispatch:
	.addr mg_err-1	;ctrl-at
	.addr ctrlb-1	;ctrl-a (like Ctrl-B = beginning of line)
	.addr ctrlb-1
	.addr ctrlc-1
	.addr ctrld-1
	.addr ctrln-1	;ctrl-e = ctrl-n
	.addr ctrlf-1
	.addr mg_err-1	;ctrl-g
	.addr ctrlh-1	;bs = backspace
	.addr ctrli-1	;insert = tab
	.addr ctrlj-1	;j = down arrow
	.addr ctrlk-1	;k = up arrow
	.addr mg_err-1	;l
	.addr ctrlm-1	;return
	.addr ctrln-1
	.addr mg_err-1	;o
	.addr mg_err-1	;p
	.addr ctrlq-1
	.addr ctrlr-1
	.addr mg_err-1	;s
	.addr mg_err-1	;t
	.addr ctrlu-1
	.addr mg_err-1	;v
	.addr mg_err-1	;w
	.addr ctrlx-1
	.addr ctrly-1	;y
	.addr mg_err-1	;z
	.addr ctrlx-1	;esc = ctrlx (for new //e kbd "clear")
	.addr mg_err-1	;ctrl-backslash
	.addr mg_err-1	;ctrl-right-bracket
	.addr mg_err-1	;ctrl-caret
	.addr mg_err-1	;ctrl-underscore
;****************************************
doApple:
	jsr downcase
	cmp #$80+'y'
	beq ctrly
	cmp #$80+'<'
	beq ctrlb0
	cmp #$80+','
	beq ctrlb0
	cmp #$80+'H'-ctrl	;1.3 - Apple-left-arrow
	beq ctrlb0	;1.3   beginning of line
	cmp #$80+'>'
	beq ctrle0
	cmp #$80+'.'
	beq ctrle0
	cmp #$80+'U'-ctrl	;1.3 - Apple-right-arrow
	beq ctrle0	;1.3   end of line
	cmp #$80+'e'
	beq tglInsert
	jmp mg_err
;
ctrlb0:	jmp ctrlb
ctrle0:	jmp ctrln
;**********************
tglInsert:
	lda insert_mode
	eor #$80
	sta insert_mode
	jmp mg_l1
;**********************
ctrly:	stx xsave	;truncate cmd lin at cursor
yblanks:
	jsr pr_sp
	inx
	cpx longest
	bcc yblanks
ybacks:	jsr pr_bs
	dex
	cpx xsave
	bne ybacks
	stx longest
	jmp mg_l1
;
ctrlm:	lda longest	;Return = keep entire line
	jsr upto_a
ctrlq:	stx xsave	;truncate & Return
blanks:	jsr pr_sp
	inx
	cpx longest
	bcc blanks
backs:	jsr pr_bs
	dex
	cpx xsave
	bne backs
	bit exec_flag
	bmi invis2
	jsr crout
invis2:	clc
	rts
;
; FIND command -- make cursor into a ">" and
; move forward to next occurrence of keypress
;
ctrlf:
mgfind_l1:
	lda #$80+'>'
	jsr rdchar
	jsr upcase
	cmp #$80+'['-ctrl
	bne find_cont
	jmp mg_l1
find_cont:
	stx xsave
find_l2:
	inx
	cpx longest
	beq f_cont
	bcc f_cont
; Not found
	ldx xsave
	jmp mg_l1
f_cont:	pha
	lda string,x
	jsr upcase
	sta p
	pla
	cmp p
	bne find_l2
	txa	;found!
	ldx xsave
	jsr upto_a
	jmp mgfind_l1
;
ctrlh:	;backspace
	lsr insert_mode
	cpx #0
	bne bs_ok
	jmp mg_err
bs_ok:	jsr pr_bs
	dex
	jmp mg_l1
;
ctrlc:
	jsr mg_can
	sec
	rts
;
ctrli:	sec
	ror insert_mode
	jmp mg_l1
;
ctrlx:
	lsr insert_mode
	jsr mg_can
	sec
	rts
;
mg_can:	jsr backx
	ldx longest
	jsr spacex
	jsr backx
	ldx #0
	stx longest
	lsr insert_mode
	rts
;
mgdelete:
	cpx #0
	beq dele_x
	jsr pr_bs
	dex
	jmp ctrld
dele_x:	jmp mg_err
;
ctrlr:	jsr ctrlr2
	jmp mg_l1
;
ctrlr2:
	jsr mg_can
	lda hist_level
	cmp #<-1
	bne ctrlrz
	lda #0
	sta hist_level
ctrlrz:
	inc hist_level
histtry:
	dec hist_level
	lda hist_level
	ldx #mli_read
	jsr HistoryMgr
	bcs histtry
	sta p+1
	sty p
	ldy #maxlen+1
gitit:	lda (p),y
	sta string,y
	dey
	cpy #<-1
	bne gitit
;
	ldx #0
r_l1:	lda string,x
	beq r_dun
	jsr cout0
	inx
	bne r_l1
r_dun:	stx longest
	rts
;
ctrlj:	;down arrow
	dec hist_level
	bmi ctrlk
	jmp ctrlr
;
ctrlk:	;up arrow
	inc hist_level
	jmp ctrlr
;
ctrld:	lsr insert_mode	;delete at cursor
	cpx longest
	bcc len_ok
	jmp mg_err
len_ok:	dec longest
	stx xsave
dl_l1:	cpx longest
	bcs dl1_dun
	lda string+1,x
	sta string,x
	jsr cout0
	inx
	bne dl_l1
dl1_dun:
	jsr pr_sp
	inx
dl_back:
	jsr pr_bs
	dex
	cpx xsave
	bne dl_back
	jmp mg_l1
;
ctrlu:
	lsr insert_mode
	cpx longest
	bcc len_ok2
	jmp mg_err
len_ok2:
	lda string,x
	jsr cout0
	inx
	jmp mg_l1
;
ctrlb:	;beginning of line
	jsr backx
	ldx #0
	jmp mg_l1
;
ctrln:	lda longest	;end of line
	jsr upto_a
	jmp mg_l1
;*********************************
backx:	lda #bs
	bne rep_x	; always
spacex:	lda #space
rep_x:	stx xsave
	cpx #0
	beq rx_x
rx_l1:	jsr cout
	dec xsave
	bne rx_l1
rx_x:	rts
;
upto_a:	sta xsave
ut_l1:	cpx xsave
	bcs ut_dun
	lda string,x
	jsr cout0
	inx
	bne ut_l1
ut_dun:	rts
;********************************
pr_sp:
	lda #$20
	bne print_a	; Always
pr_bs:
	lda #$08
	bne print_a	; Always
print_a:
	jmp cout
;

cout0:
	cmp #space	; #$20
	bcs coutnorm
	sty ysave
	start_inverse
	ora #%01000000
	jsr cout
	start_normal
	ldy ysave
	rts
coutnorm:
	jmp cout
;
; print a path (AY)
;
print_path:
	sta p+1
	sty p
	ldy #0
	lda (p),y
	tax	;length
	beq pp_dun
ppth1:	iny
	lda (p),y
	ora #%10000000
	jsr cout
	dex
	bne ppth1
pp_dun:	rts
;
; print file type XXX from A
;
print_ftype:
	sta temp
	ldx #0
pft1:	lda filetyp,x
	beq tryf2
	cmp temp
	beq pftfound
	inx
	bne pft1
; now try the built-in list  27-Jan-90
tryf2:
	ldx #0
pft2:	lda filetyp0,x
	beq pftx
	cmp temp
	beq pft2found
	inx
	bne pft2
;
pftx:	lda temp
	pha
	lda #$80+'$'
	jsr cout
	pla
	jsr prbyte
	sec
	rts

pftfound:
	stx temp
	txa
	asl a
	adc temp
	tax
	ldy #3
pftfnd1:
	lda fileasc,x
	ora #%10000000
	jsr cout
	inx
	dey
	bne pftfnd1
	clc
	rts

pft2found:
	stx temp
	txa
	asl a
	adc temp
	tax
	ldy #3
pftfnd2:
	lda fileasc0,x
	ora #%10000000
	jsr cout
	inx
	dey
	bne pftfnd2
	clc
	rts
;
; print access byte from A
;
;   d n b * * i w r
;   - - - - - - - -
;
;    rwnd B
print_access:
	sta temp
	ldx #5
pa1:	lda access_bits,x
	and temp
	php
	lda chrs,x
	plp
	bne not_bit
	lda #$a0
not_bit:
	jsr cout
	dex
	bpl pa1
	rts
chrs:	asc_hi "BIdnwr"
access_bits:
	.byte %00100000
	.byte %00000100
	.byte %10000000
	.byte %01000000
	.byte %00000010
	.byte %00000001
;**********************************
;
; print_ver -- A --> vX.X
;
print_ver:
	pha
	lda #$80+'v'
	jsr cout
	pla
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	jsr pvnib
	lda #$80+'.'
	jsr cout
	pla
pvnib:	and #%00001111
	jmp prdec_1
;
; print_sd -- A ==> _sd
;
print_sd:
	pha
	lda #$80+'.'
	jsr cout
	pla
	pha
	and #%01110000
	lsr a
	lsr a
	lsr a
	lsr a
	ora #$80+'0'
	jsr cout
	pla
	rol a
	lda #$80+'1'
	adc #0
	jmp cout

;***********************************************
fetch_ch:
	bit $c01f
	bpl fetch40
; fetch80
	sta $c001
	sta $c055
	tya
	lsr a
	tay
	bcc fetch1
	sta $c054
fetch1:	lda ($28),y
	sta $c054
	rts
fetch40:	lda ($28),y
	rts
;***********************************************
TalkCont:
	lda keyboard
	cmp #$98	;Ctrl-X?
	bne tcX
	sta kbdstrb
tcX:	rts
;***********************************************


;****************************************************
;
; redirect -- adjust redir_susplv by A, and return
;             A=%oixxxxxx
;               o=output will be redirected
;               i=input will be redirected
;
xxremref:	.byte 0
redtmp:	.byte 0
redirect:
lvpos:
rdoutx:
rdinx:
redir_x:
	rts
;
; suspend -- temporarily stop redir I/O
;
suspend:
;
; restore -- resume redir I/O
;
restore:
;	lda #$00
	rts
;************************************************
;
; begin_oredir -- start redirecting output
; to path in AY ("&" = printer)
;
redir_err:	jmp ProDOS_err
begin_oredir:
notN:
do_rem_out:
open_slA:
openSlOk:
rts99:	rts
slotn:	.byte 0
;
bord_file:
bordcr:
bo_rdx:	rts
;
bordop_p:	.byte 3
bordop_pth:	.res 2
	.addr buff_oredir
bordop_ref:	.res 1
;
bordcr_p:	.byte 7
bordcr_pth:	.res 2
	.byte %11000011
	.byte tTXT
	.addr 0
	.byte 1
	.addr 0,0
;*******************************************
;
; finish_oredir -- close output file
;
finish_oredir:
ford2x:	rts

finish_o2:
ford_file:
fordx:
fordxx:	rts
;
; file_ochar -- send char to output file
;
thischar:
	.res 1
coutx:
	.res 1
couty:
	.res 1
;
file_ochar:
	rts
; osusp--print to screen
osusp:
foc_err:
	rts
;
file_ochar_p:	.byte 4
routref:	.res 1
	.addr thischar
	.addr 1
	.addr 0
;
; append -- set mark on refnum=A to eof
;
append:
	rts
;app_err jmp ProDOS_err
;
append_p:	.byte 2
append_ref:	.byte 0
	.byte 0,0,0
;
; finish_iredir -- stop redirecting input
;
finish_iredir:
firedrx:	rts

finish_i2:
	rts
closeIfile:
finished_i:
	rts
;
; begin_iredir -- start getting input from
; path in AY
;
begin_iredir:
ird_notDflt:
ird_notSl:
notScript:
exec_txt:
birdx:	rts
;
bird_p:	.byte 3
bird_path:	.res 2
	.addr buff_iredir
bird_ref:	.res 1
;
; file_ichar -- KSW routine for exec
;
keyx:	.res 1
keyy:	.res 1
file_ichar:
;ldx keyx
;ldy keyy
;lda undercur
;jmp rdchar2 ;was jmp (ksw) 5-Jul-87
bird_er:
ich_er:
file_ix:
ThisIchr:
	rts
;
isusp:
; jmp my_rdchar
;
undercur:	.res 1
ichar_p:	.byte 4
ichar_ref:	.res 1
	.addr file_ix+1
	.addr 1
	.addr 0

do_rem_in:
ird_Slot:
	rts

twoplusKey:
	clc
	rts
