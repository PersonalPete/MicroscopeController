classdef CardController < handle
    %CardController Uses Active X to control LabVIEW for synchronisation
    %   Initialise the class to open the active x server, then using the
    %   methods, different VIs are called with different input parameters
    %   to run in the background and synchronise the lasers and camera for
    %   ALEX data acquisition
    
    properties (SetAccess = private)
        % where to find the LabVIEW VIs that will be run when requested
        ViLocation = 'C:\Users\LocalAdmin\Documents\MATLAB\MicroscopeController\CardControlVIs';
        % used to make sure we only have one VI running at a time
        IsRunning = false;
        LabviewActXServer;
        CurrentVi;
        
        % for the static laser output control
        GreenVi;
        RedVi;
        NIRVi;
        
        % is a particular laser in use (have we set an output value)
        GreenBusy = 0;
        RedBusy = 0;
        NIRBusy = 0;
        
        CoherentCon; % to send serial port information to the coherent red laser
        
    end
    
    methods (Access = public)
        function obj = CardController(redPort)
            % construct the coherent connection
            obj.CoherentCon = CoherentCube(redPort);
            
            % construct the active x server
            obj.LabviewActXServer = actxserver('LabVIEW.Application');
        end % no-arg constructor
        
        function setGreenLaser(obj,power)
            if power > 1 || power < 0
                MException('MScope:InvalidArgument',...
                    'Green power must be between 0 and 1');
            end
            
            if ~obj.IsRunning % if we aren't currently running an ALEX vi
                if obj.GreenBusy % if we have already set the green power
                    % stop the old green vi
                    obj.GreenVi.Abort;
                    % delete(obj.GreenVi);
                    obj.GreenBusy = false;
                end
                obj.GreenVi = invoke(obj.LabviewActXServer,'GetVIReference',...
                    fullfile(obj.ViLocation,'Green_Ana.vi'));                
                obj.GreenVi.SetControlValue('Green Laser Power',power);
                obj.GreenVi.Run(1);
                obj.GreenBusy = 1;
            end
        end % setGreenLaser
        
        function setRedLaser(obj,power)
            if power < 0 || power > 1
                MException('MScope:InvalidArgument',...
                    'Red state must be between bewteen 0 and 1');
            end
            
            % We should use the serial/USB connection to the laser to set
            % the red power here
            
            obj.CoherentCon.setPower(power);
            
            if ~obj.IsRunning % if we aren't currently running an ALEX vi
                if obj.RedBusy % if we have already set the red power
                    % stop the old green vi
                    obj.RedVi.Abort;
                    obj.RedBusy = false;
                end
                obj.RedVi = invoke(obj.LabviewActXServer,'GetVIReference',...
                    fullfile(obj.ViLocation,'Red_Dig.vi'));
                if power
                    obj.RedVi.SetControlValue('RedLaserOn',true);
                else
                    obj.RedVi.SetControlValue('RedLaserOn',false);
                end
                obj.RedVi.Run(1);
                obj.RedBusy = 1;
            end
        end % setGreenLaser
        
        function setNIRLaser(obj,state)
            if state < 0
                MException('MScope:InvalidArgument',...
                    'NIR state must be between boolean');
            end
            
            if ~obj.IsRunning % if we aren't currently running an ALEX vi
                if obj.NIRBusy % if we have already set the NIR power
                    % stop the old green vi
                    obj.NIRVi.Abort;
                    obj.NIRBusy = false;
                end
                obj.NIRVi = invoke(obj.LabviewActXServer,'GetVIReference',...
                    fullfile(obj.ViLocation,'NIR_Dig.vi'));
                if state
                    obj.NIRVi.SetControlValue('NIRLaserOn',true);
                else
                    obj.NIRVi.SetControlValue('NIRLaserOn',false);
                end
                obj.NIRVi.Run(1);
                obj.NIRBusy = 1;
            end
        end % setNIRLaser
        
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
            obj.CurrentVi.Abort; % stop the VI - green laser could stay on here
            obj.IsRunning = false;
        end
        
        function close(obj) % deletes the server
            try
                if obj.IsRunning
                    obj.CurrentVi.release;
                end
                
                % make sure all the lasers are off
                obj.setGreenLaser(0);
                obj.setNIRLaser(0);
                obj.setRedLaser(0);
                
                obj.GreenVi.release;
                obj.NIRVi.release;
                obj.RedVi.release
            catch
            end
            obj.CoherentCon.close;
            obj.LabviewActXServer.delete;
        end
    end
    
end

