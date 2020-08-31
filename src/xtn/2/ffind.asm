;*********************************************
; Bugs:  wildcards should be allowed (weren't working)
;
; Should deal with insufficent access and bad
; pathnames (for AppleShare)
;*********************************************
;
; External command for Davex
;
; ffind -- locate files by name, type, auxtype, etc
;
; ffind [<pathname>] [-n <name>] [-f <filetype>]
;       [-x <integer>] [-e] [-q] [-p] [-d] [-b y|n]
;       [-o <string>] [-s <integer>] [-i y|n]
;
;   path    --where to look (omit-->scan all volumes)
;   -n      --name to match
;   -f      --filetype to match
;   -x      --auxiliary type to match
;   -e      --name match must be exact
;   -q      --query "continue searching?"
;   -p      --set prefix to dir containing match
;   -d      --detail (print type, auxtype)
;   -o      --output string template
;   -b y|n  --find if backup bit set
;   -i y|n  --find if invisible
;   -s<int> --find specific storage type
;
;*********************************************
;
; 11-Jun-89 DAL ==> v1.2
;   -i and -s options added
;   -d sense reversed (now means NO detail)
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"
	;

.segment	"CODE_A000"

OrgAdr	= $A000	;change as necessary (end below $B000)
; org OrgAdr

MyVersion	= $12
MinVersion	= $12
MinVerAux	= $05	;v1.25+
;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr OrgAdr
	.addr start
	.byte MinVerAux,0,0,0
; parameters here
	.byte 0,t_path	;where to look
	.byte $80+'n',t_string ;what to look for
	.byte $80+'p',t_nil	;set prefix when found
	.byte $80+'e',t_nil	;exact matches only
	.byte $80+'f',t_ftype ;certain filetype only
	.byte $80+'x',t_int2	;certain auxtype only
	.byte $80+'q',t_nil	;query
	.byte $80+'o',t_string ;output string format
	.byte $80+'d',t_nil	;detail
	.byte $80+'b',t_yesno
	.byte $80+'i',t_yesno
	.byte $80+'s',t_int1
	.byte 0,0
descr:	pstr "locate files by name/type/auxtype/etc"
	
;*********************************************
; dum xczpage ;32 locations
str	= xczpage	;ds 2
path	= str+2	;ds 2
out	= path+2	;ds 2
no_exact	= out+2	;ds 1 ;exact-match flag
no_query	= no_exact+1	;ds 1 ;query flag
temp_ch	= no_query+1	;ds 1
str_len	= temp_ch+1	;ds 1
startpos	= str_len+1	;ds 1
count	= startpos+1	;ds 1
exit_flag	= count+1	;ds 1
specialMark	= exit_flag+1	;ds 1
; dend

pathbuff	= OrgAdr-$100
;*******************************
start:
	sta path+1
	sty path

	lda #'q'+$80
	jsr xgetparm_ch
	ror no_query

	lda #'e'+$80
	jsr xgetparm_ch
	ror no_exact

	lda #0
	sta direcpath
	sta exit_flag

	ldy #0
	lda (path),y
	beq all_units
	lda path+1
	ldy path
	jmp find_ay

all_units:
	ldx #0
one_u:	txa
	pha
	lda unit_list,x
	jsr find_on_unit
	pla
	tax
	inx
	cpx #$0E
	bcc one_u
	rts

unit_list:	.byte $10,$90,$20,$A0,$30,$B0,$40,$C0
	.byte $50,$D0,$60,$E0,$70,$F0

find_on_unit:
	sta onl_unit
	jsr mli
	.byte mli_online
	.addr online_parms
	bcc good_unit
	rts

online_parms:	.byte 2
onl_unit:	.res 1
	.addr pathbuff+1

good_unit:
	lda pathbuff+1
	and #$0f
	tax
	inx
	stx pathbuff
	lda #'/'
	sta pathbuff+1
;
	jsr xpmgr
	.byte pm_downcase
	.addr pathbuff
;
	lda #>pathbuff
	ldy #<pathbuff

find_ay:
	pha
	tya
	pha
	jsr xpush_level
	pla
	tay
	pla
	jsr xdir_setup2
	bcc find1
	jmp xProDOS_err
find1:	bit exit_flag
	bmi did_read
	jsr chkabort

	jsr xread1dir
	bcs did_read

	ldx #' '+$80
	lda catbuff
	and #$f0
	cmp #$50
	bne notExtended
	ldx #'+'+$80
notExtended:	stx specialMark

	jsr test_entry
	bcs try_next

	jsr found_match
; query?
	bit no_query
	bmi try_next
	jsr xmess

	
	asc "Continue searching"
	
	.byte 0
	lda #'y'+$80
	jsr xyesno2
	bne try_next
	sec
	ror exit_flag

try_next:
	bit exit_flag
	bmi did_read
	lda catbuff+16
	cmp #tDIR
	bne no_recurse

	lda catbuff
	and #$0f
	sta catbuff
	lda #>catbuff
	ldy #<catbuff
	jsr find_ay

no_recurse:	jmp find1

did_read:	jmp xdir_finish
;
; found a match--print it, etc.
;
found_match:
	jsr detail
	jsr showpath
	jsr setpfx
	jsr xcheck_wait
	bcs abort9
	rts
abort9:	jmp abort

detail:	lda #'d'+$80
	jsr xgetparm_ch
	bcc detail_x	;11-Jun-89
	lda specialMark
	jsr cout
	lda catbuff+16
	jsr xprint_ftype
	jsr xmess

	
	asc " $"
	
	.byte 0
	lda catbuff+$20
	jsr prbyte
	lda catbuff+$1f
	jsr prbyte
	jsr xmess

	
	asc " "
	
	.byte 0
	lda catbuff+$22
	ldy catbuff+$21
	jsr xpr_date_ay
	lda catbuff+$24
	ldy catbuff+$23
	jsr xpr_time_ay
	jsr xmess

	
	asc "  "
	
	.byte 0
detail_x:	rts

showpath:	jsr showpath2
	jmp crout

showpath2:	lda #'o'+$80
	jsr xgetparm_ch
	bcs plainpath
	sta out+1
	sty out
	ldy #0
	lda (out),y
	sta count
	beq spath_x
spath1:	iny
	lda (out),y
	ora #$80
	cmp #'='+$80
	bne plainch
	tya
	pha
	jsr plainpath
	pla
	tay
	bne nextch
plainch:	jsr cout
nextch:	dec count
	bne spath1
spath_x:	rts

plainpath:
	lda #>direcpath
	ldy #<direcpath
	jsr xprint_path
	lda #>catbuff
	ldy #<catbuff
	jmp xprint_path

abort0:	sta kbdstrb
abort:	lda #der_abort
	jmp xProDOS_err

chkabort:	lda $c000
	bpl chka_ok
	and #$7f
	cmp #$1b
	beq abort0
	cmp #$03
	beq abort0
	cmp #'.'
	bne chka_ok
	bit $c061
	bmi abort0
chka_ok:	rts
;
; test entry in catbuff against -n, -x, -f, -b, -i, -s
;
test_entry:
	jsr test_strg
	bcs match_no
	lda catbuff
	and #$0f
	sta catbuff
	jsr test_name
	bcs match_no
	jsr test_type
	bcs match_no
	jsr test_aux
	bcs match_no
	jsr test_bkup
	bcs match_no
	jsr test_invis
match_no:	rts

test_type:
	lda #'f'+$80
	jsr xgetparm_ch
	bcs type_ok
	cmp catbuff+16
	bne type_no
type_ok:	clc
	rts
type_no:	sec
	rts

test_strg:
	lda #'s'+$80
	jsr xgetparm_ch
	bcs type_ok
	sty strgCheat+1
	lda catbuff
	lsr a
	lsr a
	lsr a
	lsr a
strgCheat:	cmp #$77	;modified
	beq type_ok
	bne type_no

test_aux:
	lda #'x'+$80
	jsr xgetparm_ch
	bcs type_ok
	cpx catbuff+$20
	bne type_no
	cpy catbuff+$1f
	bne type_no
	clc
	rts

test_bkup:
	lda #'b'+$80
	jsr xgetparm_ch
	bcs bkup_ok
	cmp #0
	beq test_bn
; test_by
	lda catbuff+$1E
	and #$20
	beq bkup_no
bkup_ok:	clc
	rts
test_bn:	lda catbuff+$1e
	and #$20
	beq bkup_ok
bkup_no:	sec
	rts

test_invis:
	lda #'i'+$80
	jsr xgetparm_ch
	bcs invis_ok
	cmp #0
	beq test_in
; test_iy
	lda catbuff+$1E
	and #$04
	beq invis_no
invis_ok:	clc
	rts
test_in:	lda catbuff+$1e
	and #$04
	beq invis_ok
invis_no:	sec
	rts

test_name:	lda #'n'+$80
	jsr xgetparm_ch
	bcs null_match
	sta str+1
	sty str

	bit no_exact
	bmi not_exact
; check for exact name match
	ldy catbuff
exact1:	lda catbuff,y
	jsr xdowncase
	sta temp_ch
	lda (str),y
	jsr xdowncase
	cmp temp_ch
	bne exact_no
	dey
	cpy #<-1
	bne exact1
	clc
	rts
exact_no:	sec
	rts
;
; check if str contained in catbuff
;
null_match:	clc
	rts
not_exact:
	ldy #0
	lda (str),y
	sta str_len
	beq null_match
	cmp catbuff
	beq ne_maybe
	bcs ne_no
ne_maybe:
	lda catbuff
	clc
	adc #1
	sec
	sbc str_len
	sta startpos
chk_here:	ldx startpos
	lda str_len
	sta count
	ldy #1
chkh1:	lda (str),y
	jsr xdowncase
	sta temp_ch
	lda catbuff,x
	jsr xdowncase
	cmp temp_ch
	bne chk_next
	inx
	iny
	dec count
	bne chkh1
	clc
	rts
chk_next:	dec startpos
	bpl chk_here
ne_no:	sec
	rts
;
; set prefix to directory containing the
; entry we found (if -p was given)
;
setpfx:	lda #'p'+$80
	jsr xgetparm_ch
	bcs setpfx_x
	jsr mli
	.byte mli_setpfx
	.addr setp_parms
	bcc setpfx_x
	jmp xProDOS_err
setpfx_x:	rts

setp_parms:
	.byte 1
	.addr direcpath
;*********************************************
