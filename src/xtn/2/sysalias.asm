;*********************************************
;
; External command for Davex
;
; sysalias -- create an alias for a SYS file
;             or S16 file
;
; The alias will be an executable file whose
; only function is to launch the original
; file, after possibly setting the prefix
; and passing startup-file information to
; the target.
;
; This permits SYS and S16 files to appear
; to be in several places at once without
; actually taking up much disk space, and
; it also makes it easy to launch apps with
; convenient prefixes and startup pathnames.
;
;*********************************************
;
; Modified 7-Jul-87 DL ==> v1.1
;   -p allowed; specifies prefix
;
; Modified 12-Dec-87 DL ==> v1.2
;   -s allowed; specifies startup path
;
; Modified 15-Oct-89 DL ==> Merlin source
;
; Modified 16-Oct-89 DL ==> v1.3
;  "Catalyst buffer" changed to "startup buffer"
;  If startup buffer is large, creates a
;    smaller one instead of giving up
;  Creates aliases for S16 files, which
;    can set prefix, send Open message,
;    and Quit to original app
;
;*********************************************
;
; Converted to MPW IIgs 21-Sep-92 DAL
;
;*********************************************
;
; Known bugs:
;   The created Alias file should probably check
;   to make sure the file it's running is STILL
;   a SYS file & STILL has a Startup buffer
;
;*********************************************
	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"


.segment	"CODE_A000"

orgadr	= $A000
; org orgadr

;
; Hard-coded offsets into TheImage
;
S16ImageOffset	= $0167
S16OpenOffset	= $02DB
thePathOffset	= $00E5
thePrefixOffset	= $0126
S16QuitToOffset	= $0251
S16PrefixOffset	= $0292

myVersion	= $13
minVersion	= $10
;*********************************************
	rts
	.byte $ee,$ee
	.byte myVersion,minVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr orgadr
	.addr start
	.byte 0,0,0,0
; parameters here
	.byte 0,t_path
	.byte 0,t_path
	.byte $80+'p',t_path
	.byte $80+'s',t_path
	.byte 0,0
descr:	pstr "create alias for SYS or S16 file"
	
;*********************************************
; dum xczpage
path1	= xczpage	;ds 2
path2	= path1+2	;ds 2
stpath	= path2+2	;ds 2
pfxptr	= stpath+2	;ds 2
s16_flag	= pfxptr+2	;ds 1
; dend
;*********************************************
myerror:	jmp xProDOS_err
start:
;
; get info on 1st file to make sure it
; exists and is SYS or S16
;
	lda #0
	jsr xgetparm_n
	sta path1+1
	sty path1
	sta info_path+1
	sty info_path
	lda #10
	sta info_parms
	jsr mli
	.byte mli_gfinfo
	.addr info_parms
	bcs myerror
;
	lsr s16_flag
	lda info_ftype
	cmp #$FF
	beq is_sys
	cmp #$B3
	bne not_s16
	ror s16_flag
	bmi is_sys	;always
;
not_s16:	jsr xmess
	.byte cr
	asc "*** not a SYS or S16 file"
	.byte cr,0
	jmp xerr
;
; create a SYS sysalias file
;
is_sys:
	lda #1
	jsr xgetparm_n
	sta path2+1
	sty path2
	sta cr_path+1
	sty cr_path
	jsr mli
	.byte mli_create
	.addr create_parms
	bcc createdok
	jmp xProDOS_err
createdok:
;
	bit s16_flag
	bmi skip_sysbuff
	lda #$ef
	sta TheImage+4
	jsr startup_sz
	cmp #69
	bcc sysb_ok
;
	jsr xmess
	asc "(note: creating smaller startup buffer)"
	.byte cr,0
	lda #68
;
sysb_ok:
	sta TheImage+5
	cmp #0
	beq no_sysbuff
	dec TheImage+4		;make $EE!
no_sysbuff:
skip_sysbuff:
;
; If -s given, copy path into startup buffer
;
	lda #'s'+$80
	jsr xgetparm_ch
	bcs no_stpath
	sta stpath+1
	sty stpath
; copy startup path into one of the images
	bit s16_flag
	bmi stuff_s16st
; stuff SYS startup buffer
	ldy #0
	lda (stpath),y
	cmp TheImage+5
	bcs StPathBig
	tay
copystp:	lda (stpath),y
	sta TheImage+6,y
	dey
	bpl copystp
	jmp no_stpath
StPathBig:	jsr xmess
	.byte cr
	asc "*** startup path too big for buffer"
	.byte cr,0
	jmp xerr
