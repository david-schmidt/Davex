;*********************************************
;
; External command for DAVEX
;
; Park -- Park Sider heads
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"


.segment	"CODE_A000"

	
orgadr	= $A000
; org orgadr

myversion	= $10
minversion	= $10
;*********************************************
	rts
	.byte $ee,$ee
	.byte myversion,minversion
	.byte %00000000	;hardware req
	.addr descr
	.addr orgadr
	.addr start
	.byte 0,0,0,0
; parameters here
	.byte 0,0
descr:	pstr "park Sider heads--based on a program by Jim Thompson"
;*********************************************
; dsect
; org xczpage ;32 locations
; dend
;
start	= *
	
;
; modified for ProDOS EDASM by Dave Lyons 19-Oct-85
;
;*******************************
;                              *
;        Park.System           *
;                              *
;         10/05/85             *
;                              *
;            by                *
;                              *
;       Jim Thompson           *
;        70346,104             *
;                              *
;*******************************
;
; Copyright 1985 By JET AeroWorks
;                   Mesa, Arizona 85203
;
; All Rights Reserved.
; Non-Commercial use and distribution is authorized.
;
; What this means folks, is: use it and have fun, but don't sell
; it.  Leave the notice in.  Life doesn't have that much glory.
;
;******************************************************************
;
;     Equates
;
Base_Add	= $0000
Dos_Hook	= $03D0
Slot_Bas	= $0478
Slot	= $07F8
Rom_On	= $C000
DEntry	= $C806
EEntry	= $C824
Roms_Off	= $CFFF
;Cout = $FDED
;
;    End Equates
Entry:	CLD	; Required by ProDos System programs.
Hst_Chk:	lda #0	; Set up to page through slot Proms.
	sta Base_Add
	LDA #$C8	; Check slots from high to low.
	STA Base_Add+1	; Set for Indirect addressing.
Hst_Ck1:	DEC Base_Add+1	; It's not in that slot.
	LDA Base_Add+1
	CMP #$C0	; All slots checked?
	BEQ Hst_Ck3	; Yep, and we didn't find it.
	LDY #$00	; Indexed Indirected addressing
Hst_Ck2:	LDA (Base_Add),Y	; Get byte from slot Prom.
	CMP Rom_IDs,Y	; Check it against Host Adapter bytes.
	BNE Hst_Ck1	; Well, that didn't match
	INY	; That one did, go check another.
	CPY #$0E	; All bytes checked?
	BNE Hst_Ck2	; Nope, check some more.
	LDA Base_Add+1	; Get hi byte of slot we found it in.
	STA Slot_Cn+2	; Modify the code later in program.
	sta Slot	; store $Cn at $07F8 [Dave Lyons 3-Apr-88]
	AND #%00000111	; Mask off 'C' of $Cn.
; STA Slot        ; Save it in form $0n.
	TAX
	ASL A
	ASL A
	ASL A
	ASL A	; Shifted into form $n0.
	STA Slot_Bas,X	; Save it in slot base address.
	CLC
	BCC Got_Hst	; Go setup to park the drives.
Hst_Ck3	= *
	JSR Prt_Out	; Output the following message.
	.byte $8d,$8d	; Two carriage returns.
	asc "No Sider interface found"
	.byte $8d,$8d,$00	; Two carriage returns and a null.
Exit:	rts
;JMP Dos_Hook    ; All done, either way, so go on back.
Got_Hst	= *	; Sider.LUN = Logical Unit No.
	pha
	lda #0
	sta Sidr_LUN
	pla
	JSR Park_It	; Go do it.
	BCS Sider_2	; No Sider 1,go check on second Sider.
	JSR Prt_Out	; Output the following message.
	.byte $8d
	asc "Sider 1 Heads are parked."
	.byte $8d
	.byte 00	; A null
