% Batch_Run_ScanAndProcess.m
% Runs yOCTProcessTiledScan multiple times with different input values, saving all results in a single folder.

clc; clear; close all;

%% Inputs
sample_folder = 'H:\2025.3.26_NewPattern_Test1'; % Provide file path to your sample folder
custom_output_folder = ''; % Optional: Custom output location (leave as '' to use default inside sample_folder)

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

% Define the save folder
if isempty(custom_output_folder)
    save_folder = fullfile(sample_folder, 'Batch_Reconstruction\');
else
    save_folder = fullfile(custom_output_folder, 'Batch_Reconstruction\');
end

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

                                % ---------------------------------------------
                % Reslice to XY and save with _XY in subfolder
                try
                    info = imfinfo(outputTiffFile);
                    numPages = numel(info);
                    z = info(1).Height;
                    x = info(1).Width;

                    % Load the XZ volume (z, x, y)
                    volXZ = zeros(z, x, numPages, 'like', imread(outputTiffFile, 1));
                    for k = 1:numPages
                        volXZ(:, :, k) = imread(outputTiffFile, k);
                    end

                    % Reslice to XY (y, x, z)
                    volXY = permute(volXZ, [3, 2, 1]);

                    % Define output folder and filename
                    xy_output_folder = fullfile(save_folder, 'XY');
                    if ~exist(xy_output_folder, 'dir')
                        mkdir(xy_output_folder);
                    end
                    [~, baseName, ext] = fileparts(outputTiffFile);
                    xy_output_name = fullfile(xy_output_folder, [baseName, '_XY', ext]);

                    % Save XY stack
                    for k = 1:size(volXY, 3)
                        if k == 1
                            imwrite(volXY(:, :, k), xy_output_name, 'Compression', 'none');
                        else
                            imwrite(volXY(:, :, k), xy_output_name, 'WriteMode', 'append', 'Compression', 'none');
                        end
                    end
                    fprintf('Saved XY version: %s\n', xy_output_name);

                catch ME
                    warning('Failed to save XY version of %s\nError: %s', outputTiffFile, ME.message);
                end
                % ---------------------------------------------
            end
        end
    end
end
