classdef mScopeFileSelect < handle
    
    properties
        MainFigH
        SpoolPathH
        ButtonH
        
        COLOR_INPUT_BGD = [1 1 1];
        COLOR_INPUT_TEXT = [0 0 0];
        FONT_INPUT = 'Arial';
        
        SpoolPath = pwd;
        State = 0; % simulate idle
    end
    
    methods
        function obj = mScopeFileSelect
            
            obj.MainFigH = figure('KeyPressFcn',@(~,~) fprintf('helloworld\n'));
            
            set(obj.MainFigH,'DefaultUiControlKeyPressFcn',@(~,~) fprintf('helloworld\n'));
            
            obj.SpoolPathH = uicontrol('Parent',obj.MainFigH,...
                'Callback',@obj.setSpoolPath,...
                'keyPressFcn',@obj.tabSpoolPath,...
                'Style','edit',...
                'BackgroundColor',obj.COLOR_INPUT_BGD,...
                'Units','Normalized',...
                'Position',[0.0, 0.95, 0.50, 0.05],...
                'FontUnits','Normalized',...
                'FontName',obj.FONT_INPUT,...
                'FontSize',0.5,...
                'FontWeight','normal',...
                'ForegroundColor',obj.COLOR_INPUT_TEXT,...
                'String',obj.SpoolPath,...
                'Visible','on',...
                'tooltip','Use arrow keys to browse');
            
            obj.ButtonH = uicontrol('Parent',obj.MainFigH,...
                'style','pushbutton')
        end
        
        function emptyFcn(~,~,~)
        end
        
        function tabSpoolPath(obj,src,evt)
            % if not idle then don't allow any changes
            if obj.State ~= 0
                set(src,'String',obj.SpoolPath);% reset the input
                return % cancel any changes
            end
            
            currentPath = get(src,'String');
            slashArray = strfind(currentPath,'\'); % only on WIN
            lastForwardSlash = strfind(currentPath,'/');
            slashArray = [slashArray, lastForwardSlash];
            slashArray = sort(slashArray);
            lastSlash = slashArray(end);
            currentParentFolder = currentPath(1:max(1,lastSlash-1));
            currentFolder = currentPath(min(end,lastSlash+1):end);
            if strcmp(currentFolder,'\') || strcmp(currentFolder,'/');
                currentFolder = '';
            end
            foldersWithin = {};
            numFolders = 0;
            if exist(currentParentFolder,'dir')
                % if the folder part of the path is a directory, then lets
                % extract the names of the folders within
                listWithin = dir(fullfile(currentParentFolder,'\'));
                for entryDex = 1:length(listWithin)
                    if listWithin(entryDex).isdir && ~strcmp(listWithin(entryDex).name,'.') ...
                            && ~strcmp(listWithin(entryDex).name,'..')
                        numFolders = numFolders + 1;
                        foldersWithin{numFolders} = listWithin(entryDex).name;
                    end
                end
                currentSelectionDex = find(strcmp(currentFolder,foldersWithin),1);
                % completion for filenames
                if strcmp(evt.Key,'uparrow')
                    % select next folder in reverse alphabetical order
                    if isempty(currentSelectionDex) % we haven't selected a valid folder
                        if ~isempty(foldersWithin)
                            set(src,'String',fullfile(currentParentFolder,foldersWithin{end}));
                        end
                    else
                        folderToSelect = currentSelectionDex - 1;
                        if folderToSelect == 0, folderToSelect = length(foldersWithin); end
                        set(src,'String',fullfile(currentParentFolder,foldersWithin{folderToSelect}));
                    end
                elseif strcmp(evt.Key,'downarrow')
                    % select next folder in alphabetical order
                    if isempty(currentSelectionDex) % we haven't selected a valid folder
                        if ~isempty(foldersWithin)
                            set(src,'String',fullfile(currentParentFolder,foldersWithin{1}));
                        end
                    else
                        folderToSelect = currentSelectionDex + 1;
                        if folderToSelect > length(foldersWithin), folderToSelect = 1; end
                        set(src,'String',fullfile(currentParentFolder,foldersWithin{folderToSelect}));
                    end
                elseif strcmp(evt.Key,'leftarrow')
                    % go to parent folder
                    if ~strcmp(currentParentFolder,'') && length(slashArray) > 1
                        set(src,'String',fullfile(currentParentFolder));
                    end
                elseif strcmp(evt.Key,'rightarrow')
                    % autocomplete folder name
                    if ~isempty(currentSelectionDex)
                        % if we have already selected a valid folder
                        set(src,'String',fullfile(currentParentFolder,currentFolder,'\'));
                    elseif strcmp(currentPath(end),'/') || strcmp(currentPath(end),'\')
                        if ~isempty(foldersWithin)
                            set(src,'String',fullfile(currentParentFolder,foldersWithin{1}));
                        end
                    elseif ~isempty(find(strncmp(currentFolder,foldersWithin,length(currentFolder)),1));
                        currentSelectionDex = find(strncmp(currentFolder,foldersWithin,length(currentFolder)),1);
                        set(src,'String',fullfile(currentParentFolder,foldersWithin{currentSelectionDex}));
                    else
                        if ~isempty(foldersWithin)
                            set(src,'String',fullfile(currentParentFolder,foldersWithin{1}));
                        end
                    end
                elseif ~strcmp(evt.Character,' ') || strcmp(evt.Key,'space')
                    % i.e. a normal character or the spacebar
                end
            end
        end
        
        function setSpoolPath(obj,src,~)
            % make sure this hasn't been called immediately after an
            % acquire
            
            if obj.State ~= 0
                set(src,'String',obj.SpoolPath);% reset the input
                return % cancel any changes
            end
            setPath = get(src,'String'); % path input
            if exist(setPath,'dir') == 7 % if it is a directory
                obj.SpoolPath = setPath;
            else
                set(src,'String',obj.SpoolPath);
            end
        end
        
    end
end
