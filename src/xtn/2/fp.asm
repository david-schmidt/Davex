;*****************************************
;
; fp -- DAVEX external command by
;
; Dave Lyons
; 13-Jul-86
;
; Does AppleWriter-ish text formatting.
; Based on:
;
;    FreePrinter v1.0
;    by Elliot Lifson
;
;    5/24/86
;
; Syntax:  fp filename [-c] [-1]
;
;   -c:  print credits
;   -1:  single page (.sp1)
;
;*****************************************
;
; BUGS
;   .li not implemented
;   sometimes begins line with blank if 2
;     blanks at end of sentence
;
;*****************************************
;
; Modified 13-Jul-86 Dave Lyons:
;   made into a DAVEX external command
;   moved to EDASM assembler
;
;*****************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"
	;

.segment	"CODE_9800"

orgadr	= $9800
; org orgadr
;*****************************************
myversion	= $02
minversion	= $06
;*****************************************
;
; XC header
;
	rts
	.byte $ee,$ee
	.byte myversion,minversion
	.byte %00000000	;hardware req
	.addr descr
	.addr orgadr
	.addr start
	.byte 0,0,0,0
; parmeters
	.byte 0,t_wildpath
	.byte $80+'1',t_nil
	.byte $80+'c',t_nil
	.byte 0,0
;
descr:	pstr "text formatter based on FreePrinter"
;*****************************************
;
; ZERO PAGE ADDRESSES
;
; dsect
; org xczpage
ptr1	= xczpage	;ds 2
myP	= ptr1+2	;ds 2
myTemp	= myP+2	;ds 1
; dend
;
; Buffers
;
BufferBegin	= $8800
LastBufPg	= $97
FILEBUF	= filebuff
PATHBUF	= pagebuff
TLBUF	= pagebuff+$80
;*****************************************
;
; work storage
;
Buffer:	.addr BufferBegin
QUOT:	.byte 0	;quotient used in FJ routine
REMNDR:	.byte 0	;remainder used in FJ routine
NFLAG:	.byte 0	;parsed PM number is <0
EOFLAG:	.byte 0	;0 -> whole file has been read
VARY:	.byte 0	;work variable
VARX:	.byte 0	;work variable
PRNT:	.byte 0	;dumping to printer
LastFF:	.byte 0	;If >0, formfeed last item parsed
DMPACTV:	.byte 0	;active dumping taking place
HDRSTAT:	.byte 0	;justify header line status
LC:	.byte 0	;line counter
CC:	.byte 0	;character counter
CORCC:	.byte 0	;corrected character counter
LINELN:	.byte 0	;length of line to print
SKIPS:	.byte 0	;number of lines to skip
PGCNTR:	.byte 0	;number of page being printed
LASTCR:	.byte 0	;indicates status of EOL marker
;
; formatting variables
;
FmtVars:
LM:	.byte 10	;left margin value
RM:	.byte 70	;right margin value
PM:	.byte 0	;paragraph margin value
PAGELN:	.byte 66	;max number of lines per page
PRTLNS:	.byte 60	;# of lines to print per page
TM:	.byte 0	;# of skipped lines after header
SNGLPGE:	.byte 0	;prompt for each page
PMODE:	.byte 0	;status of text justification
LineInterval:	.byte 1	;.li value
NumVars	= *-FmtVars
;
LMS:	.res NumVars	;storage for last valid parm set
Header:	.byte 0	;length of header line
;*************************************************
start:
;
; textdump is not happening;
; line counter = 0;
; page counter = 1;
; printing off;
; CR was printed
;
	lda #0	;Initialize bytes
	sta DMPACTV	;not dumping at the moment
	sta LC	;Zero out Line Counter
	sta PRNT	;& printing flag
	lda #1	;Initialize page counter
	sta PGCNTR	;to first page.
	lda #$FF	;Indicate EOL char. is CR
	sta LASTCR
;
; if '-1', set SNGLPG
;
	lda #$80+'1'
	jsr xgetparm_ch	;SEC if not found
	lda #0
	adc #0	;adds 1 if SEC
	eor #1
	sta SNGLPGE
;
; print credits if '-c'
;
	lda #$80+'c'
	jsr xgetparm_ch
	bcs skip_credits
	jsr creditmsg
skip_credits:
;
; get pathname of input file
;
	lda #0
	jsr xgetparm_n
	sta OpenPath+1
	sty OpenPath
	sta InfoPath+1
	sty InfoPath
	sta myP+1
	sty myP
	ldy #0
	lda (myP),y
	bne file_given
	jsr xmess
	.byte cr
	asc "syntax:  fp [pathname] [-c] [-1]"
	.byte cr,0
	rts
