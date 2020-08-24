#include <stdio.h>
#include <string.h>

extern const char gDescription[];
extern void STARTUP();

#define kMyVersion 0x10
#define kMinDavexVersion 0x14
#define kMinDavexVersionMinor 0

#define PARM_COUNT 5

// [TODO] Move this into DavexXC.h:

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

struct XCHeader
{
	unsigned char fRTS, fEE1, fEE2;
	unsigned char fXCVersion, fDavexVersion;
	unsigned char fHardwareRequirements;
	const char* fDescription;
	const struct XCHeader* fOrigin;
	void (*fEntryPoint)();
	unsigned char fMinDavexVersionMinor;
	unsigned char fReserved1, fReserved2, fReserved3;
	unsigned char fParameters[PARM_COUNT+1][2];	// pairs of bytes, ending with 0,0
};


const struct XCHeader gCommandHeader =
{
	0x60, 0xEE, 0xEE,
	kMyVersion,
	kMinDavexVersion,
	0,	// hardware requirements
	gDescription,
	&gCommandHeader,
	STARTUP,
	kMinDavexVersionMinor,
	0, 0, 0,
	// Parameters
	{
		{ 0x80+'a', t_nil },	// ASCII only
		{ 0x80+'h', t_nil },	// hex only
		{ 0x80+'o', t_nil },	// no offsets
		{ 0x80+'s', t_int3 },	// starting offset
		{ 0x80+'e', t_int3 },	// ending offset
		{ 0, 0 }
	}
};

const char gDescription[] = "\x17This is the description";


extern void __fastcall__ xprint_ver(unsigned char);
extern void __fastcall__ xpoll_io();
extern unsigned char __fastcall__ xgetnump();

// #define FUNC(addr) ((void __fastcall__ (*)())addr)
// void __fastcall__ xpoll_io() { FUNC(0xB05B)(); }

int kFive = 5;

void main()
{
	puts("Testing 2 3 4: ");
	xprint_ver(0x42);
	putchar('\r');
	xprint_ver(kFive);
	putchar('\r');
	xprint_ver(strlen((char*)0x200));
	putchar('\r');
	xpoll_io();
	xprint_ver(xgetnump());
	putchar('\r');
}

