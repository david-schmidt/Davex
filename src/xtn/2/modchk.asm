;*********************************************
;
; External command for DAVEX
;
; modchk -- compare the last-mod dates on
;           two files (most useful with
;           wildcards)
;
; by Dave Lyons, 13-Jun-87
;
; Converted to Merlin 28-Jan-90 DAL
;   still version 1.0, but requires Davex 1.0 now
;
;**********************************************
;
; modchk is typically used like this (to make
; sure all source (.s) files have been compiled
; since they were last changed):
;
;   modchk =.s = -o
;
; modchk file1 file2 [-o] [-n] [-s] [-q]
;                      l    e    a    u
;                      d    w    m    i
;                      e         e    e
;                      r              t
;
; Output:  if no parameters are given, a report
;          of the following form appears:
;
;            <file1> <relation> <file2>
;
;            Relation is "<" or "=" or ">"
;
; If one or more of -o, -n, or -s is given,
; file1 is printed only if the relationship
; holds.  For example, modchk =.s = -n prints
; the names of all source files that are newer
; than their corresponding object files.
;
; If -q is given, modchk does not complain when
; file2 does not exist.
;
; If one of the files has no modification
; date/time, a warning is displayed.
;
;*********************************************
;*********************************************
;
; Converted to MPW IIgs 21-Sep-92 DAL
;
;*********************************************

	.include "Common/2/Globals2.asm"
	.include "Common/2/Apple.Globals2.asm"
	.include "Common/2/Mli.globals2.asm"
	.include "Common/Macros.asm"

.segment	"CODE_A000"


orgadr	= $A000
; org orgadr

MyVersion	= $10
MinVersion	= $10
;*********************************************
	rts
	.byte $ee,$ee
	.byte MyVersion,MinVersion
	.byte %00000000	;hardware req
	.addr descr
	.addr orgadr
	.addr start
	.byte 0,0,0,0
; parameters here
	.byte 0,t_wildpath
	.byte 0,t_wildpath
	.byte $80+'o',t_nil
	.byte $80+'n',t_nil
	.byte $80+'s',t_nil
	.byte $80+'q',t_nil
	.byte 0,0
descr:	pstr "compare last-mod dates of files"
	
;*********************************************
; dum xczpage ;32 locations
path1	= xczpage	;ds 2
path2	= path1+2	;ds 2
count	= path2+2	;ds 1
; dend
;
outa_here:
	jmp xProDOS_err
;
start:	nop		;disable wildcard-exp printing
	lda #0
	jsr xgetparm_n
	sta path1+1
	sty path1
	sta info1_path+1
	sty info1_path

	lda #1
	jsr xgetparm_n
	sta path2+1
	sty path2
	sta info2_path+1
	sty info2_path

	jsr mli
	.byte mli_gfinfo
	.addr info1_parms
	bcs outa_here

	jsr mli
	.byte mli_gfinfo
	.addr info2_parms
	bcc got_both
	cmp #err_filnotfnd
	bne outa_here

	lda #'q'+$80
	jsr xgetparm_ch
	bcc quiet
	jsr printp2
	jsr xmess
	cstr_cr " does not exist!"
quiet:	rts

got_both:
	lda info1_mdate
	ora info1_mdate+1
	ora info1_mtime
	ora info1_mtime+1
	bne got1

	jsr printp1
no_date:
	jsr xmess
	cstr_cr ":  no mod date/time available"
	rts

got1:	lda info2_mdate
	ora info2_mdate+1
	ora info2_mtime
	ora info2_mtime+1
	bne got2

	jsr printp2
	jmp no_date

got2:	jsr compare
	php
	lda #0
	sta count
	lda #'o'+$80
	jsr xgetparm_ch
	bcs skip1
	inc count
skip1:	lda #'n'+$80
	jsr xgetparm_ch
	bcs skip2
	inc count
skip2:	lda #'s'+$80
	jsr xgetparm_ch
	bcs skip3
	inc count
skip3:	lda count
	bne specific
;
; (file1) <?> (file2)
;
	jsr printp1
	lda #' '+$80
	jsr cout
	plp
	jsr print_rel
	lda #' '+$80
	jsr cout
	jsr printp2
	jmp crout

print_rel:
	beq print_eq
	bcs print_gr
	lda #'<'+$80
	jmp cout
print_gr:
	lda #'>'+$80
	jmp cout
print_eq:
	lda #'='+$80
	jmp cout

specific:
	plp
	beq cmp_equal
	bcs cmp_firstnew
;
; first is older
;
	lda #'o'+$80
	jsr xgetparm_ch
	bcs fergit_it
print_it:
	jsr printp1
	jmp crout
fergit_it:
	rts
;
; equal
;
cmp_equal:
	lda #'s'+$80
	jsr xgetparm_ch
	bcc print_it
	rts
;
; first is newer
;
cmp_firstnew:
	lda #'n'+$80
	jsr xgetparm_ch
	bcc print_it
	rts
;********************************************
compare:
; [TODO] Y2K ??? see 'update' logic
	lda info1_mdate+1
	cmp info2_mdate+1
	bne didcmp
	lda info1_mdate
	cmp info2_mdate
	bne didcmp
	lda info1_mtime+1
	cmp info2_mtime+1
	bne didcmp
	lda info1_mtime
	cmp info2_mtime
didcmp:	rts

;*********************************************
info1_parms:	.byte 10
info1_path:	.res 2
info1_access:	.res 1
info1_ftype:	.res 1
info1_aux:	.res 2
info1_stype:	.res 1
info1_blocks:	.res 2
info1_mdate:	.res 2
info1_mtime:	.res 2
info1_cdate:	.res 2
info1_ctime:	.res 2
;
info2_parms:	.byte 10
info2_path:	.res 2
info2_access:	.res 1
info2_ftype:	.res 1
info2_aux:	.res 2
info2_stype:	.res 1
info2_blocks:	.res 2
info2_mdate:	.res 2
info2_mtime:	.res 2
info2_cdate:	.res 2
info2_ctime:	.res 2
;*********************************************
printp1:
	lda path1+1
	ldy path1
	jmp xprint_path

printp2:
	lda path2+1
	ldy path2
	jmp xprint_path
