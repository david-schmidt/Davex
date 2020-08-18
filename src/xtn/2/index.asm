;*********************************************
;*********************************************
;
; External command for Davex
;
; index -- build an indexed file
;
;*********************************************
; Options:
;   pathname
;   -s <size>: Create a new file with specified index size
;   -v name: View an entry from the file
;   -a filename: Add specified file to the indexed file
;   -e name: Add a 2nd name for the file being added
;
; With only a pathname specified, prints a list of all
; the items in the file.
;*********************************************
;
; Format of an indexed file is:
;
;   $00 DvxIdx $00
;   Offset_to_text  (4 bytes)
;   Offset_to_index (4 bytes)
;   Offset_to_free_index_space (4 bytes)
;
; Index is:
;   length-pfx'd string, offset(4), length(4)
;    :
;   $00
;
; Text chunks are terminated by a $00. The data
; is compressed, with 16 common characters using
; only 5 bits (%1xxxx), and the remaining ones
; using 8 bits (%0xxxxxxx).
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

OrgAdr	= $A000	;change as necessary (end below $B000)
; org OrgAdr

MyVersion	= $11
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
	.byte 0,t_path
	.byte $80+'s',t_int2	;create with this index Size
	.byte $80+'a',t_path	;add a file
	.byte $80+'e',t_string ;extra entry
	.byte $80+'v',t_string ;view what
	.byte 0,0
descr:	pstr "build an indexed file"
	
;*********************************************
; dum xczpage ;32 locations
path		= xczpage	;ds 2 ;index file
size		= path+2	;ds 2
fpath		= size+2	;ds 2 ;file being added
free_spc	= fpath+2	;ds 3 ;free index space
bits		= free_spc+3	;ds 1
ViewName	= bits+1	;ds 2
extra_flag	= ViewName+2	;ds 1
oldEOFval	= extra_flag+1	;ds 3
; dend
;*********************************************
start:
	sta path+1
	sty path

	lda #'s'+$80
	jsr xgetparm_ch
	bcs not_s
	jsr CreateSize
not_s:	lda #'a'+$80
	jsr xgetparm_ch
	bcs not_e	;skip "e" if not "a"
	jsr AddFile
not_a:	lda #'e'+$80
	jsr xgetparm_ch
	bcs not_e
	jsr ExtraName
not_e:
	lda #'v'+$80
	jsr xgetparm_ch
	bcs not_v
	jsr ViewFile
not_v:
	jsr xgetnump	;if there is only 1 parameter (the pathname), then view the index
	cmp #1
	beq ViewIndex
	rts
;*********************************************
ViewIndex:
	lda path+1
	ldy path
	jsr OpenFile
	sta r4ref
	sta EOFref
	lda #0
	sta previousOffset
	sta previousOffset+1
	sta previousOffset+2
	tax
	ldy #$C
	jsr SeekIndex		; file index in AXY
	jsr read4
	jsr SeekIndex
@next:	jsr ReadOneName
	bcs @noMore
	jsr NewLineIfNewEntry	; stay on same line for an additional entry at the same offset
	bcs @exit
	jsr PrintName
	jmp @next
@noMore:
@exit:	jmp crout

; Print one name from the index.
; pagebuff contains length-prefixed string followed by 4-byte offset, 4-byte length.
PrintName:
	jsr xmess
	cstr "  "		; this comes at the start of the line OR separates entries on the same line
	ldx pagebuff
	ldy #0
:	lda pagebuff+1,y
	ora #$80
	jsr cout
	iny
	dex
	bne :-
	rts

; Returns SEC if the user wants to abort output.
NewLineIfNewEntry:
	ldx pagebuff
	lda pagebuff+1,x	; low byte of offset (follows length-prefixed string)
	cmp previousOffset
	bne @newLine
	lda pagebuff+2,x
	cmp previousOffset+1
	bne @newLine
	lda pagebuff+3,x
	cmp previousOffset+2
	beq @newLine
	clc
	rts
