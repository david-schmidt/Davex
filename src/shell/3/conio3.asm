;---------------------------------------------------------
; Character output
; 
; Send one character to the console from Accumulator; preserve A
; Special case: crout, which prints a carriage return
;---------------------------------------------------------
crout:	; Output return character
	lda #$0d
cout:	; Character output routine (print to screen)
	sta WRITE1_DATA
	CALLOS mli_write, WRITE1_PARMS
	lda WRITE1_DATA
	rts

;---------------------------------------------------------
; init_screen
; 
; Sets up the screen for behaviors we expect
;---------------------------------------------------------
init_screen:
	; Prepare the system for our expectations
	CALLOS mli_open, OPEN_PARMS	; Open the console
	;jsr ERRORCK
	lda OPEN_REF
	sta WRITE_REF			; Save off our console file references
	sta WRITE1_REF
	sta CONSREAD_REF
	jsr crout

	jsr on80
	lda #80
	sta scr_width			; Davex needs to know the screen width

					; Ask for device number of the console
	CALLOS mli_get_dev_num, GET_DEV_NUM_PARMS
	;jsr ERRORCK
	lda GET_DEV_NUM_REF
	sta D_STATUS_NUM		; Save off our console device references
	sta D_CONTROL_NUM

	lda #$80
	sta D_CONTROL_DATA
	lda #$0d
	sta D_CONTROL_DATA+1
	lda #$02
	sta D_CONTROL_CODE
	CALLOS mli_d_control, D_CONTROL_PARMS	; Turn data entry termination on
	lda #$00
	sta D_CONTROL_DATA
	lda #$0f
	sta D_CONTROL_CODE
	CALLOS mli_d_control, D_CONTROL_PARMS	; Turn escape mode off
	lda #$00
	sta D_CONTROL_DATA
	lda #$05
	sta D_CONTROL_CODE	; Leave the control block set up to flush the typeahead buffer

	lda e_reg		; Read the environment register
	and #$f7		; Turn $C000-$CFFF to R/W
	ora #$40		; Turn $C000-$CFFF to I/O
	sta e_reg		; Write the environment register

; Points SOS' NMI vector at the debug routine in SOS. It normally
; points at an RTS so that hitting RESET doesn't do anything. This
; changes it so when you hit RESET, SOS enters a routine that saves all the
; important stuff, and jumps into the built in monitor. To reenter SOS, do
; a 198CG from the monitor. Known to work through SOS 1.3.
; To bank your memory in, set the bank register to the highest page
; I.e. FFEF:F6 for a 256k machine.
; Your zero page actually lives at $1A00-$1AFF.
;
; In Dav3x, to restart from the monitor, you need to reset the zero page
; and the environment registers, then jump to the restart code:
;                               Davex restart address
;                                       =====
; a000:a9 1a 8d d0 ff a9 70 8d d1 ff 4c ed 21
; a000g
; And then maybe config -4n to get back into 80 column mode, until
; the code is straightened out for setting/resetting modes
	lda $1904	; Grab low byte of NMI vector
	sec		; Make sure that carry is set.
	sbc #$07	; Fall back 7 bytes from the
	sta $1911	; byte currently pointed to
	lda $1905	; (an RTS), and store this in
	sbc #$00	; the NMI JMP instruction.
	sta $1912	; Unwrap the high byte.
	rts

memory_fail:
	jsr mess
	ascz "UNABLE TO ALLOCATE REQUIRED MEMORY."
	jmp *

set_columns:	; $00 = 80 columns, $ff = 40 columns
	lda #INIT_SCREEN_DATA_END-INIT_SCREEN_DATA
	sta WRITE_LEN
	lda #<INIT_SCREEN_DATA
	sta msgp
	lda #>INIT_SCREEN_DATA
	sta msgp+1
	CALLOS mli_write, WRITE_PARMS	; Re-using the message parameter block
	rts

on40:
	lda #columns40
	jmp prep_columns

on80:
	lda #columns80
prep_columns:
	sta INIT_SCREEN_COLUMNS
	jmp set_columns

;---------------------------------------------------------
; HOME
; 
; Clears the screen
;---------------------------------------------------------
home:
	lda #$1c
	jsr cout
	rts

;***********************************************
;
; mess -- print an in-line message
;
mess:
	pla		; Return address is on the stack - which we use to find parms
	clc
	adc #$01
	sta msgp
	sta p
	pla
	adc #$00
	sta msgp+1	; The output buffer pointer, msgp, is set to the caller's memory following mess call
	sta p+1
	ldy #$00
	sty WRITE_LEN+1	; Start with MSB of 16-bit write length to zero
