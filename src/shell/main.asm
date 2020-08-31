;
; Davex by David A. Lyons
;
; Begun 31-Aug-85
;
;***********************************************
;
; Converted to ca65 09/2011 (from 1.30 source)
;  -Tabs set at 8 characters
;  -Refactored to run on SOS as well as ProDOS
;
; Davex 1.30 2-Dec-99
;  -Changed shareware notice to Freeware notice.
;  -Removed serial number support.
;  -Y2K compliant
;  -Prints a warning if the clock's year number is >99.
;  -Help mentions "?topics".
;  -Command line: Apple-left, Apple-right, Control-A.
;  -Yes/No questions: Q = abort (like Esc/Cmd-Period).
;
; Converted to MPW IIgs 13-Sep-92 DAL (from 1.27 source)
;  asmiigs davex.aii
;  linkiigs davex.aii.obj -o davex
;  makebiniigs davex -org $2000
;  setfile davex -c pdos -t PSYS
;  dup Davex :
;
;***********************************************

; Message with string
.macro	message_cstr Arg
	jsr mess
	cstr Arg
.endmacro

; Message with string, trailing Return
.macro	message_cstr_cr Arg
	jsr mess
	cstr_cr Arg
.endmacro

;***********************************************
copyright:
	jsr crout
	jsr pDavexVer
	jsr mess
dollar:	asc "Copyright (c) 1988-2020"
	.byte cr
	asc "by David A. Lyons"
	.byte cr,cr 
	asc "  https://github.com/david-schmidt/Davex"
	.byte cr,cr
	asc "Davex is Y2K compliant if you use ProDOS 8 2.0.3 or later."
.if  Proto 
	.byte cr,cr
	asc "PROTOTYPE VERSION FOR TESTING ONLY - NOT A STABLE RELEASE."
.endif
	.byte cr,0
	rts

;***********************************************
;
; RESTART (come here on RESET or Ctrl-Y or whatever)
;
restart:
	lda #0
	sta remslot	; %%% ?
.if IsDavex3
	; Respond to the configuration setting of column numbers
	lda cfg40
	jsr config_set_columns
.else ; IsDavex2
	jsr on80
.endif ; IsDavex3
	jsr finish_oredir

	lda #0
	sta fudgeCR
	sta redir_susplv
	sta redir_out
	sta redir_in
	SET_LEVEL
	jsr close
	jsr finish_iredir

	jsr spool_zap
	lda #0
	ldx #6
prclz:	sta SlotsOpen,x
	dex
	bpl prclz

	lda #<-1
	sta dir_level
	lda #>dirstack
	ldy #<dirstack
	sta dstk_ptr+1
	sty dstk_ptr
;
; 1st time ONLY, 'exec %autoexec'
;
aexec:	jsr do_autoexec	;opcode MODIFIED below
	lda #$ad	;lda abs
	sta aexec
;
; Welcome msg
;
	jsr f8rom_init	; $fb2f	;F8ROM:INIT
	start_normal
	jsr clear_sc
wCheat:	jsr welcome
	lda #>wNotQuiet
	ldy #<wNotQuiet
	sta wCheat+2
	sty wCheat+1
	jmp prompt

time_pr:
	lda #0
	jsr redirect
	bvs prompt
	bit fudgeCR	;5-Feb-90
	bpl noFudge	;5-Feb-90
	lsr fudgeCR	;5-Feb-90
	bpl prompt	;5-Feb-90
noFudge:
	jsr print_time
prompt:
	clc
	lsr stepping
	lda #0
	jsr redirect
	bvs no_cont
	jsr TalkCont	;turn voice back on (clear Ctrl-X)
	jsr restore80
no_cont:
	jsr finish_oredir
	lda #close_level
	SET_LEVEL
	lda #0
	sta rep_count+1
	sta rep_count
	jsr close	;a=0
	lda #stdlevel
	SET_LEVEL
	lda #<-1
	sta dir_level
	jsr save_config
	cli	;for IIgs users
	lda #0
	sta $48	;mon P
	lda #0	;27-Jan-90
	jsr redirect
	and #%11000000
	bne noGetlnCR
	jsr crout	;13-Jun-87
noGetlnCR:
	jsr getln
	cpx #0
	beq time_pr

	ldx #0
	stx parse_index

nextcmd:
	ldx #mli_close
	jsr mmgr

	jsr munch_space
prompt0:
	beq prompt
	cmp #_';'
	beq FoundSemi

	lda #10
	sta ExpandCount
ExpAgain:
	lda #>string
	ldy #<string
	jsr exp_alias
	php
	jsr munch_space
	plp
	bcs Expanded
	dec ExpandCount
	bne ExpAgain
Expanded:

	jsr parse_exec

	jsr chrgot
	beq prompt0
	cmp #_';'
	beq FoundSemi

	lda #der_semiexp
	jmp ProDOS_err
;
; Found a semicolon; munch text of first command and
; loop back for the next one
;
FoundSemi:
	jsr ms0
	ldx parse_index
	ldy #0
ShiftCmd:
	lda string,x
	sta string,y
	iny
	inx
	cpx string-1
	bcc ShiftCmd
	beq ShiftCmd
	lda string-1
	sec
	sbc parse_index
	sta string-1
	ldx #0
	stx parse_index
	jmp nextcmd

ExpandCount:
	.byte 0

;***********************************************
main_err:
	jsr finish_oredir
	jsr finish_iredir
	lda #0
	sta redir_susplv
	jsr bell
	jmp fix_stack

chrget:	inc parse_index
chrgot:	ldx parse_index
	lda string,x
	rts

;***********************************************
;
; parse_cmd -- parse a cmd word from command line
;              return CLC and cmd_addr if OK;
;              otherwise SEC
;
parse_cmd:
	lsr externalc
	lda #>command
	ldy #<command
	jsr parse_word
	sty command-1
	jsr point_cmdtbl
pc1:	jsr cmp_cmd
	clc
	beq found_cmd
	jsr point_nxtcmd
	bne pc1
;
; scan for BIN,SYS,S16,EXE,DIR... file with given name
;
	lda #>(command-1)
	ldy #<(command-1)
	jsr fixup_path_ay
	lda #>(command-1)
	ldy #<(command-1)
	jsr scanall
	bcs huh
;
; Here is where to do "appl" stuff, such as mapping BAS files
; to automatically be launched via BASIC.SYSTEM
;
	cmp #tDIR
	beq gotoDIR
	jsr run_something
	sec
	ror externalc
	clc
found_cmd:
	rts

gotoDIR:
	CALLOS mli_setpfx, gdParms
	CALLOS_BRANCH_POS wentD
	jmp ProDOS_err
wentD:
	lda #>nullcmd
	ldy #<nullcmd
	sta cmd_addr+1
	sty cmd_addr
	lda #>nullentr
	ldy #<nullentr
	sta cmd_ptr+1
	sty cmd_ptr
	clc
nullcmd:
	rts
nullentr:
	.byte 'x',0	; command name
	.addr nullcmd
	.byte $FF	;no parms

gdParms:
	.byte 1
	.addr cmdpath
;
; huh?
;
huh:	jsr print_cmd
	message_cstr_cr ": huh?"
	jmp main_err

;
; parse a word (up to blank, semi, eol) to AY
;
parse_word:
	sta p+1
	sty p
	ldy #0
parsew1:
	jsr chrgot
	beq pw_x
	cmp #_' '
	beq pw_x0
	cmp #_';'
	beq pw_x
	jsr downcase
	sta (p),y
	iny
	cmp #_'?'
	beq pw_x2
	cmp #_'-'
	beq pw_x2
	jsr chrget
	jmp parsew1
pw_x2:	jsr chrget
pw_x0:	jsr munch_space
pw_x:	lda #0
	sta (p),y
	rts
;
; set cmd_ptr = cmdtbl
;
point_cmdtbl:
	lda #>cmdtbl
	ldy #<cmdtbl
	sta cmd_ptr+1
	sty cmd_ptr
	rts
;
; advance cmd_ptr to next command
; return BEQ if no more commands in table
;
point_nxtcmd:
	jsr adv_cmdptr
	bne point_nxtcmd
	jsr adv_cmdptr	;pointing at addr
skipparm:
	jsr adv_cmdptr	;pointing at addr+1
	jsr adv_cmdptr	;pointing at parm1
	cmp #$ff		;1.4: a single $FF byte can end the parameter table (or the old $00, $00)
	beq adv_cmdptr
	iny
	ora (cmd_ptr),y
	bne skipparm
	jsr adv_cmdptr
;
; fall into adv_cmdptr
;
adv_cmdptr:	inc cmd_ptr
	bne cp_ok
	inc cmd_ptr+1
cp_ok:	ldy #0
	lda (cmd_ptr),y
	rts
;
; print command word
;
print_cmd:
	lda #>(command-1)
	ldy #<(command-1)
	jmp print_path
;
; compare command string with cmd_ptr^
;
cmp_cmd:
	ldy #0	;points into cmd_ptr^
	ldx #0	;points into command
compcmd1:
	lda command,x
	cmp (cmd_ptr),y
	bne no_match
	cmp #0
	beq yes_match
	inx
	iny
	bne compcmd1
no_match:
	rts

yes_match:
	iny
	lda (cmd_ptr),y
	sta cmd_addr
	iny
	lda (cmd_ptr),y
	sta cmd_addr+1
	lda #0	;BEQ
	rts
;
; munch up to a nonspace or end of line
;
ms0:	jsr chrget
munch_space:
	jsr chrgot
	beq :+
	cmp #_' '
	beq ms0
:	jmp chrgot

parse_exec:
	jsr parse_cmd
	bcc execit
	jmp fix_stack

execit:	jsr parse_parms
;
; expand wildcards here & call routine
; until there are no more expansions
;
	lsr some_flag
	jsr wild_begin
wild_again:
	jsr wild_next
	bcs wild_done
	sec
	ror some_flag
;
; repeat command rep_count times (0 ==> 1)
; Note:  the REP command has to cheat to avoid
; an infinite loop; it changes the return address
; from JSR JMPCMD to return to REPEATED
;
rep_again:
	lda #stdlevel
	SET_LEVEL
	lda #0
	jsr getparm_n
	jsr jmpcmd
	jsr check_wait
	bcc rep_noAbort
	jmp yn_abort
rep_noAbort:
	lda #stdlevel
	SET_LEVEL
	lda #0
	jsr close
	jsr restore80
;
; repeat until rep_count == 0
;
	lda rep_count+1
	ora rep_count
	beq repeated
	lda rep_count
	bne :+
	dec rep_count+1
:	dec rep_count
	jmp rep_again
repeated:
;
; repeat cmd with next wildcard expansion
;
	jmp wild_again

wild_done:
	bit some_flag
	bmi did_some
	message_cstr_cr "(no files matched)"
did_some:
	rts

jmpcmd:	jmp (cmd_addr)

;***********************************************
;
; parse_parms -- parse command's parameters from
; command line into PARMS.
;
; cmd_ptr points to the command's name
;
parse_parms:
	bit externalc
	bmi parseparms2	;already found

find_parms:
	jsr adv_cmdptr
	bne find_parms
	jsr adv_cmdptr	;pt at addr
	jsr adv_cmdptr	;pt at addr+1
	jsr adv_cmdptr	;pt at parm1

parseparms2:
	lda #0
	sta num_parms
	lda #<-1	;don't confuse wildcards
	sta parmtypes
	sta parmtypes+1

	lda #>string_buffs
	ldy #<string_buffs
	sta strbuf+1
	sty strbuf

another:
	jsr one_parm
	bcc another
	jsr chrgot
	beq sortprm
	cmp #_';'
	beq sortprm
	lda #der_toomany	;too many parameters
	jmp der
sortprm:
	jsr bubble_parm
	bcc sortprm
	rts
;
; bubble_parm:  bubble a positional parameter
;    closer to beginning of list and return
;    CLC, or do nothing and return SEC
;
bubble_parm:
	lsr bub_flag
	ldy num_parms
	beq bubb_x
	dey
	beq bubb_x
	sty bub_count
	ldy #0
	ldx #0
bubb1:	lda parms,y
	beq no_bubb	;pos parm first is ok
	lda parms+4,y
	bne no_bubb
	jsr bub_swap
	sec
	ror bub_flag
no_bubb:
	inx
	iny
	iny
	iny
	iny
	dec bub_count
	bne bubb1
	bit bub_flag
	bpl bubb_x
	clc
	rts
bubb_x:	sec
	rts
bub_flag:	.byte 0
bub_count:	.byte 0

;
; swap parm x with parm x+1 (y=4x)
;
bub_swap:
	lda parmtypes,x
	pha
	lda parmtypes+1,x
	sta parmtypes,x
	pla
	sta parmtypes+1,x
	lda #4
	sta swapcount
bswap1:	lda parms,y
	pha
	lda parms+4,y
	sta parms,y
	pla
	sta parms+4,y
	iny
	dec swapcount
	bne bswap1
	dey
	dey
	dey
	dey
	rts

swapcount:
	.byte 0

;
; calc_pindex -- x=4*(num_parms-1)
;
calc_pindex:
	pha
	ldx num_parms
	dex
	txa
	asl a
	asl a
	tax
	pla
	rts

;***********************************************
;
; parse the next positional parameter
;
posit_parm:
	ldy #0
	lda (cmd_ptr),y
	bne posit_done	;option character present (or $FF marking end of parameter list)
	iny
	lda (cmd_ptr),y	;end of parm list?
	beq posit_done
	tax	;type of parm to parse
	lda #0	;opt char (none)
	jsr pval_ax
	jsr adv_cmdptr
	jsr adv_cmdptr
	clc
	rts
posit_done:
	sec
	rts

;***********************************************
;
; parse a parameter (positional or optional)
;
one_parm:
	jsr munch_space
	beq posit_parm
	cmp #_'-'
	bne posit_parm
	jsr chrget
	beq to_illeg_parm 	;"-" at end of line
opt_ok:	jsr downcase
	sta optchar
	jsr chrget	;point to char after option
	ldy #0
chk_allowed:
	lda (cmd_ptr),y	 ; 1.4: a single byte $FF can end the parameter list (like the old $00, $00)
	cmp #$ff
	beq to_illeg_parm
	iny
	lda (cmd_ptr),y
	dey
	cmp #0
	bne p_legal
	lda (cmd_ptr),y
	bne p_legal
to_illeg_parm:
	jmp illeg_parm
p_legal:
	lda (cmd_ptr),y
	ora #$80		; 1.4: the high bit is no longer required to be set on the "option" characters
	cmp optchar
	beq this_parm
	iny
	iny
	bne chk_allowed
this_parm:
	iny
	lda (cmd_ptr),y
	tax
	stx last_type
; 24-Jan-90
	beq noMunch98
	jsr munch_space
	ldx last_type
noMunch98:
;
	lda optchar
	jsr pval_ax
; 24-Jan-90
	lda last_type
	beq noMunchEm
	jsr munch_space
noMunchEm:

	jsr chrgot
	beq fudgex
	cmp #_'-'
	beq fudgex
	cmp #_';'
	beq fudgex
	ldx last_type
	bne fudgex
	cmp #_' '
	beq fudgex
; %%% multiple options after a single '-': disabled by removing next line
	jmp opt_ok
fudgex:	clc
	rts

last_type:
	.byte 0

;***********************************************
;
; pval_ax -- parse a nil, int2, int3, path, string,
;       device, yesno, or ftype parameter into the
;       parms table from the cmd line
;
; A contains option character of this parameter
; X contains the type of this parameter (t_xxx)
;
pval_ax:
	jsr pvax2
	ldx ptype
	cpx #t_path
	beq fixpath1
	cpx #t_wildpath
	beq fixpath1
	rts
fixpath1:
	ldx num_parms
	dex
	txa
	jsr getparm_n
	jmp fixup_path_ay

pvax2:	stx ptype
; record parameter type in table
	pha
	txa
	ldy num_parms
	sta parmtypes,y
	pla

	beq pv_legal
	pha
	jsr getparm_ch
	pla
	bcc duplicated

pv_legal:
	inc num_parms
	jsr calc_pindex
	sta parms,x	;store character into table
;
; dispatch by parm type
;
	lda ptype
	beq noMunch99	;24-Jan-90
	jsr munch_space	;12-Mar-88 DL
noMunch99:
	lda ptype
	cmp #t_devnum+1
	bcs badtype
	asl a
	tax
	lda parsers+1,x
	pha
	lda parsers,x
	pha
	jmp calc_pindex

parsers:
	.addr pv_done-1
	.addr pv_int-1
	.addr pv_int-1
	.addr pv_string-1	; path
	.addr pv_string-1	; wildpath
	.addr pv_string-1	; string
	.addr pv_int-1		; int1
	.addr pv_yesno-1
	.addr pv_ftype-1
	.addr pv_devnum-1

badtype:
	lda #der_badtype
	bne der

pv_done:
	clc
	rts
;
; duplicate parm -- given more than once
;
duplicated:
	lda #der_dupopt
der:	jmp ProDOS_err

;
; illegal parameter
;
illeg_parm:
	lda #der_illegparm
	bne der

;
; getparm_n -- return the value of the Ath parameter
;              parsed
;
; return SEC if that parameter was not given
;
getparm_n:
	cmp num_parms
	bcs gpn_x
	asl a
	asl a
	tax
retval_x:
	lda parms+3,x
	pha
	lda parms+2,x
	pha
	lda parms+1,x
	tay
	pla
	tax
	pla
	clc
gpn_x:	rts

;
; getparm_ch -- get option parameter corresponding to
;               the character in A
;
;  return SEC if that parm was not given
;
getparm_ch:
	ora #$80		; 1.4: the caller no longer needs to set bit 7
	ldx #0
	ldy num_parms
	sec
	beq gpn_x
chk_ch:	cmp parms,x
	beq retval_x
	inx
	inx
	inx
	inx
	dey
	bne chk_ch
	sec
	rts
;
; get_strbuf -- move strbuf down and return address
; in AY
;
get_strbuf:
	sec
	lda strbuf
	sbc #128
	tay
	lda strbuf+1
	sbc #0
	cmp #>(string_buffs-$300) ;only 6 buffers available
	bcc s2many
	sta strbuf+1
	sty strbuf
	rts
s2many:	ldx #der_outroom
	jmp ProDOS_err

;
; free_sbuff -- deallocate last string buff
;
free_sbuff:
	clc
	lda strbuf
	adc #128
	sta strbuf
	bcc fsbxx
	inc strbuf+1
fsbxx:	rts

;
; parse a "y" or "n" parameter
;
pv_yesno:
	jsr chrgot
	jsr downcase
	cmp #_'y'
	beq @yes
	cmp #_'n'
	beq @no
	lda #der_ynexp
	jmp ProDOS_err
@no:	lda #0
	beq @yn		;always taken
@yes:	lda #<-1
@yn:	pha
	jsr calc_pindex
	pla
	sta parms+3,x
	jmp chrget

;
; parse an integer parameter (1, 2, or 3 bytes)
;
pv_int:	lda #0
	sta num
	sta num+1
	sta num+2
	sta num+3
	jsr chrgot
	cmp #_'$'
	bne not_hex
	jmp hex_num
not_hex:
	jsr chk_dig
	bcs num_exp

int_1:	pha
	jsr mult10num
	pla
	and #%00001111
	clc
	adc num
	sta num
	bcc num_ok
	inc num+1
	bne num_ok
	inc num+2
	beq overflow
num_ok:	jsr chrget
	jsr chk_dig
	bcc int_1
return_chk:
	lda num+3	;17-Oct-89
	bne overflow	;17-Oct-89
	ldy ptype
	cpy #t_int2
	bne num_ok2
	lda num+2
	bne overflow
num_ok2:
	cpy #t_int1
	bne num_ok3
	lda num+1
	ora num+2
	bne overflow
return_num:
num_ok3:
	jsr calc_pindex
	lda num+2
	sta parms+3,x
	lda num+1
	sta parms+2,x
	lda num
	sta parms+1,x
	clc
	rts

num_exp:
	lda #der_badnum
der3:	jmp ProDOS_err

overflow:
	lda #der_bignum
	bne der3

; CLC if character is a digit, SEC otherwise
chk_dig:
	cmp #_'0'
	bcc chkdig_no
	cmp #_'9'+1
	rts
chkdig_no:
	sec
	rts

;
; mult10num - multiply num (4 bytes) by 10
;
; destroys temp (4 bytes)
;
; Overflow: Bails out, does not return.
;
mult10num:
	lda num
	ldx num+1
	ldy num+2
	sta temp
	stx temp+1
	sty temp+2
	lda num+3
	sta temp+3
	jsr mult2num	; *2
	jsr mult2num	; *4
	clc
	lda num
	adc temp
	sta num
	lda num+1
	adc temp+1
	sta num+1
	lda num+2
	adc temp+2
	sta num+2
	lda num+3
	adc temp+3
	sta num+3	; *5
	bcs overflow
mult2num:
	asl num
	rol num+1
	rol num+2
	rol num+3
	bcs overflow
	rts

;
; hex_num - parse a hex number
;
; Overflow: Bails out, does not return.
;
hex_num:
	jsr chrget	;skip past "$"
	jsr chk_hex
	bcs hex_exp
hex_1:	pha
	jsr mult2num
	jsr mult2num
	jsr mult2num
	jsr mult2num
	pla
	ora num		;never overflows byte here
	sta num
	jsr chrget
	jsr chk_hex
	bcc hex_1
	jmp return_chk

hex_exp:
	lda #der_badnum
	jmp ProDOS_err

chk_hex:
	jsr downcase
	cmp #_'0'
	bcc hex_x
	cmp #_'f'+1
	bcs hex_x
	cmp #_'9'+1
	bcc is_hex
	cmp #_'a'
	bcs is_hex0
hex_x:	sec
	rts
is_hex0:
	sec
	sbc #'a'-':'
is_hex:	and #%00001111
	clc
	rts
