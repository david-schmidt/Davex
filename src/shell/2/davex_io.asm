;***************************************************
;
; DAVEX I/O routines
;
rdchar0:
	pla
rdchar:	pha
kagain:	pla
	pha
	jsr rdchar2
	jsr twoplusKey
	bcs kagain
	jsr CheckHC
	bcc rdchar0
	tay
	pla
	tya
	rts

rc_spch:
	ldy $24
	stx x99
	lda ($28),y
	jsr x98
	ldx x99
	rts
x98:	jmp (ksw)

rdchar2:
	bit speech
	bmi rc_spch
	jmp (ksw)
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

rdkey2:
;
; move cursor forw & back to scroll during NORMAL
; for //e 80 col; avoids filling bottom line with
; inverse blanks
;
	bit two_e_flag
	bpl noforwback
	lda scr_width
	cmp #80
	bcc noforwback
	lda #$9C	;cursor forward
	jsr vcout
	lda #$88	;cursor back
	jsr vcout
noforwback:

	lda invflg
	pha
	jsr inverse
	lda rc_temp
	jsr cout0
	jsr pr_bs
rc_l1:	lda keyboard
	bmi h_key
	jsr poll_io
	jsr poll_inslot
	bcs rc_l1
	bcc h_key2
h_key:	sta kbdstrb
h_key2:	sta theKey
	pla
	sta invflg
	lda rc_temp
	jsr cout0
	jsr pr_bs
	lda theKey
	rts
theKey:	.byte 0
vcout:	jmp (vid_csw)
;
; poll_inslot -- return CLC,A=char or SEC
;
in_xval: .res 1
in_yval: .res 1

poll_inslot:
	stx in_xval
	sty in_yval
	jsr poll_in2
	ldx in_xval
	ldy in_yval
	rts
poll_in2:
;;;	sec
	ldy redir_in
;;;	beq polled_in
	cpy #$f0	;8-Mar-90
	bcc WasExec	;8-Mar-90
	ldx #mli_read-$80
	jsr xprint_drvr
	bcc pollichar
	cmp #0
	beq polled_in
	jmp xProDOS_err
pollichar:
	ora #$80
polled_in:
	rts

WasExec:
	sec
	rts
;
; Mess with ShiftKey Mod and Ctrl-L for
; the II+
;
twoplusKey:
	bit two_e_flag
	bmi is_e_c
	cmp #$80+'L'-ctrl
	bne not_tgl
	lda lc_flag
	eor #%10000000
	sta lc_flag
	sec
	rts
not_tgl:
	bit lc_flag
	bpl nolc
	cmp #$80+']'
	bne not1
	lda #$80+'M'
not1:	cmp #$80+'^'
	bne not2
	lda #$80+'N'
not2:	cmp #$80+'@'
	bne not3
	lda #$80+'P'
not3:
	bit $C063
	bpl nolc
	cmp #$80+'A'
	bcc nolc
	cmp #$80+'Z'+1
	bcs nolc
	ora #%00100000
nolc:
is_e_c:
	clc
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
yesno:	lda #0		;no default response for this Y/N question
yesno2:	ora #$80
	sta yn_dflt
	bit speech
	bmi shortyn
	jsr xmess
	cstr "? (y/n) "
	jmp yn_l1
shortyn:
	lda #$80+'?'
	jsr cout
yn_l1:	lda yn_dflt
	cmp #$80
	bne somedflt
	lda #space
somedflt:
	jsr rdchar
	jsr xdowncase
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
	jsr xbell
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
	jmp xProDOS_err
;
use_yndflt:
	cmp #$8d	;Return = default choice
	beq ynd1
	cmp #$a0	;Space = default choice
	beq ynd1
	rts
ynd1:	lda yn_dflt
	rts

yn_dflt: .byte 0
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

prdec_pady:
	sec
	ror pad_flag
	lsr digit_flag
	bpl prd_l1

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
;;	sec
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

hist_level: .byte 0

mygetln2:
	lda #0
	jsr xredirect
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
	ldy $fbb3	;contains $38 (sec) in original Apple II ROM, $06 in IIe
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

mg_err:	jsr xbell
	jmp mg_l1

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
	jsr xdowncase
	cmp #$80+'y'
	beq ctrly
	cmp #$80+'<'
	beq ctrlb0
	cmp #$80+','
	beq ctrlb0
	cmp #$80+'H'-ctrl	;1.3 - Apple-left-arrow
	beq ctrlb0		;1.3   beginning of line
	cmp #$80+'>'
	beq ctrle0
	cmp #$80+'.'
	beq ctrle0
	cmp #$80+'U'-ctrl	;1.3 - Apple-right-arrow
	beq ctrle0		;1.3   end of line
	cmp #$80+'e'
	beq tglInsert
	jmp mg_err

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

ctrlh:			;backspace
	lsr insert_mode
	cpx #0
	bne bs_ok
	jmp mg_err
bs_ok:	jsr pr_bs
	dex
	jmp mg_l1

ctrlc:
	jsr mg_can
	sec
	rts

