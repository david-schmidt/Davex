;*********************************************
;
; External command for Davex
;
; Written by Jeff Ding
; Created : June 29, 1988
; Modified: Feb  06, 1989
;
; tr -- translate strings
;
;*********************************************

inc2 mac  ;two byte increment
 inc ]1
 bne inc
 inc ]1+1
inc <<<
dec2 mac
 lda ]1
 bne decexit
 dec ]1+1
decexit dec ]1
 <<<
mov2 mac  ;move hi/lo to hi/lo
 lda ]1
 sta ]2
 lda ]1+1
 sta ]2+1
 <<<

OrgAdr = $AA00

 org OrgAdr
 put globals
 put apple.globals
 put mli.globals

MyVersion = $12
MinVersion = $12
AuxVersion = $03
maxlength = 63

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
 dfb "s",t_string   ;search string
 dfb "r",t_string   ;replace string
 dfb "f",t_nil      ;force overwrite
 dfb "d",t_nil      ;replace original
 dfb "c",t_string   ;control character initiator
 dfb "h",t_string   ;hi-bit initiator
 dfb "w",t_int1     ;force wrap margin
 dfb 0,0
descr str "Translate strings.  Written by Jeff Ding"
;*********************************************

 dum xczpage ;32 locations
pointer ds 2
buffstart ds 2
buffend ds 2
last ds 2
scrnptr ds 2
hibit ds 1 ;hi-bit  initiator
control ds 1 ;control initiator
flag ds 1 ;output file flag
length ds 1 ;length of string+1
width ds 1 ;wrap margin
htab ds 1 ;current offset in line
 dend

start lda #"c" ;check for control initiator
 jsr xgetparm_ch
 bcs :noctrl
 sty pointer
 sta pointer+1
 ldy #0
 lda (pointer),y
 beq :noctrl
 iny
 lda (pointer),y
 and #$7F
 hex 2C
:noctrl lda #'^' ;default control initiator
 sta control

 lda #"h" ;check for hi-bit initiator
 jsr xgetparm_ch
 bcs :nohibit
 sty pointer
 sta pointer+1
 ldy #0
 lda (pointer),y
 beq :nohibit
 iny
 lda (pointer),y
 and #$7F
 hex 2C
:nohibit lda #'~' ;default hi bit initiator
 sta hibit

 lda #"w" ;check for wrap margin
 jsr xgetparm_ch
 bcc :stowrap
 ldy #0
:stowrap sty width
 lda #0
 sta htab ;init htab value

chkserch lda #"s" ;check for search string given
 jsr xgetparm_ch
 bcs :badparm
 sty pointer
 sta pointer+1
 ldy #0
 lda (pointer),y
 beq :badparm ;search string cannot be null
 cmp #maxlength+1
 bcs :badparm ;greater than maximum length
 tay
 iny
 sty length ;length of string+1
 ldy #1
 ldx #1
:translt jsr translate ;get character from string
 sta search-1,x
 bcs :done ;carry set means end of string
 inx
 bpl :translt
:badparm jmp bad_parms_err
:done stx search-1

chkrepl lda #"r" ;check for replace string given
 jsr xgetparm_ch
 ldx #0
 bcs :done ;null replace string
 sty pointer
 sta pointer+1
 ldy #0
 lda (pointer),y
 beq :done ;null replace string
 cmp #maxlength+1
 bcs :badparm ;greater than maximum length
 tay
 iny
 sty length ;length of string+1
 ldy #1
 ldx #1
:translt jsr translate ;get character from string
 sta replace-1,x
 bcs :done ;carry set means end of string
 inx
 bpl :translt
:badparm jmp bad_parms_err
:done stx replace-1

chkin lda #0 ;check for input filename
 jsr xgetparm_n
 sty pointer
 sty infile_info+1
 sty open_in+1
 sty destroy_in+1
 sty rename_out+3
 sta pointer+1
 sta infile_info+2
 sta open_in+2
 sta destroy_in+2
 sta rename_out+4

