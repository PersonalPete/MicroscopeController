classdef SimpleMscopeGUI < handle
    %SimpleMscopeGUI allows graphical control of Andor Camera
    % Handles are stored as properties and callbacks are methods
    
    properties (SetAccess = private)
        
        %
        RedPort = 'TEST';
        
        % some defaults
        DFT_TRIGGER_FAST = 0; % set this to 1 for fast triggering
        TIMER_IDLE_PERIOD = 0.2; % (\s between updating displayed info)
        TIMER_ACQ_PERIOD = 0.033; % update at 30 Hz in this mode (maximum)
        
        % camera controller object
        CamCon;
        
        % LabVIEW card / general laser controller - does the laser switching (and controls
        % the laser power)
        LaserCon;
        
        % controller for PI stages
        StageCon;
        NumStages = 4; % so that we check we have the right number connected
        
        % timer object for real-time updating
        TimerIdle; % runs when system is idle
        TimerAcq; % runs when camera is acquiring/videoing
        
        
        % handles to displayed objects - i.e. without callbacks
        MainFigH;
        
        CamStatH;
        CamTempH;
        FrAcqH; % how many frames acquired
        FrameRateH;
        MessageH;
        
        MinFrameH; % display for the minimum frame time
        ExpPctH; % display for the percent of the frame time that is exposing - CW only
        
        SinglePlotAxisH; % the big simgle plot of the camera image
        SingleImageH;
        
        % handles to user interface buttons and controls
        SpoolPathH;
        SpoolNameH;
        SpoolFramesH;
        
        AlexOnH;
        CwOnH;
        AlexSelectionH;
        
        GreenOnH;
        RedOnH;
        NIROnH;
        
        GreenPowerH;
        RedPowerH;
        NIRPowerH;
        
        SetFrameH;  % for the number of frames
        
        % stage positions
        LeftRightDisplayH;
        UpDownDisplayH;
        FocusDisplayH;
        
        StartVideoH;
        StartCaptH;
        StopCaptH;
        
        % Brightness controls
        MinH;
        RangeH;
        AutoH;
        
        % information about the current setup (defaults are defaults)
        SpoolPath = pwd;
        SpoolName = 'DefaultFileName';
        SpoolFrames = 100;
        
        AlexMode = 0; % this is set to be the default on construction
        AlexSelection = 1; % this is which alex type (R-G or R-G-N etc...) is selected
        % 1:Green-Red 2:Green-Red-NIR 3:Green-NIR 4:Red-NIR 5:NIR-Red-Green
        
        FrameTime = 100; % (\ms) frame time actually set
        
        % Flag for state
        State = 0; % 0 is idle, 1 is video mode, 2 is spool and video
        AllowedToStop = 1; % set to 0 whilst acquisition is being started, so timer doesn't stop acquisition prematurely
        % Display setup for video
        LatestImageData; % the most recent frame (so we can rescale a frozen frame)
        
        ImageLimits = [90 120]; % current scaling of displayed image
        numXPix = 512;
        numYPix = 512;
        
        % whether a particular laser is on at the moment (not so useful
        % during ALEX for the lasers doing the alternating)
        GreenState = 0;
        RedState = 0;
        NIRState = 0;
        
        GreenPower = 0.1; % Fraction of laser's full power it is currently set to
        RedPower = 0.1;
        
        GreenBusy = 0; % whether the particular laser is involved in the ALEX we are doing
        RedBusy = 0;
        NIRBusy = 0;
        
        % CONSTANTS
        AUTO_FACTOR = 2; % auto scales between the minimum and AUTO_FACTOR*(mean(data - min)) + min
        
        MAX_DATA = 2^16 - 1; % for the 16-bit data we are taking
        
        % define some useful constants for customising the look
        FigPos = [0.0, 0.4, 0.5, 0.6]; % outer position of the main figure
        % [left,bot,widt,heig]
        
        FONT_INPUT = 'Arial';
        FONT_INFO  = 'Arial';
        
        COLOR_BGD  = [0.2 0.2 0.2];
        
        COLOR_INPUT_BGD = [0.62 0.71 0.80]; % [0.6 1.0 0.6];
        COLOR_INPUT_TEXT = [0.2 0.2 0.2]; % [0 0 0];
        
        COLOR_AUTO_BGD = [0.24 0.35 0.67];%[0.8 0.0 0.0];
        COLOR_AUTO_TEXT = [1.0 1.0 1.0];
        
        COLOR_INFO_BGD = [0.2 0.2 0.2];
        COLOR_INFO_TEXT = [1.0 1.0 1.0];
        
        COLOR_ALEX_BGD = [0.24 0.35 0.67];%[0.9 0.6 0.6];
        COLOR_ALEX_TEXT = [1.0 1 1]; % [0.0 0.0 0.0];
        
        COLOR_CW_BGD = [0.24 0.35 0.67];%[1.0 0.6 0.2];
        COLOR_CW_TEXT = [1.0 1 1]; % [0.0 0.0 0.0];
        
        COLOR_532_BGD = [0.24 0.35 0.67];%[0.0 0.8 0.0];
        COLOR_532_TEXT = [1.0 1 1]; % [0.0 0.0 0.0];
        
        COLOR_640_BGD = [0.24 0.35 0.67];%[0.8 0.0 0.0];
        COLOR_640_TEXT = [1.0 1 1]; % [0.0 0.0 0.0];
        
        COLOR_730_BGD = [0.24 0.35 0.67];%[0.8 0.8 0.0];
        COLOR_730_TEXT = [1.0 1 1]; % [0.0 0.0 0.0];
        
        COLOR_STAT_OK = [0.39 0.58 0.93];%[0.4 0.4 0.8];
        COLOR_STAT_WARN = [0.24 0.35 0.67];%[1.0 0.5 0.0];
        COLOR_STAT_ERR = [0.8 0.0 0.0];
        COLOR_STAT_TEXT = [1.0 1.0 1.0];
        
        COLOR_VIDEO_BGD = [0.62 0.71 0.80]%;[0.2 0.2 1.0];
        COLOR_VIDEO_TEXT = [0.2 0.2 0.2];%[1 1 1];
        
        COLOR_CAPT_BGD = [0.24 0.35 0.67];%[0.2 1.0 0.2];
        COLOR_CAPT_TEXT =  [1.0 1.0 1.0];%[0.0 0.0 0.0];
        
        COLOR_STOP_BGD = [0.24 0.35 0.67];%[0.8 0.0 0.0];
        COLOR_STOP_TEXT =  [1.0 1.0 1.0];%[0.0 0.0 0.0];
        
        COLOR_RED   = [0.8 0.0 0.0];
        COLOR_GREEN = [0.0 0.8 0.0];
        COLOR_BLUE  = [0.0 0.0 0.8];
        
    end
    
    methods (Access = public)
        % constructor
        function obj = SimpleMscopeGUI
            
            % builds our camera controller and applies default camera settings
            obj.CamCon = CameraController;
            
            % builds the laser/card controller - TODO: Should set up the
            % Red laser
            fprintf('\nConnecting to NI PCIe-6351...\n');
            obj.LaserCon = CardController(obj.RedPort);
            
            fprintf('\nConnecting to stages\n');
            obj.StageCon = StageController(obj.NumStages);
            
            try % in a try-catch so we always disconnect from camera
                % build the main figure - visibility off for now
                %% MAIN FIGURE
                obj.MainFigH = figure('CloseRequestFcn',@obj.cleanUp,...
                    'Color',obj.COLOR_BGD,...
                    'ColorMap',gray(obj.MAX_DATA),...
                    'DockControls','off',...
                    'Name',class(obj),...
                    'Units','Normalized',...
                    'OuterPosition',obj.FigPos,...
                    'Pointer','arrow',...
                    'Renderer','OpenGL',...
                    'Toolbar','none',...
                    'MenuBar','none',...
                    'Visible','off');
                %% STATUS INDICATORS
                % build the camera status indicator
                obj.CamStatH = uicontrol('Parent',obj.MainFigH,...
                    'Style','text',...
                    'BackgroundColor',obj.COLOR_STAT_ERR,...
                    'Units','Normalized',...
                    'Position',[0.0, 0.0, 0.1, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INFO,...
                    'FontSize',0.475,...
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
                    'Position',[0.1, 0.0, 0.1, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INFO,...
                    'FontSize',0.475,...
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
                
                obj.FrAcqH = uicontrol('Parent',obj.MainFigH,...
                    'Style','text',...
                    'BackgroundColor',obj.COLOR_STAT_OK,...
                    'Units','Normalized',...
                    'Position',[0.2, 0.025, 0.1, 0.025],...
                    'HorizontalAlignment','center',... % for its text
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
                
                obj.AlexSelectionH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.selectAlex,...
                    'Style','popupmenu',...
                    'String',{'Green-Red' 'Green-Red-NIR' 'Green-NIR' 'Red-NIR' 'NIR-Red-Green'},...
                    'Min',1,...
                    'Max',1,...
                    'Value',obj.AlexSelection,...
                    'BackgroundColor',obj.COLOR_ALEX_BGD,...
                    'Units','Normalized',...
                    'Position',[0.80, 0.85, 0.20, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.5,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_CW_TEXT,...
                    'Visible','on');
                
                % apply the default of alex or not
                if ~obj.AlexMode
                    % Put into alex mode so we can set the type of alex
                    obj.setAlexMode(obj.AlexOnH);
                    obj.selectAlex(obj.AlexSelectionH);
                    % then go into CW mode if this is the default
                    obj.setCwMode(obj.CwOnH);
                else
                    obj.setAlexMode(obj.AlexOnH);
                    obj.selectAlex(obj.AlexSelectionH);
                end
                
                
                
                %% LASER POWERS AND ON/OFF
                obj.GreenOnH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.toggleGreen,...
                    'Style','togglebutton',...
                    'String','532',...
                    'Min',0,...
                    'Max',1,...
                    'Value',0,...
                    'BackgroundColor',obj.COLOR_532_BGD,...
                    'Units','Normalized',...
                    'Position',[0.80, 0.80, 0.0666, 0.065],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.5,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_532_TEXT,...
                    'Visible','on');
                
                obj.RedOnH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.toggleRed,...
                    'Style','togglebutton',...
                    'String','640',...
                    'Min',0,...
                    'Max',1,...
                    'Value',0,...
                    'BackgroundColor',obj.COLOR_640_BGD,...
                    'Units','Normalized',...
                    'Position',[0.8666, 0.80, 0.0666, 0.065],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.5,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_640_TEXT,...
                    'Visible','on');
                
                obj.NIROnH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.toggleNIR,...
                    'Style','togglebutton',...
                    'String','730',...
                    'Min',0,...
                    'Max',1,...
                    'Value',0,...
                    'BackgroundColor',obj.COLOR_730_BGD,...
                    'Units','Normalized',...
                    'Position',[0.9333, 0.80, 0.0666, 0.065],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.5,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_730_TEXT,...
                    'Visible','on');
                
                obj.GreenPowerH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.setGreenPower,...
                    'Style','edit',...
                    'BackgroundColor',obj.COLOR_INPUT_BGD,...
                    'Units','Normalized',...
                    'Position',[0.80, 0.75, 0.0666, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.4,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_INPUT_TEXT,...
                    'String',sprintf('%.1f %%',obj.GreenPower*100),...
                    'Visible','on');
                
                obj.RedPowerH = uicontrol('Parent',obj.MainFigH,...
                    'Callback',@obj.setRedPower,...
                    'Style','edit',...
                    'BackgroundColor',obj.COLOR_INPUT_BGD,...
                    'Units','Normalized',...
                    'Position',[0.8666, 0.75, 0.0666, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.4,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_INPUT_TEXT,...
                    'String',sprintf('%.1f %%',obj.RedPower*100),...
                    'Visible','on');
                
                obj.NIRPowerH = uicontrol('Parent',obj.MainFigH,...
                    'Style','edit',...
                    'BackgroundColor',obj.COLOR_INPUT_BGD,...
                    'Units','Normalized',...
                    'Position',[0.9333, 0.75, 0.0666, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.4,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_INPUT_TEXT,...
                    'String',sprintf('manual'),...
                    'Visible','on');
                
                %% STAGE CONTROLS
                
                % indicators
                obj.LeftRightDisplayH('Parent',obj.MainFigH,...
                    'Style','text',...
                    'BackgroundColor',obj.COLOR_INFO_BGD,...
                    'Units','Normalized',...
                    'Position',[0.80, 0.60, 0.0666, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INFO,...
                    'FontSize',0.4,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_INFO_TEXT,...
                    'String','',...
                    'Visible','on');
                
                obj.LeftRightDisplayH('Parent',obj.MainFigH,...
                    'Style','text',...
                    'BackgroundColor',obj.COLOR_INFO_BGD,...
                    'Units','Normalized',...
                    'Position',[0.80, 0.60, 0.0666, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INFO,...
                    'FontSize',0.4,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_INFO_TEXT,...
                    'String','',...
                    'Visible','on');

                obj.LeftRightDisplayH('Parent',obj.MainFigH,...
                    'Style','text',...
                    'BackgroundColor',obj.COLOR_INFO_BGD,...
                    'Units','Normalized',...
                    'Position',[0.80, 0.60, 0.0666, 0.05],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INFO,...
                    'FontSize',0.4,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_INFO_TEXT,...
                    'String','',...
                    'Visible','on');
                                
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
                
                %% IMAGE BRIGHTNESS CONTROLS
                % set the minimum displayed value
                obj.MinH = uicontrol('Parent',obj.MainFigH,...
                    'Style','slider',...
                    'Min',0,...
                    'Max',obj.MAX_DATA-2,...
                    'SliderStep',[0.01 0.1],... % minor and major steps
                    'BackgroundColor',obj.COLOR_INPUT_BGD,...
                    'Units','Normalized',...
                    'Position',[0.30 0.025 0.2 0.025],...
                    'callback',@obj.setMinImage,...
                    'TooltipString','Display minimum',...
                    'Visible','on');
                
                obj.RangeH = uicontrol('Parent',obj.MainFigH,...
                    'Style','slider',...
                    'Min',0,...
                    'Max',1,... % only zero and one because we are taking the range as the fraction of the remaining data values to not truncate
                    'SliderStep',[1e-3 0.1],... % minor and major steps
                    'BackgroundColor',obj.COLOR_INPUT_BGD,...
                    'ForegroundColor',[0 0 0],...
                    'Units','Normalized',...
                    'Position',[0.50 0.025 0.2 0.025],...
                    'callback',@obj.setRangeImage,...
                    'TooltipString','Display range',...
                    'Visible','on');
                
                obj.AutoH = uicontrol('Parent',obj.MainFigH,...
                    'Style','pushbutton',...
                    'SliderStep',[1e-4 1],... % minor and major steps
                    'BackgroundColor',obj.COLOR_AUTO_BGD,...
                    'Units','Normalized',...
                    'Position',[0.70 0.025 0.1 0.025],...
                    'FontUnits','Normalized',...
                    'FontName',obj.FONT_INPUT,...
                    'FontSize',0.8,...
                    'FontWeight','normal',...
                    'ForegroundColor',obj.COLOR_AUTO_TEXT,...
                    'String','AUTO',...
                    'Visible','on',...
                    'callback',@obj.autoscaleImage);
                
                
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
                
                %% DISPLAY FOR ACQUIRED IMAGE
                % axis to plot into
                obj.SinglePlotAxisH = axes('Parent',obj.MainFigH,...
                    'color','none',...
                    'visible','off',...
                    'DataAspectRatio',[1 1 1],...
                    'DrawMode','fast',...
                    'Position',[0.00 0.05 0.80, 0.90],...
                    'Units','Normalized',...
                    'XTick',[],...
                    'YTick',[],...
                    'Xlim',[0 obj.numXPix],...
                    'Ylim',[0 obj.numYPix],...
                    'CLim',obj.ImageLimits);
                
                obj.SingleImageH = image('Parent',obj.SinglePlotAxisH,...
                    'CDataMapping','scaled',...
                    'CData',0);
                % CData will be defined when we have some
                
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
                    'StopFcn',@(~,~)set([obj.FrameRateH; obj.MessageH; obj.FrAcqH],'String','-','BackgroundColor',obj.COLOR_STAT_OK));
                
                start(obj.TimerIdle); % only start the idle timer because we always start idle
                
            catch exception
                obj.CamCon.disconnect;
                obj.LaserCon.close;
                obj.StageCon.disconnect;
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
                set(obj.AlexSelectionH,'enable','off');
            else
                % we have finished acquiring
                set(handlesToInactivate,'enable','on');
                if obj.AlexMode, set(obj.AlexSelectionH,'enable','on'); end
            end
        end
        
        %% UPDATERS (for real-time and to call after every changed button)
        
        
        %% updater for idle timer
        function updateIdle(obj)
            try
                obj.updateStat; % Always update the status indicator
                set(obj.SinglePlotAxisH,'CLim',obj.ImageLimits); % update the image scaling
                statusNow = obj.CamCon.getStringStatus;
                
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
            try
                obj.updateStat; % always update the status
                set(obj.SinglePlotAxisH,'CLim',obj.ImageLimits); % update the image scaling
                
                statusNow = obj.CamCon.getStringStatus;
                if strcmp(statusNow,'ACQUIRE')
                    % update the frame rate and temperature indicators
                    obj.updateTemp;
                    obj.updateFrameRate;
                    
                    % update the displayed image
                    [codeStr, imageData, latestNo] = obj.CamCon.getLatestData;
                    if strcmp(codeStr,'OK')
                        set(obj.SingleImageH,'CData',imageData);
                        obj.LatestImageData = imageData;
                        % scale the image
                        set(obj.FrAcqH,'String',sprintf('%i',latestNo),'BackgroundColor',obj.COLOR_STAT_WARN);
                    end
                  
                % what happens if the ACQ timer realises the acquistion has stopped    
                elseif strcmp(statusNow,'IDLE') && obj.AllowedToStop
                    % make sure the start acquisition buttons are both
                    % available
                    obj.setGraphicsAcquiring(0);
                    
                    set(obj.StartVideoH,'enable','on','value',0);
                    set(obj.StartCaptH,'enable','on','value',0);
                    set(obj.StopCaptH,'enable','off','value',1);
                    
                    % if in ALEX then stop the lasers after the camera
                    % stops too
                    if obj.AlexMode
                        obj.LaserCon.stopSignal
                        obj.GreenState = 0;
                        obj.RedState = 0;
                        obj.NIRState = 0;
                        % set the buttons to reflect this
                        set([obj.GreenOnH, obj.RedOnH, obj.NIROnH],'Value',0,'Enable','on');                
                    end
                
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
            
            set(src,'enable','inactive','Value',1);
            set(obj.AlexSelectionH,'enable','on');
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
            
            set(src,'enable','inactive','Value',1);
            set(obj.AlexSelectionH,'enable','off');
            obj.CamCon.setAcqMode(0); % set cw mode on the camera (internal triggering)
            % make sure the camera is set to the same frame time as before
            obj.FrameTime = max(obj.FrameTime,obj.CamCon.getMinRepeatTime*1000);
            obj.CamCon.setCwRepeatTime(obj.FrameTime/1000);
            obj.AlexMode = 0;
            obj.updateTimes; % since we care about the exposure percentage
            set(obj.AlexOnH,'Value',0,'enable','on');
        end
        
        function selectAlex(obj,src,~)
            % for choosing between duALEX or trALEX types
            if ~obj.AlexMode || obj.State ~=0
                % i.e. somehow we've entered this callback in CW mode or while not idle
                set(src,'Value',obj.AlexSelection);
            else
                % set our alex type to be what the user wants
                obj.AlexSelection = get(src,'Value');
                
                % set which lasers are involved so we are allowed to change
                % the free lasers state
                switch obj.AlexSelection
                    case 1 % GR is RG
                        obj.GreenBusy = 1;
                        obj.RedBusy = 1;
                        obj.NIRBusy = 0;
                    case 2 % GRN (is RNG)
                        obj.GreenBusy = 1;
                        obj.RedBusy = 1;
                        obj.NIRBusy = 1;
                    case 3 % GN (is NG)
                        obj.GreenBusy = 1;
                        obj.RedBusy = 0;
                        obj.NIRBusy = 1;
                    case 4 % RN (is ??)
                        obj.GreenBusy = 0;
                        obj.RedBusy = 1;
                        obj.NIRBusy = 1;
                    case 5 % NRG (is NRG)
                        obj.GreenBusy = 1;
                        obj.RedBusy = 1;
                        obj.NIRBusy = 1;
                end % switch
            end % if-else
        end % selectAlex
        
        % callback from buttons to change camera settings
        
        %% SETTING LASER STATES AND POWERS
        
        function toggleGreen(obj,src,~)
            % N.B. The green laser is a little different, because the NI
            % card controls the power via the AOM - so we pass the laser
            % power as an argument rather than simply the on/off state
            % call back for laser on button
            if (obj.AlexMode && obj.State ~= 0 && obj.GreenBusy) || (~obj.AlexMode && obj.State == 3)
                % if it is in alex mode and not idle and the green laser is
                % involved in the ALEX, or in cw mode and spooling, then do
                % nothing and pop the button back to where it previously
                % was
                set(src,'Value',obj.GreenState);
            else
                % otherwise we have no problem setting the laser's state
                obj.GreenState = get(src,'Value');
                obj.LaserCon.setGreenLaser(obj.GreenState*obj.GreenPower);
            end
        end
        
        function toggleRed(obj,src,~)
            % call back for laser on button
            if (obj.AlexMode && obj.State ~= 0 && obj.RedBusy) || (~obj.AlexMode && obj.State == 3)
                % if it is in alex mode and not idle and the green laser is
                % involved in the ALEX, or in cw mode and spooling, then do
                % nothing and pop the button back to where it previously
                % was
                set(src,'Value',obj.RedState);
            else
                % otherwise we have no problem setting the laser's state
                obj.RedState = get(src,'Value');
                obj.LaserCon.setRedLaser(obj.RedState*obj.RedPower);
            end
        end
        
        function toggleNIR(obj,src,~)
            % call back for laser on button
            if (obj.AlexMode && obj.State ~= 0 && obj.NIRBusy) || (~obj.AlexMode && obj.State == 3)
                % if it is in alex mode and not idle and the green laser is
                % involved in the ALEX, or in cw mode and spooling, then do
                % nothing and pop the button back to where it previously
                % was
                set(src,'Value',obj.NIRState);
            else
                % otherwise we have no problem setting the laser's state
                obj.NIRState = get(src,'Value');
                obj.LaserCon.setNIRLaser(obj.NIRState);
            end
        end
        
        % powers
        
        function setGreenPower(obj,src,~)
            if (obj.AlexMode && obj.State ~= 0 && obj.GreenBusy) || (~obj.AlexMode && obj.State == 3)
                % if we aren't allowed to set the power then don't
                set(src,'String',sprintf('%.1f %%',obj.GreenPower*100));
            else
                inputPowerString = get(src,'String');
                if strncmp(fliplr(inputPowerString),'%',1)
                    inputPowerString = inputPowerString(1:end-1);
                end
                inputPower = str2double(inputPowerString)/100;
                if isnan(inputPower)
                    % reset to the last value which was valid
                    set(src,'String',sprintf('%.1f %%',obj.GreenPower*100));
                else
                    % make sure the power is valid (range 0-1) here
                    inputPower = max(inputPower,0);
                    inputPower = min(inputPower,1);
                    set(src,'String',sprintf('%.1f %%',inputPower*100));
                    obj.GreenPower = inputPower;
                    
                    % and set the laser power to what we want
                    obj.LaserCon.setGreenLaser(obj.GreenState*obj.GreenPower);
                end 
            end
        end % setGreenPower
        
        function setRedPower(obj,src,~)
            if (obj.AlexMode && obj.State ~= 0 && obj.RedBusy) || (~obj.AlexMode && obj.State == 3)
                % if we aren't allowed to set the power then don't
                set(src,'String',sprintf('%.1f %%',obj.RedPower*100));
            else
                inputPowerString = get(src,'String');
                if strncmp(fliplr(inputPowerString),'%',1)
                    inputPowerString = inputPowerString(1:end-1);
                end
                inputPower = str2double(inputPowerString)/100;
                if isnan(inputPower)
                    % reset to the last value which was valid
                    set(src,'String',sprintf('%.1f %%',obj.RedPower*100));
                else
                    % make sure the power is valid (range 0-1) here
                    inputPower = max(inputPower,0);
                    inputPower = min(inputPower,1);
                    set(src,'String',sprintf('%.1f %%',inputPower*100));
                    obj.RedPower = inputPower;
                    
                    % and set the laser power to what we want
                    obj.LaserCon.setRedLaser(obj.RedState*obj.RedPower);
                end 
            end
        end
        
        %% CLEANUP
        % clean up function for closing the figure (that gracefully closes
        % the camera)
        function cleanUp(obj,src,~)
            
            % stop the two timers
            stop(obj.TimerIdle);
            stop(obj.TimerAcq);
            
            obj.CamCon.disconnect; % gracefully disconnect from the camera
            obj.StageCon.disconnect;
            obj.LaserCon.close; % exit the card controller
            delete(src); % and delete the figure
        end
        
        %% CHANGING THE LOOK OF IMAGES
        
        function setMinImage(obj,src,~)
            newMin = get(src,'Value');
            
            newRange = get(src,'Value');
            newMax = obj.ImageLimits(1) + newRange*(obj.MAX_DATA-obj.ImageLimits(1));
            
            newMax = max(newMax,newMin + 1);
            obj.ImageLimits = [newMin newMax];
        end
        
        function setRangeImage(obj,src,~)
            newRange = get(src,'Value');
            newMax = obj.ImageLimits(1) + newRange*(obj.MAX_DATA-obj.ImageLimits(1));
            newMax = max(newMax,obj.ImageLimits(1) + 1);
            obj.ImageLimits(2) = newMax;
        end
        
        function autoscaleImage(obj,~,~)
            mostRecentImage = obj.LatestImageData;
            if isempty(mostRecentImage), return; end
            newMin = min(mostRecentImage(:));
            newMax = obj.AUTO_FACTOR*( mean(mostRecentImage(:)-newMin) ) + newMin + 1;
            newCLim = [newMin, newMax];
            
            set(obj.MinH,'Value',newMin);
            set(obj.RangeH,'Value',(newMax-newMin)/(obj.MAX_DATA-newMin)); % as a fraction of possible range
            
            obj.ImageLimits = newCLim;
            
            set(obj.SinglePlotAxisH,'CLim',newCLim);
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
            
            %% start the video
            if strcmp(obj.CamCon.getStringStatus,'IDLE')
                try
                    obj.CamCon.startAcquiring;
                catch
                    set(obj.MessageH,'String','CAMERA ERROR','BackgroundColor',obj.COLOR_STAT_ERR);
                end
            else
                set(obj.MessageH,'String','CAMERA BUSY','BackgroundColor',obj.COLOR_STAT_ERR);
            end
            
            %% if we are in ALEX mode then start the appropriate card action
            if obj.AlexMode
                obj.LaserCon.startAlex(obj.AlexSelection,obj.FrameTime,obj.GreenPower);
            end
            
            %% finally enable the stop and spool buttons
            
            set(obj.StartCaptH,'enable','on','Value',0);
        end
        
        % Start with spooling
        function startCapt(obj,src,~)
            
            obj.AllowedToStop = 0;
            
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
            
            %% start the video
            if strcmp(obj.CamCon.getStringStatus,'IDLE')
                try
                    obj.CamCon.startAcquiring
                catch
                    set(obj.MessageH,'String','CAMERA ERROR - STOP AND RETRY',...
                    'BackgroundColor',obj.COLOR_STAT_ERR);
                end
            else
                set(obj.MessageH,'String','CAMERA BUSY',...
                    'BackgroundColor',obj.COLOR_STAT_ERR);
            end
            
            %% if we are in ALEX mode, then start the card in the proper mode
            if obj.AlexMode
                obj.LaserCon.startAlex(obj.AlexSelection,obj.FrameTime,obj.GreenPower);
            end
            
            %% start the update timer
            try
                start(obj.AcqTimer);
            catch
            end
            
            obj.AllowedToStop  = 1;
            
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
            % Only stop the lasers if we are in ALEX mode
            % finally enable the start buttons
            set(obj.StartVideoH,'enable','on','Value',0);
            set(obj.StartCaptH,'enable','on','Value',0);
        end
    end
    
end
