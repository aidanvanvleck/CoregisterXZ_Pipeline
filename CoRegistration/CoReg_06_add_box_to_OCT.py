#   Updated: 2024.11.4, AVV
#   Further documentation on the Skin CoRegistration protocol can be found in the YoLab - Current Projects Google drive. 
#   Google Drive Folder Path: YoLab - Current Projects/_Components and General Protocols/Skin CoRegistration Protocol/ Reference Protocol for Fluorescent Skin CoRegistration (XZ)
#   Link to Reference Protocol: https://docs.google.com/document/d/1-fYOJLyQK2c38IUVoarcfj_TPqYVu_sRxUwiC_I94dQ/edit?tab=t.0#heading=h.nw90t991hz9y

#   Script Description: This script will add a white box to a 3D OCT volume, mimicking the square photobleached in the central 250um of the OCT scanning region. Do not use this script unless you have photobleached the square in the central 250x250 um of the OCT scan.
#   Recommended input file: The user should provide a *flattened* 3D OCT volume that has been resliced from the bottom so the default view is XY (as of 2024.11.4 default orientation after scanning and reconstructing is XZ). Slice 1 should be the lowest point in the scan. 
#   Mandatory Inputs to Modify: For each sample, there are two inputs that need to be verified. You must modify the input_file path, and the z_start, z_end inputs (as they rely on the height of the 3D volume)
#   Optional Inputs to Modify: A toggle exists for modifying the OCT contrast. If enhance_contrast (ln 18) is set to true, it will enhance the OCT contrast, referencing clip_limit (ln 19) to determine the extent of contrast enhancement.


import numpy as np
import tifffile as tiff
import os
from skimage import exposure

# Toggle for contrast enhancement
enhance_contrast = False  # Set to True to apply contrast enhancement, False to skip
clip_limit = 0.001  # Adjust the clip limit for contrast enhancement (lower values = less enhancement)

# Path to the 3D volume
input_file = "G:\Shared drives\Yolab - Current Projects\[Project] OCT2Hist 40x\LM\LM-08\CoRegistration\Z-StackReconstruction__dQ-1.443e+08_fS20_tRI1.33_focus450_XY_CE_Cropped.tif"

# Load the 3D .tif file (ensure correct pixel type, e.g., uint16 if necessary)
volume = tiff.imread(input_file).astype(np.uint16)

# Check the shape of the volume (should be 500x500x214)
print(f"Original volume shape: {volume.shape}")

# Optional: Enhance contrast using CLAHE (only if toggle is on)
if enhance_contrast:
    print(f"Enhancing contrast with CLAHE, clip limit = {clip_limit}...")
    clahe = exposure.equalize_adapthist  # Use CLAHE for contrast enhancement
    for z in range(volume.shape[0]):
        volume[z] = clahe(volume[z], clip_limit=clip_limit) * np.iinfo(volume.dtype).max
else:
    print("Skipping contrast enhancement.")

# Define the coordinates for the box
x_start, x_end = 125, 375   # Define the location of the box in the x-coordinate. For a 500um FOV scan, the central 250um spans from 125-375
y_start, y_end = 125, 375   # Define the location of the box in the y-coordinate. For a 500um FOV scan, the central 250um spans from 125-375
z_start, z_end = 253, 265   # Define the location of the box in the z-coordinate. Set the value such that the larger is equal to the stack height, and the smaller value an offset of ~10-20 pixels. Use the smallest possible height in order to reduce line artifacts appearing in the dataset. 

# Draw the box in the XY plane at the top (z_end)
volume[z_end-1, y_start:y_end, x_start] = np.iinfo(volume.dtype).max  # Left vertical line
volume[z_end-1, y_start:y_end, x_end-1] = np.iinfo(volume.dtype).max  # Right vertical line
volume[z_end-1, y_start, x_start:x_end] = np.iinfo(volume.dtype).max  # Top horizontal line
volume[z_end-1, y_end-1, x_start:x_end] = np.iinfo(volume.dtype).max  # Bottom horizontal line

# Draw the box in the XY plane at the bottom (z_start)
volume[z_start, y_start:y_end, x_start] = np.iinfo(volume.dtype).max  # Left vertical line
volume[z_start, y_start:y_end, x_end-1] = np.iinfo(volume.dtype).max  # Right vertical line
volume[z_start, y_start, x_start:x_end] = np.iinfo(volume.dtype).max  # Top horizontal line
volume[z_start, y_end-1, x_start:x_end] = np.iinfo(volume.dtype).max  # Bottom horizontal line

# Draw the vertical lines in the Z-axis along the edges of the box
for z in range(z_start, z_end):
    volume[z, y_start, x_start:x_end] = np.iinfo(volume.dtype).max  # Top edge line in XY
    volume[z, y_end-1, x_start:x_end] = np.iinfo(volume.dtype).max  # Bottom edge line in XY
    volume[z, y_start:y_end, x_start] = np.iinfo(volume.dtype).max  # Left edge line in XY
    volume[z, y_start:y_end, x_end-1] = np.iinfo(volume.dtype).max  # Right edge line in XY

# Get the directory and original filename
input_dir = os.path.dirname(input_file)
file_name = os.path.basename(input_file)

# Create the new file name with "_marked" appended
file_name_without_ext = os.path.splitext(file_name)[0]
output_file = os.path.join(input_dir, f"{file_name_without_ext}_marked.tif")

# Save the volume with the marked box as a new .tif file
tiff.imwrite(output_file, volume)

print(f"Saved new volume with bounding box as '{output_file}'")
