.include "Common/Globals.asm"

IsDavex2	= 1
IsDavex3	= 1-IsDavex2

;
; file levels
;
spoollevel	= 5
redir_level	= 10
close_level	= 13 ;close at cmd level
wildlevel	= 15
stdlevel	= 20
;
; high-RAM stuff
;
; dum $B100
shell_gp	= $b100
scanlist	= $b100	;ds 128
appl_list	= $b180	;ds 128 ;reserved for 'appl' command
filetypes	= $b200	;ds 256
filetyp		= filetypes
fileasc		= filetypes+64
misc		= $b300	;ds 256
print_slot	= misc
cfg40		= misc+1
cfgbell		= misc+2
cfgclock	= misc+3
cfgquiet	= misc+4
cfghelp		= misc+5 ;ds 64!
chk77		= misc+255
cfg_expansion	= $b400	;ds 256
cfg_end		= $b500
config_len	= cfg_end-shell_gp
; end of stuff for CONFIG file

spool_list	= $b500	;ds 256

; ds 768 ;for string buffers (build down)
string_buffs	= $b600+$300	;previous 3 pages = strings
History		= $b900	;ds 256
Aliases		= $ba00	;ds 768

; $BD00 page -- available for use?

;
; $BE00 page
;
; NOT for xc use!
;
; dum $BE00
maxparms	= 16
parms		= $be00	;ds maxparms*4
num_parms	= $be40	;ds 1
parmtypes	= $be41	;ds maxparms

;
; RAM globals from $800 to $1FFF
;
filebuff	= $800	;ds $400
filebuff2	= $C00	;ds $400
filebuff3	= $1000	;ds $400
wildbuff	= $1400	;ds $400 ;not for xc use
pagebuff	= $1800	;ds $100
; ds 1
string		= $1901	;ds $100 ;not for xc use
; ds 1
catbuff		= $1A02	;ds $80
; ds 1
command		= $1A83	;ds maxlen ;not for xc use
; ds 1
string2		= $1B7E	;ds $80 ;not for xc use
direcpath	= $1BFE	;ds 65 ;not for xc use
wildstring1	= $1C3F	;ds 128
wildstring2	= $1CBF	;ds 128
wildseg		= $1D3F	;ds 16
;next address = $1D4F
; $1F80 buffer is used when launching a SYS program -- search for $1F80

