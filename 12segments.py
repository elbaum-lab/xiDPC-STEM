from autoscript_tem_microscope_client import TemMicroscopeClient
from autoscript_tem_microscope_client.enumerations import *
from autoscript_tem_microscope_client.structures import *
import numpy as np
import math
from matplotlib import pyplot as plt

microscope = TemMicroscopeClient()
microscope.connect("ComputerName/IPadress", 7521)

microscope.detectors.screen.insert()
print(str(microscope.detectors.screen.measure_current() * 1E12) + " pA")
microscope.detectors.screen.retract()

bf_s = microscope.detectors.get_scanning_detector(DetectorType.BF_S)
df_s = microscope.detectors.get_scanning_detector(DetectorType.DF_S)
#haadf = microscope.detectors.get_scanning_detector(DetectorType.HAADF)

# Enable the inner segments on the BF-S detector
bf_s.set_enabled_segments(DetectorSegmentType.INNER_RING)

# Enable all segments on the DF-S detector
df_s.set_enabled_segments(DetectorSegmentType.ALL)

# Enable SINGLE segment on HAADF
#haadf.set_enabled_segments(DetectorSegmentType.SINGLE)

# Join the two lists together
segments = bf_s.get_enabled_segments() + df_s.get_enabled_segments()# + haadf.get_enabled_segments()

# Acquire one image per segment, a total of 12 images in this case
images = microscope.acquisition.acquire_stem_segment_images(segments, 1024, 3E-6)

# Plot the images in max 4 columns wide
n = len(images)
columns = min(4, n)
rows = math.ceil(n/columns)
fig, plots = plt.subplots(rows, columns)
fig.tight_layout()
#Create a new dictionary for the images and the mean
image_mean_dict = {}

for row in range(rows):
    for column in range(columns):
        plot = plots[row, column]
        plot.axis('off')
        i = column + row * columns
        if i < n:
            plot.imshow(images[i].data, cmap='gray')
            title = segments[i].detector_name + "-" + segments[i].name
            #print(title)
            plot.set_title(title)
            gray = np.mean(images[i].data, axis=0)
            mean_intensity = np.mean(gray)
            #print(round(mean_intensity, 2))
            #image_mean_dict[title] = images[i]
            plot.text(100, 0, 'Mean: ' + str(round(mean_intensity, 2)), fontsize=8, ha='center')
            image_mean_dict[title] = round(mean_intensity, 2)
print(image_mean_dict)
plt.show()

