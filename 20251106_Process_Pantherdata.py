import os
import re
import subprocess
import argparse
import configparser
from pathlib import Path

def extract_tilt_parameters(file_names):
    pos_values = []
    neg_values = []
    for name in sorted(file_names):
        pos_match = re.search(r'tilt(\d{3}).mrc', name)
        neg_match = re.search(r'tilt-(\d{2}).mrc', name)
        
        if pos_match:
            pos_tilt = int(pos_match.group(1))
            pos_values.append(pos_tilt)
        
        if neg_match:
            neg_tilt = int(neg_match.group(1))
            neg_values.append(neg_tilt)

    max_pos_tilt = max(pos_values) if pos_values else None

    if neg_values:
        min_neg_tilt = max(neg_values)
        neg_tilt_filename = next(name for name, tilt in zip(file_names, neg_values) if tilt == min_neg_tilt)
        min_neg_tilt = -min_neg_tilt
    else:
        min_neg_tilt = None
        neg_tilt_filename = None

    return max_pos_tilt, min_neg_tilt


def execute_matlab_script(matlab_folder, matlab_function_name, file_path, neg_tilt, pos_tilt, tilt_step, semi_angle, wavelength, work_dir, disk):
    command = [
        "matlab", "-nodisplay", "-useStartupFolderPref", "-batch",
        f"{matlab_function_name.strip()} {file_path} {work_dir} {neg_tilt} {pos_tilt} {tilt_step} {semi_angle} {wavelength} {disk}"
    ]
    # Execute the command
    print(command)
    os.chdir(matlab_folder)
    subprocess.run(command)


def load_config(config_file):
    """Load configuration from a config file."""
    config = configparser.ConfigParser(comment_prefixes=('#', ';'))
    config.read(config_file)
    
    if 'piDPC' not in config:
        raise ValueError(f"Config file {config_file} must contain a [piDPC] section")
    
    return config['piDPC']


