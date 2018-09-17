.include "../../src/common/3/Globals3.asm"
.include "../../src/common/3/Apple.Globals3.asm"
.include "../../src/common/3/Mli.Globals3.asm"
.include "../../src/common/3/Macros3.asm"
.include "../../src/common/3/PrivateGlobals3.asm"


.segment	"CODE"
	.ORG  $2000-14	; Makes the listing more readable, though it doesn't really org the code - the linker does that.
	.BYTE $53,$4f,$53,$20,$4e,$54,$52,$50	; "SOS NTRP"
	.ADDR $0000	; No extra header
	.ADDR ASMBEGIN	; Tell 'em where it starts
	.ADDR ASMEND	; Tell 'em where it ends

ASMBEGIN:
.include "../../src/shell/3/init3.asm"
.include "../../src/shell/main.asm"
.include "../../src/shell/3/misc3.asm"
.include "../../src/shell/3/boneyard.asm"
.include "../../src/shell/3/conio3.asm"
.include "../../src/common/3/vars.asm"
.include "../../src/shell/3/commands3.asm"
.include "../../src/shell/3/file_execution3.asm"
.include "../../src/shell/3/sosparms.asm"
.include "../../src/shell/3/davex_io.asm"
.include "../../src/shell/3/spool.asm"
.include "../../src/shell/3/date_time.asm"
.include "../../src/shell/3/printer.asm"
;.include "../../src/shell/3/end.asm"
.segment	"END"
ASMEND: