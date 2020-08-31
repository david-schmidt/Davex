;*********************************************
;*********************************************
;
; External command for Davex
;
; deschw -- describe hardware
;
; Options:
;   -t   system type
;   -c   cards
;   -s   SmartPort
;
; 15-Oct-89 DAL ==> v1.2
;   Changed "//" to "II"
;   Added IIc+ identification
;     & fixed mismatched parens
;   Added IIe debugger ROM id
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************

.segment	"CODE_9000"

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.Globals2.asm"
	.include "Common/Macros.asm"

OrgAdr	= $9000	;change as necessary (end below $B000)
.org	OrgAdr	; Makes the listing more readable, though it doesn't really org the code - the linker does that.

b_phy	= $5a
b_xce	= $fb
b_rep	= $c2
b_ldx	= $a2

;*********************************************
;
; SmartPort constants
;
sptSTATUS	= 0
sptREADBLK	= 1
sptWRITEBLK	= 2
sptFORMAT	= 3
sptCONTROL	= 4
sptINIT	= 5
sptOPEN	= 6
sptCLOSE	= 7
sptREAD	= 8
sptWRITE	= 9
;
;*********************************************
MyVersion	= $12
MinVersion	= $11
;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr OrgAdr
	.addr start
	.byte 0,0,0,0
; parameters here
	.byte $80+'t',t_nil
	.byte $80+'c',t_nil
	.byte $80+'s',t_nil
	.byte 0,0
descr:
	pstr "describe system hardware"

;*********************************************
; dum xczpage ;32 locations
slot	= xczpage	;ds.b 1
rom	= slot+1	;ds.b 2
Unit	= rom+2	;ds.b 1
scratch	= Unit+1	;ds.b 1
totalmem	= scratch+1	;ds.b 4
; dend
;
start:
	jsr xgetnump
	beq do_all
	lda #'t'+$80	;system Type
	jsr xgetparm_ch
	bcs no_type
	jsr my_crout
	jsr systemtype
no_type:	lda #'c'+$80	;Cards
	jsr xgetparm_ch
	bcs no_cards
	jsr my_crout
	jsr scanslots
no_cards:	lda #'s'+$80
	jsr xgetparm_ch
	bcs no_sp
	jsr my_crout
	jsr DescribeSP
no_sp:	rts
;
do_all:
	jsr systemtype
	jsr my_crout
	jsr scanslots
	jsr my_crout
	jsr DescribeSP
	jsr my_crout
	rts
;
systemtype:
	jsr xmess
	asc "System:  "
	.byte 0
	sec
	jsr idroutine
	bcc st_gs
	jmp IdentNotGS
;
st_gs:	jsr xmess
	asc "Apple IIgs, ROM version $"
	.byte 0
	clc
; [TODO] Use .p816
	.byte b_xce,b_rep,$30
	jsr idroutine
	.byte b_phy
	sec
	.byte b_xce
	pla
	jsr prbyte
	jsr xmess
	asc "  (Machine ID=$"
	.byte 0
	pla
	jsr prbyte
	jsr xmess
	asc ")"
	.byte 0
	jsr my_crout
	clc
	.byte b_xce
	.byte b_rep,$30
	pha
	pha
	.byte b_ldx
	.addr $1d02	;TotalMem
	.byte $22,0,0,$E1
	pla
	sta totalmem
	pla
	sta totalmem+2
	sec
	.byte b_xce
	jsr xmess
	asc "Total RAM = "
	.byte 0
	ldx #10
div1K:	lsr totalmem+3
	ror totalmem+2
	ror totalmem+1
	ror totalmem
	dex
	bne div1K
	lda totalmem+1
	ldy totalmem
	jsr xprdec_2
	jsr xmess
	asc "K"
	.byte cr,0
	rts
;
IdentNotGS:
	lda $fbb3
	cmp #$ea
	bne not_2p3
	lda $fb1e
	cmp #$ad
	beq TwoPlus
	cmp #$8a
	beq Three
unknown:	jsr xmess
	asc "???"
	.byte 0
	rts
TwoPlus:	jsr xmess
	asc "Apple ][+"
	.byte 0
	rts
Three:	jsr xmess
	asc "Apple /// (in emulation mode)"
	.byte 0
	rts
;
not_2p3:
	lda $fbb3
	cmp #$06
	bne unknown
	lda $fbc0
	cmp #$ea
	bne Not2e1
	jsr xmess
	asc "Apple IIe (unenhanced)"
	.byte 0
	rts
