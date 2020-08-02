;***********************************************
;***********************************************
;
; Davex by David A. Lyons
;
; Begun 31-Aug-85
;
;***********************************************
;
; Converted to ca65 09/2011 (from 1.30 source)
;  -Tabs set at 8 characters
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
;
; To do:
; -Remove Apple II+ support (shift-key mod, other weird keyboard support)
;
;***********************************************
.include "../Common/Globals.asm"
.include "../Common/Apple.globals.asm"
.include "../Common/Mli.globals.asm"
.include "../Common/Macros.asm"
;.include "m16.util2"

.segment	"CODE_2000"
.org		$2000	; Makes the listing more readable, though it doesn't really org the code - the linker does that.

;Davex	proc
;
; private globals
;
myBakVer	= $00
myversion	= $13
AuxVersion	= 0	; = 1.30
Proto	= 1
ShowSerialNumber	= 0
;
RemoteImp	= 0

;
more_space	= $7900
;
buff_spool	= more_space
buff_oredir	= buff_spool+$400
buff_iredir	= buff_oredir+$400
dirstack	= buff_iredir+$400
mydir_len	= dstkmax*dstk_recsiz+dirstack
mypath	= mydir_len+1
copybuff	= mypath+128
keepbuff	= copybuff
cbufflen	= highmem-copybuff
;
refSlot0	= $f0
cmdpath	= $280
;***********************************************
monitor	= $ff69
;***********************************************
;
; Startup buffer--holds name of autoexec file
;
start:	jmp start2
	.byte $ee,$ee,65
exec_pn:
	.byte 9
	asc "%autoexec"
	.res 55
;***********************************************
copyright:
	jsr xmess
	.byte cr,0
	jsr pDavexVer
	jsr xmess

 asc "Copyright (c) 1988-2020"
 .byte cr
 asc "by David A. Lyons (dlyons@netcom.com)"
 .byte cr,cr
 asc "  http://members.aol.com/DaveLyons/davex"
 .byte cr
 asc "Davex is Freeware."
 .byte cr
 asc "Davex 1.3 is Y2K compliant if you use ProDOS 8 2.0.3 or later."
	.if  Proto 
	.byte cr,cr
	asc "PROTOTYPE VERSION FOR TESTING ONLY; DO NOT DISTRIBUTE!"
	.endif
 .byte cr,0

 .if ShowSerialNumber 
	jsr pSer1
	jsr pDavexVer
	jmp pSer2
 .else
	rts
 .endif
;***********************************************
start2:	cld
	tsx		; Get a handle to the stackptr
	;stx top_stack	; Save it for full pops during aborts
	lda #stdlevel
	sta level
	lda #0
	sta redir_susplv
	sta redir_out
	sta redir_in
;
	ldx #mli_close
	jsr HistoryMgr
;
; copy JMPs for XCs
;
	ldx #0
initjmps:
	lda jumps,x
	sta resources,x
	dex
	bne initjmps
;
; do SYS program stuff--clear bitmap, etc.
; trap RESET, turn on 80-col card if present
;
	ldx #BitMapSize-1
	lda #0
init_bm:	sta bitmap,x
	dex
	bpl init_bm
	lda #%11001111
	sta bitmap+0
	lda #1
	sta bitmap+BitMapSize-1
;lda #1 ;ibakver is now RESERVED
;sta ibakver
	lda #myversion
	sta iversion
;
;	lda #$4c
;	sta $3d0	;language warm
;	sta $3d3	;language cold
;	sta $3f8	;mon Ctrl-Y
;	sta $3fb
;	lda #>restart
;	ldy #<restart
;	sta $3d2
;	sty $3d1
;	sta $3d5
;	sty $3d4
;	sta $3fa
;	sty $3f9
;	sta reset+1
;	sty reset
;	jsr pwrdup
;
;	lda #>NMIouch
;	ldy #<NMIouch
;	sta $3fd
;	sty $3fc
;
	jsr FixRAMvect	;see SUBR
;
	lda machid
	and #%11000000
	cmp #%10000000
	beq two_e
	clc
two_e:	ror two_e_flag
	sec
	ror lc_flag
;
; compute xc_req here
;
	ldx #%10000000	;40 col always ok
	lda machid
	and #%00000010
	beq no80xc
	txa
	ora #%01000000
	tax
no80xc:	txa
	pha
	sec
	jsr $fe1f
	pla
	bcs no_IIgs
	ora #%00001000	;IIgs
; Make a QDVersion call (any call) so DiversiKey will
; hook itself in if we just rebooted
	pha
	.byte $18,$fb,$c2,$30
	.byte $48,$a2,$04,$04,$22,$00,$00,$e1,$68
	.byte $38,$fb
	pla
no_IIgs:
	tax
	lda machid
	and #%11000000
	cmp #%10000000
	bne no_IIe
	txa
	ora #%00100000
	tax
no_IIe:	lda machid
	and #%11001000
	cmp #%10001000
	bne no_IIc
	txa
	ora #%00010000
	tax
no_IIc:
	stx xc_req
;
	lsr spooling
	jsr find_mydir
	lda #0
	sta filetypes
	jsr load_globpg
	jsr init_alias
	jsr need_prefix
; copy default file types if none there
; lda filetyp
; bne ftyp_there
; jsr dflt_ftyps
;ftyp_there = *
;
	jsr load_txttalk	;load texttalker if available (%pt.obj)
;
; write current Quit code to %config if Davex's quit
; code is not already installed
;
	jsr write_quit
	jsr my_quit
 .if ShowSerialNumber 
	jsr pSer1
 .endif
;***********************************************
;
; RESTART (come here on RESET or Ctrl-Y or whatever)
;
restart:
	lda #0
	sta remslot	; %%% ?
	jsr on80
	jsr finish_oredir
;
	lda #0
	sta fudgeCR
	sta level
	sta redir_susplv
	sta redir_out
	sta redir_in
	jsr close
	jsr finish_iredir
;
	jsr spool_zap
	lda #0
	ldx #6
prclz:	sta SlotsOpen,x
	dex
	bpl prclz
;
	lda #-1
	sta dir_level
	lda #>dirstack
	ldy #<dirstack
	sta dstk_ptr+1
	sty dstk_ptr
;
; 1st time ONLY, 'exec %autoexec'
;
aexec:	jsr do_autoexec
	lda #$ad	;lda abs
	sta aexec
;
; Welcome msg
;
	jsr $fb2f
	jsr normal
	jsr clear_sc
wCheat:	jsr welcome
	lda #>wNotQuiet
	ldy #<wNotQuiet
	sta wCheat+2
	sty wCheat+1
;
fix_stack:
	ldx #$f8
	txs
	bne prompt	;always
time_pr:	jmp prompt	; Skip over clock stuff
	lda #0
	jsr xredirect
	bvs prompt
	bit fudgeCR	;5-Feb-90
	bpl noFudge	;5-Feb-90
	lsr fudgeCR	;5-Feb-90
	bpl prompt	;5-Feb-90
noFudge:	jsr print_time
prompt:
	lsr stepping
	lda #0
	jsr xredirect
	bvs no_cont
	jsr TalkCont	;turn voice back on (clear Ctrl-X)
	jsr restore80
no_cont:
	jsr finish_oredir
	lda #close_level
	sta level
	lda #0
	sta rep_count+1
	sta rep_count
	jsr close	;a=0
	lda #stdlevel
	sta level
	lda #-1
	sta dir_level
	jsr save_config
	cli	;for IIgs users
	lda #0
	sta $48	;mon P
	lda #0	;27-Jan-90
	jsr xredirect
	and #%11000000
	bne noGetlnCR
	jsr crout	;13-Jun-87
noGetlnCR:
	jsr getln
	cpx #0
	beq time_pr
;
	ldx #0
	stx parse_index
;
nextcmd:
	ldx #mli_close
	jsr xmmgr
;
	jsr munch_space
prompt0:	beq prompt
	cmp #$80+';'
	beq FoundSemi
;
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
;
	jsr parse_exec
;
	jsr chrgot
	beq prompt0
	cmp #$80+';'
	beq FoundSemi
;
	lda #der_semiexp
	jmp xProDOS_err
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
;
ExpandCount:
	.byte 0
;***********************************************
err:
	jsr finish_oredir
	jsr finish_iredir
	lda #0
	sta redir_susplv
	jsr xbell
	jmp fix_stack
;
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
; HERE IS WHERE TO DO 'APPL" STUFF.
;
	cmp #tDIR
	beq gotoDIR
	jsr run_something
	sec
	ror externalc
	clc
	rts
;
gotoDIR:
	jsr mli
	.byte mli_setpfx
	.addr gdParms
	bcc wentD
	jmp xProDOS_err
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
nullcmd:	rts
nullentr:	.byte $80+'x',0
	.addr nullcmd
	.byte 0,0	;no parms
;
gdParms:	.byte 1
	.addr cmdpath
;
; huh?
;
huh:
	jsr print_cmd
	jsr xmess

	asc ": huh?"

	.byte cr,nul
	jmp xerr
found_cmd:	rts
;
; parse a word (up to blank, semi, eol) to AY
;
parse_word:
	sta p+1
	sty p
	ldy #0
parsew1:	jsr chrgot
	beq pw_x
	cmp #$80+' '
	beq pw_x0
	cmp #$80+';'
	beq pw_x
	jsr xdowncase
	sta (p),y
	iny
	cmp #$80+'?'
	beq pw_x2
	cmp #$80+'-'
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
skipparm:	jsr adv_cmdptr	;pointing at addr+1
	jsr adv_cmdptr	;pointing at parm1
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
	jmp xprint_path
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
no_match:	rts
;
yes_match:	iny
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
ms0:
	jsr chrget
munch_space:
	jsr chrgot
	beq msx
	cmp #$80+' '
	beq ms0
msx:	jmp chrgot
;
parse_exec:
	jsr parse_cmd
	bcc execit
	jmp fix_stack
;
execit:	jsr parse_parms
;
; expand wildcards here & call routine
; until there are no more expandions
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
	sta level
	lda #0
	jsr xgetparm_n
	jsr jmpcmd
	jsr xcheck_wait
	bcc rep_noab
	jmp yn_abort
rep_noab:	lda #stdlevel
	sta level
	lda #0
	jsr close
	jsr restore80
;
; repeat until rep_count==0
;
	lda rep_count+1
	ora rep_count
	beq repeated
	lda rep_count
	bne nodec_rep
	dec rep_count+1
nodec_rep:	dec rep_count
	jmp rep_again
repeated:
;
; repeat cmd with next wildcard expansion
;
	jmp wild_again
;
wild_done:
	bit some_flag
	bmi did_some
	jsr xmess

	asc "(no files matched)"

	.byte cr,0
did_some:
	rts
;
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
;
find_parms:	jsr adv_cmdptr
	bne find_parms
	jsr adv_cmdptr	;pt at addr
	jsr adv_cmdptr	;pt at addr+1
	jsr adv_cmdptr	;pt at parm1
;
parseparms2:
	lda #0
	sta num_parms
	lda #-1	;don't confuse wildcards
	sta parmtypes
	sta parmtypes+1
;
	lda #>string_buffs
	ldy #<string_buffs
	sta strbuf+1
	sty strbuf
;
another:	jsr one_parm
	bcc another
	jsr chrgot
	beq sortprm
	cmp #$80+';'
	beq sortprm
	lda #der_toomany	;too many parameters
	jmp der
sortprm:	jsr bubble_parm
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
no_bubb:	inx
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
bub_swap:	lda parmtypes,x
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
swapcount:	.byte 0
;
; calc_pindex -- x=4*(num_parms-1)
;
calc_pindex:	pha
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
posit_parm:	ldy #0
	lda (cmd_ptr),y
	bne posit_done	;option character present
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
posit_done:	sec
	rts
;***********************************************
;
; parse a parameter (positional or optional)
;
one_parm:
	jsr munch_space
	beq posit_parm
	cmp #$80+'-'
	bne posit_parm
	jsr chrget
	bne opt_ok
	jmp illeg_parm	;"-" at end of line
opt_ok:	jsr xdowncase
	sta optchar
	jsr chrget	;point to char after option
;jsr munch_space ;24-Jan-90 DL
	ldy #0
chk_allowed:	iny
	lda (cmd_ptr),y
	dey
	cmp #0
	bne p_legal
	lda (cmd_ptr),y
	bne p_legal
	jmp illeg_parm
p_legal:	lda (cmd_ptr),y
	cmp optchar
	beq this_parm
	iny
	iny
	bne chk_allowed
this_parm:	iny
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
;
	jsr chrgot
	beq fudgex
	cmp #$80+'-'
	beq fudgex
	cmp #$80+';'
	beq fudgex
	ldx last_type
	bne fudgex
	cmp #$80+' '
	beq fudgex
; %%% multiple-flags disabled by removing next line
	jmp opt_ok
fudgex:	clc
	rts
last_type:	.byte 0
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
	jsr xgetparm_n
	jmp fixup_path_ay
;
pvax2:
	stx ptype
; record parm type in table
	pha
	txa
	ldy num_parms
	sta parmtypes,y
	pla
;
	beq pv_legal
	pha
	jsr xgetparm_ch
	pla
	bcc duplicated
;
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
;
parsers:
	.addr pv_done-1
	.addr pv_int-1
	.addr pv_int-1
	.addr pv_string-1	;path
	.addr pv_string-1	;wildpath
	.addr pv_string-1	;string
	.addr pv_int-1	;int1
	.addr pv_yesno-1
	.addr pv_ftype-1
	.addr pv_devnum-1
;
badtype:	lda #der_badtype
	bne der
;
pv_done:	clc
	rts
;
; duplicate parm -- given more than once
;
duplicated:	lda #der_dupopt
der:	jmp xProDOS_err
;
; illegal parameter
;
illeg_parm:	lda #der_illegparm
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
retval_x:	lda parms+3,x
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
	jmp xProDOS_err
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
	jsr xdowncase
	cmp #$80+'y'
	beq pv_yes
	cmp #$80+'n'
	beq pv_no
	lda #der_ynexp
	jmp xProDOS_err
pv_no:	lda #0
	beq pv_yn
pv_yes:	lda #-1
pv_yn:
	pha
	jsr calc_pindex
	pla
	sta parms+3,x
	jmp chrget
;
; parse an integer parameter (1, 2, or 3 bytes)
;
pv_int:
	lda #0
	sta num
	sta num+1
	sta num+2
	sta num+3
	jsr chrgot
	cmp #$80+'$'
	bne not_hex
	jmp hex_num
not_hex:
	jsr chk_dig
	bcs num_exp
;
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
num_ok:
	jsr chrget
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
num_ok2:	cpy #t_int1
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
;
num_exp:	lda #der_badnum
der3:	jmp xProDOS_err
;
overflow:	lda #der_bignum
	bne der3
;
chk_dig:
	cmp #'9'+1+$80
	bcs chkdig_no
	cmp #$80+'0'
	bcc chkdig_no
	clc
	rts
chkdig_no:	sec
	rts
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
	jsr mult2num
	jsr mult2num
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
	sta num+3
	bcs overflow
mult2num:	asl num
	rol num+1
	rol num+2
	rol num+3
	bcs overflow
	rts
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
	clc
	adc num
	sta num
	bcc hnum_ok
	inc num+1
	bcc hnum_ok
	inc num+2
	bne hnum_ok
	jmp overflow
hnum_ok:
	jsr chrget
	jsr chk_hex
	bcc hex_1
	jmp return_chk
;
hex_exp:	lda #der_badnum
	jmp xProDOS_err
;
chk_hex:	jsr xdowncase
	cmp #$80+'0'
	bcc hex_x
	cmp #'f'+1+$80
	bcs hex_x
	cmp #'9'+1+$80
	bcc is_hex
	cmp #$80+'a'
	bcs is_hex0
hex_x:	sec
	rts
is_hex0:	sec
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
	cmp #$80+'-'
	beq strdun
	cmp #$A7
	beq gotqch
	cmp #$A2	;double quote
	bne pstr_1
gotqch:	sta quotechr
pstr_0:	jsr chrget
pstr_1:	jsr chrgot
	beq strdun
	ldx quotechr
	bne sep_allowed
; if unquoted, check for blank, ";", comma
	cmp #$80+' '
	beq strdun
	cmp #$80+','
	beq strdun0
	cmp #$80+';'
	beq strdun
	ldy ptype
	cpy #t_string
	beq sep_allowed
	cmp #$80+':'
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
strdun0:	jsr chrget
	beq strdun	;23-Feb-88
	cmp quotechr	;
	beq StrChar	;
strdun:	lda string_index
	ldy #0
	sta (p),y
	rts
;
typespec:	lda string_index
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
ftyp_int:	jsr pv_int
	lda num+1
	ora num+2
	beq ftyp_ok
	jmp overflow
ftyp_ok:	lda num
	sta num+2
	jmp return_num
;
pv_ftype:
	jsr munch_space
	cmp #$80+'$'
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
	jmp xProDOS_err
is3:
	jsr free_sbuff
	ldx #0	;index into filetyp
	lda #>fileasc
	ldy #<fileasc
	sta p2+1
	sty p2
	inc p
	bne ft1
	inc p+1
ft1:
chktyp1:	ldy #2
chktyp2:	lda (p),y
	jsr xdowncase
	sta temp
	lda (p2),y
	jsr xdowncase
	cmp temp
	bne chknextt
	dey
	bpl chktyp2
	lda filetyp,x
	sta num+2
	jmp return_num
;
chknextt:	inx
	clc
	lda p2
	adc #3
	sta p2
	bcc @p2ok
	inc p2+1
@p2ok:	lda filetyp,x
	bne chktyp1
;
	ldx #0	;index into filetyp0
	lda #>fileasc0
	ldy #<fileasc0
	sta p2+1
	sty p2
chktyp1b:	ldy #2
chktyp2b:	lda (p),y
	jsr xdowncase
	sta temp
	lda (p2),y
	jsr xdowncase
	cmp temp
	bne chknextt2
	dey
	bpl chktyp2b
	lda filetyp0,x
	sta num+2
	jmp return_num
;
chknextt2:	inx
	clc
	lda p2
	adc #3
	sta p2
	bcc p2ok2
	inc p2+1
p2ok2:	lda filetyp0,x
	bne chktyp1b
;
	lda #der_unknftyp
	jmp xProDOS_err
;
; parse a devnum value:   .sd
;
pv_devnum:
	jsr chrgot
	cmp #$80+'.'
	bne dvnerr
	jsr chrget
	cmp #$80+'1'
	bcc dvnerr
	cmp #$80+'8'
	bcs dvnerr
	and #%00001111
	asl a
	asl a
	asl a
	asl a
	sta temp
	jsr chrget
	cmp #$80+'1'
	bcc dvnerr
	cmp #$80+'3'
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
	jmp xProDOS_err
;***********************************************
;
; mess -- print an in-line message
;
mess:
	pla
	sta msgp
	pla
	sta msgp+1
	ldy #0
mess1:	inc msgp
	bne m2
	inc msgp+1
m2:	lda (msgp),y
	beq messx
	ora #%10000000
	jsr cout
	jmp mess1
messx:	lda msgp+1
	pha
	lda msgp
	pha
	rts
;
; getln -- print prefix and input a line of text
;
getln:
	lda #0
	jsr xredirect
	asl a
	bmi cmd_again
	jsr print_pfx
	jsr xmess
	asc ": "
	.byte 0
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
	beq ppfx0
	dec string2-1
ppfx0:	jmp xprint_path
;
; get_pfx
;
get_pfx:
	jsr mli
	.byte mli_getpfx
	.addr pfx_parms
	bcs ProDOS_err
	jsr xpmgr
	.byte pm_downcase
	.addr string2-1
	lda #>(string2-1)
	ldy #<(string2-1)
	rts
;
; set_pfx
;
set_pfx:
	jsr mli
	.byte mli_setpfx
	.addr pfx_parms
	bcs ProDOS_err
	rts
;
pfx_parms:	.byte 1
	.addr string2-1
;***********************************************
;
; ProDOS_err -- close files and print a message (A)
;
ProDOS_err:
	pha
	jsr normal
	jsr finish_iredir
	jsr finish_oredir
	lda #close_level
	sta level
	lda #0
	sta redir_susplv
	jsr close	;A=0
	lda #stdlevel
	sta level
	jsr xbell	;27-Jan-90
	pla
	jsr xProDOS_er
;jsr xbell
	jmp fix_stack
;
ProDOS_er:
	sta errcode
	bit speech
	bmi nostar
	jsr crout
	lda errcode
ProDOS_er2:
	sta errcode
	jsr xmess

	asc "*** "

	.byte 0
nostar:	bit errcode
	bmi nonpro_err
	jsr xmess

	asc "ProDOS "

	.byte 0
nonpro_err:
	lda errcode
	cmp #der_abort
	beq not_an_err
	jsr xmess
	asc "error: "
	.byte nul
not_an_err:
	lda #>err_text
	ldy #<err_text
	sta p+1
	sty p
;
pe_srch:
	ldy #0
	lda (p),y
	beq pe_notfnd
	cmp errcode
	beq pe_fnd
; Advance to next error
adv:	iny
	lda (p),y
	bne adv
	sec
	tya
	adc p
	sta p
	bcc p_okz
	inc p+1
p_okz:
	jmp pe_srch
;
pe_fnd:
	inc p
	bne pokz
	inc p+1
pokz:
	jsr print_p
	jmp crout
;
pe_notfnd:
	lda #$80+'$'
	jsr cout
	lda errcode
	jsr prbyte
	jmp crout
;
; bell -- ProDOS style or System, depending on cfgbell
;
sysbell:	lda #$87
	jmp cout
bell:
	lda cfgbell
	bne sysbell
	ldy #32
