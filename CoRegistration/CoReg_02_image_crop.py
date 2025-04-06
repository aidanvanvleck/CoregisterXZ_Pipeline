#   Updated: 2025.4.2, AVV
#   Further documentation on the Skin CoRegistration protocol can be found in the YoLab - Current Projects Google drive. 
#   Google Drive Folder Path: YoLab - Current Projects/_Components and General Protocols/Skin CoRegistration Protocol/ Reference Protocol for Fluorescent Skin CoRegistration (XZ)
#   Link to Reference Protocol: https://docs.google.com/document/d/1-fYOJLyQK2c38IUVoarcfj_TPqYVu_sRxUwiC_I94dQ/edit?tab=t.0#heading=h.nw90t991hz9y

#   Script Description: This script will be used to crop fluorescent images to a standard size. It is intended to be used on images that have been brightened/contrast enhanced and leveled.
#   Mandatory Inputs to Modify: 
#       input_folder: The folder path to the images you wish to crop. Normally, this will be the Slides03_Leveled folder within your sample folder
#           Example: C:\YoLab - Current Projects\[Project]OCT2Hist 40x\LM\LM-01\RawData\Slides\Slides03_Leveled
#       crop_size: the size (x, y) you wish to crop your images to in pixels. This should be large enough to include all of the lines.
#   Optional Inputs to Modify: 

import os
import re
import numpy as np
from tkinter import Tk, filedialog, StringVar, OptionMenu, Button, Label, Canvas
from PIL import Image, ImageTk

## Inputs ##
input_folder = ''  # Specify your input folder here or leave it empty to prompt user
crop_size = (3500, 500)  # Actual cropping size in pixels for the original image

class ImageCropper:
    def __init__(self, root, input_folder):
        self.root = root
        self.root.title("Image Cropper")

        if input_folder:
            self.input_folder = input_folder
        else:
            self.input_folder = filedialog.askdirectory(title="Select Folder with Images")

        self.output_folder = os.path.join(os.path.dirname(self.input_folder), "Slides04_Cropped")
        os.makedirs(self.output_folder, exist_ok=True)

        self.image_files = self.get_sorted_images()

        self.selected_image = StringVar(self.root)
        self.selected_image.set(self.image_files[0])

        Label(self.root, text="Select Image:").pack()
        self.dropdown = OptionMenu(self.root, self.selected_image, *self.image_files)
        self.dropdown.pack()

        self.canvas = Canvas(self.root)
        self.canvas.pack(expand=True, fill='both')

        self.crop_button = Button(self.root, text="Enter Cropping Mode", command=self.crop_image)
        self.crop_button.pack(side='bottom')

        self.save_button = Button(self.root, text="Crop and Save", command=self.save_cropped_image)
        self.save_button.pack(side='bottom')

        self.current_image = None
        self.crop_box = None
        self.original_width, self.original_height = 0, 0
        self.display_width, self.display_height = 0, 0

        self.load_image(self.selected_image.get())
        self.selected_image.trace("w", self.update_image_selection)

    def get_sorted_images(self):
        image_files = [f for f in os.listdir(self.input_folder) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.tif', '.bmp'))]

        def extract_numbers(filename):
            match = re.match(r'S(\d+)s(\d+)', filename)
            if match:
                slide_number = int(match.group(1))
                section_number = int(match.group(2))
                return slide_number, section_number
            return 0, 0

        return sorted(image_files, key=lambda f: extract_numbers(f))

    def update_image_selection(self, *args):
        self.load_image(self.selected_image.get())

    def load_image(self, image_name):
        image_path = os.path.join(self.input_folder, image_name)
        self.current_image = Image.open(image_path)

        self.original_width, self.original_height = self.current_image.size

        screen_width = self.root.winfo_screenwidth() - 100
        screen_height = self.root.winfo_screenheight() - 100

        display_image = self.current_image.copy()

        # Normalize unsupported modes for display
        if display_image.mode not in ("RGB", "L"):
            try:
                image_array = np.array(display_image)
                image_array = image_array.astype(np.float32)
                image_array -= image_array.min()
                if image_array.max() != 0:
                    image_array /= image_array.max()
                image_array *= 255
                image_array = image_array.astype(np.uint8)
                if image_array.ndim == 2:
                    display_image = Image.fromarray(image_array, mode='L')
                elif image_array.ndim == 3 and image_array.shape[2] == 3:
                    display_image = Image.fromarray(image_array, mode='RGB')
                else:
                    display_image = Image.fromarray(image_array)
            except Exception as e:
                print(f"Failed to normalize image {image_name}: {e}")
                return

        max_size = screen_width, screen_height - 150
        display_image.thumbnail(max_size, Image.Resampling.LANCZOS)

        self.display_width, self.display_height = display_image.size

        self.photo = ImageTk.PhotoImage(display_image)
        self.canvas.create_image(0, 0, anchor='nw', image=self.photo)

        self.scale_x = self.original_width / self.display_width
        self.scale_y = self.original_height / self.display_height

        self.canvas.config(width=self.display_width, height=self.display_height)

    def crop_image(self):
        if self.current_image:
            display_crop_width = int(crop_size[0] / self.scale_x)
            display_crop_height = int(crop_size[1] / self.scale_y)

            self.crop_box = self.canvas.create_rectangle(50, 50, 50 + display_crop_width, 50 + display_crop_height, outline="red", width=2)
            self.canvas.bind("<B1-Motion>", self.move_crop_box)

    def move_crop_box(self, event):
        if self.crop_box:
            display_crop_width = int(crop_size[0] / self.scale_x)
            display_crop_height = int(crop_size[1] / self.scale_y)
            self.canvas.coords(self.crop_box, event.x, event.y, event.x + display_crop_width, event.y + display_crop_height)

    def save_cropped_image(self):
        if self.current_image and self.crop_box:
            x1, y1, x2, y2 = self.canvas.coords(self.crop_box)

            original_x1 = int(x1 * self.scale_x)
            original_y1 = int(y1 * self.scale_y)
            original_x2 = int(x2 * self.scale_x)
            original_y2 = int(y2 * self.scale_y)

            cropped = self.current_image.crop((original_x1, original_y1, original_x2, original_y2))
            cropped = cropped.resize(crop_size)

            dpi = self.current_image.info.get('dpi', (72, 72))
            output_image_path = os.path.join(self.output_folder, self.selected_image.get())
            cropped.save(output_image_path, dpi=dpi)
            print(f"Cropped image saved with {dpi} DPI: {output_image_path}")

if __name__ == "__main__":
    root = Tk()
    app = ImageCropper(root, input_folder)
    root.mainloop()