file_given:
;--------------------------------------
DoFile:	lda #0
	sta TLBUF
DoFile1:	lda Buffer	;Move buffer start address
	sta RREF+1	;to read parm table
	lda Buffer+1
	sta RREF+2
	jsr CLEAR1	;Clear main buffer (0 left in A)
	sta REQLEN	;Compute size of MLI READ
	lda #LastBufPg+1	;by subtracting buffer start
	sec
	sbc Buffer+1
	sta REQLEN+1
;
; get_file_info
;
	jsr mli	;Get stats of requested file
	.byte mli_gfinfo
	.addr ATTRPMS
	bcs ProErr
;
; make sure it's a TXT file
;
	lda TYPE
	cmp #tTXT
	beq is_txt
;
; not TXT file
;
	jsr xmess
	asc "not TXT file"
	.byte cr,0
	jmp xerr
is_txt:
;
L33:	jsr mli	;If okay, open the file
	.byte mli_open
	.addr OPENPMS
	bcc OpenOK
ProErr:	jmp xProDOS_err
OpenOK:	lda REF	;Move file ref. #
	sta RREF	;to read parm list
	jsr READRNG	;Then read some data to buffer
;
	lda Buffer	;Initialize zero page
	sta ptr1	;pointer to beginning of buffer.
	lda Buffer+1
	sta ptr1+1
;
	jsr SETPRT	;Set printer/screen from parms.
	lda #$80	;Indicate dump taking place.
	sta DMPACTV
	jsr SAVEPMS	;Save current parm values
	lda PAGELN	;Look at Page Interval
	beq DOLINE	;If zero, no top margin
	jsr HALFMAR	;Do first page top margin
	jsr TOPLINE
DOLINE:	lda LASTCR	;Look at EOL marker status
	beq DOLINE1	;0 = space
	bmi z34	;$FF = CR;
	jmp EXIT	;else $01=null (EOF); EXIT
z34:	ldy #0	;Look at
	lda (ptr1),Y	;first character
	jsr ADJCHR	;Positive ascII, uppercase
	cmp #'.'	;Is it a period?
	beq L35	;Yes, continue cmnd. processing
	jsr CHKPMS	;Else, check parms for validity
	jsr SAVEPMS	;Resave valid parms
	jmp DOLINE1	;& continue routine
;
L35:
L36:	jsr PARSE	;Change parm by imbedded command
	jsr KILLPAR	;Skip to next paragraph
	jmp DOLINE	;Loop back for another command
DOLINE1:	lda PAGELN	;Look at Page Length spec
	beq L37	;If 0, non-stop print; do more
	lda PRTLNS	;Else get # of lines to print
	cmp LC	;vs. # of lines so far
	bne L37	;If not equal, skip below
	lda #$0	;Else, reset counter
	sta LC
	ldy SKIPS	;Get # of lines to be skipped
	beq L39	;If none, "SKIP" the routine!
L38:	jsr crout	;Else do the skips.
	jsr CHKYBD	;Check for keypress
	dey
	bne L38
L39:	lda SNGLPGE	;See if single page active
	beq L41	;No, skip past routine
	lda PRNT	;Are we printing?
	beq L40	;No, skip past
	jsr PRNTOFF
L40:	jsr xmess
	asc "Insert page & press a key"
	.byte cr,0
	jsr myWAIT
	lda PRNT
	beq L41
	jsr SETPRT	;Restart printer
L41:	inc PGCNTR	;Increment page counter
	jsr TOPLINE	;Else do topline routine
L37:
DOLINE2:	jsr LEFTMAR	;Do left margin spaces
	lda PMODE	;Look at Print Mode
	bne L46	;If not LJ, skip PM spacing
	lda LASTCR	;Else, look at EOL status
	bpl L46	;If not CR, skip 'em anyway
	lda LM	;Be sure that
	clc	; LM+PM>0
	adc PM
	bmi L46	;If not, skip spaces
	lda LINELN	;else, adjust LINELN
	sec	;for paragraph margin
	sbc PM
	tay	;Else mominal LINELN
	bpl L47
L46:	ldy LINELN	;Get # of characters on line
L47:	lda #0	;EOL marker nominally a space
	sta LASTCR
	sta LastFF	;Use existing zero to init flag
L50:	lda (ptr1),Y	;Look at nominal EOL char.
	bne L49	;If not null, skip onn past
	sty CC	;Else, save CHAR_CNTR value
	inc LASTCR	;Flag EOL as null
	jsr CRCHECK	;& look for CRs.
	jmp TEXTOUT	;then print line.
L49:	ora #$80	;If not null, set high bit
	cmp #$A0	;See if space character
	beq L51	;If yes, skip on past
	cmp #$8D	;See if CR
	bne L52	;If not, skip past
	lda #$FF	;Else set EOL status
	sta LASTCR
	bne L51	;Branch Always
