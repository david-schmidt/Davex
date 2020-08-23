// cl65 -Oi -t apple2 -C apple2-DavexXC.cfg --start-addr 0x9000 main.c DavexXC.s -o result -Wl -v

#include <string.h>

extern const char gDescription[];
extern void STARTUP();

#define kMyVersion 0x10
#define kMinDavexVersion 0x14
#define kMinDavexVersionMinor 0

#define PARM_COUNT 1

struct XCHeader
{
	unsigned char fRTS, fEE1, fEE2;
	unsigned char fXCVersion, fDavexVersion;
	unsigned char fHarewareRequirements;
	const char* fDescription;
	const struct XCHeader* fOrigin;
	void (*fEntryPoint)();
	unsigned char fMinDavedVersionMinor;
	unsigned char fReserved1, fReserved2, fReserved3;
	unsigned char fParameters[PARM_COUNT][2];	// pairs of bytes, ending with 0,0
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
	{ 0, 0 }
};

const char gDescription[] = "\x17This is the description";


extern void __fastcall__ xprint_ver(unsigned char);
extern void __fastcall__ xpoll_io();
extern unsigned char __fastcall__ xgetnump();

// #define FUNC(addr) ((void __fastcall__ (*)())addr)
// void __fastcall__ xpoll_io() { FUNC(0xB05B)(); }

void main()
{
	xprint_ver(0x42);
	xprint_ver(strlen((char*)0x200));
	xpoll_io();
	xprint_ver(xgetnump());
}

