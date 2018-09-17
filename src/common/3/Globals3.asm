.include "../../src/common/Globals.asm"
IsDavex2	= 0
IsDavex3 = 1-IsDavex2
;
; file levels
;
spoollevel	= 2
close_level	= 2 ;close at cmd level
wildlevel	= 2
stdlevel		= 3
;
; high-RAM stuff
;
; ds $300 ;for string buffers (build down)
; dum $B100
shell_gp		= $b100
scanlist		= shell_gp
appl_list	= scanlist+$80
filetypes	= appl_list+$80
filetyp		= filetypes
fileasc		= filetypes+$40
misc		= fileasc+$c0
print_slot	= misc
cfg40		= misc+1
cfgbell		= misc+2
cfgclock		= misc+3
cfgquiet		= misc+4
cfghelp		= misc+5
chk77		= misc+255
cfg_expansion	= chk77+1
cfg_end		= cfg_expansion+$100
config_len	= cfg_end-shell_gp
; end of stuff for CONFIG file
string_buffs	= $b500+$300	;previous 3 pages = strings
spool_list	= $1e00	; = $b500	;ds 256
History		= $1f00	; = $b900	;ds 256
;
; $BE00 page - not in the ///
;
; NOT for xc use!
;
; dum $BE00
maxparms	= 16
; See vars.asm for a few things that needed to be reserved.
 