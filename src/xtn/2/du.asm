;*********************************************
;
; External command for Davex
;
; du -- disk usage
;
; prints table of device #s, volume names,
; K free, % used; totals K free and % used
;
;*********************************************
;
; Modified 12-Dec-87 DL ==> v1.3
;  to NOT depend on the contents of DEVLST
;  or DEVCNT.  (For compatibility with future
;  developments in the ProDOS world.)
;
; Modified 27-Feb-88 DL ==> v1.4
;  Source converted to Merlin Pro.
;  Accepts an optional pathname; if present,
;    prints info only on that volume.
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************

.segment	"CODE_9000"

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.Globals2.asm"
	.include "Common/Macros.asm"

main:

OrgAdr	= $9000
; org OrgAdr

MyVersion	= $14
MinVersion	= $10
;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr OrgAdr
	.addr Start
	.byte 0,0,0,0
; parameters here
	.byte 0,t_path
	.byte 0,0
descr:

	pstr "print disk-use statistics"

;*********************************************
; dum xczpage
total_blocks	= xczpage	;ds 3
total_used	= total_blocks+3	;ds 3
volumes	= total_used+3	;ds 1
swapped	= volumes+1	;ds 1
volfree	= swapped+1	;ds 2
MyP	= volfree+2	;ds 2
; dend
;
Start:
	sta MyP+1
	sty MyP
	ldy #0
	lda (MyP),y
	beq AllVols
	jmp JustOne
AllVols:
	jsr crout
	lda #0
	sta volumes
	ldx #5
zero:	sta total_blocks,x
	dex
	bpl zero
;
; print header
;
	jsr xmess


	asc "  dev  volume            available K  used %"

	.byte cr,0
	bit xspeech
	bmi skipdashes
	jsr xmess


	asc "  ---  ----------------  -----------  ------"

	.byte cr,0
skipdashes:
	ldx #0
loop1:	cpx #14
	bcs loopx
	txa
	pha
	lda devices,x
	jsr print_line
	pla
	tax
	inx
	bne loop1
loopx:
	bit xspeech
	bmi skip2
	jsr xmess


	asc "                         ===========  ======"

	.byte cr,0
skip2:
	jmp print_totals
;*********************************************
fetch_info:
	sta online_dev
	jsr mli
	.byte mli_online
	.addr online_parms
	bcs nothing
	inc volumes
;
	lda pagebuff+1
	and #%00001111	;volnam len
	clc
	adc #1
	sta pagebuff
	lda #'/'+$80
	sta pagebuff+1
;
	lda #>pagebuff
	ldy #<pagebuff
	sta info_parms+2
	sty info_parms+1
	jsr mli
	.byte mli_gfinfo
	.addr info_parms
	bcs nothing
	rts
;
print_line:	jsr fetch_info
	bcs nothing
	jsr update_totals
	jsr print_info
nothing:	rts
;
online_parms:	.byte 2
online_dev:	.res 1
		.addr pagebuff+1
;
info_parms:	.byte 10
	.addr pagebuff
	.res 1	;acc
	.res 1	;ftyp
volsize:	.res 2
stype:	.res 1	;strg type
volused:	.res 2
	.res 8	;date/time
;*********************************************
update_totals:
	clc
	lda total_blocks
	adc volsize
	sta total_blocks
	lda total_blocks+1
	adc volsize+1
	sta total_blocks+1
	lda total_blocks+2
	adc #0
	sta total_blocks+2
;
	sec
	lda volsize
	sbc volused
	sta volfree
	lda volsize+1
	sbc volused+1
	sta volfree+1
;
	clc
	lda total_used
	adc volused
	sta total_used
	lda total_used+1
	adc volused+1
	sta total_used+1
	lda total_used+2
	adc #0
	sta total_used+2
	rts
;*********************************************
print_info:
	jsr sp2
; .sd
	lda online_dev
	jsr xprint_sd