Sider_2:	LDA #%00100000	; Bit 5 tells Controller to check
	STA Sidr_LUN	;  Logical Unit No 1. Sider 1 = LUN 0
	JSR Park_It	; Go do it.  Sider 2 = LUN 1.
	BCS Exit	; No second Sider.
	JSR Prt_Out	; Output the following message.
	.byte $8d
	asc "Sider 2 Heads are parked."
	.byte $8d,$00
	JMP Exit	; That's all folks.
Prt_Out:	PLA	; Save return address.
	STA Base_Add	;  here.
	PLA	; High byte of return address
	STA Base_Add+1	;  here.
	LDY #$00	; Set for indexed indirect addressing.
	INC Base_Add	; Point to first character of message.
	BNE Prt_Out1	; Check for page boundary crossing.
	INC Base_Add+1	; Bump high byte one if we do.
Prt_Out1:	LDA (Base_Add),Y	; Get character of message.
	BEQ Prt_Out2	; Check for ending null in message
	JSR cout	; Use monitor routine to send it out.
	INC Base_Add
	BNE Prt_Out1	; Go back for more, if no wraparound.
	INC Base_Add+1	; Bump high byte one if we do.
	JMP Prt_Out1	; Could have used BNE,but mesg not big
Prt_Out2:	LDA Base_Add+1	; Get high byte and set up
	PHA	;  return address.
	LDA Base_Add	; Get low byte of
	PHA	; return address.
	RTS	; return to whence we were called.
Park_It:	JSR Init_Drv	; Go read and init the Sider drive
	BCC Init_OK	; Drive has been set up & initialized.
	RTS	; No drive present or bad set up.
Init_OK:	LDA #$0B	; Seek command to Xebec controller.
	STA Seek_DCB	; Seek.DCB is Data Control Block for
	lda #0
	STA Seek_DCB+1	;  command as defined in S1410A owners
	STA Seek_DCB+2	;  manual referred to in Sider Owner's
	STA Seek_DCB+3	;  manual.
	STA Seek_DCB+4	; These four STZ's init some of DCB.
	LDX Paramtrs+27	; Page 142 of new Sider manual calls
;bytes 25 - 32, Sider characteristics.  Byte 27 is the number of
;heads in the drive. In our case this is = $04.
;
Loop1:	CLC	; Set up for loop type addition.
	LDA Paramtrs+26	; Byte 26 is the LSB of number of
	ADC Seek_DCB+3	; Cylinders (in HEX). In our case $32.
	STA Seek_DCB+3	; Save it.
	LDA Paramtrs+25	; Byte 25 is the 
	ADC Seek_DCB+2	; Cylinders. In our case $01.
	STA Seek_DCB+2	; Save it.Note: $0132 = 306 (base 10)
	LDA #$00	;
	ADC Seek_DCB+1	; Ensures that if we have a carry it
	STA Seek_DCB+1	; is added to the result.
	DEX	;
	BNE Loop1
;
;The sequence of instructions, 124 to 135, execute a loop type
;addition four times.  The end result is the number of cylinders
;converted to the number of tracks on the drive.  Each head can
;read or write 1 track per cylinder. So if there are 4 heads per
;cylinder and 306 cylinders, then there must be 1224 tracks.
;NOTE: it is important to remember that the counting begins with
;1 .not. 0, as you would expect.  306 cylinders starts at 1  for
;reference.  Further, the convention in storing the Sider
;characteristics on the drive is that for two byte values, the
;MSB is stored first.  Reverse of what we normally do.
;Bytes 25-26: 01 32.  The next series of instructions subtract
;1 from the total number of tracks, so counting now begins at 0.
;
	SEC	; Set up for subtraction.
	LDA Seek_DCB+3	; Get LSB.
	SBC #$01	; Now we're counting from zero.
	STA Seek_DCB+3
	LDA Seek_DCB+2	; Get middle byte
	SBC #$00	; We're not subtracting anything,
	STA Seek_DCB+2	; But ensuring the 'Carry' bits are
	LDA Seek_DCB+1	; Straight.
	SBC #$00
	STA Seek_DCB+1	; Now everything is OK.