bell1:	lda #2
	jsr $fca8
	sta spkr
	lda #$24
	jsr $fca8
	sta spkr
	dey
	bne bell1
	rts
;
; print_p
;
print_p:
	ldy #0
pp1:	lda (p),y
	beq pp_x
	jsr cout
	iny
	bne pp1
pp_x:	rts
;
; upcase
;
upcase:
	ora #%10000000
	cmp #$80+'a'
	bcc uc_x
	cmp #'z'+1+$80
	bcs uc_x
	and #%11011111
uc_x:	rts
;
; downcase
;
downcase:
	ora #%10000000
	cmp #$80+'A'
	bcc dc_x
	cmp #'Z'+1+$80
	bcs dc_x
	ora #%00100000
dc_x:	rts
;***********************************************
;
; print_time -- print the date and time,
; if available
;
print_time:
	jsr mli
	.byte mli_gettime
	.addr $ffff	;no parameter list

; Validate the year setting, even if we'll display from the GS clock
	lda date+1
	lsr a
	cmp #100
	bcs badYearWarning
	jmp yearOK
badYearWarning:	jsr xmess
	asc "WARNING: Your system's clock driver year number is greater than 99, which"
	.byte cr
	asc "is wrong (use 0..39 for 2000..2039).  See ProDOS 8 Technical Note #xxx."
	.byte cr,0
yearOK:
	sec
	jsr $fe1f
	bcs pt2	;not IIgs
	lda cfgclock	;Use IIgs clock?
	bne doGSclk
pt2:
	lda date+1
	ldy date
	jsr xpr_date_ay
	lda time+1
	ldy time
	jsr xpr_time_ay
	jmp crout
;
doGSclk:
	lda #0
	tax
dgsc1:	sta pagebuff,x
	dex
	bne dgsc1
	clc
	.byte $fb ;xce
	.byte $c2,$30 ;rep #$30
	.byte $f4,0,0,$f4
	.byte <pagebuff
	.byte >pagebuff ;pushlong pagebuff
	.byte $a2,$03,$0f ;ldx #ReadASCIITime
	.byte $22,$00,$00,$e1 ;jsl tool
	sec
 .byte $fb ;xce
;**
;	machine m65816
;	clc
;	xce
;	rep #$30
;	pea 0
;	pea pagebuff
;	ldx #$0f03	;ReadASCIITime
;	jsl $e10000
;	sec
;	xce
;	machine m6502
;**
	ldx #$ff
dgsc2:	inx
	lda pagebuff,x
	beq gscx
	jsr cout
	jmp dgsc2
gscx:	jmp crout
;
; print date and time from AY
;
my_date:	.addr 0
my_time:	.addr 0
print_date_ay:
	sta my_date+1
	sty my_date
	ora my_date
	beq no_pdat
;
	jsr prdate0
	lda #space
	bit speech
	bpl *+4
	lda #$80+','
	jsr cout
	lda #space
	jmp cout
;
prdate0:
	lda my_date
	and #%00011111
	jsr two_decimal0
	jsr dt_hyph
	lda my_date+1
	pha
	ror a	;c=1 if month>7
	lda my_date
	rol a
	rol a
	rol a
	rol a
	and #%00001111	;month
	sta temp
	asl a
;clc
	adc temp
	tay
	jsr month_chr
	jsr month_chr
	jsr month_chr
	jsr dt_hyph
	pla	;glob_date+1
	lsr a
	jmp two_decimal
no_pdat:	jsr xmess
	asc "<no date>  "
	.byte 0
	rts
;
; print time from AY
;
print_time_ay:
	sta my_time+1
	sty my_time
;;;	lda my_time+1	;removed 2-Dec-99 DAL
	ora my_time
	beq no_ptim
;
	lda my_time+1
	cmp #12
	php
	bcc is_a_m
;sec
	sbc #12
is_a_m:	cmp #0
	bne not_midnight
	adc #11
not_midnight:
	jsr two_decimal0
;msb ON
	lda #$80+':'
	jsr cout
	lda my_time
	jsr two_decimal
	lda #space
	jsr cout
	lda #$80+'A'
	plp
	bcc really_a_m
	lda #$80+'P'
really_a_m:
	jsr cout
	jsr speech_space
	lda #$80+'M'
	jmp cout
no_ptim:	jsr xmess
	asc "        "
	.byte 0
rts0:	rts
;
month_chr:
	lda month_text-3,y
	iny
	bne date_chr
;
speech_comma:
	bit speech
	bpl rts0
	lda #$80+','
	bne date_chr
speech_space:
	bit speech
	bpl rts0
	bmi pr_spz
dt_hyph:	;msb ON
	lda #$80+'-'
	bit speech
	bpl date_chr
pr_spz:	lda #$80+' '
date_chr:
	jmp cout
;
two_decimal0:
	cmp #10
	bcs two_decimal
	pha
	jsr pr_sp
	pla
	ora #$80+'0'
	jmp cout
two_decimal:
	cmp #100
	bcc lesshund
	jsr xmess
	asc "??"
	.byte 0
	rts
lesshund:
	ldx #$80+'0'
two_lp:	cmp #10
	bcc time_prdec
;sec
	sbc #10
	inx
	bne two_lp
time_prdec:
	pha
	txa
	jsr date_chr
	pla
	ora #$80+'0'
	bne date_chr
	asc "???"
month_text:
	asc_hi "JanFebMarAprMayJunJulAugSepOctNovDec?????????"
;***********************************************
;
; clear screen and print title
;
clear_sc:
	lda #$80+'L'-ctrl
	jsr cout
	lda #0
	jsr xredirect
	bmi nohome
	jsr home
nohome:	rts
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

	.if ShowSerialNumber 
	jsr pSer2
	.endif

	jsr xmess
	.byte cr
	asc "Type ? for help, $ for Freeware notice."
	.byte cr,0
	jmp print_time
Quiet:	rts

pDavexVer:
	jsr xmess
	asc "Davex "
	.byte 0
	lda #myversion
	jsr xprint_ver
	lda #AuxVersion+$80+'0'
	jsr cout
	jsr xmess
	.if  Proto 
	asc "p"
	.endif
	asc "  "
	.byte 0
	rts
;***********************************************
 .if ShowSerialNumber 
SerNum:	.addr 0
;
pSer1:
	lda #>mypath_all
	ldy #<mypath_all
	jsr getinfo
	lda info_auxtype+1
	ldy info_auxtype
	sta SerNum+1
	sty SerNum
	rts
;
pSer2:
	jsr xmess
	asc "(Serial #"
	.byte 0
	lda SerNum+1
	ldy SerNum
	jsr xprdec_2
	jsr xmess
	asc ")"
	.byte 0
	rts
 .endif
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

;
io_mask:	.byte 0
;*********************************************************
;
; print_drvr
;
; takes command code in X; possible data in A
; returns SEC; A = error
;
; Command codes (X):
;
;   mli_open   Open a printer for output
;              (slot # in A, returns refnum or
;               error in A)
;
;   mli_open-$80 Open a slot for input
;              (slot # in A, returns refnum or
;               error in A)
;
;   mli_read   refnum in Y; returns ready status
;              in bit 0 of A
;
;   mli_read-$80 refnum in Y; returns clc,A=character
;              or sec,A=error.  sec,A=0 --> no character
;
;   mli_write  send character (in A) to printer
;              (refnum in Y)
;
;   mli_close  close a printer for output (refnum in Y)
;
;   mli_close-$80  close a slot for input
;

;refSlot0 = $f0
refSlot1	= $f1
refSlot7	= $f7

;
; Slots-open table:
;   $8x = open for output
;   $4x = open for input
;   $Cx = open for i/o
;   $x0 = closed
;   $x1 = Pascal 1.1 device
;   $x2 = CnC1/C0x0 device
;
SlotsOpen:
	.byte 0,0,0,0,0,0,0
tempref:	.byte 0
outmask:	.res 1
;
print_drvr:
	cpx #mli_write
	bne notwrite
;
; Write a character -- refnum in Y
;
	ldx #$7f
	stx outmask
; write_pasc11 = *
write_literal:
	sty tempref
	pha
	lda SlotsOpen-refSlot1,y
	and #%10000000
	beq bref0
	lda SlotsOpen-refSlot1,y
	and #%00001111
	cmp #2
	beq write_pll
	jsr set_pwrk
	ldy #$0f
	lda (prtrwrk),y
	sta PrWrite+1
	jsr calcxy
	stx PrWrite+2
	bit $cfff
	pla
	and outmask	;13-nov-88
PrWrite:	jsr $0000
	bit $cfff
	clc
	rts
;
write_pll:
; pha
	jsr set_pwrk
	ldy #$c1
waitrdy:	lda (prtrwrk),y	;$CnC1
	bmi waitrdy
	jsr calcxy
	pla
	and outmask
	sta $C080,Y
	clc
	rts
;
read_pll:
	jsr set_pwrk
	ldy #$c1
	lda (prtrwrk),y	;$CnC1
	rol a
	rol a
	and #1
	eor #1
	clc
	rts
;
notwrite:	cpx #mli_write-$80
	bne notwrlit
	ldx #$ff
	stx outmask
	bne write_literal
;
notwrlit:	cpx #mli_read
	bne notread
;
; read_pasc11 = *
	sty tempref
	lda SlotsOpen-refSlot1,y
	and #%11000000
	bne rd_refok
bref0:	jmp badref
rd_refok:
	lda SlotsOpen-refSlot1,y
	and #%00001111
	cmp #2
	beq read_pll
	jsr set_pwrk
	ldy #$10
	lda (prtrwrk),y
	sta PrRead+1
	jsr calcxy
	stx PrRead+2
	bit $cfff
	lda #0	;request OUTPUT status
PrRead:	jsr $0000	;return: SEC=ready
	bit $cfff
	lda #0
	rol a	;return to caller: bit0=ready
	clc
	rts
;
notread:
	cpx #mli_read-$80
	bne notread2
;
; read character from Pascal device--return SEC,A=0 if no char
;
	sty tempref	;for set_pwrk
	lda SlotsOpen-refSlot1,y
	and #%01001111
	cmp #%01000001	;input, pascal
	bne CantRead
	jsr set_pwrk
	ldy #$0e
	lda (prtrwrk),y
	sta PrRead2+1
	ldy #$10
	lda (prtrwrk),y
	sta PrStat2+1
	jsr calcxy
	stx PrRead2+2
	stx PrStat2+2
	bit $cfff
	lda #1
PrStat2:	jsr $0000
	bcc NoChars
	jsr calcxy
PrRead2:	jsr $0000
	bit $cfff
	cpx #1
	bcs CantRead
	rts
CantRead:	sec
	lda #err_io
	rts
NoChars:	sec
	lda #0
	rts
;
notread2:
	pha
	lda #$80
	sta io_mask
	txa
	bmi forOutput
	lsr io_mask
forOutput:	ora #$80
	tax
	pla
;
	cpx #mli_close
	bne notclose
;
; Close an output device by refnum (Y)
;
	cpy #refSlot1
	bcc badref
	cpy #refSlot7+1
	bcs badref
	lda io_mask
	eor #$ff
	and SlotsOpen-refSlot1,y
	sta SlotsOpen-refSlot1,y
	clc
	rts
;
notopen:
	lda #err_badcall
	sec
	rts
;
notclose:	cpx #mli_open
	bne notopen
; open an output device; A=slot number
	cmp #0
	bne PrNDflt
	lda print_slot
PrNDflt:	cmp #7+1
	bcs badref
	tay
	lda SlotsOpen-1,y
	and io_mask
	beq cont_open
; already open
	lda #err_filopen
	sec
	rts
;
badref:	lda #err_ivlref
	sec
	rts
;
cont_open:	;open--slot # in Y
	lda SlotsOpen-1,y
	and #%11000000
	beq cont_open2
; when opening for another mode, don't re-init
	lda SlotsOpen-1,y
	ora io_mask
	sta SlotsOpen-1,y
	tya
	clc
	adc #refSlot0
;clc
	rts
cont_open2:
	tya
	clc
	adc #refSlot0
	sta tempref
	jsr set_pwrk
;
; anything here?
;
	ldy #0
	ldx #0
	lda (prtrwrk),y
slotOK:	cmp (prtrwrk),y
	bne pdrvr_nodev
	dex
	bne slotOK
;
; make sure it doesn't autoboot (not a printer!)
;
	ldy #1
	lda (prtrwrk),y
	cmp #$20
	bne slOK2
	ldy #3
	lda (prtrwrk),y
	bne slOK2
	ldy #5
	lda (prtrwrk),y
	cmp #3
	beq pdrvr_nodev
slOK2:
;
; see if it's a Pascal 1.1 device
;
	ldy #$b
	lda (prtrwrk),y
	cmp #1
	bne open_pll
;
; open_pasc11 = *
	ldy #$d	;init
	lda (prtrwrk),y
	sta PrOpen+1
	jsr calcxy
	stx PrOpen+2
	bit $cfff
PrOpen:	jsr $0000
	bit $cfff
	lda #1
openz:	ldy tempref
	ora io_mask
	sta SlotsOpen-refSlot1,y
	tya
	clc
	rts
;
open_pll:	lda #2
	bne openz
;
;
pdrvr_nodev:	lda #err_nodev
	sec
	rts
;
;***********************************************
;
; From tempref, calculate $Cn in X and $n0 in Y
;
calcxy:
	pha
	sec
	lda tempref
	sbc #refSlot0
	pha
	ora #$c0
	tax
	pla
	asl a
	asl a
	asl a
	asl a
	tay
	pla
	rts
;
set_pwrk:	pha
	tya
	pha
	lda tempref
	sec
	sbc #refSlot0
	ora #$c0
	sta prtrwrk+1
	lda #0
	sta prtrwrk
	pla
	tay
	pla
	rts
;***********************************************
;
; prtr_char -- send char to printer
;
; (">" puts "prtr_char" in CSW)
;
prtr_char:
	sta thischar
	stx coutx
	sty couty
	pha
	clc
	lda remslot
	adc #refSlot0
	cmp redir_out
	bne notsusp
	lda #0
	lda redir_susplv
	beq notsusp
	pla
	pha
	jmp osusp
notsusp:
	clc
	lda remslot
	adc #refSlot0
	cmp redir_out
	bne no_echo_scrn
	pla
	pha
	ora #$80
	jsr goto_vid
no_echo_scrn:
	pla
	ldx #mli_write
	ldy redir_out
	jsr print_drvr
	lda thischar
	ora #%10000000
	cmp #$80+'M'-ctrl
	bne no_addlf
	lda #$80+'J'-ctrl
	ldx #mli_write
	ldy redir_out
	jsr print_drvr
coutdone:
no_addlf:	ldx coutx
	ldy couty
	lda thischar
	rts
goto_vid:	jmp (vid_csw)
; end of "printer"
;
;



x99:	.byte 0
exec_flag:	.byte 0
fudgeCR:	.byte 0
;***************************************************
;
; DAVEX I/O routines
;
rdchar0:	pla
rdchar:
	pha
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
;
rc_spch:	ldy $24
	stx x99
	lda ($28),y
	jsr x98
	ldx x99
	rts
x98:	jmp (ksw)
;
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
not_neat:	cmp #space
	bcs not_ctrlo
	and #%01111111
not_ctrlo:	rts
;
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
;
	lda invflg
	pha
	jsr inverse
	lda rc_temp
	jsr cout0
	jsr pr_bs
rc_l1:	lda $C000
	bmi h_key
	jsr poll_io
	jsr poll_inslot
	bcs rc_l1
	bcc h_key2
h_key:	sta $C010
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
	jsr xprint_drvr
	bcc pollichar
	cmp #0
	beq polled_in
	jmp xProDOS_err
pollichar:	ora #$80
polled_in:	rts
;
WasExec:	sec
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
not_tgl:	bit lc_flag
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
get_yn:
	lda #0	;no default response for this Y/N question
get_yn2:
	ora #$80
	sta yn_dflt
	bit speech
	bmi shortyn
	jsr xmess
	asc "? (y/n) "
	.byte nul
	jmp yn_l1
shortyn:	lda #$80+'?'
	jsr cout
yn_l1:	lda yn_dflt
	cmp #$80
	bne somedflt
	lda #space
somedflt:	jsr rdchar
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
use_yndflt:	cmp #$8d	;Return = default choice
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
pcmp_dun:	bcc pr_digit
;SEC
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
pr_digit:	cpy #0
	beq printit
	cpx #$80+'0'
	bne printit
	bit digit_flag
	bmi printit
	ldx #space
	bit pad_flag
	bmi printit2
	bpl printed
printit:	sec
	ror digit_flag
printit2:	txa
	jsr cout
printed:	dey
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
hist_level:	.byte 0
mygetln2:
	lda #0
	jsr xredirect
	asl a
	sta exec_flag	;bit 7
	ldx #0
	stx longest
	stx insert_mode
	lda #-1
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
	ldy $fbb3
	cpy #6
	bne noApple	;do we have a machine with an Apple key?
	ldy button0	;Apple key down?
	bpl noApple
	jmp doApple
noApple:	cmp #space
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
mg_err:	jsr xbell
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
	cpx #-1
	beq saywhen
	cpx xsave
	bcs ins_l1
	beq ins_l1
saywhen:	inc longest
no_insrt:	clc
ins_err:	pla
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
	jsr xdowncase
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
tglInsert:	lda insert_mode
	eor #$80
	sta insert_mode
	jmp mg_l1
;**********************
ctrly:	stx xsave	;truncate cmd lin at cursor
yblanks:	jsr pr_sp
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
mgfind_l1:	lda #$80+'>'
	jsr rdchar
	jsr upcase
	cmp #$80+'['-ctrl
	bne find_cont
	jmp mg_l1
find_cont:	stx xsave
find_l2:	inx
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
	cmp #-1
	bne ctrlrz
	lda #0
	sta hist_level
ctrlrz:
	inc hist_level
histtry:	dec hist_level
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
	cpy #-1
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
dl1_dun:	jsr pr_sp
	inx
dl_back:	jsr pr_bs
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
len_ok2:	lda string,x
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
pr_sp:
	lda #space
	bne print_a
pr_bs:
	lda #$80+'H'-ctrl
	bne print_a
print_a:	jmp cout
;
cout0:	cmp #space
	bcs coutnorm
	sty ysave
	jsr inverse
	ora #%01000000
	jsr cout
	jsr normal
	ldy ysave
	rts
coutnorm:	jmp cout
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
;jsr xdowncase ;11-Jun-89
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
pftfnd1:	lda fileasc,x
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
pftfnd2:	lda fileasc0,x
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
redir_x:	sta redtmp
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
	lda #-1
	jsr redirect
	pla
	plp
	rts
;************************************************
;
; begin_oredir -- start redirecting output
; to path in AY ("&" = printer)
;
redir_err:	jmp xProDOS_err
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
open_slA:	sta slotn
	ldx #mli_open
	jsr xprint_drvr
	bcc openSlOk
	clc
	lda slotn
	adc #refSlot0
	tay
	ldx #mli_close
	jsr xprint_drvr
	lda slotn
	ldx #mli_open
	jsr xprint_drvr
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
;
bord_file:
	jsr mli
	.byte mli_create
	.addr bordcr_p
	bcc bordcr
	cmp #err_dupfil
	beq bordcr
	jmp xProDOS_err
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
redir_err2:	jmp xProDOS_err
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
	jsr xprint_drvr
	bcc fordx
	jmp xProDOS_err
ford_file:	lda level
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
foc_err:	pha
	jsr finish_oredir
	pla
app_err:	jmp xProDOS_err
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
	sta append_ref
	jsr mli
	.byte mli_geteof
	.addr append_p
	bcs app_err
	jsr mli
	.byte mli_setmark
	.addr append_p
	bcs app_err
	rts
;app_err jmp xProDOS_err
;
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
firedrx:	rts

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
	jsr xprint_drvr
	bcs iFileEr
	rts
iFileEr:	jmp xProDOS_err
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
finished_i:	rts
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
	jmp xProDOS_err
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
;ldx keyx
;ldy keyy
	sec	;5-Feb-90
	ror fudgeCR	;5-Feb-90
	lda #$8d
	bne ThisIchr
;lda undercur
;jmp rdchar2 ;was jmp (ksw) 5-Jul-87

bird_er:
ich_er:	jmp xProDOS_err
file_ix:	lda #0	;cheat!
	ora #%10000000
ThisIchr:	ldx keyx
	ldy keyy
	rts
;
isusp:	ldx keyx
	ldy keyy
	lda undercur
; jmp my_rdchar
	jmp (speechi)	;5-Dec-87
;
undercur:	.res 1
ichar_p:	.byte 4
ichar_ref:	.res 1
	.addr file_ix+1
	.addr 1
	.addr 0

do_rem_in:	lda remslot
ird_Slot:
	ldx #mli_open-$80	;open for input
	jsr xprint_drvr
	bcs ich_er
	sta redir_in
	rts
;**************************************
;
; on80 -- turn on 80-col card if here
;
suspend80:
	.byte 0
on80:
	jsr $fe89
	jsr $fe93
	jsr $fb2f
	jsr home
	lsr suspend80
	lda #40
	sta scr_width
;
;jsr hook_speech
;
	lda machid
	and #%00000010
	beq no_80col
	lda cfg40	;
	bne no_80col	;
	lda machid
	and #%11001000
	cmp #%10001000
	bne not_2c
	bit $c060
	bmi no_80col	;80-col override by 80/40 switch
not_2c:
have_80:	lda #3
	jsr outport
	jsr crout
	asl scr_width	;make 40-->80
no_80col:
;
	jsr hook_speech	;30-Jul-87
;
	lda csw+1
	ldy csw
	sta vid_csw+1
	sty vid_csw
	jmp finish_iredir
