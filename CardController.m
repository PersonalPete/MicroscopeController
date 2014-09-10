classdef CardController < handle
    %CardController Uses Active X to control LabVIEW for synchronisation
    %   Initialise the class to open the active x server, then using the
    %   methods, different VIs are called with different input parameters
    %   to run in the background and synchronise the lasers and camera for
    %   ALEX data acquisition
    
    properties (Access = private)
        % where to find the LabVIEW VIs that will be run when requested
        ViLocation = 'C:\Users\LocalAdmin\Documents\MATLAB\MicroscopeController';
        % used to make sure we only have one VI running at a time
        IsRunning = false;
        LabviewActXServer;
        CurrentVi;
    end
    
    methods (Access = public)
        function obj = CardController()
            % construct the active x server
            obj.LabviewActXServer = actxserver('LabVIEW.Application');
        end % no-arg constructor
        
        function startThreeColourALEX(obj,freq,greenAmp)
            % uses the VI 'trALEX.vi' to start three colour ALEX
            % acquisition. The frequency must be less than 1 kHz and the
            % green amplitude must be between 0 and 1
            if nargin < 3
                freq = 10; % (/Hz) default
                greenAmp = 0.1; % (/V) i.e. 10% power
            end
            
            if freq > 1000 % check the frequency is possible
                MException('MScope:InvalidArgument',...
                    'Frequency must tbe less than 1 kHz').throw;
            end
            
            if greenAmp > 1 || greenAmp < 0; % check the AOM isn't overwhelmed
                MException('MScope:InvalidArgument',...
                    'Green amplitude must be between 0 and 1 V').throw;
            end
            
            if obj.IsRunning % make sure we don't try to run two at once
                MException('MScope:AlreadyRunning',...
                    'Can''t start acquisition, already running....').throw;
            end
            
            % which VI we are going to open
            obj.CurrentVi = invoke(obj.LabviewActXServer,'GetVIReference',...
                fullfile(obj.ViLocation,'trALEX.vi'));
            
            % set the parameters for it
            obj.CurrentVi.SetControlValue('Repetition Frequency',freq);
            obj.CurrentVi.SetControlValue('Analog Amplitude',greenAmp);
            
            
            obj.CurrentVi.Run(1); % the argument '1' runs in background
            obj.IsRunning = true;
        end % startThreeColourALEX
        
        function stopSignal(obj)
            % aborts the current running VI
            if ~obj.IsRunning
                MException('MScope:NotRunning',...
                    'Can''t stop acquisition, not running').throw;
            end
            obj.CurrentVi.release; % stop the VI - green laser could stay on here
            obj.IsRunning = false;
        end
          
        function close(obj) % deletes the server
            if obj.IsRunning
                MException('MScope:IsRunning',...
                    'Can''t close, acquisition running');
            end
            obj.LabviewActXServer.delete;
        end
    end
    
end