stuff_s16st	= *
	ldy #0
	lda (stpath),y
	cmp #64
	bcs StPathBig
	tay
stuff16a:	lda (stpath),y
	sta TheImage+S16OpenOffset,y
	dey
	bpl stuff16a
no_stpath	= *
;
; copy name of 1st file into thePath
; in code image
;
	ldy #0
	lda (path1),y
	tay
copyname:	lda (path1),y
	sta TheImage+thePathOffset,y
	sta TheImage+S16QuitToOffset,y
	dey
	cpy #<-1
	bne copyname
;
; copy prefix into buffer if -p given
;
	lda #'p'+$80
	jsr xgetparm_ch
	bcs nopfx
	sta pfxptr+1
	sty pfxptr
	ldy #0
	lda (pfxptr),y
	cmp #64
	bcc pfxShort
	jsr xmess
	.byte cr
	asc "*** prefix too long"
	.byte cr,0
	jmp xerr
pfxShort	= *
	tay
copyPfx:	lda (pfxptr),y
	sta TheImage+thePrefixOffset,y
	sta TheImage+S16PrefixOffset,y
	dey
	cpy #<-1
	bne copyPfx
nopfx	= *
;
; open 2nd file & write it
;
	lda path2+1
	ldy path2
	jsr open
	sta write_ref
	sta write_ref2
	bit s16_flag
	bmi write16
	jsr mli
	.byte mli_write
	.addr write_parms
	bcc writ
err0:	jmp xProDOS_err
write16:	jsr mli
	.byte mli_write
	.addr write_s16
	bcs err0

writ:	lda write_ref
	jsr close
	lda path2+1
	ldy path2
	sta info_path+1
	sty info_path
	lda #7
	sta info_parms
	jsr mli
	.byte mli_sfinfo
	.addr info_parms
	bcc set
	jmp xProDOS_err
set	= *
	rts
;
write_parms:	.byte 4
write_ref:	.res 1
	.addr TheImage
	.addr image_end-image
	.addr 0

write_s16:	.byte 4
write_ref2:	.res 1
	.addr TheImage+S16ImageOffset
	.addr s16image_end-s16image
	.addr 0
;***********************************************
create_parms:	.byte 7
cr_path:	.res 2
	.byte %11000011	;unlocked
	.byte $00	;type $00 initially
	.addr 0	;auxtype
	.byte 1	;sttype
	.addr 0,0	;date/time
;
info_parms:	.res 1
info_path:	.res 2
	.res 1	;access
info_ftype:	.res 1
	.res 2	;aux
	.res 1	;sttype
	.res 2	;blocks
	.addr 0,0,0,0	;date/time
;***********************************************
open:	sta open_path+1
	sty open_path
	jsr mli
	.byte mli_open
	.addr open_parms
	bcc opened
proerr:	jmp xProDOS_err
opened:	lda open_ref
	rts
;
open_parms:	.byte 3
open_path:	.res 2
	.addr filebuff
open_ref:	.res 1
;
; close (a)
;
close:	sta close_ref
	jsr mli
	.byte mli_close
	.addr close_parms
	rts
close_parms:	.byte 1
close_ref:	.res 1
;
; get size of SYS startup buffer
;
startup_sz	= *
	lda path1+1
	ldy path1
	jsr open
	sta read_ref
	jsr mli
	.byte mli_read
	.addr read_parms
	bcc read_ok
	jmp xProDOS_err
read_ok:	lda read_ref
	jsr close
	lda pagebuff
	cmp #$4c
	bne sysb_0
	lda #$ee
	cmp pagebuff+3
	bne sysb_0
	cmp pagebuff+4
	bne sysb_0
	lda pagebuff+5
	rts
sysb_0:	lda #0
	rts
;
read_parms:	.byte 4
read_ref:	.byte 1
	.addr pagebuff
	.addr 10
	.addr 0
;***********************************************
;***********************************************
;
; IMAGE -- this code is written to the alias
; file, with or without a valid startup buffer
; and with the name of the original file
; inserted at the end.
;
; The code will copy itself to $1000 and execute
; there.
;
;***********************************************
TheImage:	; proc export

	.org $1000
image:	; proc export, temporg $1000
;diff1	= $1000-image
;diff2	= $2000-image

	jmp image2+$1000    ;+diff2
	.byte $ee,$00	;maybe made into $ee
	.byte 0	;cb size
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
	.byte 0,0,0,0,0,0,0,0,0,0 ;10 zeroes
image2	= *
	ldx #0
