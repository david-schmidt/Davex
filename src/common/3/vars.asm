Aliases:		.res 768		;= $ba00	;ds 768
parms:		.res maxparms*4	;= $be00	;ds maxparms*4
num_parms:	.byte 0		;= $be40	; ds 1
parmtypes:	.res maxparms	;= $be41	;ds maxparms
string_1:	.res 1		;Note - code assumes string-1 is ok to use 
string:		.res $100	;$1901	;ds $100 ;not for xc use
string2_1:	.res 1		;Note - code assumes string2-1 is ok to use
string2:		.res $80		;ds $80 ;not for xc use
machine:		.byte $EA
filebuff:	.res $400	;= $800	;ds $400
filebuff2:	.res $400	;= $C00	;ds $400
filebuff3:	.res $400	;= $1000	;ds $400
wildbuff:	.res $400	;= $1400	;ds $400 ;not for xc use
pagebuff:	.res $100	;= $1800	;ds $100
		.res 1		; ds 1
catbuff:		.res $80		;= $1A02	;ds $80
		.res 1		; ds 1
command:		.res maxlen	;= $1A83	;ds maxlen ;not for xc use
direcpath:	.res 65		;= $1BFE	;ds 65 ;not for xc use
wildstring1:	.res 128		;= $1C3F	;ds 128
wildstring2:	.res 128		;= $1CBF	;ds 128
wildseg:		.res 16		;= $1D3F	;ds 16
