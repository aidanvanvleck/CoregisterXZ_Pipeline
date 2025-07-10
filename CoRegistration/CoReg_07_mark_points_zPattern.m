%   Updated: 2025.7.10, AVV
%   Further documentation on the Skin CoRegistration protocol can be found in the YoLab - Current Projects Google drive. 
%   Google Drive Folder Path: YoLab - Current Projects/_Components and General Protocols/Skin CoRegistration Protocol/ Reference Protocol for Fluorescent Skin CoRegistration (XZ)
%   Link to Reference Protocol: https://docs.google.com/document/d/1KUnpuI36MQvX3E29HvcNMlztZdPCnHxa7kklqnhdchs/edit?tab=t.0

%   Script Description: This script will add a white box to a 3D OCT volume, mimicking the square photobleached in the central 250um of the OCT scanning region. Do not use this script unless you have photobleached the square in the central 250x250 um of the OCT scan.
%   Recommended input file: The user should provide a *flattened* 3D OCT volume that has been resliced from the bottom so the default view is XY (as of 2024.11.4 default orientation after scanning and reconstructing is XZ). Slice 1 should be the lowest point in the scan. 
%   Mandatory Inputs to Modify: For each sample, there are two inputs that need to be verified. You must modify the input_file path, and the z_start, z_end inputs (as they rely on the height of the 3D volume)
%   Optional Inputs to Modify: A toggle exists for modifying the OCT contrast. If enhance_contrast (ln 18) is set to true, it will enhance the OCT contrast, referencing clip_limit (ln 19) to determine the extent of contrast enhancement.



function CoReg_07_mark_points_zPattern(folderPath)
% GUI to browse images, mark points in numeric patterns starting at 0,
% preview adjacent slides, show a color‐coded pattern key, persist per‐image JSON,
% and export in CoLab format.

%% 1) Select folder if none provided
if nargin<1 || isempty(folderPath)
    folderPath = uigetdir(pwd,'Select image folder');
    if isequal(folderPath,0), return; end
end

%% 2) Prepare JSON subfolder
jsonFolder = fullfile(folderPath,'json');
if ~exist(jsonFolder,'dir'), mkdir(jsonFolder); end

%% 3) Define patterns (0–18) + colors
nPatterns   = 19;
patternList = arrayfun(@(i) sprintf('Pattern %d', i-1), 1:nPatterns, 'UniformOutput', false);
colorMap    = hsv(nPatterns);

%% 4) Gather & natural‐sort images
exts = {'*.png','*.tif','*.jpg'}; files = [];
for k=1:numel(exts), files=[files;dir(fullfile(folderPath,exts{k}))]; end
names = {files.name}';
slideNums=zeros(size(names)); sectionNums=zeros(size(names));
for i=1:numel(names)
    t=regexp(names{i},'^S(\d+)s(\d+)','tokens','once');
    slideNums(i)=str2double(t{1}); sectionNums(i)=str2double(t{2});
end
[~,order]=sortrows([slideNums,sectionNums]); files=files(order);
if isempty(files), error('No images found.'); end
idx=1;

%% 5) Build UI
hFig = figure('Name','Fiducial Point Marker','NumberTitle','off','KeyPressFcn',@onKey);
% Top row: Preview Prev, Preview Next, Export All
topSz=[0.08 0.04];
prevToggle = uicontrol('Style','togglebutton','String','Prev Preview','Units','normalized', ...
    'Position',[0.02 0.92 topSz],'Callback',@togglePrevPreview);
nextToggle = uicontrol('Style','togglebutton','String','Next Preview','Units','normalized', ...
    'Position',[0.12 0.92 topSz],'Callback',@toggleNextPreview);
uicontrol('Style','pushbutton','String','Export All','Units','normalized', ...
    'Position',[0.22 0.92 topSz],'Callback',@exportAll);
% Preview axes
hAxPrev = axes('Parent',hFig,'Units','normalized','Position',[0.05 0.75 0.425 0.15],'Visible','off');
hAxNext = axes('Parent',hFig,'Units','normalized','Position',[0.525 0.75 0.425 0.15],'Visible','off');
% Main axes
hAx = axes('Parent',hFig,'Units','normalized','Position',[0.05 0.2 0.9 0.5]);
% Bottom row: Previous, Next, Add toggle, Delete, Pattern selector
botY=0.05; botSz=[0.08 0.04];
uicontrol('Style','pushbutton','String','Previous','Units','normalized', ...
    'Position',[0.02 botY botSz],'Callback',@prevImage);