chkout lda #1 ;check for output filename
 jsr xgetparm_n
 sty buffstart
 sty outfile_info+1
 sty destroy_out+1
 sty open_out+1
 sty create_out+1
 sty rename_out+1
 sta buffstart+1
 sta outfile_info+2
 sta destroy_out+2
 sta open_out+2
 sta create_out+2
 sta rename_out+2
 ldy #0
 lda (buffstart),y
 beq :noout  ;output parameter not given
 tax
:loop lda (pointer),y ;check for equal filenames
 cmp (buffstart),y
 bne :setflag
 iny
 dex
 bpl :loop
 jmp bad_parms_err
:setflag lda #$80
 hex 2C
:noout lda #$0
 sta flag ;hi bit on indicates outfile

getin jsr mli ;get infile info
 dfb #mli_gfinfo
 dw infile_info
 bcc :open
 jmp xProDOS_err
:open jsr mli ;open file
 dfb #mli_open
 dw open_in
 bcc :getref
 jmp xProDOS_err
:getref lda open_in+5
:storef sta read_in+1

getout bit flag
 bmi :getinfo
 jmp getbuff
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
 bcc :create
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
 bcc :openout
 jmp xProDOS_err
:openout jsr mli ;open output file
 dfb #mli_open
 dw open_out
 bcc :storef
 jmp xProDOS_err
:storef lda open_out+5
 sta write_out+1

getbuff ldx #mli_read
 jsr xmmgr ;return # of free pages
 sta read_in+5 ;subtract maxlength from buffer length
 tya
 sec
 sbc #maxlength
 sta read_in+4
 lda read_in+5
 sbc #0
 sta read_in+5
 ldx #mli_gfinfo
 jsr xmmgr ;return lowest free page
 sta read_in+3 ;add maxlength to beginning of buffer
 tya
 clc
 adc #maxlength
 sta read_in+2
 sta buffstart
 lda #0
 adc read_in+3
 sta read_in+3
 sta buffstart+1

 ldx #0 ;x register has offset of search string
readloop jsr mli ;read data
 dfb #mli_read
 dw read_in
 bcc :calcend
 cmp #$4C ;end of data error
 bne :readerr
 jmp close ;at end of file - all done
:readerr jmp xProDOS_err
:calcend lda read_in+2 ;calculate buffer end
 clc
 adc read_in+6
 sta buffend
 lda read_in+3
 adc read_in+7
 sta buffend+1
 stx last
 lda buffstart ;buffer starting address
 sec
 sbc last
 sta last ;write last address
 sta write_out+2 ;write start address
 lda buffstart+1
 sbc #0
 sta last+1
 sta write_out+3
 mov2 buffstart;pointer
 txa
 beq :declast
 tay
 dey
:mloop lda search,y ;move search string to beginning of buffer
 sta (last),y
 dey
 bpl :mloop
:declast dec2 last

:chkloop ldy #0
 lda (pointer),y ;get current character
 cmp search,x ;compare with search string
 beq :nxtchar ;if equal - continue checking
 inc2 last ;skip character
 mov2 last;pointer ;reset pointer to beginning of search string
 ldx #0 ;fix x register
 beq :incptr
:nxtchar inx ;character found - check next in search string
 cpx search-1 ;is x = search length?
 beq :found ;yes - write out buffer
:incptr inc2 pointer ;increment to next buffer character
:chkptr lda pointer+1
 cmp buffend+1
 bcc :chkloop pointer < buffend - check search length
 lda pointer
 cmp buffend
 bcc :chkloop ;pointer < buffend - check search length
 jsr writeout ;write out buffer
 bcc :writeok
 jmp xProDOS_err
:writeok jmp readloop ;read in next section
:found jsr writeout ;write out buffer
 bcc :writrep
 jmp xProDOS_err
:writrep lda replace-1
 beq :next
 sta write_out+4
 lda #0
 sta write_out+5
 lda #<replace ;write out replace string
 sta write_out+2
 lda #>replace
 sta write_out+3
 jsr output ;output to file or screen
 bcc :next
 jmp xProDOS_err