Not2e1:	cmp #$e0
	bne not2e2
	jsr xmess
	asc "Apple IIe (enhanced)"
	.byte 0
	rts
not2e2:
	cmp #$e1
	bne notDbgr
	jsr xmess
	asc "Apple IIe (special ROMs)"
	.byte 0
	rts
notDbgr:
	cmp #$00
	bne unkn0
; it's a IIc
	lda $fbbf
	cmp #5
	beq IIcPlus
	jsr xmess
	asc "Apple IIc, version "
	.byte 0
	lda $fbbf
	cmp #$ff
	beq TwoC1
	cmp #$00
	beq TwoC2
	cmp #$03
	beq TwoC3
	cmp #$04
	beq TwoC4
unkn0:	jmp unknown
IIcPlus:	jsr xmess
	asc "Apple IIc Plus"
	.byte 0
	rts
TwoC1:	jsr xmess
	asc "1"
	.byte 0
	rts
TwoC2:	jsr xmess
	asc "2: 3.5"
	.byte $a2
	asc " disk ROM"
	.byte 0
	rts
TwoC3:	jsr xmess
	asc "3: Memory Expandable"
	.byte 0
	rts
TwoC4:	jsr xmess
	asc "4: Revised Mem. Expandable"
	.byte 0
	rts

;****************************************************
scanslots:
	lda #1
	sta slot
ss1:	jsr scan1
	inc slot
	lda slot
	cmp #8
	bcc ss1
	rts
;
scan1:	jsr xmess
	asc "Slot "
	.byte 0
	lda slot
	ora #_'0'
	jsr cout
	jsr xmess
	asc ": "
	.byte 0
	lda slot
	ora #$c0
	sta rom+1
	lda #0
	sta rom
	jsr PrSlotDesc
	jsr my_crout
	jmp MaybeATLK

ATLKsig:	asc "ATLK"
	.byte 0
MaybeATLK:
	ldy #$F9	;check $CnF9
at_chk:	lda (rom),y
	cmp ATLKsig-$F9,y
	bne not_atlk
	iny
	cpy #$FE
	bcc at_chk
	jsr xmess
	asc "        AppleTalk card; version="
	.byte 0
	ldy #$fe
	lda (rom),y
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	jsr prnib
	lda #'.'+$80
	jsr cout
	pla
	jsr prnib
	ldy #$ff
	lda (rom),y
	jsr prbyte
	jmp my_crout
not_atlk:	rts
;
prnib:	and #$0F
	cmp #$0A
	bcc prn_dig
	adc #6
prn_dig:	adc #$B0
	jmp cout

SlotEmpty:	jsr xmess
	asc "empty"
	.byte 0
	rts

notPasc0:	jmp notPasc
PrSlotDesc:
	ldy slot
	lda bitpos,y
	and sltbyt
	beq SlotEmpty
	ldy #5
	lda (rom),y
	cmp #$38
	bne notPasc0
	ldy #7
	lda (rom),y
	cmp #$18
	bne notPasc0
	ldy #$b
	lda (rom),y
	cmp #$1
	bne notPasc0
	iny
	lda (rom),y
	pha
	jsr xmess
	asc "Pascal ID = $"
	.byte 0
	pla
	pha
	jsr prbyte
	jsr xmess
	asc ": "
	.byte 0
	pla
	lsr a
	lsr a
	lsr a
	lsr a
	asl a
	tax
	lda PascTbl+1,x
	pha
	lda PascTbl,x
	pha
	rts
PascTbl:
	.addr ps0-1,ps1-1,ps2-1,ps3-1,ps4-1,ps5-1,ps6-1,ps7-1
	.addr ps8-1,ps9-1,ps10-1,ps0-1,ps0-1,ps0-1,ps0-1,ps0-1
;
ps0:	jsr xmess
	asc "???"
	.byte 0
	rts
ps1:	jsr xmess
	asc "printer"
	.byte 0
	rts
ps2:	jsr xmess
	asc "joystick/mouse"
	.byte 0
	rts
ps3:	jsr xmess
	asc "serial or parallel card"
	.byte 0
	rts
ps4:	jsr xmess
	asc "modem"
	.byte 0
	rts
ps5:	jsr xmess
	asc "sound/speech device"
	.byte 0
	rts
