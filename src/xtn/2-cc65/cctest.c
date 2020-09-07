#include <stdio.h>
#include <string.h>

extern const char gDescription[];	// forward declaration, because gCommandHeader must come firs

#define kMyVersion 0x10
#define kMinDavexVersion 0x14
#define kMinDavexVersionMinor 0

#define PARM_COUNT 9	// define before including DavexXC.h
#include "DavexXC.h"

const struct XCHeader gCommandHeader =
{
	0x60, 0xEE, 0xEE,
	kMyVersion,
	kMinDavexVersion,
	kRequiresNothingSpecial,
	gDescription,
	&gCommandHeader,
	XC_STARTUP,
	kMinDavexVersionMinor,
	0, 0, 0,
	// Parameters
	{
		{ 0, t_string },		// string
		{ '1', t_int1 },
		{ '2', t_int2 },
		{ '3', t_int3 },
		{ 'X', t_yesno },		// 1.4: 'X' can be distinct from 'x' -- capital option must come before lowercase version
		{ 'x', t_nil },			// optional -x
		{ 'd', t_devnum },
		{ 'f', t_ftype },
		{ 0, 0 }
	}
};

const char gDescription[] = "\x1B" "Davex XC compiled with cc65";

const int kFive = 5;

void Space() { putchar(' '); }

void main()
{
	xprint_ver(0x42); CROUT();
	xprint_sd(0xE0); CROUT();
	xpr_date(0); Space(); xpr_date(0x3333); CROUT();
	xpr_time(0x0A0A); Space(); xpr_time(0x0123); CROUT();
	xprint_ver(kFive); CROUT();
	xprdec_2(520); CROUT();
	xprdec_3(67890L); CROUT();
	xprdec_pad(78901); CROUT();
	xpoll_io();
	xprint_ver(xgetnump());	CROUT();
	xprint_path(xbuild_local("\x06" "config")); CROUT();	// [TODO] "Pascal" strings vs. C strings

	if (xgetparm_ch_nil('x'))
	{
		xmessage("Passed -x");
		CROUT();
	}

	{
		uint8_t yesNo;
		if (xgetparm_ch_byte('X', &yesNo))
		{
			xmessage("Found -X = ");
			PRBYTE(yesNo);
			CROUT();
		}
	}

	{
		uint8_t filetype;
		if (xgetparm_ch_byte('f', &filetype))
		{
			xmessage("Filetype = $");
			PRBYTE(filetype);
			CROUT();
		}
	}
}