ctrli:	sec
	ror insert_mode
	jmp mg_l1

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

mgdelete:
	cpx #0
	beq dele_x
	jsr pr_bs
	dex
	jmp ctrld
dele_x:	jmp mg_err

ctrlr:	jsr ctrlr2
	jmp mg_l1

ctrlr2:	jsr mg_can
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

	ldx #0
r_l1:	lda string,x
	beq r_dun
	jsr cout0
	inx
	bne r_l1
r_dun:	stx longest
	rts

ctrlj:	;down arrow
	dec hist_level
	bmi ctrlk
	jmp ctrlr

ctrlk:	;up arrow
	inc hist_level
	jmp ctrlr

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

ctrlb:	;beginning of line
	jsr backx
	ldx #0
	jmp mg_l1

ctrln:	lda longest	;end of line
	jsr upto_a
	jmp mg_l1
;*********************************
backx:	lda #bs
	bne rep_x
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
pr_sp:	lda #space
	bne print_a
pr_bs:	lda #$80+'H'-ctrl
	bne print_a
print_a:
	jmp cout

cout0:	cmp #space
	bcs coutnorm
	sty ysave
	jsr inverse
	ora #%01000000
	jsr cout
	jsr normal
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
;;;jsr xdowncase ;11-Jun-89
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
fetch40:
	lda ($28),y
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
redtmp:		.byte 0

redirect:
	clc
	adc redir_susplv
	sta redir_susplv
	bpl lvpos
	lda #0
	sta redir_susplv
lvpos:
	php
	lda remslot
	clc
	adc #refSlot0
	sta xxremref
	lda #0
	plp
	bne redir_x
	ldx redir_out
	beq rdoutx
	cpx xxremref
	beq rdoutx
	ora #%10000000
rdoutx:	ldx redir_in
	beq rdinx
	cpx xxremref
	beq rdinx
	ora #%01000000
rdinx:
redir_x:
	sta redtmp
	bit redtmp
	rts
;
; suspend -- temporarily stop redir I/O
;
suspend:
	lda #1
	jmp redirect
;
; restore -- resume redir I/O
;
restore:
	php
	pha
	lda #<-1
	jsr redirect
	pla
	plp
	rts
;************************************************
;
; begin_oredir -- start redirecting output
; to path in AY ("&" = printer)
;
redir_err:
	jmp ProDOS_err
begin_oredir:
	sta p+1
	sty p
	sta bordop_pth+1
	sty bordop_pth
	sta bordcr_pth+1
	sty bordcr_pth
	jsr finish_o2
	ldy #0
	lda (p),y
	beq rts99
	cmp #1
	bne bord_file
	iny
	lda (p),y
	ora #%10000000
	cmp #$80+'0'
	bcc notN
	cmp #$80+'9'+1
	bcs notN
	and #%00001111
	jmp open_slA
notN:	cmp #$80+'&'
	bne bord_file
; open printer for redirection
	lda #0	;slot number! 0="&" %%%
do_rem_out:
open_slA:
	sta slotn
	ldx #mli_open
	jsr print_drvr
	bcc openSlOk
	clc
	lda slotn
	adc #refSlot0
	tay
	ldx #mli_close
	jsr print_drvr
	lda slotn
	ldx #mli_open
	jsr print_drvr
	bcs redir_err
openSlOk:
	sta redir_out	;refnum
	sta routref
	lda #>prtr_char
	ldy #<prtr_char
	sta csw+1
	sty csw
rts99:	rts

slotn:	.byte 0

bord_file:
	jsr mli
	.byte mli_create
	.addr bordcr_p
	bcc bordcr
	cmp #err_dupfil
	beq bordcr
	jmp ProDOS_err
bordcr:
	lda level
	pha
	lda #redir_level
	sta level
	jsr mli
	.byte mli_open
	.addr bordop_p
	bcs redir_err2
	pla
	sta level
	lda bordop_ref
	sta redir_out
	sta routref
	lda #>file_ochar
	ldy #<file_ochar
	sta csw+1
	sty csw
bo_rdx:	rts

redir_err2:
	jmp ProDOS_err

bordop_p:
	.byte 3
bordop_pth:
	.res 2
	.addr buff_oredir
bordop_ref:
	.res 1

bordcr_p:
	.byte 7
bordcr_pth:
	.res 2
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
	jsr finish_o2
	lda remslot
	beq ford2x
	lda redir_out
	bne ford2x
	lda remslot
	jmp do_rem_out
ford2x:	rts

finish_o2:
	lda redir_out
	sec
	sbc #refSlot0
	cmp remslot
	beq fordxx
	lda vid_csw+1
	ldy vid_csw
	sta csw+1
	sty csw
	jsr hook_ospeech
	lda redir_out
	beq fordx
	cmp #refSlot0
	bcc ford_file
; close printer
	tay
	ldx #mli_close
	jsr print_drvr
	bcc fordx
	jmp ProDOS_err