ps6:	jsr xmess
	asc "clock"
	.byte 0
	rts
ps7:	jsr xmess
	asc "disk/storage device"
	.byte 0
	rts
ps8:	jsr xmess
	asc "80-column card"
	.byte 0
	rts
ps9:	jsr xmess
	asc "network/bus interface"
	.byte 0
	rts
ps10:	jsr xmess
	asc "other"
	.byte 0
	rts
;
notPasc:
	jsr chk_clock
	bcs chk_sp
	jsr xmess
	asc "ThunderClock/compatible"
	.byte 0
	rts
chk_sp:	jsr chk_smport
	bcs chkb
	jsr xmess
	asc "SmartPort"
	.byte 0
	rts
chkb:	jsr chk_blkdev
	bcs notblk
; Is it a Disk II?
	ldy #$ff
	lda (rom),y
	bne notDiskII
	jsr xmess
	asc "5.25"
	.byte $A2
	asc " disk drive"
	.byte 0
	rts
notDiskII:
	jsr xmess
	asc "ProDOS block device"
	.byte 0
	rts
notblk:	jsr xmess
	asc "unknown card"
	.byte 0
	rts
;
bitpos:
	.byte %00000001
	.byte %00000010
	.byte %00000100
	.byte %00001000
	.byte %00010000
	.byte %00100000
	.byte %01000000
	.byte %10000000
;
; If ROM at (rom) is a ProDOS-recognized clock card,
; return CLC
;
chk_clock:	ldy #0
	lda (rom),y
	cmp #$08
	bne chks_no
	ldy #2
	lda (rom),y
	cmp #$28
	bne chks_no
	ldy #4
	lda (rom),y
	cmp #$58
	bne chks_no
	ldy #6
	lda (rom),y
	cmp #$70
	bne chks_no
	clc
	rts
;
; If ROM at (rom) is for a SmartPort, return CLC
;
chk_smport:
	jsr chk_blkdev
	bcs chks_no
	ldy #7
	lda (rom),y
	bne chks_no
	clc
	rts
chks_no:	sec
	rts
;
; If ROM at (rom) is for a block device, return CLC
;
chk_blkdev:
	ldy #1
	lda (rom),y
	cmp #$20
	bne chkb_no
	ldy #3
	lda (rom),y
	bne chkb_no
	ldy #5
	lda (rom),y
	cmp #$03
	bne chkb_no
	clc
	rts
chkb_no:	sec
	rts
;
; DescribeSP -- show all SmartPort information
;
DescribeSP:	lda #1
	sta slot
	lda #0
	sta rom
desSp1:	lda slot
	ora #$c0
	sta rom+1
	jsr chk_smport
	bcs desNotSP
	jsr Descr1SP
desNotSP:	inc slot
	lda slot
	cmp #8
	bcc desSp1
	rts
;
Descr1SP:
	jsr xmess
	asc "SmartPort controller found in slot "
	.byte 0
	lda slot
	ora #_'0'
	jsr cout
	jsr xmess
	.byte _'.',cr,0
; find the entry point
	ldy #$ff
	lda (rom),y
	clc
	adc #3
	sta SpTrick+1
	lda rom+1
	sta SpTrick+2
;
	jsr SpStatus
	jsr EachStatus
	rts
;
; SpStatus -- get and print global status of a SmartPort chain
;
staterr:	jmp xProDOS_err
SpStatus:
	ldx #sptSTATUS
	lda #>GlobStat
	ldy #<GlobStat
	jsr CallSP
	bcs staterr
	jsr xmess
	asc "Number of devices: "
	.byte 0
	lda #0
	ldy NumDevs
	jsr xprdec_2
	jmp my_crout
;
GlobStat:	.byte 3,0
	.addr gstat2
	.byte 0	;statcode
gstat2:
NumDevs:	.byte 0,0,0,0,0,0,0,0
;
; EachStatus -- print stuff for every SmartPort device
;               in this chain
;
EachStatus:
	lda #1
	sta Unit
es1:	lda Unit
	cmp NumDevs
	beq es_go
	bcs es_done
es_go:	jsr StatOneUnit
	inc Unit
	jmp es1
es_done:	rts
;
StatOneUnit:
	jsr xmess
	asc "Unit #"
	.byte 0
	lda Unit
	sta UnitNum
	tay
	lda #0
	jsr xprdec_2
	jsr xmess
	asc ": "
	.byte 0
	ldx #sptSTATUS
	lda #>Stat1parms
	ldy #<Stat1parms
	jsr CallSP
	bcc statok
	jmp xProDOS_err
