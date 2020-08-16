;*********************************************
;
; External command for DAVEX
;
; conp -- IIgs Control Panel
;
; started 13-Jul-87 DL
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************
;
; PROBLEMS
;
;  Clock options not implemented
;
;*********************************************
;
; Parameters:
;
;    L  Load BRAM parameters from a file
;    K  Keep BRAM parameters in a BIN file
;
;    O  Options
;    F  Fast
;    A  Audio
;    R  RAMdisk
;    S  Slots
;  > C  Clock
;    D  Display
;    1  Port 1 settings
;    2  Port 2 settings
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
;prbyte = $fdda
;
myversion	= $09
minversion	= $11
;*********************************************
	rts
	.byte $ee,$ee
	.byte myversion,minversion
	.byte %00001000	;hardware req
	.addr descr
	.addr orgadr
	.addr start
	.byte 0,0,0,0
; parameters here
	asc "l"
	.byte t_wildpath	;load parm file
	asc "k"
	.byte t_path	;keep parm file
	asc "o"
	.byte t_string	;Options string
	asc "f"
	.byte t_string	;Fast clock
	asc "a"
	.byte t_string	;audio stuff
	asc "r"
	.byte t_string	;RAMdisk options
	asc "s"
	.byte t_string	;slots stuff
	asc "c"
	.byte t_string	;clock options
	asc "d"
	.byte t_string	;display options
	asc "1"
	.byte t_string	;port 1 setup
	asc "2"
	.byte t_string	;port 2 setup
	.byte 0,0
descr:	pstr "set IIgs Control Panel options"
;*********************************************
; dsect 0
tNIL	= $0000	;.res $100
tINT1	= $0100	;.res $100
tBOOL	= $0200	;.res $100
tSLOT	= $0300	;.res $100
tSPEED	= $0400	;.res $100
tCOLOR	= $0500	;.res $100
tRAM32	= $0600	;.res $100
tPARITY	= $0700	;.res $100
tBITS	= $0800	;.res $100
tBAUD	= $0900	;.res $100
tDEVICE	= $0A00	;.res $100
tLINELEN	= $0B00	;.res $100
tDATEFMT	= $0C00	;.res $100
tLANG	= $0D00	;.res $100
tREPSPD	= $0E00	;.res $100
tREPDLY	= $0F00	;.res $100
tBOOTSL	= $1000	;.res $100
; dend
;*********************************************
; dsect
; org xczpage ;32 locations
oldstk	= xczpage	;.res 1
error	= oldstk+1	;.res 1
myErrcode	= error+1	;.res 2
myP	= myErrcode+2	;.res 2
myP2	= myP+2	;.res 2
myTemp	= myP2+2	;.res 2
OptIdx	= myTemp+2	;.res 1
str	= OptIdx+1	;.res 2
idx	= str+2	;.res 1 ;for chrget/chrgot
tbl	= idx+1	;.res 2 ;for GeneralParse
gpp	= tbl+2	;.res 2 ;ditto
addr	= gpp+2	;.res 2
; dend
;
start:
	tsx
	stx oldstk
	jsr ReadAllBram
	bcs ouch
	lda num_parms
	beq noParms
	ldx #0
	stx OptIdx
opt1:	ldx OptIdx
	lda OptTbl,x
	beq CtlpDone
	jsr xgetparm_ch
	bcs optNext
	jsr DoOne
optNext:	inc OptIdx
	bne opt1
CtlpDone:	rts
;
noParms:	jmp DispAll
;
ouch:	jsr xmess
	asc "*** Unable to read Batery RAM: $"
	.byte 0
	lda myErrcode+1
	jsr prbyte
	lda myErrcode
	jsr prbyte
	jsr crout
	jmp xerr
;
DoOne:	lda OptIdx
	asl a
	tax
	lda OptHandle+1,x
	pha
	lda OptHandle,x
	pha
	ldx OptIdx
	lda OptTbl,x
	jsr xgetparm_ch
	sta str+1
	sty str
	ldy #0
	sty idx
	lda (str),y	;A=length, idx=0
	rts
;
chrget:	inc idx
chrgot:	ldy #0
	lda idx
	cmp (str),y
	beq chok
	bcs nch
chok:	ldy idx
	lda (str),y
	jsr xdowncase
	clc
	rts
nch:	sec
	lda #0
	rts
;
getyn:	jsr chrgot
	bcs exp_yn
	ldx #1
	cmp #'y'
	beq gotyn
	ldx #0
	cmp #'n'
	beq gotyn
exp_yn:	jsr xmess
	asc "*** 'y' or 'n' expected"
	.byte cr,0
	jmp xerr
gotyn:	clc
	txa
	pha
	jsr chrget
	pla
	rts
;
chkdig:	cmp #'0'
	bcc cdno
	cmp #'9'+1
	rts
cdno:	sec
	rts
;
max:	.byte 0
getnum1:	sta max
	inc max
	lda #0
	sta value
	jsr chrgot
	bcs gotnum
	jsr chkdig
	bcs gotnum
