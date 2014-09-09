classdef SimpleMscopeGUI < handle
    %SimpleMscopeGUI allows graphical control of Andor Camera
    % Handles are stored as properties and callbacks are methods
    
    properties (SetAccess = private)
        
        % some defaults
        DFT_TRIGGER_FAST = 0; % set this to 1 for fast triggering
        TIMER_IDLE_PERIOD = 0.2; % (\s between updating displayed info)
        TIMER_ACQ_PERIOD = 0.033; % update at 30 Hz in this mode (maximum)
        
        % camera controller object
        CamCon;
        
        % timer object for real-time updating
        TimerIdle; % runs when system is idle
        TimerAcq; % runs when camera is acquiring/videoing
        
        
        % handles to displayed objects - i.e. without callbacks
        MainFigH;
        
        CamStatH;
        CamTempH;
        FrameRateH;
        MessageH;
        
        MinFrameH; % display for the minimum frame time
        ExpPctH; % display for the percent of the frame time that is exposing - CW only
        
        
        % handles to user interface buttons and controls
        SpoolPathH;
        SpoolNameH;
        SpoolFramesH;
        
        AlexOnH;
        CwOnH;
        
        SetFrameH;
        
        StartVideoH;
        StartCaptH;
        StopCaptH;
        
        % information about the current setup (defaults are defaults)
        SpoolPath = pwd;
        SpoolName = 'DefaultFileName';
        SpoolFrames = 100;
        
        AlexMode = 1; % this is set to be the default on construction
        
        FrameTime = 100; % (\ms) frame time actually set
        
        % Flag for state
        State = 0; % 0 is idle, 1 is video mode, 2 is spool and video
        
        % define some useful constants for customising the look
        FigPos = [0.0, 0.4, 0.5, 0.6]; % outer position of the main figure
        % [left,bot,widt,heig]
        
        FONT_INPUT = 'Arial';
        FONT_INFO  = 'Arial';
        
        COLOR_BGD  = [0.2 0.2 0.2];
        
        COLOR_INPUT_BGD = [0.6 1.0 0.6];
        COLOR_INPUT_TEXT = [0.0 0.0 0.0];
        
        COLOR_INFO_BGD = [0.2 0.2 0.2];
        COLOR_INFO_TEXT = [1.0 1.0 1.0];
        
        COLOR_ALEX_BGD = [0.9 0.6 0.6];
        COLOR_ALEX_TEXT = [0.0 0.0 0.0];
        
        COLOR_CW_BGD = [1.0 0.6 0.2];
        COLOR_CW_TEXT = [0.0 0.0 0.0];
        
        COLOR_STAT_OK = [0.4 0.4 0.8];
        COLOR_STAT_WARN = [1.0 0.5 0.0];
        COLOR_STAT_ERR = [0.8 0.0 0.0];
        COLOR_STAT_TEXT = [1.0 1.0 1.0];
        
        COLOR_VIDEO_BGD = [0.2 0.2 1.0];
        COLOR_VIDEO_TEXT = [1.0 1.0 1.0];
        
        COLOR_CAPT_BGD = [0.2 1.0 0.2];
        COLOR_CAPT_TEXT = [0.0 0.0 0.0];
        
        COLOR_STOP_BGD = [0.8 0.0 0.0];
        COLOR_STOP_TEXT = [0.0 0.0 0.0];
        
        COLOR_RED   = [0.8 0.0 0.0];
        COLOR_GREEN = [0.0 0.8 0.0];
        COLOR_BLUE  = [0.0 0.0 0.8];
        
    end
    
    methods (Access = public)
        % constructor
        function obj = SimpleMscopeGUI
            
            % builds our camera controller and applies default camera settings
            obj.CamCon = CameraController;
            try % in a try-catch so we always disconnect from camera
                % build the main figure - visibility off for now
                %% MAIN FIGURE
                obj.MainFigH = figure('CloseRequestFcn',@obj.cleanUp,...
                    'Color',obj.COLOR_BGD,...
                    'DockControls','off',...
                    'Name',class(obj),...
                    'Units','Normalized',...
                    'OuterPosition',obj.FigPos,...
                    'Pointer','arrow',...
                    'Renderer','OpenGL',...
                    'Toolbar','none',...
                    'Visible','off');
                %% STATUS INDICATORS
                % build the camera status indicator
                obj.CamStatH = uicontrol('Parent',obj.MainFigH,...
                    'Style','text',...
                    'BackgroundColor',obj.COLOR_STAT_ERR,...
                    'Units','Normalized',...
                    'Position',[0.0, 0.0, 0.1, 0.025],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INFO,...
                    'FontSize',0.95,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_STAT_TEXT,...
                    'String','',... % default blank string, but gets updated on next line
                    'Visible','on');
                
                obj.updateStat; % and get the latest information
                
                % camera temperature indicator
                obj.CamTempH = uicontrol('Parent',obj.MainFigH,...
                    'Style','text',...
                    'BackgroundColor',obj.COLOR_STAT_ERR,...
                    'Units','Normalized',...
                    'Position',[0.1, 0.0, 0.1, 0.025],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INFO,...
                    'FontSize',0.95,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_STAT_TEXT,...
                    'String','',... % default blank string, but gets updated on next line
                    'Visible','on');
                
                obj.updateTemp; % and get the latest information
                
                obj.FrameRateH = uicontrol('Parent',obj.MainFigH,...
                    'Style','text',...
                    'BackgroundColor',obj.COLOR_STAT_OK,...
                    'Units','Normalized',...
                    'Position',[0.2, 0.0, 0.1, 0.025],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INFO,...
                    'FontSize',0.95,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_STAT_TEXT,...
                    'String','-',...
                    'Visible','on');
                
                obj.MessageH = uicontrol('Parent',obj.MainFigH,...
                    'Style','text',...
                    'BackgroundColor',obj.COLOR_STAT_OK,...
                    'Units','Normalized',...
                    'Position',[0.3, 0.0, 0.50, 0.025],...
                    'HorizontalAlignment','center',... % for its text
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INFO,...
                    'FontSize',0.95,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_STAT_TEXT,...
                    'String','-',...
                    'Visible','on');
                
                %% SPOOLING CONTROLS
                % spool path input
                obj.SpoolPathH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.setSpoolPath,...
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
                    'Visible','on');
                
                % spool file name base
                obj.SpoolNameH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.setSpoolName,...
                    'Style','edit',...
                    'BackgroundColor',obj.COLOR_INPUT_BGD,...
                    'Units','Normalized',...
                    'Position',[0.50, 0.95, 0.30, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.5,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_INPUT_TEXT,...
                    'String',obj.SpoolName,...
                    'Visible','on');
                
                % number of frames to spool
                obj.SpoolFramesH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.setSpoolFrames,...
                    'Style','edit',...
                    'BackgroundColor',obj.COLOR_INPUT_BGD,...
                    'Units','Normalized',...
                    'Position',[0.80, 0.95, 0.20, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.5,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_INPUT_TEXT,...
                    'String',obj.SpoolFrames,...
                    'Visible','on');
                
                %% MODE SELECTION
                % toggling between alex and cw modes
                obj.AlexOnH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.setAlexMode,...
                    'Style','togglebutton',...
                    'Max',1,...
                    'Min',0,...
                    'Value',obj.AlexMode,...
                    'BackgroundColor',obj.COLOR_ALEX_BGD,...
                    'Units','Normalized',...
                    'Position',[0.80, 0.90, 0.10, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.5,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_ALEX_TEXT,...
                    'String','ALEX',...
                    'Visible','on');
                
                obj.CwOnH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.setCwMode,...
                    'Style','togglebutton',...
                    'Max',1,...
                    'Min',0,...
                    'Value',~obj.AlexMode,...
                    'BackgroundColor',obj.COLOR_CW_BGD,...
                    'Units','Normalized',...
                    'Position',[0.90, 0.90, 0.10, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.5,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_CW_TEXT,...
                    'String','CW',...
                    'Visible','on');
                
                % apply the default of alex or not
                if obj.AlexMode, obj.setAlexMode(obj.AlexOnH); end
                if ~obj.AlexMode, obj.setCwMode(obj.CwOnH); end
                
                
                %% FRAME TIMINGS
                
                timingsFontSize = 0.35;
                
                % display the minimum frame time possible
                obj.MinFrameH = uicontrol('Parent',obj.MainFigH,...
                    'Style','text',...
                    'BackgroundColor',obj.COLOR_INFO_BGD,...
                    'Units','Normalized',...
                    'Position',[0.8666, 0.15, 0.0666, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INFO,...
                    'FontSize',0.4,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_INFO_TEXT,...
                    'String','',...
                    'Visible','on');
                
                % displaying the amount of exposure
                obj.ExpPctH = uicontrol('Parent',obj.MainFigH,...
                    'Style','text',...
                    'BackgroundColor',obj.COLOR_INFO_BGD,...
                    'Units','Normalized',...
                    'Position',[0.9333, 0.15, 0.0666, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INFO,...
                    'FontSize',0.4,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_INFO_TEXT,...
                    'String','',...
                    'Visible','on');
                
                % Setting the time - note reduced font size
                obj.SetFrameH = uicontrol('Parent',obj.MainFigH,...
                    'Style','edit',...,
                    'Callback',@obj.setFrameTime,...
                    'BackgroundColor',obj.COLOR_INPUT_BGD,...
                    'Units','Normalized',...
                    'Position',[0.8000, 0.15, 0.0666, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',timingsFontSize,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_INPUT_TEXT,...
                    'String',sprintf('%.1f ms',obj.FrameTime),...
                    'Visible','on');
                
                % and update them so we are displaying the truth
                obj.updateTimes;
                
                %% ACQUIRING
                % starting video
                obj.StartVideoH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.startVideo,...
                    'Style','togglebutton',...
                    'Max',1,...
                    'Min',0,...
                    'Value',0,...
                    'BackgroundColor',obj.COLOR_VIDEO_BGD,...
                    'Units','Normalized',...
                    'Position',[0.80, 0.10, 0.20, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName','obj.FONT_INPUT',...
                    'FontSize',0.5,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_VIDEO_TEXT,...
                    'String','VIDEO',...
                    'Visible','on');
                % starting spooling
                obj.StartCaptH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.startCapt,...
                    'Style','togglebutton',...
                    'Max',1,...
                    'Min',0,...
                    'Value',0,...
                    'BackgroundColor',obj.COLOR_CAPT_BGD,...
                    'Units','Normalized',...
                    'Position',[0.80, 0.05, 0.20, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName','obj.FONT_INPUT',...
                    'FontSize',0.5,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_CAPT_TEXT,...
                    'String','ACQUIRE',...
                    'Visible','on');
                % stoping acquiring
                obj.StopCaptH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.stopCapt,...
                    'Style','togglebutton',...
                    'Max',1,...
                    'Min',0,...
                    'Value',1,...
                    'enable','off',...
                    'BackgroundColor',obj.COLOR_STOP_BGD,...
                    'Units','Normalized',...
                    'Position',[0.80, 0.00, 0.20, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.5,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_STOP_TEXT,...
                    'String','STOP',...
                    'Visible','on');
                
                %% TIMERS FOR UPDATING
                % Status updates when IDLE
                obj.TimerIdle = timer('Period',obj.TIMER_IDLE_PERIOD,...
                    'BusyMode','drop',... % only one timer queued
                    'ExecutionMode','fixedRate',...
                    'TimerFcn',@(~,~)obj.updateIdle);
                
                obj.TimerAcq = timer('Period',obj.TIMER_ACQ_PERIOD,...
                    'BusyMode','drop',... % only one timer queued
                    'ExecutionMode','fixedRate',...
                    'TimerFcn',@(~,~)obj.updateAcq,...
                    'StopFcn',@(~,~)set([obj.FrameRateH; obj.MessageH],'String','-','BackgroundColor',obj.COLOR_STAT_OK));
                
                start(obj.TimerIdle); % only start the idle timer because we always start idle
                
            catch exception
                obj.CamCon.disconnect;
                set(obj.MainFigH,'closeRequestFcn','');
                exception.throw;
            end
            
            % make what we have visible
            set(obj.MainFigH,'Visible','on');
            
            
            
        end
        
        
    end
    
    methods (Access = public) % should be private, but for debugging make them public
        %% SWITCHING DISPLAY MODES - ACQ and IDLE
        function setGraphicsAcquiring(obj,stateFlag)
            % makes the things that we can't edit when acquisition is in
            % progress uneditable
            handlesToInactivate = [obj.SpoolPathH;
                obj.SpoolNameH;
                obj.SpoolFramesH;
                obj.AlexOnH;
                obj.CwOnH;
                obj.SetFrameH];
            if stateFlag
                % we are acquiring
                set(handlesToInactivate,'enable','off'); 
            else
                % we have finished acquiring
                set(handlesToInactivate,'enable','on');
            end
        end
        
        %% UPDATERS (for real-time and to call after every changed button)
        
        
        %% updater for idle timer
        function updateIdle(obj)
            obj.updateStat; % Always update the status indicator
            statusNow = obj.CamCon.getStringStatus;
            try
                if strcmp(statusNow,'IDLE')
                    obj.updateTemp;
                    obj.updateTimes;
                elseif strcmp(statusNow,'ACQUIRE')
                    % switch modes
                    stop(obj.TimerIdle);
                    start(obj.TimerAcq);
                end
            catch exception
                fprintf('\nIdle Timer Error: \n %s\n',exception.getReport);
            end
        end % updateIdle
        
        %% updater for acq timer
        function updateAcq(obj)
            obj.updateStat; % always update the status
            try
                statusNow = obj.CamCon.getStringStatus;
                if strcmp(statusNow,'ACQUIRE')
                    % update the frame rate and temperature indicators
                    obj.updateTemp;
                    obj.updateFrameRate;
                elseif strcmp(statusNow,'IDLE')
                    % make sure the start acquisition buttons are both
                    % available
                    obj.setGraphicsAcquiring(0);
                    
                    set(obj.StartVideoH,'enable','on','value',0);
                    set(obj.StartCaptH,'enable','on','value',0);
                    set(obj.StopCaptH,'enable','off','value',1);
                    
                    % set the state, which makes sure the above can run
                    obj.State = 0; % i.e. idle
                    
                    % stop this timer, and start the idle state timer
                    stop(obj.TimerAcq);
                    start(obj.TimerIdle);
                end
            catch exception
                fprintf('\nAcq Timer Error: \n %s\n',exception.getReport);
            end
        end
        
        %% other updaters
        
        function updateFrameRate(obj)
            % make sure the frame rate indicator says the correct frame rate
            currentRate = 1/get(obj.TimerAcq,'InstantPeriod');
            set(obj.FrameRateH,'String',sprintf('%.1f Hz',currentRate),'BackgroundColor',obj.COLOR_STAT_WARN);
        end
        
        function updateStat(obj)
            status = obj.CamCon.getStringStatus;
            switch status
                case 'IDLE'
                    statCol = obj.COLOR_STAT_OK;
                case 'ACQUIRE'
                    statCol = obj.COLOR_STAT_WARN;
                case 'ERR'
                    statCol = obj.COLOR_STAT_ERR;
            end
            set(obj.CamStatH,'String',status,'BackgroundColor',statCol);
        end
        
        function updateTemp(obj)
            [temp, tempStat] = obj.CamCon.getTemp; % get the info from the camera
            switch tempStat
                case 'STABLE'
                    tempCol = obj.COLOR_STAT_OK;
                    tempStrShow = sprintf('%i %cC',temp,char(176));
                case 'UNSTABLE'
                    tempCol = obj.COLOR_STAT_ERR;
                    tempStrShow = sprintf('%i %cC',temp,char(176));
                case 'ACQUIRE'
                    tempCol = obj.COLOR_STAT_WARN;
                    tempStrShow = get(obj.CamTempH,'String');
            end
            set(obj.CamTempH,'String',tempStrShow,'BackgroundColor',tempCol);
        end
        
        function updateTimes(obj)
            % set the minimum allowed frame time - multiply by 1000 to
            % match units s -> ms
            % PROBABLY CAN'T CALL THIS DURING ACQUIRE (checked and does
            % nothing during acquire)
            if strcmp(obj.CamCon.getStringStatus,'IDLE')
                % BOTH MODES SET THE MINIMUM IN THE SAME WAY
                minRepeatTime = obj.CamCon.getMinRepeatTime*1000; % in ms
                set(obj.MinFrameH,'String',sprintf('Min:\n%.1f ms',minRepeatTime));
                if obj.AlexMode % if we are in alex mode the camera doesn't have a say
                    %% ALEX MODE
                    % so set the displayed frame time to the the time that has been set
                    % respecting the minimum of the camera
                    obj.FrameTime = max(obj.FrameTime,minRepeatTime);
                    set(obj.ExpPctH,'String','-'); % seen as in alex mode this is meaningless (% exposure)
                    
                    % --------------- TODO ---------------------------------- %
                    % Make sure that in ALEX mode, the NI Card knows what frame
                    % time we have set and agrees to it
                    % ------------------------------------------------------- %
                    
                else
                    %% CW MODE
                    % get the actual set times
                    
                    [cameraSetFrameTime, cameraSetExpTime] = obj.CamCon.getCwTimes;
                    % convert s -> ms
                    cameraSetFrameTime = cameraSetFrameTime*1000;
                    cameraSetExpTime = cameraSetExpTime*1000;
                    % make sure our data is up to date in this object
                    obj.FrameTime = cameraSetFrameTime;
                    % set the percent exposure
                    set(obj.ExpPctH,'String',sprintf('Exp/Frm:\n%.0f %%',cameraSetExpTime/cameraSetFrameTime * 100));
                end
                % in either mode, the FrameTime property is valid and actually
                % set
                set(obj.SetFrameH,'String',sprintf('%.1f ms',obj.FrameTime));
            else
                % Do nothing
            end
        end
        %% SPOOLING CALLBACKS
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
        
        function setSpoolName(obj,src,~)
            % make sure this hasn't been called immediately after an
            % acquire
            if obj.State ~= 0
                set(src,'String',obj.SpoolName);% reset the input
                return % cancel any changes
            end 
            setName = get(src,'String'); % name input
            if isempty(regexp(setName, '[/\*:?"<>|]', 'once')) % if it isn't valid filename
                obj.SpoolName = setName;
            else % lets set the spool name as requested
                set(src,'String',obj.SpoolName);
            end
        end
        
        function setSpoolFrames(obj,src,~)
            % make sure this hasn't been called immediately after an
            % acquire
            if obj.State ~= 0
                set(src,'String',obj.SpoolFrames); % reset the input
                return % cancel any changes
            end 
            setFrames = str2double(get(src,'String'));
            if ~isnan(setFrames)
                setFrames = int32(floor(max(1,setFrames)));
                obj.SpoolFrames = setFrames;
                set(src,'String',obj.SpoolFrames);
            else
                set(src,'String',obj.SpoolFrames);
            end
        end
        
        %% ALEX OR CW MODE CALLBACKS
        function setAlexMode(obj,src,~)
            % make sure this hasn't been called immediately after an
            % acquire
            if obj.State ~= 0
                set(src,'Value',0); % reset the input
                return % cancel any changes
            end            
            
            set(src,'enable','inactive');
            obj.CamCon.setAcqMode(1 + obj.DFT_TRIGGER_FAST); % set alex mode on the camera (external triggering)
            obj.AlexMode = 1;
            obj.updateTimes; % since the exposure percentage is now meaningless
            set(obj.CwOnH,'Value',0,'enable','on');
        end
        
        function setCwMode(obj,src,~)
            % make sure this hasn't been called immediately after an
            % acquire
            if obj.State ~= 0
                set(src,'Value',0); % reset the input
                return % cancel any changes
            end   
            
            set(src,'enable','inactive');
            obj.CamCon.setAcqMode(0); % set cw mode on the camera (internal triggering)
            % make sure the camera is set to the same frame time as before
            obj.FrameTime = max(obj.FrameTime,obj.CamCon.getMinRepeatTime*1000);
            obj.CamCon.setCwRepeatTime(obj.FrameTime/1000);
            obj.AlexMode = 0;
            obj.updateTimes; % since we care about the exposure percentage
            set(obj.AlexOnH,'Value',0,'enable','on');
        end
        
        % callback from buttons to change camera settings
        
        %% CLEANUP
        % clean up function for closing the figure (that gracefully closes
        % the camera)
        function cleanUp(obj,src,~)
            
            % stop the two timers
            stop(obj.TimerIdle);
            stop(obj.TimerAcq);
            
            obj.CamCon.disconnect; % gracefully disconnect from the camera
            delete(src); % and delete the figure
        end
        
        %% FRAME TIME SETTING
        function setFrameTime(obj,src,~)
            % incase we have already started acquisition
            if obj.State ~= 0
                set(src,'String',sprintf('%.1f ms',obj.FrameTime)); % reset the input
                return % cancel any changes
            end
            if strcmp(obj.CamCon.getStringStatus,'IDLE')
                % IF THE CAMERA IS IDLE THEN WE SET THE TIME
                % lets check if the user left the 'ms' at the end of the input
                inputTimeString = get(src,'String');
                if strncmp(fliplr(inputTimeString),'sm',2)
                    inputTimeString = inputTimeString(1:end-2);
                end
                inputTime = str2double(inputTimeString);
                if isnan(inputTime)
                    % reset to the last value which was valid
                    set(src,'String',sprintf('%.1f ms',obj.FrameTime));
                else
                    % make sure the time is valid here
                    obj.FrameTime = max(inputTime,obj.CamCon.getMinRepeatTime*1000);
                end
                % call the update timings function
                if obj.AlexMode == 0  % i.e. CW only
                    obj.CamCon.setCwRepeatTime(obj.FrameTime/1000); % convert to MILLISECONDS -> SECONDS
                end
                obj.updateTimes;
            else % IF THE CAMERA IS BUSY  - IGNORE THE COMMAND
                % reset to the last value (which was valid)
                set(src,'String',sprintf('%.1f ms',obj.FrameTime));
            end
        end % set frame time
        
        %% ACQUISITION START STOP CALLBACKS
        % start without spooling
        function startVideo(obj,src,~)
            % need to check the current state of the system, and only run
            % the function if it makes any sense
            if obj.State ~= 0 % i.e. not idle
                return
            end
            
            obj.State = 1; % set the state to video
            
            % make sure the video button can only be pressed
            % once          
            set(obj.StopCaptH,'enable','on','Value',0);
            if get(obj.StartCaptH,'Value') == 1, return; end % don't do anything if startcapt has been hit too
            set(obj.StartCaptH,'enable','inactive');
            set(src,'enable','off');
            
            % make the controls that can't be used during acquisition
            % greyed out
            obj.setGraphicsAcquiring(1);
            
            try
                obj.CamCon.setSpool; % turn spooling off
                set(obj.MessageH,'String','-','BackgroundColor',obj.COLOR_STAT_OK);
            catch
                set(obj.MessageH,'String','SPOOL CANCEL FAIL','BackgroundColor',obj.COLOR_STAT_ERR);
            end
            
            % start the video
            if strcmp(obj.CamCon.getStringStatus,'IDLE')
                try
                obj.CamCon.startAcquiring;
                catch
                    set(obj.MessageH,'String','CAMERA ERROR','BackgroundColor',obj.COLOR_STAT_ERR);
                end
            else
                set(obj.MessageH,'String','CAMERA BUSY','BackgroundColor',obj.COLOR_STAT_ERR);
            end
            
            % finally enable the stop and spool buttons
            
            set(obj.StartCaptH,'enable','on','Value',0);
        end
        
        % Start with spooling
        function startCapt(obj,src,~)
            % check the state
            if obj.State == 2 % not already spooling
                return
            end
            
            obj.State = 2; % set us spooling
                      
            % stop the update timer
            try
                stop(obj.AcqTimer);
            catch
            end
            
            
            % enable the stop button
            set(obj.StopCaptH,'enable','on','Value',0);
            
            % make sure the capture and video buttons can only be pressed
            % once
            set(obj.StartVideoH,'enable','off');
            set(src,'enable','off','Value',1); % and make sure it is depressed
            
            % if it is currently acquiring, then abort the acquisition
            if strcmp(obj.CamCon.getStringStatus,'ACQUIRE')
                obj.CamCon.stopIfAcquiring;
            end
            % make the controls that can't be used during acquisition
            % unavailable
            obj.setGraphicsAcquiring(1);
            set(src,'enable','off','value',1);
            set(obj.StartVideoH,'enable','off','value',0);
            % turn spooling on
            try
                boxSize = 50;
                fullPathName = obj.CamCon.setSpool(obj.SpoolPath,obj.SpoolName,obj.SpoolFrames);
                if length(fullPathName) > boxSize
                    fullPathName = ['...' fullPathName(max(1,end-boxSize):end)];
                end
                set(obj.MessageH,'String',sprintf('%s.fits',fullPathName),...
                    'BackgroundColor',obj.COLOR_STAT_WARN);
            catch
                set(obj.MessageH,'String','SPOOL ERROR','BackgroundColor',obj.COLOR_STAT_ERR)
            end
            
            % start the video
            if strcmp(obj.CamCon.getStringStatus,'IDLE')
                obj.CamCon.startAcquiring
            else
                set(obj.MessageH,'String','CAMERA BUSY',...
                    'BackgroundColor',obj.COLOR_STAT_ERR);
            end
            
            % start the update timer
            try
                start(obj.AcqTimer);
            catch
            end
            
        end % startCapt
        
        % Stop acquisition of any sort
        function stopCapt(obj,~,~)
            obj.State = 0; % idle            
            
            % make sure this button can't be pushed again
            set(obj.StopCaptH,'enable','off');
            set(obj.StartVideoH,'enable','inactive');
            set(obj.StartCaptH,'enable','inactive');
            
            % aborting capture or video
            obj.CamCon.stopIfAcquiring;
            
            % finally enable the start buttons
            set(obj.StartVideoH,'enable','on','Value',0);
            set(obj.StartCaptH,'enable','on','Value',0);
        end
    end
    
end
