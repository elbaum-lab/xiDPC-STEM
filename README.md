# piDPC and pBF data collection and processing
## Setup
1. Install AutoScript TEM in the microscope computer and on the SerialEM computer
2. Make sure that from inside SerialEM you can connect to AutoScript TEM (e.g. by running the '20250609_PreAquAtItems.txt' script)
3. Center the beam on the detector (e.g. by running the '12segments.py')

## Collection of the individual segments of the panther detector using SerialEM
1. Copy the text of the '20250609_PreAquAtItems.txt' and '20250609_Collect_STEM_Segments.txt' to your SerialEM scripts
2. In the 'PreAquAtItems' script set the defocus
3. In the 'Collect_STEM_Segments' set the amount of Pixels and the dwell time (µs)
4. In the 'AquireAtItems' setup, specify PreAquAtItems to run before each item
5. In the Tilt menu, go to 'Run Script in TS' and choose 4, to run it before each Record step
6. Specify a 'Dummy Record': in the camera properties set the 'Record mode' to 512 pixels and 0.1 µs dwell time (the lowest possible for each)
7. Set up positions to record tilt series and make sure to save the tilt series into a separate tomo folder, e.g. Tomos. The 'Collect_STEM_Segments' script will create a subfolder for each item recorded.

## Data processing 
### Setup Matlab
Requires MatTomo in search path (PEET project: https://bio3d.colorado.edu/imod/matlab.html).
Place the 'panther_iDPC.m' script into the Matlab folder.

### Run the Python script to execute the pBF and piDPC calculation
1. Make the following changes in the script: 
1.1 Specify the Parent directory, i.e. the Tomo folder
1.2 Specify the Matlab folder 
1.3 Specify the 'search_pattern'
1.4 Specify the 'tilt_step'
1.5 Specify the 'semi_angle'
1.6 Specify the 'wavelength'
1.7 Specify the how far the BF disk goes on the detector, e.g. 'DF_Outer'

### Align the a contrast mode (either pBF or piDPC) using IMOD or AreTomo
Make sure that AreTomo exports the IMOD files

### Apply the alignment to other contrast modes
1. Create a new folder 
2. Link the relevant tilt series into the new folder, e.g.
2.1 Add the tilt series together if they contain useful signal, e.g. middle + outer ring
3. Copy/link the .xf, .tlt, tilt.com and newstack.com (and the other files specified in the two .com files)
4. Run the '20250507_Rings_reconstruction.sh' script which performs the alignment and reconstruction based on the previous alignment

### Postprocessing using 3d-deconvolution
as described in https://doi.org/10.1016/j.jsb.2023.107982

