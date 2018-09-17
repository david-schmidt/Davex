;
; GetInfo on CmdPath; return SEC/CLC;
; errcode or file type in A
;
cmdinfo:
	lda #>cmdpath
	ldy #<cmdpath
	sta ginfopth+1
	sty ginfopth
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
infoerr:	sec
	jmp ProDOS_err
goti:	lda info_type
	rts
;
geti2:
	sta ginfopth+1
	sty ginfopth
	CALLOS mli_gfinfo, infoprm
	CALLOS_BRANCH_NEG geti2err
	clc
	rts
geti2err:
	sec
	rts
;
setinfo:	sta ginfopth+1
	sty ginfopth
	CALLOS mli_sfinfo, infoprm
	CALLOS_BRANCH_NEG infoerr
	rts
;

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

	jsr pmgr
	.byte pm_downcase
	.addr mypath
	ldx mypath
stmp_x:	stx mypath
	stx mydir_len
	rts

;***********************************************
;
; ProDOS_err -- close files and print a message (A)
;
ProDOS_err:
	pha
	start_normal
;	jsr finish_iredir
;	jsr finish_oredir
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
;jsr bell
	jmp fix_stack
;
ProDOS_er:
	sta errcode
;	bit speech
;	bmi nostar
	jsr crout
	lda errcode
ProDOS_er2:
	sta errcode
	jsr mess

	asc "*** "

	.byte 0
nostar:	bit errcode
	bmi nonpro_err
	jsr mess

	asc "SOS "

	.byte 0
nonpro_err:
	lda errcode
	cmp #der_abort
	beq not_an_err
	jsr mess
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
sysbell:	bit $c040
	rts
bell:
	lda cfgbell
	bne sysbell
	ldy #32
bell1:	lda #2
	jsr wait
	sta spkr
	lda #$24
	jsr wait
	sta spkr
	dey
	bne bell1
	clc
	rts

;---------------------------------------------------------
; wait - # cycles = (5*A*A + 27*A + 26)/2
;---------------------------------------------------------
wait:
	pha
	jsr go_slow
	sec		; Delay: # cycles = (5*A*A + 27*A + 26)/2
wait2:	pha
wait3:	sbc #$01
	bne wait3	; 1.0204 USEC
	pla		;(13+27/2*A+5/2*A*A)
	sbc #$01
	bne wait2
	jsr go_fast
	pla
	rts

go_slow:
	php
	pha
	lda $FFDF	; Read the environment register
	ora #$80		; Set 1MHz switch
	sta $FFDF	; Write the environment register
	pla
	plp
	rts

go_fast:
	php
	pha
	lda $FFDF	; Read the environment register
	and #$7f		; Set 2MHz switch
	sta $FFDF	; Write the environment register
	pla
	plp
	rts

CheckHC:
	sec
	rts

fix_stack:
	ldx top_stack
	txs
	jmp prompt ; always

move:
	lda (range_strt),y
	sta (move_to),y
	jsr mover
	bcc move
	rts

mover:
	inc move_to
	bne :+
	inc move_to+1
:	lda range_strt
	cmp range_end
	lda range_strt+1
	sbc range_end+1
	inc range_strt
	bne :+
	inc range_strt+1
:	rts