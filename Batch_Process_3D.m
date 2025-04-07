% Batch_Run_ScanAndProcess.m
% Runs yOCTProcessTiledScan multiple times with different input values, saving all results in a single folder.

clc; clear; close all;

%% Inputs
sample_folder = 'H:\2025.3.26_NewPattern_Test1'; % Provide file path to your sample folder

% Define reconstruction parameter sets
focusSigma_values = [10, 20]; 
dispersionQuadraticTerm_values = [-1.496e+08, -1.516e+08, -1.536e+08];
tissueRefractiveIndex_values = [1.33]; 
focusPositionInImageZpix_values  = [492, 493];

% Ensure the sample_folder path ends with a backslash \
if ~endsWith(sample_folder, '\')
    sample_folder = [sample_folder, '\'];
end

% Automatically define the base scan folder (OCTVolume)
base_scan_folder = fullfile(sample_folder, 'OCTVolume\');

% Automatically define the save folder (Batch Reconstruction)
save_folder = fullfile(sample_folder, 'Batch_Reconstruction\');

% Ensure the save folder exists
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end

%% Loop through all parameter combinations
for fS = focusSigma_values
    for dQ = dispersionQuadraticTerm_values
        for tRI = tissueRefractiveIndex_values
            for focusPos = focusPositionInImageZpix_values

                fprintf('%s Running reconstruction with focusSigma=%d, dispersionQuadraticTerm=%.3e, tissueRefractiveIndex=%.2f, focusPosition=%d\n', ...
                    datestr(datetime), fS, dQ, tRI, focusPos);

                % Format output filename (ensuring uniqueness)
                outputFilename = sprintf('ScanAndProcess__dQ%.3e_fS%d_tRI%.2f_focus%d.tiff', ...
                    dQ, fS, tRI, focusPos);
                outputTiffFile = fullfile(save_folder, outputFilename);

                % Run the reconstruction process directly
                yOCTProcessTiledScan(...
                    base_scan_folder, ... % Automatically set scan data folder
                    {outputTiffFile}, ... % Save results in 'Batch_Reconstruction'
                    'focusPositionInImageZpix', focusPos, ...
                    'focusSigma', fS, ...
                    'dispersionQuadraticTerm', dQ, ...
                    'tissueRefractiveIndex', tRI, ...
                    'interpMethod', 'sinc5', ...
                    'v', true);

                % Pause briefly to allow saving to complete
                pause(3);

            end
        end
    end
end
