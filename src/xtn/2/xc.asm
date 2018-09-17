;*********************************************
; MPW IIgs skeleton for external commands
;*********************************************
;
; External command for Davex
;
; <name> -- <description>
;
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

.segment	"CODE_9000"

OrgAdr	= $9000	;change as necessary (end below $B000)
; org OrgAdr

MyVersion	= $01
MinVersion	= $12
MinVerAux	= $05	;v1.25
;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr OrgAdr
	.addr start
	.byte MinVerAux,0,0,0
; parameters here
	.byte 0,0
descr:	pstr "<description>"
;*********************************************
; dum xczpage ;32 locations
; dend
;
start:
	rts