;
;The variables Seek.DCB+1, Seek.DCB+2, and Seek.DCB+3 make up a
;three byte address in the Data Control Block.
;
;A clarifying point here:  The controller for the disk is
;actually in the box containing the Drive itself.  The card in
;our Apple is just an adapter that allows us to communicate with
;the disk controller.  The controller takes care of transferring
;the data to and from the Host adapter.  The controller can
;manage vitually any size disk.  That's not precisely true, but
;for anything we are going to do, it can be treated as true.
;Consequently, this software will function for either the 10 or
;20 mB Sider.  As long as First Class doesn't change were they
;keep the characteristics stored on the disk.
;
;The disk is addressed through the controller by .Sectors. not
;tracks or bytes.  So we must convert the total number of tracks
;to the total number of sectors and store them in a three byte
;address field.  So, $0132 * $04 * $20 = $9900.  Remember, there
;are 32 sectors per track, hence the $20.  But, why three bytes?
;Well, the controller is set up to handle $1F FF FF number of
;sectors, that's 2,097,151 in base ten.  Or a bit over
;53 mBytes if you prefer.  Consquently, the format of the
;Data Control Block is fixed to handle this.  The complete
;format of the DCB is explained later.
;
;The next series of instructions execute a 3 byte multiply five
;times.  It takes the total number of tracks and multiplies by
;32 ($20), recall that 2 to the fifth power is 32.  That's why
;it goes through the sequence 5 times.
;
	LDX #$04	; Set up for 5 multiplies.
Loop2:	ASL Seek_DCB+3	; First byte times 2.
	ROL Seek_DCB+2	; Second byte. Reason for ROL is so
	ROL Seek_DCB+1	; Third byte.  we can keep track of
	DEX	;             shifts into the carry bit.
	BPL Loop2	; Keep going until done 5 times.
;
;This next part 'OR''s in the Logical Unit Number of the Sider
;we want to address.  In the High byte of the address only
;BITS 4 - 0 are used in the sector addressing.  That's why the
;$1F maximum part of the address.  See the end of the program
;complete description and explanation of the DCB.
;
	LDA Seek_DCB+1	; Get high byte.
	ORA Sidr_LUN	; 'OR''s in either a %0000 0000
	STA Seek_DCB+1	; or %0010 0000. Now save it.
	LDA #<Seek_DCB	; As noted in SDRIVER vector
	LDY #>Seek_DCB	; explantion on page 139 of the Sider
	JSR T_DEntry	; manual.  Now go park the drives.
	RTS	; That's all there is to parking.
;
;This next section reads the first sector of the drive and gets
;all the characteristics and stuff.  Then it initializes the
;Disk Controller with the information so it can handle what we
;tell it to do.
;
Init_Drv:	LDA Sidr_LUN	; Get drive we're suppose to init.
	STA DCB+1	; This is the primary DCB.
	STA Init_DCB+1	; This is the one we use for init.
	LDA #<DCB	; As mentioned before.
	LDY #>DCB	;   as before.
	JSR T_DEntry	; Go read Sector 1 to get Parameters
	BCC Read_OK	; No problem in reading.
	LDY Sidr_LUN	; We had a problem in reading, see if
	JSR T_EEntry	; it's a correctable read error.
	BCC Read_OK	; Yep, it is. So we coninue.
Cant_Fix:	RTS	; Can't fix. Drive may be OFF or not there.
Read_OK:	LDA #<Init_DCB	; Get set to initialize the drive.
	LDY #>Init_DCB	;   as before.
	JSR T_DEntry	; Go Init the Disk Controller.
	BCC OK_Init	; That went fine.
	LDY Sidr_LUN	; No it didn't, see if it can be fixed.
	JSR T_EEntry	; Can it be fixed?
	BCS Cant_Fix	; Nope,  @#$%^#$@#^@^*&@^
