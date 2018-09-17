print_drvr:
	rts
;
; Slots-open table:
;   $8x = open for output
;   $4x = open for input
;   $Cx = open for i/o
;   $x0 = closed
;   $x1 = Pascal 1.1 device
;   $x2 = CnC1/C0x0 device
;
SlotsOpen:
	.byte 0,0,0,0,0,0,0
tempref:	.byte 0
outmask:	.res 1
