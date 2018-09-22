;***********************************************
;
; Startup buffer--holds name of autoexec file
;
; This has to come at $2000, by convention.
;
;***********************************************
start:	jmp start2
	.byte $ee,$ee
	.byte 65	; length of buffer
exec_pn:
	pstr "%autoexec"
	.res 55
;***********************************************

;***********************************************
start2:	cld
	ldx #$f8
	tsx
	lda #stdlevel
	sta level
	lda #0
	sta redir_susplv
	sta redir_out
	sta redir_in

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
init_bm:
	sta bitmap,x
	dex
	bpl init_bm
	lda #%11001111
	sta bitmap+0
	lda #1
	sta bitmap+BitMapSize-1
	lda #myversion
	sta iversion

	lda #$4c
	sta $3d0	; language warmstart jump ("Q" from GS Monitor)
	sta $3d3	; language coldstart jump
	sta $3f8	; monitor Ctrl-Y jump
	sta $3fb	; NMI jump
	lda #>restart
	ldy #<restart
	sta $3d2
	sty $3d1
	sta $3d5
	sty $3d4
	sta $3fa
	sty $3f9
	sta reset+1
	sty reset
	jsr pwrdup

	lda #>NMIouch
	ldy #<NMIouch
	sta $3fd
	sty $3fc

	jsr FixRAMvect

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
	jsr $fe1f	;Contains RTS in not-IIgs
	pla
	bcs no_IIgs
	ora #%00001000	;IIgs
; Make a QDVersion call (any call) so DiversiKey will
; hook itself in if we just rebooted
.P816
	pha
	clc
	XCE
	rep #$30
.A16
.I16
	pha
	ldx #$0404	; QDVersion
	jsl $e10000
	pla
	sec
	XCE
	pla
.P02

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

 	jmp restart

;****************************************
;
; If there are any $FF00 vectors in the
; block-device table corresponding to
; devices not in the device list, change
; the vector to the no-device vector
;
;****************************************
FixRAMvect:
	ldx #$1e
@loop:	lda $BF10,x
	bne @ok
	lda $BF11,x
	cmp #$ff
	bne @ok
	txa
	asl a
	asl a
	asl a
	jsr ChkDevLst	;clc=found
	bcc @ok
	lda $BF10
	sta $BF10,x
	lda $BF11
	sta $BF11,x
@ok:	dex
	dex
	bne @loop
	rts
;
; Return CLC: device A is in DevLst
; (preserve X!)
;
ChkDevLst:
	sta @mod+1
	ldy $bf31
@loop:	lda $bf32,y
	and #%11110000
@mod:	cmp #$77
	beq @yes
	dey
	bpl @loop
	sec
	rts
@yes:	clc
	rts
