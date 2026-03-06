#!/usr/bin/bash
##place the tilt.com and newst.com into this folder!
##and place all the files needed for the alignment and reconstruction into the folder, 
##such as: .tlt, .zfac, .xtilt, .xf...
##as written in the tilt.com and nwest.com

###################################################
######### Parse command-line arguments ############
###################################################
# Usage: ./recon.sh [file_pattern] [trim_range]
# Examples:
#   ./recon.sh "tomo*.mrc" 117-290   ## Select a filename & activate clip rotx and trimvol with a specific z-range
#   ./recon.sh "*.mrc" 50-200   ## Select a filename & activate clip rotx and trimvol with a specific z-range
#   ./recon.sh "tomo62*.mrc"   ## Select a filename & activate clip rotx
#   ./recon.sh   ## Set the values in the script first

homedir=pwd
mkdir -p ali_files
mkdir -p recon

###################################################
########## Default values (if no CLI args) ########
###################################################
# Default file pattern - change this if not using command-line arguments
default_files="*.mrc"

# Default trimming settings
trimming="no" ### Change to "no" to skip trimming
trim=117-290  ###If trimming=yes add the two respective slices to trim



if [ $# -eq 0 ]; then
  # No arguments - use defaults
  files_to_process="$default_files"
  echo "Using default file pattern: $files_to_process"
elif [ $# -eq 1 ]; then
  # One argument - file pattern only, use default trimming
  files_to_process="$1"
  echo "Using file pattern from command line: $files_to_process"
elif [ $# -eq 2 ]; then
  # Two arguments - file pattern and trim range
  files_to_process="$1"
  trim="$2"
  trimming="yes"
  echo "Using file pattern from command line: $files_to_process"
  echo "Using trim range from command line: $trim"
else
  echo "Error: Too many arguments."
  echo "Usage: $0 [file_pattern] [trim_range]"
  echo "Examples:"
  echo "  $0                        # Use defaults"
  echo "  $0 '*.mrc'                # Process all .mrc files with default trim"
  echo "  $0 'tomo*.mrc' 117-290    # Process tomo*.mrc with trim 117-290"
  exit 1
fi

# Function to check if the trim variable is valid
validate_trim() {
  if [[ "$1" =~ ^[0-9]+-[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

convert_dos_to_unix() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Error: File '$file' not found" >&2
    return 1
  fi
  # Check if the file has DOS line endings
  if grep -q $'\r' "$file"; then
    #echo "Converting Windows line endings to Unix format for: $file"
    # Create a temporary file
    local temp_file=$(mktemp)
    # Convert DOS to Unix line endings
    tr -d '\r' < "$file" > "$temp_file"
    # Preserve permissions
    chmod --reference="$file" "$temp_file"
    # Replace original file with converted one
    mv "$temp_file" "$file"
    #echo "Conversion complete."
    return 0
  else
    echo "File already has Unix line endings: $file"
    return 0
  fi
}


# Validate the trim variable if trimming is enabled
if [ "$trimming" = "yes" ]; then
  if ! validate_trim "$trim"; then
    echo "Error: 'trim' variable must consist of two integers separated by a minus."
    echo "Example: 117-290"
    exit 1
  fi
  echo "Trimming enabled with range: $trim"
else
  echo "Trimming disabled"
fi

# Function to get the mean value from a file using IMOD's header program
get_mean_value() {
  echo $1
  alterheader -rms $1
  mean_value=$(header $1 | grep -e "Mean density" | awk '{print $4}')
  #echo $mean_value
}
# Extract the BinByFactor value from the $newst file
get_binbyfactor() {
  local file=$1
  binbyfactor=$(grep -i '^BinByFactor' "$file" | awk '{print $2}')
  echo "BinByFactor value: $binbyfactor"
}

update_fill_value() {
  local file=$1
  local value=$2
  if grep -q '^FillValue' "$file"; then
    # Update the existing FillValue line
    sed -i 's/^FillValue.*/FillValue '"$value"'/' "$file"
  else
    # Add the FillValue line as the second-to-last line
    sed -i '$i FillValue '"$value" "$file"
  fi
}
###################################################
##########   Process files ########################
###################################################
for i in $files_to_process
###################################################
do
  y=${i%.*}
  echo $y
  echo '################################'
  #orifile=$(grep -i InputFile newst.com | cut -f2 | xargs)
  #alifile=$(grep -i OutputFile newst.com | cut -f2 | xargs)
  #tomofile=$(grep -i OutputFile tilt.com | cut -d " " -f2 | xargs)
  orifile=$(grep -i InputFile newst.com | awk '{print $2}')
  alifile=$(grep -i OutputFile newst.com | awk '{print $2}')
  tomofile=$(grep -i OutputFile tilt.com | awk '{print $2}')
  echo $tomofile
  newst=newst"$y".com
  til=tilt"$y".com
  
  cp newst.com "$newst" 
  cp tilt.com "$til"
  convert_dos_to_unix "$newst"
  convert_dos_to_unix "$til"
  get_binbyfactor "$newst"
  #new_ali="$y"_b"$binbyfactor"_ali.mrc
  new_rec=recon/"$y"_full_rec.mrc
  new_ali=ali_files/"$y"_ali.mrc
  echo "New ali file: " $new_ali
  
  # Check for 'hamminglikefilter' and adjust the output filename if present
  if grep -q '^[^#]*HammingLikeFilter' "$til"; then
    out_rec=recon/"$y"_b"$binbyfactor"_wbp_rotx_rec.mrc
    echo '## I will generate a WBP tomogram with HammingLikeFilter 0.00 ##'
  elif grep -q 'RADIAL 0.5 0.5' "$til"; then
    out_rec=recon/"$y"_b"$binbyfactor"_BP_rotx_rec.mrc
    echo '## I will generate an unweigthed BP tomogram with Radial set to 0.5 0.5 ##'
   elif grep -q 'RADIAL .5 .5' "$til"; then
    out_rec=recon/"$y"_b"$binbyfactor"_BP_rotx_rec.mrc
    echo '## I will generate an unweigthed BP tomogram with Radial set to 0.5 0.5 ##'
  elif grep -q 'Radial 0.5 0.5' "$til"; then
    out_rec=recon/"$y"_b"$binbyfactor"_BP_rotx_rec.mrc        
    echo '## I will generate an unweigthed BP tomogram with Radial set to 0.5 0.5 ##'
  elif grep -q '^[^#]*FakeSIRTiterations' "$til"; then
    out_rec=recon/"$y"_b"$binbyfactor"_sirtlike_rotx_rec.mrc
    echo '## I will generate a SirtLike tomogram ##'
  else
    out_rec=recon/"$y"_b"$binbyfactor"_rotx_sirt_rec.mrc
  fi

  echo "New rec file: " $new_rec
  get_mean_value "$i"
  #echo $mean_value
  update_fill_value "$newst" "$mean_value"
  sed -i 's|'"$orifile"'|'"$i"'|g' "$newst"
  sed -i 's|'"$alifile"'|'"$new_ali"'|g' "$newst"
  sed -i 's|'"$alifile"'|'"$new_ali"'|g' "$til"
  sed -i 's|'"$tomofile"'|'"$new_rec"'|g' "$til"
  #more $newst
  #more $til
  echo '## Im generating the ali file##'
  submfg "$newst"
  echo '## Im generating the full_rec file##'
  submfg "$til"
  echo '## Im rotating the rec file around the x-axis##'
  if [ "$trimming" = "yes" ]; then
    echo '## Trimming is enabled. Performing rotation and trimming ##'
    clip rotx "$new_rec" "$new_rec"   
    newstack -sec "$trim" "$new_rec" "$out_rec"
    
  else
    echo '## Trimming is disabled.Performing only rotation ##'
    clip rotx "$new_rec" "$out_rec"
  fi
  awk '/Projection angles:/, /^$/' "tilt"$y".log" | grep -Eo '[-+]?[0-9]*\.?[0-9]+' > "${out_rec%.*}.tlt"
  echo '#### Cleanup #####'
  rm "$new_rec"
  rm */*.mrc~
  echo "#####################"
  echo "## Done with ${i} ###" 
  echo "#####################"
done
#rm -rf ali_files
ls recon/
#3dmod *rotx_rec.mrc
