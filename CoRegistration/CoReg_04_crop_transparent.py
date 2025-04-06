#   Updated: 2024.11.4, AVV
#   Further documentation on the Skin CoRegistration protocol can be found in the YoLab - Current Projects Google drive. 
#   Google Drive Folder Path: YoLab - Current Projects/_Components and General Protocols/Skin CoRegistration Protocol/ Reference Protocol for Fluorescent Skin CoRegistration (XZ)
#   Link to Reference Protocol: https://docs.google.com/document/d/1-fYOJLyQK2c38IUVoarcfj_TPqYVu_sRxUwiC_I94dQ/edit?tab=t.0#heading=h.nw90t991hz9y

#   Script Description: This script will remove all transparent pixels from all .png images within a provided folder. It should be used on the output images from exportLayersAsCSS_PNGs_2.jsx, which are exported with significant empty space from Illustrator. 
#   Mandatory Inputs to Modify: For each sample, there are two inputs that need to be modified. 
#       input_folder: Path to the folder containing the sections that have been annotated and exported from Illustrator
#           Example:  C:\YoLab - Current Projects\[Project]OCT2Hist 40x\LM\LM-01\RawData\Slides\Slides05_Annotated
#       output_folder: Path to the folder prepared for the cropped sections
#           Example:  C:\YoLab - Current Projects\[Project]OCT2Hist 40x\LM\LM-01\RawData\Slides\Slides06_AnnotatedCropped


#   If you get an error (No module named 'PIL'), you must install pillow with the following code
#   pip install pillow
from PIL import Image
import os


# Define the input and output folders. 
input_folder = 'E:\Shared drives\Yolab - Current Projects\[Project] OCT2Hist 40x\LM\LM-09\RawData\Slides\Slides05_Annotated'           # File path to input folder, which should be labeled "Slides05_Annotated". Example file path: ...\LM-01\RawData\Slides\Slides05_Annotated
output_folder = 'E:\Shared drives\Yolab - Current Projects\[Project] OCT2Hist 40x\LM\LM-09\RawData\Slides\Slides06_AnnotatedCropped'   # File path to output folder, which should be labeled "Slides06_Annotated". Example file path: ...\LM-01\RawData\Slides\Slides06_Annotated



def crop_transparent(input_folder, output_folder):
    # Create the output folder if it doesn't exist
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    # Loop through all files in the input folder
    for filename in os.listdir(input_folder):
        if filename.endswith(".png"):  # Only process PNG files
            img_path = os.path.join(input_folder, filename)
            img = Image.open(img_path)

            # Crop out transparent pixels
            img_cropped = img.crop(img.getbbox())

            # Save the cropped image to the output folder
            output_path = os.path.join(output_folder, filename)
            img_cropped.save(output_path)

            print(f"Cropped and saved: {filename}")

# Call the function
crop_transparent(input_folder, output_folder)