;
L52:	dey	;Else, go back till you find
	bpl L50	;one or the other.
	ldy LINELN	;If no spaces or CRs in line,
L51:	sty CC	;Use default length; Save in CC
	jsr BACKSP	;Make sure no space clusters
	jsr CRCHECK	;Make sure no prior CRs in Line.
TEXTOUT:	lda CC	;First, move character count
	sta CORCC	;to corrected count.
	lda PRNT	;If not printing,
	beq L55	;skip control character scan.
	jsr CNTRL	;Correct CORCC for Control chars
L55:	iny
	lda CC	;Check # of chars for this line
	beq L60	;If 0 (E.G.2 CRs in a row) skip
	lda PMODE	;Look at Print Mode
	beq L62	;If LJ, skip below
	cmp #3	;Is FJ?
	bcs L65	;Yes, skip below
	cmp #2	;Is RJ?
	php	;Save answer
	lda LINELN	;Take line length
	sec	;subtract the corrected CC
	sbc CORCC
	plp	;Then check if RJ or CJ
	bne L63	;If RJ, skip on past
	lsr a	;Else divide by two
L63:	jsr PRTSPC	;Then pad out the line
	beq L62	;Branch always
L65:	jsr FJCALC	;If FJ, compute QUOT & REMNDR
L62:	lda (ptr1),Y	;Get character
	ora #$80	;Set high bit
	pha	;Save on stack
	lda PRNT	;See if we're printing
	bne L66	;Yes, skip on past
	pla	;Retrieve character
	cmp #$A0	;See if control char.
	bcs L68	;No, skip past
	eor #$C0	;Yes, change to inverse
	bne L68	;& skip past
L66:	pla	;If printing, retrieve character
L68:	cmp #$A0	;Is space?
	php	;Save answer for later
	jsr cout	;& dump character
	plp	;Check answer
	bne L69	;If not space, skip below
	lda PMODE	;Else, check print mode
	cmp #3	;If not FJ,
	bne L69	;skip on past
	lda LASTCR	;If FJ and EOL was a CR,
	bne L69	;skip on past, too.
	jsr DOFJ	;Else pad with spaces
L69:	iny	;Increment for next character
	cpy CC	;See if end of line reached
	bcc L62	;No, do another character
L60:	lda (ptr1),Y	;Look at EOL character
	jsr ADJCHR
	beq L70	;If null, CR or space,
	cmp #$0D	;skip past (corrects for
	beq L70	;arbitrarily injected EOL.)
	cmp #$20
	beq L70
	dey
L70:	iny
	tya	;Update
	clc	;Zero-page pointer by
	adc ptr1	;adding character counter value
	sta ptr1	;to it.
	lda #$0
	adc ptr1+1
	sta ptr1+1
	lda PMODE	;If print mode is FJ, be sure
	cmp #3	;line doesn't start with a
	bne L71	;space by skipping to first
	ldy #0	;non-space
	jsr NEXT1
L71:	lda ptr1+1
	cmp #LastBufPg	;See if last buffer page
	bcc P56	;No, skip past
	lda Buffer+1	;Yes, change ptr1 to page before
	sta ptr1+1	;start of buffer!
	dec ptr1+1
	lda ptr1	;Save low byte of pointer
	pha
	jsr COPYPGE	;then copy last page to BEGIN-1
	pla	;Restore pointer low byte
	sta ptr1
	jsr CLEAR1	;Clear the main buffer
	lda EOFLAG	;Did we already read all?
	beq P56	;Yes, skip ahead
	jsr READRNG	;Else read more of file
P56:	jsr crout	;Print a CR
	inc LC	;Increment line counter
	jsr CHKYBD	;Check for keypress
	jmp DOLINE	;then  Bop till you drop!
;
EXIT:	BIT LastFF	;See if last command was FormFeed
	bpl L64
	jsr HALFMAR	;if so, do 1st page bottom
L64:
	rts
;
; LOOK FOR EARLIEST CR ON LINE
;
CRCHECK:	dey	;decREMENT CHAR COUNTER
	bpl L77	;IF POSITIVE, SKIP PAST
	rts	;ELSE WE'RE DONE CHECKING.
L77:	lda (ptr1),Y	;LOOK AT CHARACTER
	beq L79	;IF NULL, GO BELOW
	ora #$80	;ELSE SET HIGH BIT
	cmp #$8D	;IS IT A CR?
	bne CRCHECK	;NO, CHECK NEXT CHARACTER
	sty CC	;YES, SAVE POSITION, THEN
	lda #$FF	;MARK EOL=CR
	sta LASTCR
	bne CRCHECK	; CHECK NEXT CHARACTER