;
statok:
	lda StatByte
	jsr PrintStatByte
	jsr my_crout
;
	jsr xmess
	asc "         Blocks: "
	.byte 0
	lda NumBlocks+2
	ldx NumBlocks+1
	ldy NumBlocks
	sta xnum+2
	stx xnum+1
	sty xnum
	jsr xprdec_3
	jsr my_crout
;
	jsr xmess
	asc "         Device name: "
	.byte 0
	ldx #0
	ldy NameLen
prname1:	lda NameLen+1,x
	ora #$80
	jsr cout
	inx
	dey
	bne prname1
	jsr my_crout
;
	jsr PrintType
	jsr xmess
	asc ", subtype=$"
	.byte 0
	lda DevSubtype
	jsr prbyte
	jsr xmess
	asc ", version=$"
	.byte 0
	lda UnitVersion+1
	jsr prbyte
	lda UnitVersion
	jsr prbyte
	jmp my_crout
;
PrintType:
	jsr xmess
	asc "         Type = "
	.byte 0
	lda #0
	ldy DevType
	jsr xprdec_2
	jsr xmess
	asc " ("
	.byte 0
	jsr prtype2
	jsr xmess
	asc ")"
	.byte 0
	rts

prtype2:
	lda DevType
	cmp #$c
	bcc lessc
	lda #$c
lessc:	asl a
	tax
	lda spTypes+1,x
	pha
	lda spTypes,x
	pha
	rts
;
PrintStatByte:
	sta scratch
	jsr sb7
	jsr xmess
	asc ", "
	.byte 0
	asl scratch
	asl scratch
	jsr ChkNot
	jsr xmess
	asc "online, "
	.byte 0
	asl scratch
	jsr ChkNot
	jsr xmess
	asc "write protected"
	.byte 0
	rts
;
sb7:	asl scratch
	bcc chardev
	jsr xmess
	asc "block device"
	.byte 0
	rts
chardev:	jsr xmess
	asc "character device"
	.byte 0
	rts
;
ChkNot:	asl scratch
	bcs notz
	jsr xmess
	asc "not "
	.byte 0
notz:	rts
;
Stat1parms:
	.byte 3
UnitNum:	.byte 0
	.addr Stat2
	.byte 3
Stat2:
StatByte:	.byte 0
NumBlocks:	.byte 0,0,0
NameLen:	.byte 0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DevType:	.byte 0
DevSubtype:	.byte 0
UnitVersion:	.addr 0
;**********************************************************
CallSP:	stx spCmd
	sta spParms+1
	sty spParms
SpTrick:	jsr $0000
spCmd:	.byte 0
spParms:	.addr 0
	rts
;
;
spTypes:	.addr spt0-1,spt1-1,spt2-1,spt3-1,spt4-1,spt5-1,spt6-1,spt7-1
	.addr spt8-1,spt9-1,spt10-1,spt11-1,spt12-1
spt0:	jsr xmess
	asc "RAM disk"
	.byte 0
	rts
spt1:	jsr xmess
	asc "3.5"
	.byte $a2
	asc " disk"
	.byte 0
	rts
spt2:	jsr xmess
	asc "ProFile-type hard disk"
	.byte 0
	rts
spt3:	jsr xmess
	asc "generic SCSI"
	.byte 0
	rts
spt4:	jsr xmess
	asc "ROM disk"
	.byte 0
	rts
spt5:	jsr xmess
	asc "SCSI CD-ROM"
	.byte 0
	rts
spt6:	jsr xmess
	asc "SCSI Tape or other SCSI sequential"
	.byte 0
	rts
spt7:	jsr xmess
	asc "SCSI hard disk"
	.byte 0
	rts
spt8:	jsr xmess
	asc "???"
	.byte 0
	rts
spt9:	jsr xmess
	asc "SCSI printer"
	.byte 0
	rts
spt10:	jsr xmess
	asc "5.25"
	.byte $a2
	asc " disk"
	.byte 0
	rts
spt11:	jsr xmess
	asc "???"
	.byte 0
	rts
spt12:	jsr xmess
	asc "???"
	.byte 0
	rts
;
my_crout:	jsr xcheck_wait
;bcc fine
;jmp xerr
fine:	jmp crout
