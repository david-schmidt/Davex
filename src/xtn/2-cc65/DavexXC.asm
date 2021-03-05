
	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

CSTACK = $B000	; AF00..AFFF

	.segment "STARTUP"
_XC_STARTUP:
	.export _XC_STARTUP
	.import _main
	.importzp sp
	.importzp sreg
	.import popa

	lda #>CSTACK
	ldx #<CSTACK
	sta sp+1
	stx sp
; [TODO] Call constructors/inits, and initialize any static data
	jmp _main

; Override the library COUT, which would enable language-card memory afterwards. This is called by puts(), for example.
.export COUT
COUT = $fded

; export COUT() for direct use from C: Prints character in inverse if bit 7 is clear.
.export _COUT
_COUT = cout

.export _CROUT
_CROUT = crout

.export _PRBYTE
_PRBYTE = prbyte

.export _SETNORM
_SETNORM = normal

.export _SETINV
_SETINV = inverse


.macro returnTrueForCLC
	ldx #0
	txa
	rol a
	eor #1
	rts
.endmacro

; __fastcall__ calling convention: last parameter is in sreg+1/sreg/X/A
; return value in XA, or sreg+1/sreg/X/A

;	extern _Bool __fastcall__ xgetparm_ch_nil(uint8_t optionCharacter);
.export _xgetparm_ch_nil
_xgetparm_ch_nil:
	jsr xgetparm_ch
	returnTrueForCLC

;	extern _Bool __fastcall__ xgetparm_ch_int1(uint8_t optionCharacter, uint8_t* outValue); // int1
.export _xgetparm_ch_int1
_xgetparm_ch_int1:
	stx p+1
	sta p
	jsr popa			; option character [TODO] pop just 1 byte, or 2?
	jsr xgetparm_ch		; 1-byte result in Y
	bcs :+
	tya
	ldy #0
	sta (p),y
:	returnTrueForCLC

;	extern _Bool __fastcall__ xgetparm_ch_int2(uint8_t optionCharacter, uint16_t* outValue);
.export _xgetparm_ch_int2
_xgetparm_ch_int2:
	stx num+1
	sta num
	jsr popa			; option character [TODO] pop just 1 byte, or 2?
	jsr xgetparm_ch		; 2-byte result in XY
getparm_return_int2:
	bcs :+
; Result is in XY, and we need to store it at (num) as 2 bytes
	tya
	ldy #0
	sta (num),y
	txa
	iny
	sta (num),y
:	returnTrueForCLC


;	extern _Bool __fastcall__ xgetparm_ch_int3(uint8_t optionCharacter, uint32_t* outValue);
.export _xgetparm_ch_int3
_xgetparm_ch_int3:
	stx num+1
	sta num
	jsr popa			; option character [TODO] pop just 1 byte, or 2?
	jsr xgetparm_ch
getparm_return_int3:
	bcs :+
; Result is in AXY, and we need to store it at (num) as 4 bytes
	pha
	tya
	ldy #0
	sta (num),y
	txa
	iny
	sta (num),y
	pla
	iny
	sta (num),y			; carry is still clear for no-error return
	lda #0
	iny
	sta (num),y
:	returnTrueForCLC


;	extern _Bool __fastcall__ xgetparm_ch_byte(uint8_t optionCharacter, uint8_t* outValue); // filetype, devnum, yesno
.export _xgetparm_ch_byte
_xgetparm_ch_byte:
	stx p+1
	sta p
	jsr popa			; option character [TODO] pop just 1 byte, or 2?
	jsr xgetparm_ch		; 1-byte result in A (differs from int1)
	bcs :+
	ldy #0
	sta (p),y
:	returnTrueForCLC


;	extern _Bool __fastcall__ xgetparm_n_int3(uint8_t index, uint32_t* outValue);
.export _xgetparm_n_int3
_xgetparm_n_int3:
	stx num+1
	sta num
	jsr popa			; option character
	jsr xgetparm_n
	jmp getparm_return_int3	;[TODO] Better to turn this into a library, and just let this code be not-linked-in


;	extern _Bool __fastcall__ xgetparm_ch_string(uint8_t optionCharacter, uint8_t** outString);
; [TODO]

;	extern _Bool __fastcall__ xgetparm_ch_path(uint8_t optionCharacter, uint8_t** outPath);
; [TODO]

;	extern _Bool __fastcall__ xgetparm_ch_path_and_filetype(uint8_t optionCharacter, uint8_t** outPath, uint8_t* outFiletype);
; [TODO]

;	extern _Bool __fastcall__ xgetparm_n_byte(uint8_t index, uint8_t* outValue); // int1, filetype, devnum, yesno
; [TODO]

;	extern _Bool __fastcall__ xgetparm_n_int2(uint8_t index, uint16_t* outValue);
; [TODO]

;	extern _Bool __fastcall__ xgetparm_n_string(uint8_t index, uint8_t** outString);
; [TODO]

;	extern _Bool __fastcall__ xgetparm_n_path(uint8_t index, uint8_t** outPath);
.export _xgetparm_n_path
_xgetparm_n_path:
	stx num+1
	sta num
	jsr popa			; param index number [TODO] pop just 1 byte, or 2?
	jsr xgetparm_n		; 2-byte result in AY
	bcs :+
; Result is in AY, and we need to store it at (num) as 2 bytes
	tax
	tya
	ldy #0
	sta (num),y
	iny
	txa
	sta (num),y
:	returnTrueForCLC


;	extern _Bool __fastcall__ xgetparm_n_path_and_filetype(uint8_t index, uint8_t** outPath, uint8_t* outFiletype);
; [TODO]


;	extern void __fastcall__ xmessage(const uint8_t*);
.export _xmessage
_xmessage:
; [TODO] export this from the shell as xmessage ?
	stx loadCharacter+2
	sta loadCharacter+1
	ldy #0
loadCharacter: lda $7777,y	; operand modified
	beq :+
	ora #$80
	jsr cout
	iny
	bne loadCharacter
	inc loadCharacter+2
	bne loadCharacter
:	rts

;	extern void __fastcall__ xprint_ftype(uint8_t); // print a filetype
.export _xprint_ftype
_xprint_ftype = xprint_ftype

;	extern void __fastcall__ xprint_access(uint8_t); // print a ProDOS access byte (r/w/n/d/etc)
.export _xprint_access
_xprint_access = xprint_access

;	extern void __fastcall__ xprdec_2(uint16_t); // print 2-byte value in decimal
.proc _xprdec_2
.export _xprdec_2
_xprdec_2:
	tay
	txa
	jmp xprdec_2
.endproc

;	extern void __fastcall__ xprdec_3(uint32_t); // print 3-byte value in decimal
.proc _xprdec_3
.export _xprdec_3
_xprdec_3:
	sta xnum
	stx xnum+1
	lda sreg
	sta xnum+2
	jmp xprdec_3	; wants A/X/Y
.endproc

;	extern void __fastcall__ xprdec_pad(uint32_t); // print 3-byte value in decimal, right-justified in a 7-character field
.proc _xprdec_pad
.export _xprdec_pad
_xprdec_pad:
	sta xnum
	stx xnum+1
	lda sreg
	sta xnum+2
	jmp xprdec_pad
.endproc

;	extern void __fastcall__ xprint_path(const uint8_t*);
.proc _xprint_path
.export _xprint_path
_xprint_path:
	tay
	txa
	jmp xprint_path
.endproc

;	extern uint8_t* __fastcall__ xbuild_local(uint8_t* path);	// builds a path relative to the "%" directory -- C uses XA
.proc _xbuild_local
.export _xbuild_local
_xbuild_local:
	tay
	txa
	jsr xbuild_local	; input/output in AY
	tax
	tya
	rts
.endproc

;	extern void __fastcall__ xprint_sd(uint8_t slotAndDrive);
.export _xprint_sd
_xprint_sd = xprint_sd

;	extern uint8_t __fastcall__ xredirect(int8_t adjustment);
.proc _xredirect
.export _xredirect
_xredirect:
	jsr xredirect
	ldx #0
	rts
.endproc

;	extern uint8_t __fastcall__ xpercent(uint32_t value, uint32_t total);
; [TODO] A/X/Y? and num+2,num+1,num

;	extern _Bool __fastcall__ xyesno();
.proc _xyesno
.export _xyesno
_xyesno:
	jsr xyesno
	beq :+		; beq = No (0), otherwise return 1
	lda #1
:	ldx #0
	rts
.endproc

;	extern uint8_t __fastcall__ xyesno2(uint8_t defaultChar); // v1.2
.proc _xyesno2
.export _xyesno2
_xyesno2:
	jsr xyesno2
	beq :+		; beq = No (0), otherwise return 1
	lda #1
