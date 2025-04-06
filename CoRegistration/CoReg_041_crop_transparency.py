from PIL import Image
import os

# Define the input and output folders.
input_folder = 'H:\Shared drives\Yolab - Current Projects\[Project] OCT2Hist 40x\LM\LM-02\CoRegistration\OCTSlices'  # Example file path: ...\LM-01\RawData\Slides\Slides05_Annotated
output_folder = 'H:\Shared drives\Yolab - Current Projects\[Project] OCT2Hist 40x\LM\LM-02\CoRegistration\Cropped OCTSlice Test'  # Example file path: ...\LM-01\RawData\Slides\Slides06_Annotated

# Settings
mode = "specific_color"  # Options: "transparent" or "specific_color"
specific_color = (100, 100, 100)  # RGB color to remove (used when mode is "specific_color")


def crop_images(input_folder, output_folder, mode="transparent", specific_color=None):
    # Create the output folder if it doesn't exist
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    # Loop through all files in the input folder
    for filename in os.listdir(input_folder):
        if filename.endswith(".png"):  # Only process PNG files
            img_path = os.path.join(input_folder, filename)
            img = Image.open(img_path).convert("RGBA")  # Ensure image is in RGBA mode

            # Get pixel data
            pixels = img.load()

            # Define cropping box
            min_x, min_y = img.size[0], img.size[1]
            max_x, max_y = 0, 0

            # Identify the bounding box
            for x in range(img.size[0]):
                for y in range(img.size[1]):
                    r, g, b, a = pixels[x, y]

                    # Condition for "transparent" mode
                    if mode == "transparent" and a > 0:
                        min_x, min_y, max_x, max_y = min(min_x, x), min(min_y, y), max(max_x, x), max(max_y, y)

                    # Condition for "specific_color" mode
                    elif mode == "specific_color" and (r, g, b) != specific_color:
                        min_x, min_y, max_x, max_y = min(min_x, x), min(min_y, y), max(max_x, x), max(max_y, y)

            # Crop the image
            if max_x > min_x and max_y > min_y:  # Ensure valid cropping area
                cropped_img = img.crop((min_x, min_y, max_x + 1, max_y + 1))
            else:
                cropped_img = img  # No valid cropping, keep original

            # Save the cropped image to the output folder
            output_path = os.path.join(output_folder, filename)
            cropped_img.save(output_path)

            print(f"Cropped and saved: {filename}")

# Call the function
crop_images(input_folder, output_folder, mode=mode, specific_color=specific_color if mode == "specific_color" else None)
