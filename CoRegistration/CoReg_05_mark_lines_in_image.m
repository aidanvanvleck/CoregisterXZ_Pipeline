%   Updated: 2024.11.7, AVV
%   Further documentation on the Skin CoRegistration protocol can be found in the YoLab - Current Projects Google drive. 
%   Google Drive Folder Path: YoLab - Current Projects/_Components and General Protocols/Skin CoRegistration Protocol/ Reference Protocol for Fluorescent Skin CoRegistration (XZ)
%   Link to Reference Protocol: https://docs.google.com/document/d/1-fYOJLyQK2c38IUVoarcfj_TPqYVu_sRxUwiC_I94dQ/edit?tab=t.0#heading=h.nw90t991hz9y

%   Script Description:  
%   Mandatory Inputs to Modify: For each sample, two inputs must be modified. 
%       inputFolder: File path to the folder containing your sections to be marked
%           Example: C:\YoLab - Current Projects\[Project]OCT2Hist 40x\LM\LM-01\RawData\Slides\Slides05_AnnotatedCropped
%       mainCoRegistrationFolder: File path to the sample's CoRegistration folder
%           Example: C:\YoLab - Current Projects\[Project]OCT2Hist 40x\LM\LM-01\CoRegistration

function mark_lines_in_image()
    % Define the folder path
    inputFolder = 'E:\Shared drives\Yolab - Current Projects\[Project] OCT2Hist 40x\LM\LM-09\RawData\Slides\Slides06_AnnotatedCropped';
    mainCoRegistrationFolder = 'E:\Shared drives\Yolab - Current Projects\[Project] OCT2Hist 40x\LM\LM-09'


    % Get a list of all image files in the folder
    image_files = dir(fullfile(inputFolder, '*.png'));  % Adjust extension for your images
    if isempty(image_files)
        error('No images found in the selected folder.');
    end
    
    % Create a figure for image display
    fig = figure('Name', 'Mark Lines in Image', 'NumberTitle', 'off');
    img_axes = axes(fig);
    
    % Dropdown menu for image selection
    image_names = {image_files.name}; % Names of all images
    dropdown = uicontrol('Style', 'popupmenu', 'String', image_names, ...
                         'Position', [20 20 150 50], 'Callback', @update_image);
    
    % Save button
    uicontrol('Style', 'pushbutton', 'String', 'Save', ...
              'Position', [180 20 100 50], 'Callback', @save_coordinates);
    
    % Button to start coordinate selection mode
    uicontrol('Style', 'pushbutton', 'String', 'Start Selection', ...
              'Position', [300 20 150 50], 'Callback', @start_selection);
    
    % Variables to hold current image and coordinates
    current_image = imread(fullfile(inputFolder, image_names{1}));
    coordinates = {};
    image_index = 1;
    selecting = false;
    
    % Display the first image
    display_image();

    % Callback to update image when dropdown is changed
    function update_image(src, ~)
        image_index = get(src, 'Value');
        current_image = imread(fullfile(inputFolder, image_files(image_index).name));
        coordinates = {};  % Reset coordinates for new image
        selecting = false; % Reset selection mode
        display_image();
    end

    % Updated display_image function to handle 4-channel images
    function display_image()
        try
            % Check if the image has more than 3 channels (e.g., an alpha channel)
            if size(current_image, 3) > 3
                % Take only the first 3 channels (RGB)
                current_image_rgb = current_image(:,:,1:3);
            elseif size(current_image, 3) == 1
                % Convert grayscale to RGB by replicating the grayscale channel
                current_image_rgb = repmat(current_image, [1, 1, 3]);
            else
                % If it's already RGB, keep it as is
                current_image_rgb = current_image;
            end

            % Display the image
            imshow(current_image_rgb, 'Parent', img_axes);
        catch ME
            % If there is an error, display the message
            warning('Unable to display image. Ensure it is in a valid format. Error: %s', ME.message);
        end
        title(img_axes, sprintf('Selected Image: %s', image_files(image_index).name));
    end

    % Callback for the Save button
    function save_coordinates(~, ~)
        % Save coordinates to the text file for the current image
        save_lines_to_file();
        title(img_axes, sprintf('Saved coordinates for: %s', image_files(image_index).name));
    end

    % Callback to start selecting points
    function start_selection(~, ~)
        selecting = true;
        title(img_axes, 'Click the endpoints of each line (press Enter to finish)');
        select_points();
    end

    % Function to select points interactively
    function select_points()
        while selecting && ishandle(fig)
            [x, y] = ginput(2);
            if isempty(x) || size(x, 1) < 2
                break;
            end
            % Plot the line on the image
            hold on;
            plot(img_axes, x, y, 'r', 'LineWidth', 2);
            hold off;
            coordinates{end+1} = [round(x(1)), round(y(1)); round(x(2)), round(y(2))];
        end
    end
    
    % Function to save coordinates to text file
    function save_lines_to_file()
        % Get the name of the current image
        [~, image_name, ~] = fileparts(image_files(image_index).name);
        
        % Prepare the text file path
        output_file = fullfile(mainCoRegistrationFolder, 'Marked Line Coordinates.txt');
        
        % Check if file exists, and read its contents
        if exist(output_file, 'file')
            existing_data = fileread(output_file);
        else
            existing_data = '';
        end
        
        % Check if the image name already exists in the file
        count = 0;
        while contains(existing_data, image_name)
            count = count + 1;
            image_name = sprintf('%s.%d', image_name, count);
        end
        
        % Open the text file for appending
        fid = fopen(output_file, 'a');
        if fid == -1
            error('Failed to open or create the text file.');
        end
        
        % Write the image identifier (image name)
        fprintf(fid, '%s\n', image_name);
        
        % Write the coordinates in the desired format
        for i = 1:length(coordinates)
            coord_str = sprintf('[ [%d, %d], [%d, %d] ],', ...
                                coordinates{i}(1,1), coordinates{i}(1,2), ...
                                coordinates{i}(2,1), coordinates{i}(2,2));
            fprintf(fid, '%s\n', coord_str);
        end
        
        % Close the file
        fclose(fid);
        
        % Clear coordinates for next image
        coordinates = {};
        
        % Sort and rewrite the file content alphabetically
        function sort_and_rewrite_file(output_file)
            % Read the existing lines from the file
            fileID = fopen(output_file, 'r');
            if fileID == -1
                % If file does not exist or cannot be opened, exit function
                return;
            end
            
            % Initialize arrays for image names and coordinates
            coordinates_lines = {};
            image_names = {};
            
            % Read file line by line
            while ~feof(fileID)
                line = fgetl(fileID);
                if contains(line, '[')  % This is a coordinate line
                    coordinates_lines{end+1} = line; %#ok<AGROW>
                else  % This is an image name line
                    image_names{end+1} = line; %#ok<AGROW>
                end
            end
            fclose(fileID);
            
            % If there are no image names, we skip the sorting and rewriting process
            if isempty(image_names)
                warning('No image names found. Skipping sorting.');
                return;
            end
            
            % Custom sort function to handle appended suffixes correctly
            [sorted_names, sort_idx] = sort_image_names(image_names);
            
            % Sort the coordinate lines based on the sorted image names
            if length(coordinates_lines) == length(sort_idx)
                sorted_coords = coordinates_lines(sort_idx);
            else
                % If lengths don't match, give a warning and skip sorting
                warning('Mismatch between image names and coordinates. Skipping sorting.');
                return;
            end
            
            % Write the sorted results back to the file
            fileID = fopen(output_file, 'w');
            for i = 1:length(sorted_names)
                fprintf(fileID, '%s\n', sorted_names{i});
                fprintf(fileID, '%s\n', sorted_coords{i});
            end
            fclose(fileID);
        end
        
        % Display a message indicating the data was saved
        disp(['Coordinates saved to ', output_file]);
    end

    % Function to sort and rewrite the file alphabetically
    function sort_and_rewrite_file(filepath)
        % Read the content of the file
        file_content = fileread(filepath);
        lines = strsplit(file_content, '\n');
        
        % Remove any empty lines
        lines = lines(~cellfun('isempty', lines));
        
        % Identify image names (which are not coordinates) and sort them
        image_names = lines(1:2:end);  % Every other line is an image name
        coordinates_lines = lines(2:2:end); % Coordinate lines follow each image name
        
        [sorted_names, sort_idx] = sort(image_names);
        sorted_coords = coordinates_lines(sort_idx);
        
        % Write the sorted data back to the file
        fid = fopen(filepath, 'w');
        if fid == -1
            error('Failed to open the file for writing.');
        end
        for i = 1:length(sorted_names)
            fprintf(fid, '%s\n', sorted_names{i});
            fprintf(fid, '%s\n', sorted_coords{i});
        end
        fclose(fid);
    end
end
