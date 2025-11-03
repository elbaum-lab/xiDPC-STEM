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
6. Set up positions to record tilt series
