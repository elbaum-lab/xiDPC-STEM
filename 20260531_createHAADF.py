#!/usr/bin/env python3

import argparse
import re
import shutil
import subprocess
from pathlib import Path

ANGLE_RE = re.compile(r'(-?\d+)$')
BASE_RE = re.compile(r'^(.*?)_HAADF')

def parse_filename(path: Path):
    stem = path.stem  # no .mrc

    # ---- base name (file1, file2, etc.) ----
    m_base = BASE_RE.search(stem)
    if not m_base:
        raise ValueError(f"Cannot extract base name from {path}")
    base = m_base.group(1)

    # ---- angle (last number in name) ----
    m_angle = ANGLE_RE.search(stem)
    if not m_angle:
        raise ValueError(f"Cannot extract angle from {path}")
    angle = int(m_angle.group(1))

    return base, angle


def find_haadf_files(workdir):
    """
    Search first in workdir, then in workdir/Segments.
    Returns:
        files, source_dir
    """

    files = [
        f for f in workdir.glob("*HAADF*.mrc")
        if "_tilt" in f.stem
    ]
    if files:
        return files, workdir

    segdir = workdir / "Segments"

    if segdir.is_dir():
        files = list(segdir.glob("*HAADF*.mrc"))

        if files:
            return files, segdir

    return [], None


def move_to_segments(files, workdir):
    """
    Move files into Segments directory.
    """

    segdir = workdir / "Segments"
    segdir.mkdir(exist_ok=True)

    moved_files = []

    for f in files:

        destination = segdir / f.name

        if destination.exists():
            moved_files.append(destination)
            continue

        print(f"    moving {f.name}")

        shutil.move(str(f), str(destination))

        moved_files.append(destination)

    return moved_files


def write_filelist(files, filename):
    """
    Write IMOD-compatible -fileinlist format
    (one section per file → section index = 0)
    """

    with open(filename, "w") as f:

        # number of input files
        f.write(f"{len(files)}\n")

        for path in files:
            f.write(f"{path.resolve()}\n")
            f.write("0\n")

def write_rawtlt(angles, filename):

    with open(filename, "w") as fh:
        for angle in angles:
            fh.write(f"{angle:.2f}\n")


def build_tiltseries(workdir, files, output_tlt, output_stack, base_name):

    entries = []

    for f in files:
        base, angle = parse_filename(f)
        entries.append((angle, f))

    entries.sort(key=lambda x: x[0])

    angles = [a for a, _ in entries]
    sorted_files = [f for _, f in entries]
    print(
        f"    Found {len(sorted_files)} tilts "
        f"({angles[0]}° to {angles[-1]}°)"
    )
    filelist     = workdir / f"{base_name}_filelist.txt"

    write_filelist(sorted_files, filelist)
    write_rawtlt(angles, output_tlt)

    cmd = [
        "newstack",
        "-fileinlist",
        str(filelist),
        str(output_stack),
    ]

    print("    Running:", " ".join(cmd))

    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError:
        print("    ERROR: newstack failed")
        return

    print(f"    Created {output_stack.name}")
    print(f"    Created {output_tlt.name}")


def process_directory(workdir):

    print(f"\nProcessing {workdir}")

    files, source_dir = find_haadf_files(workdir)

    if not files:
        print("    No HAADF files found")
        return

    # Determine base name from first HAADF file
    try:
        base_name, _ = parse_filename(files[0])
    except ValueError as e:
        print(f"    {e}")
        return

    output_stack = workdir / f"{base_name}_HAADF.mrc"
    output_tlt   = workdir / f"{base_name}_HAADF.rawtlt"

    if output_stack.exists() and output_tlt.exists():
        print("    Output files already exist - skipping")
        return

    if source_dir == workdir:
        print("    HAADF files found in workdir")
        files = move_to_segments(files, workdir)

    build_tiltseries(workdir, files, output_tlt, output_stack, base_name)


def main():

    parser = argparse.ArgumentParser(
        description="Assemble HAADF tilt series with IMOD newstack."
    )

    parser.add_argument(
        "parentdir",
        type=Path,
        help="Parent directory containing tilt-series folders",
    )

    args = parser.parse_args()

    parentdir = args.parentdir.resolve()

    if not parentdir.is_dir():
        raise RuntimeError(f"{parentdir} is not a directory")

    for workdir in sorted(parentdir.iterdir()):

        if workdir.is_dir():
            process_directory(workdir)


if __name__ == "__main__":
    main()
