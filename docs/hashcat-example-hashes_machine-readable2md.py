#!/usr/bin/env python3

# this script is ran automatically; there should be no need to run this manually
#  used in .github/workflows/build.yml to generate docs/hashcat-example-hashes.md on every commit to master
# example usage: ./hashcat --example-hashes --machine-readable --quiet | python3 hashcat-example-hashes_machine-readable2md.py >> docs/hashcat-example_hashes.md


import sys
import json
import os

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

OPENCL_DIR = "OpenCL"

def find_opencl_icons(zfilled_key):
    """Return markdown icons for any OpenCL files containing the key."""
    icons = []
    if not os.path.isdir(OPENCL_DIR):
        return ""
    for fname in sorted(os.listdir(OPENCL_DIR)):
        if zfilled_key in fname:
            file_url = f"/{OPENCL_DIR}/{fname}"
            # Using a small gear emoji as an icon
            icons.append(f"[<sup>*</sup>]({file_url})")
    return " " + " ".join(icons) if icons else ""

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

        zkey = key.zfill(5)
        opencl_links = find_opencl_icons(zkey)

        row = f"| [`{key}`](/src/modules/module_{zkey}.c) | `{name}`{opencl_links}{footnote} | `{example_hash}` |"
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


# to convert the markdown to docuwiki formatting for https://hashcat.net/wiki/doku.php?id=example_hashes you can use:
#  cat docs/hashcat-example-hashes.md | sed -E 's/\[\^(.+)\]/<sup>\1<\/sup>/g' | sed 's/| hash-Mode | hash-Name | Example |/\^ hash-Mode \^ hash-Name \^ Example \^/g' | grep -Fv '|:-----------|:-----------|:---------------|' | sed 's/`//g' | sed -E 's/\[([0-9]+)\]\(\/src\/modules\/module_([0-9]{5})\.c\)/[[\1|https:\/\/github.com\/hashcat\/hashcat\/tree\/master\/src\/modules\/module_\2.c]]/'
# replaces footnotes
# replaces header
# removes un-necessary table style
# removes backticks
# replaces urls