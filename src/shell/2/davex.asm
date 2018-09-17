.include "Common/2/Globals2.asm"
.include "Common/2/Apple.Globals2.asm"
.include "Common/2/Mli.Globals2.asm"
.include "Common/2/Macros2.asm"
.include "Common/2/PrivateGlobals2.asm"

.segment	"CODE_2000"
.org		$2000	; Makes the listing more readable, though it doesn't really org the code - the linker does that.

.include "Shell/2/init.asm"
.include "Shell/main.asm"
.include "Shell/2/misc.asm"
.include "Shell/2/conio.asm"
.include "Shell/2/commands.asm"
.include "Shell/2/file_execution2.asm"
.include "Shell/2/ProDOSParms.asm"
.include "Shell/2/davex_io.asm"
.include "Shell/2/spool.asm"
.include "Shell/2/date_time.asm"
.include "Shell/2/printer.asm"
ASMEND: