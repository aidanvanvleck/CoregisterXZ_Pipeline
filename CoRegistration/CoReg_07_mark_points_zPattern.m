function CoReg_07_mark_points_zPattern(folderPath)
% GUI to browse images, mark points in numeric patterns, preview adjacent slides,
% persist per-image JSON, and export in CoLab-friendly format.

%% 1) Select folder if not provided
if nargin<1 || isempty(folderPath)
    folderPath = uigetdir(pwd,'Select image folder');
    if isequal(folderPath,0), return; end
end

%% 2) Prepare JSON subfolder
jsonFolder = fullfile(folderPath,'json');
if ~exist(jsonFolder,'dir'), mkdir(jsonFolder); end

%% 3) Patterns & colors
nPatterns   = 19;
patternList = arrayfun(@(i)sprintf('Pattern %d',i),1:nPatterns,'UniformOutput',false);
colorMap    = hsv(nPatterns);

%% 4) Gather & natural-sort images
exts = {'*.png','*.tif','*.jpg'};
files = [];
for k=1:numel(exts)
    files = [files; dir(fullfile(folderPath,exts{k}))];
end
names = {files.name}';
slideNums   = zeros(size(names)); sectionNums = zeros(size(names));
for i=1:numel(names)
    t = regexp(names{i},'^S(\d+)s(\d+)','tokens','once');
    slideNums(i)=str2double(t{1}); sectionNums(i)=str2double(t{2});
end
[~,ord] = sortrows([slideNums(:), sectionNums(:)]);
files   = files(ord);
if isempty(files), error('No images found in %s.', folderPath); end
idx = 1;

%% 5) Build UI
hFig = figure('Name','Fiducial Point Marker','NumberTitle','off','KeyPressFcn',@onKey);

% Top row: Preview Prev/Next & Export
topSz = [0.08 0.04];
uicontrol('Style','pushbutton','String','Preview Prev','Units','normalized', ...
    'Position',[0.02 0.92 topSz],'Callback',@previewPrev);
uicontrol('Style','pushbutton','String','Preview Next','Units','normalized', ...
    'Position',[0.12 0.92 topSz],'Callback',@previewNext);
uicontrol('Style','pushbutton','String','Export All','Units','normalized', ...
    'Position',[0.22 0.92 topSz],'Callback',@exportAll);

% Preview axes
hAxPrev = axes('Parent',hFig,'Units','normalized','Position',[0.05 0.75 0.9 0.15],'Visible','off');

% Main axes
hAx = axes('Parent',hFig,'Units','normalized','Position',[0.05 0.2 0.9 0.5]);

% Bottom row: Previous, Next, Add Toggle, Delete, Pattern
botY = 0.05; botSz = [0.08 0.04];
uicontrol('Style','pushbutton','String','Previous','Units','normalized', ...
    'Position',[0.02 botY botSz],'Callback',@prevImage);
uicontrol('Style','pushbutton','String','Next','Units','normalized', ...
    'Position',[0.12 botY botSz],'Callback',@nextImage);
uicontrol('Style','togglebutton','String','Add Point','Units','normalized', ...
    'Position',[0.22 botY botSz],'Callback',@toggleAdd);
uicontrol('Style','pushbutton','String','Delete','Units','normalized', ...
    'Position',[0.34 botY botSz],'Callback',@deletePoint);
uicontrol('Style','text','String','Pattern:','Units','normalized', ...
    'Position',[0.46 botY 0.06 0.04],'HorizontalAlignment','left');
groupPopup = uicontrol('Style','popupmenu','String',patternList,'Units','normalized', ...
    'Position',[0.52 botY 0.2 0.04]);

%% 6) Data containers
jsonData   = struct('FM',struct('fiducialPoints',struct('id',{},'x',{},'y',{},'patternID',{})));
points     = zeros(0,2);
patternIDs = [];
addMode    = false;

%% 7) Show first image
showImage();

