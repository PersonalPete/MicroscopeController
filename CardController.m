classdef CardController < handle
    %CardController Uses Active X to control LabVIEW for synchronisation
    %   Initialise the class to open the active x server, then using the
    %   methods, different VIs are called with different input parameters
    %   to run in the background and synchronise the lasers and camera for
    %   ALEX data acquisition
    
    properties (SetAccess = private)
        % where to find the LabVIEW VIs that will be run when requested
        ViLocation = 'C:\User Data\Peter\MATLAB\MicroscopeController\CardControlVIs';
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
        
        CurrentAlexSelection = 0;
    end
    
    methods (Access = public)
        function obj = CardController(redPort)
            % construct the coherent connection
            obj.CoherentCon = CoherentCube(redPort);
            
            % construct the active x server
            obj.LabviewActXServer = actxserver('LabVIEW.Application');
            
            obj.setRedLaser(0);
            obj.setNIRLaser(0);
            obj.setGreenLaser(0);
            
        end % constructor
        
        function setGreenLaser(obj,power)
            if power > 1 || power < 0
                MException('MScope:InvalidArgument',...
                    'Green power must be between 0 and 1');
            end
            
            if (~obj.IsRunning || obj.CurrentAlexSelection == 4)
                % if we aren't currently running an ALEX vi or we are, but
                % it doesn't use this laser
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
            
            if (~obj.IsRunning || obj.CurrentAlexSelection == 3) % if we aren't currently running an ALEX vi
                if obj.RedBusy % if we have already set the red power
                    % stop the old green vi
                    obj.RedVi.Abort;
                    obj.RedBusy = false;
                end
                obj.RedVi = invoke(obj.LabviewActXServer,'GetVIReference',...
                    fullfile(obj.ViLocation,'Red_Dig.vi'));
                if power > 0
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
            
            if (~obj.IsRunning || obj.CurrentAlexSelection == 1) % if we aren't currently running an ALEX vi
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
        
        function startAlex(obj,alexSelection,frameTime,greenAmp,redPower)
            % uses the VI 'trALEX.vi' to start three colour ALEX
            % acquisition. The frame time is in MILLISECONDS
            
            frameTime = frameTime/1000; % MILLISECONDS -> SECONDS
            
            if greenAmp > 1 || greenAmp < 0; % check the AOM isn't overwhelmed
                MException('MScope:InvalidArgument',...
                    'Green amplitude must be between 0 and 1 V').throw;
            end
            
            if obj.IsRunning % make sure we don't try to run two at once
                obj.CurrentVi.Abort;
                obj.IsRunning = false;
            end
            
            % We need to check if any lasers that we are about to control
            % with the card are already busy - if they are, then we should
            % cancel the vi they are running
            
            obj.CurrentAlexSelection = alexSelection;
            
            switch alexSelection
                case 1 % GR
                    if obj.GreenBusy
                        obj.GreenVi.Abort;
                        obj.GreenBusy = false;
                    end
                    if obj.RedBusy
                        obj.RedVi.Abort;
                        obj.RedBusy = false;
                        obj.CoherentCon.setPower(redPower);
                    end
                    alexViToRun = 'DuALEX_RG.vi';
                    freq = 1/(frameTime*2); % since it is two color and freq is the overall cycle time
                case 2 % GRN
                    if obj.GreenBusy
                        obj.GreenVi.Abort;
                        obj.GreenBusy = false;
                    end
                    if obj.RedBusy
                        obj.RedVi.Abort;
                        obj.RedBusy = false;
                        obj.CoherentCon.setPower(redPower);
                    end
                    if obj.NIRBusy
                        obj.NIRVi.Abort;
                        obj.NIRBusy = false;
                    end
                    alexViToRun = 'TrALEX_GRN.vi';
                    freq = 1/(frameTime*3); % since it is three color
                case 3 % GN
                    if obj.GreenBusy
                        obj.GreenVi.Abort;
                        obj.GreenBusy = false;
                    end
                    if obj.NIRBusy
                        obj.NIRVi.Abort;
                        obj.NIRBusy = false;
                    end
                    alexViToRun = 'DuALEX_GN.vi';
                    freq = 1/(frameTime*2); % since it is two color
                case 4 % RN
                    if obj.NIRBusy
                        obj.NIRVi.Abort;
                        obj.NIRBusy = false;
                    end
                    if obj.RedBusy
                        obj.RedVi.Abort;
                        obj.RedBusy = false;
                        obj.CoherentCon.setPower(redPower);
                    end
                    alexViToRun = 'DuALEX_RN.vi';
                    freq = 1/(frameTime*2); % since it is two color
                case 5 % NRG
                    if obj.GreenBusy
                        obj.GreenVi.Abort;
                        obj.GreenBusy = false;
                    end
                    if obj.RedBusy
                        obj.RedVi.Abort;
                        obj.RedBusy = false;
                        obj.CoherentCon.setPower(redPower); % set the red power here since we just turned it off
                    end
                    if obj.NIRBusy
                        obj.NIRVi.Abort;
                        obj.NIRBusy = false;
                    end
                    alexViToRun = 'TrALEX_NRG.vi';
                    freq = 1/(frameTime*3); % since it is three color
            end
            % which VI we are going to open
            obj.CurrentVi = invoke(obj.LabviewActXServer,'GetVIReference',...
                fullfile(obj.ViLocation,alexViToRun));
            
            % set the parameters for it
            obj.CurrentVi.SetControlValue('Repetition Frequency',freq);
            obj.CurrentVi.SetControlValue('Analog Amplitude',greenAmp);
            
            obj.CurrentVi.Run(1); % the argument '1' runs in background
            obj.IsRunning = true;
        end % startALEX
        
        function stopSignal(obj)
            % aborts the current running VI(s)
                   
            if obj.IsRunning % if we are doing alex
                obj.CurrentVi.Abort; % stop the VI - green laser could stay on here
                obj.IsRunning = false;
            end
            
            % turn all the others off too
            obj.setGreenLaser(0);
            obj.setNIRLaser(0);
            obj.setRedLaser(0);
                
        end
        
        function delete(obj) % deletes the server
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
                fprintf('\nProblem disconnecting from lasers\nAttempting to ensure all are off\n');
                obj.setGreenLaser(0);
                obj.GreenVi.release;
            end
            obj.CoherentCon.delete;
            obj.LabviewActXServer.delete;
        end
    end
    
end