; /xxxxxx
	jsr sp2
	lda #>pagebuff
	ldy #<pagebuff
	jsr xprint_path
	lda #18
	sec
	sbc pagebuff
	tax
spacex:	lda #$A0
	jsr cout
	dex
	bne spacex
; xxxxxxxxK
	lda #0
	ldx volfree+1
	ldy volfree
	jsr print_k
;
	jsr sp2
	jsr cout
; xx%
	lda #0
	ldx volused+1
	ldy volused
	sta xnum+2
	stx xnum+1
	sty xnum
	ldx volsize+1
	ldy volsize
	jsr xpercent
	sta xnum
	lda #0
	sta xnum+1
	sta xnum+2
	ldy #2
	jsr xprdec_pady
	jsr xmess


	asc "%"

	.byte cr,0
	rts
;*********************************************
print_totals:
	jsr xmess


	asc "                         "

	.byte 0
	sec
	lda total_blocks
	sbc total_used
	tay
	lda total_blocks+1
	sbc total_used+1
	tax
	lda total_blocks+2
	sbc total_used+2
	jsr print_k
	jsr xmess


	asc "   "

	.byte 0
	lda total_used+2
	ldx total_used+1
	ldy total_used
	sta xnum+2
	stx xnum+1
	sty xnum
	lda total_blocks+2
	ldx total_blocks+1
	ldy total_blocks
	jsr xpercent
	sta xnum
	lda #0
	sta xnum+1
	sta xnum+2
	ldy #2
	jsr xprdec_pady
	jsr xmess


	asc "%"

	.byte cr,cr


	asc "      "

	.byte 0
	ldy volumes
	lda #0
	jsr xprdec_2
	jsr xmess


	asc " volume"

	.byte 0
	lda #0
	ldy volumes
	jsr xplural
	jsr xmess


	asc "; total storage:"

	.byte 0
	lda total_blocks+2
	ldx total_blocks+1
	ldy total_blocks
	jsr print_k
	jsr xmess
	.byte cr,0
	rts
;*********************************************
print_k:
	sta xnum+2
	stx xnum+1
	sty xnum
	lsr xnum+2
	ror xnum+1
	ror xnum
	jsr xprdec_pad
	jsr xmess


	asc "K"

	.byte 0
;*********************************************
sp2:	lda #$a0
	jsr cout
	jmp cout
;*********************************************
devices:	.byte $10,$90,$20,$a0,$30,$b0,$40,$c0
	.byte $50,$d0,$60,$e0,$70,$f0
;*********************************************
;*********************************************
j1err:	jmp xProDOS_err
JustOne:
	jsr crout
	lda MyP+1
	ldy MyP
	sta info_parms+2
	sty info_parms+1
	jsr mli
	.byte mli_gfinfo
	.addr info_parms
	bcs j1err
	lda stype
	cmp #$f
	beq is_volume
	lda devnum
	jsr fetch_info
	bcs j1err
is_volume:
	lda info_parms+2
	ldy info_parms+1
	jsr xprint_path
	jsr xmess


	asc ":   blocks free = "

	.byte nul
	sec
	lda volsize
	sbc volused
	tay
	lda volsize+1
	sbc volused+1
	jsr xprdec_2
	jsr xmess


	asc "    used = "

	.byte nul
	lda volused+1
	ldy volused
	jsr xprdec_2
	jsr show_percent
	jsr xmess


	asc "     total = "

	.byte nul
	lda volsize+1
	ldy volsize
	jsr xprdec_2
	jmp crout
;
; show_percent -- volused/volsize
;
;   " (xx%)"
;
show_percent:
	jsr xmess

	asc "  ("

	.byte 0
	lda #0
	ldx volused+1
	ldy volused
	sta xnum+2
	stx xnum+1
	sty xnum
	lda #0
	ldx volsize+1
	ldy volsize
	jsr xpercent
	tay
	lda #0
	jsr xprdec_2
	jsr xmess


	asc "%)"

	.byte 0
	rts
;*********************************************