:	ldx #0
	rts
.endproc

;	extern _Bool __fastcall__ xgetln(); // result is in "string" (TODO: call it "xString" or something?)
.proc _xgetln
.export _xgetln
_xgetln:
	jsr xgetln
	returnTrueForCLC
.endproc

;	extern void __fastcall__ xbell();
.export _xbell
_xbell = xbell

;	extern uint8_t __fastcall__ xdowncase(uint8_t ch);
.proc _xdowncase
.export _xdowncase
_xdowncase:
	jsr xdowncase
	ldx #0
	rts
.endproc

;	extern void __fastcall__ xplural(uint16_t value);
.proc _xplural
.export _xplural
_xplural:
	tay
	txa
	jmp xplural	; wants AY
.endproc

;	extern _Bool __fastcall__ xcheck_wait();
.proc _xcheck_wait
.export _xcheck_wait
_xcheck_wait:
	jsr xcheck_wait
	returnTrueForCLC
.endproc

;	extern void __fastcall__ xpr_date(uint16_t date);
.proc _xpr_date
.export _xpr_date
_xpr_date:
	tay
	txa
	jmp xpr_date_ay
.endproc

;	extern void __fastcall__ xpr_time(uint16_t time);
.proc _xpr_time
.export _xpr_time
_xpr_time:
	tay
	txa
	jmp xpr_time_ay
.endproc

;	extern void __fastcall__ xProDOS_err(uint8_t err);	// does not return
.export _xProDOS_err
_xProDOS_err = xProDOS_err

;	extern void __fastcall__ xProDOS_er(uint8_t err);
.export _xProDOS_er
_xProDOS_er = xProDOS_er

;	extern void __fastcall__ xerr();	// does not return
.export _xerr
_xerr = xerr

;	extern void __fastcall__ xprdec_pad_n(uint32_t value, uint8_t widthMinusOne);
; [TODO]

;	extern void __fastcall__ xdir_setup(uint8_t* path); // path is complete, or relative to the prefix (see xdir_setup2)
.proc _xdir_setup
.export _xdir_setup
_xdir_setup:
	tay
	txa
	jmp xdir_setup
.endproc

;	extern void __fastcall__ xdir_setup2(uint8_t* path); // v1.23 - path is complete, or relative to the already-open directory
.proc _xdir_setup2
.export _xdir_setup2
_xdir_setup2:
	tay
	txa
	jmp xdir_setup2
.endproc

;	extern void __fastcall__ xdir_finish();
.export _xdir_finish
_xdir_finish = xdir_finish

;	extern _Bool __fastcall__ xread1dir(); // if returns true, result is in "catbuff"
.proc _read1dir
.export _xread1dir
_xread1dir:
	jsr xread1dir
	returnTrueForCLC
.endproc

;	extern void __fastcall__ xpoll_io();
.export _xpoll_io
_xpoll_io = xpoll_io

;	extern void __fastcall__ xprint_ver(uint8_t version);
.export _xprint_ver
_xprint_ver = xprint_ver

;	extern void __fastcall__ xpush_level(); // call before dir_setup
.export _xpush_level
_xpush_level = xpush_level

;	extern _Bool __fastcall__ xfman_open(uint8_t* path, uint8_t* outRefnumOrError);
; [TODO]
;	extern _Bool __fastcall__ xfman_read(uint8_t refnum, uint8_t* outCharOrError);
; [TODO]

;	extern uint8_t __fastcall__ xrdkey(); // ;v1.1
.export _xrdkey
_xrdkey = xrdkey

;	extern void __fastcall__ xdirty();	// v1.1
.export _xdirty
_xdirty = xdirty

;	extern uint8_t __fastcall__ xgetnump(); // v1.1
.proc _xgetnump
.export _xgetnump
_xgetnump:
	jsr xgetnump
	ldx #0	;extend result to 16 bits
	rts
.endproc

;	extern uint8_t __fastcall__ ProDOS(uint8_t call, void* params);
.proc _ProDOS
.export _ProDOS
;;_ProDOS:
	stx @params+1
	sta @params
	jsr popa
	sta @callNum
	jsr mli
@callNum: .byte 0
@params: .addr 0
	ldx #0		; error in A
	rts
.endproc

.segment "ONCE"
.segment "INIT"
