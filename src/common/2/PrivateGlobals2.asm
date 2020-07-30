.include "Common/PrivateGlobals.asm"

; more_space	= ASMEND	; [TODO] Does this need to be page-aligned?
more_space = ((ASMEND-1) & $ff00)+$100 ; It does or spooling and redirection fail. (@mgcaret)

buff_spool	= more_space
buff_oredir	= buff_spool+$400
buff_iredir	= buff_oredir+$400
dirstack	= buff_iredir+$400
mydir_len	= dstkmax*dstk_recsiz+dirstack
mypath		= mydir_len+1
copybuff	= mypath+128
keepbuff	= copybuff
cbufflen	= highmem-copybuff

cmdpath		= $280
refSlot0	= $f0

;***********************************************
