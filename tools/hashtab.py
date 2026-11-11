#!/usr/bin/env python3
"""Work with qmldiff hash tables and hashed .qmd files.

  hashtab.py check   <hashtab> <file.qmd>   exit 1 if the file needs a name the firmware lacks
  hashtab.py unhash  <hashtab> <file.qmd>   print the file with real names
  hashtab.py version <hashtab>              print the firmware version the table was built on
"""
import re
import struct
import sys

MASK = (1 << 64) - 1
TOKEN = re.compile(r'~&(")?(\d+)&~|\[\[([\d.]+)\]\]')


def qhash(text):
    """The hash qmldiff uses for names (djb2 with a 5481 seed)."""
    h = 5481
    for byte in text.encode():
        h = (h * 33 + byte) & MASK
    return h


def load(path):
    data = open(path, "rb").read()
    table, pos = {}, 0
    while pos < len(data):
        key, length = struct.unpack(">QI", data[pos:pos + 12])
        pos += 12
        table[key] = data[pos:pos + length].decode()
        pos += length
    return table


def version(path):
    """The second record of a hash table holds the firmware version."""
    data = open(path, "rb").read()
    pos = 12 + struct.unpack(">QI", data[:12])[1]
    length = struct.unpack(">QI", data[pos:pos + 12])[1]
    return data[pos + 12:pos + 12 + length].decode()


def missing(table, text):
    """Return (line number, hash) for every hash in text the table lacks."""
    out = []
    for number, line in enumerate(text.splitlines(), 1):
        for match in TOKEN.finditer(line):
            parts = [match.group(2)] if match.group(2) else match.group(3).split(".")
            out += [(number, int(p)) for p in parts if int(p) not in table]
    return out


def unhash(table, text):
    def swap(match):
        if match.group(2):
            name = table.get(int(match.group(2)))
            if name is None:
                return match.group(0)
            return '"%s"' % name if match.group(1) else name
        names = [table.get(int(p)) for p in match.group(3).split(".")]
        return match.group(0) if None in names else ".".join(names)
    return TOKEN.sub(swap, text)


def main(argv):
    if len(argv) == 3 and argv[1] == "version":
        print(version(argv[2]))
        return 0
    if len(argv) != 4 or argv[1] not in ("check", "unhash"):
        print(__doc__)
        return 2
    table, text = load(argv[2]), open(argv[3]).read()
    if argv[1] == "unhash":
        sys.stdout.write(unhash(table, text))
        return 0
    gone = missing(table, text)
    for number, value in gone:
        print("%s:%d: firmware %s has no name for hash %d" % (argv[3], number, version(argv[2]), value))
    if not gone:
        print("ok: every hashed name in %s exists on firmware %s" % (argv[3], version(argv[2])))
    return 1 if gone else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