gn1:	and #$0f
	pha
	asl value
	bcs n2big
	lda value
	asl value
	bcs n2big
	asl value
	bcs n2big
	adc value
	bcs n2big
	sta value
	pla
	adc value
	bcs n2big
	sta value
	jsr chrget
	bcs ndun
	jsr chkdig
	bcc gn1
ndun:	lda value
	cmp max
	bcs n2big
;clc
gotnum:	lda value
	rts
n2big:	jsr xmess
	asc "*** number too big"
	.byte cr,0
	jmp xerr
;
; relnum -- A=max, X=old val
;
; Look for "<" or ">" followed by
; a number, or just a number.
;
oldval:	.byte 0
relnum:	stx oldval
	sta max
	jsr chrgot
	cmp #'<'
	beq relLess
	cmp #'>'
	beq relGreat
	lda max
	jmp getnum1
relLess:	jsr chrget
	lda max
	jsr getnum1
	bcs relx
	sta myTemp
	sec
	lda oldval
	sbc myTemp
	bcc underflow
	clc
	rts
relGreat:
	jsr chrget
	lda max
	jsr getnum1
	bcs relx
;clc
	adc oldval
	bcs overflow
	cmp max
	bcs overflow
;clc
relx:	rts
;
underflow:
	jsr xmess
	asc "*** adjusted value too small"
	.byte cr,0
	jmp xerr
overflow:
	jsr xmess
	asc "*** adjusted value too large"
	.byte cr,0
	jmp xerr
;
ThatsAll:
	jsr chrgot
	bcs wasall
	jsr xmess
	asc "*** extra characters in string"
	.byte cr,0
	jmp xerr
wasall:	clc
	rts
;
; OptTbl
;
OptTbl:	asc "lkofarscd12"
	.byte 0
OptHandle:
	.addr HandleL-1,HandleK-1,HandleO-1,HandleF-1
	.addr HandleA-1,HandleR-1,HandleS-1,HandleC-1
	.addr HandleD-1,handle1-1,handle2-1
;*********************************************
Lerr:	jmp xProDOS_err
HandleL:
	lda #'l'
	jsr xgetparm_ch
	jsr OpenFile
	jsr mli
	.byte mli_read
	.addr RWparms
	bcs Lerr
	jsr WriteAllBram
	jsr MakeCurrent
	rts
;
HandleK:
	lda #'k'
	jsr xgetparm_ch
	sta CreateP+2
	sty CreateP+1
	jsr mli
	.byte mli_create
	.addr CreateP
	bcc Kopen
	cmp #err_dupfil
	bne Kerr
Kopen:	lda CreateP+2
	ldy CreateP+1
	jsr OpenFile
	jsr mli
	.byte mli_write
	.addr RWparms
	bcs Kerr
	rts	;Davex closes file
Kerr:	jmp xProDOS_err
;
;
OpenFile:
	sta OpenP+2
	sty OpenP+1
	jsr mli
	.byte mli_open
	.addr OpenP
	bcc Opened
	jmp xProDOS_err
Opened:	lda OpenRef
	sta rwRef
	rts
;
OpenP:	.byte 3
	.addr 0,filebuff
OpenRef:	.byte 0
;
CreateP:	.byte 7,0,0,%11000011,tBIN,0,0,1,0,0,0,0
;
RWparms:	.byte 4
rwRef:	.byte 0
	.addr pagebuff,$100,0
;********************************************
;
HandleO:
	bne HandO2
	lda #>OptionParms
	ldy #<OptionParms
	jmp DumpInfoAY
;
HandO2:
	lda #>ParseOpTbl
	ldy #<ParseOpTbl
	jmp GeneralParse
;
HandleF:
	bne HandF2
	lda #>FastParms
	ldy #<FastParms
	jmp DumpInfoAY
HandF2:
	jsr chrget
	jsr getyn
	ldx #$20
	jsr WriteAX
	jmp ThatsAll
;
HandleA:
	bne HandA2
	lda #>AudioParms
	ldy #<AudioParms
	jmp DumpInfoAY
HandA2:
	jsr chrget
AudioCh:	jsr chrgot
	bcs AudioX
	cmp #'v'
	beq doVol
	cmp #'p'
	beq doPit
	jsr xmess
	asc "*** v or p expected"
	.byte cr,0
	jmp xerr
AudioX:	rts
doVol:	jsr chrget
	ldx #$1e	;volume
	jsr ReadBram
	tax	;old value
	lda #$e	;max
	jsr relnum
	bcs intVol
wrVol:	ldx #$1e
	jsr WriteAX
	jmp AudioCh
doPit:	jsr chrget
	ldx #$1f	;pitch
	jsr ReadBram
	tax
	lda #$e	;max
	jsr relnum
	bcs intPit
wrPit:	ldx #$1f
	jsr WriteAX
ach:	jmp AudioCh
;
intVol:	jsr xmess
	asc "set volume"
	.byte cr,0
	ldx #$1e
	jsr ReadBram
	sta value
	lda #$1e
	bne intAudio
