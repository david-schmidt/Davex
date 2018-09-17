run_external:
	rts

run_something:
	cmp #tSYS
	beq is_sys
	cmp #$2E	;$2E;$8001 is a Dvx command
	bne cmdNot2E
	ldx info_auxtype+1
	cpx #$80
	bne cmdNot2E
	ldx info_auxtype
	cpx #$01
	beq run_ext0
cmdNot2E:
	cmp #tBIN
	bne typerr
run_ext0:
	jmp run_external

typerr:	pha
	message_cstr "Can't run '"
	pla
	jsr print_ftype
	message_cstr_cr "' files"
	jmp main_err

is_sys:
	rts