@newLine:
	sta previousOffset+2
	lda pagebuff+2,x
	sta previousOffset+1
	lda pagebuff+1,x
	sta previousOffset
croutAndCheckWait:
	jsr crout
	jmp xcheck_wait

previousOffset: .res 3

;*********************************************
crfail:	jmp xProDOS_err
CreateSize:
	stx size+1
	sty size
; calculate start of text
	clc
	lda oIndex
	adc size
	sta oText
	sta EOFval
	lda oIndex+1
	adc size+1
	sta oText+1
	sta EOFval+1

	lda path+1
	ldy path
	sta CrPath+1
	sty CrPath
	jsr mli
	.byte mli_create
	.addr CrParms
	bcs crfail

	lda path+1
	ldy path
	jsr OpenFile
	bcs crfail
	sta WrImageRef
	sta EOFref

	jsr mli
	.byte mli_write
	.addr WrImageP
	bcs crfail

	jsr mli
	.byte mli_seteof
	.addr EOFparms
	bcs crfail

	lda WrImageRef
	jmp Close

CrParms:	.byte 7
CrPath:	.res 2
	.byte %11000011
	.byte 0	;ftype
	.addr 0	;auxtype
	.byte 1	;stype
	.addr 0,0	;crdate/time

WrImageP:
	.byte 4
WrImageRef:
	.byte 1
	.addr EmptyImage
	.addr EmptyEnd-EmptyImage
	.addr 0

CloseP:	.byte 1
CloseRef:
	.res 1

EOFparms:
	.byte 2
EOFref:	.res 1
EOFval:	.byte 0,0,0

EmptyImage:
	.byte 0
	asc "DvxIdx"
	.byte 0
oText:	.res 4
oIndex:	.addr EmptyIndex-EmptyImage
	.addr 0
oFree:	.addr EmptyIndex-EmptyImage
	.addr 0
	.res 32
EmptyIndex:
	.byte 0
EmptyEnd:
;*********************************************
AddFail:	jmp xProDOS_err
AddFile:
	sta fpath+1
	sty fpath
	sta Op2Path+1
	sty Op2Path
	jsr mli
	.byte mli_open
	.addr Op2Parms
	bcs AddFail

	lda path+1
	ldy path
	jsr OpenFile
	bcs AddFail
	sta weRef
	sta r4ref
	sta EOFref

	clc	;new space
	jsr EnterIndex

; seek to end of file before appending new text
	jsr mli
	.byte mli_geteof
	.addr EOFparms
	bcs err1
	jsr mli
	.byte mli_setmark
	.addr EOFparms
	bcs err1

CopyText:
	lda #8
	sta bits
CopyMore:
	jsr ReadSome
	bcs Copied
	jsr WriteSome
	jmp CopyMore
Copied:
	jsr WriteNul
	lda OpRef
	jsr Close
	lda Op2Ref
	jsr Close
	rts
err1:	jmp xProDOS_err

WriteNul:	lda #0
	jsr Compress1
	lda #0
	jmp Compress1

ReadSome:	lda Op2Ref
	sta pageref
	lda #1
	ldy #0
	sta pg_xfer+1
	sty pg_xfer
	jsr mli
	.byte mli_read
	.addr pageparms
	bcc rp_done
	cmp #err_eof
	bne pg_fail
rp_done:	rts
pg_fail:	jmp xProDOS_err

WriteSome:
	lda OpRef
	sta wCompRef
	ldx #0
ws1:	txa
	pha
	lda filebuff3,x
	jsr Compress1
	pla
	tax
	inx
	cpx pg_xfer+2
	bne ws1
	rts

pageparms:	.byte 4
pageref:	.res 1
	.addr filebuff3
pg_xfer:	.addr 0,0

Op2Parms:
	.byte 3
Op2Path:	.res 2
	.addr filebuff2
Op2Ref:	.res 1

