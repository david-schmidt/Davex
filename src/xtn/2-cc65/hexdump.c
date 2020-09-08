#include <stdio.h>
#include <string.h>

const char gDescription[];	// forward declaration, since gCommandHeader must come first

#define kMyVersion 0x01
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
	// Parameters (PARM_COUNT of them)
	{
		{ 0, t_wildpath },
		{ 'H', t_int2 },	// Highlight a specific byte ($bb) or mask-and-compare ($mmbb)
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

uint8_t* gPathname;
uint8_t gRefnum;

uint32_t gStartOffset;
uint32_t gEndOffset;
uint8_t gDevNum;
uint8_t gBlockMode;

uint32_t gOffset;
uint8_t gBytesPerLine;
uint16_t gAmountRead;
bool gIdenticalRowMode;	// current row matches previous row

bool gDumpMemory;
bool gBlockValid;
uint16_t gCurrentBlock;

#define currentRow pagebuff
#define previousRow (pagebuff+128)
bool gFirstRow;

#define err_eof 0x4C	// ProDOS end of file error

uint8_t gHighlightMask;
uint8_t gHighlightValue;

uint8_t ReadSome();
void BailOnError(uint8_t error);
uint8_t Open(uint8_t* pathname, uint8_t* outRefnum);
bool ShouldHighlight(uint8_t);
void ParseHighlightParameter();
bool HandleIdenticalRow();
void PrintOffset();


void main()
{
	_Bool showASCII = xgetparm_ch_nil('a');
	_Bool showHex = xgetparm_ch_nil('h');
	_Bool showOffsets = !xgetparm_ch_nil('o');
	gDumpMemory = xgetparm_ch_nil('m');
	gBlockMode = xgetparm_ch_byte('d', &gDevNum);
	gBlockValid = false;
	ParseHighlightParameter();

	if (!showASCII && !showHex)
		showASCII = showHex = true;

	if (!xgetparm_ch_int3('s', &gStartOffset))
		gStartOffset = 0;
	if (!xgetparm_ch_int3('e', &gEndOffset))
		gEndOffset = 0xFFFFFF;

	if (!xgetparm_n_path(0, &gPathname) || gPathname[0] == 0)
		gPathname = NULL;

	// Exactly 1 of: Pathname, -m, -d.xx
	if ((gPathname != NULL) + gDumpMemory + gBlockMode != 1)
		xProDOS_err(0x80);	// [TODO] der_illegalOption

	if (gPathname != NULL)
		BailOnError(Open(gPathname, &gRefnum));

	gFirstRow = true;
	gBytesPerLine = showHex ? 16 : 64;
	for (gOffset = gStartOffset; gOffset < gEndOffset; gOffset += gAmountRead)
	{
		uint8_t err = ReadSome();
		if (err == err_eof)
			break;
		BailOnError(err);

		if (HandleIdenticalRow())
			continue;

		// "Block n" header if we are right at the start of a block
		if (gBlockMode && (gOffset & 511) == 0)
		{
			xmessage("Block ");
			xprdec_2(gOffset / 512);
			CROUT();
		}

		PrintOffset();
		xmessage(": ");

		if (showHex)
		{
			uint8_t i;
			for (i = 0; i < gAmountRead; ++i)
			{
				uint8_t ch = currentRow[i];
				bool inverse = ShouldHighlight(ch);
				if (inverse)
					SETINV();
				PRBYTE(ch);
				SETNORM();
				Space();
			}
			while (i++ < gBytesPerLine)
				xmessage("   ");
		}

		if (showASCII)
		{
			uint8_t i;
			for (i = 0; i < gAmountRead; ++i)
			{
				uint8_t ch = currentRow[i];
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
	PrintOffset();
	CROUT();
}


// Prints a "*" if we are entering gIdenticalRowMode.
// Returns true if there is no need to output this row.
bool HandleIdenticalRow()
{
	const bool identical = !gFirstRow && memcmp(currentRow, previousRow, gBytesPerLine) == 0;
	gFirstRow = false;
	if (!identical)
		memcpy(previousRow, currentRow, gBytesPerLine);

	if (gAmountRead != gBytesPerLine)
	{
		gIdenticalRowMode = false;		// last line, partial
		return false;
	}

	if (identical && !gIdenticalRowMode)
	{
		xmessage("*\r");
		if (!xcheck_wait())
			xerr();
	}

	gIdenticalRowMode = identical;
	return gIdenticalRowMode;
}


// Prints gOffset: "xxxxxx" (or for Memory, "xx/xxxx")
void PrintOffset()
{
	PRBYTE(gOffset >> 16);
	if (gDumpMemory)
		putchar('/');
	PRBYTE(gOffset >> 8);
	PRBYTE(gOffset);
}


// Sets gHighlightMask and gHighlightValue from -H$mmvv
// If the mask is unspecified, use $FF.
void ParseHighlightParameter()
{
	uint16_t value;
	if (xgetparm_ch_int2('H', &value))
	{
		gHighlightMask = value >> 8;
		if (gHighlightMask == 0)
			gHighlightMask = 0xFF;
		gHighlightValue = value;
	}
	else
	{
		gHighlightMask = 0;
		gHighlightValue = 1;	 // will never match anything
	}
}


bool ShouldHighlight(uint8_t ch)
{
	return (ch & gHighlightMask) == gHighlightValue;
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


void BailOnError(uint8_t error)
{
	if (error)
		xProDOS_err(error);
}

uint8_t Open(uint8_t* pathname, uint8_t* outRefnum)
{
	//	Open = $C8, pcount=3, pathname, io_buffer, refnum (result)
	struct OpenParams { uint8_t count; uint8_t* pathname; uint8_t* ioBuffer; uint8_t refnum; };
	static struct OpenParams openParams = { 3, 0 /* pathname */, 0 /* filebuff */, 0 };
	openParams.pathname = pathname;
	openParams.ioBuffer = filebuff;
	{
		#define OPEN 0xC8
		uint8_t err = ProDOS(OPEN, &openParams);
		*outRefnum = openParams.refnum;
		return err;
	}
}

uint8_t SetMark(uint8_t refnum, uint32_t position)
{
	//	SetMark = $CE; pcount=2, ref_num, position
	struct MarkParams { uint8_t count; uint8_t refnum; uint32_t position; };
	static struct MarkParams markParams = { 2, 0 /* refnum */, 0 /* position */ };
	markParams.refnum = refnum;
	markParams.position = position;
	#define SET_MARK 0xCE
	return ProDOS(SET_MARK, &markParams);
}

uint8_t Read(uint8_t refnum, uint8_t* dataBuffer, uint16_t requestCount, uint16_t* outTransferCount)
{
	//	Read = $CA, pcount=4, ref_num, data_buffer(2), request_count(2), trans_count(2)
	struct ReadParams { uint8_t count; uint8_t refnum; uint8_t* buffer; uint16_t requestCount; uint16_t transferCount; };
	static struct ReadParams readParams = { 4, 0 /* refnum */, 0 /* buffer */, 0 /* requestCount */, 0 };
	readParams.refnum = refnum;
	readParams.buffer = dataBuffer;
	readParams.requestCount = requestCount;
	{
		#define READ 0xCA
		uint8_t err = ProDOS(READ, &readParams);
		*outTransferCount = readParams.transferCount;
		return err;
	}
}


uint8_t GetBlockIntoFileBuff2(uint16_t block)
{
	struct RWBlockParams { uint8_t count; uint8_t devnum; uint8_t* buffer; uint16_t block; };
	static struct RWBlockParams blockParams = { 3, 0 /* dev */, filebuff2, 0 };

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
			currentRow[i] = ByteFromMemory(gOffset + i);
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
			BailOnError(GetBlockIntoFileBuff2(offset / 512));

			currentRow[i] = filebuff2[withinBlock];
		}
		gAmountRead = gBytesPerLine;
		return 0;
	}

	BailOnError(SetMark(gRefnum, gOffset));
	return Read(gRefnum, currentRow, gBytesPerLine, &gAmountRead);
}
