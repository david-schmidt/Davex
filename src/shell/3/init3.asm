;***********************************************
;
; Startup buffer--holds name of autoexec file
;
start:	jmp start2
	.byte $ee,$ee,65

exec_pn:
	pstr "%autoexec"
	.res 55

;***********************************************
start2:
	sei
	cld
	tsx		; Get a handle to the stackptr
	stx top_stack	; Save it for full pops during aborts
	lda #stdlevel
	sta level
	jsr init_screen
	lda #0
	sta speech
;	sta redir_susplv
;	sta redir_out
;	sta redir_in
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
; compute xc_req here
;
	ldx #$00
	stx xc_req
;
;	lsr spooling
	jsr find_mydir
	lda #0
	sta filetypes
	jsr load_globpg
	jsr init_alias
	jsr need_prefix

	jmp restart

 top_stack:
	.byte $00	; Storage for the stack pointer

f8rom_init:
	rts