ford_file:
	lda level
	pha
	lda #redir_level
	sta level
	lda redir_out
	jsr close
	pla
	sta level
fordx:	lda #0
	sta redir_out
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
	pha
	and #%01111111
	sta thischar
	stx coutx
	sty couty
	lda redir_susplv
	bne osusp
	jsr mli
	.byte mli_write
	.addr file_ochar_p
	bcs foc_err
	pla
	ldx coutx
	ldy couty
	rts
; osusp--print to screen
osusp:
	pla
	ora #%10000000
	sta thischar
	lda csw+1
	pha
	lda csw
	pha
	lda vid_csw+1
	sta csw+1
	lda vid_csw
	sta csw
	lda thischar
	jsr cout
	pla
	sta csw
	pla
	sta csw+1
	jmp coutdone
;
foc_err:
	pha
	jsr finish_oredir
	pla
app_err:
	jmp ProDOS_err

file_ochar_p:	.byte 4
routref:	.res 1
		.addr thischar
		.addr 1
		.addr 0
;
; append -- set mark on refnum=A to eof
;
append:	sta append_ref
	jsr mli
	.byte mli_geteof
	.addr append_p
	bcs app_err
	jsr mli
	.byte mli_setmark
	.addr append_p
	bcs app_err
	rts

append_p:	.byte 2
append_ref:	.byte 0
		.byte 0,0,0
;
; finish_iredir -- stop redirecting input
;
finish_iredir:
	jsr finish_i2
	lda remslot
	beq firedrx
	lda redir_in
	bne firedrx
	jmp do_rem_in
firedrx:
	rts

finish_i2:
	lda #>my_rdchar
	ldy #<my_rdchar
	sta ksw+1
	sty ksw
	jsr hook_ispeech
	lda redir_in
	beq finished_i
	tay
	sec
	sbc #refSlot0
	cmp remslot
	beq finished_i
	cpy #refSlot0
	bcc closeIfile
	ldx #mli_close-$80
	jsr print_drvr
	bcs iFileEr
	rts
iFileEr:
	jmp ProDOS_err
closeIfile:
	lda level
	pha
	lda #redir_level
	sta level
	tya
	jsr close
	pla
	sta level
	lda #0
	sta redir_in
finished_i:
	rts
;
; begin_iredir -- start getting input from
; path in AY
;
begin_iredir:
	sta bird_path+1
	sty bird_path
	sta p+1
	sty p
	ldy #0
	lda (p),y
	beq birdx
	cmp #1
	bne ird_notSl
	tay
	lda (p),y
	and #$7f
	cmp #'&'
	bne ird_notDflt
	lda #2	;%%% config?
	ora #'0'
ird_notDflt:	cmp #'1'
	bcc ird_notSl
	cmp #'7'+1
	bcs ird_notSl
	and #$0f
	jmp ird_Slot
ird_notSl:
	lda p+1
	ldy p
	jsr getinfo
	lda info_type
	cmp #$C6	;$C6;8001=Davex script
	bne notScript
	ldx info_auxtype+1
	ldy info_auxtype
	cpx #$80
	bne notScript
	cpy #$01
	beq exec_txt
notScript:
	cmp #tTXT
	beq exec_txt
	cmp #$B0	;SRC
	beq exec_txt
	lda #der_nottxt
	jmp ProDOS_err
exec_txt:
	lda #redir_level
	sta level
	jsr mli
	.byte mli_open
	.addr bird_p
	ldx #stdlevel
	stx level
	bcs bird_er
	lda bird_ref
	sta redir_in
	lda #>file_ichar
	ldy #<file_ichar
	sta ksw+1
	sty ksw
birdx:	rts

bird_p:		.byte 3
bird_path:	.res 2
		.addr buff_iredir
bird_ref:	.res 1
;
; file_ichar -- KSW routine for exec
;
keyx:	.res 1
keyy:	.res 1

file_ichar:
	sta undercur
	stx keyx
	sty keyy
	ldx redir_susplv
	bne isusp
	lda redir_in
	sta ichar_ref
	jsr mli
	.byte mli_read
	.addr ichar_p
	bcc file_ix
	pha
	jsr finish_iredir
	pla
	cmp #err_eof
	bne ich_er
;;;	ldx keyx
;;;	ldy keyy
	sec	;5-Feb-90
	ror fudgeCR	;5-Feb-90
	lda #$8d
	bne ThisIchr

bird_er:
ich_er:	jmp ProDOS_err
file_ix:
	lda #0	;cheat!
	ora #%10000000
ThisIchr:
	ldx keyx
	ldy keyy
	rts

isusp:	ldx keyx
	ldy keyy
	lda undercur
; jmp my_rdchar
	jmp (speechi)	;5-Dec-87

undercur:
	.res 1
ichar_p:
	.byte 4
ichar_ref:
	.res 1
	.addr file_ix+1
	.addr 1
	.addr 0

do_rem_in:
	lda remslot
ird_Slot:
	ldx #mli_open-$80	;open for input
	jsr print_drvr
	bcs ich_er
	sta redir_in
	rts
