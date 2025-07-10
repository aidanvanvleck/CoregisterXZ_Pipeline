%   Updated: 2024.11.4, AVV
%   Further documentation on the Skin CoRegistration protocol can be found in the YoLab - Current Projects Google drive. 
%   Google Drive Folder Path: YoLab - Current Projects/_Components and General Protocols/Skin CoRegistration Protocol/ Reference Protocol for Fluorescent Skin CoRegistration (XZ)
%   Link to Reference Protocol: https://docs.google.com/document/d/1KUnpuI36MQvX3E29HvcNMlztZdPCnHxa7kklqnhdchs/edit?usp=sharing

%   Script Description:  This script will perform two basic steps to prepare raw fluorescent images for Marked Line Analysis. First, the script will automatically brighten and enhance the contrast of the images, saving them to a folder, "Slides02_BrightenedCE". Then, the script will allow the user to manually level the images by selecting two points to define the level line, and then saving the images in another folder called "Slides03_Leveled".
%   Mandatory Inputs to Modify: For each sample, two inputs must be modified. 
%       inputFolder: File path to the raw fluorescent image folder
%           Example: C:\YoLab - Current Projects\[Project]OCT2Hist 40x\LM\LM-01\RawData\Slides\Slides01_Raw
%       mainSlidesFolder: File path to the sample's main slides folder
%           Example: C:\YoLab - Current Projects\[Project]OCT2Hist 40x\LM\LM-01\RawData\Slides
%   Optional Inputs to Modify: The script will automatically brighten and enhance the contrast of all images during the first step. 
%       runPhase1: Set this to fasle if you want to skip the first
%       (brightening, contrast enhancement) step and go directly to
%       leveling
%       Contrast enhancement on Ln 48. By default, this value is 0.003
%       Brightness is controlled . By default, this value is 1.005 



function enhance_and_level_images()
    
    % Inputs: Modify these paths for your dataset
    inputFolder = '';  
    mainSlidesFolder = '';

    % Toggle for Phase 1 (Enhance and Save Images)
    runPhase1 = true; % Set to false to skip Phase 1 and directly proceed to leveling
    
    % Automatically create intermediate and output folder paths
    intermediateFolder = fullfile(mainSlidesFolder, 'Slides02_BrightenedCE');
    outputFolder = fullfile(mainSlidesFolder, 'Slides03_Leveled');
    
    % Create intermediate and output folders if they don't exist
    if ~exist(intermediateFolder, 'dir')
        mkdir(intermediateFolder);
    end
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    
    % Get list of image files in the folder
    imageFiles = dir(fullfile(inputFolder, '*.*'));
    validExtensions = {'.jpg', '.jpeg', '.png', '.bmp', '.tif', '.tiff'};
    
    if runPhase1
        % Phase 1: Enhance images
        for i = 1:length(imageFiles)
            [~, ~, ext] = fileparts(imageFiles(i).name);
            if ismember(lower(ext), validExtensions)
                img = imread(fullfile(inputFolder, imageFiles(i).name));
                
                % Convert to grayscale if necessary
                if size(img, 3) == 3
                    imgGray = rgb2gray(img); % Convert RGB to grayscale
                else
                    imgGray = img; % Use the image as is if it's already grayscale
                end
                
                % Ensure the image is strictly 2D
                imgGray = imgGray(:, :, 1); % Force conversion to 2D
                
                % Enhance contrast and brighten image
                imgEnhanced = adapthisteq(imgGray, 'ClipLimit', 0.003); % Adjust ClipLimit if needed
                imgBrightened = imadjust(imgEnhanced, [], [], 1.005);  % Brightening factor
                
                % Save to intermediate folder
                intermediateFileName = fullfile(intermediateFolder, imageFiles(i).name);
                imwrite(imgBrightened, intermediateFileName);
                fprintf('Enhanced and saved: %s\n', imageFiles(i).name);
            end
        end
    else
        fprintf('Skipping Phase 1: Enhance and Save Images\n');
    end
    
    % Phase 2: Level images
    enhancedFiles = dir(fullfile(intermediateFolder, '*.*'));
    enhancedFiles = enhancedFiles(~[enhancedFiles.isdir]); % Remove directories from file list
    
    % Create UI for leveling
    fig = figure('Name', 'Image Leveling Tool', 'NumberTitle', 'off', ...
                 'MenuBar', 'none', 'ToolBar', 'none', 'Position', [100, 100, 800, 600]);
    dropdown = uicontrol('Style', 'popupmenu', 'String', {enhancedFiles.name}, ...
                         'Position', [20, 20, 200, 30], 'Callback', @loadImage);
    btnSave = uicontrol('Style', 'pushbutton', 'String', 'Save Image', ...
                        'Position', [240, 20, 100, 30], 'Callback', @saveImage);
    
    % Initialize variables to store current image data
    rotatedImg = [];
    currentFileName = '';
    
    % Nested Functions
    
    function loadImage(~, ~)
        % Load the selected image for leveling
        selectedIndex = get(dropdown, 'Value');
        currentFileName = enhancedFiles(selectedIndex).name;
        img = imread(fullfile(intermediateFolder, currentFileName));
        
        % Display the image and allow user to select points
        imshow(img, 'InitialMagnification', 'fit');
        title('Click two points to define the leveling line');
        [x, y] = ginput(2); % User selects two points
        
        % Calculate the angle of rotation (line should be horizontal)
        deltaY = y(2) - y(1);
        deltaX = x(2) - x(1);
        angle = atan2d(deltaY, deltaX); % Positive angles rotate counterclockwise
        
        % Rotate the image to align the selected line horizontally
        rotatedImg = imrotate(img, angle, 'bicubic', 'loose');  % Changed from 'crop' to 'loose'
        
        % If the rotation is still incorrect, invert the angle
        % rotatedImg = imrotate(img, -angle, 'bicubic', 'crop'); % Uncomment this if needed
    
        % Display the rotated image
        imshow(rotatedImg, 'InitialMagnification', 'fit');
        title('Rotated Image');
        
        % Debugging Information
        fprintf('DeltaX: %.2f, DeltaY: %.2f, Calculated Angle: %.2f degrees\n', deltaX, deltaY, angle);
    end



    function saveImage(~, ~)
        % Save the leveled image
        if ~isempty(rotatedImg)
            outputFileName = fullfile(outputFolder, currentFileName);
            imwrite(rotatedImg, outputFileName);
            fprintf('Saved leveled image: %s\n', currentFileName);
        else
            warning('No image has been leveled. Please load and process an image first.');
        end
    end

    % Close figure when finished
    uiwait(fig); % Wait until figure is closed before ending script
end