intPit:	jsr xmess
	asc "set pitch"
	.byte cr,0
	ldx #$1f
	jsr ReadBram
	sta value
	lda #$1f
intAudio:
	pha
ia1:	lda #$a0
	jsr xrdkey
	cmp #$9b
	beq iaz
	cmp #$8d
	beq iaz
	cmp #$88
	beq iaDown
	cmp #$95
	beq iaUp
iaBeep:
	pla
	pha
	tax
	lda value
	jsr WriteAX
	lda #$87
	jsr cout
	jmp ia1
iaUp:	lda value
	cmp #$E
	bcs iaBeep
	inc value
	bne iaBeep
iaDown:	lda value
	beq iaBeep
	dec value
	jmp iaBeep
iaz:	pla
	jmp ach
;
;
minRam:	.byte 0
maxRam:	.byte 0
HandleR:
	bne HandR2
	lda #>RAMparms
	ldy #<RAMparms
	jmp DumpInfoAY
HandR2:
	ldx #$36
	jsr ReadBram
	sta minRam
	ldx #$37
	jsr ReadBram
	sta maxRam
	jsr chrget
Rch:	jsr chrgot
	bcs rDUN
	cmp #'s'
	beq rChOK
	cmp #'a'
	beq rChOK
	cmp #'b'
	beq rChOK
	jsr xmess
	asc "*** s, a, or b expected"
	.byte cr,0
	jmp xerr
rChOK:	pha
	jsr chrget
	lda #254
	jsr getnum1
	bcs RamNum
	tay
	pla
	cmp #'s'
	bne rNOTs
	sty minRam
	sty maxRam
rNOTs:	cmp #'a'
	bne rNOTa
	sty minRam
	cpy maxRam
	bcc rNOTa
	sty maxRam
rNOTa:	cmp #'b'
	bne rNOTb
	sty maxRam
	cpy minRam
	bcs rNOTb
	sty minRam
rNOTb:	jmp Rch
rDUN:	lda minRam
	ldx #$36
	jsr WriteAX
	lda maxRam
	ldx #$37
	jmp WriteAX
;
RamNum:	jsr xmess
	asc "*** number expected"
	.byte cr,0
	jmp xerr
;
HandleS:
	bne handS2
	lda #>SlotParms
	ldy #<SlotParms
	jmp DumpInfoAY
handS2:
	jsr chrget
slots1:	jsr chrgot
	bcs slotsx
	cmp #'i'
	beq sl_ok
	cmp #'x'
	beq sl_ok
	cmp #'b'
	bne sloterr
	jsr do_bootsl
	jmp slots1
sloterr:	jsr xmess
	asc "*** i, x, or b expected"
	.byte cr,0
	jmp xerr
sl_ok:	ldx #0
	cmp #'i'
	beq sl_int
	inx	;external
sl_int:	stx slFlag
slot2:	jsr chrget
	bcs slotsx
	cmp #'0'
	bcc slots1
	cmp #'7'+1
	bcs slots1
	and #$0f
	clc
	adc #$20	;$21-$27 are slots
	tax
	lda slFlag
	jsr WriteAX
	jmp slot2
slotsx:	rts
slFlag:	.byte 0
;
do_bootsl:
	jsr chrget
	ldx #$28
	jsr ReadBram
	tax
	lda #9
	jsr relnum
	bcs exp_bs
	ldx #$28
	jmp WriteAX
exp_bs:	jmp pi_miss
;
HandleC:
	bne HandC2
	lda #>ClockParms
	ldy #<ClockParms
	jmp DumpInfoAY
HandC2:
	jsr xmess
	asc "%%% clock options not done"
	.byte cr,0
	jmp xerr
;
HandleD:
	bne HandD2
	lda #>DisplayParms
	ldy #<DisplayParms
	jmp DumpInfoAY
HandD2:
	lda #>ParseDispTbl
	ldy #<ParseDispTbl
	jmp GeneralParse
;
handle1:
	bne Port1_2
	jsr xmess
	asc "Port 1 settings"
	.byte cr,0
	lda #>PrinterParms
	ldy #<PrinterParms
	jmp DumpInfoAY
Port1_2:
	lda #>ParsePrinterTbl
	ldy #<ParsePrinterTbl
	jmp GeneralParse
;
handle2:
	bne port2_2
	jsr xmess
	asc "Port 2 settings"
	.byte cr,0
	lda #>ModemParms
	ldy #<ModemParms
	jmp DumpInfoAY
port2_2:
	lda #>ParseModemTbl
	ldy #<ParseModemTbl
	jmp GeneralParse
;*********************************************
;
; GeneralParse -- input: AY=ptr to table
;
chr1:	.byte 0
chr2:	.byte 0
GeneralParse:
	sta tbl+1
	sty tbl
	jsr chrget
gp1:	lda #0
	sta chr1
	sta chr2
	jsr chrgot
	bcs gpx
	sta chr1
	jsr tryOpt
	bcc gp1
	jsr chrget
	bcs gpBadOpt
	sta chr2
	jsr tryOpt
	bcs gpBadOpt
	jmp gp1
