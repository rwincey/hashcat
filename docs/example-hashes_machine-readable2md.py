#!/usr/bin/env python3
import sys
import json

# Replace LUKS v1 hashes, they're too big: Github no longer shows the .md "(Sorry about that, but we can’t show files that are this big right now.)"
EXAMPLE_HASH_REPLACEMENTS = {
    "29511": "https://hashcat.net/misc/example_hashes/hashcat_luks_sha1_aes_cbc-essiv_128.txt",
    "29512": "https://hashcat.net/misc/example_hashes/hashcat_luks_sha1_serpent_cbc-plain64_256.txt",
    "29513": "https://hashcat.net/misc/example_hashes/hashcat_luks_sha1_twofish_xts-plain64_256.txt",
    "29521": "https://hashcat.net/misc/example_hashes/hashcat_luks_sha256_aes_cbc-plain64_128.txt",
    "29522": "https://hashcat.net/misc/example_hashes/hashcat_luks_sha256_serpent_xts-plain64_512.txt",
    "29523": "https://hashcat.net/misc/example_hashes/hashcat_luks_sha256_twofish_cbc-essiv_256.txt",
    "29531": "https://hashcat.net/misc/example_hashes/hashcat_luks_sha512_aes_cbc-plain64_256.txt",
    "29532": "https://hashcat.net/misc/example_hashes/hashcat_luks_sha512_serpent_cbc-essiv_128.txt",
    "29533": "https://hashcat.net/misc/example_hashes/hashcat_luks_sha512_twofish_cbc-plain64_256.txt",
    "29541": "https://hashcat.net/misc/example_hashes/hashcat_luks_ripemd160_aes_cbc-essiv_256.txt",
    "29542": "https://hashcat.net/misc/example_hashes/hashcat_luks_ripemd160_serpent_xts-plain64_256.txt",
    "29543": "https://hashcat.net/misc/example_hashes/hashcat_luks_ripemd160_twofish_cbc-plain64_128.txt",
}

def main():
    input_data = sys.stdin.read()
    try:
        data = json.loads(input_data)
    except json.JSONDecodeError as e:
        sys.stderr.write(f"❌ Invalid JSON input: {e}\n")
        sys.exit(1)

    footnote_map = {}
    footnote_counter = 1
    table_rows = []

    for key, value in data.items():
        name = value["name"]
        example_hash = value["example_hash"]
        example_pass = value["example_pass"]

        # Replace example_hash if key is in the replacement map
        if key in EXAMPLE_HASH_REPLACEMENTS:
            example_hash = EXAMPLE_HASH_REPLACEMENTS[key]

        footnote = ""
        if example_pass != "hashcat":
            if example_pass not in footnote_map:
                footnote_map[example_pass] = footnote_counter
                footnote_counter += 1
            footnote = f"[^{footnote_map[example_pass]}]"

        row = f"| [`{key}`](/src/modules/module_{key.zfill(5)}.c) | `{name}`{footnote} | `{example_hash}` |"
        table_rows.append(row)

    # Print the table
    print("\n".join(table_rows))

    # Print footnotes
    if footnote_map:
        print()
        for pass_val, num in footnote_map.items():
            print(f"[^{num}]: Password: `{pass_val}`")

if __name__ == "__main__":
    main()
