;************************************************
; spool
;************************************************
;
; spool <wildpath>
;
;  -x <int1>   cancel a job
;  -z          zap all jobs
;
; 'spool' alone shows queue
;
; Uses buff_spool (1K) and spoollist (1 page)
;
;************************************************
;
; spool_list:
;  repeat {
;    length-prefixed pathname
;  }
;  $00
;
;************************************************
sp_linefd:
	.byte 0

go_spool:
	sta p+1
	sty p
	lda num_parms
	cmp #1
	bne sp_notlist
	ldy #0
	lda (p),y
	bne sp_notlist
	jmp sp_list
sp_notlist:
	lda #$80+'z'
	jsr getparm_ch
	bcs sp_nzap
	jsr sp_zap
sp_nzap:
	lda #$80+'x'
	jsr getparm_ch
	bcs sp_ncan
	jsr sp_cancel
sp_ncan:
	jmp spool_file

;************************************************
spool_zap:
sp_zap:
	bit spooling
	bpl sp_zap2
; formfeed printer if it's ready
	ldy spl_prref
	ldx #mli_read
	jsr print_drvr
	and #1
	beq sp_zap2
	lda #$80+'L'-ctrl
	ldx #mli_write
	ldy spl_prref
	jsr print_drvr
sp_zap2:
	lsr spooling
	lda rsref
	jsr close
	ldx #mli_close
	ldy spl_prref
	beq szx
	jsr print_drvr
szx:	lda #0
	sta spool_list
	sta spl_prref
	rts

canthis:
	jmp thats_ok
sp_cancel:
	cpy #0
	beq spcanx
	cpy #1
	beq canthis
	lda #0
spcan0:
	dey
	beq can_this
	tax
	sec
	adc spool_list,x
	jmp spcan0

can_this:
	tax
	sec
	adc spool_list,x
	tay
spcan1:	lda spool_list,y
	sta spool_list,x
	inx
	iny
	bne spcan1
spcanx:	rts

;************************************************
spool_file:
	lda p+1
	ldy p
	sta spoolp+1
	sty spoolp
	ldy #0
	lda (p),y
	bne spoolit
	rts
spoolit:
	jsr spool_full
	lda p+1
	ldy p
	jsr getinfo
	jsr findspll
	txa
	ldy #0
	clc
	adc (p),y
	bcs spfull
	cmp #250
	bcc spl_room
spfull:	lda #der_outroom
	jmp ProDOS_err
spl_room:
	lda (p),y
	sta temp
splcopy:
	lda (p),y
	sta spool_list,x
	iny
	inx
	dec temp
	bpl splcopy
	lda #0
	sta spool_list,x
	rts

spoolthis:
	sta spoolp+1
	sty spoolp
	lda #spoollevel
	sta level
	bit spooling
	bmi already_sp
	lda #0		;slot = '&'
	ldx #mli_open
	jsr print_drvr
	bcs spool_er
	sta spl_prref
already_sp:
	jsr mli
	.byte mli_open
	.addr spool_open
	bcs spool_er
	sec
	ror spooling
	lda spoolref
	sta rsref
	rts
spool_er:
	ldx #mli_close
	ldy spl_prref
	jsr print_drvr
	jmp bell

spl_prref:
	.byte 0

spool_open:
	.byte 3
spoolp:	.res 2
	.addr buff_spool
spoolref:
	.res 1

;************************************************
spoolnext:
	jsr sp_rmv1
	lda spool_list
	bne sp_another
	lsr spooling
	ldx #mli_close
	ldy spl_prref
	jmp print_drvr

sp_another:
	lda #>spool_list
	ldy #<spool_list
	jmp spoolthis

;************************************************
sp_list:
	lda spool_list
	bne spl_some
	jsr mess
	cstr_cr "no files"
	rts
spl_some:
	ldy #1
	ldx #0
spl_file:
	txa
	pha
	tya
	pha
	lda #0
	jsr prdec_2
	jsr mess
	cstr ".  "
	pla
	tay
	pla
	tax
	iny
	jsr spl_name
	bne spl_file
	rts

spl_name:
	lda spool_list,x
	beq splx
	sta temp
splch:	inx
	lda spool_list,x
	jsr downcase
	jsr cout
	dec temp
	bne splch
	inx
	jsr crout
	lda spool_list,x
splx:	rts

;************************************************
;
; poll_spool--called during keyboard input
; need not preserve registers
;
poll_spool:
	bit spooling
	bpl poll_maybe
;
; if(printer_ready) {
;   print_char(read(spool_buff));
; }
;
	ldx #mli_read
	ldy spl_prref
	jsr print_drvr
	and #1
	beq pollsp_x

	bit sp_linefd
	bpl sp_filech
	lda #$80+'J'-ctrl
	lsr sp_linefd
	bpl spchar

sp_filech:
	jsr mli
	.byte mli_read
	.addr readspool
	bcs spl_err

spcheat:
	lda #0		; MODIFIED -- read byte to here
	ora #$80
	cmp #$80+'M'-ctrl
	bne spchar
	ror sp_linefd
spchar:	ldx #mli_write
	ldy spl_prref
	jsr print_drvr
pollsp_x:
	rts

poll_maybe:
	lda spool_list
	beq poll_nope
	jmp sp_another
poll_nope:
	rts

spl_err:
	cmp #err_eof
	beq thats_ok
	jsr bell
thats_ok:
	lda #$80+'L'-ctrl
	ldx #mli_write
	ldy spl_prref
	jsr print_drvr
	lda rsref
	jsr close
	jmp spoolnext

readspool:
	.byte 4
rsref:	.res 1
	.addr spcheat+1
	.addr 1		;read 1 character
	.addr 0

;
; sp_rmv1 -- remove 1st file from spool_list
;
sp_rmv1:
	ldx spool_list
	inx
	ldy #0
sprmv1:	lda spool_list,x
	sta spool_list,y
	iny
	inx
	bne sprmv1
	rts
;
; findspll -- x=end of spool list
;
findspll:
	ldx #<-1
fspl1:	inx
	lda spool_list,x
	bne fspl1
	rts
;
; make (p) into a complete pathname
;
spool_full:
	ldy #1
	lda (p),y
	ora #$80
	cmp #$80+'/'
	beq sfx
	ldy #63
sf1:	lda (p),y
	sta pagebuff,y
	dey
	bpl sf1
	lda p+1
	ldy p
	sta sf3+1
	sty sf3
	sta spgetp+2
	sty spgetp+1
	jsr mli
	.byte mli_getpfx
	.addr spgetp
	bcs sferr
	lda #>pagebuff
	ldy #<pagebuff
	jsr pmgr
	.byte pm_appay
sf3:	.addr 0
sfx:	rts

sferr:	jmp ProDOS_err

spgetp:	.byte 1,0,0