uicontrol('Style','pushbutton','String','Next','Units','normalized', ...
    'Position',[0.12 botY botSz],'Callback',@nextImage);
addToggle = uicontrol('Style','togglebutton','String','Add Point','Units','normalized', ...
    'Position',[0.22 botY botSz],'Callback',@toggleAddMode);
uicontrol('Style','pushbutton','String','Delete','Units','normalized', ...
    'Position',[0.34 botY botSz],'Callback',@deletePoint);
uicontrol('Style','text','String','Pattern:','Units','normalized', ...
    'Position',[0.46 botY 0.06 0.04],'HorizontalAlignment','left');
groupPopup = uicontrol('Style','popupmenu','String',patternList,'Units','normalized', ...
    'Position',[0.52 botY 0.2 0.04]);

% --- Pattern key legend on right ---
legendAx = axes('Parent',hFig,'Units','normalized','Position',[0.92 0.2 0.06 0.7],'Visible','off');
axis(legendAx,'off','tight'); hold(legendAx,'on');
yPos = linspace(0.9, 0.1, nPatterns);
for i = 1:nPatterns
    plot(legendAx, 0.1, yPos(i), 'o', 'MarkerEdgeColor', colorMap(i,:), ...
        'LineWidth', 2);
    text(legendAx, 0.3, yPos(i), sprintf('%d', i-1), ...
        'Parent', legendAx, 'FontSize', 8, 'VerticalAlignment', 'middle');
end
title(legendAx, 'Legend', 'FontWeight', 'bold');

%% 6) Data containers
jsonData   = struct('FM',struct('fiducialPoints',struct('id',{},'x',{},'y',{},'patternID',{})));
points     = zeros(0,2);
patternIDs = [];
addMode    = false;

%% 7) Show first image
showImage();

%% --- Nested functions --- 

function showImage()
    % Hide previews
    cla(hAxPrev); set(hAxPrev,'Visible','off');
    cla(hAxNext); set(hAxNext,'Visible','off');
    % Save JSON of last image
    if isfield(jsonData,'jsonPath'), saveJSON(); end
    % Load current image
    info = files(idx); [~,b,~]=fileparts(info.name);
    I = imread(fullfile(folderPath,info.name));
    imshow(I,'Parent',hAx); hold(hAx,'on');
    title(hAx,sprintf('[%d/%d] %s',idx,numel(files),info.name),'Interpreter','none');
    % Load or init JSON
    jp = fullfile(jsonFolder,[b,'.json']);
    if exist(jp,'file')
        jsonData = jsondecode(fileread(jp));
    else
        jsonData = struct('FM',struct('fiducialPoints',struct('id',{},'x',{},'y',{},'patternID',{})));
    end
    jsonData.jsonPath = jp;
    % Extract stored points
    pts = jsonData.FM.fiducialPoints;
    if isempty(pts)
        points     = zeros(0,2);
        patternIDs = [];
    else
        points     = [[pts.x]' [pts.y]'];
        patternIDs = [pts.patternID];
    end
    drawPoints();
    % Refresh previews if toggled on
    if get(prevToggle,'Value'), drawPreview(idx-1,hAxPrev); end
    if get(nextToggle,'Value'), drawPreview(idx+1,hAxNext); end
end

function saveJSON()
    S = rmfield(jsonData,'jsonPath');
    fid = fopen(jsonData.jsonPath,'w');
    fwrite(fid, jsonencode(S,'PrettyPrint',true), 'char');
    fclose(fid);
end

function drawPoints()
    delete(findall(hAx,'Tag','fidPt')); hold(hAx,'on');
    for i=1:size(points,1)
        c = colorMap(patternIDs(i)+1,:);
        plot(hAx, points(i,1), points(i,2), 'o', 'MarkerSize',8, ...
             'MarkerEdgeColor',c,'LineWidth',1,'Tag','fidPt');
    end
    hold(hAx,'off');
end

function prevImage(~,~)
    idx = max(idx-1,1); cla(hAx); showImage();
