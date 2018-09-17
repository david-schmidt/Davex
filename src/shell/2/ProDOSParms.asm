OpenA:	.byte 3
aPath:	.addr 0
	.addr filebuff
aRef:	.byte 0

ReadA:	.byte 4
aRef2:	.byte 0
	.addr Aliases
	.addr $02FF
aXferCount:
	.addr 0

fdir_pfx:
	.byte 1
	.addr mypath

set_pfx_parms:
get_pfx_parms:
	.byte 1
	.addr string2-1

bye_parms:
	.byte 4,0,0,0,0,0,0

destinfo:
	.byte 10
desti_name:
	.addr 0
desti_acc:
	.byte 0
desti_ftyp:
	.byte 0
	.addr 0
desti_stt:
	.byte 0
	.addr 0,0,0,0,0

infoprm:
	.res 1
ginfopth:
	.res 2
info_acc:
	.res 1
info_type:
	.res 1
info_auxtype:
	.res 2
info_stype:
	.res 1
info_blocks:
	.res 2
info_moddat:
	.res 2
info_modtim:
	.res 2
info_crdat:
	.res 2
info_crtim:
	.res 2

ocfg_parms:
	.byte 3
	.addr mypath
	.addr filebuff2
cfg_ref:
	.res 1

crcfg_parms:
	.byte 7
	.addr mypath
	.byte %11000011
	.byte $5A	;config file
	.addr $8005	;Davex 8 config file
	.byte 1
	.addr 0,0

OpParms:
	.byte 3
OpPath:	.res 2
	.addr filebuff
OpRef:	.res 1

EOFparms:
	.byte 2
EOFref:	.res 1
EOFval:	.byte 0,0,0

cr_parms:
	.byte 7
cr_path:
	.res 2
	.byte %11000011
cr_type:
	.res 1
	.byte 0,0	;auxtype
cr_stype:
	.res 1	;storage type
cr_date:
	.addr 0
cr_time:
	.addr 0

sz_open:
	.byte 3
sz_path:
	.addr 0
	.addr filebuff
sz_ref:	.byte 0


sz_geteof:
	.byte 2
sz_ref2:
	.byte 0
sz_eof:	.byte 0,0,0

opendir_p:
	.byte 3
	.addr direcpath
	.addr wildbuff
dir_ref:
	.res 1

get_mark_parms:
set_mark_parms:
	.byte 2
dir_ref3:
	.res 1
pmark:	.res 2
	.byte 0

online_parm:
	.byte 2
online_dev:
	.byte 0
	.addr catbuff

cp_op1:	.byte 3
cp_pn1:	.addr 0
	.addr filebuff
cpref1:	.byte 0

cp_op2:	.byte 3
cp_pn2:	.addr 0
	.addr filebuff2
cpref2:	.byte 0

cp_creatp:
	.byte 7
cp_crpn:
	.addr 0
	.byte %11000011
	.byte tBAD
	.addr 0
	.byte 1
	.addr 0,0

cpeof_p:
	.byte 2
cpeof_r:
	.byte 0
	.byte 0,0,0
;
cp_wr2:	.byte 4
cpref2b:
	.byte 0
	.addr copybuff
cp_xfer2:
	.addr 0
	.addr 0

fm_infop:
	.byte 10
fm_info:
	.res 2	; Name
	.byte 0	; Access
fm_type:
	.byte 0	; Type
	.res 13

fm_openp:
	.byte 3
fm_name:
	.res 2
	.addr filebuff
fm_ref:	.res 1
;
fm_setmp:
	.byte 2
fm_posref:
	.res 1
	.addr 300
	.byte 0

info_op:
	.byte 3
info_path:
	.res 2
	.addr filebuff
inforef:
	.res 1

dotdotPARMS:
	.byte 1
	.addr pagebuff

wildpfx:
	.byte 1
	.addr wildstring1