;
; Parse a path or string parm (possibly null,
; and possibly quoted); path possibly followed
; by a Type specifier (:xxx)
;
; Single (') or double (") quotes can be used,
; and a quote mark may be doubled inside the
; string to get just one quote (like Pascal
; does for single quotes)
;
pv_string:
	jsr get_strbuf
	sta p+1
	sty p
	sta parms+3,x
	tya
	sta parms+1,x
	lda #0
	sta parms+2,x	;file type
	sta quotechr
	tay
	sta (p),y
	sty string_index
	jsr munch_space
	jsr chrgot
	cmp #_'-'
	beq strdun
	cmp #$A7	;apostrophe
	beq gotqch
	cmp #_'"'	;double quote
	bne pstr_1
gotqch:	sta quotechr
pstr_0:	jsr chrget
pstr_1:	jsr chrgot
	beq strdun
	ldx quotechr
	bne sep_allowed
; if unquoted, check for blank, ";", comma
	cmp #_' '
	beq strdun
	cmp #_','
	beq strdun0
	cmp #_';'
	beq strdun
	ldy ptype
	cpy #t_string
	beq sep_allowed
	cmp #_':'
	beq typespec
sep_allowed:
	cmp quotechr
	beq strdun0
StrChar:
	inc string_index
	ldy string_index
	and #%01111111
	sta (p),y
	bne pstr_0
strdun0:
	jsr chrget
	beq strdun	;23-Feb-88
	cmp quotechr	;
	beq StrChar	;
strdun:	lda string_index
	ldy #0
	sta (p),y
	rts

typespec:
	lda string_index
	ldy #0
	sta (p),y
	jsr calc_pindex
	lda parms+1,x
	pha
	lda parms+3,x
	pha
	jsr chrget	;skip past colon
	jsr pv_ftype
	jsr calc_pindex
	lda num+2
	sta parms+2,x
	pla
	sta parms+3,x
	pla
	sta parms+1,x
	rts
;
; parse a file type -- xxx or 1-byte integer
;
ftyp_int:
	jsr pv_int
	lda num+1
	ora num+2
	beq ftyp_ok
	jmp overflow
ftyp_ok:
	lda num
	sta num+2
	jmp return_num

pv_ftype:
	jsr munch_space
	cmp #_'$'
	beq ftyp_int
	jsr chk_dig
	bcc ftyp_int
	jsr calc_pindex
	jsr pv_string
	ldy #0
	lda (strbuf),y
	cmp #3
	beq is3
	lda #der_needs3
	jmp ProDOS_err

is3:	jsr free_sbuff
	ldx #0	;index into filetyp
	lda #>fileasc
	ldy #<fileasc
	sta p2+1
	sty p2
	inc p
	bne :+
	inc p+1
:
chktyp1:
	ldy #2
chktyp2:
	lda (p),y
	jsr downcase
	sta temp
	lda (p2),y
	jsr downcase
	cmp temp
	bne chknextt
	dey
	bpl chktyp2
	lda filetyp,x
	sta num+2
	jmp return_num

chknextt:
	inx
	clc
	lda p2
	adc #3
	sta p2
	bcc @p2ok
	inc p2+1
@p2ok:	lda filetyp,x
	bne chktyp1

	ldx #0	;index into filetyp0
	lda #>fileasc0
	ldy #<fileasc0
	sta p2+1
	sty p2
chktyp1b:
	ldy #2
chktyp2b:
	lda (p),y
	jsr downcase
	sta temp
	lda (p2),y
	jsr downcase
	cmp temp
	bne chknextt2
	dey
	bpl chktyp2b
	lda filetyp0,x
	sta num+2
	jmp return_num

chknextt2:
	inx
	clc
	lda p2
	adc #3
	sta p2
	bcc p2ok2
	inc p2+1
p2ok2:	lda filetyp0,x
	bne chktyp1b

	lda #der_unknftyp
	jmp ProDOS_err
;
; parse a devnum value:   .sd
;
pv_devnum:
	jsr chrgot
	cmp #_'.'
	bne dvnerr
	jsr chrget
	cmp #_'1'
	bcc dvnerr
	cmp #_'8'
	bcs dvnerr
	and #%00001111
	asl a
	asl a
	asl a
	asl a
	sta temp
	jsr chrget
	cmp #_'1'
	bcc dvnerr
	cmp #_'3'
	bcs dvnerr
	and #%00000001
	ror a
	ror a
	eor #%10000000
	ora temp
	pha
	jsr calc_pindex
	pla
	sta parms+3,x
	jmp chrget
dvnerr:	lda #der_baddev
	jmp ProDOS_err

;
; getln -- print prefix and input a line of text
;
getln:
	lda #0
	jsr redirect
	asl a
	bmi cmd_again
	jsr print_pfx
	message_cstr ": "
cmd_again:
	jsr mygetln
	bcs cmd_again
	stx string-1
	cpx #0
	beq dont_keep
	lda #>(string-1)
	ldy #<(string-1)
	ldx #mli_write
	jsr HistoryMgr
dont_keep:
	ldx string-1
	rts
;
; print_pfx -- get prefix and print it
;
print_pfx:
	jsr get_pfx
	ldx string2-1
	beq :+
	dec string2-1
:	jmp print_path

;
; get_pfx
;
get_pfx:
	CALLOS mli_getpfx, get_pfx_parms
	CALLOS_BRANCH_NEG pfx_err
	jsr pmgr
	.byte pm_downcase
	.addr string2-1
	lda #>(string2-1)
	ldy #<(string2-1)
	rts

pfx_err:
	jmp ProDOS_err
;
; set_pfx
;
set_pfx:
	CALLOS mli_setpfx, set_pfx_parms
	CALLOS_BRANCH_NEG pfx_err
	rts

;
; print_p
;
print_p:
	ldy #0
pp1:	lda (p),y
	beq :+
	ora #$80
	jsr cout
	iny
	bne pp1
:	rts

;
; upcase
;
upcase:	ora #%10000000
	cmp #_'a'
	bcc uc_x
	cmp #_'z'+1
	bcs uc_x
	and #%11011111
uc_x:	rts

;
; downcase
;
downcase:
	ora #%10000000
	cmp #_'A'
	bcc :+
	cmp #_'Z'+1
	bcs :+
	ora #%00100000
:	rts

;***********************************************
;
; clear screen and print title
;
clear_sc:
.if IsDavex2
	lda #_'L'-ctrl
	jsr cout
	lda #0
	jsr redirect
	bmi nohome
.endif
	jsr home
nohome:	rts

;
; welcome
;
welcome:
	lda cfgquiet
	beq wNotQuiet
	cmp #2
	beq Quiet
	bit speech
	bmi Quiet
wNotQuiet:
	jsr pDavexVer

	jsr mess
	.byte cr
	cstr_cr "Type ? for help, $ for Freeware notice."
	jmp print_time

pDavexVer:
	message_cstr "Davex "
	lda #myversion
	jsr print_ver
	lda #AuxVersion+_'0'
	jsr cout
	jsr mess
.if  Proto 
	asc "p"
.endif
	cstr "  "
Quiet:	rts

;***********************************************
;
; shell_info --
;   X = request code
;   Exit: CLC if okay, info in registers
;
shell_info:
	txa
	bne shinf1
; shell_info(0) = version(AY)
	lda #myversion
	ldy #AuxVersion
	clc
	rts
shinf1:	dex
	bne shinf2
; shell_info(1) = alias buffer(AY=adr,X=pages)
	lda #>Aliases
	ldy #<Aliases
	ldx #3
	clc
	rts
shinf2:	dex
	bne shinf3
; shell_info(2) = history buffer(AY=adr,X=pages)
	lda #>History
	ldy #<History
	ldx #1
	clc
	rts
shinf3:	dex
	bne shinf4
; shell_info(3) = internal filetype table(AY)
	lda #>filetyp0
	ldy #<filetyp0
	clc
	rts
shinf4:	dex
	bne shinf5
; shell_info(4) = internal filetype name tbl(AY)
	lda #>fileasc0
	ldy #<fileasc0
	clc
	rts
shinf5:	sec
	rts


x99:		.byte 0		; [TODO] move to davex_io.asm (2 and 3), where it's used
exec_flag:	.byte 0
fudgeCR:	.byte 0

;**************************************
;
; Davex command table and commands
;
;**************************************
;
; command table format:
;  list of <command_entry>
;
; <command_entry> ::=
;   name   $00
;   cmd address
;   list of <positional_parm>
;   list of <optional_parm>
;
; <positional_parm> ::=
;   $00  (no option character)
;   <parm_type>
;
; <optional_parm> ::=
;   <option_character>
;   <parm_type>
;
;************************************
.macro	CommandName Arg
	asc_hi Arg
	.byte 0
.endmacro

.macro NoMoreParameters
	.byte $ff
.endmacro

;************************************
cmdtbl:
	CommandName "bye"
	.addr go_quit
	NoMoreParameters

	CommandName "$"
	.addr copyright
	NoMoreParameters

	CommandName "version"
	.addr wNotQuiet
	NoMoreParameters

	CommandName "rep"
	.addr go_repeat
	.byte 0,t_int2
	NoMoreParameters

	CommandName "config"
	.addr go_config
	.byte 'p',t_int1
	.byte '4',t_yesno
	.byte 'c',t_yesno
	.byte 'b',t_yesno
	.byte 'q',t_int1
	.byte 'h',t_string
	NoMoreParameters

	CommandName "como"
	.addr go_como
	.byte 0,t_wildpath
	NoMoreParameters

	CommandName "exec"
	.addr go_exec
	.byte 0,t_wildpath
	NoMoreParameters

	CommandName "prefix"
	.addr go_prefix
	.byte 0,t_wildpath
	NoMoreParameters

	CommandName "boot"
	.addr go_boot
	.byte 's',t_int1
	.byte 'i',t_nil	;ice cold!
	NoMoreParameters

	CommandName "mon"
	.addr go_mon
	NoMoreParameters

	CommandName "up"
	.addr go_up
	NoMoreParameters

	CommandName "top"
	.addr go_top
	NoMoreParameters

	CommandName "help"
	.addr go_help
	.byte 0,t_string
	NoMoreParameters

	CommandName "?"
	.addr go_help
	.byte 0,t_string
	NoMoreParameters

	CommandName "online"
	.addr go_online
	.byte 'o',t_nil
	NoMoreParameters

	CommandName "cls"
	.addr clear_sc
	NoMoreParameters

	CommandName "type"
	.addr go_type
	.byte 0,t_wildpath
	.byte 'h',t_nil
	.byte 'f',t_nil
	.byte 'u',t_nil
	.byte 'l',t_nil
	.byte 'p',t_nil
	.byte 't',t_string
	NoMoreParameters

	CommandName "pg"
	.addr go_more
	.byte 0,t_wildpath
	.byte 'h',t_nil
	.byte 'f',t_nil
	.byte 'u',t_nil
	.byte 'l',t_nil
	.byte 'p',t_nil
	.byte 't',t_string
	NoMoreParameters

	CommandName "rename"
	.addr go_rename
	.byte 0,t_wildpath
	.byte 0,t_path
	NoMoreParameters

	CommandName "filetype"
	.addr go_ctype
	.byte 0,t_wildpath
	.byte 0,t_ftype
	.byte 'x',t_int2
	NoMoreParameters

	CommandName "create"
	.addr go_create
	.byte 0,t_path
	NoMoreParameters

	CommandName "dt"
	.addr print_time
	NoMoreParameters

	CommandName "delete"
	.addr go_del
	.byte 0,t_wildpath
	.byte 'u',t_nil
	NoMoreParameters

	CommandName "lock"
	.addr go_lock
	.byte 0,t_wildpath
	NoMoreParameters

	CommandName "unlock"
	.addr go_unlock
	.byte 0,t_wildpath
	NoMoreParameters

	CommandName "prot"
	.addr go_prot
	.byte 0,t_wildpath
	.byte 'r',t_nil
	.byte 'w',t_nil
	.byte 'd',t_nil
	.byte 'n',t_nil
	NoMoreParameters

	CommandName "scan"
	.addr go_scan
	.byte 'a',t_string
	.byte 'r',t_string
	.byte 'z',t_nil
	.byte 'i',t_string
	NoMoreParameters

	CommandName "cat"
	.addr go_cat
	.byte 0,t_wildpath
	.byte 'a',t_string
	.byte 't',t_nil
	.byte 's',t_nil
	.byte 'f',t_ftype
	.byte 'i',t_nil
	NoMoreParameters

	CommandName "spool"
	.addr go_spool
	.byte 0,t_wildpath
;.byte 'h',t_string ;header
;.byte 'l',t_int1 ;lines/page
;.byte 'w',t_int1 ;page width
	.byte 'x',t_int1	;cancel 1
	.byte 'z',t_nil	;zap (cancel all)
	NoMoreParameters

	CommandName "info"
	.addr go_info
	.byte 0,t_wildpath
	NoMoreParameters

	CommandName "update"
	.addr go_update
	.byte 0,t_wildpath
	.byte 0,t_wildpath
	.byte 'f',t_nil
	.byte 'b',t_nil
	NoMoreParameters

	CommandName "copy"
	.addr go_copy
	.byte 0,t_wildpath
	.byte 0,t_wildpath
	.byte 'd',t_nil	;delete orig
	.byte 'f',t_nil	;force delete
	.byte 'b',t_nil	;clr bkup bit
	NoMoreParameters

	CommandName "move"
	.addr go_move
	.byte 0,t_wildpath
	.byte 0,t_wildpath
	.byte 'f',t_nil	;force delete
	NoMoreParameters

	CommandName "touch"
	.addr go_touch
	.byte 0,t_wildpath
	.byte 'b',t_yesno
	.byte 'd',t_yesno
	.byte 'i',t_yesno
	NoMoreParameters

.if IsDavex2
	CommandName "dev"
	.addr go_dev
	.byte 'r',t_devnum
	.byte 'a',t_devnum
	.byte 'z',t_nil
	NoMoreParameters
.endif

	CommandName "ftype"
	.addr go_ftype
	.byte 'r',t_ftype
	.byte 'a',t_string
	.byte 'v',t_ftype
	.byte 'z',t_nil
	NoMoreParameters

; [TODO] "appl" to associate applications with filetypes,
;	so you can launch something by document path and automatically have the right app
;	use the document
;;;;;
; CommandName "appl"
; .addr go_appl
; .byte 'r',t_ftype
; .byte 'a',t_ftype
; .byte 'p',t_string
; NoMoreParameters

	CommandName "err"
	.addr go_err
	.byte 0,t_int1
	NoMoreParameters

	CommandName "="
	.addr go_equal
	.byte 0,t_wildpath
	.byte 0,t_path
	NoMoreParameters

	CommandName "size"
	.addr go_size
	.byte 0,t_wildpath
	NoMoreParameters

	CommandName "echo"
	.addr go_echo
	.byte 0,t_string
	.byte 'n',t_nil	;no CR
	NoMoreParameters

	CommandName "eject"
	.addr go_eject
	.byte 0,t_path
	NoMoreParameters

	CommandName "wait"
	.addr go_wait
	NoMoreParameters

	CommandName "num"
	.addr go_num
	.byte 0,t_int3
	NoMoreParameters

 .if RemoteImp 
	CommandName "remote"
	.addr go_remote
	.byte 0,t_int1
	NoMoreParameters
 .endif

; end of command table
	.byte 0,0

;********************************************
notspool:
	bit spooling
	bmi ouchspool
	rts
ouchspool:
	lda #der_waitspool
	jmp ProDOS_err

;********************************************
go_num:	sta num+2
	stx num+1
	sty num
	message_cstr "  $"
	lda num+2
	jsr prbyte
	lda num+1
	jsr prbyte
	lda num
	jsr prbyte
	message_cstr " = "
	jsr prdec
	jmp crout

;********************************************
go_wait:
	bit spooling
	bpl :+
	jsr poll_io
	bit keyboard
	bpl go_wait
	sta kbdstrb
	jmp yn_abort
:	rts

;********************************************
s16_flag:
	.byte 0

go_quit:
.if IsDavex3
	lda #0
	SET_LEVEL
	jsr close
	clc		; [TODO] why?
.else
	clc
	ror s16_flag
	sta s16_name+1
	sty s16_name
	jsr notspool
	lda #0
	SET_LEVEL
	jsr close
	jsr off80
	lda #$ff
	ldy #$59
	sta $3fd
	sty $3fc

	lda reset+1
	sta reset+2
; quitting to S16?
	bit s16_flag
	bmi quit_s16
	jsr get_quitcode
.endif

os_quit:
	CALLOS mli_bye, bye_parms
	jmp ProDOS_err

.if IsDavex2
quit_s16:
	CALLOS mli_bye, quit2_parms
	jmp ProDOS_err

quit2_parms:
	.byte 4,$ee
s16_name:
	.addr 0
	.byte 0,0,0
.endif

;*********************************************
;
; boot [-s slot#] [-i]
;
;   -i = ice-cold boot (IIgs)
;
go_boot:
.if IsDavex2
	lda reset+1
	sta reset+2
; If IIgs, do what the ProDOS-16 PQUIT thinger does
; on 'Reboot system'
	sec
	jsr idroutine	;CLC on IIgs
	bcs rb_NotGS
	sei
	lda #0
.P816
	sta $E0C035	; Shadow register
.P02
	sta $c047	;clear VBL/3_75Hz int flags
	sta $c041	;disable lots of ints
	lda #9
	sta $c039	;SCC channel A cmd reg
	lda #$c0
	sta $c039
; if -i, trash $5f in the Keyboard Micro's RAM
	lda #_'i'
	jsr getparm_ch
	bcs no_ice
	jsr ice_it
no_ice:
rb_NotGS:

	jsr off80
	jsr home
	start_normal
	lda #_'i'	;
	jsr getparm_ch	;
	bcc badslot	;
	lda #_'s'
	jsr getparm_ch
	bcc boot_slot
badslot:
	jmp ($fffc)

boot_slot:
	lda #0
	sta p
	tya
	beq badslot
	cmp #7+1
	bcs badslot
	ora #$C0
	sta p+1
	jmp (p)

;
; ice_it: (OpenApple V3#6, p3_48)
;
.P816
ice_it:
	clc
	XCE
	rep #$30
.A16
.I16
	lda #$0051
	sta $0000
	pea $0002	; send 2 bytes
	pea $0000
	pea $0000
	pea $0008	; write Key Micro RAM
	ldx #$0909	; send to ADB
	jsl $e10000	; Stores $00 into $51 (Key Micro RAM)
	sec
	XCE
	rts
.P02
.else ; IsDavex3
	lda #$53	; Switch in ROM#1, I/O, disable reset switch
	sta e_reg	; Set the environment register
	jmp boot	; Jump to boot code in ROM
.endif
;
; handle an NMI
;
NMIouch:
	sec
	bcs mon2
;
; enter monitor
;
go_mon:
.if IsDavex2
	jsr notspool
	clc
mon2:	php
	jsr off80
	jsr home
	start_normal
	plp
	bcc no_nmi
	message_cstr_cr "Ouch!"
no_nmi:	jmp monitor

.else ; IsDavex3

mon2:	lda #columns40
	sta INIT_SCREEN_COLUMNS
	jsr set_columns
	jsr home
	jmp monitor
.endif

;
; prefix <path>
;
go_prefix:
setthepfx:
	sta pfxstradr+1
	sty pfxstradr
.if IsDavex3
				; SOS won't change directory to a relative path.
				; So, if a request is made without a leading slash,
				; prefix it with the current directory.
	sty p
	sta p+1
	ldy #$01
	lda (p),y		; Check out the first character
	cmp #'/'			; Is it a slash?
	beq set_prefix_literal	; Yes - then just set the request literally
	jsr get_pfx		; Otherwise, get current prefix - AY points to string2
	jsr xpmgr
	.byte pm_slashif		; Append a trailing slash, if needed
	.addr string2-1

	lda pfxstradr+1
	ldy pfxstradr
	jsr xpmgr
	.byte pm_appay		; Append the requested prefix string at ay to string2
	.addr string2-1

	ldy #<(string2-1)
	sty pfxstradr
	lda #>(string2-1)
	sta pfxstradr+1		; Point the set prefix call at the concatenated string
set_prefix_literal:

.endif ; IsDavex3
	CALLOS mli_setpfx, pfxcmdparms
	CALLOS_BRANCH_POS set_ok
	jmp ProDOS_err
set_ok:	rts

pfxcmdparms:
	.byte 1
pfxstradr:
	.res 2

;
; up -- leave a subdirectory
;
go_up:	jsr get_pfx
	jsr pmgr
	.byte pm_up
	.addr string2-1
	jmp set_pfx

;
; top
;
go_top:	jsr get_pfx
	ldx string2-1
	beq topped
	ldy #0		;# slashes
countSlashes:
	lda string2-1,x
	ora #$80
	cmp #_'/'
	bne cs_not
	iny
cs_not:	dex
	bne countSlashes
	cpy #3
	bcc topped
	jsr go_up
	jmp go_top
topped:	rts

;*********************************************
;
; 'type' command -- show contents of a file (without pausing like 'pg' and 'more')
;
case_flags:	.res 1
pause_flag:	.res 1
line_count:	.res 1
saved_tchr:	.res 1

go_type:
	clc
type_pg:
	ror pause_flag

	lda #'f'
	jsr getparm_ch
	ror a
	sta filter

	lda #'l'
	jsr getparm_ch
	ror case_flags
	lda #'u'
	jsr getparm_ch
	ror case_flags

	lda #0
	jsr getparm_n
more2:	pha
	tya
	pha
; don't prompt if output redirected
	lda #0
	jsr redirect
	bpl :+
	lsr pause_flag
:	pla
	tay
	pla
	jsr fman_open
	bcc typeopened
type_err:
	jmp ProDOS_err
typeopened:
	sta type_readref
	sta tyeofr
	CALLOS mli_geteof, tyeof
	CALLOS_BRANCH_NEG type_err

	lda #23
	sta line_count
;
; print header if -h given
;
	lda #'h'
	jsr getparm_ch
	bcs no_head
	message_cstr "******* "
	lda p+1
	ldy p
	jsr print_path
	message_cstr "--modified "
	lda p+1
	ldy p
	jsr getinfo
	lda info_moddat+1
	ldy info_moddat
	jsr pr_date_ay
	lda info_modtim+1
	ldy info_modtim
	jsr pr_time_ay
	jsr mess
	asc " *******"
	.byte cr,cr,0
	dec line_count
	dec line_count
no_head:

	lda scr_width
	sta temp
type_1:	jsr poll_io
	lda type_readref
	jsr fman_read
	bcc treadok
	cmp #err_eof
	bne typerr9
	jmp type_finish
typerr9:
	jmp ProDOS_err
treadok:
	ora #%10000000
	sta saved_tchr
	cmp #_'M'-ctrl
	bne not_typeret
typeret:
	ldx scr_width
	inx
	stx temp
	jsr check_wait
	bcc type_chk1
	jmp type_finish
type_chk1:
	lda saved_tchr
	dec line_count
	bne print_char
	lda #23
	sta line_count
	lda saved_tchr
	bit pause_flag
	bpl print_char
	jsr suspend
	jsr TalkCont
	jsr mess
	.byte cr
	cstr "--- "
	jsr type_percent
	jsr prdec_1
	message_cstr "% --- more"
	lda #_'y'	;default = Yes
	jsr yesno2
	jsr restore
	beq type_finish
	lda saved_tchr
	jmp print_char

not_typeret:
	cmp #$89
	bne not_TAB
	lda #'t'
	jsr getparm_ch
	bcs not_TAB0
	jsr print_path
	jmp type_1

not_TAB0:
	lda #$89
not_TAB:
	bit filter
	bpl print_char
	cmp #$a0
	bcs print_char
	jmp type_1
print_char:
.if IsDavex3
	cmp #$8d
	bne :+
	lda #$0d
:
.endif
	dec temp
	beq typeret
	bit case_flags
	bmi t_no_up
	jsr upcase
t_no_up:
	bit case_flags
	bvs t_no_down
	jsr downcase
t_no_down:
	jsr cout
	jmp type_1


type_finish:
	lda #'p'
	jsr getparm_ch
	bcs type_done
	jsr clear_sc
type_done:
	lda type_readref
	jsr close
	rts

type_percent:
	lda tyeofr
	sta tymarkr
	CALLOS mli_getmark, tymark
	lda tymarkval+2
	ldx tymarkval+1
	ldy tymarkval
	sta num+2
	stx num+1
	sty num
	lda tyeofval+2
	ldx tyeofval+1
	ldy tyeofval
	jmp percent

tymark:		.byte 2
tymarkr:	.res 1
  .if IsDavex3
tymarkval:	.res 4	; SOS has a four-byte tymarkval result.
  .else
tymarkval:	.res 3
  .endif

tyeof:		.byte 2
tyeofr:		.res 1
tyeofval:
.if IsDavex3
		.res 4	; SOS has a four-byte result
.else
		.res 3
.endif

type_readref:	.res 1
filter:		.res 1

;
; pg and more commands -- show contents of file;
; pause between pages
;
go_more:
	sec
	jmp type_pg

;****************************************************
;
; rename command:  rename <path1> <path2>
;
go_rename:
	sta rename_1+1
	sty rename_1
	lda #1
	jsr getparm_n
	sta rename_2+1
	sty rename_2
	CALLOS mli_rename, rename_parms
	CALLOS_BRANCH_NEG rename_err
	rts
rename_err:
	jmp ProDOS_err

rename_parms:	.byte 2
rename_1:	.res 2
rename_2:	.res 2

;
; ctype command: ctype <path1> <type> (-x auxtype)
;
; Change filetype.
;
ctype_typ:	.res 1

go_ctype:
	sta p+1
	sty p
	jsr getinfo
	lda #1
	jsr getparm_n
	sta info_type
; if -x given, change aux type
	lda #'x'
	jsr getparm_ch
	bcs same_aux
	stx info_auxtype+1
	sty info_auxtype
same_aux:
	lda p+1
	ldy p
	jmp setinfo

;****************************************
;
; create <path>[:type]
;
go_create:
	sta cr_path+1
	sty cr_path
	cpx #0
	bne :+
	ldx #tDIR
:	stx cr_type
	ldy #1		;storage type for seedling
	cpx #tDIR
	bne cr_seed
	ldy #$d		;storage type for directory
cr_seed:
	sty cr_stype
	CALLOS mli_create, cr_parms
	CALLOS_BRANCH_NEG cr_err
	rts

cr_err:	jmp ProDOS_err

;
; unlock
;
go_unlock:
	lda #%11111111	;AND mask
	ldy #%11000011	;OR mask: RWND
	bne protect
;
; lock
;
go_lock:
	lda #%00111100	;AND mask
	ldy #%00000001	;OR mask: R
	bne protect

protect:
	sta and_mask
	sty or_mask
; get file access
	lda #0
	jsr getparm_n
	sta p+1
	sty p
	jsr getinfo
	lda info_acc
	and and_mask
	ora or_mask
	sta info_acc
	lda p+1
	ldy p
	jmp setinfo

;*******************************************
;
; prot <path> -r -w -n -d
;
go_prot:
	lda #%00000000
	pha
	lda #'r'
	jsr getparm_ch
	bcs protp1
	pla
	ora #%00000001	;R
	pha
protp1:	lda #'w'
	jsr getparm_ch
	bcs protp2
	pla
	ora #%00000010	;W
	pha
protp2:	lda #'n'
	jsr getparm_ch
	bcs protp3
	pla
	ora #%01000000	;N
	pha
protp3:	lda #'d'
	jsr getparm_ch
	bcs protp4
	pla
	ora #%10000000
	pha
protp4:	pla
	tay
	lda #%00111100	;AND: clear RWND
	jmp protect

;***************************************************
;
; scan [-a add_path] [-r remove_path]
;      [-z defaults] [-i insert]
;
; [TODO] implement -i as some way to add other than at the end
;
go_scan:
	lda num_parms
	bne scan_parms
; show list of cmd directories
	lda scanlist
	bne somedirs
	message_cstr_cr "no command dirs"
	rts

somedirs:
	message_cstr_cr "command dirs:"
	ldx #0
scan_show1:
	lda scanlist,x
	beq scan_shown
	stx temp
	message_cstr "  "
	ldx temp
	lda scanlist,x	;length
	tay
scanshowch:
	inx
	lda scanlist,x
	ora #%10000000
	jsr cout
	dey
	bne scanshowch
	inx
	stx temp
	jsr crout
	jmp scan_show1
scan_shown:
	rts

; Default scan-path entries
scan_dflt:
	pstr "%"
	pstr "*"
	.byte 0

scan_zap:
	ldy #<-1
scanz1:	iny
	lda scan_dflt,y
	sta scanlist,y
	bne scanz1
	jmp makedirt

scan_parms:
	lda #'z'
	jsr getparm_ch
	bcs @notz
	jsr scan_zap
@notz:	lda #'r'
	jsr getparm_ch
	bcs @notrem
	jsr findscan_x
	bcc :+
	lda #der_notfnd
	jmp ProDOS_err
:	txa
	sec
	adc scanlist,x
	tay
@squish:
	lda scanlist,y
	sta scanlist,x
	inx
	iny
	bpl @squish

@notrem:
	lda #'a'
	jsr getparm_ch
	bcs scan_notadd
	jsr findscan_x
	bcc scan_notadd
	ldy #0
	lda (p),y
	sta count
;;;	sec
	txa
	adc count
	bpl scan_fits

	lda #der_outroom
	jmp ProDOS_err

scan_fits:
scappend:
	lda (p),y
	sta scanlist,x
	iny
	inx
	dec count
	bpl scappend
	lda #0
	sta scanlist,x

scan_notadd:
	sec
	ror config_dirty
	rts

count:	.res 1

findscan_x:
	sta p+1
	sty p
	ldy #0
	lda (p),y
	cmp #1
	beq noslash
	tay
	lda (p),y
	cmp #$2f
	beq noslash	;don't add one
	iny
	tya
	lda #$2f
	sta (p),y
	tya
	ldy #0
	sta (p),y	;update len
noslash:
	ldx #0
fsx1:	stx temp
	ldy #0
	lda (p),y	;length of target
	cmp scanlist,x	;same lengths?
	bne fsxnext
	sta count
fsxcomp:
	iny
	inx
	lda (p),y
	jsr downcase
	sta scchar
	lda scanlist,x
	jsr downcase
	cmp scchar
	bne fsxnext
	dec count
	bne fsxcomp
	clc
	ldx temp
	rts

scchar:	.byte 0

fsxnext:
	ldx temp
	lda scanlist,x
	beq scanx
	txa
	sec
	adc scanlist,x
	tax
	lda scanlist,x
	bne fsx1
scanx:	sec		;not found
	rts

;**************************************************
;
; info <path> -- print info on file & volume
;
go_info:
	jsr empty_prefix
	sta p+1
	sty p
	sta info_path+1
	sty info_path
	jsr getinfo
; devnum may change if output redirected
	lda devnum
	pha
	jsr mess
	.byte cr
	cstr "name:      "
	lda #0
	jsr getparm_n
	jsr empty_prefix
	jsr prnt_compl
	message_cstr "   "
	pla		;get devnum
	jsr print_sd
	jsr mess
	.byte cr
	cstr "strg type: "
	lda info_stype
	jsr print_stype
	jsr mess
	.byte cr
	cstr "type:      "
	lda info_type
	jsr print_ftype
	jsr mess
	cstr "        access: "
	lda info_acc
	jsr print_access
	jsr mess
	.byte cr
	cstr "aux type:  "
	lda info_auxtype+1
	ldy info_auxtype
	jsr prdec_2
	jsr mess
	cstr "  ($"
	lda info_auxtype+1
	jsr prbyte
	lda info_auxtype
	jsr prbyte
	jsr mess
	.byte ')',cr
	cstr "blocks:    "
	lda info_blocks+1
	ldy info_blocks
	jsr prdec_2
	jsr crout

	lda info_crdat+1
	ora info_crdat
	ora info_crtim+1
	ora info_crtim
	beq info_nullcr
	jsr mess
	cstr "created:   "
	lda info_crdat+1
	ldy info_crdat
	jsr pr_date_ay
	lda info_crtim+1
	ldy info_crtim
	jsr pr_time_ay
	jsr crout
info_nullcr:
	lda info_moddat+1
	ora info_moddat
	ora info_modtim+1
	ora info_modtim
	beq info_nullmod
	message_cstr "modified:  "
	lda info_moddat+1
	ldy info_moddat
	jsr pr_date_ay
	lda info_modtim+1
	ldy info_modtim
	jsr pr_time_ay
	jsr crout
info_nullmod:
info_nbin:
	rts

startup_size:
	sta info_path+1
	sty info_path
	lda #0
	tay
zrpgbf:	sta pagebuff,y
	dey
	bne zrpgbf	;in case file is short!
	CALLOS mli_open, info_op
	CALLOS_BRANCH_NEG info_err
zrpgbfOK:
	lda inforef
	sta inforef2
	CALLOS mli_read, info_rd
; a short read is not an error (no CALLOS_BRANCH_NEG info_err)
	lda inforef
	jsr close
	lda pagebuff
	cmp #$4c
	bne cbuf0
	lda #$ee
	cmp pagebuff+3
	bne cbuf0
	cmp pagebuff+4
	bne cbuf0
	lda pagebuff+5
	rts
cbuf0:	lda #0
	rts

info_err:
	jmp ProDOS_err

info_rd:	.byte 4
inforef2:	.res 1
		.addr pagebuff
		.addr 256
		.addr 0

print_stype:
	cmp #1
	beq st_seed
	cmp #2
	beq st_sap
	cmp #3
	beq st_tree
	cmp #4
	beq st_pasc
	cmp #5
	beq st_extended
	cmp #$D
	beq stp_dir
	cmp #$F
	beq st_vol
	jmp prdec_1
st_seed:
	message_cstr "seedling"
	rts
st_sap:	message_cstr "sapling"
	rts
st_tree:
	message_cstr "tree"
	rts
st_pasc:
	message_cstr "pascal area"
	rts
st_extended:
	message_cstr "extended"
	rts
stp_dir:
	message_cstr "subdirectory"
	rts
st_vol:	message_cstr "volume"
	rts

;
; repeat <int2>
;
go_repeat:
	stx rep_count+1
	sty rep_count
	tya
	ora rep_count+1
	beq rc_eq0
	cpy #0
	bne nodecrc1
	dec rep_count+1
nodecrc1:
	dec rep_count
rc_eq0:
	pla
	pla		; pop RTS address
	jmp repeated	; must cheat instead of returning normally

; [TODO] What was the 'remote' command going to do, if ever implemented? Control Davex from a serial card?
 .if  RemoteImp 
go_remote:
	cpy #1
	bcc remote0
	cpy #7+1
	bcs badrem
	sty remslot
; %%% only if not exec?!
	jsr finish_iredir
	rts
badrem:	lda #der_badnum
	jmp ProDOS_err
remote0:
	sty remslot
; %%% ?
	jsr finish_iredir
	jsr finish_oredir
	rts
 .endif


;*************************************************
;************************************************
;
; cmds2 -- lots more Davex commands
;
;************************************************
indent_level:	.byte 0
cat_ftype:	.byte 0
cat_devnum:	.byte 0
;
show_invis:
	.byte 0

;
; go_cat -- Catalog command
;
go_cat:	lda #0
	sta indent_level
	sta cat_ftype
	lda #'i'
	jsr getparm_ch
	ror a
	eor #$80
	sta show_invis
	lda #'f'
	jsr getparm_ch
	bcs c_noftp
	sta cat_ftype
c_noftp:
	lda #0
	jsr getparm_n
	jsr empty_prefix
	sta ptr+1
	sty ptr
	jsr getinfo
	lda devnum
	sta cat_devnum
	lda info_type
.if IsDavex3
	cmp #$00
	bne c_cmp_tdir
	lda #tDIR
.endif
c_cmp_tdir:
	cmp #tDIR
	beq cat_isdir
	lda #der_notdir
	jmp ProDOS_err
cat_isdir:
	lda #'a'	;arrange
	jsr getparm_ch
	bcs cat_unsort
	sta sort_str+1
	sty sort_str
	jmp cat_sorted
cat_unsort:
	jsr push_level
	lda ptr+1
	ldy ptr
	jsr dir_setup
	jsr crout
	jsr cat_header
dir_1:	jsr read1dir_vis
	bcs dir_x
	jsr print1dir
	bcs dir_xx
	lda catbuff+16	;type
	cmp #tDIR
	bne cat_xnest
	lda #'t'
	jsr getparm_ch
	bcs cat_xnest
	jsr push_level
	lda catbuff
	and #%00001111
	sta catbuff
	lda #>catbuff
	ldy #<catbuff
;
; use dir_setup2 to allow a partial path that is relative
; to the previous directory level; standard dir_setup
; paths must be relative to the PREFIX (or be complete)
;
	jsr dir_setup2
	bcc nest_ok
	pha
	ldx indent_level
	inx
	inx
	jsr indent_x
	pla
	jsr ProDOS_er2
	jsr dir_finish
	jmp nest_fail
nest_ok:
	inc indent_level
	inc indent_level
	bit speech
	bpl cat_xnest
	message_cstr_cr ">"
nest_fail:
cat_xnest:
	jmp dir_1
dir_x:	bit speech
	bpl dirdec
	lda indent_level
	beq dirdec
	message_cstr_cr "<"
dirdec:	dec indent_level
	dec indent_level
	jsr dir_finish
	lda indent_level
	bpl dir_1
	jmp cat_trailer
dir_xx:	jsr dir_finish
	dec indent_level
	dec indent_level
	bpl dir_xx
	rts
;
; -arrange the dir listing
;
cat_sorted:
	jsr push_level
	lda ptr+1
	ldy ptr
	jsr dir_setup
	jsr crout
	jsr cat_header
	lda #0
	sta keep_count+1
	sta keep_count
	jsr keep_init
catsrt1:
	jsr read1dir_vis
	bcs catsrt2
	jsr keep1dir
	jmp catsrt1
catsrt2:
	jsr dir_finish
	jsr sortdir
	jsr keep_init
catsrt3:
	jsr get1kept
	bcs catsrt_x
	jsr print1dir
	bcc catsrt3
catsrt_x:
	jmp cat_trailer

keep_count:
	.addr 0

;
; sort directory entries (length = entrylen) at
; 'keepbuff'.  There are keep_count(2 by) files
;
swapped:	.byte 0
srt_count:	.byte 0

sortdir:
	ldy #0	;if sort_str is empty, sort by name
	lda (sort_str),y
	bne sort_given
	lda #1
	sta (sort_str),y
	iny
	lda #_'n'
	sta (sort_str),y
sort_given:
	lda keep_count+1
	bne dont_srt
	lda keep_count
	pha
nextpass:
	lda #0
	sta swapped
	jsr sort1pass
	dec keep_count
	lda swapped
	bne nextpass
	pla
	sta keep_count
dont_srt:
	rts

sort1pass:
	lda keep_count
	sta srt_count
	beq sort_x
	lda #>keepbuff
	ldy #<keepbuff
sort1swap:
	sta p+1
	sty p
	dec srt_count
	beq sort_x
	clc
	lda p
	adc EntryLen
	sta p2
	lda p+1
	adc #0
	sta p2+1
	jsr cond_swap
	clc
	lda p
	adc EntryLen
	tay
	lda p+1
	adc #0
	jmp sort1swap
sort_x:	rts

sortstr_i:
	.byte 0	;index into sort string

cond_swap:
	ldy #0
	sty sortstr_i
cond1:	lda sortstr_i
	ldy #0
	inc sortstr_i
	cmp (sort_str),y
	bcs sortdun
	tay
	iny
	lda (sort_str),y
	ora #%10000000
	sta sort_char
	jsr downcase
	jsr doCmp
	beq cond1
	php
	lda sort_char
	cmp #_'a'
	bcc revSort
	plp
	bcs need2swap
	rts
revSort:
	plp
	bcc need2swap
sortdun:
	rts
need2swap:
	jmp swap_two

doCmp:	cmp #_'n'
	beq cmpNAME
	cmp #_'b'
	beq cmpBACKUP
	cmp #_'f'
	beq cmpTYPE
	cmp #_'t'
	beq cmpTYPE
	cmp #_'d'
	beq cmpModDATE
	cmp #_'m'
	beq cmpModDATE
	cmp #_'x'
	beq cmpAUX
	cmp #_'s'
	beq cmpSIZE
	cmp #_'c'
	beq cmpCrDATE
	lda #der_illegparm
	jmp ProDOS_err

cmpNAME:
	ldy #0
cmpNam:	iny
	cpy #16
	beq NamEq
	lda (p2),y
	jsr downcase
	sta temp
	lda (p),y
	jsr downcase
	cmp temp
	beq cmpNam
NamEq:	rts

cmpSIZE:
	ldy #$17
	lda (p2),y
	cmp (p),y
	bne cmpSZx
	dey
	lda (p2),y
	cmp (p),y
	bne cmpSZx
	dey
	lda (p2),y
	cmp (p),y
cmpSZx:	rts

cmpAUX:	ldy #$20
	lda (p),y
	cmp (p2),y
	bne cmpAUXx
	dey
	lda (p),y
	cmp (p2),y
cmpAUXx:
	rts

cmpBACKUP:
	ldy #$1e
	lda (p),y
	and #%00100000
	sta temp
	lda (p2),y
	and #%00100000
	cmp temp
	rts

cmpTYPE:
	ldy #16
	lda (p),y
	cmp (p2),y
	rts

cmpCrDATE:
	ldy #$18+1
	bne cmpDate
cmpModDATE:
	ldy #$21+1

cmpDate:
 .if 1 
;
; Y2K-happy date-compare:
;
; Input = 4-byte date/time records at (p),y and (p2),y
;         with Y pointing at the 2nd byte
;
; Output = BEQ/BCS/BCC for P2 compared to P
;
	lda (p),y
	jsr ExtractAndNormalizeYear
	sta tempDate
	lda (p2),y
	jsr ExtractAndNormalizeYear
	cmp tempDate
	bne cmpDATEx

	lda (p),y	;compare high bit of months
	and #1
	sta tempDate
	lda (p2),y
	and #1
	cmp tempDate
	bne cmpDATEx

	dey
	lda (p2),y
	cmp (p),y
	bne cmpDATEx
 .else
	lda (p2),y
	cmp (p),y
	bne cmpDATEx
	dey
	lda (p2),y
	cmp (p),y
	bne cmpDATEx
 .endif
	iny
	iny
	iny	;now pointing at the last byte
	lda (p2),y
	cmp (p),y
	bne cmpDATEx
	dey
	lda (p2),y
	cmp (p),y
cmpDATEx:
	rts


swap_two:
	ldy EntryLen
	dey
swap22:	lda (p),y
	pha
	lda (p2),y
	sta (p),y
	pla
	sta (p2),y
	dey
	bpl swap22
	sec
	ror swapped
	rts

;
; keep_init and keep1dir
;
keep_init:
	lda #>keepbuff
	ldy #<keepbuff
	sta keep+1
	sty keep
	rts

keep1dir:
	inc keep_count
	bne scok
	inc keep_count+1
scok:	ldy EntryLen
k1d:	dey
	bmi :+
	lda catbuff,y
	sta (keep),y
	jmp k1d
:	jmp nextkeep

get1kept:
	lda keep_count+1
	ora keep_count
	bne :+
	sec
	rts
:	lda keep_count
	bne :+
	dec keep_count+1
:	dec keep_count
	ldy EntryLen
g1k:	dey
	bmi g1kx
	lda (keep),y
	sta catbuff,y
	jmp g1k
g1kx:

nextkeep:
	clc
	lda keep
	adc EntryLen
	sta keep
	lda keep+1
	adc #0
	sta keep+1
	cmp #$AF
	bcc nkok
	lda #der_outroom
	jmp ProDOS_err
nkok:	rts	;clc

;************************************************
read1dir_vis:
	jsr read1dir
	bcs :+
	bit show_invis
	bmi :+
	lda catbuff+$1E	;access
	and #%00000100
	bne read1dir_vis
	clc
:	rts

;************************************************
cat_header:
	lda ptr+1
	ldy ptr
	jsr prnt_compl
	message_cstr "      "
	lda file_count+1
	ldy file_count
	jsr prdec_2
	message_cstr " file"
	lda file_count+1
	ldy file_count
	jsr plural
	jsr crout
	jsr crout
	message_cstr "name                       type"
	lda #'s'
	jsr getparm_ch
	bcc catshort1
	message_cstr "        blocks   modified               access"
catshort1:
	bit speech
	bmi catshort2
	jsr mess
	.byte cr
	cstr "----                       ----"
	lda #'s'
	jsr getparm_ch
	bcc catshort2
	message_cstr "------  ------   --------               ------"
catshort2:
	jmp crout

cat_trailer:
	lda #'s'
	jsr getparm_ch
	bcs catlong2
	rts
catlong2:
	jsr get_vol_info
	jsr crout
	message_cstr "blocks free: "
	sec
	lda info_auxtype
	sbc info_blocks
	tay
	lda info_auxtype+1
	sbc info_blocks+1
	jsr prdec_2
	message_cstr "    used: "
	lda info_blocks+1
	ldy info_blocks
	jsr prdec_2
	jsr show_percent
	message_cstr "     total: "
	lda info_auxtype+1
	ldy info_auxtype
	jsr prdec_2
	jmp crout

get_vol_info:
	lda cat_devnum
.if IsDavex2
	sta online_dev
	CALLOS mli_online, online_parm
	CALLOS_BRANCH_POS von_ok
	jmp ProDOS_err
.else
	lda #$00		; Clear out A & Y to ask for the real empty prefix 
	tay
	jsr empty_prefix
	sta ginfopth+1
	sty ginfopth
	jmp getinfo
.endif
von_ok:	lda catbuff
	and #%00001111
	tax
	inx
	stx catbuff-1
	lda #_'/'
	sta catbuff
	lda #>(catbuff-1)
	ldy #<(catbuff-1)
	jmp getinfo
;
; print this entry if:
;   no -f type was given     OR
;   the type matches the -f type   OR
;   it's a DIR and -t was given
;
print1dir:
	lda cat_ftype
	beq dothis2
	cmp catbuff+16
	beq dothis2
	lda catbuff+16
	cmp #tDIR
	bne notthis2
	lda #'t'
	jsr getparm_ch
	bcc dothis2
notthis2:
	clc
	rts
dothis2:
	ldx indent_level
	jsr indent_x
	lda catbuff
	and #%00001111
	tax
	ldy #1
prcat1:	lda catbuff,y
	ora #%10000000
; asl case_mask+1
; rol case_mask
; bcc no_dcase
; jsr downcase
;no_dcase
	jsr cout
	iny
	dex
	bne prcat1

	clc
	tya
	adc indent_level
	tay
tabType:
	cpy #18+10
	bcs tabbedType
	jsr pr_sp
	iny
	bne tabType
tabbedType:
	ldx #_' '
	lda catbuff
	and #$f0
	cmp #$50
	bne not_xtnd
	ldx #_'+'
not_xtnd:
	txa
	jsr cout
	lda catbuff+16
	jsr print_ftype
; short form -s?
	lda #'s'
	jsr getparm_ch
	bcs longcat
	jsr crout
	jmp check_wait
longcat:
; print ' $xxxx' (auxtype)
	message_cstr " $"
	lda catbuff+$20
	jsr prbyte
	lda catbuff+$1f
	jsr prbyte
; print a comma for Speech users
	jsr speech_comma
; blocks
	lda catbuff+$14
	ldy catbuff+$13
	ldx #0
	stx num+2
	sta num+1
	sty num
	jsr prdec_pad

	lda #_' '
	bit speech
	bpl store_char
	lda #_','
store_char:
	sta spComma

	jsr mess
spComma: cstr "   "	; first char MODIFIED above
	lda catbuff+$22
	ldy catbuff+$21
	jsr pr_date_ay

	jsr pr_sp
	lda catbuff+$24
	ldy catbuff+$23
	jsr pr_time_ay

	message_cstr "   "
	lda catbuff+$1E
	jsr print_access
	jsr crout
	jmp check_wait

;
; Calculate mask of uppercase/lowercase letters in the filename.
;
; Three filetypes use their auxtype to store this information:
;	19 ADB   UprLwr    AppleWorks Database
;	1A AWP   UprLwr    AppleWorks Word Processing
;	1B ASP   UprLwr    AppleWorks Spreadsheet
;
; But in general, the ProDOS FST stores it in two other bytes.
;
calc_cmask:
	ldx catbuff+16	;type
	cpx #$19	; < ADB ?
	bcc cm_ProFST
	cpx #$1B+1	; >= ASP+1 ?
	bcs cm_ProFST
	lda catbuff+$20
	ldy catbuff+$1f
cm_store:
	sta case_mask+1
	sty case_mask
	rts

; check for ProDOS FST lowercase bits
cm_ProFST:
	lda catbuff+$1d
	bpl no_case
	lda catbuff+$1c
	asl a
	rol catbuff+$1d
	ldy catbuff+$1d
	jmp cm_store
no_case:
	lda #$ff
	tay
	bne cm_store

case_mask:
	.res 2

indent_x:
	beq @exit
:	jsr pr_sp
	dex
	bne :-
@exit:	rts

;************************************************
;************************************************
;
; ftype [-r<type>] [-a<string> -v<ftype>] [-z]
;
go_ftype:
	lda num_parms
	bne ftype_p
; display all filetype names
	lda #7
	ldx scr_width
	cpx #80
	bcs :+
	lsr a
:	sta ftyp_mask

	clc
	jsr displayFTs
	jsr crout
	sec
displayFTs:
	ror ftInternal
	ldx #0
	ldy #0
ftype1:
	lda filetyp,x
	bit ftInternal
	bpl ftExt1
	lda filetyp0,x
ftExt1:	cmp #0
	beq ftypex
	pha
	jsr pr_sp
	jsr oneFTchar
	jsr oneFTchar
	jsr oneFTchar
	lda #_'='
	jsr cout
	lda #_'$'
	jsr cout
	pla
	jsr prbyte
	jsr pr_sp
	inx
	txa
	and ftyp_mask
	bne ftype1
	jsr crout
	jmp ftype1
ftypex:	jmp crout

ftyp_mask:	.byte 0
ftInternal:	.byte 0

oneFTchar:
	lda fileasc,y
	bit ftInternal
	bpl oneFTch
	lda fileasc0,y
oneFTch:
	iny
	ora #%10000000
	jmp cout

ftype_p:
	lda #'z'
	jsr getparm_ch
	bcs no_zapft
	lda #0
	sta filetyp
	jsr makedirt
no_zapft:

	lda #'r'
	jsr getparm_ch
	bcs ftype_add
; remove type A
	sta temp
	ldx #0
ftr1:	lda filetyp,x
	beq ftr_nf
	cmp temp
	beq ftr_f
	inx
	cpx #63
	bcc ftr1
ftr_nf:	lda #der_notfnd
	jmp ProDOS_err
ftr_f:	txa
	sta temp
	asl a
	adc temp
	tay
ftr_f1:	lda filetyp+1,x
	sta filetyp,x
	lda fileasc+5,y
	sta fileasc+2,y
	lda fileasc+4,y
	sta fileasc+1,y
	lda fileasc+3,y
	sta fileasc,y
	iny
	iny
	iny
	inx
	cpx #63
	bcc ftr_f1
	jsr makedirt

ftype_add:
	lda #'a'
	jsr getparm_ch
	bcs ftype_x
	sta p2+1
	sty p2
	ldy #0
	lda (p2),y
	cmp #3
	beq fta3
	lda #der_needs3
der2:	jmp ProDOS_err
fta3:	lda #'v'
	jsr getparm_ch
	bcc fta4
	lda #der_missopt
	bne der2
fta4:	sta temp
	ldx #0
fta1:	lda filetyp,x
	beq fta_f
	inx
	cpx #63
	bcc fta1
	lda #der_outroom
	bne der2
fta_f:	lda temp
	sta filetyp,x
	lda #0
	sta filetyp+1,x
	stx temp
	txa
	asl a
	adc temp
	tax
	inx
	inx
	ldy #3
ftacopy:
	lda (p2),y
	sta fileasc,x
	dex
	dey
	bne ftacopy
	jsr makedirt
ftype_x:
	rts

;************************************************
;
; err <int> -- print xProDOS error
;
go_err:	tya
	beq all_errs
	jmp ProDOS_er
all_errs:
	lda #0
next_err:
	pha
	ldy #3
	sta num
	lda #0
	sta num+1
	sta num+2
	jsr prdec_pady
	message_cstr ": "
	pla
	pha
	jsr ProDOS_er2
	jsr check_wait
	pla
	bcs :+
;;;	clc
	adc #1
	bcc next_err
:	rts

;************************************************
;
; '=' -- print a pathname
;
go_equal:
	nop	;disables wildcard expansion echo
	sta p2+1
	sty p2
	lda #1
	jsr getparm_n
	sta p+1
	sty p
	ldy #0
	lda (p),y
	bne goeq2
	ldy #0
	lda (p2),y
	beq eqx
	iny
	lda (p2),y
	ora #%10000000
	cmp #_'/'
	beq eq_compl
	jsr print_pfx
	lda #_'/'
	jsr cout
eq_compl:
	lda p2+1
	ldy p2
	jsr print_path
	jmp crout
eqx:	rts
goeq2:	lda p+1
	ldy p
	jsr print_path
	jmp crout

;************************************************
;
; appl)ications
;
 .if 0 
go_appl:
	message_cstr_cr "(appl not implemented)"
	rts
 .endif

;************************************************
;
; > | como
;
go_como:
	sta p+1
	sty p
	jsr begin_oredir
	lda redir_out
	beq :+
	cmp #refSlot0
	bcs :+
	jsr append
:	rts

;************************************************
;
; < | exec
;
go_exec:
	jsr finish_iredir
	lda #0
	jsr getparm_n
	jmp begin_iredir

;************************************************
;
; go_echo -- type a string (-n = no CR)
;
go_echo:
	sta p+1
	sty p
	ldy #0
	lda (p),y	; length byte
	beq echoed
	tax
echo1:	iny
	lda (p),y
	ora #%10000000
	jsr cout
	dex
	bne echo1
echoed:	lda #'n'
	jsr getparm_ch
	bcc echo_noCR
	jsr crout
echo_noCR:
	rts

;************************************************
;
; touch -- update the mod date of a file,
;          or set/clear backup bit or
;          invisible bit, or enable/disable
;
go_touch:
	jsr getinfo

	jsr touch_b
	jsr touch_d
	jsr touch_i

	jsr getnump
	cmp #1
	bne nTouchDate
	lda date+1
	ldy date
	sta info_moddat+1
	sty info_moddat
	lda time+1
	ldy time
	sta info_modtim+1
	sty info_modtim
nTouchDate:

touch_set:
	lda #0
	jsr getparm_n
	jmp setinfo

touch_b:
	lda #'b'
	jsr getparm_ch
	bcs touch_bx
	tax
	beq touch_bn
	lda info_acc
	ora #%00100000
	bne do_bub
touch_bn:
	lda info_acc
	and #%11011111
do_bub:	sta info_acc
	lda #$ff
	sta bubit	;allow fiddling w/ bkup bit
touch_bx:
	rts

touch_i:
	lda #'i'
	jsr getparm_ch
	bcs touch_ix
	tax
	beq touch_in
	lda info_acc
	ora #%00000100
	sta info_acc
	rts
touch_in:
	lda info_acc
	and #%11111011
	sta info_acc
touch_ix:
	rts

touch_d:
	lda #'d'
	jsr getparm_ch
	bcs touch_dx
	tax
	lda info_type
	cmp #$c7	;CDEV
	beq okDisable
	cmp #$b6
	bcc bad_disable
	cmp #$bd+1
	bcs bad_disable
	cmp #$ba
	beq bad_disable
	cmp #$bc
	beq bad_disable
okDisable:
	txa
	bne tDISABLE
	lda info_auxtype+1
	and #$7f	;enable
	sta info_auxtype+1
	rts
tDISABLE:
	lda info_auxtype+1
	ora #$80	;disable
	sta info_auxtype+1
touch_dx:
	rts

bad_disable:
	jsr mess
	.byte cr
	cstr_cr "*** bad filetype for enable/disable"
	jmp main_err

;************************************************
;
; config
;
go_config:
	lda num_parms
	beq cfg_show
	lda #'p'
	jsr getparm_ch
	bcs cfg2
	cpy #7+1
	bcs cfgperr
	cpy #0
	beq cfgperr
	sty print_slot
	jsr makedirt
cfg2:	lda #'4'
	jsr getparm_ch
	bcs cfg3
	sta cfg40
.if IsDavex3
	jsr config_set_columns
.endif
	jsr makedirt
cfg3:	lda #'b'
	jsr getparm_ch
	bcs cfg4
	sta cfgbell
	jsr makedirt
cfg4:	lda #'c'
	jsr getparm_ch
	bcs cfg5
	sta cfgclock
	jsr makedirt
cfg5:	lda #'q'
	jsr getparm_ch
	bcs cfg6
	cpy #3
	bcs cfgperr
	sty cfgquiet
	jsr makedirt
cfg6:	lda #'h'
	jsr getparm_ch
	bcs cfg7
	sta p+1
	sty p
	sta hp1+1
	sty hp1
	ldy #0
	lda (p),y
	cmp #64
	bcc HelpPok
	lda #der_outroom
	jmp ProDOS_err
HelpPok:
	jsr pmgr
	.byte pm_copy
hp1:	.addr 0,cfghelp
	jsr makedirt
cfg7:	rts

cfgperr:
	lda #der_badnum
	jmp ProDOS_err

cfg_show:
	message_cstr "   Printer slot: "
	lda print_slot
	ora #_'0'
	jsr cout
	jsr mess
	.byte cr
	cstr "Use system bell: "
	lda cfgbell
	jsr showyn
	jsr mess
	.byte cr
	cstr "40 columns only: "
	lda cfg40
	jsr showyn
	jsr mess
	.byte cr
	cstr "Show IIgs clock: "
	lda cfgclock
	jsr showyn
	jsr mess
	.byte cr
	cstr "    Quiet level: "
	lda cfgquiet
	ora #_'0'
	jsr cout
	jsr mess
	.byte cr
	cstr " Help directory: "
	lda #>cfghelp
	ldy #<cfghelp
	jsr print_path
	jmp crout

showyn:	bne showy
	message_cstr "no"
	rts
showy:	message_cstr "yes"
	rts

.if IsDavex3
config_set_columns:
	bne config_set_40
	lda #columns80
	bne config_set_it	; Always
config_set_40:
	lda #columns40
config_set_it:
	sta INIT_SCREEN_COLUMNS
	jsr set_columns
	rts
.endif

;*******************************************************

;*******************************************************
;
; copy <pn1> <pn2> [-f] [-d] [-b]
;
; -f = force replacement of existing file
; -d = delete original after successful copy
; -b = clear backup bit after copy (both files)
;
;*******************************************************
;
; copy(pn1,pn2,options)
; {
;   if null(pn2) pn2 = GetPrefix();
;   GetInfo(pn1);
;   Open(pn1);
;   GetEOF(pn1);
;   repeat
;     GetInfo(pn2);
;     .if type=DIR  concat(pn2,filename(pn1));
;   until type<>DIR;
;   If not found(pn2)
;     create(pn2,"BAD",unlocked)
;   else
;     ask("okay to replace",pn2);
;   ...
; }
;
;*******************************************************
copydir:
	lda cp_pn2+1
	ldy cp_pn2
	sta cpd_cr+2
	sty cpd_cr+1
	jsr geti2
	bcs cpd_cre
	lda info_stype
	cmp #$f
	beq cpdok3
cpd_cre:
	CALLOS mli_create, cpd_cr
	CALLOS_BRANCH_NEG cpd_err
cpdok3:	jsr push_level
	lda cp_pn1+1
	ldy cp_pn1
	jsr dir_setup
cdir1:	jsr read1dir
	bcs cdirx
	lda catbuff
	and #%00001111
	sta catbuff
; append name to path1, path2
	jsr cp_appboth

	jsr cp_report
	jsr cp_recurse

; remove last seg from path1, path2
	lda cp_pn1+1
	ldy cp_pn1
	jsr up_ay
	lda cp_pn2+1
	ldy cp_pn2
	jsr up_ay
	jmp cdir1
cdirx:	jmp dir_finish
cpd_err:
	jmp ProDOS_err

cpd_cr:	.byte 7,0,0,%11000011,tDIR,0,0,$D,0,0,0,0

;*******************************************
up_ay:	sta upay+1
	sty upay
	jsr pmgr
	.byte pm_up
upay:	.addr 0
	rts

cp_appboth:
	lda cp_pn1+1
	ldy cp_pn1
	sta cpapp+1
	sty cpapp
	sta cpsl1+1
	sty cpsl1
	lda cp_pn2+1
	ldy cp_pn2
	sta cpapp2+1
	sty cpapp2
	sta cpsl2+1
	sty cpsl2
	jsr pmgr
	.byte pm_slashif
cpsl1:	.addr 0
	jsr pmgr
	.byte pm_slashif
cpsl2:	.addr 0
	lda #>catbuff
	ldy #<catbuff
	jsr pmgr
	.byte pm_appay
cpapp:	.addr 0
	lda #>catbuff
	ldy #<catbuff
	jsr pmgr
	.byte pm_appay
cpapp2:	.addr 0
	rts

;*******************************************
;*******************************************
go_move:
	sta cp_pn1+1
	sty cp_pn1
	lsr del_flag
	bpl goc_2	; always taken

del_flag:	.res 1

;*******************************************
go_copy:
	sta cp_pn1+1
	sty cp_pn1
	lda #'d'
	jsr getparm_ch
	ror del_flag
goc_2:
	lda #1
	jsr getparm_n
	jsr empty_prefix
	jmp cont
go_copy2:
	sec
	ror del_flag
cont:	sta cp_pn2+1
	sty cp_pn2
	sta cp_crpn+1
	sty cp_crpn
	sta desti_name+1
	sty desti_name

cp_recurse:
	lda cp_pn1+1
	ldy cp_pn1
	jsr getinfo

	lda info_type
	cmp #tDIR
	bne cp_ndir
	jmp copydir
cp_ndir:

	CALLOS mli_open, cp_op1
	CALLOS_BRANCH_NEG cp_err0
	lda cpref1
	sta cpref1b
;
; get eof of file1
;
	sta cpeof_r
	CALLOS mli_geteof, cpeof_p
	CALLOS_BRANCH_NEG cp_err0
.if IsDavex3
	lda cpeof_r
	sta cpseof_ref
	ldy #$03
:	lda #<cpgeof_result
	sta p
	lda #>cpgeof_result
	sta p+1
	lda #<cpseof_result
	sta p2
	lda #>cpseof_result
	sta p2+1
	lda (p),y
	sta (p2),y
	dey
	bne :-
.endif
;
; GetInfo on the dest file
;
cp_getdesti:
	lda #$ff
	sta desti_acc
	sta desti_stt
	CALLOS mli_gfinfo, destinfo
	CALLOS_BRANCH_POS cp_goti
	cmp #err_filnotfnd
	beq cp_create
cp_err0:
	jmp ProDOS_err
cp_goti:
	lda desti_stt
	cmp #$f	;is it a volume?
	beq cp_isdir
	cmp #$d	;is it a subdirectory?
	bne cp_ask
cp_isdir:
;
; append filename of path1 onto path2 and go back to see
; if the file exists
;
	jsr cp_intodir
	jmp cp_getdesti
;
cp_create:
	CALLOS mli_create, cp_creatp
	CALLOS_BRANCH_POS cp_created
	jmp ProDOS_err
;
cp_ask:
	lda desti_acc
	and #%11000011
	cmp #%11000011
	bne ask_anyway

	lda #'f'
	jsr getparm_ch
	bcc cp_created

ask_anyway:
	jsr suspend
	jsr TalkCont
	message_cstr "Okay to replace "
	lda cp_pn2+1
	ldy cp_pn2
	jsr prnt_compl
	lda desti_acc
	and #%11000011
	cmp #%11000011
	beq cpyn
	message_cstr " [LOCKED] "
cpyn:	lda #_'n'	;default = No
	jsr yesno2
	jsr restore	;must save N!
	bmi cp_created
	lda cpref1
	jmp close

cp_created:
	lda info_type
	pha
	lda info_acc
	pha
	lda #tBAD
	sta info_type
	lda #%11000011
	sta info_acc
	lda cp_pn2+1
	ldy cp_pn2
	jsr setinfo
	pla
	sta info_acc
	pla
	sta info_type

	CALLOS mli_open, cp_op2
	CALLOS_BRANCH_NEG cp_er
	lda cpref2
	sta cpref2b
;
; the main copy loop!  (Read a bufferfull, write it..._)
;
copy1:
	CALLOS mli_read, cp_rd1
	CALLOS_BRANCH_POS copy2
	cmp #err_eof
	beq copied
cp_er:	jmp ProDOS_err
copy2:	lda cp_xfer+1
	ldy cp_xfer
	sta cp_xfer2+1
	sty cp_xfer2
	CALLOS mli_write, cp_wr2
	CALLOS_BRANCH_NEG cp_er
	jmp copy1
copied:
; set EOF of file2
	lda cpref2
	sta cpeof_r
.if IsDavex2
	CALLOS mli_seteof, cpeof_p
.else
	CALLOS mli_seteof, cpseof_p	; Need a slightly different parm structure in SOS
.endif
	CALLOS_BRANCH_NEG cp_er
; close both files
	lda cpref1
	jsr close
	lda cpref2
	jsr close
;
; clr backup bit on original if -b
;
	lda #'b'
	jsr getparm_ch
	bcs no_clearbb
	lda #$ff
	sta bubit	;allow bit to clear
	lda info_acc
	and #%11011111
	sta info_acc
	lda cp_pn1+1
	ldy cp_pn1
	jsr setinfo
	lda #$ff
	sta bubit
no_clearbb:
;
; set info on copy
;
	lda cp_pn2+1
	ldy cp_pn2
	jsr setinfo
;
; if -d, delete 1st file %%% should unlock first???
;
	lda del_flag
	bmi cp_notrm
	lda cp_pn1+1
	ldy cp_pn1
	sta cprm_p+1
	sty cprm_p
	CALLOS mli_destroy, cprm
	CALLOS_BRANCH_POS cp_notrm
	jmp ProDOS_err
cp_notrm:
	rts

cp_rd1:		.byte 4
cpref1b:	.byte 0
		.addr copybuff
		.addr cbufflen
cp_xfer:	.addr 0

cprm:		.byte 1
cprm_p:		.addr 0

;
;
; append last seg of path1 onto path2
;
cp_intodir:
	lda cp_pn1+1
	ldy cp_pn1
	sta p+1
	sty p

	lda cp_pn2+1
	ldy cp_pn2
	sta cp_appnm+1
	sty cp_appnm
	sta cp_appnm0+1
	sty cp_appnm0
;
; add a '/' onto path2 if it doesn't end in one already
;
	jsr pmgr
	.byte pm_slashif
cp_appnm0: .addr 0

	ldy #0
	lda (p),y	;length of pn1
	tay
	sta pn1len
	beq intodx
cpsrch:	dey
	beq cpigot
	lda (p),y
	and #$7f
	cmp #$2f
	bne cpsrch
cpigot:	iny
cpi1:	tya
	pha
	lda (p),y
	jsr pmgr
	.byte pm_appch
cp_appnm: .addr 0
	pla
	tay
	iny
	cpy pn1len
	bcc cpi1
	beq cpi1
intodx:	rts

pn1len:	.byte 0

;*********************************************
cp_report:
	lda cp_pn1+1
	ldy cp_pn1
	jsr print_path
	message_cstr " --> "
	lda cp_pn2+1
	ldy cp_pn2
	jsr print_path
	jsr crout
	jmp check_wait

;*********************************************

;*********************************************
;
; size -- print size of file or tree of files
;
szpath:	.addr 0

go_size:
	nop		;disable wildcard expansion display
	jsr empty_prefix
	sta szpath+1
	sty szpath
	jsr print_path
	message_cstr ":  "
	lda szpath+1
	ldy szpath
	jsr size_ay
	lda num+1
	ldy num
	sta num3+1
	sty num3
	jsr prdec_2
	message_cstr " block"
	lda num3+1
	ldy num3
	jsr plural
	message_cstr "; "
	lda num2+2
	ldx num2+1
	ldy num2
	sta num+2
	stx num+1
	sty num
	jsr print_dec
	message_cstr " byte"
	lda num2+2
	ora num2+1
	ldy num2
	jsr plural
	jmp crout
;
; return # blocks in NUM*2 and # bytes
; in NUM2*3
;
size_ay:
	sta p+1
	sty p
	sta sz_path+1
	sty sz_path
	jsr getinfo
	lda info_blocks+1
	ldy info_blocks
	sta num+1
	sty num
	lda #0
	sta sz_eof+2
	sta sz_eof+1
	sta sz_eof
	CALLOS mli_open, sz_open
	CALLOS_BRANCH_NEG sz0
	lda sz_ref
	sta sz_ref2
	CALLOS mli_geteof, sz_geteof
;CALLOS_BRANCH_NEG sz_err ;just use 0 if it returns an error
	lda sz_ref
	jsr close
sz0:	lda sz_eof+2
	ldx sz_eof+1
	ldy sz_eof
	sta num2+2
	stx num2+1
	sty num2
;
; calc volume block size from EOF
;
	ldx info_stype
	cpx #15
	bne sznvol
	lda num2+2
	lsr a
	sta num+1
	lda num2+1
	ror a
	sta num
sznvol:

	lda info_type
	cmp #tDIR
	beq szdir
	rts
; compute size of everything in dir
szdir:	jsr push_level
	lda p+1
	ldy p
	jsr dir_setup
sz1:	jsr read1dir
	bcs sz_x
	lda num2+2
	pha
	lda num2+1
	pha
	lda num2
	pha
	lda num+1
	pha
	lda num
	pha

	jsr build_szpath

	ldx catbuff+16
	cpx #tDIR
	beq slowsize
;
; kwiksize routine -- just look in the DIR entry!
;
; Put blocks --> NUM  (2 bytes)
;     EOF    --> NUM2 (3 bytes)
;
	lda catbuff+$14
	sta num+1
	lda catbuff+$13
	sta num
	lda catbuff+$17
	sta num2+2
	lda catbuff+$16
	sta num2+1
	lda catbuff+$15
	sta num2
	jmp anysize

slowsize:
	jsr size_ay
anysize:
	clc
	pla
	adc num
	sta num
	pla
	adc num+1
	sta num+1
	clc
	pla
	adc num2
	sta num2
	pla
	adc num2+1
	sta num2+1
	pla
	adc num2+2
	sta num2+2
	jmp sz1
sz_x:	jmp dir_finish
sz_err:
	jmp ProDOS_err

build_szpath:
	ldy #127
bszp:	lda direcpath,y
	sta pagebuff,y
	dey
	bpl bszp
	lda catbuff
	and #%00001111
	sta catbuff
	lda #>catbuff
	ldy #<catbuff
	jsr pmgr
	.byte pm_appay
	.addr pagebuff
	lda #>pagebuff
	ldy #<pagebuff
	rts

;********************************************
;
; del -- delete file
;
go_del:	sta del_path+1
	sty del_path
	jsr getinfo
	cmp #tDIR
	bne del_ndir
	jsr suspend
	lda del_path+1
	ldy del_path
	jsr go_size
	jsr TalkCont
	message_cstr "Okay to destroy directory"
	lda #_'n'	;default = No
	jsr yesno2
	jsr restore
	beq deldun
del_ndir:
del_recurse:
	lda #'u'	;unlock first?
	jsr getparm_ch
	bcs del_unlx
	jsr go_unlock
del_unlx:
	lda del_path+1
	ldy del_path
	jsr getinfo
	cmp #tDIR
	bne del_ndir2
	jsr deldir
del_ndir2:
	CALLOS mli_destroy, del_parms
	CALLOS_BRANCH_NEG del_err
deldun:	rts
del_err:
	jmp ProDOS_err

del_parms:
	.byte 1
del_path:
	.addr 0

;****************************************
deldir:
	jsr push_level
	lda del_path+1
	ldy del_path
	jsr dir_setup
deld1:	jsr read1dir
	bcs deldx

	lda catbuff
	and #%00001111
	sta catbuff
	lda del_path+1
	ldy del_path
	sta delp+1
	sty delp
	sta dslif+1
	sty dslif
	jsr pmgr
	.byte pm_slashif
dslif:	.addr 0
	lda #>catbuff
	ldy #<catbuff
	jsr pmgr
	.byte pm_appay
delp:	.addr 0

	jsr del_recurse

	lda del_path+1
	ldy del_path
	jsr up_ay
	jmp deld1
deldx:	jmp dir_finish

;****************************************


;****************************************
;
; dev [-r<dev>] [-a<dev>] [-z]
;
; -z)ap removes all devices that don't
;       currently have volumes online
;
; Should have an option to reconstruct
; the dev table from the BF-page driver
; addresses & slot ROMs.
;
;****************************************
rm_which:
	.byte 0

dv_done:
	rts
go_dev:
	lda num_parms
	bne dv_some

	ldx devcnt
	bmi dv_done
dv_list:
	lda devlst,x
	pha
	jsr pr_sp
	pla
	jsr print_sd
	dex
	bpl dv_list
	rts

dv_some:
	lda #'r'
	jsr getparm_ch
	bcs dv_notr
	jsr dev_rm1
	jmp dv_nota

dv_notr:
	lda #'a'
	jsr getparm_ch
	bcs dv_nota
	ldx devcnt
	cpx #15
	bcc devcntok
	lda #der_outroom
	jmp ProDOS_err
devcntok:
	inc devcnt
	inx
	sta devlst,x
dv_nota:
	lda #'z'
	jsr getparm_ch
	bcs dv_notz
;
; zap all unused volumes
;
	ldx #0
	stx rm_which
zap1:	lda devcnt
	bmi dv_notz
	beq dv_notz
	ldx rm_which
	lda devlst,x
	sta zap_dev
	cpx devcnt
	beq zok
	bcs dv_notz
zok:	CALLOS mli_online, zap_p
	CALLOS_BRANCH_POS zapnext
	lda zap_dev
	jsr dev_rm1
	jmp zap1	;don't increment! (would miss 1)
zapnext:
	inc rm_which
	bne zap1
dv_notz:
	rts

zap_p:		.byte 2
zap_dev:	.byte 1
		.addr pagebuff

;
; dev_rm1 -- remove device in A
;
dev_rm1:
	and #%11110000
	sta temp
; sta dvUnit
	ldx devcnt
	bmi dvrx
	beq dvrx
dv_finda:
	lda devlst,x
	and #%11110000
	cmp temp
	beq dv_found
	dex
	bpl dv_finda
	rts
dv_found:
	lda devlst+1,x
	sta devlst,x
	inx
	cpx devcnt
	bcc dv_found
	dec devcnt
dvrx:	rts

;******************************
;
; update command for Davex
;
go_update:
	sta up_pn1+1
	sty up_pn1
	lda #1
	jsr getparm_n
	jsr empty_prefix
	sta up_pn2+1
	sty up_pn2
upd_recurse:	jsr check_wait
	jsr upd_report
	lda up_pn1+1
	ldy up_pn1
	jsr getinfo
	sta up_type1
	lda info_moddat+1
	ldy info_moddat
	sta up_date1+1
	sty up_date1
	lda info_modtim+1
	ldy info_modtim
	sta up_time1+1
	sty up_time1

	lda up_pn2+1
	ldy up_pn2
	jsr geti2
	bcc upd_ok2
	cmp #err_filnotfnd
	bne uperr
	message_cstr_cr "new file"

	lda #'f'
	jsr getparm_ch
	bcc crenew

	jsr TalkCont
	message_cstr "Okay to create "
	lda up_pn2+1
	ldy up_pn2
	jsr print_path
	jsr yesno
	beq nonew
crenew:	jmp upd_copy
nonew:	rts
uperr:	jmp ProDOS_err
upd_ok2:
;
; check filetypes
;
	lda info_type
	cmp up_type1
	beq types_match

	message_cstr "filetypes differ ("
	lda up_type1
	jsr print_ftype
	lda #_','
	jsr cout
	lda info_type
	jsr print_ftype
	message_cstr ")"
	lda #tDIR
	cmp info_type
	beq cantRepl
	cmp up_type1
	beq cantRepl
; ask
	message_cstr ". Continue"
	lda #_'n'	;default = No
	jsr yesno2
	bne match0
	rts

cantRepl:
	jsr crout
	jmp check_wait

match0:	jsr upd_report

types_match:
;
; compare mod dates of old/new files, or of all files within
; a directory
;
	lda up_type1
	cmp #tDIR
	bne updndir
	jmp update_dir
updndir:
;
; cmp moddate/modtime; info_xxx is file 2, up_xxx for file 1
;
 .if 1 
; Y2K-happy date comparison
	lda info_moddat+1	;compare year numbers
	jsr ExtractAndNormalizeYear
	sta tempDate

	lda up_date1+1
	jsr ExtractAndNormalizeYear
	cmp tempDate
	bne up_cmp

	lda info_moddat+1	;compare high bit of month
	and #1
	sta tempDate
	lda up_date1+1
	and #1
	cmp tempDate
	bne up_cmp

	lda up_date1
	cmp info_moddat
	bne up_cmp
 .else
;not Y2K happy
	lda up_date1+1
	cmp info_moddat+1
	bne up_cmp
	lda up_date1
	cmp info_moddat
	bne up_cmp
 .endif

	lda up_time1+1
	cmp info_modtim+1
	bne up_cmp
	lda up_time1
	cmp info_modtim
up_cmp:	beq up_done
	bcc up_warn

	message_cstr_cr "outdated"
	jsr check_wait

upd_copy:
	lda up_pn1+1
	ldy up_pn1
	sta cp_pn1+1
	sty cp_pn1
	lda up_pn2+1
	ldy up_pn2
	jmp go_copy2

up_done:
	message_cstr_cr "current"
	jmp check_wait

up_warn:
	message_cstr "master file is older ["
	lda up_pn1+1
	ldy up_pn1
	jsr print_path
	message_cstr_cr "]"
	jmp check_wait

;
; Y2K-happy year utility:
;
;   Input = high byte of Date value in A
;   Output = normalized year number in A (40..139 = 1940..2039)
;
WrapAroundYear	= 40

ExtractAndNormalizeYear:
	lsr a
	cmp #WrapAroundYear
	bcs @noWrap1
	adc #100	;map 0..39 --> 100..139
@noWrap1:
	rts

tempDate:
	.byte 0
;
; update recursively on all files within
; directory
;
update_dir:
	message_cstr_cr "scanning directory"

	jsr push_level
	lda up_pn2+1
	ldy up_pn2
	sta upd_up2+1
	sty upd_up2

	lda up_pn1+1
	ldy up_pn1
	sta upd_up+1
	sty upd_up
	jsr dir_setup	;open the subdir

updd1:	;update recursively for each file
	jsr read1dir
	bcs upddx
	lda catbuff
	and #%00001111
	sta catbuff

	jsr up_appboth
	jsr upd_recurse
;
; remove last seg of both pathnames
;
	jsr pmgr
	.byte pm_up
upd_up:	.addr 0
	jsr pmgr
	.byte pm_up
upd_up2:
	.addr 0
	jmp updd1	;go back for more files this dir

upddx:	jmp dir_finish	;close the subdir, return from recursion

;
; append a filename to both pathnames
;
up_appboth:
	lda up_pn1+1
	ldy up_pn1
	sta upapp+1
	sty upapp
	sta upsl1+1
	sty upsl1
	lda up_pn2+1
	ldy up_pn2
	sta upapp2+1
	sty upapp2
	sta upsl2+1
	sty upsl2
	jsr pmgr
	.byte pm_slashif
upsl1:	.addr 0
	jsr pmgr
	.byte pm_slashif
upsl2:	.addr 0
	lda #>catbuff
	ldy #<catbuff
	jsr pmgr
	.byte pm_appay
upapp:	.addr 0
	lda #>catbuff
	ldy #<catbuff
	jsr pmgr
	.byte pm_appay
upapp2:	.addr 0
	rts

;
; report which file we're trying to update now
;
upd_report:
	lda up_pn2+1
	ldy up_pn2
	jsr print_path
	message_cstr " -- "
	rts

;***********************************************
up_pn1:		.addr 0
up_pn2:		.addr 0
up_type1:	.byte 0
up_date1:	.byte 0,0	;mod date of first file
up_time1:	.byte 0,0	;mod time of first file
;***********************************************


;******************************************************
;
; subr -- Davex subroutines
;
;******************************************************
makedirt:
	sec
	ror config_dirty
	rts

;******************************************************
;
; getnump
;
; Output: A = number of parameters
;	  BEQ/BNE for 0 or >0 params!
;
; This is a public entry point (xgetnump).
;
getnump:
	lda num_parms
	rts

;******************************************************
;
; directory-scanning subroutine
;
; scanall -- scan through all command directories for
;  a file (path in AY).  Return BCS if not found;
;  otherwise path is at $280 and A=file type.
;
scanptr: .res 1

scanall:
	sta p+1
	sty p
	ldy #0
	lda (p),y
	beq cmd_err
	cmp #63
	bcc cmd_ok
cmd_err:
	sec
	rts
cmd_ok:
	iny
	lda (p),y
	ora #%10000000
	cmp #_'/'
	bne part_path
;
; full pathname specified; try once
;
	ldy #127
copyfull:
	lda (p),y
	sta cmdpath,y
	dey
	bpl copyfull
	jmp cmdinfo

part_path:
;
; try all the prefixes in ScanList
;
	ldx #0
	stx scanptr
scan1:	ldx scanptr
	lda scanlist,x
	bne scan_more
; we scanned them all and didn't find it
	sec
	rts
scan_more:
	sta count
	cmp #1
	bne not_curdir
	lda scanlist+1,x
	ora #%10000000
	cmp #_'*'
	bne not_curdir
	ldy #0
	sty cmdpath
	beq trycurdir
not_curdir:
	ldy #0
copy_part:
	lda scanlist,x
	sta cmdpath,y
	inx
	iny
	dec count
	bpl copy_part
trycurdir:
	lda p+1
	ldy p
	jsr pmgr
	.byte pm_appay
	.addr cmdpath

	lda p+1
	pha
	lda p
	pha
	lda ptr+1
	pha
	lda ptr
	pha
	lda #>cmdpath
	ldy #<cmdpath
	jsr fixup_path_ay
	pla
	sta ptr
	pla
	sta ptr+1
	pla
	sta p
	pla
	sta p+1

	jsr cmdinfo
	bcs cmd_noper
	rts
cmd_noper:
	ldx scanptr
	txa
	sec
	adc scanlist,x
	sta scanptr
	jmp scan1

;****************************************
;
; load_globpg -- attempt to load Davex's
;                global 'page' from disk
;
load_globpg:
	lsr config_dirty
	lda #>config_pn
	ldy #<config_pn
	jsr build_local
	jsr open_config
	bcs globpg_err
.if IsDavex2
	sta qcref2
	sta qcref3
.endif ; IsDavex2
	lda #mli_read
	jsr rw_config
	bcs globpg_err
	jsr close_config
; this is for people with old config files
gpchk:	lda chk77
	cmp #$77
	beq is77
	lda #0
	tax
fillmisc:
	sta misc,x
	dex
	bne fillmisc
	lda #1
	sta print_slot
	lda #$77
	sta chk77
	jsr makedirt
is77:
; supply '%help' help-dir path if none is recorded
	lda cfghelp
	bne HasHelp
	jsr pmgr
	.byte pm_copy
	.addr DefaultHelp,cfghelp
HasHelp:
	rts

DefaultHelp:
	pstr "%help"

globpg_err:
	lda #0
	tax
fillgp:	sta shell_gp,x
	sta shell_gp+$100,x
	sta shell_gp+$200,x
	sta shell_gp+$300,x
	dex
	bne fillgp
	jsr scan_zap
	sec
	ror config_dirty
	bmi gpchk	; always taken

config_pn:
	pstr "config"

;*********************************************
open_config:
	CALLOS mli_open, ocfg_parms
	CALLOS_BRANCH_NEG ocfg_no
	lda cfg_ref
	sta cfgref2
	clc
	rts
ocfg_no:
	sec
	rts

rw_config:
	cmp #mli_read
	bne config_w
.if IsDavex3
	lda #$04
	sta crw_parms
.endif
	CALLOS mli_read, crw_parms
.if IsDavex3
	CALLOS_BRANCH_POS :+
	sec
	rts
:	clc
.endif
	rts

config_w:
.if IsDavex3
	lda #$03
	sta crw_parms
.endif
	CALLOS mli_write, crw_parms
.if IsDavex3
	CALLOS_BRANCH_POS :+
	sec
	rts
:	clc
.endif
	rts

crw_parms:
	.byte 4
cfgref2:
	.res 1
	.addr shell_gp
	.addr config_len
	.addr 0

close_config:
	lda cfgref2
	jmp close

;**********************************************
save_config:
	bit config_dirty
	bpl clean
	lda #>config_pn
	ldy #<config_pn
	jsr build_local
	jsr create_cfg
	jsr open_config
	bcs sc_err
	lda #mli_write
	jsr rw_config
	bcs sc_err
	lsr config_dirty
	jsr close_config
clean:	clc
	rts

sc_err:	message_cstr "[Unable to save %config]"
	clc
	rts

create_cfg:
	CALLOS mli_create, crcfg_parms
	CALLOS_BRANCH_POS crcfg_x
	cmp #err_dupfil
	beq crcfg_x
	sec
	rts
crcfg_x:
	clc
	rts

;**********************************************
;
; build_local --
;
;  entry:  AY points to partial pathname
;
;  exit:   AY points to MYPATH, which contains
;             the shell directory's prefix +
;             the partial pathname
;
build_local:
	ldx mydir_len
	stx mypath
	jsr pmgr
	.byte pm_appay
	.addr mypath
	lda #>mypath
	ldy #<mypath
	rts
;
; do_autoexec -- execute file specifiedd in startup buffer,
;                if the file exists
;
do_autoexec:
	lda #>exec_pn
	ldy #<exec_pn
	sta ginfopth+1
	sty ginfopth
	jsr fixup_path_ay
.if IsDavex2
	lda #10
	sta infoprm
.endif
	CALLOS mli_gfinfo, infoprm
	CALLOS_BRANCH_NEG no_aexec

	lda #>exec_pn
	ldy #<exec_pn
	jsr begin_iredir
no_aexec:
	rts
;
; plural -- if AY<>1, print 's'
;
plural:
	cmp #0
	bne plur_s
	cpy #1
	bne plur_s
	rts
plur_s:	lda #_'s'
	jmp cout

;
; prnt_compl -- print_path, but print prefix first
; if pn is partial
;
prnt_compl:
	sta p+1
	sty p
	ldy #1
	lda (p),y
	ora #%10000000
	cmp #_'/'
	beq fullpn
	lda p+1
	pha
	lda p
	pha
	jsr print_pfx
	lda #_'/'
	jsr cout
	pla
	sta p
	pla
	sta p+1
fullpn:	lda p+1
	ldy p
	jmp print_path

;
; check_wait -- pause display & allow abort (SEC)
;
; For Textalker (Echo) users: Ctrl-X STAYS on kbd
;
stepping:
	.byte 0

check_wait:
	jsr poll_io
	bit stepping
	bmi cw_wait
	lda keyboard
	bpl cw_x
	cmp #_'X'-ctrl
	beq cw_x
	cmp #$9b	;esc
	beq cw_xxx
	cmp #_'C'-ctrl
	beq cw_abort
	cmp #_'S'-ctrl
	beq cw_wait
	jsr chk_appleper
	cmp #_' '
	bne cw_x
	sta kbdstrb
cw_wait:
	jsr poll_io
	lda keyboard
	bpl cw_wait
	sta kbdstrb	;munch bad chars in case type-ahead active
	jsr CheckHC
	bcc cw_wait
	cmp #$9b	;Escape
	beq cw_xxx
	cmp #_'C'-ctrl
	beq cw_abort
	cmp #_'X'-ctrl
	beq cw_xx
	cmp #_'S'-ctrl
	beq cw_done
	cmp #_'Q'-ctrl
	beq cw_done
	jsr chk_appleper
	cmp #_' '
	bne cw_x	;was cw_wait
	ror stepping
	clc
	rts
cw_done:
	sta kbdstrb
cw_x:	clc
cw_xx:	php
	lsr stepping
	plp
	rts
cw_xxx:	jsr crout
	sta kbdstrb
	lsr stepping
	sec
	rts
cw_abort:
	sta kbdstrb
	lsr stepping
	jmp yn_abort

chk_appleper:
	cmp #_'.'
	bne notAper
	bit button0	;Apple
	bpl notAper
	ldx machine
	cpx #6
	beq cw_abort
notAper:
	rts

close:
	sta mycl_r
	CALLOS mli_close, mycls
close_done:
	rts

mycls:	.byte 1
mycl_r:	.res 1

;
; empty_prefix -- used after call to getparm.
; If string AY points to is empty, load AY
; with pointer to prefix instead
;
empty_prefix:
	sta ptr+1
	sty ptr
	ldy #0
	lda (ptr),y
	beq ep_usepfx
	lda ptr+1
	ldy ptr
	rts
ep_usepfx:
	jmp get_pfx
;
; percent -- return A=percent
; that NUM(*3) is of AXY
;
percent:
	sta num3+2
	stx num3+1
	sty num3
	lda #0
	sta num+3
	sta num3+3
	sta num2+3
	sta num2+2
	sta num2+1
	sta num2
	sta perc
	jsr mult10num
	jsr mult10num
; while num2<num do (perc++; num2+=num3)
per_while:
	sec
	lda num2
	sbc num
	lda num2+1
	sbc num+1
	lda num2+2
	sbc num+2
	lda num2+3
	sbc num+3
	bcs per_whilex
	clc
	ldy #4
	ldx #0
per_add:
	lda num2,x
	adc num3,x
	sta num2,x
	inx
	dey
	bne per_add
	inc perc
	bne per_while
per_whilex:
	lda perc
	rts

perc:	.byte 0

;
; show_percent -- info_blocks/info_auxtype
;
;   ' (xx%)'
;
show_percent:
	message_cstr "  ("
	lda #0
	ldx info_blocks+1
	ldy info_blocks
	sta num+2
	stx num+1
	sty num
	lda #0
	ldx info_auxtype+1
	ldy info_auxtype
	jsr percent
	jsr prdec_1
	message_cstr "%)"
	rts
;
; need_prefix -- if prefix is null, set it
; to the shell path
;
need_prefix:
	jsr get_pfx
	sta p+1
	sty p
	ldy #0
	lda (p),y
	bne @out
	lda mydir_len
	sta mypath
	CALLOS mli_setpfx, needp_p
	jsr go_top
@out:	rts

needp_p:
	.byte 1
	.addr mypath

;****************************************
;
; fixup_path_ay -- if path begins with
;    %    --> % is shell directory
;    .sd  --> .sd is volume name
;    ..   --> .. is parent directory
;    .    -->  . is current directory
;
fixup_path_ay:
	sta p+1
	sty p
	sta ptr+1
	sty ptr
	ldy #0
	lda (p),y
	beq :+
	iny
	jsr pchar
	cmp #_'%'
	beq fp_shelld
	cmp #_'.'
	beq fixup_dot
:	rts

fp_shelld:
	jsr shorten_p
	ldy #1
	jsr pchar
	cmp #_'/'
	bne fpsh2
	jsr shorten_p
fpsh2:	lda p+1
	ldy p
	jsr build_local
	ldy mypath
fpcopy:	lda mypath,y
	sta (ptr),y
	dey
	bpl fpcopy
	rts

fixup_dot:
	ldy #0
	lda (p),y
	cmp #2
	bcc not_parent
	ldy #2
	jsr pchar
	cmp #_'.'
	bne not_parent
; .. = parent directory
	jsr shorten_p
	jsr shorten_p
	ldy #0
	lda (ptr),y
	beq parent_nosl
	iny
	jsr pchar
	cmp #_'/'
	bne parent_nosl
	jsr shorten_p
parent_nosl:
	sec	;flag '..'
	.byte $24 ; Hide next byte (skip over the CLC)
singleDOT:
	clc	;flag '.'
	php
	CALLOS mli_getpfx, dotdotPARMS
	jsr pmgr
	.byte pm_downcase
	.addr pagebuff
	plp
	bcc not_dotdot
	jsr pmgr
	.byte pm_up
	.addr pagebuff
	lda pagebuff
	cmp #1
	bne not_dotdot
	dec pagebuff
not_dotdot:
	jmp splice_dot

not_parent:
; check for .sd
	ldy #0
	lda (p),y
	cmp #3
	bcc chk_dot
	ldy #2
	jsr pchar
	cmp #_'1'
	bcc chk_dot
	cmp #_'8'
	bcs chk_dot
	and #%00001111
	asl a
	asl a
	asl a
	asl a
	sta temp
	iny
	jsr pchar
	cmp #_'1'
	bcc :+
	cmp #_'3'
	bcs :+
	and #%00000001
	ror a
	ror a
	ora temp
	eor #%10000000
	jsr online1
	jmp splice_sd
:	rts

chk_dot:
	jsr shorten_p
	ldy #0
	lda (ptr),y
	beq singleDOT
	iny
	jsr pchar
	cmp #_'/'
	bne singleDOT
	jsr shorten_p
	jmp singleDOT

online1:
	sta o1_dev
	CALLOS mli_online, o1_parms
	CALLOS_BRANCH_POS o1ok
	jmp ProDOS_err
o1ok:	lda pagebuff+1
	and #%00001111
	tax
	inx
	inx
	stx pagebuff
	lda #'/'
	sta pagebuff+1
	sta pagebuff,x
	jsr pmgr
	.byte pm_downcase
	.addr pagebuff
	rts

o1_parms:
	.byte 2
o1_dev:	.res 1
	.addr pagebuff+1

splice_dot:
	ldy #0
	lda (ptr),y
	sta temp
	inc temp
	ldy #1
	bne splpth2

splice_sd:
	ldy #0
	lda (ptr),y
	sta temp
	inc temp
	ldy #4
	lda (ptr),y
	ora #%10000000
	cmp #_'/'
	bne splpth2
	iny
splpth2:
	cpy temp
	bcs splpth3
	lda (ptr),y
	inc pagebuff
	ldx pagebuff
	sta pagebuff,x
	iny
	bne splpth2
splpth3:
	ldy #127
:	lda pagebuff,y
	sta (ptr),y
	dey
	bpl :-
	rts

;
; shorten_p -- remove 1st character of
;              path at P
;
shorten_p:
	ldy #0
	lda (p),y
	beq :+
	tax
@loop:	iny
	iny
	lda (p),y
	dey
	sta (p),y
	dex
	bne @loop
	lda (p,x)
	sec
	sbc #1
	sta (p,x)
:	rts

;
; pchar -- get (p),y in lowercase, high bit on
;
pchar:	lda (p),y
	jmp downcase

;*************************************
;
; memory manager (crude but useful)
;
; commands (x): MLI_xxx
;   close -- free all dynamic mem
;
;   open  -- alloc A pages from low
;            mem; SEC=out of mem;
;            return A=1st page
;
;   read  -- # free pages --> A (Y=0)
;
;   gfinfo-- get low page --> A (Y=0)
;
;   write -- set high page to A
;
mmgr:	cpx #mli_close
	bne mm_ncl
;
; close: free dynamic mem
;
	lda #>highmem
	sta mmgr_hi
	lda #>copybuff
	sta mmgr_lo
	clc
	rts

mm_ncl:	cpx #mli_write
	bne mm_nwr
;
; write: set high page
;
	cmp mmgr_lo
	bcc mmw_err
	cmp #>highmem
	bcs mmw_err
	sta mmgr_hi
	clc
	rts

mmw_err:
	lda #der_outmem
	sec
	rts

mm_nwr:	cpx #mli_gfinfo
	bne mm_ninfo
;
; getinfo: A=low page
;
	lda #0		;open 0 pages
	beq mmopen	;always taken

mm_ninfo:
	cpx #mli_open
	bne mm_nopen
;
; open: reserve A pages
;
mmopen:	ldy mmgr_lo	;reserve here
	clc
	adc mmgr_lo
	cmp mmgr_hi
	bcs mmw_err
	sta mmgr_lo
	tya
	ldy #0
	clc
	rts

mm_nopen:
	cpx #mli_read
	bne mm_nrd
;
; read: get free pages
;
	sec
	lda mmgr_hi
	sbc mmgr_lo
	ldy #0
	clc
	rts

mm_nrd:
	lda #err_badcall
	sec
	rts

;***********************************
;
; off80
;
off80:
	jsr finish_oredir
.if IsDavex2
	jsr mess
	.byte _'U'-ctrl,_'T'-ctrl,_'A',_'1',0	; for an old 80-column card on Apple II+?
	jsr setkbd
	jsr setvid
	jsr hook_speech
.else ; isDavex3
	jsr on40
.endif ; isDavex2
	lda #40
	sta scr_width
	jmp home

;********************************************
;
; wildcard expansion routines for
; Davex
;
; 28-Jun-86
;
;*******************************************
;*******************************************
;
; wild_state :
;   0 = not expanding wildcards
;   1 = returning original path; no wildcards
;   2 = scanning directory
;   3 = scanning volume list
;
wild_state:	.res 1
;
; wild_begin -- start a wildcard
; expansion
;
wild_begin:
	lda #1
	sta wild_state
	lda num_parms
	beq wbx
	jsr grab_wstrings
	jsr contains_wild
	bcs wbx

	inc wild_state	; = 2
	bit wild_flags
	bvc :+		; branch if no wildcards in volume name portion
	inc wild_state	; = 3
:	jsr push_level
	lda #>wildstring1
	ldy #<wildstring1
	jsr getinfo
	cmp #tDIR
	beq w_isDIR
	lda #der_notdir
	jmp ProDOS_err
w_isDIR:
	lda #>wildstring1
	ldy #<wildstring1
	jsr dir_setup
wbx:	rts
;
; wild_next -- create next expansion
; of wildcard strings; return SEC if
; no more matches
;
wild_next:
	ldx wild_state
	beq wn_done
	dex
	bne nxtwld
; return non-wild path once
	stx wild_state
	clc
	rts

nxtwld:	jsr read1dir
	bcs wnfin1
	lda catbuff
	and #%00001111
	sta catbuff
	jsr compare_wild
	bcs nxtwld
	jsr expand_wild
;
; print <command> <path1> [<path2>] except
; for commands beginning with NOP
;
	jsr suspend
	bit wild_flags
	bmi ask_path
	ldy #0
	lda (cmd_addr),y
	cmp #$ea
	beq no_askpath
	bne askpath2
ask_path:
	jsr TalkCont
askpath2:
	jsr print_cmd
	jsr pr_sp
	lda #0
	jsr getparm_n
	jsr print_path
	lda parmtypes+1
	cmp #t_path
	beq do2
	cmp #t_wildpath
	bne skip2
do2:	jsr pr_sp
	lda #1
	jsr getparm_n
	jsr print_path
skip2:
	bit wild_flags
	bpl noquery
	lda #_'n'	;default = No
	jsr yesno2
	jsr restore
	beq nxtwld
	clc
	rts

noquery:
	jsr crout
no_askpath:
	jsr restore
	clc
	rts

wnfin1:	jsr dir_finish
	dec wild_state
wn_done:
	sec
	rts

;*******************************************
;
; directory reading routines
;
; push_level -- close old dir level (do this
;               before calling dir_setup)
;
; dir_setup -- open dir (ay=path)
;
; read1dir -- get next active entry from
;             open directory; BCS if no more
;             entries
;
; dir_finish -- close level
;
;*******************************************
dir_setup:
	ldx #0
	stx direcpath
	jsr dir_setup2
	bcc :+
	jmp ProDOS_err
:	rts

dir_setup2:		; partial path in AY
	pha
	tya
	pha
	lda dir_level
	bpl :+
	lda #0
	sta direcpath
:	pla
	tay
	pla
	jsr buildcatpath
	lda #wildlevel
	SET_LEVEL
	CALLOS mli_open, opendir_p
	pha
	lda #stdlevel
	SET_LEVEL
	pla
	CALLOS_BRANCH_POS dset_opened
	sec
	rts
dset_opened:
	lda dir_ref
	sta dir_ref2
	sta dir_ref3
	sta dir_ref4
.if IsDavex3
	sta dir_ref5
.endif
	lda #0
	ldy #$23
	jsr setmark
	bcs wld_err
	jsr read1byte
	bcc wld_did1
	rts
wld_did1:
	sta EntryLen
	jsr read1byte
	sta EntPerBlock
	jsr read1byte
	sta file_count
	jsr read1byte
	sta file_count+1

	lda EntPerBlock
	sta filecntr

	lda #4
	clc
	adc EntryLen
	tay
	lda #0
	jsr setmark
	dec filecntr
	lda dir_ref
	clc
	rts
wld_err:
	jmp ProDOS_err

;
; read next active entry & dec file_count
;
read1dir:
	lda EntryLen
	sta rc_len
	CALLOS mli_read, readcat_parms
	CALLOS_BRANCH_POS rc_ok
	cmp #err_eof
	beq eoDIR
	jmp ProDOS_err

eoDIR:
;;;	sec		; carry is already set from CMP+BEQ ( sec for >= )
	rts

rc_ok:	dec filecntr
	bne rc_sameblk
	jsr getmark
	ldy #4
	and #%11111110
	clc
	adc #2
	jsr setmark
	lda EntPerBlock
	sta filecntr
rc_sameblk:
	lda catbuff
	and #%11110000
	beq read1dir	;not active

	lda file_count
	bne :+
	dec file_count+1
:	dec file_count
	jsr calc_cmask
	ldy #1
	ldx #15
niceCase:
	asl case_mask+1
	rol case_mask
	bcc NoLcase
	lda catbuff,y
	jsr downcase
	and #$7f
	sta catbuff,y
NoLcase:
	iny
	dex
	bne niceCase
; zero out unused name bytes (for sorting)
	lda catbuff
	and #$f
	tay
	lda #0
:	cpy #15
	bcs @out
	sta catbuff+1,y
	iny
	bne :-
@out:	clc
	rts
;
; close file & pop level of dirstack
;
dir_finish:
	jmp pop_level

readcat_parms:
	.byte 4
dir_ref2:
	.res 1
	.addr catbuff
rc_len:	.addr 0
	.res 2


; do not change order or insert
file_count:
	.res 2
filecntr:
	.res 1	;counts down to 0 for each block
; end of do-not-change

EntryLen:
	.res 1
EntPerBlock:
	.res 1
;
; getmark into ay
;
getmark:
	CALLOS mli_getmark, get_mark_parms
	lda pmark+1
	ldy pmark
	rts
setmark:
.if IsDavex2
	sta pmark+1
	sty pmark
	lda #0
	sta pmark+2
.else
	sta pmark_set+1
	sty pmark_set
	lda #0
	sta pmark_set+2
.endif
setmark2:
	CALLOS mli_setmark, set_mark_parms
	CALLOS_BRANCH_POS :+
	sec
	rts
:	clc
	rts

read1byte:
	CALLOS mli_read, read1p
	CALLOS_BRANCH_NEG r1x2
dcheat:	lda #0
r1x:
	clc
	rts
r1x2:
	sec
	rts

read1p:	.byte 4
dir_ref4:
	.res 1
	.addr dcheat+1
	.addr 1
	.addr 0

buildcatpath:
	sta p+1
	sty p
	ldy #1
	lda (p),y
	and #%01111111
	cmp #$2f
	beq bcp_full
; append to old direcpath
	ldy #0
	lda (p),y	;len
	tax
appdirp:
	iny
	lda (p),y
	cpx #0
	beq appdirpx
	stx appdpx
	inc direcpath
	ldx direcpath
	sta direcpath,x
	ldx appdpx
	dex
	bne appdirp
needslash:
	ldx direcpath
	lda direcpath,x
	and #%01111111
	cmp #$2f
	beq slashed
	inc direcpath
	lda #$2f
	ldx direcpath
	sta direcpath,x
slashed:
appdirpx:
	rts

appdpx:	.res 1

bcp_full:
	ldy #64
bcpf2:	lda (p),y
	sta direcpath,y
	dey
	bpl bcpf2
	jmp needslash

;*******************************************
push_level:
	lda dir_level
	bmi pl_nolevel

	jsr getmark
	lda #wildlevel
	SET_LEVEL
	lda dir_ref
	jsr close	;close this level
	lda #stdlevel
	SET_LEVEL

	lda dir_level
	cmp #dstkmax
	bcc dlevelok
	lda #der_levels
	jmp ProDOS_err
dlevelok:
	ldy #64
pushpn:	lda direcpath,y
	sta (dstk_ptr),y
	dey
	bpl pushpn
	ldy #dstk_mark
	lda pmark
	sta (dstk_ptr),y
	lda pmark+1
	iny
	sta (dstk_ptr),y
	lda pmark+2
	iny
	sta (dstk_ptr),y
	ldy #dstk_fcount
pushmore:
	lda file_count-dstk_fcount,y
	sta (dstk_ptr),y
	iny
	cpy #dstk_recsiz
	bcc pushmore
	clc
	lda dstk_ptr
	adc #dstk_recsiz
	sta dstk_ptr
	bcc dstkpok
	inc dstk_ptr+1
dstkpok:
pl_nolevel:
	inc dir_level
	rts

;*******************************************
pop_level:
	lda dir_ref
	jsr close
	lda #0
	sta direcpath
	lda dir_level
	cmp #1
	bpl pop_lev2
	lda #<-1
	sta dir_level
	sec
	rts
pop_lev2:
	sec
	lda dstk_ptr
	sbc #dstk_recsiz
	sta dstk_ptr
	bcs dstkpok2
	dec dstk_ptr+1
dstkpok2:
	lda dstk_ptr+1
	ldy dstk_ptr
	sta p+1
	sty p
	ldy #64
popdirp:
	lda (p),y
	sta direcpath,y
	dey
	bpl popdirp
	lda p+1
	ldy p
	jsr dir_setup
	ldy #dstk_mark
	lda (dstk_ptr),y
	sta pmark
	iny
	lda (dstk_ptr),y
	sta pmark+1
	iny
	lda (dstk_ptr),y
	sta pmark+2
	jsr setmark2
	ldy #dstk_fcount
	lda (dstk_ptr),y
	sta file_count
	iny
	lda (dstk_ptr),y
	sta file_count+1
	ldy #dstk_filecntr
	lda (dstk_ptr),y
	sta filecntr
	dec dir_level
	clc
	rts

;*******************************************
;
; wildcard string routines
;
;*******************************************
;
; contains_wild -- return CLC if WILDSTRING1
; is wild
;
; wild_index = position in wildstring1 of
; wildcard_
;
; wild_flags:  Q V x x  x x x x
;   Q=query (?)
;   V=wild in volume name
;
wild_index:	.res 1
wild_flags:	.res 1

contains_wild:
	ldy #0
	sty wild_index
	sty wild_flags
	sty temp	;true if hit '/'
	lda wildstring1,y
	tay
	beq cw_no
cw1:	lda wildstring1,y
	ora #%10000000
	cmp #_'/'
	bne cwnslsh
;;;	sec
	ror temp
cwnslsh:
	cmp #_'*'
	beq cwyes0
	cmp #_'='
	beq cwyes
	cmp #_'?'
	bne cwno
	lda #%10000000	;query flag
	ora wild_flags
	sta wild_flags
cwyes0:	lda #_'='
	sta wildstring1,y
cwyes:	ldx wild_index
	bne extra_wild
	bit temp
	bmi bad_place
	sty wild_index
cwno:	dey
	bne cw1
	lda wild_index
	bne cw_yes
cw_no:	sec
	rts
cw_yes:	ldy #1
	lda wildstring1,y
	ora #%10000000
	cmp #_'/'
	bne not_wvol
	ldx #1	;'/' count
wvolchk:
	iny
	cpy wild_index
	bcs wvchecked
	lda wildstring1,y
	ora #%10000000
	cmp #_'/'
	bne wvolchk
	inx
	bne wvolchk
wvchecked:
	cpx #2
	bcs not_wvol
	lda #%01000000	;wc in volname
	ora wild_flags
	sta wild_flags
not_wvol:
	jsr build_wpath
	clc
	rts
;
extra_wild:
	lda #der_1wild
der5:	jmp ProDOS_err
;
bad_place:
bad_wild:
	lda #der_badwild
	bne der5
;
; build_wpath -- copy part of wildstring1 before
; segment with wildcard into wdirpath
;
build_wpath:
	ldy wild_index
bwp2:	lda wildstring1,y
	ora #%10000000
	cmp #_'/'
	beq bwp_len
	dey
	bne bwp2
; wc in seg1 of partial path; use prefix
	ldx wildstring1
wseg2:	lda wildstring1,x
	sta wildseg,x
	dex
	bpl wseg2
	CALLOS mli_getpfx, wildpfx
	jsr pmgr
	.byte pm_downcase
	.addr wildstring1
	rts

bwp_len:
	sty temp
	sec
	lda wildstring1
	sbc temp
	sta wildseg	;length of last seg
	ldx #0
wseg1:	iny
	inx
	lda wildstring1,y
	sta wildseg,x
	cpy wildstring1
	bcc wseg1
	ldy temp
	sty wildstring1
	rts
;
; compare_wild -- returns CLC if string in CATBUFF
; matches string at WILDSEG
;
; May have to ask the user (for '?' wildcards)
;
matchstr_left:	.res 1
matchstr_r:	.res 1

compare_wild:
	bit wild_flags
	bvc cmpw_notvol
; we could allow wildcards in volume names someday, but now it's an error
	jmp bad_wild

cmpw_notvol:
	jsr cmp_wseg
	bcs cmpwno
	lda #0
	jsr getparm_n
	txa
	beq cmpw_notyp
	cmp catbuff+16
	bne cmpwno
cmpw_notyp:
	clc
	rts
cmpwno:
	sec
	rts
;
; CLC=matches: compare path at catbuff to
; wildseg (containing '=' for any wc)
;
cmp_wseg:
; an '=' must match at least 0 characters
	ldx catbuff
	inx
	cpx wildseg
	bcc cmppw_no
	jsr cmp_left
	bcs cmppw_no
; calculate matchstr_r
	sec
	lda catbuff
	sbc wildseg
	sec
	adc matchstr_left
	sta matchstr_r

	jmp cmp_right

cmppw_no:
	sec
	rts

;
; cmp_left -- return CLC if chars in WILDSEG
; before wildcard match chars at beginning
; of path at CATBUFF
;
cmp_left:
	ldy #0
cleft1:	lda wildseg+1,y
	jsr downcase
	cmp #_'='
	beq cleftok
	sta temp
	lda catbuff+1,y
	jsr downcase
	cmp temp
	bne cleftno
	iny
	cpy wildseg
	bcc cleft1
cleftok:
	iny
	sty matchstr_left
	clc
	rts
cleftno:
	sec
	rts

;
; cmp_right -- return CLC if chars in WILDSEG
; after wildcard match chars at end of path
; at CATBUFF
;
cmp_right:
	ldy wildseg
	ldx catbuff
cright1:
	lda wildseg,y
	jsr downcase
	cmp #_'='
	beq crightok
	sta temp
	lda catbuff,x
	jsr downcase
	cmp temp
	bne crightno
	dex
	dey
	bne cright1
crightok:
	clc
	rts
crightno:
	sec
	rts

;
; grab_wstrings -- copy 1st (and possibly 2nd)
; path parameters into wildstring1 (and
; wildstring2)
;
grab_wstrings:
	lda #0
	sta wildstring1
	sta wildstring2
	lda parmtypes
	cmp #t_wildpath
	bne grabbed
	lda #0
	jsr getparm_n
	sta p+1
	sty p
	ldy #127
grab1:	lda (p),y
	sta wildstring1,y
	dey
	cpy #<-1
	bne grab1

	lda parmtypes+1
	cmp #t_path
	beq grab2a
	cmp #t_wildpath
	bne grabbed
grab2a:	lda #1
	jsr getparm_n
	sta p+1
	sty p
	ldy #127
grab2:	lda (p),y
	sta wildstring2,y
	dey
	cpy #<-1
	bne grab2
grabbed:
	rts

;
; expand_wild -- generate first path from
; catbuff & wildstring1.  If there's a second
; path, replace any wild character in it with the
; same string the wild character in the 1st
; path replaces
;
expand_wild:
	lda #0
	jsr getparm_n
	sta p+1
	sty p
	sta ew_p+1
	sty ew_p
	ldy #127
ew1:	lda wildstring1,y
	sta (p),y
	dey
	bpl ew1
	lda #>catbuff
	ldy #<catbuff
	jsr pmgr
	.byte pm_appay
ew_p:	.addr 0
;
; replace '=' in wildstring2 with WildReplace
;
	lda wildstring2
	beq @out
	lda #1
	jsr getparm_n
	sta p+1
	sty p
	lda #0
	tay
	tax
	sta (p),y
@loop:	cpx wildstring2
	bcs @out
	inx
	lda wildstring2,x
	jsr replch
	jmp @loop
@out:	rts

;
; replch -- add char or WILDREPACE onto
; second parameter
;
replch:
	ora #%10000000
	cmp #_'?'
	beq replwc
	cmp #_'*'
	beq replwc
	cmp #_'='
	bne repl_addch

replwc:
	txa
	pha
	ldx matchstr_left
appmatch:
	cpx matchstr_r
	bcs appmatchx
	lda catbuff,x
	jsr repl_addch
	inx
	bne appmatch
appmatchx:
	pla
	tax
	rts

repl_addch:
	pha
	ldy #0
	lda (p),y
	clc
	adc #1
	sta (p),y
	cmp #126
	bcs wc_outr
	tay
	pla
	sta (p),y
	rts

wc_outr:
	lda #der_outroom
	jmp ProDOS_err


;
; Modified 23-Jan-90 DAL for Davex 1.25
;   History buffer is now $100 bytes (was $200)
;
;*********************************************
;
; Path manager for DAVEX
;
; History manager for DAVEX
;
;*********************************************
;
; call format:
;
;   jsr pmgr
;   .byte pm_-----
;   .addr (parameters)
;
;*********************************************
pmlen:	.res 1
pm_y:	.res 1

pm_disp:
	.addr pm_doappay-1
	.addr pm_doappch-1
	.addr pm_doup-1
	.addr pm_doslashif-1
	.addr pm_docopy-1
	.addr pm_dodownc-1

;*********************************************
pmfetch2:
	jsr pmfetch
	sta pmpath2
	jsr pmfetch
	sta pmpath2+1
	rts

;*********************************************
pmfetch:
	inc pmptr
	bne pmptrok
	inc pmptr+1
pmptrok:
	ldy #0
	lda (pmptr),y
	rts

;*********************************************
pmgr:	sta pmpath1+1
	sty pmpath1
	pla
	sta pmptr
	pla
	sta pmptr+1
	jsr pmfetch
	cmp #pm_last+1
	bcc pmgr_ok
	.byte 0		; single-byte brk (since assembler wants 2)

pmgr_ok:
	jsr pmgr2
	lda pmptr+1
	pha
	lda pmptr
	pha
	lda pmpath1+1
	ldy pmpath1
	rts

pmgr2:	asl a
	tay
	lda pm_disp+1,y
	pha
	lda pm_disp,y
	pha
	lda pmpath1+1
	ldy pmpath1
	rts

;*********************************************
pm_doappay:
	jsr pmfetch2
	ldy #0
	lda (pmpath1),y
	sta pmlen
pmapp1:	cpy pmlen
	bcs pmapped
	iny
	lda (pmpath1),y
	jsr pm_app2
	jmp pmapp1
pmapped:
	rts

pm_doappch:
	jsr pmfetch2
	lda pmpath1+1	;a
	jmp pm_app2

pm_doup:
	jsr pmfetch2
	ldy #0
	lda (pmpath2),y
	beq upxx
	tay
	dey
	beq didup
doup1:	lda (pmpath2),y
	and #$7f
	cmp #$2f
	beq didup
	dey
	bpl doup1
didup:	tya
	ldy #0
	sta (pmpath2),y
upxx:	rts

pm_doslashif:
	jsr pmfetch2
	ldy #0
	lda (pmpath2),y
	tay
	lda (pmpath2),y
	and #$7f
	cmp #$2f
	beq dsifx
	lda #$2f	;slash
	bne pm_app2
dsifx:	rts

pm_docopy:
	jsr pmfetch2
	lda pmpath2+1
	ldy pmpath2
	sta pmpath1+1
	sty pmpath1
	jsr pmfetch2
	ldy #0
	lda (pmpath1),y
	tay
pmcopy1:
	lda (pmpath1),y
	sta (pmpath2),y
	dey
	cpy #$ff
	bne pmcopy1
	rts

pm_app2:
	sty pm_y
	pha
	ldy #0
	lda (pmpath2),y
	clc
	adc #1
	sta (pmpath2),y
	tay
	pla
	sta (pmpath2),y
	ldy pm_y
	rts

pm_dodownc:
	jsr pmfetch2
	ldy #0
	lda (pmpath2),y
	beq @out
	tay
@loop:	lda (pmpath2),y
	jsr downcase
	and #$7f
	sta (pmpath2),y
	dey
	bne @loop
@out:	rts

;*********************************************
;*********************************************
;
; HistoryMgr -- manage list of previous cmds
;
HistoryMgr:
	cpx #mli_close
	bne n_hcl
;
; empty the history list
;
	lda #0
	sta History
	clc
	rts

n_hcl:	cpx #mli_write
	bne n_hwr
;
; write string (AY) to history list
;
	sta p2+1
	sty p2
histwr0:
	jsr count_history
	sec
	ldy #0
	lda p
	adc (p2),y
	lda p+1
	adc #0
	cmp #>(History+$100)
	bcc hist_fits
	jsr shift_hist
	jmp histwr0

hist_fits:
	ldy #0
	lda (p2),y
	tay
	iny
	lda #0
	sta (p),y
	dey
	inc p2
	bne hp2ok
	inc p2+1
hp2ok:
histwr1:
	lda (p2),y
	sta (p),y
	dey
	cpy #<-1
	bne histwr1
	clc
	rts

n_hwr:	cpx #mli_read
	bne n_hrd
;
; read the Ath string from the end of the
; history list (return ptr in AY)
;
	sta temp
	jsr count_history
	pha
	jsr point_history
	pla
	sec
	sbc #1
	sec
	sbc temp
	sta temp
	beq readhist
readh1:	jsr next_hist
	cpy #0
	beq readherr
	dec temp
	bne readh1
readhist:
	lda p+1
	ldy p
	clc
readherr:
	rts

n_hrd:	sec
	lda #err_badcall
	rts
;
; return size of history (A)
;
count_history:
	ldx #<-1
	jsr point_history
@count:	inx
	jsr next_hist
	cpy #0
	bne @count
	txa
	rts
;
; point_history
;
point_history:
	lda #>History
	ldy #<History
	sta p+1
	sty p
	rts
;
; next_hist -- advance P to next string
; return len of str in Y
;
next_hist:
	ldy #<-1
nexth1:	iny
	lda (p),y
	bne nexth1
	tya
	beq nh1
	sec
	adc p
	sta p
	bcc nh1
	inc p+1
nh1:	rts

;
; shift_hist -- remove oldest string
;
shift_hist:
	jsr point_history
	lda p+1
	ldy p
	sta move_to+1
	sty move_to
	jsr next_hist
	lda p+1
	ldy p
	sta range_strt+1
	sty range_strt
	lda #>(History+$100)
	ldy #<(History+$100)
	sta range_end+1
	sty range_end
	ldy #0
	jmp move


;***********************************************************
;
; File manager for Davex  -- USES PAGEBUFF!
;
;***********************************************************
;
; Note: This implementation can keep track of just ONE
;       file at a time.
;
;***********************************************************
;
; Allows commands to easily support reading from AWP files.
; calls:
;
;   jsr fman_open
;     takes path ptr in AY, returns (CLC,A=refnum) or
;     (SEC,A=error)
;
;   jsr fman_read
;     takes refnum in A, returns (CLC,A=char) or (SEC,A=err)
;
;***********************************************************
fm_bufidx:	.byte 0
fm_bufsz:	.byte 0
awp_blanks:	.byte 0

fman_open:
	sta fm_name+1
	sty fm_name
	sta fm_info+1
	sty fm_info
	CALLOS mli_gfinfo, fm_infop
	CALLOS_BRANCH_NEG fmEXIT1
	CALLOS mli_open, fm_openp
	CALLOS_BRANCH_NEG fmEXIT2
fmOK:	lda #0
	sta fm_bufsz
	sta fm_bufidx
	sta awp_blanks
	lda fm_type
	cmp #tAWP
	bne notAWPopn
	jsr SkipAWPhdr
notAWPopn:
	lda fm_ref
	clc
	rts
fmEXIT:	sec
	rts
fmEXIT1:
	jmp ProDOS_err
fmEXIT2:
	cmp #err_filopen
	bne fmOK
	jmp ProDOS_err

SkipAWPhdr:
	lda fm_ref
	sta fm_posref
	CALLOS mli_setmark, fm_setmp
	rts

fm_readp:
	.byte 4
fm_rref:
	.byte 0
	.addr pagebuff
	.addr 80	;request count
txtLEN:	.addr 0

;*******************************************
fman_read:
	sta fm_rref
	lda fm_type
	cmp #tAWP
	beq fmr_awp
;
; read 1 character from a non-AWP file
;
fmr_txt:
	ldx fm_bufidx
	lda pagebuff,x
	ora #$80
	cpx fm_bufsz
	bcc fmTXT_ok
	jsr fill_TXT
	bcc fmr_txt
fmTXT_ok:
	inc fm_bufidx
	rts

fill_TXT:
	CALLOS mli_read, fm_readp
	CALLOS_BRANCH_NEG fm_readx
	lda #0
	sta fm_bufidx
	lda txtLEN
	sta fm_bufsz
.if IsDavex3
	clc
	rts
fm_readx:
	sec
	rts
.else
fm_readx:
	rts
.endif

;
; read 1 character from AWP file
;
fmr_awp:
	lda awp_blanks
	beq fmr_notbl
	dec awp_blanks
	lda #$a0
	clc
	rts
fmr_notbl:
	ldx fm_bufidx
	lda pagebuff+2,x
	ora #$80
	cpx fm_bufsz
	bcc :+
	jsr fill_awp
	bcc fmr_awp
:	inc fm_bufidx
	rts

;
; fill the AWP line buffer from file
;
fill_awp:
	lda fm_rref
	sta fill_ref
	sta awptext_ref
	CALLOS mli_read, fillp
	CALLOS_BRANCH_NEG filled
	lda awp_rec+1
	cmp #$D0	;CR record?
	beq awp_cr
	cmp #0
	bne fill_awp	;formatting rec--try again
	lda awp_rec
	sta awptext_len
	CALLOS mli_read, awptext
	pha
	ldx #0
	stx fm_bufidx
	lda pagebuff+1
	and #$7f
	sta fm_bufsz
	inc fm_bufsz
	tax
	lda #_'M'-ctrl
	sta pagebuff+2,x
	lda pagebuff
	sta awp_blanks
	pla
filled:	rts

awp_cr:	lda #_'M'-ctrl
	sta pagebuff+2
	ldx #0
	stx fm_bufidx
	inx
	stx fm_bufsz
	clc
	rts

fillp:	.byte 4
fill_ref:
	.res 1
	.addr awp_rec
	.addr 2
	.addr 0
awp_rec:
	.res 2


awptext:
	.byte 4
awptext_ref:
	.res 1
	.addr pagebuff
awptext_len:
	.addr 0
	.addr 0

;**************************************
;
; 'eject' command for Davex
;
; Modified 31-Jan-88 DL
;   To do a Status(0) to determine the number of units
;   in the chain, rather than stopping when an error
;   occurs.  Apple's SCSI card does not behave as
;   expected when a unit number beyond the end of the
;   chain is used.
;
;**************************************
max_unit:	.byte 0
this_unit:	.byte 0
this_slot:	.byte 0

go_eject:
	sta p+1
	sty p
	lda #7
	sta this_slot
@ej1:	lda this_slot
	jsr eject_slot
	dec this_slot
	bne @ej1
	rts

;
; eject stuff from slot A if there's a SmartPort there
;
eject_slot:
	jsr isSmartPort
	bcs ejected_sl
	jsr CalcSP
	jsr GetMaxU
	lda #1
	sta this_unit
ej2:
	lda this_unit
	cmp max_unit
	beq TryEjThis
	bcs ejected_sl
TryEjThis:
	lda this_slot
	ldx this_unit
	jsr eject_ax
	inc this_unit
	jmp ej2
ejected_sl:
	rts

CalcSP:
	lda this_slot
	ora #$c0
	sta callSP+2
	sta callSP2+2
	sta callSP3+2
	sta callSP4+2
	sta temp+1
	ldy #0
	sty temp
	ldy #$ff
	lda (temp),y
	clc
	adc #3
	sta callSP+1
	sta callSP2+1
	sta callSP3+1
	sta callSP4+1
	rts

;
; get the number of units in the chain
;
GetMaxU:
callSP4: jsr $ffff
	.byte 0		;status
	.addr maxu_p
	lda pagebuff	;unit count
	sta max_unit
	rts

maxu_p:	.byte 3,0
	.addr pagebuff
	.byte 0

;
; Eject unit (A=slot, X=unit) IF there's
; a UniDisk 3.5 or Apple 3.5 there and the
; volume name is one that we're supposd
; to eject.
;
; (TYPE=1 identifies a UniDisk 3.5 or Apple 3.5)
;
eject_ax:
	stx ej_unitnm
	stx stat_unitnm
; x=unit#
	lda this_slot
	jsr ej_decide
	bcs ejected
	jsr CanEject
	bcs ejected
;
callSP:	jsr $ffff
	.byte 4
	.addr EjParms
ejected:
	rts

;
; CanEject -- return CLC if unit is ejectable (TYPE=1)
;
CanEject:
callSP2: jsr $ffff
	.byte 0	;status
	.addr spstat_p
	bcs cant_ej	;error $11 (invalid unit) should occur eventually

	lda pagebuff+21
	cmp #1
	beq yes_ej
cant_ej:
	sec
	rts
yes_ej:	clc
	rts

spstat_p:
	.byte 3
stat_unitnm:
	.byte 0
	.addr pagebuff
	.byte 3		;get DIB

;
; ej_decide (A=slot, X=unit) CLC = eject this disk
;
ej_decide:
	stx rb2unit
	ldy #0
	lda (p),y
	bne callSP3
	clc	;null name --> eject all
	rts

callSP3: jsr $ffff
	.byte 1	;readblock
	.addr ej_rb2
	bcs decid_no
	lda #_'/'
	sta pagebuff+1
	lda filebuff+4
	and #%00001111
	tax
	inx
	stx pagebuff
ejBldN:	dex
	beq ejBilt
	lda filebuff+4,x
	jsr downcase
	sta pagebuff+1,x
	jmp ejBldN
ejBilt:

	jsr pmgr
	.byte pm_slashif
	.addr pagebuff
	lda p+1
	ldy p
	sta ejslif+1
	sty ejslif
	jsr pmgr
	.byte pm_slashif
ejslif:	.addr 0

	ldy #0
	lda (p),y
	tax
	cmp pagebuff
	bne decid_no
:	iny
	dex
	beq decid_yes
	lda (p),y
	jsr downcase
	cmp pagebuff,y
	beq :-
decid_no:
	sec
	rts
decid_yes:
	clc
	rts

ej_rb2:	.byte 3
rb2unit:
	.byte 0
	.addr filebuff
	.byte 2,0,0	;block #

;
; isSmartPort -- return SEC if no card in slot A
;
isSmartPort:
	cmp #8
	bcs ispNO
	cmp #0
	beq ispNO
	ora #$C0
	sta temp+1
	lda #0
	sta temp
	ldy #1
	lda (temp),y
	cmp #$20
	bne ispNO
	ldy #3
	lda (temp),y
	bne ispNO
	ldy #5
	lda (temp),y
	cmp #3
	bne ispNO
	ldy #7
	lda (temp),y
	bne ispNO
	clc
	rts
ispNO:	sec
	rts
;
EjParms:
	.byte 3
ej_unitnm:
	.byte 0
	.addr EjCtrl
	.byte 4
EjCtrl:	.addr 0


;*********************************************
;
; ERR.TEXT for ProDOS and Davex errors
;
;*********************************************
;
; Format:
;   Code*1, String $00
;   Code*1, String $00 ...
;   $00
;
; Codes for ProDOS are $00..$7F
; Codes for Davex  are $80..$FF
;
;**********************************************
.macro	ErrorEntry byte, string
	.byte byte
	asc_hi string
	.byte 0
.endmacro
;**********************************************
err_text:
	ErrorEntry $2f, "no disk"
	ErrorEntry err_badcall, "bad ProDOS call"
	ErrorEntry err_badcnt, "bad pcount"
	ErrorEntry err_ifull, "inttbl full"
	ErrorEntry err_io, "disk I/O"
	ErrorEntry err_nodev, "no device connected"
	ErrorEntry err_wrprot, "disk write-protected"
	ErrorEntry err_switched, "disk switched"
	ErrorEntry err_2slow, "drive too slow"
	ErrorEntry err_2fast, "drive too fast"
	ErrorEntry err_pnsyntax, "bad pathname syntax"
	ErrorEntry err_fcbfull, "FCB full"
	ErrorEntry err_ivlref, "bad refnum"
	ErrorEntry err_dirnotfnd, "directory not found"
	ErrorEntry err_volnotfnd, "volume not found"
	ErrorEntry err_filnotfnd, "file not found"
	ErrorEntry err_dupfil, "duplicate file"
	ErrorEntry err_full, "volume full"
	ErrorEntry err_dirfull, "directory full"
	ErrorEntry err_filfmt, "file format error"
	ErrorEntry err_strgtype, "bad storage type"
	ErrorEntry err_eof, "end of file"
	ErrorEntry err_badpos, "bad file pos"
	ErrorEntry err_locked, "file locked"
	ErrorEntry err_filopen, "file open"
	ErrorEntry err_dircnt, "dir count"
	ErrorEntry err_notprodos, "volume is not ProDOS"
	ErrorEntry err_ivlparm, "invalid param"
	ErrorEntry err_vcbtfull, "VCB full"
	ErrorEntry err_badbufadr, "bad buff addr"
	ErrorEntry err_dupvol, "duplicate volume"
	ErrorEntry err_badmap, "baked bit-map"
;=======================================
;
; Part II of error table:  Davex errors
;
	ErrorEntry der_illegparm, "illegal option"
	ErrorEntry der_toomany, "too many parameters"
	ErrorEntry der_badtype, "bad parm type"
	ErrorEntry der_unknftyp, "unknown filetype"
	ErrorEntry der_dupopt, "duplicate option"
	ErrorEntry der_baddev, "devnum format is .61"
	ErrorEntry der_abort, "aborted"
	ErrorEntry der_waitspool, "wait for files to print or use spool -z"
	ErrorEntry der_needs3, "filetype needs 3 chars"
	ErrorEntry der_missopt, "missing option"
	ErrorEntry der_badhware, "missing hardware"
	ErrorEntry der_badnum, "bad number"
	ErrorEntry der_bignum, "number too big"
	ErrorEntry der_ynexp, "'y' or 'n' expected"
	ErrorEntry der_nosbf, "no startup buffer"
	ErrorEntry der_smallsbf, "startup buffer too small"
	ErrorEntry der_notxtn, "not an external command"
	ErrorEntry der_adrlow, "cmd address too low"
	ErrorEntry der_notfnd, "not found"
	ErrorEntry der_semiexp, "missing ';'"
	ErrorEntry der_nottxt, "not script file"
	ErrorEntry der_notdir, "not DIR"
	ErrorEntry der_levels, "too many dir levels"
	ErrorEntry der_1wild, "1 wildcard only"
	ErrorEntry der_badwild, "bad wildcard"
	ErrorEntry der_outmem, "out of memory"
	ErrorEntry der_outroom, "out of room"
;====================================
	.byte 0


;
; 'filetypes' -- default filetypes for Davex
;
; Last mod 24-Mar-90 DAL (March 1990 File Type notes)
;
filetyp0:
	.byte $01,$03,$04,$06,$08,$0B,$0F,$16
	.byte $19,$1A,$1B,$20,$2a,$2b,$2c,$2d
	.byte $2e,$42,$50,$51,$52,$53,$54,$55
	.byte $56,$57,$58,$59,$5a,$5b,$5c,$5d
	.byte $5e,$6b,$6d,$6e,$6f,$a0,$ab,$ac
	.byte $ad,$b0,$b1,$b2,$b3,$b4,$b5,$b6
	.byte $b7,$b8,$b9,$ba,$bb,$bc,$bd,$bf
	.byte $c0,$c1,$c2,$c3,$c5,$c6,$c7,$c8
	.byte $c9,$ca,$d5,$d6,$d7,$d8,$db,$e0
	.byte $e2,$ee,$ef,$f0,$f9,$fa,$fb,$fc
	.byte $fd,$fe,$ff
	.byte $00

fileasc0:
	asc "badptxtxtbinfotwpfdirpfs"
	asc "adbawpasptdmsc8ob8ic8ld8"
	asc "p8cftdgwpgssgdbdrwgdphmd"
	asc "edustnhlpcomcfganmmument"
	asc "dvubiotdrprehdvwp gsbtdf"
	asc "bdfsrcobjlibs16rtlexepif"
	asc "tifndacdatoldvrldffstdoc"
	asc "pntpicanipaloogscrcdvfon"
	asc "fndicnmusinsmdisnddbmlbr"
	asc "atkr16pascmdos intivrbas"
	asc "varrelsys"
listend:

;
; talkstuff -- misc routines for speech (Textalker, Echo II)
;
; Last mod 28-Jul-87 DL
;
hook_speech:
	jsr hook_ispeech
	jsr hook_ospeech
	jsr is_txtt
	beq ini_tt
	jsr is_slotb
	beq ini_sb
	rts
; init textalker
ini_tt:	ldx #$ff
	stx $37d
	ldy $c01f
	lda $bf98
	jsr $3a9
	rts
; init SCAT
ini_sb:
	lda #0
	jsr $3b2
	rts

hook_ispeech:
	jsr hooki2
	lda ksw+1
	ldy ksw
	sta speechi+1
	sty speechi
	rts

hooki2:
	jsr is_txtt
	beq hooki_tt
	jsr is_slotb
	bne no_speek
; hook in SlotBuster ($3ac)
	lda #3
	sta ksw+1
	lda #$ac
	sta ksw
	lda #$ff
	sta speech
	rts

hooki_tt:
	lda #3
	sta ksw+1
	lda #$a9
	sta ksw
	lda #$ff
	sta speech
	rts
no_speek:
	lda #0
	sta speech
	rts

hook_ospeech:
	jsr is_txtt
	beq hooko_tt
	jsr is_slotb
	bne no_speek
; hook out slotbuster == same as textalker ($3A6)
hooko_tt:
	lda #3
	sta csw+1
	lda #$a6
	sta csw
	lda #$ff
	sta speech
	rts
;
; is_txtt -- return BEQ if TextTalker routines present
;
is_txtt:
	lda $3a6
	cmp #$ee
	bne isttx
	lda $3a9
	cmp #$8e
isttx:	rts

;
; is_slotb -- return BEQ if SlotBuster II routines present
;
is_slotb:	lda #$d8
	cmp $3a6
	bne issbx
	cmp $3ac
issbx:	rts

;
; load Textalker from disk
;
no_tt:	rts

load_txttalk:
	lda $bf98
	and #$30
	cmp #$30
	bne no_tt
	lda #$60	; this makes PT_OBJ load into AuxMem at $01/6000.
	sta ttcheat+2
	jsr is_slotb
	beq no_tt
; if Apple down, force reload PT_OBJ
	bit button0
	bmi loadtt
	jsr is_txtt
	beq no_tt
loadtt:	lda #>tt_name
	ldy #<tt_name
	jsr build_local
	sta tt_open+1
	sty tt_open
	CALLOS mli_open, tt_openp
	CALLOS_BRANCH_NEG no_tt

	lda tt_ref
	sta tt_read+1

	ldx #$3cf-$380
cp3tt:	lda tt3img,x
	sta $380,x
	dex
	bpl cp3tt

readtt:	CALLOS mli_read, tt_read
	CALLOS_BRANCH_POS ttrok
	cmp #err_eof
	beq ttdone
	jmp ProDOS_err
ttrok:	sty $c005	; $C005	W	RAMWRTON	Write enable aux memory from $0200-$BFFF
	ldy #0
ttr2:	lda pagebuff,y
ttcheat: sta $ff00,y
	dey
	bne ttr2
	sty $c004	; $C004	W	RAMWRTOFF	Write enable main memory from $0200-$BFFF
	inc ttcheat+2
	jmp readtt

ttdone:	lda tt_ref
	jsr close

	lda #$ff
	sta $37d
	lda $bf98
	ldy $c01f
	jsr $3a9

	jsr mess
	.byte $85,_'C',0	;compressed speech (fast)
	rts

tt3img:
	.byte $e3
	ldx #0
	.byte $8e,$7d,$03,$ae,$7f,$03,$86,$eb
	ldx $380
	stx $ec
	ldx $3cf
	txs
	ldx $3ce
	jmp $c307
	cld
	inc $37d
	cld
	inc $37d
	cld
	inc $37d
	inc $37d
	stx $3ce
	tsx
	stx $3cf
	ldx $eb
	stx $37f
	ldx $ec
	stx $380
	ldx $37d
	stx $eb
	clv
	sec
	ldx #0
	stx $3ed
	ldx #$60
	stx $3ee
	jmp $c314
	.byte $02,$f2

tt_openp:
	.byte 3
tt_open:
	.addr 0
	.addr filebuff
tt_ref:	.byte 0

tt_read:
	.byte 4
	.byte 0
	.addr pagebuff,$100,0

tt_name: pstr "PT.OBJ"

;
; Revised 23-Jan-90 DAL for Davex 1.25
;   for $300 bytes of Aliases space (was $200)
;
;*********************************************************
;
; alias -- routines for 'alias' command and alias
;          expansion
;
;*********************************************************
;
; There are 3 pages reserved for aliases as "Aliases".
;
; The format is simple: an image of a text file, with
; RETURNs between lines, and a $00 at the end.
;
; The file (%aliases) has one alias per line; the first
; word (everything up to the first blank or the end
; of line) is the key, and the rest is the alias (what
; the alias gets "expanded" into).
;
;*********************************************************
;
; init_alias gets called once when Davex is entered.  It
;            loads an image of %aliases to Aliases (or
;            just puts the terminating $00 there if the
;            file can't be read)
;
; exp_alias  gets called whenever a possible alias needs
;            to be expanded; AY = address of string, and
;            there is a length byte just before it.
;
;*********************************************************

;*********************************************************
;
; called once--load %Alias file
;
init_alias:
	lda #0
	tax
InitA1:	sta Aliases,x
	sta Aliases+$100,x
	sta Aliases+$200,x
	dex
	bne InitA1

	lda #>AliasName
	ldy #<AliasName
	jsr build_local
	sta aPath+1
	sty aPath

	CALLOS mli_open, OpenA
	CALLOS_BRANCH_NEG InitA_dun
	lda aRef
	sta aRef2

	CALLOS mli_read, ReadA
	CALLOS_BRANCH_NEG InitA_dun

	ldx #0
Strip7:	lda Aliases,x
	and #%01111111
	sta Aliases,x
	lda Aliases+$100,x
	and #%01111111
	sta Aliases+$100,x
	lda Aliases+$200,x
	and #%01111111
	sta Aliases+$200,x
	dex
	bne Strip7

	lda aRef
	jmp close
InitA_dun:
	rts

AliasName: pstr "aliases"

;*********************************************************
;
; Called for each command on line; pointer to string in
; AY.  The string should be expanded IN PLACE and has a
; maximum length of 250.
;
; The string is zero-terminated AND has a length byte
; just before the address passed in AY.
;
; Return with SEC if no expansion was done, CLC if it was.
;
exp_alias:
	sta p+1
	sty p
	lda #>Aliases
	ldy #<Aliases
	sta p2+1
	sty p2
; a Tilde prevents expansion
	ldy #0
	lda (p),y
	ora #$80
	cmp #_'~'
	beq isTilde
ExpA1:	ldy #0
	lda (p2),y
	beq ExpDone
	jsr MaybeExp
	bcc DidExpand
	jsr NextAlias
	jmp ExpA1
ExpDone:
	sec
DidExpand:
	rts

isTilde:
	lda p
	bne :+
	dec p+1
:	dec p
	jsr KillOneChar
	sec
	rts

FetchChar:
	inc p2
	bne :+
	inc p2+1
:	ldy #0
	lda (p2),y
	ora #%10000000
	rts

NextAlias:
	jsr FetchChar
	cmp #$8d
	beq FetchChar
	and #%01111111
	bne NextAlias
	rts

MaybeExp:
	ldy #0
Comp:	lda (p),y
	beq SourceEnd
	jsr downcase
	cmp #_';'
	beq SourceEnd
	cmp #_' '
	beq SourceEnd
	sta temp
	lda (p2),y
	jsr downcase
	cmp temp
	bne NoMatch
	iny
	bne Comp

NoMatch:
	sec
	rts

;
; Hit end of word in input; if also at end of word in
; the alias, we have a match!
;
SourceEnd:
	lda (p2),y
	jsr downcase
	cmp #_' '
	beq YesMatch
	cmp #$8d
	beq YesMatch
	sec
	rts

;
; Remove original text from line & insert alias text one
; character at a time.
;
NullAlias:
	clc
	rts

YesMatch:
	lda p
	bne :+
	dec p+1
:	dec p

	sty temp
KillOld:
	jsr KillOneChar
	dey
	bne KillOld

	ldy temp
	lda (p2),y
	beq NullAlias
	ora #%10000000
	cmp #$8d
	beq NullAlias

	ldy temp
SrchEnd:
	iny
;beq out_room?
	lda (p2),y
	beq InsertExp
	ora #%10000000
	cmp #$8d
	bne SrchEnd

InsertExp:
;inc temp
	dey
Insert1:
	lda (p2),y
	jsr InsertOne
	dey
	cpy temp
	bcs Insert1

KillBlanks:
	ldy #1
	lda (p),y
	ora #$80
	cmp #_' '
	bne :+
	jsr KillOneChar
	jmp KillBlanks
:	clc
	rts


KillOneChar:
	tya
	pha
	ldy #0
	lda (p),y
	sec
	sbc #1
	sta (p),y
:	iny
	iny
	lda (p),y
	dey
	sta (p),y
	cpy #252
	bcc :-
	pla
	tay
	rts

InsertOne:
	sty I1y
	pha
	ldy #0
	lda (p),y
	cmp #250
	bcs @full
	ldy #250
:	lda (p),y
	iny
	sta (p),y
	dey
	dey
	bne :-
; shifted all characters; now inc length
	lda (p),y
	clc
	adc #1
	sta (p),y
; and store the new 1st character
	pla
	ora #$80
	iny
	sta (p),y
	ldy I1y
	rts

@full:	lda #der_outroom
	jmp ProDOS_err

I1y:	.byte 0

;*********************************************************

;*********************************************
;
; Davex help command
;
;*********************************************
bits:	.res 1
ViewName = xczpage
path	= xczpage+2
;
; help command
;
go_help:
	sta p+1
	sty p
	ldy #0
	lda (p),y
	bne help_str

	jsr mess
	.byte cr
	asc "(Use  ? ?  and ?topics for more info.)  Built-in commands:"
	.byte cr,cr,0
	jsr point_cmdtbl
	lda #0
	sta temp
help1:	lda cmd_ptr+1
	ldy cmd_ptr
	jsr print_str
	jsr pr_sp
	inc temp
	lda temp
	clc
	adc #10
	cmp scr_width
	bcc helpl
	jsr crout
	lda #0
	sta temp
helpl:	jsr point_nxtcmd
	bne help1
	jmp crout
;
; help_str -- help cmd has non-null arg
;
help_str:
 .if  0   ;*** expand Help aliases
	lda p+1
	pha
	lda p
	pha
	ldy p
	lda p+1
	iny
	jsr exp_alias
	pla
	sta p
	pla
	sta p+1
 .endif

	ldy #0
	lda (p),y
	tay
	inc p
	lda #0
	sta (p),y
;
; check the help directory for a file with the
; same name
;
	jsr FindHelpDir
; append 0-term str to help dir path (in pagebuff)
	ldy #<-1
helpap:	iny
	lda (p),y
	beq hlpapd
	jsr pmgr
	.byte pm_appch
	.addr pagebuff
	jmp helpap
hlpapd:
;
; if file exists, do a 'pg' on it
;
	lda #>pagebuff
	ldy #<pagebuff
	jsr geti2
	bcs TryIndex

	lda #%11000000
	sta pause_flag	;b7
	sta filter	;b7
	sta case_flags	;b7,6
	lda #>pagebuff
	ldy #<pagebuff
	jmp more2

print_str:
	sta p+1
	sty p
	ldy #0
@loop:	lda (p),y
	beq :+
	ora #%10000000
	jsr cout
	inc temp
	iny
	bne @loop
:	rts

;*********************************************
TryIndex:
	lda #0
	jsr getparm_n
	jmp ViewFile

;*********************************************
;*********************************************
OpenFile:
	sta OpPath+1
	sty OpPath
	CALLOS mli_open, OpParms
	CALLOS_BRANCH_NEG OpFail
ofOK:	clc
	lda OpRef
.if IsDavex3
	clc
	rts
.endif
OpFail:
	cmp #err_filopen
	beq ofOK
.if IsDavex3
	sec
.endif
	rts
;*********************************************
;*********************************************
SeekIndex:
	sta EOFval+2
	stx EOFval+1
	sty EOFval
	CALLOS mli_setmark, EOFparms
	CALLOS_BRANCH_NEG si_fail
	rts

si_fail:
	jmp ProDOS_err

;*********************************************
read4:	CALLOS  mli_read, read4_p
	CALLOS_BRANCH_NEG si_fail
	lda four+2
	ldx four+1
	ldy four
	rts

read4_p:
	.byte 4
r4ref:	.res 1
	.addr four,4,0
four:	.res 4

;*********************************************

ComprTable:
	asc " etoaisrn"
	.byte $0D
	asc "ldhpcf"

byte:	.res 1

;*********************************************
;*********************************************
;
; View a file
;
IndexName:
	pstr "INDEXED.HELP"

vf_fail:
	jmp ProDOS_err
ViewFile:
	sta ViewName+1
	sty ViewName

	jsr FindHelpDir
	lda #>IndexName
	ldy #<IndexName
	jsr pmgr
	.byte pm_appay
	.addr pagebuff

	lda #>pagebuff
	ldy #<pagebuff
	jsr OpenFile
	bcs vf_fail
	sta r4ref
	sta EOFref
	lda #0
	tax
	ldy #$C
	jsr SeekIndex
	jsr read4
	jsr SeekIndex
search:	jsr ReadOneName
	bcs missing
	jsr CompareVN
	bne search
	jmp ViewThis

missing:
	jsr mess
	.byte cr
	cstr_cr "*** not found"
	jmp main_err

;*********************************************
ron_err:
	jmp ProDOS_err

ReadOneName:
	lda OpRef
	sta ron_ref1
	sta ron_ref2
	sta unp_ref
	CALLOS mli_read, ron_rd1
	CALLOS_BRANCH_NEG ron_err
	lda pagebuff
	bne ron_cont
	sec
	rts
ron_cont:
	clc
	adc #8
	sta ron_len
	CALLOS mli_read, ron_rd2
	CALLOS_BRANCH_NEG ron_err
	rts

ron_rd1:
	.byte 4
ron_ref1:
	.res 1
	.addr pagebuff,1,0

ron_rd2:
	.byte 4
ron_ref2:
	.res 1
	.addr pagebuff+1
ron_len:
	.addr 0,0

;*********************************************
CompareVN:
	ldy #0
	lda (ViewName),y
	cmp pagebuff
	bne cvn_no
	tay
cvn1:	lda (ViewName),y
	jsr downcase
	and #%01111111
	cmp pagebuff,y
	bne cvn_no
	dey
	bne cvn1
cvn_no:	rts

;*********************************************
vt_fail:
	jmp ProDOS_err

ViewThis:
	ldx pagebuff
	lda pagebuff+1,x
	sta EOFval
	lda pagebuff+2,x
	sta EOFval+1
	lda pagebuff+3,x
	sta EOFval+2
	lda OpRef
	sta EOFref
	CALLOS mli_setmark, EOFparms
	CALLOS_BRANCH_NEG vt_fail

	lda #0
	sta bits
	lda #23
	sta line_count
View1:	jsr UnpackChar
	bcs viewed
	cmp #$8D
	bne not_cw
	jsr check_wait
	jsr NextLine
	beq viewed
	jsr crout
	jmp View1
not_cw:	jsr cout
	jmp View1

viewed:	lda OpRef
	jmp close

;*********************************************
unpack_err:
	jmp ProDOS_err
UnpackChar:
	jsr GetBit
	bcs unp_packed

	lda #0
	ldx #7
unp_u1:	pha
	txa
	pha
	jsr GetBit
	pla
	tax
	pla
	rol a
	dex
	bne unp_u1
	cmp #0
	beq :+
	ora #%10000000
	clc
:	rts

unp_packed:
	lda #0
	ldx #4
unp_p1:	pha
	txa
	pha
	jsr GetBit
	pla
	tax
	pla
	rol a
	dex
	bne unp_p1
	tax
	lda ComprTable,x
	ora #%10000000
	clc
	rts

;*********************************************
GetBit:	ldy bits
	bne have_bit
	CALLOS mli_read, unpack1
	CALLOS_BRANCH_NEG unpack_err
	lda #8
	sta bits
have_bit:
	asl byte
	dec bits
	rts

unpack1:
	.byte 4
unp_ref:
	.res 1
	.addr byte
	.addr 1,0

;*********************************************
FindHelpDir:
	jsr pmgr
	.byte pm_copy
	.addr cfghelp,pagebuff
	lda p+1
	pha
	lda p
	pha
	lda #>pagebuff
	ldy #<pagebuff
	jsr fixup_path_ay
	jsr pmgr
	.byte pm_slashif
	.addr pagebuff
	pla
	sta p
	pla
	sta p+1
	rts

;*********************************************
NextLine:
	dec line_count
	bne no_stop
	lda #23
	sta line_count
	lda #0
	jsr redirect
	asl a
	bcs no_stop
	jsr suspend
	jsr TalkCont
	jsr mess
	.byte cr
	cstr "--- more"
	lda #_'y'	;default = Yes
	jsr yesno2
	jmp restore	;(preserves P)

no_stop:
	lda #1
	rts

.if 0
;---------------------------------------------------------
; dumphex: Dump out successive bytes of a memory range, given an address
; dumphex_ptr: Dump out successive bytes of a memory range, given a pointer to be dereferenced first
; Input - Byte immediately following call is the length
;         Addr immediately following that is the pointer to memory to dump
; Output - text on the screen, processor environment is preserved
;---------------------------------------------------------
dumphex:
	jsr dumphex_stash
	lda #$01
	sta dumphex_mode
	bne dumphex_go	; Always	
dumphex_ptr:
	jsr dumphex_stash
	lda #$00
	sta dumphex_mode
dumphex_go:
	pla		; Return address is on the stack - which we use to find parms
	clc
	adc #$01
	sta dump_ptr
	pla
	adc #$00
	sta dump_ptr+1
	ldy #$00
	lda (dump_ptr),y
	sta num		; First parm - length (byte) number of bytes to process
	iny
	lda (dump_ptr),y
	sta dump_ptr_2	; Second parm - pointer address (2 bytes) of memory to dump
	iny
	lda (dump_ptr),y
	sta dump_ptr_2+1

	clc		; Calculate return address
	lda #$02
	adc dump_ptr
	sta dump_ptr
	lda dump_ptr+1
	adc #$00
	pha		; Push return lsb
	lda dump_ptr
	pha		; Push return msb

	lda dumphex_mode
	bne @skip_deref
	ldy #$00		; Dereference the pointer - caller wants indirect addressing
	lda (dump_ptr_2),y
	sta dump_ptr
	iny
	lda (dump_ptr_2),y
	sta dump_ptr_2+1
	lda dump_ptr
	sta dump_ptr_2	; Put everything back into ptr for printing

@skip_deref:
	lda num
	beq @dump_done
	lda dump_ptr_2+1
	jsr prbyte
	lda dump_ptr_2
	jsr prbyte
	lda #_':'
	jsr cout
	lda num
	ldy #$00
:	lda (dump_ptr_2),y
	jsr prbyte
	lda #space
	jsr cout
	iny
	cpy num
	bne :-
	jsr crout
@dump_done:

dumphex_unstash:
	ldx sto_x
	ldy sto_y
	lda sto_p
	pha
	lda sto_a
	plp
	rts

dumphex_stash:
	sta sto_a	; Stash the world away
	sty sto_y
	stx sto_x
	php
	pla
	sta sto_p
	rts

sto_x:	.res 1
sto_y:	.res 1
sto_a:	.res 1
sto_p:	.res 1

dumphex_mode:
	.byte 0		; nonzero = second parm is a memory address (no dereference)
			; $00 = second parm is a pointer to be dereferenced 
.endif

;******************************************
;
; Tail of Davex
;
;******************************************
;
; These jumps are copied to high RAM once;
; the space may then be overwritten
;
jumps:	;after code
	jmp getparm_ch
	jmp getparm_n
	jmp mess
	jmp print_ftype
	jmp print_access
	jmp prdec_2
	jmp prdec
	jmp prdec_pad
	jmp print_path
	jmp build_local
	jmp print_sd
	jmp print_drvr
	jmp redirect
	jmp percent
	jmp yesno
	jmp mygetln
	jmp bell
	jmp downcase
	jmp plural
	jmp check_wait
	jmp pr_date_ay
	jmp pr_time_ay
	jmp ProDOS_err
	jmp ProDOS_er
	jmp main_err
	jmp prdec_pady
	jmp dir_setup
	jmp dir_finish
	jmp read1dir
	jmp pmgr
	jmp mmgr
	jmp poll_io
	jmp print_ver
	jmp push_level
	jmp fman_open
	jmp fman_read
	jmp rdchar	;v1.1
	jmp makedirt	;v1.1
	jmp getnump	;v1.1
	jmp yesno2	;v1.2
	jmp dir_setup2	;v1.23
	jmp shell_info	;v1.25