end

function nextImage(~,~)
    idx = min(idx+1,numel(files)); cla(hAx); showImage();
end

function toggleAddMode(src,~)
    addMode = logical(src.Value);
    if addMode
        set(hFig,'WindowButtonDownFcn',@onClick);
    else
        set(hFig,'WindowButtonDownFcn','');
    end
end

function onClick(~,~)
    cp = get(hAx,'CurrentPoint'); x=cp(1,1); y=cp(1,2);
    xl=get(hAx,'XLim'); yl=get(hAx,'YLim');
    if x>=xl(1)&&x<=xl(2)&&y>=yl(1)&&y<=yl(2)
        if ~isstruct(jsonData.FM.fiducialPoints)
            jsonData.FM.fiducialPoints=struct('id',{},'x',{},'y',{},'patternID',{});
        end
        pid = get(groupPopup,'Value')-1;
        p.id        = numel(jsonData.FM.fiducialPoints)+1;
        p.x         = x; p.y = y;
        p.patternID = pid;
        jsonData.FM.fiducialPoints(end+1)=p;
        points(end+1,:)   = [x y];
        patternIDs(end+1) = pid;
        drawPoints(); saveJSON();
    end
end

function deletePoint(~,~)
    [x,y] = ginput(1); if isempty(points), return; end
    [~,iMin]=min(hypot(points(:,1)-x,points(:,2)-y));
    points(iMin,:)=[]; patternIDs(iMin)=[];
    jsonData.FM.fiducialPoints(iMin)=[]; drawPoints(); saveJSON();
end

function togglePrevPreview(src,~)
    if src.Value, drawPreview(idx-1,hAxPrev);
    else, cla(hAxPrev); set(hAxPrev,'Visible','off'); end
end

function toggleNextPreview(src,~)
    if src.Value, drawPreview(idx+1,hAxNext);
    else, cla(hAxNext); set(hAxNext,'Visible','off'); end
end

function drawPreview(ind, ax)
    if ind<1||ind>numel(files), return; end
    info = files(ind); [~,b,~]=fileparts(info.name);
    I = imread(fullfile(folderPath,info.name));
    imshow(I,'Parent',ax); hold(ax,'on');
    title(ax,info.name,'Interpreter','none');
    jp = fullfile(jsonFolder,[b,'.json']);
    if exist(jp,'file')
        D=jsondecode(fileread(jp));
        for jj=1:numel(D.FM.fiducialPoints)
            pt = D.FM.fiducialPoints(jj);
            c  = colorMap(pt.patternID+1,:);
            plot(ax,pt.x,pt.y,'o','MarkerEdgeColor',c,'LineWidth',1);
        end
    end
    set(ax,'Visible','on');
end

function exportAll(~,~)
    outFile = fullfile(folderPath,'compiled_points.txt');
    fid     = fopen(outFile,'w');
    for j=1:numel(files)
        [~,b,~]=fileparts(files(j).name);
        fprintf(fid,'slide_name = ''%s''\n',b);
        fprintf(fid,'fluorescent_image_points_uv_pix = {\n');
        jp = fullfile(jsonFolder,[b,'.json']);
        if exist(jp,'file')
            D   = jsondecode(fileread(jp));
            pts = D.FM.fiducialPoints;
            if ~isempty(pts)
                ids = unique([pts.patternID]);
                for k=ids
                    coords = round([[pts([pts.patternID]==k).x]' [pts([pts.patternID]==k).y]']);
                    fprintf(fid,'    %d:[[',k);
                    for m=1:size(coords,1)
                        fprintf(fid,'[%d, %d]',coords(m,1),coords(m,2));
                        if m<size(coords,1), fprintf(fid,'], ['); end
                    end
                    fprintf(fid,']]\n');
                end
            end
        end
        fprintf(fid,'}\n\n');
    end
    fclose(fid);
    msgbox(['Saved to ',outFile],'Export Complete');
end

function onKey(~,evt)
    switch evt.Key
        case 'rightarrow', nextImage();
        case 'leftarrow',  prevImage();
        case 'a'
            val = ~get(addToggle,'Value');
            set(addToggle,'Value',val);
            toggleAddMode(addToggle);
        case 'd', deletePoint();
    end
end
end