;*********************************************
exFail:	jmp xProDOS_err
ExtraName:
	sta fpath+1
	sty fpath

	jsr mli
	.byte mli_open
	.addr Op2Parms
	bcs exFail

	lda path+1
	ldy path
	jsr OpenFile
	bcs exFail
	sta weRef
	sta r4ref
	sta EOFref

	sec	;same space
	jsr EnterIndex

	rts
;*********************************************
;*********************************************
OpenFile:
	sta OpPath+1
	sty OpPath
	jsr mli
	.byte mli_open
	.addr OpParms
	bcs OpFail
	lda OpRef
OpFail:	rts

OpParms:	.byte 3
OpPath:	.res 2
	.addr filebuff
OpRef:	.res 1
;*********************************************
Close:	sta CloseRef
	jsr mli
	.byte mli_close
	.addr CloseP
	rts
;*********************************************
ei_fail:	jmp xProDOS_err
EnterIndex:
	ror extra_flag
	lda #0
	tax
	ldy #$10	;free index space
	jsr SeekIndex
	jsr read4
	lda four+2
	ldx four+1
	ldy four
	sta free_spc+2
	stx free_spc+1
	sty free_spc
	jsr SeekIndex	;seek to free index space

; write the file name into the index
	ldy #0
	lda (fpath),y
	sta pagebuff
	tay
copy_nm:	lda (fpath),y
	jsr xdowncase
	and #%01111111
	sta pagebuff,y
	dey
	bne copy_nm

	ldy #0
	lda (fpath),y
	clc
	adc #1
	sta weLen
	jsr mli
	.byte mli_write
	.addr WriteEntry
ei_fail0:
	bcs ei_fail

; write the file offset into the index
	lda oldEOFval+2
	ldx oldEOFval+1
	ldy oldEOFval
	bit extra_flag
	bmi OldEOF
	jsr mli
	.byte mli_geteof
	.addr EOFparms
	bcs ei_fail
	lda EOFval+2
	ldx EOFval+1
	ldy EOFval
	sta oldEOFval+2
	stx oldEOFval+1
	sty oldEOFval
OldEOF:	sta four+2
	stx four+1
	sty four
	jsr write4

; write the file length into the index
	lda EOFref
	pha
	lda Op2Ref
	sta EOFref
	jsr mli
	.byte mli_geteof
	.addr EOFparms
	bcs ei_fail0
	lda EOFval+2
	ldx EOFval+1
	ldy EOFval
	sta four+2
	stx four+1
	sty four
	jsr write4
	pla
	sta EOFref

	clc
	ldy #0
	lda (fpath),y
	adc #9
	adc free_spc
	sta four
	lda free_spc+1
	adc #0
	sta four+1
	lda free_spc+2
	adc #0
	sta four+2
freesp_ok:
	lda #0
	tax
	ldy #$10
	jsr SeekIndex
	jsr write4
	rts

WriteEntry:
	.byte 4
weRef:	.res 1
	.addr pagebuff
weLen:	.addr 0,0

;*********************************************
SeekIndex:
	sta EOFval+2
	stx EOFval+1
	sty EOFval
	jsr mli
	.byte mli_setmark
	.addr EOFparms
	bcs si_fail
	rts
si_fail:	jmp xProDOS_err
;*********************************************
read4:	jsr mli
	.byte mli_read
	.addr read4_p
	bcs si_fail
	lda four+2
	ldx four+1
	ldy four
	rts

write4:	jsr mli
	.byte mli_write
	.addr read4_p
	bcs si_fail
	rts

read4_p:	.byte 4
r4ref:	.res 1
	.addr four,4,0
four:	.res 4
;*********************************************

ComprTable:
	asc " etoaisrn"
	.byte $0D
	asc "ldhpcf"

Compress1:
	and #%01111111
	ldx #15
cmp1:	cmp ComprTable,x
	beq Write5
	dex
	bpl cmp1
	ldx #8
	jmp WriteX
Write5:
	txa
	ora #%00010000
	asl a
	asl a
	asl a
	ldx #5