copyme:	lda $2000,x
	sta $1000,x
	lda $2100,x
	sta $1100,x
	dex
	bne copyme
	jmp continue ; +diff1
i_error:	pha
	jsr $fc58
	pla
	jsr $fdda
	jsr $fbdd
	jsr $fbdd
	jsr $fd0c
	jsr mli
	.byte mli_bye
	.addr bye_parms  ; +diff1
;;;	brk
	.byte 0
bye_parms:	.byte 4,0,0,0,0,0,0
continue	= *
	lda thePrefix  ; +diff1
	beq noSetP
	jsr mli
	.byte mli_setpfx
	.addr i_setp  ; +diff1
	bcs i_error
noSetP	= *
;
	jsr mli
	.byte mli_open
	.addr i_openp  ; +diff1
	bcs i_error
;
	lda i_ref  ; +diff1
	sta i_ref2  ; +diff1
	sta i_ref3  ; +diff1
;
	jsr mli
	.byte mli_read
	.addr i_readp  ; +diff1
	bcs i_error
;
	jsr mli
	.byte mli_close
	.addr i_closep  ; +diff1
;
	lda $1005	;startup buff sz
	beq i_nocopy
	lda $1006
	beq i_nocopy
	tay
i_copycb:	lda $1006,y
	sta $2006,y
	dey
	cpy #<-1
	bne i_copycb
i_nocopy	= *
;
	ldy thePath    ; +diff1
cppath280:	lda thePath,y  ; +diff1
	sta $280,y
	dey
	cpy #<-1
	bne cppath280
	jmp $2000
;
i_openp:	.byte 3
	.addr thePath  ; +diff1
	.addr $C00
i_ref:	.byte 0
;
i_readp:	.byte 4
i_ref2:	.byte 0
	.addr $2000
	.addr $ffff
	.addr 0
;
i_closep:	.byte 1
i_ref3:	.byte 0
;
i_setp:	.byte 1
	.addr thePrefix  ; +diff1
;
thePath:	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0
thePrefix:
	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0
image_end:

;********************************************
;	export s16image
s16image:
	.byte $ED,$01,$00,$00,$00,$00,$00,$00,$70,$01,$00,$00,$FF,$0A,$04,$02
	.byte $00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$01,$00,$00,$00,$00,$00,$2C,$00,$40,$00,$20,$20,$20,$20
	.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.byte $F2,$70,$01,$00,$00,$4B,$AB,$AD,$E6,$00,$F0,$0A,$22,$A8,$00,$E1
	.byte $09,$00,$98,$00,$00,$00,$AD,$2F,$01,$29,$FF,$00,$F0,$6B,$48,$48
	.byte $F4,$00,$00,$18,$69,$0A,$00,$48,$8D,$9E,$00,$48,$A2,$02,$02,$22
	.byte $00,$00,$E1,$F4,$00,$C0,$48,$48,$A2,$02,$09,$22,$00,$00,$E1,$68
	.byte $8D,$A0,$00,$68,$8D,$A2,$00,$B0,$40,$F4,$00,$00,$F4,$27,$01,$AD
	.byte $A2,$00,$48,$AD,$A0,$00,$48,$F4,$00,$00,$AD,$9E,$00,$48,$A2,$02
	.byte $28,$22,$00,$00,$E1,$F4,$01,$00,$F4,$01,$00,$AD,$A2,$00,$48,$AD
	.byte $A0,$00,$48,$A2,$01,$15,$22,$00,$00,$E1,$AD,$A2,$00,$48,$AD,$A0
	.byte $00,$48,$A2,$02,$10,$22,$00,$00,$E1,$22,$A8,$00,$E1,$29,$00,$90
	.byte $00,$00,$00,$00,$00,$A5,$00,$00,$00,$00,$00,$00,$00,$00,$00,$E6
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $51
;	export S16QuitTo
S16QuitTo:
	.byte $00,$00,$33,$34,$35,$36
	.byte $37,$38,$31,$32,$33,$34,$35,$36,$37,$38,$31,$32,$33,$34,$35,$36
	.byte $37,$38,$31,$32,$33,$34,$35,$36,$37,$38,$31,$32,$33,$34,$35,$36
	.byte $37,$38,$31,$32,$33,$34,$35,$36,$37,$38,$31,$32,$33,$34,$35,$36
	.byte $37,$38,$31,$32,$33,$34,$35,$36,$37,$38
	.byte $50