gpx:	jmp ThatsAll
;
gpBadOpt:
	jsr xmess
	asc "*** bad option in string"
	.byte cr,0
	jmp xerr
;
tryOpt:	;option in chr1/chr2
	lda tbl+1
	ldy tbl
	sta gpp+1
	sty gpp
to1:	ldy #0
	lda (gpp),y
	beq to_x
	cmp chr1
	bne to_next
	iny
	lda (gpp),y
	beq to_this
	cmp chr2
	bne to_next
to_this:	jsr chrget
	jsr gpDo1
	clc
	rts
to_next:	clc
	lda gpp
	adc #6
	sta gpp
	bcc to1
	inc gpp+1
	bne to1
to_x:	sec
	rts
;
gpDo1:
	ldy #5
	lda (gpp),y
	sta addr+1
	dey
	lda (gpp),y
	sta addr
	jsr goThere
	pha
	ldy #2
	lda (gpp),y	;battery RAM index
	tax
	pla
	cpx #$ff
	beq noWB
	jsr WriteAX
noWB:	rts
goThere:	jmp (addr)
;
;
ParseTLang:
	jsr ParseInt
; %%% validate?
	rts
;
ParseKLang:
	jsr ParseInt
; %%% validate?
	rts
;
ParseInt:
	ldy #2
	lda (gpp),y
	tax
	jsr ReadBram
	tax	;old value
	ldy #3
	lda (gpp),y	;max value
	jsr relnum
	bcs pi_miss
	rts
pi_miss:	jsr xmess
	asc "*** num or >num or <num expected"
	.byte cr,0
	jmp xerr
;
ParseYN:
	jsr getyn
	rts
;
ParseBaud:
; %%%
	jmp ParseInt
;
ParseDev:
	jsr chrgot
	bcs pdbad
	pha
	jsr chrget
	pla
	cmp #'m'
	beq pdev_m
	cmp #'p'
	beq pdev_p
pdbad:	jsr xmess
	asc "*** device must be m or p"
	.byte cr,0
	jmp xerr
pdev_m:	lda #1
	rts
pdev_p:	lda #0
	rts
;
ParseBits:
	jsr chrgot
	bcs bitsbad
	cmp #'5'
	bcc bitsbad
	cmp #'8'+1
	bcs bitsbad
	sta myTemp
	jsr chrget
	cmp #'/'
	bne bitsbad
	jsr chrget
	cmp #'1'
	bcc bitsbad
	cmp #'2'+1
	bcs bitsbad
	cmp #'2'
	php
	lda myTemp
	sec
	sbc #'5'
	plp
	rol a
	pha
	jsr chrget
	pla
	rts
bitsbad:	jsr xmess
	asc "*** bits must be 5/1 to 8/2"
	.byte cr,0
	jmp xerr
;
ParseParity:
	jsr chrgot
	bcs parbad
	pha
	jsr chrget
	pla
	cmp #'n'
	beq ppar_n
	cmp #'e'
	beq ppar_e
	cmp #'o'
	beq ppar_o
parbad:	jsr xmess
	asc "*** parity must be n, e, or o"
	.byte cr,0
	jmp xerr
ppar_n:	lda #2
	rts
ppar_e:	lda #1
	rts
ppar_o:	lda #0
	rts
;
ParseLength:
	jsr chrgot
	cmp #'u'
	beq plUnlim
	jsr ParseInt
	ldx #4
pl1:	cmp LengthTable,x
	beq plfine
	dex
	bpl pl1
	jsr xmess
	asc "*** length must be u, 40, 72, 80, or 132"
	.byte cr,0
	jmp xerr
plfine:	txa
	rts
plUnlim:	jsr chrget
	lda #0
	rts
;*********************************************
;
; Use PrntTable to show all settings 
;
DispAll:
	lda #>PrntTable
	ldy #<PrntTable
	sta myP+1
	sty myP
DispAll1:
	lda myP+1
	pha
	lda myP
	pha
	ldy #1
	lda (myP),y
	beq DispAllx
	pha
	dey
	lda (myP),y
	tay
	pla
	jsr DumpInfoAY
	clc
	pla
	adc #2
	sta myP
	pla
	adc #0
	sta myP+1
	jmp DispAll1
DispAllx:
	pla
	pla
	rts
;
DumpInfoAY:
	sta myP+1
	sty myP
DispLp:	ldy #0
	lda (myP),y
	iny
	ora (myP),y
	beq DispDone
	jsr Disp1
	clc
	lda myP
	adc #4
	sta myP
	bcc DispLp
	inc myP+1
	bne DispLp
DispDone:
	jmp crout
;
Disp1:
	lda (myP),y
	pha
	dey
	lda (myP),y
	tay
	pla
	jsr print_ay25
	ldy #2
	lda (myP),y
	tax
	jsr ReadBram
	sta value
	jsr xmess
	asc ": "
	.byte 0
	jsr PrintValue
	rts
;
print_ay25:
	ldx #25
