;*********************************************
;
; External command for Davex
;
; Written by Jeff Ding
; Modified: June 19, 1988
;
; viewhr -- view a hi-res picture file
;
;*********************************************

OrgAdr = $AE00
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
 dfb %00000000 ;hardware req
 dw descr
 dw OrgAdr
 dw start
 dfb AuxVersion
 dfb 0,0,0
; parameters here
 dfb 0,t_wildpath
 dfb 0,0
descr str "View a hi-res picture.  Written by Jeff Ding"
;*********************************************

 dum xczpage ;32 locations
pointer ds 2
hiresptr ds 2
membuff ds 1
 dend

start = *
 sta pointer+1 ;store pointer to pathname
 sty pointer
 ldx #mli_open
 lda #$20 ;# pages for hi-res picture
 jsr xmmgr
 bcc :getfile
 jmp nomem
:getfile sta membuff
 ldy #0
 lda (pointer),y
 bne :getinfo
 jmp nofile
:getinfo movd pointer;info_parms+1  ;get file info
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
 cmp #$20
 beq :open
 cmp #$40
 beq :open
:picerr jmp notpic
:open movd pointer;open_parms+1 ;open file
 lda #<filebuff
 sta open_parms+3
 lda #>filebuff
 sta open_parms+4
 jsr mli
 dfb mli_open
 dw open_parms
 bcc :gotfile
 jmp generr
:gotfile lda refnum
 sta read_parms+1
 lda #0
 sta read_parms+2
 lda membuff
 sta read_parms+3
 lda #$0
 sta read_parms+4
 lda #$20
 sta read_parms+5
 jsr mli ;get picture
 dfb mli_read
 dw read_parms
 bcc :swap
 jmp generr
:swap lda refnum
 sta close_parms+1
 jsr mli ;close file
 dfb mli_close
 dw close_parms
 inc $3F4 ;inc power up byte in case of reset
 lda #0 ;no davex code to handle it!
 sta pointer
 sta hiresptr
 lda membuff
 sta pointer+1
 lda #$20
 sta hiresptr+1
 ldx #$20 ;swap hires page and free mem
 ldy #$0
:loop lda (hiresptr),y
 pha
 lda (pointer),y
 sta (hiresptr),y
 pla
 sta (pointer),y
 iny
 bne :loop
 inc pointer+1
 inc hiresptr+1
 dex
 bne :loop
 sta $C07E ;turn iou on (Enable access to Dhires)
 sta $C05F ;turn off double hires
 sta $C07F ;turn iou off (Disenable access to Dhires)
 lda $C057 ;hires
 lda $C054 ;page1
 lda $C052 ;no mixed
 lda $C050 ;graphics
:kbloop lda keyboard
 bpl :kbloop
 lda $C051 ;text
 lda $C056 ;lores -- fix Mousetalk bug
 lda #0
 sta pointer
 sta hiresptr
 lda membuff
 sta pointer+1
 lda #$20
 sta hiresptr+1
 ldx #$20 ;put back davex code in hires
 ldy #$0
:loop2 lda (pointer),y
 sta (hiresptr),y
 iny
 bne :loop2
 inc pointer+1
 inc hiresptr+1
 dex
 bne :loop2
 dec $3F4 ;fix powerup byte.  Davex able to handle reset
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
close_parms = *
 db 1
 ds 1

generr jmp xProDOS_err
nomem jsr crout
 jsr xmess
 asc "Error:  Memory not available",8D,00
 jmp xerr
nofile jsr crout
 jsr xmess
 asc "Error:  Filename not specified",8D,00
 jmp xerr
notpic jsr crout
 jsr xmess
 asc "Error:  Not a picture file",8D,00
 jmp xerr
 err *-1/$B000
 