def parse_arguments():
    """Parse command-line arguments with config file support."""
    parser = argparse.ArgumentParser(
        description='Process Panther data for piDPC analysis',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    # Config file option
    parser.add_argument(
        '--config', '-c',
        type=str,
        help='Path to piDPC.conf configuration file'
    )
    
    # All other parameters
    parser.add_argument(
        '--parent-directory', '-d',
        type=str,
        help='Directory containing the directories of the individual files'
    )
    
    parser.add_argument(
        '--search-pattern', '-p',
        type=str,
        default='BF-S_Inner1',
        help='Search pattern for files'
    )
    
    parser.add_argument(
        '--tilt-step', '-t',
        type=float,
        default=2.0,
        help='Tilt step in degrees'
    )
    
    parser.add_argument(
        '--semi-angle', '-s',
        type=float,
        default=1.2,
        help='Semiconvergence angle in mrad'
    )
    
    parser.add_argument(
        '--wavelength', '-w',
        type=float,
        default=0.0025,
        help='Wavelength in nm'
    )
    
    parser.add_argument(
        '--bf-disk-location', '-b',
        type=str,
        default='DF_Outer',
        choices=['BF_Inner', 'DF_Inner', 'DF_Outer'],
        help='Location of the BF disk'
    )
    
    parser.add_argument(
        '--matlab-folder', '-m',
        type=str,
        help='Path to the MATLAB folder'
    )
    
    parser.add_argument(
        '--matlab-function', '-f',
        type=str,
        default='panther_piDPC',
        help='Name of the MATLAB function to execute'
    )
    
    parser.add_argument(
        '--overwrite',
        action='store_true',
        default=True,
        help='Enable looking in Segments subfolder'
    )
    
    parser.add_argument(
        '--no-overwrite',
        action='store_false',
        dest='overwrite',
        help='Disable looking in Segments subfolder'
    )
    
    args = parser.parse_args()
    
    # If config file is provided, load it and use as defaults
    if args.config:
        config = load_config(args.config)
        
        # Override with config file values if not provided on command line
        if args.parent_directory is None and 'parent_directory' in config:
            args.parent_directory = config['parent_directory']
        if args.search_pattern == 'BF-S_Inner1' and 'search_pattern' in config:
            args.search_pattern = config['search_pattern']
        if args.tilt_step == 2.0 and 'tilt_step' in config:
            args.tilt_step = float(config['tilt_step'])
        if args.semi_angle == 1.2 and 'semi_angle' in config:
            args.semi_angle = float(config['semi_angle'])
        if args.wavelength == 0.0025 and 'wavelength' in config:
            args.wavelength = float(config['wavelength'])
        if args.bf_disk_location == 'DF_Outer' and 'bf_disk_location' in config:
            args.bf_disk_location = config['bf_disk_location']
        if args.matlab_folder is None and 'matlab_folder' in config:
            args.matlab_folder = config['matlab_folder']
        if args.matlab_function == 'panther_piDPC' and 'matlab_function' in config:
            args.matlab_function = config['matlab_function']
        if 'overwrite' in config:
            args.overwrite = config.getboolean('overwrite')
    
    # Validate required arguments
    if args.parent_directory is None:
        parser.error('--parent-directory is required (or must be set in config file)')
    if args.matlab_folder is None:
        parser.error('--matlab-folder is required (or must be set in config file)')
    
    return args


if __name__ == "__main__":
    # Parse arguments
    args = parse_arguments()
    
    print("Off I go")
    print(f"Configuration:")
    print(f"  Parent directory: {args.parent_directory}")
    print(f"  Search pattern: {args.search_pattern}")
    print(f"  Tilt step: {args.tilt_step}")
    print(f"  Semi angle: {args.semi_angle}")
    print(f"  Wavelength: {args.wavelength}")
    print(f"  BF disk location: {args.bf_disk_location}")
    print(f"  MATLAB folder: {args.matlab_folder}")
    print(f"  MATLAB function: {args.matlab_function}")
    print(f"  Overwrite: {args.overwrite}")
    print()

    # Iterate over directories in the parent directory
    for folder in os.listdir(args.parent_directory):
        work_dir = os.path.join(args.parent_directory, folder)
        if os.path.isdir(work_dir):
            print(f"Processing folder: {work_dir}")

            # Search for the tilt_000_file in the working directory
            file_names = [f for f in os.listdir(work_dir) if args.search_pattern in f and os.path.isfile(os.path.join(work_dir, f))]
            tilt_000_file = next((f for f in file_names if "tilt000.mrc" in f), None)
            print('0 deg files:', tilt_000_file)

            # If overwrite is enabled and the file isn't found, check in the Segments subfolder
            if tilt_000_file is None and args.overwrite:
                segments_work_dir = os.path.join(work_dir, "Segments")
                if os.path.isdir(segments_work_dir):
                    file_names = [f for f in os.listdir(segments_work_dir) if args.search_pattern in f and os.path.isfile(os.path.join(segments_work_dir, f))]
                    tilt_000_file = next((f for f in file_names if "tilt000.mrc" in f), None)
                    tilt_000_path = os.path.join(segments_work_dir, tilt_000_file) if tilt_000_file else None
                else:
                    tilt_000_path = None
            else:
                tilt_000_path = os.path.join(work_dir, tilt_000_file) if tilt_000_file else None

            # If the tilt_000_file is still not found, skip this folder
            if tilt_000_path is None:
                print(f"No file matching 'tilt000.mrc' found in {work_dir} or its 'Segments' subfolder. Skipping this folder.")
                continue
            
            # Extract tilt parameters from file names
            pos_tilt, neg_tilt = extract_tilt_parameters(file_names)

            print('Positive tilt:', pos_tilt)
            print('Negative tilt:', neg_tilt)
            print('0 deg file:', tilt_000_file)
                    
            execute_matlab_script(
                args.matlab_folder,
                args.matlab_function,
                tilt_000_path,
                neg_tilt,
                pos_tilt,
                args.tilt_step,
                args.semi_angle,
                args.wavelength,
                work_dir,
                args.bf_disk_location
            )
