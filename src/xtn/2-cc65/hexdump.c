#include <stdio.h>
#include <string.h>

const char gDescription[];	// forward declaration, since gCommandHeader must come first

#define kMyVersion 0x01
#define kMinDavexVersion 0x14
#define kMinDavexVersionMinor 0

#define PARM_COUNT 7	// define before including DavexXC.h
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
		{ 0, t_wildpath },
		{ 0x80+'a', t_nil }, // ASCII only
		{ 0x80+'h', t_nil }, // Hex only
		{ 0x80+'o', t_nil }, // no Offsets displayed
		{ 0x80+'m', t_nil }, // dump Memory
		{ 0x80+'s', t_int3 }, // Starting offset
		{ 0x80+'e', t_int3 }, // Ending offset
		{ 0, 0 }
	}
};

const char gDescription[] = "\x22" "Dump a file or memory in hex/ASCII";

void CROUT() { putchar('\r'); }
void Space() { putchar(' '); }

uint32_t gStartOffset;
uint32_t gEndOffset;

uint32_t gOffset;
uint8_t gBytesPerLine;
uint16_t gAmountRead;

_Bool gDumpMemory;

#define pagebuff ((uint8_t*)0x800)
#define err_eof 0x4C	// ProDOS end of file error

uint8_t ReadSome();

void main()
{
	_Bool showASCII = xgetparm_ch_nil('a');
	_Bool showHex = xgetparm_ch_nil('h');
	_Bool showOffsets = !xgetparm_ch_nil('o');
	gDumpMemory = xgetparm_ch_nil('m');

	if (!showASCII && !showHex)
		showASCII = showHex = true;

	if (!xgetparm_ch_int3('s', &gStartOffset))
		gStartOffset = 0;
	if (!xgetparm_ch_int3('e', &gEndOffset))
		gEndOffset = 0xFFFFFF;

	{
		const uint8_t bytesPerLine = showHex ? 16 : 64;
		for (gOffset = gStartOffset; gOffset < gEndOffset; gOffset += bytesPerLine)
		{
			uint8_t err = ReadSome();
			if (err == err_eof)
				break;
			if (err != 0)
				xProDOS_err(err);	// does not return

#if 0 // using printf() added 1,885 bytes
			if (showOffsets)
				printf("%06lX: ", offset);
#else
			PRBYTE(gOffset >> 16);
			if (gDumpMemory)
				putchar('/');
			PRBYTE(gOffset >> 8);
			PRBYTE(gOffset);
//			fputs(": ", stdout);	// fputs() works, but it adds 80 bytes (in addition to puts() overhead)
			xmessage(": ");
#endif

			if (showHex)
			{
				uint8_t i;
				for (i = 0; i < bytesPerLine; ++i)
				{
					PRBYTE(pagebuff[i]);
					Space();
				}
			}

			if (showASCII)
			{
				uint8_t i;
				for (i = 0; i < bytesPerLine; ++i)
				{
					uint8_t ch = pagebuff[i] | 0x80;
					if (ch > 0xA0)
						putchar(ch);
					else
						putchar('.');
				}
			}

			CROUT();
			if (!xcheck_wait())
				return;
		}
	}
}


uint8_t ByteFromMemory(uint32_t addr)
{
	const uint8_t bank = addr >> 16;

	// Not safe to read: $00C0xx, $01C0xx, $E0C0xx, $E1C0xx
	if ((bank & ~1) == 0 || (bank & ~1) == 0xE0)
	{
		const uint8_t page = addr >> 8;
		if (page == 0xC0)
			return 0x77;
	}

	// [TODO] Language Card memory read (-L1, -L2)
	// [TODO] Auxmem memory read ($01xxxx)

	// [TODO] Apple IIgs memory read
	if (bank > 0)
		return 0xEE;

	return *(uint8_t*)addr;
}

// Returns a ProDOS error code; [TODO] sets gAmountRead? so we can stop at the end of the file
uint8_t ReadSome()
{
	if (gDumpMemory)
	{
		// Read from offset to offset+bytesPerLine-1
		uint8_t i;
		for (i = 0; i < gBytesPerLine; ++i)
			pagebuff[i] = ByteFromMemory(gOffset + i);
		gAmountRead = gBytesPerLine;
		return 0; // noErr
	}

	xProDOS_err(0xFF);	// [TODO] files not supported yet
}

