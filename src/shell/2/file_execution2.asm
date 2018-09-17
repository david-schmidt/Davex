;****************************************
;
; shell/runcmd -- SYS/BIN/S16 file runner
;                 for Davex
;
;****************************************
run_s16:
	jsr notspool
	sec
	jsr $fe1f	;IIgs?
	bcs typerr
	lda #>bridge_name
	ldy #<bridge_name
	jsr build_local
	sta br_ugh+2
	sty br_ugh+1
	ldx #63
br_ugh:	lda $ffff,x
	and #$7f	;23-Feb-88
	sta $2c0,x
	dex
	bpl br_ugh

	ldx #3
cpdave:	lda dave,x
	.byte $9f,$02,$01,$01 ;STA $010102,X
	dex
	bpl cpdave

	ldx #63
cpys16:	lda cmdpath,x
	and #$7f	;ProDOS 16 cares about high bit!
	.byte $9f,$06,$01,$01 ;STA $010106,X
	lda mypath_all,x
	and #$7f
	.byte $9f,$46,$01,$01 ;STA $010146,X
	dex
	bpl cpys16
	CALLOS  mli_bye, s16p
	.byte 0	;single-byte BRK
s16p:	.byte 4,$ee
	.addr $2c0,0

bridge_name:
	pstr "BRIDGE.S16"
dave:	asc "DAVE"

run_something:
	cmp #tSYS
	beq is_sys
	cmp #tS16
	beq run_s16
	cmp #$B5	;can run EXE files, too!
	beq run_s16
	cmp #$2E	;$2E;$8001 is a Dvx command
	bne cmdNot2E
	ldx info_auxtype+1
	cpx #$80
	bne cmdNot2E
	ldx info_auxtype
	cpx #$01
	beq run_ext0
cmdNot2E:
	cmp #tBIN
	bne typerr
run_ext0:
	jmp run_external

typerr:	pha
	message_cstr "Can't run '"
	pla
	jsr print_ftype
	message_cstr_cr "' files"
	jmp main_err

is_sys:	jsr notspool
	jsr finish_oredir
	jsr finish_iredir
	jsr chk_argu
	ldx #127
copy280:
	lda cmdpath,x
	jsr upcase
	and #$7f
	sta $280,x
	dex
	bpl copy280
	lda #0
	SET_LEVEL
	jsr close
	jsr open_sys
	bcs run_err
;
; If '-n' parameter given, don't replace quit code
;
	lda #$80+'n'
	jsr getparm_ch
	bcc no_return
	jsr write_quit
	jsr my_quit
no_return:
	jsr copy_loader
	jsr off80
	jsr $fe89
	jsr $fe93
	start_normal
	jsr home
	lda #>cmdpath
	ldy #<cmdpath
	jsr print_path
	message_cstr_cr "..."
	jsr hook_speech
	lda $3f3
	sta $3f4	; cause Reset to reboot

	lda #$ff	; disconnect NMI
	ldy #$59
	sta $3fd
	sty $3fc

	lda #0
	ldx #23
clearbm1:
	sta bitmap,x
	dex
	bne clearbm1
	lda #%11001111
	sta bitmap+0
	lda #1
	sta bitmap+BitMapSize-1
	jmp $1800
run_err:
	rts

;
; open system file & store refnum into
; loader code
;
open_sys:
	lda #stdlevel
	SET_LEVEL
	CALLOS mli_open, loader_open
	CALLOS_BRANCH_NEG @exit
	lda loadref1
	sta loadref2
	sta loadref3
@exit:	rts

loader_open:
	.byte 3
	.addr cmdpath
	.addr filebuff
loadref1:
	.byte 0

;
; save current quit code into %config if it does not
; belong to this incarnation of Davex.
;
write_quit:		;use filebuff2
	bit $c083
	bit $c083
	ldx #0
getq:	lda $d100,x
	sta filebuff3,x
	lda $d200,x
	sta filebuff3+$100,x
	lda $d300,x
	sta filebuff3+$200,x
	dex
	bne getq
	bit $c082
	lda filebuff3
	cmp myqcode
	bne notmine
	lda filebuff3+1
	cmp myqcode+1
	bne notmine
	lda filebuff3+2
	cmp myqcode+2
	bne notmine
	ldy mypath_all
qmine:	lda mypath_all,y
	cmp filebuff3+mypath_all-myqcode,y
	bne notmine
	dey
	bpl qmine
offline:
	rts

notmine:
	lda #>config_pn
	ldy #<config_pn
	jsr build_local
	jsr open_config
	bcs offline
	sta qcref2
	sta qcref3
	jsr posit_qcode
	CALLOS mli_write, wr_quitc
	CALLOS_BRANCH_NEG wrq_err
	lda qcref2
	jmp close

wrq_err:
	jmp ProDOS_er