print_ay:	;x=field width (right just)
	sta myP2+1
	sty myP2
	txa
	sec
	ldy #0
	sbc (myP2),y
	tax
	bcc pr0
	beq pr0
pr1:	lda #_' '
	jsr cout
	dex
	bne pr1
pr0:	ldy #0
	lda (myP2),y
	beq pr0b
	tax
pr1b:	iny
	lda (myP2),y
	ora #$80
	jsr cout
	dex
	bne pr1b
pr0b:	rts
;
value:	.byte 0
PrintValue:
	jsr pv2
mycrout:
	jsr crout
	jsr xcheck_wait
	bcs ESCced
	rts
ESCced:	ldx oldstk
	txs
	rts
;
pv2:	ldy #3
	lda (myP),y
	asl a
	tax
	lda Kinds+1,x
	pha
	lda Kinds,x
	pha
	lda value
	rts
Kinds:	.addr prNil-1,prInt-1,prBool-1,prSlot-1,prSpeed-1,prColor-1,prRAM32-1
	.addr prParity-1,prBits-1,prBaud-1,prDevice-1,prLineLen-1,prDateFmt-1
	.addr prLang-1,prRepSpd-1,prRepDly-1,prBootSl-1
;
prNil:	rts
;
prLang:
	pha
	jsr prInt
	jsr xmess
	asc "  "
	.byte 0
	pla
	asl a
	tax
	lda KLangTbl,x
	tay
	lda KLangTbl+1,x
	ldx #0
	jmp print_ay
;
KLangTbl:
	.addr L00,L01,L02,L03,L04,L05,L06,L07,L08,L09
	.addr L10,L11,L12,L13,L14,L15,L16,L17,L18,L19
	.addr L20,L21,L22,L23,L24,L25,L26,L27,L28,L29
	.addr L30,L31,Linval
L00:	pstr "English (U.S.A.)"
L01:	pstr "English (U.K.)"
L02:	pstr "French"
L03:	pstr "Danish"
L04:	pstr "Spanish"
L05:	pstr "Italian"
L06:	pstr "German"
L07:	pstr "Swedish"
L08:	pstr "Dvorak"
L09:	pstr "French Canadian"
L10:	pstr "Flemish"
L11:	pstr "Hebrew"
L12:	pstr "Japanese"
L13:	pstr "Arabic"
L14:	pstr "Greek"
L15:	pstr "Turkish"
L16:	pstr "Finnish"
L17:	pstr "Portuguese"
L18:	pstr "Tamil"
L19:	pstr "Hindi"
L20:	pstr "T1"
L21:	pstr "T2"
L22:	pstr "T3"
L23:	pstr "T4"
L24:	pstr "T5"
L25:	pstr "T6"
L26:	pstr "L1"
L27:	pstr "L2"
L28:	pstr "L3"
L29:	pstr "L4"
L30:	pstr "L5"
L31:	pstr "L6"
Linval:	pstr "???"
;
prDateFmt:
	beq prdMDY
	cmp #1
	beq prdDMY
	cmp #2
	beq prdYMD
inval:	jsr xmess
	asc "invalid setting"
	.byte 0
	rts
prdMDY:	jsr xmess
	asc "MM/DD/YY"
	.byte 0
	rts
prdDMY:	jsr xmess
	asc "DD/MM/YY"
	.byte 0
	rts
prdYMD:	jsr xmess
	asc "YY/MM/DD"
	.byte 0
	rts
;
prParity:
	beq prpOdd
	cmp #1
	beq prpEven
	cmp #2
	bne inval
	jsr xmess
	asc "none"
	.byte 0
	rts
prpEven:	jsr xmess
	asc "even"
	.byte 0
	rts
prpOdd:	jsr xmess
	asc "odd"
	.byte 0
	rts
;
prBits:
	cmp #8
	bcs inval
	pha
	lsr a
	clc
	adc #5
	ora #_'0'
	jsr cout
	lda #_'/'
	jsr cout
	pla
	and #1
	clc
	adc #1
	ora #_'0'
	jmp cout
;
prBaud:
	cmp #15
	bcs invalb
	asl a
	tax
	lda BaudTbl,x
	tay
	lda BaudTbl+1,x
	jmp xprdec_2
invalb:	jmp inval
;
BaudTbl:	.addr 50,75,110,134,150,300,600,1200,1800
	.addr 2400,3600,4800,7200,9600,19200
;
prRepSpd:
	pha
	jsr prInt
	jsr xmess
	asc "  = "
	.byte 0
	pla
	tax
	lda RepSpeeds,x
	jsr prInt
	jsr xmess
	asc " chars/sec"
	.byte 0
	rts
;
RepSpeeds:
	.byte 4,8,11,15,20,24,30,40
;
prRepDly:
	pha
	jsr prInt
	jsr xmess
	asc "  = "
	.byte 0
	pla
	cmp #5
	bcc delayok
	lda #5
delayok:	asl a
	tax
	lda DelayTbl,x
	tay
	lda DelayTbl+1,x
	ldx #0
	jmp print_ay