WriteX:
	asl a
	rol byte
	dec bits
	bne not_full
	pha
	txa
	pha
	jsr FlushByte
	lda #8
	sta bits
	pla
	tax
	pla
not_full:
	dex
	bne WriteX
	rts

FlushByte:
	jsr mli
	.byte mli_write
	.addr wCompParms
	bcs err2
	rts
err2:	jmp xProDOS_err

wCompParms:
	.byte 4
wCompRef:
	.res 1
	.addr byte
	.addr 1,0

byte:	.res 1
;*********************************************
;*********************************************
;
; View a file
;
ViewFile:
	sta ViewName+1
	sty ViewName
	lda path+1
	ldy path
	jsr OpenFile
	sta r4ref
	sta EOFref
	lda #0
	tax
	ldy #$C
	jsr SeekIndex
	jsr read4
	jsr SeekIndex
search:	jsr ReadOneName
	bcs missing
	jsr CompareVN
	bne search
	jmp ViewThis

missing:	jsr xmess
	.byte cr
	asc "*** not found"
	.byte cr,0
	jmp xerr
;*********************************************
ron_err:	jmp xProDOS_err
ReadOneName:
	lda OpRef
	sta ron_ref1
	sta ron_ref2
	sta unp_ref
	jsr mli
	.byte mli_read
	.addr ron_rd1
	bcs ron_err
	lda pagebuff
	bne ron_cont
	sec
	rts
ron_cont:
	clc
	adc #8
	sta ron_len
	jsr mli
	.byte mli_read
	.addr ron_rd2
	bcs ron_err
	rts

ron_rd1:	.byte 4
ron_ref1:
	.res 1
	.addr pagebuff,1,0

ron_rd2:	.byte 4
ron_ref2:
	.res 1
	.addr pagebuff+1
ron_len:	.addr 0,0
;*********************************************
CompareVN:
	ldy #0
	lda (ViewName),y
	cmp pagebuff
	bne cvn_no
	tay
cvn1:	lda (ViewName),y
	jsr xdowncase
	and #%01111111
	cmp pagebuff,y
	bne cvn_no
	dey
	bne cvn1
cvn_no:	rts
;*********************************************
vt_fail:	jmp xProDOS_err
ViewThis:
	ldx pagebuff
	lda pagebuff+1,x
	sta EOFval
	lda pagebuff+2,x
	sta EOFval+1
	lda pagebuff+3,x
	sta EOFval+2
	lda OpRef
	sta EOFref
	jsr mli
	.byte mli_setmark
	.addr EOFparms
	bcs vt_fail

	lda #0
	sta bits
View1:
	jsr UnpackChar
	bcs viewed
	cmp #$8D
	bne not_cw
	jsr xcheck_wait
	jsr crout
	jmp View1
not_cw:	jsr cout
	jmp View1

viewed:	lda OpRef
	jsr Close
	rts
;*********************************************
unpack_err:
	jmp xProDOS_err
UnpackChar:
	jsr GetBit
	bcs unp_packed

	lda #0
	ldx #7
unp_u1:	pha
	txa
	pha
	jsr GetBit
	pla
	tax
	pla
	rol a
	dex
	bne unp_u1
	cmp #0
	beq GotNull
	ora #%10000000
	clc
GotNull:	rts
unp_packed:
	lda #0
	ldx #4
unp_p1:	pha
	txa
	pha
	jsr GetBit
	pla
	tax
	pla
	rol a
	dex
	bne unp_p1
	tax
	lda ComprTable,x
	ora #%10000000
	clc
	rts

;*********************************************
GetBit:	ldy bits
	bne have_bit
	jsr mli
	.byte mli_read
	.addr unpack1
	bcs unpack_err
	lda #8
	sta bits
have_bit:
	asl byte
	dec bits
	rts

unpack1:	.byte 4
unp_ref:	.res 1
	.addr byte
	.addr 1,0
;*********************************************
