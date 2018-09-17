;
; ProDOS global equates for Davex
;
mli	= $bf00
datetime	= $bf06
syserr	= $bf09
sysdeath	= $bf0c
serr	= $bf0f ;error code
devnum	= $bf30
devcnt	= $bf31
devlst	= $bf32

bitmap	= $bf58
BitMapSize	= 24

date	= $bf90
time	= $bf92
level	= $bf94
bubit	= $bf95

machid	= $bf98
sltbyt	= $bf99
pfixptr	= $bf9a
mliactv	= $bf9b
cmdadr	= $bf9c

iversion	= $bffd ;sys prog version
kversion	= $bfff ;version # of ProDOS

;
; MLI call numbers
;
mli_bye	= $65
mli_create	= $c0
mli_destroy	= $c1
mli_rename	= $c2
mli_sfinfo	= $c3
mli_gfinfo	= $c4
mli_online	= $c5
mli_setpfx	= $c6
mli_getpfx	= $c7
mli_open	= $c8
mli_newline	= $c9
mli_read	= $ca
mli_write	= $cb
mli_close	= $cc
mli_flush	= $cd
mli_setmark	= $ce
mli_getmark	= $cf
mli_seteof	= $d0
mli_geteof	= $d1
mli_setbuf	= $d2
mli_getbuf	= $d3
mli_gettime	= $82
mli_allocint	= $40
mli_deallint	= $41
mli_readblk	= $80
mli_writeblk	= $81

;
; standard file types
;
tBAD	= 1
tTXT	= 4
tBIN	= 6
tDIR	= $f
tCMD	= $f0
tINT	= $fa
tIVR	= $fb
tBAS	= $fc
tVAR	= $fd
tREL	= $fe
tSYS	= $ff
tAWP	= $1a
tS16	= $b3
tSRC	= $b0

;
; error codes
;
err_ok	= $00
err_badcall	= $01
err_badcnt	= $04
err_ifull	= $25
err_io	= $27
err_nodev	= $28
err_wrprot	= $2b
err_switched	= $2e
err_2slow	= $33
err_2fast	= $34
err_pnsyntax	= $40
err_fcbfull	= $42
err_ivlref	= $43
err_dirnotfnd	= $44
err_volnotfnd	= $45
err_filnotfnd	= $46
err_dupfil	= $47
err_full	= $48
err_dirfull	= $49
err_filfmt	= $4a
err_strgtype	= $4b
err_eof	= $4c
err_badpos	= $4d
err_locked	= $4e
err_filopen	= $50
err_dircnt	= $51
err_notprodos	= $52
err_ivlparm	= $53
err_vcbtfull	= $55
err_badbufadr	= $56
err_dupvol	= $57
err_badmap	= $5a
