;**********************************
;
; online command
;
msg_index:
	.res 1
go_online:
	lda #>pagebuff
	ldy #<pagebuff
	sta p+1
	sty p
	CALLOS mli_online, onl_parms
	CALLOS_BRANCH_POS onl_ok
	jmp ProDOS_err
onl_ok:
;
; print slot, drive, name for each volume
;
	lda #0
vloop:	pha
	asl a
	asl a
	asl a
	asl a
	tay
	lda (p),y
	beq nextvol
	ldx #msg2-msg
	stx msg_index
	and #$0f
	bne normal_name
;
; error occured on this volume.  print
; err msg if 'not ProDOS volume' or
; 'duplicate volume'
;
	sty temp
	lda #$80+'o'
	jsr getparm_ch
	ldy temp
	bcs print_this
	jmp nextvol

print_this:
	iny
	lda (p),y
	dey
	ldx #msg_notpro-msg
	cmp #err_notprodos
	beq this_vol
	ldx #msg_dupvol-msg
	cmp #err_dupvol
	bne nextvol
this_vol:
	stx msg_index
;
; do one volume
;
normal_name:
	lda (p),y	;get devnum
	jsr print_sd

	ldx msg_index
onlmsg:	lda msg,x
	beq onlmsgx
	ora #$80
	jsr cout
	inx
	bne onlmsg
onlmsgx:

	lda (p),y
	and #$0f
	tax
	beq nextvol
	iny
charlp:	lda (p),y
	jsr downcase
	jsr cout
	iny
	dex
	bne charlp
	jsr crout

nextvol:
	pla
	clc
	adc #1
	cmp #16
	bcc vloop
	rts

msg:
msg2:	cstr " = /"
msg_notpro:
	cstr_cr ":  <non-ProDOS disk>"
msg_dupvol:
	cstr_cr ":  <duplicate volume>"

onl_parms:
	.byte 2
	.byte 0
	.addr pagebuff