L79:	dey	;IF NULL, decREMENT CHAR COUNTER
	bmi L80	;IF NEGATIVE END OF FILE REACHED
	lda (ptr1),Y	;ELSE LOOK AT CHARACTER
	beq L79	;IF NULL, GO BACK FOR NEXT CHAR.
L80:	iny	;POINT CTR AT FIRST NULL
	sty CC	;& STORE IT'S VALUE IN CC
	lda #1
	sta LASTCR
	bpl CRCHECK	;BRANCH ALWAYS
;
; FIND EARLIEST SPACE IN CLUSTER
;
BACKSP:	lda PMODE
	cmp #3
	beq BACKSP1
	cmp #1
	beq BACKSP1
	rts
BACKSP1:	dey	;decREMENT INdex
	bmi L81	;IF NEGATIVE, EXIT
	lda (ptr1),Y	;ELSE LOOK AT PREVIOUS CHAR.
	jsr ADJCHR
	cmp #$20	;WAS IT A SPACE?
	beq BACKSP1	;YES, BACKSPACE PAST IT
L81:	iny	;ELSE RESET INdex
	sty CC	;& SAVE IT AS CHAR. COUNT
	rts
;**************************************
;
; Check textline for control characters
;
CNTRL:	ldy CORCC	;get actual char cound
L107:	dey	;move before EOL marker
	bpl L106	;exit if Y<0
	rts
L106:	lda (ptr1),Y	;look at a characer
	and #%01111111
	cmp #$20	;ctrl char?
	bcs L107	;nope, check next
	dec CORCC	;adjust corrected char count
	cmp #$1B	;ESC?
	bne L107
	dec CORCC	;assume ESC & 1 char don't print
;NOP ;USER CAN ADD A
;NOP ; secOND OR THIRD "dec CORCC"
;NOP ; IF NECESSARY.
;NOP
;NOP
;NOP
	bpl L107	;BRANCH ALWAYS
;
; CALCULATE QUOT & REM FOR FJ ROUTINE
;
FJCALC:	ldx #0	;INITIALIZE X-COUNTER
	stx QUOT	; QUOTIENT,
	stx REMNDR	; & REMAINDER.
	ldy CC	;GET CHARACTER COUNT
L109:	dey	;COUNT NUMBER OF SPACES IN LINE
	bmi L110
	lda (ptr1),Y
	ora #$80
	cmp #$A0
	bne L109
	inx	;KEEP COUNT IN X-REG.
	bne L109	;BRANCH ALWAYS
L110:	stx REMNDR	;MOVE COUNT TO REMNDR
	lda LINELN	;GET LENGTH OF LINE
	sec
	sbc CORCC	;SUBTRACT CORRCC
	bcs L111	;IF POSITIVE, SKIP PAST
	ldx #0	;ELSE WEIRD SITUATION;
	stx REMNDR	; CLEAR THE REGS & EXIT
	beq L112
L111:	sbc REMNDR	;ELSE DIVIDE BY # OF SPACES
	bcc L113
	inc QUOT
	bne L111
L113:	adc REMNDR
	sta REMNDR	;STORE REMAINDER IN REMNDR
L112:	ldy #0	;RESET Y-REG
	rts	;& EXIT
;
; Add padding for .fj
;
DOFJ:	tya	;SAVE Y-REG
	pha
	lda QUOT	;PRINT QUOT # OF SPACES
	jsr PRTSPC
	lda REMNDR	;THEN PRINT A REMNDR SPACE,
	beq z113	; UNTIL THERE ARE NONE LEFT
	dec REMNDR
	lda #$80+' '
	jsr cout
z113:	pla	;RESTORE Y-REG
	tay
	rts	;& EXIT
;
; Check that parameters are valid
;
CHKPMS:	lda RM	;GET RM
	sec	;SUBTRACT LM+1
	sbc LM	;(clc IS OKAY)
	bcc L114	;IF <0, ERROR
	cmp #4	;MUST BE AT LEAST 5 CHARS.
	bcs L115	;IF>=5, SKIP PAST
L114:	jsr xmess
	asc "margins too wide"
	.byte cr,0
	jmp xerr
L115:	sta LINELN	;IS LNGTH OF PRINTED LINE.
	inc LINELN	;CORRECT IT UP 1.
	lda PM	;IF PM IS >0, MAKE SURE
	bmi L116
	lda LINELN	; THAT PM IS SMALL ENOUGH TO
	sec	; PERMIT 5 CHARACTERS TO BE
	sbc #$05	; PRINTED ON THE LINE
	sbc PM
	bcc L114
