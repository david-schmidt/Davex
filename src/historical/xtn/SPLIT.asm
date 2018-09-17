;*********************************************
;
; External command for Davex
;
; Written by Jeff Ding
; Created : July 17, 1988
; Modified: Feb 04, 1989
;
; split -- split off sections of files
;
;*********************************************

inc3 mac
 inc ]1
 bne inc3exit
 inc ]1+1
 bne inc3exit
 inc ]1+2
inc3exit <<<
inc2 mac
 inc ]1
 bne inc2exit
 inc ]1+1
inc2exit <<<
mov3 mac
 lda ]1
 sta ]2
 lda ]1+1
 sta ]2+1
 lda ]1+2
 sta ]2+2
 <<<
mov2 mac
 lda ]1
 sta ]2
 lda ]1+1
 sta ]2+1
 <<<

OrgAdr = $AC00

 org OrgAdr
 put globals
 put apple.globals
 put mli.globals

MyVersion = $11
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
 dfb 0,t_wildpath   ;output file name
 dfb "s",t_int3     ;starting point
 dfb "e",t_int3     ;ending point
 dfb "l",t_int3     ;length
 dfb "b",t_yesno    ;measurement in bytes=yes  lines=no
 dfb "d",t_int1     ;line delimiter ascii number
 dfb "f",t_nil      ;force delete of output file
 dfb "w",t_int1     ;wrap margin
 dfb 0,0
descr str "Split.  Written by Jeff Ding"
;*********************************************

 dum xczpage ;32 locations - DO NOT change order!

pointer ds 2
buffstart ds 2 ;buffer starting address
bufflast ds 2 ;last address of buffer
begin ds 3 ;starting offset
end ds 3 ;ending offset
line ds 3 ;current line offset
flag ds 1 ;%1000_0000 - outfile given
   ;%0100_0000 - count by lines
htab ds 1
width ds 1
dline ds 1 ;line delimiter
 dend

start nop
 sty pointer ;initialize variables
 sty infile_info+1
 sty open_in+1
 sta pointer+1
 sta infile_info+2
 sta open_in+2
 lda #0 ;blank variables
 ldx #10
:zerolp sta begin,x
 dex
 bpl :zerolp

 lda #1 ;check for output filename
 jsr xgetparm_n
 sty buffstart
 sty outfile_info+1
 sty destroy_out+1
 sty create_out+1
 sty open_out+1
 sta buffstart+1
 sta outfile_info+2
 sta destroy_out+2
 sta create_out+2
 sta open_out+2
 ldy #0
 lda (buffstart),y
 beq :chkbyte
 tax
:chk= lda (pointer),y
 cmp (buffstart),y
 bne :fileok
 iny
 dex
 bpl :chkequ
 jmp bad_parms_err
:fileok lda flag
 ora #%10000000
 sta flag

:chkbyte lda #"b" ;check for byte/line flag
 jsr xgetparm_ch
 bcs :chkstrt
 bmi :chkstrt
 lda flag
 ora #%01000000
 sta flag

:chkstrt lda #"s" ;check for starting offset
 jsr xgetparm_ch
 bcs :nostart
 sty begin
 stx begin+1
 sta begin+2
:nostart bit flag
 bvc :chkend
 lda begin
 ora begin+1
 ora begin+2
 bne :chkend
 inc3 begin ;if by lines - begin cannot be zero

:chkend lda #"e" ;check for ending offset
 jsr xgetparm_ch
 bcs :chklen
 sty end
 stx end+1
 sta end+2
 inc3 end
 lda begin+2
 cmp end+2
 bcc :chkdlim
 lda begin+1
 cmp end+1
 bcc :chkdlim
 lda begin
 cmp end
 bcc :chkdlim
:error jmp bad_parms_err

:chklen lda #"l" ;check for length offset
 jsr xgetparm_ch
 bcc :stolen
 dec end
 dec end+1
 dec end+2
 bne :chkdlim
:stolen sty end
 stx end+1
 sta end+2
 ora end+1
 ora end
 beq :error ;length cannot be zero
 lda begin ;calculate ending offset
 clc
 adc end
 sta end
 lda begin+1
 adc end+1
 sta end+1
 lda begin+2
 adc end+2
 sta end+2

:chkdlim lda #"d" ;check for line delimiter
 jsr xgetparm_ch
 bcc :ddelim
 ldy #$0D ;defalt line delimiter is carriage return
:ddelim tya
 and #$7F
 sta dline

 lda #"w" ;check for wrap margin
 jsr xgetparm_ch
 bcc :stowrap
 ldy #0
:stowrap sty width

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
 sta setmark_in+1

getout bit flag
 bmi :getinfo
 jmp adjust
:getinfo jsr mli ;get outfile info
 dfb #mli_gfinfo
 dw outfile_info
 bcc :exists
 cmp #$46
 beq :create
 jmp xProDOS_err
:exists lda #"f" ;check for force destruction flag
 jsr xgetparm_ch
 bcc :destroy
 lda #1
 jsr xredirect
 jsr xmess
 asc "Okay to overwrite ",00
 ldy open_out+1
 lda open_out+2
 jsr xprint_path
 lda #"n"
 jsr xyesno2
 php
 lda #$FF
 jsr xredirect
 plp
 bne :destroy
 lda #$86 ;abort err
 jmp xProDOS_err
