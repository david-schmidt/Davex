; Define an ASCII character with no attributes (high bit set).
.define _(char) char | $80

; Define an ASCII character with the inverse attribute
.define _I(char) char & $3f

; Define an ASCII string with no attributes
.macro  asc Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) & $7f
        .endrep
.endmacro

.define asc2(Arg)  asc Arg

.macro  asc_hi Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) | $80
        .endrep
.endmacro

.macro  ascz Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) | $80
        .endrep
        .byte   $00
.endmacro

; Define a Pascal string with no attributes
.macro	pstr Arg
	.byte	.strlen(Arg) 
	.repeat	.strlen(Arg), I
	.byte	.strat(Arg, I) & $7f
	.endrep
.endmacro

; Define a Pascal string with high bit set
.macro	pstr_hi Arg
	.byte	.strlen(Arg) 
	.repeat	.strlen(Arg), I
	.byte	.strat(Arg, I) | $80
	.endrep
.endmacro

; C string
.macro  cstr Arg
	.repeat .strlen(Arg), I
	.byte   .strat(Arg, I) & $7f
	.endrep
	.byte 0
.endmacro

; C string with Return on the end
.macro  cstr_cr Arg
	.repeat .strlen(Arg), I
	.byte   .strat(Arg, I) & $7f
	.endrep
	.byte cr,0
.endmacro

; Message with string (use from external commands)
.macro	xmessage_cstr Arg
	jsr xmess
	cstr Arg
.endmacro

; Message with string, trailing Return (use from external commands)
.macro	xmessage_cstr_cr Arg
	jsr xmess
	cstr_cr Arg
.endmacro

.macro  asccr Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) | $80
        .endrep
        .byte   $8d
.endmacro

; Define an ASCII string with the inverse attribute
.macro  inv   Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) & $3f
        .endrep
.endmacro

.macro  invcr   Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) & $3f
        .endrep
        .byte $8d
.endmacro

.macro DEBUG_NUM Arg1
	pha
	tya
	pha
	txa
	pha
	lda #Arg1
	jsr prbyte
	lda #$20
	jsr cout
	pla
	tax
	pla
	tay
	pla
;	rts
.endmacro

.macro PRODOS_ERROR Arg1
	pha
	lda Arg1
	jsr prbyte
	jsr crout
	pla
	jmp ProDOS_err
.endmacro