OK_Init:	LDA Paramtrs+33	; Get Sider Step Option
	STA DCB+5	; This is a $07.
	CLC	; Everything is fine and dandy.
	RTS	; Go on back.
;
;This next sequence is the actual vectors to DENTRY and EENTRY
;as noted on page 136 of the Sider manual.
;
T_DEntry:	LDX Roms_Off	; Turns off all Slot Proms.
Slot_Cn:	LDX Rom_On	; Turns on Host Adapter, moded to CN.
	JSR DEntry	; Vector to the Controller.
	RTS	;
;
T_EEntry:	LDA #<Err_Buff	; Error buffer, 12 bytes total
	LDX #>Err_Buff	;  last 4 are Sense Status bytes.
	JSR EEntry	; Vector to the Controller.
	BCS Bad_Err	; Something is big time wrong.
	LDA Sen_Stat	; 1st byte of Sense Status is what we
	AND #%01111111	; check.  Mask off Bit 7, don't need.
	CMP #$18	; Is it a Correctable read error?
	BEQ OK_Error	; Yep, so no big deal.
	SEC	; Wasn't a correctable read error.
	RTS	; Head on back
OK_Error:	CLC	; Indicate no error.
Bad_Err:	RTS	; Either OK or Carry already set

;** PAGE
;
;The following are three Data Control Blocks.  Only one was
;really necessary, but, individual ones were used for clarity.
;A DCB is made up of a contiguous sequence of 6 bytes for the
;Disk Controller.  The Host Adapter Prom requires that we add
;the address of the buffer which contains or will contain the
;data going to or coming from the Disk Controller.  This makes
;up a total of eight bytes in the DCB.
;
;First Class Peripherals has their driver software only transfer
;one 256 byte sector at a time.  However, you can indicate a
;multi-sector transfer of almost any amount.  The driver
;software does have to be smarter in order to handle
;read/write errors that may occur part way through a
;multi-sector transfer.  For most of what We do, the speed or
;efficiency gained in a multi-sector transfer is not necessary.
;
;A Data Control Block looks like this:
;
;        Bit   7   6   5   4   3   2   1   0
;            ---------------------------------
;   Byte 0  | Cmd Class   |    Opcode        |
;            ---------------------------------
;   Byte 1  | /    /  LUN |   High Address   |
;            ---------------------------------
;   Byte 2  |       Middle  Address          |
;            ---------------------------------
;   Byte 3  |         Low   Address          |
;            ---------------------------------
;   Byte 4  |       Sector  Count            |
;            ---------------------------------
;   Byte 5  |         Step  Option           |
;            ---------------------------------
;   Byte 6  |     Buffer Low Address         |
;            ---------------------------------
;   Byte 7  |     Buffer High Address        |
;            ---------------------------------
;
;Byte 0 is the Opcode that goes to the Disk Controller.
;Command code is not used for our application, so Bits 7 -5 are
;always 0's.  Bits 4 - 0 are used for the actual commands or
;Disk Controller opcodes.  These are such things as: 8 - Read,
;A - Write, C - Initialize Drive, etc.  We use Seek to park the
;heads.  In other words we tell it to GOTO or Seek a particular
;sector in order to park it.
;
;Byte 1 contains the Logical Unit Number and High Address
;information. Bits 7 and 6 are not used, so for convention make
;them 0's.  Bit 5 is used to indicate which of two drives the
;opcode should go to.  The Xebec Disk Controller can directly
;manage 2 drives.  A '0' in Bit 5 means our first Sider, a '1'
;means the second one.  This leaves Bits 4 - 0 that can be used
;for the High Sector Address.
;That's how we get $1F as the highest possible part of our
;address.  For single 10 mByte Sider operation, this address
;part will, after calculation, always be 0's.  The maximum
;number of sectors on a single 10 mB Sider is 1224 * 32 = 39,168
;or $9900. For a single 20 mB Sider this = 78,336 or $13200.
;So the High Address only comes into play if we have a 20 mB
;Sider.  BUT IT MUST BE ALLOWED FOR IN ALL CALCULATIONS;
;SO DON'T TRY TO SHORTCUT IT.
;
;Bytes 2 and 3 are the remaining part of the Sector Address.
;If you would want to read Sector 1 on Sider 1, then bytes 1 - 3
;would be: 00 00 01.
;
;Byte 4 is the number of Sectors to be transferred, one way or
;the other.  Some commands, like Seek, don't transfer data and
;consequently don't use this byte. HOWEVER, IT MUST BE INCLUDED.
;So make it a '0' for conventions sake.  Actually, the Disk
;Controller doesn't care whats in the byte, IF IT DOESN'T USE IT
;In the Sider manual this is reffered to as Block Count.  It is
;a 256 byte Block or sector not a 512 byte Block.
;PASCALer's take note.
;
;Byte 5 is called the Sider Step Option in the Sider Manual.
;However, this is actually a Control Field that can be used to
;control things like Retries on errors, Type of speed control
;that the Controller should use and lastly, the Step Option.
;For our implementation on the Apple computers we will only
;concern ourselves with the Step Option.
;The Step Option is identified during formatting of the drive
;and then must be used from then on.  My exact knowledge of the
;hardware breaks down at this point.  I'm not positive that the
;Step Option is as cast in concrete as it seems after
;formatting.  Using the supplied Sider software, this value is
;$07; which means a 15 micro-Second buffered step.  So, Byte 5
;is always a $07.
;
;Bytes 6 and 7 identify the location of the buffer to be used
;during data transfer.  The length of the buffer depends on the
;Opcode given it.  If the Opcode is a Read/Write (8/A) and the
;Sector count is 1, then the buffer length must be 256 bytes.
;If the Opcode is for requesting Sense Status, then only 12
;bytes are necessary for the buffer.  The last four of which are
;the actual Sense Status bytes.
;
;Credit for the above technical information is made to XEBEC
;Systems, Incorporated.  Specifically, the S1410A, 5.25 INCH
;WINCHESTER DISK CONTROLLER OWNER'S MANUAL.  Copyright Xebec
;Systems, Inc, 1984.
;
;To preclude any misunderstanding: I do not, nor have I ever,
;worked for Xebec or First Class Peripherals.  I am just a
;hobbiest and hacker.
;
;Finally, here is the final part of the program:
;
DCB:	.byte 08	; Initially set as a Read Opcode.
	.byte 0	; LUN/High Address.
	.byte 0	; Middle Address.
	.byte 1	; Low Address.
	.byte 1	; Sector Count, for us Always = '1'.
	.byte $07	; Sider Step Option, for us = $07.
	.addr Paramtrs	; Address of a 256 byte buffer.
Init_DCB:	.byte $0C	; Set as Init Drive Characteristics
	.byte 0	; LUN/High Address
	.byte 0	;
	.byte 0	;
	.byte 0	;
	.byte 0	;
	.addr Paramtrs+25	; Location of 8 byte buffer
;                              Containing Init information.
;                              See: page 142 of Sider Owner's
;                              Manual.
Seek_DCB:	.byte $0B	; Set as Seek Opcode.
	.byte 0	;
	.byte 0	;
	.byte 0	;
	.byte 1	;
	.byte $07	;
	.addr Paramtrs	; Not actually used by Seek command,
;                           but must be included.
Rom_IDs:	.byte $A9,$20,$A9,$00 ; First 14 .byte $values in Host adapter.
	.byte $A9,$03,$A9,$3C
	.byte $2C,$FF,$CF,$20
	.byte $0C,$C8
Sidr_LUN:	.res 1	; Sider Logical Unit Number
Err_Buff:	.res 8	; Error buffer used by EEntry, all 12
Sen_Stat:	.res 4	; bytes are used, we check last 4.
Paramtrs:	.res 256	; 256 byte buffer for reading in Sider
;                          Parameter Block.
