;*********************************************
;*********************************************
;
; External command for Davex
;
; gsbuff -- examine/set IIgs port buffers
;
; 22-Mar-88   David A. Lyons
;
;*********************************************
;
; gsbuff n        display buff info, slot n
; gsbuff n -i<s>  set input buff to sK
; gsbuff n -o<s>  set output buff to sK
;
;*********************************************
;
; Converted to MPW IIgs 20-Sep-92 DAL
;
;*********************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/Macros.asm"


.segment	"CODE_A000"

OrgAdr	= $A000	;change as necessary (end below $B000)
; org OrgAdr

;*********************************************
;*********************************************
GetInBuffer	= $10
GetOutBuffer	= $11
SetInBuffer	= $12
SetOutBuffer	= $13
;*********************************************
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
	.byte 0,t_int1
	.byte $80+'i',t_int2
	.byte $80+'o',t_int2
	.byte 0,0
descr:	pstr "examine/set IIgs port buffers"
	
;*********************************************
; xczpage ;32 locations
;
slotnum	= xczpage	;ds 1
Cn	= slotnum+1	;ds 2
hand	= Cn+2		;ds 4
error2	= hand+4	;ds 2

;*********************************************
badslot:
	jsr xmess
	.byte cr
	cstr_cr "*** slot number must be 1..7"
	jmp my_xerr

;*********************************************
start:	sty slotnum
	sec
	jsr $fe1f
	bcc is_gs
	jsr xmess
	.byte cr
	cstr_cr "*** 'gsbuff' requires Apple IIgs"
	jmp xerr
is_gs:

.P816
.I8
.A8

	lda $cfff
	lda slotnum
	beq badslot
	cmp #7+1
	bcs badslot

	ora #$C0
	sta Cn+1
	stz Cn

	ldy #5
	lda (Cn),y
	cmp #$38
	bne not_pasc
	ldy #7
	lda (Cn),y
	cmp #$18
	bne not_pasc
	ldy #$b
	lda (Cn),y
	cmp #$01
	beq is_pasc
not_pasc:
	jsr xmess
	.byte cr
	asc "*** card does not support Pascal 1.1 protocol"
	.byte cr,0
	jmp my_xerr
is_pasc:
	iny
	lda (Cn),y
	and #$F0
	cmp #$30
	beq is_ser
	jsr xmess
	.byte cr
	asc "*** not a serial card"
	.byte cr,0
	jmp my_xerr
is_ser:
	ldy #$11
	lda (Cn),y
	beq DoesExtended
	jsr xmess
	.byte cr
	asc "*** card does not support extended interface"
	.byte cr,0
	jmp my_xerr
DoesExtended:

	jsr InitCard

	lda #'i'+$80
	jsr xgetparm_ch
	bcs no_i
	jsr SetIn

no_i:	lda #'o'+$80
	jsr xgetparm_ch
	bcs no_o
	jsr SetOut

no_o:	jmp ReportBuffs
;*********************************************
SetIn:	lda #SetInBuffer
	bne SetIOBuff
SetOut:	lda #SetOutBuffer
SetIOBuff:
	stx buffsiz+1
	sty buffsiz
	sta ext_cmd
	jsr Allocate
	jsr ExtendedCall
	rts
;*********************************************
Allocate:
	clc
	xce
	rep #$30
.A16
.I16
	pha
	pha		; space for NewHandle result
	pea $0000	; NewHandle size high
	lda buffsiz
	pha		; size low

	pha		; space for id
	pea $8000	; firmware category
	ldx #$2003	; GetNewID
	jsl $e10000

	pea $4008	; NewHandle flags (locked, no special mem)
	pha		; final parameter not interesting, and is 0 (from GetNewID error code)
	pha
	ldx #$0902	; NewHandle
	jsl $e10000
	bcs nh_error
	pla
	sta hand
	pla
	sta hand+2
	lda [hand]
	sta buffadr
	ldy #2
	lda [hand],y
	sta buffadr+2
	sec
	xce
	rts

nh_error:
	sta error2
	sec
	xce
.I8
.A8
	jsr xmess
	.byte cr
	asc "*** error allocating memory: $"
	.byte 0
	lda error2+1
	jsr $fdda	;PRBYTE
	lda error2
	jsr $fdda	;PRBYTE
	jsr crout
	jmp my_xerr

;*********************************************
ReportBuffs:
	jsr xmess
	.byte cr
	asc "Slot "
	.byte 0
	lda slotnum
	ora #'0'+$80
	jsr cout
	jsr xmess
	asc ":"
	.byte cr
	asc "  Input buffer:  "
	.byte 0
	lda #GetInBuffer
	jsr PrintBuffInfo
	jsr xmess
	asc "  Output buffer: "
	.byte 0
	lda #GetOutBuffer
	jsr PrintBuffInfo
	jmp cleanup
;*********************************************
PrintBuffInfo:
	sta ext_cmd
	jsr ExtendedCall
	jsr xmess
	asc "size="
	.byte 0
	lda buffsiz+1
	ldy buffsiz
	jsr xprdec_2
	jsr xmess
	asc ", address=$"
	.byte 0
	lda buffadr+3
	jsr $fdda
	lda buffadr+2
	jsr $fdda
	lda buffadr+1
	jsr $fdda
	lda buffadr
	jsr $fdda
	jmp crout
error:	jsr xmess
	.byte cr
	asc "*** extended call returned error $"
	.byte 0
	lda result+1
	jsr $fdda
	lda result
	jsr $fdda
	jsr crout
	jmp my_xerr

InitCard:
	ldy #$0d
	lda (Cn),y
	sta ic+1
	lda Cn+1
	sta ic+2
	ldx Cn
	lda Cn
	asl a
	asl a
	asl a
	asl a
	tay
ic:	jsr $ffff
	rts

ExtendedCall:
	ldy #$12	;extended
	lda (Cn),y
	sta ec1+1
	lda Cn+1
	sta ec1+2
	ldy #0
	ldx #>cmdtbl
	lda #<cmdtbl
ec1:	jsr $ffff
	lda result+1
	ora result
	bne error
	rts

;*********************************************
cmdtbl:		.byte 4
ext_cmd:	.res 1
result:		.res 2
buffadr:	.res 4
buffsiz:	.res 2
;*********************************************
cleanup:
	lda $cfff
	lda $7f8
	cmp #$C1
	bcc clean2
	cmp #$C8
	bcs clean2
	sta Cn+1
	lda #0
	sta Cn
	ldy #0
	lda (Cn),y
clean2:	rts

my_xerr:
	jsr cleanup
	jmp xerr
;*********************************************
