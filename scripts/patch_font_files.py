#!/usr/bin/env python3
import fontforge
import sys
import os


patch_map = {
    "UnitOT-Bold": ["Bold"],
    "UnitOT-BoldIta": ["Bold", "Italic"],
    "UnitOT-Ita": ["Italic"],
    "UnitOT-Light": ["Light"],
    "UnitOT-LightIta": ["Light", "Italic"],
    "UnitOT-Medi": ["Medium"],
    "UnitOT-MediIta": ["Medium", "Italic"],
    "UnitOT": ["Regular"],
}


def patch_font(input_path: str, output_dir: str):
    try:
        font = fontforge.open(input_path)
    except Exception as e:
        print(f"Error opening font file: {e}")
        return False

    font.uniqueid = 0
    # It seems that font.xuid is already automatically being re-generated on
    # each font open.

    patch = patch_map[font.fontname]
    font.fontname = "UnitOT-" + "".join(patch)
    font.familyname = "Unit OT"
    font.fullname = "Unit OT " + " ".join(patch)

    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, f"{font.fontname}.otf")
    try:
        font.generate(output_path)
        print(f"Font successfully generated: {output_path}")
        font.close()
        return True
    except Exception as e:
        print(f"Error generating font: {e}")
        font.close()
        return False


def main():
    usage = f"fontforge -script {sys.argv[0]} <input_font_dir> [output_dir]"
    if len(sys.argv) < 2:
        print(f"Usage: {usage}")
        sys.exit(1)

    input_dir = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else "."
    if not os.path.exists(input_dir):
        print(f"Error: Input directory {input_dir} does not exist")
        sys.exit(1)

    file_count = 0
    for font_file in os.listdir(input_dir):
        if not font_file.endswith(".otf"):
            print(f"Skipping {font_file}")
            continue
        if not patch_font(os.path.join(input_dir, font_file), output_path):
            print(f"Failed patching {font_file}")
            sys.exit(1)
        file_count += 1
    print(f"Successfully patched {file_count} files")


if __name__ == "__main__":
    main()
