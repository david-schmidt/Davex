;*********************************************
;
; External command for Davex
;
; Written by Jeff Ding
; Modified: June 28, 1988
;
; ram3 -- disable/enable slot 3 drive 2 volume
;
;*********************************************

	.include "../../Common/2/Globals2.asm"
	.include "../../Common/2/Apple.Globals2.asm"
	.include "../../Common/2/Mli.globals2.asm"
	.include "../../Common/Macros.asm"

.segment	"CODE_AC00"
OrgAdr = $AC00
emptydev = $BF10
dev32 = $BF26

.org OrgAdr

MyVersion = $11
MinVersion = $12
AuxVersion = $03

;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %000000000
	.addr descr
	.addr OrgAdr
	.addr start
	.byte AuxVersion
	.byte 0,0,0
	; parameters here
	.byte "r",t_nil  ;remove ram3 drive
	.byte "f",t_nil ;force removal
	.byte "a",t_nil  ;add ram3 drive
	.byte "v",t_int2 ;vector pointer to ram driver
	.byte "i",t_int1 ;identification of ram driver
	.byte 0,0
descr:	pstr "Disable/enable /ram drive.  Written by Jeff Ding"
;*********************************************

start:
	jsr xgetnump
	beq status
	lda #'r'
	jsr xgetparm_ch
	bcc remove
	lda #'a'
	jsr xgetparm_ch
	bcc add
	lda #'f'
	jsr xgetparm_ch
	bcc ferr
	jmp viparm_err
ferr:	jmp fparm_err
status:	jmp status
remove:	jmp remove
add:	jmp add

remove:
	jsr online    ;make sure volume there
	bcc xpush
	jmp nodev_err
xpush:	jsr xpush_level   ;check for entries in volume
	lda #>pathname
	ldy #<pathname
	jsr xdir_setup
	jsr xread1dir
	php
	jsr xdir_finish
	plp
	bcs remove
	lda #'f'
	jsr xgetparm_ch
	bcc remove
	lda #1
	jsr xredirect
	jsr prntpath
	jsr xmess
	asc_hi " not empty, okay to destroy"
	.byte $00
	lda #'n'
	jsr xyesno2
	php
	lda #$FF
	jsr xredirect
	plp
	bne remove
	jmp remove_err
remove:	jsr prntpath
	jsr xmess
	asc_hi " removed"
	.byte $8D, $00
	lda dev32
	cmp ramdev
	bne prntdev
	lda dev32+1
	cmp ramdev+1
	beq rmdev
prntdev:
	jsr xmess
	asc_hi "device vector: "
	.byte $00
	ldy ramdev
	lda ramdev+1
	jsr xprdec_2
	jsr crout
rmdev:	lda emptydev
	sta dev32
	lda emptydev+1
	sta dev32+1
	ldx devcnt ;get device count
devloop:
	lda devlst,x ;check for device in list
	sta ramid
	and #$F0
	cmp #$B0 ;slot 3 drive 2
	beq gotdev
	dex
	bpl devloop
	bmi exit
gotdev:	cpx devcnt ;delete device from list
	beq decdev
	lda devlst+1,x
	sta devlst,x
	inx
	bne gotdev
decdev:	lda #0 ;reduce device count by one
	sta devlst,x
	dec devcnt
	lda :ramid
	and #$0F
	cmp ramid
	beq exit
	pha
	jsr xmess
	asc_hi "device id: "
	.byte $00
	pla
	tay
	lda #0
	jsr xprdec_2
	jsr crout
exit:	jmp online
ramid:	.res 1

add:
	jsr xgetnump
	cmp #1
	bne chkvec
 lda machid ;check for 128k
 and #%00110000
 cmp #%00110000
 beq :chkdev
 jmp driver_err
:chkvec lda #"v"
 jsr xgetparm_ch
 bcs :chkid
 stx ramdev+1 ;store new driver pointer
 sty ramdev
:chkid lda #"i"
 jsr xgetparm_ch
 bcs :chkdev
 tya
 and #$0F
 sta ramid ;store new identification
:chkdev ldx devcnt ;check for driver
:chkloop lda devlst,x
 and #$F0
 cmp #$B0
 bne :next
 jmp devthere_err
:next dex
 bpl :chkloop ;install driver
 inc devcnt
 ldx devcnt
:insloop lda devlst-1,x
 sta devlst,x
 dex
 bne :insloop
 lda #$B0 ;slot 3 drive 2 ram driver
 ora ramid
 sta devlst
 lda ramdev
 sta dev32
 lda ramdev+1
 sta dev32+1
 lda #3 ;format command
 sta $42
 lda #$B0 ;slot 3 drive 2
 sta $43
 sta $C080 ;select l.c.
 jsr jmpdev ;format the volume
 sta $C081 ;select motherboard roms
 bcc :exit
 jmp general_err
:exit jsr online
 jsr prntpath
 jsr xmess
 asc_hi " installed",8D,00
 rts
ramdev	.addr $FF00
ramid db $0F
jmpdev jmp (dev32)

status:
 jsr online
 bcc :jsr
 jmp nodev_err
:jsr jsr prntpath
 jsr xmess
 asc_hi " present in slot 3 drive 2",8D,00
 rts

online:
	jsr mli
	.byte mli_online
	.addr online_parms
 bcc :noerr
 cmp #$28
 beq :nodev
 jmp general_err
:noerr lda filename
 and #%00001111
 sta filename
 bne :adslash
 lda filename+1
 cmp #$28
 beq :nodev
 jmp general_err
:nodev sec
 rts
:adslash lda #"/" ;add slash on front
 sta pathname+1
 ldx filename
 stx pathname
 inc pathname
:loop lda filename+1,x
 sta pathname+2,x
 dex
 bpl :loop
 clc
 rts

prntpath:
 lda #>pathname
 ldy #<pathname
 jmp xprint_path

online_parms:
 db 2
 db %10110000
	.addr filename
filename ds 16
pathname ds 16

general_err:
	jmp xProDOS_err
viparm_err:
	jsr crout
	jsr xmess
	asc_hi "Error:  -v and -i option not valid without -a"
	.byte $8D, $00
	jmp xerr
fparm_err:
	jsr crout
	jsr xmess
	asc_hi "Error:  -f option not valid without -r,"
	.byte $8D, $00
	jmp xerr
remove_err:
	jsr crout
	jsr xmess
	asc_hi "Error:  device not removed"
	.byte $8D, $00
	jmp xerr
devthere_err:
	jsr crout
	jsr xmess
	asc_hi "Error:  device already installed"
	.byte $8D, $00
	jmp xerr
nodev_err:
	jsr xmess
	asc_hi "no device connected in slot 3 drive 2"
	.byte $8D, $00
	rts
driver_err:
	jsr crout
	jsr xmess
	asc_hi "Error:  standard ProDOS driver not present"
	.byte $8D, $00
	jmp xerr
	err *-1/$B000