L116:
L118:	lda PAGELN	;GET LINES PER PAGE
	beq L120	;IF ZERO, SKIP PAST
	lda PRTLNS	;ELSE GET # OF PRINTED LINES
	cmp #3	;MUST BE >=3
	bcc L122	;ELSE ERROR
;sec ; SUBTRACT PRINTED LINES
	lda PAGELN	; FROM TOTAL PAGE LINES TO GET
	sbc PRTLNS	; NUMBER OF SKIPS PER PAGE
	bcs L123	;IF >=0, OKAY; SKIP PAST
L122:	jsr xmess
	asc "bad .PL value"
	.byte cr,0
	jmp xerr
L123:	sta SKIPS	;SKIPPED LINES/PAGE
	lda TLBUF	;LOOK AT Header LENGTH
	beq L120	;IF NO Header, SKIP PAST
	lda PRTLNS	;ELSE LOOK AT # OF PRINT LINES
	clc
	sbc TM	;SUBTRACT (TM+1) (clc OKAY)
	bmi L124	;IF TM>=PRTLNS, ERROR
	bne L120	;ELSE OKAY
L124:	;error $84!
	jsr xmess
	asc "top margin too large (.tm)"
	.byte cr,0
	jmp xerr
L120:	rts	;ELSE RETURN
;
; Parse imbedded commands routine
;
PARSE:	jsr NEXT	;ADVANCE POINTER TO NEXT CHAR
PARSE1:	jsr NEXT1	;ADVANCE TO FIRST NON-SPACE
	ldx #0	;ELSE INIT TABLE POINTER
	stx LastFF	;INIT "LAST WAS FORMFEED" FLAG
L125:	cmp COMTBL,X	;LOOK AT FIRST TABLE LETTER
	beq L126	;IF MATCH, SKIP PAST
	inx	;ELSE SKIP 2 BYTES
	inx
	cpx #endComTbl-COMTBL
	bcc L125	;NO GO BACK FOR ANOTHER
	rts	;ELSE RETURN, (THEN TO KILLPAR)
L126:	inx	;incR. TO LOOK AT 2ND CHAR
	iny	;
	lda (ptr1),Y	; & LOOK AT IT
	dey
	jsr ADJCHR	;MAKE POSITIVE, UPPER CASE
	cmp COMTBL,X	;COMPARE WITH TABLE
	bne L127
	jsr NEXT
	jsr NEXT
	bne HandLER
L127:	lda (ptr1),Y	;& REGAIN FIRST BYTE
	jsr ADJCHR	;MAKE POSITIVE, UPPERCASE
	inx	;ADVANCE TO NEXT TABLE CHAR
	bne L125	;BRANCH ALWAYS
;
; get next non-blank
;
NEXT1:	lda (ptr1),Y	;ADVANCE POINTER
	jsr ADJCHR	; PAST ANY SPACES
	cmp #' '
	beq L128
	rts
L128:	jsr NEXT
	bne NEXT1
;
; advance 1 character
;
NEXT:	inc ptr1
	bne PTRok
	inc ptr1+1
PTRok:	rts
;
; Handle parsed commands
;
HandLER:	dex
	lda myCommand,X	;MOVE Command ADDRES
	sta jmpCmd+1	; TO JUMP Command BELOW
	lda myCommand+1,X
	sta jmpCmd+2
jmpCmd:	jmp $ffff	;modified!
;
; High bit off, uppercase
;
ADJCHR:	and #%01111111
	cmp #'a'
	bcc notLC
	and #%11011111
	clc
notLC:	rts
;
; Evaluate decimal number at PTR
;
; return # in A
;
myNumTemp:	.res 1
SETPTR:
	lda #0
	sta myNumTemp
	tay
Decimal1:	lda (ptr1),y
	and #%01111111
	cmp #'0'
	bcc DecDone
	cmp #'9'+1
	bcs DecDone
; myNumTemp *= 10; myNumTemp += digit
	jsr Mult10
	clc
	and #%00001111
	adc myNumTemp
	sta myNumTemp
	iny
	bne Decimal1
;
DecDone:	lda myNumTemp
	rts
;
; Multiply myNumTemp by 10
;
Mult10:	pha
	lda #0
	ldx #10
	clc
mult1:	adc myNumTemp
	dex
	bne mult1
	sta myNumTemp
	pla
	rts
;
; Advance PTR to next paragraph
;
KILLPAR:	ldy #0	;ADVANCE ptr1 TO CR OR NULL:
L136:	lda (ptr1),Y	;LOOK AT CHARACTER
	beq L135	;IF NULL, SKIP PAST
	and #$7F	;ELSE RESET HIGH BIT
	cmp #$0D	; & SEE IF CR
	beq L137	;YES, SKIP PAST
	jsr L138	;ELSE ADVANCE POINTER
	bne L136	;BRANCH ALWAYS
