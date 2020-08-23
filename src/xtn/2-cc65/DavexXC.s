
;	.include "../../Common/2/Globals2.asm"	-- relative include of common/globals.asm doesn't work from Globals2.asm, under cl65
;	.include "Common/2/Apple.Globals2.asm"
;	.include "Common/2/Mli.globals2.asm"
;	.include "Common/Macros.asm"

CSTACK = $B000	; AF00..AFFF

.segment "STARTUP"
__STARTUP__:
_STARTUP:
	.export __STARTUP__
	.export _STARTUP
	.import _main
	.importzp sp

	lda #>CSTACK
	ldx #<CSTACK
	sta sp+1
	stx sp
; [TODO] Call constructors/inits, and initialize any static data
	jmp _main


;-----

; [TODO] .h declarations for all these
; [TODO] glue for the nontrivial ones
.if 1	; [TODO] get from include file instead
xgetparm_ch	= $b000
xgetparm_n	= $b003
xmess		= $b006
xprint_ftype	= $b009
xprint_access	= $b00c
xprdec_2	= $b00f
xprdec_3	= $b012
xprdec_pad	= $b015
xprint_path	= $b018
xbuild_local	= $b01b
xprint_sd	= $b01e
xprint_drvr	= $b021
xredirect	= $b024
xpercent	= $b027
xyesno		= $b02a
xgetln		= $b02d
xbell		= $b030
xdowncase	= $b033
xplural		= $b036
xcheck_wait	= $b039
xpr_date_ay	= $b03c
xpr_time_ay	= $b03f
xProDOS_err	= $b042
xProDOS_er	= $b045
xerr		= $b048
xprdec_pady	= $b04b
xdir_setup	= $b04e
xdir_finish	= $b051
xread1dir	= $b054
xpmgr		= $b057
xmmgr		= $b05a
xpoll_io	= $b05d
xprint_ver	= $b060
xpush_level	= $b063
xfman_open	= $b066
xfman_read	= $b069
xrdkey		= $b06c ;v1.1
xdirty		= $b06f ;v1.1
xgetnump	= $b072 ;v1.1
xyesno2		= $b075 ;v1.2
xdir_setup2	= $b078 ;v1.23
xshell_info	= $b07b ;v1.25
.endif

; __fastcall__ calling convention: last parameter is in (?) XA ?
; return value in A, XA, ??

.export _xprint_ver
_xprint_ver = xprint_ver

.export _xpoll_io
_xpoll_io = xpoll_io

.export _xgetnump
_xgetnump = xgetnump

.segment "ONCE"
.segment "INIT"
