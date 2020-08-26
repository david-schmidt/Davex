
#include <stdbool.h>
#include <stdint.h>

enum
{
	t_nil		= 0,	// parameter with no associated value
	t_int2		= 1,	// 2-byte integer
	t_int3		= 2,	// 3-byte integer
	t_path		= 3,	// pathname
	t_wildpath	= 4,	// pathname allowing wildcards
	t_string	= 5,	// string
	t_int1		= 6,	// 1-byte integer
	t_yesno		= 7,	// Yes/No
	t_ftype		= 8,	// filetype
	t_devnum	= 9		// device number (.sd)
};

enum XCHardwareRequirements
{
	kRequires40ColumnScreen = 0b10000000,
	kRequires80ColumnScreen = 0b01000000,
	kRequiresIIeOrIIgs = 0b00100000,
	kRequiresIIc = 0b00010000,
	kRequiresIIgs = 0b00001000
};

struct XCHeader
{
	uint8_t fRTS, fEE1, fEE2;
	uint8_t fXCVersion, fDavexVersion;
	uint8_t fHardwareRequirements;
	const uint8_t* fDescription;
	const struct XCHeader* fOrigin;
	void (*fEntryPoint)();
	uint8_t fMinDavexVersionMinor;
	uint8_t fReserved1, fReserved2, fReserved3;
	uint8_t fParameters[PARM_COUNT+1][2];	// pairs of bytes, ending with 0,0
};

// #define FUNC(addr) ((void __fastcall__ (*)())addr)
// void __fastcall__ xpoll_io() { FUNC(0xB05B)(); }


extern _Bool __fastcall__ xgetparm_ch_nil(uint8_t optionCharacter);
extern _Bool __fastcall__ xgetparm_ch_byte(uint8_t optionCharacter, uint8_t* outValue); // int1, filetype, devnum, yesno
extern _Bool __fastcall__ xgetparm_ch_int2(uint8_t optionCharacter, uint16_t* outValue);
extern _Bool __fastcall__ xgetparm_ch_int3(uint8_t optionCharacter, uint32_t* outValue);
extern _Bool __fastcall__ xgetparm_ch_string(uint8_t optionCharacter, uint8_t** outString);
extern _Bool __fastcall__ xgetparm_ch_path(uint8_t optionCharacter, uint8_t** outPath);
extern _Bool __fastcall__ xgetparm_ch_path_and_filetype(uint8_t optionCharacter, uint8_t** outPath, uint8_t* outFiletype);

extern _Bool __fastcall__ xgetparm_n_byte(uint8_t index, uint8_t* outValue); // int1, filetype, devnum, yesno
extern _Bool __fastcall__ xgetparm_n_int2(uint8_t index, uint16_t* outValue);
extern _Bool __fastcall__ xgetparm_n_int3(uint8_t index, uint32_t* outValue);
extern _Bool __fastcall__ xgetparm_n_string(uint8_t index, uint8_t** outString);
extern _Bool __fastcall__ xgetparm_n_path(uint8_t index, uint8_t** outPath);
extern _Bool __fastcall__ xgetparm_n_path_and_filetype(uint8_t index, uint8_t** outPath, uint8_t* outFiletype);

extern void __fastcall__ xmessage(const uint8_t*); // calls puts() for now
extern void __fastcall__ xprint_ftype(uint8_t); // print a filetype
extern void __fastcall__ xprint_access(uint8_t); // print a ProDOS access byte (r/w/n/d/etc)
extern void __fastcall__ xprdec_2(uint16_t); // print 2-byte value in decimal
extern void __fastcall__ xprdec_3(uint32_t); // print 3-byte value in decimal
extern void __fastcall__ xprdec_pad(uint32_t); // print 3-byte value in decimal, right-justified in a 7-character field
extern void __fastcall__ xprint_path(const uint8_t*);
extern uint8_t* __fastcall__ xbuild_local(uint8_t* path);	// builds a path relative to the "%" directory
extern void __fastcall__ xprint_sd(uint8_t slotAndDrive);
// extern void __fastcall__ xprint_drvr(); // TODO
extern uint8_t __fastcall__ xredirect(int8_t adjustment);
extern uint8_t __fastcall__ xpercent(uint32_t value, uint32_t total);
extern _Bool __fastcall__ xyesno();
extern uint8_t __fastcall__ xyesno2(uint8_t defaultChar); // v1.2
extern _Bool __fastcall__ xgetln(); // result is in "string" (TODO: call it "xString" or something?)
extern void __fastcall__ xbell();
extern uint8_t __fastcall__ xdowncase(uint8_t ch);
extern void __fastcall__ xplural(uint16_t value);
extern _Bool __fastcall__ xcheck_wait();
extern void __fastcall__ xpr_date(uint16_t date);
extern void __fastcall__ xpr_time(uint16_t time);
extern void __fastcall__ xProDOS_err(uint8_t err);	// does not return
extern void __fastcall__ xProDOS_er(uint8_t err);
extern void __fastcall__ xerr();	// does not return
extern void __fastcall__ xprdec_pad_n(uint32_t value, uint8_t widthMinusOne);
extern void __fastcall__ xdir_setup(uint8_t* path); // path is complete, or relative to the prefix (see xdir_setup2)
extern void __fastcall__ xdir_setup2(uint8_t* path); // v1.23 - path is complete, or relative to the already-open directory
extern void __fastcall__ xdir_finish();
extern _Bool __fastcall__ xread1dir(); // if returns true, result is in "catbuff"
extern void __fastcall__ xpmgr(); // TODO -- split into _append, _appendChar, _trailingSlashIfNeeded, _removeLastSegment, _copy
extern void __fastcall__ xmmgr(); // TODO -- split into xmmgr_free_all, xmmgr_allocate, xmmgr_lowest_free_page, _highest_allocatable_page, _set_highest_page
extern void __fastcall__ xpoll_io();
extern void __fastcall__ xprint_ver(uint8_t version);
extern void __fastcall__ xpush_level(); // call before dir_setup
extern _Bool __fastcall__ xfman_open(uint8_t* path, uint8_t* outRefnumOrError);
extern _Bool __fastcall__ xfman_read(uint8_t refnum, uint8_t* outCharOrError);

extern uint8_t __fastcall__ xrdkey(); // ;v1.1
extern void __fastcall__ xdirty();	// v1.1
extern uint8_t __fastcall__ xgetnump(); // v1.1

// [TODO] extern void __fastcall__ xshell_info(unsigned char selector); // v1.25 // [TODO] Return value varies?
//	input:  X=request code
//	output: CLC, requested information in registers/etc.
//			SEC, requested information not available
//
//	X=0:  Get Davex version in A, Y.
//		  For version $a.bc, A=$ab and Y=$0c.
//	X=1:  Get alias buffer (AY=address, X=size in pages)
//	X=2:  Get history buffer (AY=address, X=size in pages)
//	X=3:  Get internal filetype table (AY=address)
//	X=4:  Get internal filetype name table (AY=address)

//

// [TODO] External commands may use 'filebuff', 'filebuff2', and 'filebuff3', defined in GLOBALS; each one is $400 bytes long.

// [TODO] The high bit of 'xspeech' is on when a speech synthesizer is being used.