;
; restore80 -- turn 80col back on if
; it was turned off
;
restore80:
	bit suspend80
	bpl ns80
	jsr TalkCont
	jsr xmess
	.byte cr
	asc "Hit a key: "
	.byte 0
	lda #$a0
	jsr rdchar
	jmp on80
ns80:	rts
;***********************************************
;
; CheckHC -- preserving A,X,Y, do a screen dump
;            if A="H" and the Apple Key is down
;            on a //e, //c, IIgs
;
;  Also allow Apple-space = linefeed,
;             Apple-rtn   = formfeed
;
;  Return CLC if a something was done.
;
hc_char:	.byte 0
CheckHC:
	sta hc_char
	pha
	tya
	pha
	txa
	pha
	ldy $fbb3
	cpy #6
	bne noHC
; not if input redirected! 27-Jan-90
	lda #0
	jsr xredirect
	bvs noHC
	bit fudgeCR	;5-Feb-90
	bmi noHC	;5-Feb-90 ('exec' ending)
;
	bit button0
	bpl noHC
	lda hc_char
	jsr xdowncase
	cmp #$80+'h'
	bne noHC1
	jsr HardCopy
	clc
	bcc hcExit
noHC1:	cmp #$80+' '	;Apple-space=linefeed
	bne noHC2
	jsr doLineFeed
	clc
	bcc hcExit
noHC2:	cmp #$80+'M'-ctrl	;Apple-return=formfeed
	bne noHC
	jsr doFormFeed
	clc
	bcc hcExit
noHC:	sec
hcExit:	pla
	tax
	pla
	tay
	pla
	rts
;***********************************************
HardCopy:
	ldx #mli_open
	lda #0	;slot=default
	jsr xprint_drvr
	bcs hcerr
	sta hcref
;
	lda $29
	pha
	lda $28
	pha
	lda $25
	pha
	lda $24
	pha
	lda #0
	sta $25
	sta $24
;
hc1:
	lda $25	;vertical position
	jsr $fbc1	;BASCALC
hc2:
	ldy $24	;horizontal position
	jsr fetch_ch
	jsr hcwrite
;
	inc $24
	ldy $24
	cpy scr_width
	bcc hc2
;
	lda #$8d
	jsr hcwrite
	lda #$8a
	jsr hcwrite
	lda #0
	sta $24
	inc $25
	lda $25
	cmp #24
	bcc hc1
;
	pla
	sta $24
	pla
	sta $25
	pla
	sta $28
	pla
	sta $29
hcClose:	ldx #mli_close
	ldy hcref
	jmp xprint_drvr
hcerr0:	plp
hcerr:	jsr xbell
	jmp xbell
hcref:	.byte 0
;
hcwrite:	ldx #mli_write
	ldy hcref
	jmp xprint_drvr
;
doLineFeed:	clc
	.byte $24
doFormFeed:	sec
	php
	ldx #mli_open
	lda #0
	jsr xprint_drvr
	bcs hcerr0	;pulls P & beeps
	sta hcref
	plp
	bcc doLF2
	lda #$8d
	jsr hcwrite
	lda #$8c
	jsr hcwrite
	jmp hcClose
doLF2:	lda #$8a
	jsr hcwrite
	jmp hcClose
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
	lda $c000
	cmp #$98	;Ctrl-X?
	bne tcX
	sta $c010
tcX:	rts
;***********************************************


;**************************************
;
; Davex command table and commands
;
;**************************************
;
; Do scan -i
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
cmdtbl:
	asc_hi "bye"
	.byte 0
	.addr go_quit
	.byte 0,0
;
	asc_hi "$"
	.byte 0
	.addr copyright
	.byte 0,0
;
	asc_hi "version"
	.byte 0
	.addr wNotQuiet
	.byte 0,0
;
	asc_hi "rep"
	.byte 0
	.addr go_repeat
	.byte 0,t_int2
	.byte 0,0
;
	asc_hi "config"
	.byte 0
	.addr go_config
	.byte $80+'p',t_int1
	.byte $80+'4',t_yesno
	.byte $80+'c',t_yesno
	.byte $80+'b',t_yesno
	.byte $80+'q',t_int1
	.byte $80+'h',t_string
	.byte 0,0
;
	asc_hi "como"
	.byte 0
	.addr go_como
	.byte 0,t_wildpath
	.byte 0,0
;
	asc_hi "exec"
	.byte 0
	.addr go_exec
	.byte 0,t_wildpath
	.byte 0,0
;
	asc_hi "prefix"
	.byte 0
	.addr go_prefix
	.byte 0,t_wildpath
	.byte 0,0
;
	asc_hi "boot"
	.byte 0
	.addr go_boot
	.byte $80+'s',t_int1
	.byte $80+'i',t_nil	;ice cold!
	.byte 0,0
;
	asc_hi "mon"
	.byte 0
	.addr go_mon
	.byte 0,0
;
	asc_hi "up"
	.byte 0
	.addr go_up
	.byte 0,0
;
	asc_hi "top"
	.byte 0
	.addr go_top
	.byte 0,0
;
	asc_hi "help"
	.byte 0
	.addr go_help
	.byte 0,t_string
	.byte 0,0
;
	asc_hi "?"
	.byte 0
	.addr go_help
	.byte 0,t_string
	.byte 0,0
;
	asc_hi "online"
	.byte 0
	.addr go_online
	.byte $80+'o',t_nil
	.byte 0,0
;
	asc_hi "cls"
	.byte 0
	.addr clear_sc
	.byte 0,0
;
	asc_hi "type"
	.byte 0
	.addr go_type
	.byte 0,t_wildpath
	.byte $80+'h',t_nil
	.byte $80+'f',t_nil
	.byte $80+'u',t_nil
	.byte $80+'l',t_nil
	.byte $80+'p',t_nil
	.byte $80+'t',t_string
	.byte 0,0
;
	asc_hi "pg"
	.byte 0
	.addr go_more
	.byte 0,t_wildpath
	.byte $80+'h',t_nil
	.byte $80+'f',t_nil
	.byte $80+'u',t_nil
	.byte $80+'l',t_nil
	.byte $80+'p',t_nil
	.byte $80+'t',t_string
	.byte 0,0
;
	asc_hi "rename"
	.byte 0
	.addr go_rename
	.byte 0,t_wildpath
	.byte 0,t_path
	.byte 0,0
;
	asc_hi "filetype"
	.byte 0
	.addr go_ctype
	.byte 0,t_wildpath
	.byte 0,t_ftype
	.byte $80+'x',t_int2
	.byte 0,0
;
	asc_hi "create"
	.byte 0
	.addr go_create
	.byte 0,t_path
	.byte 0,0
;
	asc_hi "dt"
	.byte 0
	.addr print_time
	.byte 0,0
;
	asc_hi "delete"
	.byte 0
	.addr go_del
	.byte 0,t_wildpath
	.byte $80+'u',t_nil
	.byte 0,0
;
	asc_hi "lock"
	.byte 0
	.addr go_lock
	.byte 0,t_wildpath
	.byte 0,0
;
	asc_hi "unlock"
	.byte 0
	.addr go_unlock
	.byte 0,t_wildpath
	.byte 0,0
;
	asc_hi "prot"
	.byte 0
	.addr go_prot
	.byte 0,t_wildpath
	.byte $80+'r',t_nil
	.byte $80+'w',t_nil
	.byte $80+'d',t_nil
	.byte $80+'n',t_nil
	.byte 0,0
;
	asc_hi "scan"
	.byte 0
	.addr go_scan
	.byte $80+'a',t_string
	.byte $80+'r',t_string
	.byte $80+'z',t_nil
	.byte $80+'i',t_string
	.byte 0,0
;
	asc_hi "cat"
	.byte 0
	.addr go_cat
	.byte 0,t_wildpath
	.byte $80+'a',t_string
	.byte $80+'t',t_nil
	.byte $80+'s',t_nil
	.byte $80+'f',t_ftype
	.byte $80+'i',t_nil
	.byte 0,0
;
	asc_hi "spool"
	.byte 0
	.addr go_spool
	.byte 0,t_wildpath
;dfb $80+'h',t_string ;header
;dfb $80+'l',t_int1 ;lines/page
;dfb $80+'w',t_int1 ;page width
	.byte $80+'x',t_int1	;cancel 1
	.byte $80+'z',t_nil	;zap (cancel all)
	.byte 0,0
;
	asc_hi "info"
	.byte 0
	.addr go_info
	.byte 0,t_wildpath
	.byte 0,0
;
	asc_hi "update"
	.byte 0
	.addr go_update
	.byte 0,t_wildpath
	.byte 0,t_wildpath
	.byte $80+'f',t_nil
	.byte $80+'b',t_nil
	.byte 0,0
;
	asc_hi "copy"
	.byte 0
	.addr go_copy
	.byte 0,t_wildpath
	.byte 0,t_wildpath
	.byte $80+'d',t_nil	;delete orig
	.byte $80+'f',t_nil	;force delete
	.byte $80+'b',t_nil	;clr bkup bit
	.byte 0,0
;
	asc_hi "move"
	.byte 0
	.addr go_move
	.byte 0,t_wildpath
	.byte 0,t_wildpath
	.byte $80+'f',t_nil	;force delete
	.byte 0,0
;
	asc_hi "touch"
	.byte 0
	.addr go_touch
	.byte 0,t_wildpath
	.byte $80+'b',t_yesno
	.byte $80+'d',t_yesno
	.byte $80+'i',t_yesno
	.byte 0,0
;
	asc_hi "dev"
	.byte 0
	.addr go_dev
	.byte $80+'r',t_devnum
	.byte $80+'a',t_devnum
	.byte $80+'z',t_nil
	.byte 0,0
;
	asc_hi "ftype"
	.byte 0
	.addr go_ftype
	.byte $80+'r',t_ftype
	.byte $80+'a',t_string
	.byte $80+'v',t_ftype
	.byte $80+'z',t_nil
	.byte 0,0
;*
; asc_hi "appl"
; .byte 0
; .addr go_appl
; .byte $80+'r',t_ftype
; .byte $80+'a',t_ftype
; .byte $80+'p',t_string
; .byte 0,0
;
	asc_hi "err"
	.byte 0
	.addr go_err
	.byte 0,t_int1
	.byte 0,0
;
	asc_hi "="
	.byte 0
	.addr go_equal
	.byte 0,t_wildpath
	.byte 0,t_path
	.byte 0,0
;
	asc_hi "size"
	.byte 0
	.addr go_size
	.byte 0,t_wildpath
	.byte 0,0
;
	asc_hi "echo"
	.byte 0
	.addr go_echo
	.byte 0,t_string
	.byte $80+'n',t_nil	;no CR
	.byte 0,0
;
	asc_hi "eject"
	.byte 0
	.addr go_eject
	.byte 0,t_path
	.byte 0,0
;
	asc_hi "wait"
	.byte 0
	.addr go_wait
	.byte 0,0
;
	asc_hi "num"
	.byte 0
	.addr go_num
	.byte 0,t_int3
	.byte 0,0
;
 .if RemoteImp 
	asc_hi "remote"
	.byte 0
	.addr go_remote
	.byte 0,t_int1
	.byte 0,0
 .endif
;*
; asc_hi "mem"
; .byte 0
; .addr go_mem
; .byte 0,0
;*
;
	.byte 0,0
;********************************************
notspool:
	bit spooling
	bmi ouchspool
	rts
ouchspool:	lda #der_waitspool
	jmp xProDOS_err
;********************************************
go_num:	sta num+2
	stx num+1
	sty num
	jsr xmess
	asc "  $"
	.byte 0
	lda num+2
	jsr $fdda
	lda num+1
	jsr $fdda
	lda num
	jsr $fdda
	jsr xmess
	asc " = "
	.byte 0
	jsr xprdec_3
	jmp crout
;********************************************
go_wait:
	bit spooling
	bpl wait_x
	jsr xpoll_io
	bit $c000
	bpl go_wait
	sta $c010
	jmp yn_abort
wait_x:	rts
;********************************************
s16_flag:	.byte 0
go_quit:
	clc
go_quit2:	ror s16_flag
	sta s16_name+1
	sty s16_name
	jsr notspool
	lda #0
	sta level
	jsr close
	jsr off80
	lda #$ff
	ldy #$59
	sta $3fd
	sty $3fc
;
	lda $3f3
	sta $3f4
; quitting to S16?
	bit s16_flag
	bmi quit_s16
;
	jsr get_quitcode
	jsr mli
	.byte mli_bye
	.addr bye_parms
	jmp xProDOS_err
bye_parms:	.byte 4,0,0,0,0,0,0
;
quit_s16:	jsr mli
	.byte mli_bye
	.addr quit2_parms
	jmp xProDOS_err
;
quit2_parms:	.byte 4,$ee
s16_name:	.addr 0
	.byte 0,0,0
