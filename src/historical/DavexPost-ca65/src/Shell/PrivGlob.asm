;
; private globals
;
myBakVer	= $00
myversion	= $12
AuxVersion	= 7 ; = 1.27
Proto	= 0
;
more_space	= $7900
;
buff_spool	= more_space
buff_oredir	= buff_spool+$400
buff_iredir	= buff_oredir+$400
dirstack	= buff_iredir+$400
mydir_len	= dstkmax*dstk_recsiz+dirstack
mypath	= mydir_len+1
copybuff	= mypath+128
keepbuff	= copybuff
cbufflen	= highmem-copybuff
;
refSlot0	= $f0
cmdpath	= $280