L137:	lda #$FF	;SET LASTCR TO CR STATUS
	sta LASTCR
L138:	inc ptr1	;incREMENT POITER PAIR
	bne L139
	inc ptr1+1
L139:	rts
;
L135:	lda #1	;set LASTCR to null
	sta LASTCR
	bne L138	;always
;************************************************
;
; Dot command handlers
;
OldValue:	.byte 0
DeltaChr:	.byte 0	;'+', '-', or $00
;
ComCom:
	sta OldValue
	lda #0
	sta DeltaChr
	jsr NEXT1	;find first non-space
	cmp #'-'
	beq DeltaSign
	cmp #'+'
	bne AbsoluteNum
DeltaSign:
	sta DeltaChr
	jsr NEXT
AbsoluteNum:
	jsr SETPTR	;parse decimal # into A
	ldx DeltaChr
	beq ComDone
	cpx #'+'
	beq ComAdjust
	eor #$ff	;negate A
	clc
	adc #1
ComAdjust:
	clc
	adc OldValue
ComDone:	cmp #0
	rts
;
; .lm
;
LMCOM:	lda LM
	jsr ComCom
	sta LM
	rts
;
; .rm
;
RMCOM:	lda RM
	jsr ComCom
	sta RM
	rts
;
; .pi
;
PICOM:	lda PAGELN
	jsr ComCom
	sta PAGELN
	rts
;
; .pl
;
PLCOM:	lda PRTLNS
	jsr ComCom
	sta PRTLNS
	rts
;
; .tm
;
TMCOM:	lda TM
	jsr ComCom
	sta TM
	rts
;
; Dave's .PM
;
PMCOM:	lda #0
	jsr ComCom
	sta PM
	rts
;
; .sp
;
SPCOM:	lda SNGLPGE
	jsr ComCom
	beq spNO
	lda #1
spNO:	sta SNGLPGE
	rts
;
; .li
;
LICOM:	lda LineInterval
	jsr ComCom
	sta LineInterval
	rts
