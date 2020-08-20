#!/usr/bin/python3

# index create indexed.help <index-size-in-bytes>
# index add    indexed.help <text-file-to-add> [additional-entry-name-aliases-for-this-file]

# Format of an indexed file is:
#
# +000  $00 DvxIdx $00
# +008  Offset_to_text  (4 bytes)
# +012  Offset_to_index (4 bytes)
# +016  Offset_to_free_index_space (4 bytes)
# +020  <reserved, 32 bytes>
# +052  start of index
#
# Index is:
#   length-pfx'd string, offset(4), uncompressed-length(4)
#    :
#   $00
#
# Text chunks are terminated by a $00. The data
# is compressed, with 16 common characters using
# only 5 bits (%1xxxx), and the remaining ones
# using 8 bits (%0xxxxxxx).

import sys, struct, os.path

SixteenCommonBytes = " etoaisrn\x0dldhpcf"	# Frozen for original format indexed.help files (see index.asm and shell main.asm)

def Compress(ch):
	fourBits = SixteenCommonBytes.find(chr(ch))
	if fourBits != -1:
		return "{:0>5b}".format(16 + fourBits)
	return "{:0>8b}".format(ch)

verb = sys.argv[1]
indexFile = sys.argv[2]

if verb == "create":
	indexSize = int(sys.argv[3])
	offsetToIndex = 52
	offsetOfText = offsetToIndex + indexSize

	outFile = open(indexFile, "wb")
	outFile.write(bytes("\x00DvxIdx\x00", "utf8"))
	outFile.write(struct.pack('i', offsetOfText))
	outFile.write(struct.pack('i', offsetToIndex))
	outFile.write(struct.pack('i', offsetToIndex))  # start of free space in index
	for pad in range(8):
		outFile.write(struct.pack('i', 0))	# 8 four-byte integers: reserved

	outFile.seek(offsetOfText - 1)
	outFile.write(struct.pack('B', 0))
	exit(0)

if verb == "add":
	outFile = open(indexFile, "r+b")
	addFilePath = sys.argv[3]
	addFile = open (addFilePath, "r")
	addLines = addFile.readlines()
	addFileUncompressedSize = addFile.tell()
	addFile.close()

	# Read offsetOfText -- the index can't extend that far
	outFile.seek(8) # read offsetOfText from +008
	data = outFile.read(4)
	offsetOfText = int.from_bytes(data, "little")

	# End-of-file offset is where we will put the new chunk of compressed text.
	outFile.seek(0, 2) # end of file
	offsetToNewText = outFile.tell()

	# Seek to free index space
	outFile.seek(16)
	data = outFile.read(4)
	freeIndexSpace = int.from_bytes(data, "little")

	# Write new index entry: length-byte, string name, 4-byte offset to start of text, 4-byte length of (compressed?) text
	entryName = os.path.basename(addFilePath).lower()
	outFile.seek(freeIndexSpace)
	outFile.write(struct.pack('B', len(entryName)))
	outFile.write(bytes(entryName, "utf8"))
	outFile.write(struct.pack('i', offsetToNewText))
	outFile.write(struct.pack('i', addFileUncompressedSize))

	# Optionally write additional index entries for the same text we are adding.
	for extraName in sys.argv[4:]:
		outFile.write(struct.pack('B', len(extraName)))
		outFile.write(bytes(extraName, "utf8"))
		outFile.write(struct.pack('i', offsetToNewText))
		outFile.write(struct.pack('i', addFileUncompressedSize))

	# Update freeIndexSpace in file
	freeIndexSpace = outFile.tell()
	if freeIndexSpace >= offsetOfText:
		print("Error: Overflowed the available index space")
		exit(1)
	outFile.seek(16)
	outFile.write(struct.pack('i', freeIndexSpace))

	# Write the new text
	outFile.seek(offsetToNewText)
	outBinary = ""
	for line in addLines:
		for ch in line.rstrip():
			outBinary += Compress(ord(ch))
		outBinary += Compress(13) # carriage return
	outBinary += Compress(0)

	while len(outBinary) > 0:
		if len(outBinary) < 8:
			outBinary = (outBinary + "0000000")[0:8]
		byte = int(outBinary[0:8], 2)
		outBinary = outBinary[8:]
		outFile.write(struct.pack('B', byte))

	outFile.close()
	exit(0)

print("Unknown verb: " + verb)
exit(1)
