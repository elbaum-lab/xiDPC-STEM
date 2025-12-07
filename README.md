# piDPC and pBF data collection and processing
## Setup
1. Install AutoScript TEM on the microscope computer and on the SerialEM computer
2. Make sure that AutoScript TEM on the microscope computer is reachable from SerialEM:
   - 2.1 Set the correct IP adress or computername
   - 2.2 Test by e.g. running the '20250609\_PreAquAtItems.txt' script
3. Beam Centering: 
    - 3.1 Center the beam roughly to the center on the detector 
    - 3.2 Fine: 
        - 3.2.1 refine manually by running the '12segments.py' on the microscope computer, or 
        - 3.2.2 automatically by running the '20251202\_CenterBeam.txt' from SerialEM (watch the log carefully). If it doesn't converge properly, center manually (3.2.1) and then again (3.2.2) 



## Collection of the individual segments of the panther detector using SerialEM
1. Copy the text of the '20251202\_PreAquAtItems.txt', '20251202\_CenterBeam.txt' and '20250609\_Collect_STEM_Segments.txt' to your SerialEM scripts
2. The 'PreAquAtItems' script sets the defocus (usually around -0.5 µm), and executes the CenterBeam script to automatically center the diffraction disk on the four segments
3. In the 'Collect_STEM_Segments' set the number of pixels and the dwell time (µs)
4. In the 'AquireAtItems' setup, specify the 'PreAquAtItems' script to run before each item
5. In the Tilt menu, go to 'Run Script in TS', choose the correct script and then '4', to run it before each Record step
6. Specify a 'Dummy Record': in the camera properties set the 'Record mode' to 512 pixels and 0.1 µs dwell time (the lowest possible for each)
7. Set up positions to record tilt series and make sure to save the tilt series into a separate data folder. The 'Collect_STEM_Segments' script will save the data into a subfolder for each item recorded.



## Data processing 
### Setup Matlab
Requires MatTomo in search path (PEET project: https://bio3d.colorado.edu/imod/matlab.html).
Place the 'panther\_xiDPC.m' script into the Matlab startup folder.


### Run the Python script to execute the pBF and piDPC calculation
1. Make the following changes in the xDPC.conf file: 
    - 1.1 Specify the Parent directory, i.e. the data folder that contains the subfolders with the data
    - 1.2 Specify the Matlab folder
    - 1.3 Specify the 'search_pattern' (something which makes the script recognizing the file name)
    - 1.4 Specify the 'tilt_step'
    - 1.5 Specify the 'semi_angle'
    - 1.6 Specify the 'wavelength'
    - 1.7 Specify the how far the BF disk extends on the detector, e.g. 'DF_Outer'
2. execute the Process\_Pantherdata script using these options: 
#### Using config file only
python Process\_Pantherdata.py --config xDPC.conf
#### Using command-line arguments only
python Process\_Pantherdata.py -d /path/to/data -m /path/to/matlab
#### Mix config file with command-line overrides
python Process\_Pantherdata.py --config xDPC.conf --tilt-step 3.0 --semi-angle 1.5


### Align the resulting tilt series of a contrast mode (either pBF or piDPC) using IMOD or AreTomo
(Please note, the 'Dummy Record Tilt series' can be used to extract the .rawtlt)
Make sure that AreTomo exports the IMOD files


### Apply the alignment to other contrast modes
1. Create a new folder 
2. Link the relevant tilt series into the new folder
   - 2.1 Merge the tilt series of a contrast mode using the IMOD program 'clip add' if they contain useful signal, e.g. inner + middle + outer ring
3. Copy/link the .xf, .tlt, tilt.com and newst.com (and the other files specified in the two .com files)
4. Set trimming to yes or no (line 12)
4.1 If to yes, set the amount of z-slices for the final rotated reconstruction (line 13)
5. If needed, change the filename flag (line 86)
6. Run the '20250507\_Rings\_reconstruction.sh' script which performs the alignment and reconstruction based on the previous alignment

### Postprocessing using 3d-deconvolution
as described in https://doi.org/10.1016/j.jsb.2023.107982