;
DelayTbl:
	.addr Del0,Del1,Del2,Del3,Del4,DelInv
Del0:	pstr ".25 sec"
Del1:	pstr ".50 sec"
Del2:	pstr ".75 sec"
Del3:	pstr "1 sec"
Del4:	pstr "no repeat"
DelInv:	pstr "???"
;
prDevice:
	bne devMod
	jsr xmess
	asc "printer"
	.byte 0
	rts
devMod:	jsr xmess
	asc "modem"
	.byte 0
	rts
;
prLineLen:
	tax
	beq unlim
	lda LengthTable,x
	tay
	lda #0
	jmp xprdec_2
LengthTable:
	.byte 0,40,72,80,132
unlim:	jsr xmess
	asc "unlimited"
	.byte 0
	rts
;
prBootSl:
	pha
	jsr prInt
	pla
	cmp #0
	beq bs_scan
	cmp #8
	beq bs_ramd
	cmp #9
	beq bs_romd
	rts
bs_scan:	jsr xmess
	asc " = scan"
	.byte 0
	rts
bs_ramd:	jsr xmess
	asc " = RAM disk"
	.byte 0
	rts
bs_romd:	jsr xmess
	asc " = ROM disk"
	.byte 0
	rts
;
prInt:
	tay
	lda #0
	jmp xprdec_2
;
prBool:
	bne BoolYes
	jsr xmess
	asc "no"
	.byte 0
	rts
BoolYes:	jsr xmess
	asc "yes"
	.byte 0
	rts
;
prSlot:
	bne slExt
	jsr xmess
	asc "internal"
	.byte 0
	rts
slExt:	jsr xmess
	asc "your card"
	.byte 0
	rts
;
prSpeed:
	bne pFast
	jsr xmess
	asc "slow"
	.byte 0
	rts
pFast:	jsr xmess
	asc "fast"
	.byte 0
	rts
;
prColor:
	pha
	cmp #10
	bcs ColNoSp
	lda #_' '
	jsr cout
ColNoSp:	pla
	pha
	jsr prInt
	lda #_' '
	jsr cout
	jsr cout
	pla
	cmp #$10
	bcc goodcolor
	lda #$10
goodcolor:
	asl a
	tax
	lda ColorTbl,x
	tay
	lda ColorTbl+1,x
	ldx #0
	jmp print_ay
;
ColorTbl:
	.addr cBlack,cDeepRed,cDarkBlue,cPurple
	.addr cDarkGreen,cDarkGray,cMedBlue,cLightBlue
	.addr cBrown,cOrange,cLightGray,cPink
	.addr cLightGreen,cYellow,cAquamarine,cWhite
	.addr cInvalid
;
cBlack:	pstr "black"
cDeepRed:
	pstr "deep red"
cDarkBlue:
	pstr "dark blue"
cPurple:	pstr "purple"
cDarkGreen:
	pstr "dark green"
cDarkGray:
	pstr "dark gray"
cMedBlue:
	pstr "medium blue"
cLightBlue:
	pstr "light blue"
cBrown:	pstr "brown"
cOrange:	pstr "orange"
cLightGray:
	pstr "light gray"
cPink:	pstr "pink"
cLightGreen:
	pstr "light green"
cYellow:	pstr "yellow"
cAquamarine:
	pstr "aquamarine"
cWhite:	pstr "white"
cInvalid:
	pstr "invalid color"
;
prRAM32:
	ldx #0
	stx myTemp
	ldx #5
mult32:	asl a
	rol myTemp
	dex
	bne mult32
	tay
	lda myTemp
	jsr xprdec_2	;AX=2-byte #
	lda #_'K'
	jmp cout
;*********************************************
;
; 65816 stuff
;
xce	= $fb
rep	= $c2
pea	= $f4
jsl	= $22
tool	= $e100
;*********************************************
;
; WriteBram -- A=byte, X=parameter #
;
WriteBram:
	sta pagebuff,x
	clc
	.byte xce,rep,$30
	and #$ff
	.byte 0
	pha
	txa
	and #$ff
	.byte 0
	pha
	ldx #$03
	.byte $0b
	.addr jsl,tool
	sta myErrcode
	ror error
	sec
	.byte xce
	bit error
	bpl noerr
is_err:	lda #0
	sec
	rts
noerr:	clc
	rts
;
WriteAX:	jsr WriteBram
	bcs writax
	jsr MakeCurrent
	clc
	rts
writax:	jsr xmess
	asc "*** Unable to write battery RAM: $"
	.byte 0
	lda myErrcode+1
	jsr prbyte
	lda myErrcode
	jsr prbyte
	jsr crout
	jmp xerr
;*********************************************
;
; ReadBram -- input  X=parameter #;
;             output A=byte
;
ReadBram:
	lda pagebuff,x
	clc
	rts
;
; Write all battery RAM from Pagebuff
;
WriteAllBram:
	clc
	.byte xce
	.byte rep,$30
	.byte pea,0,0,pea
	.addr pagebuff
	ldx #$03
	.byte $09
	.addr jsl,tool
	sta myErrcode
	ror error
	sec
	.byte xce
	bit error
	bmi is_err
	clc
	rts