;*********************************************
;
; boot [-s slot#] [-i]
;
;   -i = ice-cold boot (IIgs)
;
go_boot:	lda reset+1
	sta reset+2
; If IIgs, do what the ProDOS-16 PQUIT thinger does
; on 'Reboot system'
	sec
	jsr $fe1f	;CLC on IIgs
	bcs rb_NotGS
	sei
	lda #0
	.byte $8f,$35,$c0,$e0 ;sta $e0c035 = shadow
	sta $c047	;clear VBL/3_75Hz int flags
	sta $c041	;disable lots of ints
	lda #9
	sta $c039	;SCC channel A cmd reg
	lda #$c0
	sta $c039
; if -i, trash $5f in the Keyboard Micro's RAM
	lda #$80+'i'
	jsr xgetparm_ch
	bcs no_ice
	jsr ice_it
no_ice:
rb_NotGS:
;
	jsr off80
	jsr home
	lda normal
	lda #$80+'i'	;
	jsr xgetparm_ch	;
	bcc badslot	;
	lda #$80+'s'
	jsr xgetparm_ch
	bcc boot_slot
badslot:	jmp ($fffc)
boot_slot:	lda #0
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
;   clc
;   xce
;   rep #$30
;   lda #$0051
;   sta $0000
;   pea $0002  (send 2 bytes)
;   pea $0000
;   pea $0000
;   pea $0008  (write Micro RAM)
;   ldx #$0909 (send to ADB)
;   jsl $e10000    Stores $00 into $51 (Micro RAM)
;   sec
;   xce
;
ice_it:
	.byte $18,$fb,$c2,$30
	.byte $a9,$51,$00,$8d,0,0
	.byte $f4,2,0,$f4,0,0,$f4,0,0,$f4,8,0
	.byte $a2,9,9,$22,0,0,$e1
	.byte $38,$fb
	rts
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
	jsr notspool
	clc
mon2:	php
	jsr off80
	jsr home
	jsr normal
	plp
	bcc no_nmi
	jsr xmess
	asc "Ouch!"
	.byte cr,0
no_nmi:
	jmp monitor
;
; prefix <path>
;
go_prefix:
setthepfx:	sta pfxstradr+1
	sty pfxstradr
	jsr mli
	.byte mli_setpfx
	.addr pfxcmdparms
	bcc set_ok
	jmp xProDOS_err
set_ok:	rts
;
pfxcmdparms:	.byte 1
pfxstradr:	.res 2
;
; up -- leave a subdirectory
;
go_up:
	jsr get_pfx
	jsr xpmgr
	.byte pm_up
	.addr string2-1
	jmp set_pfx
;
; top
;
go_top:
	jsr get_pfx
	ldx string2-1
	beq topped
	ldy #0	;# slashes
countsl:	lda string2-1,x
	ora #$80
	cmp #$80+'/'
	bne cs_not
	iny
cs_not:	dex
	bne countsl
	cpy #3
	bcc topped
	jsr go_up
	jmp go_top
topped:	rts
;**********************************
;
; online command
;
msg_index:	.res 1
go_online:
	lda #>pagebuff
	ldy #<pagebuff
	sta p+1
	sty p
	jsr mli
	.byte mli_online
	.addr onl_parms
	bcc onl_ok
	jmp xProDOS_err
onl_ok:
;
; print slot, drive, name for each volume
;
	lda #0
vloop:	pha
	asl a
	asl a
	asl a
	asl a
	tay
	lda (p),y
	beq nextvol
	ldx #msg2-msg
	stx msg_index
	and #$0f
	bne normal_name
;
; error occured on this volume.  print
; err msg if 'not ProDOS volume' or
; 'duplicate volume'
;
	sty temp
	lda #$80+'o'
	jsr xgetparm_ch
	ldy temp
	bcs print_this
	jmp nextvol
;
print_this:
	iny
	lda (p),y
	dey
	ldx #msg_notpro-msg
	cmp #err_notprodos
	beq this_vol
	ldx #msg_dupvol-msg
	cmp #err_dupvol
	bne nextvol
this_vol:	stx msg_index
;
; do one volume
;
normal_name:
	lda (p),y	;get devnum
	jsr print_sd
;
	ldx msg_index
onlmsg:	lda msg,x
	beq onlmsgx
	jsr cout
	inx
	bne onlmsg
onlmsgx:
;
	lda (p),y
	and #$0f
	tax
	beq nextvol
	iny
charlp:	lda (p),y
	jsr xdowncase
	jsr cout
	iny
	dex
	bne charlp
	jsr crout
;
nextvol:	pla
	clc
	adc #1
	cmp #16
	bcc vloop
	rts
;
msg:
msg2:	asc_hi " = /"
	.byte 0
msg_notpro:
	asc_hi ":  <non-ProDOS disk>"
	.byte cr,0
msg_dupvol:
	asc_hi ":  <duplicate volume>"
	.byte cr,0
;
onl_parms:
	.byte 2
	.byte 0
	.addr pagebuff
;*********************************************
;
; type command -- show contents of a file
;
case_flags:
	.res 1
pause_flag:
	.res 1
line_count:
	.res 1
saved_tchr:	.res 1
go_type:
	clc
type_pg:	ror pause_flag
;
	lda #$80+'f'
	jsr xgetparm_ch
	ror a
	sta filter
;
	lda #$80+'l'
	jsr xgetparm_ch
	ror case_flags
	lda #$80+'u'
	jsr xgetparm_ch
	ror case_flags
;
	lda #0
	jsr xgetparm_n
more2:
	pha
	tya
	pha
; don't prompt if output redirected
	lda #0
	jsr redirect
	bpl pg_ok
	lsr pause_flag
pg_ok:
;
	pla
	tay
	pla
	jsr fman_open
	bcc typeopened
type_err:	jmp xProDOS_err
typeopened:
	sta type_readref
	sta tyeofr
	jsr mli
	.byte mli_geteof
	.addr tyeof
	bcs type_err
;
	lda #23
	sta line_count
;
; print header if -h given
;
	lda #$80+'h'
	jsr xgetparm_ch
	bcs no_head
	jsr xmess
	asc "******* "
	.byte 0
	lda p+1
	ldy p
	jsr print_path
	jsr xmess
	asc "--modified "
	.byte 0
	lda p+1
	ldy p
	jsr getinfo
	lda info_moddat+1
	ldy info_moddat
	jsr xpr_date_ay
	lda info_modtim+1
	ldy info_modtim
	jsr xpr_time_ay
	jsr xmess
	asc " *******"
	.byte cr,cr,nul
	dec line_count
	dec line_count
no_head:
;
	lda scr_width
	sta temp
type_1:
	jsr xpoll_io
	lda type_readref
	jsr fman_read
	bcc treadok
	cmp #err_eof
	bne typerr9
	jmp type_finish
typerr9:	jmp xProDOS_err
treadok:
	ora #%10000000
	sta saved_tchr
	cmp #$80+'M'-ctrl
	bne not_typeret
typeret:	ldx scr_width
	inx
	stx temp
	jsr xcheck_wait
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
	jsr xmess
	.byte cr
	asc "--- "
	.byte 0
	jsr type_perc
	jsr prdec_1
	jsr xmess
	asc "% --- more"
	.byte 0
	lda #$80+'y'	;default = Yes
	jsr xyesno2
	jsr restore
	beq type_finish
	lda saved_tchr
	jmp print_char
not_typeret:
	cmp #$89
	bne not_TAB
	lda #$80+'t'
	jsr xgetparm_ch
	bcs not_TAB0
	jsr xprint_path
	jmp type_1
not_TAB0:	lda #$89
not_TAB:	bit filter
	bpl print_char
	cmp #$a0
	bcs print_char
	jmp type_1
print_char:
	dec temp
	beq typeret
	bit case_flags
	bmi t_no_up
	jsr upcase
t_no_up:	bit case_flags
	bvs t_no_down
	jsr xdowncase
t_no_down:
	jsr cout
	jmp type_1
;
type_finish:
	lda #$80+'p'
	jsr xgetparm_ch
	bcs type_done
	jsr clear_sc
type_done:	rts
;
type_perc:
	lda tyeofr
	sta tymarkr
	jsr mli
	.byte mli_getmark
	.addr tymark
	lda tymarkval+2
	ldx tymarkval+1
	ldy tymarkval
	sta num+2
	stx num+1
	sty num
	lda tyeofval+2
	ldx tyeofval+1
	ldy tyeofval
	jmp xpercent
;
tymark:	.byte 2
tymarkr:	.res 1
tymarkval:	.res 3
;
tyeof:	.byte 2
tyeofr:	.res 1
tyeofval:	.res 3
;
type_readref:	.res 1
filter:
	.res 1
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
	jsr xgetparm_n
	sta rename_2+1
	sty rename_2
	jsr mli
	.byte mli_rename
	.addr rename_parms
	bcs rename_err
	rts
rename_err:	jmp xProDOS_err
;
rename_parms:	.byte 2
rename_1:	.res 2
rename_2:	.res 2
;
; ctype command: ctype <path1> <type> (-x auxtype)
;
ctype_typ:	.res 1
go_ctype:
	sta p+1
	sty p
	jsr getinfo
	lda #1
	jsr xgetparm_n
	sta info_type
; if -x given, change aux type
	lda #$80+'x'
	jsr xgetparm_ch
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
	bne type_x
	ldx #tDIR
type_x:
	stx cr_type
	ldy #1	;storage type for seedling
	cpx #tDIR
	bne cr_seed
	ldy #$d	;sttype for directory
cr_seed:	sty cr_stype
	jsr mli
	.byte mli_create
	.addr cr_parms
	bcs cr_err
	rts
cr_err:	jmp xProDOS_err
;
cr_parms:	.byte 7
cr_path:	.res 2
	.byte %11000011
cr_type:	.res 1
	.byte 0,0	;auxtype
cr_stype:	.res 1	;storage type
cr_date:	.addr 0
cr_time:	.addr 0
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
go_lock:	lda #%00111100	;AND mask
	ldy #%00000001	;OR mask: R
	bne protect
;
protect:	sta and_mask
	sty or_mask
; get file access
	lda #0
	jsr xgetparm_n
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
	lda #$80+'r'
	jsr xgetparm_ch
	bcs protp1
	pla
	ora #%00000001	;R
	pha
protp1:	lda #$80+'w'
	jsr xgetparm_ch
	bcs protp2
	pla
	ora #%00000010	;W
	pha
protp2:	lda #$80+'n'
	jsr xgetparm_ch
	bcs protp3
	pla
	ora #%01000000	;N
	pha
protp3:	lda #$80+'d'
	jsr xgetparm_ch
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
go_scan:
	lda num_parms
	bne scan_parms
; show list of cmd directories
	lda scanlist
	bne somedirs
	jsr xmess
	asc "no command dirs"
	.byte cr,0
	rts
somedirs:
	jsr xmess
	asc "command dirs:"
	.byte cr,0
	ldx #0
scan_show1:	lda scanlist,x
	beq scan_shown
	stx temp
	jsr xmess
	asc "  "
	.byte 0
	ldx temp
	lda scanlist,x	;length
	tay
scanshowch:	inx
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
;

scan_dflt:
	.byte 1
	asc "%"
	.byte 1
	asc "*"
	.byte 0

;
scan_zap:
	ldy #-1
scanz1:	iny
	lda scan_dflt,y
	sta scanlist,y
	bne scanz1
	jmp xdirty
;
scan_parms:
	lda #$80+'z'
	jsr xgetparm_ch
	bcs scan_notz
	jsr scan_zap
scan_notz:
	lda #$80+'r'
	jsr xgetparm_ch
	bcs scan_notrem
	jsr findscan_x
	bcc rmvcont
	lda #der_notfnd
	jmp xProDOS_err
rmvcont:
	txa
	sec
	adc scanlist,x
	tay
squish:	lda scanlist,y
	sta scanlist,x
	inx
	iny
	bpl squish
;
scan_notrem:	lda #$80+'a'
	jsr xgetparm_ch
	bcs scan_notadd
	jsr findscan_x
	bcc scan_notadd
	ldy #0
	lda (p),y
	sta count
;sec
	txa
	adc count
	bpl scan_fits
;
	lda #der_outroom
	jmp xProDOS_err
;
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
;
scan_notadd:	sec
	ror config_dirty
	rts
;
count:
	.res 1
findscan_x:	sta p+1
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
noslash:	ldx #0
fsx1:	stx temp
	ldy #0
	lda (p),y	;length of target
	cmp scanlist,x	;same lengths?
	bne fsxnext
	sta count
fsxcomp:	iny
	inx
	lda (p),y
	jsr xdowncase
	sta scchar
	lda scanlist,x
	jsr xdowncase
	cmp scchar
	bne fsxnext
	dec count
	bne fsxcomp
	clc
	ldx temp
	rts
scchar:	.byte 0
;
fsxnext:	ldx temp
	lda scanlist,x
	beq scanx
	txa
	sec
	adc scanlist,x
	tax
	lda scanlist,x
	bne fsx1
scanx:	sec	;not found
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
	jsr xmess
	.byte cr
	asc "name:      "
	.byte 0
	lda #0
	jsr xgetparm_n
	jsr empty_prefix
	jsr prnt_compl
	jsr xmess
	asc "   "
	.byte 0
	pla	;get devnum
	jsr print_sd
	jsr crout
	jsr xmess
	asc "strg type: "
	.byte 0
	lda info_stype
	jsr print_stype
	jsr crout
	jsr xmess
	asc "type:      "
	.byte 0
	lda info_type
	jsr xprint_ftype
	jsr xmess
	asc "        access: "
	.byte 0
	lda info_acc
	jsr xprint_access
	jsr crout
	jsr xmess
	asc "aux type:  "
	.byte 0
	lda info_auxtype+1
	ldy info_auxtype
	jsr prdec_2
	jsr xmess
	asc "  ($"
	.byte 0
	lda info_auxtype+1
	jsr prbyte
	lda info_auxtype
	jsr prbyte
	jsr xmess
	.byte $80+')',cr
	asc "blocks:    "
	.byte 0
	lda info_blocks+1
	ldy info_blocks
	jsr prdec_2
	jsr crout
;
	lda info_crdat+1
	ora info_crdat
	ora info_crtim+1
	ora info_crtim
	beq info_nullcr
	jsr xmess
	asc "created:   "
	.byte 0
	lda info_crdat+1
	ldy info_crdat
	jsr xpr_date_ay
	lda info_crtim+1
	ldy info_crtim
	jsr xpr_time_ay
	jsr crout
info_nullcr:
	lda info_moddat+1
	ora info_moddat
	ora info_modtim+1
	ora info_modtim
	beq info_nullmod
	jsr xmess
	asc "modified:  "
	.byte 0
	lda info_moddat+1
	ldy info_moddat
	jsr xpr_date_ay
	lda info_modtim+1
	ldy info_modtim
	jsr xpr_time_ay
	jsr crout
info_nullmod:
info_nbin:	rts
;
startup_size:
	sta info_path+1
	sty info_path
	lda #0
	tay
zrpgbf:	sta pagebuff,y
	dey
	bne zrpgbf	;in case file is short!
	jsr mli
	.byte mli_open
	.addr info_op
	bcs info_err
	lda inforef
	sta inforef2
	jsr mli
	.byte mli_read
	.addr info_rd
;bcs info_err
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
;
info_err:	jmp xProDOS_err
info_op:	.byte 3
info_path:	.res 2
	.addr filebuff
inforef:	.res 1
;
info_rd:	.byte 4
inforef2:	.res 1
	.addr pagebuff
	.addr 256
	.addr 0
;
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
st_seed:	jsr xmess
	asc "seedling"
	.byte 0
	rts
st_sap:	jsr xmess
	asc "sapling"
	.byte 0
	rts
st_tree:	jsr xmess
	asc "tree"
	.byte 0
	rts
st_pasc:	jsr xmess
	asc "pascal area"
	.byte 0
	rts
st_extended:	jsr xmess
	asc "extended"
	.byte 0
	rts
stp_dir:	jsr xmess
	asc "subdirectory"
	.byte 0
	rts
st_vol:	jsr xmess
	asc "volume"
	.byte 0
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
nodecrc1:	dec rep_count
rc_eq0:
	pla
	pla
	jmp repeated	;must cheat!
;
;go_mem:
;	rts
;
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
	jmp xProDOS_err
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
go_cat:	lda #0
	sta indent_level
	sta cat_ftype
	lda #$80+'i'
	jsr xgetparm_ch
	ror a
	eor #$80
	sta show_invis
	lda #$80+'f'
	jsr xgetparm_ch
	bcs c_noftp
	sta cat_ftype
c_noftp:	lda #0
	jsr xgetparm_n
	jsr empty_prefix
	sta ptr+1
	sty ptr
	jsr getinfo
	lda devnum
	sta cat_devnum
	lda info_type
	cmp #tDIR
	beq cat_isdir
	lda #der_notdir
	jmp xProDOS_err
cat_isdir:	lda #$80+'a'	;arrange
	jsr xgetparm_ch
	bcs cat_unsort
	sta sort_str+1
	sty sort_str
	jmp cat_sorted
cat_unsort:	jsr xpush_level
	lda ptr+1
	ldy ptr
	jsr xdir_setup
	jsr crout
	jsr cat_header
dir_1:	jsr read1dir_vis
	bcs dir_x
	jsr print1dir
	bcs dir_xx
	lda catbuff+16	;type
	cmp #tDIR
	bne cat_xnest
	lda #$80+'t'
	jsr xgetparm_ch
	bcs cat_xnest
	jsr xpush_level
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
	jsr xdir_finish
	jmp nest_fail
nest_ok:
	inc indent_level
	inc indent_level
	bit speech
	bpl cat_xnest
	jsr xmess
	.byte $80+'>',cr,0
nest_fail:
cat_xnest:	jmp dir_1
dir_x:	bit speech
	bpl dirdec
	lda indent_level
	beq dirdec
	jsr xmess
	.byte $80+'<',cr,0
dirdec:
	dec indent_level
	dec indent_level
	jsr xdir_finish
	lda indent_level
	bpl dir_1
	jmp cat_trailer
dir_xx:	jsr xdir_finish
	dec indent_level
	dec indent_level
	bpl dir_xx
	rts
;
; -arrange the dir listing
;
cat_sorted:	jsr xpush_level
	lda ptr+1
	ldy ptr
	jsr xdir_setup
	jsr crout
	jsr cat_header
	lda #0
	sta keep_count+1
	sta keep_count
	jsr keep_init
catsrt1:	jsr read1dir_vis
	bcs catsrt2
	jsr keep1dir
	jmp catsrt1
catsrt2:	jsr xdir_finish
	jsr sortdir
	jsr keep_init
catsrt3:	jsr get1kept
	bcs catsrt_x
	jsr print1dir
	bcc catsrt3
catsrt_x:	jmp cat_trailer
;
keep_count:	.addr 0
;
; sort directory entries (length = entrylen) at
; 'keepbuff'.  There are keep_count(2 by) files
;
swapped:	.byte 0
srt_count:	.byte 0
;
sortdir:	ldy #0	;if sort_str is empty, sort by name
	lda (sort_str),y
	bne sort_given
	lda #1
	sta (sort_str),y
	iny
	lda #$80+'n'
	sta (sort_str),y
sort_given:	lda keep_count+1
	bne dont_srt
	lda keep_count
	pha
nextpass:	lda #0
	sta swapped
	jsr sort1pass
	dec keep_count
	lda swapped
	bne nextpass
	pla
	sta keep_count
dont_srt:	rts
;
sort1pass:	lda keep_count
	sta srt_count
	beq sort_x
	lda #>keepbuff
	ldy #<keepbuff
sort1swap:	sta p+1
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
;
sortstr_i:	.byte 0	;index into sort string
cond_swap:	ldy #0
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
	jsr xdowncase
	jsr doCmp
	beq cond1
	php
	lda sort_char
	cmp #$80+'a'
	bcc revSort
	plp
	bcs need2swap
	rts
revSort:	plp
	bcc need2swap
sortdun:	rts
need2swap:	jmp swap_two
;
doCmp:	cmp #$80+'n'
	beq cmpNAME
	cmp #$80+'b'
	beq cmpBACKUP
	cmp #$80+'f'
	beq cmpTYPE
	cmp #$80+'t'
	beq cmpTYPE
	cmp #$80+'d'
	beq cmpModDATE
	cmp #$80+'m'
	beq cmpModDATE
	cmp #$80+'x'
	beq cmpAUX
	cmp #$80+'s'
	beq cmpSIZE
	cmp #$80+'c'
	beq cmpCrDATE
	lda #der_illegparm
	jmp xProDOS_err
;
cmpNAME:
	ldy #0
cmpNam:	iny
	cpy #16
	beq NamEq
	lda (p2),y
	jsr xdowncase
	sta temp
	lda (p),y
	jsr xdowncase
	cmp temp
	beq cmpNam
NamEq:	rts
;
cmpSIZE:	ldy #$17
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
;
cmpAUX:	ldy #$20
	lda (p),y
	cmp (p2),y
	bne cmpAUXx
	dey
	lda (p),y
	cmp (p2),y
cmpAUXx:	rts
;
cmpBACKUP:	ldy #$1e
	lda (p),y
	and #%00100000
	sta temp
	lda (p2),y
	and #%00100000
	cmp temp
	rts
;
cmpTYPE:
	ldy #16
	lda (p),y
	cmp (p2),y
	rts
;
cmpCrDATE:	ldy #$18+1
	bne cmpDate
cmpModDATE:	ldy #$21+1

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
cmpDATEx:	rts
;
;
swap_two:	ldy EntryLen
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
keep_init:	lda #>keepbuff
	ldy #<keepbuff
	sta keep+1
	sty keep
	rts
;
keep1dir:	inc keep_count
	bne scok
	inc keep_count+1
scok:	ldy EntryLen
k1d:	dey
	bmi k1dx
	lda catbuff,y
	sta (keep),y
	jmp k1d
k1dx:	jmp nextkeep
;
get1kept:
	lda keep_count+1
	ora keep_count
	bne g1k_ok
	sec
	rts
g1k_ok:
	lda keep_count
	bne scokz
	dec keep_count+1
scokz:	dec keep_count
	ldy EntryLen
g1k:	dey
	bmi g1kx
	lda (keep),y
	sta catbuff,y
	jmp g1k
g1kx:
nextkeep:	clc
	lda keep
	adc EntryLen
	sta keep
	lda keep+1
	adc #0
	sta keep+1
	cmp #$AF
	bcc nkok
	lda #der_outroom
	jmp xProDOS_err
nkok:	rts	;clc
;************************************************
read1dir_vis:
	jsr xread1dir
	bcs r1v_x
	bit show_invis
	bmi r1v_x
	lda catbuff+$1E	;access
	and #%00000100
	bne read1dir_vis
	clc
r1v_x:	rts
;************************************************
cat_header:
	lda ptr+1
	ldy ptr
	jsr prnt_compl
	jsr xmess
	asc "      "
	.byte 0
	lda file_count+1
	ldy file_count
	jsr prdec_2
	jsr xmess
	asc " file"
	.byte 0
	lda file_count+1
	ldy file_count
	jsr xplural
	jsr crout
	jsr crout
	jsr xmess
	asc "name                       type"
	.byte 0
	lda #$80+'s'
	jsr xgetparm_ch
	bcc catshort1
	jsr xmess
	asc "        blocks   modified               access"
	.byte 0
catshort1:
	bit speech
	bmi catshort2
	jsr crout
	jsr xmess
	asc "----                       ----"
	.byte 0
	lda #$80+'s'
	jsr xgetparm_ch
	bcc catshort2
	jsr xmess
	asc "------  ------   --------               ------"
	.byte 0
catshort2:	jmp crout
;
cat_trailer:
	lda #$80+'s'
	jsr xgetparm_ch
	bcs catlong2
	rts
catlong2:
	jsr get_vol_info
	jsr crout
	jsr xmess
	asc "blocks free: "
	.byte 0
	sec
	lda info_auxtype
	sbc info_blocks
	tay
	lda info_auxtype+1
	sbc info_blocks+1
	jsr prdec_2
	jsr xmess
	asc "    "
	.byte 0
	jsr xmess
	asc "used: "
	.byte 0
	lda info_blocks+1
	ldy info_blocks
	jsr prdec_2
	jsr show_percent
	jsr xmess
	asc "     total: "
	.byte 0
	lda info_auxtype+1
	ldy info_auxtype
	jsr prdec_2
	jmp crout
;
get_vol_info:	lda cat_devnum
	sta online_dev
	jsr mli
	.byte mli_online
	.addr online_parm
	bcc von_ok
	jmp xProDOS_err
von_ok:	lda catbuff
	and #%00001111
	tax
	inx
	stx catbuff-1
	lda #$80+'/'
	sta catbuff
	lda #>(catbuff-1)
	ldy #<(catbuff-1)
	jmp getinfo
;
online_parm:	.byte 2
online_dev:	.byte 0
	.addr catbuff
;
; print this entry if:
;   no -f type was given     OR
;   the type matches the -f type   OR
;   it's a DIR and -t was given
;
print1dir:
; jsr calc_cmask
	lda cat_ftype
	beq dothis2
	cmp catbuff+16
	beq dothis2
	lda catbuff+16
	cmp #tDIR
	bne notthis2
	lda #$80+'t'
	jsr xgetparm_ch
	bcc dothis2
notthis2:	clc
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
; jsr xdowncase
;no_dcase
	jsr cout
	iny
	dex
	bne prcat1
;
	clc
	tya
	adc indent_level
	tay
tabType:	cpy #18+10
	bcs tabbedType
	jsr pr_sp
	iny
	bne tabType
tabbedType:
	ldx #$80+' '
	lda catbuff
	and #$f0
	cmp #$50
	bne not_xtnd
	ldx #$80+'+'
not_xtnd:	txa
	jsr cout
	lda catbuff+16
	jsr xprint_ftype
; short form -s?
	lda #$80+'s'
	jsr xgetparm_ch
	bcs longcat
	jsr crout
	jmp xcheck_wait
longcat:
; print ' $xxxx' (auxtype)
	jsr xmess
	asc " $"
	.byte 0
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
	jsr xprdec_pad

	lda #$80+' '
	bit speech
	bpl store_char
	lda #$80+','
store_char:	sta spComma
;
	jsr xmess
spComma:	asc "   "
	.byte 0
	lda catbuff+$22
	ldy catbuff+$21
	jsr xpr_date_ay
;
	jsr pr_sp
	lda catbuff+$24
	ldy catbuff+$23
	jsr xpr_time_ay
;
	jsr xmess
	asc "   "
	.byte 0
	lda catbuff+$1E
	jsr xprint_access
	jsr crout
	jmp xcheck_wait
;
calc_cmask:
	ldx catbuff+16	;type
	cpx #$19	; < ADB ?
	bcc cm_ProFST
	cpx #$1B+1	; >= ASP+1 ?
	bcs cm_ProFST
	lda catbuff+$20
	ldy catbuff+$1f
cm_store:	sta case_mask+1
	sty case_mask
	rts
; check for ProDOS FST lowercase bits
cm_ProFST:	lda catbuff+$1d
	bpl no_case
	lda catbuff+$1c
	asl a
	rol catbuff+$1d
	ldy catbuff+$1d
	jmp cm_store
no_case:	lda #$ff
	tay
	bne cm_store
;
case_mask:
	.addr 0
;
indent_x:
	beq idntx
idnt1:	jsr pr_sp
	dex
	bne idnt1
idntx:	rts
;************************************************
;************************************************
;
; ftype [-r<type>] [-a<string> -v<ftype>] [-z]
;
go_ftype:	lda num_parms
	bne ftype_p
; display all filetype names
	lda #7
	ldx scr_width
	cpx #80
	bcs f7
	lsr a
f7:	sta ftyp_mask

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
	lda #$80+'='
	jsr cout
	lda #$80+'$'
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
;
ftyp_mask:	.byte 0
ftInternal:	.byte 0
;
oneFTchar:
	lda fileasc,y
	bit ftInternal
	bpl oneFTch
	lda fileasc0,y
oneFTch:	iny
	ora #%10000000
	jmp cout
;
ftype_p:
	lda #$80+'z'
	jsr xgetparm_ch
	bcs no_zapft
	lda #0
	sta filetyp
	jsr xdirty
no_zapft:
;
	lda #$80+'r'
	jsr xgetparm_ch
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
	jmp xProDOS_err
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
	jsr xdirty
;
ftype_add:	lda #$80+'a'
	jsr xgetparm_ch
	bcs ftype_x
	sta p2+1
	sty p2
	ldy #0
	lda (p2),y
	cmp #3
	beq fta3
	lda #der_needs3
der2:	jmp xProDOS_err
fta3:	lda #$80+'v'
	jsr xgetparm_ch
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
ftacopy:	lda (p2),y
	sta fileasc,x
	dex
	dey
	bne ftacopy
	jsr xdirty
ftype_x:	rts
;************************************************
;
; err <int> -- print xProDOS error
;
go_err:	tya
	beq all_errs
	jmp xProDOS_er
all_errs:	lda #0
next_err:	pha
	ldy #3
	sta num
	lda #0
	sta num+1
	sta num+2
	jsr xprdec_pady
	jsr xmess
	asc ": "
	.byte 0
	pla
	pha
	jsr ProDOS_er2
	jsr xcheck_wait
	pla
	bcs errdun
; clc
	adc #1
	bcc next_err
errdun:	rts
;************************************************
;
; '=' -- print a pathname
;
go_equal:	nop	;disables wildcard exp echo
	sta p2+1
	sty p2
	lda #1
	jsr xgetparm_n
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
	cmp #$80+'/'
	beq eq_compl
	jsr print_pfx
	lda #$80+'/'
	jsr cout
eq_compl:	lda p2+1
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
	jsr xmess
	asc "(appl not implemented)"
	.byte cr,0
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
	beq od_prtr
	cmp #refSlot0
	bcs od_prtr
	jsr append
od_prtr:	rts
;************************************************
;
; < | exec
;
go_exec:
	jsr finish_iredir
	lda #0
	jsr xgetparm_n
	jmp begin_iredir
;************************************************
;
; go_echo -- type a string (-n = no CR)
;
go_echo:
	sta p+1
	sty p
	ldy #0
	lda (p),y
	beq echoed
	tax
echo1:	iny
	lda (p),y
	ora #%10000000
	jsr cout
	dex
	bne echo1
echoed:	lda #$80+'n'
	jsr xgetparm_ch
	bcc echo_noCR
	jsr crout
echo_noCR:	rts
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

	jsr xgetnump
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

touch_set:	lda #0
	jsr xgetparm_n
	jmp setinfo

touch_b:	lda #$80+'b'
	jsr xgetparm_ch
	bcs touch_bx
	tax
	beq touch_bn
	lda info_acc
	ora #%00100000
	bne do_bub
touch_bn:	lda info_acc
	and #%11011111
do_bub:	sta info_acc
	lda #$ff
	sta bubit	;allow fiddling w/ bkup bit
touch_bx:	rts

touch_i:	lda #$80+'i'
	jsr xgetparm_ch
	bcs touch_ix
	tax
	beq touch_in
	lda info_acc
	ora #%00000100
	sta info_acc
	rts
touch_in:	lda info_acc
	and #%11111011
	sta info_acc
touch_ix:	rts

touch_d:	lda #$80+'d'
	jsr xgetparm_ch
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
okDisable:	txa
	bne tDISABLE
	lda info_auxtype+1
	and #$7f	;enable
	sta info_auxtype+1
	rts
tDISABLE:	lda info_auxtype+1
	ora #$80	;disable
	sta info_auxtype+1
touch_dx:	rts
;
bad_disable:	jsr xmess
	.byte cr
	asc "*** bad filetype for enable/disable"
	.byte cr,0
	jmp xerr
;************************************************
;
; config
;
go_config:
	lda num_parms
	beq cfg_show
	lda #$80+'p'
	jsr xgetparm_ch
	bcs cfg2
	cpy #7+1
	bcs cfgperr
	cpy #0
	beq cfgperr
	sty print_slot
	jsr xdirty
cfg2:	lda #$80+'4'
	jsr xgetparm_ch
	bcs cfg3
	sta cfg40
	jsr xdirty
cfg3:	lda #$80+'b'
	jsr xgetparm_ch
	bcs cfg4
	sta cfgbell
	jsr xdirty
cfg4:	lda #$80+'c'
	jsr xgetparm_ch
	bcs cfg5
	sta cfgclock
	jsr xdirty
cfg5:	lda #$80+'q'
	jsr xgetparm_ch
	bcs cfg6
	cpy #3
	bcs cfgperr
	sty cfgquiet
	jsr xdirty
cfg6:
	lda #$80+'h'
	jsr xgetparm_ch
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
	jmp xProDOS_err
HelpPok:	jsr xpmgr
	.byte pm_copy
hp1:	.addr 0,cfghelp
	jsr xdirty
cfg7:
	rts
cfgperr:	lda #der_badnum
	jmp xProDOS_err
;
cfg_show:
	jsr xmess
	asc "   Printer slot: "
	.byte 0
	lda print_slot
	ora #$80+'0'
	jsr cout
	jsr xmess
	.byte cr
	asc "Use system bell: "
	.byte 0
	lda cfgbell
	jsr showyn
	jsr xmess
	.byte cr
	asc "40 columns only: "
	.byte 0
	lda cfg40
	jsr showyn
	jsr xmess
	.byte cr
	asc "Show IIgs clock: "
	.byte 0
	lda cfgclock
	jsr showyn
	jsr xmess
	.byte cr
	asc "    Quiet level: "
	.byte 0
	lda cfgquiet
	ora #$80+'0'
	jsr cout
	jsr xmess
	.byte cr
	asc " Help directory: "
	.byte 0
	lda #>cfghelp
	ldy #<cfghelp
	jsr xprint_path
	jmp crout
;
showyn:	bne showy
	jsr xmess
	asc "no"
	.byte 0
	rts
showy:	jsr xmess
	asc "yes"
	.byte 0
	rts
;************************************************

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
cpd_cre:	jsr mli
	.byte mli_create
	.addr cpd_cr
	bcs cpd_err
cpdok3:	jsr xpush_level
	lda cp_pn1+1
	ldy cp_pn1
	jsr xdir_setup
cdir1:	jsr xread1dir
	bcs cdirx
	lda catbuff
	and #%00001111
	sta catbuff
; append name to path1, path2
	jsr cp_appboth
;
	jsr cp_report
	jsr cp_recurse
;
; remove last seg from path1, path2
	lda cp_pn1+1
	ldy cp_pn1
	jsr up_ay
	lda cp_pn2+1
	ldy cp_pn2
	jsr up_ay
	jmp cdir1
cdirx:	jmp xdir_finish
cpd_err:	jmp xProDOS_err
;
cpd_cr:	.byte 7,0,0,%11000011,tDIR,0,0,$D,0,0,0,0
;*******************************************
up_ay:
	sta upay+1
	sty upay
	jsr xpmgr
	.byte pm_up
upay:	.addr 0
	rts
;
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
	jsr xpmgr
	.byte pm_slashif
cpsl1:	.addr 0
	jsr xpmgr
	.byte pm_slashif
cpsl2:	.addr 0
	lda #>catbuff
	ldy #<catbuff
	jsr xpmgr
	.byte pm_appay
cpapp:	.addr 0
	lda #>catbuff
	ldy #<catbuff
	jsr xpmgr
	.byte pm_appay
cpapp2:	.addr 0
	rts
;*******************************************
;*******************************************
go_move:
	sta cp_pn1+1
	sty cp_pn1
	lsr del_flag
	bpl goc_2
del_flag:	.res 1
;*******************************************
go_copy:
	sta cp_pn1+1
	sty cp_pn1
	lda #$80+'d'
	jsr xgetparm_ch
	ror del_flag
goc_2:
	lda #1
	jsr xgetparm_n
	jsr empty_prefix	;15-Jun-87
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
;
cp_recurse:
	lda cp_pn1+1
	ldy cp_pn1
	jsr getinfo
;
	lda info_type
	cmp #tDIR
	bne cp_ndir
	jmp copydir
cp_ndir:
;
	jsr mli
	.byte mli_open
	.addr cp_op1
	bcs cp_err0
	lda cpref1
	sta cpref1b
;
; get eof of file1
;
	sta cpeof_r
	jsr mli
	.byte mli_geteof
	.addr cpeof_p
	bcs cp_err0
;
; GetInfo on the dest file
;
cp_getdesti:
	lda #$ff
	sta desti_acc
	sta desti_stt
	jsr mli
	.byte mli_gfinfo
	.addr destinfo
	bcc cp_goti
	cmp #err_filnotfnd
	beq cp_create
cp_err0:	jmp xProDOS_err
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
cp_create:	jsr mli
	.byte mli_create
	.addr cp_creatp
	bcc cp_created
	jmp xProDOS_err
;
cp_ask:
	lda desti_acc
	and #%11000011
	cmp #%11000011
	bne ask_anyway
;
	lda #$80+'f'
	jsr xgetparm_ch
	bcc cp_created
;
ask_anyway:	jsr suspend
	jsr TalkCont
	jsr xmess
	asc "Okay to replace "
	.byte 0
	lda cp_pn2+1
	ldy cp_pn2
	jsr prnt_compl
	lda desti_acc
	and #%11000011
	cmp #%11000011
	beq cpyn
	jsr xmess
	asc " [LOCKED] "
	.byte 0
cpyn:	lda #$80+'n'	;default = No
	jsr xyesno2
	jsr restore	;must save N!
	bmi cp_created
	lda cpref1
	jmp close
;
cp_created:
;
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
;
	jsr mli
	.byte mli_open
	.addr cp_op2
	bcs cp_er
	lda cpref2
	sta cpref2b
;
; the main copy loop!  (Read a bufferfull, write it..._)
;
copy1:
	jsr mli
	.byte mli_read
	.addr cp_rd1
	bcc copy2
	cmp #err_eof
	beq copied
cp_er:	jmp xProDOS_err
copy2:	lda cp_xfer+1
	ldy cp_xfer
	sta cp_xfer2+1
	sty cp_xfer2
	jsr mli
	.byte mli_write
	.addr cp_wr2
	bcs cp_er
	jmp copy1
copied:
; set EOF of file2
	lda cpref2
	sta cpeof_r
	jsr mli
	.byte mli_seteof
	.addr cpeof_p
	bcs cp_er
; close both files
	lda cpref1
	jsr close
	lda cpref2
	jsr close
;
; clr backup bit on original if -b
;
	lda #$80+'b'
	jsr xgetparm_ch
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
	jsr mli
	.byte mli_destroy
	.addr cprm
	bcc cp_notrm
	jmp xProDOS_err
cp_notrm:	rts
;
cprm:	.byte 1
cprm_p:	.addr 0
;
cp_op1:	.byte 3
cp_pn1:
	.addr 0
	.addr filebuff
cpref1:	.byte 0
;
cp_op2:	.byte 3
cp_pn2:	.addr 0
	.addr filebuff2
cpref2:	.byte 0
;
cp_rd1:	.byte 4
cpref1b:	.byte 0
	.addr copybuff
	.addr cbufflen
cp_xfer:	.addr 0
;
cp_wr2:	.byte 4
cpref2b:	.byte 0
	.addr copybuff
cp_xfer2:	.addr 0
	.addr 0
;
cpeof_p:	.byte 2
cpeof_r:	.byte 0
	.byte 0,0,0
;
cp_creatp:	.byte 7
cp_crpn:	.addr 0
	.byte %11000011
	.byte tBAD
	.addr 0
	.byte 1
	.addr 0,0
;
destinfo:	.byte 10
desti_name:	.addr 0
desti_acc:	.byte 0
desti_ftyp:	.byte 0
	.addr 0
desti_stt:	.byte 0
	.addr 0,0,0,0,0
;
; append last seg of path1 onto path2
;
cp_intodir:
	lda cp_pn1+1
	ldy cp_pn1
	sta p+1
	sty p
;
	lda cp_pn2+1
	ldy cp_pn2
	sta cp_appnm+1
	sty cp_appnm
	sta cp_appnm0+1
	sty cp_appnm0
;
; add a '/' onto path2 if it doesn't end in one already
;
	jsr xpmgr
	.byte pm_slashif
cp_appnm0:	.addr 0
;
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
	jsr xpmgr
	.byte pm_appch
cp_appnm:	.addr 0
	pla
	tay
	iny
	cpy pn1len
	bcc cpi1
	beq cpi1
intodx:	rts
;
pn1len:	.byte 0
;*******************************************
cp_report:
	lda cp_pn1+1
	ldy cp_pn1
	jsr xprint_path
	jsr xmess
	asc " --> "
	.byte 0
	lda cp_pn2+1
	ldy cp_pn2
	jsr xprint_path
	jsr crout
	jmp xcheck_wait
;*******************************************

;*********************************************
;
; size -- print size of file or tree of files
;
szpath:	.addr 0
go_size:
	nop	;disable wildcard expansion display
	jsr empty_prefix
	sta szpath+1
	sty szpath
	jsr xprint_path
	jsr xmess
	asc ":  "
	.byte 0
	lda szpath+1
	ldy szpath
	jsr size_ay
	lda num+1
	ldy num
	sta num3+1
	sty num3
	jsr xprdec_2
	jsr xmess
	asc " block"
	.byte 0
	lda num3+1
	ldy num3
	jsr xplural
	jsr xmess
	asc "; "
	.byte 0
	lda num2+2
	ldx num2+1
	ldy num2
	sta num+2
	stx num+1
	sty num
	jsr print_dec
	jsr xmess
	asc " byte"
	.byte 0
	lda num2+2
	ora num2+1
	ldy num2
	jsr xplural
	jmp crout
;
; return # blocks in NUM*2 and # bytes
; in NUM2*3
;
size_ay:	sta p+1
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
	jsr mli
	.byte mli_open
	.addr sz_open
	bcs sz0
	lda sz_ref
	sta sz_ref2
	jsr mli
	.byte mli_geteof
	.addr sz_geteof
;bcs sz_err ;just use 0 if it returns an error
	lda sz_ref
	jsr close
sz0:
	lda sz_eof+2
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
;
	lda info_type
	cmp #tDIR
	beq szdir
	rts
; compute size of everything in dir
szdir:	jsr xpush_level
	lda p+1
	ldy p
	jsr xdir_setup
sz1:	jsr xread1dir
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
;
	jsr build_szpath
;
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
;
slowsize:	jsr size_ay
anysize:	clc
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
sz_x:	jmp xdir_finish
sz_err:	jmp xProDOS_err
;
build_szpath:	ldy #127
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
;
sz_open:	.byte 3
sz_path:	.addr 0
	.addr filebuff
sz_ref:	.byte 0
;
sz_geteof:	.byte 2
sz_ref2:	.byte 0
sz_eof:	.byte 0,0,0
;********************************************
;********************************************
;
; del -- delete file
;
go_del:
	sta del_path+1
	sty del_path
	jsr getinfo
	cmp #tDIR
	bne del_ndir
	jsr suspend
	lda del_path+1
	ldy del_path
	jsr go_size
	jsr TalkCont
	jsr xmess
	asc "Okay to destroy directory"
	.byte 0
	lda #$80+'n'	;default = No
	jsr xyesno2
	jsr restore
	beq deldun
del_ndir:
del_recurse:
	lda #$80+'u'	;unlock first?
	jsr xgetparm_ch
	bcs del_unlx
	jsr go_unlock
del_unlx:
	lda del_path+1
	ldy del_path
	jsr getinfo
	cmp #tDIR
	bne del_ndir2
	jsr deldir
del_ndir2:	jsr mli
	.byte mli_destroy
	.addr del_parms
	bcs del_err
deldun:	rts
del_err:	jmp xProDOS_err
;
del_parms:	.byte 1
del_path:	.addr 0
;****************************************
deldir:
	jsr xpush_level
	lda del_path+1
	ldy del_path
	jsr xdir_setup
deld1:	jsr xread1dir
	bcs deldx
;
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
;
	jsr del_recurse
;
	lda del_path+1
	ldy del_path
	jsr up_ay
	jmp deld1
deldx:	jmp xdir_finish
;****************************************


;*************************************
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
rm_which:	.byte 0
;
dv_done:	rts
go_dev:
	lda num_parms
	bne dv_some
;
	ldx devcnt
	bmi dv_done
dv_list:
	lda devlst,x
	pha
	jsr pr_sp
	pla
	jsr xprint_sd
	dex
	bpl dv_list
	rts
;
dv_some:
	lda #$80+'r'
	jsr xgetparm_ch
	bcs dv_notr
	jsr dev_rm1
	jmp dv_nota
;
dv_notr:	lda #$80+'a'
	jsr xgetparm_ch
	bcs dv_nota
	ldx devcnt
	cpx #15
	bcc devcntok
	lda #der_outroom
	jmp xProDOS_err
devcntok:
	inc devcnt
	inx
	sta devlst,x
dv_nota:
	lda #$80+'z'
	jsr xgetparm_ch
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
zok:	jsr mli
	.byte mli_online
	.addr zap_p
	bcc zapnext
	lda zap_dev
	jsr dev_rm1
	jmp zap1	;don't increment! (would miss 1)
zapnext:	inc rm_which
	bne zap1
dv_notz:
	rts
;
zap_p:	.byte 2
zap_dev:	.byte 1
	.addr pagebuff
;
; dev_rm1 -- remove device in A
;
dev_rm1:	and #%11110000
	sta temp
; sta dvUnit
	ldx devcnt
	bmi dvrx
	beq dvrx
dv_finda:	lda devlst,x
	and #%11110000
	cmp temp
	beq dv_found
	dex
	bpl dv_finda
	rts
dv_found:	lda devlst+1,x
	sta devlst,x
	inx
	cpx devcnt
	bcc dv_found
	dec devcnt
; jsr mli
; .byte mli_online
; .addr dvOnline
dvrx:	rts
;
;dvOnline .byte 2
;dvUnit .byte 0
; .addr pagebuff
;

;******************************
;
; update command for Davex
;
go_update:
	sta up_pn1+1
	sty up_pn1
	lda #1
	jsr xgetparm_n
	jsr empty_prefix
	sta up_pn2+1
	sty up_pn2
upd_recurse:	jsr xcheck_wait
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
;
	lda up_pn2+1
	ldy up_pn2
	jsr geti2
	bcc upd_ok2
	cmp #err_filnotfnd
	bne uperr
	jsr xmess
	asc "new file"
	.byte cr,0
;
	lda #$80+'f'
	jsr xgetparm_ch
	bcc crenew
;
	jsr TalkCont
	jsr xmess
	asc "Okay to create "
	.byte 0
	lda up_pn2+1
	ldy up_pn2
	jsr xprint_path
	jsr xyesno
	beq nonew
crenew:	jmp upd_copy
nonew:	rts
uperr:	jmp xProDOS_err
upd_ok2:
;
; check filetypes
;
	lda info_type
	cmp up_type1
	beq types_match

	jsr xmess
	asc "filetypes differ ("
	.byte 0
	lda up_type1
	jsr xprint_ftype
	lda #$80+','
	jsr cout
	lda info_type
	jsr xprint_ftype
	jsr xmess
	.byte $80+')',0
	lda #tDIR
	cmp info_type
	beq cantRepl
	cmp up_type1
	beq cantRepl
; ask
	jsr xmess
	asc ". Continue"
	.byte 0
	lda #$80+'n'	;default = No
	jsr xyesno2
	bne match0
	rts

cantRepl:	jsr crout
	jmp xcheck_wait

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
;
	jsr xmess
	asc "outdated"
	.byte cr,0
	jsr xcheck_wait
;
upd_copy:
	lda up_pn1+1
	ldy up_pn1
	sta cp_pn1+1
	sty cp_pn1
	lda up_pn2+1
	ldy up_pn2
	jmp go_copy2
;
up_done:	jsr xmess
	asc "current"
	.byte cr,0
	jmp xcheck_wait
;
up_warn:	jsr xmess
	asc "master file is older ["
	.byte 0
	lda up_pn1+1
	ldy up_pn1
	jsr xprint_path
	jsr xmess
	.byte $80+']',cr,0
	jmp xcheck_wait

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
	jsr xmess
	asc "scanning directory"
	.byte cr,0
;
	jsr xpush_level
	lda up_pn2+1
	ldy up_pn2
	sta upd_up2+1
	sty upd_up2
;
	lda up_pn1+1
	ldy up_pn1
	sta upd_up+1
	sty upd_up
	jsr xdir_setup	;open the subdir
;
updd1:	;update recursively for each file
	jsr xread1dir
	bcs upddx
	lda catbuff
	and #%00001111
	sta catbuff
;
	jsr up_appboth
	jsr upd_recurse
;
; remove last seg of both pathnames
;
	jsr xpmgr
	.byte pm_up
upd_up:	.addr 0
	jsr xpmgr
	.byte pm_up
upd_up2:	.addr 0
;
	jmp updd1	;go back for more files this dir
;
upddx:	jmp xdir_finish	;close the subdir, return from recursion
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
	jsr xpmgr
	.byte pm_slashif
upsl1:	.addr 0
	jsr xpmgr
	.byte pm_slashif
upsl2:	.addr 0
	lda #>catbuff
	ldy #<catbuff
	jsr xpmgr
	.byte pm_appay
upapp:	.addr 0
	lda #>catbuff
	ldy #<catbuff
	jsr xpmgr
	.byte pm_appay
upapp2:	.addr 0
	rts
;
; report which file we're trying to update now
;
upd_report:
	lda up_pn2+1
	ldy up_pn2
	jsr xprint_path
	jsr xmess
	asc " -- "
	.byte 0
	rts
;***********************************************
up_pn1:	.addr 0
up_pn2:	.addr 0
up_type1:	.byte 0
up_date1:	.byte 0,0	;mod date of first file
up_time1:	.byte 0,0	;mod time of first file
;***********************************************


;************************************************
; spool
;************************************************
;
; spool <wildpath>
;
;  -x <int1>   cancel a job
;  -z          zap all jobs
;
; 'spool' alone shows queue
;
; Uses buff_spool (1K) and spoollist (1 page)
;
;************************************************
;
; spool_list:
;  repeat {
;    length-prefixed pathname
;  }
;  $00
;
;************************************************
sp_linefd:	.byte 0
;
go_spool:
	sta p+1
	sty p
	lda num_parms
	cmp #1
	bne sp_notlist
	ldy #0
	lda (p),y
	bne sp_notlist
	jmp sp_list
sp_notlist:
	lda #$80+'z'
	jsr xgetparm_ch
	bcs sp_nzap
	jsr sp_zap
sp_nzap:	lda #$80+'x'
	jsr xgetparm_ch
	bcs sp_ncan
	jsr sp_cancel
sp_ncan:	jmp spool_file
;************************************************
spool_zap:
sp_zap:
	bit spooling
	bpl sp_zap2
; formfeed printer if it's ready
	ldy spl_prref
	ldx #mli_read
	jsr xprint_drvr
	and #1
	beq sp_zap2
	lda #$80+'L'-ctrl
	ldx #mli_write
	ldy spl_prref
	jsr xprint_drvr
sp_zap2:
	lsr spooling
	lda rsref
	jsr close
	ldx #mli_close
	ldy spl_prref
	beq szx
	jsr xprint_drvr
szx:	lda #0
	sta spool_list
	sta spl_prref
	rts
;
canthis:	jmp thats_ok
sp_cancel:
	cpy #0
	beq spcanx
	cpy #1
	beq canthis
	lda #0
spcan0:
	dey
	beq can_this
	tax
	sec
	adc spool_list,x
	jmp spcan0
;
can_this:	tax
	sec
	adc spool_list,x
	tay
spcan1:	lda spool_list,y
	sta spool_list,x
	inx
	iny
	bne spcan1
spcanx:	rts
;************************************************
spool_file:
	lda p+1
	ldy p
	sta spoolp+1
	sty spoolp
	ldy #0
	lda (p),y
	bne spoolit
	rts
spoolit:
	jsr spool_full
	lda p+1
	ldy p
	jsr getinfo
	jsr findspll
	txa
	ldy #0
	clc
	adc (p),y
	bcs spfull
	cmp #250
	bcc spl_room
spfull:	lda #der_outroom
	jmp xProDOS_err
spl_room:
	lda (p),y
	sta temp
splcopy:	lda (p),y
	sta spool_list,x
	iny
	inx
	dec temp
	bpl splcopy
	lda #0
	sta spool_list,x
	rts
;
spoolthis:
	sta spoolp+1
	sty spoolp
	lda #spoollevel
	sta level
	bit spooling
	bmi already_sp
	lda #0	;slot = '&'
	ldx #mli_open
	jsr xprint_drvr
	bcs spool_er
	sta spl_prref
already_sp:
	jsr mli
	.byte mli_open
	.addr spool_open
	bcs spool_er
	sec
	ror spooling
	lda spoolref
	sta rsref
	rts
spool_er:
	ldx #mli_close
	ldy spl_prref
	jsr xprint_drvr
	jmp xbell
;
spl_prref:	.byte 0
;
spool_open:	.byte 3
spoolp:	.res 2
	.addr buff_spool
spoolref:	.res 1
;************************************************
spoolnext:
	jsr sp_rmv1
	lda spool_list
	bne sp_another
	lsr spooling
	ldx #mli_close
	ldy spl_prref
	jmp xprint_drvr
;
sp_another:
	lda #>spool_list
	ldy #<spool_list
	jmp spoolthis
;************************************************
sp_list:
	lda spool_list
	bne spl_some
	jsr xmess
	asc "no files"
	.byte cr,0
	rts
spl_some:
	ldy #1
	ldx #0
spl_file:	txa
	pha
	tya
	pha
	lda #0
	jsr xprdec_2
	jsr xmess
	asc ".  "
	.byte 0
	pla
	tay
	pla
	tax
	iny
	jsr spl_name
	bne spl_file
	rts
spl_name:
	lda spool_list,x
	beq splx
	sta temp
splch:	inx
	lda spool_list,x
	jsr xdowncase
	jsr cout
	dec temp
	bne splch
	inx
	jsr crout
	lda spool_list,x
splx:	rts
;************************************************
;
; poll_spool--called during keyboard input
; need not preserve registers
;
poll_spool:
	bit spooling
	bpl poll_maybe
;
; if(printer_ready) {
;   print_char(read(spool_buff));
; }
;
	ldx #mli_read
	ldy spl_prref
	jsr xprint_drvr
	and #1
	beq pollsp_x
;
	bit sp_linefd
	bpl sp_filech
	lda #$80+'J'-ctrl
	lsr sp_linefd
	bpl spchar
;
sp_filech:
	jsr mli
	.byte mli_read
	.addr readspool
	bcs spl_err
;
spcheat:	lda #0	;read here
	ora #$80
	cmp #$80+'M'-ctrl
	bne spchar
	ror sp_linefd
spchar:	ldx #mli_write
	ldy spl_prref
	jsr xprint_drvr
pollsp_x:	rts
;
poll_maybe:
	lda spool_list
	beq poll_nope
	jmp sp_another
poll_nope:	rts
;
spl_err:
	cmp #err_eof
	beq thats_ok
	jsr xbell
thats_ok:
	lda #$80+'L'-ctrl
	ldx #mli_write
	ldy spl_prref
	jsr xprint_drvr
	lda rsref
	jsr close
	jmp spoolnext
;
readspool:	.byte 4
rsref:	.res 1
	.addr spcheat+1
	.addr 1	;read 1 ch
	.addr 0
;
; sp_rmv1 -- remove 1st file from spool_list
;
sp_rmv1:
	ldx spool_list
	inx
	ldy #0
sprmv1:	lda spool_list,x
	sta spool_list,y
	iny
	inx
	bne sprmv1
	rts
;
; findspll -- x=end of spool list
;
findspll:	ldx #-1
fspl1:	inx
	lda spool_list,x
	bne fspl1
	rts
;
; make (p) into a complete pathname
;
spool_full:
	ldy #1
	lda (p),y
	ora #$80
	cmp #$80+'/'
	beq sfx
	ldy #63
sf1:	lda (p),y
	sta pagebuff,y
	dey
	bpl sf1
	lda p+1
	ldy p
	sta sf3+1
	sty sf3
	sta spgetp+2
	sty spgetp+1
	jsr mli
	.byte mli_getpfx
	.addr spgetp
	bcs sferr
	lda #>pagebuff
	ldy #<pagebuff
	jsr xpmgr
	.byte pm_appay
sf3:	.addr 0
sfx:	rts
sferr:	jmp xProDOS_err
spgetp:	.byte 1,0,0


;****************************************
;
; subr -- Davex subroutines
;
;****************************************
makedirt:
	sec
	ror config_dirty
	rts
;
; NOTE--guarantee beq/bne for 0 or >0 params!
;
getnump:
	lda num_parms
	rts
;
; getinfo for a file; path in AY, return type in A
;
; getinfo never returns if an error is detected;
; geti2 does
;
getinfo:
	jsr geti2
	bcc goti
infoerr:	jmp xProDOS_err
goti:	lda info_type
	rts
;
geti2:
	sta ginfopth+1
	sty ginfopth
	lda #10
	sta infoprm
	jsr mli
	.byte mli_gfinfo
	.addr infoprm
	rts
;
setinfo:
	sta ginfopth+1
	sty ginfopth
	lda #7
	sta infoprm
	jsr mli
	.byte mli_sfinfo
	.addr infoprm
	bcs infoerr
	rts
;
infoprm:	.res 1
ginfopth:	.res 2
info_acc:
	.res 1
info_type:
	.res 1
info_auxtype:
	.res 2
info_stype:
	.res 1
info_blocks:
	.res 2
info_moddat:
	.res 2
info_modtim:
	.res 2
info_crdat:
	.res 2
info_crtim:
	.res 2
;******************************************************
;
; directory-scanning subroutine
;
; scanall -- scan through all command directories for
;  a file (path in AY).  Return BCS if not found;
;  otherwise path is at $280 and A=file type.
;
scanptr:	.res 1
;
scanall:
	sta p+1
	sty p
	ldy #0
	lda (p),y
	beq cmd_err
	cmp #63
	bcc cmd_ok
cmd_err:	sec
	rts
cmd_ok:
	iny
	lda (p),y
	ora #%10000000
	cmp #$80+'/'
	bne part_path
;
; full pathname specified; try once
;
	ldy #127
copyfull:	lda (p),y
	sta cmdpath,y
	dey
	bpl copyfull
	jmp cmdinfo
;
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
scan_more:	sta count
	cmp #1
	bne not_curdir
	lda scanlist+1,x
	ora #%10000000
	cmp #$80+'*'
	bne not_curdir
	ldy #0
	sty cmdpath
	beq trycurdir
not_curdir:
	ldy #0
copy_part:	lda scanlist,x
	sta cmdpath,y
	inx
	iny
	dec count
	bpl copy_part
trycurdir:	lda p+1
	ldy p
	jsr pmgr
	.byte pm_appay
	.addr cmdpath
;
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
;
	jsr cmdinfo
	bcs cmd_noper
	rts
cmd_noper:	ldx scanptr
	txa
	sec
	adc scanlist,x
	sta scanptr
	jmp scan1
;
; GetInfo on CmdPath; return SEC/CLC;
; errcode or file type in A
;
cmdinfo:
	lda #>cmdpath
	ldy #<cmdpath
	sta ginfopth+1
	sty ginfopth
	lda #10
	sta infoprm
	jsr mli
	.byte mli_gfinfo
	.addr infoprm
	bcs cmderr
	lda info_type
cmderr:	rts
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
	sta qcref2
	sta qcref3
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
	jsr xdirty
is77:
; supply '%help' help-dir path if none is recorded
	lda cfghelp
	bne HasHelp
	jsr xpmgr
	.byte pm_copy
	.addr DefaultHelp,cfghelp
HasHelp:
	rts

DefaultHelp:
	.byte 5
	asc "%help"

;
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
	bmi gpchk
config_pn:

	.byte 6
	asc "config"

;*********************************************
open_config:
	jsr mli
	.byte mli_open
	.addr ocfg_parms
	lda cfg_ref
	sta cfgref2
	rts
ocfg_parms:
	.byte 3
	.addr mypath
	.addr filebuff2
cfg_ref:	.res 1
;
rw_config:
	sta config_rw
	jsr mli
config_rw:
	.byte 0
	.addr crw_parms
	rts
;
crw_parms:
	.byte 4
cfgref2:	.res 1
	.addr shell_gp
	.addr config_len
	.addr 0
;
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
sc_err:	jsr xmess
	asc "[Unable to save %config]"
	.byte 0
	clc
	rts
;
create_cfg:	jsr mli
	.byte mli_create
	.addr crcfg_parms
	bcc crcfg_x
	cmp #err_dupfil
	beq crcfg_x
	sec
	rts
crcfg_x:	clc
	rts
;
crcfg_parms:	.byte 7
	.addr mypath
	.byte %11000011
	.byte $5A	;config file
	.addr $8005	;Davex 8 config file
	.byte 1
	.addr 0,0
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
;*********************************************
;
; find_mydir --
;
;   should be called ONCE right after Davex
;   is entered.  Looks at $280 to find path
;   of Davex, prepends system prefix if the
;   path at $280 is partial, and strips the
;   entryname from the full pathname
;
find_mydir:
	jsr mli
	.byte mli_getpfx
	.addr fdir_pfx
	lda $281
	ora #%10000000
	cmp #$80+'/'
	bne fdir_partial
	lda #0
	sta mypath
fdir_partial:
	lda #>$280
	ldy #<$280
	jsr pmgr
	.byte pm_appay
	.addr mypath
;
	jsr xpmgr
	.byte pm_downcase
	.addr mypath
;
	ldx #79
keep_all:	lda mypath,x
	sta mypath_all,x
	dex
	bpl keep_all
;
	ldx mypath
strip_mp:	dex
	beq stmp_x
	lda mypath,x
	ora #%10000000
	cmp #$80+'/'
	bne strip_mp
stmp_x:	stx mypath
	stx mydir_len
	rts
fdir_pfx:	.byte 1
	.addr mypath
;
; do_autoexec -- execute file spec'd in startup buffer, if
;                the file exists
;
do_autoexec:
	lda #>exec_pn
	ldy #<exec_pn
	sta ginfopth+1
	sty ginfopth
	jsr fixup_path_ay
	lda #10
	sta infoprm
	jsr mli
	.byte mli_gfinfo
	.addr infoprm
	bcs no_aexec
;
	lda #>exec_pn
	ldy #<exec_pn
	jsr begin_iredir
no_aexec:	rts
;
; plural -- if ay<>1, print 's'
;
plural:
	cmp #0
	bne plur_s
	cpy #1
	bne plur_s
	rts
plur_s:	jsr xmess
	asc "s"
	.byte 0
	rts
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
	cmp #$80+'/'
	beq fullpn
	lda p+1
	pha
	lda p
	pha
	jsr print_pfx
	lda #$80+'/'
	jsr cout
	pla
	sta p
	pla
	sta p+1
fullpn:	lda p+1
	ldy p
	jmp xprint_path
;
; check_wait -- pause display & allow abort (SEC)
;
; For Textalker (Echo) users: Ctrl-X STAYS on kbd
;
stepping:
	.byte 0
check_wait:
	jsr xpoll_io
	bit stepping
	bmi cw_wait
	lda $c000
	bpl cw_x
	cmp #$80+'X'-ctrl
	beq cw_x
	cmp #$9b	;esc
	beq cw_xxx
	cmp #$80+'C'-ctrl
	beq cw_abort
	cmp #$80+'S'-ctrl
	beq cw_wait
	jsr chk_appleper
	cmp #$80+' '
	bne cw_x
	sta $c010
cw_wait:	jsr xpoll_io
	lda $c000
	bpl cw_wait
	sta $c010	;munch bad chars in case type-ahead active
	jsr CheckHC
	bcc cw_wait
	cmp #$9b
	beq cw_xxx
	cmp #$80+'C'-ctrl
	beq cw_abort
	cmp #$80+'X'-ctrl
	beq cw_xx
	cmp #$80+'S'-ctrl
	beq cw_done
	cmp #$80+'Q'-ctrl
	beq cw_done
	jsr chk_appleper
	cmp #$a0
	bne cw_x	;was cw_wait
	ror stepping
	clc
	rts
cw_done:	sta $c010
cw_x:	clc
cw_xx:	php
	lsr stepping
	plp
	rts
cw_xxx:	jsr crout
	sta $c010
	lsr stepping
	sec
	rts
cw_abort:	sta $c010
	lsr stepping
	jmp yn_abort
;
chk_appleper:
	cmp #$80+'.'
	bne notAper
	bit button0	;Apple
	bpl notAper
	ldx $fbb3
	cpx #6
	beq cw_abort
notAper:	rts
;
close:
	sta mycl_r
	jsr mli
	.byte mli_close
	.addr mycls
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
ep_usepfx:	jmp get_pfx
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
per_add:	lda num2,x
	adc num3,x
	sta num2,x
	inx
	dey
	bne per_add
	inc perc
	bne per_while
per_whilex:	lda perc
	rts
perc:	.byte 0
;
; show_percent -- info_blocks/info_auxtype
;
;   ' (xx%)'
;
show_percent:
	jsr xmess
	asc "  ("
	.byte 0
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
	jsr xmess
	asc "%)"
	.byte 0
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
	bne needpx
	lda mydir_len
	sta mypath
	jsr mli
	.byte mli_setpfx
	.addr needp_p
	jsr go_top	;17-Jun-89
needpx:	rts
;
needp_p:	.byte 1
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
	beq fixedup
	iny
	jsr pchar
	cmp #$80+'%'
	beq fp_shelld
	cmp #$80+'.'
	beq fixup_dot
fixedup:	rts
;
fp_shelld:
	jsr shorten_p
	ldy #1
	jsr pchar
	cmp #$80+'/'
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
;
fixup_dot:
	ldy #0
	lda (p),y
	cmp #2
	bcc not_parent
	ldy #2
	jsr pchar
	cmp #$80+'.'
	bne not_parent
; .. = parent directory
	jsr shorten_p
	jsr shorten_p
	ldy #0
	lda (ptr),y
	beq parent_nosl
	iny
	jsr pchar
	cmp #$80+'/'
	bne parent_nosl
	jsr shorten_p
parent_nosl:	sec	;flag '..'
	.byte $24
singleDOT:	clc	;flag '.'
	php
	jsr mli
	.byte mli_getpfx
	.addr dotdotPARMS
	jsr xpmgr
	.byte pm_downcase
	.addr pagebuff
	plp
	bcc not_dotdot
	jsr xpmgr
	.byte pm_up
	.addr pagebuff
	lda pagebuff
	cmp #1
	bne not_dotdot
	dec pagebuff
not_dotdot:
	jmp splice_dot
;
dotdotPARMS:	.byte 1
	.addr pagebuff
;
not_parent:
; check for .sd
	ldy #0
	lda (p),y
	cmp #3
	bcc chk_dot
	ldy #2
	jsr pchar
	cmp #$80+'1'
	bcc chk_dot
	cmp #$80+'8'
	bcs chk_dot
	and #%00001111
	asl a
	asl a
	asl a
	asl a
	sta temp
	iny
	jsr pchar
	cmp #$80+'1'
	bcc fixedup2
	cmp #$80+'3'
	bcs fixedup2
	and #%00000001
	ror a
	ror a
	ora temp
	eor #%10000000
	jsr online1
	jmp splice_sd
fixedup2:	rts
;
chk_dot:
	jsr shorten_p
	ldy #0
	lda (ptr),y
	beq singleDOT
	iny
	jsr pchar
	cmp #$80+'/'
	bne singleDOT
	jsr shorten_p
	jmp singleDOT
;
online1:	sta o1_dev
	jsr mli
	.byte mli_online
	.addr o1_parms
	bcc o1ok
	jmp xProDOS_err
o1ok:	lda pagebuff+1
	and #%00001111
	tax
	inx
	inx
	stx pagebuff
	lda #'/'	;14-Oct-89 DAL
	sta pagebuff+1
	sta pagebuff,x
	jsr xpmgr
	.byte pm_downcase
	.addr pagebuff
	rts
;
o1_parms:	.byte 2
o1_dev:	.res 1
	.addr pagebuff+1
;
splice_dot:	ldy #0
	lda (ptr),y
	sta temp
	inc temp
	ldy #1
	bne splpth2
;
splice_sd:
	ldy #0
	lda (ptr),y
	sta temp
	inc temp
	ldy #4
	lda (ptr),y
	ora #%10000000
	cmp #$80+'/'
	bne splpth2
	iny
splpth2:	cpy temp
	bcs splpth3
	lda (ptr),y
	inc pagebuff
	ldx pagebuff
	sta pagebuff,x
	iny
	bne splpth2
splpth3:	ldy #127
splpth_cb:	lda pagebuff,y
	sta (ptr),y
	dey
	bpl splpth_cb
	rts
;
; shorten_p -- remove 1st character of
;              path at P
;
shorten_p:	ldy #0
	lda (p),y
	beq shpx
	tax
shp1:	iny
	iny
	lda (p),y
	dey
	sta (p),y
	dex
	bne shp1
	lda (p,x)
	sec
	sbc #1
	sta (p,x)
shpx:	rts
;
; pchar -- get (p),y in lowercase, high bit on
;
pchar:	lda (p),y
	jmp xdowncase
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
mmgr:
	cpx #mli_close
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
;
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
mmw_err:	lda #der_outmem
	sec
	rts
;
mm_nwr:	cpx #mli_gfinfo
	bne mm_ninfo
;
; getinfo: A=low page
;
	lda #0	;open 0 pages
	beq mmopen	;always
;
mm_ninfo:	cpx #mli_open
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
;
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
;
mm_nrd:
	lda #err_badcall
	sec
	rts
;****************************************
;
; If there are any $FF00 vectors in the
; block-device table corresponding to
; devices not in the device list, change
; the vector to the no-device vector
;
FixRAMvect:
	ldx #$1e
frv1:	lda $BF10,x
	bne frv_ok
	lda $BF11,x
	cmp #$ff
	bne frv_ok
	txa
	asl a
	asl a
	asl a
	jsr ChkDevLst	;clc=found
	bcc frv_ok
	lda $BF10
	sta $BF10,x
	lda $BF11
	sta $BF11,x
frv_ok:	dex
	dex
	bne frv1
	rts
;
; Return CLC: device A is in DevLst
; (preserve X!)
;
ChkDevLst:
	sta the_dev
	ldy $bf31
cdl1:	lda $bf32,y
	and #%11110000
	cmp the_dev
	beq cdl_yes
	dey
	bpl cdl1
	sec
	rts
cdl_yes:	clc
	rts
the_dev:	.res 1
;****************************************


;****************************************
;
; shell/runcmd -- SYS/BIN/S16 file runner
;                 for Davex
;
;****************************************
;
run_s16:
	jsr notspool
	sec
	jsr $fe1f	;IIgs?
	bcs typerr
	lda #>bridge_name
	ldy #<bridge_name
	jsr xbuild_local
	sta br_ugh+2
	sty br_ugh+1
	ldx #63
br_ugh:	lda $ffff,x
	and #$7f	;23-Feb-88
	sta $2c0,x
	dex
	bpl br_ugh
;
	ldx #3
cpdave:	lda dave,x
	.byte $9f,$02,$01,$01 ;STA $010102,X
	dex
	bpl cpdave
;
	ldx #63
cpys16:	lda cmdpath,x
	and #$7f	;ProDOS 16 cares about high bit!
	.byte $9f,$06,$01,$01 ;STA $010106,X
	lda mypath_all,x
	and #$7f
	.byte $9f,$46,$01,$01 ;STA $010146,X
	dex
	bpl cpys16
	jsr mli
	.byte mli_bye
	.addr s16p
	.byte 0	;single-byte BRK
s16p:	.byte 4,$ee
	.addr $2c0,0
;
bridge_name:
	.byte 10
	asc "BRIDGE.S16"
dave:	asc "DAVE"
;
run_something:
	cmp #tSYS
	beq is_sys
	cmp #tS16
	beq run_s16
	cmp #$B5	;can run EXE files, too!
	beq run_s16
	cmp #$2E	;$2E;$8001 is a Dvx command
	bne cmdNot2E
	ldx info_auxtype+1
	cpx #$80
	bne cmdNot2E
	ldx info_auxtype
	cpx #$01
	beq run_ext0
cmdNot2E:	cmp #tBIN
	bne typerr
run_ext0:	jmp run_external
typerr:	pha
	jsr xmess
	asc "Can't run '"
	.byte 0
	pla
	jsr xprint_ftype
	jsr xmess
	asc "' files"
	.byte cr,0
	jmp xerr
;
is_sys:
	jsr notspool
	jsr finish_oredir
	jsr finish_iredir
	jsr chk_argu
	ldx #127
copy280:	lda cmdpath,x
	jsr upcase	; 28-Jul-87
	and #$7f	;
	sta $280,x
	dex
	bpl copy280
	lda #0
	sta level
	jsr close
	jsr open_sys
	bcs run_err
;
; if '-n' parameter given, don't
; replace quit code
;
	lda #$80+'n'
	jsr xgetparm_ch
	bcc no_return
	jsr write_quit
	jsr my_quit
no_return:	jsr copy_loader
	jsr off80
	jsr $fe89
	jsr $fe93
	jsr normal
	jsr home
	lda #>cmdpath
	ldy #<cmdpath
	jsr xprint_path
	jsr xmess
	asc "..."
	.byte cr,0
	jsr hook_speech
	lda $3f3
	sta $3f4
;
	lda #$ff	;disconnect NMI
	ldy #$59
	sta $3fd
	sty $3fc
;
	lda #0
	ldx #23
clearbm1:	sta bitmap,x
	dex
	bne clearbm1
	lda #%11001111
	sta bitmap+0
	lda #1
	sta bitmap+BitMapSize-1
	jmp $1800
run_err:	rts
;
; open system file & store refnum into
; loader code
;
open_sys:
	lda #stdlevel
	sta level
	jsr mli
	.byte mli_open
	.addr loader_open
	bcs loadopx
	lda loadref1
	sta loadref2
	sta loadref3
loadopx:	rts
loader_open:	.byte 3
	.addr cmdpath
	.addr filebuff
loadref1:	.byte 0
;
; save current quit code into %config if it does not
; belong to this incarnation of Davex.
;
write_quit:	;use filebuff2
	bit $c083
	bit $c083
	ldx #0
getq:	lda $d100,x
	sta filebuff3,x
	lda $d200,x
	sta filebuff3+$100,x
	lda $d300,x
	sta filebuff3+$200,x
	dex
	bne getq
	bit $c082
	lda filebuff3
	cmp myqcode
	bne notmine
	lda filebuff3+1
	cmp myqcode+1
	bne notmine
	lda filebuff3+2
	cmp myqcode+2
	bne notmine
	ldy mypath_all	;was #79 (15-Oct-89)
qmine:	lda mypath_all,y
	cmp filebuff3+mypath_all-myqcode,y
	bne notmine
	dey
	bpl qmine
offline:	rts
notmine:
	lda #>config_pn
	ldy #<config_pn
	jsr xbuild_local
	jsr open_config
	bcs offline
	sta qcref2
	sta qcref3
	jsr posit_qcode
	jsr mli
	.byte mli_write
	.addr wr_quitc
	bcs wrq_err
	lda qcref2
	jmp close
wrq_err:	jmp xProDOS_er
;
posit_qcode:
	jsr mli
	.byte mli_setmark
	.addr kill_qc
	bcs wrq_err
	rts
;
; get_quitcode -- load quit code from %config
; if present; return with CLC if successful, SEC
; if not
;
gotqc:	rts
get_quitcode:
	bit $c083
	lda $d100
	ldx $d101
	ldy $d102
	bit $c082
	cmp myqcode
	bne gotqc
	cpx myqcode+1
	bne gotqc
	cpy myqcode+2
	bne gotqc
;
	lda #>config_pn
	ldy #<config_pn
	jsr xbuild_local
	jsr open_config
	bcs reload_x
	sta qcref2
	sta qcref3
	jsr posit_qcode
	jsr mli
	.byte mli_read
	.addr wr_quitc
	bcs reload_x
	bit $c083
	bit $c083
	ldx #0
reload1:	lda filebuff3,x
	sta $d100,x
	lda filebuff3+$100,x
	sta $d200,x
	lda filebuff3+$200,x
	sta $d300,x
	dex
	bne reload1
	bit $c082
	jsr mli
	.byte mli_seteof
	.addr kill_qc
reload_x:	jmp close_config
;
wr_quitc:	.byte 4
qcref2:
	.byte 0
	.addr filebuff3
	.addr $300	;length of QUIT code
	.addr 0
;
kill_qc:	.byte 2
qcref3:
	.byte 0
	.addr config_len
	.byte 0
;
; install Quit code to return to MYPATH_ALL
;
my_quit:
	bit $c083
	bit $c083
	ldx #0
myquit1:	lda myqcode,x
	sta $d100,x
	lda myqcode+$100,x
	sta $d200,x
	lda myqcode+$200,x
	sta $d300,x
	dex
	bne myquit1
	bit $c081
	rts
;
; myqcode -- code to return to the shell;
; must run at $1000
;
myqcode:
	cld
	sed
	cld
	lda $c082
	sta $c00c
	jsr $fe89
	jsr $fe93
	jsr normal
	jsr $fb2f	;13-Jun-87
	jsr $fc58	;home
	lda $3f3
	sta $3f4
; init brkv
	lda #$fa
	sta $3f1
	lda #$59
	sta $3f0	;brkv
	lda #0
	sta level
	jsr mli
	.byte mli_close
	.addr qt_closeall-myqcode+$1000
	ldx #23
	lda #0
clearbm2:
	sta bitmap,x
	dex
	bne clearbm2
	lda #%11001111
	sta bitmap+0
	lda #1
	sta bitmap+BitMapSize-1
	ldx #79
copympx:	lda mypath_all-myqcode+$1000,x
	sta $280,x
	dex
	bpl copympx
rtn_again:
	jsr mli
	.byte mli_open
	.addr qt_open-myqcode+$1000
	bcs qt_err
	lda qt_ref-myqcode+$1000
	sta qt_ref2-myqcode+$1000
	jsr mli
	.byte mli_read
	.addr qt_read-myqcode+$1000
	bcs qt_err
	jsr mli
	.byte mli_close
	.addr qt_closeall-myqcode+$1000
	jmp $2000
qt_err:	jsr home
	jsr mli
	.byte mli_close
	.addr qt_closeall-myqcode+$1000
	ldx #0
qtprob1:	lda qtprobmsg-myqcode+$1000,x
	beq qtprobx
	jsr cout
	inx
	bne qtprob1
qtprobx:
	lda #$e
	jsr qtone
	lda #$0c
	jsr qtone
	lda #$e
	jsr qtone
	jsr $fd0c
	jsr home
	jmp rtn_again-myqcode+$1000
qtprobmsg:
	asc "Unable to return to Davex"
	.byte cr,cr
	asc "Hit a key to try again..."
	.byte 0
qtone	= *-myqcode+$1000
	ldx #200
qton1:	pha
	jsr $fca8
	lda spkr
	pla
	dex
	bne qton1
	rts
;
mypath_all:
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;
qt_closeall:	.byte 1
	.byte 0
;
qt_open:	.byte 3
	.addr mypath_all-myqcode+$1000
	.addr $800
qt_ref:	.byte 0
;
qt_read:	.byte 4
qt_ref2:	.byte 0
	.addr $2000
	.addr $ffff
	.addr 0
;***********************************
;
; off80
;
off80:
	jsr finish_oredir
	jsr xmess
	.byte $80+'U'-ctrl,$80+'T'-ctrl,$80+'A',$80+'1',0
	jsr $fe89
	jsr $fe93
	jsr hook_speech
	lda #40
	sta scr_width
	jmp home
;
; copy_loader -- move real loader down to $1800
;
copy_loader:
	ldx #0
copyl1:	lda loader,x
	sta $1800,x
	dex
	bne copyl1
	rts
;
; LOADER -- code to run at $1800 to load and
; run a SYS file
;
loader:
	jsr mli
	.byte mli_read
	.addr loader_read-loader+$1800
	bcs loader_err
	jsr mli
	.byte mli_close
	.addr loader_close-loader+$1800
	bcs loader_err
; copy startup argument if present
	ldy $1F80
	beq ld_nostrarg
ld_copyarg:
	lda $1F80,y
	sta $2006,y
	dey
	cpy #-1
	bne ld_copyarg
ld_nostrarg:
	jsr home
	ldx #$f8
	txs
	jmp $2000
loader_err:
	pha
	jsr home
	ldx #6
lderr1:	lda lderrmsg-loader+$1800,x
	jsr cout
	dex
	bpl lderr1
	pla
	jsr $fdda
	lda $3f3
	sta $3f4
	jsr $fd0c
;dfb 0,0
	jsr mli
	.byte mli_bye
	.addr ldbye-loader+$1800
	jmp ($fffc)
ldbye:	.byte 4,0,0,0,0,0,0
lderrmsg:
	asc "$ rorrE"
;
loader_read:
	.byte 4
loadref2:
	.byte 0
	.addr $2000
	.addr $ffff
	.addr 0
loader_close:
	.byte 1
loadref3:
	.byte 0
;
; chk_argu -- scan for a string parameter
; (after a SYS file name); give error if there
; is no Startup buffer large enough, else
; return string at $1F80
;
chk_argu:
	lda #>sysparms
	ldy #<sysparms
	sta cmd_ptr+1
	sty cmd_ptr
	jsr parse_parms
	lda #0
	jsr xgetparm_n
	sta ptr+1
	sty ptr
	ldy #127
copyarg:	lda (ptr),y
	sta $1F80,y
	dey
	bpl copyarg
	lda $1F80
	bne arg_given
	rts
arg_given:
	lda #>cmdpath
	ldy #<cmdpath
	jsr startup_size
	cmp #0
	beq null_buffer
	tax
	dex
	cpx $1F80
	bcc small_buffer
	rts
;
small_buffer:
	lda #der_smallsbf
bf_err:	jmp xProDOS_err
null_buffer:
	lda #der_nosbf
	bne bf_err
;
sysparms:
	asc "x"
	.byte 0
	.addr 0
	.byte 0,t_string
	.byte $80+'n',t_nil
	.byte 0,0
;**************************************************
;
; run_external -- load a BIN or $2E;8001 file,
; parse its parameters, and run it
;
run_external:
	lda #>cmdpath
	ldy #<cmdpath
	jsr startup_size
	lda pagebuff
	cmp #$60
	bne notxtrn
	lda #$ee
	cmp pagebuff+1
	bne notxtrn
	cmp pagebuff+2
	bne notxtrn
;
	lda pagebuff+x_minver
	cmp #myBakVer
	bcc vers_err
	cmp #myversion
	bne did_chkver
	lda pagebuff+12	;13-Mar-88 DL
	and #$0f
	cmp #AuxVersion
did_chkver:
	beq ver_okay
	bcc ver_okay
;
vers_err:
	jsr xmess
	asc "External cmd not compatible with this version of Davex."
	.byte cr,0
	jmp xerr
;
notxtrn:
	lda #der_notxtn
	jmp xProDOS_err
;
; version ok -- load external cmd
;
xtn_err:	jmp xProDOS_err
ver_okay:
	lda pagebuff+x_loadadr+1
	ldy pagebuff+x_loadadr
	sta xtn_addr+1
	sty xtn_addr
	cmp #>copybuff
	beq adr_err
	bcs adr_ok
adr_err:	lda #der_adrlow
	bne der4
adr_ok:
;
; check OK hardware
;
	lda xc_req
	eor #%11111111
	and pagebuff+x_reqbits
	beq reqs_ok
	lda #der_badhware
der4:	jmp xProDOS_err
reqs_ok:
;
; turn off 80col if necessary
;
	bit pagebuff+x_reqbits
	bpl keep80
	lda scr_width
	cmp #80
	ror suspend80	;set if was 80col
	jsr off80
keep80:
;
	jsr xtn_open
	bcs xtn_err
	jsr xtn_read
	bcs xtn_err
	lda xtn_ref
	jsr close
;
	clc
	lda xtn_addr
	adc #x_parmtbl
	sta cmd_ptr
	lda xtn_addr+1
	adc #>x_parmtbl
	sta cmd_ptr+1
;
	lda pagebuff+x_goadr+1
	ldy pagebuff+x_goadr
	sta cmd_addr+1
	sty cmd_addr
; tell mmgr about us
	ldx #mli_write
	lda xtn_addr+1
	jsr mmgr
	bcs xcerr
; clc
	rts
xcerr:	jmp xProDOS_err
;
xtn_open:
	jsr mli
	.byte mli_open
	.addr xtnop
	rts
xtn_read:
	lda xtn_ref
	sta xtn_ref2
	jsr mli
	.byte mli_read
	.addr xtnrd
	rts
;
xtnop:	.byte 3
	.addr cmdpath
	.addr filebuff
xtn_ref:	.byte 0
;
xtnrd:	.byte 4
xtn_ref2:	.byte 0
xtn_addr:	.byte 0,0
	.addr highmem-copybuff
	.addr 0


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
;
	inc wild_state
	bit wild_flags
	bvc wnvolz	;%%% ???
	inc wild_state	;exp voltbl
wnvolz:
	jsr push_level
	lda #>wildstring1
	ldy #<wildstring1
	jsr getinfo
	cmp #tDIR
	beq w_isDIR
	lda #der_notdir
	jmp xProDOS_err
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
;
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
ask_path:	jsr TalkCont
askpath2:
	jsr print_cmd
	jsr pr_sp
	lda #0
	jsr xgetparm_n
	jsr xprint_path
	lda parmtypes+1
	cmp #t_path
	beq do2
	cmp #t_wildpath
	bne skip2
do2:	jsr pr_sp
	lda #1
	jsr xgetparm_n
	jsr xprint_path
skip2:
	bit wild_flags
	bpl noquery
	lda #$80+'n'	;default = No
	jsr xyesno2
	jsr restore
	beq nxtwld
	clc
	rts
;
noquery:
	jsr crout	;5-Jul-87
no_askpath:
	jsr restore
	clc
	rts
;
wnfin1:	jsr dir_finish
	dec wild_state
wn_done:	sec
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
	bcc dset_noErr
	jmp xProDOS_err
dset_noErr:	rts
;
dir_setup2:	;partial path in AY
	pha
	tya
	pha
	lda dir_level
	bpl dsdlx
	lda #0
	sta direcpath
dsdlx:
	pla
	tay
	pla
	jsr buildcatpath
	lda #wildlevel
	sta level
	jsr mli
	.byte mli_open
	.addr opendir_p
	pha
	lda #stdlevel
	sta level
	pla
	bcc dset_opened
	rts
dset_opened:
	lda dir_ref
	sta dir_ref2
	sta dir_ref3
	sta dir_ref4
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
;
	lda EntPerBlock
	sta filecntr
;
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
wld_err:	jmp xProDOS_err
;
; read next active entry & dec file_count
;
read1dir:
	lda EntryLen
	sta rc_len
	jsr mli
	.byte mli_read
	.addr readcat_parms
	bcc rc_ok
	cmp #err_eof
	beq eoDIR
	jmp xProDOS_err
eoDIR:	sec
	rts
rc_ok:
	dec filecntr
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
;
	lda file_count
	bne nodecfc
	dec file_count+1
nodecfc:	dec file_count
; 11-Jun-89
	jsr calc_cmask
	ldy #1
	ldx #15
niceCase:	asl case_mask+1
	rol case_mask
	bcc NoLcase
	lda catbuff,y
	jsr xdowncase
	and #$7f
	sta catbuff,y
NoLcase:	iny
	dex
	bne niceCase
; zero out unused name bytes (for sorting)
	lda catbuff
	and #$f
	tay
	lda #0
zernamb:	cpy #15
	bcs zerdnam
	sta catbuff+1,y
	iny
	bne zernamb
zerdnam:	clc
	rts
;
; close file & pop level of dirstack
;
dir_finish:
	jmp pop_level
;
opendir_p:	.byte 3
	.addr direcpath
	.addr wildbuff
dir_ref:	.res 1
;
readcat_parms:	.byte 4
dir_ref2:	.res 1
	.addr catbuff
rc_len:	.addr 0
	.res 2
	rts
;
; do not change order or insert
file_count:
	.res 2
filecntr:	.res 1	;counts down to 0 for each block
; end of do-not-change
EntryLen:
	.res 1
EntPerBlock:
	.res 1
;
; getmark into ay
;
getmark:
	jsr mli
	.byte mli_getmark
	.addr mark_parms
	lda pmark+1
	ldy pmark
	rts
setmark:	sta pmark+1
	sty pmark
	lda #0
	sta pmark+2
setmark2:	jsr mli
	.byte mli_setmark
	.addr mark_parms
	rts
;
mark_parms:	.byte 2
dir_ref3:	.res 1
pmark:	.res 2
	.byte 0
;
read1byte:	jsr mli
	.byte mli_read
	.addr read1p
	bcs r1x
dcheat:	lda #0
r1x:	rts
;
read1p:	.byte 4
dir_ref4:	.res 1
	.addr dcheat+1
	.addr 1
	.addr 0
;
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
appdirp:	iny
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
appdirpx:	rts
appdpx:	.res 1
;
bcp_full:	ldy #64
bcpf2:	lda (p),y
	sta direcpath,y
	dey
	bpl bcpf2
	jmp needslash
;*******************************************
push_level:
	lda dir_level
	bmi pl_nolevel
;
	jsr getmark
	lda #wildlevel
	sta level
	lda dir_ref
	jsr close	;close this level
	lda #stdlevel
	sta level
;
	lda dir_level
	cmp #dstkmax
	bcc dlevelok
	lda #der_levels
	jmp xProDOS_err
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
pushmore:	lda file_count-dstk_fcount,y
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
pl_nolevel:	inc dir_level
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
	lda #-1
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
popdirp:	lda (p),y
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
;
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
	cmp #$80+'/'
	bne cwnslsh
;sec
	ror temp
cwnslsh:
	cmp #$80+'*'
	beq cwyes0
	cmp #$80+'='
	beq cwyes
	cmp #$80+'?'
	bne cwno
	lda #%10000000	;query flag
	ora wild_flags
	sta wild_flags
cwyes0:	lda #$80+'='
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
	cmp #$80+'/'
	bne not_wvol
	ldx #1	;'/' count
wvolchk:	iny
	cpy wild_index
	bcs wvchecked
	lda wildstring1,y
	ora #%10000000
	cmp #$80+'/'
	bne wvolchk
	inx
	bne wvolchk
wvchecked:	cpx #2
	bcs not_wvol
	lda #%01000000	;wc in volname
	ora wild_flags
	sta wild_flags
not_wvol:
	jsr build_wpath
	clc
	rts
;
extra_wild:	lda #der_1wild
der5:	jmp xProDOS_err
;
bad_place:	lda #der_badwild
	bne der5
;
; build_wpath -- copy part of wildstring1 before
; segment with wildcard into wdirpath
;
build_wpath:
	ldy wild_index
bwp2:	lda wildstring1,y
	ora #%10000000
	cmp #$80+'/'
	beq bwp_len
	dey
	bne bwp2
; wc in seg1 of partial path; use prefix
	ldx wildstring1
wseg2:	lda wildstring1,x
	sta wildseg,x
	dex
	bpl wseg2
	jsr mli
	.byte mli_getpfx
	.addr wildpfx
	jsr xpmgr
	.byte pm_downcase
	.addr wildstring1
	rts
wildpfx:	.byte 1
	.addr wildstring1
;
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
;
compare_wild:
	bit wild_flags
	bvc cmpw_notvol
; allow wild volumes later?
	lda #der_badwild
	jmp xProDOS_err
;
cmpw_notvol:
	jsr cmp_wseg
	bcs cmpwno
	lda #0
	jsr xgetparm_n
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
; = must match at least 0 characters
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
;
	jmp cmp_right
cmppw_no:	sec
	rts
;
; cmp_left -- return CLC if chars in WILDSEG
; before wildcard match chars at beginning
; of path at CATBUFF
;
cmp_left:
	ldy #0
cleft1:	lda wildseg+1,y
	jsr xdowncase
	cmp #$80+'='
	beq cleftok
	sta temp
	lda catbuff+1,y
	jsr xdowncase
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
cleftno:	sec
	rts
;
; cmp_right -- return CLC if chars in WILDSEG
; after wildcard match chars at end of path
; at CATBUFF
;
cmp_right:
	ldy wildseg
	ldx catbuff
cright1:	lda wildseg,y
	jsr xdowncase
	cmp #$80+'='
	beq crightok
	sta temp
	lda catbuff,x
	jsr xdowncase
	cmp temp
	bne crightno
	dex
	dey
	bne cright1
crightok:	clc
	rts
crightno:	sec
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
	jsr xgetparm_n
	sta p+1
	sty p
	ldy #127
grab1:	lda (p),y
	sta wildstring1,y
	dey
	cpy #-1
	bne grab1
;
	lda parmtypes+1
	cmp #t_path
	beq grab2a
	cmp #t_wildpath
	bne grabbed
grab2a:	lda #1
	jsr xgetparm_n
	sta p+1
	sty p
	ldy #127
grab2:	lda (p),y
	sta wildstring2,y
	dey
	cpy #-1
	bne grab2
grabbed:	rts
;
; expand_wild -- generate first path from
; catbuff & wildstring1.  If there's a second
; path, replace any wild character in it with the
; same string the wild character in the 1st
; path replaces
;
expand_wild:
	lda #0
	jsr xgetparm_n
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
	beq repl2x
	lda #1
	jsr xgetparm_n
	sta p+1
	sty p
	lda #0
	tay
	tax
	sta (p),y
repl2:	cpx wildstring2
	bcs repl2x
	inx
	lda wildstring2,x
	jsr replch
	jmp repl2
repl2x:	rts
;
; replch -- add char or WILDREPACE onto
; second parameter
;
replch:
	ora #%10000000
	cmp #$80+'?'
	beq replwc
	cmp #$80+'*'
	beq replwc
	cmp #$80+'='
	bne repl_addch
;
replwc:
	txa
	pha
	ldx matchstr_left
appmatch:	cpx matchstr_r
	bcs appmatchx
	lda catbuff,x
	jsr repl_addch
	inx
	bne appmatch
appmatchx:	pla
	tax
	rts
;
repl_addch:	pha
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
wc_outr:	lda #der_outroom
	jmp xProDOS_err


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
;
pm_disp:	.addr pm_doappay-1
	.addr pm_doappch-1
	.addr pm_doup-1
	.addr pm_doslashif-1
	.addr pm_docopy-1
	.addr pm_dodownc-1
;*********************************************
pmfetch2:	jsr pmfetch
	sta pmpath2
	jsr pmfetch
	sta pmpath2+1
	rts
;*********************************************
pmfetch:	inc pmptr
	bne pmptrok
	inc pmptr+1
pmptrok:	ldy #0
	lda (pmptr),y
	rts
;*********************************************
pmgr:
	sta pmpath1+1
	sty pmpath1
	pla
	sta pmptr
	pla
	sta pmptr+1
	jsr pmfetch
	cmp #pm_last+1
	bcc pmgr_ok
	.byte 0	;single-byte brk
pmgr_ok:	jsr pmgr2
	lda pmptr+1
	pha
	lda pmptr
	pha
	lda pmpath1+1
	ldy pmpath1
	rts
;
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
pmapped:	rts
;
pm_doappch:
	jsr pmfetch2
	lda pmpath1+1	;a
	jmp pm_app2
;
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
;
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
;
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
pmcopy1:	lda (pmpath1),y
	sta (pmpath2),y
	dey
	cpy #$ff
	bne pmcopy1
	rts
;
pm_app2:	sty pm_y
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
;
pm_dodownc:
	jsr pmfetch2
	ldy #0
	lda (pmpath2),y
	beq downcxx
	tay
pmdown1:	lda (pmpath2),y
	jsr xdowncase
	and #$7f
	sta (pmpath2),y
	dey
	bne pmdown1
downcxx:	rts
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
;
n_hcl:	cpx #mli_write
	bne n_hwr
;
; write string (AY) to history list
;
	sta p2+1
	sty p2
histwr0:	jsr count_history
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
;
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
histwr1:	lda (p2),y
	sta (p),y
	dey
	cpy #-1
	bne histwr1
	clc
	rts
;
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
;
n_hrd:
	sec
	lda #err_badcall
	rts
;
; return size of history (A)
;
count_history:
	ldx #-1
	jsr point_history
counth1:	inx
	jsr next_hist
	cpy #0
	bne counth1
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
	ldy #-1
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
;*********************************************


;***********************************************************
;
; File manager for Davex  -- USES PAGEBUFF!
;
;***********************************************************
;
; Note--this implementation can keep track of just ONE
;       file at a time; future implementations should
;       allow several.
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
;
fman_open:
	sta fm_name+1
	sty fm_name
	sta fm_info+1
	sty fm_info
	jsr mli
	.byte mli_gfinfo
	.addr fm_infop
	bcs fmEXIT
	jsr mli
	.byte mli_open
	.addr fm_openp
	bcs fmEXIT
	lda #0
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
fmEXIT:	rts
;
SkipAWPhdr:
	lda fm_ref
	sta fm_posref
	jsr mli
	.byte mli_setmark
	.addr fm_setmp
	rts
;
fm_setmp:	.byte 2
fm_posref:	.res 1
	.addr 300
	.byte 0
;
fm_infop:	.byte 10
fm_info:	.res 2
	.byte 0
fm_type:	.byte 0
	.res 13
;
fm_openp:	.byte 3
fm_name:	.res 2
	.addr filebuff
fm_ref:	.res 1
;
fm_readp:	.byte 4
fm_rref:	.byte 0
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
fmr_txt:	ldx fm_bufidx
	lda pagebuff,x
	ora #$80
	cpx fm_bufsz
	bcc fmTXT_ok
	jsr fill_TXT
	bcc fmr_txt
fmTXT_ok:	inc fm_bufidx
	rts
;
fill_TXT:
	jsr mli
	.byte mli_read
	.addr fm_readp
	bcs fm_readx
	lda #0
	sta fm_bufidx
	lda txtLEN
	sta fm_bufsz
fm_readx:	rts
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
fmr_notbl:	ldx fm_bufidx
	lda pagebuff+2,x
	ora #$80
	cpx fm_bufsz
	bcc fmrawp_ok
	jsr fill_awp
	bcc fmr_awp
fmrawp_ok:
	inc fm_bufidx
	rts
;
; fill the AWP line buffer from file
;
fill_awp:
	lda fm_rref
	sta fill_ref
	sta awptext_ref
	jsr mli
	.byte mli_read
	.addr fillp
	bcs filled
	lda awp_rec+1
	cmp #$D0	;CR record?
	beq awp_cr
	cmp #0
	bne fill_awp	;formatting rec--try again
	lda awp_rec
	sta awptext_len
	jsr mli
	.byte mli_read
	.addr awptext
	pha
	ldx #0
	stx fm_bufidx
	lda pagebuff+1
	and #$7f
	sta fm_bufsz
	inc fm_bufsz
	tax
	lda #$80+'M'-ctrl
	sta pagebuff+2,x
	lda pagebuff
	sta awp_blanks
	pla
filled:	rts
;
awp_cr:	lda #$80+'M'-ctrl
	sta pagebuff+2
	ldx #0
	stx fm_bufidx
	inx
	stx fm_bufsz
	clc
	rts
;
fillp:	.byte 4
fill_ref:	.res 1
	.addr awp_rec
	.addr 2
	.addr 0
awp_rec:	.res 2
;
awptext:	.byte 4
awptext_ref:	.res 1
	.addr pagebuff
awptext_len:	.addr 0
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
;
go_eject:
	sta p+1
	sty p
	lda #7
	sta this_slot
ej1:	lda this_slot
	jsr eject_slot
	dec this_slot
	bne ej1
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
ejected_sl:	rts
;
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
callSP4:	jsr $ffff
	.byte 0	;status
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
ejected:	rts
;
; CanEject -- return CLC if unit is ejectable (TYPE=1)
;
CanEject:
callSP2:	jsr $ffff
	.byte 0	;status
	.addr spstat_p
; errors?
	bcs cant_ej	;error $11 (invalid unit) should occur eventually
;
	lda pagebuff+21
	cmp #1
	beq yes_ej
cant_ej:	sec
	rts
yes_ej:	clc
	rts
;
spstat_p:	.byte 3
stat_unitnm:	.byte 0
	.addr pagebuff
	.byte 3	;get DIB
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
callSP3:	jsr $ffff
	.byte 1	;readblock
	.addr ej_rb2
	bcs decid_no
	lda #$80+'/'
	sta pagebuff+1
	lda filebuff+4
	and #%00001111
	tax
	inx
	stx pagebuff
ejBldN:	dex
	beq ejBilt
	lda filebuff+4,x
	jsr xdowncase
	sta pagebuff+1,x
	jmp ejBldN
ejBilt:
;
	jsr xpmgr
	.byte pm_slashif
	.addr pagebuff
	lda p+1
	ldy p
	sta ejslif+1
	sty ejslif
	jsr xpmgr
	.byte pm_slashif
ejslif:	.addr 0
;
	ldy #0
	lda (p),y
	tax
	cmp pagebuff
	bne decid_no
ej9:	iny
	dex
	beq decid_yes
	lda (p),y
	jsr xdowncase
	cmp pagebuff,y
	beq ej9
decid_no:	sec
	rts
decid_yes:	clc
	rts
;
ej_rb2:	.byte 3
rb2unit:	.byte 0
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
EjParms:	.byte 3
ej_unitnm:	.byte 0
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
;
err_text:
	.byte $2f
	asc_hi "no disk"
	.byte 0
	.byte err_badcall
	asc_hi "bad ProDOS call"
	.byte 0
	.byte err_badcnt
	asc_hi "bad pcount"
	.byte 0
	.byte err_ifull
	asc_hi "inttbl full"
	.byte 0
	.byte err_io
	asc_hi "disk I/O"
	.byte 0
	.byte err_nodev
	asc_hi "no device connected"
	.byte 0
	.byte err_wrprot
	asc_hi "disk write-protected"
	.byte 0
	.byte err_switched
	asc_hi "disk switched"
	.byte 0
	.byte err_2slow
	asc_hi "drive too slow"
	.byte 0
	.byte err_2fast
	asc_hi "drive too fast"
	.byte 0
	.byte err_pnsyntax
	asc_hi "bad pathname syntax"
	.byte 0
	.byte err_fcbfull
	asc_hi "FCB full"
	.byte 0
	.byte err_ivlref
	asc_hi "bad refnum"
	.byte 0
	.byte err_dirnotfnd
	asc_hi "directory not found"
	.byte 0
	.byte err_volnotfnd
	asc_hi "volume not found"
	.byte 0
	.byte err_filnotfnd
	asc_hi "file not found"
	.byte 0
	.byte err_dupfil
	asc_hi "duplicate file"
	.byte 0
	.byte err_full
	asc_hi "volume full"
	.byte 0
	.byte err_dirfull
	asc_hi "directory full"
	.byte 0
	.byte err_filfmt
	asc_hi "file format error"
	.byte 0
	.byte err_strgtype
	asc_hi "bad storage type"
	.byte 0
	.byte err_eof
	asc_hi "end of file"
	.byte 0
	.byte err_badpos
	asc_hi "bad file pos"
	.byte 0
	.byte err_locked
	asc_hi "file locked"
	.byte 0
	.byte err_filopen
	asc_hi "file open"
	.byte 0
	.byte err_dircnt
	asc_hi "dir count"
	.byte 0
	.byte err_notprodos
	asc_hi "volume is not ProDOS"
	.byte 0
	.byte err_ivlparm
	asc_hi "invalid param"
	.byte 0
	.byte err_vcbtfull
	asc_hi "VCB full"
	.byte 0
	.byte err_badbufadr
	asc_hi "bad buff addr"
	.byte 0
	.byte err_dupvol
	asc_hi "duplicate volume"
	.byte 0
	.byte err_badmap
	asc_hi "baked bit-map"
	.byte 0
;=======================================
;
; Part II of error table:  Davex errors
;
	.byte der_illegparm
	asc_hi "illegal option"
	.byte 0
	.byte der_toomany
	asc_hi "too many parameters"
	.byte 0
	.byte der_badtype
	asc_hi "bad parm type"
	.byte 0
	.byte der_unknftyp
	asc_hi "unknown filetype"
	.byte 0
	.byte der_dupopt
	asc_hi "duplicate option"
	.byte 0
	.byte der_baddev
	asc_hi "devnum format is .61"
	.byte 0
	.byte der_abort
	asc_hi "aborted"
	.byte 0
	.byte der_waitspool
	asc_hi "wait for files to print or use spool -z"
	.byte 0
	.byte $88
	asc_hi "illegal block read/write"
	.byte 0
	.byte der_needs3
	asc_hi "filetype needs 3 chars"
	.byte 0
	.byte der_missopt
	asc_hi "missing option"
	.byte 0
	.byte der_badhware
	asc_hi "missing hardware"
	.byte 0
	.byte der_badnum
	asc_hi "bad number"
	.byte 0
	.byte der_bignum
	asc_hi "number too big"
	.byte 0
	.byte der_ynexp
	asc_hi "y' or 'n' expected"
	.byte 0
	.byte der_nosbf
	asc_hi "no startup buffer"
	.byte 0
	.byte der_smallsbf
	asc_hi "startup buffer too small"
	.byte 0
	.byte der_notxtn
	asc_hi "not an external command"
	.byte 0
	.byte der_adrlow
	asc_hi "cmd address too low"
	.byte 0
	.byte der_notfnd
	asc_hi "not found"
	.byte 0
	.byte der_semiexp
	asc_hi "missing ';'"
	.byte 0
	.byte der_nottxt
	asc_hi "not script file"
	.byte 0
	.byte der_notdir
	asc_hi "not DIR"
	.byte 0
	.byte der_levels
	asc_hi "too many dir levels"
	.byte 0
	.byte der_1wild
	asc_hi "1 wildcard only"
	.byte 0
	.byte der_badwild
	asc_hi "bad wildcard"
	.byte 0
	.byte der_outmem
	asc_hi "out of memory"
	.byte 0
	.byte der_outroom
	asc_hi "out of room"
	.byte 0
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
;
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
;
hook_ispeech:
	jsr hooki2
	lda ksw+1
	ldy ksw
	sta speechi+1
	sty speechi
	rts
;
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
;
hooki_tt:	lda #3
	sta ksw+1
	lda #$a9
	sta ksw
	lda #$ff
	sta speech
	rts
no_speek:	lda #0
	sta speech
	rts
;
hook_ospeech:
	jsr is_txtt
	beq hooko_tt
	jsr is_slotb
	bne no_speek
; hook out slotbuster == same as textalker ($3A6)
hooko_tt:	lda #3
	sta csw+1
	lda #$a6
	sta csw
	lda #$ff
	sta speech
	rts
;
; is_txtt -- return BEQ if TextTalker routines present
;
is_txtt:	lda $3a6
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
	lda #$60
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
	jsr xbuild_local
	sta tt_open+1
	sty tt_open
	jsr mli
	.byte mli_open
	.addr tt_openp
	bcs no_tt
;
	lda tt_ref
	sta tt_read+1
;
	ldx #$3cf-$380
cp3tt:	lda tt3img,x
	sta $380,x
	dex
	bpl cp3tt
;
readtt:	jsr mli
	.byte mli_read
	.addr tt_read
	bcc ttrok
	cmp #err_eof
	beq ttdone
	jmp xProDOS_err
ttrok:	sty $c005
	ldy #0
ttr2:	lda pagebuff,y
ttcheat:	sta $ff00,y
	dey
	bne ttr2
	sty $c004
	inc ttcheat+2
	jmp readtt
;
ttdone:	lda tt_ref
	jsr close
;
	lda #$ff
	sta $37d
	lda $bf98
	ldy $c01f
	jsr $3a9
;
	jsr xmess
	.byte $85,$80+'C',0	;compressed speech (fast)
	rts
;
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
;
tt_openp:	.byte 3
tt_open:	.addr 0
	.addr filebuff
tt_ref:	.byte 0
;
tt_read:	.byte 4
	.byte 0
	.addr pagebuff,$100,0
;

tt_name:	.byte 6
	asc "PT.OBJ"



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
; There are 2 pages reserved for aliases as "Aliases".
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
	jsr xbuild_local
	sta aPath+1
	sty aPath

	jsr mli
	.byte mli_open
	.addr OpenA
	bcs InitA_dun

	lda aRef
	sta aRef2

	jsr mli
	.byte mli_read
	.addr ReadA

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
InitA_dun:	rts

OpenA:	.byte 3
aPath:	.addr 0
	.addr filebuff
aRef:	.byte 0

ReadA:	.byte 4
aRef2:	.byte 0
	.addr Aliases,$2FF,0


AliasName:
	.byte 7
	asc "aliases"

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
	cmp #$80+'~'
	beq isTilde
ExpA1:	ldy #0
	lda (p2),y
	beq ExpDone
	jsr MaybeExp
	bcc DidExpand
	jsr NextAlias
	jmp ExpA1
ExpDone:	sec
DidExpand:	rts

isTilde:	lda p
	bne noDecP9
	dec p+1
noDecP9:	dec p
	jsr KillOneChar
	sec
	rts

FetchChar:	inc p2
	bne @P2ok
	inc p2+1
@P2ok:
	ldy #0
	lda (p2),y
	ora #%10000000
	rts

NextAlias:	jsr FetchChar
	cmp #$8d
	beq FetchChar
	and #%01111111
	bne NextAlias
	rts

MaybeExp:
	ldy #0
Comp:	lda (p),y
	beq SourceEnd
	jsr xdowncase
	cmp #$80+';'
	beq SourceEnd
	cmp #$80+' '
	beq SourceEnd
	sta temp
	lda (p2),y
	jsr xdowncase
	cmp temp
	bne NoMatch
	iny
	bne Comp

NoMatch:	sec
	rts

;
; Hit end of word in input; if also at end of word in
; the alias, we have a match!
;
SourceEnd:
	lda (p2),y
	jsr xdowncase
	cmp #$80+' '
	beq YesMatch
	cmp #$8d
	beq YesMatch
	sec
	rts

;
; Remove original text from line & insert alias text one
; character at a time.
;
NullAlias:	clc
	rts

YesMatch:
	lda p
	bne NoDecP1
	dec p+1
NoDecP1:	dec p

	sty temp
KillOld:	jsr KillOneChar
	dey
	bne KillOld

	ldy temp
	lda (p2),y
	beq NullAlias
	ora #%10000000
	cmp #$8d
	beq NullAlias

	ldy temp
SrchEnd:	iny
;beq out_room?
	lda (p2),y
	beq InsertExp
	ora #%10000000
	cmp #$8d
	bne SrchEnd

InsertExp:
;inc temp
	dey
Insert1:	lda (p2),y
	jsr InsertOne
	dey
	cpy temp
	bcs Insert1

KillBlanks:	ldy #1
	lda (p),y
	ora #$80
	cmp #$a0
	bne kbDone
	jsr KillOneChar
	jmp KillBlanks

kbDone:
	clc
	rts


KillOneChar:	tya
	pha
	ldy #0
	lda (p),y
	sec
	sbc #1
	sta (p),y
K1C:	iny
	iny
	lda (p),y
	dey
	sta (p),y
	cpy #252
	bcc K1C
	pla
	tay
	rts

InsertOne:	sty I1y
	pha
	ldy #0
	lda (p),y
	cmp #250
	bcs I1Full
	ldy #250
I1C:	lda (p),y
	iny
	sta (p),y
	dey
	dey
	bne I1C
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
I1Full:	lda #der_outroom
	jmp xProDOS_err
I1y:	.byte 0
;*********************************************************

;*********************************************
;
; Davex help command
;
;*********************************************
bits:	.res 1
ViewName	= xczpage
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
;
	jsr xmess
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
helpl:
	jsr point_nxtcmd
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
;
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
	ldy #-1
helpap:	iny
	lda (p),y
	beq hlpapd
	jsr xpmgr
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
;
	lda #%11000000
	sta pause_flag	;b7
	sta filter	;b7
	sta case_flags	;b7,6
	lda #>pagebuff
	ldy #<pagebuff
	jmp more2
;
print_str:	sta p+1
	sty p
	ldy #0
ps1:	lda (p),y
	beq psx
	ora #%10000000
	jsr cout
	inc temp
	iny
	bne ps1
psx:	rts
;*********************************************
TryIndex:
	lda #0
	jsr xgetparm_n
	jmp ViewFile
;*********************************************
EOFparms:	.byte 2
EOFref:	.res 1
EOFval:	.byte 0,0,0
;*********************************************
OpenFile:
	sta OpPath+1
	sty OpPath
	jsr mli
	.byte mli_open
	.addr OpParms
	bcs OpFail
	lda OpRef
OpFail:	rts

OpParms:	.byte 3
OpPath:	.res 2
	.addr filebuff
OpRef:	.res 1
;*********************************************
;*********************************************
SeekIndex:	sta EOFval+2
	stx EOFval+1
	sty EOFval
	jsr mli
	.byte mli_setmark
	.addr EOFparms
	bcs si_fail
	rts
si_fail:	jmp xProDOS_err
;*********************************************
read4:	jsr mli
	.byte mli_read
	.addr read4_p
	bcs si_fail
	lda four+2
	ldx four+1
	ldy four
	rts

read4_p:	.byte 4
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
	.byte 12
	asc "indexed.help"

vf_fail:	jmp xProDOS_err
ViewFile:
	sta ViewName+1
	sty ViewName

	jsr FindHelpDir
	lda #>IndexName
	ldy #<IndexName
	jsr xpmgr
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

missing:	jsr xmess
	.byte cr
	asc "*** not found"
	.byte cr,0
	jmp xerr
;*********************************************
ron_err:	jmp xProDOS_err
ReadOneName:
	lda OpRef
	sta ron_ref1
	sta ron_ref2
	sta unp_ref
	jsr mli
	.byte mli_read
	.addr ron_rd1
	bcs ron_err
	lda pagebuff
	bne ron_cont
	sec
	rts
ron_cont:
	clc
	adc #8
	sta ron_len
	jsr mli
	.byte mli_read
	.addr ron_rd2
	bcs ron_err
	rts

ron_rd1:	.byte 4
ron_ref1:	.res 1
	.addr pagebuff,1,0

ron_rd2:	.byte 4
ron_ref2:	.res 1
	.addr pagebuff+1
ron_len:	.addr 0,0
;*********************************************
CompareVN:
	ldy #0
	lda (ViewName),y
	cmp pagebuff
	bne cvn_no
	tay
cvn1:	lda (ViewName),y
	jsr xdowncase
	and #%01111111
	cmp pagebuff,y
	bne cvn_no
	dey
	bne cvn1
cvn_no:	rts
;*********************************************
vt_fail:	jmp xProDOS_err
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
	jsr mli
	.byte mli_setmark
	.addr EOFparms
	bcs vt_fail

	lda #0
	sta bits
	lda #23
	sta line_count
View1:
	jsr UnpackChar
	bcs viewed
	cmp #$8D
	bne not_cw
	jsr xcheck_wait
	jsr NextLine
	beq viewed
	jsr crout
	jmp View1
not_cw:	jsr cout
	jmp View1

viewed:	lda OpRef
	jmp close
;*********************************************
unpack_err:	jmp xProDOS_err
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
	beq GotNull
	ora #%10000000
	clc
GotNull:	rts
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
	jsr mli
	.byte mli_read
	.addr unpack1
	bcs unpack_err
	lda #8
	sta bits
have_bit:	asl byte
	dec bits
	rts

unpack1:	.byte 4
unp_ref:	.res 1
	.addr byte
	.addr 1,0
;*********************************************
FindHelpDir:
	jsr xpmgr
	.byte pm_copy
	.addr cfghelp,pagebuff
	lda p+1
	pha
	lda p
	pha
	lda #>pagebuff
	ldy #<pagebuff
	jsr fixup_path_ay
	jsr xpmgr
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
	jsr xredirect
	asl a
	bcs no_stop
	jsr suspend
	jsr TalkCont
	jsr xmess
	.byte cr
	asc "--- more"
	.byte 0
	lda #$80+'y'	;default = Yes
	jsr xyesno2
	jmp restore	;(preserves P)
no_stop:	lda #1
	rts

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
	jmp get_yn
	jmp mygetln
	jmp bell
	jmp downcase
	jmp plural
	jmp check_wait
	jmp print_date_ay
	jmp print_time_ay
	jmp ProDOS_err
	jmp ProDOS_er
	jmp err
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
	jmp get_yn2	;v1.2
	jmp dir_setup2	;v1.23
	jmp shell_info	;v1.25
