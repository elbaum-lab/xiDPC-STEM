import os
import re
import subprocess
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

    #command = [
    #    "matlab", "-nodisplay", "-useStartupFolderPref", "-batch", f"{matlab_function_name.strip()} {file_path} {work_dir} {neg_tilt} {pos_tilt} {tilt_step} {semi_angle} {wavelength} {disk}"
    #]
    command = [
        "matlab", "-nodisplay", "-useStartupFolderPref", "-batch",
        f"{matlab_function_name.strip()} {file_path} {work_dir} {neg_tilt} {pos_tilt} {tilt_step} {semi_angle} {wavelength} {disk}"
        ]
    # Execute the command
    print(command)
    os.chdir(matlab_folder)
    subprocess.run(command)

if __name__ == "__main__":

    overwrite = True # Set this to True to enable looking in 'Segments' subfolder
    # Directory containing the directory of the files
    parent_directory = "/directory/containing/the/directories/of/the/individual/Files"
    
    print("Off I go")
   # Define the search pattern
    search_pattern = "BF-S_Inner1"
   #Set the tilt_step
    tilt_step = 2
   #Set the semiconvergence angle (in mrad)
    semi_angle = 1.2

   #Set the Wavelength (in nm)
    wavelength = 0.0025
    
     # Set the BF_disk_is_on option # Change this to "BF_Inner", "DF_Inner" or "DF_Outer" as to where the BF disk is
    BF_disk_is_on = "DF_Outer"

    # Iterate over directories in the parent directory
    for folder in os.listdir(parent_directory):
        work_dir = os.path.join(parent_directory, folder)
        if os.path.isdir(work_dir):
            print(f"Processing folder: {work_dir}")

            # Search for the tilt_000_file in the working directory
            file_names = [f for f in os.listdir(work_dir) if search_pattern in f and os.path.isfile(os.path.join(work_dir, f))]
            tilt_000_file = next((f for f in file_names if "tilt000.mrc" in f), None)
            print('0 deg files:', tilt_000_file)

            # If overwrite is enabled and the file isn't found, check in the Segments subfolder
            if tilt_000_file is None and overwrite is True:
                segments_work_dir = os.path.join(work_dir, "Segments")
                if os.path.isdir(segments_work_dir):
                    file_names = [f for f in os.listdir(segments_work_dir) if search_pattern in f and os.path.isfile(os.path.join(segments_work_dir, f))]
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
                    
            # Example usage
            matlab_folder = "\path\to\the\matlab\folder"
            matlab_function_name = "panther_piDPC"
            execute_matlab_script(matlab_folder, matlab_function_name, tilt_000_path, neg_tilt, pos_tilt, tilt_step, semi_angle, wavelength, work_dir, BF_disk_is_on)