;
; Read all battery RAM to Pagebuff
;
ReadAllBram:
	clc
	.byte xce
	.byte rep,$30
	.byte pea,0,0,pea
	.addr pagebuff
	ldx #$03
	.byte $0a
	.addr jsl,tool
	sta myErrcode
	ror error
	sec
	.byte xce
	bit error
	bmi is_errz
	clc
	rts
is_errz:	jmp is_err
;
; MakeCurrent -- set up the system according
;                to the battery RAM
;
MakeCurrent:
	clc
	.byte xce
; call TOBRAMSETUP in SEP #$30 mode!
	sec	;do NOT set int/ext slots
	.byte $22,$94,$00,$e1 ;JSL TOBRAMSETUP
	sec
	.byte xce
	clc
	rts
;*********************************************
;*********************************************
PrntTable:
	.addr DisplayParms,AudioParms,SlotParms,OptionParms
	.addr ClockParms,RAMparms,PrinterParms,ModemParms
	.addr FastParms,MiscParms,0
;
DisplayParms:
	.addr sColor,$18+tBOOL
	.addr s80,$19+tBOOL
	.addr sTextCol,$1a+tCOLOR
	.addr sBackCol,$1b+tCOLOR
	.addr sBordCol,$1c+tCOLOR
	.addr 0,0
;
AudioParms:
	.addr sVolume,$1e+tINT1
	.addr sPitch,$1f+tINT1
	.addr 0,0
;
SlotParms:
	.addr sSlot1,$21+tSLOT
	.addr sSlot2,$22+tSLOT
	.addr sSlot3,$23+tSLOT
	.addr sSlot4,$24+tSLOT
	.addr sSlot5,$25+tSLOT
	.addr sSlot6,$26+tSLOT
	.addr sSlot7,$27+tSLOT
	.addr sStart,$28+tBOOTSL
	.addr 0,0
;
OptionParms:
	.addr sTextLang,$29+tLANG
	.addr sKbdLang,$2a+tLANG
	.addr sKbdBuff,$2b+tBOOL
	.addr sRepSpeed,$2c+tREPSPD
	.addr sRepDelay,$2d+tREPDLY
	.addr sDblClick,$2e+tINT1
	.addr sFlashRate,$2f+tINT1
	.addr sCapsLC,$30+tBOOL
	.addr sFastSD,$31+tBOOL
	.addr sDualSp,$32+tBOOL
	.addr sFastMouse,$33+tBOOL
	.addr 0,0
;
RAMparms:
	.addr sMinRam,$36+tRAM32
	.addr sMaxRam,$37+tRAM32
	.addr 0,0
;
ClockParms:
	.addr sDateFmt,$34+tDATEFMT
	.addr sTimeFmt,$35+tBOOL
	.addr 0,0
;
FastParms:
	.addr sSpeed,$20+tSPEED
	.addr 0,0
;
MiscParms:
	.addr sAtlkNode,$80+tINT1
	.addr 0,0
;
; parm table for printer port
;
PrinterParms:
	.addr sDevice,$00+tDEVICE
	.addr sLineLen,$01+tLINELEN
	.addr sDelLF,$02+tBOOL
	.addr sAddLF,$03+tBOOL
	.addr sEcho,$04+tBOOL
	.addr sBuffer,$05+tBOOL
	.addr sBaud,$06+tBAUD
	.addr sBits,$07+tBITS
	.addr sParity,$08+tPARITY
	.addr sDCDhs,$09+tBOOL
	.addr sDSRhs,$0A+tBOOL
	.addr sXOFFhs,$0B+tBOOL
	.addr 0,0
;
; Modem parameters
;
ModemParms:
	.addr sDevice,$0C+tDEVICE
	.addr sLineLen,$0D+tLINELEN
	.addr sDelLF,$0E+tBOOL
	.addr sAddLF,$0F+tBOOL
	.addr sEcho,$10+tBOOL
	.addr sBuffer,$11+tBOOL
	.addr sBaud,$12+tBAUD
	.addr sBits,$13+tBITS
	.addr sParity,$14+tPARITY
	.addr sDCDhs,$15+tBOOL
	.addr sDSRhs,$16+tBOOL
	.addr sXOFFhs,$17+tBOOL
	.addr 0,0
