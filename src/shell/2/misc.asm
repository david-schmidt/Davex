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
	CALLOS mli_gfinfo, infoprm
	CALLOS_BRANCH_NEG cmderr
	lda info_type
cmderr:	rts

;
; getinfo for a file; path in AY, return type in A
;
; getinfo never returns if an error is detected;
; geti2 does
;
getinfo:
	jsr geti2
	bcc goti
infoerr:
	jmp ProDOS_err

goti:	lda info_type
	rts

geti2:	sta ginfopth+1
	sty ginfopth
	lda #10
	sta infoprm
	CALLOS mli_gfinfo, infoprm
	CALLOS_BRANCH_NEG geti2err
	clc
	rts

geti2err:
	sec
	rts

setinfo:
	sta ginfopth+1
	sty ginfopth
	lda #7
	sta infoprm
	CALLOS mli_sfinfo, infoprm
	CALLOS_BRANCH_NEG infoerr
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
	CALLOS mli_getpfx, fdir_pfx

	lda $281
	ora #%10000000
	cmp #_'/'
	bne fdir_partial
	lda #0
	sta mypath
fdir_partial:
	lda #>$280
	ldy #<$280
	jsr pmgr
	.byte pm_appay
	.addr mypath

fdir_next:
	jsr pmgr
	.byte pm_downcase
	.addr mypath

	ldx #79
keep_all:
	lda mypath,x
	sta mypath_all,x
	dex
	bpl keep_all

	ldx mypath
strip_mp:
	dex
	beq :+
	lda mypath,x
	ora #%10000000
	cmp #_'/'
	bne strip_mp
:	stx mypath
	stx mydir_len
	rts

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
	jsr bell	;27-Jan-90
	pla
	jsr ProDOS_er
	jmp fix_stack

ProDOS_er:
	sta errcode
	bit speech
	bmi nostar
	jsr crout
	lda errcode
ProDOS_er2:
	sta errcode
	jsr mess
	cstr "*** "
nostar:	bit errcode
	bmi nonpro_err
	jsr mess
	cstr "ProDOS "
nonpro_err:
	lda errcode
	cmp #der_abort
	beq not_an_err
	jsr mess
	cstr "error: "
not_an_err:
	lda #>err_text
	ldy #<err_text
	sta p+1
	sty p

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
p_okz:	jmp pe_srch

pe_fnd:	inc p
	bne :+
	inc p+1
:	jsr print_p
	jmp crout

pe_notfnd:
	lda #_'$'
	jsr cout
	lda errcode
	jsr prbyte
	jmp crout
;
; bell -- ProDOS style or System, depending on cfgbell
;
sysbell:
	lda #$87
	jmp cout
bell:
	lda cfgbell
	bne sysbell
	ldy #32
:	lda #2
	jsr wait
	sta spkr
	lda #$24
	jsr wait
	sta spkr
	dey
	bne :-
	rts

fix_stack:
	ldx #$f8
	txs
	jmp prompt
