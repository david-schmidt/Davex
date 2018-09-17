;***********************************************
;*
;* Shell_Globals
;*
;***********************************************
maxlen	= 250
;************************************
;* global locations (ZP)
;************************************
;*
;* z-page stuff ($60 up)
;*
; dum $60
speech	= $60	;ds 1
num	= $61	;ds 4
prtrwrk	= $65	;ds 2 ;ptr to driver workspace
num2	= $67	;ds 4
num3	= $6B	;ds 4
scr_width	= $6F	;ds 1
redir_susplv	= $70	;ds 1 ;redirection suspend level
redir_out	= $71	;ds 1
redir_in	= $72	;ds 1
externalc	= $73	;ds 1
re_entry	= $74	;ds 1
spooling	= $75	;ds 1
two_e_flag	= $76	;ds 1
lc_flag	= $77	;ds 1
errcode	= $78	;ds 1
msgp	= $79	;ds 2
p	= $7B	;ds 2
p2	= $7D	;ds 2
ptr	= $7F	;ds 2
xsave	= $81	;ds 1
ysave	= $82	;ds 1
temp	= $83	;ds 4
insert_mode	= $87	;ds 1
longest	= $88	;ds 1
rc_temp	= $89	;ds 1
rd_save	= $8A	;ds 1
digit_flag	= $8B	;ds 1
pad_flag	= $8C	;ds 1
numtemp	= $8D	;ds 3
parse_index	= $90	;ds 1
cmd_ptr	= $91	;ds 2
cmd_addr	= $93	;ds 2
strbuf	= $95	;ds 2
ptype	= $97	;ds 1
optchar	= $98	;ds 1
string_index	= $99	;ds 1
quotechr	= $9A	;ds 1
some_flag	= $9B	;ds 1
dir_level	= $9C	;ds 1
dstk_ptr	= $9D	;ds 2
config_dirty	= $9F	;ds 1
vid_csw	= $A0	;ds 2
pmptr	= $A2	;ds 2
pmpath1	= $A4	;ds 2
pmpath2	= $A6	;ds 2
rep_count	= $A8	;ds 2
xc_req	= $AA	;ds 1
mmgr_lo	= $AB	;ds 1
mmgr_hi	= $AC	;ds 1
and_mask	= $AD	;ds 1
or_mask	= $AE	;ds 1
keep	= $AF	;ds 2
sort_str	= $B1	;ds 2
sort_char	= $B3	;ds 1
speechi	= $B4	;ds 2
remslot	= $B6	;ds 1
; dend
;
xspeech	= speech ;bit 7=speech active
xnum	= num
xczpage	= $E0 ;XCs use ZP from $E0..FF
;
highmem	= $b000
;
; dum $800
filebuff	= $800	;ds $400
filebuff2	= $C00	;ds $400
filebuff3	= $1000	;ds $400
wildbuff	= $1400	;ds $400 ;not for xc use
pagebuff	= $1800	;ds $100
; ds 1
string	= $1901	;ds $100 ;not for xc use
; ds 1
catbuff	= $1A02	;ds $80
; ds 1
command	= $1A83	;ds maxlen ;not for xc use
; ds 1
string2	= $1B7E	;ds $80 ;not for xc use
direcpath	= $1BFE	;ds 65 ;not for xc use
wildstring1	= $1C3F	;ds 128
wildstring2	= $1CBF	;ds 128
wildseg	= $1D3F	;ds 16
;next address = $1D4F
; dend
;
; parameter types
;
t_nil	= 0	;ds 1
t_int2	= 1	;ds 1
t_int3	= 2	;ds 1
t_path	= 3	;ds 1
t_wildpath	= 4	;ds 1
t_string	= 5	;ds 1
t_int1	= 6	;ds 1
t_yesno	= 7	;ds 1
t_ftype	= 8	;ds 1
t_devnum	= 9	;ds 1
;
; high-RAM stuff
;
; dum $B100
shell_gp	= $b100
scanlist	= $b100	;ds 128
appl_list	= $b180	;ds 128 ;reserved for 'appl' command
filetypes	= $b200	;ds 256
filetyp	= filetypes
fileasc	= filetypes+64
misc	= $b300	;ds 256
print_slot	= misc
cfg40	= misc+1
cfgbell	= misc+2
cfgclock	= misc+3
cfgquiet	= misc+4
cfghelp	= misc+5 ;ds 64!
chk77	= misc+255
cfg_expansion	= $b400	;ds 256
cfg_end	= $b500
config_len	= cfg_end-shell_gp
; end of stuff for CONFIG file
spool_list	= $b500	;ds 256
; ds 768 ;for string buffers (build down)
string_buffs	= $b600+$300	;previous 3 pages = strings
History	= $b900	;ds 256
Aliases	= $ba00	;ds 768
; dend
;
; $BE00 page
;
; NOT for xc use!
;
; dum $BE00
maxparms	= 16
parms	= $be00	;ds maxparms*4
num_parms	= $be40	;ds 1
parmtypes	= $be41	;ds maxparms
;dend
;
; offsets into an xc
;
x_cmdver	= 3	;ds 1
x_minver	= 4	;ds 1
x_reqbits	= 5	;ds 1
x_descp	= 6	;ds 2
x_loadadr	= 8	;ds 2
x_goadr	= $A	;ds 2
x_reserved	= $C	;ds 4 ;must be 0
x_parmtbl	= $10	;= *
; dend
;
; path manager commands
;
pm_appay	= 0	;ds 1
pm_appch	= 1	;ds 1
pm_up	= 2	;ds 1
pm_slashif	= 3	;ds 1
pm_copy	= 4	;ds 1
pm_downcase	= 5	;ds 1 ;v1.30
pm_last	= 6	;= *
; dend
;
; Davex routine entries
;
; dum highmem ;$b000
resources	= highmem
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
; dend
;
; file levels
;
spoollevel	= 5
redir_level	= 10
close_level	= 13 ;close at cmd level
wildlevel	= 15
stdlevel	= 20
;
; Error codes for Davex errors
;
; der_xxx -- for ProDOS_err
;
; dum $80
der_illegparm	= $80
der_toomany	= $81
der_badtype	= $82
der_unknftyp	= $83
der_dupopt	= $84
der_baddev	= $85
der_abort	= $86
der_waitspool	= $87
;reserved	= $88
der_needs3	= $89
der_missopt	= $8a
der_badhware	= $8b
der_notidev	= $8c
der_badnum	= $8d
der_bignum	= $8e
der_ynexp	= $8f
der_nosbf	= $90
der_smallsbf	= $91
der_notxtn	= $92
der_adrlow	= $93
der_semiexp	= $94
der_notfnd	= $95
der_nottxt	= $96
der_notdir	= $97
der_levels	= $98
der_1wild	= $99
der_badwild	= $9a
der_outmem	= $9b
der_outroom	= $9c
; dend

;*******************************************
;
; dirstack (at end of program) is an array of
; DSTKMAX records:
;   pathname*65
;   mark*3          (byte position in dir)
;   filecount*2     (# files in dir)
;   filecntr*1      (# files left this blk)
;
; dum 0
dstk_path	= 0	;ds 65
dstk_mark	= 65	;ds 3
dstk_fcount	= 68	;ds 2
dstk_filecntr	= 70	;ds 1
dstk_recsiz	= 71	;ds 0
; dend
dstkmax	= 10
;********************************************
