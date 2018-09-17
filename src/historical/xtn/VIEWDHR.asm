;*********************************************
;
; External command for Davex
;
; Written by Jeff Ding
; Modified: June 15, 1988
;
; viewdhr -- view a double hi-res picture file
;
;*********************************************
OrgAdr = $AC00
 org OrgAdr
movd mac
 lda ]1
 sta ]2
 lda ]1+1
 sta ]2+1
 <<<

 put globals
 put apple.globals
 put mli.globals

MyVersion = $11
MinVersion = $12
AuxVersion = $3

;*********************************************
 rts
 dfb $ee,$ee
 dfb MyVersion,MinVersion
 dfb %01100000
 dw descr
 dw OrgAdr
 dw start
 dfb AuxVersion
 dfb 0,0,0
; parameters here
 dfb 0,t_wildpath
 dfb "f",t_nil
 dfb "r",t_nil
 dfb 0,0
descr str "View a double hi-res picture.  Written by Jeff Ding"
;*********************************************

 dum xczpage
pathptr ds 2
hiresptr ds 2
memptr ds 2
mempage ds 1
sto80tmp ds 1 ;temp storage for 80store switch
ioutmp ds 1 ;temp storage for ioudis switch
dhiretmp ds 1 ;temp storage for dhires switch
hirestmp ds 1 ;temp storage for hires switch
mixedtmp ds 1 ;temp storage for mixed switch
page2tmp ds 1 ;temp storage for page2 switch
texttmp ds 1 ;temp storage for text switch
 dend

start = *
 sta pathptr+1 ;store pathptr to pathname
 sty pathptr
 ldx #mli_open
 lda #$20 ;32 pages for buffer
 jsr xmmgr
 bcc chkname
 jmp nomem
chkname sta mempage
 ldy #0 ;check for name parameter
 lda (pathptr),y
 bne chkram
 jmp nofile
chkram lda #"f" ;check for f parameter
 jsr xgetparm_ch
 bcc getinfo ;check for ram driver
 jsr mli
 dfb mli_online
 dw online_parms
 bcc :chklen
 cmp #$28 ;no device connected error
 beq getinfo
 jmp generr
:chklen lda filename ;if 0 then ram driver gone
 beq getinfo
 jmp ramerr
getinfo movd pathptr;info_parms+1  ;get file info
 jsr mli
 dfb mli_gfinfo
 dw info_parms
 bcc :chkfile
 jmp generr
:chkfile lda ftype ;check for picture
 cmp #tBIN
 beq :chkaux
 cmp #$08 ;FOT file type
 bne :picerr
:chkaux lda auxtype
 bne :picerr
 lda auxtype+1
 cmp #$20 ;auxtype set at $2000
 beq open
:picerr jmp notpic
open movd pathptr;open_parms+1 ;open file
 lda #<filebuff
 sta open_parms+3
 lda #>filebuff
 sta open_parms+4
 jsr mli
 dfb mli_open
 dw open_parms
 bcc chkrev1
 jmp generr
chkrev1 lda #"r" ;move file pointer if -r
 jsr xgetparm_ch
 bcs readaux
 lda refnum
 sta setmark_parms+1
 lda #0
 sta setmark_parms+2
 sta setmark_parms+4
 lda #$20
 sta setmark_parms+3
 jsr mli
 dfb mli_setmark
 dw setmark_parms
 bcc readaux
 jmp generr
readaux lda refnum
 sta read_parms+1
 lda #0
 sta read_parms+2
 lda mempage
 sta read_parms+3
 lda #$0
 sta read_parms+4
 lda #$20
 sta read_parms+5
 jsr mli ;load aux portion of picture
 dfb mli_read
 dw read_parms
 bcc :swap
 jmp generr
:swap lda mempage ;move memory to aux page
 sta memptr+1
 lda #$0
 sta memptr
 sta hiresptr
 lda #$20
 sta hiresptr+1
 lda $C018 ;read 80store switch
 sta sto80tmp
 sta $C000 ;turn off 80store
 sta $C002 ;read from main 48k
 sta $C005 ;write to aux memory 48k
 ldy #0
 ldx #$20
