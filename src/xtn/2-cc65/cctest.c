#include <stdio.h>
#include <string.h>

extern const char gDescription[];
extern void STARTUP();

#define kMyVersion 0x10
#define kMinDavexVersion 0x14
#define kMinDavexVersionMinor 0

#define PARM_COUNT 8	// define before including DavexXC.h
#include "DavexXC.h"

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
		{ 0, t_string },		// string
		{ 0x80+'x', t_nil },	// optional -x
		{ 0x80+'y', t_yesno },
		{ 0x80+'1', t_int1 },
		{ 0x80+'2', t_int2 },
		{ 0x80+'3', t_int3 },
		{ 0x80+'d', t_devnum },
		{ 0x80+'f', t_ftype },
		{ 0, 0 }
	}
};

const char gDescription[] = "\x17This is the description";

const int kFive = 5;

void CROUT() { putchar('\r'); }
void Space() { putchar(' '); }

void main()
{
	xmessage("Testing 2 3 4");	// [TODO] _puts is forcing to uppercase -- library not initialized?
	CROUT();
	xprint_ver(0x42); CROUT();
	xprint_sd(0xE0); CROUT();
	xpr_date(0); Space(); xpr_date(0x3333); CROUT();
	xpr_time(0x0A0A); Space(); xpr_time(0x0123); CROUT();
	xprint_ver(kFive); CROUT();
	xprdec_2(520); CROUT();
	xprdec_3(67890L); CROUT();
	xprdec_pad(78901); CROUT();
	xprint_ver(strlen((char*)0x200)); CROUT();
	xpoll_io();
	xprint_ver(xgetnump());	CROUT();
	xprint_path(xbuild_local("\006config")); CROUT();	// [TODO] "Pascal" strings vs. C strings

	if (xgetparm_ch_nil('x'))
		xmessage("Passed -x");
}