get_next:		; Count the number of bytes to print
	iny
	bne no_inc
	inc p+1
	inc WRITE_LEN+1
no_inc:
	lda (p),y
	bne get_next
	sty WRITE_LEN
	CALLOS mli_write, WRITE_PARMS
	clc		; Flatten return address - take an arbitrary pointer plus length and make it an address
	tya		; Y holds the lsb of the number of bytes we counted
	adc msgp		; Add the original address' lsb 
	sta p		; Hang on to that for a second while we calculate the msb and push that
	lda msgp+1	; Get original address' msb   
	adc WRITE_LEN+1	; Add in the msb from length we counted, plus the carry (if any) from lsb addition
	pha		; Push msb of return address
	lda p		; Grab the lsb we stashed a second ago
	pha		; Push the lsb
	rts		; Return to the caller just past the point of the message

;---------------------------------------------------------
; prbyte: Print Byte routine (HEX value)
;---------------------------------------------------------
prbyte:
prhex:
	PHA		; PRINT BYTE AS 2 HEX
	LSR		; DIGITS, DESTROYS A-REG
	LSR
	LSR
	LSR
	JSR :+
	PLA
	AND #$0F	; PRINT HEX DIG IN A-REG
:	ORA #$B0	;  LSB'S
	CMP #$BA
	BCC :+
	ADC #$06
:	JMP cout
	rts

suspend80:
restore80:
	rts

INIT_SCREEN_DATA:
	.byte 16
INIT_SCREEN_COLUMNS:
	.byte columns80
	.byte 21, $0f	; Make return do newline
	.byte 1	; Reset viewport
	.byte 28	; Clear screen
INIT_SCREEN_DATA_END:

; Table for write one character

WRITE1_PARMS:	.byte 3
WRITE1_REF:	.byte $FF
WRITE1_DATA_PTR:	.word WRITE1_DATA
WRITE1_LEN:	.word $0001
WRITE1_DATA:	.byte $00

; Table for write string

WRITE_PARMS:	.byte 3
WRITE_REF:	.byte $FF
WRITE_DATA_PTR:	.word msgp
WRITE_LEN:	.word $0000

; Table for console read

CONSREAD_PARMS:	.byte $04
CONSREAD_REF:	.byte $00
		.word CONSREAD_INPUT
CONSREAD_COUNT:	.word $0001
CONSREAD_XFERCT:	.word $0000
CONSREAD_INPUT:	.res $100, $00

; Table for open

OPEN_PARMS:	.byte 4
OPEN_NAME:	.addr CONSOLE
OPEN_REF:	.byte $ff
OPEN_OPT_PTR:	.addr 0
OPEN_LEN:	.byte 0

CONSOLE:	.byte CONSOLE_END-CONSOLE_BODY
CONSOLE_BODY:	.byte ".CONSOLE"
CONSOLE_END:

; Table for get device number

GET_DEV_NUM_PARMS:
		.byte $02
GET_DEV_NUM_NAME:
		.addr CONSOLE
GET_DEV_NUM_REF:
		.byte $00

; Table for device status

D_STATUS_PARMS:	.byte $03
D_STATUS_NUM:	.byte $00
D_STATUS_CODE:	.byte $00
D_STATUS_LIST:	.addr D_STATUS_DATA
D_STATUS_DATA:	.byte $00, $00

; Table for device control

D_CONTROL_PARMS:
		.byte $03
D_CONTROL_NUM:	.byte $01
D_CONTROL_CODE:	.byte $00
D_CONTROL_LIST:	.addr D_CONTROL_DATA
D_CONTROL_DATA:	.byte $00, $00

FIND_SEG_PARMS:	.byte $06	; Six parameters
FIND_SEG_MODE:	.byte $00	; In - don't cross 32k boundaries
FIND_SEG_LABEL:	.byte $10	; In - our segment "label"
FIND_SEG_PAGES:	.addr $0080	; In/Out - number of pages
FIND_SEG_BASE:	.addr $0000	; Out - origin segment addr
FIND_SEG_LIMIT:	.addr $0000	; Out - last segment addr
FIND_SEG_NUM:	.byte $00	; Out - segment "number"

GET_PREFIX_PARMS:	.byte $02
GET_PREFIX_PATH:	.addr string2-1
GET_PREFIX_LENGTH:
		.byte $80

SET_PREFIX_PARMS:	.byte $01
SET_PREFIX_PATH:	.addr string2-1	; Must be Pascal string
