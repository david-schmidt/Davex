;*********************************************
;
; External command for Davex
;
; Written by Jeff Ding
; Created : July 17, 1988
; Modified: Feb  12, 1989
;
; wc -- word count
;
;*********************************************

incd mac
 inc ]1
 bne inc
 inc ]1+1
 bne inc
 inc ]1+2
inc <<<
movd mac
 lda ]1
 sta ]2
 lda ]1+1
 sta ]2+1
 lda ]1+2
 sta ]2+2
 <<<

OrgAdr = $AD00

 org OrgAdr
 put globals
 put apple.globals
 put mli.globals

MyVersion = $20
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
 dfb 0,t_wildpath   ;input file name 1
 dfb 0,t_wildpath   ;input file name 2
 dfb 0,t_path     ;input file name 3
 dfb 0,t_path     ;input file name 4
 dfb 0,t_path     ;input file name 5
 dfb "c",t_nil      ;character count only
 dfb "w",t_nil      ;word count only
 dfb "l",t_nil      ;line count only
 dfb "t",t_nil      ;totals only
 dfb "d",t_int1     ;line delimiter ascii number
 dfb "e",t_int1     ;word delimiter ascii number
 dfb "m",t_int1     ;wrap margin
 dfb 0,0
descr str "Word count.  Written by Jeff Ding"
;*********************************************

 dum xczpage ;32 locations
pathname ds 2 ;pathname to open file
tchar ds 3 ;do not change oder
tword ds 3 ;do not change order
tline ds 3 ;do not change order
char ds 3 ;do not change order
word ds 3 ;do not change order
line ds 3 ;do not change order
flag ds 1 ;do not change order
htab ds 1 ;do not change order
current ds 1 ;current character
prev ds 1 ;previous character
dword ds 1 ;word delimiter
dline ds 1 ;line delimiter
width ds 1 ;margin to force increment of lines
parmnum ds 1 ;current parm number
 dend

start nop ;initial entry point
fixstart jmp initial
initial lda #<start2
 sta fixstart+1
 lda #>start2
 sta fixstart+2
 ldx #8
 lda #0
:loop sta tchar,x
 dex
 bpl :loop

start2 nop ;consecutive entry point
 lda #0
 sta parmnum
nextparm lda parmnum
 jsr xgetparm_n ;get pathname address
 sty pathname ;save pathname address
 sta pathname+1
 ldy #0
 lda (pathname),y
 bne :prtpath
 jmp alldone ;no more paths
:prtpath lda #"t"
 jsr xgetparm_ch
 bcc :nocr
 jsr crout
:nocr ldy pathname
 lda pathname+1
 jsr xprint_path
 jsr xmess
 asc ":",8D,00

init lda #0 ;initialize variables
 ldx #10
:loop sta char,x
 dex
 bpl :loop

 lda #"c" ;check for character only flag
 jsr xgetparm_ch
 bcs :chkword
 lda flag
 ora #%00000001
 sta flag

:chkword lda #"w" ;check for word only flag
 jsr xgetparm_ch
 bcs :chkline
 lda flag
 ora #%00000010
 sta flag

:chkline lda #"l" ;ckeck for line only flag
 jsr xgetparm_ch
 bcs :chkflag
 lda flag
 ora #%00000100
 sta flag
:chkflag lda flag ;if none given, display all
 bne :chkdlim
 ora #%00000111
 sta flag

:chkdlim lda #"d" ;check for line delimiter
 jsr xgetparm_ch
 bcc :ddelim
 ldy #$0D ;defalt line delimiter is carriage return
:ddelim tya
 and #$7F
 sta dline

 lda #"e" ;check for word delimiter
 jsr xgetparm_ch
 bcc :edelim
 ldy #$20 ;defalt word delimiter is space
:edelim tya
 and #$7F
 sta dword
 sta prev

 lda #"m" ;check for margin width
 jsr xgetparm_ch
 bcc :wrap
 ldy #0
:wrap sty width

open ldy pathname ;open file
 lda pathname+1
 jsr xfman_open
 bcs :readerr
 sta close_parms+1
:read lda close_parms+1
 jsr xfman_read ;read character from file
 bcc :readok
 cmp #$4C ;at end of file - all done
 bne :readerr
 jmp :exit
:readerr jmp xProDOS_err
:readok and #$7F
 sta current ;save character
 cmp dword
 beq :word
 cmp dline ;character equal to line delimiter?
 bne :incchar
 incd line ;if equal increment line count
 lda #0
 sta htab
:word lda dline
 cmp prev ;was last character a line delimiter or
 beq :incchar
 lda dword
 cmp prev ;was last character a word delimiter?
 beq :incchar
 incd word ;if not increment word count
:incchar incd char ;increment character count
 lda current
 sta prev ;move current to previous character
 ldx width ;margin width given?
 beq :read ;no - check next character
 cmp dline ;last character a line delimiter?
 beq :read ;yes - already wrapped
 cmp dword ;last character a word delimiter?
 bne :chktab ;no - inc htab
 txa  ;yes - check range
 sec
 sbc htab
 cmp #10 ;dword within 9 spaces of margin?
 bcc :wrap ;yes - wrap
:chktab inc htab
 lda htab
 cmp width ;htab at wrap margin?
 bcc :read
:wrap incd line ;yes - increment # of lines
 lda #0
 sta htab
 jmp :read ;check next character
:exit lda prev
 cmp dline ;last character equal to line delimiter?
 beq close ;yes - exit
 cmp dword ;last character equal to word delimiter?
 beq :incline ;yes - inc line count
 incd word
:incline incd line

close jsr mli ;close file
 dfb #mli_close
 dw close_parms
 bcc addtot
 jmp xProDOS_err

addtot ldy #3 ;add to totals
 ldx #0
:loop lda char,x
 clc
 adc tchar,x
 sta tchar,x
 inx
 lda char,x
 adc tchar,x
 sta tchar,x
 inx
 lda char,x
 adc tchar,x
 sta tchar,x
 inx
 dey
 bne :loop

print lda #"t" ;if t given, skip over print
 jsr xgetparm_ch
 bcc :nxtparm
 jsr prntchar ;print out char,word,line
:nxtparm inc parmnum
 lda parmnum
 cmp #5
 bcs alldone
 jsr xcheck_wait
 jmp nextparm

alldone lda char+2
 cmp tchar+2
 bcc prnttot
 lda char+1
 cmp tchar+1
 bcc prnttot
 lda char
 cmp tchar
 bcc prnttot
 jmp exit

prnttot ldx #8
:loop lda tchar,x
 sta char,x
 dex
 bpl :loop
 jsr xmess
 hex 8D
 asc "Grand total:",8D,00

prntchar lda flag
 and #%00000001
 beq prntword
 movd char;xnum
 jsr xmess
 asc "char count =",00
 jsr xprdec_pad
 jsr crout

prntword lda flag
 and #%00000010
 beq prntline
 movd word;xnum
 jsr xmess
 asc "word count =",00
 jsr xprdec_pad
 jsr crout

prntline lda flag
 and #%00000100
 beq exit
 movd line;xnum
 jsr xmess
 asc "line count =",00
 jsr xprdec_pad
 jsr crout

exit rts

close_parms = *
 db $1
 ds 1
 err *-1/$B000