posit_qcode:
	CALLOS mli_setmark, kill_qc
	CALLOS_BRANCH_NEG wrq_err
	rts

;
; get_quitcode -- load quit code from %config
; if present; return with CLC if successful, SEC
; if not
;
gotqc:	rts

get_quitcode:
	bit $c083
	lda $d100
	ldx $d101
	ldy $d102
	bit $c082
	cmp myqcode
	bne gotqc
	cpx myqcode+1
	bne gotqc
	cpy myqcode+2
	bne gotqc

	lda #>config_pn
	ldy #<config_pn
	jsr build_local
	jsr open_config
	bcs reload_x
	sta qcref2
	sta qcref3
	jsr posit_qcode
	CALLOS mli_read, wr_quitc
	CALLOS_BRANCH_NEG reload_x
	bit $c083
	bit $c083
	ldx #0
reload1:
	lda filebuff3,x
	sta $d100,x
	lda filebuff3+$100,x
	sta $d200,x
	lda filebuff3+$200,x
	sta $d300,x
	dex
	bne reload1
	bit $c082
	CALLOS mli_seteof, kill_qc
reload_x:
	jmp close_config

wr_quitc:
	.byte 4
qcref2:
	.byte 0
	.addr filebuff3
	.addr $300	;length of QUIT code
	.addr 0

kill_qc:
	.byte 2
qcref3:
	.byte 0
	.addr config_len
	.byte 0

;
; install Quit code to return to MYPATH_ALL
;
my_quit:
	bit $c083
	bit $c083
	ldx #0
myquit1:
	lda myqcode,x
	sta $d100,x
	lda myqcode+$100,x
	sta $d200,x
	lda myqcode+$200,x
	sta $d300,x
	dex
	bne myquit1
	bit $c081
	rts

;
; myqcode -- code to return to the shell;
; must run at $1000
;
myqcode:
	cld
	sed
	cld
	lda $c082
	sta $c00c
	jsr $fe89
	jsr $fe93
	start_normal
	jsr f8rom_init
	jsr home
	lda $3f3
	sta $3f4
; init brkv
	lda #$fa
	sta $3f1
	lda #$59
	sta $3f0	;brkv
	lda #0
	SET_LEVEL
	CALLOS mli_close, qt_closeall-myqcode+$1000
	ldx #23
	lda #0
clearbm2:
	sta bitmap,x
	dex
	bne clearbm2
	lda #%11001111
	sta bitmap+0
	lda #1
	sta bitmap+BitMapSize-1
	ldx #79
@copy:	lda mypath_all-myqcode+$1000,x
	sta $280,x
	dex
	bpl @copy
rtn_again:
	CALLOS mli_open, qt_open-myqcode+$1000
	CALLOS_BRANCH_NEG qt_err
	lda qt_ref-myqcode+$1000
	sta qt_ref2-myqcode+$1000
	CALLOS mli_read,qt_read-myqcode+$1000
	CALLOS_BRANCH_NEG qt_err
	CALLOS mli_close, qt_closeall-myqcode+$1000
	jmp $2000

qt_err:	jsr home
	CALLOS mli_close, qt_closeall-myqcode+$1000
	ldx #0
qtprob1:
	lda qtprobmsg-myqcode+$1000,x
	beq qtprobx
	jsr cout
	inx
	bne qtprob1
qtprobx:
	lda #$e
	jsr qtone
	lda #$0c
	jsr qtone
	lda #$e
	jsr qtone
	jsr $fd0c
	jsr home
	jmp rtn_again-myqcode+$1000

qtprobmsg:
	asc "Unable to return to Davex"
	.byte cr,cr
	cstr "Hit a key to try again..."
	.byte 0

qtone	= *-myqcode+$1000
	ldx #200
qton1:	pha
	jsr wait
	lda spkr
	pla
	dex
	bne qton1
	rts

mypath_all:
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

qt_closeall:
	.byte 1
	.byte 0

qt_open:
	.byte 3
	.addr mypath_all-myqcode+$1000
	.addr $800
qt_ref:	.byte 0

qt_read:
	.byte 4
qt_ref2:
	.byte 0
	.addr $2000
	.addr $ffff
	.addr 0

;
; copy_loader -- move real loader down to $1800
;
copy_loader:
	ldx #0
copyl1:	lda loader,x
	sta $1800,x
	dex
	bne copyl1
	rts

;
; LOADER -- code to run at $1800 to load and run a SYS file
;
loader:
	CALLOS mli_read, loader_read-loader+$1800
	CALLOS_BRANCH_NEG loader_err
	CALLOS mli_close, loader_close-loader+$1800
	CALLOS_BRANCH_NEG loader_err
; copy startup argument if present
	ldy $1F80
	beq ld_nostrarg
