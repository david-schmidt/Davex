;*********************************************
;
; External command for Davex
;
; Written by Jeff Ding
; Created : Feb 09, 1989
; Modified: Feb 12, 1989
;
; tail - display end of file
;
;*********************************************

inc2 mac
 inc ]1
 bne inc
 inc ]1+1
inc <<<
mov2 mac
 lda ]1
 sta ]2
 lda ]1+1
 sta ]2+1
 <<<
dec2 mac
 lda ]1
 bne dec21
 dec ]1+1
dec21 dec ]1
 <<<

OrgAdr = $AE00

 org OrgAdr
 put globals
 put apple.globals
 put mli.globals

MyVersion = $10
MinVersion = $12
AuxVersion = $03

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
 dfb 0,t_wildpath   ;input file name
 dfb "l",t_int1     ;number of lines to print
 dfb "d",t_int1     ;line delimiter ascii number
 dfb "w",t_int1     ;wrap margin
 dfb 0,0
descr str "Tail -  Display end of file.  Written by Jeff Ding"
;*********************************************

 dum xczpage ;32 locations
pointer ds 2
buffend ds 2
lines ds 1 ;number of lines to print
width ds 1 ;margin to force increment of lines
bytes ds 2 ;number bytes needed to load
dline ds 1 ;line delimiter
htab ds 1 ;current htab position
 dend

start sty open_in+1 ;save pathname address
 sta open_in+2

 lda #"l" ;check for lines
 jsr xgetparm_ch
 bcs :linedef
 cpy #0
 bne :stoline
:linedef ldy #5 ;default print 5 lines
:stoline sty lines

 lda #"w" ;check for wrap width
 jsr xgetparm_ch
 bcs :wrapdef
 cpy #0
 bne :stowrap
:wrapdef ldy #79 ;default wrap at 79 characters
:stowrap sty width

 lda #"d" ;check for line delimiter
 jsr xgetparm_ch
 bcc :ddelim
 ldy #$0D ;defalt line delimiter is carriage return
:ddelim tya
 and #$7F
 sta dline

 ldx #mli_read ;get buffer info
 jsr xmmgr ;return # of free pages
 sty read_in+4
 sta read_in+5
 ldx #mli_gfinfo
 jsr xmmgr ;return lowest free page
 sty read_in+2
 sta read_in+3

open jsr mli ;open file
 dfb #mli_open
 dw open_in
 bcc :getref
:error jmp xProDOS_err
:getref lda open_in+5
 sta get_eof+1
 sta set_mark+1
 sta read_in+1
 jsr mli ;get end of file position
 dfb #mli_geteof
 dw get_eof
 bcs :error

calcbyte lda #0 ;calc bytes needed to load
 sta bytes
 sta bytes+1
 ldx lines
:loop lda width
 clc
 adc bytes
 sta bytes
 lda #0
 adc bytes+1
 sta bytes+1
 dex
 bne :loop

chkbytes lda bytes+1 ;check # bytes needed vs buffer size
 cmp read_in+5
 bcc :move ;buffer larger than bytes needed
 bne :lenok ;more bytes than buffer
 lda bytes
 cmp read_in+4
 bcs :lenok ;buffer larger than bytes needed
:move mov2 bytes;read_in+4
:lenok

setmark lda get_eof+4 ;check # bytes needed vs file length
 bne :sbc ;plenty of bytes in file
 lda read_in+5
 cmp get_eof+3
 bcc :sbc ;plenty of bytes in file
 bne :load ;more bytes wanted than in file
 lda read_in+4
 cmp get_eof+2
 bcs :load ;file smaller than requested bytes
:sbc lda get_eof+2 ;subtract bytes from end of file
 sec
 sbc read_in+4
 sta set_mark+2
 lda get_eof+3
 sbc read_in+5
 sta set_mark+3
 lda get_eof+4
 sbc #0
 sta set_mark+4
 jsr mli ;set mark in file
 dfb #mli_setmark
 dw set_mark
 bcc :load
:error jmp xProDOS_err
:load jsr mli
 dfb #mli_read
 dw read_in
 bcs :error
 lda read_in+2
 clc
 adc read_in+6
 sta buffend
 sta pointer
 lda read_in+3
 adc read_in+7
 sta buffend+1
 sta pointer+1
 dec2 pointer
 jsr mli ;close file
 dfb #mli_close
 dw close_parms
 bcs :error

 lda #0
 sta htab
adjust ldy #0
 lda (pointer),y
 and #$7F ;blank hi-bit
 cmp dline ;equal to line delimiter?
 beq :decline ;yes - decrement lines left
 inc htab
 lda htab
 cmp width ;at wrap margin - inc lines found
 bne :nxtchar
:decline dec lines ;dec lines
 lda #0
 sta htab
 lda lines
 cmp #$FF
 beq :exit ;beginning of first line found - exit
:nxtchar dec2 pointer
 lda read_in+3
 cmp pointer+1
 bcc adjust
 lda read_in+2
 cmp pointer
 bcc adjust
 bcs :exit2
:exit inc2 pointer
:exit2

 lda #0
 sta htab
display ldy #0
 lda (pointer),y
 ora #$80
 cmp #$A1 ;> " " ok
 bcs :outchar
 cmp #$8D ;carriage return ok
 beq :outcr
 cmp #$89 ;tab character ok
 beq :outchar
 cmp #" "
 bne :outdot ;not a space - output space
 lda width
 sec
 sbc htab
 cmp #10
 bcc :outcr
 lda #" "
 hex 2C
:outdot lda #"."
:outchar jsr cout
 inc htab
 lda htab
 cmp width ;horizontal position at width?
 bne :incptr
:outcr jsr crout ;yes - output carriage return
:xcheck jsr xcheck_wait
 bcs :exit
 lda #0
 sta htab ;set htab to beginning of file
:incptr inc2 pointer
 lda pointer+1
 cmp buffend+1
 bcc display
 lda pointer
 cmp buffend
 bcc display
:exit rts

open_in dfb $3
 ds 2
 dw filebuff
 ds 1
get_eof = *
 dfb $2
 ds 4
set_mark = *
 dfb $2
 ds 4
read_in = *
 dfb $4
 ds 7
close_parms = *
 dfb $1
 ds 1
 err *-1/$B000