%% --- Nested functions ---

    function showImage()
        % hide preview
        cla(hAxPrev); set(hAxPrev,'Visible','off');
        % save JSON of previous
        if isfield(jsonData,'jsonPath'), saveJSON(); end
        % load current image
        info = files(idx); [~,b,~] = fileparts(info.name);
        I = imread(fullfile(folderPath,info.name));
        imshow(I,'Parent',hAx); hold(hAx,'on');
        title(hAx,sprintf('[%d/%d] %s',idx,numel(files),info.name),'Interpreter','none');
        % load or init JSON
        jp = fullfile(jsonFolder,[b,'.json']);
        if exist(jp,'file')
            jsonData = jsondecode(fileread(jp));
        else
            jsonData = struct('FM',struct('fiducialPoints',struct('id',{},'x',{},'y',{},'patternID',{})));
        end
        jsonData.jsonPath = jp;
        % extract points
        pts = jsonData.FM.fiducialPoints;
        if isempty(pts)
            points = zeros(0,2); patternIDs = [];
        else
            points     = [[pts.x]' [pts.y]'];
            patternIDs = [pts.patternID];
        end
        drawPoints();
    end

    function saveJSON()
        S = rmfield(jsonData,'jsonPath');
        fid = fopen(jsonData.jsonPath,'w');
        fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');
        fclose(fid);
    end

    function drawPoints()
        delete(findall(hAx,'Tag','fidPt'));
        hold(hAx,'on');
        for ii=1:size(points,1)
            c = colorMap(patternIDs(ii),:);
            plot(hAx,points(ii,1),points(ii,2),'o','MarkerEdgeColor',c,'LineWidth',1,'Tag','fidPt');
        end
        hold(hAx,'off');
    end

    function prevImage(~,~)
        idx = max(idx-1,1);
        cla(hAx); showImage();
    end

    function nextImage(~,~)
        idx = min(idx+1,numel(files));
        cla(hAx); showImage();
    end

    function toggleAdd(src,~)
        addMode = logical(src.Value);
        if addMode
            set(hFig,'WindowButtonDownFcn',@onClick);
        else
            set(hFig,'WindowButtonDownFcn','');
        end
    end

    function onClick(~,~)
        pt = get(hAx,'CurrentPoint'); x=pt(1,1); y=pt(1,2);
        xl = get(hAx,'XLim'); yl = get(hAx,'YLim');
        if x>=xl(1)&&x<=xl(2)&&y>=yl(1)&&y<=yl(2)
            if ~isstruct(jsonData.FM.fiducialPoints)
                jsonData.FM.fiducialPoints = struct('id',{},'x',{},'y',{},'patternID',{});
            end
            pid = get(groupPopup,'Value');
            p.id        = numel(jsonData.FM.fiducialPoints)+1;
            p.x         = x; p.y = y;
            p.patternID = pid;
            jsonData.FM.fiducialPoints(end+1) = p;
            points(end+1,:)   = [x y];
            patternIDs(end+1) = pid;
            drawPoints(); saveJSON();
        end
    end

    function deletePoint(~,~)
        [x,y] = ginput(1);
        if isempty(points), return; end
        [~,iMin] = min(hypot(points(:,1)-x,points(:,2)-y));
        points(iMin,:)           = [];
        patternIDs(iMin)         = [];
        jsonData.FM.fiducialPoints(iMin) = [];
        drawPoints(); saveJSON();
    end

    function previewPrev(~,~), previewOffset(-1); end
    function previewNext(~,~), previewOffset( 1); end

    function previewOffset(d)
        if idx+d<1||idx+d>numel(files), return; end
        prev = files(idx+d); [~,b,~] = fileparts(prev.name);
        I = imread(fullfile(folderPath,prev.name));
        imshow(I,'Parent',hAxPrev); hold(hAxPrev,'on');
        title(hAxPrev,prev.name,'Interpreter','none');
        try
            D = jsondecode(fileread(fullfile(jsonFolder,[b,'.json'])));
            for jj=1:numel(D.FM.fiducialPoints)
                pt = D.FM.fiducialPoints(jj);
                c = colorMap(pt.patternID,:);
                plot(hAxPrev,pt.x,pt.y,'o','MarkerEdgeColor',c,'LineWidth',1,'Tag','fidPt');
            end
            set(hAxPrev,'Visible','on');
        catch, end
    end

    function exportAll(~,~)
        outFile = fullfile(folderPath,'compiled_points.txt');
        fid     = fopen(outFile,'w');
        for jj=1:numel(files)
            [~,b,~] = fileparts(files(jj).name);
            fprintf(fid,'slide_name = ''%s''\n',b);
            fprintf(fid,'fluorescent_image_points_uv_pix = {\n');
            jp = fullfile(jsonFolder,[b,'.json']);
            if exist(jp,'file')
                D   = jsondecode(fileread(jp));
                pts = D.FM.fiducialPoints;
                if ~isempty(pts)
                    ids = unique([pts.patternID]);
                    for k=ids
                        sel    = [pts.patternID]==k;
                        coords = round([[pts(sel).x]' [pts(sel).y]']);
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
                tb = findobj(hFig,'Style','togglebutton');
                set(tb,'Value',~get(tb,'Value'));
                toggleAdd(tb);
            case 'd', deletePoint();
        end
    end
end
