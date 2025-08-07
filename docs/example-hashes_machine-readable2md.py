#!/usr/bin/env python3
import sys
import json

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

        footnote = ""
        if example_pass != "hashcat":
            if example_pass not in footnote_map:
                footnote_map[example_pass] = footnote_counter
                footnote_counter += 1
            footnote = f"[^{footnote_map[example_pass]}]"

        row = f"| `{key}` | `{name}`{footnote} | `{example_hash}` |"
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