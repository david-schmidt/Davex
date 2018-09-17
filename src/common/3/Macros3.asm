.include "../../src/common/Macros.asm"

.macro	CALLOS Arg1, Arg2
	.byte $00
	.byte Arg1
	.addr Arg2
	clc
	beq :+
	sec
:
.endmacro

.macro CALLOS_BRANCH_POS Arg1
	beq Arg1		; Branch on success
.endmacro

.macro CALLOS_BRANCH_NEG Arg1
	bne Arg1		; Branch on failure
.endmacro

.macro	start_inverse
	lda #$12		; Code for start printing in inverse
	jsr cout
.endmacro
               
.macro	start_normal
	lda #$11		; Code for start printing normally
	jsr cout
.endmacro

.macro	SET_LEVEL
	sta set_level_num
	CALLOS mli_setlevel_3, set_level_parms
.endmacro
