;*********************************************
;
; External command for Davex
;
; what -- describe file type
;
; Prints info based on a file's filetype,
; auxiliary type, length, and the contents
; of its first block.
;
; Output:
;
; filetype [auxtype]   filename
;   [strg type]  [mod date]  [create date]
;   [blocks]  [bytes]
;   [more info--OMF, Binary II, etc]
;   [type-specific info]
;   [(disabled)]
;
;*******************************************************
;
; Modified 14-Nov-87 --> v1.4
;   removed stupid TXT guessing
;   added more PIC and PNT stuff, plus lots more
;
; Modified 5-Dec-87  --> v1.5
;   no error reported for empty files
;   IIgs Fonts--reports family name and size
;   All ProDOS 16 OMF files--reports version numbers
;   Prints warning if Binary II file has a duplicated
;     first block (of 128 bytes)
;   Prints warning if BAS file has wrong Aux-type
;
; Modified 12-Mar-88 --> v1.6
;   recognizes VSTORE volume images
;   recognizes more DRV types
;   prints auxiliary-version digit when
;     identifying external cmds ("...for
;     Davex vX.YZ+")
;
; Modified 2-Apr-88 --> v1.7
;   prints vstore file#
;   lots of options added for printing the sort
;     of info that "info" prints (strg type,
;     create/mod date/time, auxtype, blocks,
;     length)
;   contents of SYS startup buffs printed
;
; Modified 28-Apr-88 --> v1.8
;   recognizes SQueezed files ($76 $FF...)
;   and CRYPTOR files (type=$00, aux=$1987);
;   TOOL029 and TOOL032 recognized
;
; Modified 6-Oct-88 --> v2.0
;   recognizes EXTENDED storage type
;   doesn't abort if can't open file
;   shows "disabled" for disabled GS files
;   recognizes FST and GLF files
;
; Modified 27-Jan-90 --> v2.1 DAL
;   recognizes $2E;$8001 files as Davex command
;
;*******************************************************
;*******************************************************
;
; Converted to MPW IIgs 21-Sep-92 DAL
;
;*******************************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_9000"

orgadr	= $9000
; org orgadr

MyVersion	= $22
MinVersion	= $10

DvxAuxtype	= $8001
;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr orgadr
	.addr start
	.byte 0,0,0,0
; parameters here
	.byte 0,t_wildpath
	.byte $80+'a',t_nil	;all info
	.byte $80+'s',t_nil	;storage type
	.byte $80+'m',t_nil	;mod date
	.byte $80+'c',t_nil	;create date
	.byte $80+'x',t_nil	;aux type
	.byte $80+'b',t_nil	;blocks
	.byte $80+'l',t_nil	;length
	.byte $80+'n',t_nil	;no blank lines
	.byte 0,0
descr:	pstr "display important info about a file"
	
;*********************************************
; 32 locations at xczpage
path	= xczpage	;ds 2
myP	= path+2	;ds 2
scratch	= myP+2		;ds 1
flags	= scratch+1	;ds 1

f_STYPE	= %00000001
f_XTYPE	= %00000010
f_CRDAT	= %00000100
f_MODAT	= %00001000
f_BLKS	= %00010000
f_LEN	= %00100000
f_ALL	= %00111111

opt_chr:	.byte $80+'s',$80+'x',$80+'c',$80+'m',$80+'b',$80+'l',$80+'a'
opt_msk:	.byte f_STYPE,f_XTYPE,f_CRDAT,f_MODAT,f_BLKS,f_LEN,f_ALL

outa_here:
	jmp xProDOS_err

start:	nop			;don't display wildcard expansions
	lda #'n'+$80
	jsr xgetparm_ch
	bcc no_crout
	jsr crout
no_crout:
	jsr build_flags
	lda #0
	jsr xgetparm_n
	sta path+1
	sty path
	sta info_path+1
	sty info_path
	jsr mli
	.byte mli_gfinfo
	.addr info_parms
	bcs outa_here
	jsr read_some
	jsr pr_name_type
	jsr maybe_info
	jsr guess
	jsr disabled
	jmp invisible

;*********************************************
build_flags:
	lda #0
	sta flags
	ldy #opt_msk-opt_chr
bflag1:	tya
	pha
	lda opt_chr,y
	jsr xgetparm_ch
	pla
	tay
	bcs no_toggle
	lda opt_msk,y
	eor flags
	sta flags
no_toggle:
	dey
	bpl bflag1
	rts

;*********************************************
info_parms:	.byte 10
info_path:	.byte 0,0
info_acc:	.byte 0
info_ftype:	.byte 0
info_aux:	.byte 0,0
info_stype:	.byte 0
info_blocks:	.byte 0,0
info_mod:	.addr 0,0
info_create:	.addr 0,0
;*********************************************
pr_name_type:
	lda info_ftype
	jsr xprint_ftype
	jsr maybe_aux
	xmessage_cstr "    "
	lda path+1
	ldy path
	jsr xprint_path
	jmp crout

maybe_info:
	jsr maybe_modat
	jsr maybe_crdat
no_info1:
	lda flags
	and #f_BLKS+f_LEN+f_STYPE
	beq :+
	xmessage_cstr "   "
	jsr maybe_stype
	jsr maybe_blks
	jsr maybe_len
	jsr crout
:	rts

maybe_aux:
	lda flags
	and #f_XTYPE
	beq aux_no
	xmessage_cstr " $"
	lda info_aux+1
	jsr prbyte
	lda info_aux
	jsr prbyte
aux_no:	rts

maybe_stype:
	lda flags
	and #f_STYPE
	beq no_styp
	ldx info_stype
	cpx #$f+1
	bcc :+
	ldx #$10
:	lda styp_tbl,x
	tax
styp1:	lda stypes,x
	beq @done
	ora #$80
	jsr cout
	inx
	bne styp1
@done:	xmessage_cstr "   "
no_styp:
	rts

styp_tbl:
	.byte 0,st_SEED-stypes,st_SAP-stypes,st_TREE-stypes
	.byte st_PASC-stypes,st_EXT-stypes,0,0,0,0,0,0,0
	.byte st_DIR-stypes,0,st_VOL-stypes,0

stypes:		cstr "bad strg type"
st_SEED:	cstr "seedling     "
st_SAP:		cstr "sapling      "
st_TREE:	cstr "tree         "
st_PASC:	cstr "Pascal Area  "
st_EXT:		cstr "extended     "
st_DIR:		cstr "subdirectory "
st_VOL:		cstr "volume       "

maybe_crdat:
	lda flags
	and #f_CRDAT
	beq no_crd
	xmessage_cstr "   created:  "
	lda info_create+1
	ldy info_create
	jsr xpr_date_ay
	lda info_create+3
	ldy info_create+2
	jsr xpr_time_ay
	jmp crout
no_crd:	rts

maybe_modat:
	lda flags
	and #f_MODAT
	beq @out
	xmessage_cstr "   modified: "
	lda info_mod+1
	ldy info_mod
	jsr xpr_date_ay
	lda info_mod+3
	ldy info_mod+2
	jsr xpr_time_ay
	jmp crout
@out:	rts

maybe_blks:
	lda flags
	and #f_BLKS
	beq @out
	xmessage_cstr "blocks: "
	lda info_blocks+1
	ldy info_blocks
	jsr xprdec_2
	xmessage_cstr "   "
@out:	rts

maybe_len:
	lda flags
	and #f_LEN
	beq @out
	xmessage_cstr "bytes: "
	lda eof_val+2
	ldx eof_val+1
	ldy eof_val
	sta num+2
	stx num+1
	sty num
	jsr xprdec_3
@out:	rts

;*********************************************
;
; Files with types $B6 through $BD, except $BA,
; are disabled if bit 15 (msb) of the auxtype is set.
;
disabled:
	lda info_ftype
	cmp #$B6
	bcc @out
	cmp #$BD+1
	bcs @out
	cmp #$BA
	beq @out
	lda info_aux+1
	bpl @out
	xmessage_cstr_cr "   (disabled)"
@out:	rts

invisible:
	lda info_acc
	and #%00000100
	beq @out
	xmessage_cstr_cr "   (INVISIBLE)"
@out:	rts

;*********************************************
guess:	jsr check_vstore
	bcc is_vstore
	jsr check_binii
	bcc is_binii
	jsr check_sqz
	bcc is_sqz
	jsr omf_data
	lda info_ftype
	sta type_list
	ldx #listend-type_list
search:	dex
	cmp type_list,x
	bne search
	txa
	asl a
	tax
	lda guess_list+1,x
	pha
	lda guess_list,x
	pha
	rts
is_sqz:	jmp show_sqz
is_vstore:
	jmp show_vstore

is_binii:
	xmessage_cstr "   Binary II [v"
	ldy filebuff2+126
	lda #0
	jsr xprdec_2
	xmessage_cstr "]; contains "
	ldy filebuff2+127
	iny
	lda #0
	jsr xprdec_2
	xmessage_cstr " file"
	ldy filebuff2+127
	iny
	lda #0
	jsr xplural
	jsr crout

	ldx #127
mw1:	lda filebuff2+128,x
	cmp filebuff2,x
	bne mwx
	dex
	bpl mw1
	xmessage_cstr_cr "   [WARNING: 2nd 128 bytes are identical to 1st 128!]"
mwx:	rts

check_binii:
	lda filebuff2
	cmp #$0a
	bne no_b2
	lda filebuff2+1
	cmp #$47
	bne no_b2
	lda filebuff2+2
	cmp #$4c
	bne no_b2
	lda filebuff2+18
	cmp #$02
	bne no_b2
	clc
	rts
no_b2:	sec
	rts
;
; check_sqz -- return CLC if file is
;              squeezed
;
check_sqz:
	lda filebuff2
	cmp #$76
	bne no_b2
	lda filebuff2+1
	cmp #$ff
	bne no_b2
	clc
	rts
;
show_sqz:
	jsr xmess
	asc "   [Squeezed copy of "
	.byte $a2,0
	ldx #0
sqzn1:	lda filebuff2+4,x
	beq sqzn9
	ora #$80
	jsr cout
	inx
	bne sqzn1
sqzn9:	jsr xmess
	.byte $A2,$80+']',$8D,$00
	rts

;
; omf_data -- if file is an OMF file,
;             print OMF version
;
omf_data:	lda info_ftype
	cmp #$B1
	bcc @out
	cmp #$bf
	bcs @out
	xmessage_cstr "   [Object Module Format v"
	ldy filebuff2+$0f
	lda #0
	jsr xprdec_2
	xmessage_cstr_cr "]"
@out:	rts

;*********************************************
show_vstore:
	jsr xmess
	asc "   Stored-volume image (vstore/vrestore)"
	.byte cr
	cstr "   File #"

	ldy filebuff2+$40
	lda #0
	jsr xprdec_2
	xmessage_cstr "   vstore "
	lda filebuff2+$11
	jsr xprint_ver
	xmessage_cstr "; vrestore "
	lda filebuff2+$12
	jsr xprint_ver
	jsr xmess
	asc "+"
	.byte cr
	cstr "   Image of /"
	lda #>filebuff2
	ldy #<filebuff2+$29
	jsr xprint_path
	xmessage_cstr " from "
	lda filebuff2+$20
	jsr xprint_sd
	xmessage_cstr " ("
	lda filebuff2+$22
	ldy filebuff2+$21
	jsr xprdec_2
	xmessage_cstr_cr " blocks)"
	rts

check_vstore:
	ldx #$e
cvs1:	lda HdrImg,x
	cmp filebuff2,x
	bne notvs
	dex
	bpl cvs1
	clc
	rts
notvs:	sec
	rts

HdrImg:	.byte $60
	asc "VSTORE [Davex]"		; Verified in Davex 1.26 that the high bits are clear here.

;*********************************************
type_list:
	.byte 0
	.byte $00,$01		;typeless, bad
	.byte tBIN,tDIR		;binary, folder
	.byte $19,$1A,$1B	;ADB, AWP, ASP
	.byte $2A,$2B,$2C,$2D	;A2SRC,A2OBJ,A2Int,A2LangDat
	.byte $2E		;P8 code module
	.byte $42,$50		;FTD, word proc
	.byte $51,$52,$53,$54	;gs sprdsht, db, draw, dtp
	.byte $55,$56,$58,$59	;hypermedia, edu data, help, com
	.byte $5A,$5B,$5C	;cfg, anim, multimedia
	.byte $AB,$AC,$AD	;GSB, TDF, BDF
	.byte tSRC,$B1,$B2,$B3	;SRC,OBJ,LIB,S16
	.byte $B4,$B5,$B6,$B7	;RTL,EXE,PIF,TIF
	.byte $B8,$B9,$BA,$BB	;NDA,CDA,TOL,DRV
	.byte $BC,$BD,$BF	;GLF,FST,document
	.byte $C0,$C1		;packed pic, SHR pic
	.byte $C5,$C7,$C8,$C9,$CA ;OOG,CDV,FON,FND,ICN
	.byte $D5,$D6,$D7	;music seq, instr, midi
	.byte $D8,$DB		;samp snd, DB Master
	.byte $E0,$E2		;Archival library, ATLK data
	.byte $F0,$F9		;BASIC command, GS/OS sys file
	.byte $fc,$ff		;BAS, SYS
listend:

guess_list:
	.addr nothing-1
	.addr guess_00-1,guess_bad-1
	.addr guess_bin-1,guess_dir-1
	.addr guess_adb-1,guess_awp-1,guess_asp-1
	.addr guess_2a-1,guess_2b-1,guess_2c-1,guess_2d-1
	.addr guess_2e-1
	.addr guess_42-1,guess_50-1
	.addr guess_51-1,guess_52-1,guess_53-1,guess_54-1
	.addr guess_55-1,guess_56-1,guess_58-1,guess_59-1
	.addr guess_5a-1,guess_5b-1,guess_5c-1
	.addr guess_gsb-1,guess_tdf-1,guess_bdf-1
	.addr guess_src-1,guess_obj-1,guess_lib-1,guess_s16-1
	.addr guess_rtl-1,guess_exe-1,guess_pif-1,guess_tif-1
	.addr guess_nda-1,guess_cda-1,guess_tol-1,guess_drv-1
	.addr guess_glf-1,guess_fst-1,guess_doc-1
	.addr guess_pnt-1,guess_pic-1
	.addr guess_c5-1,guess_cdv-1,guess_fon-1,guess_fnd-1,guess_icn-1
	.addr guess_d5-1,guess_d6-1,guess_d7-1
	.addr guess_d8-1,guess_db-1
	.addr guess_e0-1,guess_e2-1
	.addr guess_f0-1,guess_f9-1
	.addr guess_bas-1,guess_sys-1

;*********************************************
read_some:
	ldx #0
	txa
:	sta filebuff2,x
	dex
	bne :-

	lda path+1
	ldy path
	sta open_path+1
	sty open_path
	jsr mli
	.byte mli_open
	.addr open_p
	bcs cant_open
	lda open_ref
	sta read_ref
	sta eof_ref
	jsr mli
	.byte mli_geteof
	.addr eof_parms
	bcs open_err
	jsr mli
	.byte mli_read
	.addr read_p
	bcc nothing
	cmp #err_eof
	bne open_err
nothing:
	rts
open_err:
	jmp xProDOS_err

cant_open:
	lda #0
	tax
co1:	sta filebuff2+$100,x
	sta filebuff2,x
	dex
	bne co1
	rts

open_p:	.byte 3
open_path:
	.addr 0
	.addr filebuff
open_ref:
	.byte 0

read_p:	.byte 4
read_ref:
	.byte 0
	.addr filebuff2
	.addr $200
read_len:
	.addr 0

eof_parms:
	.byte 2
eof_ref:
	.byte 1
eof_val:
	.byte 0,0,0

;*********************************************
;*********************************************
guess_2a:
	xmessage_cstr_cr "   Apple II Source Code"
	rts
guess_2b:
	xmessage_cstr_cr "   Apple II Object Code"
	rts
guess_2c:
	xmessage_cstr_cr "   Apple II Interpreted Code"
	rts
guess_2d:
	xmessage_cstr_cr "   Apple II Language Data"
	rts
guess_42:
	xmessage_cstr_cr "   File Type Names"
	rts
guess_50:
	xmessage_cstr_cr "   IIgs Word Processor"
	rts
guess_51:
	xmessage_cstr_cr "   IIgs Spreadsheet"
	rts
guess_52:
	xmessage_cstr_cr "   IIgs Data Base"
	rts
guess_53:
	xmessage_cstr_cr  "   Drawing"
	rts
guess_54:
	xmessage_cstr_cr "   Desktop Publishing"
	rts
guess_55:
	xmessage_cstr_cr "   Hypermedia"
	rts
guess_56:
	xmessage_cstr_cr "   Educational Data"
	rts
guess_58:
	xmessage_cstr_cr "   Help File"
	rts
guess_59:
	xmessage_cstr_cr "   Communications File"
	rts
guess_5a:
	xmessage_cstr_cr "   Configuration File"
	rts
guess_5b:
	xmessage_cstr_cr "   Animation File"
	rts
guess_5c:
	xmessage_cstr_cr "   Multimedia document"
	rts
guess_doc:
	xmessage_cstr_cr "   GS/OS document"
	rts
guess_c5:
	xmessage_cstr_cr "   Object-oriented graphics"
	rts
guess_cdv:
	xmessage_cstr_cr "   Control Panel document"
	rts
guess_d5:
	xmessage_cstr_cr "   Music sequence"
	rts
guess_d6:
	xmessage_cstr_cr "   Instrument"
	rts
guess_d7:
	xmessage_cstr_cr "   MIDI data"
	rts
guess_d8:
	xmessage_cstr_cr "   Audio IFF document"
	rts
guess_db:
	xmessage_cstr_cr "   DB Master document"
	rts
guess_e0:
	xmessage_cstr "   Archival Library: "
;%%%
	jmp crout
guess_e2:
	xmessage_cstr_cr "   AppleTalk data"
	rts
guess_f0:
	xmessage_cstr_cr "   BASIC command"
	rts
guess_f9:
	xmessage_cstr_cr "   GS/OS system file"
	rts
;
guess_bdf:
	xmessage_cstr_cr "   IIgs BASIC data file"
	rts
;
guess_bas:
	xmessage_cstr_cr "   Applesoft BASIC program"
	lda filebuff2
	ora filebuff2+1
	beq wbok
	jsr comp_basaux
	cmp info_aux+1
	bne warnbas
	cpy info_aux
	bne warnbas
wbok:	rts
warnbas:	tax
	tya
	pha
	txa
	pha
	xmessage_cstr "   [Warning!  Aux-type should be $"
	pla
	jsr prbyte
	pla
	jsr prbyte
	xmessage_cstr_cr "]"
	rts
;
; compute correct aux-type (=load address) for a BAS file; first
; block is in FileBuff2.
;
; File looks like this:
;   [byte 0]  LINK to next line (2 bytes)
;   [byte 2]  Line number (2 bytes)
;   [byte 4]  characters & tokens (n bytes, n>=0)
;   [b  4+n]  $00 (end of line marker)
;
; For a correct program, AuxType + n+4 = LINK, so
; AuxType = LINK - offset-to-end-of-line
;
comp_basaux:
	ldy #3
scaneol:
	iny
	lda filebuff2,y
	bne scaneol
	iny
	sty scratch
	sec
	lda filebuff2
	sbc scratch
	tay
	lda filebuff2+1
	sbc #0
	rts

guess_bad:
	xmessage_cstr_cr "   bad file"
	rts

guess_sys:
	jsr check_alias8
	bcc was_alias
	xmessage_cstr_cr "   ProDOS 8 application"
was_alias:
	jsr chk_startup
	cmp #0
	beq gsysz
	pha
	xmessage_cstr "   ["
	pla
	tay
	lda #0
	jsr xprdec_2
	jsr xmess
	asc "-byte startup buffer contains "
	.byte $a2,0
	lda #>filebuff2
	ldy #<filebuff2+6
	jsr xprint_path
	jsr xmess
	.byte $A2,$80+']',cr,0
gsysz:	rts

chk_startup:
	lda filebuff2
	cmp #$4c
	bne cbuf0
	lda #$ee
	cmp filebuff2+3
	bne cbuf0
	cmp filebuff2+4
	bne cbuf0
	lda filebuff2+5
	rts
cbuf0:	lda #0
	rts

check_alias8:
	lda filebuff2
	cmp #$4c
	bne g8no
	lda filebuff2+1
	cmp #$4c
	bne g8no
	lda filebuff2+2
	cmp #$20
	bne g8no
	lda filebuff2+3
	cmp #$ee
	bne g8no
	lda read_len+1
	cmp #>359
	bne g8no
	lda read_len
	cmp #<359
	bne g8no
	jsr xmess
	asc "   sysalias for "
	.byte $A2	; double quote
	.byte 0
	lda #>(filebuff2+$E5)
	ldy #<filebuff2+$E5
	jsr xprint_path
	jsr xmess
	.byte $A2,cr,0
	clc
	rts
g8no:	sec
	rts

guess_fon:
	xmessage_cstr "   IIgs font: "
	ldy filebuff2
	ldx #1
fontnm1:
	lda filebuff2,x
	ora #$80
	cmp #$A0
	bcc fnmx
	jsr cout
fnmx:	inx
	dey
	bne fontnm1
	jsr xmess
	.byte $80+' ',0
	ldx filebuff2
	lda filebuff2+7,x
	tay
	lda #0
	jsr xprdec_2
	jmp crout
;
guess_obj:
	xmessage_cstr_cr "   IIgs object file (for linker)"
	rts
;
guess_lib:
	xmessage_cstr_cr "   IIgs library file"
	rts
;
guess_s16:
	xmessage_cstr_cr "   IIgs application"
	rts
;
guess_rtl:
	xmessage_cstr_cr "   IIgs run-time library"
	rts
;
guess_exe:
	xmessage_cstr_cr "   IIgs shell application"
	rts
;
guess_nda:
	xmessage_cstr_cr "   IIgs New Desk Accessory (under Apple menu)"
	rts
;
guess_cda:
	xmessage_cstr_cr "   IIgs Classic Desk Accessory (Apple-Ctrl-ESC)"
	rts
;
guess_awp:
	xmessage_cstr_cr "   AppleWorks Word Processor file"
	rts
;
guess_adb:
	xmessage_cstr_cr "   AppleWorks Database file"
	rts
;
guess_asp:
	xmessage_cstr_cr "   AppleWorks Spreadsheet file"
	rts
;
guess_icn:
	xmessage_cstr_cr "   IIgs Icon file"
	rts
;
guess_fnd:
	xmessage_cstr_cr "   IIgs Finder data file"
	rts
;
guess_tif:
	xmessage_cstr_cr "   IIgs temporary init file"
	rts
;
guess_pif:
	xmessage_cstr_cr "   IIgs permanent init file"
	rts
;
guess_glf:
	xmessage_cstr_cr "   IIgs Generic Load File"
	rts
;
guess_fst:
	xmessage_cstr_cr "   GS/OS File System Translator"
	rts
;
;%%%
guess_drv:	lda info_aux+1
	bne drv_unkn
	lda info_aux
	cmp #3
	beq drv3
	cmp #2
	beq drv2
	cmp #1
	bne drv_unkn
	xmessage_cstr_cr "   IIgs printer driver"
	rts
drv2:
	xmessage_cstr_cr "   IIgs interface driver"
	rts
drv_unkn:
	xmessage_cstr_cr "   unknown IIgs Driver"
	rts
drv3:
	xmessage_cstr_cr "   IIgs AppleTalk driver"
	rts
;
guess_gsb:
	xmessage_cstr_cr "   IIgs BASIC program"
	rts
;
guess_tdf:
	xmessage_cstr_cr "   IIgs BASIC Tool Definition File"
	rts
;
guess_pic:
	lda info_aux+1
	bne pic_unkn
	lda info_aux
	cmp #2
	bcs pic_unkn
	cmp #0
	beq pic_32k
	xmessage_cstr_cr "   unpacked QD PICT"
	rts

pic_32k:
	xmessage_cstr_cr "   unpacked super-hires picture (32K)"
	rts

pic_unkn:
	xmessage_cstr_cr "   unpacked super-hires picture; unknown format"
	rts
;
guess_2e:
	lda info_aux+1
	cmp #>DvxAuxtype
	bne notDvxCmd
	lda info_aux
	cmp #<DvxAuxtype
	bne notDvxCmd
	jsr chk_xtn
	bcs notDvxCmd
	rts
notDvxCmd:
	xmessage_cstr_cr "   ProDOS 8 code module"
	rts
;
guess_bin	= *
	jsr chk_xtn
	bcs not_xtn
	rts
not_xtn	= *
; %%% other binary file stuff here
	rts
;
xtn_no:	sec
	rts
chk_xtn	= *
	lda filebuff2
	cmp #$60
	bne xtn_no
	lda #$ee
	cmp filebuff2+1
	bne xtn_no
	cmp filebuff2+2
	bne xtn_no
xtn_yes	= *
	xmessage_cstr "   external command ("
	lda filebuff2+3
	jsr xprint_ver
	xmessage_cstr ") for Davex "
	lda filebuff2+4
	jsr xprint_ver
	lda filebuff2+12
	ora #_'0'
	jsr cout
	xmessage_cstr "+  (at $"
	lda filebuff2+9
	jsr prbyte
	lda filebuff2+8
	jsr prbyte
	xmessage_cstr_cr ")"
;
	lda filebuff2+6
	ora filebuff2+7
	beq no_purp
	xmessage_cstr "   {"
	jsr print_purp
	xmessage_cstr_cr "}"
no_purp:	clc
	rts
;
; print_purp -- print the description of an
; external command; first 512 bytes are in
; filebuff2.
;
; Subtract "orgaddr" field from "descr" field
; to find out how far into the xc to go to find
; the string.  String is 1-byte length prefixed.
;
print_purp:
	sec
	lda filebuff2+6
	sbc filebuff2+8
	tay
	lda filebuff2+7
	sbc filebuff2+9
	tax
	bne badpurp
	sty myP
	clc
	adc #>filebuff2
	sta myP+1
	ldy #0
	lda (myP),y
	beq badpurp
	tax
prpur1:	iny
	lda (myP),y
	ora #$80
	cmp #$a0
	bcc prpbad
	jsr cout
prpbad:	dex
	bne prpur1
badpurp:
	rts

;*********************************************
guess_00:
	lda info_aux
	cmp #$87
	bne @out
	lda info_aux+1
	cmp #$19
	bne @out
	xmessage_cstr_cr "   [File encrypted with Bredon's CRYPTOR]"
@out:	rts

;*********************************************
;%%%
guess_src:
	xmessage_cstr "   APW "
	lda info_aux+1
	bne src_unkn_cr
	lda info_aux
	cmp #30+1
	bcs src_unkn_cr
	jsr printsrc
	jmp crout

printsrc:
	asl a
	tax
	lda src_table+1,x
	pha
	lda src_table,x
	pha
	rts

; common auxtypes for SRC files
src_table:
	.addr SRCprotext-1	;0
	.addr SRCtext-1		;1
	.addr SRC6502-1		;2
	.addr SRC65816-1	;3
	.addr SRCbasic-1	;4
	.addr SRCbwpascal-1	;5
	.addr SRCexec-1		;6
	.addr SRCsmallc-1	;7
	.addr SRCbwc-1		;8
	.addr SRClinked-1	;9
	.addr SRCcc-1		;10
	.addr SRCpascal-1	;11
	.addr SRCcmd-1		;12
	.addr src_unkn-1	;13
	.addr src_unkn-1	;14
	.addr src_unkn-1	;15
	.addr src_unkn-1	;16
	.addr src_unkn-1	;17
	.addr src_unkn-1	;18
	.addr src_unkn-1	;19
	.addr src_unkn-1	;20
	.addr src_unkn-1	;21
	.addr src_unkn-1	;22
	.addr src_unkn-1	;23
	.addr src_unkn-1	;24
	.addr src_unkn-1	;25
	.addr src_unkn-1	;26
	.addr src_unkn-1	;27
	.addr src_unkn-1	;28
	.addr src_unkn-1	;29
	.addr SRC_TML-1		;30

src_unkn_cr:
	jsr src_unkn
	jmp crout

src_unkn: xmessage_cstr "[unknown]"   ; is the CR here a bug?
	rts

SRCprotext:
	xmessage_cstr "ProDOS text file"
	rts
;
SRCtext:
	xmessage_cstr "text"
	rts
;
SRC6502:
	xmessage_cstr "6502 assembly"
	rts
;
SRC65816:
	xmessage_cstr "65816 assembly"
	rts
;
SRCbasic:
	xmessage_cstr "BASIC"
	rts
;
SRCbwpascal:
	xmessage_cstr "Byte Works Pascal"
	rts
;
SRCexec:
	xmessage_cstr "exec file"
	rts
;
SRCsmallc:
	xmessage_cstr "Byte Works Small C"
	rts
;
SRCbwc:
	xmessage_cstr "Byte Works C"
	rts

SRCbwbasic:
	xmessage_cstr "Byte Works BASIC"
	rts

SRCcc:
	xmessage_cstr "C"
	rts

SRCpascal:
	xmessage_cstr "Pascal"
	rts

SRCcmd:
	xmessage_cstr "command processor window"
	rts

SRClinked:
	xmessage_cstr "linker script"
	rts

SRC_TML:
	xmessage_cstr "TML Pascal"
	rts
;*********************************************
guess_dir:
	lda info_stype
	cmp #15
	beq is_vol
	cmp #13
	beq is_subd
	xmessage_cstr_cr "   Ouch!  Not really a directory"
is_subd:
is_vol:
	rts
;
guess_pnt:
	xmessage_cstr "   "
	lda info_aux+1
	bne pnt_unkn
	lda info_aux
	cmp #4
	bcs pnt_unkn
	asl a
	tax
	lda #>(pntx-1)
	pha
	lda #<pntx-1
	pha
	lda pnttbl+1,x
	pha
	lda pnttbl,x
	pha
	rts

pnttbl:	.addr pnt_pw-1,pnt_pack-1,pnt_apple-1,pnt_ppict-1

pnt_pw:
	xmessage_cstr "packed PaintWorks"
	rts

pnt_pack:
	xmessage_cstr "PackBytes"
	rts

pnt_apple:
	xmessage_cstr "Apple preferred"
	rts

pnt_ppict:
	xmessage_cstr "packed QD PICT"
	rts

pnt_unkn:
	xmessage_cstr "unknown"
pntx:
	xmessage_cstr_cr " format"
	rts

toolnum: .byte 0

guess_tol:
	lda #0
	sta toolnum
	lda path+1
	ldy path
	sta myP+1
	sty myP
	ldy #0
	lda (myP),y
	cmp #7
	bcc tolx
	tay
	dey
	dey
	lda (myP),y
	jsr mult10
	iny
	lda (myP),y
	jsr mult10
	iny
	lda (myP),y
	jsr mult10

	xmessage_cstr "   "

	lda toolnum
	cmp #54
	bcc lessmaxt
	lda #0
lessmaxt:
	asl a
	tax
	lda toolnames+1,x
	sta myP+1
	lda toolnames,x
	sta myP
	ldy #0
	lda (myP),y
	tax
:	iny
	lda (myP),y
	ora #$80
	jsr cout
	dex
	bne :-
	jsr crout
tolx:	rts

mult10:	and #%00001111
	pha
	asl toolnum
	lda toolnum
	asl toolnum
	asl toolnum
	clc
	adc toolnum
	sta toolnum
	pla
	clc
	adc toolnum
	sta toolnum
	rts

toolnames:
	.addr tool0,tool1,tool2,tool3,tool4,tool5,tool6,tool7
	.addr tool8,tool9,tool10,tool11,tool12,tool13,tool14,tool15
	.addr tool16,tool17,tool18,tool19,tool20,tool21,tool22,tool23
	.addr tool24,tool25,tool26,tool27,tool28,tool29,tool30,tool31
	.addr tool32,tool33,tool34,tool35,tool36,tool37,tool38,tool39
	.addr tool40,tool41,tool42,tool43,tool44,tool45,tool46,tool47
	.addr tool48,tool49,tool50,tool51,tool52,tool53

tool0	= *
tool1	= *
tool2	= *
tool3	= *
tool4	= *
tool5	= *
tool6	= *
tool7	= *
tool8	= *
tool9	= *
tool10	= *
tool11	= *
tool12	= *
tool13	= *
tool30	= *
tool31	= *
tool36	= *
tool39	= *
tool40	= *
tool41	= *
tool42	= *
tool43	= *
tool44	= *
tool45	= *
tool46	= *
tool47	= *
tool48	= *
tool49	= *
	pstr "????"
	
tool14:	pstr "Window Manager"
tool15:	pstr "Menu Manager"
tool16:	pstr "Control Manager"
tool17:	pstr "Loader"
tool18:	pstr "QuickDraw Auxiliary"
tool19:	pstr "Printer tools"
tool20:	pstr "Line Edit"
tool21:	pstr "Dialog Manager"
tool22:	pstr "Scrap Manager"
tool23:	pstr "Standard File"
tool24:	pstr "Disk Utilities"
tool25:	pstr "Note Synthesizer"
tool26:	pstr "Note Sequencer"
tool27:	pstr "Font Manager"
tool28:	pstr "List Manager"
tool29:	pstr "Audio Compression/Expansion"
tool32:	pstr "MIDI Tools"
tool33:	pstr "Video Overlay tools"
tool34:	pstr "Text Edit"
tool35: pstr "MIDI Synth toolset"
tool37: pstr "Animation"
tool38: pstr "Media Control toolset"
tool50:	pstr "Male speech (TML Systems/First Byte)"
tool51:	pstr "Female speech (TML Systems/First Byte)"
tool52:	pstr "English to phonetics (TML Systems)"
tool53: pstr "Call Box TPS (So What Software)"
;*********************************************
