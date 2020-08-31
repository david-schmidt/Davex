#include <stdio.h>
#include <string.h>

const char gDescription[];	// forward declaration, since gCommandHeader must come first

#define kMyVersion 0x01
#define kMinDavexVersion 0x14
#define kMinDavexVersionMinor 0

#define PARM_COUNT 8	// define before including DavexXC.h
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
	// Parameters (PARM_COUNT of them)
	{
		{ 0, t_wildpath },
		{ 'd', t_devnum },
		{ 'a', t_nil }, // ASCII only
		{ 'h', t_nil }, // Hex only
		{ 'o', t_nil }, // no Offsets displayed
		{ 'm', t_nil }, // dump Memory
		{ 's', t_int3 }, // Starting offset
		{ 'e', t_int3 }, // Ending offset
		{ 0, 0 }
	}
};

const char gDescription[] = "\x22" "Dump a file or memory in hex/ASCII";

void Space() { putchar(' '); }

uint32_t gStartOffset;
uint32_t gEndOffset;
uint8_t gDevNum;
uint8_t gBlockMode;

uint32_t gOffset;
uint8_t gBytesPerLine;
uint16_t gAmountRead;

bool gDumpMemory;
bool gBlockValid;

uint16_t gCurrentBlock;


#define err_eof 0x4C	// ProDOS end of file error

uint8_t ReadSome();
bool ShouldHighlight(uint8_t);

void main()
{
	_Bool showASCII = xgetparm_ch_nil('a');
	_Bool showHex = xgetparm_ch_nil('h');
	_Bool showOffsets = !xgetparm_ch_nil('o');
	gDumpMemory = xgetparm_ch_nil('m');
	gBlockMode = xgetparm_ch_byte('d', &gDevNum);
	gBlockValid = false;

	if (!showASCII && !showHex)
		showASCII = showHex = true;

	if (!xgetparm_ch_int3('s', &gStartOffset))
		gStartOffset = 0;
	if (!xgetparm_ch_int3('e', &gEndOffset))
		gEndOffset = 0xFFFFFF;

	{
		gBytesPerLine = showHex ? 16 : 64;
		for (gOffset = gStartOffset; gOffset < gEndOffset; gOffset += gBytesPerLine)
		{
			uint8_t err = ReadSome();
			if (err == err_eof)
				break;
			if (err != 0)
				xProDOS_err(err);	// does not return

			// "Block n"
			if (gBlockMode && (gOffset & 511) == 0)
			{
				xmessage("Block ");
				xprdec_2(gOffset / 512);
				CROUT();
			}

			// Offset:
			PRBYTE(gOffset >> 16);
			if (gDumpMemory)
				putchar('/');
			PRBYTE(gOffset >> 8);
			PRBYTE(gOffset);
			xmessage(": ");

			if (showHex)
			{
				uint8_t i;
				for (i = 0; i < gBytesPerLine; ++i)
				{
					uint8_t ch = pagebuff[i];
					bool inverse = ShouldHighlight(ch);
					if (inverse)
						SETINV();
					PRBYTE(ch);
					SETNORM();
					Space();
				}
			}

			if (showASCII)
			{
				uint8_t i;
				for (i = 0; i < gBytesPerLine; ++i)
				{
					uint8_t ch = pagebuff[i];
					bool inverse = ShouldHighlight(ch);
					uint8_t ch7 = ch | 0x80;
					if (inverse)
						SETINV();
					if (ch7 > 0xA0)
						COUT(ch7);
					else
						putchar('.');
					SETNORM();
				}
			}

			CROUT();
			if (!xcheck_wait())
				return;
		}
	}
}


bool ShouldHighlight(uint8_t ch)
{
	// [TODO] parse command-line options to specify what data to highlight
	if (gDumpMemory)
		return ch >= 0x80;

	if (gBlockMode)
		return ch == 0x4C;

	return false;
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


uint8_t GetBlockIntoFileBuff(uint16_t block)
{
	struct RWBlockParams { uint8_t count; uint8_t devnum; uint8_t* buffer; uint16_t block; };
	static struct RWBlockParams blockParams = { 3, 0 /* dev */, filebuff, 0 };

	if (gBlockValid && block == gCurrentBlock)
		return 0;

	#define READ_BLOCK 0x80
	blockParams.devnum = gDevNum;
	blockParams.block = block;
	{
		uint8_t err = ProDOS(READ_BLOCK, &blockParams);
		if (err == 0)
		{
			gBlockValid = true;
			gCurrentBlock = block;
		}
		return err;
	}
}

// Returns a ProDOS error code. Sets gAmountRead so we can stop at the end of the file.
uint8_t ReadSome()
{
	if (gDumpMemory)
	{
		// Read from gOffset to gOffset+gBytesPerLine-1
		uint8_t i;
		for (i = 0; i < gBytesPerLine; ++i)
			pagebuff[i] = ByteFromMemory(gOffset + i);
		gAmountRead = gBytesPerLine;
		return 0; // noErr
	}

	if (gBlockMode)
	{
		uint8_t i;
		for (i = 0; i < gBytesPerLine; ++i)
		{
			uint32_t offset = gOffset + i;
			uint16_t withinBlock = offset & 511;
			uint8_t err = GetBlockIntoFileBuff(offset / 512);
			if (err)
				xProDOS_err(err);

			pagebuff[i] = filebuff[withinBlock];
		}
		gAmountRead = gBytesPerLine;
		return 0;
	}

	xProDOS_err(0xFF);	// [TODO] files not supported yet
}