:next mov2 pointer;last
 inc2 pointer
 mov2 pointer;write_out+2
 ldx #0
 beq :chkptr

writeout lda last ;calculate length
 sec
 sbc write_out+2
 sta write_out+4
 lda last+1
 sbc write_out+3
 sta write_out+5
 inc2 write_out+4
 lda write_out+4
 ora write_out+5
 bne output ;write out buffer
 clc
 rts  ;buffer length is zero

output bit flag
 bpl :screen ;output to screen
 jsr mli ;write out buffer to file
 dfb #mli_write
 dw write_out
 rts
:screen stx :xtemp
 mov2 write_out+2;scrnptr
:outloop ldy #0
 lda (scrnptr),y
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
 bcs :abort
 lda #0
 sta htab ;set htab to beginning of file
:next inc2 scrnptr
 dec2 write_out+4
 lda write_out+4
 bne :outloop
 lda write_out+5
 bne :outloop
 ldx :xtemp
 clc
 rts
:xtemp ds 1
:abort pla  ;soft abort - exit
 pla

close jsr mli ;close up all files
 dfb #mli_close
 dw close_all
 bcc :closeok
 jmp xProDOS_err
:closeok bit flag
 bpl :alldone
 lda #"d" ;check for delete and rename flag
 jsr xgetparm_ch
 bcs :alldone
 jsr mli ;destroy infile
 dfb #mli_destroy
 dw destroy_in
 bcc :rename
 jmp xProDOS_err
:rename jsr mli ;rename new to old name
 dfb #mli_rename
 dw rename_out
 bcc :alldone
 jmp xProDOS_err
:alldone rts

translate = *
 lda #0
 sta :hibit
 sta :control
:fixloop lda (pointer),y
 and #$7F
:chkhi cmp hibit ;hibit delimiter?
 bne :chkctrl ;no - check for control
 bit :hibit ;was previous a ~ ?
 bmi :char ;yes - special character
 dec :hibit ;no - next character get's hibit on
 bmi :next ;get next character
:chkctrl cmp control ;control delimiter?
 bne :char ;no - normal character
 bit :control ;was previous a ^ ?
 bmi :char ;yes - special character
 dec :control ;no - next character get's control code
 bmi :next ;get next character
:char bit :control ;control char?
 bpl :noctrl
 cmp #$60 ;lower case character?
 bcc :nolower
 sbc #$20 ;make lower case upper
:nolower cmp #$3F ;special code for rubout?
 beq :rubout
 cmp #$3E ;special code for ^ ?
 beq :carrot
 cmp #$3D ;special code for ~ ?
 beq :circum
 bcc :exit ;illegal control code - skip
 and #$3F ;and bits to make character a control code
 hex 2C ;skip next load
:rubout lda #$7F
 hex 2C ;skip next load
:carrot lda #$5E
 hex 2C ;skip next load
:circum lda #$7E
:noctrl bit :hibit ;hibit encountered?
 bpl :exit
 ora #$80 ;add in hibit
:exit iny
 cpy length
 rts
:next iny
 cpy length
 bcc :fixloop
 rts
:hibit ds 1 ;hibit flag
:control ds 1 ;control flag

 ds 1
search ds maxlength
 ds 1
replace ds maxlength

infile_info = *
 db $A
 ds 17
outfile_info = *
 db $A
 ds 17
destroy_in = *
 db $1
 ds 2
destroy_out = *
 db $1
 ds 2
open_in = *
 db $3
 ds 2
 dw filebuff
 ds 1
open_out = *
 db $3
 ds 2
 dw filebuff2
 ds 1
read_in = *
 db $4
 ds 7
write_out = *
 db $4
 ds 7
create_out = *
 db $7
 ds 11
close_all = *
 db $1
 db 0
rename_out
 db $2
 ds 4

bad_parms_err = *
 jsr xmess
 hex 8D
 asc "Error:  Bad parameters",8D,00
 jmp xerr
 err *-1/$B000
