OpenA:	.byte 4
aPath:	.addr 0
aRef:	.byte 0
aOption:	.addr 0
aLength: .byte 0

ReadA:	.byte 4
aRef2:	.byte 0
	.addr Aliases
	.addr $02FF
aXferCount:
	.addr 0

fdir_pfx:
	.byte 2
	.addr mypath
	.byte 128

set_pfx_parms:
	.byte 1
	.addr string2-1

get_pfx_parms:
	.byte 2
	.addr string2-1
	.byte 128

bye_parms:
	.byte $00, $00, $00, $00, $00, $00 

destinfo:	.byte 3
desti_name:	.addr 0
desti_ptr:	.addr desti_options
desti_opti_len:	.byte $0f

desti_options:
desti_acc:	.byte 0
desti_ftyp:	.byte 0
desti_auxtype:	.addr 0
desti_stt:	.byte 0
desti_EOF:	.byte 0,0,0,0
desti_blks_used:	.addr 0
desti_last_mod:	.byte 0,0,0,0


infoprm:		.byte 3
ginfopth:	.addr 0
infoprm_ptr:	.addr infoprm_options
infoprm_opti_len:	.byte $0f

infoprm_options:
info_acc:	.res 1
info_type:	.res 1
info_auxtype:	.res 2
info_stype:	.res 1
info_EOF:	.byte 0,0,0,0
info_blocks:	.res 2
info_moddat:	.res 2
info_modtim:	.res 2
info_crdat:	.byte 0,0	; Not updated by SOS
info_crtim:	.byte 0,0	; Not updated by SOS


ocfg_parms:
	.byte 4
	.addr mypath
cfg_ref:	.res 1
	.addr 0
	.byte 0

crcfg_parms:
	.byte 3
	.addr mypath
	.addr crcfg_options
	.byte 4
crcfg_options:
	;.byte %11000011	; Not settable with SOS' create call
	.byte $5A	; Type - config file
	.addr $8005	; Auxtype - Davex 8 config file
	.byte 1		; Storage type - file (vs. directory)

OpParms:	.byte 4
OpPath:	.addr 0
OpRef:	.res 1
	.addr 0
	.byte 0

EOFparms:
	.byte 3
EOFref:	.res 1
EOFbase:	.byte 0
EOFval:	.byte 0,0,0,0

cr_parms:
	.byte 3
cr_path:	.res 2
cr_opts_ptr:
	.addr cr_opts
cr_opts_length:
	.byte 4

cr_opts:
cr_type:	.res 1
	.byte 0,0	;auxtype
cr_stype:
	.res 1		;storage type
cr_date:	.addr 0		; Ignored by SOS
cr_time:	.addr 0		; Ignored by SOS

sz_open:	.byte 4
sz_path:	.addr 0
sz_ref:	.byte 0
sz_open_opt_ptr:
	.addr 0
sz_len:	.byte 0
;
;
sz_geteof:
	.byte 2
sz_ref2:	.byte 0
sz_eof:	.byte 0, 0, 0, 0

opendir_p:
	.byte 4
	.addr direcpath
dir_ref:	.res 1
	.addr 0
	.byte 0
;
get_mark_parms:
	.byte 2
dir_ref3:
	.res 1
pmark:	.res 2
	.byte 0, 0
;
set_mark_parms:
	.byte 3
dir_ref5:
	.res 1
set_mark_offset:
	.byte 0
pmark_set:
	.res 2
	.byte 0, 0
;
online_parm:
	.byte 4
online_dev:
	.byte 0
	.addr catbuff
;
cp_op1:	.byte 4
cp_pn1:	.addr 0
cpref1:	.byte 0
	.addr 0
	.byte 0
;
cp_op2:	.byte 4
cp_pn2:	.addr 0
cpref2:	.byte 0
	.addr 0
	.byte 0
;
cp_creatp:
	.byte 3
cp_crpn:	.addr 0
	.addr cpcr_options
	.byte 4
cpcr_options:
	;.byte %11000011
	.byte tBAD
	.addr 0		; No auxtype
	.byte 1		; Storage type - file (vs. directory)
;
cpeof_p:
	.byte 2
cpeof_r:
	.byte 0
cpgeof_result:
	.byte 0,0,0,0
;
cpseof_p:
	.byte 3
cpseof_ref:
	.byte 0
cpseof_base:
	.byte 0
cpseof_result:
	.byte 0,0,0,0
;
cp_wr2:	.byte 3
cpref2b:	.byte 0
	.addr copybuff
cp_xfer2:
	.addr 0
;
fm_infop:	.byte 3
fm_info:		.res 2	; Name
fm_ptr:		.addr fm_info_options
fm_info_op_len:	.byte $0f
fm_info_options:
		.byte 0	; Access
fm_type:		.byte 0	; Type
		.res 13
;
fm_openp:	.byte 4
fm_name:		.res 2
fm_ref:		.res 1
		.addr 0
		.byte 0
;
fm_setmp:	.byte 3
fm_posref:	.res 1
fm_base:		.byte 0
		.addr 300
		.byte 0
;
info_op:		.byte 4
info_path:	.res 2
inforef:		.res 1
		.addr 0
		.byte 0
;
set_level_parms:	.byte 1
set_level_num:	.byte 2
;
dotdotPARMS:
	.byte 2
	.addr pagebuff
	.byte $80

wildpfx:
	.byte 2
	.addr wildstring1
	.byte $80
