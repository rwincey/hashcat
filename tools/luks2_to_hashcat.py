#!/usr/bin/env python3

#
# Author......: Netherlands Forensic Institute
# License.....: MIT
#

from argparse import ArgumentParser
import logging
import sys
import json
from base64 import b64decode

logging.basicConfig(format="%(asctime)s %(levelname)-8s %(message)s",
    level=logging.WARNING)

def main():
  parser = ArgumentParser(description="Extract LUKS2 parameters from a LUKS2 image to a format useable by Hashcat with entropy check.")
  parser.add_argument('-i', '--input', dest='inName', metavar='in', required=False, help="input file")
  parser.add_argument('-o', '--output', dest='outName', metavar='out', required=False, help="output file")
  parser.add_argument('--verbose', '-v', dest='verbosity', action='count', default=0, help="increase verbosity")
  args = parser.parse_args()

  if args.verbosity == 1:
    logging.getLogger().setLevel(logging.INFO)
  elif args.verbosity > 1:
    logging.getLogger().setLevel(logging.DEBUG)

  if args.inName is not None:
    try:
      inFile = open(args.inName, 'rb')
    except OSError as ex:
      logging.error(f"Failed to open input file '{args.inName}': {ex}")
      return 1
  else:
    inFile = sys.stdin.buffer

  if args.outName is not None:
    try:
      outFile = open(args.outName, 'w')
    except OSError as ex:
      logging.error(f"Failed to open input file '{args.outName}': {ex}")
      return 1
  else:
    outFile = sys.stdout

  inFile.seek(0x1000)
  json_data = inFile.read(32768)
  json_end = json_data.find(b"\x00")
  json_header = json.loads(json_data[:json_end])

  # print("\nWe got the following large json header:\n")
  # print(json.dumps(json_header, indent=4))

  keyslot_offset = int(json_header['keyslots']['0']['area']['offset'])
  keyslot_size = int(json_header['keyslots']['0']['area']['key_size'])
  encryption = json_header['keyslots']['0']['area']['encryption']

  (cipher_type, cipher_mode) = tuple(encryption.split("-", 1))

  inFile.seek(keyslot_offset)
  keyslot_encrypted_data = inFile.read(256000) #don't yet know how to calculate this length exactly

  blocknumbers = int(json_header['keyslots']['0']['af']['stripes'])
  hash_mode = json_header['keyslots']['0']['af']['hash']

  # Include first sector of the segment for entropy check
  segment_offset = int(json_header['segments']['0']['offset'])
  inFile.seek(segment_offset)
  first_sector = inFile.read(512)

  kdf = json_header['keyslots']['0']['kdf']['type']
  time = int(json_header['keyslots']['0']['kdf']['time'])
  memory = int(json_header['keyslots']['0']['kdf']['memory'])
  cpus = int(json_header['keyslots']['0']['kdf']['cpus'])
  salt = b64decode(json_header['keyslots']['0']['kdf']['salt'])

  key_size = int(json_header['keyslots']['0']['key_size']) * 8

  hash_string = (f"$luks$2${kdf}${hash_mode}${cipher_type}${cipher_mode}${key_size}$m={memory},t={time},p={cpus}${salt.hex()}$"
        f"{keyslot_encrypted_data.hex()}${first_sector.hex()}")

  outFile.write(hash_string)
  outFile.write("\n")

  if args.outName is not None:
    outFile.close()

  if args.inName is not None:
    inFile.close()

  return 0


if __name__ == "__main__":
  exitCode = main()
  sys.exit(exitCode)