:swloop lda (memptr),y
 sta (hiresptr),y
 lda #0
 sta (memptr),y
 iny
 bne :swloop
 inc memptr+1
 inc hiresptr+1
 dex
 bne :swloop
 sta $C004 ;write to main 48k
 lda sto80tmp
 bpl chkrev2 ;if plus 80store off
 sta $C001 ;turn on 80store
chkrev2 lda #"r" ;move pointer again if -r
 jsr xgetparm_ch
 bcs readmain
 lda #0
 sta setmark_parms+3
 jsr mli
 dfb mli_setmark
 dw setmark_parms
 bcc readmain
 jmp generr
readmain jsr mli ;load main portion of picture
 dfb mli_read
 dw read_parms
 bcc close
 jmp generr
close lda refnum
 sta close_parms+1
 jsr mli ;close file
 dfb mli_close
 dw close_parms
 inc $3F4 ;inc power up byte to reboot in case of reset
 lda #0 ;no code to handle it.
 sta memptr
 sta hiresptr
 lda mempage
 sta memptr+1
 lda #$20
 sta hiresptr+1
 ldx #$20 ;swap hires page and free mem
 ldy #$0
:swloop lda (hiresptr),y
 pha
 lda (memptr),y
 sta (hiresptr),y
 pla
 sta (memptr),y
 iny
 bne :swloop
 inc memptr+1
 inc hiresptr+1
 dex
 bne :swloop
 lda $C07E ;read ioudis
 sta ioutmp
 sta $C07E ;turn iou on (Enable access to Dhires)
 lda $C07F ;read dhires switch
 sta dhiretmp
 sta $C05E ;turn on double hires
 lda $C01D ;read hires switch
 sta hirestmp
 lda $C057 ;turn on high-resolution
 lda $C01B ;read mixed switch
 sta mixedtmp
 lda $C052 ;turn off mixed mode
 lda $C01C ;read page2 switch
 sta page2tmp
 lda $C054 ;select page 1
 lda $C01A ;read text switch
 sta texttmp
 lda $C050 ;turn off text mode
:kbloop lda keyboard
 bpl :kbloop
 lda texttmp
 bpl :notext ;if plus then text off
 lda $C051 ;turn on text
:notext lda page2tmp
 bpl :nopage2 ;if plus then page2 off
 lda $C055 ;turn on page 2
:nopage2 lda mixedtmp
 bpl :nomixed ;if plus then mixed off
 lda $C053 ;turn on mixed mode
:nomixed lda hirestmp
 bmi :hireson ;if minus then hires on
 lda $C056 ;turn off hi-resolution
:hireson lda dhiretmp
 bmi :dhireon ;if minus then dhires on
 lda $C05F ;turn off double-high-resolution
:dhireon lda ioutmp
 bpl :iouon ;if plus then iou on
 lda $C07F ;turn iou off (disable access to Dhires)
:iouon lda #0
 sta memptr
 sta hiresptr
 lda mempage
 sta memptr+1
 lda #$20
 sta hiresptr+1
 ldx #$20 ;put back davex code in hires
 ldy #$0
:loop2 lda (memptr),y
 sta (hiresptr),y
 iny
 bne :loop2
 inc memptr+1
 inc hiresptr+1
 dex
 bne :loop2
 dec $3F4 ;fix power up byte
 ldx #mli_close
 jsr xmmgr
 lda keyboard
 cmp #space
 beq :clearkb
 cmp #esc
 beq :clearkb
 jsr xcheck_wait
:clearkb lda kbdstrb
 rts

online_parms = *
 db 2
 db $B0
 dw filename
filename ds 16
info_parms = *
 db $A
 ds 3
ftype ds 1
auxtype ds 2
 ds 11
open_parms = *
 db $3
 ds 4
refnum ds 1
read_parms = *
 db 4
 ds 7
setmark_parms = *
 db 2
 ds 4
close_parms = *
 db 1
 ds 1

generr jmp xProDOS_err
nomem jsr crout
 jsr xmess
 asc "Error:  No memory available",8D,00
 jmp xerr
nofile jsr crout
 jsr xmess
 asc "Error:  Filename not specified",8D,00
 jmp xerr
ramerr jsr crout
 jsr xmess
 asc "Error:  Auxiliary memory in use",8D,00
 jmp xerr
notpic jsr crout
 jsr xmess
 asc "Error:  Not a picture file",8D,00
 jmp xerr
 err *-1/$B000