;	Export S16Prefix
S16Prefix:
	.byte $00,$00,$33,$34,$35
	.byte $36,$37,$38,$31,$32,$33,$34,$35,$36,$37,$38,$31,$32,$33,$34,$35
	.byte $36,$37,$38,$31,$32,$33,$34,$35,$36,$37,$38,$31,$32,$33,$34,$35
	.byte $36,$37,$38,$31,$32,$33,$34,$35,$36,$37,$38,$31,$32,$33,$34,$35
	.byte $36,$37,$38,$31,$32,$33,$34,$35,$36,$37,$38
	.byte $4F
	.byte $00,$00,$00,$00,$01,$00,$00,$00
;	export S16Open
S16Open:	.byte $00,$00,$33,$34,$35,$36,$37,$38,$31,$32,$33,$34
	.byte $35,$36,$37,$38,$31,$32,$33,$34,$35,$36,$37,$38,$31,$32,$33,$34
	.byte $35,$36,$37,$38,$31,$32,$33,$34,$35,$36,$37,$38,$31,$32,$33,$34
	.byte $35,$36,$37,$38,$31,$32,$33,$34,$35,$36,$37,$38,$31,$32,$33,$34
	.byte $35,$36,$37,$38,$00,$F5,$04,$00,$0D,$00,$98,$00,$F5,$02,$F0,$45
	.byte $00,$27,$01,$F5,$04,$00,$8A,$00,$90,$00,$F5,$04,$00,$90,$00,$A5
	.byte $00,$F5,$04,$00,$9A,$00,$E6,$00,$F7,$0F,$00,$00,$00,$00,$0C,$03
	.byte $12,$24,$3C,$40,$48,$4B,$4F,$56,$67,$6B,$76,$7A,$00
;	export s16image_end
s16image_end:

;****************************************************
;****************************************************
;           keep s16image
;****************************************************
;*
;* S16 launcher image for Davex 8 sysalias command
;*
;* Dave Lyons, 15-Oct-89
;*
;* Optionally does a SET_PREFIX(0,...)
;* Optionally does a MessageCenter(Add,1,...)
;* Does a QUIT
;*
;****************************************************
;Kool       start
;
;tool       = $e10000
;P16        = $e100a8
;
;           phk
;           plb
;
;* set prefix 0
;           lda PrefixPath
;           beq noSetPfx
;           jsl p16
;           dc  i'$0009'
;           dc  i4'PfxParms'
;noSetPfx   anop
;
;* add message 1 to MessageCenter
;           lda OpenPath
;           and #$00ff
;           beq noMessage
;
;           pha
;           pha           ;space for result
;           pea 0
;           clc
;           adc #10
;           pha           ;size = pathlen + 10
;           sta theLength
;           pha           ;space for user id
;           ldx #$0202    ;MMStartUp()
;           jsl tool
;           pea $C000     ;locked+fixed
;           pha
;           pha
;           ldx #$0902    ;NewHandle
;           jsl tool
;           pla
;           sta theHand
;           pla
;           sta theHand+2
;           bcs noMessage
;
;           pea OpenBlock|-16
;           pea OpenBlock
;           lda theHand+2
;           pha
;           lda theHand
;           pha
;           pea 0
;           lda theLength
;           pha
;           ldx #$2802    ;PtrToHand
;           jsl tool
;
;           pea 1         ;add message
;           pea 1         ;type 1
;           lda theHand+2
;           pha
;           lda theHand
;           pha
;           ldx #$1501    ;MessageCenter   act type msg
;           jsl tool
;
;           lda theHand+2
;           pha
;           lda theHand
;           pha
;           ldx #$1002    ;DisposeHandle
;           jsl tool
;
;noMessage  anop
;
;* quit to the destination S16 (or EXE?) file
;           jsl p16
;           dc  i'$0029'
;           dc  i4'QuitParms'
;           brk 0
;
;QuitParms  dc i4'QuitPath'
;           dc i'0,0'
;
;PfxParms   dc i'0'
;           dc i4'PrefixPath'
;
;theLength  dc i'0'
;theHand    dc i4'0'
;
;           dc c'Q'
;QuitPath   dc i1'0,0'
;           dc c'345678123456781234567812345678'
;           dc c'12345678123456781234567812345678'
;
;           dc c'P'
;PrefixPath dc i1'0,0'
;           dc c'345678123456781234567812345678'
;           dc c'12345678123456781234567812345678'
;
;           dc c'O'
;OpenBlock  dc i4'0'
;           dc i'1'   ;msg type 1
;           dc i'0'   ;Open (not Print)
;OpenPath   dc i1'0,0'
;           dc c'345678123456781234567812345678'
;           dc c'12345678123456781234567812345678'
;           dc i1'0'
;
;           end
;***************************************************
