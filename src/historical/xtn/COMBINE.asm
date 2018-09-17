;*********************************************
;
; External command for Davex
;
; Written by Jeff Ding
; Created : Aug  03, 1988
; Modified: Aug  03, 1988
;
; combine -- combine files together
;
;*********************************************

OrgAdr = $AD00

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
 dfb 0,t_wildpath   ;input file names
 dfb 0,t_wildpath
 dfb 0,t_path
 dfb 0,t_path
 dfb 0,t_path
 dfb "o",t_path     ;output file name
 dfb "w",t_int1     ;wrap margin
 dfb 0,0
descr str "Combine.  Written by Jeff Ding"
;*********************************************

 dum xczpage ;32 locations
pointer ds 2
buffstart ds 2 ;buffer starting address
bufflast ds 2 ;last address of buffer
outfile ds 2 ;pointer to output filename
number ds 1 ;current input file
flag ds 1 ;%1000_0000 - outfile given
   ;%0100_0000 - outfile open
htab ds 1
width ds 1
 dend

start nop  ;disable wildcard printing
 lda #0 ;initalize variables
 sta number
 sta width
 sta htab
 sta flag

getbuff ldx #mli_read
 jsr xmmgr ;return # of free pages
 sty read_in+4
 sta read_in+5
 ldx #mli_gfinfo
 jsr xmmgr ;return lowest free page
 sty buffstart
 sty read_in+2
 sta buffstart+1
 sta read_in+3

getwrap lda #"w" ;check for wrap margin
 jsr xgetparm_ch
 bcc :stowrap
 ldy #0
:stowrap sty width

chkout lda #"o" ;check for output filename
 jsr xgetparm_ch
 bcs chkin
 sty outfile
 sty outfile_info+1
 sty create_out+1
 sty open_out+1
 sta outfile+1
 sta outfile_info+2
 sta create_out+2
 sta open_out+2
 ldy #0
 lda (outfile),y
 beq chkin
 lda flag
 ora #%10000000
 sta flag

chkin lda number ;get input file
 jsr xgetparm_n
 sty pointer
 sty infile_info+1
 sty open_in+1
 sta pointer+1
 sta infile_info+2
 sta open_in+2
 ldy #0
 lda (pointer),y
 tax
 bne :chkequ
 cmp number
 beq :inerr
 jmp closeout ;no more input files.
 lda #1
 jsr xredirect
:inerr jsr xmess
 hex 8D
 asc "Error:  No input file",8D,00
 lda #-1
 jsr xredirect
 jmp xerr
:chk= lda (pointer),y ;check for equal filenames
 cmp (outfile),y
 bne getin
 iny
 dex
 bpl :chkequ
 lda #1
 jsr xredirect
 jsr xmess
 hex 8D
 asc "Error:  Filenames cannot be equal",8D,00
 lda #-1
 jsr xredirect
 jmp xerr

getin jsr mli ;get infile info
 dfb #mli_gfinfo
 dw infile_info
 bcs :error
 jsr mli ;open file
 dfb #mli_open
 dw open_in
 bcc :getref
:error jmp xProDOS_err
:getref lda open_in+5
 sta read_in+1
 sta close_in+1

getout bit flag
 bpl readin
 bvs readin
 lda flag ;set open out flag
 ora #%01000000
 sta flag
 jsr mli ;get outfile info
 dfb #mli_gfinfo
 dw outfile_info
 bcc :openout
 cmp #$46
 beq :create
 jmp xProDOS_err
:create ldy #4 ;copy infile info into outfile info
:loop1 lda infile_info+3,y
 sta create_out+3,y
 dey
 bpl :loop1
 ldy #3
:loop2 lda infile_info+14,y
 sta create_out+8,y
 dey
 bpl :loop2
 jsr mli ;create new output file
 dfb #mli_create
 dw create_out
 bcs :error
:openout jsr mli ;open output file
 dfb #mli_open
 dw open_out
 bcc :storef
:error jmp xProDOS_err
:storef lda open_out+5
 sta mark_out+1
 sta write_out+1
 sta close_out+1
 jsr mli ;get output eof
 dfb #mli_geteof
 dw mark_out
 bcs :error
 jsr mli ;set mark to append data
 dfb #mli_setmark
 dw mark_out
 bcs :error

readin jsr mli ;read data from infile
 dfb #mli_read
 dw read_in
 bcc :readok
 cmp #$4C ;at end of file - all done
 bne :readerr
 jmp closein
:readerr jmp xProDOS_err
:readok lda read_in+6 ;store write length
 sta write_out+4
 clc
 adc buffstart
 sta bufflast ;calculate last buffer address
 lda read_in+7
 sta write_out+5
 adc buffstart+1
 sta bufflast+1
 lda buffstart
 sta pointer ;init pointer
 sta write_out+2 ;store write start
 lda buffstart+1
 sta pointer+1
 sta write_out+3

main bit flag
 bpl :mloop
 jsr mli ;write out buffer
 dfb #mli_write
 dw write_out
 bcc readin
 jmp xProDOS_err
:mloop ldy #0
 lda (pointer),y
 ora #$80
 cmp #$A1 ;> " " output
 bcs :outchar
 cmp #$8D ;carriage return
 beq :outcr
 cmp #$89 ;tab character
 beq :outchar
 cmp #" " ;space?
 bne :outdot
 lda width ;check for wrap
 beq :outspc ;no - output space
 sec
 sbc htab
 cmp #10 ;within 9 spaces of wrap margin?
 bcc :outcr ;yes - output carriage return
:outspc lda #" " ;no - output space
 hex 2C
:outdot lda #"."
:outchar jsr cout
 inc htab
 lda htab
 ldx width ;width parameter given?
 beq :chk80 ;nope
 cmp width ;horizontal position at width?
 beq :outcr ;no - next character
:chk80 cmp #80
 bne :next
 beq :xcheck
:outcr jsr crout ;yes - output carriage return
:xcheck jsr xcheck_wait
 bcs closein
 lda #0
 sta htab ;set htab to beginning of file
:next inc pointer
 bne :chkptr
 inc pointer+1
:chkptr lda pointer
 cmp bufflast ;compare with last address
 bcc :mloop ;not end of buffer
 lda pointer+1
 cmp bufflast+1
 bcc :mloop ;not end of buffer
 jmp readin

closein jsr mli ;close input file
 dfb #mli_close
 dw close_in
 bcc :noerr
 jmp xProDOS_err
:noerr inc number ;process next file
 lda number
 cmp #5
 bcs closeout
 jmp chkin

closeout bit flag ;check for output file
 bpl :exit
 jsr mli ;close output file
 dfb #mli_close
 dw close_out
 bcc :exit
 jmp xProDOS_err
:exit rts

infile_info = *
 dfb $A
 ds 17
open_in dfb $3
 ds 2
 dw filebuff
 ds 1
read_in = *
 dfb $4
 ds 7
close_in = *
 dfb $1
 ds 1
open_out = *
 dfb $3
 ds 2
 dw filebuff2
 ds 1
outfile_info = *
 dfb $A
 ds 17
mark_out = *
 dfb $2
 ds 4
create_out = *
 dfb $7
 ds 11
write_out = *
 dfb $4
 ds 7
close_out = *
 dfb $1
 ds 1
 err *-1/$B000
