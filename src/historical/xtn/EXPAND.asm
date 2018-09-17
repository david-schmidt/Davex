;*********************************************
;
; External command for Davex
;
; Written by Jeff Ding
; Created : Apr 30, 1989
; Modified: Jun 04, 1989
;
; expand -- expand tabs in files
;
;*********************************************

OrgAdr = $AE00

 org OrgAdr
 put globals
 put apple.globals
 put mli.globals

MyVersion = $11
MinVersion = $12
AuxVersion = $03
prbl2 = $F94A
maxtabs = 16

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
 dfb "s",t_string   ;programmable tab stops
 dfb "t",t_int1     ;tab spaces
 dfb "c",t_int1     ;tab character
 dfb 0,0
descr str "Expand tabs.  Written by Jeff Ding"
;*********************************************

 dum xczpage ;32 locations
pointer ds 2
buffstart ds 2 ;buffer starting address
bufflast ds 2 ;last address of buffer
length ds 1
xtemp ds 1
number ds 1
htab ds 1
tabchar ds 1
tabspace ds 1 ;standard spaces between tabs
tabstops ds maxtabs ;programmable tab stops
 dend

start sty open_in+1 ;store infile info
 sta open_in+2
 lda #0 ;initalize variables
 sta htab
 ldy #maxtabs-1
:loop sta tabstops,y
 dey
 bpl :loop

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

gettab lda #"t" ;check for tab space
 jsr xgetparm_ch
 bcs :default
 cpy #0
 bne :stotab
:default ldy #8
:stotab sty tabspace

getchar lda #"c" ;check for tab character
 jsr xgetparm_ch
 bcc :given
 ldy #$09 ;tab character default
:given sty tabchar

getstops lda #"s" ;get  programmable tab stops
 jsr xgetparm_ch
 ldx #1
 bcs :done
 sty pointer
 sta pointer+1
 ldy #0
 lda (pointer),y
 sta length
 inc length ;length of string + 1
:nextnum stx xtemp
 lda #0
 sta number
 ldx #3 ;loop 3 times
:nextdig iny ;get next number from string
 cpy length
 bcs :delim ;at end of string
 lda (pointer),y
 ora #$80
 cmp #"0"
 bcc :delim ;not a number
 cmp #":"
 bcs :delim ;not a number
 and #$0F
 pha
 lda number
 asl
 bcs :tobig
 asl
 bcs :tobig
 asl
 bcs :tobig
 adc number
 bcs :tobig
 adc number
 sta number
 bcs :tobig
 pla
 adc number
 bcc :stornum
:tobig ldx xtemp ;invalid number - done
 jmp :done
:stornum sta number
 dex
 bne :nextdig
:delim ldx xtemp
 lda number
 beq :done
 dec number
 lda number
 cpx #1
 beq :store
 cmp tabstops-2,x
 bcc :done
 beq :done
:store sta tabstops-1,x
 inx
 cpx #maxtabs+1
 bcs :done
 cpy length
 bcc :nextnum
:done cpx #maxtabs+1
 bcs :exit
 lda tabspace
 cpx #1
 beq :store2
 clc
 adc tabstops-2,x
 bcs :exit ;tab overflow
:store2 sta tabstops-1,x
 inx
 bpl :done
:exit

getin jsr mli ;open file
 dfb #mli_open
 dw open_in
 bcs readerr
 lda open_in+5
 sta read_in+1

readin jsr mli ;read data from infile
 dfb #mli_read
 dw read_in
 bcc readok
 cmp #$4C ;at end of file - all done
 bne readerr
 jmp close
readerr jmp xProDOS_err
readok lda read_in+6 ;store write length
 clc
 adc buffstart
 sta bufflast ;calculate last buffer address
 lda read_in+7
 adc buffstart+1
 sta bufflast+1
 lda buffstart
 sta pointer ;init pointer
 lda buffstart+1
 sta pointer+1

main ldy #0
 lda (pointer),y
 cmp tabchar
 beq :outtab
 ora #$80
 cmp #" " ;> " " output
 bcs :outchar
 cmp #$8D ;carriage return
 beq :outcr
 bne :outdot
:outtab jsr exptab ;expand tab -1 space
 lda #" "
 hex 2C
:outdot lda #"."
:outchar jsr cout
 inc htab
 lda htab
 beq :outcr
:chk80 cmp #80
 bcc :next
 beq :xcheck
 cmp #160
 bcc :next
 beq :xcheck
 cmp #240
 beq :xcheck
 bne :next
:outcr jsr crout ;force carraige return
 lda #0
 sta htab
:xcheck jsr xcheck_wait
 bcs close
:next inc pointer
 bne :chkptr
 inc pointer+1
:chkptr lda pointer
 cmp bufflast ;compare with last address
 bcc main ;not end of buffer
 lda pointer+1
 cmp bufflast+1
 bcc main ;not end of buffer
 jmp readin

exptab ldx #0 ;expand tab to spaces
 lda htab
:tab1 cmp tabstops,x
 bcc :gottab
 inx
 cpx #maxtabs
 bcc :tab1
 bcs :exit
:gottab lda tabstops,x
 sec
 sbc htab
 tax
 dex
 beq :exit
 txa
 clc
 adc htab
 sta htab
 jsr prbl2
:exit rts

close jsr mli ;close input file
 dfb #mli_close
 dw close_file
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
close_file = *
 dfb $1
 dfb 0

 err *-1/$B000
