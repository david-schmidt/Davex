;**********************************
;
; online command
;
msg_index:
	.res 1
go_online:

	ldy #$00
	lda #$00
	ldy #$01			; SOS devices are numbered $1-$18
scan_device_loop:
	sty D_INFO_NUM
	lda #$00
	ldx #D_INFO_OPTION_END-D_INFO_NAME
:	sta D_INFO_NAME-1,x		; Clean out D_INFO_NAME data
	dex
	bne :-
	CALLOS mli_get_dev_info, D_INFO_PARMS
	CALLOS_BRANCH_NEG scan_next	; Skip it if we got an OS call error
	lda D_INFO_OPTION+2
	bpl scan_next			; Skip it if it isn't a block device
sv:
	tya
	pha
	jsr scan_volume
	pla
	tay
scan_next:
	iny
	cpy #$19
	bne scan_device_loop
	rts

scan_volume:
	CALLOS mli_online, VOLUME_PARMS	; Retrieve the volume name
	php
	pha
	lda #>D_INFO_NAME
	sta msgp+1
	lda #<D_INFO_NAME
	sta msgp
	ldy #$01
sv_dev_name_loop:
	lda (msgp),y		; Copy in the device name
	bne :+
	lda #$20			; Swap spaces for zeroes
	sta (msgp),Y
:	iny
	cpy #$10
	bne sv_dev_name_loop
	dey
	sty D_INFO_NAME
	lda #>D_INFO_NAME
	ldy #<D_INFO_NAME
	jsr print_path
	pla
	plp
sv_try:	CALLOS_BRANCH_POS sv_new_name
	cmp #err_switched			; If we get a "disk switched" error, retry 
	bne sv_none
	jmp sv_try
sv_new_name:
	jsr mess
	ascz " = /"
	lda #>VOLUME_NAME
	ldy #<VOLUME_NAME
	jsr print_path
	jsr crout
	rts

sv_none:
	cmp #err_notprodos
	bne :+
	jsr mess
	asc_hi " : <non-native disk>"
	.byte cr,0
	rts
:	cmp #err_volnotfnd
	bne :+
	jsr mess
	asc_hi " : <volume not found>"
	.byte cr,0
	rts
:	jsr mess
	asc_hi " : <I/O error>"
	.byte cr,0
	rts
;
; Table for dev_info query

D_INFO_PARMS:	.byte $04
D_INFO_NUM:	.byte $01
D_INFO_NAME_PTR:	.addr D_INFO_NAME
D_INFO_OPTION_PTR:
		.addr D_INFO_OPTION
D_INFO_LENGTH:	.byte $07

D_INFO_NAME:	.res 16
D_INFO_OPTION:	.res $07
D_INFO_OPTION_END = *

; Table for volume query

VOLUME_PARMS:	.byte $04
VOLUME_DEV_PTR:	.addr D_INFO_NAME
VOLUME_NAME_PTR:	.addr VOLUME_NAME
VOLUME_BLOCKS:	.res 2
VOLUME_FREE:	.res 2

VOLUME_NAME:	.res $10