;
; .ff [#] -- formfeed if fewer than # lines
;            remain on current page (formfeed
;            always if # is omitted)
;
; (Ignore if .PL=0)
;
FFCOM:
	lda #0
	jsr ComCom
	beq do_formfeed	;not conditional
	sta myTemp
	lda PRTLNS
	sec
	sbc LC	;A=prtlns-linecount: # lines remaining
	cmp myTemp
	bcs ff_done
;
do_formfeed:
	lda DMPACTV	;ignore if not dumping
	beq ff_done
;
	lda PAGELN	;ignore if continuous print
	beq ff_done
;
	sec
	ror LastFF	;set LastFF flag
	lda PRTLNS
	sec	;compute # lines to skip
	sbc LC
	beq ff_done	;IF NONE, IGNORE
	tay	;ELSE SKIP LINES TO END OF PAGE
ff_L1:	jsr crout	; (LESS BOTTOM MARGIN)
	jsr CHKYBD
	dey
	bne ff_L1
	lda PRTLNS	;CORRECT LINE COUNTER
	sta LC
ff_done:	rts
;
; .lj  .cj  .rj  .fj
;
LJCOM:	txa
	sec
	sbc #lcrf-COMTBL
	lsr a
	sta PMODE
	rts
;
; .tl
;
TLCOM:	jsr NEXT1
	sty HDRSTAT
TLCOM1:	lda (ptr1),Y	;LOOK AT FIRST CHARACTER
	jsr ADJCHR
	cmp #'*'	;IF STAR,
	bne L148
	jsr NEXT	;MOVE POINTER PAST IT
	inc HDRSTAT	;& MODIFY STATUS
	bne TLCOM1	;THEN DO AGAIN
L148:	lda HDRSTAT	;FINALLY LOOK AT STATUS;
	beq L149	;IF ZERO SKIP PAST
	dec HDRSTAT	;ELSE decREMENT
	lda HDRSTAT
	cmp #3
	bcc L149
	lda #2
	sta HDRSTAT
; STATUS =0 FOR NONE OR 1 STARS, =1 FOR 2 STARS
;  =2 FOR 3 OR MORE
L149:	jsr NEXT1
	jsr ADJCHR
	cmp #$0D	;IF FIRST CHAR IS CR, SKIP BELOW
	beq L151
L152:	cmp #$0D	;ELSE IF CR ENCOUNTERED,
	beq L153	;EXIT AT :P2
	iny	;ADVANCE INdex
	lda (ptr1),Y	;LOOK AT CHARACTER
	jsr ADJCHR
	bcc L152	;BRANCH ALWAYS
L153:	dey	;CORRECT INdex
	lda (ptr1),Y	;BLOW OFF TRAILING SPACES
	jsr ADJCHR
	cmp #$20
	beq L153
	iny
	sty TLBUF	;SAVE LENGTH OF STRING
L154:	dey	; & MOVE TO
	bmi L150
	lda (ptr1),Y	; TLBuffer
	and #$7F
	sta TLBUF+1,Y
	bne L154
L150:	rts
L151:	sty TLBUF	;ZERO LENGTH IF NULL INPUT
	rts
;
; SAVE PRINT PARMS
;
SAVEPMS:	ldx #NumVars-1
save1:	lda LM,X
	sta LMS,X
	dex
	bpl save1
	lda TLBUF
	sta Header
	rts
;
; RESTORE PRINT PARMS
;
RESTPMS:	ldx #NumVars-1
rest1:	lda LMS,X
	sta LM,X
	dex
	bpl rest1
	lda Header
	sta TLBUF	;EXIT THRU CHKPMS TO
	jmp CHKPMS	;CORRECT HALF PROCESSED PARMS
;
CHKYBD:
	tya
	pha
	txa
	pha
	jsr xcheck_wait
	bcs abort_fp
	pla
	tax
	pla
	tay
	rts
abort_fp:	jsr xmess
	.byte cr
	asc "--fp aborted--"
	.byte cr,0
	jmp xerr
;
; clear path buffer to nulls
;
CLEAR90:	lda #<PATHBUF
	sta PAGE+2
	jmp CLEAR
;
; Clear main buffer from start to LastBufPg+$FF
;
CLEAR1:	lda Buffer
	sta PAGE+1
	lda Buffer+1
	sta PAGE+2
L161:	jsr CLEAR
	inc PAGE+2
	lda PAGE+2
	cmp #LastBufPg
	bcc L161
CLEAR:	lda #0	;CLEAR A PAGE
	tay
	sta PAGE+1
PAGE:	sta Buffer,Y
	iny
	bne PAGE
	rts
;
; print top or bottom margin: blank lines
;
HALFMAR:	lda SKIPS
	lsr a	;/2
	beq NoSkips
	tay
DoSkips:	jsr crout
	jsr CHKYBD
	dey
	bne DoSkips
NoSkips:	rts
;
; READ call to MLI
;
READRNG:	jsr mli
	.byte mli_read
	.addr READPMS
	bcc ReadOK2
ProErr2:	jmp xProDOS_err
;
ReadOK2:	lda REF
	sta MREF
	sta EOFREF
;
	jsr mli
	.byte mli_geteof
	.addr EOFPMS
	bcs ProErr2
;
	jsr mli
	.byte mli_getmark
	.addr MARKPMS
	bcs ProErr2
;
	ldx #2	;Cmp EOF with Mark
CmpMarkEOF:	lda EOFPOS,X
	cmp MARKPOS,X	;If =, while file read; EOFLAG=0
	bne MarkNEeof	;else EOFLAG<>0
	dex
	bpl CmpMarkEOF
MarkNEeof:	inx
	stx EOFLAG
	rts
;
; Copy last buffer page to first page-1
;
COPYPGE:	ldy #0
	sty ptr1
L183:	lda LastBufPg*$100,Y
	sta (ptr1),Y
	iny
	bne L183
	rts
;
; Wait for keypress after delay
;
myWAIT:	lda #$FF
	sta VARX
L190:	dec VARX
	bne L190
WAITKY:	lda keyboard
	bpl WAITKY
	sta kbdstrb
	and #$7F
	cmp #3
	beq L191
	rts
L191:	jmp abort_fp
;
ThisRTS:	rts
;
; Print the top line information
;
TOPLINE:	ldy TLBUF	;length of header
	beq ThisRTS
	sty VARY
SearchPound:	dey	;dec index
	lda TOPLINE+1,Y	;look for "#"
	cmp #'#'	; (working backwards)
	bne SearchPound
	lda PGCNTR	;ELSE, LOOK AT PAGE COUNTER
	cmp #10	;IF <10 EXIT
	bcc L193
	inc VARY	;ELSE incREMENT WORK AREA
	cmp #100	;SAME FOR <100
	bcc L193
	inc VARY
L193:	lda LINELN	;GET RM-LM
	cmp VARY	;IS Header LONGER?
	bcs L194	;NO, CONTINUE
L195:	lda LM	;YES, DO LJ
	bpl L196
L194:	lda HDRSTAT	;LOOK AT Header STATUS
	beq L195	;IF ZERO, DO LJ
	cmp #1	;IF 1, CJ; DO CENTERING RTN.
	beq L198
	lda RM	;ELSE DO RJ; GET RM VALUE
	sec	;SUBTRACT
	sbc VARY	; CORRECTED LENGTH
	bpl L196	; & PRINT THAT MANY SPACES
L198:	lda LINELN	;COMPUTE CENTERING. START
	sec	;WITH WORKING LENGTH (RM-LM)
	sbc VARY	;IF Header LONGER,
	bcs L197	; MAKE EQUAL
	lda #0
L197:	lsr a	;NOW, DIVIDE BY 2
	clc
	adc LM	;ADD LEFT MARG BACK IN
L196:	jsr PRTSPC	;ELSE, PRINT SPACES.
	ldy #0	;NOW RESET INdex TO
L199:	lda TLBUF+1,Y	;PRINT TOPLINE
	cmp #'#'	;IF CHARACTER IS NOT "#"
	bne L200	;SKIP PAST
	tya
	pha
	lda #0	;OF PAGE CNTR
	ldy PGCNTR
	jsr xprdec_2
	pla
	tay
	jmp L201	;SKIP ORIGINAL CHARACTER
L200:	ora #$80	;SET HIGH BIT
	jsr cout	;PRINT TO SCREEN
L201:	iny	;incR. FOR NEXT CHAR.
	cpy TLBUF	;REACHED END?
	bcc L199	;NO, DO ANOTHER
	jsr crout	;ELSE PRINT A CR
	inc LC	; & ADVANCE COUNTER
	lda TM	;GET NUMBER OF BLANK LINES
	beq L203	; NONE? SKIP PAST
	tay	;ELSE USE AS COUNTER
L202:	jsr crout	; TO PRINT CRS
	inc LC	; & incR. LINE COUNTER
	dey	;decR COUNTER
	bne L202	;NOT ZERO, DO ANOTHER
L203:	rts	; & RETURN
;
; PRINT "N" SPACES BEFORE EACH LINE
;
LEFTMAR:	lda LASTCR	;LOOK AT EOL CHAR.
	bpl L205	;IF NOT CR, SKIP BELOW
	lda PMODE	;ELSE LOOK AT PRINT MODE
	bne L205	;IF NOT LJ, SKIP BELOW
	lda LM	;COMPUTE LM+PM SPACES
	clc
	adc PM
	bpl PRTSPC	;THEN PRINT THEM
	rts
L205:	lda LM	;IF NOT NEW PAR OR LJ,
;
; PRINT A-REG NUMBER OF SPACES
;
PRTSPC:	tay	; PRINT MARGIN SPACES
	beq L207
	lda #' '+$80
L208:	jsr cout
	dey
	bne L208
L207:	rts
;
; Suspend printing
;
PRNTOFF:
	lda #1
	jsr xredirect
	rts
;
; SET PRINT FLAGS FROM DEFAULTS
;
SETPRT:
	lda #<-1
	jsr xredirect
	lda #1
	sta PRNT
	rts
;**********************************
;
;          T A B L E S
;
; open file
;
OPENPMS:	.byte 3
OpenPath:
	.addr 0
	.addr FILEBUF
REF:	.byte 0
;
; read from file
;
READPMS:	.byte 4
RREF:	.res 3
REQLEN:	.res 2
RETLEN:	.res 2
;
; get file info
;
ATTRPMS:	.byte 10
InfoPath:
	.addr 0
	.byte 0
TYPE:	.res $0E
;
; get file mark
;
MARKPMS:	.byte 2
MREF:	.byte 0
MARKPOS:	.res 3
;
; get EOF
;
EOFPMS:	.byte 2
EOFREF:	.byte 0
EOFPOS:	.res 3
;
; Dot command handler addresses
;
myCommand:
	.addr LMCOM
	.addr RMCOM
	.addr PICOM
	.addr PLCOM
	.addr TMCOM
	.addr PMCOM
	.addr SPCOM
	.addr FFCOM
	.addr LJCOM
	.addr LJCOM
	.addr LJCOM
	.addr LJCOM
	.addr TLCOM
	.addr LICOM
;
; Table of 2-letter dot commands
;
COMTBL:	asc "LM"
	asc "RM"
	asc "PI"
	asc "PL"
	asc "TM"
	asc "PM"
	asc "SP"
	asc "FF"
lcrf:	asc "LJ"
	asc "RJ"
	asc "CJ"
	asc "FJ"
	asc "TL"
	asc "LI"
endComTbl:
;***************************************
creditmsg:
	jsr xmess
	.byte cr
	asc "Dave Lyons developed "
	.byte $27
	asc "fp"
	.byte $27
	asc " from:"
	.byte cr,cr
	asc "     - FREEPRINTER - v1.0"
	.byte cr
	asc "       by Elliot Lifson"
	.byte cr
	asc "  (c) 1986, NINCOMPUTE, LTD"
	.byte cr,cr,0
	rts
