#!/usr/bin/python3

# [TODO] extract filename from pathname
# [TODO] check that we will not overflow the index into the text data
# [TODO] add the extra index entries if requested
# [TODO] what is the 4-byte length field in each entry? I don't think it's ever used, but traditionally the index command has set it to something.

# index create indexed.help <index-size-in-bytes>
# index add    indexed.help <text-file-to-add> [additional-alias-for-this-file]

# Format of an indexed file is:
#
# +000   $00 DvxIdx $00
# +008  Offset_to_text  (4 bytes)
# +012  Offset_to_index (4 bytes)
# +016  Offset_to_free_index_space (4 bytes)
# +020  <reserved, 32 bytes>
# +052  start of index
#
# Index is:
#   length-pfx'd string, offset(4), length(4)
#    :
#   $00
#
# Text chunks are terminated by a $00. The data
# is compressed, with 16 common characters using
# only 5 bits (%1xxxx), and the remaining ones
# using 8 bits (%0xxxxxxx).

import sys, struct

verb = sys.argv[1]
indexFile = sys.argv[2]

if verb == "create":
	indexSize = int(sys.argv[3])
	print("We will create with size = " + str(indexSize))
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
	outFile.write(struct.pack('b', 0))
	exit(0)

if verb == "add":
	outFile = open(indexFile, "r+b")
	addFilePath = sys.argv[3]
	addFile = open (addFilePath, "r")
	addLines = addFile.readlines()
	addFile.close()

	# End-of-file offset is where we will put the new chunk of compressed text.
	outFile.seek(0, 2) # end of file
	offsetToNewText = outFile.tell()

	# Seek to free index space
	outFile.seek(16)
	data = outFile.read(4)
	freeIndexSpace = int.from_bytes(data, "little")
	print("freeIndexSpace = ", freeIndexSpace)

	# Write new index entry: length-byte, string name, 4-byte offset to start of text, 4-byte length of (compressed?) text
	entryName = addFilePath		# [TODO] extract just the filename portion
	outFile.seek(freeIndexSpace)
	outFile.write(struct.pack('b', len(entryName)))
	outFile.write(bytes(entryName, "utf8"))
	outFile.write(struct.pack('i', offsetToNewText))
	outFile.write(struct.pack('i', 0x77777777))	# [TODO] write the length

	# Optionally write additional index entries for the same text we are adding.

	# Update freeIndexSpace in file
	freeIndexSpace = outFile.tell()
	outFile.seek(16)
	outFile.write(struct.pack('i', freeIndexSpace))

	# Write the new text
	outFile.seek(offsetToNewText)
	for line in addLines:
		for ch in line.rstrip():
		    outFile.write(bytes(ch, "utf8"))
		outFile.write(struct.pack('b', 13)) # carriage return
	outFile.write(struct.pack('b', 0))
	outFile.close()
	exit(0)

print("Unknown verb: " + verb)
exit(1)
