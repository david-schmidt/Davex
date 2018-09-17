.include "../../src/common/PrivateGlobals.asm"

more_space	= ASMEND
;
buff_spool	= more_space
buff_oredir	= buff_spool+$400
buff_iredir	= buff_oredir+$400
dirstack	= buff_iredir+$400
mydir_len	= dstkmax*dstk_recsiz+dirstack
mypath		= mydir_len+1
cmdpath		= mypath+128
copybuff	= cmdpath+128 
keepbuff	= copybuff
cbufflen	= highmem-copybuff
;
refSlot0	= $f0
;***********************************************
