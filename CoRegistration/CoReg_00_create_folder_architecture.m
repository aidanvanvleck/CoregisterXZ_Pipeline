%   Updated: 2024.11.4, AVV
%   Further documentation on the Skin CoRegistration protocol can be found in the YoLab - Current Projects Google drive. 
%   Google Drive Folder Path: YoLab - Current Projects/_Components and General Protocols/Skin CoRegistration Protocol/ Reference Protocol for Fluorescent Skin CoRegistration (XZ)
%   Link to Reference Protocol: https://docs.google.com/document/d/1-fYOJLyQK2c38IUVoarcfj_TPqYVu_sRxUwiC_I94dQ/edit?tab=t.0#heading=h.nw90t991hz9y

%   Script Description:  This script will create the folder architecture used for each sample to ensure data is always saved in the same format. 
%   Mandatory Inputs to Modify: 
%       sample_folder: Points to your sample's main folder  
%           Example: C:\YoLab - Current Projects\[Project]OCT2Hist 40x\LM\LM-01



%% Main Script
sample_folder = 'G:\Shared drives\Yolab - Current Projects\Aidan (Drive)\2025 New Pattern\2025.3.26_test1';    % The file path to your sample's main folder. This should be an empty folder. 
createFileStructure(sample_folder);


% Function Definition
function createFileStructure(sample_folder)
    % Check if the master folder (sample_folder) exists, if not, create it
    if ~exist(sample_folder, 'dir')
        mkdir(sample_folder);
    end

    % Define top-level subfolder names
    subfolders = {'CoRegistration', 'RawData','ImagePairs'};

    % Create top-level subfolders
    for i = 1:length(subfolders)
        subfolderPath = fullfile(sample_folder, subfolders{i});
        if ~exist(subfolderPath, 'dir')
            mkdir(subfolderPath);
        end
    end

    % Create subfolders within the 'RawData' folder
    RawDataFolder = fullfile(sample_folder, 'RawData');
    RawDataSubfolders = {'Slides', 'OCT', 'BulkTissue'};
    
    for i = 1:length(RawDataSubfolders)
        subfolderPath = fullfile(RawDataFolder, RawDataSubfolders{i});
        if ~exist(subfolderPath, 'dir')
            mkdir(subfolderPath);
        end
    end

    % Create subfolders within the 'Slides' folder
    slidesFolder = fullfile(RawDataFolder, 'Slides');  % Corrected 'RawData' to 'RawDataFolder'
    slidesSubfolders = {'Slides01_Raw','Slides05_Annotated','Slides06_AnnotatedCropped'};
    
    for i = 1:length(slidesSubfolders)
        subfolderPath = fullfile(slidesFolder, slidesSubfolders{i});
        if ~exist(subfolderPath, 'dir')
            mkdir(subfolderPath);
        end
    end

    % Create subfolders within the 'Slides01_Raw' folder
    slides01Folder = fullfile(slidesFolder, 'Slides01_Raw');  % Corrected 'RawData' to 'slidesFolder'
    slides01Subfolders = {'Fluorescent','H&E'};
    
    for i = 1:length(slides01Subfolders)
        subfolderPath = fullfile(slides01Folder, slides01Subfolders{i});
        if ~exist(subfolderPath, 'dir')
            mkdir(subfolderPath);
        end
    end



    % Create subfolders within the 'CoRegistration' folder
    CoRegistrationFolder = fullfile(sample_folder, 'CoRegistration');
    CoRegistrationSubfolders = {'OCTSlices', 'CoLab_SectionLocation'};
    
    for i = 1:length(CoRegistrationSubfolders)
        subfolderPath = fullfile(CoRegistrationFolder, CoRegistrationSubfolders{i});
        if ~exist(subfolderPath, 'dir')
            mkdir(subfolderPath);
        end
    end

    disp('Folder structure created successfully.');
end
