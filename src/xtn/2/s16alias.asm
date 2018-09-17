;***************************************************
;
; S16 launcher image for Davex 8 sysalias command
;
; Dave Lyons, 15-Oct-89
;
; Optionally does a SET_PREFIX(0,...)
; Optionally does a MessageCenter(Add,1,...)
; Does a QUIT
;
;***************************************************
Kool:	start

tool	= $e10000
P16	= $e100a8

	phk
	plb

; set prefix 0
	lda PrefixPath
	beq noSetPfx
	jsl p16
	dc  i'$0009'
	dc  i4'PfxParms'
noSetPfx:	anop

; add message 1 to MessageCenter
	lda OpenPath
	and #$00ff
	beq noMessage

	pha
	pha	;space for result
	pea 0
	clc
	adc #10
	pha	;size = pathlen + 10
	sta theLength
	pha	;space for user id
	ldx #$0202	;MMStartUp()
	jsl tool
	pea $C000	;locked+fixed
	pha
	pha
	ldx #$0902	;NewHandle
	jsl tool
	pla
	sta theHand
	pla
	sta theHand+2
	bcs noMessage

	pea OpenBlock|-16
	pea OpenBlock
	lda theHand+2
	pha
	lda theHand
	pha
	pea 0
	lda theLength
	pha
	ldx #$2802	;PtrToHand
	jsl tool

	pea 1	;add message
	pea 1	;type 1
	lda theHand+2
	pha
	lda theHand
	pha
	ldx #$1501	;MessageCenter   act type msg
	jsl tool

	lda theHand+2
	pha
	lda theHand
	pha
	ldx #$1002	;DisposeHandle
	jsl tool

noMessage:	anop

; quit to the destination S16 (or EXE?) file
	jsl p16
	dc  i'$0029'
	dc  i4'QuitParms'
	brk 0

QuitParms:	dc  i4'QuitPath'
	dc  i'0,0'

PfxParms:	dc  i'0'
	dc  i4'PrefixPath'

theLength:	dc  i'0'
theHand:	dc  i4'0'

	dc  c'Q'
QuitPath:	dc  i1'0,0'
	dc  c'345678123456781234567812345678'
	dc  c'12345678123456781234567812345678'

	dc  c'P'
PrefixPath:	dc  i1'0,0'
	dc  c'345678123456781234567812345678'
	dc  c'12345678123456781234567812345678'

	dc  c'O'
OpenBlock:	dc  i4'0'
	dc  i'1'	;msg type 1
	dc  i'0'	;Open (not Print)
OpenPath:	dc  i1'0,0'
	dc  c'345678123456781234567812345678'
	dc  c'12345678123456781234567812345678'
	dc  i1'0'
