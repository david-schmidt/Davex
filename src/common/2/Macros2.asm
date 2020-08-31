.include "Common/Macros.asm"

.macro 	CALLOS Arg1, Arg2
	jsr mli
	.byte Arg1
	.addr Arg2
.endmacro

.macro CALLOS_BRANCH_POS Arg1
	bcc Arg1		; Branch on success
.endmacro

.macro CALLOS_BRANCH_NEG Arg1
	bcs Arg1		; Branch on failure
.endmacro

.macro	start_inverse
	lda #$12		; Code for start printing in inverse
	jsr cout
.endmacro
               
.macro	start_normal
	jsr normal
.endmacro

.macro	SET_LEVEL
	sta level
.endmacro

; [TODO] use .p816 instead of invoking this macro
.macro XCE
	.byte $fb
.endmacro
