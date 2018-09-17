;*********************************************
;
; External command for Davex
;
; Written by Jeff Ding
; Modified: Dec 25, 1989
;
; date -- interactive date and time setting program
;
; 8-Mar-90 DAL--changed version # to 1.5
;   because Jeff didn't bump the version number
;   when he fixed -f and the date rollover.
;   Some folks got 'date' 1.4 with Davex 1.25.
;
;*********************************************

OrgAdr = $AC00
Date = $BF90
Time = $BF92

 org OrgAdr
 put globals
 put apple.globals
 put mli.globals

MyVersion = $15 ;8-Mar-90 DL (JD did not bump vers #)
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
 dfb "p",t_nil
 dfb "s",t_nil
 dfb "d",t_nil
 dfb "t",t_nil
 dfb "f",t_path
 dfb 0,0
descr str "Date and time setting program.  Written by Jeff Ding"
;*********************************************

 dum xczpage ;32 locations
day ds 1
month ds 1
year ds 1
hour ds 1
minute ds 1
fileflag ds 1
hourtemp ds 1
 dend

start = *
 jsr mli ;get date/time from clock card if any
 dfb mli_gettime
 dw $0000
 jsr getinfo ;get date/time from prodos
 lda #"f" ;check for file time stamp
 sta fileflag ;make fileflag non 0
 jsr xgetparm_ch
 bcs :getnump ;-f not given
 sty file_info+1
 sta file_info+2
 lda day
 ora month
 ora year
 ora hour
 ora minute
 sta fileflag
 bne :chknump ;date/time already set
 jsr getfile ;get file time stamp
:chknump jsr xgetnump ;if no other parms given then print/set
 cmp #1
 beq :noopt
 lda fileflag
 beq :noopt ;if zero - get date/time
 bne :getoptp ;if not zero - check for more options
:getnump jsr xgetnump ;if no parameters then print and set
 cmp #0
 beq :noopt
:getoptp lda #"p" ;if -p then print only
 jsr xgetparm_ch
 bcc :prtonly
 lda #"s" ;if -s then check -d and -t
 jsr xgetparm_ch
 bcc :chkdate
 jmp option_err ;-d or -t given with no -s
:chkdate lda #1
 jsr xredirect
 lda #"d" ;if -d then print/set date
 jsr xgetparm_ch
 bcc :date
 lda day
 ora month
 ora year
 bne :chktime ;date already set - skip
:date jsr prntdate
 jsr getdate
:chktime lda #"t" ;if -t then print/set time
 jsr xgetparm_ch
 bcc :time
 lda hour
 ora minute
 bne :done ;time already set - skip
:time jsr prnttime
 jsr gettime
:done lda #$FF
 jmp xredirect
:noopt lda #1
 jsr xredirect
 jsr prntdate
 jsr getdate
 jsr prnttime
 jsr gettime
 lda #$FF
 jmp xredirect
:prtonly jsr prntdate
 jmp prnttime

getinfo lda Date+1 ;translate Prodos date/time into
 clc  ;day,month,year,hour,minute
 ror
 sta year
 lda Date
 ror
 lsr
 lsr
 lsr
 lsr
 sta month
 lda Date
 and #%00011111
 sta day
 lda Time+1
 sta hour
 lda Time
 sta minute
 rts

getfile jsr mli ;get date/time stamp from file
 dfb mli_gfinfo
 dw file_info
 bcs :exit ;file not found
 ldy #3
:loop lda file_info+10,y
 sta Date,y
 dey
 bpl :loop
 jsr getinfo
:exit rts

stodate lda month ;store day,month,year in Prodos
 asl
 asl
 asl
 asl
 asl
 sta Date
 lda year
 rol
 sta Date+1
 lda day
 ora Date
 sta Date
 rts

stotime lda hour ;store hour,minute in Prodos
 sta Time+1
 lda minute
 sta Time
 rts

prntdate jsr xmess ;print date from day,month,year
 asc "Current Date: ",00
 ldy day
 lda #0
 jsr xprdec_2
 lda #"-"
 jsr cout
 lda month
 asl
 clc
 adc month
 tax
 lda montable,x
 cmp #$E0
 bcc :nolower
 sbc #$20
:nolower jsr cout
 lda montable+1,x
 jsr cout
 lda montable+2,x
 jsr cout
 lda #"-"
 jsr cout
 ldy year
 cpy #10
 bcs :nopad
 lda #"0"
 jsr cout
:nopad lda #0
 jsr xprdec_2
 jmp crout
montable asc "???"
 asc "jan"
 asc "feb"
 asc "mar"
 asc "apr"
 asc "may"
 asc "jun"
 asc "jul"
 asc "aug"
 asc "sep"
 asc "oct"
 asc "nov"
 asc "dec"

prnttime jsr xmess
 asc "Current Time: ",00
 lda #0
 ldy hour
 jsr xprdec_2
 lda #":"
 jsr cout
 ldy minute
 cpy #10
 bcs :nopad
 lda #"0"
 jsr cout
:nopad lda #0
 jsr xprdec_2
 jmp crout

getdate jsr xmess
 asc "Set New Date: ",00
 jsr getinput
 bcs :err
 jsr chkdate
 bcs :err
 jsr stodate
:err jmp crout

gettime jsr xmess
 asc "Set New Time: ",00
 jsr getinput
 bcs :err
 jsr chktime
 bcs :err
 jsr stotime
:err jmp crout

getinput ldx #8 ;clear out instring with spaces
 lda #" "
:clrloop sta instring,x
 dex
 bpl :clrloop
 ldx #0
:curloop stx :xtemp ;store instring offset in temp variable
 lda #" "
 jsr xrdkey ;print cursor
 ldx :xtemp
 cmp #cr
 beq :return ;return key pressed
 cmp #bs
 beq :back ;back arrow pressed
 cmp #$FF
 beq :back ;delete key pressed
 cmp #" "
 bcc :curloop ;anything < a space not allowed
 cpx #9
 bcs :curloop ;end of input string
 jsr cout ;character good.  print it
 jsr xdowncase ;convert to lower case before storing in buffer
:noupper sta instring,x
 inx  ;increment offset in buffer
 jmp :curloop
:back cpx #0 ;no backup if at zero position in buffer
 beq :curloop
 lda #bs
 jsr cout ;backup one space
 dex
 lda #" " ;blank buffer
 sta instring,x
 jsr cout ;blank character on screen
 lda #bs
 jsr cout ;return cursor to actual position
 jmp :curloop
:return cpx #0
 beq :err ;no string entered
 clc
 rts
:err sec
 rts
:xtemp ds 1
instring ds 9

chkdate ldx #0 ;check date.  Any field zero except year makes err
 jsr getdigit ;get day
 sta day ;store day found
 ldy #0 ;put next 3 characters in month temp
:getmnth lda instring,x
 sta tmpmnth,y
 inx
 iny
 cpy #3
 bcc :getmnth
 inx  ;set up offset for year
 stx xtemp ;save offset into instring
 ldy #0
 ldx #0
:chkmnth lda montable,x
 cmp tmpmnth
 bne :nxtmnth
 lda montable+1,x
 cmp tmpmnth+1
 bne :nxtmnth
 lda montable+2,x
 cmp tmpmnth+2
 beq :mnthfnd ;month found -- y reg has #
:nxtmnth inx
 inx
 inx
 iny
 cpy #13
 bcc :chkmnth
 ldy #0 ;month not valid
:mnthfnd sty month
 ldx xtemp ;restore offset into instring
 jsr getdigit ;get year
 sta year ;store year found
 ldx month
 beq :err ;if month=0 then error
 dex  ;fix month offset (0-11)
 lda day
 beq :err ;if day=0 then error
 cmp maxday,x ;check max days for the month
 bcs :err ;if more then error
 rts  ;carry clear on exit here
:err sec
 rts
maxday dfb 32 ;max # of days +1 per month
 dfb 30
 dfb 32
 dfb 31
 dfb 32
 dfb 31
 dfb 32
 dfb 32
 dfb 31
 dfb 32
 dfb 31
 dfb 32
tmpmnth ds 3
xtemp ds 1

incdate inc day ;increment day by one
 ldx month
 beq :ldx
 cpx #13
 bcc :dex
:ldx ldx #1 ;if invalid fudge
 stx month
:dex dex  ;fix month offset (0-11)
:loadday lda day ;get new day
 cmp maxday,x ;cmp with # of days for month
 bcc :exit ;no day overflow
 lda #1
 sta day ;day overflow - first of month
 inc month ;inc month
 lda month
 cmp #13 ;month overflow?
 bcc :exit ;no
:loadmon lda #1
 sta month ;yes - first month
 inc year ;next year
:exit jmp stodate ;store date

chktime ldx #0 ;check time.  zero time is ok.
 jsr getdigit ;get hour
 cmp #24 ;hour>24 then error
 bcs :err
 sta hourtemp ;store hour found
 jsr getdigit ;get minutes
 sta minute ;store minute found
 cmp #60 ;minute>59 then error
 bcs :err
 sec
 ora hourtemp
 beq :err
 lda hourtemp ;get new hour
 cmp hour ;is new hour<old hour (next day)
 bcs :stohour ;no
 lda #"d" ;check for -d option
 jsr xgetparm_ch
 bcc :stohour ;given - skip date increment
 lda #"t" ;check for -t option
 jsr xgetparm_ch
 bcs :stohour ;not given - skip date increment
 lda fileflag
 beq :stohour ;date set from file - skip date increment
 jsr incdate ;increment date by one day
:stohour lda hourtemp
 sta hour
 clc
:err rts  ;no error carry clear on exit

getdigit lda instring,x ;process 1 or 2 dec digits into one
 cmp #"0"
 bcc :nodigit
 cmp #"9"+1
 bcc :storehi
:nodigit lda #0
:storehi and #$0F
 sta numhi
 inx  ;go to second position
 lda instring,x
 inx  ;go to third position
 cmp #"0"
 bcc :switch
 cmp #"9"+1
 bcc :storelo
:switch lda numhi ;hi is actually low.
 sta numlo
 lda #0 ;zero out hi
 sta numhi
 lda numlo
 dex  ;keep in line if number<10
:storelo and #$0F
 sta numlo
 inx  ;set up offset - skip delimiter
 lda numhi ;combine decimal numhi and numlo
 asl
 asl  ;multiply by four
 clc
 adc numhi ;add 1 (multiply by five)
 asl  ;multiply by two
 clc  ;result is multiply by 10
 adc numlo ;add in low part
 rts  ;return with result in A-reg
numhi ds 1
numlo ds 1

option_err = *
 jsr crout
 jsr xmess
 asc "Error:  -d or -t option not valid without -s",8D,00
 jmp xerr

file_info = *
 dfb $A
 ds 17

 err *-1/$B000