;
; printer/modem strings
;
sDevice:	pstr "device connected"
sLineLen:	pstr "line length"
sDelLF:	pstr "delete 1 LF after CR"
sAddLF:	pstr "add 1 LF after CR"
sEcho:	pstr "echo"
sBuffer:	pstr "buffer"
sBaud:	pstr "baud rate"
sBits:	pstr "data/stop bits"
sParity:	pstr "parity"
sDCDhs:	pstr "DCD handshake"
sDSRhs:	pstr "DSR/DTR handshake"
sXOFFhs:	pstr "X-ON/X-OFF handshake"
;*********************************************
sColor:	pstr "monochrome display"
s80:	pstr "80 columns"
sTextCol:	pstr "text color"
sBackCol:	pstr "background color"
sBordCol:	pstr "border color"
sVolume:	pstr "volume"
sPitch:	pstr "pitch"
sSpeed:	pstr "system speed"
sSlot:	pstr "slot"
sStart:	pstr "boot slot"
sSlot1:	pstr "slot 1 {printer  }"
sSlot2:	pstr "slot 2 {modem    }"
sSlot3:	pstr "slot 3 {display  }"
sSlot4:	pstr "slot 4 {mouse    }"
sSlot5:	pstr "slot 5 {SmartPort}"
sSlot6:	pstr "slot 6 {disk port}"
sSlot7:	pstr "slot 7 {AppleTalk}"
sTextLang:	pstr "text display language"
sKbdLang:	pstr "keyboard language"
sKbdBuff:	pstr "keyboard buffering"
sRepSpeed:	pstr "repeat speed"
sRepDelay:	pstr "repeat delay"
sDblClick:	pstr "double click time"
sFlashRate:	pstr "cursor flash rate"
sCapsLC:	pstr "Shift+caps=LC"
sFastSD:	pstr "Fast space/delete"
sDualSp:	pstr "dual speed keys"
sFastMouse:	pstr "high speed mouse"
sMinRam:	pstr "minimum RAMdisk size"
sMaxRam:	pstr "maximum RAMdisk size"
sAtlkNode:	pstr "AppleTalk node #"
sDateFmt:	pstr "date format"
sTimeFmt:	pstr "24 hour format"
;***********************************************
ParseDispTbl:
	asc "tx"
	.byte $1a,15	;text color
	.addr ParseInt
	asc "bk"
	.byte $1b,15	;backgr color
	.addr ParseInt
	asc "bd"
	.byte $1c,15	;border color
	.addr ParseInt
	asc "80"
	.byte $19,0	;80 col
	.addr ParseYN
	asc "m"
	.byte 0,$18,0	;monocolor monitor
	.addr ParseYN
	.byte 0,0
;
ParseOpTbl:
	asc "tl"
	.byte $29,31	;text language
	.addr ParseTLang
	asc "kl"
	.byte $2a,31	;kbd language
	.addr ParseKLang
	asc "kb"
	.byte $2b,0	;kbd buffering
	.addr ParseYN
	asc "rs"
	.byte $2c,7	;rep speed
	.addr ParseInt
	asc "rd"
	.byte $2d,4	;rep delay
	.addr ParseInt
	asc "dc"
	.byte $2e,4	;double click
	.addr ParseInt
	asc "fr"
	.byte $2f,4	;flash rate
	.addr ParseInt
	asc "cs"
	.byte $30,0	;caps+shift=lc
	.addr ParseYN
	asc "fs"
	.byte $31,0	;fast space/del
	.addr ParseYN
	asc "ds"
	.byte $32,0	;dual-speed keys
	.addr ParseYN
	asc "hm"
	.byte $33,0	;high-spd mouse
	.addr ParseYN
	.byte 0,0
;
; parm table for printer port
;
ParsePrinterTbl:
	asc "dv"
	.byte $00,0	;device
	.addr ParseDev
	asc "l"
	.byte 0,$01,254	;line length
	.addr ParseLength
	asc "dl"
	.byte $02,0	;delete LF
	.addr ParseYN
	asc "al"
	.byte $03,0	;add LF
	.addr ParseYN
	asc "e"
	.byte 0,$04,0	;echo
	.addr ParseYN
	asc "bf"
	.byte $05,0
	.addr ParseYN
	asc "br"
	.byte $06,14
	.addr ParseBaud
	asc "ds"
	.byte $07,0
	.addr ParseBits
	asc "p"
	.byte 0,$08,0
	.addr ParseParity
	asc "ch"
	.byte $09,0
	.addr ParseYN
	asc "dh"
	.byte $0a,0
	.addr ParseYN
	asc "xh"
	.byte $0b,0
	.addr ParseYN
	.byte 0,0
;
; Parse table for modem port
;
ParseModemTbl:
	asc "dv"
	.byte $0c,0	;device
	.addr ParseDev
	asc "l"
	.byte 0,$0d,254	;line length
	.addr ParseLength
	asc "dl"
	.byte $0e,0	;delete LF
	.addr ParseYN
	asc "al"
	.byte $0f,0	;add LF
	.addr ParseYN
	asc "e"
	.byte 0,$10,0	;echo
	.addr ParseYN
	asc "bf"
	.byte $11,0
	.addr ParseYN
	asc "br"
	.byte $12,14
	.addr ParseBaud
	asc "ds"
	.byte $13,0
	.addr ParseBits
	asc "p"
	.byte 0,$14,0
	.addr ParseParity
	asc "ch"
	.byte $15,0
	.addr ParseYN
	asc "dh" 
	.byte $16,0
	.addr ParseYN
	asc "xh"
	.byte $17,0
	.addr ParseYN
	.byte 0,0
;***********************************************