:destroy jsr mli ;destroy old file
 dfb #mli_destroy
 dw destroy_out
 bcs :error
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
 jsr mli ;open output file
 dfb #mli_open
 dw open_out
 bcc :storef
:error jmp xProDOS_err
:storef lda open_out+5
 sta write_out+1

adjust bit flag
 bvs adjline
 mov3 begin;setmark_in+2 ;adjust beginning of file by bytes
 jsr mli
 dfb #mli_setmark
 dw setmark_in
 bcs :exit
 jsr readin ;fill buffer
 mov2 buffstart;pointer
 bcc main
:exit jmp close ;start > eof - quit

adjline jsr readin ;adjust beginning of lines
 bcs :exit ;at end of file - exit
 lda buffstart
 sec
 sbc #1
 sta pointer
 lda buffstart+1
 sbc #0
 sta pointer+1
 jmp :incline ;one line found at beginning of file
:chkloop ldy #0
 lda (pointer),y
 and #$7F ;blank hi-bit
 cmp dline ;equal to line delimiter?
 bne :incptr ;not - increment pointer
:incline inc3 line ;increment lines found
 lda line
 cmp begin
 bcc :incptr
 lda line+1
 cmp begin+1
 bcc :incptr
 lda line+2
 cmp begin+2
 bcc :incptr ;not found yet - increment pointer
 jsr incptr ;found - increment to first position
 bcc :exit
:rdloop jsr readin ;end of buffer - read again
 bcs :exit ;end of file - exit
 mov2 buffstart;pointer
 jmp :chkloop
:incptr jsr incptr
 bcc :chkloop ;not at end of buffer - check again
 bcs :rdloop ;at end of buffer - read again
:exit bcc main
 jmp close ;start > eof - quit

main mov2 pointer;write_out+2
:mloop ldy #0
 lda (pointer),y
 bit flag
 bmi :noout
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
 beq :ldaspc
 sec
 sbc htab
 cmp #10
 bcc :outcr
:ldaspc lda #" "
 hex 2C
:outdot lda #"."
:outchar jsr cout
 inc htab
 lda htab
 ldx width ;width parameter given?
 beq :chk80 ;nope
 cmp width ;horizontal position at width?
 beq :outcr ;nope
:chk80 cmp #80
 bne :noout
 beq :xcheck
:outcr jsr crout ;yes - output carriage return
:xcheck jsr xcheck_wait
 bcs :exit
 lda #0
 sta htab ;set htab to beginning of file
:noout bit flag ;counting by lines?
 bvc :incbgin ;nope
 lda (pointer),y
 and #$7F
 cmp dline
 bne :incptr
:incbgin inc3 begin ;increment offset
 lda begin+2
 cmp end+2
 bcc :incptr ;not at end
 lda begin+1
 cmp end+1
 bcc :incptr ;not at end
 lda begin
 cmp end
 bcc :incptr ;end found - exit
 inc2 pointer
 bcs :finish
:incptr jsr incptr
 bcc :mloop ;not end of buffer
 bit flag
 bpl :nofile ;no output file
 jsr write
:nofile jsr readin
 mov2 buffstart;pointer
 bcs :exit ;all done
 jmp main ;check next character
:finish bit flag ;all done
 bpl :exit
 jsr write
:exit

close bit flag
 bpl :exit
 jsr mli
 dfb #mli_close
 dw close_parms
 bcs error
:exit rts

write lda pointer ;calculate length
 sec
 sbc write_out+2
 sta write_out+4
 lda pointer+1
 sbc write_out+3
 sta write_out+5
 jsr mli ;write out buffer
 dfb #mli_write
 dw write_out
 bcs error
:exit rts

error jmp xProDOS_err

readin jsr mli ;read data from infile
 dfb #mli_read
 dw read_in
 bcc :readok
 cmp #$4C ;at end of file - all done
 beq :end
 bne error
:readok lda read_in+6 ;calculate last buffer address
 clc  ;add 1 to last buffer address
 adc buffstart
 sta bufflast
 lda read_in+7
 adc buffstart+1
 sta bufflast+1
 clc
 rts
:end sec
 rts

incptr inc2 pointer ;increment pointer
 lda pointer+1
 cmp bufflast+1 ;compare with last address
 bcc :exit
 lda pointer
 cmp bufflast
:exit rts

infile_info = *
 dfb $A
 ds 17
open_in dfb $3
 ds 2
 dw filebuff
 ds 1
setmark_in = *
 dfb $2
 ds 4
read_in = *
 dfb $4
 ds 7
open_out = *
 dfb $3
 ds 2
 dw filebuff2
 ds 1
outfile_info = *
 dfb $A
 ds 17
destroy_out = *
 dfb $1
 ds 2
create_out = *
 dfb $7
 ds 11
write_out = *
 dfb $4
 ds 7
close_parms = *
 dfb $1
 dfb 0

bad_parms_err = *
 jsr xmess
 dfb $8D
 asc "Error:  Bad parameters",8D,00
 jmp xerr
 err *-1/$B000