ld_copyarg:
	lda $1F80,y
	sta $2006,y
	dey
	cpy #<-1
	bne ld_copyarg
ld_nostrarg:
	jsr home
	ldx #$f8
	txs
	jmp $2000
loader_err:
	pha
	jsr home
	ldx #6
lderr1:	lda lderrmsg-loader+$1800,x
	jsr cout
	dex
	bpl lderr1
	pla
	jsr prbyte
	lda $3f3
	sta $3f4
	jsr $fd0c
	CALLOS mli_bye, ldbye-loader+$1800
	jmp ($fffc)
ldbye:	.byte 4,0,0,0,0,0,0

lderrmsg:
	asc "$ rorrE"

loader_read:
	.byte 4
loadref2:
	.byte 0
	.addr $2000
	.addr $ffff
	.addr 0
loader_close:
	.byte 1
loadref3:
	.byte 0
;
; chk_argu -- scan for a string parameter
; (after a SYS file name); give error if there
; is no Startup buffer large enough, else
; return string at $1F80
;
chk_argu:
	lda #>sysparms
	ldy #<sysparms
	sta cmd_ptr+1
	sty cmd_ptr
	jsr parse_parms
	lda #0
	jsr getparm_n
	sta ptr+1
	sty ptr
	ldy #127
copyarg:
	lda (ptr),y
	sta $1F80,y
	dey
	bpl copyarg
	lda $1F80
	bne arg_given
	rts
arg_given:
	lda #>cmdpath
	ldy #<cmdpath
	jsr startup_size
	cmp #0
	beq null_buffer
	tax
	dex
	cpx $1F80
	bcc small_buffer
	rts

small_buffer:
	lda #der_smallsbf
bf_err:	jmp ProDOS_err

null_buffer:
	lda #der_nosbf
	bne bf_err

sysparms:
	cstr "x"		; dummy name
	.addr 0			; dummy entry point
	.byte 0,t_string
	.byte $80+'n',t_nil	; '-n' = don't replace the Quit code before launching SYS
	.byte 0,0

;**************************************************
;
; run_external -- load a BIN or $2E;8001 file,
; parse its parameters, and run it
;
run_external:
	lda #>cmdpath
	ldy #<cmdpath
	jsr startup_size
	lda pagebuff
	cmp #$60
	bne notxtrn
	lda #$ee
	cmp pagebuff+1
	bne notxtrn
	cmp pagebuff+2
	bne notxtrn

	lda pagebuff+x_minver
	cmp #myBakVer
	bcc @davexTooOld
	cmp #myversion
	bne :+
	lda pagebuff+x_minverMinor
	and #$0f
	cmp #AuxVersion
:	beq ver_okay
	bcc ver_okay

@davexTooOld:
	message_cstr_cr "External cmd not compatible with this version of Davex."
	jmp main_err

notxtrn:
	lda #der_notxtn
	bne der4
;
; version ok -- load external cmd
;
xtn_err:
	jmp ProDOS_err
ver_okay:
	lda pagebuff+x_loadadr+1
	ldy pagebuff+x_loadadr
	sta xtn_addr+1
	sty xtn_addr
	cmp #>copybuff
	beq adr_err
	bcs adr_ok
adr_err:
	lda #der_adrlow
	bne der4
adr_ok:

;
; check OK hardware
;
	lda xc_req
	eor #%11111111
	and pagebuff+x_reqbits
	beq reqs_ok
	lda #der_badhware
der4:
xcerr:	jmp ProDOS_err

reqs_ok:
;
; turn off 80col if necessary
;
	bit pagebuff+x_reqbits
	bpl keep80
	lda scr_width
	cmp #80
	ror suspend80	;set if was 80col
	jsr off80
keep80:

	jsr xtn_open
	bcs xtn_err
	jsr xtn_read
	bcs xtn_err
	lda xtn_ref
	jsr close

	clc
	lda xtn_addr
	adc #x_parmtbl
	sta cmd_ptr
	lda xtn_addr+1
	adc #>x_parmtbl
	sta cmd_ptr+1

	lda pagebuff+x_goadr+1
	ldy pagebuff+x_goadr
	sta cmd_addr+1
	sty cmd_addr
; tell mmgr about us
	ldx #mli_write
	lda xtn_addr+1
	jsr mmgr
	bcs xcerr
;;;	clc
	rts

xtn_open:
	CALLOS mli_open, xtnop
	rts

xtn_read:
	lda xtn_ref
	sta xtn_ref2
	CALLOS mli_read, xtnrd
	rts
;
xtnop:	.byte 3
	.addr cmdpath
	.addr filebuff
xtn_ref:
	.byte 0

xtnrd:	.byte 4
xtn_ref2:
	.byte 0
xtn_addr:
	.byte 0,0
	.addr highmem-copybuff	; amount to read
	.addr 0
